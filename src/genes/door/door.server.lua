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

-- Render door state according to value
genesUtil.observeStateValue(door, "open")
	:subscribe(doorUtil.renderDoor)

-- Activated
interactUtil.getInteractStream(door)
	:map(dart.select(2)) -- drop the client, keep just the door
	:subscribe(genesUtil.toggleStateValue(door, "open"))
