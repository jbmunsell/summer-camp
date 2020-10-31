--
--	Jackson Munsell
--	14 Sep 2020
--	rx2.lua
--
--	My recreation of reactive extensions due to some weird quirks and shortcomings of RxLua
--

-- return lib
local folder = script.Parent.Parent.rx
local Observable = require(folder.Observable)
local Observer = require(folder.Observer)
local ConnectableObservable = require(folder.ConnectableObservable)
local BehaviorSubject = require(folder.BehaviorSubject)

---------------------------------------------------------------------------------------------------
-- Publish functions (circular, must be abstracted to this module)
---------------------------------------------------------------------------------------------------

-- Publish
-- function Observable:publish()
-- 	local onSubscribe = self._onSubscribe
-- 	ConnectableObservable.init(self, onSubscribe)
-- 	setmetatable(self, ConnectableObservable)
-- 	return self
-- end

-- -- Share
-- function Observable:share()
-- 	local connectable = self:publish()
-- 	connectable:connect()
-- 	return connectable
-- end

-- Share
-- 	This new version of share multicasts to a BehaviorSubject and skips the first value, which is automatically
-- 	pushed from the BehaviorSubject.
function Observable:share()
	return self:multicast(BehaviorSubject.new()):skip(1)
end

-- Multicast
function Observable:multicast(o)
	o.bin:hold(self:subscribe(function (...)
		o:push(...)
	end, function (...)
		o:fail(...)
	end, function (...)
		o:complete(...)
	end))

	return o
end

---------------------------------------------------------------------------------------------------
-- lib return
---------------------------------------------------------------------------------------------------

return {
	Observable = Observable,
	ConnectableObservable = ConnectableObservable,
	Observer = Observer,
	BehaviorSubject = BehaviorSubject,
}
