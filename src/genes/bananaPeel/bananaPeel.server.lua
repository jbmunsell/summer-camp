--
--	Jackson Munsell
--	15 Oct 2020
--	bananaPeel.server.lua
--
--	Banana peel object server driver. Causes a player to slip
-- 	and ragdoll upon touched, also flinging the banana peel.
--

-- env
local AnalyticsService = game:GetService("AnalyticsService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local bananaPeel = genes.bananaPeel
local throw = genes.throw

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local throwUtil = require(throw.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Destroy a banana peel
-- 	Fades out on clients and destroys on server
local function destroyBananaPeel(peel)
	peel.state.bananaPeel.hot.Value = false
	bananaPeel.net.Destroyed:FireAllClients(peel)
	delay(peel.config.bananaPeel.destroyFadeDuration.Value + 1, function ()
		peel:Destroy()
	end)
end

-- Subtract a slip and tell client to send character flying
local function tripCharacter(peel, player)
	peel.state.bananaPeel.slips.Value = peel.state.bananaPeel.slips.Value - 1
	pcall(function ()
		peel.PrimaryPart:SetNetworkOwner(player)
	end)
	bananaPeel.net.Slipped:FireClient(player, peel)

	-- Send event
	AnalyticsService:FireEvent("bananaPeelSlipped", {
		playerId = player.UserId,
	})
end

-- Restore ownership to auto assignment
local function restorePeelOwnership(peel)
	peel.PrimaryPart:SetNetworkOwnershipAuto()
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Stream representing all banana peels at their point of creation
local peelInstanceStream = genesUtil.initGene(bananaPeel)

-- Currently the only thing influencing peel's hot value is
-- 	whether or not it is being held by a person
throwUtil.getThrowStream(bananaPeel)
	:map(dart.select(1))
	:delay(0.2)
	:map(dart.drag(true))
	:subscribe(genesUtil.setStateValue(bananaPeel, "hot"))

-- Destroy banana peels after a number of slips
local peelExpiredStream = peelInstanceStream
	:flatMap(function (peel)
		return rx.Observable.from(peel.state.bananaPeel.slips)
			:filter(dart.equals(0))
			:map(dart.constant(peel))
	end)
peelExpiredStream
	:delay(2)
	:subscribe(destroyBananaPeel)

-- Stream representing character slipping on a peel
local characterTripStream = peelInstanceStream
	:flatMap(function (peel)
		return rx.Observable.fromPlayerTouchedDescendant(peel,
			peel.config.bananaPeel.peelDebounce.Value)
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
		return peel.config.bananaPeel.getUpDelay.Value
	end)
	:filter(function (peel) return peel:IsDescendantOf(game) end)
	:subscribe(restorePeelOwnership)
