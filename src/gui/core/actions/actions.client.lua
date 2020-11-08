--
--	Jackson Munsell
--	08 Oct 2020
--	actions.client.lua
--
--	Actions gui client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local ragdoll = env.src.ragdoll
local pickup = genes.pickup
local actions = env.src.gui.core.actions

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local glib = require(axis.lib.glib)
local tableau = require(axis.lib.tableau)
local Bin = require(axis.classes.Bin)
local pickupStreams = require(pickup.streams)
local actionsConfig = require(actions.config)

---------------------------------------------------------------------------------------------------
-- References
---------------------------------------------------------------------------------------------------

-- Tag instances and seeds
local Core = env.PlayerGui:WaitForChild("Core")
local actionsContainer = Core.Container.Actions
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

	-- Create state
	tableau.tableToValueObjects("state", {
		object = object,
	}).Parent = button

	-- Connect to button activated to trigger
	local triggerSub = rx.Observable.from(button.Button.Activated)
		:map(dart.constant(object))
		:subscribe(toggleEquipped)
	local ancestrySub = rx.Observable.from(object.AncestryChanged)
		:startWith(object.Parent)
		:subscribe(dart.bind(renderButtonEquipped, button))

	-- Parent to container
	local bin = Bin.new(triggerSub, ancestrySub)
	rx.Observable.fromInstanceLeftGame(button)
		:subscribe(dart.bind(Bin.destroy, bin))
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
		:foreach(renderButtonHotkey)
end

-- Set scrolling frame size
local function setScrollingFrameSize(pixelSize)
	actionsContainer.CanvasSize = UDim2.new(0, pixelSize.X, 0, pixelSize.Y)
end

---------------------------------------------------------------------------------------------------
-- Streams and subscriptions
---------------------------------------------------------------------------------------------------

-- Disable default backpack gui
game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

-- Recompute scrolling frame size when the list layout size changes
local layout = actionsContainer:FindFirstChildWhichIsA("UIListLayout")
rx.Observable.fromProperty(layout, "AbsoluteContentSize")
	:subscribe(setScrollingFrameSize)

-- Clear layout contents to begin
-- 	(eliminates the display testing actions)
glib.clearLayoutContents(actionsContainer)

-- Dive on press or hotkey
diveFrame.Hotkey.TextLabel.Text = string.sub(tostring(actionsConfig.diveHotkey), -1)
rx.Observable.from(diveFrame.Button.Activated)
	:merge(rx.Observable.from(actionsConfig.diveHotkey))
	:subscribe(function ()
		ragdoll.interface.tryDive:Invoke()
	end)

-- Update on subject change
pickupStreams.ownedObjects:subscribe(renderLayout)
