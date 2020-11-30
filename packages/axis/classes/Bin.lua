--
--	Jackson Munsell
--	21 Sep 2020
--	Bin.lua
--
--	Bin module - holds items like instances and event connections to be dumped upon request
--

-- modules
local class = require(script.Parent.Parent.lib.class)

-- Supported types
local SupportedTypes = {
	"Instance",
	"RBXScriptConnection",
	"table",
	"function",
}

-- Dispose
local function dispose(item)
	local t = typeof(item)
	if t == "Instance" then
		item:Destroy()
	elseif t == "RBXScriptConnection" then
		item:Disconnect()
	elseif t == "table" then
		if item._isObserver then
			item:unsubscribe()
		end
	elseif t == "function" then
		item()
	else
		error("Could not dispose of object of type " .. t)
	end
end

-- class
local Bin = class.new()

-- Object maintenance
function Bin.init(self, ...)
	-- Members
	self.items = {}

	-- Hold all supplied in constructor
	for _, item in pairs({...}) do
		self:hold(item)
	end
end
function Bin.destroy(self)
	self:dump()
end

-- Hold item
-- 	Tracks this item and disposes of it when dump is called
function Bin.hold(self, ...)
	for _, item in ipairs(table.pack(...)) do
		local tof = typeof(item)
		assert(table.find(SupportedTypes, tof), "Bin cannot hold type '" .. tof .. "'")

		if tof == "table" and item._isObserver and not item:isSubscribed() then return end
		if self.destroyed then
			-- print("Hold called on a destroyed bin; disposing")
			dispose(item)
		else
			table.insert(self.items, item)
		end
	end
end

-- Drop item
-- 	Drops a specific item (if we have it) and disposes it
function Bin.drop(self, item)
	for i, v in pairs(self.items) do
		if v == item then
			table.remove(self.items, i)
			break
		end
	end
	dispose(item)
end

-- Dump
-- 	Disconnects events, unsubscribes subscriptions, and destroys instances
function Bin.dump(self)
	for _, item in pairs(self.items) do
		dispose(item)
	end
	self.items = {}
end

-- Destroy
-- 	Dumps and sets flag so that we can immediately dump future holds
function Bin.destroy(self)
	self.destroyed = true
	self:dump()
end

-- return class
return Bin
