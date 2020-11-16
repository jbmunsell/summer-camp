--
--	Jackson Munsell
--	13 Nov 2020
--	leader.util.lua
--
--	leader gene util
--

-- env
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local leader = genes.player.leader

-- modules
local genesUtil = require(genes.util)

-- lib
local leaderUtil = {}

-- is player leader
function leaderUtil.isLeader(player)
	return player.state.leader.isLeader.Value
end

-- Get team leaders
function leaderUtil.getTeamLeaders(team)
	return genesUtil.getInstances(leader)
		:filter(leaderUtil.isLeader)
		:filter(function (p) return p.Team == team end)
end

-- Render character size
function leaderUtil.renderCharacterSize(character)
	-- Get player and humanoid
	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	leaderUtil.forceRenderCharacterSize(character, leaderUtil.isLeader(player))
end

-- Force render character size
function leaderUtil.forceRenderCharacterSize(character, isLeader)
	-- Set scale values
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end
	for _, c in pairs(env.config.roles.camperSizeModifiers:GetChildren()) do
		humanoid:WaitForChild(c.Name).Value = (isLeader and 1 or c.Value)
	end
end

-- return lib
return leaderUtil
