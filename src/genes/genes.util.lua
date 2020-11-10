--
--	Jackson Munsell
--	19 Oct 2020
--	genes.util.lua
--
--	Shared object util. Contains general object functionality
--

-- env
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)

-- lib
local genesUtil = {}
local geneInstanceStreams = {}
local geneFolders = {}

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
		-- Add folders
		genesUtil.touchFolder(instance, gene, "config")
		genesUtil.touchFolder(instance, gene, "state")
		genesUtil.addInterface(instance, gene)

		-- Add tags to apply inherited gene functionality
		genesUtil.getAllSubGenes(gene):foreach(function (g)
			genesUtil.addGene(instance, g)
		end)
	end
	rx.Observable.fromInstanceTag(geneData.instanceTag)
		:subscribe(initInstance)
	return genesUtil.getInstanceStream(gene)
end

-- Add new state folder to object
local function mergeFolders(src, dest)
	for _, child in pairs(src:GetChildren()) do
		local existing = dest:FindFirstChild(child.Name)
		if not existing then
			-- stick the whole thing there
			child:Clone().Parent = dest
		else
			if child:IsA("Folder") then
				-- merge folder contents
				mergeFolders(child, existing)
			else -- assume value object
				-- existing.Value = child.Value
				-- Trying out removing this because it overwrites custom config settings
			end
		end
	end
end
function genesUtil.touchFolder(instance, gene, tableName)
	local geneData = require(gene.data)
	if not geneData[tableName] then return end

	local folder = instance:FindFirstChild(tableName)
	if not folder then
		folder = Instance.new("Folder", instance)
		folder.Name = tableName
	end

	if not geneFolders[tableName] then
		geneFolders[tableName] = {}
	end
	if not geneFolders[tableName][gene] then
		geneFolders[tableName][gene] = tableau.tableToValueObjects("", geneData[tableName])
	end
	geneFolders[tableName][gene].Parent = ReplicatedStorage
	mergeFolders(geneFolders[tableName][gene], folder)
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
	if not instance:FindFirstChild("state") then return end
	if not instance:FindFirstChild("config") then return end

	-- Chase all genes to see if they have the appropriate state folder
	return genesUtil.getAllSubGenes(gene)
		:append({ gene })
		:all(function (g)
			local data = require(g.data)
			local hasState = not data.state or check(instance.state, data.state)
			local hasConfig = not data.config or check(instance.config, data.config)
			return hasState and hasConfig
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
		setmetatable(baseGeneData.config[geneData.name], { __index = geneData.config[geneData.name] })
	end

	-- Loop all subsequent genes and integrate
	for _, g in pairs(geneData.genes or {}) do
		integrate(baseGeneData, require(g.data))
	end
end
function genesUtil.createGeneData(raw)
	-- Start with base gene data to get its own sub genes
	-- integrate(raw, raw)

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

---------------------------------------------------------------------------------------------------
-- Factory functions
---------------------------------------------------------------------------------------------------

-- Make set state
-- 	Returns a function that accepts an instance and a value and sets that instance's state value
function genesUtil.setStateValue(gene, stateValueName)
	local geneName = require(gene.data).name
	return function (instance, value)
		instance.state[geneName][stateValueName].Value = value
	end
end
function genesUtil.getStateValue(gene, stateValueName)
	local geneName = require(gene.data).name
	return function (instance)
		return instance.state[geneName][stateValueName].Value
	end
end
function genesUtil.stateValueEquals(gene, stateValueName, target)
	local geneName = require(gene.data).name
	return function (instance)
		return instance.state[geneName][stateValueName].Value == target
	end
end

-- Make transform state
-- 	Similar to makeSetState, but instead of using a callback value this function runs a transform
-- 	on the current state value.
-- 	Useful for toggling booleans or incrementing numbers.
function genesUtil.transformStateValue(gene, stateValueName, transform)
	local geneName = require(gene.data).name
	return function (instance)
		local valueObject = instance.state[geneName][stateValueName]
		valueObject.Value = transform(valueObject.Value)
	end
end
function genesUtil.toggleStateValue(gene, stateValueName)
	return genesUtil.transformStateValue(gene, stateValueName, dart.boolNot)
end

---------------------------------------------------------------------------------------------------
-- Stream creation
---------------------------------------------------------------------------------------------------

-- Observe state
-- 	Returns a stream of instances from the given gene flatmapped to a specific state value changed,
-- 	passing the instance and the new state value.
function genesUtil.observeStateValue(gene, stateValueName, transform)
	return genesUtil.crossObserveStateValue(gene, gene, stateValueName, transform)
end

-- Cross observe state
-- 	Similar to observeStateValue, but this function uses the instance stream of the first gene
-- 	while observing a state value from another gene.
-- 	This is useful for having subgenes listen to their parent gene's state changes.
function genesUtil.crossObserveStateValue(instanceGene, stateGene, stateValueName, transform)
	transform = transform or dart.identity

	local stateGeneName = require(stateGene.data).name
	return genesUtil.getInstanceStream(instanceGene)
		:flatMap(function (instance)
			return transform(rx.Observable.from(instance.state[stateGeneName][stateValueName]))
				:map(dart.carry(instance))
		end)
end

-- With change count!
-- 	This is used for state-based transition effects, like playing a sound when a state goes
-- 	to false, or emitting particles when a state changes. We don't want to do these things
-- 	on the initial rendering (change count 0, since it's init, not transition), but we still want some
-- 	of the rendering code, like raw setting values etc.
-- 	This function will select only the instance and follow it with the change count.
function genesUtil.observeStateValueWithInit(instanceGene, stateValueName)
	return genesUtil.observeStateValue(instanceGene, stateValueName, function (o)
		-- What we do here is we take the FIRST emission from the source observable
		-- 	and map it to true, and then merge everything BUT the first emission
		-- 	from the source observable and map it to nil
		return o:skip(1)
			:map(dart.constant(nil))
			:merge(o:first():map(dart.constant(true)))
	end)
end

-- return lib
return genesUtil
