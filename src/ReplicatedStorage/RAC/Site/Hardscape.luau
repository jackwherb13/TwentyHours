--!strict
local P = require(script.Parent.Primitives)
local H = require(script.Parent.Heightfield)
local G = require(script.Parent.Parent.Build.Geometry)
local Hardscape = {}
local function onBuilding(site: any, x: number, z: number): boolean
	local e = site.entrance
	if x >= e.x and x <= e.x + e.landingDepth + e.risers * e.run + 2 and math.abs(z - e.z) <= e.width / 2 + 4 then
		return true
	end
	for _, polygon in site.terrain.padPolygons do
		if G.contains(polygon, x, z) then
			return true
		end
	end
	return false
end
local function v(x: number, z: number, rise: number): Vector3
	return Vector3.new(x, H.height(x, z) + rise, z)
end
function Hardscape.build(parent: Instance, site: any)
	local surfaces = P.folder(parent, "GroundSlabs")
	local paint = P.folder(parent, "RoadMarkings")
	for _, route in site.roads do
		local path = P.folder(surfaces, route.id)
		local walk = route.kind == "footway"
			or route.kind == "path"
			or route.kind == "steps"
			or route.kind == "pedestrian"
		for i = 1, #route.points - 1 do
			local a, b = route.points[i], route.points[i + 1]
			local dx, dz = b[1] - a[1], b[2] - a[2]
			local length = math.sqrt(dx * dx + dz * dz)
			if length < 0.1 then
				continue
			end
			local ux, uz = dx / length, dz / length
			local segments = math.ceil(length / 12)
			for k = 0, segments - 1 do
				local t0, t1 = k / segments, (k + 1) / segments
				local x0, z0 = a[1] + dx * t0, a[2] + dz * t0
				local x1, z1 = a[1] + dx * t1, a[2] + dz * t1
				local x, z = (x0 + x1) / 2, (z0 + z1) / 2
				if x < H.data.x0 or x > H.data.x0 + 1200 or z < H.data.z0 or z > H.data.z0 + 1200 then
					continue
				end
				if onBuilding(site, x, z) then
					continue
				end
				local pavement = P.beam(
					path,
					"PavementSlab",
					v(x0, z0, -0.16),
					v(x1, z1, -0.16),
					route.width,
					0.32,
					if walk then "concrete" else "asphalt",
					true
				)
				if not walk and route.kind ~= "cycleway" then
					for _, side in { -1, 1 } do
						local off = side * (route.width / 2 + 0.22)
						P.beam(
							path,
							"CurbSlab",
							v(x0 - uz * off, z0 + ux * off, 0.13),
							v(x1 - uz * off, z1 + ux * off, 0.13),
							0.44,
							0.48,
							"concrete",
							true
						)
					end
				end
				if route.markings then
					for _, off in { -0.3, 0.3 } do
						P.box(
							paint,
							"CenterStripeSlab",
							Vector3.new(0.16, 0.025, pavement.Size.Z),
							pavement.CFrame * CFrame.new(off, 0.2, 0),
							"yellow"
						)
					end
					if route.bikeLane then
						for _, side in { -1, 1 } do
							local off = side * (route.width / 2 - 5)
							P.box(
								paint,
								"BikeLaneStripeSlab",
								Vector3.new(0.22, 0.025, pavement.Size.Z),
								pavement.CFrame * CFrame.new(off, 0.2, 0),
								"white"
							)
						end
					end
				end
			end
		end
	end
	for _, area in site.areas do
		if area.kind == "building" then
			continue
		end
		local xs, zs = {}, {}
		for _, q in area.polygon do
			table.insert(xs, q[1])
			table.insert(zs, q[2])
		end
		table.sort(xs)
		table.sort(zs)
		local lot = P.folder(surfaces, area.id)
		-- Scanline rows keep arbitrary OSM polygon outlines without overlapping slabs.
		for z = math.max(H.data.z0, zs[1]), math.min(H.data.z0 + 1200, zs[#zs]) - 6, 6 do
			local start: number? = nil
			local function flush(x: number)
				if start then
					for left = start, x - 0.1, 18 do
						local right = math.min(x, left + 18)
						P.beam(
							lot,
							"LotSlab",
							v(left, z + 3, -0.18),
							v(right, z + 3, -0.18),
							5.98,
							0.24,
							if area.kind == "pitch" then "grass" else "asphalt",
							true
						)
					end
					start = nil
				end
			end
			local finish = math.min(H.data.x0 + 1200, xs[#xs])
			for x = math.max(H.data.x0, xs[1]), finish, 6 do
				if G.contains(area.polygon, x + 3, z + 3) and not onBuilding(site, x + 3, z + 3) then
					start = start or x
				else
					flush(x)
				end
			end
			flush(finish)
		end
		if area.kind == "parking" then
			for z = zs[1] + 20, zs[#zs] - 18, 60 do
				for x = xs[1] + 8, xs[#xs] - 8, 9 do
					if
						G.contains(area.polygon, x, z)
						and G.contains(area.polygon, x, z + 18)
						and not onBuilding(site, x, z + 9)
					then
						P.beam(paint, "StallStripeSlab", v(x, z, 0.04), v(x, z + 18, 0.04), 0.15, 0.03, "white")
					end
				end
			end
		end
	end
	for _, crossing in site.crosswalks do
		local a = crossing.at
		for t = -crossing.width / 2, crossing.width / 2, 4 do
			P.box(
				paint,
				"CrosswalkStripeSlab",
				Vector3.new(2, 0.04, 10),
				CFrame.new(a[1] + t, H.height(a[1] + t, a[2]) + 0.10, a[2])
					* CFrame.Angles(0, math.rad(crossing.rotation), 0),
				"white"
			)
		end
	end
end
return Hardscape
