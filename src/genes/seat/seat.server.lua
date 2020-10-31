--
--	Jackson Munsell
--	29 Oct 2020
--	seat.server.lua
--
--	Seat server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local seat = genes.seat

-- modules
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Streams and subscriptions
---------------------------------------------------------------------------------------------------

-- Init seats to make them interactable
genesUtil.initGene(seat)
