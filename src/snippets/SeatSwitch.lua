for _, seat in pairs(workspace:GetDescendants()) do
	if seat:IsA("Seat") and not seat:IsDescendantOf(workspace.Map.Vehicles) then
		local part = Instance.new("Part")
		part.Transparency = seat.Transparency
		part.Size = seat.Size
		part.CFrame = seat.CFrame
		part.Name = seat.Name
		part.Anchored = seat.Anchored
		part.CanCollide = seat.CanCollide
		game:GetService("CollectionService"):AddTag(part, "gene_seat")
		workspace.Terrain.WaistBackAttachment:Clone().Parent = part
		part.Parent = seat.Parent
		seat:Destroy()
	end
end