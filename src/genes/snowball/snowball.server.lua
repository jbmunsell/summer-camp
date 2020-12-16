--
--	Jackson Munsell
--	14 Dec 2020
--	snowball.server.lua
--
--	snowball gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)

local ragdoll = env.src.character.ragdoll

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function ragdollPlayer(_, player)
	ragdoll.net.Push:FireClient(player)
	delay(2, function ()
		ragdoll.net.Pop:FireClient(player)
	end)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local snowballs = genesUtil.initGene(genes.snowball)

-- Ragdoll player when hit
local hitStream = snowballs:flatMap(function (instance)
	return rx.Observable.from(instance.interface.projectile.ServerHit)
		:map(dart.carry(instance))
end)
hitStream:delay(3):tap(dart.printConstant("Destroying snowball")):subscribe(dart.destroy)
hitStream
	:map(function (_, hitInstance)
		return _, axisUtil.getPlayerFromCharacterDescendant(hitInstance)
	end)
	:filter(dart.select(2))
	:subscribe(ragdollPlayer)
