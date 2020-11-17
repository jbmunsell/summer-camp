--
--	Jackson Munsell
--	06 Nov 2020
--	timeOfDaySwitch.server.lua
--
--	timeOfDaySwitch gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local multiswitch = genes.multiswitch
local timeOfDaySwitch = multiswitch.timeOfDaySwitch

-- modules
local rx = require(axis.lib.rx)
local genesUtil = require(genes.util)
local timeOfDaySwitchData = require(timeOfDaySwitch.data)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Create target switch
local function createTargetSwitch(instance)
	local targetGeneName = instance.config.timeOfDaySwitch.targetGene.Value
	local targetSwitches = instance.state[targetGeneName].switches
	local name = timeOfDaySwitchData.name
	if not targetSwitches:FindFirstChild(name) then
		Instance.new("BoolValue", targetSwitches).Name = timeOfDaySwitchData.name
	end
	return targetSwitches[name]
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
local switches = genesUtil.initGene(timeOfDaySwitch)

-- Switch time listener
switches:subscribe(function (instance)
	local config = instance.config.timeOfDaySwitch
	local switch = createTargetSwitch(instance)
	local states = {
		{
			time = config.switchOnTime.Value,
			bool = true,
		},
		{
			time = config.switchOffTime.Value,
			bool = false,
		},
	}
	local firstIndex = (states[1].time < states[2].time and 1 or 2)
	local firstState = states[firstIndex]
	local secondState = states[3 - firstIndex]
	rx.Observable.from(env.src.schedule.interface.GameTimeHours):subscribe(function (t)
		local state
		if t > secondState.time then
			state = secondState
		elseif t > firstState.time then
			state = firstState
		else
			state = secondState
		end
		switch.Value = state.bool
	end)
end)
