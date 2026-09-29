--!strict
-- Seated leg press, selectorized, black frame and pads (IMG_0369 Matrix line).
-- Angled footplate, reclined back, side weight stack with a Mason-green stripe.
-- Pivot bottom-center; the lifter sits facing -Z.
local Kit = require(script.Parent.Kit)

local LegPress = {
	kind = "leg_press",
	size = Vector3.new(3.35, 4.85, 6.25),
}

local function optNum(opts: { [string]: any }?, key: string, default: number, lo: number, hi: number): number
	local v = if opts ~= nil then opts[key] else nil
	if type(v) == "number" then
		return math.clamp(v :: number, lo, hi)
	end
	return default
end

function LegPress.build(cf: CFrame, opts: { [string]: any }?): Model
	-- Stack sits on the left; shift so the pivot is the center of the footprint.
	local b = Kit.new("LegPress", cf * CFrame.new(0.53, 0, 0))
	local C = Kit.Color
	local steel = C.SteelBlack
	local plates = math.floor(optNum(opts, "plates", 12, 8, 14) + 0.5)
	local accent = optNum(opts, "accent", 1, 0, 1) >= 0.5

	b:box("SkidL", Vector3.new(0.2, 0.16, 5.8), Kit.at(-0.85, 0.1, 0.1), steel, Enum.Material.Metal, true)
	b:box("SkidR", Vector3.new(0.2, 0.16, 5.8), Kit.at(0.85, 0.1, 0.1), steel, Enum.Material.Metal, true)
	b:box("SkidEndF", Vector3.new(1.9, 0.14, 0.2), Kit.at(0, 0.1, -2.7), steel, Enum.Material.Metal, true)
	b:box("SkidEndB", Vector3.new(1.9, 0.14, 0.2), Kit.at(0, 0.1, 2.9), steel, Enum.Material.Metal, true)
	for s = -1, 1, 2 do
		b:box(
			`Boot{s}F`,
			Vector3.new(0.35, 0.05, 0.4),
			Kit.at(s * 0.85, 0.025, -2.7),
			C.RubberBlack,
			Enum.Material.Rubber
		)
		b:box(
			`Boot{s}B`,
			Vector3.new(0.35, 0.05, 0.4),
			Kit.at(s * 0.85, 0.025, 2.9),
			C.RubberBlack,
			Enum.Material.Rubber
		)
	end

	-- Rails the carriage rides, about 40 deg.
	for s = -1, 1, 2 do
		local x = s * 0.72
		for i = 0, 4 do
			local t0, t1 = i / 5, (i + 1) / 5
			local z0, z1 = 1.5 - 3.6 * t0, 1.5 - 3.6 * t1
			local y0, y1 = 1.15 + 2.6 * t0, 1.15 + 2.6 * t1
			local a = Vector3.new(x, y0, z0)
			local c = Vector3.new(x, y1, z1)
			local mid = (a + c) * 0.5
			local cfRail = CFrame.lookAt(mid, c) * CFrame.Angles(0, math.rad(90), 0)
			b:cyl(`Rail{s}{i}`, (c - a).Magnitude, 0.1, cfRail, C.Chrome, Enum.Material.Metal)
		end
	end

	local seat = CFrame.new(0, 1.4, 1.55) * CFrame.Angles(math.rad(-8), 0, 0)
	b:box("Seat", Vector3.new(1.35, 0.22, 1.2), seat, C.Upholstery, Enum.Material.Leather, true)
	b:box("SeatPan", Vector3.new(1.15, 0.08, 0.95), seat * CFrame.new(0, -0.06, 0.04), steel, Enum.Material.Metal)
	local back = CFrame.new(0, 2.15, 2.25) * CFrame.Angles(math.rad(-55), 0, 0)
	b:box("Back", Vector3.new(1.35, 0.22, 2.05), back, C.Upholstery, Enum.Material.Leather, true)
	b:box("BackPan", Vector3.new(1.15, 0.08, 1.9), back * CFrame.new(0, -0.14, 0), steel, Enum.Material.Metal)
	b:box("Head", Vector3.new(0.7, 0.16, 0.4), back * CFrame.new(0, 0.18, 0.85), C.Upholstery, Enum.Material.Leather)

	for s = -1, 1, 2 do
		b:cyl(`Handle{s}`, 0.55, 0.07, Kit.alongZ(s * 0.85, 1.7, 1.7), C.Chrome, Enum.Material.Metal)
		b:cyl(`Grip{s}`, 0.32, 0.08, Kit.alongZ(s * 0.85, 1.7, 1.55), C.RubberBlack, Enum.Material.Rubber)
	end

	local foot = CFrame.new(0, 2.05, -0.35) * CFrame.Angles(math.rad(-42), 0, 0)
	b:box("Footplate", Vector3.new(2.05, 1.7, 0.1), foot, steel, Enum.Material.Metal, true)
	for i = -2, 2 do
		b:box(
			`Tread{i}`,
			Vector3.new(1.85, 0.035, 0.02),
			foot * CFrame.new(0, i * 0.28, -0.06),
			C.SteelGrey,
			Enum.Material.Metal
		)
	end
	b:box("Carriage", Vector3.new(1.7, 0.35, 0.45), Kit.at(0, 1.85, 0.15), steel, Enum.Material.Metal, true)
	b:box("Shoe", Vector3.new(1.5, 0.75, 0.55), Kit.at(0, 1.72, -0.2), steel, Enum.Material.Metal, true)
	b:box("Stop", Vector3.new(1.5, 0.12, 0.1), Kit.at(0, 1.25, 0.85), C.RubberBlack, Enum.Material.Rubber)

	-- Side stack.
	local sx = -1.7
	b:box("Shroud", Vector3.new(0.7, 3.5, 0.9), Kit.at(sx, 1.92, 0.2), steel, Enum.Material.Metal, true)
	b:box(
		"Window",
		Vector3.new(0.04, 2.0, 0.55),
		Kit.at(sx - 0.34, 1.7, 0.2),
		Color3.fromRGB(14, 14, 16),
		Enum.Material.SmoothPlastic
	)
	if accent then
		b:box(
			"Accent",
			Vector3.new(0.03, 2.6, 0.1),
			Kit.at(sx - 0.36, 2.3, -0.15),
			C.MasonGreen,
			Enum.Material.SmoothPlastic
		)
	end
	for i = 1, plates do
		local y = 0.85 + (i - 1) * (1.7 / plates)
		b:box(`Plate{i}`, Vector3.new(0.5, 0.06, 0.4), Kit.at(sx, y, 0.2), steel, Enum.Material.Metal)
	end
	b:cyl("Rod", 1.9, 0.04, Kit.vertical(sx + 0.12, 1.7, 0.2), C.Chrome, Enum.Material.Metal)
	b:cyl("Pin", 0.22, 0.045, Kit.at(sx - 0.28, 1.35, 0.2), C.MasonGold, Enum.Material.Metal)
	b:box("Mast", Vector3.new(0.12, 1.5, 0.12), Kit.at(sx, 3.9, 0.2), steel, Enum.Material.Metal)
	b:box("Link", Vector3.new(0.9, 0.1, 0.12), Kit.at(-0.8, 1.55, 0.35), steel, Enum.Material.Metal)

	return b:done()
end

return LegPress
