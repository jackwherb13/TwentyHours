--!strict
-- Real fixtures. Gyms get suspended LED high-bays, corridors get 2x4 troffers,
-- the lobby and the open stair get downlights low enough to light the floor.
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

local function scatter(
	parent: Instance,
	room: Blueprint.Room,
	kind: string,
	y: number,
	spacing: number,
	limit: number
)
	local x0, x1, z0, z1 = bounds(room.polygon)
	local placed = 0
	local x = x0 + spacing * 0.5
	while x < x1 - 1 and placed < limit do
		local z = z0 + spacing * 0.5
		while z < z1 - 1 and placed < limit do
			if Geometry.contains(room.polygon, x, z) then
				local model = PropRegistry.build(kind, CFrame.new(x, y, z), nil)
				model.Name = kind
				model:SetAttribute("Room", room.id)
				model.Parent = parent
				placed += 1
			end
			z += spacing
		end
		x += spacing
	end
end

function Lights.build(parent: Instance, level: Blueprint.Level)
	local folder = Instance.new("Folder")
	folder.Name = "Lights"
	folder.Parent = parent
	for _, room in level.rooms do
		if room.type == "void" or room.type == "construction" then
			continue
		end
		local x0, x1, z0, z1 = bounds(room.polygon)
		if math.min(x1 - x0, z1 - z0) < 6 and room.type ~= "stair" then
			continue
		end
		local floorY = level.elevation
		local ceilY = floorY + room.ceilingHeight
		if room.type == "gym" or room.id == "cage_gym" then
			scatter(folder, room, "high_bay_light", ceilY - 4, 28, 12)
		elseif room.type == "stair" then
			scatter(folder, room, "downlight", floorY + 11, 9, 6)
			scatter(folder, room, "downlight", floorY + 22, 10, 4)
		elseif room.type == "lobby" or room.id == "south_vestibule" or room.ceilingHeight >= 24 then
			scatter(folder, room, "downlight", floorY + 11, 14, 10)
			if room.ceilingHeight >= 24 then
				scatter(folder, room, "downlight", math.min(ceilY - 1, floorY + 26), 16, 6)
			end
		elseif room.type == "corridor" then
			scatter(folder, room, "troffer_2x4", ceilY - 0.5, 18, 8)
		elseif room.ceilingType == "none" then
			continue
		else
			scatter(folder, room, "troffer_2x2", ceilY - 0.45, 12, 4)
		end
	end
end

return Lights
