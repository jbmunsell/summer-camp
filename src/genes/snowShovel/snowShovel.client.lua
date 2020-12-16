--
--	Jackson Munsell
--	16 Dec 2020
--	snowShovel.client.lua
--
--	snowShovel gene client driver
--

-- env
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local inputUtil = require(env.src.input.util)
local genesUtil = require(genes.util)
local pickupUtil = require(genes.pickup.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local preview = env.res.snow.SnowBuildIndicator:Clone()

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function renderPreview(instance)
	local hit = inputUtil.getMouseHit()
	local root = axisUtil.getLocalHumanoidRootPart()
	local show = instance
	if instance then
		local range = instance and instance.config.snowShovel.buildRange.Value
		show = (hit and root and (hit - root.Position).magnitude <= range)
		preview.CFrame = CFrame.new(hit)
	end
	preview.Parent = show and workspace or ReplicatedStorage
end

local function updateBuildingTimer(instance, dt)
	local timer = instance.state.snowShovel.buildTimer
	local resetTimer = false
	if dt then
		timer.Value = timer.Value - dt
		if timer.Value <= 0 then
			resetTimer = true
			local result = inputUtil.raycastMouse()
			if result and result.Instance == workspace.Terrain and result.Material == Enum.Material.Snow then
				genes.snowShovel.net.BuildRequested:FireServer(instance, result.Position)
			end
		end
	else
		resetTimer = true
	end

	if resetTimer then
		timer.Value = instance.config.snowShovel.buildTimer.Value
	end
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.snowShovel)

-- show preview
pickupUtil.getLocalCharacterHoldingStream(genes.snowShovel):switchMap(function (instance)
	return instance and rx.Observable.heartbeat():map(dart.constant(instance)) or rx.Observable.just()
end):subscribe(renderPreview)

-- Pass activated value
pickupUtil.getActivatedStream(genes.snowShovel):flatMap(function (instance, input)
	return rx.Observable.fromProperty(input, "UserInputState")
		:filter(dart.equals(Enum.UserInputState.End)):map(dart.constant(false))
		:first()
		:startWith(true)
		:map(dart.carry(instance))
end):switchMap(function (instance, building)
	return (building
	and rx.Observable.heartbeat()
	or rx.Observable.just(false))
		:map(dart.carry(instance))
end):subscribe(updateBuildingTimer)
