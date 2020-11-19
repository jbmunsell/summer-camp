--
--	Jackson Munsell
--	14 Nov 2020
--	characterCollisions.util.lua
--
--	Character collisions util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)

-- lib
local characterCollisionsUtil = {}

-- Get character descendants
function characterCollisionsUtil.getPartDescendants(obs)
	return obs:flatMap(function (c)
		return rx.Observable.fromInstanceEvent(c, "DescendantAdded")
			:startWithTable(c:GetDescendants())
			:filter(dart.isa("BasePart"))
	end)
end

-- return lib
return characterCollisionsUtil
