--
--	Jackson Munsell
--	07/22/20
--	fx.lua
--
--	World fx library
--

-- services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")
local CollectionService = game:GetService("CollectionService")

-- modules
local axis = script.Parent.Parent
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)

-- Consts
local fxClasses = {
	"Fire",
	"Smoke",
	"Sparkles",
	"Light",
	"Beam",
	"ParticleEmitter",
	"BillboardGui",
}

-- Module
local fx = {}

-- Connect collision group management
function fx.bindTagToCollisionGroup(tag, groupName)
	-- Name
	local groups = PhysicsService:GetCollisionGroups()
	local found = false
	for _, group in pairs(groups) do
		if group.name == groupName then
			found = true
			break
		end
	end
	if not found and RunService:IsServer() then
		print(string.format("No collision group exists for name '%s'; creating", groupName))
		PhysicsService:CreateCollisionGroup(groupName)
	end
	
	-- setter
	local function setCollisionGroup(part)
		if not part:IsA("BasePart") then
			error("Part tagged with FXPart is not a BasePart; " .. part:GetFullName())
		end
		PhysicsService:SetPartCollisionGroup(part, groupName)
	end
	for _, instance in pairs(CollectionService:GetTagged(tag)) do
		setCollisionGroup(instance)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(setCollisionGroup)
end
function fx.connectCollisionGroupManagement()
	fx.bindTagToCollisionGroup("FXPart", "FXParts")
	fx.bindTagToCollisionGroup("GhostPart", "GhostParts")
	if RunService:IsServer() then
		for _, group in pairs(PhysicsService:GetCollisionGroups()) do
			PhysicsService:CollisionGroupSetCollidable(group.name, "FXParts", false)
			PhysicsService:CollisionGroupSetCollidable(group.name, "GhostParts", false)
		end
	end
end

-- Hide ghost parts
local function _hide(instance)
	if instance:IsA("BasePart") then
		instance.Transparency = 1
	elseif instance:IsA("SurfaceSelection") then
		instance.Visible = false
	end
end
function fx.hideGhostParts()
	for _, instance in pairs(CollectionService:GetTagged("GhostPart")) do
		_hide(instance)
		for _, descendant in pairs(instance:GetDescendants()) do
			_hide(descendant)
		end
	end
end

