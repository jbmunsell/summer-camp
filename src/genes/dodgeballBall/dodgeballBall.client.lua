--
--	Jackson Munsell
--	19 Oct 2020
--	dodgeballBall.client.lua
--
--	DodgeballBall client driver. Throws on click and that's pretty much it
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local input = env.src.input
local genes = env.src.genes
local pickup = genes.pickup
local dodgeballBall = genes.dodgeballBall

-- modules
local dart = require(axis.lib.dart)
local inputUtil = require(input.util)
local pickupUtil = require(pickup.util)
local genesUtil = require(genes.util)

-- init
genesUtil.initGene(dodgeballBall)

-- Bind click
pickupUtil.getClickWhileHoldingStream(dodgeballBall)
	:map(inputUtil.getMouseHit)
	:subscribe(dart.forward(dodgeballBall.net.ThrowRequested))
	