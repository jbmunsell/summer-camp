--
--	Jackson Munsell
--	13 Nov 2020
--	gui.client.lua
--
--	Main gui client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

-- modules

-- Show splash screen
env.PlayerGui:WaitForChild("SplashScreen").Enabled = true
