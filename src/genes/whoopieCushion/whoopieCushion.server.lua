--
--	Jackson Munsell
--	31 Oct 2020
--	whoopieCushion.server.lua
--
--	Whoopie cushion object server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local whoopieCushion = genes.whoopieCushion

-- modules
local rx = require(axis.lib.rx)
local fx = require(axis.lib.fx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local whoopieCushionUtil = require(whoopieCushion.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Init gene
local cushionStream = genesUtil.initGene(whoopieCushion)

-- Disable all emitters on startup
cushionStream:subscribe(dart.follow(fx.setEmittersEnabled, false))

-- When a cushion is picked up by a person, prime it
local function followTrue(cushion)
	return cushion, true
end
local function followFalse(cushion)
	return cushion, false
end
local pickedUp, dropped = cushionStream
	:flatMap(function (cushion)
		return rx.Observable.from(cushion.state.pickup.holder.Changed)
			:map(dart.carry(cushion))
	end)
	:partition(function (_, holder) return holder end)
pickedUp:map(followTrue):subscribe(whoopieCushionUtil.setCushionFilled) -- Cushion fills on pickup
pickedUp:map(followFalse):subscribe(whoopieCushionUtil.setCushionHot) -- Cushion is NOT hot on pickup
dropped:map(followTrue):delay(0.2):subscribe(whoopieCushionUtil.setCushionHot) -- Cushion is hot after dropping

-- When a cushion is primed, render it as such
cushionStream
	:flatMap(function (cushion)
		return rx.Observable.from(cushion.state.whoopieCushion.filled.Changed)
			:map(dart.constant(cushion))
	end)
	:subscribe(whoopieCushionUtil.renderCushion)

-- When a cushion is touched by a character
cushionStream
	:flatMap(function (cushion)
		return rx.Observable.fromHumanoidTouchedDescendant(cushion)
	end)
	:reject(function (cushion, _)
		return cushion.state.pickup.holder.Value
		or not cushion.state.whoopieCushion.hot.Value
		or cushion.state.whoopieCushion.blows.Value <= 0
	end)
	:subscribe(whoopieCushionUtil.fireCushion)

-- Destroy cushions that have run out of blows
cushionStream
	:flatMap(function (cushion)
		return rx.Observable.from(cushion.state.whoopieCushion.blows)
			:filter(function (x)
				return x <= 0
			end)
			:map(dart.constant(cushion))
	end)
	:subscribe(whoopieCushionUtil.removeCushion)
