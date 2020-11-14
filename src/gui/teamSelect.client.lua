--
--	Jackson Munsell
--	13 Nov 2020
--	teamSelect.client.lua
--
--	Team select gui client driver
--

-- env
local Teams = game:GetService("Teams")
local TweenService = game:GetService("TweenService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)

---------------------------------------------------------------------------------------------------
-- Instances
---------------------------------------------------------------------------------------------------

local cameraTweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

local coreGui = env.PlayerGui:WaitForChild("Core")
local splashScreen = env.PlayerGui:WaitForChild("SplashScreen")
local teamSelect = env.PlayerGui:WaitForChild("TeamSelect")
local cameraParts = workspace.cabinCameraParts
local teamImage = teamSelect:FindFirstChild("TeamImage", true)
local coloredInstances = {
	teamSelect:FindFirstChild("JoinButton", true),
	teamSelect:FindFirstChild("ColoredTop", true),
}
local dullInstances = {
	teamSelect:FindFirstChild("DullTop", true),
	teamSelect:FindFirstChild("DullDiamond", true),
}
local labels = {
	teamName = teamSelect:FindFirstChild("TeamNameLabel", true),
	teamDescription = teamSelect:FindFirstChild("TeamDescriptionLabel", true),
}

local inspectingTeam = rx.BehaviorSubject.new(Teams.Lupus)

local TeamsList = {
	Teams.Lupus,
	Teams.Strix,
	Teams.Scorpius,
	Teams.Felis,
}

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Set inspecting team
local function renderInspectingTeam(team)
	-- Get config
	local config = env.config.cabins[team.Name]
	local color = config.color.Value
	local dullColor do
		local h, s, v = color:ToHSV()
		dullColor = Color3.fromHSV(h, s, v - 0.3)
	end

	-- Tween camera
	local part = cameraParts[team.Name]
	TweenService:Create(workspace.CurrentCamera, cameraTweenInfo, { CFrame = part.CFrame }):Play()

	-- Set labels
	labels.teamName.Text = team.Name
	labels.teamDescription.Text = config.description.Value

	-- Set gui colors
	teamImage.Image = config.image.Value
	for _, instance in pairs(coloredInstances) do
		instance.BackgroundColor3 = color
	end
	for _, instance in pairs(dullInstances) do
		instance.BackgroundColor3 = dullColor
	end
end

-- Shift inspecting team
local function shiftInspectingTeam(delta)
	local index = table.find(TeamsList, inspectingTeam:getValue())
	inspectingTeam:push(TeamsList[(index - 1 + delta) % #TeamsList + 1])
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Connect to arrows to switch team
local function arrowToShift(arrowName, delta)
	return rx.Observable.from(teamSelect:FindFirstChild(arrowName, true).Activated)
		:map(dart.constant(delta))
end
arrowToShift("LeftArrow", -1)
	:merge(arrowToShift("RightArrow", 1))
	:subscribe(shiftInspectingTeam)

-- Connect to gui enabled
local enableStream = rx.Observable.fromProperty(splashScreen, "Enabled")
	:reject()
	:first()
	:merge(rx.Observable.from(coreGui:FindFirstChild("ChangeTeam", true).Button.Activated))
	:reject(function () return teamSelect.Enabled end)
enableStream:subscribe(function ()
	-- Create terminator
	teamSelect.Enabled = true
	local terminator = rx.Observable.fromProperty(teamSelect, "Enabled"):reject():first()

	-- Seize camera and hide core
	coreGui.Enabled = false
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	terminator:subscribe(function ()
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	end)

	-- Render on change
	inspectingTeam:takeUntil(terminator):subscribe(renderInspectingTeam)

	-- Send join request on click
	rx.Observable.from(teamSelect:FindFirstChild("JoinButton", true).Activated)
		:first()
		:mapToLatest(inspectingTeam)
		:subscribe(function (...)
			teamSelect.Enabled = false
			coreGui.Enabled = true
			env.src.genes.player.team.net.TeamChangeRequested:FireServer(...)
		end)
end)
