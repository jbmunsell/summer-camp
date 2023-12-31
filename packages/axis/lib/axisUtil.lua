--
--	Jackson Munsell
--	04 Sep 2020
--	axisUtil.lua
--
--	Collection of handy functions that don't really belong in any other specific place
--

-- env
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- modules
local axis = script.Parent.Parent
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local easing = require(axis.lib.easing)

-- lib
local axisUtil = {}

-- Constants
local SmoothAttachTweenInfo = TweenInfo.new(
	0.3,
	Enum.EasingStyle.Cubic,
	Enum.EasingDirection.Out
)
local ImpulseDuration = 0.1
local ImpulseProperties = {
	VectorForce = "Force",
	Torque      = "Torque",
}

-- Utility functions
local function jip()
	return math.random() - 0.5
end

-- Put commas in a number
function axisUtil.commify(number)
	local str = tostring(number)
	return
		#str % 3 == 0 and
		str:reverse():gsub("(%d%d%d)", "%1,"):reverse():sub(2) or
		str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
end

-- Destroy child by name if it exists
function axisUtil.destroyChild(instance, childName)
	local child = instance:FindFirstChild(childName)
	if child then
		child:Destroy()
	end
end
function axisUtil.destroyChildren(instance, childName)
	for _, child in pairs(instance:GetChildren()) do
		if child.Name == childName then
			child:Destroy()
		end
	end
end

-- Get player humanoid
function axisUtil.getPlayerCharacterStream()
	return rx.Observable.from(Players.PlayerAdded)
		:startWithTable(Players:GetPlayers())
		:flatMap(function (p)
			return rx.Observable.fromInstanceEvent(p, "CharacterAdded")
				:startWith(p.Character)
				:filter()
				:map(dart.carry(p))
		end)
end
function axisUtil.getHumanoidDiedStream()
	return rx.Observable.from(workspace.DescendantAdded)
		:startWithTable(workspace:GetDescendants())
		:filter(dart.isa("Humanoid"))
		:flatMap(function (h)
			return rx.Observable.fromInstanceEvent(h, "Died")
				:map(dart.constant(h))
		end)
end
function axisUtil.getPlayerHumanoid(player)
	return player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
end
function axisUtil.getPlayerHumanoidRootPart(player)
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end
function axisUtil.getPlayerFromCharacterDescendant(d)
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and d:IsDescendantOf(player.Character) then
			return player
		end
	end
end

-- Square distance
function axisUtil.squareMagnitude(vector)
	return vector.X * vector.X + vector.Y * vector.Y + vector.Z * vector.Z
end

-- Thank you badcc!!!!!!
function axisUtil.closestPointToPart(point, part)
    local cf = part.CFrame
    local relative = cf:pointToObjectSpace(point)
    local x = math.clamp(relative.X, -part.Size.X * 0.5, part.Size.X * 0.5)
    local y = math.clamp(relative.Y, -part.Size.Y * 0.5, part.Size.Y * 0.5)
    local z = math.clamp(relative.Z, -part.Size.Z * 0.5, part.Size.Z * 0.5)
    return cf * Vector3.new(x, y, z)
end

-- Get position
function axisUtil.getCFrame(instance)
	return axisUtil.makeGetCFrame(instance)()
end
function axisUtil.makeGetCFrame(instance)
	if instance:IsA("Model") then
		return function ()
			local primary = instance.PrimaryPart
			if not primary then
				error("Attempt to call getCFrame on a model with no PrimaryPart: " .. instance:GetFullName())
			end
			return primary.CFrame
		end
	elseif instance:IsA("BasePart") then
		return function ()
			return instance.CFrame
		end
	elseif instance:IsA("Attachment") then
		return function ()
			return instance.WorldCFrame
		end
	else
		error("Unable to get CFrame for value of type " .. typeof(instance))
	end
end
function axisUtil.getPosition(instance)
	return axisUtil.getCFrame(instance).p
end
function axisUtil.setCFrame(instance, cframe)
	axisUtil.makeSetCFrame(instance)(cframe)
end
function axisUtil.makeSetCFrame(instance)
	if instance:IsA("Model") then
		return function (cframe)
			instance:SetPrimaryPartCFrame(cframe)
		end
	elseif instance:IsA("BasePart") then
		return function (cframe)
			instance.CFrame = cframe
		end
	-- elseif instance:IsA("Attachment") then
	-- 	return instance.WorldCFrame
	else
		error("Unable to set CFrame for value of type " .. typeof(instance))
	end
end

-- Get local humanoid
function axisUtil.getLocalHumanoid()
	if not RunService:IsClient() then
		error("axisUtil.getLocalHumanoid can only be called from the client.")
	end
	local player = Players.LocalPlayer
	local character = player and player.Character
	return character and character:FindFirstChildWhichIsA("Humanoid")
