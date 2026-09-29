--!strict
local P = require(script.Parent.Primitives)
local H = require(script.Parent.Heightfield)
local G = require(script.Parent.Parent.Build.Geometry)
local County = {}
-- Lidar inside the footprint is the roof. Pavement draped on it cuts through the floors.
local function onBuilding(site: any, x: number, z: number): boolean
	local pads = if site.terrain then site.terrain.padPolygons else nil
	if not pads then
		return false
	end
	for _, polygon in pads do
		if G.contains(polygon, x, z) then
			return true
		end
	end
	return false
end
function County.build(parent: Instance, site: any)
	local source = site.planimetric
	local ground = P.folder(parent, "CountyPavement")
	local slabs: { BasePart } = {}
	local dress: { BasePart } = {}
	local function inEntrance(x: number, z: number): boolean
		local e = site.entrance
		if not e then
			return false
		end
		return math.abs(x - e.x) < e.width / 2 + 18 and z > e.z - 2 and z < e.z + e.landingDepth + 12 * e.run + 36
	end
	for _, q in source.patches do
		local x, z = q.x + q.w / 2, q.z + q.d / 2
		local hy = H.height(x, z)
		-- Roof lidar still cuts floors. Pavement near the pad must stay (hy>8 used to drop the roundabout).
		if onBuilding(site, x, z) or inEntrance(x, z) then
			continue
		end
		-- South road meets the stair toe instead of dropping into a lidar trench.
		local e = site.entrance
		if e then
			local toe = -(e.risers or 10) * (e.rise or 0.583)
			local south = z - (e.z or 0)
			if south > 8 and south < 90 and math.abs(x - e.x) < (e.width or 40) + 48 then
				hy = math.max(hy, toe - 0.15)
			end
		end
		local gx = (H.height(x + q.w / 2, z) - H.height(x - q.w / 2, z)) / math.max(q.w, 0.5)
		local gz = (H.height(x, z + q.d / 2) - H.height(x, z - q.d / 2)) / math.max(q.d, 0.5)
		local right = Vector3.new(1, gx, 0).Unit
		local back = Vector3.new(0, gz, 1)
		local up = back:Cross(right).Unit
		back = right:Cross(up).Unit
		local thickness = 0.5
		-- Top face sits on the lidar sample. A negative offset buried Patriot Circle.
		local centerY = hy + 0.08 - up.Y * thickness / 2
		local slabName = if q.material == "asphalt" then "LotSlab" else "PavementSlab"
		table.insert(
			slabs,
			P.box(
				ground,
				slabName,
				-- Inset so an asphalt lot and a concrete walk do not share a face.
				Vector3.new(math.max(0.5, q.w - 0.2), thickness, math.max(0.5, q.d - 0.2)),
				CFrame.fromMatrix(Vector3.new(x, centerY, z), right, up, back),
				q.material,
				true
			)
		)
	end
	-- Curbs and stall paint sit above the slab top. Shared Y faces within 0.005 ft
	-- are flagged as z-fights, and roof-height lidar must not grow a curb into a door.
	local d = H.data
	local function grounded(x: number, z: number): boolean
		if x < d.x0 or z < d.z0 or x > d.x0 + d.nx * d.step or z > d.z0 + d.nz * d.step then
			return false
		end
		if onBuilding(site, x, z) then
			return false
		end
		local e = site.entrance
		if
			e
			and math.abs(x - e.x) < e.width / 2 + 10
			and z > e.z - 1
			and z < e.z + e.landingDepth + e.risers * e.run + 28
		then
			return false
		end
		return true
	end
	local curbs = P.folder(ground, "Curbs")
	for _, curb in source.curbs or {} do
		local a, b = curb.a, curb.b
		local mx, mz = (a[1] + b[1]) / 2, (a[2] + b[2]) / 2
		if not grounded(mx, mz) or not grounded(a[1], a[2]) or not grounded(b[1], b[2]) then
			continue
		end
		local dx, dz = b[1] - a[1], b[2] - a[2]
		local length = math.sqrt(dx * dx + dz * dz)
		if length < 1.2 then
			continue
		end
		-- Shift off the pavement edge so a vertical face is not coplanar with the slab.
		local ox, oz = -dz / length * 0.35, dx / length * 0.35
		-- 6 in curb. Slab top is the lidar sample + 0.08, so the curb center sits 0.25 ft above that.
		table.insert(
			dress,
			P.beam(
				curbs,
				"Curb",
				Vector3.new(a[1] + ox, H.height(a[1], a[2]) + 0.33, a[2] + oz),
				Vector3.new(b[1] + ox, H.height(b[1], b[2]) + 0.33, b[2] + oz),
				0.5,
				0.5,
				"concrete",
				true
			)
		)
	end
	local paint = P.folder(ground, "Markings")
	for _, mark in source.markings or {} do
		local a, b = mark.a, mark.b
		local mx, mz = (a[1] + b[1]) / 2, (a[2] + b[2]) / 2
		if not grounded(mx, mz) then
			continue
		end
		local color = if mark.color == "yellow" then "yellow" else "white"
		local stripeW = mark.width or 0.333
		if stripeW < 0.8 then
			stripeW = 0.333
		end
		table.insert(
			dress,
			P.beam(
				paint,
				"StallStripe",
				Vector3.new(a[1], H.height(a[1], a[2]) + 0.163, a[2]),
				Vector3.new(b[1], H.height(b[1], b[2]) + 0.163, b[2]),
				math.clamp(stripeW, 0.12, 2.2),
				0.04,
				color,
				false
			)
		)
	end
	-- 9 x 18 ft stalls and a 24 ft aisle on large asphalt patches. Planimetric paint is kept above.
	local stallCount = 0
	local function addStripe(ax: number, az: number, bx: number, bz: number)
		if stallCount >= 320 then
			return
		end
		local mx, mz = (ax + bx) / 2, (az + bz) / 2
		if not grounded(mx, mz) then
			return
		end
		stallCount += 1
		table.insert(
			dress,
			P.beam(
				paint,
				"StallStripe",
				Vector3.new(ax, H.height(ax, az) + 0.17, az),
				Vector3.new(bx, H.height(bx, bz) + 0.17, bz),
				0.333,
				0.04,
				"white",
				false
			)
		)
	end
	-- County patches are small cells, not one rectangle per lot. Stripe the largest cells first.
	local ranked = {}
	for _, q in source.patches do
		if q.material == "asphalt" then
			table.insert(ranked, q)
		end
	end
	table.sort(ranked, function(a, b)
		return a.w * a.d > b.w * b.d
	end)
	for _, q in ranked do
		if stallCount >= 320 then
			break
		end
		local cx, cz = q.x + q.w / 2, q.z + q.d / 2
		if onBuilding(site, cx, cz) or inEntrance(cx, cz) then
			continue
		end
		local alongX = q.w >= q.d
		local length = if alongX then q.w else q.d
		local depth = if alongX then q.d else q.w
		if length < 18 or depth < 8 then
			continue
		end
		local stallDepth = math.min(18, depth - 1)
		local rows = math.clamp(math.floor((depth + 24) / 42), 1, 2)
		for row = 0, rows - 1 do
			local band = row * 42
			if band + stallDepth > depth - 0.5 then
				break
			end
			local n = math.min(math.floor((length - 2) / 9), 10)
			for i = 0, n do
				local t = 1 + i * 9
				if t > length - 1 then
					break
				end
				if alongX then
					addStripe(q.x + t, q.z + band + 0.5, q.x + t, q.z + band + 0.5 + stallDepth)
				else
					addStripe(q.x + band + 0.5, q.z + t, q.x + band + 0.5 + stallDepth, q.z + t)
				end
			end
		end
	end
	-- Planted islands every ~72 ft on the larger asphalt cells, plus working poles.
	local islandN = 0
	local poles = P.folder(ground, "LotPoles")
	for _, q in ranked do
		if islandN >= 28 then
			break
		end
		local cx, cz = q.x + q.w / 2, q.z + q.d / 2
		if onBuilding(site, cx, cz) or inEntrance(cx, cz) or q.w < 28 or q.d < 18 then
			continue
		end
		if (math.floor(cx / 72) + math.floor(cz / 72)) % 2 ~= 0 then
			continue
		end
		islandN += 1
		local hy = H.height(cx, cz)
		local island =
			P.box(ground, "LotIslandSlab", Vector3.new(6, 0.55, 16), CFrame.new(cx, hy + 0.36, cz), "concrete", true)
		table.insert(dress, island)
		P.box(ground, "LotIslandPlant", Vector3.new(4.6, 1.4, 14), CFrame.new(cx, hy + 1.15, cz), "shrub")
		local pole = P.box(poles, "LightPole", Vector3.new(0.32, 18, 0.32), CFrame.new(cx, hy + 9.1, cz), "dark", true)
		local globe = P.box(poles, "LightGlobe", Vector3.new(1.1, 1.1, 1.1), CFrame.new(cx, hy + 18.4, cz), "metal")
		globe.Shape = Enum.PartType.Ball
		globe.Material = Enum.Material.SmoothPlastic
		globe.Color = Color3.fromRGB(255, 236, 200)
		local lamp = Instance.new("PointLight")
		lamp.Brightness = 1.4
		lamp.Range = 42
		lamp.Color = Color3.fromRGB(255, 236, 200)
		lamp.Parent = globe
		table.insert(dress, pole)
	end
	-- The geometry check uses AABBs. A sloped slab's box can share a face with a curb
	-- even when the meshes do not. Nudge the thinner part until the faces separate.
	local function extents(part: BasePart): ({ number }, { number })
		local cf, s = part.CFrame, part.Size
		local c = cf.Position
		local r, u, look = cf.RightVector, cf.UpVector, cf.LookVector
		local hx = math.abs(r.X) * s.X / 2 + math.abs(u.X) * s.Y / 2 + math.abs(look.X) * s.Z / 2
		local hy = math.abs(r.Y) * s.X / 2 + math.abs(u.Y) * s.Y / 2 + math.abs(look.Y) * s.Z / 2
		local hz = math.abs(r.Z) * s.X / 2 + math.abs(u.Z) * s.Y / 2 + math.abs(look.Z) * s.Z / 2
		return { c.X - hx, c.Y - hy, c.Z - hz }, { c.X + hx, c.Y + hy, c.Z + hz }
	end
	local function faceFight(aMin: { number }, aMax: { number }, bMin: { number }, bMax: { number }): boolean
		local ox = math.min(aMax[1], bMax[1]) - math.max(aMin[1], bMin[1])
		local oy = math.min(aMax[2], bMax[2]) - math.max(aMin[2], bMin[2])
		local oz = math.min(aMax[3], bMax[3]) - math.max(aMin[3], bMin[3])
		local function axis(o1: number, o2: number, a0: number, a1: number, b0: number, b1: number): boolean
			return o1 > 0.25
				and o2 > 0.25
				and o1 * o2 > 0.5
				and (math.abs(a1 - b1) < 0.005 or math.abs(a0 - b0) < 0.005)
		end
		return axis(oy, oz, aMin[1], aMax[1], bMin[1], bMax[1])
			or axis(ox, oz, aMin[2], aMax[2], bMin[2], bMax[2])
			or axis(ox, oy, aMin[3], aMax[3], bMin[3], bMax[3])
	end
	for _ = 1, 6 do
		local moved = false
		for _, part in dress do
			local aMin, aMax = extents(part)
			local function hit(list: { BasePart }): boolean
				for _, other in list do
					if other ~= part then
						local bMin, bMax = extents(other)
						if faceFight(aMin, aMax, bMin, bMax) then
							part.CFrame = part.CFrame + Vector3.new(0.04, 0.03, 0.04)
							return true
						end
					end
				end
				return false
			end
			if hit(slabs) or hit(dress) then
				moved = true
			end
		end
		if not moved then
			break
		end
	end
end
return County
