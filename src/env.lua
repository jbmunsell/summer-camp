--
--	Jackson Munsell
--	24 Jul 2020
--	env.lua
--
--	Holds some key environment variables
--

-- services
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts

-- table
local env = {}
env.res = ReplicatedStorage.res
env.packages = ReplicatedStorage.packages

-- Distribute on server startup
if RunService:IsServer() then
	-- Staging area for server scripts so that they don't run until we're finished
	local serverStaging = Instance.new("Folder")

	-- Distribute source files to respective directories
	local function fetchDistributedDir(dest, instance)
		-- Build lineage
		local line = {}
		while instance.Parent ~= ServerStorage do
			-- print("Full name: ", instance:GetFullName())
			instance = instance.Parent
			table.insert(line, 1, instance)
		end
		-- print("Created whole lineage")
		for _, folder in pairs(line) do
			local walker = dest:FindFirstChild(folder.Name)
			if not walker then
				walker = Instance.new("Folder", dest)
				walker.Name = folder.Name
			end
			dest = walker
		end
		return dest
	end
	local function distribute(dir)
		for _, instance in pairs(dir:GetChildren()) do
			local dest

			if string.sub(instance.Name, 1, 2) ~= "--" then
				local folderNamePattern = "([^%.]*)"
				if instance.Name == instance.Parent.Name then
					if instance:IsA("LocalScript") then
						instance.Name = "client"
					elseif instance:IsA("Script") then
						instance.Name = "server"
					end
				elseif string.match(instance.Name, folderNamePattern) == instance.Parent.Name then
					instance.Name = string.gsub(instance.Name, "([^%.]*%.)", "")
				end

				if instance:IsA("Folder") then
					distribute(instance)
				elseif instance:IsA("LocalScript") then
					dest = StarterPlayerScripts
				elseif instance:IsA("Script") then
					Instance.new("StringValue", instance).Name = "ShouldEnable"
					instance.Disabled = true
					dest = serverStaging
				else
					dest = ReplicatedStorage
				end

				if dest then
					instance.Parent = fetchDistributedDir(dest, instance)
				end
			end
		end
	end
	distribute(ServerStorage.src)

	-- Place server staging contents into server script service so that they can run
	for _, child in pairs(serverStaging:GetChildren()) do
		child.Parent = ServerScriptService
	end
	for _, s in pairs(ServerScriptService:GetDescendants()) do
		spawn(function ()
			if s:IsA("Script") and s:FindFirstChild("ShouldEnable") then
				s.ShouldEnable:Destroy()
				s.Disabled = false
			end
		end)
	end
end

-- Add special locations
local locations = { ReplicatedStorage.src }
if RunService:IsServer() then
	table.insert(locations, game:GetService("ServerScriptService").src)
elseif RunService:IsClient() then
	local localPlayer = game:GetService("Players").LocalPlayer
	local playerScripts = localPlayer:WaitForChild("PlayerScripts")
	table.insert(locations, playerScripts:WaitForChild("src"))
	env.LocalPlayer = localPlayer
	env.PlayerGui = localPlayer:WaitForChild("PlayerGui")
end

-- Iterate all locations and build reference table according to functional bundles
local index_mt = {
	__index = function (self, str)
		local dirLocations = rawget(self, "__locations")
		for _, location in pairs(dirLocations) do
			local instance = location:FindFirstChild(str)
			if instance then
				if instance:IsA("Folder") then
					return rawget(self, instance.Name)
				end
				return instance
			end
		end
		local locationNames = {}
		for _, l in pairs(dirLocations) do
			table.insert(locationNames, l:GetFullName())
		end
		local locs = table.concat(locationNames, "\n\t")
		error("Unable to find child '" .. str .. "' of directory. Locations:\n\t" .. locs)
	end,
	__tostring = function (self)
		return rawget(self, "__locations")[1]:GetFullName()
	end,
}
local function index(instance, envLayer)
	if instance:IsA("Folder") then
		if not envLayer[instance.Name] then
			envLayer[instance.Name] = setmetatable({
				__locations = { instance },
			}, index_mt)
		else
			table.insert(rawget(envLayer[instance.Name], "__locations"), instance)
		end
		for _, child in pairs(instance:GetChildren()) do
			index(child, envLayer[instance.Name])
		end
	end
end
for _, src in pairs(locations) do
	index(src, env)
end

-- return table
return env
