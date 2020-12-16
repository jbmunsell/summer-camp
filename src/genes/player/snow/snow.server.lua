--
--	Jackson Munsell
--	14 Dec 2020
--	snow.server.lua
--
--	snow gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local fx = require(axis.lib.fx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local pickupUtil = require(genes.pickup.util)
local playerUtil = require(genes.player.util)
local snowUtil = require(genes.player.snow.util)

local snowNet = genes.player.snow.net

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Gather snow
local function gatherSnow(player)
	-- Terminator stream
	local terminator = rx.Observable.from(player.state.snow.gathering):reject():first()

	-- Get ground
	local result = snowUtil.raycastPlayerGround(player, CFrame.new(0, 0, -2))
	if not result or not result.Position then return end

	-- Snowball
	local ball = env.res.snow.Snowball:Clone()
	fx.new("ScaleEffect", ball)
	local weld = Instance.new("Weld")
	weld.Part0 = workspace.Terrain
	weld.Part1 = ball.PrimaryPart
	weld.C0 = CFrame.new(result.Position)
	weld.Name = "StationaryWeld"
	weld.Parent = ball
	ball.Parent = workspace
	genesUtil.waitForGene(ball, genes.pickup)
	local function setBallScale(scale)
		ball.ScaleEffect.Value = scale
	end
	local function pickupSnowball()
		pickupUtil.unequipCharacter(player.Character)
		pickupUtil.equip(player.Character, ball)
	end

	-- Create snowball and increase size until stopped gathering
	rx.Observable.heartbeat()
		:scan(function (x, dt) return x + dt * 6 end, 1)
		:map(function (d) return math.pow(d, 1 / 3) end)
		:takeUntil(terminator)
		:subscribe(setBallScale)

	-- When they stop gathering, give them this object as a pickup
	terminator:subscribe(pickupSnowball)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene for all players
playerUtil.initPlayerGene(genes.player.snow)

-- When they start gathering, run a heartbeat stream to increase scale
genesUtil.observeStateValue(genes.player.snow, "gathering")
	:filter(dart.select(2))
	:map(dart.select(1))
	:subscribe(gatherSnow)

-- Process requests
rx.Observable.from(snowNet.GatheringStarted)
	:filter(snowUtil.isPlayerStandingOnSnow)
	:map(dart.drag(true))
	:merge(rx.Observable.from(snowNet.GatheringStopped):map(dart.drag(false)))
	:subscribe(function (player, gathering)
		player.state.snow.gathering.Value = gathering
	end)
