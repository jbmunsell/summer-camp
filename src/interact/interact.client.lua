--
--	Jackson Munsell
--	04 Sep 2020
--	interact.client.lua
--
--	Client interact functionality
--

-- env
local CollectionService = game:GetService("CollectionService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local input = env.src.input
local objects = env.src.objects
local interact = env.src.interact

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local axisUtil = require(axis.lib.axisUtil)
local inputUtil = require(input.util)
local objectsUtil = require(objects.util)
local interactUtil = require(interact.util)
local interactConfig = require(interact.config)

---------------------------------------------------------------------------------------------------
-- Instances and constants
---------------------------------------------------------------------------------------------------

-- instances
local interactPrompt = env.PlayerGui:WaitForChild("InteractPrompt")

-- constants
local SpritesheetDims = Vector2.new(4, 4)
local SpritesheetScale = 128

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Mouse event filtering
local function mouseFilter(inputObject, processed)
	return not processed and inputObject.UserInputType == Enum.UserInputType.MouseButton1
end

-- Is interactable
local function isInteractable(instance)
	return instance:IsDescendantOf(workspace)
	and    instance.state.interact.enabledServer.Value
	and    instance.state.interact.enabledClient.Value
	and not interactUtil.isLocked(instance)
end

-- Get interaction holds
-- 	Returns a list of all properly named attachments
-- 	OR the part / PrimaryPart if no such attachments exist.
local function getInteractionHolds(instance)
	local atts = tableau.from(instance:GetDescendants())
		:filter(dart.isNamed("InteractionPromptAdornee"))
	if atts:size() > 0 then
		return atts
	else
		if instance:IsA("BasePart") then
			return tableau.from({ instance })
		elseif instance:IsA("Model") then
			return tableau.from({ instance.PrimaryPart })
		end
	end
end

-- Get distance modifier
local function getHoldPosition(hold)
	return (hold:IsA("Attachment") and hold.WorldPosition or hold.Position)
end
local function getHoldOffset(hold)
	return (getHoldPosition(hold) - workspace.CurrentCamera.CFrame.p)
end
local function getHoldDistance(hold)
	return env.LocalPlayer:DistanceFromCharacter(getHoldPosition(hold))
end
local function getDistanceModifier(hold)
	local offset = getHoldOffset(hold)
	local cameraLook = workspace.CurrentCamera.CFrame.LookVector
	local dot = offset.unit:Dot(cameraLook)
	if dot <= 0 then
		return math.huge
	end
	return getHoldDistance(hold) * (1 - dot)
end

-- Is in range
local function isInRange(hold)
	return getHoldDistance(hold) <= interactConfig.distanceThreshold
end

-- Get best interactor
local function getBestInteractor()
	local params = inputUtil.getBasicRaycastParams()
	local head = env.LocalPlayer.Character:FindFirstChild("Head")
	local attachment = head and head:FindFirstChild("FaceFrontAttachment")
	if not attachment then return end

	local function isInSight(hold)
		local pos = (hold:IsA("Attachment") and hold.WorldPosition or hold.Position)
		local result = workspace:Raycast(attachment.WorldPosition, (pos - attachment.WorldPosition), params)
		local ancestor = result and axisUtil.getTaggedAncestor(result.Instance, interactConfig.instanceTag)
		return not result
		or not result.Instance
		or hold == result.Instance
		or hold.Parent == result.Instance
		or (ancestor and hold:IsDescendantOf(ancestor))
	end

	-- local hold = tableau.fromInstanceTag(interactConfig.instanceTag)
	-- local hold = interactUtil.getInstances()
	local hold = objectsUtil.getObjects(interact)
		:filter(isInteractable)
		:flatMap(getInteractionHolds)
		:filter(isInRange)
		:min(getDistanceModifier)
	return hold and isInSight(hold) and hold or nil
end

-- Get interactable from interactor
-- 	This function reads upward the instance hierarchy until it finds the ancestor that 
-- 	has the interactable tag
local function getInteractableFromInteractor(interactor)
	if interactor == game then
		return nil
	end
	return CollectionService:HasTag(interactor, interactConfig.instanceTag) and interactor
			or getInteractableFromInteractor(interactor.Parent)
end

-- Update interact prompt
local function updateInteractPrompt(interactor, timer)
	-- Set enabled and adornee
	interactPrompt.Enabled = (interactor and true or false)
	interactPrompt.Adornee = interactor

	-- Pull proper image from spritesheet
	local totalCells = (SpritesheetDims.X * SpritesheetDims.Y)
	local timerFraction = 1 - (timer / interactConfig.duration)
	local i = math.max(0, math.min(totalCells - 1, math.floor(timerFraction * totalCells)))

	-- Hide if we haven't started
	interactPrompt.Dial.Visible = (timerFraction > 0)

	-- Set image rect offset for cell
	local cell = Vector2.new(i % SpritesheetDims.X, math.floor(i / SpritesheetDims.X))
	interactPrompt.Dial.ImageRectOffset = cell * SpritesheetScale
end

-- Trigger interact
local function triggerInteract(interactor)
	local interactable = getInteractableFromInteractor(interactor)
	interact.interface.ClientInteracted:Fire(interactable)
	interact.net.ClientInteracted:FireServer(interactable)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- 	Merge E up/down to true/false stream
-- 	with the (mouse is down inside the button) stream
local function createButtonInputStream(event, value)
	return rx.Observable.from(event)
		:filter(mouseFilter)
		:map(dart.constant(value))
end
local keyStateStream = rx.Observable.from(Enum.KeyCode.E)
	:map(dart.equals(Enum.UserInputState.Begin))
	:multicast(rx.BehaviorSubject.new(false))
local buttonDownStream = createButtonInputStream(interactPrompt.InteractButton.InputBegan, true)
local buttonUpStream = createButtonInputStream(interactPrompt.InteractButton.InputEnded, false)
local buttonStateStream = buttonDownStream:merge(buttonUpStream)
	:startWith(false)
local advancingInteractionStateStream = keyStateStream
	:combineLatest(buttonStateStream, dart.boolOr)

-- Connect to heartbeat to sense interactables and place prompt
local hotInteractor = rx.Observable.heartbeat()
	:map(getBestInteractor)
	:distinctUntilChanged()
	:multicast(rx.BehaviorSubject.new())

-- Timer state encapsulation
local interactionTimer = rx.BehaviorSubject.new(interactConfig.duration)

-- Decrease by dt when we have a hot one AND we are triggering interaction with mouse or keys
rx.Observable.heartbeat()
	:combineLatest(hotInteractor, advancingInteractionStateStream, function (dt, hot, advancing)
		return hot and advancing and dt or 0
	end)
	:reject(dart.equals(0))
	:subscribe(function (dt)
		interactionTimer:push(interactionTimer:getValue() - dt)
	end)

-- When we stop advancing OR when the hot interactable changes, reset timer
advancingInteractionStateStream
	:reject()
	:merge(hotInteractor)
	:map(dart.constant(interactConfig.duration))
	:multicast(interactionTimer)

-- Subscriptions
-- 	Whenever the hot interactable or the timer changes, update the gui
hotInteractor
	:combineLatest(interactionTimer, dart.identity)
	:subscribe(updateInteractPrompt)

-- Whenever the timer is less than zero and it used to be greater than zero, trigger interaction
interactionTimer
	:map(function (x) return x < 0 end)
	:distinctUntilChanged()
	:filter()
	:mapToLatest(hotInteractor)
	:subscribe(triggerInteract)
