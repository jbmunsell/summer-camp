--
--	Jackson Munsell
--	24 Aug 2020
--	CharacterTagService.lua
--
--	axis service that tags all player characters with the PlayerCharacter tag.
-- 		PlayerIndicatorHandler uses this tag to ignore player characters from raycasting.
--

-- modules
local rx = require(script.Parent.Parent.lib.rx)

-- services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

-- consts
local CharacterTag = "PlayerCharacter"

-- return main
return function ()
	print("Running axis CharacterTagService")
	rx.Observable.from(Players.PlayerAdded)
		:flatMap(function (player)
			return rx.Observable.fromInstanceEvent(player, "CharacterAdded")
				:startWith(player.Character)
				:filter()
		end)
		:subscribe(function (character)
			CollectionService:AddTag(character, CharacterTag)
		end)
end
