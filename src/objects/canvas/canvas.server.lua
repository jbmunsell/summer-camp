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
local objects = env.src.objects
local canvas = objects.canvas

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local canvasUtil = require(canvas.util)
local objectsUtil = require(objects.util)

-- init canvas
local function initCanvas(instance)
	-- Create streams
	rx.Observable.from(instance.state.canvas.owner)
		:map(function (owner)
			return owner and string.format("%s's canvas", owner.Name) or ""
		end)
		:subscribe(function (text)
			instance.CanvasPart.NameGui.NameLabel.Text = text
		end)
end

-- Canvas state manipulators
local function grantCanvasOwnership(client, canvasInstance)
	canvasInstance.state.canvas.owner.Value = client
end

-- init all canvases forever
local canvasStream = objectsUtil.initObjectClass(canvas)
canvasStream:subscribe(initCanvas)

-- Connect to client requests
rx.Observable.from(canvas.net.CanvasOwnershipRequested.OnServerEvent)
	:filter(function (client, canvasInstance)
		local team = canvasInstance.state.canvas.teamToAcceptFrom.Value
		local teamGood = (not team) or (team == client.Team)
		local hasAlready = canvasUtil.getPlayerCanvas(client)
		return teamGood and not hasAlready
	end)
	:subscribe(grantCanvasOwnership)
rx.Observable.from(canvas.net.CanvasChangeRequested.OnServerEvent)
	:filter(function (client, canvasInstance, _)
		return canvasInstance.state.canvas.owner.Value == client
	end)
	:map(dart.omitFirst)
	:subscribe(canvasUtil.changeCanvas)
