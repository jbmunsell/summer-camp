--
--	Jackson Munsell
--	28 Nov 2020
--	mop.server.lua
--
--	mop gene server driver
--

-- env
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local ragdoll = env.src.ragdoll

-- modules
local fx = require(axis.lib.fx)
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local mopUtil = require(genes.mop.util)
local pickupUtil = require(genes.pickup.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local transparencyTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function setDebounce(instance)
	local v = instance.state.mop.debounce
	v.Value = true
	rx.Observable.timer(instance.config.mop.debounceTimer.Value):subscribe(function ()
		v.Value = false
	end)
end

local function createPuddle(character, instance)
	-- Get ground position
	local player = Players:GetPlayerFromCharacter(character)
	local down = Vector3.new(0, -10, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Whitelist
	params.FilterDescendantsInstances = { workspace.Terrain, workspace.Map }
	local result = workspace:Raycast(instance.BottomBase.Position + down * -0.5, down, params)
	if not result or not result.Position then return end

	-- Create a puddle at ground position
	local puddle = env.res.objects.Puddle:Clone()
	local pcf = puddle:GetPrimaryPartCFrame()
	puddle:SetPrimaryPartCFrame(pcf - pcf.p + result.Position)
	fx.new("TransparencyEffect", puddle)
	puddle.TransparencyEffect.Value = 1
	puddle.Parent = workspace

	-- Tween her transparency up
	TweenService:Create(puddle.TransparencyEffect, transparencyTweenInfo, { Value = 0 }):Play()
	rx.Observable.timer(instance.config.mop.puddleDuration.Value):subscribe(function ()
		local t = TweenService:Create(puddle.TransparencyEffect, transparencyTweenInfo, { Value = 1 })
		t.Completed:Connect(function ()
			puddle:Destroy()
		end)
		t:Play()
	end)

	-- Connect to touched
	rx.Observable.fromPlayerTouchedDescendant(puddle, 0.5)
		:map(dart.select(2))
		:reject(dart.equals(player))
		:reject(function (p)
			return p.Character.Humanoid:GetState() == Enum.HumanoidStateType.Physics
		end)
		:subscribe(function (p)
			ragdoll.net.Push:FireClient(p)
			delay(2, function ()
				ragdoll.net.Pop:FireClient(p)
			end)
		end)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.mop)

-- Create puddle when activated
pickupUtil.getActivatedStream(genes.mop)
	:reject(function (_, instance) return instance.state.mop.debounce.Value end)
	:subscribe(function (character, instance)
		setDebounce(instance)
		createPuddle(character, instance)
	end)
