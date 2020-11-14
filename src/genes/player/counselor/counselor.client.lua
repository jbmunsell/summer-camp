--
--	Jackson Munsell
--	13 Nov 2020
--	counselor.client.lua
--
--	counselor gene client driver
--

-- env
local StarterGui = game:GetService("StarterGui")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Shout counselor in chat
local function shoutCounselor(player)
	local generalMessage = string.format("%s has been appointed counselor of the %s!",
		player.Name, player.Team.Name)
	StarterGui:SetCore("ChatMakeSystemMessage", {
		Text = generalMessage,
		Color = env.config.teams[player.Team.Name].color.Value,
	})
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
genesUtil.initGene(env.src.genes.player.counselor)

-- Send system message on changed
genesUtil.observeStateValue(genes.player.counselor, "isCounselor")
	:filter(dart.select(2))
	:subscribe(shoutCounselor)
