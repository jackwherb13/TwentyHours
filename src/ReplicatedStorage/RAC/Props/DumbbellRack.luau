--!strict
-- Two-tier hex dumbbell rack, 5–100 lb pairs (IMG_0318).
-- Grey A-frame saddles like the RAC dumbbell bay. Heads are block-hex urethane, chrome handles.
-- Bottom row holds 55–100, top row 5–50, columns aligned. Pivot bottom-center, front faces -Z.
local Kit = require(script.Parent.Kit)

local DumbbellRack = {
	kind = "dumbbell_rack",
	size = Vector3.new(8.05, 2.95, 1.9),
}

local TOP = { 5, 10, 15, 20, 25, 30, 35, 40, 45, 50 }
local BOTTOM = { 55, 60, 65, 70, 75, 80, 85, 90, 95, 100 }

local function optNum(opts: { [string]: any }?, key: string, default: number, lo: number, hi: number): number
	local v = if opts ~= nil then opts[key] else nil
	if type(v) == "number" then
		return math.clamp(v :: number, lo, hi)
	end
	return default
end

local function acrossOf(lb: number): number
	return 0.26 + (lb - 5) / 95 * 0.4
end

local function centers(weights: { number }, extra: number): { number }
	local gaps: { number } = {}
	local total = 0
	for i, lb in weights do
		local g = math.max(acrossOf(lb) + 0.16, 0.62) + extra
		gaps[i] = g
		total += g
	end
	local xs: { number } = {}
	local x = -total / 2
	for i, g in gaps do
		xs[i] = x + g / 2
		x += g
	end
	return xs
end

local function leg(b: any, name: string, x: number, z0: number, z1: number, color: Color3)
	local yTop = 2.65
	for i = 0, 2 do
		local t0, t1 = i / 3, (i + 1) / 3
		local a = Vector3.new(x, 0.06 + (yTop - 0.06) * t0, z0 + (z1 - z0) * t0)
		local c = Vector3.new(x, 0.06 + (yTop - 0.06) * t1, z0 + (z1 - z0) * t1)
		local mid = (a + c) * 0.5
		local len = (c - a).Magnitude
		local cf = CFrame.lookAt(mid, c) * CFrame.Angles(0, math.rad(90), 0)
		b:cyl(`{name}{i}`, len, 0.09, cf, color, Enum.Material.Metal)
	end
end

local function dumbbell(b: any, name: string, x: number, y: number, lb: number)
	local C = Kit.Color
	local t = (lb - 5) / 95
	local across = acrossOf(lb)
	local thick = 0.15 + t * 0.26
	local grip = 0.4 + t * 0.22
	b:cyl(`{name}H`, grip + 0.1, 0.075, Kit.alongZ(x, y, 0), C.Chrome, Enum.Material.Metal)
	b:cyl(`{name}G`, 0.3, 0.09, Kit.alongZ(x, y, 0), C.RubberBlack, Enum.Material.Rubber)
	for s = -1, 1, 2 do
		local z = s * (grip / 2 + thick / 2)
		b:box(`{name}Head{s}`, Vector3.new(across, across, thick), Kit.at(x, y, z), C.RubberBlack, Enum.Material.Rubber)
		b:cyl(
			`{name}C{s}`,
			0.045,
			0.11 + t * 0.05,
			Kit.alongZ(x, y, s * (grip / 2 - 0.02)),
			C.Chrome,
			Enum.Material.Metal
		)
	end
end

function DumbbellRack.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("DumbbellRack", cf)
	local C = Kit.Color
	local frame = C.FrameGrey
	local extra = optNum(opts, "gap", 0, 0, 0.1)
	local xs = centers(BOTTOM, extra)
	local span = xs[#xs] - xs[1]
	local half = span / 2 + 0.45

	for _, x in { -half, 0, half } do
		local tag = string.format("%d", math.floor((x + 5) * 10))
		leg(b, `A{tag}L`, x, -0.8, -0.12, frame)
		leg(b, `A{tag}R`, x, 0.8, 0.12, frame)
		b:box(`Foot{tag}`, Vector3.new(0.18, 0.08, 1.7), Kit.at(x, 0.04, 0), frame, Enum.Material.Metal, true)
		b:box(`Cap{tag}`, Vector3.new(0.16, 0.1, 0.3), Kit.at(x, 2.68, 0), frame, Enum.Material.Metal)
		b:box(`TieLo{tag}`, Vector3.new(0.1, 0.1, 1.15), Kit.at(x, 1.1, 0), frame, Enum.Material.Metal)
		b:box(`TieHi{tag}`, Vector3.new(0.1, 0.1, 0.7), Kit.at(x, 2.3, 0), frame, Enum.Material.Metal)
	end

	local railLen = span + 0.7
	for _, z in { -0.14, 0.14 } do
		local tag = if z < 0 then "F" else "B"
		b:cyl(`RailLo{tag}`, railLen, 0.08, Kit.at(0, 1.08, z), frame, Enum.Material.Metal)
		b:cyl(`RailHi{tag}`, railLen, 0.08, Kit.at(0, 2.28, z), frame, Enum.Material.Metal)
		b:box(
			`CradleLo{tag}`,
			Vector3.new(railLen, 0.03, 0.06),
			Kit.at(0, 1.13, z),
			C.RubberBlack,
			Enum.Material.Rubber
		)
		b:box(
			`CradleHi{tag}`,
			Vector3.new(railLen, 0.03, 0.06),
			Kit.at(0, 2.33, z),
			C.RubberBlack,
			Enum.Material.Rubber
		)
	end
	b:box("Stretcher", Vector3.new(span, 0.08, 0.1), Kit.at(0, 0.12, 0), frame, Enum.Material.Metal, true)

	for i, lb in BOTTOM do
		dumbbell(b, `Lo{i}`, xs[i], 1.16, lb)
	end
	for i, lb in TOP do
		dumbbell(b, `Hi{i}`, xs[i], 2.36, lb)
	end

	return b:done()
end

return DumbbellRack
