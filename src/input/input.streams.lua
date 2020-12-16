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

-- module
local inputStreams = {}

-- streams
inputStreams.click = rx.Observable.from(UserInputService.InputBegan)
	:filter(function (input, processed)
		return not processed
		and (input.UserInputType == Enum.UserInputType.MouseButton1
		or   input.KeyCode == Enum.KeyCode.ButtonR2)
	end)
	:merge(rx.Observable.from(UserInputService.TouchTapInWorld):reject(dart.select(2)))

-- activation ended
inputStreams.activationEnded = rx.Observable.from(UserInputService.InputEnded)
	:filter(function (input)
		return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
	end)

-- Gamepads enabled subject
inputStreams.gamepadEnabled = rx.Observable.from(UserInputService.GamepadConnected)
	:merge(rx.Observable.from(UserInputService.GamepadConnected))
	:startWith(0)
	:map(function () return UserInputService.GamepadEnabled end)
	:multicast(rx.BehaviorSubject.new())

-- return lib
return inputStreams
