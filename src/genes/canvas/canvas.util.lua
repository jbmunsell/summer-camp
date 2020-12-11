--
--	Jackson Munsell
--	04 Sep 2020
--	canvasUtil.lua
--
--	Canvas object shared functionality
--

-- env
local RunService = game:GetService("RunService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local input = env.src.input
local genes = env.src.genes
local canvas = genes.canvas

-- modules
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local genesUtil = require(genes.util)
local inputUtil
if RunService:IsClient() then
	inputUtil = require(input.util)
end

-- lib
local canvasUtil = {}
local White = Color3.new(1, 1, 1)

-- Set canvas owner
function canvasUtil.setCanvasOwner(instance, owner)
	instance.state.canvas.owner.Value = owner
end

-- Get canvas frame
function canvasUtil.getCanvasFrame(canvasInstance)
	return canvasInstance:FindFirstChild("CanvasPart", true).SurfaceGui.CanvasFrame
end

-- Get cell from index
function canvasUtil.getCellFromIndex(canvasInstance, cellIndex)
	return canvasUtil.getCanvasFrame(canvasInstance):FindFirstChild(cellIndex)
end

-- Change canvas
function canvasUtil.changeCanvas(canvasInstance, change)
	-- Push change to desired cell on canvas
	local cell = canvasUtil.getCellFromIndex(canvasInstance, change.cellIndex)
	if cell then
		cell.BackgroundColor3 = change.color or White
		cell.BackgroundTransparency = change.transparency or 0
	end
end

-- Clear canvas
function canvasUtil.clearCanvas(canvasInstance)
	tableau.from(canvasUtil.getCanvasFrame(canvasInstance):GetChildren())
		:filter(dart.isa("Frame"))
		:foreach(function (cell)
			cell.BackgroundColor3 = Color3.new(1, 1, 1)
		end)
end

-- Get player canvas
function canvasUtil.getPlayerCanvasInGroup(player, group)
	local function playerIsOwner(canvasInstance)
		return canvasInstance.state.canvas.owner.Value == player
	end
	return genesUtil.getInstances(canvas)
		:filter(dart.isDescendantOf(group))
		:first(playerIsOwner)
end

---------------------------------------------------------------------------------------------------
-- Client functions (mostly)
---------------------------------------------------------------------------------------------------

-- Set a slider's position
function canvasUtil.setSliderPosition(slider, position)
	slider.Circle.Position = UDim2.new(position, 0, 0.5, 0)
end

-- Update canvas hsv color sliders to match provided color
function canvasUtil.updateCanvasColorDisplay(canvasInstance, color)
	-- Set current color display
	local colorSelectorGui = canvasInstance.ColorSelector.SurfaceGui
	local sliders = colorSelectorGui.Sliders
	colorSelectorGui.CurrentColorDisplay.Center.ImageColor3 = color

	-- Set individual slider positions
	local h, s, v = color:ToHSV()
	canvasUtil.setSliderPosition(sliders.Hue, h)
	canvasUtil.setSliderPosition(sliders.Saturation, s)
	canvasUtil.setSliderPosition(sliders.Brightness, v)

	-- Set each slider's gradient
	sliders.Saturation.UIGradient.Color = ColorSequence.new(Color3.fromHSV(h, 0, v), Color3.fromHSV(h, 1, v))
	sliders.Brightness.UIGradient.Color = ColorSequence.new(Color3.fromHSV(h, s, 0), Color3.fromHSV(h, s, 1))
end

-- Set tool button highlighted
function canvasUtil.setToolButtonHighlighted(canvasInstance, button, highlighted)
	button.ImageColor3 = (highlighted
		and canvasInstance.config.canvas.activeToolHighlightColor.Value
		or White)
end

-- Set author gui visible
function canvasUtil.setToolsVisible(canvasInstance, visible)
	canvasInstance.ColorSelector.SurfaceGui.Enabled = visible
	canvasInstance.Tools.SurfaceGui.Enabled = visible
end

-- Set editing
function canvasUtil.setEditing(instance, editing)
	instance.state.canvas.editing.Value = editing
end

-- Get cell index from raycast result
function canvasUtil.getCellIndexFromRaycastResult(canvasInstance, raycastResult)
	-- Assert hit
	local canvasPart = canvasInstance:FindFirstChild("CanvasPart", true)
	if not raycastResult or raycastResult.Instance ~= canvasPart then return nil end

	-- Get index from position
	local canvasPartSize = canvasPart.Size
	local canvasFrame = canvasUtil.getCanvasFrame(canvasInstance)
	local cellCount = canvasFrame.UIGridLayout.AbsoluteCellCount
	local offset = canvasPart.CFrame:toObjectSpace(CFrame.new(raycastResult.Position)).p + (canvasPartSize * 0.5)
	local cellCoordinates = Vector2.new(
		math.floor((offset.X / canvasPartSize.X) * cellCount.X),
		math.floor((1 - offset.Y / canvasPartSize.Y) * cellCount.Y)
	)
	return cellCoordinates.X + cellCoordinates.Y * cellCount.X
end

-- Get canvas cell from mouse location
function canvasUtil.getCanvasCellIndexFromMouse(canvasInstance)
	return canvasUtil.getCellIndexFromRaycastResult(canvasInstance, inputUtil.raycastMouse())
end

-- lib
return canvasUtil
