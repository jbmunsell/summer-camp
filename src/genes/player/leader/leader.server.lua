--
--	Jackson Munsell
--	13 Nov 2020
--	leader.server.lua
--
--	leader gene server driver
--

-- env
local AnalyticsService = game:GetService("AnalyticsService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local leader = genes.player.leader

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local playerUtil = require(genes.player.util)
local leaderUtil = require(leader.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Set leader
local function setLeader(player, isLeader)
	player.state.leader.isLeader.Value = isLeader
end

-- Send role changed analytics
local function sendRoleChangedAnalytics(player, isLeader)
	AnalyticsService:FireEvent("roleChangeRequested", {
		playerId = player.UserId,
		isLeader = isLeader,
	})
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
local playerStream = playerUtil.hardInitPlayerGene(leader)

-- When a player leader value changes, render their character size
genesUtil.observeStateValue(leader, "isLeader")
	:map(dart.index("Character"))
	:merge(playerStream:map(dart.index("CharacterAdded")):flatMap(rx.Observable.from))
	:filter()
	:subscribe(leaderUtil.renderCharacterSize)

-- Comply with player requests always
local changeRequestStream = rx.Observable.from(leader.net.RoleChangeRequested)
changeRequestStream:subscribe(setLeader)
changeRequestStream:subscribe(sendRoleChangedAnalytics)
