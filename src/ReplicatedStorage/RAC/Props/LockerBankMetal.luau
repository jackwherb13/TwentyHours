--!strict
-- Single-tier ventilated steel lockers. opts.count is the door count (default 4).
-- Grey doors, green header rail, blank number plates. Front (door face) is -Z.
local Kit = require(script.Parent.Kit)

local DOOR_W = 1.15
local DEPTH = 1.42
local HEIGHT = 6.15
local DEFAULT_N = 4

local LockerBankMetal = {
	kind = "locker_bank_metal",
	size = Vector3.new(DEFAULT_N * DOOR_W + 0.16, HEIGHT, DEPTH),
}

local DOOR = Color3.fromRGB(86, 90, 96)
local SLOT = Color3.fromRGB(28, 30, 34)
local PLATE = Color3.fromRGB(214, 176, 64)

local function optNum(opts: { [string]: any }?, key: string, default: number, lo: number, hi: number): number
	local n = default
	if opts ~= nil then
		local v = opts[key]
		if type(v) == "number" then
			n = v :: number
		end
	end
	return math.max(lo, math.min(hi, n))
end

function LockerBankMetal.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("LockerBankMetal", cf)
	local C = Kit.Color
	local n = math.floor(optNum(opts, "count", DEFAULT_N, 1, 12) + 0.5)
	local length = n * DOOR_W + 0.14

	local function sliceY(
		name: string,
		size: Vector3,
		x: number,
		y: number,
		z: number,
		color: Color3,
		material: Enum.Material,
		collide: boolean?
	)
		local limit = 1.9
		local nSeg = math.max(1, math.ceil(size.Y / limit))
		local h = size.Y / nSeg
		local bottom = y - size.Y / 2
		for s = 0, nSeg - 1 do
			b:box(
				`{name}_{s}`,
				Vector3.new(size.X, h, size.Z),
				Kit.at(x, bottom + h * (s + 0.5), z),
				color,
				material,
				collide
			)
		end
	end

	local capH = 0.06
	local headerH = 0.16
	local headerTop = HEIGHT - capH
	local carcassTop = headerTop - headerH
	local carcassBottom = 0.35
	local carcassH = carcassTop - carcassBottom
	b:box(
		"Carcass",
		Vector3.new(length, carcassH, DEPTH - 0.08),
		Kit.at(0, carcassBottom + carcassH / 2, 0.04),
		C.SteelGrey,
		Enum.Material.Metal,
		true
	)
	b:box("Base", Vector3.new(length + 0.04, 0.32, DEPTH), Kit.at(0, 0.16, 0), C.SteelBlack, Enum.Material.Metal, true)
	b:box(
		"Header",
		Vector3.new(length + 0.02, headerH, DEPTH + 0.02),
		Kit.at(0, carcassTop + headerH / 2, 0),
		C.MasonGreen,
		Enum.Material.Metal
	)
	b:box(
		"TopCap",
		Vector3.new(length + 0.06, capH, DEPTH + 0.06),
		Kit.at(0, headerTop + capH / 2, 0),
		C.SteelBlack,
		Enum.Material.Metal
	)

	for i = 0, n do
		local x = -length / 2 + 0.07 + i * DOOR_W
		sliceY(
			`Mullion{i}`,
			Vector3.new(0.07, HEIGHT - 0.48, 0.08),
			x,
			0.4 + (HEIGHT - 0.48) / 2,
			-DEPTH / 2 + 0.02,
			C.SteelGrey,
			Enum.Material.Metal,
			false
		)
	end

	for i = 0, n - 1 do
		local x = -length / 2 + 0.07 + (i + 0.5) * DOOR_W
		local doorW = DOOR_W - 0.1
		sliceY(
			`Door{i}`,
			Vector3.new(doorW, HEIGHT - 0.62, 0.06),
			x,
			0.42 + (HEIGHT - 0.62) / 2,
			-DEPTH / 2 - 0.01,
			DOOR,
			Enum.Material.Metal,
			true
		)
		for s = 0, 4 do
			b:box(
				`Vent{i}_{s}`,
				Vector3.new(doorW * 0.62, 0.045, 0.03),
				Kit.at(x, HEIGHT - 1.15 - s * 0.16, -DEPTH / 2 - 0.05),
				SLOT,
				Enum.Material.Metal
			)
		end
		b:box(
			`Handle{i}`,
			Vector3.new(0.08, 0.55, 0.08),
			Kit.at(x + doorW * 0.32, 3.15, -DEPTH / 2 - 0.08),
			C.Chrome,
			Enum.Material.Metal
		)
		b:box(
			`Pull{i}`,
			Vector3.new(0.16, 0.1, 0.1),
			Kit.at(x + doorW * 0.32, 2.95, -DEPTH / 2 - 0.1),
			C.Chrome,
			Enum.Material.Metal
		)
		b:cyl(
			`Lock{i}`,
			0.05,
			0.1,
			Kit.alongZ(x + doorW * 0.32, 3.5, -DEPTH / 2 - 0.06),
			C.SteelBlack,
			Enum.Material.Metal
		)
		b:box(
			`Plate{i}`,
			Vector3.new(0.28, 0.16, 0.02),
			Kit.at(x, HEIGHT - 0.55, -DEPTH / 2 - 0.05),
			PLATE,
			Enum.Material.Metal
		)
		b:box(
			`Num{i}`,
			Vector3.new(0.14, 0.06, 0.01),
			Kit.at(x, HEIGHT - 0.55, -DEPTH / 2 - 0.065),
			C.SteelBlack,
			Enum.Material.SmoothPlastic
		)
		b:cyl(
			`Hinge{i}a`,
			0.08,
			0.07,
			Kit.vertical(x - doorW * 0.46, 4.6, -DEPTH / 2 - 0.02),
			C.SteelGrey,
			Enum.Material.Metal
		)
		b:cyl(
			`Hinge{i}b`,
			0.08,
			0.07,
			Kit.vertical(x - doorW * 0.46, 2.2, -DEPTH / 2 - 0.02),
			C.SteelGrey,
			Enum.Material.Metal
		)
	end

	sliceY(
		"SideL",
		Vector3.new(0.06, HEIGHT - 0.3, DEPTH),
		-length / 2 + 0.03,
		HEIGHT / 2,
		0,
		C.SteelGrey,
		Enum.Material.Metal,
		true
	)
	sliceY(
		"SideR",
		Vector3.new(0.06, HEIGHT - 0.3, DEPTH),
		length / 2 - 0.03,
		HEIGHT / 2,
		0,
		C.SteelGrey,
		Enum.Material.Metal,
		true
	)
	return b:done()
end

return LockerBankMetal
