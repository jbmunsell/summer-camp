for _, cabin in pairs(workspace.Cabins:GetChildren()) do
	if cabin.Name ~= "Cabin1" then
		local add = workspace.Cabins.Cabin1.Add:Clone()
		local offset = workspace.Cabins.Cabin1.PrimaryPart.CFrame:toObjectSpace(add:GetPrimaryPartCFrame())
		add:SetPrimaryPartCFrame(cabin.PrimaryPart.CFrame:toWorldSpace(offset))
		add.Parent = cabin
	end
end