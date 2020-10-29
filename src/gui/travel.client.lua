--
--	Jackson Munsell
--	21 Sep 2020
--	travel.client.lua
--
--	Travel gui functionality driver
--

-- env
local UserInputService = game:GetService("UserInputService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local rx   = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local glib = require(axis.lib.glib)

-- instances
local Core = env.PlayerGui:WaitForChild("Core")
local TravelFrame = Core.Container.Travel
local TravelMenuButton = Core.Container.MenuButtons.Travel
local seeds = Core.seeds
local animations = Core.animations

-- Send to location
local function sendToLocation(location)
	-- Grab local player character
	local character = env.LocalPlayer.Character
	if not character then return end

	-- Snap to location (preserving rotation)
	local cf = character:GetPrimaryPartCFrame()
	character:SetPrimaryPartCFrame(cf - cf.p + location.Position)
end

-- Construct locations list
local function constructLocations()
	-- Clear list
	glib.clearLayoutContents(TravelFrame.Locations)

	-- Populate list
	local locations = workspace["travel-locations"]:GetChildren()
	for _, location in pairs(locations) do
		local entry = seeds.travel.Location:Clone()
		entry.TitleLabel.Text = location.Name
		entry.Visible = true
		entry.Parent = TravelFrame.Locations
		rx.Observable.from(entry.Activated)
			:subscribe(dart.bind(sendToLocation, location))
	end
end
constructLocations()

-- Set selected location
local function getLocationEntryAtPosition(xy)
	-- return tableau.childrenOfClass(TravelFrame.Locations, "GuiObject")
	-- 	:first(glib.isPointInGuiObject)
	for _, v in pairs(TravelFrame.Locations:GetChildren()) do
		if v:IsA("GuiObject") and glib.isPointInGuiObject(xy, v) then
			return v
		end
	end
end
local function setSelectedLocation(entry)
	for _, v in pairs(TravelFrame.Locations:GetChildren()) do
		if v:IsA("GuiObject") then
			v.ImageTransparency = (v == entry and 0 or 1)
		end
	end
end
rx.Observable.heartbeat()
	:map(function () return UserInputService:GetMouseLocation() end)
	:map(getLocationEntryAtPosition)
	:distinctUntilChanged()
	:subscribe(setSelectedLocation)

-- Set visible
local function setVisible(visible, instant)
	glib.playAnimation(animations.travel[visible and "show" or "hide"], TravelFrame, instant)
end

-- Connect to show / hide
local visibleSubject = rx.BehaviorSubject.new(false)
TravelFrame.Visible = true -- Constantly visible, position controlled by anims
rx.Observable.from(TravelMenuButton.Button.Activated)
	:map(function () return not visibleSubject:getValue() end)
	:merge(glib.getExitStream(TravelFrame):map(dart.constant(false)))
	:subscribe(function (v)
		visibleSubject:push(v)
	end)
visibleSubject:subscribe(setVisible)
visibleSubject:push(false, true)
