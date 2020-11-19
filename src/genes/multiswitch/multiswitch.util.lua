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

-- Create switch
function multiswitchUtil.createSwitch(instance, setName, switchName)
	local switch = Instance.new("BoolValue")
	switch.Name = switchName
	switch.Value = true
	switch.Parent = instance.state[setName].switches
end

-- Queries
function multiswitchUtil.all(instance, setName, f)
	f = f or dart.identity
	for _, switch in pairs(instance.state[setName].switches:GetChildren()) do
		if not f(switch.Value) then
			return false
		end
	end
	return true
end

-- Streams
-- 	Observes the switches for a single instance
function multiswitchUtil.observeSwitches(instance, setName)
	local switches = instance.state[setName].switches
	return rx.Observable.fromInstanceEvent(switches, "ChildAdded")
		:startWithTable(switches:GetChildren())
		:flatMap(function (c)
			-- Go directly to the changed event to skip the first one
			-- 	so we don't push a bunch of init events
			return rx.Observable.fromInstanceEvent(c, "Changed")
		end)
end

-- 	Gets the switch stream for all instances of a gene
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
