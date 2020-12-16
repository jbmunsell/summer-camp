--
--	Jackson Munsell
--	15 Dec 2020
--	snowball.util.lua
--
--	snowball gene util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local fx = require(axis.lib.fx)
local snowUtil = require(genes.player.snow.util)

-- lib
local snowballUtil = {}

-- pop snowball at position
function snowballUtil.popSnowball(instance, position)
	-- Destroy instance
	instance.PrimaryPart.Anchored = true
	instance.PrimaryPart.CanCollide = false
	fx.new("TransparencyEffect", instance).Value = 1
	fx.smoothDestroy(instance)

	-- Toss snow melt particles
	snowUtil.emitSnowParticlesAtPosition(position, 30 * instance.ScaleEffect.Value,
		function (emitterPart)
			local vel = instance.state.projectile.velocityMagnitude.Value
			local minvel = instance.config.projectile.minThrowVelocity.Value
			local speed = emitterPart.ParticleEmitter.Speed.Max
			local modifier = math.pow(vel / minvel, 2)
			emitterPart.ParticleEmitter.Speed = NumberRange.new(speed * modifier)
		end)
end

-- return lib
return snowballUtil
