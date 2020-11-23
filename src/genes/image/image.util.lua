--
--	Jackson Munsell
--	00 Mon 2020
--	image.util.lua
--
--	image gene util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)

-- lib
local imageUtil = {}

-- init instance
function imageUtil.initInstance(instance)
	genesUtil.readConfigIntoState(instance, "image", "image")
	rx.Observable.from(instance.state.image.image)
		:map(dart.carry(instance))
		:subscribe(imageUtil.renderImage)
end

-- render image
function imageUtil.renderImage(instance, image)
	for _, d in pairs(instance:GetDescendants()) do
		if d.Name == "autoImageProperty" then
			d.Parent[d.Value] = image
		end
	end
end

-- return lib
return imageUtil
