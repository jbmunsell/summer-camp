--
--	Jackson Munsell
--	11 Dec 2020
--	guiButton.client.lua
--
--	guiButton gene client driver
--

-- env
local UserInputService = game:GetService("UserInputService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local gamepadImages = env.src.gui.gamepad.images

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Render gamepad button according to button config value
local function renderGamepadButton(instance)
	if not instance:FindFirstChild("GamepadButtonImage") then
		local image = env.res.gui.GamepadButtonImage:Clone()
		image.Parent = instance
	end
	local image = instance.GamepadButtonImage
	local config = instance.config.guiButton
	local dict = require(gamepadImages[config.gamepadButtonImageType.Value])
	local imageData = dict[config.gamepadButton.Value]
	image.Image = dict.image
	image.ImageRectOffset = imageData.offset
	image.ImageRectSize = imageData.size
	local aspect = image:FindFirstChildWhichIsA("UIAspectRatioConstraint")
	if not aspect then
		aspect = Instance.new("UIAspectRatioConstraint", image)
	end
	aspect.AspectRatio = imageData.size.X / imageData.size.Y
end

-- Render gamepad button visible
local function renderGamepadButtonVisible(instance, visible)
	instance:WaitForChild("GamepadButtonImage").Visible = visible
end

-- Bind gamepad button activated
local function bindGamepadButton(instance)
	local button = Enum.KeyCode[instance.config.guiButton.gamepadButton.Value]
	local terminator = rx.Observable.from(instance.state.guiButton.gamepadControlEnabled):reject()
	print("Binding gamepad button " .. instance:GetFullName())
	rx.Observable.from(button, 2001)
		:filter(dart.equals(Enum.UserInputState.Begin))
		:takeUntil(terminator)
		:subscribe(function ()
			instance.interface.guiButton.Activated:Fire()
		end, nil, dart.printConstant("Unbinding gamepad button " .. instance:GetFullName()))
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Gamepad enabled stream
local gamepadEnabledStream = rx.Observable.from(UserInputService.GamepadConnected)
	:merge(rx.Observable.from(UserInputService.GamepadConnected))
	:startWith(0)
	:map(function () return UserInputService.GamepadEnabled end)
	:multicast(rx.BehaviorSubject.new())

-- init gene
local buttons = genesUtil.initGene(genes.guiButton)

-- Observe state value
local controlEnabledStream = genesUtil.observeStateValue(genes.guiButton, "gamepadControlEnabled")

-- Render gamepad button if applicable
buttons:reject(function (instance)
	return instance.config.guiButton.gamepadButton.Value == ""
end):subscribe(renderGamepadButton)

-- Update button display on enabled change
controlEnabledStream:subscribe(renderGamepadButtonVisible)

-- Bind gamepad button on enabled change
controlEnabledStream:filter(dart.select(2)):subscribe(bindGamepadButton)

-- Gamepad control enabled value setting
-- 	Recalculate when ancestry changed
-- 		OR when any ancestors visibility changes
-- 		OR when this instance's active property changes
buttons:flatMap(function (instance)
	return rx.Observable.fromInstanceEvent(instance, "AncestryChanged")
		:startWith(0)
		:switchMap(function ()
			local q = instance
			local observables = {}
			while q and q:IsDescendantOf(game) and q ~= env.PlayerGui do
				if q:IsA("GuiObject") then
					table.insert(observables, rx.Observable.fromProperty(q, "Visible", true))
				elseif q:IsA("ScreenGui") then
					table.insert(observables, rx.Observable.fromProperty(q, "Enabled", true))
				end
				q = q.Parent
			end
			table.insert(observables, rx.Observable.fromProperty(instance, "Active", true))
			table.insert(observables, dart.boolAll)
			return gamepadEnabledStream:combineLatest(unpack(observables))
		end)
		:merge(rx.Observable.fromInstanceLeftGame(instance):map(dart.constant(false)))
		:map(dart.carry(instance))
end):subscribe(function (instance, controlEnabled)
	instance.state.guiButton.gamepadControlEnabled.Value = controlEnabled
end)

-- Pipe all regular activated events to the interface
buttons:flatMap(function (instance)
	return rx.Observable.fromInstanceEvent(instance, "Activated")
		:map(dart.constant(instance))
end):subscribe(function (button)
	button.interface.guiButton.Activated:Fire()
end)
