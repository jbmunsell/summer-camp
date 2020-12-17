--
--	Jackson Munsell
--	14 Dec 2020
--	snowball.server.lua
--
--	snowball gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local snowballs = genesUtil.initGene(genes.snowball)

-- Destroy snowball on impact
local hitStream = snowballs:flatMap(function (instance)
	return rx.Observable.from(instance.interface.projectile.ServerHit)
		:map(dart.carry(instance))
end)
hitStream:delay(3):subscribe(dart.destroy)
