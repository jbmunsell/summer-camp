--
--	Jackson Munsell
--	19 Oct 2020
--	dodgeball.client.lua
--
--	Dodgeball client driver. Throws on click and that's pretty much it
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local input = env.src.input
local pickup = env.src.objects.pickup
local dodgeball = env.src.objects.dodgeball

-- modules
local dart = require(axis.lib.dart)
local inputUtil = require(input.util)
local pickupUtil = require(pickup.util)

-- Bind click
pickupUtil.getClickWhileHoldingStream(dodgeball)
	:map(inputUtil.getMouseHit)
	:subscribe(dart.forward(dodgeball.net.ThrowRequested))
	