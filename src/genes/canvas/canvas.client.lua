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
local multiswitch = genes.multiswitch
local canvas = genes.canvas
local input = env.src.input

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local canvasUtil = require(canvas.util)
local multiswitchUtil = require(multiswitch.util)
local inputUtil = require(input.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Paint canvas cell
-- 	(and submit change request to server)
local function changeCanvas(canvasInstance, change)
	canvasUtil.changeCanvas(canvasInstance, change)
	canvas.net.CanvasChangeRequested:FireServer(canvasInstance, change)
end

-- Claim a canvas for ourselves
local function claimCanvas(canvasInstance)
	-- Set owner to local player
	canvasInstance.state.canvas.owner.Value = env.LocalPlayer
	canvas.net.CanvasOwnershipRequested:FireServer(canvasInstance)
end

-- Connect drawing input
local function connectDrawingInput(canvasInstance)
	-- instances
	local toolsContainer = canvasInstance.Tools.SurfaceGui.Container

	-- Create terminator stream
	local stoppedEditing = rx.Observable.from(canvasInstance.state.canvas.editing.Changed)
		:reject()
		:merge(rx.Observable.from(canvasInstance.state.canvas.owner.Changed))
	local terminator = rx.Observable.fromInstanceLeftGame(canvasInstance)
		:merge(stoppedEditing)
		:first()

	-- Share until operator
	local function shareUntil(o)
		return o:takeUntil(terminator):share()
	end

	-- Create mouse hit stream
	local mouseRaycastStream = rx.Observable.heartbeat()
		:map(dart.constant(nil))
		:map(inputUtil.raycastMouse)
		:pipe(shareUntil)
	local function isMouse(inputObject)
		return inputObject.UserInputType == Enum.UserInputType.Touch
		or inputObject.UserInputType == Enum.UserInputType.MouseButton1
	end
	local mouseStateStream = rx.Observable.from(UserInputService.InputBegan)
		:filter(isMouse)
		:map(dart.constant(true))
		:merge(rx.Observable.from(UserInputService.InputEnded):filter(isMouse):map(dart.constant(false)))
		:takeUntil(terminator)
		:multicast(rx.BehaviorSubject.new())

	-- Is accepting input
	local isAcceptingInput = mouseStateStream:filter()
		:withLatestFrom(mouseRaycastStream)
		:map(dart.select(2))
		:map(dart.bind(canvasUtil.getCellIndexFromRaycastResult, canvasInstance))
		:map(dart.boolify)
		:merge(mouseStateStream:reject())
		:takeUntil(terminator)
		:multicast(rx.BehaviorSubject.new())

	-- Stream for user clicking on a unique canvas cell
	local canvasInteractStream = mouseRaycastStream
		:filter(function ()
			return mouseStateStream:getValue() and isAcceptingInput:getValue()
		end)
		-- :filter(function ()
		-- 	return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
		-- end)
		:map(dart.bind(canvasUtil.getCellIndexFromRaycastResult, canvasInstance))
		:distinctUntilChanged()
		:filter()
		:pipe(shareUntil)

	-- Stream for the currently selected tool
	local activeTool = rx.BehaviorSubject.new("Brush")

	-- Switch tool on button clicks
	rx.Observable.from(toolsContainer:GetChildren())
		:filter(dart.isa("GuiButton"))
		:flatMap(function (button)
			return rx.Observable.from(button.Activated)
				:map(dart.constant(button.Name))
		end)
		:takeUntil(terminator)
		:multicast(activeTool)

	-- Get a stream for a specific tool interacting with the canvas
	local function getToolInteractStream(toolName)
		return canvasInteractStream
			:filter(function ()
				return toolName == activeTool:getValue()
			end)
	end

	-- Switch tool on color picker canvas interact
	local colorPickedStream = getToolInteractStream("ColorPicker")
		:map(function (cellIndex)
			return canvasUtil.getCellFromIndex(canvasInstance, cellIndex).BackgroundColor3
		end)
		:pipe(shareUntil)
	colorPickedStream
		:map(dart.constant("Brush"))
		:takeUntil(terminator)
		:multicast(activeTool)

	-- Stream for adjusting the sliders
	local function mapInputEventToConstant(event, constant)
		return rx.Observable.from(event)
			:filter(function (inputObject, processed)
				return not processed and (inputObject.UserInputType == Enum.UserInputType.MouseButton1
					or inputObject.UserInputType == Enum.UserInputType.Touch)
			end)
			:map(dart.constant(constant))
	end
	local function createSliderManipulationStream(slider, hsvSelector, initialValue)
		-- Tag part real quick
		local colorSelectorPart = canvasInstance.ColorSelector

		-- Create stream to indicate grab state
		local sliderDownStream = mapInputEventToConstant(slider.Circle.InputBegan, true)
		local sliderUpStream = mapInputEventToConstant(UserInputService.InputEnded, false)
		local sliderGrabbedStream = sliderDownStream:merge(sliderUpStream)

		-- return a stream that emits the place from 0 to 1 along the slider that the cursor is at
		return mouseRaycastStream
			:filter(function (result) return result and result.Instance == colorSelectorPart end)
			:withLatestFrom(sliderGrabbedStream)
			:filter(function (_, grabbed) return grabbed end)
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
			:merge(colorPickedStream:map(function (c)
				return table.pack(c:ToHSV())[hsvSelector]
			end))
			:pipe(shareUntil)
			:startWith(initialValue)
	end
	local sliders = canvasInstance.ColorSelector.SurfaceGui.Sliders
	local hueAdjustedStream = createSliderManipulationStream(sliders.Hue, 1, 1)
	local satAdjustedStream = createSliderManipulationStream(sliders.Saturation, 2, 1)
	local valAdjustedStream = createSliderManipulationStream(sliders.Brightness, 3, 1)

	-- Stream for whether tool buttons should be active
	local toolButtonActiveStream = activeTool
		:flatMap(function (toolName)
			return rx.Observable.from(toolsContainer:GetChildren())
				:filter(dart.isa("GuiObject"))
				:map(function (button) return button, button.Name == toolName end)
		end)

	-- Color changing streams
	local colorChangedStream = hueAdjustedStream
		:combineLatest(satAdjustedStream, valAdjustedStream, Color3.fromHSV)
		:pipe(shareUntil)

	-- Paint application stream and erase stream
	-- Erase stream is just a stream that applies white color to target cell
	local eraseStream = getToolInteractStream("Eraser")
		:map(function (cellIndex)
			return {
				cellIndex = cellIndex,
				transparency = 1,
			}
		end)
		:pipe(shareUntil)
	local paintStream = getToolInteractStream("Brush")
		:withLatestFrom(colorChangedStream)
		:map(function (cellIndex, color)
			return {
				cellIndex = cellIndex,
				color = color,
			}
		end)
		:pipe(shareUntil)

	-- Subscriptions
	local function subscribe(stream, f)
		return stream:takeUntil(terminator):subscribe(f)
	end

	-- Highlight active tool when changed
	subscribe(toolButtonActiveStream:map(dart.carry(canvasInstance)), canvasUtil.setToolButtonHighlighted)

	-- 	Paint and erase
	subscribe(paintStream:merge(eraseStream):map(dart.carry(canvasInstance)), changeCanvas)

	-- Update color display on color changed
	subscribe(colorChangedStream, dart.bind(canvasUtil.updateCanvasColorDisplay, canvasInstance))
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Canvas instance stream
local canvases = genesUtil.initGene(canvas)

-- Player owns canvas in group stream
local function getPlayerOwnsCanvasInGroupStream(group)
	return rx.Observable.from(group:GetChildren())
		:filter(dart.follow(genesUtil.hasGeneTag, genes.canvas))
		:flatMap(function (instance)
			return rx.Observable.from(instance.state.canvas.owner)
		end)
		:map(dart.bind(canvasUtil.getPlayerCanvasInGroup, env.LocalPlayer, group))
		:map(dart.boolify) -- push through nil values as false (otherwise stream won't fire)
		:distinctUntilChanged()
end

-- Bind interact switch
canvases
	:flatMap(function (instance)
		local stream
		if instance.config.canvas.collaborative.Value then
			stream = rx.Observable.just(false)
		else
			local ownerStream = rx.Observable.from(instance.state.canvas.owner)
			stream = ownerStream
				:map(dart.boolNot)
				:combineLatest(getPlayerOwnsCanvasInGroupStream(instance.Parent):map(dart.boolNot), dart.boolAll)
		end
		return stream:map(dart.carry(instance, "interact", "canvas"))
	end)
	:subscribe(multiswitchUtil.setSwitchEnabled)

-- Bind author gui rendering
local canvasObtained = canvases
	:flatMap(function (instance)
		return rx.Observable.from(instance.state.canvas.owner)
			:map(dart.equals(env.LocalPlayer))
			:map(dart.carry(instance))
	end)

-- Claim ownership on interact (another stream will connect on owner changed)
rx.Observable.from(interact.interface.ClientInteracted.Event)
	:filter(dart.follow(genesUtil.hasGeneTag, canvas))
	:subscribe(claimCanvas)

-- When a noncollaborative canvas sets US as the owner,
-- 	OR a collaborative canvas comes within range,
-- 	connect tools
local collaborativeInRange = canvases
	:filter(function (instance)
		return instance.config.canvas.collaborative.Value
	end)
	:flatMap(function (instance)
		local canvasPartPosition = instance:FindFirstChild("CanvasPart", true).Position
		local drawingDistance = instance.config.canvas.drawingDistance.Value
		return rx.Observable.heartbeat()
			:map(function ()
				local d = env.LocalPlayer:DistanceFromCharacter(canvasPartPosition)
				return d ~= 0 and d <= drawingDistance
			end)
			:distinctUntilChanged()
			:map(dart.carry(instance))
	end)
collaborativeInRange
	:merge(canvasObtained:map(dart.drag(true)))
	:subscribe(canvasUtil.setEditing)

-- Set tool visibility according to editing value
local editingCanvas = canvases
	:flatMap(function (instance)
		return rx.Observable.from(instance.state.canvas.editing)
			:map(dart.carry(instance))
	end)
editingCanvas:subscribe(canvasUtil.setToolsVisible)

-- Connect drawing input when we are editing
editingCanvas
	:filter(dart.select(2))
	:map(dart.select(1))
	:subscribe(connectDrawingInput)
