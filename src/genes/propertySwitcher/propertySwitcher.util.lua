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
local axis = env.packages.axis
local genes = env.src.genes
local propertySwitcher = genes.propertySwitcher

-- modules
local tableau = require(axis.lib.tableau)
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
	assert(set, string.format("%s does not have property set named %s",
		instance:GetFullName(), setName))

	-- Tween
	local tweenInfo = TweenInfo.new(config.tweenDuration.Value,
		Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
	TweenService:Create(instance, tweenInfo, tableau.valueObjectsToTable(set)):Play()
end

-- return lib
return propertySwitcherUtil
