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
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.proximitySensor)

-- Track player character position
rx.Observable.heartbeat():subscribe(function ()
	local root = axisUtil.getLocalHumanoidRootPart()
	if not root then return end

	for _, sensor in pairs(genesUtil.getInstances(genes.proximitySensor):raw()) do
		local instancePosition = sensor.PrimaryPart.Position
		local range = sensor.config.proximitySensor.range.Value
		local isInRange = axisUtil.squareMagnitude(root.Position - instancePosition) <= range
		sensor.state.proximitySensor.isInRange.Value = isInRange
	end
end)
