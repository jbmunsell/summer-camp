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
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local fireplaceUtil = require(fireplace.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- The reason this exists is to standardize overriding CONFIG folders in studio,
-- 	not state folders.
local function pullFireColor(instance)
	instance.state.fireplace.color.Value = instance.config.fireplace.color.Value
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Init gene
local fireplaces = genesUtil.initGene(fireplace)

-- Pull fire color on init
fireplaces:subscribe(pullFireColor)

-- Render color changed
fireplaces
	:flatMap(function (instance)
		return rx.Observable.from(instance.state.fireplace.color)
			:map(dart.constant(instance))
	end)
	:subscribe(fireplaceUtil.renderFireColor)

-- Render enabled
fireplaces
	:flatMap(function (instance)
		return rx.Observable.from(instance.state.fireplace.enabled)
			:map(dart.constant(instance))
	end)
	:subscribe(fireplaceUtil.renderFireplaceEnabled)
