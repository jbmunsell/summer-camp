--
--	Jackson Munsell
--	20 Oct 2020
--	balloon.client.lua
--
--	Balloon client driver. Requests a balloon attach on click and
-- 	that's pretty much it
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local input = env.src.input
local genes = env.src.genes
local pickup = genes.pickup
local balloon = genes.balloon

-- modules
local dart = require(axis.lib.dart)
local inputUtil = require(input.util)
local pickupUtil = require(pickup.util)

-- Bind click
pickupUtil.getClickWhileHoldingStream(balloon)
	:map(function ()
		local raycastResult = inputUtil.raycastMouse()
		return raycastResult.Instance, raycastResult.Position
	end)
	:subscribe(dart.forward(balloon.net.PlacementRequested))
	