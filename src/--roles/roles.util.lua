--
--	Jackson Munsell
--	09 Nov 2020
--	roles.util.lua
--
--	Roles util. Contains functions for rendering counselors
--

-- env
local ChatService = require(game:GetService("ServerScriptService")
	:WaitForChild("ChatServiceRunner").ChatService)
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local tableau = require(axis.lib.tableau)
local axisUtil = require(axis.lib.axisUtil)
local dataUtil = require(env.src.data.util)

-- lib
local rolesUtil = {}

-- is counselor
function rolesUtil.isPlayerCounselor(player)
	dataUtil.waitForState(player, "roles")
	return player.state.roles.isCounselor.Value
end

-- Set counselor
function rolesUtil.setCounselor(player, counselor)
	dataUtil.waitForState(player, "roles")
	player.state.roles.isCounselor.Value = counselor
end

-- Get all counselors
function rolesUtil.getAllCounselors()
	return tableau.from(Players:GetPlayers())
		:filter(rolesUtil.isPlayerCounselor)
end

-- Get team counselors
function rolesUtil.getTeamCounselors(team)
	return tableau.from(team:GetPlayers())
		:filter(rolesUtil.isPlayerCounselor)
end

-- Render character size
function rolesUtil.renderCharacterSize(character, isCounselor)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end
	tableau.from(env.config.roles.camperSizeModifiers:GetChildren())
		:foreach(function (m)
			if humanoid:FindFirstChild(m.Name) then
				humanoid[m.Name].Value = (isCounselor and 1 or m.Value)
			end
		end)
end

-- Render counselor character
function rolesUtil.renderCounselorCharacter(character)
	-- Destroy old
	rolesUtil.destroyCounselorRendering(character)

	-- Get stuff
	local player = Players:GetPlayerFromCharacter(character)
	local head = character:FindFirstChild("Head")
	if not player or not head then return end

	-- Create gui
	local team = player.Team
	local gui = env.res.roles.TeamGui:Clone()
	gui.Parent = character.Head
	gui.TeamImage.Image = env.config.cabins[team.Name].image.Value

	-- Set size modifiers
	rolesUtil.renderCharacterSize(character, true)
end

-- Render counselor
function rolesUtil.announceCounselor(player)
	-- Send a chat message
	local actionMessage = string.format("been appointed counselor of Cabin %s!", player.Team.Name)
	local generalMessage = string.format("%s has %s", player.Name, actionMessage)
	local personalMessage = string.format("You have %s", actionMessage)
	local channel = ChatService:GetChannel("All")
	for _, speakerName in pairs(channel:GetSpeakerList()) do
		local speaker = ChatService:GetSpeaker(speakerName)
		local speakerPlayer = speaker:GetPlayer()
		if speakerPlayer.Team == player.Team then
			local message = (speakerPlayer == player and personalMessage or generalMessage)
			speaker:SendSystemMessage(message, channel.Name)
		end
	end
end

-- Destroy counselor rendering
function rolesUtil.destroyCounselorRendering(character)
	-- Destroy gui
	axisUtil.destroyChild(character.Head, "TeamGui")

	-- Set size modifiers
	rolesUtil.renderCharacterSize(character, false)
end

-- return lib
return rolesUtil
