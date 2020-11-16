--
--	Jackson Munsell
--	13 Nov 2020
--	leader.util.lua
--
--	leader gene util
--

-- env
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

-- return lib
return leaderUtil
