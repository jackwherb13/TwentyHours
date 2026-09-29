--!strict
-- Open wood team lockers: top shoe cubby, hanging stall, blank plate, bench seat.
-- IMG_0377, IMG_0378. No names. opts.count is the number of stalls (default 4).
-- You approach from -Z; the bench is the near side.
local Kit = require(script.Parent.Kit)

local STALL_W = 1.58
local BODY_D = 1.55
local BENCH_D = 1.15
local HEIGHT = 6.7
local DEFAULT_N = 4
local TOTAL_D = BODY_D + BENCH_D

local LockerBankWood = {
	kind = "locker_bank_wood",
	size = Vector3.new(DEFAULT_N * STALL_W + 0.16, HEIGHT, TOTAL_D),
}

local BACK = Color3.fromRGB(92, 64, 40)
local PLATE = Color3.fromRGB(186, 154, 78)
local SEAT = Color3.fromRGB(196, 154, 102)

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

function LockerBankWood.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("LockerBankWood", cf)
	local C = Kit.Color
	local n = math.floor(optNum(opts, "count", DEFAULT_N, 1, 10) + 0.5)
	local length = n * STALL_W + 0.12
	local backZ = TOTAL_D / 2

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
		local nSeg = math.max(1, math.ceil(size.Y / 2.15))
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
	local frontZ = backZ - BODY_D
	local benchFront = -TOTAL_D / 2

	b:box(
		"Plinth",
		Vector3.new(length, 0.22, BODY_D),
		Kit.at(0, 0.11, (frontZ + backZ) / 2),
		C.WoodLocker,
		Enum.Material.Wood,
		true
	)
	b:box(
		"Back",
		Vector3.new(length - 0.08, HEIGHT - 0.28, 0.08),
		Kit.at(0, 0.22 + (HEIGHT - 0.28) / 2, backZ - 0.06),
		BACK,
		Enum.Material.Wood
	)
	b:box(
		"Top",
		Vector3.new(length, 0.1, BODY_D),
		Kit.at(0, HEIGHT - 0.05, (frontZ + backZ) / 2),
		C.WoodLocker,
		Enum.Material.Wood
	)
	b:box(
		"CubbyShelf",
		Vector3.new(length - 0.12, 0.08, BODY_D - 0.16),
		Kit.at(0, 5.35, (frontZ + backZ) / 2 + 0.02),
		C.WoodLocker,
		Enum.Material.Wood,
		true
	)
	b:box(
		"CubbyLip",
		Vector3.new(length - 0.16, 0.28, 0.08),
		Kit.at(0, 5.52, frontZ + 0.06),
		C.WoodLocker,
		Enum.Material.Wood
	)
	b:box(
		"ShoeShelf",
		Vector3.new(length - 0.16, 0.07, BODY_D - 0.28),
		Kit.at(0, 0.55, (frontZ + backZ) / 2),
		SEAT,
		Enum.Material.Wood
	)

	for i = 0, n do
		local x = -length / 2 + 0.06 + i * STALL_W
		sliceY(
			`Div{i}`,
			Vector3.new(0.08, HEIGHT - 0.16, BODY_D - 0.06),
			x,
			(HEIGHT - 0.16) / 2 + 0.04,
			(frontZ + backZ) / 2,
			C.WoodLocker,
			Enum.Material.Wood,
			true
		)
	end

	for i = 0, n - 1 do
		local x = -length / 2 + 0.06 + (i + 0.5) * STALL_W
		b:box(`Plate{i}`, Vector3.new(0.42, 0.16, 0.03), Kit.at(x, 5.5, frontZ + 0.055), PLATE, Enum.Material.Metal)
		b:box(
			`PlateLine{i}`,
			Vector3.new(0.22, 0.025, 0.012),
			Kit.at(x, 5.5, frontZ + 0.038),
			BACK,
			Enum.Material.SmoothPlastic
		)
		local divX = x - STALL_W / 2
		b:cyl(`Hook{i}`, 0.28, 0.06, Kit.alongZ(divX + 0.02, 4.52, frontZ + 0.3), C.Chrome, Enum.Material.Metal)
		b:cyl(`HookTip{i}`, 0.12, 0.05, Kit.vertical(divX + 0.02, 4.52, frontZ + 0.4), C.Chrome, Enum.Material.Metal)
		b:box(
			`CubbyStop{i}`,
			Vector3.new(STALL_W - 0.16, 0.9, 0.05),
			Kit.at(x, 6.0, backZ - 0.14),
			BACK,
			Enum.Material.Wood
		)
		b:cyl(`Rod{i}`, STALL_W - 0.06, 0.05, Kit.at(x, 4.85, frontZ + 0.35), C.Chrome, Enum.Material.Metal)
	end

	local seatY = 1.5
	local seatZ = benchFront + BENCH_D / 2 + 0.02
	b:box(
		"Bench",
		Vector3.new(length - 0.08, 0.12, BENCH_D - 0.12),
		Kit.at(0, seatY, seatZ),
		SEAT,
		Enum.Material.Wood,
		true
	)
	b:box(
		"BenchNose",
		Vector3.new(length - 0.04, 0.08, 0.08),
		Kit.at(0, seatY - 0.02, benchFront + 0.08),
		C.WoodLocker,
		Enum.Material.Wood
	)
	local pedestals = math.max(2, math.floor(n / 2) + 1)
	for i = 0, pedestals - 1 do
		local x = -length / 2 + length * ((i + 0.5) / pedestals)
		b:box(
			`Leg{i}`,
			Vector3.new(0.18, seatY - 0.12, 0.18),
			Kit.at(x, (seatY - 0.12) / 2, seatZ),
			C.SteelBlack,
			Enum.Material.Metal,
			true
		)
		b:box(
			`Foot{i}`,
			Vector3.new(0.42, 0.08, BENCH_D - 0.2),
			Kit.at(x, 0.04, seatZ),
			C.SteelBlack,
			Enum.Material.Metal
		)
		b:box(
			`Bracket{i}`,
			Vector3.new(0.28, 0.08, 0.22),
			Kit.at(x, seatY - 0.12, seatZ),
			C.SteelGrey,
			Enum.Material.Metal
		)
	end
	b:box("Stretcher", Vector3.new(length - 0.8, 0.08, 0.1), Kit.at(0, 0.35, seatZ), C.SteelBlack, Enum.Material.Metal)

	return b:done()
end

return LockerBankWood
