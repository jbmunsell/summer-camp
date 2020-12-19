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
local axisUtil = require(axis.lib.axisUtil)
local pickupUtil = require(pickup.util)
local pickupStreams = require(pickup.streams)
local inputUtil = require(input.util)
local genesUtil = require(genes.util)
local inputStreams = require(input.streams)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function renderGrip(grip)
	-- grip.C0 = grip.Part0.RightGripAttachment.CFrame * grip.Part1.RightGripAttachment.CFrame
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
genesUtil.initGene(pickup)

-- Track local character held objects
pickupUtil.initHeldObjectTracking()
rx.Observable.from(env.LocalPlayer.CharacterAdded)
	:startWith(env.LocalPlayer.Character)
	:filter()
	:subscribe(pickupUtil.trackCharacterHeldObjects)

-- When local player starts holding an object, tween the grip (if it's not in the workspace)
rx.Observable.from(env.LocalPlayer.CharacterAdded)
	:startWith(env.LocalPlayer.Character)
	:filter()
	:switchMap(function (character)
		return rx.Observable.from(character.ChildAdded)
	end)
	:filter(dart.isNamed("RightGrip"))
	:subscribe(renderGrip)

-- Simple activation pass
local activatedStream = inputStreams.click
	:map(function ()
		return pickupUtil.getCharacterHeldObjects(env.LocalPlayer.Character):first(),
			inputUtil.getMouseHit()
	end)
	:filter()
activatedStream:subscribe(dart.forward(pickup.net.ObjectActivated))
activatedStream:subscribe(function (instance)
	local animation = instance.config.pickup.activationAnimation.Value
	if animation then
		axisUtil.getLocalHumanoid():LoadAnimation(animation):Play()
	end
end)

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
