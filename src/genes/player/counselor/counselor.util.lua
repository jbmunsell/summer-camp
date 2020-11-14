--
--	Jackson Munsell
--	13 Nov 2020
--	counselor.util.lua
--
--	counselor gene util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local counselor = genes.player.counselor

-- modules
local genesUtil = require(genes.util)

-- lib
local counselorUtil = {}

-- is player counselor
function counselorUtil.isCounselor(player)
	return player.state.counselor.isCounselor.Value
end

-- Get team counselors
function counselorUtil.getTeamCounselors(team)
	return genesUtil.getInstances(counselor)
		:filter(counselorUtil.isCounselor)
		:filter(function (p) return p.Team == team end)
end

-- return lib
return counselorUtil
