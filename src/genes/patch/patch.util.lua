--
--	Jackson Munsell
--	25 Nov 2020
--	patch.util.lua
--
--	patch gene util
--

-- env
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
local genesUtil = require(genes.util)
local pickupUtil = require(genes.pickup.util)

-- lib
local patchUtil = {}

-- attach patch
function patchUtil.attachPatch(player, patch, result)
	-- Calculate cframe
	local cframe = CFrame.new(result.Position, result.Position + result.Normal)

	-- Disable pickup
	pickupUtil.stripObject(patch)

	-- Set value
	local state = patch.state.patch
	state.attached.Value = true
	state.attachmentCFrame.Value = result.Instance.CFrame:toObjectSpace(cframe)
	state.owner.Value = player

	-- Get player backpack
	local backpack = player.state.characterBackpack.instance.Value
	patch.Parent = backpack
	local weld = Instance.new("Weld")
	weld.Part0 = backpack.Handle
	weld.Part1 = patch
	weld.C0 = state.attachmentCFrame.Value
	weld.Parent = patch
end

-- Give player patch
function patchUtil.givePlayerPatch(player, patch)
	-- Put the patch in their stowed items
	patch.Parent = ReplicatedStorage
	genesUtil.waitForGene(patch, genes.pickup)
	pickupUtil.stowObjectForPlayer(player, patch)
end

-- return lib
return patchUtil
