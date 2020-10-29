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
local objects = env.src.objects
local interact = objects.interact
local humanoidHolder = objects.humanoidHolder

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local objectsUtil = require(objects.util)
local interactUtil = require(interact.util)
local humanoidHolderUtil = require(humanoidHolder.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Basic init class
local humanoidHolderStream = objectsUtil.initObjectClass(humanoidHolder)

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
	-- :subscribe(print)
	:subscribe(interactUtil.setLockEnabled)

-- Whenever any humanoid dies or leaves the game, clear holder ownership
rx.Observable.from(workspace.DescendantAdded)
	:startWithTable(workspace:GetDescendants()) -- there HAS to be a better way jackson
	:filter(dart.isa("Humanoid"))
	:flatMap(function (humanoid)
		return rx.Observable.fromInstanceLeftGame(humanoid)
			:merge(rx.Observable.from(humanoid.Died), rx.Observable.from(humanoid.Jumping):filter())
			:map(dart.constant(humanoid))
	end)
	:subscribe(humanoidHolderUtil.removeHumanoidOwner)

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
