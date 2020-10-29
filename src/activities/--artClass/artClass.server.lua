--
--	Jackson Munsell
--	03 Sep 2020
--	ArtClass.lua
--
--	Art class server activity component
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local objects = env.src.objects
local activities = env.src.activities

-- modules
local rx   = require(axis.lib.rx)
local fx   = require(axis.lib.fx)
local dart = require(axis.lib.dart)
local activitiesUtil = require(activities.util)
local canvasUtil     = require(objects.canvas.util)
local canvasConfig   = require(objects.canvas.config)
local artClassConfig = require(activities.artClass.config)

-- Create canvas objects within an art class environment
local function createCanvasObjects(activityInstance)
	for _, marker in pairs(activityInstance.functional["canvas-markers"]:GetChildren()) do
		local canvas = env.res.objects.Canvas:Clone()
		fx.placeModelOnGroundAtPoint(canvas, marker.CFrame)
		canvas.Parent = activityInstance.functional.canvases
		env.CollectionService:AddTag(canvas, canvasConfig.instanceTag)
	end
end

-- Constructor
local function createArtClass(activityInstance)
	-- Create object
	local artClass = activitiesUtil.createActivityFromInstance(activityInstance, artClassConfig)

	-- Create canvases
	createCanvasObjects(activityInstance)

	-- Clear canvases on session start
	local function flatMapCanvases(stream)
		return stream
			:flatMap(function (...)
				return rx.Observable.from(activityInstance.functional.canvases:GetChildren())
					:map(dart.drag(...))
			end)
	end
	flatMapCanvases(artClass.sessionStreams.start):subscribe(function (canvas, cabinTeam)
		canvasUtil.clearCanvas(canvas)
		canvas.state.teamToAcceptFrom.Value = cabinTeam
		canvas.state.locked.Value = false
	end)
	flatMapCanvases(artClass.sessionStreams.stop):subscribe(function (canvas)
		canvas.state.owner.Value = nil
		canvas.state.locked.Value = true
	end)
end
-- Currently there is no activity destruction since they stick around for the whole server lifetime

-- Bind to tag
rx.Observable.fromInstanceTag(artClassConfig.instanceTag)
	:subscribe(createArtClass)
