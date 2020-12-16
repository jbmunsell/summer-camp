--
--	Jackson Munsell
--	16 Dec 2020
--	snowShovel.server.lua
--
--	snowShovel gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local snowUtil = require(genes.player.snow.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

-- Consts
local VoxelResolution = 4
local SnowBuildRadius = 2
local SnowMeltTimer = 60
local SnowObserveRegionSize = Vector3.new(16, 16, 16)

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

-- Build snow at position
local function buildSnowAtPosition(position)
	local corner = position - SnowObserveRegionSize * 0.5
	local region = Region3.new(corner, corner + SnowObserveRegionSize):ExpandToGrid(VoxelResolution)
	local preMaterials, preOccupances = workspace.Terrain:ReadVoxels(region, VoxelResolution)
	workspace.Terrain:FillBall(position, SnowBuildRadius, Enum.Material.Snow)
	local changedMaterials, changedOccupancies = workspace.Terrain:ReadVoxels(region, VoxelResolution)

	snowUtil.emitSnowParticlesAtPosition(position)

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

-- Return terrain to original
local function revertTerrainAtIndex(globalIndex)
	local pos = globalIndex * VoxelResolution - globalIndexPositionShift
	local region = Region3.new(pos - Vector3.new(1, 1, 1), pos):ExpandToGrid(VoxelResolution)
	local mat = { { { originalMaterials[globalIndex.X][globalIndex.Y][globalIndex.Z] } } }
	local occ = { { { originalOccupancies[globalIndex.X][globalIndex.Y][globalIndex.Z] } } }
	workspace.Terrain:WriteVoxels(region, VoxelResolution, mat, occ)

	snowUtil.emitSnowParticlesAtPosition(region.CFrame.p)
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

-- init gene
genesUtil.initGene(genes.snowShovel)

-- Move terrain back to normal after snow melt timer
rx.Observable.heartbeat():subscribe(updateTerrainTimers)

-- Field build requests from clients
rx.Observable.from(genes.snowShovel.net.BuildRequested)
	:filter(function (player, instance, position)
		local range = instance.config.snowShovel.buildRange.Value
		return player.Character
		and instance.state.pickup.holder.Value == player.Character
		and (position - axisUtil.getPosition(player.Character)).magnitude <= range + 3
	end)
	:map(dart.select(3))
	:subscribe(buildSnowAtPosition)
