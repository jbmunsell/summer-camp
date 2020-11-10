--
--	Jackson Munsell
--	07/08/18
--	glib.lua
--
--	Gui library
--

-- rx module
local rx = require(script.Parent.rx)
local dart = require(script.Parent.dart)

-- Module
local glib = {}

-- Consts
local GuiInset = 36
glib.GOLDEN_RATIO = 1.61803398875

-- Transparency properties of gui objects
-- 	This section is for functions that recursively set the transparency of an entire frame
-- 	based on the original values of properties. For example, if you have a frame that
-- 	is at 0.7 transparency and you call glib.SetTransparency(frame, 0.5) then the transparency will be set to
-- 	half of the way between the original transparency (which is 0.7) and 1, so the resulting transparency will be 0.85
local TransProps = {
	BasePart    = {"Transparency"},
	Frame		= {"BackgroundTransparency"},
	TextLabel	= {"BackgroundTransparency", "TextTransparency", "TextStrokeTransparency"},
	TextBox		= {"BackgroundTransparency", "TextTransparency", "TextStrokeTransparency"},
	TextButton	= {"BackgroundTransparency", "TextTransparency", "TextStrokeTransparency"},
	ImageLabel	= {"BackgroundTransparency", "ImageTransparency"},
	ImageButton	= {"BackgroundTransparency", "ImageTransparency"},
	ScrollingFrame	= {"BackgroundTransparency"},
}
function glib.LogFrameTransparency(f)
	if not f:FindFirstChild("_Transparency") then
		local value = Instance.new("NumberValue")
		value.Name = "_Transparency"
		value.Value = 0
		value.Parent = f
	end
	local function ltrans(ob)
		if ob:IsA("GuiObject") and TransProps[ob.ClassName] then
			for _, prop in pairs(TransProps[ob.ClassName]) do
				local pn = "_" .. prop
				local val = ob:FindFirstChild(pn)
				if not val then
					val = Instance.new("NumberValue")
					val.Name = pn
					val.Parent = ob
				end
				val.Value = ob[prop]
			end
		end
		for _, child in pairs(ob:GetChildren()) do
			ltrans(child)
		end
	end
	ltrans(f)
end
function glib.SetFrameTransparency(f, trans)
	if not f:FindFirstChild("_Transparency") then glib.LogFrameTransparency(f) end
	local val = f:FindFirstChild("_Transparency")
	if not val then
		val = Instance.new("NumberValue")
		val.Name = "_Transparency"
		val.Parent = f
	end
	val.Value = trans
	local function set(ob)
		if ob:IsA("GuiObject") and TransProps[ob.ClassName] then
			for _, prop in pairs(TransProps[ob.ClassName]) do
				local otherVal = ob:FindFirstChild("_" .. prop)
				if otherVal then
					ob[prop] = otherVal.Value + trans * (1 - otherVal.Value)
				end
			end
		end
		for _, child in pairs(ob:GetChildren()) do
			set(child)
		end
	end
	set(f)
end
function glib.GetFrameTransparency(f)
	local val = f:FindFirstChild("_Transparency")
	return val and val.Value or 0
end

