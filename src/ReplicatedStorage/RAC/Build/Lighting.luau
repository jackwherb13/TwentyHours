--!strict
-- Room fixtures parented at workspace.RAC.Lighting so LightingController can bind.
-- Fewer, brighter fixtures: gym high-bays every ~32 ft at 18 ft; rooms on a 12–16 ft grid.
-- Lobby stays sparse so daylight through the south glass does not blow out.
local Blueprint = require(script.Parent.Blueprint)
local Geometry = require(script.Parent.Geometry)
local PropRegistry = require(script.Parent.PropRegistry)

local Lighting = {}

local function tagNormal(light: Instance)
	pcall(function()
		game:GetService("CollectionService"):AddTag(light, "NormalLight")
	end)
end

type Tune = { brightness: number, range: number, angle: number }

local TUNE: { [string]: Tune } = {
	high_bay_light = { brightness = 12, range = 60, angle = 90 },
	troffer_2x4 = { brightness = 4.2, range = 40, angle = 90 },
	troffer_2x2 = { brightness = 3.6, range = 32, angle = 90 },
	downlight = { brightness = 2.4, range = 26, angle = 80 },
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

local function applyTune(model: Instance, zone: string, kind: string)
	local spec = TUNE[kind]
	for _, desc in model:GetDescendants() do
		if desc:IsA("PointLight") or desc:IsA("SpotLight") or desc:IsA("SurfaceLight") then
			local light = desc :: any
			if spec then
				light.Brightness = spec.brightness
				light.Range = spec.range
				if light:IsA("SurfaceLight") or light:IsA("SpotLight") then
					light.Angle = spec.angle
				end
			end
			light.Enabled = true
			light.Shadows = false
			light:SetAttribute("Zone", zone)
			tagNormal(light)
		end
	end
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

local function addFill(model: Model, zone: string, brightness: number, range: number)
	local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if part == nil then
		return
	end
	local fill = Instance.new("PointLight")
	fill.Name = "Fill"
	fill.Brightness = brightness
	fill.Range = range
	fill.Color = Color3.fromRGB(255, 248, 235)
	fill.Shadows = false
	fill.Enabled = true
	fill:SetAttribute("Zone", zone)
	fill.Parent = part
	tagNormal(fill)
end

local function place(parent: Instance, roomId: string, kind: string, x: number, y: number, z: number)
	local model = PropRegistry.build(kind, CFrame.new(x, y, z), nil)
	model.Name = kind
	model:SetAttribute("Room", roomId)
	model.Parent = parent
	applyTune(model, roomId, kind)
	if kind == "high_bay_light" then
		addFill(model, roomId, 5.0, 48)
	elseif kind == "troffer_2x4" or kind == "troffer_2x2" then
		addFill(model, roomId, 1.8, 22)
	elseif kind == "downlight" then
		addFill(model, roomId, 0.9, 16)
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
		-- Mount at 18 ft so Range 60 covers the maple at eye height from the overlook.
		scatter(zone, room, "high_bay_light", floorY + 18, 32, 16)
	elseif roomType == "stair" then
		local pack = math.min(ceilY - 1.5, floorY + 14)
		scatter(zone, room, "downlight", math.min(floorY + 5, pack), 10, 4)
		scatter(zone, room, "downlight", math.min(floorY + 12, pack), 10, 4)
		scatter(zone, room, "downlight", pack, 12, 3)
	elseif roomType == "lobby" or room.id == "south_vestibule" then
		-- Sparse cans. Daylight through the south curtain wall already fills this volume.
		scatter(zone, room, "downlight", math.min(ceilY - 2, floorY + 12), 18, 6)
	elseif room.ceilingHeight >= 24 then
		scatter(zone, room, "downlight", floorY + 12, 16, 6)
	elseif TROFFER_KIND[roomType] then
		local kind = TROFFER_KIND[roomType]
		local spacing = if kind == "troffer_2x4" then 16 else 12
		scatter(zone, room, kind, ceilY - 0.5, spacing, 8)
	elseif room.ceilingType ~= "none" then
		scatter(zone, room, "troffer_2x2", ceilY - 0.45, 14, 6)
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
