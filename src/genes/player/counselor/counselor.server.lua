--
--	Jackson Munsell
--	13 Nov 2020
--	counselor.server.lua
--
--	counselor gene server driver
--

-- env
local Teams = game:GetService("Teams")
local Players = game:GetService("Players")
local AnalyticsService = game:GetService("AnalyticsService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local counselor = genes.player.counselor

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local playerUtil = require(genes.player.util)
local sessionTimeUtil = require(genes.player.sessionTime.util)
local counselorUtil = require(counselor.util)
local counselorData = require(counselor.data)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Render new counselor
local function renderNewCounselor(player)
	-- Send gui notification
	local notificationText = string.format("You have been appointed counselor of the %s! You are now "
		.. "in charge of starting team activities. Ask your campers what they want to do.",
		player.Team.Name)
	env.src.gui.notifications.net.Push:FireClient(player, notificationText)
end

-- Add team counselor
local function addTeamCounselor(team)
	local target = genesUtil.getInstances(counselor)
		:filter(function (p) return p.Team == team end)
		:reject(counselorUtil.isCounselor)
		:max(sessionTimeUtil.getSessionTime)
	if target then
		print("Appointing " .. target.Name .. " as counselor")
		target.state.counselor.isCounselor.Value = true

		AnalyticsService:FireEvent("counselorAppointed", {
			playerId = target.UserId,
			sessionTime = sessionTimeUtil.getSessionTime(target),
			numCabinPlayers = #team:GetPlayers(),
		})
	end
end

-- Recalculate counselors for a given team
local function recalculateTeamCounselors(team)
	-- Get current counselors
	local currentCount = counselorUtil.getTeamCounselors(team):size()
	local desiredCount = math.ceil(#team:GetPlayers() / counselorData.campersPerCounselor)
	print(string.format("Counselor calculation, #players: %d, currentCount: %d, desiredCount: %d",
		#team:GetPlayers(), currentCount, desiredCount))

	-- Add new counselors if we need them,
	-- 	but do not remove people who are already counselors if we dip below count
	for _ = currentCount + 1, desiredCount do
		addTeamCounselor(team)
	end
end

-- Render character size
local function renderCharacterSize(character)
	-- Get player and humanoid
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or not player then return end

	-- Set scale values
	local isCounselor = counselorUtil.isCounselor(player)
	for _, c in pairs(env.config.roles.camperSizeModifiers:GetChildren()) do
		humanoid:WaitForChild(c.Name).Value = (isCounselor and 1 or c.Value)
	end
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
local playerStream = playerUtil.initPlayerGene(counselor)

-- When a player changes teams or leaves, recalculate counselors
local teamLostPlayer = rx.Observable.from(Teams:GetTeams())
	:flatMap(function (team)
		return rx.Observable.from(team.PlayerRemoved)
			:map(dart.constant(team))
	end)
playerStream
	:flatMap(function (player)
		return rx.Observable.fromProperty(player, "Team")
			:startWith(player.Team)
	end)
	:merge(teamLostPlayer)
	:reject(dart.equals(Teams["New Arrivals"]))
	:subscribe(recalculateTeamCounselors)

-- When a player counselor value changes, render their character size
local isCounselorStream = genesUtil.observeStateValue(counselor, "isCounselor")
isCounselorStream:filter(dart.select(2)):subscribe(renderNewCounselor)
isCounselorStream
	:map(dart.index("Character"))
	:merge(playerStream:map(dart.index("CharacterAdded")):flatMap(rx.Observable.from))
	:filter()
	:subscribe(renderCharacterSize)
