--
--	Jackson Munsell
--	19 Dec 2020
--	freezeTag.server.lua
--
--	freezeTag gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local collection = require(axis.lib.collection)
local genesUtil = require(genes.util)
local activityUtil = require(genes.activity.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Player frozen
local function renderPlayerFrozen(player, frozen)
	-- Get stuff
	local character = player.Character
	local root = axisUtil.getPlayerHumanoidRootPart(player)
	if not root then return end

	-- TODO: Create ice box around player

	-- Weld them to the terrain to prevent movement????????
	axisUtil.destroyChildren(character, "FreezeTagWeld")
	if frozen then
		local weld = Instance.new("Weld")
		weld.Part0 = workspace.Terrain
		weld.Part1 = root
		weld.C0 = root.CFrame
		weld.Name = "FreezeTagWeld"
		weld.Parent = character
	end
end
local function renderPlayerFreezer(player, freezer)
	-- Get stuff

	-- TODO: Remove outfit

	-- TODO: Add outfit if freezer
end

-- Score
local function updateScore(activityInstance)
	local state = activityInstance.state.activity
	for i = 1, 2 do
		local score = 0
		for _, v in pairs(state.roster[i]:GetChildren()) do
			if v.Value and not v.Value.state.activityData.freezeTag.frozen.Value then
				score = score + 1
			end
		end
		state.score[i].Value = score
	end
end
local function getWinningTeam(activityInstance)
	local state = activityInstance.state.activity
	for _, val in pairs(state.score:GetChildren()) do
		if val.Value == 0 then
			return state.sessionTeams[val.Name].Value
		end
	end
end

-- Player business
local function foreachPlayer(activityInstance, f)
	for _, teamFolder in pairs(activityInstance.state.activity.roster:GetChildren()) do
		for _, v in pairs(teamFolder:GetChildren()) do
			f(v.Value)
		end
	end
end
local function resetPlayerState(player)
	local state = player.state.activityData.freezeTag
	state.frozen.Value = false
	state.freezer.Value = false
end
local function handlePlayersTouching(a, b)
	-- Get states
	local aState = a.state.activityData.freezeTag
	local bState = b.state.activityData.freezeTag

	-- If they're on different teams and ONE is a freezer,
	-- 	then freeze the other one
	if a.Team ~= b.Team then
		if aState.freezer.Value and not bState.freezer.Value then
			b.frozen.Value = true
		elseif bState.freezer.Value and not aState.freezer.Value then
			a.frozen.Value = true
		end

	-- If they're on the same team and NEITHER is a freezer,
	-- 	then unfreeze both
	else
		if not aState.freezer.Value and not bState.freezer.Value then
			a.frozen.Value = false
			b.frozen.Value = false
		end
	end
end
local function checkFreezers(activityInstance)
	for _, teamFolder in pairs(activityInstance.state.activity.roster:GetChildren()) do
		local hasFreezer = false
		for _, v in pairs(teamFolder:GetChildren()) do
			if v.Value and v.Value.state.activityData.freezeTag.freezer.Value then
				hasFreezer = true
				break
			end
		end
		if not hasFreezer then
			local v = collection.getRandom(teamFolder)
			if v then v.Value.state.activityData.freezeTag.freezer.Value = true end
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local instanceStream = genesUtil.initGene(genes.activity.freezeTag)

-- Basic activity streams
local sessionStart = activityUtil.getSessionStateStreams(genes.activity.freezeTag)
local playStartStream = activityUtil.getPlayStartStream(genes.activity.freezeTag)
local scoreChangedStream = activityUtil.getScoreChangedStream(genes.activity.freezeTag)
local playerRemovedFromRosterStream = activityUtil.getPlayerRemovedFromRosterStream(genes.activity.freezeTag)

-- Player frozen changed
local frozenChanged = genesUtil.deepObserveStateValue(genes.player.activityData, {"freezeTag", "frozen"})
local freezerChanged = genesUtil.deepObserveStateValue(genes.player.activityData, {"freezeTag", "freezer"})

---------------------------------------------------------------------------------------------------
-- Subscriptions
---------------------------------------------------------------------------------------------------

-- Terminate when an entire team leaves
activityUtil.getSingleTeamLeftStream(genes.activity.freezeTag):subscribe(activityUtil.zeroJoinTerminate)

-- Spawn players on session start
sessionStart:subscribe(activityUtil.ejectPlayers)
playStartStream:subscribe(activityUtil.spawnAllPlayers)

-- Players touching
instanceStream:flatMap(function (activityInstance)
	return rx.Observable.from(activityInstance.state.activity.inSession):switchMap(function (inSession)
		return inSession and rx.Observable.heartbeat() or rx.Observable.never()
	end):map(dart.carry(activityInstance))
end):subscribe(function (activityInstance)
	foreachPlayer(activityInstance, function (a)
		foreachPlayer(activityInstance, function (b)
			local aroot = axisUtil.getPlayerHumanoidRootPart(a)
			local broot = axisUtil.getPlayerHumanoidRootPart(b)
			if aroot and broot and (aroot.Position - broot.Position).magnitude <= 2 then
				handlePlayersTouching(a, b)
			end
		end)
	end)
end)

-- Reset state when they leave the roster
playerRemovedFromRosterStream:map(dart.select(2)):subscribe(resetPlayerState)

-- On play start OR player removed from roster, check if we need a freezer and reappoint
playStartStream:merge(playerRemovedFromRosterStream):subscribe(checkFreezers)

-- Recalculate score when freeze value changes
frozenChanged
	:map(function (player)
		return activityUtil.getPlayerActivity(player)
	end)
	:filter()
	:filter(dart.follow(genesUtil.hasGeneTag, genes.activity.freezeTag))
	:subscribe(updateScore)

-- Render freeze according to value
frozenChanged:subscribe(renderPlayerFrozen)
freezerChanged:subscribe(renderPlayerFreezer)

-- Declare winner when a team is entirely frozen
scoreChangedStream
	:map(function (activityInstance) return activityInstance, getWinningTeam(activityInstance) end)
	:filter(dart.select(2))
	:subscribe(activityUtil.declareWinner)
