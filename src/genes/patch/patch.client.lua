--
--	Jackson Munsell
--	24 Nov 2020
--	patch.client.lua
--
--	patch gene client driver
--

-- env
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local pickupUtil = require(genes.pickup.util)
local inputUtil = require(env.src.input.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local raycastParams = RaycastParams.new()
raycastParams.CollisionGroup = "Default"

local preview = rx.BehaviorSubject.new()

local gui = env.PlayerGui:WaitForChild("Core").Container.PatchDisplay
do
	local initText = string.format("%s to attach to your backpack",
		(UserInputService.TouchEnabled and "Tap" or "Click"))
	gui.Frame.Label.Text = initText
end

genesUtil.waitForGene(env.LocalPlayer, genes.player.characterBackpack)
local localBackpackSubject = rx.BehaviorSubject.new()
rx.Observable.from(env.LocalPlayer.state.characterBackpack.instance)
	:multicast(localBackpackSubject)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function renderPreview()
	local result = inputUtil.raycastMouse(raycastParams)
	local previewInstance = preview:getValue()
	local localBackpack = localBackpackSubject:getValue()
	if result and result.Instance and localBackpack and result.Instance:IsDescendantOf(localBackpack) then
		previewInstance.CFrame = CFrame.new(result.Position, result.Position + result.Normal)
			* CFrame.Angles(0, math.pi * 0.5, 0)
		previewInstance.Parent = workspace
	else
		previewInstance.Parent = ReplicatedStorage
	end
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.patch)

-- Create preview according to whether or not we're holding a patch
pickupUtil.getLocalCharacterHoldingStream(genes.patch):subscribe(function (instance)
	local old = preview:getValue()
	if old then old:Destroy() end
	local new = instance and instance:Clone()
	if new then
		new.Anchored = true
		for _, tag in pairs(CollectionService:GetTags(new)) do
			CollectionService:RemoveTag(new, tag)
		end
		CollectionService:AddTag(new, "FXPart")
		new.Parent = ReplicatedStorage
	end
	preview:push(new)
end)

-- Set gui visible according to preview
preview:map(dart.boolify):subscribe(function (p) gui.Visible = p end)

-- Set preview cframe to mouse or touch
preview:switchMap(function (instance)
	return instance
	and rx.Observable.heartbeat()
	or rx.Observable.never()
end):subscribe(renderPreview)

-- Send request on activated
pickupUtil.getActivatedStream(genes.patch):subscribe(function (instance)
	local result = inputUtil.raycastMouse(raycastParams)
	local p = preview:getValue()
	local localBackpack = localBackpackSubject:getValue()
	if p and p:IsDescendantOf(workspace) and
	result and localBackpack and result.Instance:IsDescendantOf(localBackpack) then
		local offset = localBackpack.Handle.CFrame:toObjectSpace(CFrame.new(result.Position, result.Position + result.Normal)
			* CFrame.Angles(0, math.pi * 0.5, 0))
		genes.patch.net.AttachRequested:FireServer(instance, offset)
	end
end)
