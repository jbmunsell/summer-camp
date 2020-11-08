--
--	Jackson Munsell
--	08 Nov 2020
--	pulloutChair.server.lua
--
--	pulloutChair gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local humanoidHolder = genes.humanoidHolder
local pulloutChair = genes.pulloutChair

-- modules
local genesUtil = require(genes.util)
local pulloutChairUtil = require(pulloutChair.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Log CFrame
local function logCFrame(instance)
	local value = Instance.new("CFrameValue")
	value.Value = instance:GetPrimaryPartCFrame()
	value.Name = "inCFrame"
	value.Parent = instance.config.pulloutChair
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local chairs = genesUtil.initGene(pulloutChair)

-- Log current cframe for all chairs
chairs:subscribe(logCFrame)

-- On owner changed, set pulled out
genesUtil.crossObserveStateValue(pulloutChair, humanoidHolder, "owner")
	:subscribe(pulloutChairUtil.renderChair)
