--
--	Jackson Munsell
--	19 Oct 2020
--	foodTray.server.lua
--
--	Food tray server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local foodTray = genes.foodTray

-- modules
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Bind all trays
genesUtil.initGene(foodTray)
