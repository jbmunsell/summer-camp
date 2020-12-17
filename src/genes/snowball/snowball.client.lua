--
--	Jackson Munsell
--	14 Dec 2020
--	snowball.client.lua
--
--	snowball gene client driver
--

-- env
local TweenService = game:GetService("TweenService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local ragdoll = env.src.character.ragdoll

-- modules
local fx = require(axis.lib.fx)
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local snowballUtil = require(genes.snowball.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local snowScreen = env.PlayerGui:WaitForChild("SnowScreen")

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function showSnowScreenParticles(instance)
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local config = snowScreen.config
	local function selectRandom(key)
		local min = config[key .. "Min"].Value
		local max = config[key .. "Max"].Value
		local d = math.random()
		return d * max + (1 - d) * min
	end
	local function selectRandomUDim2(key)
		return UDim2.new(selectRandom(key), 0, selectRandom(key), 0)
	end

	for _ = 1, math.ceil(config.imageCount.Value * instance.ScaleEffect.Value) do
		local image = snowScreen.seeds.Snow:Clone()
		image.Size = selectRandomUDim2("size")
		image.Position = selectRandomUDim2("position")
		image.Rotation = selectRandom("rotation")
		image.Visible = true
		image.Parent = snowScreen
		rx.Observable.timer(config.imageVisibleDuration.Value):subscribe(function ()
			local tween = TweenService:Create(image, tweenInfo, { ImageTransparency = 1 })
			tween.Completed:Connect(function ()
				image:Destroy()
			end)
			tween:Play()
		end)
	end
end

local function handleSnowballImpact(snowball, hit, hitPosition)
	local character = env.LocalPlayer.Character
	if hit and character and hit:IsDescendantOf(character) then
		if snowball.ScaleEffect.Value >= snowball.config.snowball.ragdollScaleMin.Value then
			ragdoll.interface.PushRagdoll:Invoke()
			delay(2, function ()
				ragdoll.interface.PopRagdoll:Invoke()
			end)
		end

		showSnowScreenParticles(snowball)
	end
	snowballUtil.popSnowball(snowball, hitPosition)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local snowballs = genesUtil.initGene(genes.snowball)

-- Snowball hit something
snowballs:flatMap(function (instance)
	return rx.Observable.from(instance.interface.projectile.LocalHit)
		:map(dart.carry(instance))
end):subscribe(handleSnowballImpact)

-- Set trail enabled according to launched value
local launchedStream = snowballs:flatMap(function (instance)
	return rx.Observable.from(instance.interface.projectile.LocalThrown)
		:map(dart.carry(instance))
end)
launchedStream -- Equip snow mittens after we threw a snowball
	:filter(function (_, player) return player == env.LocalPlayer end)
	:subscribe(function ()
		local mittens = genesUtil.getInstances(genes.snowMittens):raw()
		for _, v in pairs(mittens) do
			if v.state.pickup.owner.Value == env.LocalPlayer then
				genes.pickup.net.ToggleEquipRequested:FireServer(v)
			end
		end
	end)
launchedStream:subscribe(function (instance)
	fx.setFXEnabled(instance, true)
end)
