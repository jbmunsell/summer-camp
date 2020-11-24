--
--	Jackson Munsell
--	15 Oct 2020
--	dart.lua
--
--	Dart lib. Contains a ton of tiny helper functions for
-- 	use with rx and tableau.
--

-- lib
local dart = {}

-- quick wrappers
function dart.destroy(c)
	if c then
		c:Destroy()
	end
end
function dart.getDescendants(c)
	return c:GetDescendants()
end
function dart.getChildren(c)
	return c:GetChildren()
end
function dart.clearAllChildren(c)
	c:ClearAllChildren()
end
function dart.getPlayerFromCharacter(c)
	return game:GetService("Players"):GetPlayerFromCharacter(c)
end
function dart.identity(...)
	return ...
end

-- quick utilities (not factories)
function dart.increment(v)
	return v + 1
end
function dart.boolOr(a, b)
	return a or b
end
function dart.boolAnd(a, b)
	return a and b
end
function dart.boolNot(a)
	return not a
end
function dart.boolAll(...)
	for _, val in ipairs(table.pack(...)) do
		if not val then
			return false
		end
	end
	return true
end
function dart.boolify(v)
	return (v and true or false)
end

-- Coroutine wrap factory
function dart.wrap(f)
	return function (...)
		return coroutine.wrap(f)(...)
	end
end

-- Find first child factory
function dart.findFirstChild(name, recursive)
	return function (instance)
		return instance:FindFirstChild(name, recursive)
	end
end
function dart.isDescendantOf(instance)
	return function (v)
		return v:IsDescendantOf(instance)
	end
end

-- Parameter manipulation
function dart.drag(...)
	local static = table.pack(...)
	return function (...)
		local payload = table.pack(...)
		local pcount = payload.n
		for i, v in ipairs(static) do
			payload[i + pcount] = v
		end
		return table.unpack(payload, 1, pcount + static.n)
	end
end
function dart.carry(...)
	local static = table.pack(...)
	return function (...)
		local payload = table.pack(...)
		local pcount = payload.n
		for k, v in ipairs(static) do
			table.insert(payload, k, v)
		end
		return table.unpack(payload, 1, pcount + static.n)
	end
end
function dart.bind(f, ...)
	local base = table.pack(...)
	return function (...)
		local payload = table.pack(...)
		local pcount = payload.n
		for k, v in ipairs(base) do
			table.insert(payload, k, v)
		end
		return f(table.unpack(payload, 1, pcount + base.n))
	end
end
function dart.follow(f, ...)
	local back = table.pack(...)
	return function (...)
		local payload = table.pack(...)
		local pcount = payload.n
		for _, v in ipairs(back) do
			table.insert(payload, v)
		end
		return f(table.unpack(payload, 1, pcount + back.n))
	end
end

-- equals value
function dart.equals(val)
	return function (x)
		return x == val
	end
end

-- does NOT equal value
function dart.notEquals(val)
	return function (x)
		return x ~= val
	end
end

-- less than
function dart.lessThan(val)
	return function (x)
		return x < val
	end
end
function dart.greaterThan(val)
	return function (x)
		return x > val
	end
end

-- return constant value
function dart.constant(val)
	return function ()
		return val
	end
end

-- IsA class
function dart.isa(class)
	return function (instance)
		return instance:IsA(class)
	end
end

-- print constant value
function dart.printConstant(v)
	return function ()
		print(v)
	end
end

-- select a single datum from a data set
function dart.select(i)
	return function (...)
		return table.pack(...)[i]
	end
end

-- drop a single datum from a data set
function dart.drop(i)
	return function (...)
		local data = table.pack(...)
		table.remove(data, i)
		return table.unpack(data, 1, data.n)
	end
end

-- index
function dart.index(...)
	local keys = {...}
	return function (v)
		for _, key in pairs(keys) do
			v = v[key]
		end
		return v
	end
end

-- is named
function dart.isNamed(name)
	return function (instance)
		return instance.Name == name
	end
end

-- has instance tag
function dart.hasTag(tag)
	return function (instance)
		return game:GetService("CollectionService"):HasTag(instance, tag)
	end
end
function dart.addTag(tag)
	return function (instance)
		game:GetService("CollectionService"):AddTag(instance, tag)
	end
end

-- get name ancestor
function dart.getNamedAncestor(instance, name)
	while instance and instance ~= game do
		instance = instance.Parent
		if instance.Name == name then
			return instance
		end
	end
	return nil
end

-- Get a player from the character child
function dart.getPlayerFromCharacterChild(child)
  return child.Parent and game:GetService("Players"):GetPlayerFromCharacter(child.Parent)
end

-- set value
function dart.setValue(value)
	return function (valueObject)
		valueObject.Value = value
	end
end

-- forward to a bindable or remote event
function dart.forward(instance)
	local RunService = game:GetService("RunService")
	local fire
	if instance:IsA("BindableEvent") then
		fire = function (...) instance:Fire(...) end
	elseif instance:IsA("RemoteEvent") then
		if RunService:IsClient() then
			fire = function (...) instance:FireServer(...) end
		elseif RunService:IsServer() then
			fire = function (...) instance:FireClient(...) end
		end
	end
	return fire
end

-- return lib
return dart
