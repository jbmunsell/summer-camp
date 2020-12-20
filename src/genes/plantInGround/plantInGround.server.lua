--
--	Jackson Munsell
--	11 Nov 2020
--	plantInGround.server.lua
--
--	plantInGround gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local plantInGroundUtil = require(genes.plantInGround.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local plants = genesUtil.initGene(genes.plantInGround)

-- Set planted to false upon holder gained
genesUtil.crossObserveStateValue(genes.plantInGround, genes.pickup, "holder")
	:filter(dart.select(2))
	:subscribe(function (instance)
		instance.state.plantInGround.planted.Value = false
	end)

-- Stick on activated or optional init
plants:filter(function (instance) return instance.config.plantInGround.initPlant.Value end)
	:merge(genesUtil.crossObserveStateValue(genes.plantInGround, genes.pickup, "holder")
		:reject(dart.select(2))
		:map(dart.select(1)))
	:reject(function (instance)
		return instance.state.pickup.owner.Value -- This is to prevent planting objects when you stow them
		or instance.state.plantInGround.planted.Value
	end)
	:subscribe(plantInGroundUtil.tryPlant)
