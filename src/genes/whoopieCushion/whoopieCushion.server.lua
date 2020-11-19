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
local pickup = genes.pickup
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

-- Streams of pickup and drop
local dropped, pickedUp = genesUtil.crossObserveStateValue(whoopieCushion, pickup, "holder")
	:map(dart.select(1))
	:partition(genesUtil.stateValueEquals(pickup, "holder", nil))

-- Set hot value to true when dropped (slight delay), and false when picked up
dropped:delay(0.5):map(dart.drag(true))
	:merge(pickedUp:map(dart.drag(false)))
	:subscribe(genesUtil.setStateValue(whoopieCushion, "hot"))

-- Set filled value to true when picked up
pickedUp:map(dart.drag(true))
	:subscribe(genesUtil.setStateValue(whoopieCushion, "filled"))

-- When a cushion is primed, render it as such
genesUtil.observeStateValueWithInit(whoopieCushion, "filled")
	:subscribe(whoopieCushionUtil.renderCushion)

-- When a cushion is touched by a character
cushionStream
	:flatMap(rx.Observable.fromHumanoidTouchedDescendant)
	:reject(function (cushion, _)
		return cushion.state.pickup.holder.Value
		or not cushion.state.whoopieCushion.hot.Value
		or cushion.state.whoopieCushion.blows.Value <= 0
	end)
	:subscribe(whoopieCushionUtil.fireCushion)

-- Destroy cushions that have run out of blows
genesUtil.observeStateValue(whoopieCushion, "blows")
	:filter(genesUtil.stateValueEquals(whoopieCushion, "blows", 0))
	:subscribe(whoopieCushionUtil.removeCushion)
