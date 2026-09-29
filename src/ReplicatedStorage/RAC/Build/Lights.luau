--!strict
-- Legacy per-level lights folder. Build.luau uses Lighting.build (workspace.RAC.Lighting).
-- Keep this module as a sparse fallback so a second dense grid cannot be spawned.
local Blueprint = require(script.Parent.Blueprint)
local Geometry = require(script.Parent.Geometry)
local PropRegistry = require(script.Parent.PropRegistry)

local Lights = {}

local function bounds(poly: Blueprint.Polygon): (number, number, number, number)
	local x0, x1 = math.huge, -math.huge
	local z0, z1 = math.huge, -math.huge
	for _, p in poly do
		x0 = math.min(x0, p[1])
		x1 = math.max(x1, p[1])
		z0 = math.min(z0, p[2])
		z1 = math.max(z1, p[2])
	end
	return x0, x1, z0, z1
end

local function place(parent: Instance, room: Blueprint.Room, kind: string, x: number, y: number, z: number)
	local model = PropRegistry.build(kind, CFrame.new(x, y, z), nil)
	model.Name = kind
	model:SetAttribute("Room", room.id)
	model.Parent = parent
	for _, desc in model:GetDescendants() do
		if desc:IsA("Light") then
			desc.Enabled = true
			desc.Shadows = false
		end
	end
end

local function scatter(parent: Instance, room: Blueprint.Room, kind: string, y: number, spacing: number, limit: number)
	local x0, x1, z0, z1 = bounds(room.polygon)
	local inset = math.min(spacing * 0.45, 8)
	local placed = 0
	local x = x0 + inset
	while x < x1 - 1 and placed < limit do
		local z = z0 + inset
		while z < z1 - 1 and placed < limit do
			if Geometry.contains(room.polygon, x, z) then
				place(parent, room, kind, x, y, z)
				placed += 1
			end
			z += spacing
		end
		x += spacing
	end
end

local function fixtures(folder: Instance, room: Blueprint.Room, roomType: string, floorY: number, ceilY: number)
	if roomType == "gym" or room.id == "cage_gym" then
		scatter(folder, room, "high_bay_light", floorY + 18, 32, 16)
	elseif roomType == "stair" then
		scatter(folder, room, "downlight", floorY + 8, 12, 4)
	elseif roomType == "lobby" or room.id == "south_vestibule" then
		scatter(folder, room, "downlight", math.min(ceilY - 2, floorY + 12), 18, 6)
	elseif roomType == "corridor" then
		scatter(folder, room, "troffer_2x4", ceilY - 0.5, 16, 8)
	elseif room.ceilingType ~= "none" then
		scatter(folder, room, "troffer_2x2", ceilY - 0.45, 12, 8)
	end
end

function Lights.build(parent: Instance, level: Blueprint.Level)
	-- Skip if Lighting.build already filled workspace.RAC.Lighting.
	local rac: Instance? = parent
	while rac ~= nil and rac.Name ~= "RAC" do
		rac = rac.Parent
	end
	if rac ~= nil then
		local existing = rac:FindFirstChild("Lighting")
		if existing and #existing:GetChildren() > 1 then
			return
		end
	end
	local folder = Instance.new("Folder")
	folder.Name = "Lights"
	folder.Parent = parent
	for _, room in level.rooms do
		local roomType: string = room.type
		if roomType == "void" or roomType == "construction" then
			continue
		end
		local x0, x1, z0, z1 = bounds(room.polygon)
		local tooNarrow = math.min(x1 - x0, z1 - z0) < 6
		if tooNarrow and roomType ~= "stair" then
			continue
		end
		local floorY = level.elevation
		fixtures(folder, room, roomType, floorY, floorY + room.ceilingHeight)
	end
end

return Lights
