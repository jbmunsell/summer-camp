--
--	Jackson Munsell
--	12 Sep 2020
--	dodgeballBall.lua
--
--	Dodgeball ball server component
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

-- modules
local rx = require(env.axis.lib.rx)
local dart = require(env.axis.lib.dart)
local class = require(env.axis.lib.class)

-- instances
local BallVerticalForce = env.res.activities.physics.DodgeballVerticalForce
local ThrowRemote = env.net.activities.dodgeball.ThrowRequested

-- Constants
local ThrowVelocity = 100

-- class
local dodgeballBall = class.new()

-- Object maintenance
function dodgeballBall.init(self, dodgeballTool, projectileFolder)
	-- Hold folder reference
	self.refs = {
		projectileFolder = projectileFolder,
		tool = dodgeballTool,
	}

	-- State subjects
	self.state = {
		thrower = rx.BehaviorSubject.new(),
		hot     = rx.BehaviorSubject.new(),
	}
	self:resetState()

	-- Events
	self.events = {
		streamTerminator = Instance.new("BindableEvent"),
	}

	-- Instances
	self.instances = {
		partSubject = rx.BehaviorSubject.new(),
		toolSubject = rx.BehaviorSubject.new(),
	}
	self:resetInstances()

	-- Event streams
	self.streams = {
		terminator = rx.Observable.from(self.events.streamTerminator),
	}
	local function bind(f)
		return dart.bind(f, self)
	end
	local function connect(stream)
		return stream:takeUntil(self.streams.terminator)
	end

	-- When our part gets touched
	local partTouchedStream = connect(self.instances.partSubject
		:flatMap(function (part)
			return rx.Observable.from(part.Touched)
				:filter(function (hit)
					local thrower = self.state.thrower:getValue()
					return not part.Parent:IsA("Tool")
					and not (thrower and hit:IsDescendantOf(thrower.Character))
				end)
		end))

	-- Touched while cold and hot
	self.streams.hotTouched, self.streams.coldTouched = partTouchedStream
		:partition(function ()
			return self.state.hot:getValue()
		end)

	-- Throw requested by ball holder
	self.streams.throwRequested = connect(rx.Observable.from(ThrowRemote.OnServerEvent))
		:filter(function (client)
			return client.Character
			and self:getPart():IsDescendantOf(client.Character)
		end)

	-- Subscriptions!
	-- Recreate instances when one of them is destroyed
	-- 	(this could happen when a ball part goes beyond map or player leaves while holding)
	local function fromRemoved(subject)
		return subject:flatMap(function (instance)
			return rx.Observable.from(instance.AncestryChanged)
				:filter(function ()
					return not instance:IsDescendantOf(game)
				end)
		end)
	end
	fromRemoved(self.instances.partSubject)
		:merge(fromRemoved(self.instances.toolSubject))
		:subscribe(bind(self.resetInstances))

	-- Create vertical force when necessary
	self.state.hot:subscribe(bind(self.setVerticalForceEnabled))

	-- Throw when they wanna throw
	self.streams.throwRequested:subscribe(bind(self.throwFromPlayer))
end
function dodgeballBall.destroy(self)
	-- Terminate all streams
	self.events.streamTerminator:Fire()

	-- Destroy instances
	for _, instance in pairs(self.instances) do
		instance:Destroy()
	end
end

-- Getters
function dodgeballBall.getPart(self)
	return self.instances.partSubject:getValue()
end
function dodgeballBall.getTool(self)
	return self.instances.toolSubject:getValue()
end

-- Resetters
function dodgeballBall.resetState(self)
	self.state.hot:push(false)
	self.state.thrower:push(nil)
end
function dodgeballBall.resetInstances(self)
	for _, instance in pairs({self:getPart(), self:getTool()}) do
		if instance:IsDescendantOf(game) then
			instance:Destroy()
		end
	end
	local part = env.res.activities.models.Dodgeball:Clone()
	local tool = self.refs.tool:Clone()
	part.Parent = env.ReplicatedStorage
	tool.Parent = env.ReplicatedStorage
	self.instances.partSubject:push(part)
	self.instances.toolSubject:push(tool)
	self:transformToProjectile()
end

-- Transform
function dodgeballBall.transformToProjectile(self)
	local part, tool = self:getPart(), self:getTool()
	if tool.Parent:FindFirstChild("Humanoid") then
		tool.Parent.Humanoid:UnequipTools()
	end
	part.Parent = self.refs.projectileFolder
	part.Name = "Dodgeball"
	tool.Parent = env.ReplicatedStorage
end
function dodgeballBall.transformToTool(self, humanoid)
	local part, tool = self:getPart(), self:getTool()
	part.Name = "Handle"
	part.Parent = tool
	tool.Parent = humanoid.Parent
end

-- Spawn at part
function dodgeballBall.spawnAtPart(self, spawnPart)
	-- Reset state and hide tool in replicated storage
	self:resetInstances()

	-- Place part
	local part = self:getPart()
	part.CFrame = spawnPart.CFrame
end

-- Equip player
function dodgeballBall.equipPlayer(self, player)
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if humanoid then
		self:transformToTool(humanoid)
		-- humanoid:EquipTool(self:getTool())
	end
end
function dodgeballBall.stripFromPlayer(self, player)
	if player.Character and self:getPart():IsDescendantOf(player.Character) then
		self:transformToProjectile()
	end
end

-- Throw from player
function dodgeballBall.throwFromPlayer(self, player, target)
	self.state.hot:push(true)
	self.state.thrower:push(player)
	self:transformToProjectile()

	local part = self:getPart()
	part.Velocity = (target - part.Position).unit * ThrowVelocity
end

-- Vertical force
-- 	(this serves to make a more accurate throw so that the ball isn't totally sunk by gravity)
function dodgeballBall.setVerticalForceEnabled(self, enabled)
	local part = self:getPart()
	local force = part:FindFirstChild(BallVerticalForce.Name)
	local hasForce = (force and true or false)
	if hasForce ~= enabled then
		if enabled then
			BallVerticalForce:Clone().Parent = part
		else
			force:Destroy()
		end
	end
end

-- Brick (turns off hot and removes reference to thrower)
function dodgeballBall.brick(self)
	self.state.hot:push(false)
	self.state.thrower:push(nil)
end

-- return class
return dodgeballBall
