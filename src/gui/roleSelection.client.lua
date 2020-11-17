--
--	Jackson Munsell
--	16 Nov 2020
--	roleSelection.client.lua
--
--	Role selection gui client driver
--

-- env
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local leaderUtil = require(genes.player.leader.util)

---------------------------------------------------------------------------------------------------
-- Instances
---------------------------------------------------------------------------------------------------

local coreGui = env.PlayerGui:WaitForChild("Core")
local splashScreen = env.PlayerGui:WaitForChild("SplashScreen")
local roleSelection = env.PlayerGui:WaitForChild("RoleSelection")

local blur = Lighting.Blur
local blurTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

local previewAnimation = env.res.pickup.ToolHoldAnimation

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function enableGui()
	roleSelection.Enabled = true
end
local function hideGui()
	roleSelection.Enabled = false
end

local function setCoreEnabled(enabled)
	coreGui.Enabled = enabled
end

local function setBlurEnabled(enabled)
	if enabled then
		blur.Enabled = true
		TweenService:Create(blur, blurTweenInfo, { Size = roleSelection.config.blur.size.Value }):Play()
	else
		local tween = TweenService:Create(blur, blurTweenInfo, { Size = 0 })
		tween.Completed:Connect(function ()
			blur.Enabled = false
		end)
		tween:Play()
	end
end

local function clearViewportFrame(frame)
	axisUtil.destroyChild(frame, "Character")
	axisUtil.destroyChild(frame, "Camera")
end

local function createCharacters()
	-- Assert character
	local character = env.LocalPlayer.Character
	if not character then
		warn("Cannot create role selection characters; no player character exists")
	end

	-- Clear
	local camperFrame = roleSelection:FindFirstChild("CamperFrame", true)
	local leaderFrame = roleSelection:FindFirstChild("LeaderFrame", true)
	clearViewportFrame(camperFrame)
	clearViewportFrame(leaderFrame)

	-- Create new camper character and new counselor character
	for _, d in pairs(character:GetDescendants()) do
		d.Archivable = true
	end
	character.Archivable = true
	local function createCharacter(frame)
		local copy = character:Clone()
		copy.Name = "Character"
		copy:SetPrimaryPartCFrame(CFrame.new())
		copy.Parent = frame

		local camera = Instance.new("Camera", frame)
		camera.CFrame = CFrame.new(Vector3.new(0, 2, -8), Vector3.new())

		local anim = Instance.new("Animator", copy.Humanoid)
		anim:LoadAnimation(previewAnimation):Play()

		return copy
	end

	-- Create leader character
	local leaderCharacter = createCharacter(leaderFrame)
	leaderUtil.forceRenderCharacterSize(leaderCharacter, true)

	-- Create camper character
	local camperCharacter = createCharacter(camperFrame)
	leaderUtil.forceRenderCharacterSize(camperCharacter, false)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Clone character whenever appearance loads
-- 	or after one 10 second timer upon joining just for safety
-- rx.Observable.from(env.LocalPlayer.CharacterAppearanceLoaded)
-- 	:merge(rx.Observable.just(env.LocalPlayer:HasAppearanceLoaded()):filter())
-- 	:subscribe(createCharacters)

-- Enable gui stream
rx.Observable.from(coreGui:FindFirstChild("CharacterSelect", true).Button.Activated)
	:subscribe(enableGui)
	
-- Tween blur according to enabled
local enabledStream = rx.Observable.fromProperty(roleSelection, "Enabled")
enabledStream:subscribe(setBlurEnabled)

-- Connect to buttons
local function getActivatedStream(name, isLeader)
	return rx.Observable.from(roleSelection:FindFirstChild(name, true).JoinButton.Activated)
		:map(dart.constant(isLeader))
end
local leaderSelected = getActivatedStream("LeaderFrame", true)
local camperSelected = getActivatedStream("CamperFrame", false)
local optionSelected = leaderSelected:merge(camperSelected)
optionSelected:subscribe(dart.forward(genes.player.leader.net.RoleChangeRequested))
optionSelected:subscribe(hideGui)
