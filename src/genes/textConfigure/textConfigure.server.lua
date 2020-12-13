--
--	Jackson Munsell
--	23 Nov 2020
--	textConfigure.server.lua
--
--	textConfigure gene server driver
--

-- env
local TextService = game:GetService("TextService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local genesUtil = require(genes.util)
local textConfigureUtil = require(genes.textConfigure.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Filter player text
local function filterPlayerText(player, text)
	local filteredMessage = "Text filtering error :/"
	local success, e = pcall(function ()
		local textObject = TextService:FilterStringAsync(text, player.UserId)
		filteredMessage = textObject:GetNonChatStringForBroadcastAsync()
	end)
	if not success then
		warn("Caught error:")
		warn(e)
	end
	return filteredMessage
end

-- Configure instance from player
local function configureInstanceFromPlayer(player, instance, text)
	local result = (instance.config.textConfigure.shouldFilter.Value and filterPlayerText(player, text) or text)
	instance.state.textConfigure.text.Value = result
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.textConfigure):subscribe(function (instance)
	genesUtil.readConfigIntoState(instance, "textConfigure", "text")
end)

-- When text is changed, render autos
genesUtil.observeStateValue(genes.textConfigure, "text"):subscribe(textConfigureUtil.renderText)

-- When player requests text change, filter and pass to state.
-- 	Extended genes will listen to the state value of this gene on their instance.
rx.Observable.from(genes.textConfigure.net.ConfigureRequested)
	:filter(function (player, instance)
		return instance.state.pickup.owner.Value == player
	end)
	:subscribe(configureInstanceFromPlayer)
