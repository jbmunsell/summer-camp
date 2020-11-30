--
--	Jackson Munsell
--	24 Nov 2020
--	captureTheFlag.client.lua
--
--	captureTheFlag gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local genesUtil = require(genes.util)
local activityUtil = require(genes.activity.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function renderFlags(activityInstance)
	local localTeam = env.LocalPlayer.Team
	local sessionTeams = activityInstance.state.activity.sessionTeams
	print("showing flags")
	for i = 1, 2 do
		local team = sessionTeams[i].Value
		local flag = activityInstance["Flag" .. i]
		local gui = flag:FindFirstChildWhichIsA("BillboardGui", true)
		gui.Enabled = true
		gui.Frame.TeamImage.Image = team.config.team.image.Value
		gui.Frame.TeamImage.TextLabel.Text = (team == localTeam and "Defend" or "Capture")
		flag.state.interact.switches.captureTheFlag.Value = (team ~= localTeam)
	end
end

local function hideFlags(activityInstance)
	print("hiding flags")
	for i = 1, 2 do
		local flag = activityInstance["Flag" .. i]
		flag:FindFirstChildWhichIsA("BillboardGui", true).Enabled = false
		flag.state.interact.switches.captureTheFlag.Value = false
	end
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.activity.captureTheFlag)

-- When a new one starts, link up the flags
local function getLocalPlayerStream(f)
	return f(genes.activity.captureTheFlag)
		:filter(function (_, player) return player == env.LocalPlayer end)
end
getLocalPlayerStream(activityUtil.getPlayerAddedToRosterStream):subscribe(renderFlags)
getLocalPlayerStream(activityUtil.getPlayerRemovedFromRosterStream):subscribe(hideFlags)
