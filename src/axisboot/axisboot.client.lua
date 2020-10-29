--
--	Jackson Munsell
--	24 Aug 2020
--	axisboot.lua
--
--	Boots up specific components of the axis framework
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local fx = require(axis.lib.fx)
fx.connectCollisionGroupManagement()

local glib = require(axis.lib.glib)
-- glib.driveGuiEffects()
-- glib.driveSprings()
glib.drive()

require(axis.handlers.PlayerIndicatorHandler)()
