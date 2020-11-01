--
--	Jackson Munsell
--	31 Oct 2020
--	stick.server.lua
--
--	Stick server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local stick = genes.stick

-- modules
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Bind all trays
genesUtil.initGene(stick)
