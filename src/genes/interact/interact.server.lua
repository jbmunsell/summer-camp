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
local axis = env.packages.axis
local genes = env.src.genes
local interact = genes.interact

-- modules
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local interactUtil = require(interact.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function updateInteractStamp(instance)
	instance.state.interact.stamp.Value = os.time()
end

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
local stream = interactUtil.getInteractStream(interact)
stream:subscribe(fireInteractEvent)
stream:map(dart.select(2)):subscribe(updateInteractStamp)
