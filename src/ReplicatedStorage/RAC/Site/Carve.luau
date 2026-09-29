--!strict
-- Air out every room, wall, and the footprint slab. Grass voxels above the floor read as tufts indoors.
local Geometry = require(script.Parent.Parent.Build.Geometry)
local Data = require(script.Parent.CarveData)

local Carve = {}

local function fill(terrain: Terrain, x: number, z: number, w: number, d: number, y0: number, y1: number): number
	if w < 0.8 or d < 0.8 or y1 - y0 < 1 then
		return 0
	end
	terrain:FillBlock(CFrame.new(x + w / 2, (y0 + y1) / 2, z + d / 2), Vector3.new(w, y1 - y0, d), Enum.Material.Air)
	return 1
end

function Carve.apply(terrain: Terrain): number
	local n = 0
	for _, room in Data.rooms do
		for _, r in Geometry.rectangles(room.polygon) do
			n += fill(terrain, r.x, r.z, r.w, r.d, room.y0, room.y1)
		end
	end
	for _, wall in Data.walls do
		local dx, dz = wall.bx - wall.ax, wall.bz - wall.az
		local length = math.sqrt(dx * dx + dz * dz)
		if length < 0.5 or wall.y1 - wall.y0 < 1 then
			continue
		end
		local mx, mz = (wall.ax + wall.bx) / 2, (wall.az + wall.bz) / 2
		local midY = (wall.y0 + wall.y1) / 2
		terrain:FillBlock(
			CFrame.lookAt(Vector3.new(mx, midY, mz), Vector3.new(wall.bx, midY, wall.bz)),
			Vector3.new(wall.thickness + 0.5, wall.y1 - wall.y0, length + 0.4),
			Enum.Material.Air
		)
		n += 1
	end
	for _, r in Geometry.rectangles(Data.footprint) do
		n += fill(terrain, r.x, r.z, r.w, r.d, -1, 42)
	end
	return n
end

-- Any occupied non-air voxel whose center is above floor-1 ft and inside the footprint fails.
function Carve.audit(terrain: Terrain): { fails: number, samples: number }
	local resolution = 4
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, p in Data.footprint do
		minX, maxX = math.min(minX, p[1]), math.max(maxX, p[1])
		minZ, maxZ = math.min(minZ, p[2]), math.max(maxZ, p[2])
	end
	local region = Region3.new(Vector3.new(minX, -1, minZ), Vector3.new(maxX, 42, maxZ)):ExpandToGrid(resolution)
	local materials, occupancy = terrain:ReadVoxels(region, resolution)
	local size = region.Size
	local origin = region.CFrame.Position - size / 2
	local fails, samples = 0, 0
	for ix, column in materials do
		for iy, row in column do
			for iz, material in row do
				local x = origin.X + (ix - 0.5) * resolution
				local y = origin.Y + (iy - 0.5) * resolution
				local z = origin.Z + (iz - 0.5) * resolution
				if y > -1 and Geometry.contains(Data.footprint, x, z) then
					samples += 1
					local occ = occupancy[ix][iy][iz]
					if material ~= Enum.Material.Air and occ > 0 then
						fails += 1
					end
				end
			end
		end
	end
	return { fails = fails, samples = samples }
end

return Carve
