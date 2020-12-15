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
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
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

local function setPlayerChatColor(player, color)
	genesUtil.waitForGene(player, genes.player.chat)
	player.state.chat.color.Value = color
end

local function renderChatColor(player)
	local speaker = ChatService:GetSpeaker(player.Name)
	speaker:SetExtraData("ChatColor", player.state.chat.color.Value)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
playerUtil.initPlayerGene(genes.player.chat)

-- Update on changed
genesUtil.observeStateValue(genes.player.chat, "color")
	:filter(function (player)
		return ChatService:GetSpeaker(player.Name)
	end)
	:merge(rx.Observable.from(ChatService.SpeakerAdded)
		:map(function (speakerName)
			local player = Players:FindFirstChild(speakerName)
			return player and genesUtil.hasFullState(player, genes.player.chat) and player
		end)
		:filter())
	:subscribe(renderChatColor)

-- Connect to megaphone holding
axisUtil.getPlayerCharacterStream():flatMap(function (player, character)
	return pickupUtil.getCharacterHeldObjectsStream(character):switchMap(function ()
		local megaphone = pickupUtil.characterHoldsObject(character, genes.megaphone)
		return megaphone
		and rx.Observable.from(megaphone.state.color.color)
		or rx.Observable.just(White)
	end):map(dart.carry(player))
end):subscribe(setPlayerChatColor)
