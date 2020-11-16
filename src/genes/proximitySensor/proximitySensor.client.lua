--
--	Jackson Munsell
--	15 Nov 2020
--	proximitySensor.client.lua
--
--	proximitySensor gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function setInRange(instance, isInRange)
	instance.state.proximitySensor.isInRange.Value = isInRange
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local sensors = genesUtil.initGene(genes.proximitySensor)

-- Track player character position
sensors:flatMap(function (instance)
	local range = instance.config.proximitySensor.range.Value
	return rx.Observable.heartbeat()
		:map(function ()
			return env.LocalPlayer.Character
			and env.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		end)
		:filter()
		:map(dart.index("CFrame"))
		:map(function (cf)
			return (cf.p - axisUtil.getPosition(instance)).magnitude <= range
		end)
		:distinctUntilChanged()
		:map(dart.carry(instance))
end):subscribe(setInRange)