end
function axisUtil.getLocalAnimator()
	if not RunService:IsClient() then
		error("axisUtil.getLocalAnimator can only be called from the client.")
	end
	local player = Players.LocalPlayer
	local character = player and player.Character
	return character and character:FindFirstChildWhichIsA("Humanoid"):WaitForChild("Animator")
end
function axisUtil.getLocalHumanoidRootPart()
	if not RunService:IsClient() then
		error("axisUtil.getLocalHumanoidRootPart can only be called from the client.")
	end
	local player = Players.LocalPlayer
	local character = player and player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

-- Stop a playing animation track by its source animation
function axisUtil.stopAnimationTrack(animator, animation)
	for _, track in pairs(animator:GetPlayingAnimationTracks()) do
		if track.Animation == animation then
			track:Stop()
		end
	end
end

-- Set properties
function axisUtil.setProperties(instance, properties)
	for k, v in pairs(properties) do
		instance[k] = v
	end
end

-- Get tagged ancestor
function axisUtil.getTaggedAncestor(instance, tag, checkInstance)
	if checkInstance and CollectionService:HasTag(instance, tag) then
		return instance
	end
	while instance and instance ~= game do
		instance = instance.Parent
		if CollectionService:HasTag(instance, tag) then
			return instance
		end
	end
	return nil
end

-- Get descendants with a specific collection service tag
function axisUtil.getTaggedDescendants(instance, tag)
	local tagged = {}
	for _, v in pairs(CollectionService:GetTagged(tag)) do
		if v:IsDescendantOf(instance) then
			table.insert(tagged, v)
		end
	end
	return tagged
end
function axisUtil.getFirstTaggedDescendant(instance, tag)
	return axisUtil.getTaggedDescendants(instance, tag)[1]
end

-- Get random point inside of a part
function axisUtil.getRandomPointInPart(part)
	return (part.CFrame * CFrame.new(jip() * part.Size.X, jip() * part.Size.Y, jip() * part.Size.Z)).p
end
function axisUtil.getRandomPointInPartXZ(part)
	return (part.CFrame * CFrame.new(jip() * part.Size.X, 0, jip() * part.Size.Z)).p
end

-- Is point inside of part
-- Very naive
function axisUtil.isPointInPart(point, part)
	local a = part.CFrame * CFrame.new(-part.Size * 0.5)
	local b = a * CFrame.new(part.Size)
	a, b = a.p, b.p
	
	return	point.X >= math.min(a.X, b.X) and point.X <= math.max(a.X, b.X)
	and		point.Y >= math.min(a.Y, b.Y) and point.Y <= math.max(a.Y, b.Y)
	and		point.Z >= math.min(a.Z, b.Z) and point.Z <= math.max(a.Z, b.Z)
end
function axisUtil.isPointInPartXZ(point, part)
	local offset = part.CFrame:pointToObjectSpace(point)
	local hsize = part.Size * 0.5
	return math.abs(offset.X) <= hsize.X and math.abs(offset.Z) <= hsize.Z
end

-- Calculate mass of a whole model
function axisUtil.getModelMass(model)
	local mass = 0
	for _, child in pairs(model:GetDescendants()) do
		if child:IsA("BasePart") then
			mass = mass + child:GetMass()
		end
	end
	return mass
end

-- Base apply impulse function
local function applyCharacterImpulse(character, impulse, instanceType)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		print("Cannot apply velocity impulse to character with no root part")
		return
	end

	local impulseProperty = ImpulseProperties[instanceType]
	local impulseObject = Instance.new(instanceType, root)
	impulseObject.RelativeTo = Enum.ActuatorRelativeTo.World
	impulseObject.Attachment0 = root.RootRigAttachment
	impulseObject[impulseProperty] = axisUtil.getModelMass(character) * impulse
	delay(ImpulseDuration, function ()
		impulseObject:Destroy()
	end)
end

-- Apply a velocity impulse to a character
function axisUtil.applyCharacterVelocityImpulse(character, impulse)
	applyCharacterImpulse(character, impulse, "VectorForce")
end

-- Apply a rotation impulse to a character via torque
-- NOTE: This only works with characters that are in a physics based state
function axisUtil.applyCharacterRotationImpulse(character, impulse)
	applyCharacterImpulse(character, impulse, "Torque")
end

-- Create dynamic tween
function axisUtil.createDynamicTween(instance, tweenInfo, targets)
	-- Create proxy value object
	local val = Instance.new("NumberValue", ReplicatedStorage)
	val.Value = 0
	local pulse = RunService.Heartbeat:Connect(function ()
		for property, getTarget in pairs(targets) do
			instance[property] = getTarget(val.Value)
		end
	end)
	local tween = TweenService:Create(val, tweenInfo, { Value = 1 })
	tween.Completed:Connect(function () pulse:Disconnect() end)
	return tween
