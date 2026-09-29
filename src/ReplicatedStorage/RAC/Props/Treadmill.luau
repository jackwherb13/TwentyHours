--!strict
-- Commercial treadmill, ~33 in wide by 80 in long, console near 5 ft.
-- Charcoal shrouds, black belt, dark screen. Pivot bottom-center; the runner faces -Z.
local Kit = require(script.Parent.Kit)

local Treadmill = {
	kind = "treadmill",
	size = Vector3.new(2.95, 5.2, 6.6),
}

local CHARCOAL = Color3.fromRGB(48, 50, 54)

local function optNum(opts: { [string]: any }?, key: string, default: number, lo: number, hi: number): number
	local v = if opts ~= nil then opts[key] else nil
	if type(v) == "number" then
		return math.clamp(v :: number, lo, hi)
	end
	return default
end

function Treadmill.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("Treadmill", cf)
	local C = Kit.Color
	local steel = C.SteelBlack
	local accent = optNum(opts, "accent", 1, 0, 1) >= 0.5

	b:box("Deck", Vector3.new(2.55, 0.18, 5.15), Kit.at(0, 0.42, 0.45), steel, Enum.Material.Metal, true)
	b:box("Belt", Vector3.new(1.75, 0.06, 4.85), Kit.at(0, 0.54, 0.4), C.RubberBlack, Enum.Material.Rubber, true)
	for i = 0, 4 do
		b:box(
			`Seam{i}`,
			Vector3.new(1.7, 0.01, 0.03),
			Kit.at(0, 0.575, -1.6 + i * 1.05),
			Color3.fromRGB(40, 40, 42),
			Enum.Material.SmoothPlastic
		)
	end
	b:box("RailL", Vector3.new(0.12, 0.28, 5.2), Kit.at(-1.32, 0.5, 0.4), CHARCOAL, Enum.Material.Metal, true)
	b:box("RailR", Vector3.new(0.12, 0.28, 5.2), Kit.at(1.32, 0.5, 0.4), CHARCOAL, Enum.Material.Metal, true)
	b:cyl("RollerF", 1.7, 0.18, Kit.at(0, 0.5, -1.95), C.SteelGrey, Enum.Material.Metal)
	b:cyl("RollerB", 1.7, 0.16, Kit.at(0, 0.48, 2.75), C.SteelGrey, Enum.Material.Metal)
	b:box("Hood", Vector3.new(2.78, 0.825, 1.15), Kit.at(0, 0.4125, -2.55), CHARCOAL, Enum.Material.SmoothPlastic, true)
	b:box("HoodLip", Vector3.new(2.82, 0.08, 0.12), Kit.at(0, 0.85, -2.05), steel, Enum.Material.Metal)
	b:box(
		"RearCap",
		Vector3.new(2.7, 0.575, 0.28),
		Kit.at(0, 0.2875, 3.05),
		CHARCOAL,
		Enum.Material.SmoothPlastic,
		true
	)
	for s = -1, 1, 2 do
		b:cyl(`Wheel{s}`, 0.1, 0.22, Kit.vertical(s * 0.85, 0.05, 3.12), C.RubberBlack, Enum.Material.Rubber)
		b:box(
			`Foot{s}`,
			Vector3.new(0.28, 0.08, 0.4),
			Kit.at(s * 0.95, 0.04, -2.7),
			C.RubberBlack,
			Enum.Material.Rubber
		)
	end

	for s = -1, 1, 2 do
		b:box(
			`Upright{s}a`,
			Vector3.new(0.16, 1.7, 0.16),
			Kit.at(s * 1.32, 1.55, -1.85),
			steel,
			Enum.Material.Metal,
			true
		)
		b:box(`Upright{s}b`, Vector3.new(0.16, 1.6, 0.16), Kit.at(s * 1.32, 3.2, -1.85), steel, Enum.Material.Metal)
		b:cyl(`Hand{s}`, 2.6, 0.1, Kit.alongZ(s * 1.32, 3.15, -0.4), steel, Enum.Material.Metal)
		b:cyl(`HandrailDrop{s}`, 0.45, 0.09, Kit.vertical(s * 1.32, 2.95, 0.85), steel, Enum.Material.Metal)
		b:box(
			`Contact{s}`,
			Vector3.new(0.22, 0.1, 0.28),
			Kit.at(s * 1.22, 3.22, -1.78),
			C.SteelGrey,
			Enum.Material.Metal
		)
		b:cyl(`Cup{s}`, 0.12, 0.22, Kit.vertical(s * 0.72, 4.15, -1.95), CHARCOAL, Enum.Material.SmoothPlastic)
	end

	b:box("Console", Vector3.new(2.45, 0.85, 0.35), Kit.at(0, 4.55, -2.05), steel, Enum.Material.SmoothPlastic, true)
	b:box("ConsoleBrow", Vector3.new(2.2, 0.08, 0.38), Kit.at(0, 5.0, -2.05), CHARCOAL, Enum.Material.SmoothPlastic)
	local screen =
		b:box("Screen", Vector3.new(1.35, 0.48, 0.04), Kit.at(0, 4.7, -2.24), C.Screen, Enum.Material.SmoothPlastic)
	screen.Reflectance = 0.25
	b:light(screen, Enum.NormalId.Front, 0.45, 6, Color3.fromRGB(170, 200, 220))
	b:box("Glint", Vector3.new(1.1, 0.03, 0.01), Kit.at(0, 4.86, -2.27), C.OffWhite, Enum.Material.SmoothPlastic).Transparency =
		0.45
	b:box(
		"Keys",
		Vector3.new(1.5, 0.12, 0.05),
		Kit.at(0, 4.28, -2.22),
		Color3.fromRGB(28, 30, 34),
		Enum.Material.SmoothPlastic
	)
	for i = -2, 2 do
		b:box(
			`Key{i}`,
			Vector3.new(0.14, 0.05, 0.03),
			Kit.at(i * 0.22, 4.28, -2.25),
			C.SteelGrey,
			Enum.Material.SmoothPlastic
		)
	end
	if accent then
		b:box(
			"Accent",
			Vector3.new(1.6, 0.045, 0.02),
			Kit.at(0, 4.98, -2.25),
			C.MasonGreen,
			Enum.Material.SmoothPlastic
		)
	end
	b:box(
		"Led",
		Vector3.new(0.05, 0.05, 0.02),
		Kit.at(0.85, 4.42, -2.24),
		Color3.fromRGB(40, 200, 90),
		Enum.Material.Neon
	)

	return b:done()
end

return Treadmill
