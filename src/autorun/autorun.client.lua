--
--	Jackson Munsell
--	20 Nov 2020
--	autorun.client.lua
--
--	Auto runs the character after moving for a few seconds
--

-- env
local TweenService = game:GetService("TweenService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local pickupUtil = require(genes.pickup.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local runningChanged = env.src.autorun.net.RunningChanged

local RunningFOV = 75
local WalkingFOV = 70
local RunningSpeed = 28
local WalkingSpeed = 16
local AutorunTimer = 3
local SpeedTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function setRunning(running)
	local humanoid = axisUtil.getLocalHumanoid()
	local camera = workspace.CurrentCamera
	local humanoidGoals = { WalkSpeed = running and RunningSpeed or WalkingSpeed }
	local cameraGoals = { FieldOfView = running and RunningFOV or WalkingFOV }
	TweenService:Create(humanoid, SpeedTweenInfo, humanoidGoals):Play()
	TweenService:Create(camera, SpeedTweenInfo, cameraGoals):Play()
	runningChanged:FireServer(running)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

local holdingHeavy = pickupUtil.getLocalCharacterHoldingStream(genes.preventRunning)
	:map(dart.boolify)

local running = rx.Observable.from(env.LocalPlayer.CharacterAdded)
	:startWith(env.LocalPlayer.Character)
	:filter()
	:map(function (character)
		return character:WaitForChild("Humanoid")
	end)
	:filter()
	:flatMap(function (humanoid)
		return rx.Observable.fromInstanceEvent(humanoid, "Running")
	end)
	:map(dart.greaterThan(0.02))
	:distinctUntilChanged()
	:share()
local started, stopped = running:partition()
started
	:withLatestFrom(holdingHeavy)
	:reject(dart.select(2))
	:subscribe(function ()
	-- Speed them up after a few seconds if we're still running
	local fast = rx.Observable.timer(AutorunTimer)
	fast:map(dart.constant(true))
		:merge(stopped:map(dart.constant(false)))
		:takeUntil(stopped:delay(0):merge(holdingHeavy:filter()))
		:subscribe(setRunning)
end)
