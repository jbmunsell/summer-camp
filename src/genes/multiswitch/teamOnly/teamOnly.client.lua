--
--	Jackson Munsell
--	11 Nov 2020
--	teamOnly.client.lua
--
--	teamOnly gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local multiswitch = genes.multiswitch
local teamOnly = multiswitch.teamOnly

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local multiswitchUtil = require(multiswitch.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Update switch
local function updateSwitch(instance)
	local targetTeam = instance.config.teamOnly.team.Value
	local enabled = (not targetTeam or (targetTeam == env.LocalPlayer.Team))
	multiswitchUtil.setSwitchEnabled(instance, "interact", "teamOnly", enabled)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Apply interact lock for teams when the unlocked team changes
-- OR the localplayer team changes
genesUtil.getInstanceStream(teamOnly)
	:flatMap(function (instance)
		return rx.Observable.from(instance.config.teamOnly.team)
			:merge(rx.Observable.fromProperty(env.LocalPlayer, "Team"))
			:map(dart.constant(instance))
	end)
	:subscribe(updateSwitch)
