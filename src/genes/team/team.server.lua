--
--	Jackson Munsell
--	16 Nov 2020
--	team.server.lua
--
--	team gene server driver
--

-- env
local AnalyticsService = game:GetService("AnalyticsService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Increase team wins
local function addWin(team)
	team.state.team.wins.Value = team.state.team.wins.Value + 1
end

-- Change team
local function changePlayerTeam(player, team)
	-- Set values
	local oldTeam = player.Team
	player.Team = team

	-- Fire event
	local teams = genesUtil.getTaggedInstances(genes.team)
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

-- init gene
genesUtil.initGene(genes.team)

-- When an activity declares a winner, increase the team's wins
genesUtil.observeStateValue(genes.activity, "winningTeam")
	:map(dart.select(2))
	:filter()
	:subscribe(addWin)

-- Accept team change requests
rx.Observable.from(genes.team.net.TeamChangeRequested):subscribe(changePlayerTeam)
