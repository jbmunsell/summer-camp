--
--	Jackson Munsell
--	15 Nov 2020
--	activityInvites.client.lua
--
--	Activity invites gui driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local glib = require(axis.lib.glib)
local activityUtil = require(genes.activity.util)

---------------------------------------------------------------------------------------------------
-- Instances
---------------------------------------------------------------------------------------------------

local coreGui = env.PlayerGui:WaitForChild("Core")

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function teleportPlayer(boardInstance)
	local character = env.LocalPlayer.Character
	if not character then return end
	character:SetPrimaryPartCFrame(boardInstance:FindFirstChild("TeleportSpawn", true).CFrame)
end

local function killInvite(invite)
	glib.playAnimation(coreGui.animations.activityPrompt.hide, invite):subscribe(dart.destroy)
end

local function showActivityInvite(boardInstance, sender)
	-- Create invite
	local config = boardInstance.config.activityInviteBoard
	local invite = coreGui.seeds.activityPrompt.CasualActivityPrompt:Clone()

	-- Configure
	invite:FindFirstChild("SenderLabel", true).Text = string.format("Invited by %s", sender.Name)
	invite:FindFirstChild("MainLabel", true).Text = config.activityDisplayName.Value
	for _, child in pairs(invite:FindFirstChild("BackgroundImages", true):GetChildren()) do
		if child:IsA("GuiObject") then
			child.Visible = (child.Name == config.activityDisplayName.Value)
		end
	end

	-- Subscribe to join click
	local joinClicked = rx.Observable.from(invite:FindFirstChild("JoinButton", true).Activated)
	joinClicked
		:merge(glib.getExitStream(invite), rx.Observable.timer(10))
		:subscribe(dart.bind(killInvite, invite))
	joinClicked:subscribe(dart.bind(teleportPlayer, boardInstance))

	-- Play animation
	glib.playAnimation(coreGui.animations.activityPrompt.show, invite)
	invite.Parent = coreGui
	invite.Visible = true
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- From invite sent stream
rx.Observable.from(genes.activityInviteBoard.net.InviteSent)
	:reject(dart.bind(activityUtil.isPlayerCompeting, env.LocalPlayer))
	:subscribe(showActivityInvite)
