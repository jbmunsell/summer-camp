--
--	Jackson Munsell
--	14 Sep 2020
--	Observable.lua
--
--	rx Observable class
--

-- roblox services
local ContextActionService = game:GetService("ContextActionService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- modules
local axis = script.Parent.Parent
local class = require(axis.lib.class)
local Observer = require(script.Parent.Observer)

-- constants
local identity = function (x) return x end
local noop = function () end

-- class
local Observable = class.new()

-- Constructor
function Observable:init(onSubscribe)
	assert(type(onSubscribe) == "function", "onSubscribe must be a function")

	self._onSubscribe = onSubscribe
	self._isObservable = true
end

-- Subscribe
function Observable:subscribe(onNext, onFail, onCompleted)
	-- Create observer object
	local observer = Observer.new(onNext, onFail, onCompleted)
	self._onSubscribe(observer)
	return observer
end

---------------------------------------------------------------------------------------------------
-- Constructors
---------------------------------------------------------------------------------------------------

-- Never
-- 	Returns an observable that never pushes any values, never fails, and never completes
function Observable.never()
	return Observable.new(function () end)
end

-- Timer
-- 	Returns an observable that pushes a nil value ONCE after a specific time elapses
-- 	@param t - time in seconds
function Observable.timer(t)
	assert(type(t) == "number", "Observable.timer requires a number")

	return Observable.new(function (observer)
		delay(t, function ()
			observer:push()
			observer:complete()
		end)
	end)
end

-- Just
-- 	Returns an observable that instantly upon subscription pushes a single event
-- 	containing all of the data passed to Observable.just
function Observable.just(...)
	local data = table.pack(...)
	return Observable.new(function (observer)
		observer:push(table.unpack(data))
		observer:complete()
	end)
end

-- From
-- 	Returns an observable that is specially created from the source type.
-- 	Currently accommodates:
-- 		tables (Observable one-by-one emits each value in the table)
-- 		RBXScriptSignal (Observable emits all values emitted from the signal, and automatically
-- 			terminates if the signal has been destroyed (i.e. instance to which the event belongs
-- 			gets destroyed)
-- 		Instance
-- 			RemoteEvent
-- 				? RunService:IsClient() | from(RemoteEvent.OnClientEvent)
-- 				? RunService:IsServer() | from(RemoteEvent.OnServerEvent)
-- 			BindableEvent (Observable emits all values emitted by BindableEvent.Event)
-- 			ValueBase (Observable emits all values from .Changed, starting with the current value.
-- 				If you wish to NOT start with current value, just use Observable.from(valueObject.Changed))
-- 		EnumItem
-- 			KeyCode (Observable connects to ContextActionService event with the KeyCode and fires
-- 				all events with the UserInputState from ContextActionService)
function Observable.from(o)
	local t = typeof(o)
	if t == "table" then
		return Observable.new(function (observer)
			local data = o._isFunctionalTable and o.data or o
			for _, v in pairs(data) do
				observer:push(v)
				if not observer:isSubscribed() then break end
			end
			observer:complete()
		end)
	elseif t == "RBXScriptSignal" then
		return Observable.new(function (observer)
			local connection = o:Connect(function (...)
				observer:push(...)
			end)
			observer.bin:hold(connection)
			observer.bin:hold(RunService.Heartbeat:Connect(function ()
				if not connection.Connected then
					observer:complete()
				end
			end))
		end)
	elseif t == "Instance" then
		if o:IsA("BindableEvent") then
			return Observable.from(o.Event)
		elseif o:IsA("ValueBase") then
			-- This is chosen instead of using :startWith because some ValueObjects have nil values
			-- and still desire to fire with initial value (nil)
			return Observable.just(o.Value):merge(Observable.from(o.Changed))
		elseif o:IsA("RemoteEvent") then
			if RunService:IsServer() then
				return Observable.from(o.OnServerEvent)
			elseif RunService:IsClient() then
				return Observable.from(o.OnClientEvent)
			end
		else
			error("Unable to create Observable from instance class '" .. o.ClassName .. "'")
		end
	elseif t == "EnumItem" then
		if table.find(Enum.KeyCode:GetEnumItems(), o) then
			return Observable.new(function (observer)
				local actionName = HttpService:GenerateGUID(false)
				ContextActionService:BindAction(actionName, function (_, state, _)
					observer:push(state)
				end, false, o)

				observer.bin:hold(function ()
					ContextActionService:UnbindAction(actionName)
				end)
			end)
		end
	else
		error("Unable to create Observable from type '" .. t .. "'")
	end
end

-- From property
-- 	Returns an observable that fires each time a specific property of an instance is changed.
function Observable.fromProperty(instance, property, init)
	assert(typeof(instance) == "Instance", "Observable.fromProperty requires an instance")
	assert(type(property) == "string", "Observable.fromProperty requires a string")
	local o = Observable.from(instance:GetPropertyChangedSignal(property))
		:map(function ()
			return instance[property]
		end)
	return (init and o:startWith(instance[property]) or o)
end

-- From instance tag
-- 	Returns an observable that fires each time a new instance receives the given tag,
-- 	starting with all the instances that already have that tag.
-- 	This somewhat goofy implementation is necessary to prevent problems where the subscriber
-- 	yields, which means that we could miss some events between the calls to
-- 	:GetTagged(tag) and :GetInstanceAddedSignal(tag). In order to solve, we create a subscription
-- 	to the added event FIRST, and then we wrap a coroutine to operate on everything that is currently
-- 	tagged.
-- 
-- 	Just kidding! I've changed this again to return it to normal with the expectation that
-- 	individual subscribers will call :subscribe(coroutine.wrap(callback)) if parallelism
-- 	is necessary.
-- 
-- 	Just kidding again! I've re-enabled this change. Fingers crossed
function Observable.fromInstanceTag(instanceTag)
	-- return Observable.from(CollectionService:GetInstanceAddedSignal(instanceTag))
	-- 	:startWithTable(CollectionService:GetTagged(instanceTag))

	return Observable.new(function (observer)
		local sub = Observable.from(CollectionService:GetInstanceAddedSignal(instanceTag))
			:subscribe(observer:wrapAll())
		for _, instance in pairs(CollectionService:GetTagged(instanceTag)) do
			coroutine.wrap(function ()
				observer:push(instance)
			end)()
		end
		return sub
	end)
end

-- From instance left game
-- 	Returns an observable that fires when an instance completely leaves the game hierarchy.
-- 	Close as possible to mimicking an Instance.Destroyed event.
function Observable.fromInstanceLeftGame(instance)
	return Observable.from(instance.AncestryChanged)
		:filter(function () return not instance:IsDescendantOf(game) end)
		:first()
end

-- From player touched descendant
-- 	TODO: Get rid of this in favor of fromHumanoidTouchedDescendant
function Observable.fromPlayerTouchedDescendant(instance, debounce)
	local instances = (instance:IsA("BasePart") and { instance } or instance:GetDescendants())
	local observable = Observable.from(instances)
		:filter(function (d) return d:IsA("BasePart") end)
		:flatMap(function (d) return Observable.from(d.Touched) end)
		:map(function (hit) return hit.Parent and Players:GetPlayerFromCharacter(hit.Parent) end)
		:filter()
		:map(function (player)
			return instance, player
		end)
	return (debounce and observable:throttleFirst(debounce) or observable)
end
function Observable.fromHumanoidTouchedDescendant(instance, debounce)
	local instances = (instance:IsA("BasePart") and { instance } or instance:GetDescendants())
	local observable = Observable.from(instances)
		:filter(function (d) return d:IsA("BasePart") end)
		:flatMap(function (d) return Observable.from(d.Touched) end)
		:map(function (hit) return hit.Parent and hit.Parent:FindFirstChildWhichIsA("Humanoid") end)
		:filter()
		:map(function (humanoid)
			return instance, humanoid
		end)
	return (debounce and observable:throttleFirst(debounce) or observable)
end

-- Heartbeat
-- 	Returns an observable that fires on each game heartbeat.
function Observable.heartbeat()
	return Observable.from(RunService.Heartbeat)
end

-- Interval
-- 	Returns an observable that never terminates and fires every (t) seconds.
function Observable.interval(t)
	assert(type(t) == "number", "Observable.interval requires a number")

	return Observable.new(function (observer)
		spawn(function ()
			while wait(t) and observer:isSubscribed() do
				observer:push()
			end
		end)
	end)
end

-- Range
-- 	Returns an observable that pushes whole numbers starting at (start) and including the next
-- 	(n - 1) numbers.
function Observable.range(start, num)
	assert(type(start) == "number" and type(num) == "number", "Observable.range requires two numbers")

	return Observable.new(function (observer)
		for i = start, start + num - 1 do
			observer:push(i)
		end
		observer:complete()
	end)
end

-- Repeat value
-- 	Returns an observable that pushes the value (v) on subscription (i) separate times.
function Observable.repeatValue(v, i)
	return Observable.new(function (observer)
		for _ = 1, i do
			observer:push(v)
		end
		observer:complete()
	end)
end

---------------------------------------------------------------------------------------------------
-- Transforming observables
---------------------------------------------------------------------------------------------------

-- Pipe
-- 	Runs a custom transform on an observable. Useful for applying multiple operators at once
function Observable:pipe(transform)
	return transform(self)
end

-- Tap
-- 	Runs a function and then passes as normal
function Observable:tap(pushTap, failTap, completeTap)
	pushTap = pushTap or noop
	failTap = failTap or noop
	completeTap = completeTap or noop

	local function tap(original, tapper)
		return function (...)
			tapper(...)
			original(...)
		end
	end
	return Observable.new(function (observer)
		local push, fail, complete = observer:wrapAll()
		observer.bin:hold(self:subscribe(tap(push, pushTap), tap(fail, failTap), tap(complete, completeTap)))
	end)
end

-- Map
-- 	Runs a transform function on the provided value and emits the return value of the transform function
function Observable:map(transform)
	assert(type(transform) == "function", "Observable:map requires a function")

	return Observable.new(function (observer)
		local sub = self:subscribe(function (...)
			observer:push(transform(...))
		end, observer:wrapFailComplete())
		observer.bin:hold(sub)
	end)
end

-- Map to latest
-- 	Creates a new observable that maps all emissions from the source observable to the latest value from
-- 	a BehaviorSubject.
function Observable:mapToLatest(subject)
	assert(subject._isBehaviorSubject, "Observable:mapToLatest requires a BehaviorSubject")

	return self:map(function ()
		return subject:getValue()
	end)
end

-- Flat map
-- 	Runs a transform function on the provided value that returns an observable,
-- 	and returns an observable that merges the results from all observables returned from the
-- 	transform function.
function Observable:flatMap(transform)
	assert(type(transform) == "function", "Observable:flatMap requires a function")

	return Observable.new(function (observer)
		-- Count remaining
		local remaining = 1 -- start at 1 to include root subscription
		local function complete()
			remaining = remaining - 1
			if remaining == 0 then
				observer:complete()
			end
		end

		-- Push and fail
		local push, fail, _ = observer:wrapAll()

		-- Subscribe to top observable
		local sub = self:subscribe(function (...)
			-- Subscribe and hold inner observables
			local observable = transform(...)
			if not type(observable) == "table" and observable._isObservable then
				error("flatMap callback must return an Observable")
			end
			remaining = remaining + 1
			observer.bin:hold(observable:subscribe(push, fail, complete))
		end, fail, complete)

		-- Hold outer subscription
		observer.bin:hold(sub)
	end)
end

-- Scan
-- 	Runs a transform function on the most recent value emitted by this observable and the new value
-- 	and emits the result of that transform function
function Observable:scan(transform, seed)
	assert(type(transform) == "function", "Observable:scan requires a function")
	assert(seed ~= nil, "Observable:scan requires a seed value")

	return Observable.new(function (observer)
		local v = seed
		local sub = self:subscribe(function (...)
			v = transform(v, ...)
			observer:push(v)
		end, observer:wrapFailComplete())
		observer.bin:hold(sub)
	end)
end

---------------------------------------------------------------------------------------------------
-- Filtering operators
---------------------------------------------------------------------------------------------------

-- Filter
-- 	Creates a new observable that only emits values that pass a function
function Observable:filter(f)
	assert(not f or type(f) == "function", "Observable:filter requires nil or a function")
	f = f or identity

	return Observable.new(function (observer)
		local sub = self:subscribe(function (...)
			if f(...) then
				observer:push(...)
			end
		end, observer:wrapFailComplete())
		observer.bin:hold(sub)
	end)
end

-- Reject
-- 	Creates a new observable that only emits values that do NOT pass a function.
-- 	This observable rejects values that DO pass.
function Observable:reject(f)
	f = f or identity
	return self:filter(function (...)
		return not f(...)
	end)
end

-- Partition
-- 	Returns two new observables; one that filters according to F and one that rejects according to F.
function Observable:partition(f)
	return self:filter(f), self:reject(f)
end

-- Distinct
-- 	Returns a new observable that only emits unique values from the source observable
-- 	the first time they are to be emitted.
function Observable:distinct(comparator)
	assert(not comparator or type(comparator) == "function", "Observable:distinct requires nil or a function")

	return Observable.new(function (observer)
		local values = {}
		local sub = self:subscribe(function (v)
			local has
			if comparator then
				has = true
				for _, cached in pairs(values) do
					if not comparator(v, cached) then
						has = false
						break
					end
				end
			else
				has = (table.find(values, v))
			end
			if not has then
				table.insert(values, v)
				observer:push(v)
			end
		end, observer:wrapFailComplete())
		observer.bin:hold(sub)
	end)
end

-- Distinct until changed
-- 	Returns a new observable that only emits values that are not equal to the previous value
function Observable:distinctUntilChanged(comparator)
	assert(not comparator or type(comparator) == "function", "Observable:distinctUntilChanged requires nil or a function")

	return Observable.new(function (observer)
		local previous
		local sub = self:subscribe(function (v)
			local eq
			if comparator then
				eq = comparator(previous, v)
			else
				eq = (previous == v)
			end
			if not eq then
				previous = v
				observer:push(v)
			end
		end, observer:wrapFailComplete())
		observer.bin:hold(sub)
	end)
end

-- Throttle
-- 	Returns an observable that will produce the latest value from any values collected
-- 	during the throttling window, which resets each time a value is received.
function Observable:throttle(t)
	assert(type(t) == "number", "Observable:throttle requires a number")

	return Observable.new(function (observer)
		local throttle = 0
		local latest
		local sub = self:subscribe(function (...)
			throttle = t
			latest = table.pack(...)
		end, observer:wrapFailComplete())
		observer.bin:hold(sub)
		observer.bin:hold(RunService.Heartbeat:Connect(function (dt)
			if throttle > 0 then
				throttle = throttle - dt
				if throttle <= 0 then
					observer:push(table.unpack(latest, 1, latest.n))
				end
			end
		end))
	end)
end

-- Throttle first
-- 	Returns an observable that will not produce any values within a certain time window of the first
-- 	value produced. The window resets each time a value is produced when the observable is NOT
-- 	throttling.
function Observable:throttleFirst(t)
	assert(type(t) == "number", "Observable:throttleFirst requires a number")

	return Observable.new(function (observer)
		local throttle = 0
		local sub = self:subscribe(function (...)
			if throttle <= 0 then
				throttle = t
				observer:push(...)
			end
		end, observer:wrapFailComplete())
		observer.bin:hold(sub)
		observer.bin:hold(RunService.Heartbeat:Connect(function (dt)
			if throttle >= 0 then
				throttle = throttle - dt
			end
		end))
	end)
end

-- Take
-- 	Returns an observable that emits the first N values from the source observable
-- 	and then terminates.
function Observable:take(count)
	assert(type(count) == "number", "Observable:take requires a number")

	return Observable.new(function (observer)
		local taken = 0

		local sub = self:subscribe(function (...)
			if taken >= count then return end
			taken = taken + 1

			observer:push(...)

			if taken >= count then
				observer:complete()
			end
		end, observer:wrapFailComplete())
		observer.bin:hold(sub)
	end)
end

-- Take last
-- 	Returns an observable that emits the last N values from the source observable
-- 	and then terminates. This new observable does not emit until the source
-- 	observable terminates.
function Observable:takeLast(count)
	assert(type(count) == "number", "Observable:takeLast requires a number")

	return Observable.new(function (observer)
		local values = {}

		local _, fail, _ = observer:wrapAll()
		local function push(v)
			table.insert(values, v)
			if #values > count then
				table.remove(values, 1)
			end
		end
		local function complete()
			for _, v in pairs(values) do
				observer:push(v)
			end
			observer:complete()
		end

		local sub = self:subscribe(push, fail, complete)
		observer.bin:hold(sub)
	end)
end

-- First
-- 	Returns an observable that emits only the first value emitted from the source observable
function Observable:first()
	return self:take(1)
end

-- Last
-- 	Returns an observable that emits only the last value emitted from the source observable.
-- 	This new observable does not emit until the source observable completes.
function Observable:last()
	return self:takeLast(1)
end

-- Replay
-- 	Returns an observable that keeps track of the latest N values emitted from the source observable
-- 	and fires with those N values in a series each time the source observable fires.
function Observable:replay(n)
	assert(type(n) == "number", "Observable:replay requires a number")

	return Observable.new(function (observer)
		local index = 0
		local values = {}
		local _, fail, complete = observer:wrapAll()
		local function push(v)
			-- table.insert(values, index, v)
			index = index + 1
			values[index] = v
			if index > n then
				-- table.remove(values, 1)
				for i = 2, index do
					values[i - 1] = values[i]
				end
				index = index - 1
			end
			observer:push(table.unpack(values, 1, n))
		end

		local sub = self:subscribe(push, fail, complete)
		observer.bin:hold(sub)
	end)
end

---------------------------------------------------------------------------------------------------
-- Combination operators
---------------------------------------------------------------------------------------------------

-- Combine latest
-- 	Returns an observable that fires with the latest value from each source observable
-- 	any time any of the source observables fires. NOTE: The returned observable will NOT
-- 	fire until all of the sources have fired at least once.
function Observable:combineLatest(...)
	local sources = {...}
	local operate = table.remove(sources, #sources)
	table.insert(sources, 1, self)
	for _, source in pairs(sources) do
		assert(type(source) == "table" and source._isObservable, "Observable:combineLatest only works with Observables")
	end
	assert(type(operate) == "function", "Observable:combineLatest requires a function for the last argument")

	return Observable.new(function (observer)
		local latest = {}
		local pending = table.create(#sources, true)
		local completed = table.create(#sources, true)

		local fail, _ = observer:wrapFailComplete()
		local complete = function (index)
			return function ()
				completed[index] = nil
				if not next(completed) then
					observer:complete()
				end
			end
		end

		for i, source in pairs(sources) do
			local sub = source:subscribe(function (v)
				pending[i] = nil
				latest[i] = v
				if not next(pending) then
					observer:push(operate(table.unpack(latest, 1, #sources)))
				end
			end, fail, complete(i))
			observer.bin:hold(sub)
		end
	end)
end

-- With latest from
-- 	Returns an observable that fires any time the source observable fires with that value
-- 	from the source observable, and the latest cached value from the secondary observable.
-- 	NOTE: This will only use one value from each observable. Streams that emit multiple
-- 	simultaneous unpacked parameters are not supported.
function Observable:withLatestFrom(secondary)
	assert(type(secondary) == "table" and secondary._isObservable, "Observable:withLatestFrom requires an Observable")

	return Observable.new(function (observer)
		local cached = nil

		local secondarySub = secondary:subscribe(function (...)
			cached = ...
		end)
		local primarySub = self:subscribe(function (...)
			observer:push(..., cached)
		end, observer:wrapFailComplete())

		observer.bin:hold(secondarySub)
		observer.bin:hold(primarySub)
	end)
end

-- Merge
-- 	Returns an observable that emits every value emitted by any of the sources.
function Observable:merge(...)
	local sources = {...}
	table.insert(sources, 1, self)
	return Observable.new(function (observer)
		local completed = {}
		local push, fail, _ = observer:wrapAll()
		local function complete(source)
			return function ()
				table.insert(completed, source)
				if #sources == #completed then
					observer:complete()
				end
			end
		end

		for _, source in pairs(sources) do
			observer.bin:hold(source:subscribe(push, fail, complete(source)))
		end
	end)
end

-- Start with
-- 	Returns an observable that merges values emitted by the source observable
-- 	with a series of static values.
function Observable:startWith(...)
	local values = table.pack(...)
	return Observable.new(function (observer)
		for _, v in ipairs(values) do
			observer:push(v)
			if not observer:isSubscribed() then return end
		end
		return self:subscribe(observer:wrapAll())
	end)
end

-- Start with args
-- 	Identical to startWith, but uses the entire series as args to a single push call
-- 	instead of iterating each value.
function Observable:startWithArgs(...)
	local data = table.pack(...)
	return Observable.new(function (observer)
		observer:push(table.unpack(data))
		return self:subscribe(observer:wrapAll())
	end)
end

-- Start with table
-- 	Identical to startWith, but iterates every item in a single table and pushes
-- 	each individual value.
function Observable:startWithTable(t)
	return Observable.new(function (observer)
		if #t > 0 then
			for _, v in pairs(t) do
				observer:push(v)
				if not observer:isSubscribed() then return end
			end
		end
		return self:subscribe(observer:wrapAll())
	end)
end

-- Switch
-- 	Returns an observable that emits the values from only the most recently emitted
-- 	observable from the source observable.
function Observable:switch()
	return Observable.new(function (observer)
		local latestSub
		local push, fail, complete = observer:wrapAll()
		local sub = self:subscribe(function (observable)
			if latestSub then
				observer.bin:drop(latestSub)
			end

			latestSub = observable:subscribe(push, fail)
			observer.bin:hold(latestSub)
		end, fail, complete)
		observer.bin:hold(sub)
	end)
end

-- Switch map
-- 	Handy combination of map and switch
function Observable:switchMap(f)
	assert(type(f) == "function", "Observable:switchMap requires a function")

	return self:map(f)
		:switch()
end

-- Zip
-- 	Returns an observable that specifically combines emitted values by the index from
-- 	each source observable, only emitting once each source observable has emitted a value
-- 	at that index. Zip will run an operate function and emit the value returned by that
-- 	function.
function Observable:zip(...)
	local sources = {...}
	local operate = table.remove(sources, #sources)
	table.insert(sources, 1, self)
	for _, source in pairs(sources) do
		assert(type(source) == "table" and source._isObservable, "Observable:zip only works with Observables")
	end
	local count = #sources

	return Observable.new(function (observer)
		local pending = {}
		local values = {}
		for i = 1, count do
			values[i] = {}
		end

		local function pushPayload()
			local payload = {}
			for i = 1, count do
				payload[i] = table.remove(values[i], 1)
			end
			observer:push(operate(unpack(payload)))
		end
		local function resetPending()
			pending = table.create(count, true)
			for i = 1, count do
				if values[i][1] ~= nil then
					pending[i] = nil
				end
			end
		end
		resetPending()

		for i, source in pairs(sources) do
			local function push(v)
				table.insert(values[i], v)
				if #values[i] == 1 then
					pending[i] = nil
					if not next(pending) then
						pushPayload()
						resetPending()
					end
				end
			end
			local sub = source:subscribe(push, observer:wrapFailComplete())
			observer.bin:hold(sub)
		end
	end)
end

---------------------------------------------------------------------------------------------------
-- Logic operators
---------------------------------------------------------------------------------------------------

-- Skip
-- 	Returns an observable that ignores the first N emissions from the source observable.
function Observable:skip(count)
	assert(type(count) == "number", "Observable:skip requires a number")

	return Observable.new(function (observer)
		local skipped = 0

		local sub = self:subscribe(function (...)
			if skipped < count then
				skipped = skipped + 1
				return
			end

			observer:push(...)
		end)

		observer.bin:hold(sub)
	end)
end

-- Skip until
-- 	Returns an observable that ignores emissions from the source observable until the first
-- 	emission from a starter observable.
function Observable:skipUntil(starter)
	assert(type(starter) == "table" and starter._isObservable, "Observable:skipUntil requires an Observable")

	return Observable.new(function (observer)
		local skipping = true
		local starterSub
		starterSub = starter:subscribe(function ()
			skipping = false
			observer.bin:drop(starterSub)
		end)

		local primarySub = self:subscribe(function (...)
			if not skipping then
				observer:push(...)
			end
		end, observer:wrapFailComplete())

		observer.bin:hold(starterSub)
		observer.bin:hold(primarySub)
	end)
end

-- Skip while
-- 	Returns an observable that ignores emissions from the source observable until the provided
-- 	function returns false.
function Observable:skipWhile(f)
	assert(type(f) == "function", "Observable:skipWhile requires a function")

	return Observable.new(function (observer)
		local skipping = true

		local primarySub = self:subscribe(function (...)
			if skipping then
				skipping = f(...)
			end
			if not skipping then
				observer:push(...)
			end
		end, observer:wrapFailComplete())

		observer.bin:hold(primarySub)
	end)
end

-- Take until
-- 	Returns an observable that emits all values from the source observable until
-- 	the terminator observable emits once.
function Observable:takeUntil(terminator)
	assert(type(terminator) == "table" and terminator._isObservable, "Observable:takeUntil requires an Observable")

	return Observable.new(function (observer)
		local primarySub = self:subscribe(observer:wrapAll())

		local terminatorSub = terminator:subscribe(function ()
			observer:complete()
		end, observer:wrapFailComplete())

		observer.bin:hold(primarySub)
		observer.bin:hold(terminatorSub)
	end)
end

-- Take while
-- 	Returns an observable that emits all values from the source observable until
-- 	the provided function returns false.
function Observable:takeWhile(f)
	assert(type(f) == "function", "Observable:takeWhile requires a function")

	return Observable.new(function (observer)
		local sub = self:subscribe(function (...)
			if not f(...) then
				observer:complete()
			else
				observer:push(...)
			end
		end, observer:wrapFailComplete())

		observer.bin:hold(sub)
	end)
end

---------------------------------------------------------------------------------------------------
-- Aggregation operators
---------------------------------------------------------------------------------------------------

-- Reduce
-- 	Applies a function to each value emitted from an observable, providing the most recent value
-- 	and the returned value from the function called on the previous value.
function Observable:reduce(f, seed)
	assert(type(f) == "function", "Observable:reduce requires a function")
	assert(seed ~= nil, "Observable:reduce requires a seed value")

	return Observable.new(function (observer)
		local aggregate = seed

		local _, fail, _ = observer:wrapAll()

		local sub = self:subscribe(function (v)
			aggregate = f(aggregate, v)
		end, fail, function ()
			observer:push(aggregate)
			observer:complete()
		end)

		observer.bin:hold(sub)
	end)
end

---------------------------------------------------------------------------------------------------
-- Timing operators
---------------------------------------------------------------------------------------------------

-- Delay
-- 	Emits all items from the source observable after t seconds elapses
function Observable:delay(t)
	local tt = type(t)
	assert(tt == "number" or tt == "function", "Observable:delay requires a number or a function")

	return Observable.new(function (observer)
		return self:subscribe(function (...)
			local args = table.pack(...)
			local d = (tt == "function" and t(...) or t)
			delay(d, function ()
				observer:push(table.unpack(args, 1, args.n))
			end)
		end, observer:wrapFailComplete())
	end)
end

-- return class
return Observable
