--
--	Jackson Munsell
--	29 Oct 2020
--	humanoidHolder.client.lua
--
--	Humanoid holder client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local interact = genes.interact
local humanoidHolder = genes.humanoidHolder

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local humanoidHolderUtil = require(humanoidHolder.util)
local interactUtil = require(interact.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Set lock
local function setLock(locked)
	local function setObjectLock(object)
		interactUtil.setLockEnabled(object, "humanoidHolderClient", locked)
	end
	genesUtil.getInstances(humanoidHolder)
		:foreach(setObjectLock)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- When any changes, check if any has local owner
genesUtil.getInstanceStream(humanoidHolder)
	:flatMap(function (holder)
		return rx.Observable.from(holder.state.humanoidHolder.owner)
	end)
	:map(axisUtil.getLocalHumanoid)
	:map(humanoidHolderUtil.getHumanoidHolder)
	:map(dart.boolify)
	:subscribe(setLock)

-- Local humanoid jumped, pass to server
rx.Observable.from(env.LocalPlayer.CharacterAdded)
	:startWith(env.LocalPlayer.Character)
	:filter()
	:map(function (character)
		return character:WaitForChild("Humanoid")
	end)
	:flatMap(function (humanoid)
		return rx.Observable.from(humanoid.Jumping)
	end)
	:filter()
	:subscribe(dart.forward(humanoidHolder.net.Jumped))