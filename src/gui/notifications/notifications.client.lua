--
--	Jackson Munsell
--	14 Sep 2020
--	notifications.client.lua
--
--	CoreGui.Notifications driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local notifications = env.src.gui.notifications

-- modules
local rx   = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local glib = require(axis.lib.glib)
local notificationsConfig = require(notifications.config)

-- instances
local Core = env.PlayerGui:WaitForChild("Core")
local seeds = Core.seeds
local animations = Core.animations

-- is core enabled
local function isCoreEnabled()
	return Core.Enabled
end

-- Destroy notification
local function killNotification(notification)
	glib.playAnimation(animations.notifications.hide, notification)
		:subscribe(dart.destroy)
end

-- Notify
local function notify(message)
	-- Create and configure new notification
	local notification = seeds.notifications.Notification:Clone()
	notification.Visible = true
	notification.TextLabel.Text = message

	-- Close stream
	glib.getExitStream(notification)
		:merge(rx.Observable.timer(notificationsConfig.duration))
		:first()
		:subscribe(dart.bind(killNotification, notification))

	-- Start springing and set parent
	glib.playAnimation(animations.notifications.show, notification)
	notification.Parent = Core.Container
end

-- Notification factory stream
rx.Observable.from(notifications.net.Push)
	:filter(isCoreEnabled)
	:subscribe(notify)
