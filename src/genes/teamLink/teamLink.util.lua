--
--	Jackson Munsell
--	22 Nov 2020
--	teamLink.util.lua
--
--	teamLink gene util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local genesUtil = require(genes.util)

-- lib
local teamLinkUtil = {}

local function defaultAccess(team, stateValueName)
	return team.config.team[stateValueName].Value
end

local function tryLink(instance, configValueName, gene, stateValueName, default, transform)
	transform = transform or defaultAccess
	if instance.config.teamLink[configValueName].Value then
		local geneName = require(gene.data).name
		rx.Observable.from(instance.state.teamLink.team)
			:subscribe(function (team)
				genesUtil.waitForGene(instance, gene)
				if team and genesUtil.hasGeneTag(team, genes.team) then
					instance.state[geneName][stateValueName].Value = transform(team, stateValueName)
				else
					instance.state[geneName][stateValueName].Value = default
				end
			end)
	end
end

function teamLinkUtil.initTeamLink(instance)
	-- Link properties (interact is handled by client)
	genesUtil.readConfigIntoState(instance, "teamLink", "team")
	local config = instance.config.teamLink
	tryLink(instance, "linkColor", genes.color, "color", config.defaultColor.Value)
	tryLink(instance, "linkImage", genes.image, "image", config.defaultImage.Value, function (team)
		return team.config.team[config.teamImageType.Value].Value
	end)

	-- Pull from owner if config says so
	if config.linkFromOwnerTeam.Value then
		genesUtil.waitForGene(instance, genes.pickup)
		rx.Observable.from(instance.state.pickup.owner)
			:switchMap(function (player)
				return player
				and rx.Observable.fromProperty(player, "Team", true) 
				or rx.Observable.just(nil)
			end)
			:subscribe(function (team)
				instance.state.teamLink.team.Value = team
			end)
	end
end

-- return lib
return teamLinkUtil
