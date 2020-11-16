--
--	Jackson Munsell
--	16 Nov 2020
--	leaderboard.client.lua
--
--	Leaderboard client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Instances
---------------------------------------------------------------------------------------------------

local leaderboard = workspace:FindFirstChild("TeamLeaderboard", true)
local teamsList = leaderboard:FindFirstChild("TeamsList", true)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function getWins(team)
	return team.state.team.wins.Value
end

local function renderLeaderboard()
	-- Sort according to wins
	local teams = genesUtil.getInstances(genes.team):raw()
	table.sort(teams, function (a, b)
		return getWins(a) > getWins(b)
	end)

	-- Set each thing up
	for i = 1, #teams do
		local team = teams[i]
		local frame = teamsList["Team" .. i]
		frame.WinsText.Text = string.format("Wins: %d", getWins(team))
		frame.TeamImage.Image = team.config.team.image.Value
	end
	teamsList.Team1.BackgroundColor3 = teams[1].config.team.color.Value
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Observe team win state and recalculate on changed
genesUtil.observeStateValue(genes.team, "wins"):subscribe(renderLeaderboard)
