--
--	Jackson Munsell
--	21 Aug 2020
--	data.server.lua
--
--	Server data driver - handles all data saving and loading
--

-- env
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local data = env.src.data

-- modules
local rx = require(axis.lib.rx)
local tableau = require(axis.lib.tableau)

-- instances
local dataConfig = require(data.config)
local store = DataStoreService:GetDataStore("testdb-001")

-- Build key
local function buildDataStoreKey(player)
	return tostring(player.UserId)
end

-- Create player state
-- 	Clones default player state folder and parents to player
local function createPlayerState(player)
	-- local state = env.data.playerState:Clone()
	-- state.Name = "state"
	-- state.Parent = player
end

-- Data maintenance
local function loadPlayerData(player)
	-- -- variable
	-- local folder

	-- -- If data stores are enabled, fetch data and construct folder
	-- if dataConfig.DataStoresEnabled then
	-- 	local data = store:GetAsync(buildDataStoreKey(player))
	-- 	folder = tableau.tableToValueObjects("solidState", data)

	-- -- If data stores are not enabled, then clone the spoof data
	-- else
	-- 	folder = env.data.spoofSolidState:Clone()
	-- end

	-- -- Set folder parent to player
	-- folder.Parent = player
end
local function savePlayerData(player)
	-- Flag read
	if not dataConfig.DataStoresEnabled then return end

	-- -- Assert data loaded
	-- if not player:FindFirstChild("solidState") then return end

	-- -- Serialize folder and save
	-- local data = tableau.valueObjectsToTable(player.solidState)
	-- store:SetAsync(buildDataStoreKey(player), data)
end
local function saveAll()
	for _, player in pairs(Players:GetPlayers()) do
		savePlayerData(player)
	end
end

-- Streams
local playerAdded = rx.Observable.from(Players.PlayerAdded)
local playerRemoving = rx.Observable.from(Players.PlayerRemoving)
local autosaveStream = rx.Observable.interval(dataConfig.AutosaveInterval)
	:filter(function () return dataConfig.AutosaveEnabled end)

-- Subscriptions
playerAdded:subscribe(createPlayerState)
playerAdded:subscribe(loadPlayerData)
playerRemoving:subscribe(savePlayerData)
autosaveStream:subscribe(saveAll)
game:BindToClose(saveAll)
