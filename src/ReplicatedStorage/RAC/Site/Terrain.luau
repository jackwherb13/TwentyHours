--!strict
-- Edit-mode only. Replaces voxels only inside this site's bounded region.
local Heightfield = require(script.Parent.Heightfield)
local TerrainBuilder = {}
function TerrainBuilder.build(terrain: Terrain): { [string]: number }
	local d = Heightfield.data
	local materials =
		{ Enum.Material.Grass, Enum.Material.Asphalt, Enum.Material.Concrete, Enum.Material.Rock, Enum.Material.Ground }
	local resolution = 4
	local function materialAt(x: number, z: number): number
		local u = math.clamp((x - d.x0) / d.step - 0.5, 0, d.nx - 1.001)
		local v = math.clamp((z - d.z0) / d.step - 0.5, 0, d.nz - 1.001)
		local i, j = math.floor(u) + 1, math.floor(v) + 1
		return tonumber(string.sub(d.materials[j], i, i)) :: number
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
						-- Roof-classified lidar inside the footprint was growing grass through floors.
						if insidePad(x, z) then
							h = math.min(h, -1.5)
							material = 3
						elseif math.abs(x) < 34 and z > -1 and z < 64 then
							-- Stair, ramp, and apron. Concrete does not grow grass blades through the treads.
							material = 3
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
	return { columns = d.nx * d.nz, voxels = count, yMin = d.yMin, yMax = d.yMax }
end
return TerrainBuilder
