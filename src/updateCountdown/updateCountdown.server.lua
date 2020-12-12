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

local UpdateTimestamp = 1608393600
local countdownLabel = workspace.UpdateCountdown:FindFirstChild("CountdownLabel", true)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

rx.Observable.heartbeat():subscribe(function ()
	local remaining = UpdateTimestamp - tick()
	local seconds = math.floor(remaining) % 60
	local minutes = math.floor(remaining / 60) % 60
	local hours = math.floor(remaining / (60 * 60)) % 24
	local days = math.floor(remaining / (60 * 60 * 24))
	countdownLabel.Text = string.format("%02d:%02d:%02d:%02d", days, hours, minutes, seconds)
end)
