--
--	Jackson Munsell
--	24 Oct 2020
--	dish.util.lua
--
--	Dish util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local pickup = genes.pickup
local foodTray = genes.foodTray

-- modules
local axisUtil = require(axis.lib.axisUtil)
local pickupUtil = require(pickup.util)

-- lib
local dishUtil = {}

-- Get dish type
local dishTypes = {
	"Cup",
	"Plate",
	"Bowl",
}
function dishUtil.getBottomAttachment(instance)
	return dishUtil.getDishTypeAttachment(instance, dishUtil.getDishType(instance))
end
function dishUtil.getDishTypeAttachment(instance, dishType)
	return instance:FindFirstChild(dishType .. "BottomAttachment", true)
end
function dishUtil.getDishType(instance)
	for _, dishType in pairs(dishTypes) do
		if dishUtil.getDishTypeAttachment(instance, dishType) then return dishType end
	end
end

-- Equip
function dishUtil.equip(character, instance)
	local tray = pickupUtil.characterHoldsObject(character, foodTray)
	if tray then
		axisUtil.destroyChild(instance, "StationaryWeld")

		instance.state.dish.tray.Value = tray
		local attachment = dishUtil.getBottomAttachment(instance)
		assert(attachment, "Unable to find bottom attachment in dish instance " .. instance:GetFullName())
		local weld = axisUtil.smoothAttach(tray, instance, attachment.Name)
		weld.Name = "TrayWeld"
		weld.Parent = instance
	else
		instance.state.dish.tray.Value = nil
		axisUtil.destroyChild(instance, "TrayWeld")
		pickupUtil.unequipCharacter(character)
		pickupUtil.equip(character, instance)
	end
end

-- return lib
return dishUtil
