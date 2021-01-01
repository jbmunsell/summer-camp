--
--	Jackson Munsell
--	16 Dec 2020
--	snowMittens.server.lua
--
--	snowMittens gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local fx = require(axis.lib.fx)
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local soundUtil = require(axis.lib.soundUtil)
local genesUtil = require(genes.util)
local pickupUtil = require(genes.pickup.util)
local snowUtil = require(env.src.snow.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Gather snow
local function gatherSnow(instance)
	-- Terminator stream
	local player = instance.state.pickup.owner.Value
	if not player then
		error("Attempt to gather snow with no player instance")
	end
	local terminator = rx.Observable.from(instance.state.snowMittens.gathering)
		:reject()
		:merge(rx.Observable.fromInstanceLeftGame(instance))
		:first()

	-- Get ground
	local result = snowUtil.raycastPlayerGround(player, CFrame.new(0, 0, -3))
	if not result or not result.Position then return end

	-- Snowball
	local ball = env.res.snow.Snowball:Clone()
	local gatheringSound = soundUtil.playSound(env.res.snow.audio.SnowGather, ball.PrimaryPart)
	ball:SetPrimaryPartCFrame(CFrame.new(result.Position))
	fx.new("ScaleEffect", ball)
	local weld = Instance.new("Weld")
	weld.Part0 = workspace.Terrain
	weld.Part1 = ball.PrimaryPart
	weld.C0 = CFrame.new(result.Position)
	weld.Name = "StationaryWeld"
	weld.Parent = ball
	ball.Parent = workspace
	fx.setFXEnabled(ball, false)
	local function setBallScale(scale)
		ball.ScaleEffect.Value = scale
	end
	local function pickupSnowball()
		gatheringSound:Stop()
		gatheringSound:Destroy()
		if instance:IsDescendantOf(game) then
			genesUtil.waitForGene(ball, genes.pickup)
			pickupUtil.unequipCharacter(player.Character)
			pickupUtil.equip(player.Character, ball)
		else
			ball:Destroy()
		end
	end

	-- Create snowball and increase size until stopped gathering
	rx.Observable.heartbeat()
		:scan(function (x, dt) return x + dt * 6 end, 1)
		:map(function (d) return math.pow(d, 1 / 3) end)
		:takeUntil(terminator)
		:subscribe(setBallScale)

	-- When they stop gathering, give them this object as a pickup
	terminator
		-- :filter(function () return instance:IsDescendantOf(game) end)
		:subscribe(pickupSnowball)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene for all players
genesUtil.initGene(genes.snowMittens)

-- When they start gathering, run a heartbeat stream to increase scale
genesUtil.observeStateValue(genes.snowMittens, "gathering")
	:filter(dart.select(2))
	:map(dart.select(1))
	:subscribe(gatherSnow)

-- Process requests
local gatherStart = rx.Observable.from(genes.snowMittens.net.GatheringStarted)
	:filter(snowUtil.isPlayerStandingOnSnow)
	:filter(function (player, instance)
		return player.Character and
		instance.state.pickup.holder.Value == player.Character
	end)
local gatherStop = rx.Observable.from(genes.snowMittens.net.GatheringStopped)
	:filter(function (player, instance)
		return instance.state.pickup.owner.Value == player
	end)
local function transform(gatherStream, bool)
	return gatherStream:map(dart.select(2)):map(dart.drag(bool))
end
transform(gatherStart, true)
	:merge(transform(gatherStop, false))
	:subscribe(function (instance, gathering)
		instance.state.snowMittens.gathering.Value = gathering
	end)
