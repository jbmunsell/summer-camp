--
--	Jackson Munsell
--	29 Oct 2020
--	humanoidHolder.client.lua
--
--	Humanoid holder client driver
--

-- env
local UserInputService = game:GetService("UserInputService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local multiswitch = genes.multiswitch
local humanoidHolder = genes.humanoidHolder

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local humanoidHolderUtil = require(humanoidHolder.util)
local multiswitchUtil = require(multiswitch.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Set lock
local function setSwitch(enabled)
	genesUtil.getInstances(humanoidHolder)
		:foreach(function (instance)
			multiswitchUtil.setSwitchEnabled(instance, "interact", "humanoidHolder", enabled)
		end)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- When any changes, check if any has local owner
local holders = genesUtil.initGene(humanoidHolder)
holders
	:flatMap(function (holder)
		return rx.Observable.from(holder.state.humanoidHolder.owner)
	end)
	:map(axisUtil.getLocalHumanoid)
	:filter()
	:map(humanoidHolderUtil.getHumanoidHolder)
	:map(dart.boolNot)
	:subscribe(setSwitch)

-- Local humanoid jumped, pass to server
rx.Observable.from(UserInputService.JumpRequest):subscribe(dart.forward(humanoidHolder.net.Jumped))
