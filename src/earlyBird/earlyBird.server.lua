--
--	Jackson Munsell
--	11 Nov 2020
--	earlyBird.server.lua
--
--	Early bird badge server driver
--

-- env
local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local BadgeId = 0

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Award badge
local function awardBadge(player)
	pcall(function ()
		BadgeService:AwardBadge(player.UserId, BadgeId)
	end)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Award to player on entered
rx.Observable.from(Players.PlayerAdded)
	:startWithTable(Players:GetPlayers())
	:map(dart.carry(awardBadge))
	:map(dart.bind)
	:subscribe(spawn)
