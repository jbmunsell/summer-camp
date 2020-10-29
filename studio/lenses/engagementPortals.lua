--
--	Jackson Munsell
--	03 Oct 2020
--	engagementPortals.lua
--
--	Engagement portals lens for studio
--

-- modules
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local axis = ReplicatedStorage.src.axis
local fx = require(axis.lib.fx)
local Lens = require(axis.classes.Lens)

-- Settings
local settings = {
	LensName = "EngagementPortals",
	InstanceTag = "EngagementPoint",
	GetModelSeed = function () return ReplicatedStorage.res.activities.models.EngagementPortal end,
	PlaceModel = function (model, spawn)
		fx.placeModelOnGroundAtPoint(model, spawn.Position)
	end
}

-- Create new lens
return function ()
	return Lens.new(settings)
end
