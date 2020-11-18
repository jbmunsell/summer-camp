--
--	Jackson Munsell
--	13 Nov 2020
--	propertySwitcher.util.lua
--
--	propertySwitcher gene util
--

-- env
local TweenService = game:GetService("TweenService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local propertySwitcher = genes.propertySwitcher

-- modules
local genesUtil = require(genes.util)

-- lib
local propertySwitcherUtil = {}

-- init
function propertySwitcherUtil.init()
	-- init gene
	genesUtil.initGene(propertySwitcher)

	-- listen for state changed
	genesUtil.observeStateValue(propertySwitcher, "propertySet")
		:subscribe(propertySwitcherUtil.tweenToPropertySet)
end

-- tween to property set
function propertySwitcherUtil.tweenToPropertySet(instance, setName)
	-- Debounce init
	if setName == "" then return end

	-- Grab set
	local config = instance.config.propertySwitcher
	local set = config.propertySets:FindFirstChild(setName)
	if not set then error(string.format("%s does not have property set named %s",
		instance:GetFullName(), setName)) end

	-- Tween
	local goals = {}
	for _, value in pairs(set:GetChildren()) do
		if value:IsA("StringValue") or value:IsA("BoolValue") then
			instance[value.Name] = value.Value
		else
			goals[value.Name] = value.Value
		end
	end
	local tweenInfo = TweenInfo.new(config.tweenDuration.Value,
		Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
	TweenService:Create(instance, tweenInfo, goals):Play()
end

-- return lib
return propertySwitcherUtil
