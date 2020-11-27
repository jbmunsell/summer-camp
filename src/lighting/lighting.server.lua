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
local soundUtil = require(axis.lib.soundUtil)
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
genesUtil.waitForGene(Lighting, genes.propertySwitcher)
for _, set in pairs(Lighting.config.propertySwitcher.propertySets:GetChildren()) do
	local t = tonumber(set.Name)
	scheduleUtil.getTimeOfDayStream(t):subscribe(dart.bind(setPropertySet, set))
end

local rooster = env.res.audio.sounds.Rooster
local twinkle = env.res.audio.sounds.NightTwinkle
scheduleUtil.getLiveTimeOfDayStream(6):subscribe(dart.bind(soundUtil.playSoundGlobal, rooster))
scheduleUtil.getLiveTimeOfDayStream(18):subscribe(dart.bind(soundUtil.playSoundGlobal, twinkle))
