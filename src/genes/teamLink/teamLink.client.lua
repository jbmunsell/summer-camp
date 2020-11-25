--
--	Jackson Munsell
--	22 Nov 2020
--	teamLink.client.lua
--
--	teamLink gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local teamLinkUtil = require(genes.teamLink.util)
local multiswitchUtil = require(genes.multiswitch.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function updateSwitch(instance)
	local targetTeam = instance.state.teamLink.team.Value
	local enabled = (not targetTeam or targetTeam == env.LocalPlayer.Team)
	multiswitchUtil.setSwitchEnabled(instance, "interact", "teamLink", enabled)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.teamLink):subscribe(function (instance)
	-- Drive the ones that are in player gui (server drives everything else)
	if instance:IsDescendantOf(env.PlayerGui) then
		teamLinkUtil.initTeamLink(instance)
	end

	-- Interact switch
	if instance.config.teamLink.linkInteract.Value then
		multiswitchUtil.createSwitch(instance, "interact", "teamLink")
		rx.Observable.from(instance.state.teamLink.team)
			:merge(rx.Observable.fromProperty(env.LocalPlayer, "Team"))
			:subscribe(dart.bind(updateSwitch, instance))
	end
end)
