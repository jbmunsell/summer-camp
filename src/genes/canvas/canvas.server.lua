--
--	Jackson Munsell
--	04 Sep 2020
--	canvas.server.lua
--
--	Canvas server functionality
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local canvas = genes.canvas

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local canvasUtil = require(canvas.util)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Connect name gui
local function connectOwnerDisplay(instance)
	-- If we have a name gui then connect to it
	local nameGui = instance:FindFirstChild("NameGui", true)
	if nameGui then
		rx.Observable.from(instance.state.canvas.owner)
			:map(function (owner)
				return owner and string.format("%s's canvas", owner.Name) or ""
			end)
			:subscribe(function (text)
				nameGui.NameLabel.Text = text
			end)
	end
end

-- Wipe canvas
local function wipeCanvas(instance)
	-- Set all the cells to transparent
	tableau.fromLayoutContents(canvasUtil.getCanvasFrame(instance))
		:foreach(function (cell)
			cell.BackgroundTransparency = 1
		end)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init all canvases forever
local canvases = genesUtil.initGene(canvas)

-- Connect to name gui display and wipe on init
canvases:subscribe(connectOwnerDisplay)
canvases:subscribe(wipeCanvas)

-- Connect to client ownership request
rx.Observable.from(canvas.net.CanvasOwnershipRequested.OnServerEvent)
	:reject(canvasUtil.getPlayerCanvas)
	:subscribe(canvasUtil.setCanvasOwner)

-- Connect to client change request
rx.Observable.from(canvas.net.CanvasChangeRequested.OnServerEvent)
	:filter(function (client, canvasInstance, _)
		return canvasInstance.config.canvas.collaborative.Value
		or canvasInstance.state.canvas.owner.Value == client
	end)
	:map(dart.drop(1))
	:subscribe(canvasUtil.changeCanvas)
