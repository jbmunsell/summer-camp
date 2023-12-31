--
--	Jackson Munsell
--	04 Sep 2020
--	interact.client.lua
--
--	Client interact functionality
--

-- env
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local input = env.src.input
local genes = env.src.genes
local interact = genes.interact
local multiswitch = genes.multiswitch

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local inputUtil = require(input.util)
local genesUtil = require(genes.util)
local multiswitchUtil = require(multiswitch.util)

---------------------------------------------------------------------------------------------------
-- Instances and constants
---------------------------------------------------------------------------------------------------

-- instances
local interactPrompt = env.PlayerGui:WaitForChild("InteractPrompt")

-- constants
local SpritesheetDims = Vector2.new(4, 4)
local SpritesheetScale = 128

-- caches
local holdPackages = {}
local pollingPackages = {}

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Render input prompt
local function renderInputPrompt()
	local gamepad = UserInputService.GamepadEnabled
	local touch = not gamepad and UserInputService.TouchEnabled
	interactPrompt.InteractButton.GamepadImage.Visible = gamepad
	interactPrompt.InteractButton.TouchImage.Visible = touch
	interactPrompt.InteractButton.KeyLabel.Visible = not touch and not gamepad
end

-- Update polling list
local pollingDistance = math.pow(env.config.interact.PollingDistance.Value, 2)
local function updatePollingList()
	-- Reset packages
	pollingPackages = {}

	-- data
	local root = axisUtil.getLocalHumanoidRootPart()
	if not root then return end
	local playerPos = root.Position
	local function getDistance(package)
		return axisUtil.squareMagnitude(package.hold.WorldPosition - playerPos)
	end

	-- Build new list
	for _, package in pairs(holdPackages) do
		if package.isInteractable:getValue() and getDistance(package) <= pollingDistance then
			table.insert(pollingPackages, package)
		end
	end
end

-- Get best hold
local function getBestHold()
	local head = env.LocalPlayer.Character:FindFirstChild("Head")
	local faceFront = head and head:FindFirstChild("FaceFrontAttachment")
	if not faceFront then return end
	local charpos = faceFront.WorldPosition

	local bestPackage = nil
	local bestModifier = -math.huge
	local bestHoldPosition = nil
	local cameraCFrame = workspace.CurrentCamera.CFrame
	for _, package in pairs(pollingPackages) do
		local hold = package.hold
		if package.isInteractable:getValue() then
			local holdPosition = hold.WorldPosition
			local distanceFromCharacter = (charpos - holdPosition).magnitude
			local threshold = package.threshold
			if distanceFromCharacter <= threshold then
				local offset = holdPosition - cameraCFrame.p
				local dot = offset.unit:Dot(cameraCFrame.LookVector)
				if dot > 0 then
					local dmod = (1 - distanceFromCharacter / threshold) * 0.5 + dot * 0.5
					if dmod > bestModifier then
						bestModifier = dmod
						bestPackage = package
						bestHoldPosition = holdPosition
					end
				end
			end
		end
	end
	if not bestPackage then return end

	local params = inputUtil.getToolRaycastParams()
	local result = workspace:Raycast(charpos, (bestHoldPosition - charpos), params)
	local instance = result and result.Instance
	if not instance
	or instance == bestPackage.instance
	or instance:IsDescendantOf(bestPackage.instance)
	then
		return bestPackage.hold
	end
end

-- Get interactable from hold
-- 	This function reads upward the instance hierarchy until it finds the ancestor that 
-- 	has the interactable tag
local function getEnabledInteractableFromHold(hold)
	for _, package in pairs(holdPackages) do
		if package.hold == hold and package.isInteractable:getValue() then return package.instance end
	end
end

-- Update interact prompt
local function updateInteractPrompt(hold, timer)
	-- Get config
	local instance = hold and getEnabledInteractableFromHold(hold)
	local config = (instance and instance.config.interact)

	-- Set enabled and adornee
	interactPrompt.Enabled = (hold and true or false)
	interactPrompt.Adornee = hold

	if not instance then return end

	-- Pull proper image from spritesheet
	local totalCells = (SpritesheetDims.X * SpritesheetDims.Y)
	local timerFraction = ((hold and timer) and 1 - (timer / config.duration.Value) or 0)
	local i = math.max(0, math.min(totalCells - 1, math.floor(timerFraction * totalCells)))

	-- Hide if we haven't started
	interactPrompt.Dial.Visible = (timerFraction > 0)

	-- Set image rect offset for cell
	local cell = Vector2.new(i % SpritesheetDims.X, math.floor(i / SpritesheetDims.X))
	interactPrompt.Dial.ImageRectOffset = cell * SpritesheetScale
