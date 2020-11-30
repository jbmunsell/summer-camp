--
--	Jackson Munsell
--	21 Sep 2020
--	Observer.lua
--
--	rx Observer class
--

-- Constants
local noop = function () end

-- modules
local class = require(script.Parent.Parent.lib.class)
local Bin = require(script.Parent.Parent.classes.Bin)

-- class
local Observer = class.new()

-- Object maintenance
function Observer:init(onNext, onFail, onComplete)
	-- Type assertions
	assert(type(onNext) == "function" or type(onNext) == "nil")
	assert(type(onFail) == "function" or type(onFail) == "nil")
	assert(type(onComplete) == "function" or type(onComplete) == "nil")

	-- Class flag for Bin class to unsubscribe on dump
	self._isObserver = true

	-- Hold functions
	self._onNext = onNext or noop
	self._onFail = onFail or noop
	self._onComplete = onComplete or noop

	-- State
	self.subscribed = true
	self.bin = Bin.new()
end
function Observer:destroy()
	self:complete()
	-- self:unsubscribe()
end

-- Accessors
function Observer:isSubscribed()
	return self.subscribed
end

-- Push
function Observer:push(...)
	if not self.subscribed then
		-- warn("Attempt to push to an unsubscribed Observer")
		-- print(debug.traceback())
		return
	end
	self._onNext(...)
end
function Observer:fail(...)
	if not self.subscribed then return end
	self._onFail(...)
end
function Observer:complete(...)
	if not self.subscribed then return end
	self:unsubscribe()
	self._onComplete(...)
end

-- Wraps
function Observer:wrapAll()
	return function (...)
		self:push(...)
	end, function (...)
		self:fail(...)
	end, function (...)
		self:complete(...)
	end
end 
function Observer:wrapFailComplete()
	return function (...)
		self:fail(...)
	end, function (...)
		self:complete(...)
	end
end

-- Unsubscribe
function Observer:unsubscribe()
	-- Set state to stopped
	self.subscribed = false
	self.bin:destroy()
end

-- return class
return Observer
