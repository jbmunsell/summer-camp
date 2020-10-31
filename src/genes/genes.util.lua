--
--	Jackson Munsell
--	19 Oct 2020
--	genes.util.lua
--
--	Shared object util. Contains general object functionality
--

-- env
local CollectionService = game:GetService("CollectionService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)

-- lib
local genesUtil = {}
local geneInstanceStreams = {}

-- Has gene
function genesUtil.hasGene(instance, gene)
	return CollectionService:HasTag(instance, require(gene.data).instanceTag)
end
function genesUtil.addGene(instance, gene)
	CollectionService:AddTag(instance, require(gene.data).instanceTag)
end

-- Get genes
function genesUtil.getAllSubGenes(gene)
	local genes = {}
	for _, sub in pairs(require(gene.data).genes or {}) do
		table.insert(genes, sub)
		for _, subsub in pairs(genesUtil.getAllSubGenes(sub).data) do
			table.insert(genes, subsub)
		end
	end
	return tableau.from(genes)
end

-- Get a SNAPSHOT list of instances with a particular gene
function genesUtil.getInstances(gene)
	return tableau.fromInstanceTag(require(gene.data).instanceTag)
		:filter(function (instance)
			return genesUtil.hasFullState(instance, gene)
		end)
end

-- Get an ongoing stream of all instances with a gene
function genesUtil.getInstanceStream(gene)
	-- Operate cache
	local cached = geneInstanceStreams[gene]
	if not cached then
		local data = require(gene.data)
		cached = rx.Observable.fromInstanceTag(data.instanceTag)
			:flatMap(function (instance)
				if genesUtil.hasFullState(instance, gene) then
					return rx.Observable.just(instance)
				else
					return rx.Observable.from(instance.DescendantAdded)
						:filter(function ()
							return genesUtil.hasFullState(instance, gene)
						end)
						:map(dart.constant(instance))
						:merge(rx.Observable.fromInstanceLeftGame(instance):map(dart.constant(nil)))
						:first()
				end
			end)
			:filter()
	end

	return cached
end

-- init object server
function genesUtil.initGene(gene)
	local geneData = require(gene.data)
	local function initInstance(instance)
		-- Set data if we haven't already.
		-- 	This will ensure that we only have the top-level gene set
		-- 	the data value
		if not instance:FindFirstChild("dataScript") then
			genesUtil.setDataScript(instance, gene.data)
		end

		-- Add config folder if it doesn't already exist
		if not instance:FindFirstChild("config") then
			Instance.new("Folder", instance).Name = "config"
		end

		-- Add state for gene
		genesUtil.addStateFolder(instance, gene)

		-- Add interface for gene
		genesUtil.addInterface(instance, gene)

		-- Add tags to apply gene functionality
		genesUtil.getAllSubGenes(gene):foreach(function (g)
			genesUtil.addGene(instance, g)
		end)
	end
	rx.Observable.fromInstanceTag(geneData.instanceTag)
		:subscribe(initInstance)
	return genesUtil.getInstanceStream(gene)
end

-- Add new state folder to object
function genesUtil.addStateFolder(instance, gene)
	local geneData = require(gene.data)
	if not geneData.state then return end

	local state = instance:FindFirstChild("state")
	if not state then
		state = Instance.new("Folder", instance)
		state.Name = "state"
	end
	tableau.tableToValueObjects(geneData.name, geneData.state).Parent = state
end

-- Filter tag with state
local function check(folder, tb)
	for k, v in pairs(tb) do
		if not folder:FindFirstChild(k) then
			return false
		elseif type(v) == "table" and not check(folder[k], v) then
			return false
		end
	end
	return true
end
function genesUtil.hasFullState(instance, gene)
	-- Check primary state
	if not instance:FindFirstChild("state")
	or not instance:FindFirstChild("dataScript") then return end

	-- Chase all genes to see if they have the appropriate state folder
	return genesUtil.getAllSubGenes(gene)
		:append({ gene })
		:all(function (g)
			local data = require(g.data)
			return instance.state:FindFirstChild(data.name)
			and check(instance.state[data.name], data.state)
		end)
end

-- Create gene data
-- Integrate existing gene data into new gene data
local function integrate(baseGeneData, geneData)
	-- Create config table if it doesn't exist
	-- 	(we DO want this to happen for the first recursion with baseGeneData)
	if not baseGeneData.config then
		baseGeneData.config = {}
	end
	if not baseGeneData.config[geneData.name] then
		baseGeneData.config[geneData.name] = {}
	end

	-- Skip the initial recursion with baseGeneData
	if baseGeneData ~= geneData then
		if baseGeneData.name == "lightGroup" then
			print("integrating " .. geneData.name)
		end
		setmetatable(baseGeneData.config[geneData.name], { __index = geneData.config[geneData.name] })
	end

	-- Loop all subsequent genes and integrate
	for _, g in pairs(geneData.genes or {}) do
		integrate(baseGeneData, require(g.data))
	end
end
function genesUtil.createGeneData(raw)
	-- Start with base gene data to get its own sub genes
	integrate(raw, raw)

	-- return compiled data table (same variable "raw" because we set metatables)
	return raw
end

-- Create interface
function genesUtil.addInterface(instance, gene)
	local geneData = require(gene.data)
	local listing = geneData.interface
	if not listing then return end

	if not instance:FindFirstChild("interface") then
		Instance.new("Folder", instance).Name = "interface"
	end
	
	local interface = Instance.new("Folder", instance.interface)
	interface.Name = geneData.name

	local events = listing.events or {}
	local functions = listing.functions or {}
	for _, eventName in pairs(events) do
		Instance.new("BindableEvent", interface).Name = eventName
	end
	for _, fname in pairs(functions) do
		Instance.new("BindableFunction", interface).Name = fname
	end
end

-- Set config script
local instanceProxy_mt = {
	__index = function (self, key)
		local instance = rawget(self, "instance")
		local data = rawget(self, "data")
		local child = instance:FindFirstChild(key)
		if child then
			if child:IsA("ValueBase") then
				return child.Value
			else
				return setmetatable({
					instance = instance[key],
					data = data[key],
				}, getmetatable(self))
			end
		else
			return data[key]
		end
	end,
}
function genesUtil.setDataScript(instance, dataScript)
	if not instance:FindFirstChild("dataScript") then
		Instance.new("ObjectValue", instance).Name = "dataScript"
	end
	instance.dataScript.Value = dataScript
end
function genesUtil.getConfig(instance)
	if instance:FindFirstChild("dataScript") then
		return setmetatable({
			instance = instance.config,
			data = require(instance.dataScript.Value).config,
		}, instanceProxy_mt)
	end
end

-- return lib
return genesUtil
