--
--	Jackson Munsell
--	15 Dec 2020
--	projectile.server.lua
--
--	projectile gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local pickupUtil = require(genes.pickup.util)
local projectileUtil = require(genes.projectile.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local projectiles = genesUtil.initGene(genes.projectile)

-- Owner has hit something
projectiles:flatMap(function (instance)
	return rx.Observable.from(instance.interface.projectile.RemoteHit)
		:filter(function (client)
			return client and client == instance.state.projectile.owner.Value
		end)
		:map(dart.drop(1))
		:map(dart.carry(instance))
end):subscribe(function (projectile, hitInstance, position)
	local interface = projectile.interface.projectile
	interface.RemoteHit:FireAllClients(hitInstance, position)
	interface.ServerHit:Fire(hitInstance, position)
end)

-- Release requested
rx.Observable.from(genes.projectile.net.ReleaseRequested)
	-- Make sure player is holding this
	:filter(function (player, instance, start, target, velocity)
		local holder = instance.state.pickup.holder.Value
		return holder and holder == player.Character
	end)
	-- Clamp velocity for anti exploit
	:map(function (player, instance, start, target, velocity)
		local config = instance.config.projectile
		local vmin = config.minThrowVelocity.Value
		local vmax = config.maxThrowVelocity.Value
		return player,
			instance,
			start,
			target,
			math.clamp(velocity, vmin, vmax)
	end)
	:subscribe(function (player, instance, start, target, velocity)
		pickupUtil.stripObject(instance)
		instance.state.projectile.owner.Value = player
		genes.projectile.net.ProjectileFired:FireAllClients(player, instance, start, target, velocity)
	end)