end

-- Trigger interact
local function triggerInteract(hold)
	local interactable = getEnabledInteractableFromHold(hold)
	interact.interface.ClientInteracted:Fire(interactable)
	interact.net.ClientInteracted:FireServer(interactable)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Render prompt when gamepad connection changes
rx.Observable.from(UserInputService.GamepadConnected)
	:merge(rx.Observable.from(UserInputService.GamepadDisconnected))
	:startWith(0)
	:subscribe(renderInputPrompt)

-- Init gene
local interactStream = genesUtil.initGene(interact)

-- Get interactable stream
local function getInteractableSubject(instance)
	local ancestry = rx.Observable.fromInstanceEvent(instance, "AncestryChanged")
		:startWith(0)
		:map(function () return instance:IsDescendantOf(workspace) end)
	local switches = multiswitchUtil.observeSwitches(instance, "interact")
		:startWith(0)
		:map(dart.constant(nil))
		:map(dart.bind(multiswitchUtil.all, instance, "interact"))
	return ancestry:combineLatest(switches, dart.boolAnd)
		:multicast(rx.BehaviorSubject.new())
end

-- Poll all interactables at 2hz
rx.Observable.interval(0.5):subscribe(updatePollingList)

-- Maintain hold packages cache list
spawn(function ()
	local totalTracker = ReplicatedStorage.debug.data.TotalInteractables
	local pollingTracker = ReplicatedStorage.debug.data.PollingInteractables
	while wait(1) do
		totalTracker.Value = #holdPackages
		pollingTracker.Value = #pollingPackages
	end
end)
local function placeAttachmentInPart(part)
	local att = Instance.new("Attachment", part)
	att.Name = "InteractAttachment"
	return att
end
interactStream:subscribe(function (instance)
	local inserted
	local stream
	local function insert(hold)
		-- Connect to its interactable stream
		if not inserted then
			stream = getInteractableSubject(instance)
		end

		-- Set and insert
		inserted = true
		table.insert(holdPackages, { instance = instance, hold = hold, isInteractable = stream,
			threshold = instance.config.interact.distanceThreshold.Value })
	end
	for _, d in pairs(instance:GetDescendants()) do
		if d.Name == "InteractAttachment" then
			insert(d)
		end
	end
	if not inserted then
		if instance:IsA("Model") then
			if instance.PrimaryPart then
				insert(placeAttachmentInPart(instance.PrimaryPart))
			else
				warn("Interactable model has no PrimaryPart or interact attachments: " .. instance:GetFullName())
			end
		elseif instance:IsA("BasePart") then
			insert(placeAttachmentInPart(instance))
		end
	end
end)
local function cull(list, instance)
	for i = #list, 1, -1 do
		if list[i].instance == instance then
			table.remove(list, i)
		end
	end
end
rx.Observable.from(CollectionService:GetInstanceRemovedSignal(require(interact.data).instanceTag))
	:subscribe(function (instance)
		cull(holdPackages, instance)
		cull(pollingPackages, instance)
	end)

-- 	Merge E up/down to true/false stream
-- 	with the (mouse is down inside the button) stream
-- local function createButtonInputStream(event, value)
-- 	return rx.Observable.from(event)
-- 		:filter(mouseFilter)
-- 		:map(dart.constant(value))
-- end
local keyStateStream = rx.Observable.from(Enum.KeyCode.E)
	:merge(rx.Observable.from(Enum.KeyCode.ButtonX))
	:map(dart.equals(Enum.UserInputState.Begin))
	:multicast(rx.BehaviorSubject.new(false))
-- local buttonDownStream = createButtonInputStream(interactPrompt.InteractButton.InputBegan, true)
-- local buttonUpStream = createButtonInputStream(interactPrompt.InteractButton.InputEnded, false)
-- local buttonStateStream = buttonDownStream:merge(buttonUpStream)
-- 	:startWith(false)
local interactInputDown = keyStateStream
	-- :combineLatest(buttonStateStream, dart.boolOr)
	:multicast(rx.BehaviorSubject.new(false))

-- Connect to heartbeat to sense interactables and place prompt
local hotInteractor = rx.Observable.heartbeat()
	:reject(function () return interactInputDown:getValue() end)
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
		local interactable = getEnabledInteractableFromHold(hot)
		return hot and interactable and interactable.config.interact.duration.Value
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
	:merge(rx.Observable.from(interactPrompt.InteractButton.Activated))
	:mapToLatest(hotInteractor)
	:subscribe(triggerInteract)
