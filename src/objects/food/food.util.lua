--
--	Jackson Munsell
--	24 Oct 2020
--	food.util.lua
--
--	Food util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local objects = env.src.objects
local pickup = objects.pickup
local foodTray = objects.foodTray

-- modules
local fx = require(axis.lib.fx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local axisUtil = require(axis.lib.axisUtil)
local pickupUtil = require(pickup.util)
local foodTrayConfig = require(foodTray.config)

-- lib
local foodUtil = {}

-- Get dish type
local dishTypes = {
	"Cup",
	"Plate",
	"Bowl",
}
function foodUtil.getBottomAttachment(foodInstance)
	return foodUtil.getDishTypeAttachment(foodInstance, foodUtil.getDishType(foodInstance))
end
function foodUtil.getDishTypeAttachment(foodInstance, dishType)
	return foodInstance:FindFirstChild(dishType .. "BottomAttachment", true)
end
function foodUtil.getDishType(foodInstance)
	for _, dishType in pairs(dishTypes) do
		if foodUtil.getDishTypeAttachment(foodInstance, dishType) then return dishType end
	end
end

-- Equip
function foodUtil.equip(character, foodInstance)
	local tray = pickupUtil.getCharacterHeldObjects(character)
		:first(dart.hasTag(foodTrayConfig.instanceTag))
	if tray then
		foodInstance.state.food.tray.Value = tray
		local attachment = foodUtil.getBottomAttachment(foodInstance)
		assert(attachment, "Unable to find bottom attachment in food instance " .. foodInstance:GetFullName())
		local weld = axisUtil.smoothAttach(tray, foodInstance, attachment.Name)
		weld.Name = "TrayWeld"
		weld.Parent = foodInstance
	else
		foodInstance.state.food.tray.Value = nil
		axisUtil.destroyChild(foodInstance, "TrayWeld")
		pickupUtil.unequipCharacter(character)
		pickupUtil.equip(character, foodInstance)
	end
end

-- Eat food
function foodUtil.isFoodEaten(foodInstance)
	return foodInstance.state.food.eaten.Value
end
function foodUtil.eatFood(foodInstance)
	-- Set state value
	foodInstance.state.food.eaten.Value = true

	-- Create sound if it doesn't exist
	local sound = foodInstance:FindFirstChild("EatSound", true)
	if not sound then
		sound = env.res.dining.EatSound:Clone()
		sound.Parent = foodInstance.PrimaryPart
		if not foodInstance.PrimaryPart then
			warn("Attempt to play eat sound in a food model with no PrimaryPart")
			return
		end
	end
	sound:Play()

	-- Fade out all non-dish parts
	tableau.from(foodInstance:GetDescendants())
		:filter(dart.isa("BasePart"))
		:reject(dart.isNamed("DishPart"))
		:foreach(fx.fadeOutAndDestroy)
end

-- return lib
return foodUtil
