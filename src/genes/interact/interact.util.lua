--
--	Jackson Munsell
--	04 Sep 2020
--	interactUtil.lua
--
--	Interact util
--

-- env
local RunService = game:GetService("RunService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local interact = genes.interact

-- modules
local rx = require(axis.lib.rx)
local genesUtil = require(genes.util)

-- lib
local interactUtil = {}

-- Get interact stream
function interactUtil.getInteractStream(class)
	if RunService:IsServer() then
		return rx.Observable.from(interact.net.ClientInteracted)
			:filter(function (_, instance)
				return genesUtil.hasFullState(instance, class)
			end)
	elseif RunService:IsClient() then
		return rx.Observable.from(interact.interface.ClientInteracted)
			:filter(function (instance)
				return genesUtil.hasFullState(instance, class)
			end)
	end
end

-- return lib
return interactUtil
