--
--	Jackson Munsell
--	09 Nov 2020
--	roles.server.lua
--
--	Roles server driver. Handles assignment of counselors
--

-- env
local Teams = game:GetService("Teams")
local Players = game:GetService("Players")
local AnalyticsService = game:GetService("AnalyticsService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local roles = env.src.roles

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local rolesConfig = require(roles.config)
local dataUtil = require(env.src.data.util)
local rolesUtil = require(roles.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- get session time
local function getSessionTime(player)
	dataUtil.waitForState(player, "roles")
	return player.state.roles.sessionTime.Value
end

-- Increase session times for all players
local function increasePlayerSessionTime(player, dt)
	dataUtil.waitForState(player, "roles")
	player.state.roles.sessionTime.Value = player.state.roles.sessionTime.Value + dt
end
local function increaseSessionTimes(dt)
	tableau.from(Players:GetPlayers())
		:foreach(dart.follow(increasePlayerSessionTime, dt))
end

-- Add counselor
local function addCounselor(team)
	local players = tableau.from(team:GetPlayers())
	local target = players
		:reject(rolesUtil.isPlayerCounselor)
		:max(getSessionTime)
	if target then
		rolesUtil.setCounselor(target, true)
		AnalyticsService:FireEvent("counselorAppointed", {
			playerId = target.UserId,
			sessionTime = target.state.roles.sessionTime.Value,
			numCabinPlayers = #team:GetPlayers(),
		})
	end
end

-- Recalculate counselors
local function recalculateCounselors(team)
	-- Get target counselor count and compare with current counselor count
	local players = tableau.from(team:GetPlayers())
	local currentCount = rolesUtil.getTeamCounselors(team):size()
	local desiredCount = math.ceil(players:size() / rolesConfig.campersPerCounselor)
	print(string.format("Counselor calculation, #players: %d, currentCount: %d, desiredCount: %d",
		players:size(), currentCount, desiredCount))

	-- Add new counselors if we need them,
	-- 	but do not remove people who are already counselors if we dip below count
	for _ = currentCount + 1, desiredCount do
		addCounselor(team)
	end
end

-- Change player team
-- 	Here we set their conuselor value to false before changing team
-- 	so that recounts can work appropriately
local function changePlayerTeam(player, team)
	local oldTeam = player.Team
	rolesUtil.setCounselor(player, false)
	player.Team = team

	-- Fire analytics event
	local playerCounts = {}
	for _, t in pairs(Teams:GetTeams()) do
		table.insert(playerCounts, { team = t, count = #t:GetPlayers() })
	end
	table.sort(playerCounts, function (a, b)
		return a.count < b.count
	end)
	local _, newTeamIndex = tableau.from(playerCounts):first(function (v) return v.team == team end)
	AnalyticsService:FireEvent("teamChanged", {
		playerId = player.UserId,
		oldTeam = oldTeam.Name,
		newTeam = team.Name,
		teamRelativePlayers = newTeamIndex,
	})
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Create state for players
local rolesStateStream = dataUtil.registerPlayerState("roles", rolesConfig.state)

-- When a player team changes OR a player leaves the game,
-- 	recalculate counselors
rx.Observable.from(Teams:GetTeams())
	:flatMap(function (team)
		return rx.Observable.from(team.PlayerAdded)
			:merge(rx.Observable.from(team.PlayerRemoved))
			:startWith(0)
			:map(dart.constant(team))
	end)
	:subscribe(recalculateCounselors)

-- Update session times
rx.Observable.heartbeat():subscribe(increaseSessionTimes)

-- Handle team change requests
rx.Observable.from(roles.net.TeamChangeRequested)
	:reject(function (player, team) -- reject if they're already on this team
		return player.Team == team
	end)
	:subscribe(changePlayerTeam)

-- Counselor appointment stream
local counselorAppointed = rolesStateStream
	:flatMap(function (player)
		return rx.Observable.from(player.state.roles.isCounselor)
			:filter()
			:map(dart.constant(player))
	end)

-- Announce counselor to the cabin when they're appointed
counselorAppointed:subscribe(rolesUtil.announceCounselor)

-- All characters of counselors simply must have a billboard gui!
rolesStateStream
	:flatMap(function (player)
		return rx.Observable.from(player.CharacterAdded)
			:startWith(0)
			:map(dart.constant(player))
			:filter(rolesUtil.isPlayerCounselor)
	end)
	:merge(counselorAppointed)
	:map(dart.index("Character"))
	:filter()
	:subscribe(rolesUtil.renderCounselorCharacter)

-- Destroy counselor images when they leave the game or are unmarked
rolesStateStream
	:flatMap(function (player)
		return rx.Observable.from(player.state.roles.isCounselor)
			:reject()
			:merge(rx.Observable.from(Players.PlayerRemoving)
				:filter(dart.equals(player))
				:first())
			:map(dart.constant(player))
	end)
	:map(dart.index("Character"))
	:filter()
	:subscribe(rolesUtil.destroyCounselorRendering)
