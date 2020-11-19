--
--	Jackson Munsell
--	19 Nov 2020
--	chat.client.lua
--
--	chat player gene client driver
--

-- env
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function renderChatBubble(billboard)
	local player = Players:GetPlayerFromCharacter(billboard.Adornee.Parent)
	if not player then return end

	local color = player.state.chat.color
	local function setColor(instance)
		instance.ImageColor3 = color.Value
	end
	rx.Observable.fromInstanceEvent(billboard, "DescendantAdded")
		:startWithTable(billboard:GetDescendants())
		:filter(dart.isa("ImageLabel"))
		:subscribe(setColor)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
genesUtil.initGene(genes.player.chat)

-- When a bubble chat gets added, set the color according to the player's chat color
rx.Observable.from(env.PlayerGui:WaitForChild("BubbleChat").ChildAdded):subscribe(renderChatBubble)
