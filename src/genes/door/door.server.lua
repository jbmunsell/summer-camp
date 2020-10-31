--
--	Jackson Munsell
--	29 Oct 2020
--	door.server.lua
--
--	Door object driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local interact = genes.interact
local door = genes.door

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local interactUtil = require(interact.util)
local genesUtil = require(genes.util)
local doorUtil = require(door.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init class
genesUtil.initGene(door)
	:flatMap(function (instance)
		return rx.Observable.from(instance.state.door.open)
			:map(dart.constant(instance))
	end)
	:subscribe(doorUtil.renderDoor)

-- Activated
interactUtil.getInteractStream(door)
	:map(dart.omitFirst)
	:subscribe(doorUtil.toggleDoorOpen)
