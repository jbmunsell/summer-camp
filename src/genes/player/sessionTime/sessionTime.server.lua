--
--	Jackson Munsell
--	13 Nov 2020
--	sessionTime.server.lua
--
--	sessionTime gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local sessionTime = genes.player.sessionTime

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local playerUtil = require(genes.player.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Increase session time
local function increaseSessionTime(player, dt)
	player.state.sessionTime.sessionTime.Value = player.state.sessionTime.sessionTime.Value + dt
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
playerUtil.initPlayerGene(sessionTime)

-- Increase on heartbeat
rx.Observable.heartbeat()
	:flatMap(function (dt)
		return rx.Observable.from(genesUtil.getInstances(sessionTime))
			:map(dart.drag(dt))
	end)
	:subscribe(increaseSessionTime)
