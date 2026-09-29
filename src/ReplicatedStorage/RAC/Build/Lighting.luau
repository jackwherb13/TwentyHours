--!strict
-- Room fixtures parented at workspace.RAC.Lighting so LightingController can bind.
-- Fewer, brighter fixtures: gym high-bays every ~32 ft at 18 ft; rooms on a 12–16 ft grid.
-- Lobby stays sparse so daylight through the south glass does not blow out.
local Blueprint = require(script.Parent.Blueprint)
local Geometry = require(script.Parent.Geometry)

local Lighting = {}

local function tagNormal(light: Instance)
	light:SetAttribute("RAC_Light", "NormalLight")
	pcall(function()
		game:GetService("CollectionService"):AddTag(light, "NormalLight")
	end)
	pcall(function()
		light:AddTag("NormalLight")
	end)
end

type Tune = { brightness: number, range: number, angle: number }

local TUNE: { [string]: Tune } = {
	high_bay_light = { brightness = 6, range = 48, angle = 100 },
	troffer_2x4 = { brightness = 1.4, range = 24, angle = 80 },
	troffer_2x2 = { brightness = 1.1, range = 18, angle = 75 },
	downlight = { brightness = 0.9, range = 16, angle = 70 },
}

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

local TROFFER_KIND: { [string]: string } = {
	corridor = "troffer_2x4",
	office = "troffer_2x2",
	locker = "troffer_2x2",
	support = "troffer_2x2",
	fitness = "troffer_2x2",
	racquetball = "troffer_2x2",
	storage = "troffer_2x2",
	restroom = "troffer_2x2",
	mechanical = "troffer_2x2",
}

local FIXTURE_SIZE: { [string]: Vector3 } = {
	high_bay_light = Vector3.new(1.2, 0.25, 4),
	troffer_2x4 = Vector3.new(2, 0.12, 4),
	troffer_2x2 = Vector3.new(2, 0.12, 2),
	downlight = Vector3.new(0.7, 0.08, 0.7),
}

local function place(parent: Instance, roomId: string, kind: string, x: number, y: number, z: number)
	-- One housing and one spot. The old kit meshes were most of the 13k lighting parts.
	local housing = Instance.new("Part")
	housing.Name = kind
	housing.Size = FIXTURE_SIZE[kind] or Vector3.new(2, 0.12, 2)
	housing.CFrame = CFrame.new(x, y, z)
	housing.Anchored = true
	housing.CanCollide = false
	housing.Material = Enum.Material.Metal
	housing.Color = if kind == "high_bay_light" then Color3.fromRGB(214, 216, 214) else Color3.fromRGB(236, 236, 232)
	housing.TopSurface = Enum.SurfaceType.Smooth
	housing.BottomSurface = Enum.SurfaceType.Smooth
	housing:SetAttribute("Room", roomId)
	housing.Parent = parent
	local spec = TUNE[kind]
	local spot = Instance.new("SpotLight")
	spot.Name = "Lamp"
	spot.Face = Enum.NormalId.Bottom
	spot.Brightness = if spec then spec.brightness else 1
	spot.Range = if spec then spec.range else 18
	spot.Angle = if spec then spec.angle else 70
	spot.Color = Color3.fromRGB(255, 246, 230)
	spot.Shadows = false
	spot.Enabled = true
	spot:SetAttribute("Zone", roomId)
	spot.Parent = housing
	tagNormal(spot)
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
				place(parent, room.id, kind, x, y, z)
				placed += 1
			end
			z += spacing
		end
		x += spacing
	end
end

-- Cover the floor. A fixed cap of 4 left the 200 ft overlook and the west hall dark.
local function gridBudget(room: Blueprint.Room, spacing: number, hardCap: number): number
	local x0, x1, z0, z1 = bounds(room.polygon)
	local nx = math.max(1, math.floor((x1 - x0 - 2) / spacing) + 1)
	local nz = math.max(1, math.floor((z1 - z0 - 2) / spacing) + 1)
	return math.clamp(nx * nz, 1, hardCap)
end

local function fixtures(zone: Instance, room: Blueprint.Room, roomType: string, floorY: number, ceilY: number)
	if roomType == "gym" or room.id == "cage_gym" then
		scatter(zone, room, "high_bay_light", floorY + 22, 28, gridBudget(room, 28, 16))
	elseif roomType == "stair" then
		scatter(zone, room, "downlight", floorY + 10, 14, gridBudget(room, 14, 6))
	elseif
		room.id == "office_w2"
		or room.id == "training_room"
		or room.id == "coach_suite"
		or room.id == "coach_head"
		or room.id == "corridor_entry_link"
	then
		scatter(zone, room, "troffer_2x4", ceilY - 0.5, 16, gridBudget(room, 16, 6))
	elseif roomType == "lobby" or room.id == "south_vestibule" then
		scatter(zone, room, "downlight", math.min(ceilY - 2, floorY + 12), 18, gridBudget(room, 18, 4))
	elseif room.ceilingHeight >= 24 then
		scatter(zone, room, "downlight", floorY + 12, 20, gridBudget(room, 20, 6))
	elseif TROFFER_KIND[roomType] then
		local kind = TROFFER_KIND[roomType]
		local spacing = if kind == "troffer_2x4" then 18 else 16
		local cap = if kind == "troffer_2x4" then 14 else 6
		scatter(zone, room, kind, ceilY - 0.5, spacing, gridBudget(room, spacing, cap))
	elseif room.ceilingType ~= "none" then
		scatter(zone, room, "troffer_2x2", ceilY - 0.45, 16, gridBudget(room, 16, 4))
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
