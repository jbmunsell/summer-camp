--
--	Jackson Munsell
--	18 Nov 2020
--	adminPanel.client.lua
--
--	Admin panel gui client driver
--

-- env
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local rx = require(axis.lib.rx)
local glib = require(axis.lib.glib)
local collection = require(axis.lib.collection)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local adminPanel = env.PlayerGui:WaitForChild("AdminPanel")
local toggleVisibilityButton = adminPanel:FindFirstChild("VisibilityToggle", true)

-- Early assertion of admin status
if not collection.getValue(env.config.admins, env.LocalPlayer.UserId) then
	adminPanel:Destroy()
	return
else
	glib.clearLayoutContents(adminPanel.Container.Data)
	adminPanel.Enabled = true
end

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function toggleVisibility()
	adminPanel.Container.Visible = not adminPanel.Container.Visible
end

local function setButtonText(visible)
	toggleVisibilityButton.Text = (visible and "-" or "+")
end

local function createValueLabel(tracker)
	-- Clone label
	local label = adminPanel.seeds.DataLabel:Clone()

	-- Bind to value
	rx.Observable.from(tracker):subscribe(function (v)
		label.Text = string.format("%s: %s", tracker.Name, tostring(v))
	end)

	-- Present
	label.Parent = adminPanel.Container.Data
	label.Visible = true
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Toggle visibility on button clicked
rx.Observable.from(toggleVisibilityButton.Activated):subscribe(toggleVisibility)
rx.Observable.fromProperty(adminPanel.Container, "Visible", true):subscribe(setButtonText)

-- Bind labels to values
rx.Observable.from(ReplicatedStorage.debug.data:GetChildren()):subscribe(createValueLabel)
