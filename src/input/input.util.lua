--
--	Jackson Munsell
--	22 Oct 2020
--	input.util.lua
--
--	Input util - contains mouse raycasting functions
--

-- env
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local enum = env.src.enum
local pickup = env.src.pickup
local objects = env.src.objects

-- modules
local rx = require(axis.lib.rx)
local tableau = require(axis.lib.tableau)
local InstanceTags = require(enum.InstanceTags)
local pickupUtil = require(pickup.util)
local objectsUtil = require(objects.util)

-- lib
local inputUtil = {}
local maintainedRaycastParams = nil

---------------------------------------------------------------------------------------------------
-- Mouse tracking functions
---------------------------------------------------------------------------------------------------

-- Update maintained raycast params
function inputUtil.updateMaintainedRaycastParams()
	local instances = tableau.concat(
		CollectionService:GetTagged(InstanceTags.FXPart),
		CollectionService:GetTagged(InstanceTags.GhostPart)
	)
	table.insert(instances, env.LocalPlayer.Character)
	instances = tableau.concat(instances, pickupUtil.getLocalCharacterHeldObjects():raw())

	maintainedRaycastParams = RaycastParams.new()
	maintainedRaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	maintainedRaycastParams.FilterDescendantsInstances = instances
end
inputUtil.updateMaintainedRaycastParams()
local function fromTag(tag)
	return rx.Observable.from(CollectionService:GetInstanceAddedSignal(tag))
end

-- Update on any item holder changed
objectsUtil.getObjectsStream(pickup)
	:flatMap(function (instance)
		return rx.Observable.from(instance.state.pickup.holder)
	end)
	:merge(fromTag(InstanceTags.FXPart), fromTag(InstanceTags.GhostPart))
	:subscribe(inputUtil.updateMaintainedRaycastParams)

-- Basic raycast params
-- 	Ignores the basic ignore groups, like fx parts and ghost parts
function inputUtil.getBasicRaycastParams(config)
	-- default config
	config = config or tableau.null
	assert(type(config) == "table", "toolUtil.getBasicRaycastParams requires a table")

	-- Return maintained if no parameters are given
	if config == tableau.null then
		return maintainedRaycastParams
	end

	-- Create ignore list
	local instances = tableau.concat(
		CollectionService:GetTagged(InstanceTags.FXPart),
		CollectionService:GetTagged(InstanceTags.GhostPart),
		(config.IgnoreCharacters and CollectionService:GetTagged(InstanceTags.PlayerCharacter) or {})
	)
	table.insert(instances, env.LocalPlayer.Character)

	-- Create params
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = instances

	-- return params
	return params
end

-- Raycast mouse
function inputUtil.raycastMouse(config)
	local raycastParams = inputUtil.getBasicRaycastParams(config)
	local mousePosition = UserInputService:GetMouseLocation()
	local ray = workspace.CurrentCamera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
	local dir = ray.Direction * 1000
	local result = workspace:Raycast(ray.Origin, dir, raycastParams)
	return result, ray.Origin + dir
end

-- Get mouse hit
function inputUtil.getMouseHit(params)
	local result, final = inputUtil.raycastMouse(params)
	return result and result.Position or final
end

-- return
return inputUtil
