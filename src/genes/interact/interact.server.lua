--
--	Jackson Munsell
--	04 Sep 2020
--	interact.server.lua
--
--	Server interact functionality
--

-- env
local CollectionService = game:GetService("CollectionService")
local AnalyticsService = game:GetService("AnalyticsService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local interact = genes.interact

-- modules
local genesUtil = require(genes.util)
local interactUtil = require(interact.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function fireInteractEvent(client, instance)
	AnalyticsService:FireEvent("instanceInteracted", {
		instanceName = instance.Name,
		playerId = client.UserId,
		instanceTags = CollectionService:GetTags(instance),
	})
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Init all interactables
genesUtil.initGene(interact)

-- Fire event
interactUtil.getInteractStream(interact):subscribe(fireInteractEvent)
