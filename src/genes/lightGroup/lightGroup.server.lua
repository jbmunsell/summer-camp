--
--	Jackson Munsell
--	07 Sep 2020
--	lightGroup.server.lua
--
--	Light group interactable server functionality driver
--

-- env
local env  = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local interact = genes.interact
local lightGroup = genes.lightGroup
local multiswitch = genes.multiswitch

-- modules
local dart = require(axis.lib.dart)
local soundUtil = require(axis.lib.soundUtil)
local genesUtil = require(genes.util)
local interactUtil = require(interact.util)
local lightGroupUtil = require(lightGroup.util)
local multiswitchUtil = require(multiswitch.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Connect to all light groups forever
genesUtil.initGene(lightGroup)

-- Create streams from all switches
multiswitchUtil.getSwitchStream(lightGroup)
	:subscribe(lightGroupUtil.renderLightGroup)

-- Light group interacted
local interacted = interactUtil.getInteractStream(lightGroup)
	:map(dart.select(2))
interacted:subscribe(dart.follow(multiswitchUtil.toggleSwitch, "lightGroup", "primary"))
interacted:subscribe(function (instance)
	local attachment = instance:FindFirstChild("InteractionPromptAdornee", true)
	if attachment then
		soundUtil.playRandom(env.res.genes.lightGroup.sounds, attachment)
	end
end)
