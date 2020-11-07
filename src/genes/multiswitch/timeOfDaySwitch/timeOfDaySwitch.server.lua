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
local schedule = env.src.schedule
local genes = env.src.genes
local multiswitch = genes.multiswitch
local timeOfDaySwitch = multiswitch.timeOfDaySwitch

-- modules
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local genesUtil = require(genes.util)
local multiswitchUtil = require(multiswitch.util)
local scheduleStreams = require(schedule.streams)
local timeOfDaySwitchData = require(timeOfDaySwitch.data)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Create target switch
local function createTargetSwitch(instance)
	local targetGeneName = instance.config.timeOfDaySwitch.targetGene.Value
	local targetSwitches = instance.state[targetGeneName].switches
	if not targetSwitches:FindFirstChild(timeOfDaySwitchData.name) then
		Instance.new("BoolValue", targetSwitches).Name = timeOfDaySwitchData.name
	end
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
local switches = genesUtil.initGene(timeOfDaySwitch)

-- Create switch for new things
switches:subscribe(createTargetSwitch)

-- Switch time listener
switches
	:flatMap(function (instance)
		-- Wait for the switch
		local config = instance.config.timeOfDaySwitch
		instance.state[config.targetGene.Value].switches:WaitForChild(timeOfDaySwitchData.name)

		-- Quick state map
		local states = tableau.from({
			{
				time = config.switchOnTime.Value,
				bool = true,
			},
			{
				time = config.switchOffTime.Value,
				bool = false,
			}
		})

		-- Helper
		local indexTime = dart.index("time")
		local function getTimeState(t)
			-- Get the max time that is LESS THAN current time of day.
			-- 	If current ToD is LESS THAN both options, use the latest option
			-- 	to properly handle time wrapping.
			local post = states:filter(function (s)
				return s.time < t
			end):max(indexTime)
			post = post or states:max(indexTime)
			return post.bool
		end

		-- Map state from time
		return scheduleStreams.gameTime
			:map(getTimeState)
			:distinctUntilChanged()
			:map(dart.carry(instance, config.targetGene.Value, timeOfDaySwitchData.name))
	end)
	:subscribe(multiswitchUtil.setSwitchEnabled)
