--!strict
-- Play-time safety net. Tags and the Lighting folder are authored on the model;
-- this restores them if a place load drops CollectionService tags.
local CollectionService = game:GetService("CollectionService")

local rac = workspace:WaitForChild("RAC")

local lighting = rac:FindFirstChild("Lighting")
if lighting == nil then
	local folder = Instance.new("Folder")
	folder.Name = "Lighting"
	folder.Parent = rac
	local mode = Instance.new("StringValue")
	mode.Name = "MasterMode"
	mode.Value = "normal"
	mode.Parent = folder
end

local function tag(inst: Instance, name: string)
	pcall(function()
		CollectionService:AddTag(inst, name)
	end)
	pcall(function()
		inst:AddTag(name)
	end)
end

for _, inst in rac:GetDescendants() do
	if inst:GetAttribute("RAC_Zone") == true then
		tag(inst, "Zone")
	end
	local lightKind = inst:GetAttribute("RAC_Light")
	if type(lightKind) == "string" then
		tag(inst, lightKind)
	end
	if inst:IsA("BasePart") then
		local n = string.lower(inst.Name)
		if
			string.find(n, "tread", 1, true)
			or string.find(n, "landing", 1, true)
			or string.find(n, "bridge", 1, true)
			or string.find(n, "turn", 1, true)
		then
			inst.CanCollide = true
			inst.CanQuery = true
		end
		if inst:GetAttribute("RAC_ClearOpening") == true then
			inst.CanCollide = false
		end
	end
end

local levels = rac:FindFirstChild("Levels")
if levels then
	for _, levelFolder in levels:GetChildren() do
		local stairs = levelFolder:FindFirstChild("Stairs")
		if not stairs then
			continue
		end
		for _, stair in stairs:GetChildren() do
			if stair:GetAttribute("RAC_StairLink") ~= true or stair:FindFirstChild("StairLink") then
				continue
			end
			local low: BasePart? = nil
			local high: BasePart? = nil
			local lowY, highY = math.huge, -math.huge
			for _, d in stair:GetDescendants() do
				if d:IsA("BasePart") and string.find(string.lower(d.Name), "tread", 1, true) then
					local y = d.CFrame.Position.Y
					if y < lowY then
						lowY = y
						low = d
					end
					if y > highY then
						highY = y
						high = d
					end
				end
			end
			if low and high and low ~= high then
				local function attach(part: BasePart, name: string): Attachment
					local att = Instance.new("Attachment")
					att.Name = name
					att.Parent = part
					att.WorldPosition = part.CFrame.Position + Vector3.new(0, 3, 0)
					return att
				end
				local ok, created = pcall(function()
					return Instance.new("PathfindingLink")
				end)
				if ok and typeof(created) == "Instance" then
					created.Name = "StairLink"
					created.Parent = stair
					local anyLink = created :: any
					anyLink.Attachment0 = attach(low, "StairLinkBottom")
					anyLink.Attachment1 = attach(high, "StairLinkTop")
					anyLink.IsBidirectional = true
					anyLink.Label = "Stairs"
				end
			end
		end
	end
end
