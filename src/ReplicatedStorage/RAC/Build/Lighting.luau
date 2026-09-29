--!strict
-- Room fixtures parented at workspace.RAC.Lighting so LightingController can bind.
-- Gyms: high-bays about every 20 ft. Corridors and rooms: troffers about every 8 ft.
-- Lobby: downlights plus a few pendants. Stairs: cans along the going, not one high plane.
local Blueprint = require(script.Parent.Blueprint)
local Geometry = require(script.Parent.Geometry)
local PropRegistry = require(script.Parent.PropRegistry)

local Lighting = {}

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

local function tune(model: Instance, zone: string)
	for _, desc in model:GetDescendants() do
		if desc:IsA("PointLight") or desc:IsA("SpotLight") or desc:IsA("SurfaceLight") then
			local light = desc :: any
			light.Brightness = math.clamp(light.Brightness, 1.5, 3)
			light.Range = math.clamp(light.Range, 16, 40)
			light.Enabled = true
			light:SetAttribute("Zone", zone)
		end
	end
end

local function place(parent: Instance, roomId: string, kind: string, x: number, y: number, z: number)
	local model = PropRegistry.build(kind, CFrame.new(x, y, z), nil)
	model.Name = kind
	model:SetAttribute("Room", roomId)
	model.Parent = parent
	tune(model, roomId)
end

local function scatter(parent: Instance, room: Blueprint.Room, kind: string, y: number, spacing: number, limit: number)
	local x0, x1, z0, z1 = bounds(room.polygon)
	local placed = 0
	local x = x0 + math.min(spacing * 0.5, 4)
	while x < x1 - 1 and placed < limit do
		local z = z0 + math.min(spacing * 0.5, 4)
		while z < z1 - 1 and placed < limit do
			if Geometry.contains(room.polygon, x, z) then
				place(parent, room.id, kind, x, y, z)
				placed += 1
			end
			z += spacing
		end
		x += spacing
	end
end

local function fixtures(zone: Instance, room: Blueprint.Room, roomType: string, floorY: number, ceilY: number)
	if roomType == "gym" or room.id == "cage_gym" then
		-- 20 ft mount, not hard against a 32 ft deck. Range is capped at 40, so a
		-- joist-height bay leaves the court dark. The grid has to cover the whole floor.
		scatter(zone, room, "high_bay_light", floorY + 20, 20, 40)
	elseif roomType == "stair" then
		-- Cans along the going. Keep every pack under this room's ceiling.
		local pack = math.min(ceilY - 1.5, floorY + 16)
		scatter(zone, room, "downlight", math.min(floorY + 4, pack), 8, 6)
		scatter(zone, room, "downlight", math.min(floorY + 10, pack), 8, 6)
		scatter(zone, room, "downlight", pack, 8, 4)
	elseif roomType == "lobby" or room.id == "south_vestibule" or room.ceilingHeight >= 24 then
		scatter(zone, room, "downlight", floorY + 10, 8, 12)
		scatter(zone, room, "downlight", math.min(ceilY - 2, floorY + 18), 16, 4)
	elseif roomType == "corridor" or roomType == "office" or roomType == "locker" or roomType == "support" then
		local kind = if roomType == "corridor" then "troffer_2x4" else "troffer_2x2"
		scatter(zone, room, kind, ceilY - 0.5, 8, 18)
	elseif room.ceilingType ~= "none" then
		scatter(zone, room, "troffer_2x2", ceilY - 0.45, 8, 10)
	end
end

function Lighting.build(model: Instance, data: Blueprint.Data): Folder
	local parent = Geometry.folder(model, "Lighting")
	local master = Instance.new("StringValue")
	master.Name = "MasterMode"
	master.Value = "normal"
	master.Parent = parent
	for _, level in data.levels do
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
			local zone = Instance.new("Folder")
			zone.Name = room.id
			zone.Parent = parent
			local mode = Instance.new("StringValue")
			mode.Name = "Mode"
			mode.Value = "normal"
			mode.Parent = zone
			local floorY = level.elevation
			fixtures(zone, room, roomType, floorY, floorY + room.ceilingHeight)
		end
	end
	return parent
end

return Lighting
