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
-- Grid is NAVD88 minus Level 1. DATUM stays 0; the south walk is lifted in height().
local DATUM = 0

local function bilinear(x: number, z: number): number
	local u = math.clamp((x - Data.x0) / Data.step - 0.5, 0, Data.nx - 1.001)
	local v = math.clamp((z - Data.z0) / Data.step - 0.5, 0, Data.nz - 1.001)
	local i, j = math.floor(u) + 1, math.floor(v) + 1
	local a, b = u % 1, v % 1
	return DATUM
		+ heights[j][i] * (1 - a) * (1 - b)
		+ heights[j][i + 1] * a * (1 - b)
		+ heights[j + 1][i] * (1 - a) * b
		+ heights[j + 1][i + 1] * a * b
end

local function insidePad(x: number, z: number): boolean
	local pads = Data.pad
	if not pads then
		return false
	end
	for _, poly in pads do
		local inside = false
		local j = #poly
		for i, point in poly do
			local b = poly[j]
			if (point[2] > z) ~= (b[2] > z) and x < (b[1] - point[1]) * (z - point[2]) / (b[2] - point[2]) + point[1] then
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

function Heightfield.height(x: number, z: number): number
	-- Roof lidar inside the footprint is not the floor. Fill it so the lobby is not a bridge.
	if insidePad(x, z) then
		return -0.4
	end
	local h = bilinear(x, z)
	local skirt = false
	for _, dist in { 8, 16 } do
		for k = 0, 7 do
			local a = k * math.pi / 4
			if insidePad(x + math.cos(a) * dist, z + math.sin(a) * dist) then
				h = math.max(h, if dist == 8 then -0.8 else -2.0)
				skirt = true
				break
			end
		end
		if skirt then
			break
		end
	end
	-- South door lidar is about -3 ft and the circle is -7 to -12. The stair lands on a
	-- short concrete walk, then the drive falls back toward the surveyed circle.
	if x > -70 and x < -12 and z > -1 and z < 32 then
		h = math.max(h, -4.15)
	elseif x > -100 and x < 30 and z >= 32 and z < 84 then
		h = math.max(h, -4.15 - (z - 32) * 0.12)
	end
	return h
end
function Heightfield.cell(x: number, z: number): (number, number)
	return heights[z][x], tonumber(string.sub(Data.materials[z], x, x)) :: number
end
Heightfield.data = Data
return Heightfield
