--!strict
-- Coarse campus heightfield. Inside the exterior agent's 4 ft grid this matches Heightfield.height.
local Data = require(script.Parent.CampusData)
local Fine = require(script.Parent.Parent.Heightfield)

local heights: { { number } } = {}
for z, row in Data.rows do
	local values = {}
	for token in string.gmatch(row, "[^,]+") do
		table.insert(values, (tonumber(token) :: number) / 100)
	end
	heights[z] = values
end

local Height = {}

function Height.coarse(x: number, z: number): number
	local u = math.clamp((x - Data.x0) / Data.step - 0.5, 0, Data.nx - 1.001)
	local v = math.clamp((z - Data.z0) / Data.step - 0.5, 0, Data.nz - 1.001)
	local i, j = math.floor(u) + 1, math.floor(v) + 1
	local a, b = u % 1, v % 1
	return heights[j][i] * (1 - a) * (1 - b)
		+ heights[j][i + 1] * a * (1 - b)
		+ heights[j + 1][i] * (1 - a) * b
		+ heights[j + 1][i + 1] * a * b
end

function Height.at(x: number, z: number): number
	local f = Data.fine
	if x >= f.x0 and z >= f.z0 and x <= f.x0 + f.nx * f.step and z <= f.z0 + f.nz * f.step then
		return Fine.height(x, z)
	end
	return Height.coarse(x, z)
end

Height.data = Data
return Height
