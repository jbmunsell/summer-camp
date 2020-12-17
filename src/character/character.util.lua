--
--	Jackson Munsell
--	17 Dec 2020
--	character.util.lua
--
--	Character util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
local humanoidHolderUtil = require(genes.humanoidHolder.util)

-- lib
local characterUtil = {}

-- Teleport character
function characterUtil.teleportCharacter(character, cframe)
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		humanoid.Sit = false
		humanoidHolderUtil.removeHumanoidOwner(humanoid)
		wait()
	end
	character:SetPrimaryPartCFrame(cframe)
end

-- return lib
return characterUtil
