--!strict
-- Seated chest press. Converging arms, black pads, side stack with a Mason-green stripe.
-- Matches the selectorized line beside the racks (IMG_0318, IMG_0369).
-- Pivot bottom-center; the lifter sits facing -Z and presses toward -Z.
local Kit = require(script.Parent.Kit)

local ChestPress = {
	kind = "chest_press",
	size = Vector3.new(3.7, 4.15, 3.65),
}

local function optNum(opts: { [string]: any }?, key: string, default: number, lo: number, hi: number): number
	local v = if opts ~= nil then opts[key] else nil
	if type(v) == "number" then
		return math.clamp(v :: number, lo, hi)
	end
	return default
end

function ChestPress.build(cf: CFrame, opts: { [string]: any }?): Model
	-- Stack sits behind the right shoulder. Shift onto the footprint center.
	local b = Kit.new("ChestPress", cf * CFrame.new(-0.36, 0, -0.34))
	local C = Kit.Color
	local steel = C.SteelBlack
	local plates = math.floor(optNum(opts, "plates", 12, 8, 14) + 0.5)
	local accent = optNum(opts, "accent", 1, 0, 1) >= 0.5

	b:box("Base", Vector3.new(2.3, 0.14, 3.4), Kit.at(0.1, 0.12, 0.35), steel, Enum.Material.Metal, true)
	b:box("FootF", Vector3.new(2.5, 0.05, 0.35), Kit.at(0, 0.03, -1.2), C.RubberBlack, Enum.Material.Rubber, true)
	b:box("FootB", Vector3.new(2.2, 0.05, 0.3), Kit.at(0.3, 0.03, 1.9), C.RubberBlack, Enum.Material.Rubber)
	b:box("Pedal", Vector3.new(1.3, 0.08, 0.45), Kit.at(0, 0.2, -0.85), C.RubberBlack, Enum.Material.Rubber, true)

	b:box("SeatPost", Vector3.new(0.22, 1.05, 0.22), Kit.at(0, 0.7, 0.45), steel, Enum.Material.Metal, true)
	b:box("Seat", Vector3.new(1.3, 0.22, 1.15), Kit.at(0, 1.38, 0.35), C.Upholstery, Enum.Material.Leather, true)
	b:box("SeatPan", Vector3.new(1.15, 0.06, 1.0), Kit.at(0, 1.24, 0.35), steel, Enum.Material.Metal)
	b:box("Back", Vector3.new(1.3, 2.15, 0.2), Kit.at(0, 2.55, 1.15), C.Upholstery, Enum.Material.Leather, true)
	b:box("BackPan", Vector3.new(1.15, 2.0, 0.08), Kit.at(0, 2.5, 1.28), steel, Enum.Material.Metal)
	b:box("Head", Vector3.new(0.7, 0.28, 0.12), Kit.at(0, 3.55, 1.02), C.Upholstery, Enum.Material.Leather)

	-- Pivots beside the shoulders, arms out to horizontal grips.
	for s = -1, 1, 2 do
		b:cyl(`Pivot{s}`, 1.05, 0.18, Kit.alongZ(s * 0.58, 2.62, 0.72), C.SteelGrey, Enum.Material.Metal)
		local arm = CFrame.new(s * 0.95, 2.62, -0.25) * CFrame.Angles(0, math.rad(s * -16), 0)
		b:box(`Arm{s}`, Vector3.new(0.16, 0.2, 1.25), arm, steel, Enum.Material.Metal, true)
		b:cyl(`Handle{s}`, 0.42, 0.075, Kit.alongZ(s * 1.35, 2.6, -0.85), C.Chrome, Enum.Material.Metal)
		b:cyl(`Grip{s}`, 0.28, 0.09, Kit.alongZ(s * 1.35, 2.6, -0.85), C.RubberBlack, Enum.Material.Rubber)
		b:box(`ArmLink{s}`, Vector3.new(0.22, 0.42, 0.55), Kit.at(s * 0.78, 2.38, 0.18), steel, Enum.Material.Metal)
	end
	b:box("Cam", Vector3.new(1.7, 0.22, 0.4), Kit.at(0, 2.14, 0.5), steel, Enum.Material.Metal)
	b:box("CamPost", Vector3.new(0.18, 0.75, 0.18), Kit.at(0, 1.72, 0.5), steel, Enum.Material.Metal, true)
	b:cyl("CamAxle", 1.4, 0.08, Kit.at(0, 2.15, 0.55), C.SteelGrey, Enum.Material.Metal)

	-- Stack behind the right shoulder.
	local sx, sz = 1.55, 1.05
	b:box("Shroud", Vector3.new(0.85, 3.72, 0.7), Kit.at(sx, 2.01, sz), steel, Enum.Material.Metal, true)
	b:box(
		"Window",
		Vector3.new(0.04, 2.05, 0.48),
		Kit.at(sx + 0.43, 1.7, sz),
		Color3.fromRGB(14, 14, 16),
		Enum.Material.SmoothPlastic
	)
	if accent then
		b:box(
			"Accent",
			Vector3.new(0.03, 2.4, 0.1),
			Kit.at(sx + 0.45, 2.2, sz - 0.22),
			C.MasonGreen,
			Enum.Material.SmoothPlastic
		)
	end
	for i = 1, plates do
		local y = 0.8 + (i - 1) * (1.85 / plates)
		b:box(`Plate{i}`, Vector3.new(0.55, 0.06, 0.4), Kit.at(sx, y, sz), steel, Enum.Material.Metal)
	end
	b:cyl("Rod", 2.05, 0.04, Kit.vertical(sx - 0.15, 1.7, sz), C.Chrome, Enum.Material.Metal)
	b:cyl("Pin", 0.24, 0.045, Kit.at(sx + 0.4, 1.4, sz), C.MasonGold, Enum.Material.Metal)
	b:ball("PinKnob", 0.07, Kit.at(sx + 0.52, 1.4, sz), C.MasonGold, Enum.Material.SmoothPlastic)
	b:box("StackLink", Vector3.new(0.8, 0.1, 0.12), Kit.at(0.7, 2.15, 0.7), steel, Enum.Material.Metal)
	b:box("TopCap", Vector3.new(0.9, 0.1, 0.75), Kit.at(sx, 3.85, sz), steel, Enum.Material.Metal)

	return b:done()
end

return ChestPress
