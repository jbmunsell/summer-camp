--
--	Jackson Munsell
--	16 Nov 2020
--	activityResults.client.lua
--
--	Activity results gui client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local glib = require(axis.lib.glib)
local genesUtil = require(genes.util)
local activityUtil = require(genes.activity.util)

---------------------------------------------------------------------------------------------------
-- Instances
---------------------------------------------------------------------------------------------------

local coreGui = env.PlayerGui:WaitForChild("Core")

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function killFrame(frame)
	glib.playAnimation(coreGui.animations.activityPrompt.hide, frame):subscribe(dart.destroy)
end

local function showMatchResult(activityInstance)
	-- Get data
	local state = activityInstance.state.activity
	local winningTeam = state.winningTeam.Value

	-- Create window
	local container = coreGui.seeds.activityResult.ActivityContainer:Clone()
	container.Parent = coreGui.Container
	local frame = container.ActivityResult
	for i = 1, 2 do
		local team = state.sessionTeams[i].Value
		local didWin = (team == winningTeam)
		local teamFrame = frame["Team" .. i]
		teamFrame.state.teamLink.team.Value = team
		teamFrame.Color.BackgroundTransparency = (didWin and 0 or 1)
		teamFrame.Circle.BackgroundTransparency = (didWin and 0 or 1)
		teamFrame.Circle.TeamImage.Crown.Visible = didWin
	end
	frame.ScoreLabel.Text = string.format("%d - %d", state.score[1].Value, state.score[2].Value)
	frame.WinningTeamLabel.Text = string.format("%s win!", winningTeam.Name)
	frame.ActivityLabel.Text = activityInstance.config.activity.displayName.Value

	-- Kill after 10 seconds
	rx.Observable.timer(10)
		:merge(glib.getExitStream(container))
		:first()
		:subscribe(dart.bind(killFrame, container))

	-- Play animation
	glib.playAnimation(coreGui.animations.activityPrompt.show, container)
	container.Visible = true
end

local function notifyZeroJoin()
	local frame = coreGui.seeds.zeroJoinCase.Notification:Clone()

	rx.Observable.timer(7):subscribe(dart.bind(killFrame, frame))

	glib.playAnimation(coreGui.animations.activityPrompt.show, frame)
	frame.Parent = coreGui.Container
	frame.Visible = true
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Listen for zero join case
rx.Observable.from(genes.activity.net.ZeroJoinCase):subscribe(notifyZeroJoin)

-- Listen to winner declared
genesUtil.observeStateValue(genes.activity, "winningTeam")
	:filter(dart.select(2))
	:filter(function (activityInstance)
		return activityUtil.isPlayerInFullRoster(activityInstance, env.LocalPlayer)
	end)
	:subscribe(showMatchResult)
