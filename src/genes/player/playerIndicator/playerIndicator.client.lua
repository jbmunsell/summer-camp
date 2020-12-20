--
--	Jackson Munsell
--	11 Nov 2020
--	playerIndicator.client.lua
--
--	playerIndicator gene client driver
--

-- env
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local playerIndicator = genes.player.playerIndicator

-- modules
local rx = require(axis.lib.rx)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local raycastParams = RaycastParams.new()
raycastParams.CollisionGroup = "IndicatorRaycast"

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Render indicator
local function renderIndicatorPosition(indicator)
	local player = indicator.state.playerIndicator.player.Value
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local result = root and workspace:Raycast(root.Position + Vector3.new(0, -1, 0),
		Vector3.new(0, -20, 0), raycastParams)
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

-- Reposition all indicators on heartbeat
rx.Observable.heartbeat():subscribe(function ()
	for _, indicator in pairs(genesUtil.getInstances(playerIndicator):raw()) do
		if indicator.state.playerIndicator.enabled.Value then
			renderIndicatorPosition(indicator)
		end
	end
end)

-- Render color on changed
genesUtil.observeStateValue(playerIndicator, "color")
	:subscribe(renderIndicatorColor)

-- Render enabled
genesUtil.observeStateValue(playerIndicator, "enabled")
	:subscribe(renderIndicatorEnabled)
