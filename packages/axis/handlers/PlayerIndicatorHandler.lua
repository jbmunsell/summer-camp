--
--	Jackson Munsell
--	24 Aug 2020
--	PlayerIndicatorHandler.lua
--
--	axis handler that manages all player indicators on the client
--

-- modules
local rx = require(script.Parent.Parent.lib.rx)

-- services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- consts
local DownVector = Vector3.new(0, -20, 0)
local IndicatorTag = "PlayerIndicator"
local IgnoreTags = {
	"FXPart",
	"PlayerCharacter",
	"GhostPart",
	IndicatorTag
}

-- variables
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

-- Update raycast list
local function updateRaycastList()
	-- Construct filter list
	local ignores = {}
	for _, tag in pairs(IgnoreTags) do
		for _, instance in pairs(CollectionService:GetTagged(tag)) do
			table.insert(ignores, instance)
		end
	end
	raycastParams.FilterDescendantsInstances = ignores
end

-- Update player indicator
local function castRayDown(part)
	return workspace:Raycast(part.Position, DownVector, raycastParams)
end
local function snapIndicatorToPosition(indicator, position)
	indicator.Parent = workspace
	indicator.CFrame = CFrame.new(position)
end
local function hideIndicator(indicator)
	indicator.Parent = ReplicatedStorage
end

-- return main
return function ()
	-- Update raycast list
	rx.Observable.heartbeat()
		:startWith(0)
		:subscribe(updateRaycastList)

	-- Update indicators
	local snapStream, hideStream = rx.Observable.heartbeat()
		:flatMap(function ()
			return rx.Observable.from(CollectionService:GetTagged(IndicatorTag))
		end)
		:map(function (indicator)
			local primary = indicator.PlayerPointer.Value and
				indicator.PlayerPointer.Value.Character and
				indicator.PlayerPointer.Value.Character.PrimaryPart
			local result = primary and castRayDown(primary)
			return indicator, result and result.Position
		end)
		:partition(function (_, hit) return hit end)
	snapStream:subscribe(snapIndicatorToPosition)
	hideStream:subscribe(hideIndicator)
end
