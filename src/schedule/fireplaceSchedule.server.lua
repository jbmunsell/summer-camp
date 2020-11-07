--
--	Jackson Munsell
--	31 Oct 2020
--	fireplaceSchedule.server.lua
--
--	Server driver that turns on and off fireplaces according to time of day.
-- 	Will probably remove in a later iteration once fires are moved to manual ignition.
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local schedule = env.src.schedule
local genes = env.src.genes
local fireplace = genes.fireplace

-- modules
local rx = require(axis.lib.rx)
local fx = require(axis.lib.fx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local scheduleStreams = require(schedule.streams)

---------------------------------------------------------------------------------------------------
-- Variables and subjects
---------------------------------------------------------------------------------------------------

local firesEnabled = rx.BehaviorSubject.new()

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Render fireplace
local function renderFireplace(instance)
	instance.state.fireplace.enabled.Value = firesEnabled:getValue()
	-- fx.setFXEnabled(instance, firesEnabled:getValue())
end

-- Set fireplaces enabled
local function setFireplacesEnabled()
	genesUtil.getInstances(fireplace)
		:foreach(renderFireplace)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Turn off for free time and turn off for lights out
scheduleStreams.scheduleChunk
	:map(dart.isNamed("FreeTime"))
	:multicast(firesEnabled)
firesEnabled
	:subscribe(setFireplacesEnabled)

-- Set new fires to enabled when they spawn
genesUtil.getInstanceStream(fireplace)
	:subscribe(renderFireplace)
