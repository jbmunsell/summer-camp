--
--	Jackson Munsell
--	07 Nov 2020
--	throw.util.lua
--
--	throw gene util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local pickup = genes.pickup
local throw = genes.throw

-- modules
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local pickupUtil = require(pickup.util)

-- non-lib functions
local function getRoot(instance)
	if instance:IsA("BasePart") then
		return instance
	elseif instance:IsA("Model") then
		return instance.PrimaryPart
	else
		error("Unable to get root of instance " .. instance:GetFullName())
	end
end

-- lib
local throwUtil = {}

-- Throw character object
function throwUtil.throwCharacterObject(character, object, target)
	local root = getRoot(object)
	pickupUtil.disownHeldObjects(character)
	pickupUtil.releaseHeldObjects(character)
	root.Velocity = (target - root.Position).unit * object.config.throw.throwMagnitude.Value
	object.state.throw.thrower.Value = character
end

-- Get thrown stream
function throwUtil.getThrowStream(gene)
	return genesUtil.crossObserveStateValue(gene, throw, "thrower")
		:filter(dart.select(2))
end

-- return lib
return throwUtil
