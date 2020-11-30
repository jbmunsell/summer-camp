--
--	Jackson Munsell
--	29 Nov 2020
--	jobGiver.client.lua
--
--	jobGiver gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.jobGiver):subscribe(function (instance)
	local job = instance.config.jobGiver.job.Value
	local invite = string.format("Become a %s!", job.config.job.displayName.Value)
	instance:FindFirstChild("JobUI", true):FindFirstChild("TextLabel", true).Text = invite
end)
