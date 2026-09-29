--!strict
-- Edit-mode only. Replaces voxels only inside this site's bounded region.
local Heightfield = require(script.Parent.Heightfield)
local Carve = require(script.Parent.Carve)
local TerrainBuilder = {}
function TerrainBuilder.build(terrain: Terrain): { [string]: number }
	local d = Heightfield.data
	local materials =
		{ Enum.Material.Grass, Enum.Material.Asphalt, Enum.Material.Concrete, Enum.Material.Rock, Enum.Material.Ground }
	local resolution = 4
	local function rawMaterial(x: number, z: number): number
		local u = math.clamp((x - d.x0) / d.step - 0.5, 0, d.nx - 1.001)
		local v = math.clamp((z - d.z0) / d.step - 0.5, 0, d.nz - 1.001)
		local i, j = math.floor(u) + 1, math.floor(v) + 1
		return tonumber(string.sub(d.materials[j], i, i)) :: number
	end
	local function materialAt(x: number, z: number): number
		local m = rawMaterial(x, z)
		if m ~= 1 then
			return m
		end
		-- Close grass inside lots. A cell with several asphalt neighbors is pavement.
		local paved = 0
		for _, dist in { 4, 8, 12 } do
			for _, o in { { dist, 0 }, { -dist, 0 }, { 0, dist }, { 0, -dist } } do
				if rawMaterial(x + o[1], z + o[2]) == 2 then
					paved += 1
				end
			end
		end
		-- Keep the entrance lawn. Everywhere else, two asphalt neighbors close a grass gap in a lot.
		local entranceLawn = math.abs(x) < 48 and z >= 34 and z < 115
		if paved >= 2 and not entranceLawn then
			return 2
		end
		return m
	end
	local function insidePad(x: number, z: number): boolean
		local pads = d.pad
		if not pads then
			return false
		end
		for _, poly in pads do
			local inside = false
			local j = #poly
			for i, a in poly do
				local b = poly[j]
				if (a[2] > z) ~= (b[2] > z) and x < (b[1] - a[1]) * (z - a[2]) / (b[2] - a[2]) + a[1] then
					inside = not inside
				end
				j = i
			end
			if inside then
				return true
			end
		end
		return false
	end
	local function nearLine(x: number, z: number, pts: { { number } }, half: number): boolean
		local limit = half * half
		for i = 1, #pts - 1 do
			local ax, az = pts[i][1], pts[i][2]
			local bx, bz = pts[i + 1][1], pts[i + 1][2]
			local dx, dz = bx - ax, bz - az
			local len2 = dx * dx + dz * dz
			local t = if len2 > 1 then math.clamp(((x - ax) * dx + (z - az) * dz) / len2, 0, 1) else 0
			local ex, ez = x - (ax + dx * t), z - (az + dz * t)
			if ex * ex + ez * ez < limit then
				return true
			end
		end
		return false
	end
	-- Patriot Circle centerline from the digitized double-yellow. The material grid calls this band grass.
	local patriotWest = {
		{ -410, 186.2 },
		{ -280, 188.5 },
		{ -100, 191.5 },
		{ 20, 193.5 },
		{ 55, 179.6 },
		{ 82, 157.6 },
	}
	local patriotEast = {
		{ 200, 141.0 },
		{ 280, 147.5 },
		{ 360, 160.0 },
	}
	local function carriageway(x: number, z: number): boolean
		local dx, dz = x - 147, z - 147
		local r2 = dx * dx + dz * dz
		-- Island stays grass (r < 33). The ring matches the inner curb at 36 ft and the outer edge near 66 ft.
		if r2 > 33 * 33 and r2 < 68 * 68 then
			return true
		end
		return nearLine(x, z, patriotWest, 16) or nearLine(x, z, patriotEast, 16)
	end
	local count = 0
	-- WriteVoxels snaps regions onto the 4-stud grid. The lidar origin is not on that grid
	-- after the building-frame shift, so each tile is expanded and sampled at voxel centers.
	local tile = 80
	local x1, z1 = d.x0 + d.nx * d.step, d.z0 + d.nz * d.step
	local sx = d.x0
	while sx < x1 - 0.01 do
		local sz = d.z0
		while sz < z1 - 0.01 do
			local rough = Region3.new(
				Vector3.new(sx, d.yMin, sz),
				Vector3.new(math.min(sx + tile, x1), d.yMax, math.min(sz + tile, z1))
			)
			local region = rough:ExpandToGrid(resolution)
			local size = region.Size
			local vx = math.round(size.X / resolution)
			local vy = math.round(size.Y / resolution)
			local vz = math.round(size.Z / resolution)
			local origin = region.CFrame.Position - size / 2
			local mats, occupancy = {}, {}
			for ix = 1, vx do
				mats[ix], occupancy[ix] = {}, {}
				local x = origin.X + (ix - 0.5) * resolution
				for iy = 1, vy do
					mats[ix][iy], occupancy[ix][iy] = {}, {}
					local bottom = origin.Y + (iy - 1) * resolution
					for iz = 1, vz do
						local z = origin.Z + (iz - 0.5) * resolution
						local h = Heightfield.height(x, z)
						local material = materialAt(x, z)
						local flight = x > -14 and x < 20 and z > -1 and z < 35
						local yard = x < -194 and x > -212 and z < -230 and z > -274
						-- East RAC lot. The grid stores it as concrete and grass beside the glass corner.
						local eastLot = x > 52 and x < 175 and z > -6 and z < 56
						if insidePad(x, z) or flight then
							material = 3
						elseif yard or carriageway(x, z) or (eastLot and (material == 1 or material == 3)) then
							-- Roads and the east lot stay on lidar height. Only the material changes.
							material = 2
						else
							-- The south approach is baked concrete from an old plaza. Photos show lawn.
							local southLawn = math.abs(x) < 42 and z >= 36 and z < 102 and material == 3
							local westCheek = x < -14 and x > -46 and z > 8 and z < 36 and material == 3
							if southLawn or westCheek then
								material = 1
							elseif material == 1 and not (math.abs(x) < 48 and z >= 34 and z < 115) then
								local left = rawMaterial(x - 8, z) == 2
								local right = rawMaterial(x + 8, z) == 2
								local north = rawMaterial(x, z - 8) == 2
								local south = rawMaterial(x, z + 8) == 2
								if (left and right) or (north and south) then
									material = 2
								end
							end
						end
						local fill = math.clamp((h - bottom) / resolution, 0, 1)
						mats[ix][iy][iz] = if fill == 0 then Enum.Material.Air else materials[material]
						occupancy[ix][iy][iz] = fill
					end
				end
			end
			terrain:WriteVoxels(region, resolution, mats, occupancy)
			count += vx * vy * vz
			sz += tile
		end
		task.wait()
		sx += tile
	end
	terrain:SetAttribute(
		"RAC_DEM_Source",
		"USGS VA_NorthernVA_B22 LAZ classified ground; Fairfax planimetrics; VGIN imagery"
	)
	terrain:SetAttribute("RAC_GridBearingDeg", 10.43)
	terrain:SetAttribute("RAC_Heightmap", "verification/exterior/heightmap.png")
	-- Terrain:ImportHeightmap is not a script API. WriteVoxels applies the same grid.
	local lighting = game:GetService("Lighting")
	lighting.FogStart = 520
	lighting.FogEnd = 980
	lighting.FogColor = Color3.fromRGB(186, 196, 188)
	local plate = workspace:FindFirstChild("Baseplate")
	if plate and plate:IsA("BasePart") then
		plate.Transparency = 1
		plate.CanCollide = false
	end
	local carved = Carve.apply(terrain)
	return { columns = d.nx * d.nz, voxels = count, carved = carved, yMin = d.yMin, yMax = d.yMax }
end
return TerrainBuilder
