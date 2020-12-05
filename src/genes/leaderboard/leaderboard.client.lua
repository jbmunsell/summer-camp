--
--	Jackson Munsell
--	05 Dec 2020
--	leaderboard.client.lua
--
--	leaderboard gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function getWins(team)
	return team.state.team.wins.Value
end

local function getSortedTeams()
	-- Sort according to wins
	local teams = genesUtil.getInstances(genes.team):raw()
	table.sort(teams, function (a, b)
		return getWins(a) > getWins(b)
	end)
	return teams
end

local function renderLeaderboard(board, teamsSorted)
	local teamsList = board:FindFirstChild("TeamsList", true)
	if #teamsSorted == 0 then return end
	for i = 1, #teamsSorted do
		local team = teamsSorted[i]
		local frame = teamsList["Team" .. i]
		frame.WinsText.Text = string.format("Wins: %d", getWins(team))
		frame.TeamImage.Image = team.config.team.image.Value
	end
	teamsList.Team1.BackgroundColor3 = teamsSorted[1].config.team.color.Value
end

local function renderAllLeaderboards()
	-- Set each thing up
	local teamsSorted = getSortedTeams()
	for _, board in pairs(genesUtil.getInstances(genes.leaderboard):raw()) do
		renderLeaderboard(board, teamsSorted)
	end
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.leaderboard):subscribe(function (instance)
	renderLeaderboard(instance, getSortedTeams())
end)

-- Observe team win state and recalculate on changed
genesUtil.observeStateValue(genes.team, "wins"):subscribe(renderAllLeaderboards)
