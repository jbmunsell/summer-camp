--
--	Jackson Munsell
--	23 Nov 2020
--	textConfigure.client.lua
--
--	textConfigure gene client driver
--

-- env
local UserInputService = game:GetService("UserInputService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local pickupUtil = require(genes.pickup.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local gui = env.PlayerGui:WaitForChild("Core").Container.TextConfigure
local textInput = gui:FindFirstChildWhichIsA("TextBox", true)

-- Set initial text according to input type
do
	local initText = string.format("%s to edit text.", (UserInputService.TouchEnabled and "Touch" or "Click"))
	textInput.Text = initText
end

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function setGuiEnabled(enabled)
	gui.Visible = enabled
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.textConfigure)

-- When a player equips an object, show the gui
local holdingStream = pickupUtil.getLocalCharacterHoldingStream(genes.textConfigure)
holdingStream:map(dart.boolify):subscribe(setGuiEnabled)

-- When the gui is changed, send data to server
rx.Observable.from(textInput.FocusLost)
	:map(function () return textInput.Text end)
	:distinctUntilChanged()
	:map(function (text)
		return pickupUtil.localCharacterHoldsObject(genes.textConfigure), text
	end)
	:filter()
	:merge(holdingStream:filter():map(function (instance)
		return instance, textInput.Text
	end))
	:subscribe(dart.forward(genes.textConfigure.net.ConfigureRequested))

