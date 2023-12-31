--
--	Jackson Munsell
--	15 Oct 2020
--	dining.server.lua
--
--	Dining server driver. Handles all dining setup and events
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local schedule = env.src.schedule
local dining = env.src.dining
local genes = env.src.genes
local dish = genes.dish
local foodTray = genes.foodTray

-- modules
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local axisUtil = require(axis.lib.axisUtil)
local scheduleStreams = require(schedule.streams)
local diningConfig = require(dining.config)
local dishUtil = require(dish.util)
local genesUtil = require(genes.util)

-- Try
if not workspace:FindFirstChild("dining") then
	warn("Dining folder not found; quitting")
	return
end

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Clear nested component
local function clearNestedComponent(primary, secondary)
	for _, c in pairs(workspace.dining:GetChildren()) do
		if c.Name == primary then
			c[secondary]:ClearAllChildren()
		end
	end
end

-- Clear various parts of meal
local function clearFreshTrayTrolleys()
	clearNestedComponent("FreshTrayTrolley", "Trays")
end
local function clearServingTables()
	clearNestedComponent("ServingTable", "Dishes")
end

-- Fill fresh trolley trays
local function fillFreshTrolleyTrays()
	-- Get tray spawn start locations
	-- local spawnPoints = tableau.from(workspace.dining:GetChildren())
	-- 	:filter(dart.isNamed("FreshTrayTrolley"))
	-- 	:flatMap(dart.getDescendants)
	-- 	:filter(dart.isNamed("TrayStartLocation"))
	local traySpawns = {}
	for _, c in pairs(workspace.dining:GetChildren()) do
		if c.Name == "FreshTrayTrolley" then
			for _, d in pairs(c:GetDescendants()) do
				if d.Name == "TrayStartLocation" then
					table.insert(traySpawns, d)
				end
			end
		end
	end
	for _, spawnPoint in pairs(traySpawns) do
		wait()
		local trolley = dart.getNamedAncestor(spawnPoint, "FreshTrayTrolley")
		for i = 1, (diningConfig.numFreshTrays / #traySpawns) do
			local tray = env.res.dining.Tray:Clone()
			tray.CFrame = spawnPoint.WorldCFrame + Vector3.new(0, 0.1 * (i - 1), 0)
			tray.Parent = trolley.Trays
			-- genesUtil.addGeneTag(tray, foodTray)
			local weld = Instance.new("WeldConstraint")
			weld.Name = "StationaryWeld"
			weld.Part0 = spawnPoint.Parent
			weld.Part1 = tray
			weld.Parent = tray
		end
	end
end

-- Fill serving tables
local function fillServingTables(mealKey)
	-- Place a dish on all dish attachments
	local dishSpawns = {}
	for _, c in pairs(workspace.dining:GetChildren()) do
		if c.Name == "ServingTable" then
			for _, d in pairs(c:GetDescendants()) do
				if d.Name == "DishAttachment" then
					table.insert(dishSpawns, d)
				end
			end
		end
	end
	for _, dishAttachment in pairs(dishSpawns) do
		wait()
		local servingTable = dart.getNamedAncestor(dishAttachment, "ServingTable")
		local dishName = tableau.from(diningConfig[mealKey][servingTable.config.dishType.Value .. "List"])
			:random()
		local dishInstance = env.res.dining.dishes[dishName]:Clone()
		dishInstance.Parent = servingTable.Dishes
		-- genesUtil.addGeneTag(dishInstance, dish)
		axisUtil.snapAttachments(dishAttachment, dishUtil.getBottomAttachment(dishInstance))

		local weld = Instance.new("WeldConstraint")
		weld.Name = "StationaryWeld"
		weld.Part0 = dishAttachment.Parent
		weld.Part1 = dishInstance.PrimaryPart
		weld.Parent = dishInstance
	end
end

-- Init meal
local function initMeal(mealChunk)
	-- Clear old trays from trolleys
	clearFreshTrayTrolleys()
	wait()

	-- Create new trays in trolleys
	fillFreshTrolleyTrays()
	wait()

	-- Clear old dish from tables
	clearServingTables()
	wait()

	-- Place new dish on tables
	fillServingTables(mealChunk.MealKey)
end

-- Destroy meal
local function destroyMeal()
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Is meal chunk
local function isMealChunk(chunk)
	return chunk and chunk.MealKey
end

-- Connect to chunk changed
local mealStarted = scheduleStreams.scheduleChunk
	:filter(isMealChunk)
local mealFinished = scheduleStreams.scheduleChunk
	:map(isMealChunk)
	:distinctUntilChanged()
	:reject()
mealStarted:subscribe(initMeal)
mealFinished:subscribe(destroyMeal)
