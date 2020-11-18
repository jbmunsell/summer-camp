--
--	Jackson Munsell
--	16 Nov 2020
--	introSequence.client.lua
--
--	Intro sequenec client driver
--

-- env
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
local roleSelection = env.PlayerGui:WaitForChild("RoleSelection")
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
roleSelection.Enabled = false
teamSelect.Enabled = false
splashScreen.Enabled = true

-- Streams
local roleSelected = rx.Observable.fromProperty(roleSelection, "Enabled")
	:reject()
	:first()
local playClicked = rx.Observable.from(splashScreen:FindFirstChild("PlayButton", true).Activated)
	:first()

-- Get other instances
local camera = workspace.CurrentCamera
local depth = Lighting.DepthOfField
genesUtil.waitForGene(depth, genes.propertySwitcher)

-- Start camera tween and show splash screen
depth.state.propertySwitcher.propertySet.Value = "intro"
camera.CameraType = Enum.CameraType.Scriptable
rx.Observable.heartbeat()
	:takeUntil(roleSelected)
	:subscribe(function (dt)
		pivot = pivot * CFrame.Angles(0, dt * rotationSpeed, 0)
		camera.CFrame = pivot:toWorldSpace(cameraOffset)
	end)

-- Show role selection and hide splash screen on clicked
playClicked:subscribe(function ()
	roleSelection.Enabled = true
	splashScreen.Enabled = false
end)

-- When role selection hides, hide depth and show team selection
roleSelected:subscribe(function ()
	-- camera.CameraType = Enum.CameraType.Custom
	depth.state.propertySwitcher.propertySet.Value = "gameplay"
	teamSelect.Enabled = true
	splashScreen.Enabled = false
end)

-- Bind core gui visible to basically everything else NOT being visible
local function fromDisabled(gui)
	return rx.Observable.fromProperty(gui, "Enabled", true):map(dart.boolNot)
end
fromDisabled(splashScreen):combineLatest(fromDisabled(teamSelect), fromDisabled(roleSelection), dart.boolAll)
	:subscribe(function (v)
		coreGui.Enabled = v
	end)
