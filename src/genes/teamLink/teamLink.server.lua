--
--	Jackson Munsell
--	22 Nov 2020
--	teamLink.server.lua
--
--	teamLink gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function tryLink(instance, configValueName, gene, stateValueName)
	rx.Observable.from(instance.config.teamLink[configValueName])
		:filter()
		:first()
		:subscribe(function ()
			local geneName = require(gene.data).name
			genesUtil.addGeneTag(instance, gene)
			genesUtil.waitForGene(instance, gene)
			rx.Observable.from(instance.state.teamLink.team)
				:filter()
				:subscribe(function (team)
					if genesUtil.hasGeneTag(team, genes.team) then
						instance.state[geneName][stateValueName].Value = team.config.team[stateValueName].Value
					end
				end)
		end)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.teamLink):subscribe(function (instance)
	-- Link properties (interact is handled by client)
	genesUtil.readConfigIntoState(instance, "teamLink", "team")
	tryLink(instance, "linkColor", genes.color, "color")
	tryLink(instance, "linkImage", genes.image, "image")

	-- Pull from owner if config says so
	if instance.config.teamLink.linkFromOwnerTeam.Value then
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
end)
