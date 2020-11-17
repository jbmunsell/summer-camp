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

-- Setters
local function setInviteButtonVisible(instance, visible)
	getInviteButton(instance).Visible = visible
end
local function setCooldownLabelText(instance, text)
	getCooldownLabel(instance).Text = text
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
local boards = genesUtil.initGene(genes.activityInviteBoard)

-- Set cooldown text according to cooldown
local teamChanged = rx.Observable.fromProperty(env.LocalPlayer, "Team")
boards:flatMap(function (instance)
	local stamps = instance.state.activityInviteBoard.inviteStamps
	return rx.Observable.from(stamps.ChildAdded):startWith(stamps:GetChildren())
		:flatMap(function (stamp)
			return rx.Observable.from(stamp):map(dart.constant(stamp))
		end)
		:merge(teamChanged:map(function (team)
			return stamps[team.Name]
		end))
		:filter(function (stamp)
			return stamp.Name == env.LocalPlayer.Team.Name
		end)
		:map(dart.carry(instance))
end):subscribe(function (instance, stamp)
	local hsub
	local cooldown = instance.config.activityInviteBoard.inviteCooldown.Value
	hsub = rx.Observable.heartbeat():subscribe(function ()
		local t = (stamp.Value + cooldown) - os.time()
		setInviteButtonVisible(instance, t <= 0)
		if t > 0 then
			setCooldownLabelText(instance, math.floor(t))
		else
			hsub:complete()
		end
	end)
end)

-- Forward input from invite button to server
boards:flatMap(function (instance)
	return rx.Observable.from(getInviteButton(instance).Activated)
		:map(dart.constant(instance))
end):tap(print):subscribe(dart.forward(genes.activityInviteBoard.net.InviteSendRequested))
