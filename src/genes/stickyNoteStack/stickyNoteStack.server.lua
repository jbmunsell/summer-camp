--
--	Jackson Munsell
--	22 Oct 2020
--	stickyNoteStack.server.lua
--
--	Sticky note stack server driver - handles sticky note placement
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Init all sticky note stacks
genesUtil.initGene(genes.stickyNoteStack)
