--
--	Jackson Munsell
--	22 Nov 2020
--	job.util.lua
--
--	job gene util
--

-- env
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local collection = require(axis.lib.collection)
local genesUtil = require(genes.util)
local pickupUtil = require(genes.pickup.util)

-- lib
local jobUtil = {}

-- Render player character
function jobUtil.renderPlayerCharacter(player)
	genesUtil.waitForGene(player, genes.player.characterBackpack)
	jobUtil.renderCharacterWithJob(player.Character, player.state.job.job.Value,
		player.state.job.wearClothes.Value)
end

-- Render character with job
function jobUtil.renderCharacterWithJob(character, job, wearClothes)
	-- Get humanoid
	local humanoid = character and character:FindFirstChild("Humanoid")
	if not humanoid or not job then return end
	local config = job.config.jobClass

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

-- Grant job gear
-- 	Clear gear collection
-- 	Insert new gears into collection
-- 	Award gear to player
function jobUtil.giveJobGear(player, job)
	-- Destroy gear from old job
	for _, entry in pairs(player.state.job.gear:GetChildren()) do
		if entry.Value then
			entry.Value:Destroy()
		end
	end
	collection.clear(player.state.job.gear)

	-- Insert new gears into collection and stow for player
	for _, gear in pairs(job.config.jobClass.gear:GetChildren()) do
		local copy = gear:Clone()
		collection.addValue(player.state.job.gear, copy)
		copy.Parent = ReplicatedStorage
		genesUtil.waitForGene(copy, genes.pickup)
		pickupUtil.stowObjectForPlayer(player, copy)
	end
end

-- return lib
return jobUtil
