--
--	Jackson Munsell
--	08 Nov 2020
--	pulloutChair.util.lua
--
--	pulloutChair gene util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local pulloutChair = env.src.genes.pulloutChair

-- modules
local axisUtil = require(axis.lib.axisUtil)
local pulloutChairData = require(pulloutChair.data)

-- lib
local pulloutChairUtil = {}

-- render chair based on humanoid holder owner
function pulloutChairUtil.renderChair(instance)
	local isOut = instance.state.humanoidHolder.owner.Value
	local inCFrame = instance.config.pulloutChair:WaitForChild("inCFrame").Value
	local pullout = instance.config.pulloutChair.pulloutTranslation.Value
	local dest = inCFrame * (isOut and pullout or CFrame.new())
	axisUtil.tweenModelCFrame(instance, pulloutChairData.tweenInfo, dest)
end

-- return lib
return pulloutChairUtil
