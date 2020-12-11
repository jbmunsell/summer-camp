--
--	Jackson Munsell
--	25 Nov 2020
--	jobSelection.client.lua
--
--	Job selection gui client driver
--

-- env
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local fx = require(axis.lib.fx)
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local glib = require(axis.lib.glib)
local axisUtil = require(axis.lib.axisUtil)
local soundUtil = require(axis.lib.soundUtil)
local collection = require(axis.lib.collection)
local Spring = require(axis.classes.Spring)
local genesUtil = require(genes.util)
local inputStreams = require(env.src.input.streams)
local interactUtil = require(genes.interact.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local state = {
	outfitsEnabled     = rx.BehaviorSubject.new(true),
	avatarScale        = rx.BehaviorSubject.new(env.config.character.scaleDefault.Value),
	selectedIndex      = rx.BehaviorSubject.new(1),
	isPrimarySelection = rx.BehaviorSubject.new(true),
}

local jobSelection = env.PlayerGui:WaitForChild("JobSelection")

local blur = Lighting.Blur

local instances = {
	closeButton  = jobSelection:FindFirstChild("CloseButton", true),
	outfitButton = jobSelection:FindFirstChild("OutfitButton", true),
	scaleSlider  = jobSelection:FindFirstChild("ScaleSlider", true),
	jobContainer = jobSelection:FindFirstChild("JobContainer", true),
}

local buttonTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local focusTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local jobListing = {
	env.res.jobs.artist,
	env.res.jobs.camper,
	env.res.jobs.teamLeader,
	env.res.jobs.cheerleader,
	env.res.jobs.securityGuard,
	env.res.jobs.janitor,
}

-- Create a dummy in workspace that we can use play with descriptions and copy over results
if not env.LocalPlayer:HasAppearanceLoaded() then
	env.LocalPlayer.CharacterAppearanceLoaded:wait()
end

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function getJobFrame(job)
	for _, frame in pairs(instances.jobContainer:GetChildren()) do
		if frame:IsA("GuiObject") and frame:FindFirstChild("job") and frame.job.Value == job then
			return frame
		end
	end
end

local function renderEnabled(enabled)
	blur.state.propertySwitcher.propertySet.Value = (enabled and "jobSelection" or "gameplay")
end

local function renderSelectedIndex(index)
	-- Tween scale of all things and set appropriate gradients
	for i, job in pairs(jobListing) do
		-- Scale
		local frame = getJobFrame(job)
		local goal = frame.properties[i == index and "selectedYScale" or "unselectedYScale"].Value
		TweenService:Create(frame, focusTweenInfo, { Size = UDim2.new(1, 0, goal, 0) }):Play()
	end
end

local function renderAvatarScale(scale)
	-- Place button and adjust bar fill
	local scaleMin = env.config.character.scaleMin.Value
	local scaleMax = env.config.character.scaleMax.Value
	local slider = instances.scaleSlider
	local d = (scale - scaleMin) / (scaleMax - scaleMin)
	slider.Fill.Size = UDim2.new(d, 0, 1, 0)
	slider.Slider.Position = UDim2.new(d, 0, 0.5, 0)
end

local function renderOutfitsEnabled(enabled)
	-- Change button rendering
	local fill = instances.outfitButton.Fill
	fill.BackgroundColor3 = fill.properties[enabled and "filledColor" or "unfilledColor"].Value

	-- TODO: Update all avatars to wear appropriate clothes
end

-- Render avatars very simply
local function renderAvatars()
	local scale = state.avatarScale:getValue()
	for _, job in pairs(jobListing) do
		local frame = getJobFrame(job)
		local character = frame.WorldModel.Character
		local playerCharacter = env.LocalPlayer.Character
		local outfit = state.outfitsEnabled:getValue()
		local assets = job.config.job:FindFirstChild("humanoidDescriptionAssets")
		character.ScaleEffect.Value = scale

		local fullShadowY = frame.Shadow.properties.maxYScale.Value
		local anchorY = 0.4
		frame.Shadow.Position = UDim2.new(frame.Shadow.Position.X.Scale, 0,
			anchorY + (fullShadowY - anchorY) * scale, 0)

		local function tryClothing(piece)
			local jobPiece = assets and assets:FindFirstChild(piece)
			if jobPiece and jobPiece:IsA("Folder") then
				jobPiece = jobPiece:GetChildren()[1]
			end
			if outfit and jobPiece then
				character[piece][piece .. "Template"] = jobPiece[piece .. "Template"]
			else
				character[piece][piece .. "Template"] = playerCharacter[piece][piece .. "Template"]
			end
		end
		tryClothing("Shirt")
		tryClothing("Pants")

		wait()
		character:SetPrimaryPartCFrame(frame.rootCFrame.Value)
	end
end

local function renderJobFrame(job)
	-- State
	local frame = getJobFrame(job)
	local button = frame.Perks.ActionButton
	local isLocked = not collection.getValue(env.LocalPlayer.state.jobs.unlocked, job)
	local isSelected = table.find(jobListing, job) == state.selectedIndex:getValue()

	-- Render according to locked first priority, selected second priority,
	-- 	and (unlocked and unselected) third priority
	local gradientName
	local buttonHeight
	local buttonColor
	local lockVisible = false
	local ambientColor
	if isLocked then
		gradientName = "Locked"
		buttonHeight = button.properties.fullHeight.Value
		buttonColor = button.properties.buyColor.Value
		-- lockVisible = true
		ambientColor = frame.properties.ambientLocked.Value
	else
		buttonColor = button.properties.selectColor.Value
		lockVisible = false
		ambientColor = frame.properties.ambientUnlocked.Value
		button.Text = "Select"
		if isSelected then
			gradientName = "Selected"
			buttonHeight = button.properties.fullHeight.Value
		else
			gradientName = "Unselected"
			buttonHeight = button.properties.emptyHeight.Value
		end
	end

	-- Set lock visible
	frame.Lock.Visible = lockVisible
	frame.Ambient = ambientColor

	-- Tween button height
	TweenService:Create(button, buttonTweenInfo, { Size = UDim2.new(1, 0, buttonHeight, 0) }):Play()
	button.BackgroundColor3 = buttonColor

	-- Render gradients
	local function addGradient(instance, gradientType)
		instance.Gradient:Destroy()
		local gradient = jobSelection.seeds.gradients[gradientName .. gradientType]:Clone()
		gradient.Parent = instance
		gradient.Name = "Gradient"
	end
	addGradient(frame.Background.Border, "Border")
	addGradient(frame.Background.Border.Fill, "Fill")
end

local function createJobFrame(job, i)
	-- Create frame
	local jobConfig = job.config.job
	local frame = jobSelection.seeds.JobFrame:Clone()
	local pointer = Instance.new("ObjectValue", frame)
	pointer.Name = "job"
	pointer.Value = job
	frame.LayoutOrder = i
	frame.JobName.Text = jobConfig.displayName.Value

	-- Character
	local rootCFrame = Instance.new("CFrameValue", frame)
	rootCFrame.Value = frame.WorldModel.Character:GetPrimaryPartCFrame()
	rootCFrame.Name = "rootCFrame"
	frame.WorldModel.Character:Destroy()
	local character = env.LocalPlayer.Character
	character:WaitForChild("Humanoid")
	character.Archivable = true
	for _, d in pairs(character:GetDescendants()) do
		d.Archivable = true
	end
	local copy = character:Clone()
	copy.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	fx.new("ScaleEffect", copy)
	copy:SetPrimaryPartCFrame(rootCFrame.Value)
	copy.Parent = frame.WorldModel
	copy.Name = "Character"
	for _, child in pairs(copy:GetChildren()) do
		if child.Name == "Head" then
			Instance.new("BoolValue", child).Name = "noScale"
		elseif child:IsA("Accessory") then
			local weld = child:FindFirstChild("AccessoryWeld", true)
			if weld and weld.Part1 == copy.Head then
				Instance.new("BoolValue", child.Handle).Name = "noScale"
			end
		end
	end

	-- Show and parent
	frame.Visible = true
	frame.Parent = instances.jobContainer

	-- Create perks
	for _, child in pairs(frame.Perks:GetChildren()) do
		if child:IsA("GuiObject") and child.Name ~= "ActionButton" then
			child:Destroy()
		end
	end
	for _, perk in pairs(jobConfig.displayedPerks:GetChildren()) do
		local perkFrame = jobSelection.seeds.Perk:Clone()
		perkFrame.TextLabel.Text = perk.Name
		perkFrame.Visible = true
		perkFrame.Parent = frame.Perks
	end

	-- Set price text if locked
	local actionButton = frame.Perks.ActionButton
	local unlocked = env.LocalPlayer.state.jobs.unlocked
	local function isUnlocked()
		return collection.getValue(unlocked, job)
	end
	if not isUnlocked() and jobConfig.gamepassId.Value ~= 0 then
		spawn(function ()
			local info = MarketplaceService:GetProductInfo(jobConfig.gamepassId.Value, Enum.InfoType.GamePass)
			actionButton.Text = string.format("R$%s", axisUtil.commify(info.PriceInRobux))
		end)
	end

	-- Subscribe to job business
	-- When job unlocked is changed OR selected index is changed, render frame contents again
	local jobUnlockedStream = collection.observeChanged(unlocked)
		:map(isUnlocked)
		:map(dart.boolify)
		:filter()
		:first()
	state.selectedIndex
		:flatMap(function ()
			return rx.Observable.from(jobListing)
		end)
		:merge(jobUnlockedStream)
		:startWith(0)
		:subscribe(dart.bind(renderJobFrame, job))

	-- Action button clicked
	rx.Observable.fromInstanceEvent(actionButton, "Activated"):subscribe(function ()
		if isUnlocked() then
			-- Send request to server and close gui
			local outfitsEnabled = state.outfitsEnabled:getValue()
			local scale = state.avatarScale:getValue()
			genes.player.jobs.net.JobChangeRequested:FireServer(job, outfitsEnabled, scale)
			jobSelection.Enabled = false
			state.isPrimarySelection:push(false)
		else
			-- Prompt gamepass purchase
			MarketplaceService:PromptGamePassPurchase(env.LocalPlayer, jobConfig.gamepassId.Value)
		end
	end)

	-- Hide button if it's supposed to be invisible
	rx.Observable.fromProperty(actionButton, "Size"):map(function ()
		return actionButton.Size.Y.Scale > 0
	end):subscribe(function (v)
		actionButton.Visible = v
	end)

	-- Frame activated, set as selected
	rx.Observable.fromInstanceEvent(frame.Background, "Activated"):subscribe(function ()
		state.selectedIndex:push(table.find(jobListing, job))
	end)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

--------------------------------------------------------
-- Prep work
-- The dummy job container is a padding technique to allow pseudo-negative scrolling
genesUtil.waitForGene(Lighting.Blur, genes.propertySwitcher)
Lighting.Blur.Size = 0
Lighting.Blur.state.propertySwitcher.propertySet.Value = "gameplay"
Lighting.Blur.Enabled = true
genesUtil.waitForGene(env.LocalPlayer, genes.player.jobs)
glib.clearLayoutContents(instances.jobContainer)
jobSelection.seeds.DummyJobFrame:Clone().Parent = instances.jobContainer
instances.jobContainer.DummyJobFrame.Visible = true
for i, job in pairs(jobListing) do
	createJobFrame(job, i)
end

--------------------------------------------------------
-- State subscriptions
rx.Observable.fromProperty(jobSelection, "Enabled"):subscribe(renderEnabled)
state.selectedIndex:subscribe(renderSelectedIndex)
state.avatarScale:subscribe(renderAvatarScale)
state.outfitsEnabled:subscribe(renderOutfitsEnabled)
state.isPrimarySelection:subscribe(function (isPrimary)
	instances.closeButton.Visible = not isPrimary
end)

-- Create a position spring for scrolling frame
local positionSpring = Spring.new(0, 0)
positionSpring:setSpeed(10)
positionSpring:setDamping(1)
rx.Observable.fromProperty(jobSelection, "Enabled")
	:switchMap(function (enabled)
		return enabled and rx.Observable.heartbeat() or rx.Observable.never()
	end)
	:subscribe(function (dt)
		local jobFrame = getJobFrame(jobListing[state.selectedIndex:getValue()])
		local jobContainer = instances.jobContainer
		local targetCenter = (jobContainer.AbsoluteSize.X * 0.5)
		local framePosition = jobFrame.AbsolutePosition
		local containerPosition = jobContainer.AbsolutePosition
		local jobHalf = jobFrame.AbsoluteSize.X * 0.5
		local jobOffsetFromCanvas = (framePosition.X - containerPosition.X + jobContainer.CanvasPosition.X)
		positionSpring:setTarget(jobOffsetFromCanvas - targetCenter + jobHalf)
		positionSpring:update(dt)
		jobContainer.CanvasPosition = Vector2.new(positionSpring:getPosition(), 0)
	end)

--------------------------------------------------------
-- Set state values according to other things
rx.Observable.fromInstanceEvent(instances.outfitButton, "Activated"):subscribe(function ()
	state.outfitsEnabled:push(not state.outfitsEnabled:getValue())
end)
rx.Observable.fromInstanceEvent(instances.closeButton, "Activated"):subscribe(function ()
	jobSelection.Enabled = false
end)

-- Slider adjustments
local function getScaleFromMousePosition()
	local characterConfig = env.config.character
	local mousePosition = UserInputService:GetMouseLocation()
	local sliderPosition = instances.scaleSlider.AbsolutePosition
	local sliderSize = instances.scaleSlider.AbsoluteSize
	local d = math.min(1, math.max(0, (mousePosition.X - sliderPosition.X) / sliderSize.X))
	return characterConfig.scaleMin.Value * (1 - d) +characterConfig.scaleMax.Value * d
end
rx.Observable.fromInstanceEvent(instances.scaleSlider.Slider, "InputBegan")
	:filter(function (input)
		return input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1
	end)
	:map(dart.constant(true))
	:merge(inputStreams.activationEnded:map(dart.constant(false)))
	:switchMap(function (holding)
		return holding and rx.Observable.heartbeat() or rx.Observable.never()
	end)
	:map(getScaleFromMousePosition)
	:multicast(state.avatarScale)

-- Swipe to change index
rx.Observable.from(UserInputService.TouchSwipe)
	:reject(dart.select(2))
	:filter(function () return jobSelection.Enabled end)
	:map(function (direction)
		if direction == Enum.SwipeDirection.Left then
			return -1
		elseif direction == Enum.SwipeDirection.Right then
			return 1
		end
	end)
	:filter()
	:subscribe(function (shift)
		state.selectedIndex:push(state.selectedIndex:getValue() + shift)
	end)

-- Update avatars on scale changed
state.avatarScale
	-- :throttle(0.1)
	:merge(state.outfitsEnabled)
	:subscribe(renderAvatars)

-- Play special sound on job unlocked
-- 	player, gamePassId, wasPurchased
rx.Observable.from(MarketplaceService.PromptGamePassPurchaseFinished)
	:filter(dart.equals(env.LocalPlayer))
	:filter(dart.select(3))
	:subscribe(dart.bind(soundUtil.playSoundGlobal, env.res.audio.sounds.JobUnlocked))

-- Open gui on job giver interact
interactUtil.getInteractStream(genes.jobGiver):subscribe(function (instance)
	local job = instance.config.jobGiver.job.Value
	state.selectedIndex:push(table.find(jobListing, job))
	jobSelection.Enabled = true
end)
