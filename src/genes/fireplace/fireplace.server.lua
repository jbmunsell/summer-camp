--
--	Jackson Munsell
--	31 Oct 2020
--	fireplace.server.lua
--
--	Fireplace gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local fireplace = genes.fireplace

-- modules
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
genesUtil.observeStateValueWithInit(fireplace, "color")
	:subscribe(fireplaceUtil.renderFireColor)

-- Render enabled
genesUtil.observeStateValue(fireplace, "enabled")
	:subscribe(fireplaceUtil.renderFireplaceEnabled)
