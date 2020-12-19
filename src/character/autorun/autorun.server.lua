--
--	Jackson Munsell
--	20 Nov 2020
--	autorun.server.lua
--
--	Turns on particles when client says they're running
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local fx = require(axis.lib.fx)
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function renderCharacterRuning(character, running)
	local emitter = character:FindFirstChild("SprintEmitter")
	if emitter then
		fx.setFXEnabled(emitter, running)
	end
end

local function initCharacter(character)
	local humanoid = character:FindFirstChild("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	local emitter = env.res.character.SprintEmitter:Clone()
	emitter.Parent = character
	renderCharacterRuning(character, false)

	local weld = Instance.new("Weld")
	weld.Part0 = character.HumanoidRootPart
	weld.Part1 = emitter

	local function adjustWeld()
		weld.C0 = CFrame.new(0, -0.5 * (root.Size.Y + humanoid.HipHeight), root.Size.Z * 0.5)
			* CFrame.Angles(math.pi * 0.5, 0, 0)
	end

	rx.Observable.fromProperty(humanoid, "HipHeight", true)
		:merge(rx.Observable.fromProperty(root, "Size"))
		:subscribe(adjustWeld)

	weld.Parent = emitter
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

rx.Observable.from(env.src.character.autorun.net.RunningChanged)
	:map(function (player, running)
		return player.Character, running
	end)
	:filter()
	:subscribe(renderCharacterRuning)

axisUtil.getPlayerCharacterStream():map(dart.select(2)):subscribe(initCharacter)