end

-- Weld attachment and tween
function axisUtil.getObjectCFrame(object)
	if object:IsA("BasePart") then
		return object.CFrame
	elseif object:IsA("Model") then
		return object:GetPrimaryPartCFrame()
	end
end
function axisUtil.computeAttachInfo(att_a, att_b)
	local target = att_a.CFrame * att_b.CFrame:inverse()
	local current = att_a.Parent.CFrame:toObjectSpace(att_b.Parent.CFrame)

	return {
		att_a = att_a,
		att_b = att_b,
		target = target,
		current = current,
	}
end
function axisUtil.findAttachments(a, b, attachmentName)
	local att_a = a:FindFirstChild(attachmentName, true)
	local att_b = b:FindFirstChild(attachmentName, true)

	if not att_a and att_b then
		error(string.format("Unable to find attachments for name '%s' in %s and %s",
			attachmentName, a:GetFullName(), b:GetFullName()))
	end

	return att_a, att_b
end

-- This function will simply align the parents of two attachments, moving B to match A's CFrame.
-- 	It does not create a weld.
function axisUtil.snapAttachments(att_a, att_b)
	att_b.Parent.CFrame = att_a.WorldCFrame:toWorldSpace(att_b.CFrame:inverse())
end

-- Smooth attach attachments
local function assertAttachment(attachment, name, instance)
	if not attachment then
		error(string.format("Unable to find attachment named '%s' in %s", name, instance:GetFullName()))
	end
end
local function getAttachment(x, xName)
	if typeof(xName) == "string" then
		return x:FindFirstChild(xName, true)
	else
		return xName
	end
end
local function getAttachments(a, aName, b, bName)
	local att_a = getAttachment(a, aName)
	local att_b = getAttachment(b, bName)
	assertAttachment(att_a, aName, a)
	assertAttachment(att_b, bName, b)
	return att_a, att_b
end
function axisUtil.smoothAttachAttachments(a, aName, b, bName, tweenInfo)
	tweenInfo = tweenInfo or SmoothAttachTweenInfo

	local att_a, att_b = getAttachments(a, aName, b, bName)

	local info = axisUtil.computeAttachInfo(att_a, att_b)

	local original = att_b.Parent.CFrame
	local weld = Instance.new("Weld", a)
	weld.C0 = info.current
	weld.Part0 = info.att_a.Parent
	weld.Part1 = info.att_b.Parent

	local t = rx.BehaviorSubject.new(0)
	local terminator = t:filter(function (x)
		return x >= tweenInfo.Time
	end):first()
	rx.Observable.from(RunService.Stepped):takeUntil(terminator):subscribe(function (_, dt)
		local nt = t:getValue() + dt
		t:push(nt)
		if not att_a.Parent then return end
		local targetCFrame = att_a.Parent.CFrame:toWorldSpace(info.target)
		local d = math.min(1, nt / tweenInfo.Time)
		local lcf = original:lerp(targetCFrame, easing.outCubic(d))
		weld.C0 = att_a.Parent.CFrame:toObjectSpace(lcf)
	end)

	return weld, info
end
function axisUtil.snapAttachAttachments(a, aName, b, bName)
	local att_a, att_b = getAttachments(a, aName, b, bName)

	local info = axisUtil.computeAttachInfo(att_a, att_b)
	local weld = Instance.new("Weld")
	weld.Part0 = att_a.Parent
	weld.Part1 = att_b.Parent
	weld.C0 = info.target
	weld.Parent = a

	return weld
end

-- This function will align the parents of two attachments so that B matches A's CFrame,
-- 	doing so using a weld.
function axisUtil.snapAttach(a, b, attachmentName)
	return axisUtil.snapAttachAttachments(a, attachmentName, b, attachmentName)
end
function axisUtil.smoothAttach(a, b, attachmentName, tweenInfo)
	return axisUtil.smoothAttachAttachments(a, attachmentName, b, attachmentName, tweenInfo)
end

-- Tween model cframe
function axisUtil.tweenModelCFrame(model, info, target)
	if not model.PrimaryPart then
		error("Cannot tween model with no PrimaryPart " .. model:GetFullName())
	end

	local proxy = Instance.new("CFrameValue")
	proxy.Value = model:GetPrimaryPartCFrame()
	proxy.Changed:Connect(function (value)
		model:SetPrimaryPartCFrame(value)
	end)
	proxy.Parent = ReplicatedStorage

	local tween = TweenService:Create(proxy, info, { Value = target })
	tween.Completed:Connect(function ()
		proxy:Destroy()
	end)
	tween:Play()
end

-- return lib
return axisUtil
