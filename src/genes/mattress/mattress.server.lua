--
--	Jackson Munsell
--	11 Oct 2020
--	mattress.server.lua
--
--	Mattress server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local mattress = genes.mattress

-- modules
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Streams and subscriptions
---------------------------------------------------------------------------------------------------

-- Init mattresses to make them interactable
genesUtil.initGene(mattress)
