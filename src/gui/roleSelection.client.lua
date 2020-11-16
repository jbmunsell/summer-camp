--
--	Jackson Munsell
--	16 Nov 2020
--	roleSelection.client.lua
--
--	Role selection gui client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local axisUtil = require(axis.lib.axisUtil)
local leaderUtil = require(genes.player.leader.util)

---------------------------------------------------------------------------------------------------
-- Instances
---------------------------------------------------------------------------------------------------

local coreGui = env.PlayerGui:WaitForChild("Core")
local splashScreen = env.PlayerGui:WaitForChild("SplashScreen")
local roleSelection = env.PlayerGui:WaitForChild("RoleSelection")

local previewAnimation = env.res.pickup.ToolHoldAnimation

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function enableGui()
	roleSelection.Enabled = true
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
rx.Observable.from(env.LocalPlayer.CharacterAppearanceLoaded)
	:merge(rx.Observable.just(env.LocalPlayer:HasAppearanceLoaded()):filter())
	:subscribe(createCharacters)

-- Enable gui stream
rx.Observable.fromProperty(splashScreen, "Enabled")
	:reject()
	:first()
	-- :merge(someButtonActivated)
	-- :subscribe(enableGui)
	