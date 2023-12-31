--
--	Jackson Munsell
--	22 Nov 2020
--	jobs.util.lua
--
--	jobs gene util
--

-- env
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local dart = require(axis.lib.dart)
local collection = require(axis.lib.collection)
local genesUtil = require(genes.util)
local pickupUtil = require(genes.pickup.util)

-- lib
local jobsUtil = {}

-- Render player character
function jobsUtil.renderPlayerCharacter(player)
	-- Wait for backpack ready
	genesUtil.waitForGene(player, genes.player.characterBackpack)
	-- jobsUtil.renderCharacterWithJob(player.Character, player.state.jobs.job.Value,
	-- 	player.state.jobs.outfitsEnabled.Value, player.state.jobs.avatarScale.Value)

	-- Get objects
	local jobsState = player.state.jobs
	local jobConfig = player.state.jobs.job.Value.config.job
	local avatarScale = jobsState.avatarScale.Value
	local humanoid = player.Character:FindFirstChild("Humanoid")
	local playerClothes = jobsState.playerClothes
	local characterDescription = humanoid and humanoid:GetAppliedDescription()
	if not humanoid then return end

	-- Set character scale
	for _, scale in pairs({"DepthScale", "WidthScale", "HeightScale"}) do
		characterDescription[scale] = avatarScale
	end
	local backpack = player.state.characterBackpack.instance.Value
	if backpack then
		backpack.ScaleEffect.Value = avatarScale
	end

	-- Apply it all
	humanoid:ApplyDescription(characterDescription)
	wait()

	-- Set clothes
	local function tryClothes(piece)
		local jobPiece = jobConfig.humanoidDescriptionAssets:FindFirstChild(piece)
		if jobPiece and jobPiece:IsA("Folder") then
			jobPiece = jobPiece:FindFirstChild(player.Team.Name)
		end
		if not player.Character:FindFirstChild(piece) then
			Instance.new(piece, player.Character).Name = piece
		end
		if not playerClothes:FindFirstChild(piece) then
			Instance.new(piece, playerClothes).Name = piece
		end
		if jobsState.outfitsEnabled.Value and jobPiece then
			player.Character[piece][piece .. "Template"] = jobPiece[piece .. "Template"]
			-- characterDescription[piece] = jobPiece.Value
		else
			player.Character[piece][piece .. "Template"] = playerClothes[piece][piece .. "Template"]
			-- characterDescription[piece] = playerDescription[piece]
		end
	end
	tryClothes("Shirt")
	tryClothes("Pants")
end

-- Root function to give player all gear from a specific folder
function jobsUtil.givePlayerGear(player, gearFolder, process)
	process = process or dart.noop
	-- Insert new gears into collection and stow for player
	for _, gear in pairs(gearFolder:GetChildren()) do
		local copy = gear:Clone()
		if genesUtil.hasGeneTag(copy, genes.playerProperty) then
			copy.state.playerProperty.owner.Value = player
		end
		copy.Parent = ReplicatedStorage
		genesUtil.waitForGene(copy, genes.pickup)
		pickupUtil.stowObjectForPlayer(player, copy)
		if process then
			process(copy)
		end
	end
end

-- Grant job gear
-- 	Clear gear collection
-- 	Insert new gears into collection
-- 	Award gear to player
function jobsUtil.givePlayerJobGear(player, job)
	-- Destroy gear from old job
	for _, entry in pairs(player.state.jobs.gear:GetChildren()) do
		if entry.Value then
			entry.Value:Destroy()
		end
	end
	collection.clear(player.state.jobs.gear)

	-- Give new
	jobsUtil.givePlayerGear(player, job.config.job.gear, function (instance)
		collection.addValue(player.state.jobs.gear, instance)
	end)
end

-- Give player job daily gear
function jobsUtil.givePlayerJobDailyGear(player, job)
	-- Track
	collection.addValue(player.state.jobs.dailyGearGiven, job)

	-- Give all daily gear
	jobsUtil.givePlayerGear(player, job.config.job.dailyGear)
end

-- return lib
return jobsUtil
