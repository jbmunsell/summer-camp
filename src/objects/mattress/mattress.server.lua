--
--	Jackson Munsell
--	11 Oct 2020
--	mattress.server.lua
--
--	Mattress server driver. Adds interactable tag to all mattresses
--

-- env
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local objects = env.src.objects
local interact = objects.interact
local mattress = objects.mattress

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local objectsUtil = require(objects.util)
local interactUtil = require(interact.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Get client mattress
local function getClientMattress(client)
	return objectsUtil.getObjects(mattress)
		:first(function (instance)
			return instance.state.mattress.owner.Value == client
		end)
end

-- Release mattress
local function releaseMattress(mattressInstance)
	mattressInstance.state.owner.Value = nil
	interactUtil.setInteractEnabled(mattressInstance, true)
end

-- Grant mattress ownership
local function grantMattressOwnership(client, mattressInstance)
	-- Assert humanoid
	local humanoid = axisUtil.getPlayerHumanoid(client)
	if not humanoid then return end

	-- Change value
	mattressInstance.state.owner.Value = client
	interactUtil.setInteractEnabled(mattressInstance, false)

	-- Hold it with a bin
	local function filterFromClient(obs)
		return obs:filter(dart.equals(client))
	end
	local playerLeftGame = filterFromClient(rx.Observable.from(Players.PlayerRemoving))
	local playerLeftMattress = filterFromClient(rx.Observable.from(mattress.net.Abandoned))
	rx.Observable.fromInstanceLeftGame(humanoid)
		:merge(playerLeftGame, playerLeftMattress)
		:map(dart.constant(mattressInstance))
		:first()
		:subscribe(releaseMattress)
end

---------------------------------------------------------------------------------------------------
-- Streams and subscriptions
---------------------------------------------------------------------------------------------------

-- Init mattresses to make them interactable
objectsUtil.initObjectClass(mattress)

-- Occupy mattresses when a player interacts
rx.Observable.from(mattress.net.Claimed)
	:reject(function (client, mattressInstance)
		return getClientMattress(client) or mattressInstance.state.mattress.owner.Value
	end)
	:subscribe(grantMattressOwnership)
