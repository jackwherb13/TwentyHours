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
-- Grid is NAVD88 minus Level 1. DATUM stays 0. Roads keep raw lidar; only the door flight is filled.
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
			if
				(point[2] > z) ~= (b[2] > z)
				and x < (b[1] - point[1]) * (z - point[2]) / (b[2] - point[2]) + point[1]
			then
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
	local raw = bilinear(x, z)
	-- West L2 doors (l2_w040 at x=-351.5, l2_w023 at x=-359.5). Raw lidar is +22 to +27,
	-- which buries a sill at y=20. Land on the sill, then climb back to the hillside.
	local function westPad(doorX: number, z0: number, z1: number): number?
		if z < z0 or z > z1 or x > doorX + 1.5 or x < doorX - 40 then
			return nil
		end
		local dist = doorX - x
		if dist <= 16 then
			return 20
		end
		local t = math.clamp((dist - 16) / 24, 0, 1)
		return 20 * (1 - t) + raw * t
	end
	local west = westPad(-351.5, -116, -88) or westPad(-359.5, -100, -72)
	if west then
		return west
	end
	local h = raw
	for _, dist in { 4, 9 } do
		local hit = false
		for k = 0, 7 do
			local a = k * math.pi / 4
			if insidePad(x + math.cos(a) * dist, z + math.sin(a) * dist) then
				h = math.max(h, if dist == 4 then -0.35 else -1.1)
				hit = true
				break
			end
		end
		if hit then
			break
		end
	end
	-- Fill only the bowl under the door-centered flight (Exterior: 11 risers, toe z = 30.2).
	-- Patriot Circle and the lawn stay on raw lidar.
	if x > -14 and x < 20 and z >= -1 and z < 35 then
		local flightStart = 6.65
		local toe = 30.2
		local drop = 11 * (7 / 12)
		local walk = 0.0
		if z > flightStart then
			local t = math.clamp((z - flightStart) / (toe - flightStart), 0, 1)
			walk = -drop * t
		end
		return math.max(raw, walk - 0.95)
	end
	return h
end
function Heightfield.cell(x: number, z: number): (number, number)
	return heights[z][x], tonumber(string.sub(Data.materials[z], x, x)) :: number
end
Heightfield.data = Data
return Heightfield
