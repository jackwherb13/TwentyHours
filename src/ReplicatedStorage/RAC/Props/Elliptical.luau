--!strict
-- Front-drive elliptical. Flywheel shroud, opposing pedals and swing arms, console.
-- Black and charcoal, like the cardio row facing the RAC windows (IMG_0318).
-- Pivot bottom-center; the rider faces -Z. Pose is mid-stride.
local Kit = require(script.Parent.Kit)

local Elliptical = {
	kind = "elliptical",
	size = Vector3.new(1.95, 5.4, 5.8),
}

local CHARCOAL = Color3.fromRGB(48, 50, 54)

local function optNum(opts: { [string]: any }?, key: string, default: number, lo: number, hi: number): number
	local v = if opts ~= nil then opts[key] else nil
	if type(v) == "number" then
		return math.clamp(v :: number, lo, hi)
	end
	return default
end

local function link(b: any, name: string, a: Vector3, c: Vector3, dia: number, color: Color3, mat: Enum.Material)
	local mid = (a + c) * 0.5
	local cf = CFrame.lookAt(mid, c) * CFrame.Angles(0, math.rad(90), 0)
	b:cyl(name, (c - a).Magnitude, dia, cf, color, mat)
end

function Elliptical.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("Elliptical", cf)
	local C = Kit.Color
	local steel = C.SteelBlack
	local accent = optNum(opts, "accent", 1, 0, 1) >= 0.5

	b:box("Base", Vector3.new(1.35, 0.16, 5.4), Kit.at(0, 0.1, 0.05), steel, Enum.Material.Metal, true)
	b:box("StabF", Vector3.new(1.7, 0.1, 0.22), Kit.at(0, 0.08, -2.65), steel, Enum.Material.Metal, true)
	b:box("StabB", Vector3.new(1.55, 0.1, 0.22), Kit.at(0, 0.08, 2.55), steel, Enum.Material.Metal, true)
	for s = -1, 1, 2 do
		b:box(
			`BootF{s}`,
			Vector3.new(0.22, 0.05, 0.28),
			Kit.at(s * 0.7, 0.025, -2.65),
			C.RubberBlack,
			Enum.Material.Rubber
		)
		b:box(
			`BootB{s}`,
			Vector3.new(0.22, 0.05, 0.28),
			Kit.at(s * 0.62, 0.025, 2.55),
			C.RubberBlack,
			Enum.Material.Rubber
		)
	end

	b:box("Shroud", Vector3.new(1.25, 1.55, 1.35), Kit.at(0, 0.95, -1.85), CHARCOAL, Enum.Material.SmoothPlastic, true)
	b:box("ShroudCap", Vector3.new(1.15, 0.2, 1.2), Kit.at(0, 1.75, -1.8), steel, Enum.Material.SmoothPlastic)
	b:cyl("Flywheel", 0.18, 1.15, Kit.at(0, 0.95, -1.7), C.SteelGrey, Enum.Material.Metal)
	b:cyl("Hub", 0.22, 0.28, Kit.at(0, 0.95, -1.7), steel, Enum.Material.Metal)
	b:box("CrankCover", Vector3.new(0.35, 0.35, 0.2), Kit.at(0, 0.85, -1.05), steel, Enum.Material.Metal)

	-- Crank and pedals, left foot forward.
	local crankY, crankZ = 0.78, -0.85
	link(
		b,
		"CrankL",
		Vector3.new(-0.15, crankY, crankZ),
		Vector3.new(-0.58, 0.5, -0.3),
		0.07,
		C.SteelGrey,
		Enum.Material.Metal
	)
	link(
		b,
		"CrankR",
		Vector3.new(0.15, crankY, crankZ),
		Vector3.new(0.55, 0.48, 0.55),
		0.07,
		C.SteelGrey,
		Enum.Material.Metal
	)
	b:box("PedalL", Vector3.new(0.32, 0.08, 0.7), Kit.at(-0.62, 0.5, -0.3), C.RubberBlack, Enum.Material.Rubber, true)
	b:box("PedalR", Vector3.new(0.32, 0.08, 0.7), Kit.at(0.62, 0.44, 0.6), C.RubberBlack, Enum.Material.Rubber, true)
	b:box("PedalLipL", Vector3.new(0.32, 0.06, 0.06), Kit.at(-0.62, 0.56, -0.62), C.SteelGrey, Enum.Material.Metal)
	b:box("PedalLipR", Vector3.new(0.32, 0.06, 0.06), Kit.at(0.62, 0.5, 0.28), C.SteelGrey, Enum.Material.Metal)
	link(b, "ArmLinkL", Vector3.new(-0.62, 0.5, -0.3), Vector3.new(-0.4, 1.55, 0.85), 0.06, steel, Enum.Material.Metal)
	link(b, "ArmLinkR", Vector3.new(0.62, 0.55, 0.45), Vector3.new(0.4, 1.45, 1.5), 0.06, steel, Enum.Material.Metal)

	-- Swing arms, opposite the feet. Pivot up by the console mast.
	link(b, "SwingL", Vector3.new(-0.45, 3.55, -1.55), Vector3.new(-0.55, 2.7, 0.35), 0.08, steel, Enum.Material.Metal)
	link(b, "SwingR", Vector3.new(0.45, 3.55, -1.55), Vector3.new(0.55, 2.85, -0.55), 0.08, steel, Enum.Material.Metal)
	b:cyl("HandL", 0.55, 0.09, Kit.vertical(-0.55, 2.9, 0.36), C.RubberBlack, Enum.Material.Rubber)
	b:cyl("HandR", 0.55, 0.08, Kit.vertical(0.58, 3.05, -0.45), C.RubberBlack, Enum.Material.Rubber)
	b:cyl("PivotL", 0.12, 0.14, Kit.at(-0.45, 3.55, -1.55), C.SteelGrey, Enum.Material.Metal)
	b:cyl("PivotR", 0.12, 0.14, Kit.at(0.45, 3.55, -1.55), C.SteelGrey, Enum.Material.Metal)

	b:box("MastA", Vector3.new(0.16, 1.5, 0.16), Kit.at(0, 2.55, -2.15), steel, Enum.Material.Metal, true)
	b:box("MastB", Vector3.new(0.16, 1.4, 0.16), Kit.at(0, 3.95, -2.15), steel, Enum.Material.Metal)
	b:box("Console", Vector3.new(1.35, 0.7, 0.32), Kit.at(0, 4.85, -2.25), steel, Enum.Material.SmoothPlastic, true)
	local screen =
		b:box("Screen", Vector3.new(0.95, 0.4, 0.04), Kit.at(0, 4.95, -2.43), C.Screen, Enum.Material.SmoothPlastic)
	screen.Reflectance = 0.22
	b:light(screen, Enum.NormalId.Front, 0.4, 5, Color3.fromRGB(170, 200, 220))
	b:box(
		"Keys",
		Vector3.new(0.9, 0.08, 0.04),
		Kit.at(0, 4.62, -2.42),
		Color3.fromRGB(28, 30, 34),
		Enum.Material.SmoothPlastic
	)
	if accent then
		b:box("Accent", Vector3.new(0.9, 0.04, 0.02), Kit.at(0, 5.18, -2.42), C.MasonGreen, Enum.Material.SmoothPlastic)
	end
	b:cyl("CupL", 0.1, 0.18, Kit.vertical(-0.55, 4.55, -2.15), CHARCOAL, Enum.Material.SmoothPlastic)
	b:cyl("CupR", 0.1, 0.18, Kit.vertical(0.55, 4.55, -2.15), CHARCOAL, Enum.Material.SmoothPlastic)

	return b:done()
end

return Elliptical
