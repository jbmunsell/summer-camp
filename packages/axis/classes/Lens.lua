--
--	Jackson Munsell
--	04 Oct 2020
--	Lens.lua
--
--	Lens class - for studio editing, shows models at functional part positions when toggled
--

-- services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- modules
local axis = script.Parent.Parent
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local class = require(axis.lib.class)

-- class
local Lens = class.new()

-- Object maintenance
function Lens:init(settings)
	-- Hold settings
	self.settings = settings

	-- Create folder and value
	local valueObject = Instance.new("BoolValue", ReplicatedStorage.studio.lenses)
	valueObject.Name = settings.LensName
	valueObject.Value = false
	local function getVisible()
		return valueObject.Value
	end

	-- Clear old lens contents
	if not workspace.lenses:FindFirstChild(settings.LensName) then
		Instance.new("Folder", workspace.lenses).Name = settings.LensName
	end
	self.lensFolder = workspace.lenses[settings.LensName]

	-- Spawn added
	local spawnAdded = rx.Observable.from(CollectionService:GetInstanceAddedSignal(settings.InstanceTag))
		:filter(getVisible)

	-- Global visibility streams
	local showAll, hideAll = rx.Observable.from(valueObject)
		:partition()
	hideAll:subscribe(dart.bind(Lens.clear, self))
	showAll
		:flatMap(function ()
			return rx.Observable.from(CollectionService:GetTagged(settings.InstanceTag))
		end)
		:merge(spawnAdded)
		:subscribe(dart.bind(Lens.createModel, self))

	-- Spawn change streams
	local function subscribeSpawnEvent(lensMethod, getEvent)
		rx.Observable.fromInstanceTag(settings.InstanceTag)
			:flatMap(function (instance)
				return getEvent(instance)
					:map(dart.constant(instance))
			end)
			:filter(getVisible)
			:map(dart.bind(Lens.getModelFromSpawn, self))
			:filter()
			:subscribe(dart.bind(lensMethod, self))
	end

	-- Update position on spawn moved
	subscribeSpawnEvent(Lens.updateModelPosition, function (spawnPart)
		return rx.Observable.fromProperty(spawnPart, "CFrame")
	end)
	rx.Observable.from(self.lensFolder.ChildAdded)
		:subscribe(dart.bind(Lens.updateModelPosition, self))

	-- Destroy model on spawn removed
	subscribeSpawnEvent(Lens.destroyModel, function (spawnPart)
		return rx.Observable.fromInstanceLeftGame(spawnPart)
	end)
end
function Lens:destroy()
end

-- Get model from spawn
function Lens:getModelFromSpawn(spawnPart)
	if not spawnPart then return end
	for _, model in pairs(self.lensFolder:GetChildren()) do
		if model.SpawnPointer.Value == spawnPart then
			return model
		end
	end
end

-- Clear
function Lens:clear()
	self.lensFolder:ClearAllChildren()
end

-- Create model
function Lens:createModel(spawnPart)
	-- Create and position model
	local model = self.settings.GetModelSeed():Clone()

	-- Create object value to point to spawn part
	Instance.new("ObjectValue", model).Name = "SpawnPointer"
	model.SpawnPointer.Value = spawnPart

	-- Parent it to set off position update
	model.Parent = self.lensFolder
end

-- Update model position
function Lens:updateModelPosition(model)
	local place = self.settings.PlaceModel or function (m, spawnPart)
		m:SetPrimaryPartCFrame(spawnPart.CFrame)
	end
	place(model, model.SpawnPointer.Value.CFrame)
end

-- return class
return Lens
