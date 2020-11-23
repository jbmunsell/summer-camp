--
--	Jackson Munsell
--	07 Nov 2020
--	powderSack.server.lua
--
--	powderSack gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local genesUtil = require(genes.util)
local fireplaceUtil = require(genes.fireplace.util)
local powderSackUtil = require(genes.powderSack.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
genesUtil.initGene(genes.powderSack)

-- Check positions on heartbeat
local instances = genesUtil.getInstances(genes.powderSack):raw()
rx.Observable.interval(0.2):subscribe(function ()
	for _, instance in pairs(instances) do
		if not powderSackUtil.isPoofed(instance) then
			local fire = fireplaceUtil.getFireWithinRadius(instance, "powderAffectRadius")
			if fire then
				powderSackUtil.poofSackInFire(instance, fire)
			end
		end
	end
end)
