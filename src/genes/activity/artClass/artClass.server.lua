--
--	Jackson Munsell
--	11 Nov 2020
--	artClass.server.lua
--
--	artClass activity gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local activity = genes.activity
local artClass = activity.artClass
local canvas = genes.canvas

-- modules
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local canvasUtil = require(canvas.util)
local multiswitchUtil = require(genes.multiswitch.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Get canvases
local function getCanvases(artClassInstance)
	return genesUtil.getInstances(canvas)
		:filter(dart.isDescendantOf(artClassInstance))
end

-- Init canvases
-- 	Places a switch in canvases so that we can lock them for our class
local function initCanvases(artClassInstance)
	getCanvases(artClassInstance):foreach(dart.follow(multiswitchUtil.createSwitch, "interact", "artClass"))
end

-- Open canvases
local function openCanvases(artClassInstance)
	local team = artClassInstance.state.activity.sessionTeams[1].Value
	local function open(canvasInstance)
		canvasUtil.clearCanvas(canvasInstance)
		canvasInstance.state.interact.switches:WaitForChild("artClass").Value = true
		canvasInstance.state.canvas.teamToAcceptFrom.Value = team
	end
	getCanvases(artClassInstance):foreach(open)
end

-- Lock canvases
local function lockCanvases(artClassInstance)
	local function close(canvasInstance)
		canvasInstance.state.interact.switches:WaitForChild("artClass").Value = false
		canvasInstance.state.canvas.owner.Value = nil
	end

	getCanvases(artClassInstance):foreach(close)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(artClass)
	:subscribe(initCanvases)

-- Session start and end
local sessionStart, sessionEnd = genesUtil.crossObserveStateValue(artClass, activity, "inSession")
	:partition(dart.select(2))

-- Open up canvases to team on start
sessionStart:subscribe(openCanvases)

-- Lock canvases on end
sessionEnd:subscribe(lockCanvases)
