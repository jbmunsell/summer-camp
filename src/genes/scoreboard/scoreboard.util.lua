--
--	Jackson Munsell
--	07 Sep 2020
--	scoreboardUtil.lua
--
--	Server scoreboard util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

-- lib
local scoreboardUtil = {}

-- Easy getters
local function getTeamLabels(instance, teamIndex)
	return {
		nameLabel = instance:FindFirstChild("Team" .. teamIndex .. "NameLabel", true),
		scoreLabel = instance:FindFirstChild("Team" .. teamIndex .. "ScoreLabel", true),
	}
end
local function getClockLabels(instance)
	return {
		minutesLabel = instance:FindFirstChild("ClockMinutesLabel", true),
		secondsLabel = instance:FindFirstChild("ClockSecondsLabel", true),
	}
end

-- Exported setters
function scoreboardUtil.setTeams(instance, teamsFolder)
	for i = 1, 2 do
		local teamName = teamsFolder[i].Value.Name
		local labels = getTeamLabels(instance, i)
		for _, label in pairs(labels) do
			label.TextColor3 = env.config.teams[teamName].color.Value
		end
		labels.nameLabel.Text = teamName
	end
end
function scoreboardUtil.setScore(instance, score)
	for i = 1, 2 do
		getTeamLabels(instance, i).scoreLabel.Text = tostring(score[i])
	end
end
function scoreboardUtil.setTime(instance, secondsRemaining)
	local minutes = math.floor(secondsRemaining / 60)
	local seconds = math.floor(secondsRemaining % 60)
	local labels = getClockLabels(instance)
	labels.minutesLabel.Text = string.format("%02d", minutes)
	labels.secondsLabel.Text = string.format("%02d", seconds)
end

-- return lib
return scoreboardUtil
