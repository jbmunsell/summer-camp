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
local humanoidHolder = genes.humanoidHolder

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local interactUtil = require(interact.util)
local humanoidHolderUtil = require(humanoidHolder.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Basic init class
local humanoidHolderStream = genesUtil.initGene(humanoidHolder)

-- Create interact locks
humanoidHolderStream
	:map(dart.drag("humanoidHolderServer", "humanoidHolderClient"))
	:subscribe(interactUtil.createLocks)

-- When a humanoid holder owner changes, render it
humanoidHolderStream
	:flatMap(function (holder)
		return rx.Observable.from(holder.state.humanoidHolder.owner)
			:map(dart.constant(holder))
	end)
	:subscribe(humanoidHolderUtil.renderHumanoidHolder)

-- When a humanoid holder has an owner, apply interact lock
humanoidHolderStream
	:flatMap(function (holder)
		return rx.Observable.from(holder.state.humanoidHolder.owner)
			:map(dart.boolify)
			:map(dart.carry(holder, "humanoidHolderServer"))
	end)
	:subscribe(interactUtil.setLockEnabled)

-- Whenever any humanoid dies or leaves the game, clear holder ownership
local humanoidStream = rx.Observable.from(workspace.DescendantAdded)
	:startWithTable(workspace:GetDescendants()) -- there HAS to be a better way jackson
	:filter(dart.isa("Humanoid"))

humanoidStream
	:flatMap(function (humanoid)
		return rx.Observable.fromInstanceLeftGame(humanoid)
			-- :merge(rx.Observable.from(humanoid.Died), rx.Observable.from(humanoid.Jumping):filter())
			:merge(rx.Observable.from(humanoid.Died))
			:map(dart.constant(humanoid))
	end)
	:subscribe(humanoidHolderUtil.removeHumanoidOwner)

-- Pop out of holders on jump
-- humanoidStream
-- 	:flatMap(function (humanoid)
-- 		return rx.Observable.from(humanoid.Jumping)
-- 			:tap(print)
-- 			:filter()
-- 			:map(dart.constant(humanoid))
-- 	end)
-- 	:subscribe(humanoidHolderUtil.popHumanoid)
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
