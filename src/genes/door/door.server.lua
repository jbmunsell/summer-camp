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
local soundUtil = require(axis.lib.soundUtil)
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
local interacted = interactUtil.getInteractStream(door)
	:map(dart.select(2)) -- drop the client, keep just the door
interacted:subscribe(genesUtil.toggleStateValue(door, "open"))
interacted:subscribe(function (instance)
	local attachment = instance:FindFirstChild("InteractAttachment", true)
	if attachment then
		soundUtil.playRandom(env.res.genes.door.sounds, attachment)
	end
end)
