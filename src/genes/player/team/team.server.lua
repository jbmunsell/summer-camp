--
--	Jackson Munsell
--	13 Nov 2020
--	counselor.server.lua
--
--	counselor gene server driver
--

-- env
local Teams = game:GetService("Teams")
local AnalyticsService = game:GetService("AnalyticsService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local playerUtil = require(genes.player.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Change team
local function changeTeam(player, team)
	-- Set values
	local oldTeam = player.Team
	player.state.counselor.isCounselor.Value = false
	player.Team = team

	-- Fire event
	local teams = {
		Teams.Wolves,
		Teams.Owls,
		Teams.Cheetahs,
		Teams.Scorpions,
	}
	table.sort(teams, function (a, b)
		return #a:GetPlayers() < #b:GetPlayers()
	end)
	AnalyticsService:FireEvent("teamChanged", {
		playerId = player.UserId,
		oldTeam = oldTeam.Name,
		newTeam = team.Name,
		oldTeamRelativePlayers = table.find(teams, oldTeam),
		newTeamRelativePlayers = table.find(teams, team),
	})
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
local playerStream = playerUtil.initPlayerGene(genes.player.team)

-- Accept team change requests
playerStream
	:flatMap(function (player)
		return rx.Observable.from(genes.player.team.net.TeamChangeRequested)
			:filter(dart.equals(player))
	end)
	:subscribe(changeTeam)
