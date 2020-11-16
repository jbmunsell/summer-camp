--
--	Jackson Munsell
--	13 Nov 2020
--	leader.server.lua
--
--	leader gene server driver
--

-- env
local Players = game:GetService("Players")
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

-- Render character size
local function renderCharacterSize(character)
	-- Get player and humanoid
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or not player then return end

	-- Set scale values
	local isLeader = leaderUtil.isLeader(player)
	for _, c in pairs(env.config.roles.camperSizeModifiers:GetChildren()) do
		humanoid:WaitForChild(c.Name).Value = (isLeader and 1 or c.Value)
	end
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
local playerStream = playerUtil.initPlayerGene(leader)

-- When a player leader value changes, render their character size
genesUtil.observeStateValue(leader, "isLeader")
	:map(dart.index("Character"))
	:merge(playerStream:map(dart.index("CharacterAdded")):flatMap(rx.Observable.from))
	:filter()
	:subscribe(renderCharacterSize)

-- Comply with player requests always
local changeRequestStream = rx.Observable.from(leader.net.RoleChangeRequested)
changeRequestStream:subscribe(setLeader)
changeRequestStream:subscribe(sendRoleChangedAnalytics)
