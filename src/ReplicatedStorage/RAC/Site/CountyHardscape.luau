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
		-- Door-centered flight. Scene entrance.x is the old west stair and must not punch a hole in the road.
		return math.abs(x) < 20 and z > -2 and z < 36
	end
	for _, q in source.patches do
		local x, z = q.x + q.w / 2, q.z + q.d / 2
		local hy = H.height(x, z)
		-- Roof lidar still cuts floors. Pavement near the pad must stay (hy>8 used to drop the roundabout).
		if onBuilding(site, x, z) or inEntrance(x, z) then
			continue
		end
		-- Follow lidar, but a steep patch becomes a flying knife. Flatten those onto the center sample.
		local halfW = math.max(q.w, 0.5) / 2
		local halfD = math.max(q.d, 0.5) / 2
		local dhx = H.height(x + halfW, z) - H.height(x - halfW, z)
		local dhz = H.height(x, z + halfD) - H.height(x, z - halfD)
		local steep = math.abs(dhx) > 2.4 or math.abs(dhz) > 2.4
		local right: Vector3, up: Vector3, back: Vector3
		if steep then
			right = Vector3.new(1, 0, 0)
			up = Vector3.new(0, 1, 0)
			back = Vector3.new(0, 0, 1)
		else
			local gx = dhx / math.max(q.w, 0.5)
			local gz = dhz / math.max(q.d, 0.5)
			right = Vector3.new(1, gx, 0).Unit
			back = Vector3.new(0, gz, 1)
			up = back:Cross(right).Unit
			back = right:Cross(up).Unit
		end
		local thickness = 0.5
		-- Top face sits on the lidar sample. A negative offset buried Patriot Circle.
		local centerY = hy + 0.08 - up.Y * thickness / 2
		local slabName = if q.material == "asphalt" then "LotSlab" else "PavementSlab"
		table.insert(
			slabs,
			P.box(
				ground,
				slabName,
				-- Hairline inset. A wider gap read as grass between asphalt cells.
				Vector3.new(math.max(0.5, q.w - 0.05), thickness, math.max(0.5, q.d - 0.05)),
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
		if math.abs(x) < 20 and z > -2 and z < 36 then
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
	local paint = P.folder(ground, "MarkingSlab")
	-- Synthetic stalls live outside MarkingSlab. Builder deletes that folder and keeps SiteMarkings.
	local lotPaint = P.folder(ground, "LotPaintSlab")
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
				Vector3.new(a[1], H.height(a[1], a[2]) + 0.42, a[2]),
				Vector3.new(b[1], H.height(b[1], b[2]) + 0.42, b[2]),
				math.clamp(stripeW, 0.4, 2.2),
				0.1,
				color,
				false
			)
		)
	end
	-- 9 x 18 ft stalls and a 24 ft aisle. County cells are small; cluster the fat ones into a lot.
	local stallCount = 0
	local function tracedAlready(x: number, z: number): boolean
		-- Lot K and the east pocket are painted by SiteMarkings. Don't draw a second grid.
		if z > 250 and x > -430 and x < 60 then
			return true
		end
		if x > 50 and x < 90 and z > 18 and z < 55 then
			return true
		end
		return false
	end
	local function addStripe(ax: number, az: number, bx: number, bz: number)
		if stallCount >= 200 then
			return
		end
		local mx, mz = (ax + bx) / 2, (az + bz) / 2
		if not grounded(mx, mz) or tracedAlready(mx, mz) then
			return
		end
		stallCount += 1
		table.insert(
			dress,
			P.beam(
				lotPaint,
				"StallStripe",
				Vector3.new(ax, H.height(ax, az) + 0.42, az),
				Vector3.new(bx, H.height(bx, bz) + 0.42, bz),
				0.7,
				0.12,
				"white",
				false
			)
		)
	end
	type Field = { x0: number, z0: number, x1: number, z1: number, area: number }
	local fields: { Field } = {}
	local function overlaps(a: Field, b: Field): boolean
		return a.x0 < b.x1 + 8 and b.x0 < a.x1 + 8 and a.z0 < b.z1 + 8 and b.z0 < a.z1 + 8
	end
	local function fillOf(f: Field): number
		return f.area / math.max(1, (f.x1 - f.x0) * (f.z1 - f.z0))
	end
	for _, q in source.patches do
		if q.material ~= "asphalt" or math.min(q.w, q.d) < 12 or math.max(q.w, q.d) < 18 then
			continue
		end
		local cx, cz = q.x + q.w / 2, q.z + q.d / 2
		if onBuilding(site, cx, cz) or inEntrance(cx, cz) then
			continue
		end
		local cell: Field = { x0 = q.x, z0 = q.z, x1 = q.x + q.w, z1 = q.z + q.d, area = q.w * q.d }
		local host: Field? = nil
		for _, field in fields do
			if overlaps(field, cell) then
				local merged: Field = {
					x0 = math.min(field.x0, cell.x0),
					z0 = math.min(field.z0, cell.z0),
					x1 = math.max(field.x1, cell.x1),
					z1 = math.max(field.z1, cell.z1),
					area = field.area + cell.area,
				}
				local long = math.max(merged.x1 - merged.x0, merged.z1 - merged.z0)
				if long <= 240 and fillOf(merged) >= 0.38 then
					host = field
					field.x0, field.z0, field.x1, field.z1, field.area =
						merged.x0, merged.z0, merged.x1, merged.z1, merged.area
					break
				end
			end
		end
		if not host then
			table.insert(fields, cell)
		end
	end
	local islandN = 0
	local poles = P.folder(ground, "LotPoles")
	local function lotPole(x: number, z: number)
		local hy = H.height(x, z)
		local pole = P.box(poles, "LightPole", Vector3.new(0.35, 22, 0.35), CFrame.new(x, hy + 11.2, z), "dark", true)
		pole.Material = Enum.Material.SmoothPlastic
		pole.Color = Color3.fromRGB(32, 34, 36)
		pole.Reflectance = 0
		local head = P.box(poles, "LightHead", Vector3.new(2.4, 0.4, 1.05), CFrame.new(x, hy + 22.35, z), "dark")
		head.Material = Enum.Material.SmoothPlastic
		head.Color = Color3.fromRGB(28, 30, 32)
		head.Reflectance = 0
		local lens = P.box(poles, "LightHead", Vector3.new(1.9, 0.08, 0.6), CFrame.new(x, hy + 22.1, z), "white", false)
		lens.Material = Enum.Material.SmoothPlastic
		lens.Color = Color3.fromRGB(255, 232, 196)
		local lamp = Instance.new("PointLight")
		lamp.Brightness = 1.2
		lamp.Range = 46
		lamp.Color = Color3.fromRGB(255, 228, 190)
		lamp.Parent = lens
		table.insert(dress, pole)
		table.insert(dress, head)
	end
	for _, field in fields do
		local width, depth = field.x1 - field.x0, field.z1 - field.z0
		local alongX = width >= depth
		local length = if alongX then width else depth
		local span = if alongX then depth else width
		if length < 36 or span < 20 or fillOf(field) < 0.38 then
			continue
		end
		-- One 18 ft stall band, a 24 ft aisle, then another band when the lot is deep enough.
		local bands = if span >= 60 then 2 else 1
		for band = 0, bands - 1 do
			local inset = 1.5 + band * (18 + 24)
			if inset + 18 > span - 1 then
				break
			end
			local n = math.min(math.floor((length - 4) / 9), 16)
			for i = 0, n do
				local t = 2 + i * 9
				if t > length - 2 then
					break
				end
				if alongX then
					addStripe(field.x0 + t, field.z0 + inset, field.x0 + t, field.z0 + inset + 18)
				else
					addStripe(field.x0 + inset, field.z0 + t, field.x0 + inset + 18, field.z0 + t)
				end
			end
		end
		-- One blue accessible stall and a lot sign, plus a drive tongue toward the south road.
		local hy2 = H.height((field.x0 + field.x1) / 2, (field.z0 + field.z1) / 2)
		local px = if alongX then field.x0 + 6.5 else field.x0 + 10
		local pz = if alongX then field.z0 + 10 else field.z0 + 6.5
		if grounded(px, pz) and not tracedAlready(px, pz) then
			local paintW = if alongX then 8.2 else 16.5
			local paintD = if alongX then 16.5 else 8.2
			local stall = P.box(
				lotPaint,
				"StallPaint",
				Vector3.new(paintW, 0.08, paintD),
				CFrame.new(px, hy2 + 0.46, pz),
				"metal",
				false
			)
			stall.Color = Color3.fromRGB(35, 78, 150)
			stall.Material = Enum.Material.SmoothPlastic
			local sign =
				P.pole(poles, "LotSign", Vector3.new(field.x0 + 1.2, hy2, field.z0 + 1.2), 8, 0.12, "dark", false)
			local board = P.box(
				poles,
				"LotSign",
				Vector3.new(1.6, 1.6, 0.12),
				CFrame.new(field.x0 + 1.2, hy2 + 7.2, field.z0 + 1.2),
				"metal",
				false
			)
			board.Color = Color3.fromRGB(20, 72, 150)
			table.insert(dress, sign)
			table.insert(dress, board)
		end
		local tongueZ = field.z1 + 14
		local tongueX = (field.x0 + field.x1) / 2
		if field.z1 < 140 and not onBuilding(site, tongueX, tongueZ) and not inEntrance(tongueX, tongueZ) then
			local ty = H.height(tongueX, tongueZ)
			local tongue = P.box(
				ground,
				"LotAisle",
				Vector3.new(24, 0.4, 28),
				CFrame.new(tongueX, ty + 0.16, tongueZ),
				"asphalt",
				true
			)
			table.insert(slabs, tongue)
			if not tracedAlready(tongueX, field.z1 - 2) and grounded(tongueX, field.z1 - 2) then
				local sy = H.height(tongueX, field.z1 - 2)
				table.insert(
					dress,
					P.beam(
						lotPaint,
						"StopBar",
						Vector3.new(tongueX - 8, sy + 0.4, field.z1 - 2),
						Vector3.new(tongueX + 8, sy + 0.4, field.z1 - 2),
						1.3,
						0.1,
						"yellow",
						false
					)
				)
				for bar = 0, 4 do
					local bz = tongueZ - 6 + bar * 2.2
					if grounded(tongueX, bz) then
						local by = H.height(tongueX, bz)
						table.insert(
							dress,
							P.beam(
								lotPaint,
								"CrosswalkBar",
								Vector3.new(tongueX - 7, by + 0.4, bz),
								Vector3.new(tongueX + 7, by + 0.4, bz),
								0.7,
								0.1,
								"white",
								false
							)
						)
					end
				end
				-- Shallow curb cut where the aisle meets the road. Local Y is thickness, so the ramp check stays quiet.
				local cut = P.box(
					lotPaint,
					"CurbCut",
					Vector3.new(8, 0.18, 5),
					CFrame.new(tongueX, sy + 0.22, field.z1 + 1.6),
					"concrete",
					true
				)
				table.insert(dress, cut)
			end
		end
		for _, side in { -1, 1 } do
			local ax = if side < 0 then field.x0 - 16 else field.x1 + 16
			local az = (field.z0 + field.z1) / 2
			if not onBuilding(site, ax, az) and not inEntrance(ax, az) and grounded(ax, az) then
				local ay = H.height(ax, az)
				local link =
					P.box(ground, "LotAisle", Vector3.new(28, 0.4, 22), CFrame.new(ax, ay + 0.16, az), "asphalt", true)
				table.insert(slabs, link)
			end
		end
		if islandN < 24 and span >= 36 and length >= 54 then
			local count = math.clamp(math.floor(length / 72), 1, 3)
			for k = 1, count do
				if islandN >= 24 then
					break
				end
				islandN += 1
				local t = length * k / (count + 1)
				local across = span * 0.5
				local ix = if alongX then field.x0 + t else field.x0 + across
				local iz = if alongX then field.z0 + across else field.z0 + t
				if grounded(ix, iz) then
					local islandY = H.height(ix, iz)
					local iw = if alongX then 8 else 18
					local id = if alongX then 18 else 8
					local island = P.box(
						ground,
						"LotIslandSlab",
						Vector3.new(iw, 0.55, id),
						CFrame.new(ix, islandY + 0.4, iz),
						"concrete",
						true
					)
					table.insert(dress, island)
					local plant = P.box(
						ground,
						"LotIslandPlant",
						Vector3.new(iw - 2.2, 1.3, id - 2.2),
						CFrame.new(ix, islandY + 1.55, iz),
						"shrub"
					)
					plant.CanCollide = false
					table.insert(dress, plant)
					lotPole(ix, iz)
				end
			end
		end
	end
	-- Lot K is south of the DEM tile. Stall stripes already use the clamped edge height.
	-- The deck is the asphalt those stripes sit on. Same material and color, so shared faces are not z-fights.
	for gx = -400, 20, 64 do
		for gz = 236, 500, 64 do
			local cx, cz = gx + 32, gz + 32
			local hy = H.height(cx, cz)
			local deck =
				P.box(ground, "LotSlab", Vector3.new(64, 0.4, 64), CFrame.new(cx, hy - 0.02, cz), "asphalt", true)
			table.insert(slabs, deck)
		end
	end
	for i = 0, 5 do
		local px = -360 + i * 70
		lotPole(px, 300)
		local hy = H.height(px + 10, 268)
		local stall = P.box(
			lotPaint,
			"StallPaint",
			Vector3.new(8.2, 0.08, 16.5),
			CFrame.new(px + 10, hy + 0.32, 268),
			"metal",
			false
		)
		stall.Color = Color3.fromRGB(35, 78, 150)
		stall.Material = Enum.Material.SmoothPlastic
		table.insert(dress, stall)
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
