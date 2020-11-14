--
--	Jackson Munsell
--	13 Nov 2020
--	splashScreen.client.lua
--
--	Splash screen client driver
--

-- env
local Lighting = game:GetService("Lighting")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Instances
---------------------------------------------------------------------------------------------------

-- Screen gui
local splashScreen = env.PlayerGui:WaitForChild("SplashScreen")
local cameraParts = workspace.introCameraParts
local pivot = CFrame.new(cameraParts.Pivot.Position)
local cameraOffset = pivot:toObjectSpace(workspace.introCameraParts.Camera.CFrame)

-- Camera variables
local rotationSpeed = math.pi * 2 * 0.01

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- Action
---------------------------------------------------------------------------------------------------

-- Show
-- splashScreen.Enabled = true
-- Should be on by default

-- Create terminator
local terminator = rx.Observable.from(splashScreen.Frame.Logo.PlayButton.Activated)
	:first()

-- Depth of field
local depth = Lighting.DepthOfField
genesUtil.waitForState(depth, genes.propertySwitcher)
depth.state.propertySwitcher.propertySet.Value = "intro"

-- Connect camera
local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable
rx.Observable.heartbeat()
	:takeUntil(terminator)
	:subscribe(function (dt)
		pivot = pivot * CFrame.Angles(0, dt * rotationSpeed, 0)
		camera.CFrame = pivot:toWorldSpace(cameraOffset)
	end)

-- Destroy
terminator:subscribe(function ()
	depth.state.propertySwitcher.propertySet.Value = "gameplay"
	splashScreen.Enabled = false
end)
