--
--	Jackson Munsell
--	31 Oct 2020
--	whoopieCushion.util.lua
--
--	Whoopie cushion object util
--

-- env
local TweenService = game:GetService("TweenService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local fx = require(axis.lib.fx)
local dart = require(axis.lib.dart)
local soundUtil = require(axis.lib.soundUtil)
local genesUtil = require(genes.util)

-- lib
local whoopieCushionUtil = {}

-- Set cushion primed
function whoopieCushionUtil.setCushionHot(cushion, hot)
	cushion.state.whoopieCushion.hot.Value = hot
end
function whoopieCushionUtil.setCushionFilled(cushion, filled)
	cushion.state.whoopieCushion.filled.Value = filled
end

-- Render cushion
function whoopieCushionUtil.renderCushion(cushion)
	-- Get primed state
	local filled = cushion.state.whoopieCushion.filled.Value
	local config = genesUtil.getConfig(cushion).whoopieCushion

	-- Either way we're going to tween size
	local info = (filled and config.tweenUpInfo or config.tweenDownInfo)
	local targets = {}
	targets.Size = (filled and config.fullSize or config.emptySize)

	-- Tween
	TweenService:Create(cushion, info, targets):Play()

	-- Play sound and blow particles if unprimed
	if not filled then
		local emitter = cushion:FindFirstChild("GustEmitter", true)
		if emitter then
			emitter:Emit(config.particleCount)
		end

		local soundFolder = cushion:FindFirstChild("blowSounds", true) or env.res.genes.whoopieCushion.sounds.blows
		soundUtil.playRandom(soundFolder, cushion)
	else
		soundUtil.playSound(env.res.genes.whoopieCushion.sounds.Inflate, cushion)
	end
end

-- Fire cushion
function whoopieCushionUtil.fireCushion(cushion)
	whoopieCushionUtil.setCushionHot(cushion, false)
	whoopieCushionUtil.setCushionFilled(cushion, false)
	cushion.state.whoopieCushion.blows.Value = cushion.state.whoopieCushion.blows.Value - 1
end

-- Remove cushion
function whoopieCushionUtil.removeCushion(cushion)
	local duration = genesUtil.getConfig(cushion).whoopieCushion.destroyFadeDuration
	local sound = cushion:FindFirstChild("Fart", true)
	rx.Observable.timer(5)
		:merge(sound and rx.Observable.from(sound.Ended) or rx.Observable.never())
		:first()
		:subscribe(dart.bind(fx.fadeOutAndDestroy, cushion, duration))
end

-- return lib
return whoopieCushionUtil
