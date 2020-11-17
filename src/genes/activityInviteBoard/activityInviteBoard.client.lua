--
--	Jackson Munsell
--	16 Nov 2020
--	activityInviteBoard.client.lua
--
--	activityInviteBoard gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Accessors
local function getInviteButton(instance)
	return instance:FindFirstChild("InviteButton", true)
end
local function getCooldownLabel(instance)
	return instance:FindFirstChild("CooldownLabel", true)
end
local function hasLocalTeamStamp(instance)
	return instance.state.activityInviteBoard.inviteStamps:FindFirstChild(env.LocalPlayer.Team.Name)
end

-- Setters
local function setInviteButtonVisible(instance, visible)
	getInviteButton(instance).Visible = visible
end
local function setCooldownLabelText(instance, text)
	getCooldownLabel(instance).Text = text
end

-- Get local team's cooldown for an instance
local function getLocalTeamCooldown(instance)
	local stamp = instance.state.activityInviteBoard.inviteStamps[env.LocalPlayer.Team.Name].Value
	return (stamp + instance.config.activityInviteBoard.inviteCooldown.Value) - os.time()
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
local boards = genesUtil.initGene(genes.activityInviteBoard)

-- Set cooldown text according to cooldown
local cooldownStream = boards
	:flatMap(function (instance)
		return rx.Observable.heartbeat()
			:map(dart.constant(instance))
			:filter(hasLocalTeamStamp)
			:map(getLocalTeamCooldown)
			:map(math.floor)
			:distinctUntilChanged()
			:map(dart.carry(instance))
	end)
cooldownStream
	:map(function (v, cooldown) return v, cooldown < 0 end)
	:subscribe(setInviteButtonVisible)
cooldownStream
	:reject(function (_, cooldown) return cooldown < 0 end)
	:subscribe(setCooldownLabelText)

-- Forward input from invite button to server
boards:flatMap(function (instance)
	return rx.Observable.from(getInviteButton(instance).Activated)
		:map(dart.constant(instance))
end):tap(print):subscribe(dart.forward(genes.activityInviteBoard.net.InviteSendRequested))
