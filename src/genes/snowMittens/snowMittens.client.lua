--
--	Jackson Munsell
--	16 Dec 2020
--	snowMittens.client.lua
--
--	snowMittens gene client driver
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
local pickupUtil = require(genes.pickup.util)
local snowUtil = require(env.src.snow.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

-- Humanoid running subject
local humanoidRunning = rx.BehaviorSubject.new(0)
local gatheringSnow = rx.BehaviorSubject.new(false)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Start gathering snow
-- 	Sends message to server to start gathering
local function startGatheringSnow(instance)
	-- Assert humanoid
	local humanoid = axisUtil.getLocalHumanoid()
	if not humanoid then return end

	-- Tell server we're gathering
	gatheringSnow:push(true)
	genes.snowMittens.net.GatheringStarted:FireServer(instance)

	-- Start playing animation
	local animator = axisUtil.getLocalAnimator()
	local startTrack = animator:LoadAnimation(env.res.snow.animations.GatherSnowStart)
	local loopTrack = animator:LoadAnimation(env.res.snow.animations.GatherSnowLoop)
	rx.Observable.from(startTrack:GetMarkerReachedSignal("GatherLoopStart"))
		:filter(function () return gatheringSnow:getValue() end)
		:first()
		:takeUntil(rx.Observable.from(startTrack.Stopped))
		:subscribe(function ()
			loopTrack:Play()
		end)
	startTrack:Play()

	-- Stop gathering function
	local function stopGathering()
		-- startTrack:Stop()
		loopTrack:Stop()
		gatheringSnow:push(false)
		genes.snowMittens.net.GatheringStopped:FireServer(instance)
	end

	-- When the humanoid moves or dies, stop gathering
	delay(0.2, function ()
		rx.Observable.from(humanoid.Died)
			:merge(rx.Observable.fromInstanceLeftGame(humanoid),
				humanoidRunning:reject(dart.lessThan(1)))
			:first()
			:subscribe(stopGathering)
	end)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.snowMittens)

-- Humanoid running
rx.Observable.from(env.LocalPlayer.CharacterAdded)
	:startWith(env.LocalPlayer.Character)
	:filter()
	:switchMap(function (c)
		return rx.Observable.from(c:WaitForChild("Humanoid").Running)
	end)
	:multicast(humanoidRunning)

-- init gene for all players
genesUtil.initGene(genes.snowMittens)

-- When the user clicks, check if standing over snow and play animation
pickupUtil.getActivatedStream(genes.snowMittens)
	:filter(dart.bind(snowUtil.isPlayerStandingOnSnow, env.LocalPlayer))
	:reject(function () return gatheringSnow:getValue() end)
	:subscribe(startGatheringSnow)
