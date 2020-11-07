--
--	Jackson Munsell
--	06 Nov 2020
--	multiswitch.util.lua
--
--	multiswitch gene util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local genesUtil = require(genes.util)

-- lib
local multiswitchUtil = {}

-- Setters
function multiswitchUtil.setSwitchEnabled(instance, setName, switchName, enabled)
	instance.state[setName].switches[switchName].Value = enabled
end
function multiswitchUtil.toggleSwitch(instance, setName, switchName)
	local switch = instance.state[setName].switches[switchName]
	switch.Value = not switch.Value
end

-- Queries
function multiswitchUtil.all(instance, setName, f)
	return tableau.fromValueObjects(instance.state[setName].switches):all(f)
end

-- Streams
function multiswitchUtil.getSwitchStream(gene)
	local geneData = require(gene.data)
	return genesUtil.getInstanceStream(gene)
		:flatMap(function (instance)
			local switches = instance.state[geneData.name].switches
			return rx.Observable.from(switches.ChildAdded)
				:startWithTable(switches:GetChildren())
				:flatMap(rx.Observable.from)
				:map(dart.constant(instance))
		end)
end

-- return lib
return multiswitchUtil