-- Clear layout contents
function glib.clearLayoutContents(container)
	for _, child in pairs(container:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- Calculate absolute position
function glib.CalculateAbsolutePosition(position, parent)
	local parentPos = parent.AbsolutePosition
	local parentSize = parent.AbsoluteSize
	return parentPos + Vector2.new(
		position.X.Scale * parentSize.X + position.X.Offset,
		position.Y.Scale * parentSize.Y + position.Y.Offset
	)
end

-- Frame has mouse
function glib.FrameHasMouse(frame)
	local mouse = game:GetService("Players").LocalPlayer:GetMouse()
	return (
		frame.AbsolutePosition.X <= mouse.X and
		frame.AbsolutePosition.Y <= mouse.Y and
		frame.AbsolutePosition.X + frame.AbsoluteSize.X >= mouse.X and
		frame.AbsolutePosition.Y + frame.AbsoluteSize.Y >= mouse.Y
	)
end

-- --------------------------------------------------------------------------
-- Functional utilities
-- --------------------------------------------------------------------------

-- Reads up the hierarchy until it finds a screen gui ancestor
function glib.getScreenGui(instance)
	if not instance or instance:IsA("ScreenGui") then return instance end
	return glib.getScreenGui(instance.Parent)
end

-- Returns whether or not a gui object contains a point, automatically accounting for 
-- 	ignore gui inset
function glib.isPointInGuiObject(point, instance)
	local screen = glib.getScreenGui(instance)
	if screen and screen.IgnoreGuiInset then
		point = Vector2.new(point.X, point.Y - GuiInset)
	end
	return (
		instance.AbsolutePosition.X <= point.X and
		instance.AbsolutePosition.Y <= point.Y and
		instance.AbsolutePosition.X + instance.AbsoluteSize.X >= point.X and
		instance.AbsolutePosition.Y + instance.AbsoluteSize.Y >= point.Y
	)
end

-- --------------------------------------------------------------------------
-- Reactive functions
-- --------------------------------------------------------------------------

-- Get exit stream
-- 	returns a stream of click events from first child of name "ExitButton"
function glib.getExitStream(instance)
	local exitButton = instance:FindFirstChild("ExitButton", true)
	if exitButton then
		return rx.Observable.from(exitButton.Activated)
	end
end

-- --------------------------------------------------------------------------
-- Spring functions
-- --------------------------------------------------------------------------

-- Spring class
local Spring = require(script.Parent.Parent.classes.Spring)

-- Springs
local springs = {}

-- Destroy springs
function glib.destroySprings(instance)
	local map = springs[instance]
	for _, spring in pairs(map) do
		spring:destroy()
	end
	springs[instance] = nil
end

-- Spring map create and get
function glib.createSpringMap(instance)
	local map = {}
	springs[instance] = map
	rx.Observable.from(instance.AncestryChanged)
		:filter(function () return not instance:IsDescendantOf(game) end)
		:first()
		:map(dart.constant(instance))
		:subscribe(glib.destroySprings)
	return map
end
function glib.getSprings(instance)
	return springs[instance] or glib.createSpringMap(instance)
end

function glib.updateSpringConfig(instance, property, configFolder)
	local spring = glib.getSpring(instance, property)
	spring:setSpeed(configFolder.Speed.Value)
	spring:setDamping(configFolder.Damping.Value)
end

-- Property spring create and get
function glib.createSpringForProperty(instance, property)
	local value = instance[property]
	local instanceSprings = glib.getSprings(instance)
	local spring = Spring.new(value, value)
	instanceSprings[property] = spring

	-- Listen to config changed
	-- local springConfig = instance:FindFirstChild("springConfig")
	-- rx.Observable.just(springConfig)
	-- 	:filter()
	-- 	:flatMap(function (folder)
	-- 		return rx.Observable.from(folder:GetChildren())
	-- 	end)
	-- 	:flatMap(function (valueObject)
	-- 		return rx.Observable.from(valueObject.Changed)
	-- 	end)
	-- 	:startWith(springConfig):filter()
	-- 	:takeUntil(rx.Observable.fromInstanceLeftGame(instance))
	-- 	:subscribe(dart.bind(glib.updateSpringConfig, instance, property, springConfig))

	return spring
end
function glib.getSpring(instance, property)
	local instanceSprings = glib.getSprings(instance)
	return instanceSprings[property] or glib.createSpringForProperty(instance, property)
end

-- Map multiple properties values with a function
local function mapPropertyValues(instance, map, f)
	for property, value in pairs(map) do
		if property ~= "OnCompleted" then
			f(instance, property, value)
		end
	end
end

-- Set properties instantly
function glib.setProperty(instance, property, target)
	local spring = glib.getSpring(instance, property)
	spring:setPosition(target)
	spring:setTarget(target)
end
function glib.setProperties(instance, map)
	mapPropertyValues(instance, map, glib.setProperty)
	return rx.Observable.just(instance)
end

-- Set property target
function glib.setTarget(instance, property, target)
	local spring = glib.getSpring(instance, property)
	spring:setTarget(target)
end
function glib.setTargets(instance, map)
	-- Set the target for each property
	mapPropertyValues(instance, map, glib.setTarget)

	-- Create a spring reached stream for each thing
	local reachedStreams = {}
	local terminator = rx.Observable.fromInstanceLeftGame(instance)
	for property, value in pairs(map) do
		local spring = glib.getSpring(instance, property)
		terminator = terminator:merge(rx.Observable.from(spring.TargetChanged))
		local reached = rx.Observable.from(spring.TargetReached)
			:filter(dart.equals(value))
		table.insert(reachedStreams, reached)
	end
	return rx.Observable.just()
	-- return rx.Observable.combineLatest(unpack(reachedStreams))
	-- 	:map(dart.constant(instance))
	-- 	:first()
	-- 	:takeUntil(terminator)
end

-- Actually drive the springs
-- 	This function must be called somewhere on the client in order for glib
-- 	springs to update on heartbeat
local function updateSprings(dt)
	for instance, springMap in pairs(springs) do
		for property, spring in pairs(springMap) do
			spring:update(dt)
			instance[property] = spring:getPosition()
		end
	end
end
function glib.driveSprings()
	rx.Observable.heartbeat():subscribe(updateSprings)
end

-- Play animation
function glib.playAnimation(animationModule, instance, instant, ...)
	local tween = require(animationModule)(instance, instant, ...)
	local observable
	if type(tween) == "table" then
		for _, t in pairs(tween) do
			t:Play()
		end
		observable = rx.Observable.never()
	else
		observable = (instant and rx.Observable.just() or rx.Observable.from(tween.Completed))
		tween:Play()
	end
	return observable:map(dart.constant(instance))
end

-- --------------------------------------------------------------------------
-- Drive all
-- --------------------------------------------------------------------------

function glib.drive()
	-- glib.driveSprings()
end

-- return library
return glib

