--
--	Jackson Munsell
--	12 Dec 2020
--	chalkBlackboard.server.lua
--
--	chalkBlackboard gene server driver
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

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local boards = genesUtil.initGene(genes.chalkBlackboard)

-- Update to nearest chalk text
boards:flatMap(function (instance)
	return rx.Observable.interval(0.2):map(function ()
		return genesUtil.getNearestInstance(genes.chalk, axisUtil.getPosition(instance),
			instance.config.chalkBlackboard.reach.Value)
	end):distinctUntilChanged():switchMap(function (chalk)
		if chalk then
			return rx.Observable.from(chalk.state.textConfigure.text)
		else
			return rx.Observable.never()
		end
	end):map(dart.carry(instance))
end):subscribe(function (instance, text)
	instance.state.textConfigure.text.Value = text
end)
