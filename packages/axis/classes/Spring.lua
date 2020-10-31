--
--	Jackson Munsell
--	07/20/18
--	Spring.lua
--
--	Spring class
--

-- Consts
local e = 2.718281828459045
local UDimScaleMagnitudeWeight = 50
local UDimOffsetMagnitudeWeight = 1
local TargetReachedMagnitudeThreshold = 0.001

-- local functions
local function multiplyUDim2(udim2, scalar)
	return UDim2.new(
		udim2.X.Scale * scalar, udim2.X.Offset * scalar,
		udim2.Y.Scale * scalar, udim2.Y.Offset * scalar
	)
end
local function getMagnitude(v)
	local t = typeof(v)
	if t == "UDim2" then
		-- SUPER CHEESY udim2 magnitude calculation
		return math.abs(v.X.Scale + v.Y.Scale) * UDimScaleMagnitudeWeight +
			   math.abs(v.X.Offset + v.Y.Offset) * UDimOffsetMagnitudeWeight
	elseif t == "Vector2" or t == "Vector3" then
		return v.magnitude
	elseif t == "number" then
		return math.abs(v)
	else
		error("Unable to get magnitude of type '" .. t .. "'")
	end
end

-- Module
local Spring = {}
Spring.__index = Spring

-- Constructor
function Spring.new(position, target)
	-- Assert params
	if not position then
		error("Missing argument #1 to Spring constructor.", 2)
	elseif not target then
		error("Missing argument #2 to Spring constructor.", 2)
	elseif type(position) ~= type(target) then
		error("Spring constructor requires identical types for position and target arguments." .. 
			" position: " .. tostring(type(position)) ..
			" target: " .. tostring(type(target)),
			2)
	elseif typeof(position) ~= typeof(target) then
		error("Spring constructor requires identical types for position and target arguments." .. 
			" position: " .. tostring(typeof(position)) ..
			" target: " .. tostring(typeof(target)),
			2)
	end

	-- Create object
	local object = setmetatable({}, Spring)

	-- Set values
	local function createEvent()
		return Instance.new("BindableEvent", game:GetService("ReplicatedStorage"))
	end
	object.TargetReached = createEvent()
	object.TargetChanged = createEvent()
	object.position = position
	object.target = target
	object.speed = 1
	object.damping = 1
	if typeof(object.position) == "UDim2" then
		object.isUDim2 = true
	end

	-- Set velocity based on type
	if object.isUDim2 then
		object.velocity = multiplyUDim2(object.target, 0)
	else
		object.velocity = (object.target) * 0
	end

	-- return object
	return object
end
function Spring:destroy()
	self.TargetReached:Destroy()
end

-- Getters
function Spring:getPosition()
	return self.position
end
function Spring:getVelocity()
	return self.velocity
end
function Spring:getTarget()
	return self.target
end

-- Setters
function Spring:setPosition(position)
	self.position = position
end
function Spring:setTarget(target)
	self.target = target
	self.TargetChanged:Fire(target)
end
function Spring:setVelocity(velocity)
	self.velocity = velocity
end
function Spring:setSpeed(speed)
	self.speed = speed
end
function Spring:setDamping(damping)
	self.damping = damping
end

-- Update
function Spring:update(dt)
	-- Coefficients
	local ppc, pvc, vvc, vpc
	
	-- Over damped
	local damping = self.damping
	local w = self.speed
	if damping > 1 then
		local za = -w * damping
		local zb = w * math.sqrt(damping * damping - 1)
		local z1 = za - zb
		local z2 = za + zb
		
		local e1 = math.pow(e, z1 * dt)
		local e2 = math.pow(e, z2 * dt)
		
		local inv = 1 / (2 * zb)
		
		local e1inv = e1 * inv
		local e2inv = e2 * inv
		
		local z1e1inv = z1 * e1inv
		local z2e2inv = z2 * e2inv
		
		ppc = e1inv * z2 - z2e2inv + e2
		pvc = -e1inv + e2inv
		
		vpc = (z1e1inv - z2e2inv + e2) * z2
		vvc = -z1e1inv + z2e2inv
		
	-- Under damped
	elseif damping < 1 then
		local oz = w * damping
		local alpha = w * math.sqrt(1 - damping * damping)
		
		local et = math.pow(e, -oz * dt)
		local ct = math.cos(alpha * dt)
		local st = math.sin(alpha * dt)
		
		local invalpha = 1 / alpha
		
		local esin = et * st
		local ecos = et * ct
		local eoz = et * oz * st * invalpha
		
		ppc = ecos + eoz
		pvc = esin * invalpha
		
		vpc = -esin * alpha - oz * eoz
		vvc = ecos - eoz
		
	-- Critically damped
	elseif damping == 1 then
		local eterm = math.pow(e, -w * dt)
		local tme = dt * eterm
		
		ppc = tme + eterm
		pvc = tme
		
		vpc = -w * tme
		vvc = -tme + eterm
	end
	
	-- Set position and velocity
	if self.isUDim2 then
		local oldpos = self.position - self.target
		local oldvel = self.velocity
		
		-- Set
		self.position = multiplyUDim2(oldpos, ppc) + multiplyUDim2(oldvel, pvc) + self.target
		self.velocity = multiplyUDim2(oldpos, vpc) + multiplyUDim2(oldvel, vvc)
	else
		local oldpos = self.position - self.target
		local oldvel = self.velocity
		
		-- Set
		self.position = oldpos * ppc + oldvel * pvc + self.target
		self.velocity = oldpos * vpc + oldvel * vvc
	end

	-- Target reached
	local reached = (getMagnitude(self.target - self.position) / getMagnitude(self.target) <= TargetReachedMagnitudeThreshold)
	if reached then
		self.TargetReached:Fire(self.target)
	end

	-- return
	return self.position, self.velocity
end

-- return module
return Spring
