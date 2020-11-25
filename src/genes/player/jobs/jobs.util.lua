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
	genesUtil.waitForGene(player, genes.player.characterBackpack)
	jobsUtil.renderCharacterWithJob(player.Character, player.state.jobs.job.Value,
		player.state.jobs.wearClothes.Value)
end

-- Render character with job
function jobsUtil.renderCharacterWithJob(character, job, wearClothes)
	-- Get humanoid
	local humanoid = character and character:FindFirstChild("Humanoid")
	if not humanoid or not job then return end
	local config = job.config.job

	-- Render humanoid description items
	local player = Players:GetPlayerFromCharacter(character)
	local avatarDescription = Players:GetHumanoidDescriptionFromUserId(player.UserId)
	for _, child in pairs(config.humanoidDescription:GetChildren()) do
		if (child.Name ~= "Shirt" and child.Name ~= "Pants") or wearClothes then
			avatarDescription[child.Name] = child.Value
		end
	end

	-- Render backpack size
	local backpack = player and player.state.characterBackpack.instance.Value
	if backpack then
		backpack.ScaleEffect.Value = config.backpackScale.Value
	end

	-- Apply
	humanoid:ApplyDescription(avatarDescription)
end

-- Root function to give player all gear from a specific folder
function jobsUtil.givePlayerGear(player, gearFolder, process)
	process = process or dart.noop
	-- Insert new gears into collection and stow for player
	for _, gear in pairs(gearFolder:GetChildren()) do
		local copy = gear:Clone()
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
	print("giving ", player, " daily gear for " .. job:GetFullName())
	jobsUtil.givePlayerGear(player, job.config.job.dailyGear)
end

-- return lib
return jobsUtil
