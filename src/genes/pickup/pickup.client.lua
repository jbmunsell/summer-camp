--
--	Jackson Munsell
--	16 Oct 2020
--	pickup.client.lua
--
--	Client pickup driver. Tweens as well as server for smoothiness
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local input = env.src.input
local genes = env.src.genes
local pickup = genes.pickup

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local pickupUtil = require(pickup.util)
local pickupStreams = require(pickup.streams)
local inputUtil = require(input.util)
local genesUtil = require(genes.util)
local inputStreams = require(input.streams)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
genesUtil.initGene(pickup)

-- Play equip on equip
-- 	The server does this exact same thing, but it also tells the clients
-- 	and has the clients perform the functionality as well. This way the clients
-- 	each tween the object and get a nice smooth equip animation
rx.Observable.from(pickup.net.ObjectEquipped)
	:subscribe(function (character, object)
		pickupUtil.unequipCharacter(character)
		pickupUtil.equip(character, object)
	end)

-- Simple activation pass
local clickWithHeldStream = inputStreams.click
	:map(function ()
		return pickupUtil.getCharacterHeldObjects(env.LocalPlayer.Character):first(),
			inputUtil.getMouseHit()
	end)
clickWithHeldStream:subscribe(dart.forward(pickup.net.ObjectActivated))

-- Drop on backspace
rx.Observable.from(Enum.KeyCode.Backspace)
	:filter(dart.equals(Enum.UserInputState.Begin))
	:subscribe(dart.forward(pickup.net.DropRequested))

-- Unequip on number key pressed
-- 	Bind keys 1 thru 0
local function bindKey(keyName, index)
	rx.Observable.from(Enum.KeyCode[keyName])
		:filter(dart.equals(Enum.UserInputState.Begin))
		:map(function ()
			return pickupStreams.ownedObjects:getValue()[index]
		end)
		:filter()
		:subscribe(dart.forward(pickup.net.ToggleEquipRequested))
end
local keyNames = {
	"One",
	"Two",
	"Three",
	"Four",
	"Five",
	"Six",
	"Seven",
	"Eight",
	"Nine",
	"Zero",
}
tableau.from(keyNames):foreachi(bindKey)
