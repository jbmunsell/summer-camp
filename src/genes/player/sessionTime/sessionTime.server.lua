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
local genesUtil = require(genes.util)
local playerUtil = require(genes.player.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
playerUtil.softInitPlayerGene(sessionTime)

-- Increase on heartbeat
rx.Observable.heartbeat():subscribe(function (dt)
	for _, player in pairs(genesUtil.getInstances(sessionTime):raw()) do
		local sessionTimeValue = player.state.sessionTime.sessionTime
		sessionTimeValue.Value = sessionTimeValue.Value + dt
	end
end)
