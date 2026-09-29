--!strict
-- Edit-mode only. Writes the 32 ft horizon DEM, then Campus.Terrain (16 ft + 4 ft fine restamp).
local CampusTerrain = require(script.Parent.Parent.Campus.Terrain)
local Height = require(script.Parent.Height)
local Data = Height.data
local CampusHeight = require(script.Parent.Parent.Campus.Height)

local TerrainBuilder = {}

local materials = {
	Enum.Material.Grass,
	Enum.Material.Asphalt,
	Enum.Material.Concrete,
	Enum.Material.Rock,
	Enum.Material.Ground,
	Enum.Material.LeafyGrass,
	Enum.Material.Water,
}

function TerrainBuilder.build(terrain: Terrain): { [string]: number }
	local resolution = 4
	local function materialAt(x: number, z: number): number
		local u = math.clamp((x - Data.x0) / Data.step - 0.5, 0, Data.nx - 1.001)
		local v = math.clamp((z - Data.z0) / Data.step - 0.5, 0, Data.nz - 1.001)
		local i, j = math.floor(u) + 1, math.floor(v) + 1
		return tonumber(string.sub(Data.materials[j], i, i)) :: number
	end
	local count = 0
	local tile = 128
	local x1, z1 = Data.x0 + Data.nx * Data.step, Data.z0 + Data.nz * Data.step
	local sx = Data.x0
	while sx < x1 - 0.01 do
		local sz = Data.z0
		while sz < z1 - 0.01 do
			local ex = math.min(sx + tile, x1)
			local ez = math.min(sz + tile, z1)
			-- Skip tiles fully inside the campus coarse box (Campus.Terrain owns those voxels).
			local midX, midZ = (sx + ex) / 2, (sz + ez) / 2
			if not CampusHeight.inside(midX, midZ) then
				local rough = Region3.new(Vector3.new(sx, Data.yMin, sz), Vector3.new(ex, Data.yMax, ez))
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
			end
			sz += tile
		end
		task.wait()
		sx += tile
	end
	local campus = CampusTerrain.build(terrain)
	terrain:SetAttribute("RAC_Horizon_DEM", "USGS 3DEP 1/3 arc-sec + 1 m; 32 ft horizon, 16 ft campus, 4 ft fine")
	return { horizonVoxels = count, coarseVoxels = campus.coarseVoxels, fineVoxels = campus.fineVoxels }
end

return TerrainBuilder
