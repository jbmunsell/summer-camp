--
--	Jackson Munsell
--	13 Nov 2020
--	sessionTime.util.lua
--
--	sessionTime gene util
--

-- env
-- local env = require(game:GetService("ReplicatedStorage").src.env)

-- modules

-- lib
local sessionTimeUtil = {}

-- is player sessionTime
function sessionTimeUtil.getSessionTime(player)
	return player.state.sessionTime.sessionTime.Value
end

-- return lib
return sessionTimeUtil
