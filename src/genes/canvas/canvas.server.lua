--
--	Jackson Munsell
--	04 Sep 2020
--	canvas.server.lua
--
--	Canvas server functionality
--

-- env
local Players = game:GetService("Players")
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

-- Remove owners when the player leaves
rx.Observable.from(Players.PlayerRemoving):flatMap(function (player)
	return rx.Observable.from(genesUtil.getInstances(canvas))
		:filter(function (canvasInstance)
			return canvasInstance.state.canvas.owner.Value == player
		end)
end):subscribe(function (canvasInstance)
	wipeCanvas(canvasInstance)
	canvasUtil.setCanvasOwner(canvasInstance, nil)
end)

-- Connect to name gui display and wipe on init
canvases:subscribe(connectOwnerDisplay)
canvases:subscribe(wipeCanvas)

-- Connect to client ownership request
rx.Observable.from(canvas.net.CanvasOwnershipRequested.OnServerEvent)
	:reject(function (p, c) return canvasUtil.getPlayerCanvasInGroup(p, c.Parent) end)
	:map(function (p, c) return c, p end)
	:subscribe(canvasUtil.setCanvasOwner)

-- Connect to client change request
rx.Observable.from(canvas.net.CanvasChangeRequested.OnServerEvent)
	:filter(function (client, canvasInstance, _)
		return canvasInstance.config.canvas.collaborative.Value
		or canvasInstance.state.canvas.owner.Value == client
	end)
	:map(dart.drop(1))
	:subscribe(canvasUtil.changeCanvas)
