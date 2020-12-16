--
--	Jackson Munsell
--	14 Dec 2020
--	snowball.client.lua
--
--	snowball gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local snowballUtil = require(genes.snowball.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local snowballs = genesUtil.initGene(genes.snowball)

-- Snowball hit something
snowballs:flatMap(function (instance)
	return rx.Observable.from(instance.interface.projectile.LocalHit)
		:tap(print)
		:map(dart.select(2)) -- select the position
		:map(dart.carry(instance)) -- carry our snowball
end):subscribe(snowballUtil.popSnowball) -- pop it at the desired position
