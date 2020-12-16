--
--	Jackson Munsell
--	14 Dec 2020
--	snow.client.lua
--
--	snow gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local snowUtil = require(genes.player.snow.util)

local snowNet = genes.player.snow.net

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

-- Humanoid running subject
local humanoidRunning = rx.BehaviorSubject.new(0)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Start gathering snow
-- 	Sends message to server to start gathering
local function startGatheringSnow()
	-- Assert humanoid
	local humanoid = axisUtil.getLocalHumanoid()
	if not humanoid then return end

	-- Tell server we're gathering
	snowNet.GatheringStarted:FireServer()

	-- Stop gathering function
	local function stopGathering()
		snowNet.GatheringStopped:FireServer()
	end

	-- When the humanoid moves or dies, stop gathering
	rx.Observable.from(humanoid.Died)
		:merge(rx.Observable.fromInstanceLeftGame(humanoid),
			humanoidRunning:reject(dart.lessThan(0.1)))
		:first()
		:subscribe(stopGathering)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Humanoid running
rx.Observable.from(env.LocalPlayer.CharacterAdded)
	:startWith(env.LocalPlayer.Character)
	:filter()
	:switchMap(function (c)
		return rx.Observable.from(c:WaitForChild("Humanoid").Running)
	end)
	:multicast(humanoidRunning)

-- init gene for all players
genesUtil.initGene(genes.player.snow)

-- When the user presses G, check if they are standing over snow and gather snowball
rx.Observable.from(Enum.KeyCode.G)
	:filter(dart.equals(Enum.UserInputState.Begin))
	:filter(dart.bind(snowUtil.isPlayerStandingOnSnow, env.LocalPlayer))
	:subscribe(startGatheringSnow)
