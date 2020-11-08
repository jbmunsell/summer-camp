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
local multiswitch = genes.multiswitch
local whoopieCushion = genes.whoopieCushion

-- modules
local rx = require(axis.lib.rx)
local fx = require(axis.lib.fx)
local dart = require(axis.lib.dart)
local soundUtil = require(axis.lib.soundUtil)
local multiswitchUtil = require(multiswitch.util)
local whoopieCushionData = require(whoopieCushion.data)

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
function whoopieCushionUtil.renderCushion(cushion, init)
	-- Get primed state
	local filled = cushion.state.whoopieCushion.filled.Value
	local config = cushion.config.whoopieCushion

	-- Either way we're going to tween size
	local info = (filled and whoopieCushionData.tweenUpInfo or whoopieCushionData.tweenDownInfo)
	local targets = {}
	targets.Size = (filled and config.fullSize or config.emptySize).Value

	-- Tween
	TweenService:Create(cushion, info, targets):Play()

	-- Play sound and blow particles if unprimed and NOT init render pass
	if not init then
		if not filled then
			local emitter = cushion:FindFirstChild("GustEmitter", true)
			if emitter then
				emitter:Emit(config.particleCount.Value)
			end

			local soundFolder = cushion:FindFirstChild("blowSounds", true) or env.res.genes.whoopieCushion.sounds.blows
			soundUtil.playRandom(soundFolder, cushion)
		else
			soundUtil.playSound(env.res.genes.whoopieCushion.sounds.Inflate, cushion)
		end
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
	multiswitchUtil.setSwitchEnabled(cushion, "interact", "destroyed", false)
	local duration = cushion.config.whoopieCushion.destroyFadeDuration.Value
	local sound = cushion:FindFirstChild("Fart", true)
	rx.Observable.timer(5)
		:merge(sound and rx.Observable.from(sound.Ended) or rx.Observable.never())
		:first()
		:subscribe(dart.bind(fx.fadeOutAndDestroy, cushion, duration))
end

-- return lib
return whoopieCushionUtil
