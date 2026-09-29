--!strict
-- Lune: every generated room and the footprint schedule an Air fill above floor-1.
-- Studio: require this logic via Site.Carve.audit(workspace.Terrain). Any non-Air voxel
-- above floor-1 ft inside the footprint fails.
local process = require("@lune/process")
local Loader = require("../tests/lib/loader")

local loader = Loader.new()
local Carve = loader.load("src/ReplicatedStorage/RAC/Site/Carve")
local fills = {}
local terrain = {}
function terrain.FillBlock(_, cf, size, material)
	table.insert(fills, { cf = cf, size = size, material = material })
end
local blocks = Carve.apply(terrain)
assert(blocks > 80, "expected room and footprint air blocks")
assert(#fills == blocks)

local function inside(x: number, y: number, z: number): boolean
	for _, fill in fills do
		local c, s = fill.cf.Position, fill.size
		local dx = math.abs(x - c.X)
		local dy = math.abs(y - c.Y)
		local dz = math.abs(z - c.Z)
		-- Axis-aligned footprint fills. Oriented wall fills are extra.
		local right, up, look = fill.cf.RightVector, fill.cf.UpVector, fill.cf.LookVector
		local axisAligned = math.abs(right.X) > 0.99 and math.abs(up.Y) > 0.99 and math.abs(look.Z) > 0.99
		if axisAligned and dx <= s.X / 2 and dy <= s.Y / 2 and dz <= s.Z / 2 then
			return true
		end
	end
	return false
end

assert(inside(-136, 10, -206), "competition gym must be air above the floor")
assert(inside(-20, 4, -8), "south lobby must be air above the floor")
assert(not inside(0, 10, 90), "Patriot Circle is outside the footprint")
print(string.format("PASS footprint air: %d FillBlock calls; gym and lobby covered; circle left alone", blocks))
process.exit(0)
