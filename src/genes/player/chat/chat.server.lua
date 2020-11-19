--
--	Jackson Munsell
--	19 Nov 2020
--	chat.server.lua
--
--	chat player gene server driver
--

-- env
local ServerScriptService = game:GetService("ServerScriptService")
local ChatService = require(ServerScriptService:WaitForChild("ChatServiceRunner").ChatService)
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local genesUtil = require(genes.util)
local playerUtil = require(genes.player.util)
local pickupUtil = require(genes.pickup.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local White = Color3.new(1, 1, 1)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function updateChatColor(player)
	-- Get character
	local character = player.Character
	if not character then return end

	-- Get held megaphone
	local megaphone = pickupUtil.characterHoldsObject(player.Character, genes.megaphone)
	genesUtil.waitForGene(player, genes.player.chat)
	player.state.chat.color.Value = (megaphone and megaphone.state.color.color.Value or White)
end

local function renderChatColor(player, chatColor)
	local speaker = ChatService:GetSpeaker(player.Name)
	speaker:SetExtraData("ChatColor", chatColor)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
playerUtil.hardInitPlayerGene(genes.player.chat)

-- Update on changed
genesUtil.observeStateValue(genes.player.chat, "color"):subscribe(renderChatColor)

-- Connect to megaphone holding
genesUtil.crossObserveStateValue(genes.megaphone, genes.pickup, "holder", function (obs)
	return obs:replay(2)
end):flatMap(function (_, old, new)
	old = Players:GetPlayerFromCharacter(old)
	new = Players:GetPlayerFromCharacter(new)
	return rx.Observable.from({ old, new })
end):filter():delay(0):subscribe(updateChatColor)
