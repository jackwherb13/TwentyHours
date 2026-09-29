--!strict
local Geometry = {}
export type Point = { number }
export type Polygon = { Point }
export type Rect = { x: number, z: number, w: number, d: number }

function Geometry.contains(poly: Polygon, x: number, z: number): boolean
	local inside = false
	local j = #poly
	for i, a in poly do
		local b = poly[j]
		if (a[2] > z) ~= (b[2] > z) and x < (b[1] - a[1]) * (z - a[2]) / (b[2] - a[2]) + a[1] then
			inside = not inside
		end
		j = i
	end
	return inside
end

-- Sweep the complete arrangement of edges, subtract holes, then merge identical row runs.
-- Exact for rectilinear L/U polygons and holes, independent of winding or input order.
function Geometry.rectangles(poly: Polygon, holes: { Polygon }?): { Rect }
	local cutouts: { Polygon } = holes or {}
	local xs: { number } = {}
	local zs: { number } = {}
	local function collect(p: Polygon)
		assert(#p >= 3, "Polygon needs at least three vertices")
		for i, a in p do
			local b = p[i % #p + 1]
			assert(
				math.abs(a[1] - b[1]) < 0.0001 or math.abs(a[2] - b[2]) < 0.0001,
				"Slab polygons must be rectilinear"
			)
			if not table.find(xs, a[1]) then
				table.insert(xs, a[1])
			end
			if not table.find(zs, a[2]) then
				table.insert(zs, a[2])
			end
		end
	end
	collect(poly)
	for _, hole in cutouts do
		collect(hole)
	end
	table.sort(xs)
	table.sort(zs)
	local result: { Rect } = {}
	for j = 1, #zs - 1 do
		local z, d = zs[j], zs[j + 1] - zs[j]
		local start: number? = nil
		local function flush(finish: number)
			if start == nil then
				return
			end
			local x = start :: number
			local w = finish - x
			for _, rect in result do
				if rect.x == x and rect.w == w and math.abs(rect.z + rect.d - z) < 0.0001 then
					rect.d += d
					start = nil
					return
				end
			end
			table.insert(result, { x = x, z = z, w = w, d = d })
			start = nil
		end
		for i = 1, #xs - 1 do
			local x = (xs[i] + xs[i + 1]) / 2
			local inside = Geometry.contains(poly, x, z + d / 2)
			for _, hole in cutouts do
				if Geometry.contains(hole, x, z + d / 2) then
					inside = false
					break
				end
			end
			if inside then
				start = start or xs[i]
			else
				flush(xs[i])
			end
		end
		flush(xs[#xs])
	end
	return result
end

function Geometry.frame(a: Point, b: Point, elevation: number): (CFrame, number)
	local dx, dz = b[1] - a[1], b[2] - a[2]
	local length = math.sqrt(dx * dx + dz * dz)
	assert(length > 0, "Zero length segment")
	return CFrame.new(a[1], elevation, a[2]) * CFrame.Angles(0, -math.atan2(dz, dx), 0), length
end

function Geometry.folder(parent: Instance, name: string): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end
return Geometry
