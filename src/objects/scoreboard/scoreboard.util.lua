--
--	Jackson Munsell
--	07 Sep 2020
--	scoreboardUtil.lua
--
--	Server scoreboard util
--

-- env
-- local env = require(game:GetService("ReplicatedStorage").src.env)

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

-- Easy setters
local function loadTeamAppearance(instance, teamIndex, teamConfig)
	local labels = getTeamLabels(instance, teamIndex)
	for _, label in pairs(labels) do
		label.TextColor3 = teamConfig.Color
	end
	labels.nameLabel.Text = teamConfig.DisplayName
end
local function setAppearanceFromConfig(instance, teamsConfig)
	for i = 1, 2 do
		loadTeamAppearance(instance, i, teamsConfig[i])
	end
end
local function setScore(instance, score)
	for i = 1, 2 do
		getTeamLabels(instance, i).scoreLabel.Text = tostring(score[i])
	end
end
local function setTime(instance, secondsRemaining)
	local minutes = math.floor(secondsRemaining / 60)
	local seconds = math.floor(secondsRemaining % 60)
	local labels = getClockLabels(instance)
	labels.minutesLabel.Text = string.format("%02d", minutes)
	labels.secondsLabel.Text = string.format("%02d", seconds)
end

-- return lib
return {
	setAppearanceFromConfig = setAppearanceFromConfig,
	setScore = setScore,
	setTime = setTime,
}
