--
--	Jackson Munsell
--	14 Nov 2020
--	lighting.server.lua
--
--	Lighting server driver. Adjusts lighting property set according to ToD
--

-- env
local Lighting = game:GetService("Lighting")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local scheduleUtil = require(env.src.schedule.util)

---------------------------------------------------------------------------------------------------
-- Set property set
---------------------------------------------------------------------------------------------------

local function setPropertySet(set)
	Lighting.state.propertySwitcher.propertySet.Value = set.Name
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Adjust time of day
genesUtil.waitForState(Lighting, genes.propertySwitcher)
for _, set in pairs(Lighting.config.propertySwitcher.propertySets:GetChildren()) do
	local t = tonumber(set.Name)
	scheduleUtil.getTimeOfDayStream(t):subscribe(dart.bind(setPropertySet, set))
end