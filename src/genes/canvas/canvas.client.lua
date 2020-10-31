--
--	Jackson Munsell
--	04 Sep 2020
--	canvas.client.lua
--
--	Canvas client functionality
--

-- env
local UserInputService = game:GetService("UserInputService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local interact = genes.interact
local canvas = genes.canvas
local input = env.src.input

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local canvasUtil = require(canvas.util)
local interactUtil = require(interact.util)
local inputUtil = require(input.util)

-- Consts
local White = Color3.new(1, 1, 1)

-- Streams
local playerOwnsAnyCanvasStream = genesUtil.getInstanceStream(canvas)
	:flatMap(function (canvasInstance)
		return rx.Observable.from(canvasInstance.AncestryChanged)
			:filter(function () return not canvasInstance:IsDescendantOf(game) end)
			:merge(rx.Observable.from(canvasInstance.state.canvas.owner))
	end)
	:map(dart.bind(canvasUtil.getPlayerCanvas, env.LocalPlayer))
	:map(dart.boolify)
	:distinctUntilChanged()
	:startWith(false)

-- Slider functions
local function setSliderPosition(slider, position)
	slider.Circle.Position = UDim2.new(position, 0, 0.5, 0)
end

-- Set tool button highlighted
local function setToolButtonHighlighted(canvasInstance, button, highlighted)
	button.ImageColor3 = (highlighted
		and genesUtil.getConfig(canvasInstance).canvas.activeToolHighlightColor
		or White)
end

-- Set author gui visible
local function setCanvasAuthorGuiVisible(canvasInstance, visible)
	canvasInstance.ColorSelector.SurfaceGui.Enabled = visible
	canvasInstance.Tools.SurfaceGui.Enabled = visible
end

-- Update canvas color display
local function updateCanvasColorDisplay(canvasInstance, color)
	-- Set current color display
	local colorSelectorGui = canvasInstance.ColorSelector.SurfaceGui
	local sliders = colorSelectorGui.Sliders
	colorSelectorGui.CurrentColorDisplay.Center.ImageColor3 = color

	-- Set individual slider positions
	local h, s, v = color:ToHSV()
	setSliderPosition(sliders.Hue, h)
	setSliderPosition(sliders.Saturation, s)
	setSliderPosition(sliders.Brightness, v)

	-- Set each slider's gradient
	sliders.Saturation.UIGradient.Color = ColorSequence.new(Color3.fromHSV(h, 0, v), Color3.fromHSV(h, 1, v))
	sliders.Brightness.UIGradient.Color = ColorSequence.new(Color3.fromHSV(h, s, 0), Color3.fromHSV(h, s, 1))
end

-- init canvas
local function initCanvas(instance)
	-- Create streams from state values
	local ownerChanged = rx.Observable.from(instance.state.canvas.owner)
	local teamChanged = rx.Observable.from(instance.state.canvas.teamToAcceptFrom)
	local lockedChanged = rx.Observable.from(instance.state.canvas.locked)
	local interactableStream = ownerChanged:combineLatest(teamChanged, lockedChanged, playerOwnsAnyCanvasStream,
		function (owner, team, locked, playerOwns)
			return (not locked)
			and (not team or team == env.LocalPlayer.Team)
			and (not owner)
			and (not playerOwns)
		end)
		:map(dart.carry(instance))

	-- Set interact enabled according to ownership
	interactableStream:subscribe(interactUtil.setInteractEnabled)
	ownerChanged
		:map(function (player)
			return instance, (player == env.LocalPlayer)
		end)
		:subscribe(setCanvasAuthorGuiVisible)
end

-- Get canvas cell from mouse location
local function getCanvasCellIndexFromMouse(canvasInstance)
	-- Assert hit
	local raycastResult = inputUtil.raycastMouse()
	if not raycastResult
	or raycastResult.Instance ~= canvasInstance.CanvasPart
	then return nil end

	-- Get index from position
	local canvasPartSize = canvasInstance.CanvasPart.Size
	local canvasFrame = canvasInstance.CanvasPart.SurfaceGui.CanvasFrame
	local cellCount = canvasFrame.UIGridLayout.AbsoluteCellCount
	local offset = canvasInstance.CanvasPart.CFrame:toObjectSpace(CFrame.new(raycastResult.Position)).p + (canvasPartSize * 0.5)
	local cellCoordinates = Vector2.new(
		math.floor((offset.X / canvasPartSize.X) * cellCount.X),
		math.floor((1 - offset.Y / canvasPartSize.Y) * cellCount.Y)
	)
	return cellCoordinates.X + cellCoordinates.Y * cellCount.X
end

-- Paint canvas cell
-- 	(and submit change request to server)
local function changeCanvas(canvasInstance, change)
	canvasUtil.changeCanvas(canvasInstance, change)
	canvas.net.CanvasChangeRequested:FireServer(canvasInstance, change)
end

-- Claim a canvas for ourselves
local function claimCanvas(canvasInstance)
	-- instances
	local toolsContainer = canvasInstance.Tools.SurfaceGui.Container

	-- Set owner to local player
	canvasInstance.state.canvas.owner.Value = env.LocalPlayer
	canvas.net.CanvasOwnershipRequested:FireServer(canvasInstance)

	-- Create terminator stream
	local ownershipLost = rx.Observable.from(canvasInstance.state.canvas.owner.Changed)
		:reject() -- pass through only falsy values
	local terminator = rx.Observable.fromInstanceLeftGame(canvasInstance)
		:merge(ownershipLost)

	-- Stream for adjusting the sliders
	local function mapInputEventToConstant(event, constant)
		return rx.Observable.from(event)
			:filter(function (inputObject, processed)
				return not processed and inputObject.UserInputType == Enum.UserInputType.MouseButton1
			end)
			:map(dart.constant(constant))
	end
	local function createSliderManipulationStream(slider, initialValue)
		-- Tag part real quick
		local colorSelectorPart = canvasInstance.ColorSelector

		-- Create stream to indicate grab state
		local sliderDownStream = mapInputEventToConstant(slider.Circle.InputBegan, true)
		local sliderUpStream = mapInputEventToConstant(UserInputService.InputEnded, false)
		local sliderGrabbedStream = sliderDownStream:merge(sliderUpStream)

		-- return a stream that emits the place from 0 to 1 along the slider that the cursor is at
		return rx.Observable.heartbeat()
			:withLatestFrom(sliderGrabbedStream)
			:filter(function (_, grabbed) return grabbed end)
			:map(dart.constant(nil))
			:map(inputUtil.raycastMouse)
			:filter(function (result) return result.Instance == colorSelectorPart end)
			:map(function (result)
				-- NOTE: These calculations currently rely on the slider's container frame having an X size of 1,
				-- 	and the slider itself being aligned by its center within the container frame,
				-- 	and the slider itself only using size scale, NOT offset scale
				local offset = colorSelectorPart.CFrame:toObjectSpace(CFrame.new(result.Position)).p
				local partX = offset.X + colorSelectorPart.Size.X * 0.5
				local guiStartX = (1 - slider.Size.X.Scale) * 0.5 * colorSelectorPart.Size.X
				local guiSizeX  = slider.Size.X.Scale * colorSelectorPart.Size.X
				local guiProportion = (partX - guiStartX) / guiSizeX
				return math.max(0, math.min(1, guiProportion))
			end)
			:startWith(initialValue)
	end
	local sliders = canvasInstance.ColorSelector.SurfaceGui.Sliders
	local hueAdjustedStream = createSliderManipulationStream(sliders.Hue, 1)
	local satAdjustedStream = createSliderManipulationStream(sliders.Saturation, 1)
	local valAdjustedStream = createSliderManipulationStream(sliders.Brightness, 1)

	-- Stream for user clicking on a unique canvas cell
	local canvasInteractStream = rx.Observable.heartbeat()
		:filter(function ()
			return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
		end)
		:map(dart.bind(getCanvasCellIndexFromMouse, canvasInstance))
		:distinctUntilChanged()
		:filter()

	-- Stream for the currently selected tool
	local activeTool = rx.BehaviorSubject.new("Brush")

	-- Switch tool on button clicks
	rx.Observable.from(toolsContainer:GetChildren())
		:filter(dart.isa("GuiButton"))
		:flatMap(function (button)
			return rx.Observable.from(button.Activated)
				:map(dart.constant(button.Name))
		end)
		:multicast(activeTool)

	-- Switch tool on color picker canvas interact
	canvasInteractStream
		:filter(function () return activeTool:getValue() == "ColorPicker" end)
		:map(dart.constant("Brush"))
		:multicast(activeTool)

	-- Stream for whether tool buttons should be active
	local toolButtonActiveStream = activeTool
		:flatMap(function (toolName)
			return rx.Observable.from(toolsContainer:GetChildren())
				:filter(dart.isa("GuiObject"))
				:map(function (button) return button, button.Name == toolName end)
		end)

	-- Get a stream for a specific tool interacting with the canvas
	local function getToolInteractStream(toolName)
		return canvasInteractStream
			:filter(function ()
				return toolName == activeTool:getValue()
			end)
	end

	-- Color changing streams
	local colorChangedStream = getToolInteractStream("ColorPicker")
		:map(function (cellIndex)
			return canvasUtil.getCellFromIndex(canvasInstance, cellIndex).BackgroundColor3
		end)
		:merge(hueAdjustedStream:combineLatest(satAdjustedStream, valAdjustedStream, Color3.fromHSV))

	-- Paint application stream and erase stream
	-- Erase stream is just a stream that applies white color to target cell
	local function toCanvasChange(constantColor)
		return function (cellIndex, color)
			return canvasInstance, { cellIndex = cellIndex, color = constantColor or color }
		end
	end
	local eraseStream = getToolInteractStream("Eraser")
		:map(toCanvasChange(White))
	local paintStream = getToolInteractStream("Brush")
		:withLatestFrom(colorChangedStream)
		:map(toCanvasChange())

	-- Subscriptions
	local function subscribe(stream, f)
		return stream:takeUntil(terminator):subscribe(f)
	end

	-- Highlight active tool when changed
	subscribe(toolButtonActiveStream:map(dart.carry(canvasInstance)), setToolButtonHighlighted)

	-- 	Paint and erase
	subscribe(paintStream:merge(eraseStream), changeCanvas)

	-- Update color display on color changed
	subscribe(colorChangedStream, dart.bind(updateCanvasColorDisplay, canvasInstance))
end

-- Connect to all canvas objects forever
genesUtil.getInstanceStream(canvas)
	:subscribe(initCanvas)

-- Connect to canvas client interaction
rx.Observable.from(interact.interface.ClientInteracted.Event)
	:filter(dart.follow(genesUtil.hasGene, canvas))
	:subscribe(claimCanvas)
