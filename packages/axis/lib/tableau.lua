--
--	Jackson Munsell
--	24 Jul 2020
--	tableau.lua
--
--	Library of extra table manipulation functions
--

-- lib
local tableau = {}

-- table lock
local tableLock = {
	__index = function(tb, key)
		local val = rawget(tb, key)
		if val == nil then
			error(string.format("Key '%s' not found in table", key))
		end
		return val
	end,
	__newindex = function()
		error("Read only tables cannot be modified")
	end
}
function tableau.lock(tb)
	for _, v in pairs(tb) do
		if type(v) == "table" then
			setmetatable(v, tableLock)
		end
	end
	return setmetatable(tb, tableLock)
end

-- enumerate a series of strings into a locked table
function tableau.enumerate(strings)
	local t = {}
	for i, key in ipairs(strings) do
		t[key] = i
	end
	return tableau.lock(t)
end

-- log
function tableau.log(tb, ntabs)
	if not tb then print("nil") return end
	ntabs = ntabs or 0
	local tabstr = string.rep("\t", ntabs)
	for k, v in pairs(tb) do
		if type(v) == "table" then
			print(tabstr .. k .. ": ")
			tableau.log(v, ntabs + 1)
		else
			print(tabstr .. k .. ": " .. tostring(v))
		end
	end
end

-- removeValue
-- 	Removes the first occurrence of a specific value from a table
function tableau.removeValue(tb, v)
	local index = table.find(tb, v)
	if index then
		table.remove(tb, index)
	end
end

-- compare
-- 	Does a deep primitive comparison of tables
function tableau.compare(a, b, escape)
	for k, v in pairs(a) do
		local t = type(v)
		local eq = (t == "table" and tableau.compare(v, b[k]) or (b[k] == v))
		if not eq then return false end
	end
	return (escape and true or tableau.compare(b, a, true))
end

-- concat
-- 	concatenates multiple arrays into a single array
function tableau.concat(...)
	local bt = {}
	for _, t in ipairs(table.pack(...)) do
		for _, v in ipairs(t) do
			table.insert(bt, v)
		end
	end
	return bt
end

-- shuffle
function tableau.shuffle(tb)
	local st = tableau.copy(tb)
	for i = #st, 2, -1 do
		local j = math.random(i)
		st[i], st[j] = st[j], st[i]
	end
	return st
end

-- copy
-- 	shallow copy
function tableau.copy(tb)
	local new = {}
	for k, v in pairs(tb) do
		new[k] = v
	end
	return new
end

-- Merge dictionaries
function tableau.merge(src, dest)
	for k, v in pairs(src) do
		if type(v) ~= "table" then
			dest[k] = v
		else
			dest[k] = {}
			tableau.merge(v, dest[k])
		end
	end
end

-- duplicate
-- 	deep copy
function tableau.duplicate(tb)
	local new = {}
	for k, v in pairs(tb) do
		new[k] = (type(v) == "table" and tableau.duplicate(v) or v)
	end
	return new
end

-- concat field
function tableau.concatField(tb, field, sep)
	local str = ""
	for _, v in pairs(tb) do
		str = str .. v[field] .. (sep or " ")
	end
	return str
end

-- merge
-- function tableau.merge(a, b)
-- 	local r = {}
-- 	for k, v in pairs(a) do
-- 		r[k] = v
-- 	end
-- 	for k, v in pairs(b) do
-- 		r[k] = v
-- 	end
-- 	return r
-- end

-- Value objects to table
tableau.null = {} -- Special value to cover object values with nil init value
local SpecialTypeMappings = {
	["table"]    = "Folder",
	["boolean"]  = "BoolValue",
	["null"]     = "ObjectValue",
	["Instance"] = "ObjectValue",
}
local function capitalize(str)
	return string.gsub(str, "^%l", string.upper)
end
function tableau.getValueObjectType(value)
	local t = (value == tableau.null and "null" or typeof(value))
	if SpecialTypeMappings[t] then
		t = SpecialTypeMappings[t]
	else
		t = capitalize(t) .. "Value"
	end
	
	return t	
end
function tableau.valueObjectsToTable(instance)
	if instance:IsA("Folder") then
		local tb = {}
		for _, child in pairs(instance:GetChildren()) do
			tb[child.Name] = tableau.valueObjectsToTable(child)
		end
		return tb
	elseif instance:IsA("ValueBase") then
		return instance.Value
	end
end
function tableau.tableToValueObjects(key, value)
	local t = tableau.getValueObjectType(value)
	local instance = Instance.new(t)
	instance.Name = key
	if t == "Folder" then
		for k, v in pairs(value) do
			tableau.tableToValueObjects(k, v).Parent = instance
		end
	else
		if value ~= tableau.null then
			instance.Value = value
		end
	end
	
	return instance
