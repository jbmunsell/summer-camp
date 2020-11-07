--
--	Jackson Munsell
--	29 Oct 2020
--	humanoidHolder.util.lua
--
--	Humanoid holder util
--

-- env
local TweenService = game:GetService("TweenService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local humanoidHolder = genes.humanoidHolder

-- modules
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local humanoidHolderData = require(humanoidHolder.data)

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
	genesUtil.getInstances(humanoidHolder)
		:filter(isOwned)
		:foreach(humanoidHolderUtil.resetOwner)
end

-- Get humanoid holder
function humanoidHolderUtil.getHumanoidHolder(humanoid)
	return genesUtil.getInstances(humanoidHolder)
		:first(function (object)
			return object.state.humanoidHolder.owner.Value == humanoid
		end)
end

-- Render holder
function humanoidHolderUtil.renderHumanoidHolder(holder)
	local owner = holder.state.humanoidHolder.owner.Value
	if not owner then
		-- If there is no owner, break weld
		axisUtil.destroyChild(holder, "HumanoidHoldWeld")
	else
		-- Smooth attach owner to this instance
		local weld, _, attachInfo = axisUtil.smoothAttach(holder, owner.Parent,
			"WaistBackAttachment", humanoidHolderData.tweenInInfo)
		holder.state.humanoidHolder.entryOffset.Value = attachInfo.current
		weld.Name = "HumanoidHoldWeld"

		-- Force humanoid sit
		owner.Sit = true
		-- owner:LoadAnimation(config.humanoidHolder.animation):Play()
	end
end

-- Pop humanoid
function humanoidHolderUtil.popHumanoid(humanoid)
	-- Find their holder if any
	local holder = humanoidHolderUtil.getHumanoidHolder(humanoid)
	if not holder then return end

	-- Grab the hold weld
	local weld = holder:FindFirstChild("HumanoidHoldWeld", true)
	if not weld then
		warn("Attempt to pop humanoid with valid holder but no hold weld")
		return
	end

	-- Ease the hold weld BACK to its original offset
	local info = humanoidHolderData.tweenOutInfo
	local goal = { C0 = holder.state.humanoidHolder.entryOffset.Value }
	local tween = TweenService:Create(weld, info, goal)
	tween.Completed:Connect(function ()
		weld:Destroy()
		humanoidHolderUtil.removeHumanoidOwner(humanoid)
	end)
	tween:Play()
end

-- return lib
return humanoidHolderUtil
