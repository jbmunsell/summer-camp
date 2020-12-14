--
--	Jackson Munsell
--	16 Nov 2020
--	introSequence.client.lua
--
--	Intro sequenec client driver
--

-- env
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Instances
---------------------------------------------------------------------------------------------------

-- guis
local coreGui = env.PlayerGui:WaitForChild("Core")
local splashScreen = env.PlayerGui:WaitForChild("SplashScreen")
local jobSelection = env.PlayerGui:WaitForChild("JobSelection")
local teamSelect = env.PlayerGui:WaitForChild("TeamSelect")

-- Camera variables
local cameraParts = workspace.introCameraParts
local pivot = CFrame.new(cameraParts.Pivot.Position)
local cameraOffset = pivot:toObjectSpace(workspace.introCameraParts.Camera.CFrame)
local rotationSpeed = math.pi * 2 * 0.01


---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------



---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Start camera tween (stop on first hide of role selection)
-- Show splash screen
-- On splash screen activated, show role selection
-- On first hide of role selection, stop camera tween, hide DOF, and show team selection

-- Enable and disable all the right guis
coreGui.Enabled = false
jobSelection.Enabled = false
teamSelect.Enabled = false
splashScreen.Enabled = true

-- Bind core gui visible to basically everything else NOT being visible
local function fromDisabled(gui)
	return rx.Observable.fromProperty(gui, "Enabled", true):map(dart.boolNot)
end
fromDisabled(splashScreen):combineLatest(fromDisabled(teamSelect), fromDisabled(jobSelection), dart.boolAll)
	:subscribe(function (v)
		coreGui.Enabled = v
	end)

-- Quick lab check
if StarterGui:FindFirstChild("config") then
	if StarterGui.config.disableIntro.Value then
		warn("Gui disabled; requesting first team and returning")
		genesUtil.getInstanceStream(genes.team)
			:first()
			:subscribe(dart.forward(genes.team.net.TeamChangeRequested))
		jobSelection.Enabled = false
		teamSelect.Enabled = false
		splashScreen.Enabled = false
		return
	end
end

-- Buttons and genes
local playButton = splashScreen:FindFirstChild("PlayButton", true)
genesUtil.waitForGene(playButton, genes.guiButton)

-- Streams
local jobSelected = rx.Observable.fromProperty(jobSelection, "Enabled")
	:reject()
	:first()
local playClicked = rx.Observable.from(playButton.interface.guiButton.Activated)
	:first()

-- Get other instances
local camera = workspace.CurrentCamera
local depth = Lighting.DepthOfField
genesUtil.waitForGene(depth, genes.propertySwitcher)

-- Start camera tween and show splash screen
depth.state.propertySwitcher.propertySet.Value = "intro"
camera.CameraType = Enum.CameraType.Scriptable
rx.Observable.heartbeat()
	:takeUntil(playClicked)
	:subscribe(function (dt)
		pivot = pivot * CFrame.Angles(0, dt * rotationSpeed, 0)
		camera.CFrame = pivot:toWorldSpace(cameraOffset)
	end)

-- When play is clicked, show job selection
playClicked:subscribe(function ()
	depth.state.propertySwitcher.propertySet.Value = "gameplay"
	splashScreen.Enabled = false
	jobSelection.Enabled = true
end)

-- When job selection hides, show team select
jobSelected:subscribe(function ()
	teamSelect.Enabled = true
end)
