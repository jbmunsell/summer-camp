--
--	Jackson Munsell
--	22 Nov 2020
--	itemRestock.server.lua
--
--	itemRestock gene server driver
--

-- env
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local storage = Instance.new("Folder", ReplicatedStorage)
storage.Name = "itemStockStorage"
genesUtil.initGene(genes.itemRestock):subscribe(function (instance)
	local stockValue = instance.state.itemRestock.stock
	if not stockValue.Value then
		local stock = instance:Clone()
		stock.state.itemRestock.stock.Value = stock
		stock.Parent = storage
		stockValue.Value = stock
	end
	local parent = instance.Parent
	rx.Observable.fromInstanceLeftGame(instance):subscribe(function ()
		local new = stockValue.Value:Clone()
		new.state.itemRestock.stock.Value = stockValue.Value
		new.Parent = parent
	end)
end)
