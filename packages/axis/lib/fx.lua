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

-- return library
return fx
