--
--	Jackson Munsell
--	13 Nov 2020
--	characterBackpack.client.lua
--
--	characterBackpack gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local characterBackpack = genes.player.characterBackpack

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- set local transparency modifier
local function setLocalTransparencyModifier(instance)
	local character = env.LocalPlayer.Character
	local head = character and character:FindFirstChild("Head")
	if not head then return end

	for _, d in pairs(instance:GetDescendants()) do
		if d:IsA("BasePart") or d:IsA("Decal") then
			d.LocalTransparencyModifier = head.LocalTransparencyModifier
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

genesUtil.initGene(characterBackpack)
genesUtil.observeStateValue(characterBackpack, "instance")
	:filter(dart.equals(env.LocalPlayer))
	:map(dart.select(2))
	:filter()
	:switchMap(function (instance)
		return instance
			and rx.Observable.heartbeat():map(dart.constant(instance))
			or rx.Observable.never()
	end)
	:subscribe(setLocalTransparencyModifier)
