--
--	Jackson Munsell
--	15 Oct 2020
--	bananaPeel.server.lua
--
--	Banana peel object server driver. Causes a player to slip
-- 	and ragdoll upon touched, also flinging the banana peel.
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local bananaPeel = genes.bananaPeel

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Destroy a banana peel
-- 	Fades out on clients and destroys on server
local function destroyBananaPeel(peel)
	peel.state.bananaPeel.hot.Value = false
	bananaPeel.net.Destroyed:FireAllClients(peel)
	delay(genesUtil.getConfig(peel).bananaPeel.destroyFadeDuration + 1, function ()
		peel:Destroy()
	end)
end

-- Subtract a slip and tell client to send character flying
local function tripCharacter(peel, player)
	peel.state.bananaPeel.slips.Value = peel.state.bananaPeel.slips.Value - 1
	peel.PrimaryPart:SetNetworkOwner(player)
	bananaPeel.net.Slipped:FireClient(player, peel)
end

-- Restore ownership to auto assignment
local function restorePeelOwnership(peel)
	peel.PrimaryPart:SetNetworkOwnershipAuto()
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Stream representing all banana peels at their point of creation
local peelObjectStream = genesUtil.initGene(bananaPeel)

-- Currently the only thing influencing peel's hot value is
-- 	whether or not it is being held by a person
peelObjectStream
	:flatMap(function (peel)
		return rx.Observable.from(peel.state.pickup.holder)
			:map(dart.boolNot)
			:map(dart.carry(peel))
	end)
	:delay(0.2) -- give it some time to get out of the thrower's reach
	:subscribe(function (peel, hot)
		peel.state.bananaPeel.hot.Value = hot
	end)

-- Destroy banana peels after a number of slips
local peelExpiredStream = peelObjectStream
	:flatMap(function (peel)
		return rx.Observable.from(peel.state.bananaPeel.slips)
			:filter(dart.equals(0))
			:map(dart.constant(peel))
	end)
peelExpiredStream
	:delay(2)
	:subscribe(destroyBananaPeel)

-- Stream representing character slipping on a peel
local characterTripStream = peelObjectStream
	:delay(0.1)
	:flatMap(function (peel)
		return rx.Observable.fromPlayerTouchedDescendant(peel,
			genesUtil.getConfig(peel).bananaPeel.peelDebounce)
	end)
	:reject(function (peel, player)
		local humanoid = axisUtil.getPlayerHumanoid(player)
		local root = axisUtil.getPlayerHumanoidRootPart(player)
		return math.abs(peel.PrimaryPart.Velocity.Y) >= 0.01
		or peel.state.bananaPeel.expired.Value
		or not peel.state.bananaPeel.hot.Value
		or not root
		or not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Physics
	end)

-- Trip character when they touch
characterTripStream
	:subscribe(tripCharacter)

-- Restore network ownership to auto after a couple seconds
characterTripStream
	:delay(function (peel)
		return genesUtil.getConfig(peel).bananaPeel.getUpDelay
	end)
	:filter(function (peel) return peel:IsDescendantOf(game) end)
	:subscribe(restorePeelOwnership)
