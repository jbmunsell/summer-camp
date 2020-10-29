--
--	Jackson Munsell
--	11 Oct 2020
--	mattress.client.lua
--
--	Mattress client driver. Binds to spacebar to jump out of mattress when you enter it
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local CollectionService = game:GetService("CollectionService")
local axis = env.packages.axis
local interact = env.src.objects.interact
local mattress = env.src.objects.mattress

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local interactUtil = require(interact.util)
local mattressConfig = require(mattress.config)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Set all mattresses interact enabled
local function setMattressesInteractEnabled(enabled)
	for _, mattressInstance in pairs(CollectionService:GetTagged(mattressConfig.instanceTag)) do
		interactUtil.setInteractEnabled(mattressInstance, enabled)
	end
end

-- Lay on mattress
local function layOnMattress(mattressInstance)
	-- Get low back attachment points
	local character = env.LocalPlayer.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	if not humanoid then return end
	-- Disable mattress interaction
	setMattressesInteractEnabled(false)

	-- Send to server
	mattress.net.Claimed:FireServer(mattressInstance)

	-- Create a weld and tween the weld
	local weld = axisUtil.smoothAttach(mattressInstance, character,
		"WaistBackAttachment", mattressConfig.layTweenInfo)

	-- Set humanoid to sitting to enable jump events
	-- Here we stop all animation tracks to disable the sitting animation
	humanoid.Sit = true
	delay(0.2, function ()
		for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
			track:Stop()
		end
	end)

	-- Create a bin for this laying session to dump on jump
	rx.Observable.from(humanoid.Jumping)
		:filter()
		:first()
		:subscribe(function ()
			weld:Destroy()
			mattress.net.Abandoned:FireServer(mattressInstance)
			setMattressesInteractEnabled(true)
		end)
end

---------------------------------------------------------------------------------------------------
-- Streams and subscriptions
---------------------------------------------------------------------------------------------------

-- Bind to mattress interacted
interactUtil.getInteractStream(mattress)
	:map(dart.omitFirst)
	:subscribe(layOnMattress)
