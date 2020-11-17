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
local powderSack = genes.powderSack

-- modules
local rx = require(axis.lib.rx)
local genesUtil = require(genes.util)
local fireplaceUtil = require(genes.fireplace.util)
local powderSackUtil = require(powderSack.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
genesUtil.initGene(powderSack)

-- Render color on init
genesUtil.crossObserveStateValue(powderSack, genes.color, "color")
	:subscribe(powderSackUtil.renderColor)

-- Connect to sack thrown
-- throwUtil.getThrowStream(powderSack)
-- 	:map(dart.drag(true))
-- 	:subscribe(powderSackUtil.setHot)

-- Blow it when one gets close enough to a fire
genesUtil.getInstanceStream(powderSack):subscribe(function (instance)
	rx.Observable.fromProperty(instance.PrimaryPart, "Position"):subscribe(function ()
		if not powderSackUtil.isPoofed(instance) then
			local fire = fireplaceUtil.getFireWithinRadius(instance, "powderAffectRadius")
			if fire then
				powderSackUtil.poofSackInFire(instance, fire)
			end
		end
	end)
end)
