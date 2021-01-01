--
--	Jackson Munsell
--	18 Dec 2020
--	kingOfTheHill.server.lua
--
--	kingOfTheHill gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local activityUtil = require(genes.activity.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Activity state
local function getKingTeam(activityInstance)
	-- Check all players to see if they are inside the hill
	local state = activityInstance.state.activity
	local pitch = activityInstance.config.activity.pitch.Value
	local captureZone = pitch.functional.CaptureZone
	local has = {}
	for _, teamFolder in pairs(state.roster:GetChildren()) do
		for _, playerValue in pairs(teamFolder:GetChildren()) do
			local root = axisUtil.getPlayerHumanoidRootPart(playerValue.Value)
			if root and axisUtil.isPointInPartXZ(root.Position, captureZone)
			and root.Position.Y > captureZone.Position.Y then
				table.insert(has, teamFolder)
				break
			end
		end
	end

	-- We are only capturing if ONLY ONE team is in the zone
	return (#has == 1 and state.sessionTeams[has[1].Name].Value or nil)
end
local function getWinningTeam(activityInstance)
	local state = activityInstance.state.activity
	for _, val in pairs(state.score:GetChildren()) do
		if val.Value >= activityInstance.config.kingOfTheHill.timeToWin.Value then
			return state.sessionTeams[val.Name].Value
		end
	end
end

-- Hit count
local function decreaseHitCount(player)
	local v = player.state.activityData.kingOfTheHill.hits
	v.Value = v.Value - 1
end
local function resetHitCount(activityInstance, player)
	player.state.activityData.kingOfTheHill.hits.Value = activityInstance.config.kingOfTheHill.playerHits.Value
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local instanceStream = genesUtil.initGene(genes.activity.kingOfTheHill)

-- Basic activity streams
local sessionStart, sessionEnd = activityUtil.getSessionStateStreams(genes.activity.kingOfTheHill)
local playStartStream = activityUtil.getPlayStartStream(genes.activity.kingOfTheHill)
local scoreChangedStream = activityUtil.getScoreChangedStream(genes.activity.kingOfTheHill)

-- Stream producing the team that dominates the hill, nil if no team OR contested
genesUtil.getInstanceStream(genes.activity.kingOfTheHill):flatMap(function (activityInstance)
	local state = activityInstance.state.activity
	return rx.Observable.from(state.isCollectingRoster)
		:map(function (collecting)
			return not collecting and state.inSession.Value
		end)
		:switchMap(function (inPlay)
			return inPlay
			and rx.Observable.heartbeat()
				:map(dart.bind(getKingTeam, activityInstance))
				:distinctUntilChanged()
			or rx.Observable.just(nil)
		end):map(dart.carry(activityInstance))
end):merge(sessionEnd:map(dart.select(1))):subscribe(function (activityInstance, team)
	activityInstance.state.kingOfTheHill.capturingTeam.Value = team
end)

-- Stream that fires when a player's kingOfTheHillHits value reaches zero
local function carryActivity(obs)
	return obs:map(function (player)
		return activityUtil.getPlayerActivity(player), player
	end)
	:filter()
	:filter(function (activityInstance)
		return genesUtil.hasGeneTag(activityInstance, genes.activity.kingOfTheHill)
	end)
end
local hitsChanged = genesUtil.deepObserveStateValue(genes.player.activityData, {"kingOfTheHill", "hits"})
local playerDroppedStream = hitsChanged
	:filter(function (_, hits)
		return hits == 0
	end)
	:pipe(carryActivity)

---------------------------------------------------------------------------------------------------
-- Subscriptions
---------------------------------------------------------------------------------------------------

-- Terminate when an entire team leaves
activityUtil.getSingleTeamLeftStream(genes.activity.kingOfTheHill):subscribe(activityUtil.zeroJoinTerminate)

-- Show and hide billboard according to this person being in a roster
local playerStream = genesUtil.getInstanceStream(genes.player.activityData)
playerStream
	:flatMap(function (player)
		return rx.Observable.from(player.CharacterAdded):startWith(player.Character):filter()
	end)
	:subscribe(function (character)
		local gui = env.res.snow.HitsGui:Clone()
		gui.Enabled = false
		gui.Parent = character.Head
	end)
playerStream
	:flatMap(function (player)
		return activityUtil.getPlayerActivityStream(player):map(dart.drag(player))
	end)
	:subscribe(function (activityInstance, player)
		local gui = player.Character.Head:WaitForChild("HitsGui")
		gui.Enabled = activityInstance and genesUtil.hasGeneTag(activityInstance, genes.activity.kingOfTheHill)
	end)

-- Render number of hearts on hits changed
hitsChanged:subscribe(function (player, hits)
	if player.Character then
		local gui = player.Character.Head:WaitForChild("HitsGui")
		for i = 1, 3 do
			gui:FindFirstChild("Heart" .. i, true).Visible = (i <= hits)
		end
	end
end)

-- Set scoreboard and team link on go
sessionStart:subscribe(function (activityInstance)
	local pitch = activityInstance.config.activity.pitch.Value
	activityUtil.updateScoreboardTeams(activityInstance)
	for i = 1, 2 do
		pitch["ArenaProps" .. i].state.teamLink.team.Value = activityInstance.state.activity.sessionTeams[i].Value
	end
end)
scoreChangedStream:subscribe(activityUtil.updateScoreboardScore)

-- Spawn players on session start
sessionStart:subscribe(activityUtil.ejectPlayers)
playStartStream:subscribe(activityUtil.spawnAllPlayers)
activityUtil.getPlayerAddedToRosterStream(genes.activity.kingOfTheHill)
	:merge(playerDroppedStream:delay(2))
	:subscribe(function (activityInstance, player)
		resetHitCount(activityInstance, player)
		activityUtil.releasePlayerRagdoll(activityInstance, player)
		activityUtil.spawnPlayer(activityInstance, player)
	end)

-- Decrease player hits when hit by a snowball
genesUtil.getInstanceStream(genes.snowball):flatMap(function (instance)
	return rx.Observable.from(instance.interface.projectile.ServerHit)
		:map(axisUtil.getPlayerFromCharacterDescendant)
		:filter()
		:reject(function (hitPlayer)
			return hitPlayer.Team == instance.state.projectile.owner.Value.Team
		end)
		:pipe(carryActivity)
		:filter(activityUtil.isInPlay)
		:map(dart.select(2))
end):subscribe(decreaseHitCount)

-- Ragdolling and freeing
playerDroppedStream:subscribe(activityUtil.ragdollPlayer)
sessionEnd:delay(2):subscribe(activityUtil.releaseAllRagdolls)

-- Change flag team according to capturing team
genesUtil.observeStateValue(genes.activity.kingOfTheHill, "capturingTeam")
	:subscribe(function (activityInstance, team)
		local pitch = activityInstance.config.activity.pitch.Value
		genesUtil.waitForGene(pitch.Banner, genes.teamLink)
		pitch.Banner.state.teamLink.team.Value = team
	end)

-- Increase team score on heartbeat
instanceStream:flatMap(function (activityInstance)
	return rx.Observable.from(activityInstance.state.kingOfTheHill.capturingTeam):switchMap(function (team)
		return team
		and rx.Observable.heartbeat():map(dart.carry(team))
		or rx.Observable.never()
	end):map(dart.carry(activityInstance))
end):subscribe(activityUtil.changeTeamScore)

-- Declare a winner when the score threshold is crossed
scoreChangedStream
	:map(function (activityInstance) return activityInstance, getWinningTeam(activityInstance) end)
	:filter(dart.select(2))
	:subscribe(activityUtil.declareWinner)
