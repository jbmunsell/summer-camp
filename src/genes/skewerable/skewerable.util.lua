--
--	Jackson Munsell
--	01 Nov 2020
--	skewerable.util.lua
--
--	skewerable gene util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local pickup = genes.pickup
local skewer = genes.skewer

-- modules
local axisUtil = require(axis.lib.axisUtil)
local pickupUtil = require(pickup.util)
local genesUtil = require(genes.util)

-- lib
local skewerableUtil = {}

-- Equip
function skewerableUtil.equip(character, instance)
	-- If they have a skewer, then skewer the skewer
	local skewerInstance = pickupUtil.characterHoldsObject(character, skewer)
	if skewerInstance then
		instance.state.skewerable.skewer.Value = skewerInstance
		instance.state.skewerable.skewerSlotIndex.Value = 0
	else
		-- If the character is not holding a skewer, then have them drop what they are holding
		-- 	and pick up this instance
		instance.state.skewerable.skewer.Value = nil
		axisUtil.destroyChild(instance, "SkewerWeld")
		pickupUtil.unequipCharacter(character)
		pickupUtil.equip(character, instance)
	end
end

-- Bump slot index
function skewerableUtil.bumpSlotIndex(instance)
	instance.state.skewerable.skewerSlotIndex.Value = instance.state.skewerable.skewerSlotIndex.Value + 1
end

-- Render slot weld
function skewerableUtil.renderSlotWeld(instance)
	-- Destroy skewer weld so that we can recreate it
	axisUtil.destroyChild(instance, "SkewerWeld")

	-- If it's too high, then drop this thing
	local state = instance.state.skewerable
	local slotIndex = state.skewerSlotIndex.Value
	local skewerInstance = state.skewer.Value
	if slotIndex > genesUtil.getConfig(skewerInstance).skewer.maxSkewerSlots then
		state.skewer.Value = nil
	else
		-- If it's in range, then smooth attach
		local attachmentName = string.format("Slot%dAttachment", slotIndex)
		local weld = axisUtil.smoothAttachAttachments(skewerInstance, attachmentName,
			instance, "SkewerAttachment")
		weld.Parent = instance
		weld.Name = "SkewerWeld"
	end
end

-- return lib
return skewerableUtil
