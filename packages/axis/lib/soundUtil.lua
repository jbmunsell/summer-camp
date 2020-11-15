--
--	Jackson Munsell
--	31 Oct 2020
--	soundUtil.lua
--
--	Sound util
--

-- modules

-- lib
local soundUtil = {}

-- Play random from a group
function soundUtil.playRandom(container, parent)
	local sounds = {}
	for _, child in pairs(container:GetChildren()) do
		if child:IsA("Sound") then
			table.insert(sounds, child)
		end
	end
	local sound = sounds[math.random(1, #sounds)]
	soundUtil.playSound(sound, parent)
end

-- Play sound in a part and clean up after
function soundUtil.playSound(sound, parent)
	sound = sound:Clone()
	sound.Parent = parent
	sound.Ended:Connect(function ()
		sound:Destroy()
	end)
	sound:Play()
	return sound
end

-- return lib
return soundUtil
