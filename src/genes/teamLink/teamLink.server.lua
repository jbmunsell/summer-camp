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
	if instance.config.teamLink[configValueName].Value then
		local geneName = require(gene.data).name
		genesUtil.addGeneTag(instance, gene)
		genesUtil.waitForGene(instance, gene)
		rx.Observable.from(instance.state.teamLink.team):filter():subscribe(function (team)
			instance.state[geneName][stateValueName].Value = team.config.team[stateValueName].Value
		end)
	end
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.teamLink):subscribe(function (instance)
	genesUtil.readConfigIntoState(instance, "teamLink", "team")
	tryLink(instance, "linkColor", genes.color, "color")
	tryLink(instance, "linkImage", genes.image, "image")
end)
