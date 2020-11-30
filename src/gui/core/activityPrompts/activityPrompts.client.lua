--
--	Jackson Munsell
--	15 Nov 2020
--	activityPrompts.client.lua
--
--	Activity prompts gui client driver
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

local Core = env.PlayerGui:WaitForChild("Core")
local leaveButton = Core:FindFirstChild("LeaveActivityButton", true)

local localPlayerCompeting = activityUtil.getPlayerCompetingStream(env.LocalPlayer)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function setLeaveButtonVisible(visible)
	leaveButton.Visible = visible
end

local function killPrompt(prompt)
	glib.playAnimation(Core.animations.activityPrompt.hide, prompt):subscribe(dart.destroy)
end

local function createStartupPrompt(activityInstance)
	-- Get data
	local config = activityInstance.config.activity
	local state = activityInstance.state.activity
	local finishTime = os.time() + config.rosterCollectionTimer.Value
	local team = env.LocalPlayer.Team

	-- Create prompt
	local prompt = Core.seeds.activityPrompt.ActivityPrompt:Clone()
	prompt.MainLabel.Text = string.upper(config.displayName.Value)
	prompt:FindFirstChild("ActivityImage", true).Image = config.activityPromptImage.Value
	for _, value in pairs(state.sessionTeams:GetChildren()) do
		prompt:FindFirstChild("Team" .. value.Name, true).state.teamLink.team.Value = value.Value
	end

	-- Create streams
	local terminator = rx.Observable.fromInstanceLeftGame(prompt)
	local exitStream = glib.getExitStream(prompt)
	local rosterCollectionStopped = rx.Observable.from(state.isCollectingRoster)
		:reject()
		:first()
	local rosterFull = activityUtil.getTeamRosterChangedStream(activityInstance, team, true)
		:map(dart.bind(activityUtil.isTeamRosterFull, activityInstance, team))
		:takeUntil(terminator)

	-- Set join button according to roster full
	rosterFull:subscribe(function (isFull)
		prompt.JoinButton.state.propertySwitcher.propertySet.Value = (isFull and "full" or "open")
	end)

	-- Timer updating
	local pulse = rx.Observable.heartbeat():startWith(0):map(function ()
		return finishTime - os.time()
	end):takeUntil(terminator)
	pulse:map(math.floor):subscribe(function (t)
		prompt.TimerLabel.Text = t
	end)
	pulse
		:filter(dart.lessThan(0))
		:merge(exitStream, localPlayerCompeting:filter(), rosterCollectionStopped)
		:first()
		-- :subscribe(dart.bind(killPrompt, prompt))

	-- Connect to join button text
	rx.Observable.from(prompt.JoinButton.Activated):first()
		:map(dart.constant(activityInstance))
		:subscribe(dart.forward(genes.activity.net.RosterJoinRequested))

	-- Show and parent
	glib.playAnimation(Core.animations.activityPrompt.show, prompt)
	prompt.Parent = Core.Container
	prompt.Visible = true
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

genesUtil.observeStateValue(genes.activity, "isCollectingRoster")
	:filter(dart.select(2))
	:filter(function (activityInstance)
		return activityUtil.getTeamIndex(activityInstance, env.LocalPlayer.Team)
	end)
	:reject(dart.bind(activityUtil.isPlayerCompeting, env.LocalPlayer))
	:subscribe(createStartupPrompt)

-- Bind activity leave buton
localPlayerCompeting:startWith(false):subscribe(setLeaveButtonVisible)
rx.Observable.from(leaveButton.Activated):subscribe(dart.forward(genes.activity.net.LeaveActivityRequested))
