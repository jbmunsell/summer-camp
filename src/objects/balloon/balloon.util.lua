--
--	Jackson Munsell
--	13 Oct 2020
--	balloonUtil.lua
--
--	Shared balloon functions
--

-- env
-- local env = require(game:GetService("ReplicatedStorage").src.env)

-- modules

-- lib
local balloonUtil = {}

-- Scale balloon
function balloonUtil.scaleBalloon(balloonInstance, scale)
	balloonInstance.Size = balloonInstance.Size * scale
	balloonInstance.AngularVelocity.MaxTorque = balloonInstance.AngularVelocity.MaxTorque * scale ^ 4
	balloonInstance.VectorForce.Force = balloonInstance.VectorForce.Force * scale ^ 3
	balloonInstance.RopeAttachment.Position = balloonInstance.RopeAttachment.Position * scale
	balloonInstance.Center.Position = balloonInstance.Center.Position * scale
end

-- Detach balloon
function balloonUtil.detachBalloon(balloonInstance)
	if balloonInstance:FindFirstChild("RopeConstraint") and balloonInstance.RopeConstraint.Attachment1 then
		balloonInstance.RopeConstraint.Attachment1:Destroy()
	end
end

-- return lib
return balloonUtil
