--!strict
-- Edit-mode only. Writes the coarse campus DEM, then restores the exterior 4 ft grid on top so the seam matches.
local FineTerrain = require(script.Parent.Parent.Terrain)
local Height = require(script.Parent.Height)
local Data = Height.data

local TerrainBuilder = {}

function TerrainBuilder.build(terrain: Terrain): { [string]: number }
	local materials = {
		Enum.Material.Grass,
		Enum.Material.Asphalt,
		Enum.Material.Concrete,
		Enum.Material.Rock,
		Enum.Material.Ground,
		Enum.Material.LeafyGrass,
		Enum.Material.Water,
	}
	local resolution = 16
	local function materialAt(x: number, z: number): number
		local u = math.clamp((x - Data.x0) / Data.step - 0.5, 0, Data.nx - 1.001)
		local v = math.clamp((z - Data.z0) / Data.step - 0.5, 0, Data.nz - 1.001)
		local i, j = math.floor(u) + 1, math.floor(v) + 1
		return tonumber(string.sub(Data.materials[j], i, i)) :: number
	end
	local count = 0
	local tile = 96
	local x1, z1 = Data.x0 + Data.nx * Data.step, Data.z0 + Data.nz * Data.step
	local sx = Data.x0
	while sx < x1 - 0.01 do
		local sz = Data.z0
		while sz < z1 - 0.01 do
			local rough = Region3.new(
				Vector3.new(sx, Data.yMin, sz),
				Vector3.new(math.min(sx + tile, x1), Data.yMax, math.min(sz + tile, z1))
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
						local h = Height.at(x, z)
						local fill = math.clamp((h - bottom) / resolution, 0, 1)
						local material = materialAt(x, z)
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
	-- Re-stamp the fine RAC DEM so the overlap is bit-identical to the exterior agent.
	local fine = FineTerrain.build(terrain)
	terrain:SetAttribute("RAC_Campus_DEM", "USGS 3DEP 1m + VA_NorthernVA_B22; 16 ft coarse, 4 ft fine overlap")
	return { coarseVoxels = count, fineVoxels = fine.voxels, yMin = Data.yMin, yMax = Data.yMax }
end

return TerrainBuilder
