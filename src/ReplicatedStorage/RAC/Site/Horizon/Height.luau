--!strict
-- 32 ft horizon DEM. Inside the campus 16 ft box this matches Campus.Height.
local Data = require(script.Parent.HorizonData)
local CampusHeight = require(script.Parent.Parent.Campus.Height)

local heights: { { number } } = {}
for z, row in Data.rows do
	local values = {}
	for token in string.gmatch(row, "[^,]+") do
		table.insert(values, (tonumber(token) :: number) / 100)
	end
	heights[z] = values
end

local Height = {}

function Height.far(x: number, z: number): number
	local u = math.clamp((x - Data.x0) / Data.step - 0.5, 0, Data.nx - 1.001)
	local v = math.clamp((z - Data.z0) / Data.step - 0.5, 0, Data.nz - 1.001)
	local i, j = math.floor(u) + 1, math.floor(v) + 1
	local a, b = u % 1, v % 1
	local row = heights[j]
	local row2 = heights[j + 1] or row
	return row[i] * (1 - a) * (1 - b)
		+ (row[i + 1] or row[i]) * a * (1 - b)
		+ row2[i] * (1 - a) * b
		+ (row2[i + 1] or row2[i]) * a * b
end

function Height.at(x: number, z: number): number
	if CampusHeight.inside(x, z) then
		return CampusHeight.at(x, z)
	end
	return Height.far(x, z)
end

Height.data = Data
return Height
