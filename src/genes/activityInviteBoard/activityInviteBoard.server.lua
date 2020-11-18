--
--	Jackson Munsell
--	16 Nov 2020
--	activityInviteBoard.server.lua
--
--	activityInviteBoard gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function createStampEntry(instance, team)
	Instance.new("NumberValue", instance.state.activityInviteBoard.inviteStamps).Name = team.Name
end

local function updateStamp(instance, team)
	instance.state.activityInviteBoard.inviteStamps[team.Name].Value = os.time()
end

local function getCooldownForTeam(instance, team)
	local state = instance.state.activityInviteBoard
	local config = instance.config.activityInviteBoard
	return (state.inviteStamps[team.Name].Value + config.inviteCooldown.Value) - os.time()
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
local inviteBoards = genesUtil.initGene(genes.activityInviteBoard)

-- Create team stamp entries
inviteBoards:flatMap(function (instance)
	return genesUtil.getInstanceStream(genes.team):map(dart.carry(instance))
end):subscribe(createStampEntry)

-- Connect to invite request
local validRequest = rx.Observable.from(genes.activityInviteBoard.net.InviteSendRequested)
	:filter(dart.boolAnd)
	:reject(function (player, instance)
		return getCooldownForTeam(instance, player.Team) > 0
	end)
	:share()
validRequest
	:map(function (p, instance) return instance, p.Team end)
	:subscribe(updateStamp)
validRequest
	:flatMap(function (player, instance)
		return rx.Observable.from(player.Team:GetPlayers())
			:reject(dart.equals(player))
			:map(dart.drag(instance, player))
	end)
	:subscribe(dart.forward(genes.activityInviteBoard.net.InviteSent))
