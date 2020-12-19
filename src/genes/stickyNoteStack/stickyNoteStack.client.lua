--
--	Jackson Munsell
--	20 Oct 2020
--	stickyNoteStack.client.lua
--
--	Sticky note stack client driver. Places on click.
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local pickup = genes.pickup

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local pickupUtil = require(pickup.util)
local genesUtil = require(genes.util)
local textConfigureUtil = require(genes.textConfigure.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.stickyNoteStack)

-- Update preview text
pickupUtil.getLocalCharacterHoldingStream(genes.stickyNoteStack):switchMap(function (instance)
	return instance
		and rx.Observable.from(instance.interface.worldAttach.PreviewCreated)
			:map(dart.carry(instance))
		or rx.Observable.never()
end):switchMap(function (instance, preview)
	return rx.Observable.from(instance.state.textConfigure.text)
		:map(dart.carry(preview))
		:takeUntil(rx.Observable.fromInstanceLeftGame(preview))
end):subscribe(function (preview, text)
	textConfigureUtil.renderText(preview, text)
end)
