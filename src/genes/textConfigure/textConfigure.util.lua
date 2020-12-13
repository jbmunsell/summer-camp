--
--	Jackson Munsell
--	23 Nov 2020
--	textConfigure.util.lua
--
--	textConfigure gene util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

-- modules

-- lib
local textConfigureUtil = {}

-- render text
function textConfigureUtil.renderText(instance, text)
	text = instance.config.textConfigure.pretext.Value .. text
	for _, d in pairs(instance:GetDescendants()) do
		if d.Name == "autoTextProperty" then
			d.Parent[d.Value] = text
		end
	end
end

-- return lib
return textConfigureUtil
