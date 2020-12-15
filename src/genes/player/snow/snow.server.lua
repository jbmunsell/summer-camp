--
--	Jackson Munsell
--	14 Dec 2020
--	snow.server.lua
--
--	snow gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local fx = require(axis.lib.fx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local pickupUtil = require(genes.pickup.util)
local playerUtil = require(genes.player.util)
local snowUtil = require(genes.player.snow.util)

local snowNet = genes.player.snow.net

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

-- Consts
local VoxelResolution = 4
local SnowBuildRadius = 2
local SnowMeltTimer = 5
local SnowObserveRegionSize = Vector3.new(16, 16, 16)
local SnowParticleCount = 5

-- Cache entire terrain map
local originalMaterials, originalOccupancies
local terrainTimers = {}
local globalIndexPositionShift
do
	local dim = 256
	local corner = Vector3.new(dim, dim, dim)
	local region = Region3.new(corner * -1, corner):ExpandToGrid(VoxelResolution)
	originalMaterials, originalOccupancies = workspace.Terrain:ReadVoxels(region, VoxelResolution)
	globalIndexPositionShift = corner
end

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Set kneeling animation, sound, and particles enabled
local function setSnowFXEnabled(player, enabled)
end

-- Emit snow particles at point
local function emitSnowParticlesAtPosition(position, count)
	local emitter = env.res.snow.SnowMeltEmitter:Clone()
	emitter.Size = Vector3.new(2, 2, 2)
	emitter.CFrame = CFrame.new(position)
	emitter.Parent = workspace
	fx.setFXEnabled(emitter, false)
	fx.emit(emitter, count or SnowParticleCount)
	fx.smoothDestroy(emitter)
end

-- Gather snow
local function gatherSnow(player)
	-- Terminator stream
	local terminator = rx.Observable.from(player.state.snow.gathering):reject():first()

	-- Get ground
	local result = snowUtil.raycastPlayerGround(player, CFrame.new(0, 0, -2))
	if not result or not result.Position then return end

	-- Snowball
	local ball = env.res.snow.Snowball:Clone()
	fx.new("ScaleEffect", ball)
	local weld = Instance.new("Weld")
	weld.Part0 = workspace.Terrain
	weld.Part1 = ball.PrimaryPart
	weld.C0 = CFrame.new(result.Position)
	weld.Name = "StationaryWeld"
	weld.Parent = ball
	ball.Parent = workspace
	genesUtil.waitForGene(ball, genes.pickup)
	local function setBallScale(scale)
		ball.ScaleEffect.Value = scale
	end
	local function pickupSnowball()
		pickupUtil.equip(player.Character, ball)
	end

	-- Create snowball and increase size until stopped gathering
	rx.Observable.heartbeat()
		:scan(function (x, dt) return x + dt * 6 end, 1)
		:map(function (d) return math.pow(d, 1 / 3) end)
		:takeUntil(terminator)
		:subscribe(setBallScale)

	-- When they stop gathering, give them this object as a pickup
	terminator:subscribe(pickupSnowball)
end

-- Build snow at position
local function buildSnowAtPosition(position)
	local corner = position - SnowObserveRegionSize * 0.5
	local region = Region3.new(corner, corner + SnowObserveRegionSize):ExpandToGrid(VoxelResolution)
	local preMaterials, preOccupances = workspace.Terrain:ReadVoxels(region, VoxelResolution)
	workspace.Terrain:FillBall(position, SnowBuildRadius, Enum.Material.Snow)
	local changedMaterials, changedOccupancies = workspace.Terrain:ReadVoxels(region, VoxelResolution)

	emitSnowParticlesAtPosition(position)

	local changedCount = 0
	local function spawnTimer(globalIndex)
		-- Reset timer if already exists
		changedCount = changedCount + 1
		for _, entry in pairs(terrainTimers) do
			if entry.index == globalIndex then
				entry.timer = SnowMeltTimer
				return
			end
		end

		-- Create new timer because none was found
		local entry = {
			index = globalIndex,
			timer = SnowMeltTimer,
		}
		table.insert(terrainTimers, entry)
	end

	for x = 1, preMaterials.Size.X do
		for y = 1, preMaterials.Size.Y do
			for z = 1, preMaterials.Size.Z do
				local globalIndex = (region.CFrame.p - region.Size * 0.5 + globalIndexPositionShift)
					* (1 / VoxelResolution) + Vector3.new(x, y, z)
				local gx, gy, gz = globalIndex.X, globalIndex.Y, globalIndex.Z

				if (preMaterials[x][y][z] ~= changedMaterials[x][y][z]
					or preOccupances[x][y][z] ~= changedOccupancies[x][y][z])
				and (changedMaterials[x][y][z] ~= originalMaterials[gx][gy][gz]
					or changedOccupancies[x][y][z] ~= originalOccupancies[gx][gy][gz])
				then
					spawnTimer(globalIndex)
				end
			end
		end
	end
end

-- Build snow underneath a player
local function buildSnowUnderPlayer(player)
	local position = snowUtil.getPlayerStandingPosition(player)
	if not position then return end
	buildSnowAtPosition(position)
end

-- Return terrain to original
local function revertTerrainAtIndex(globalIndex)
	local pos = globalIndex * VoxelResolution - globalIndexPositionShift
	local region = Region3.new(pos - Vector3.new(1, 1, 1), pos):ExpandToGrid(VoxelResolution)
	local mat = { { { originalMaterials[globalIndex.X][globalIndex.Y][globalIndex.Z] } } }
	local occ = { { { originalOccupancies[globalIndex.X][globalIndex.Y][globalIndex.Z] } } }
	workspace.Terrain:WriteVoxels(region, VoxelResolution, mat, occ)

	emitSnowParticlesAtPosition(region.CFrame.p)
end

-- Update terrain timers
local function updateTerrainTimers(dt)
	for i = #terrainTimers, 1, -1 do
		local entry = terrainTimers[i]
		entry.timer = entry.timer - dt
		if entry.timer <= 0 then
			revertTerrainAtIndex(entry.index)
			table.remove(terrainTimers, i)
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene for all players
local playerStream = playerUtil.initPlayerGene(genes.player.snow)

-- Play sounds and animation according to state values
playerStream:flatMap(function (player)
	local state = player.state.snow
	return rx.Observable.from(state.building)
		:combineLatest(rx.Observable.from(state.gathering), dart.boolOr)
		:map(dart.carry(player))
end):subscribe(setSnowFXEnabled)

-- When they start building, run an interval stream to do it
playerStream:flatMap(function (player)
	return rx.Observable.from(player.state.snow.building):switchMap(function (building)
		return building and rx.Observable.interval(1) or rx.Observable.never()
	end):map(dart.constant(player))
end):subscribe(buildSnowUnderPlayer)

-- When they start gathering, run a heartbeat stream to increase scale
genesUtil.observeStateValue(genes.player.snow, "gathering")
	:filter(dart.select(2))
	:map(dart.select(1))
	:subscribe(gatherSnow)

-- Process requests
rx.Observable.from(snowNet.GatheringStarted)
	:filter(snowUtil.isPlayerStandingOnSnow)
	:map(dart.drag(true))
	:merge(rx.Observable.from(snowNet.GatheringStopped):map(dart.drag(false)))
	:subscribe(function (player, gathering)
		player.state.snow.gathering.Value = gathering
	end)
rx.Observable.from(snowNet.BuildingChangeRequested)
	:subscribe(function (player, building)
		player.state.snow.building.Value = building
	end)

-- Move terrain back to normal after snow melt timer
rx.Observable.heartbeat():subscribe(updateTerrainTimers)
