--
--	Jackson Munsell
--	08 Oct 2020
--	actions.client.lua
--
--	Actions gui client driver
--

-- env
local UserInputService = game:GetService("UserInputService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local ragdoll = env.src.character.ragdoll
local pickup = genes.pickup
local actions = env.src.gui.core.actions

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local glib = require(axis.lib.glib)
local tableau = require(axis.lib.tableau)
local genesUtil = require(genes.util)
local pickupStreams = require(pickup.streams)
local pickupUtil = require(pickup.util)
local actionsConfig = require(actions.config)

---------------------------------------------------------------------------------------------------
-- References
---------------------------------------------------------------------------------------------------

-- Tag instances and seeds
local Core = env.PlayerGui:WaitForChild("Core")
local actionsContainer = Core.Container.ActionContainer.Actions
local diveFrame = Core.Container.Dive
local seeds = Core.seeds

-- Images
local ButtonPlain = "http://www.roblox.com/asset/?id=5624604424"
local ButtonEquipped = "http://www.roblox.com/asset/?id=5820907301"

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Is object equipped
local function isObjectEquipped(object)
	return object and object:IsDescendantOf(workspace)
end

-- Toggle equipped
local function toggleEquipped(object)
	pickup.net.ToggleEquipRequested:FireServer(object)
end

-- Render button based on object parentage (show green circle if equipped)
local function renderButtonHotkey(button, index)
	button.Hotkey.TextLabel.Text = index
end
local function renderButtonEquipped(button)
	local object = button.state.object.Value
	button.Button.Image = (isObjectEquipped(object) and ButtonEquipped or ButtonPlain)
end

-- Create button for object
local function createButtonForObject(object)
	-- Clone button
	local button = seeds.actions.ActionModule:Clone()
	button.Icon.Image = object.config.pickup.buttonImage.Value
	button.Icon.ImageColor3 = object.config.pickup.buttonColor.Value
	button.Visible = true
	button.Hotkey.Visible = UserInputService.KeyboardEnabled

	-- Create state
	tableau.tableToValueObjects("state", {
		object = object,
	}).Parent = button

	-- Connect to button activated to trigger
	local terminator = rx.Observable.fromInstanceLeftGame(button)
	rx.Observable.from(button.Button.Activated)
		:map(dart.constant(object))
		:takeUntil(terminator)
		:subscribe(toggleEquipped)
	rx.Observable.from(object.AncestryChanged)
		:startWith(object.Parent)
		:takeUntil(terminator)
		:subscribe(dart.bind(renderButtonEquipped, button))

	-- Parent to container
	button.Parent = actionsContainer

	-- return button
	return button
end

-- Get object gui
local function getObjectGui(object)
	return tableau.fromLayoutContents(actionsContainer)
		:first(function (guiObject)
			return guiObject.state.object.Value == object
		end)
end

-- Render layout
-- 	NEW for generic pickups
local function renderLayout(ownedObjects)
	-- Create new action modules for all owned objects
	tableau.from(ownedObjects)
		:reject(getObjectGui)
		:foreach(createButtonForObject)

	-- Destroy all action modules that we no longer own
	tableau.from(actionsContainer:GetChildren())
		:filter(dart.isa("GuiObject"))
		:filter(function (action)
			return not action.state.object.Value
			or not table.find(ownedObjects, action.state.object.Value)
		end)
		:foreach(dart.destroy)

	-- Set hotkey text
	tableau.fromLayoutContents(actionsContainer)
		:foreachi(renderButtonHotkey)
end

---------------------------------------------------------------------------------------------------
-- Streams and subscriptions
---------------------------------------------------------------------------------------------------

-- Disable default backpack gui
game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

-- Recompute scrolling frame size when the list layout size changes
-- local layout = actionsContainer:FindFirstChildWhichIsA("UIListLayout")
-- rx.Observable.fromProperty(layout, "AbsoluteContentSize")
-- 	:subscribe(setScrollingFrameSize)

-- Clear layout contents to begin
-- 	(eliminates the display testing actions)
glib.clearLayoutContents(actionsContainer)

-- Dive on press or hotkey
genesUtil.waitForGene(diveFrame.Button, genes.guiButton)
diveFrame.Hotkey.TextLabel.Text = string.sub(tostring(actionsConfig.diveHotkey), -1)
rx.Observable.from(diveFrame.Button.interface.guiButton.Activated)
	:merge(rx.Observable.from(actionsConfig.diveHotkey)
		:filter(dart.equals(Enum.UserInputState.Begin)))
	:subscribe(function ()
		ragdoll.interface.tryDive:Invoke()
	end)

-- Switch selected index on right or left bumpers
local function buttonShift(button, shift)
	return rx.Observable.from(button):filter(dart.equals(Enum.UserInputState.Begin))
		:map(dart.constant(shift))
end
buttonShift(Enum.KeyCode.ButtonR1, 1)
	:merge(buttonShift(Enum.KeyCode.ButtonL1, -1))
	:subscribe(function (shift)
		local owned = pickupStreams.ownedObjects:getValue()
		local held = pickupUtil.getLocalCharacterHeldObjects():first()
		local index = table.find(owned, held)
		local shifted
		if index then
			shifted = index + shift
			if shifted < 1 or shifted > #owned then
				shifted = index
			end
		else
			shifted = (shift == 1 and 1 or #owned)
		end
		toggleEquipped(owned[shifted])
	end)

-- Set hotkey visible to not gamepad image visible (which is automatic)
rx.Observable.fromProperty(diveFrame.Button.GamepadButtonImage, "Visible", true)
	:map(dart.boolNot)
	:subscribe(function (v)
		diveFrame.Hotkey.Visible = v
	end)

-- Update on subject change
pickupStreams.ownedObjects:subscribe(renderLayout)
