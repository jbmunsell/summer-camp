--
--	Jackson Munsell
--	15 Dec 2020
--	lookAtMouse.client.lua
--
--	Makes a character look at the mouse
--

-- env
local RunService = game:GetService("RunService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local inputUtil = require(env.src.input.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local LerpScalar = 5

local transforms = {
	upperTorso = CFrame.new(),
	head = CFrame.new(),
}

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function stepCharacter(dt)
	-- Get character
	local character = env.LocalPlayer.Character
	if not character then return end

	-- Get constituents
	local lowerTorso = character:FindFirstChild("LowerTorso")
	local upperTorso = character:FindFirstChild("UpperTorso")
	if not lowerTorso or not upperTorso then return end

	-- Calculate target looks
	local target = lowerTorso.CFrame:pointToObjectSpace(inputUtil.getMouseHit())
	local upperTorsoUnit = (upperTorso.Position - target).unit * -1
	print("before clamping: ", upperTorsoUnit)
	local zSign = upperTorsoUnit.Z > 0 and 1 or -1
	upperTorsoUnit = Vector3.new(
		math.clamp(upperTorsoUnit.X, -1, 1),
		math.clamp(upperTorsoUnit.Y, -1, 1) * zSign * -1,
		math.abs(upperTorsoUnit.Z) * -1
	).unit
	print("after clamping: ", upperTorsoUnit)
	local upperTorsoTarget = CFrame.new(Vector3.new(), upperTorsoUnit)
	local upperTorsoTransform = transforms.upperTorso:lerp(upperTorsoTarget, dt * LerpScalar)
	upperTorso.Waist.Transform = upperTorsoTransform
	transforms.upperTorso = upperTorsoTransform

	print("")
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- rx.Observable.from(RunService.Stepped):map(dart.select(2)):subscribe(stepCharacter)
