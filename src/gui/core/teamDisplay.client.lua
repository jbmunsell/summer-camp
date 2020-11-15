--
--	Jackson Munsell
--	14 Nov 2020
--	teamDisplay.client.lua
--
--	Team display gui driver
--

-- env
local Teams = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Instances
---------------------------------------------------------------------------------------------------

local ClickToChangeStayTime = 10
local ClickToChangeTweenInfo = TweenInfo.new(0.5)

local core = env.PlayerGui:WaitForChild("Core")
local teamDisplay = core:FindFirstChild("TeamDisplay", true)

do
	local actionText = (UserInputService.TouchEnabled and "Touch" or "Click")
	teamDisplay.Button.ClickToChange.Text = actionText .. " to change"
end

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Show change text
local function showChangeText()
	local label = teamDisplay.Button.ClickToChange
	label.TextTransparency = 0
	rx.Observable.timer(ClickToChangeStayTime):subscribe(function ()
		TweenService:Create(label, ClickToChangeTweenInfo, { TextTransparency = 1 }):Play()
	end)
end

-- Update team image
local function updateTeamImage()
	teamDisplay.Button.Image = env.config.teams[env.LocalPlayer.Team.Name].image.Value
end

-- Update counselor list
local function updateCounselorList()
	-- Get counselors
	local team = env.LocalPlayer.Team
	local counselors = genesUtil.getInstances(genes.player.counselor)
		:filter(function (p)
			return p.Team == team and p.state.counselor.isCounselor.Value
		end)

	-- Destroy old
	for _, instance in pairs(teamDisplay.Labels:GetChildren()) do
		if instance:IsA("GuiObject") and instance.Name ~= "Title" then
			instance:Destroy()
		end
	end

	-- Create new
	counselors:foreach(function (player)
		local label = core.seeds.teamDisplay.CounselorLabel:Clone()
		label.Text = player.Name
		label.Visible = true
		label.Parent = teamDisplay.Labels
	end)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Team changed
local teamChanged = rx.Observable.fromProperty(env.LocalPlayer, "Team", true)
	:reject(dart.equals(Teams["New Arrivals"]))
teamChanged:subscribe(updateTeamImage)
teamChanged:subscribe(showChangeText)

-- Counselors changed
local counselorsChanged = genesUtil.observeStateValue(genes.player.counselor, "isCounselor")
counselorsChanged:merge(teamChanged):subscribe(updateCounselorList)