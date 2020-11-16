--
--	Jackson Munsell
--	15 Nov 2020
--	drawFocus.client.lua
--
--	drawFocus gene client driver
--

-- env
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local drawFocusData = require(genes.drawFocus.data)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function renderCamera(instance, isInRange)
	local camera = workspace.CurrentCamera
	local focusPart = instance:FindFirstChild("CameraFocusPart", true)
	local root = env.LocalPlayer.Character.HumanoidRootPart
	if not focusPart then
		error(string.format("%s has no descendant named CameraFocusPart", instance:GetFullName()))
	end
	if isInRange then
		local offset = camera.CFrame.p - root.Position
		instance.state.drawFocus.cameraHeadOffset.Value = CFrame.new(offset, offset + camera.CFrame.LookVector)
		camera.CameraType = Enum.CameraType.Scriptable
		TweenService:Create(camera, drawFocusData.tweenInfo, { CFrame = focusPart.CFrame }):Play()
	else
		local offset = instance.state.drawFocus.cameraHeadOffset.Value
		local original = camera.CFrame
		local tween = axisUtil.createDynamicTween(camera, drawFocusData.tweenInfo, {
			CFrame = function (d)
				return original:lerp(offset + root.Position, d)
			end,
		})
		rx.Observable.from(tween.Completed):first():subscribe(function ()
			camera.CameraType = Enum.CameraType.Custom
		end)
		tween:Play()
	end
end

local function getExitStream()
	local humanoid = axisUtil.getLocalHumanoid()
	if not humanoid then return rx.Observable.just(0) end

	local running = rx.Observable.from(humanoid.Running)
		:map(dart.greaterThan(0.01))
	local stopAndStart = running:distinctUntilChanged():filter():skip(1)

	return rx.Observable.from(humanoid.Died)
		:merge(stopAndStart)
		:first()
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local instanceStream = genesUtil.initGene(genes.drawFocus)

-- This makes me furious
instanceStream:subscribe(function (instance)
	local was = false
	RunService:BindToRenderStep("cameraBinding", Enum.RenderPriority.Last.Value, function ()
		local is = instance.state.proximitySensor.isInRange.Value
		if is ~= was then
			was = is
			if is then
				renderCamera(instance, true)
				getExitStream():subscribe(dart.bind(renderCamera, instance, false))
			end
		end
	end)
end)
