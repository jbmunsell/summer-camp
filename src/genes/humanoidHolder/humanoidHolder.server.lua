--
--	Jackson Munsell
--	29 Oct 2020
--	humanoidHolder.server.lua
--
--	Character holder object class server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local interact = genes.interact
local multiswitch = genes.multiswitch
local humanoidHolder = genes.humanoidHolder

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local interactUtil = require(interact.util)
local multiswitchUtil = require(multiswitch.util)
local humanoidHolderUtil = require(humanoidHolder.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Basic init class
genesUtil.initGene(humanoidHolder)

-- When a humanoid holder owner changes, render it
local ownerStream = genesUtil.observeStateValue(humanoidHolder, "owner")
ownerStream:subscribe(humanoidHolderUtil.renderHumanoidHolder)

-- When a humanoid holder has an owner, apply interact lock
ownerStream
	:map(function (instance, owner)
		return instance, "interact", "humanoidHolder", not owner
	end)
	:subscribe(multiswitchUtil.setSwitchEnabled)

-- Whenever any humanoid dies or leaves the game, clear holder ownership
axisUtil.getPlayerCharacterStream()
	:map(dart.select(2))
	:flatMap(function (character)
		local humanoid = character:WaitForChild("Humanoid")
		return rx.Observable.fromInstanceLeftGame(character)
			-- :merge(rx.Observable.from(humanoid.Died), rx.Observable.from(humanoid.Jumping):filter())
			:merge(rx.Observable.fromInstanceEvent(humanoid, "Died"))
			:map(dart.constant(humanoid))
	end)
	:subscribe(humanoidHolderUtil.removeHumanoidOwner)

-- Pop humanoid when they wanna jump
-- 	NOTE: Needs entry point for non-player characters
rx.Observable.from(humanoidHolder.net.Jumped)
	:map(axisUtil.getPlayerHumanoid)
	:filter()
	:subscribe(humanoidHolderUtil.popHumanoid)

-- Claim request
interactUtil.getInteractStream(humanoidHolder)
	:map(function (client, holder)
		return holder, client.Character and client.Character:FindFirstChildWhichIsA("Humanoid")
	end)
	:filter(dart.boolAnd)
	:reject(function (holder, humanoid)
		return humanoidHolderUtil.getHumanoidHolder(humanoid)
		or holder.state.humanoidHolder.owner.Value
	end)
	:subscribe(humanoidHolderUtil.setOwner)
