--!strict
local Geometry = require(script.Parent.Geometry)
local Floors = require(script.Parent.Floors)
local Layout = {}
local function rectangle(x0: number, y0: number, x1: number, y1: number)
	return { { x0, y0 }, { x1, y0 }, { x1, y1 }, { x0, y1 } }
end
-- Subtract construction reservations in the wall's longitudinal/elevation plane.
function Layout.rectangles(level: any, index: number, data: any): { Geometry.Rect }
	local wall = level.walls[index]
	local cf, length = Geometry.frame(wall.a, wall.b, level.elevation)
	local holes = {}
	local function cut(x0: number, y0: number, x1: number, y1: number)
		x0, x1 = math.max(0, math.round(x0 * 10000) / 10000), math.min(length, math.round(x1 * 10000) / 10000)
		y0, y1 = math.max(0, y0), math.min(wall.height, y1)
		if x1 - x0 > 0.0001 and y1 - y0 > 0.0001 then
			table.insert(holes, rectangle(x0, y0, x1, y1))
		end
	end
	for _, o in wall.openings do
		assert(o.offset >= 0 and o.offset + o.width <= length + 0.001, "Opening outside wall")
		assert(o.sill >= 0 and o.head <= wall.height and o.head > o.sill, "Invalid opening height")
		cut(o.offset, o.sill, o.offset + o.width, o.head)
	end
	-- At tees the through wall wins; at corners the east-west wall owns the joint.
	for otherIndex, other in level.walls do
		if otherIndex == index then
			continue
		end
		local a = cf:PointToObjectSpace(Vector3.new(other.a[1], 0, other.a[2]))
		local b = cf:PointToObjectSpace(Vector3.new(other.b[1], 0, other.b[2]))
		if math.abs(a.X - b.X) > 0.0001 then
			continue
		end
		local z0, z1 = math.min(a.Z, b.Z), math.max(a.Z, b.Z)
		if z0 > wall.thickness / 2 or z1 < -wall.thickness / 2 then
			continue
		end
		local otherThrough = z0 < -0.001 and z1 > 0.001
		local thisThrough = a.X > 0.001 and a.X < length - 0.001
		if otherThrough or (not thisThrough and math.abs(wall.b[2] - wall.a[2]) > 0.001) then
			cut(a.X - other.thickness / 2, 0, a.X + other.thickness / 2, other.height)
		end
	end
	if data then
		for _, upper in data.levels do
			if upper.elevation <= level.elevation then
				continue
			end
			local voids = {}
			for _, void in upper.voids do
				table.insert(voids, void.polygon)
			end
			for _, room in upper.rooms do
				if room.type == "void" then
					table.insert(voids, room.polygon)
				end
			end
			for _, slab in Geometry.rectangles(data.site.footprint, voids) do
				local a = cf:PointToObjectSpace(Vector3.new(slab.x, 0, slab.z))
				local b = cf:PointToObjectSpace(Vector3.new(slab.x + slab.w, 0, slab.z + slab.d))
				local z0, z1 = math.min(a.Z, b.Z), math.max(a.Z, b.Z)
				if z0 < wall.thickness / 2 - 0.0001 and z1 > -wall.thickness / 2 + 0.0001 then
					cut(
						math.min(a.X, b.X),
						upper.elevation - level.elevation - Floors.THICKNESS,
						math.max(a.X, b.X),
						wall.height
					)
				end
			end
			-- A wall above a void still owns its level's vertical range.
			for _, other in upper.walls do
				local a = cf:PointToObjectSpace(Vector3.new(other.a[1], 0, other.a[2]))
				local b = cf:PointToObjectSpace(Vector3.new(other.b[1], 0, other.b[2]))
				if math.abs(a.Z - b.Z) < 0.0001 and math.abs(a.Z) < (wall.thickness + other.thickness) / 2 - 0.0001 then
					cut(math.min(a.X, b.X), upper.elevation - level.elevation, math.max(a.X, b.X), wall.height)
				end
			end
		end
	end
	return Geometry.rectangles(rectangle(0, 0, length, wall.height), holes)
end
return Layout
