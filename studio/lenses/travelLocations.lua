--
--	Jackson Munsell
--	03 Oct 2020
--	travelLocations.lua
--
--	Travel locations lens for studio
--

-- modules
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local axis = ReplicatedStorage.src.axis
local fx = require(axis.lib.fx)
local Lens = require(axis.classes.Lens)

-- Settings
local settings = {
	LensName = "TravelLocations",
	InstanceTag = "TravelLocation",
	GetModelSeed = function ()
		return ReplicatedStorage.res.travel.TravelLocationIndicator
	end,
	PlaceModel = function (model, spawn)
		fx.placeModelOnGroundAtPoint(model, spawn.Position)
	end
}

-- Create new lens
return function ()
	return Lens.new(settings)
end
