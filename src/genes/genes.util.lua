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
local RunService = game:GetService("RunService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)

-- lib
local genesUtil = {}
local geneFolders = {}

-- Create gene folders
if RunService:IsServer() then
	genesUtil.log = Instance.new("BoolValue", ReplicatedStorage.debug)
	genesUtil.log.Name = "genes"
	Instance.new("Folder", ReplicatedStorage).Name = "_geneValueFolders"
else
	genesUtil.log = ReplicatedStorage.debug:WaitForChild("genes")
end

-- Has gene
function genesUtil.hasGeneTag(instance, gene)
	return CollectionService:HasTag(instance, require(gene.data).instanceTag)
end
function genesUtil.removeGeneTag(instance, gene)
	local tag = require(gene.data).instanceTag
	if CollectionService:HasTag(instance, tag) then
		CollectionService:RemoveTag(instance, tag)
	end
end
function genesUtil.addGeneTag(instance, gene)
	local tag = require(gene.data).instanceTag
	if not CollectionService:HasTag(instance, tag) then
		CollectionService:AddTag(instance, tag)
	end
end
function genesUtil.getTaggedInstances(gene)
	return CollectionService:GetTagged(require(gene.data).instanceTag)
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

-- Ready tracking
local readyInstances = {}
local function getReadyInstances(gene)
	if not readyInstances[gene] then
		readyInstances[gene] = {}
	end
	return readyInstances[gene]
end

-- init gene queue
local _geneRequestQueue = {}
local function queueInstanceWithGene(instance, gene)
	for i = #_geneRequestQueue, 1, -1 do
		local entry = _geneRequestQueue[i]
		if entry[1] == instance and entry[2] == gene then return end
	end
	if table.find(getReadyInstances(gene), instance) then return end
	table.insert(_geneRequestQueue, { instance, gene })

	if genesUtil.log.Value then
		print("Queueing ", instance:GetFullName(), " with gene ", gene)
	end

	rx.Observable.from(instance.DescendantAdded)
		:throttle(0.2)
		:startWith(0)
		:filter(dart.bind(genesUtil.hasFullState, instance, gene))
		:first()
		:subscribe(function ()
			table.insert(getReadyInstances(gene), instance)
			gene.data.InstanceReadyEvent:Fire(instance)
		end, nil, (genesUtil.log.Value and function ()
			print("Completed state listener for ", instance, gene)
		end) or nil)
end
local function initInstanceGene(instance, gene)
	-- Add folders
	if RunService:IsServer() or instance:IsDescendantOf(env.PlayerGui) then
		local geneData = require(gene.data)
		genesUtil.touchFolder(instance, gene, "config")
		genesUtil.touchFolder(instance, gene, "state")
		genesUtil.addInterface(instance, gene)

		-- Add tags to apply inherited gene functionality
		for _, g in pairs(geneData.genes) do
			genesUtil.addGeneTag(instance, g)
		end
	end
end
function genesUtil.initQueueProcessing(bufferSize)
	rx.Observable.heartbeat():subscribe(function ()
		for _ = 1, math.min(bufferSize, #_geneRequestQueue) do
			local request = table.remove(_geneRequestQueue, 1)
			initInstanceGene(unpack(request))
		end
	end)
end

-- init object server
function genesUtil.initGene(gene)
	-- Grab data
	local geneData = require(gene.data)

	-- Cache a list of these instances for rapid accessing
	local instanceRemoved = CollectionService:GetInstanceRemovedSignal(geneData.instanceTag)
	local geneReadyList = getReadyInstances(gene)
	if not gene.data:FindFirstChild("InstanceReadyEvent") then
		if RunService:IsServer() then
			Instance.new("BindableEvent", gene.data).Name = "InstanceReadyEvent"
		elseif RunService:IsClient() then
			gene.data:WaitForChild("InstanceReadyEvent")
		end
	end
	rx.Observable.from(instanceRemoved):subscribe(dart.bind(tableau.removeValue, geneReadyList))

	-- (server only) Init all tagged instances when we hear about them
	local queueInstance = dart.follow(queueInstanceWithGene, gene)
	rx.Observable.fromInstanceTag(geneData.instanceTag):subscribe(queueInstance)
	-- if RunService:IsServer() then
	-- 	rx.Observable.fromInstanceTag(geneData.instanceTag):subscribe(queueInstance)
	-- elseif RunService:IsClient() then
	-- 	rx.Observable.fromInstanceTag(geneData.instanceTag):filter(dart.isDescendantOf(env.PlayerGui))
	-- 		:subscribe(queueInstance)
	-- end

	-- return instance stream
	return genesUtil.getInstanceStream(gene)
end

-- Add gene async
-- 	This supports client-side gene addition and folder rendering
function genesUtil.addGeneAsync(instance, gene)
	-- Add collection service tag
	genesUtil.addGeneTag(instance, gene)

	-- Server will automatically queue, so force it if we're client
	-- if RunService:IsClient() and not instance:IsDescendantOf(env.PlayerGui) then
	-- 	queueInstanceWithGene(instance, gene)
	-- end

	-- Wait for folders to render
	genesUtil.waitForGene(instance, gene)
end

-- Get a SNAPSHOT list of instances with a particular gene
function genesUtil.getInstances(gene)
	return tableau.from(getReadyInstances(gene) or {})
end

-- Get instance stream
function genesUtil.getInstanceStream(gene)
	local event = gene.data:WaitForChild("InstanceReadyEvent")
	return rx.Observable.from(event):startWithTable(genesUtil.getInstances(gene):raw())
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
	geneFolders[tableName][gene].Parent = ReplicatedStorage._geneValueFolders
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
local function checkGene(instance, gene, checked)
	checked = checked or {}

	local data = require(gene.data)
	for _, g in pairs(data.genes) do
		-- Keep a list of what we've checked so that we don't double check genes
		if not checked[g] then
			if not checkGene(instance, g, checked) then return false end
			checked[g] = true
		end
	end
	if data.state and not check(instance.state, data.state) then return false end
	if data.config and not check(instance.config, data.config) then return false end
	return true
end
function genesUtil.hasFullState(instance, gene)
	-- Check primary state
	if not instance:FindFirstChild("state") then return end
	if not instance:FindFirstChild("config") then return end

	-- Chase all genes to see if they have the appropriate state folder
	return checkGene(instance, gene)
end
function genesUtil.waitForGene(instance, gene)
	local instanceList = getReadyInstances(gene)
	while not table.find(instanceList, instance) do
		wait()
	end
	for _, sub in pairs(require(gene.data).genes) do
		genesUtil.waitForGene(instance, sub)
	end
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

-- Read config into state
function genesUtil.readConfigIntoState(instance, geneName, valueName)
	local v = instance.config[geneName][valueName].Value
	if v then
		instance.state[geneName][valueName].Value = v
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
			return transform(rx.Observable.from(instance.state[stateGeneName][stateValueName]), instance)
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
