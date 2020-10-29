--
--	Jackson Munsell
--	04 Sep 2020
--	canvasUtil.lua
--
--	Canvas object shared functionality
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local objects = env.src.objects
local canvas = objects.canvas

-- modules
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local objectsUtil = require(objects.util)

-- Get cell from index
local function getCellFromIndex(canvasInstance, cellIndex)
	return canvasInstance.CanvasPart.SurfaceGui.CanvasFrame:FindFirstChild(cellIndex)
end

-- Change canvas
local function changeCanvas(canvasInstance, change)
	-- Push change to desired cell on canvas
	local cell = getCellFromIndex(canvasInstance, change.cellIndex)
	if cell then
		cell.BackgroundColor3 = change.color
	end
end

-- Clear canvas
local function clearCanvas(canvasInstance)
	tableau.from(canvasInstance.CanvasPart.SurfaceGui.CanvasFrame:GetChildren())
		:filter(dart.isa("Frame"))
		:foreach(function (cell)
			cell.BackgroundColor3 = Color3.new(1, 1, 1)
		end)
end

-- Get player canvas
local function getPlayerCanvas(player)
	local function playerIsOwner(canvasInstance)
		return canvasInstance.state.canvas.owner.Value == player
	end
	return objectsUtil.getObjects(canvas)
		:first(playerIsOwner)
end

-- lib
return {
	changeCanvas = changeCanvas,
	getCellFromIndex = getCellFromIndex,
	clearCanvas = clearCanvas,
	getPlayerCanvas = getPlayerCanvas,
}
