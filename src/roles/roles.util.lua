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
print("Required chat service")
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local tableau = require(axis.lib.tableau)

-- lib
local rolesUtil = {}

-- is counselor
function rolesUtil.isPlayerCounselor(player)
	return player.state.roles.isCounselor.Value
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

-- Render counselor
function rolesUtil.renderCounselor(player)
	-- TODO: Create gui objects

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
function rolesUtil.destroyCounselorRendering(player)
	-- TODO: Find and destroy gui objects
end

-- return lib
return rolesUtil
