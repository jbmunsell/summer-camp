--
--	Jackson Munsell
--	29 Oct 2020
--	humanoidHolder.util.lua
--
--	Humanoid holder util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local objects = env.src.objects
local humanoidHolder = objects.humanoidHolder

-- modules
local axisUtil = require(axis.lib.axisUtil)
local objectsUtil = require(objects.util)

-- lib
local humanoidHolderUtil = {}

-- Set owner
function humanoidHolderUtil.setOwner(holder, humanoid)
	holder.state.humanoidHolder.owner.Value = humanoid
end
function humanoidHolderUtil.resetOwner(holder)
	holder.state.humanoidHolder.owner.Value = nil
end

-- Remove humanoid owner
function humanoidHolderUtil.removeHumanoidOwner(humanoid)
	local function isOwned(holder)
		return holder.state.humanoidHolder.owner.Value == humanoid
	end
	objectsUtil.getObjects(humanoidHolder)
		:filter(isOwned)
		:foreach(humanoidHolderUtil.resetOwner)
end

-- Get humanoid holder
function humanoidHolderUtil.getHumanoidHolder(humanoid)
	return objectsUtil.getObjects(humanoidHolder)
		:first(function (object)
			return object.state.humanoidHolder.owner.Value == humanoid
		end)
end

-- Render holder
function humanoidHolderUtil.renderHumanoidHolder(holder)
	local owner = holder.state.humanoidHolder.owner.Value
	local config = objectsUtil.getConfig(holder)
	if not owner then
		-- If there is no owner, break weld
		axisUtil.destroyChild(holder, "HumanoidHoldWeld")
	else
		-- Smooth attach owner to this instance
		local weld = axisUtil.smoothAttach(holder, owner.Parent,
			"WaistBackAttachment", config.humanoidHolder.tweenInInfo)
		weld.Name = "HumanoidHoldWeld"

		-- Force humanoid sit
		owner.Sit = true
		-- owner:LoadAnimation(config.humanoidHolder.animation):Play()
	end
end

-- return lib
return humanoidHolderUtil
