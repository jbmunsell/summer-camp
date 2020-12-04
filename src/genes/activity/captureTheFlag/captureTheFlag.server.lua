--
--	Jackson Munsell
--	24 Nov 2020
--	captureTheFlag.server.lua
--
--	captureTheFlag gene server driver
--

-- env
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local soundUtil = require(axis.lib.soundUtil)
local collection = require(axis.lib.collection)
local genesUtil = require(genes.util)
local activityUtil = require(genes.activity.util)
local multiswitchUtil = require(genes.multiswitch.util)
local plantInGroundUtil = require(genes.plantInGround.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Create flag switches
local function initFlags(activityInstance)
	for i = 1, 2 do
		local flag = activityInstance["Flag" .. i]
		genesUtil.waitForGene(flag, genes.interact)
		multiswitchUtil.createSwitch(flag, "interact", "captureTheFlag", false)
		local copy = flag:Clone()
		copy.Parent = ReplicatedStorage
		collection.addValue(activityInstance.state.captureTheFlag.flagSeeds, copy)
		flag:Destroy()
	end
end

-- Prepare bases for a match by linking teams and spawning balloons
local function prepareBases(activityInstance)
	for teamIndex = 1, 2 do
		-- Get team
		local team = activityInstance.state.activity.sessionTeams[teamIndex].Value
		local base = activityInstance["Base" .. teamIndex]

		-- Clone flag
		local flag = activityInstance.state.captureTheFlag.flagSeeds[teamIndex].Value:Clone()
		flag.Parent = activityInstance
		genesUtil.waitForGene(flag, genes.teamLink)
		genesUtil.waitForGene(flag, genes.pickup)
		genesUtil.waitForGene(flag, genes.plantInGround)
		wait()
		axisUtil.destroyChildren(flag, "StationaryWeld")
		flag:SetPrimaryPartCFrame(base:FindFirstChild("FlagPlant", true).CFrame + Vector3.new(0, 5, 0))
		plantInGroundUtil.tryPlant(flag)

		-- Link team
		base.state.teamLink.team.Value = team
		flag.state.teamLink.team.Value = team

		-- Spawn balloons
		for _, attachment in pairs(base:GetDescendants()) do
			if attachment.Name == "BalloonSpawn" then
				local balloon = env.res.objects.Balloon:Clone()
				balloon.Parent = activityInstance
				genesUtil.waitForGene(balloon, genes.color)
				balloon.state.color.color.Value = team.config.team.color.Value
				local weld = axisUtil.snapAttachAttachments(attachment.Parent, attachment, balloon, "StickAttachment")
				weld.Parent = balloon
				weld.Name = "StationaryWeld"
			end
		end
	end
end
local function destroyBalloons(activityInstance)
	for _, d in pairs(activityInstance:GetDescendants()) do
		if d.Name == "Balloon" then d:Destroy() end
	end
end
local function unlinkBases(activityInstance)
	for i = 1, 2 do
		local base = activityInstance["Base" .. i]
		genesUtil.waitForGene(base, genes.teamLink)
		base.state.teamLink.team.Value = nil

		if activityInstance.state.captureTheFlag.flagSeeds:FindFirstChild(i) then
			axisUtil.destroyChild(activityInstance, "Flag" .. i)
		end
	end
end

-- Spawn players
local function spawnPlayer(activityInstance, player)
	local teamIndex = activityUtil.getPlayerTeamIndex(activityInstance, player)
	local spawnPlane = activityInstance["Team" .. teamIndex .. "SpawnPlane"]
	activityUtil.spawnPlayersInPlane({ player }, spawnPlane)
end
local function spawnAllPlayers(activityInstance)
	for i = 1, 2 do
		local players = activityInstance.state.activity.roster[i]:GetChildren()
		for _, value in pairs(players) do
			spawnPlayer(activityInstance, value.Value)
		end
	end
end

-- Is flag in opponent's zone
local function isFlagInOpponentsZone(activityInstance, teamIndex)
	local flag = activityInstance:FindFirstChild("Flag" .. teamIndex)
	if not flag then return false end
	local zone = activityInstance["Base" .. (3 - teamIndex)].PlantVictoryZone
	return axisUtil.isPointInPartXZ(axisUtil.getPosition(flag), zone)
end

-- Declare winner
-- 	This function sets the score and then formally declares a winner so that there is something
-- 	to display on the result gui.
local function declareWinner(activityInstance, teamIndex)
	local value = activityInstance.state.activity.score[teamIndex]
	value.Value = value.Value + 1
	activityUtil.declareWinner(activityInstance, activityInstance.state.activity.sessionTeams[teamIndex].Value)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local activityInstances = genesUtil.initGene(genes.activity.captureTheFlag)

-- Session state streams
local sessionStart, sessionEnd = genesUtil.crossObserveStateValue(genes.activity.captureTheFlag,
	genes.activity, "inSession"):partition(dart.select(2))

-- Play start stream
local playStartStream = sessionStart:flatMap(function (activityInstance)
	return rx.Observable.from(activityInstance.state.activity.isCollectingRoster.Changed)
		:filter(dart.bind(activityUtil.isInSession, activityInstance))
		:reject()
		:first()
		:map(dart.constant(activityInstance))
end)

---------------------------------------------------------------------------------------------------
-- Subscriptions
---------------------------------------------------------------------------------------------------

-- Kill the session with a technical zero join case if one team all leaves
activityUtil.getSingleTeamLeftStream(genes.activity.captureTheFlag):subscribe(activityUtil.zeroJoinTerminate)

-- Create flag interact switches for new instances
activityInstances:subscribe(initFlags)

-- Spawn balloons on session start
sessionStart:subscribe(prepareBases)
sessionEnd:delay(2):subscribe(destroyBalloons)
sessionEnd:delay(2):subscribe(unlinkBases)

-- Whistle
playStartStream:subscribe(function (activityInstance)
	soundUtil.playSound(env.res.audio.sounds.Whistle, activityInstance.Base1.PlantVictoryZone)
	soundUtil.playSound(env.res.audio.sounds.Whistle, activityInstance.Base2.PlantVictoryZone)
end)

-- Listen for flag planted
activityInstances:subscribe(function (activityInstance)
	rx.Observable.heartbeat()
		:filter(dart.bind(activityUtil.isInSession, activityInstance))
		:subscribe(function ()
			for teamIndex = 1, 2 do
				if isFlagInOpponentsZone(activityInstance, teamIndex) then
					declareWinner(activityInstance, 3 - teamIndex)
				end
			end
		end)
end)

sessionStart:merge(playStartStream):subscribe(spawnAllPlayers)

-- Place single when they enter the roster
activityUtil.getPlayerAddedToRosterStream(genes.activity.captureTheFlag):subscribe(spawnPlayer)
