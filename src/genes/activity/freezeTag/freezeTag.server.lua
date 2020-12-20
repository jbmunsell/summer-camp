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

	-- Create ice box around player
	axisUtil.destroyChildren(character, "IceBlock")
	if frozen then
		local ice = env.res.snow.IceBlock:Clone()
		local weld = Instance.new("Weld")
		weld.Part0 = root
		weld.Part1 = ice
		weld.Parent = ice
		ice.CFrame = root.CFrame
		ice.Parent = character
	end

	-- Weld them to the terrain to prevent movement????????
	axisUtil.destroyChildren(character, "FreezeTagWeld")
	if frozen then
		local freezeWeld = Instance.new("Weld")
		freezeWeld.C0 = root.CFrame
		freezeWeld.Part0 = workspace.Terrain
		freezeWeld.Part1 = root
		freezeWeld.Name = "FreezeTagWeld"
		freezeWeld.Parent = character
	end
end
local function renderPlayerFreezer(player, freezer)
	-- Get stuff
	local character = player.Character
	local root = axisUtil.getPlayerHumanoidRootPart(player)
	if not root then return end

	-- Create freezer around player
	axisUtil.destroyChildren(character, "_Freezer")
	if freezer then
		local freezerModel = env.res.snow.Freezer:Clone()
		freezerModel.Name = "_Freezer"
		local weld = Instance.new("Weld")
		weld.Part0 = character.UpperTorso
		weld.Part1 = freezerModel.PrimaryPart
		weld.Parent = freezerModel
		freezerModel:SetPrimaryPartCFrame(root.CFrame)
		freezerModel.Parent = character
	end
end

-- Score
local function updateScore(activityInstance)
	local state = activityInstance.state.activity
	for i = 1, 2 do
		local score = 0
		for _, v in pairs(state.roster[i]:GetChildren()) do
			local tagState = v.Value and v.Value.state.activityData.freezeTag
			if not tagState.freezer.Value and not tagState.frozen.Value then
				score = score + 1
			end
		end
		state.score[i].Value = score
	end
end
local function getWinningTeam(activityInstance)
	local state = activityInstance.state.activity
	for i = 1, 2 do
		if state.score[i].Value == 0 then
			return state.sessionTeams[3 - i].Value
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
			bState.frozen.Value = true
		elseif bState.freezer.Value and not aState.freezer.Value then
			aState.frozen.Value = true
		end

	-- If they're on the same team and NEITHER is a freezer,
	-- 	then unfreeze both
	else
		if not aState.freezer.Value and not bState.freezer.Value then
			aState.frozen.Value = false
			bState.frozen.Value = false
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
local playerAddedToRosterStream = activityUtil.getPlayerAddedToRosterStream(genes.activity.freezeTag)

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
activityUtil.getPlayerAddedToRosterStream(genes.activity.freezeTag):subscribe(activityUtil.spawnPlayer)

-- Set scoreboard and team link on go
sessionStart:subscribe(function (activityInstance)
	local pitch = activityInstance.config.activity.pitch.Value
	activityUtil.updateScoreboardTeams(activityInstance)
	for i = 1, 2 do
		pitch["ArenaProps" .. i].state.teamLink.team.Value = activityInstance.state.activity.sessionTeams[i].Value
	end
end)
scoreChangedStream:subscribe(activityUtil.updateScoreboardScore)

-- Players touching
instanceStream:flatMap(function (activityInstance)
	return rx.Observable.from(activityInstance.state.activity.inSession):switchMap(function (inSession)
		return inSession and rx.Observable.heartbeat() or rx.Observable.never()
	end):map(dart.carry(activityInstance))
end):subscribe(function (activityInstance)
	foreachPlayer(activityInstance, function (a)
		foreachPlayer(activityInstance, function (b)
			if a == b then return end
			local aroot = axisUtil.getPlayerHumanoidRootPart(a)
			local broot = axisUtil.getPlayerHumanoidRootPart(b)
			if aroot and broot and (aroot.Position - broot.Position).magnitude <= 3 then
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
	:merge(playerAddedToRosterStream, playerRemovedFromRosterStream)
	:subscribe(updateScore)

-- Render freeze according to value
frozenChanged:subscribe(renderPlayerFrozen)
freezerChanged:subscribe(renderPlayerFreezer)

-- Declare winner when a team is entirely frozen
scoreChangedStream
	:filter(activityUtil.isInPlay)
	:map(function (activityInstance) return activityInstance, getWinningTeam(activityInstance) end)
	:filter(dart.select(2))
	:subscribe(activityUtil.declareWinner)
