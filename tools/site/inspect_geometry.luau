--!strict
local fs = require("@lune/fs")
local r = require("@lune/roblox")
local m = r.deserializeModel(fs.readFile("verification/exterior/building_preview.rbxm"))[1]
for _, p in m:GetDescendants() do
	if
		p:IsA("BasePart")
		and (
			p.Parent.Name == "w049"
			or p.Parent.Name == "w044"
			or (p.Parent.Name == "Skin" and p.Parent.Parent.Name == "Facade_10")
		)
	then
		print(p:GetFullName(), p.CFrame.Position, p.Size, p.CFrame.RightVector)
	end
end