end

---------------------------------------------------------------------------------------------------
-- Functional tables
---------------------------------------------------------------------------------------------------

-- identity function
local function identity(...)
	return ...
end

-- functional table metatable
local ftable = {}
ftable._isFunctionalTable = true
ftable.__index = ftable
-- __len metamethod is not supported in luau :(((((
-- ftable.__len = function (self)
-- 	return #self.data
-- end

-- from
function tableau.from(tb)
	if tb._isFunctionalTable then return tb end
	return setmetatable({ data = tb }, ftable)
end

-- empty
function tableau.empty()
	return tableau.from({})
end

-- from instance tag
function tableau.fromInstanceTag(instanceTag)
	return tableau.from(game:GetService("CollectionService"):GetTagged(instanceTag))
end

-- from layout contents
function tableau.fromLayoutContents(guiLayoutContainer)
	return tableau.from(guiLayoutContainer:GetChildren())
		:filter(function (instance) return instance:IsA("GuiObject") end)
end

-- from value objects
function tableau.fromValueObjects(instance)
	return tableau.from(tableau.valueObjectsToTable(instance))
end

-- raw
function ftable:raw()
	return self.data
end

-- tap
function ftable:tap(f)
	assert(type(f) == "function", "ftable:tap requires a function")
	for i, v in pairs(self.data) do
		f(v, i)
	end
	return self
end

-- foreach
function ftable:foreach(f)
	assert(type(f) == "function", "ftable:foreach requires a function")
	for _, v in pairs(self.data) do
		f(v)
	end
end
function ftable:foreachi(f)
	assert(type(f) == "function", "ftable:foreach requires a function")
	for i, v in pairs(self.data) do
		f(v, i)
	end
end

-- random
function ftable:random()
	return self.data[math.random(1, #self.data)]
end

-- size
function ftable:size()
	return #self.data
end

-- all
function ftable:all(f)
	local t = type(f)
	assert(t == "function" or t == "nil", "ftable:all requires a function or nil")

	f = f or identity

	for i, v in pairs(self.data) do
		if not f(v, i) then
			return false
		end
	end
	return true
end

-- filter
function ftable:filter(f)
	f = f or identity
	assert(type(f) == "function", "ftable:filter requires a function or nil")
	local data = {}
	for i, v in pairs(self.data) do
		if f(v, i) then
			table.insert(data, v)
		end
	end
	return tableau.from(data)
end

-- reject
function ftable:reject(f)
	assert(type(f) == "function", "ftable:reject requires a function")
	return self:filter(function (...)
		return not f(...)
	end)
end

-- map
function ftable:map(f)
	assert(type(f) == "function", "ftable:map requires a function")
	local data = {}
	for i, v in pairs(self.data) do
		table.insert(data, f(v, i))
	end
	return tableau.from(data)
end

-- flat map
function ftable:flatMap(f)
	assert(type(f) == "function", "ftable:flatMap requires a function")
	local data = {}
	for i, v in pairs(self.data) do
		local nest = f(v, i)
		if type(nest) ~= "table" then
			error("ftable:flatMap callback must return a table")
		end
		tableau.from(nest):foreach(function (k)
			table.insert(data, k)
		end)
	end
	return tableau.from(data)
end

-- reduce
function ftable:reduce(f, seed)
	assert(type(f) == "function", "ftable:reduce requires a function")
	for _, v in pairs(self.data) do
		seed = f(v, seed)
	end
	return seed
end

-- min
function ftable:min(getValue)
	getValue = getValue or identity
	assert(type(getValue) == "function", "ftable:min requires a function or nil")

	if #self.data == 0 then return nil end
	
	local cmin = nil
	local cval = math.huge
	for _, v in pairs(self.data) do
		local val = getValue(v)
		if val and val < cval then
			cmin = v
			cval = val
		end
	end
	return cmin, cval
end
function ftable:max(getValue)
	getValue = getValue or identity
	assert(type(getValue) == "function", "ftable:max requires a function or nil")

	if #self.data == 0 then return nil end
	
	local cmax = nil
	local cval = -math.huge
	for _, v in pairs(self.data) do
		local val = getValue(v)
		if val and val > cval then
			cmax = v
			cval = val
		end
	end
	return cmax, cval
end

-- first
function ftable:first(f)
	assert(not f or type(f) == "function", "ftable:first requires a function or nil")

	f = f or identity

	for _, v in pairs(self.data) do
		if not f or f(v) then
			return v
		end
	end
end

-- append
function ftable:append(t)
	assert(t and type(t) == "table", "ftable:append requires a table")

	local data = tableau.copy(self.data)
	for _, v in ipairs(t._isFunctionalTable and t.data or t) do
		table.insert(data, v)
	end

	return tableau.from(data)
end

-- return lib
return tableau