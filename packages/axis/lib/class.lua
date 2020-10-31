--
--	Jackson Munsell
--	24 Jul 2020
--	class.lua
--
--	Axis class module - basic OOP class factory
--

-- tableau
local tableau = require(script.Parent.tableau)

-- class
local class = {}

-- constructor
function class.new()
	-- Create class
	local newClass = {}
	newClass.__index = newClass

	-- Create constructor and map to init
	newClass.new = function(...)
		local object = setmetatable({}, newClass)
		if newClass.init then
			newClass.init(object, ...)
		end
		return object
	end

	-- return new class
	return newClass
end

-- extend
function class.extend(super)
	-- Create class
	local sub = class.new()
	setmetatable(sub, super)

	-- return subclass
	return sub
end

-- VERY naive mix function
function class.mix(super, component)
	for k, v in pairs(component) do
		super[k] = v
	end
end

-- bind method
function class.bind(func, ...)
	local base = table.pack(...)
	return function(...)
		local args = tableau.concat(base, table.pack(...))
		return func(table.unpack(args))
	end
end

-- return class
return class
