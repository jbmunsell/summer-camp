--
--	Jackson Munsell
--	27 Sep 2020
--	BehaviorSubject.lua
--
--	Behavior subject class - functions as both an observer and an observable.
-- 	Also caches the latest value and emits immediately to new subscribers.
-- 	Ideal for pseudo-properties that always have a value from which subscribers
-- 	will read on construction and on changed.
--

-- modules
local axis = script.Parent.Parent
local class = require(axis.lib.class)
local tableau = require(axis.lib.tableau)
local Bin = require(axis.classes.Bin)
local Observable = require(script.Parent.Observable)

-- class
local BehaviorSubject = class.extend(Observable)

-- Object maintenance
function BehaviorSubject:init(seed)
	Observable.init(self, function (observer)
		table.insert(self.observers, observer)
		observer:push(self:getValue())
		observer.bin:hold(function ()
			tableau.removeValue(self.observers, observer)
		end)
	end)
	self._isBehaviorSubject = true
	self.value = seed
	self.bin = Bin.new()
	self.observers = {}
end
function BehaviorSubject:destroy()
	for _, observer in pairs(self.observers) do
		observer:destroy()
	end
	self.bin:destroy()
end

-- Get value
function BehaviorSubject:getValue()
	return self.value
end

-- Push
function BehaviorSubject:push(...)
	self.value = ...
	for _, observer in pairs(self.observers) do
		observer:push(...)
	end
end

-- fail and complete
function BehaviorSubject:fail(...)
	for _, observer in pairs(self.observers) do
		observer:fail(...)
	end
end
function BehaviorSubject:complete(...)
	for _, observer in pairs(self.observers) do
		observer:complete(...)
	end
end

-- return class
return BehaviorSubject
