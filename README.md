## Summer Camp

This is a repository for the Roblox game Summer Camp, developed by Jackson Munsell and Chris Hyde. All code written by Jackson Munsell.

For this project I created an ECS-style system in Roblox that relies on Instances as entities, and CollectionService tags as components. The components are known as **genes**, and are available in src/genes.
Genes are setup such that both server and client files are stored in a single folder, and the game unpacks those scripts into the appropriate directories during runtime. This is done for happy organizational purposes, to keep related functionality (server and client of same gene) in the same folder.

The game also uses a technique called [Reactive Programming](https://reactivex.io/), which is not the same as React/Roact. Reactive programming is an event-based programming style that uses modifiable streams as objects, similar to functional programming.

The result is very interesting, and allows for code to be written like the following, which prints every time the local character dies:

``` lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local rx = require(ReplicatedStorage.rx)
local dart = require(ReplicatedStorage.dart)

rx.Observable.from(Players.LocalPlayer.CharacterAdded)
  :startWith(Players.LocalPlayer.Character)
  :filter()
  :map(dart.waitForChild("Humanoid"))
  :switchMap(function(hum) return rx.Observable.from(hum.Died) end)
  :subscribe(function() print("LocalPlayer humanoid just died.") end)
```
