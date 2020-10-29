--
--	Jackson Munsell
--	19 Oct 2020
--	objects.util.lua
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
local objectsUtil = {}

-- Get genes
function objectsUtil.getGenes(class)
	local genes = tableau.copy(require(class.config).genes or {})
	for _, gene in pairs(genes) do
		genes = tableau.concat(genes, objectsUtil.getGenes(gene))
	end
	return genes
end

-- Get a SNAPSHOT list of objects of a particular class
function objectsUtil.getObjects(class)
	return tableau.fromInstanceTag(require(class.config).instanceTag)
		:filter(function (object)
			return objectsUtil.hasFullState(object, class)
		end)
end

-- Get an ongoing stream of all objects of a class
function objectsUtil.getObjectsStream(class)
	local config = require(class.config)
	return rx.Observable.fromInstanceTag(config.instanceTag)
		:flatMap(function (instance)
			if objectsUtil.hasFullState(instance, class) then
				return rx.Observable.just(instance)
			else
				return rx.Observable.from(instance.DescendantAdded)
					:filter(function ()
						return objectsUtil.hasFullState(instance, class)
					end)
					:map(dart.constant(instance))
					:merge(rx.Observable.fromInstanceLeftGame(instance):map(dart.constant(nil)))
					:first()
			end
		end)
		:filter()
end

-- init object server
function objectsUtil.initObjectClass(class)
	local config = require(class.config)
	local function initObject(instance)
		-- Set config if we haven't already.
		-- 	This will ensure that we only have the top-level class set
		-- 	the config value
		if not instance:FindFirstChild("configScript") then
			objectsUtil.setConfigScript(instance, class.config)
		end

		-- Add state for class
		objectsUtil.addStateFolder(instance, class)

		-- Add interface for class
		objectsUtil.addInterface(instance, class)

		-- Add tags to apply gene functionality
		local genes = objectsUtil.getGenes(class)
		for _, gene in pairs(genes) do
			CollectionService:AddTag(instance, require(gene.config).instanceTag)
		end
	end
	rx.Observable.fromInstanceTag(config.instanceTag)
		:subscribe(initObject)
	return objectsUtil.getObjectsStream(class)
end

-- Add new state folder to object
function objectsUtil.addStateFolder(instance, class)
	local classConfig = require(class.config)
	if not classConfig.state then return end

	local state = instance:FindFirstChild("state")
	if not state then
		state = Instance.new("Folder", instance)
		state.Name = "state"
	end
	tableau.tableToValueObjects(classConfig.className, classConfig.state).Parent = state
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
function objectsUtil.hasFullState(instance, class)
	-- Check primary state
	if not instance:FindFirstChild("state")
	or not instance:FindFirstChild("configScript") then return end

	-- Chase all genes to see if they have the appropriate state folder
	local genes = objectsUtil.getGenes(class)
	table.insert(genes, 1, class)
	for _, gene in pairs(genes) do
		local config = require(gene.config)
		if not instance.state:FindFirstChild(config.className)
		or not check(instance.state[config.className], config.state) then
			return false
		end
	end
	return true
end

-- Create object config
function objectsUtil.createObjectConfig(config)
	local function integrate(gene)
		local geneConfig = require(gene.config)
		if not config[geneConfig.className] then
			config[geneConfig.className] = {}
		end
		setmetatable(config[geneConfig.className], { __index = geneConfig })
		for _, g in pairs(geneConfig.genes or {}) do
			integrate(g)
		end
	end
	for _, gene in pairs(config.genes or {}) do
		integrate(gene)
	end
	return config
end

-- Create interface
function objectsUtil.addInterface(object, class)
	local classConfig = require(class.config)
	local listing = classConfig.interface
	if not listing then return end

	if not object:FindFirstChild("interface") then
		Instance.new("Folder", object).Name = "interface"
	end
	
	local interface = Instance.new("Folder", object.interface)
	interface.Name = classConfig.className

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
function objectsUtil.setConfigScript(object, configScript)
	if not object:FindFirstChild("configScript") then
		Instance.new("ObjectValue", object).Name = "configScript"
	end
	object.configScript.Value = configScript
end
function objectsUtil.getConfig(object)
	if object:FindFirstChild("configScript") then
		return require(object.configScript.Value)
	end
end

-- return lib
return objectsUtil
