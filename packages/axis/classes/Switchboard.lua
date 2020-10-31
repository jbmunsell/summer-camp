--
--	Jackson Munsell
--	24 Jul 2020
--	Switchboard.lua
--
--	Switchboard class - maintains event connections
--

-- env
local axis = script.Parent.Parent
local RunService = game:GetService("RunService")

-- modules
local class = require(axis.meta.class)

-- class
local Switchboard = class.new()

-- Constructor
function Switchboard.init(self)
	-- Allocate members
	self.connections = {}
	self.objects = {}
end

-- connect
function Switchboard.connect(self, connection)
	table.insert(self.connections, connection)
end
function Switchboard.attachObject(self, object)
	if not object.destroy then
		error("Attempt to attach an object with no 'destroy' method")
	end
	table.insert(self.objects, object)
end

-- bind method to signal
function Switchboard.connectToHeartbeat(self, func)
	self:connect(RunService.Heartbeat:Connect(func))
end

-- destroy
function Switchboard.destroy(self)
	for _, connection in pairs(self.connections) do
		connection:Disconnect()
	end
	for _, object in pairs(self.objects) do
		object:destroy()
	end
end

-- return class
return Switchboard
