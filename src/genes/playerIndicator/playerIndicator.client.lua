--
--	Jackson Munsell
--	11 Nov 2020
--	playerIndicator.client.lua
--
--	playerIndicator gene client driver
--

-- env
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local playerIndicator = genes.playerIndicator

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local IgnoreTags = {
	-- "PlayerCharacter",
}
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Update raycast list
local function updateRaycastList()
	local ignores = {}
	print("Updating raycast list")
	for _, d in pairs(workspace:GetDescendants()) do
		if d:IsA("Humanoid") then
			table.insert(ignores, d.Parent)
		end
	end
	for _, tag in pairs(IgnoreTags) do
		for _, instance in pairs(CollectionService:GetTagged(tag)) do
			print("Inserting ", instance:GetFullName())
			table.insert(ignores, instance)
		end
	end
	raycastParams.FilterDescendantsInstances = ignores
end

-- Render indicator
local function renderIndicatorPosition(indicator)
	local player = indicator.state.playerIndicator.player.Value
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local result = root and workspace:Raycast(root.Position, Vector3.new(0, -20, 0), raycastParams)
	local position = result and result.Position

	if position then
		indicator.Parent = workspace
		indicator.CFrame = CFrame.new(position)
	else
		indicator.Parent = ReplicatedStorage
	end
end
local function renderIndicatorColor(indicator, color)
	indicator.Color = color
	indicator.PointLight.Color = color
end
local function renderIndicatorEnabled(indicator, enabled)
	indicator.Parent = (enabled and workspace or ReplicatedStorage)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(playerIndicator)

-- Update raycast list
rx.Observable.from(IgnoreTags)
	:flatMap(function (tag)
		return rx.Observable.from(CollectionService:GetInstanceAddedSignal(tag))
			:merge(rx.Observable.from(CollectionService:GetInstanceRemovedSignal(tag)))
	end)
	:startWith(0)
	:merge(rx.Observable.from(workspace.DescendantAdded):filter(dart.isa("Humanoid")))
	:subscribe(updateRaycastList)

-- Reposition all indicators on heartbeat
rx.Observable.heartbeat()
	:map(dart.bind(genesUtil.getInstances, playerIndicator))
	:flatMap(rx.Observable.from)
	:filter(function (i) return i.state.playerIndicator.enabled.Value end)
	:subscribe(renderIndicatorPosition)

-- Render color on changed
genesUtil.observeStateValue(playerIndicator, "color")
	:subscribe(renderIndicatorColor)

-- Render enabled
genesUtil.observeStateValue(playerIndicator, "enabled")
	:subscribe(renderIndicatorEnabled)
