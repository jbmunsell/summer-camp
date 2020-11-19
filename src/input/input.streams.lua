--
--	Jackson Munsell
--	16 Oct 2020
--	inputStreams.lua
--
--	Client input streams collection
--

-- env
local UserInputService = game:GetService("UserInputService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)

-- streams
local clickStream = rx.Observable.from(UserInputService.InputBegan)
	:filter(function (input, processed)
		return not processed and input.UserInputType == Enum.UserInputType.MouseButton1
	end)
	:merge(rx.Observable.from(UserInputService.TouchTapInWorld):tap(print):reject(dart.select(2)))
	:map(dart.constant(nil))

-- return lib
return {
	click = clickStream,
}