-- Enable emitters
function fx.setEmittersEnabled(instance, enabled)
	for _, descendant in pairs(instance:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			descendant.Enabled = enabled
		end
	end
end

-- Clear emitters
function fx.clearEmitters(instance)
	for _, descendant in pairs(instance:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			descendant:Clear()
		end
	end
end

-- Set lights enabled
function fx.setLightsEnabled(instance, enabled)
	for _, descendant in pairs(instance:GetDescendants()) do
		if descendant:IsA("Light") then
			descendant.Enabled = enabled
		end
	end
end

-- Set fx enabled
--	This applies to Lights, smoke, fire, sparkles, and particle emitters
function fx.setFXEnabled(instance, enabled)
	for _, descendant in pairs(instance:GetDescendants()) do
		for _, class in pairs(fxClasses) do
			if descendant:IsA(class) then
				descendant.Enabled = enabled
				break
			end
		end
	end
end

-- Place model on ground at point
function fx.placeModelOnGroundAtPoint(model, point, placementOffset)
	-- Default params
	if typeof(point) == "CFrame" then
		placementOffset = (point - point.p)
		point = point.p
	end
	placementOffset = placementOffset or CFrame.new()

	-- Construct raycast params
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = {}

	-- Insert all ghost parts and player characters
	local function insert(a)
		table.insert(params.FilterDescendantsInstances, a)
	end
	for _, instance in pairs(CollectionService:GetTagged("GhostPart")) do
		insert(instance)
	end
	for _, instance in pairs(CollectionService:GetTagged("FXPart")) do
		insert(instance)
	end
	for _, player in pairs(game:GetService("Players"):GetPlayers()) do
		insert(player.Character)
	end

	-- Raycast down 100 studs
	local result = workspace:Raycast(point, Vector3.new(0, -100, 0), params)
	local position = result and result.Position or point
	position = position + Vector3.new(0, model.PrimaryPart.Size.Y * 0.5, 0)

	-- Place model at hit point
	model:SetPrimaryPartCFrame(CFrame.new(position) * placementOffset)
end

-- Fade out and destroy
function fx.fadeOutAndDestroy(instance, t)
	-- Default time
	t = t or 0.5

	-- Create list of tweens
	local tweens = {}
	local function log(v)
		local props = {}
		if v:IsA("BasePart") then
			props.Transparency = 1
		elseif v:IsA("GuiObject") then
			props.BackgroundTransparency = 1
		elseif v:IsA("Light") then
			props.Brightness = 0
		end

		-- Can't be elseif because it's also a gui object
		if v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then
			props.TextTransparency = 1
			props.TextStrokeTransparency = 1
		end
		
		table.insert(tweens, TweenService:Create(v, TweenInfo.new(t), props))
	end
	for _, d in pairs(instance:GetDescendants()) do
		log(d)
	end
	log(instance)

	-- Tween
	local dcon
	for i, tween in pairs(tweens) do
		tween:Play()
		if i == #tweens then
			dcon = tween.Completed:Connect(function ()
				dcon:Disconnect()
				instance:Destroy()
			end)
		end
	end
end

-- hide
function fx.hide(instance)
	local instances = instance:GetDescendants()
	table.insert(instances, instance)

	for _, v in pairs(instances) do
		if v:IsA("BasePart") then
			v.Transparency = 1
		elseif v:IsA("GuiObject") then
			v.Visible = false
		-- elseif v:IsA("Light") then
		-- 	v.Enabled = false
		end
	end
end

-- smooth destroy
function fx.smoothDestroy(instance)
	-- Wait for maximum particle emitter duration
	local max = 0
	for _, d in pairs(instance:GetDescendants()) do
		if d:IsA("ParticleEmitter") then
			d.Enabled = false
			if d.Lifetime.Max > max then
				max = d.Lifetime.Max
			end
		end
	end
	delay(max, function ()
		instance:Destroy()
	end)
end

---------------------------------------------------------------------------------------------------
-- Transparency setting
---------------------------------------------------------------------------------------------------

local TransparencyProps = {
	BasePart    = {"Transparency"},
	Texture     = {"Transparency"},
	GuiObject   = {"BackgroundTransparency"},
	TextLabel	= {"TextTransparency", "TextStrokeTransparency"},
	TextBox	    = {"TextTransparency", "TextStrokeTransparency"},
	TextButton	= {"TextTransparency", "TextStrokeTransparency"},
	ImageLabel	= {"ImageTransparency"},
	ImageButton	= {"ImageTransparency"},
}
function fx.logTransparencyWithValue(instance, initValue)
	-- Parameters
	initValue = initValue or 0
	assert(instance and type(instance) == "userdata", "fx.logTransparencyWithValue requires an instance")
	assert(initValue ~= 1, "fx.logTransparencyWithValue requires a value not equal to 1")

	-- Zero transparency properties folder
	local propertiesFolder
	local function touchFolder()
		if not propertiesFolder then
			propertiesFolder = Instance.new("Folder", instance)
			propertiesFolder.Name = "ZeroTransparencyProperties"
		end
		return propertiesFolder
	end

	-- Log all properties for appropriate classes
	for class, properties in pairs(TransparencyProps) do
		if instance:IsA(class) then
			local folder = touchFolder()
			for _, property in pairs(properties) do
				-- Create value
				local value = Instance.new("NumberValue", folder)
				value.Name = property

				-- Extrapolate zero transparency value from current and init
				value.Value = instance[property] - ((1 - instance[property]) / (1 - initValue))
			end
		end
	end

	-- Recurse through children
	for _, child in pairs(instance:GetChildren()) do
		fx.logTransparencyWithValue(child, initValue)
	end
end
function fx.setTransparency(instance, transparency)
	-- Parameters
	assert(instance and type(instance) == "userdata", "fx.setTransparency requires an instance")
	assert(transparency, "fx.setTransparency requires a number")

	-- Try color properties
	for class, _ in pairs(TransparencyProps) do
		if instance:IsA(class) then
			local folder = instance:FindFirstChild("ZeroTransparencyProperties")
			if folder then
				for _, valueObject in pairs(folder:GetChildren()) do
					instance[valueObject.Name] = valueObject.Value + (1 - valueObject.Value) * transparency
				end
			end
		end
	end

	-- Recurse through children
	for _, child in pairs(instance:GetChildren()) do
		fx.setTransparency(child, transparency)
	end
end

---------------------------------------------------------------------------------------------------
-- Brightness setting
---------------------------------------------------------------------------------------------------

-- Remove saturation
local ColorProps = {
	BasePart    = {"Color"},
	GuiObject   = {"BackgroundColor3", "BorderColor3"},
	TextLabel	= {"TextColor3", "TextStrokeColor3"},
	TextBox		= {"TextColor3", "TextStrokeColor3"},
	TextButton	= {"TextColor3", "TextStrokeColor3"},
	ImageLabel	= {"ImageColor3"},
	ImageButton	= {"ImageColor3"},
}
function fx.logColorsWithBrightness(instance, startingValue)
	-- Parameters
	startingValue = startingValue or 1
	assert(instance and type(instance) == "userdata", "fx.logColorsWithBrightness requires an instance")
	assert(startingValue > 0, "fx.logColorsWithBrightness requires a value greater than zero")

	-- Full brightness properties folder
	local propertiesFolder
	local function touchFolder()
		if not propertiesFolder then
			propertiesFolder = Instance.new("Folder", instance)
			propertiesFolder.Name = "FullBrightnessColorProperties"
		end
		return propertiesFolder
	end

	-- Log all properties for appropriate classes
	for class, properties in pairs(ColorProps) do
		if instance:IsA(class) then
			local folder = touchFolder()
			for _, property in pairs(properties) do
				-- Create value
				local value = Instance.new("Color3Value", folder)
				value.Name = property

				-- Extrapolate full brightness from current value
				local h, s, v = Color3.toHSV(instance[property])
				value.Value = Color3.fromHSV(h, s, (v / startingValue))
			end
		end
	end

	-- Recurse through children
	for _, child in pairs(instance:GetChildren()) do
		fx.logColorsWithBrightness(child, startingValue)
	end
end
function fx.setBrightness(instance, brightness)
	-- Parameters
	assert(instance and type(instance) == "userdata", "fx.setBrightness requires an instance")
	assert(brightness, "fx.setBrightness requires a number")

	-- Try color properties
	for class, _ in pairs(ColorProps) do
		if instance:IsA(class) then
			local folder = instance:FindFirstChild("FullBrightnessColorProperties")
			if folder then
				for _, valueObject in pairs(folder:GetChildren()) do
					local h, s, v = Color3.toHSV(valueObject.Value)
					instance[valueObject.Name] = Color3.fromHSV(h, s, v * brightness)
				end
			end
		end
	end

	-- Recurse through children
	for _, child in pairs(instance:GetChildren()) do
		fx.setBrightness(child, brightness)
	end
end

---------------------------------------------------------------------------------------------------
-- Effects
---------------------------------------------------------------------------------------------------

-- Instance effects list
local InstanceEffects = {
	BrightnessEffect = {
		valueType = "NumberValue",
		init = function (effect, instance, value)
			fx.logColorsWithBrightness(instance, value)
			effect.Value = (value or 1)
		end,
		render = fx.setBrightness,
	},
	TransparencyEffect = {
		valueType = "NumberValue",
		init = function (effect, instance, value)
			fx.logTransparencyWithValue(instance, value)
			effect.Value = value or 0
		end,
		render = fx.setTransparency,
	},
}

-- new effects
function fx.new(effectType, instance, startingValue)
	-- Get effect
	local effectClass = InstanceEffects[effectType]

	-- Create it within instance
	local effect = Instance.new(effectClass.valueType, instance)
	effect.Name = effectType
	effectClass.init(effect, instance, startingValue)
	CollectionService:AddTag(effect, effectType)
end

-- drive effects
function fx.driveEffects()
	for effectType, effectClass in pairs(InstanceEffects) do
		rx.Observable.fromInstanceTag(effectType)
			:flatMap(function (effect)
				return rx.Observable.from(effect.Changed)
					:map(dart.carry(effect.Parent))
			end)
			:subscribe(effectClass.render)
	end
end

-- return library
return fx
