--!strict
local Data = require(script.Parent.TerrainData)
local Heightfield = {}
local heights: { { number } } = {}
for z, row in Data.rows do
	local values = {}
	for token in string.gmatch(row, "[^,]+") do
		table.insert(values, (tonumber(token) :: number) / 100)
	end
	heights[z] = values
end
function Heightfield.height(x: number, z: number): number
	local u = math.clamp((x - Data.x0) / Data.step - 0.5, 0, Data.nx - 1.001)
	local v = math.clamp((z - Data.z0) / Data.step - 0.5, 0, Data.nz - 1.001)
	local i, j = math.floor(u) + 1, math.floor(v) + 1
	local a, b = u % 1, v % 1
	return heights[j][i] * (1 - a) * (1 - b)
		+ heights[j][i + 1] * a * (1 - b)
		+ heights[j + 1][i] * (1 - a) * b
		+ heights[j + 1][i + 1] * a * b
end
function Heightfield.cell(x: number, z: number): (number, number)
	return heights[z][x], tonumber(string.sub(Data.materials[z], x, x)) :: number
end
Heightfield.data = Data
return Heightfield
