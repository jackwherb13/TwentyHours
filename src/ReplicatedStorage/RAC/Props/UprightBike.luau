--!strict
-- Upright exercise bike. Shrouded flywheel, saddle, bullhorns, console.
-- Black steel and charcoal plastics. Pivot bottom-center; the rider faces -Z.
local Kit = require(script.Parent.Kit)

local UprightBike = {
	kind = "upright_bike",
	size = Vector3.new(1.95, 4.7, 3.5),
}

local CHARCOAL = Color3.fromRGB(48, 50, 54)

local function optNum(opts: { [string]: any }?, key: string, default: number, lo: number, hi: number): number
	local v = if opts ~= nil then opts[key] else nil
	if type(v) == "number" then
		return math.clamp(v :: number, lo, hi)
	end
	return default
end

local function link(b: any, name: string, a: Vector3, c: Vector3, dia: number, color: Color3)
	local mid = (a + c) * 0.5
	local cf = CFrame.lookAt(mid, c) * CFrame.Angles(0, math.rad(90), 0)
	b:cyl(name, (c - a).Magnitude, dia, cf, color, Enum.Material.Metal)
end

function UprightBike.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("UprightBike", cf)
	local C = Kit.Color
	local steel = C.SteelBlack
	local accent = optNum(opts, "accent", 1, 0, 1) >= 0.5

	b:box("Base", Vector3.new(0.9, 0.14, 3.2), Kit.at(0, 0.12, -0.1), steel, Enum.Material.Metal, true)
	b:box("StabF", Vector3.new(1.7, 0.1, 0.2), Kit.at(0, 0.08, -1.6), steel, Enum.Material.Metal, true)
	b:box("StabB", Vector3.new(1.45, 0.1, 0.2), Kit.at(0, 0.08, 1.35), steel, Enum.Material.Metal, true)
	for s = -1, 1, 2 do
		b:box(
			`BootF{s}`,
			Vector3.new(0.22, 0.04, 0.26),
			Kit.at(s * 0.7, 0.02, -1.6),
			C.RubberBlack,
			Enum.Material.Rubber
		)
		b:box(
			`BootB{s}`,
			Vector3.new(0.22, 0.04, 0.26),
			Kit.at(s * 0.58, 0.02, 1.35),
			C.RubberBlack,
			Enum.Material.Rubber
		)
	end

	b:box("Shroud", Vector3.new(1.15, 1.35, 1.15), Kit.at(0, 0.9, -0.85), CHARCOAL, Enum.Material.SmoothPlastic, true)
	b:cyl("Flywheel", 0.16, 1.05, Kit.at(0, 0.85, -0.75), C.SteelGrey, Enum.Material.Metal)
	b:cyl("Hub", 0.2, 0.24, Kit.at(0, 0.85, -0.75), steel, Enum.Material.Metal)
	b:box("ShroudCap", Vector3.new(1.05, 0.12, 1.05), Kit.at(0, 1.6, -0.85), steel, Enum.Material.SmoothPlastic)

	link(b, "CrankL", Vector3.new(-0.12, 0.72, -0.35), Vector3.new(-0.52, 0.45, 0.05), 0.06, C.SteelGrey)
	link(b, "CrankR", Vector3.new(0.12, 0.72, -0.35), Vector3.new(0.48, 0.42, -0.7), 0.06, C.SteelGrey)
	b:box("PedalL", Vector3.new(0.28, 0.06, 0.4), Kit.at(-0.55, 0.45, 0.05), C.RubberBlack, Enum.Material.Rubber)
	b:box("PedalR", Vector3.new(0.28, 0.06, 0.4), Kit.at(0.55, 0.4, -0.7), C.RubberBlack, Enum.Material.Rubber)
	b:cyl("CageL", 0.32, 0.05, Kit.alongZ(-0.55, 0.52, 0.05), C.SteelGrey, Enum.Material.Metal)
	b:cyl("CageR", 0.32, 0.05, Kit.alongZ(0.55, 0.47, -0.7), C.SteelGrey, Enum.Material.Metal)

	b:box("Post", Vector3.new(0.16, 2.9, 0.16), Kit.at(0, 1.55, 0.55), steel, Enum.Material.Metal, true)
	b:box("PostClamp", Vector3.new(0.22, 0.16, 0.22), Kit.at(0, 2.95, 0.55), C.SteelGrey, Enum.Material.Metal)
	b:box("Saddle", Vector3.new(0.4, 0.1, 0.72), Kit.at(0, 3.15, 0.5), C.Upholstery, Enum.Material.Leather, true)
	b:box("SaddleNose", Vector3.new(0.22, 0.08, 0.28), Kit.at(0, 3.12, 0.1), C.Upholstery, Enum.Material.Leather)
	b:cyl("SeatBolt", 0.08, 0.08, Kit.vertical(0, 3.02, 0.55), C.SteelGrey, Enum.Material.Metal)

	b:box("Stem", Vector3.new(0.14, 1.7, 0.14), Kit.at(0, 2.35, -1.08), steel, Enum.Material.Metal, true)
	b:cyl("Bar", 1.35, 0.08, Kit.at(0, 3.15, -1.05), steel, Enum.Material.Metal)
	b:cyl("HornL", 0.4, 0.07, Kit.alongZ(-0.6, 3.13, -0.95), C.RubberBlack, Enum.Material.Rubber)
	b:cyl("HornR", 0.4, 0.07, Kit.alongZ(0.6, 3.13, -0.95), C.RubberBlack, Enum.Material.Rubber)
	b:box("PadL", Vector3.new(0.16, 0.06, 0.22), Kit.at(-0.45, 3.2, -1.05), C.RubberBlack, Enum.Material.Rubber)
	b:box("PadR", Vector3.new(0.16, 0.06, 0.22), Kit.at(0.45, 3.2, -1.05), C.RubberBlack, Enum.Material.Rubber)

	b:box("Console", Vector3.new(1.15, 0.65, 0.28), Kit.at(0, 4.15, -1.35), steel, Enum.Material.SmoothPlastic, true)
	local screen =
		b:box("Screen", Vector3.new(0.75, 0.36, 0.04), Kit.at(0, 4.25, -1.51), C.Screen, Enum.Material.SmoothPlastic)
	screen.Reflectance = 0.22
	b:light(screen, Enum.NormalId.Front, 0.35, 5, Color3.fromRGB(170, 200, 220))
	b:box(
		"Keys",
		Vector3.new(0.7, 0.08, 0.04),
		Kit.at(0, 3.95, -1.5),
		Color3.fromRGB(28, 30, 34),
		Enum.Material.SmoothPlastic
	)
	if accent then
		b:box("Accent", Vector3.new(0.7, 0.035, 0.02), Kit.at(0, 4.46, -1.5), C.MasonGreen, Enum.Material.SmoothPlastic)
	end
	b:box("Neck", Vector3.new(0.14, 0.9, 0.16), Kit.at(0, 3.55, -1.12), steel, Enum.Material.Metal)

	return b:done()
end

return UprightBike
