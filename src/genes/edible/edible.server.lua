--
--	Jackson Munsell
--	19 Oct 2020
--	edible.server.lua
--
--	Edible gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local edible = genes.edible
local pickup = genes.pickup

-- modules
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local pickupUtil = require(pickup.util)
local edibleUtil = require(edible.util)

-- Bind all instances
genesUtil.initGene(edible)

-- Eat on click
pickupUtil.getActivatedStream(edible)
	:map(dart.drop(1))
	:reject(edibleUtil.isEaten)
	:subscribe(edibleUtil.eat)
