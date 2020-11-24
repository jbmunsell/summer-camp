--
--	Jackson Munsell
--	23 Nov 2020
--	job.util.lua
--
--	job gene util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
local genesUtil = require(genes.util)

-- lib
local jobUtil = {}

-- get job from gamepass id
function jobUtil.getJobFromGamepassId(gamepassId)
	for _, job in pairs(genesUtil.getInstances(genes.job):raw()) do
		if job.config.job.gamepassId.Value == gamepassId then
			return job
		end
	end
end

-- return lib
return jobUtil
