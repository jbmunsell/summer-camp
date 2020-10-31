--
--	Jackson Munsell
--	04 Sep 2020
--	interact.client.lua
--
--	Client interact functionality
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local input = env.src.input
local genes = env.src.genes
local interact = genes.interact

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local inputUtil = require(input.util)
local genesUtil = require(genes.util)
local interactUtil = require(interact.util)

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
local function getHoldDistance(characterAttachment, hold)
	return (characterAttachment.WorldPosition - getHoldPosition(hold)).magnitude
end
local function getDistanceModifier(characterAttachment, hold)
	local offset = getHoldOffset(hold)
	local cameraLook = workspace.CurrentCamera.CFrame.LookVector
	local dot = offset.unit:Dot(cameraLook)
	if dot <= 0 then
		return math.huge
	end
	return getHoldDistance(characterAttachment, hold) * (1 - dot)
end

-- Is in range
local function isInRange(characterAttachment, instance, hold)
	local config = genesUtil.getConfig(instance).interact
	return getHoldDistance(characterAttachment, hold) <= config.distanceThreshold
end
local function isInSight(characterAttachment, instance, hold)
	local charpos = characterAttachment.WorldPosition
	local params = inputUtil.getBasicRaycastParams()
	local pos = (hold:IsA("Attachment") and hold.WorldPosition or hold.Position)
	local result = workspace:Raycast(charpos, (pos - charpos), params)

	return not result
	or not result.Instance
	or hold == result.Instance
	or hold.Parent == result.Instance
	or result.Instance:IsDescendantOf(instance)
end

-- Get best hold
local function getBestHold()
	local head = env.LocalPlayer.Character:FindFirstChild("Head")
	local attachment = head and head:FindFirstChild("FaceFrontAttachment")
	if not attachment then return end

	local closestInstance, closestHold
	local closestModifier = math.huge
	genesUtil.getInstances(interact)
		:filter(isInteractable)
		:foreach(function (instance)
			getInteractionHolds(instance)
				:filter(dart.bind(isInRange, attachment, instance))
				:foreach(function (hold)
					local dmod = getDistanceModifier(attachment, hold)
					if dmod < closestModifier then
						closestModifier = dmod
						closestInstance = instance
						closestHold = hold
					end
				end)
		end)

	return closestHold and isInSight(attachment, closestInstance, closestHold) and closestHold or nil
end

-- Get interactable from hold
-- 	This function reads upward the instance hierarchy until it finds the ancestor that 
-- 	has the interactable tag
local function getInteractableFromHold(hold)
	if hold == game then
		return nil
	end
	return genesUtil.hasGene(hold, interact) and hold or getInteractableFromHold(hold.Parent)
end

-- Update interact prompt
local function updateInteractPrompt(hold, timer)
	-- Get config
	local config = (hold and genesUtil.getConfig(getInteractableFromHold(hold)).interact)

	-- Set enabled and adornee
	interactPrompt.Enabled = (hold and true or false)
	interactPrompt.Adornee = hold

	-- Pull proper image from spritesheet
	local totalCells = (SpritesheetDims.X * SpritesheetDims.Y)
	local timerFraction = ((hold and timer) and 1 - (timer / config.duration) or 0)
	local i = math.max(0, math.min(totalCells - 1, math.floor(timerFraction * totalCells)))

	-- Hide if we haven't started
	interactPrompt.Dial.Visible = (timerFraction > 0)

	-- Set image rect offset for cell
	local cell = Vector2.new(i % SpritesheetDims.X, math.floor(i / SpritesheetDims.X))
	interactPrompt.Dial.ImageRectOffset = cell * SpritesheetScale
end

-- Trigger interact
local function triggerInteract(hold)
	local interactable = getInteractableFromHold(hold)
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
local interactInputDown = keyStateStream
	:combineLatest(buttonStateStream, dart.boolOr)
	:multicast(rx.BehaviorSubject.new(false))

-- Connect to heartbeat to sense interactables and place prompt
local hotInteractor = rx.Observable.heartbeat()
	:map(getBestHold)
	:distinctUntilChanged()
	:multicast(rx.BehaviorSubject.new())

-- Actually advancing
local advancingInteract = interactInputDown
	:withLatestFrom(hotInteractor)
	:map(dart.boolAnd)
	:multicast(rx.BehaviorSubject.new(false))

-- Timer state encapsulation
local interactionTimer = rx.BehaviorSubject.new(nil)

-- Reset timer when hot changes OR we let go
hotInteractor
	:merge(advancingInteract:reject())
	:map(function ()
		local hot = hotInteractor:getValue()
		return hot and genesUtil.getConfig(getInteractableFromHold(hot)).interact.duration
	end)
	:multicast(interactionTimer)

-- Decrease timer on heartbeat if we are actually advancing
rx.Observable.heartbeat()
	:filter(function ()
		return advancingInteract:getValue()
	end)
	:map(function (dt)
		local timer = interactionTimer:getValue()
		return timer and timer - dt
	end)
	:multicast(interactionTimer)

-- Update gui on timer changed
interactionTimer
	:map(function (timer)
		return hotInteractor:getValue(), timer
	end)
	:subscribe(updateInteractPrompt)

-- Whenever the timer is less than zero and it used to be greater than zero, trigger interaction
interactionTimer
	:map(function (x) return x and x < 0 end)
	:distinctUntilChanged()
	:filter()
	:mapToLatest(hotInteractor)
	:subscribe(triggerInteract)
