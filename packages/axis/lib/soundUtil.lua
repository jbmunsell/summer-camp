--
--	Jackson Munsell
--	31 Oct 2020
--	soundUtil.lua
--
--	Sound util
--

-- modules
local CollectionService = game:GetService("CollectionService")

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
function soundUtil.playSoundGlobal(sound)
	return soundUtil.playSound(sound, workspace)
end

-- Play sound at point
function soundUtil.playSoundAtPoint(sound, point)
	local p = Instance.new("Part")
	CollectionService:AddTag(p, "FXPart")
	p.CanCollide = false
	p.Anchored = true
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.CFrame = CFrame.new(point)
	p.Parent = workspace
	local soundInstance = soundUtil.playSound(sound, p)
	soundInstance.Ended:Connect(function ()
		p:Destroy()
	end)
end

-- return lib
return soundUtil
