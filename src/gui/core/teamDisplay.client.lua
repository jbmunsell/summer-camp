--
--	Jackson Munsell
--	14 Nov 2020
--	teamDisplay.client.lua
--
--	Team display gui driver
--

-- env
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
local function setTeam(team)
	genesUtil.waitForGene(teamDisplay, genes.teamLink)
	teamDisplay.state.teamLink.team.Value = team
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Team changed
local teamChanged = rx.Observable.fromProperty(env.LocalPlayer, "Team", true)
	:filter(function (team)
		return genesUtil.hasGeneTag(team, genes.team)
	end)
teamChanged:subscribe(setTeam)
teamChanged:subscribe(showChangeText)
