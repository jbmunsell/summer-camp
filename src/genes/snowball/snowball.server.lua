--
--	Jackson Munsell
--	14 Dec 2020
--	snowball.server.lua
--
--	snowball gene server driver
--

-- env
local TweenService = game:GetService("TweenService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local snowballUtil = require(genes.snowball.util)
local plantInGroundUtil = require(genes.plantInGround.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function setPlanted(instance)
	instance.state.snowball.planted.Value = true
end
local function handleSnowballDrop(instance, dropper)
	-- Try planting in the terrain
	print("handling snowball drop")
	plantInGroundUtil.tryPlant(instance)

	-- Try planting on a snowball
	if instance:FindFirstChild("StationaryWeld") then
		print("planted in terrain")
		setPlanted(instance)
	else
		local primary = instance.PrimaryPart
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { instance }
		params.FilterType = Enum.RaycastFilterType.Blacklist
		local result = workspace:Raycast(primary.Position, Vector3.new(0, -10, 0), params)
		local hitSnowball = result
			and result.Instance
			and axisUtil.getTaggedAncestor(result.Instance, require(genes.snowball.data).instanceTag)
		if hitSnowball then
			print("planting on another snowball")
			setPlanted(instance)

			local weldOffset = CFrame.new(0, (result.Instance.Size.Y + primary.Size.Y) * 0.4, 0)
			local weld = Instance.new("Weld")
			weld.Part0 = result.Instance
			weld.Part1 = primary
			weld.C0 = result.Instance.CFrame:toObjectSpace(primary.CFrame)
			weld.Parent = result.Instance
			TweenService:Create(weld, tweenInfo, { C0 = weldOffset }):Play()
		end
	end

	-- If planted, spawn a melt timer. Otherwise, pop on touch
	local popStream
	if instance.state.snowball.planted.Value then
		popStream = rx.Observable.timer(instance.config.snowball.meltTimer.Value)
	else
		popStream = rx.Observable.fromInstanceEvent(instance.PrimaryPart, "Touched")
			:reject(dart.isDescendantOf(dropper))
	end
	popStream:first():subscribe(function ()
		snowballUtil.popSnowball(instance, instance.PrimaryPart.Position)
	end)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local snowballs = genesUtil.initGene(genes.snowball)

-- Destroy snowball on impact
local hitStream = snowballs:flatMap(function (instance)
	return rx.Observable.from(instance.interface.projectile.ServerHit)
		:map(dart.carry(instance))
end)
hitStream:delay(3):subscribe(dart.destroy)

-- Try planting on the second release event
snowballs:flatMap(function (instance)
	return rx.Observable.from(instance.state.pickup.holder)
		:reject(function () return instance.state.projectile.owner.Value end)
		:replay(2)
		:filter(function (old, new)
			return old and not new
		end)
		:map(function (old)
			return instance, old
		end)
		:first()
end):subscribe(handleSnowballDrop)

-- Make collidable when planted
genesUtil.observeStateValue(genes.snowball, "planted"):subscribe(function (instance, planted)
	instance.PrimaryPart.CanCollide = planted
end)
