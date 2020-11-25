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
local patchUtil = require(genes.patch.util)
local pickupUtil = require(genes.pickup.util)
local inputUtil = require(env.src.input.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local preview = rx.BehaviorSubject.new()

local gui = env.PlayerGui:WaitForChild("Core").Container.PatchDisplay
do
	local initText = string.format("%s to attach to your backpack! This feature is an "
		.. " experiment, so patches don't save yet. Tell us what you think on the group wall!",
		(UserInputService.TouchEnabled and "Tap" or "Click"))
	gui.Frame.Label.Text = initText
end

genesUtil.waitForGene(env.LocalPlayer, genes.player.characterBackpack)
local localBackpack
while not localBackpack do
	wait()
	localBackpack = env.LocalPlayer.state.characterBackpack.instance.Value
end

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function renderPreview()
	local result = inputUtil.raycastMouse()
	local instance = preview:getValue()
	if result and result.Instance and result.Instance:IsDescendantOf(localBackpack) then
		instance.CFrame = CFrame.new(result.Position, result.Position + result.Normal)
		instance.Parent = workspace
	else
		instance.Parent = ReplicatedStorage
	end
end

local function packageRaycastResult(result)
	return {
		Instance = result.Instance,
		Normal = result.Normal,
		Position = result.Position,
	}
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
	local result = inputUtil.raycastMouse()
	if result and result.Instance:IsDescendantOf(localBackpack) then
		genes.patch.net.AttachRequested:FireServer(instance, packageRaycastResult(result))
	end
end)
