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

-- modules
local rx = require(axis.lib.rx)
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

-- Clear thrower
function throwUtil.clearThrower(instance)
	instance.state.throw.thrower.Value = nil
end

-- Throw character object
function throwUtil.throwCharacterObject(character, object, target)
	local root = getRoot(object)
	pickupUtil.disownHeldObjects(character)
	pickupUtil.releaseHeldObjects(character)
	root.Velocity = (target - root.Position).unit * object.config.throw.throwMagnitude.Value
	object.state.throw.thrower.Value = character
end

-- Get thrown stream
function throwUtil.getThrownStream(gene)
	return genesUtil.getInstanceStream(gene)
		:flatMap(function (instance)
			return rx.Observable.from(instance.state.throw.thrower)
				:filter()
				:map(dart.constant(instance))
		end)
end

-- return lib
return throwUtil
