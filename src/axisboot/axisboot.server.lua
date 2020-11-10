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
require(axis.services.CharacterTagService)()
fx.connectCollisionGroupManagement()
fx.hideGhostParts()
fx.driveEffects()
