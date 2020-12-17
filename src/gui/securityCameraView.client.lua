--
--	Jackson Munsell
--	23 Nov 2020
--	securityCameraView.client.lua
--
--	Security camera view gui
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
local pickupUtil = require(genes.pickup.util)
local inputStreams = require(env.src.input.streams)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

-- local gui = env.PlayerGui:WaitForChild("SecurityCameraGui")
local viewEnabled = rx.BehaviorSubject.new(false)
local viewIndex = rx.BehaviorSubject.new(1)
local securityCameraParts = workspace.securityCameraParts:GetChildren()
local colorCorrection = Lighting.ColorCorrection
genesUtil.waitForGene(colorCorrection, genes.propertySwitcher)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function shiftViewIndex(delta)
	local v = viewIndex:getValue() + delta
	viewIndex:push((v - 1) % #securityCameraParts + 1)
end

local function updateView()
	local part = securityCameraParts[viewIndex:getValue()]
	workspace.CurrentCamera.CFrame = part.CFrame
end

local function setViewEnabled(enabled)
	local cameraType = (enabled and Enum.CameraType.Scriptable or Enum.CameraType.Custom)
	local propertySet = (enabled and "securityCameraView" or "gameplay")
	workspace.CurrentCamera.CameraType = cameraType
	colorCorrection.state.propertySwitcher.propertySet.Value = propertySet
	if enabled then
		updateView()
	end
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Set view enabled on changed
viewEnabled:distinctUntilChanged():skip(1):subscribe(setViewEnabled)

-- Update view whenever the index changes (if we're enabled)
viewIndex:filter(function () return viewEnabled:getValue() end)
	:subscribe(updateView)

-- Bind gui enabled to whether or not we're holding a security camera viewer
pickupUtil.getLocalCharacterHoldingStream(genes.securityCameraViewer)
	:map(dart.boolify)
	:multicast(viewEnabled)

-- Switch the view when we tap or click in the world
viewEnabled:filter():flatMap(function ()
	return inputStreams.click:takeUntil(viewEnabled:reject())
end):subscribe(dart.bind(shiftViewIndex, 1))
