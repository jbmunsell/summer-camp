--
--	Jackson Munsell
--	12 Dec 2020
--	updateCountdown.server.lua
--
--	Update countdown server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local rx = require(axis.lib.rx)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local UpdateTimestamp = 1608480000 - (4 * 60 * 60)
local countdownLabel = workspace.UpdateCountdown:FindFirstChild("CountdownLabel", true)
local daysLabel = workspace.UpdateCountdown:FindFirstChild("DaysLabel", true)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

rx.Observable.heartbeat():subscribe(function ()
	local remaining = UpdateTimestamp - tick()
	local seconds = math.floor(remaining) % 60
	local minutes = math.floor(remaining / 60) % 60
	local hours = math.floor(remaining / (60 * 60)) % 24
	local days = math.floor(remaining / (60 * 60 * 24))
	daysLabel.Text = (days == 0 and "TODAY!" or string.format("%d day%s", days, (days == 1 and "" or "s")))
	countdownLabel.Text = string.format("%02d:%02d:%02d", hours, minutes, seconds)
end)
