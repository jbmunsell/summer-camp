--
--	Jackson Munsell
--	09 Nov 2020
--	collection.lua
--
--	Utility module for folders that represent array-style data
--

-- modules
local axis = script.Parent.Parent
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)

-- lib
local collection = {}

-- add entry
function collection.addValue(folder, entry)
	local value = Instance.new(tableau.getValueObjectType(entry))
	value.Name = tostring(#folder:GetChildren() + 1)
	value.Value = entry
	value.Parent = folder
end

-- Remove entry
function collection.removeValue(folder, value)
	local entry = collection.getValue(folder, value)
	if entry then
		entry:Destroy()
	end
end

-- get entry
function collection.getValue(folder, value)
	return tableau.from(folder:GetChildren())
		:first(function (v) return v.Value == value end)
end
function collection.getRandom(folder)
	local children = folder:GetChildren()
	if #children > 0 then
		return children[math.random(1, #children)]
	end
end

-- get index
function collection.getIndex(folder, value)
	return tonumber(collection.getValue(folder, value).Name)
end

-- clear
function collection.clear(folder)
	folder:ClearAllChildren()
end

-- observe values changed
function collection.observeChanged(folder, init)
	local stream = rx.Observable.fromInstanceEvent(folder, "ChildAdded")
		:merge(rx.Observable.fromInstanceEvent(folder, "ChildRemoved"))
		:map(dart.constant(nil))
	return init and stream:startWithArgs(nil) or stream
end

-- return lib
return collection
