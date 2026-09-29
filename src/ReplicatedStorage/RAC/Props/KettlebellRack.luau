--!strict
-- Two-shelf kettlebell rack. Black steel, black bells, chrome handles.
-- Top: 10–35 lb. Bottom: 40–90 lb. Pivot bottom-center, front faces -Z.
local Kit = require(script.Parent.Kit)

local KettlebellRack = {
	kind = "kettlebell_rack",
	size = Vector3.new(6.7, 3.0, 1.6),
}

local TOP = { 10, 15, 20, 25, 30, 35 }
local BOTTOM = { 40, 50, 60, 70, 80, 90 }

local function optNum(opts: { [string]: any }?, key: string, default: number, lo: number, hi: number): number
	local v = if opts ~= nil then opts[key] else nil
	if type(v) == "number" then
		return math.clamp(v :: number, lo, hi)
	end
	return default
end

local function diameter(lb: number): number
	return 0.42 + math.clamp((lb - 10) / 80, 0, 1) * 0.5
end

local function layout(lbs: { number }, gap: number): ({ number }, { number })
	local ds: { number } = {}
	for i, lb in lbs do
		ds[i] = diameter(lb)
	end
	local xs: { number } = {}
	local total = 0
	local steps: { number } = {}
	for i = 1, #lbs - 1 do
		steps[i] = (ds[i] + ds[i + 1]) / 2 + gap
		total += steps[i]
	end
	local x = -total / 2
	xs[1] = x
	for i = 1, #lbs - 1 do
		x += steps[i]
		xs[i + 1] = x
	end
	return xs, ds
end

local function bell(b: any, name: string, x: number, shelfTop: number, d: number)
	local C = Kit.Color
	local r = d / 2
	local y = shelfTop + r
	b:ball(`{name}B`, d, Kit.at(x, y, 0), C.RubberBlack, Enum.Material.Rubber)
	local y0 = y + r * 0.2
	local y1 = y + r + 0.16
	for s = -1, 1, 2 do
		local hx = x + s * r * 0.62
		b:cyl(`{name}U{s}`, y1 - y0, 0.045, Kit.vertical(hx, (y0 + y1) / 2, 0), C.Chrome, Enum.Material.Metal)
	end
	b:cyl(`{name}T`, r * 1.35, 0.045, Kit.at(x, y1, 0), C.Chrome, Enum.Material.Metal)
end

function KettlebellRack.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("KettlebellRack", cf)
	local C = Kit.Color
	local steel = C.SteelBlack
	local gap = optNum(opts, "gap", 0.14, 0.08, 0.22)
	local xs, ds = layout(BOTTOM, gap)
	local topXs, topDs = layout(TOP, gap)
	local half = math.max(math.abs(xs[1] - ds[1] / 2), math.abs(xs[#xs] + ds[#ds] / 2)) + 0.35
	local loTop, hiTop = 0.58, 1.98

	for _, x in { -half, half } do
		local tag = if x < 0 then "L" else "R"
		b:box(`PostF{tag}`, Vector3.new(0.14, 1.4, 0.14), Kit.at(x, 0.75, -0.55), steel, Enum.Material.Metal, true)
		b:box(`PostF2{tag}`, Vector3.new(0.14, 1.35, 0.14), Kit.at(x, 2.1, -0.55), steel, Enum.Material.Metal, true)
		b:box(`PostB{tag}`, Vector3.new(0.14, 1.4, 0.14), Kit.at(x, 0.75, 0.55), steel, Enum.Material.Metal, true)
		b:box(`PostB2{tag}`, Vector3.new(0.14, 1.35, 0.14), Kit.at(x, 2.1, 0.55), steel, Enum.Material.Metal, true)
		b:box(`Foot{tag}`, Vector3.new(0.4, 0.08, 1.45), Kit.at(x, 0.04, 0), steel, Enum.Material.Metal, true)
		for s = -1, 1, 2 do
			b:box(
				`Boot{tag}{s}`,
				Vector3.new(0.18, 0.06, 0.22),
				Kit.at(x, 0.03, s * 0.62),
				C.RubberBlack,
				Enum.Material.Rubber
			)
		end
	end
	b:box("ShelfLo", Vector3.new(half * 2, 0.08, 1.15), Kit.at(0, loTop - 0.04, 0), steel, Enum.Material.Metal, true)
	b:box("ShelfHi", Vector3.new(half * 2, 0.08, 1.05), Kit.at(0, hiTop - 0.04, 0), steel, Enum.Material.Metal, true)
	b:box("LipLoF", Vector3.new(half * 2, 0.1, 0.05), Kit.at(0, loTop + 0.02, -0.55), steel, Enum.Material.Metal)
	b:box("LipLoB", Vector3.new(half * 2, 0.1, 0.05), Kit.at(0, loTop + 0.02, 0.55), steel, Enum.Material.Metal)
	b:box("LipHiF", Vector3.new(half * 2, 0.1, 0.05), Kit.at(0, hiTop + 0.02, -0.5), steel, Enum.Material.Metal)
	b:box("LipHiB", Vector3.new(half * 2, 0.1, 0.05), Kit.at(0, hiTop + 0.02, 0.5), steel, Enum.Material.Metal)
	b:box("TopTie", Vector3.new(half * 2, 0.1, 0.12), Kit.at(0, 2.78, 0), steel, Enum.Material.Metal)
	b:box("Accent", Vector3.new(0.9, 0.08, 0.04), Kit.at(0, 2.74, -0.07), C.MasonGreen, Enum.Material.SmoothPlastic)

	for i, _lb in BOTTOM do
		bell(b, `Lo{i}`, xs[i], loTop, ds[i])
	end
	for i, _lb in TOP do
		bell(b, `Hi{i}`, topXs[i], hiTop, topDs[i])
	end

	return b:done()
end

return KettlebellRack
