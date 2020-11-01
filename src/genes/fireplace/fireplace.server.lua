--
--	Jackson Munsell
--	31 Oct 2020
--	fireplace.server.lua
--
--	Fireplace gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local fireplace = genes.fireplace

-- modules
local rx = require(axis.lib.rx)
local fx = require(axis.lib.fx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Init gene
local fireplaces = genesUtil.initGene(fireplace)

-- Render
fireplaces
	:flatMap(function (instance)
		return rx.Observable.from(instance.state.fireplace.enabled)
			:map(dart.carry(instance))
	end)
	:subscribe(fx.setFXEnabled)
