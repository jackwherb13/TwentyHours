--!strict
-- Selectorized lat pulldown. Thigh rollers, wide bar, front stack with a Mason-green stripe.
-- Black steel and black vinyl, matching the RAC Matrix / Hammer floor (IMG_0318, IMG_0369).
-- Pivot bottom-center; the lifter sits facing -Z.
local Kit = require(script.Parent.Kit)

local LatPulldown = {
	kind = "lat_pulldown",
	size = Vector3.new(4.15, 7.1, 4.35),
}

local function optNum(opts: { [string]: any }?, key: string, default: number, lo: number, hi: number): number
	local v = if opts ~= nil then opts[key] else nil
	if type(v) == "number" then
		return math.clamp(v :: number, lo, hi)
	end
	return default
end

local function mast(b: any, name: string, x: number, z: number, y0: number, y1: number, color: Color3)
	local n = math.max(1, math.ceil((y1 - y0) / 1.8))
	local h = (y1 - y0) / n
	for i = 1, n do
		b:box(
			`{name}{i}`,
			Vector3.new(0.22, h, 0.22),
			Kit.at(x, y0 + h * (i - 0.5), z),
			color,
			Enum.Material.Metal,
			i == 1
		)
	end
end

function LatPulldown.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("LatPulldown", cf)
	local C = Kit.Color
	local steel = C.SteelBlack
	local plates = math.floor(optNum(opts, "plates", 14, 8, 16) + 0.5)
	local accent = optNum(opts, "accent", 1, 0, 1) >= 0.5

	b:box("Base", Vector3.new(2.4, 0.14, 3.6), Kit.at(0, 0.1, 0.3), steel, Enum.Material.Metal, true)
	b:box("Foot", Vector3.new(2.6, 0.06, 0.35), Kit.at(0, 0.03, -1.35), C.RubberBlack, Enum.Material.Rubber, true)
	b:box("FootB", Vector3.new(2.2, 0.06, 0.3), Kit.at(0, 0.03, 1.85), C.RubberBlack, Enum.Material.Rubber)
	b:box("SeatPost", Vector3.new(0.2, 1.15, 0.2), Kit.at(0, 0.7, 0.85), steel, Enum.Material.Metal, true)
	b:box("Seat", Vector3.new(1.25, 0.2, 1.15), Kit.at(0, 1.4, 0.75), C.Upholstery, Enum.Material.Leather, true)
	b:box("SeatPan", Vector3.new(1.1, 0.06, 1.0), Kit.at(0, 1.27, 0.75), steel, Enum.Material.Metal)
	b:box("Back", Vector3.new(1.15, 0.7, 0.16), Kit.at(0, 1.85, 1.35), C.Upholstery, Enum.Material.Leather, true)

	-- Thigh hold-down: the silhouette that makes this a lat pulldown.
	b:box("ThighArm", Vector3.new(1.25, 0.24, 1.4), Kit.at(0, 2.08, 0.5), steel, Enum.Material.Metal, true)
	b:cyl("RollerL", 0.55, 0.28, Kit.at(-0.4, 2.15, -0.15), C.Upholstery, Enum.Material.Leather)
	b:cyl("RollerR", 0.55, 0.28, Kit.at(0.4, 2.15, -0.15), C.Upholstery, Enum.Material.Leather)
	b:cyl("RollerAxle", 1.15, 0.06, Kit.at(0, 2.15, -0.15), C.SteelGrey, Enum.Material.Metal)
	b:box("ThighPadL", Vector3.new(0.15, 0.1, 0.4), Kit.at(-0.55, 2.45, 0.15), C.Upholstery, Enum.Material.Leather)
	b:box("ThighPadR", Vector3.new(0.15, 0.1, 0.4), Kit.at(0.55, 2.45, 0.15), C.Upholstery, Enum.Material.Leather)

	mast(b, "Mast", 0, 1.15, 0.2, 6.7, steel)
	b:box("Boom", Vector3.new(0.2, 0.18, 2.5), Kit.at(0, 6.65, -0.05), steel, Enum.Material.Metal, true)
	b:box("BoomCap", Vector3.new(0.45, 0.16, 0.35), Kit.at(0, 6.8, -1.2), steel, Enum.Material.Metal)
	b:cyl("TopPulley", 0.1, 0.36, Kit.at(0, 6.74, -1.15), C.SteelGrey, Enum.Material.Metal)
	b:box("Cable", Vector3.new(0.06, 1.45, 0.08), Kit.at(0, 5.95, -0.55), C.RubberBlack, Enum.Material.SmoothPlastic)
	b:box("CableTop", Vector3.new(0.06, 0.08, 0.75), Kit.at(0, 6.55, -0.85), C.RubberBlack, Enum.Material.SmoothPlastic)

	-- Wide bar parked at the top of the pull, with angled end grips.
	b:cyl("LatBar", 3.5, 0.09, Kit.at(0, 5.25, -0.55), C.Chrome, Enum.Material.Metal)
	b:cyl("LatGripL", 0.85, 0.08, Kit.at(-1.55, 5.25, -0.55), C.RubberBlack, Enum.Material.Rubber)
	b:cyl("LatGripR", 0.85, 0.08, Kit.at(1.55, 5.25, -0.55), C.RubberBlack, Enum.Material.Rubber)
	for s = -1, 1, 2 do
		local endCf = CFrame.new(s * 1.72, 5.22, -0.55) * CFrame.Angles(0, 0, math.rad(s * 18))
		b:cyl(`LatEnd{s}`, 0.32, 0.08, endCf * CFrame.Angles(0, math.rad(90), 0), C.Chrome, Enum.Material.Metal)
		b:box(`Stirrup{s}`, Vector3.new(0.1, 0.24, 0.1), Kit.at(s * 0.15, 5.36, -0.55), steel, Enum.Material.Metal)
	end
	b:cyl("BarHook", 0.18, 0.07, Kit.vertical(0, 5.36, -0.55), C.Chrome, Enum.Material.Metal)

	-- Front stack, the thing you face while pulling.
	b:box("ShroudL", Vector3.new(0.1, 3.3, 0.85), Kit.at(-0.55, 2.0, -1.45), steel, Enum.Material.Metal, true)
	b:box("ShroudR", Vector3.new(0.1, 3.3, 0.85), Kit.at(0.55, 2.0, -1.45), steel, Enum.Material.Metal, true)
	b:box("ShroudTop", Vector3.new(1.2, 0.12, 0.85), Kit.at(0, 3.6, -1.45), steel, Enum.Material.Metal)
	b:box("ShroudBot", Vector3.new(1.2, 0.16, 0.9), Kit.at(0, 0.4, -1.45), steel, Enum.Material.Metal, true)
	b:box(
		"Window",
		Vector3.new(0.85, 2.3, 0.04),
		Kit.at(0, 1.9, -1.88),
		Color3.fromRGB(14, 14, 16),
		Enum.Material.SmoothPlastic
	)
	if accent then
		b:box(
			"Accent",
			Vector3.new(0.08, 2.5, 0.03),
			Kit.at(-0.38, 1.95, -1.91),
			C.MasonGreen,
			Enum.Material.SmoothPlastic
		)
	end
	for i = 1, plates do
		local y = 0.7 + (i - 1) * (2.15 / plates)
		b:box(`Plate{i}`, Vector3.new(0.72, 0.06, 0.4), Kit.at(0, y, -1.55), steel, Enum.Material.Metal)
	end
	b:cyl("RodL", 2.55, 0.04, Kit.vertical(-0.22, 1.58, -1.42), C.Chrome, Enum.Material.Metal)
	b:cyl("RodR", 2.55, 0.04, Kit.vertical(0.22, 1.58, -1.42), C.Chrome, Enum.Material.Metal)
	b:cyl("Pin", 0.32, 0.05, Kit.alongZ(0.22, 1.55, -1.75), C.MasonGold, Enum.Material.Metal)
	b:ball("PinKnob", 0.07, Kit.at(0.22, 1.55, -1.95), C.MasonGold, Enum.Material.SmoothPlastic)
	b:box(
		"StackCable",
		Vector3.new(0.025, 2.6, 0.025),
		Kit.at(0, 4.9, -1.2),
		C.RubberBlack,
		Enum.Material.SmoothPlastic
	)

	return b:done()
end

return LatPulldown
