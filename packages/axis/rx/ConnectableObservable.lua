--
--	Jackson Munsell
--	27 Sep 2020
--	ConnectableObservable.lua
--
--	Connectable observable class - does not start emitting values until the
-- 	:connect() method is called - then begins emitting values to all subscribers
--

-- modules
local axis = script.Parent.Parent
local class = require(axis.lib.class)
local tableau = require(axis.lib.tableau)
local Bin = require(axis.classes.Bin)
local Observable = require(script.Parent.Observable)

-- class
local ConnectableObservable = class.extend(Observable)

-- Object maintenance
-- function ConnectableObservable:init()
-- 	Observable.init(self, function (observer)
-- 		table.insert(self.observers, observer)
-- 		observer.bin:hold(function ()
-- 			tableau.removeValue(self.observers, observer)
-- 		end)
-- 	end)
-- 	self.bin = Bin.new()
-- 	self.observers = {}
-- end
-- function ConnectableObservable:destroy()
-- 	self.bin:destroy()
-- end

-- -- Connect
-- function ConnectableObservable:connect()
-- 	local sub = self:subscribe(function (...)
-- 		for _, observer in pairs(self.observers) do
-- 			observer:push(...)
-- 		end
-- 	end, function (...)
-- 		for _, observer in pairs(self.observers) do
-- 			observer:fail(...)
-- 		end
-- 	end, function (...)
-- 		for _, observer in pairs(self.observers) do
-- 			observer:complete(...)
-- 		end
-- 	end)

-- 	self.bin:hold(sub)
-- end

-- return class
return ConnectableObservable
