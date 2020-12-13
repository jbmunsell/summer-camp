--
--	Jackson Munsell
--	12 Dec 2020
--	chalk.client.lua
--
--	chalk gene client driver
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

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local chalkCoverFrame = env.PlayerGui:WaitForChild("Core"):FindFirstChild("ChalkCover", true)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.chalk)

-- If we are NOT holding OR we are NOT in range of a blackboard, then show text edit cover
pickupUtil.getLocalCharacterHoldingStream(genes.chalk)
	:switchMap(function (instance)
		return instance
		and rx.Observable.interval(0.2):map(function ()
			return genesUtil.getNearestInstance(genes.chalkBlackboard,
				axisUtil.getPosition(instance), instance.config.chalk.reach.Value)
			end):map(dart.boolNot)
		or rx.Observable.just(false)
	end)
	:startWith(false)
	:subscribe(function (v)
		chalkCoverFrame.Visible = v
	end)
