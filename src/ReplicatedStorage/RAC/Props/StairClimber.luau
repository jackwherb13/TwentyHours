--!strict
-- Revolving stair climber (the step machines along the RAC cardio row, IMG_0318 / IMG_0369).
-- Black side housings, five visible steps, rails, console. Pivot bottom-center; the climber faces -Z.
local Kit = require(script.Parent.Kit)

local StairClimber = {
	kind = "stair_climber",
	size = Vector3.new(2.7, 5.35, 3.95),
}

local CHARCOAL = Color3.fromRGB(42, 44, 48)

local function optNum(opts: { [string]: any }?, key: string, default: number, lo: number, hi: number): number
	local v = if opts ~= nil then opts[key] else nil
	if type(v) == "number" then
		return math.clamp(v :: number, lo, hi)
	end
	return default
end

function StairClimber.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("StairClimber", cf)
	local C = Kit.Color
	local steel = C.SteelBlack
	local steps = math.floor(optNum(opts, "steps", 6, 4, 7) + 0.5)
	local accent = optNum(opts, "accent", 1, 0, 1) >= 0.5

	b:box("Base", Vector3.new(2.35, 0.16, 3.6), Kit.at(0, 0.1, 0.15), steel, Enum.Material.Metal, true)
	b:box("StabF", Vector3.new(2.5, 0.08, 0.22), Kit.at(0, 0.05, -1.55), steel, Enum.Material.Metal, true)
	b:box("StabB", Vector3.new(2.4, 0.08, 0.22), Kit.at(0, 0.05, 1.85), steel, Enum.Material.Metal, true)
	for s = -1, 1, 2 do
		b:box(
			`Boot{s}`,
			Vector3.new(0.28, 0.04, 0.3),
			Kit.at(s * 1.05, 0.02, -1.55),
			C.RubberBlack,
			Enum.Material.Rubber
		)
		b:box(
			`BootB{s}`,
			Vector3.new(0.28, 0.04, 0.3),
			Kit.at(s * 1.0, 0.02, 1.85),
			C.RubberBlack,
			Enum.Material.Rubber
		)
		b:box(
			`Side{s}a`,
			Vector3.new(0.12, 1.7, 2.5),
			Kit.at(s * 0.95, 1.15, 0.2),
			CHARCOAL,
			Enum.Material.SmoothPlastic,
			true
		)
		b:box(
			`Side{s}b`,
			Vector3.new(0.12, 1.6, 2.3),
			Kit.at(s * 0.95, 2.75, 0.05),
			CHARCOAL,
			Enum.Material.SmoothPlastic
		)
		b:box(`SideCap{s}`, Vector3.new(0.14, 0.12, 2.55), Kit.at(s * 0.95, 3.55, 0.1), steel, Enum.Material.Metal)
		b:cyl(`Rail{s}`, 2.3, 0.09, Kit.alongZ(s * 1.15, 3.35, 0.15), steel, Enum.Material.Metal)
		b:box(`RailPost{s}`, Vector3.new(0.08, 0.7, 0.08), Kit.at(s * 1.15, 3.7, -0.85), steel, Enum.Material.Metal)
		b:cyl(`Grip{s}`, 0.7, 0.08, Kit.alongZ(s * 1.15, 3.38, 1.05), C.RubberBlack, Enum.Material.Rubber)
	end

	b:box("Back", Vector3.new(1.7, 2.4, 0.1), Kit.at(0, 1.5, 1.4), steel, Enum.Material.Metal, true)
	b:box("FrontLip", Vector3.new(1.7, 0.7, 0.1), Kit.at(0, 0.6, -0.95), steel, Enum.Material.Metal)

	for i = 0, steps - 1 do
		local y = 0.55 + i * 0.4
		local z = 1.05 - i * 0.32
		b:box(`Step{i}`, Vector3.new(1.45, 0.1, 0.52), Kit.at(0, y, z), C.RubberBlack, Enum.Material.Rubber, true)
		b:box(`Nose{i}`, Vector3.new(1.45, 0.06, 0.05), Kit.at(0, y + 0.02, z - 0.26), C.SteelGrey, Enum.Material.Metal)
		b:box(
			`Riser{i}`,
			Vector3.new(1.4, 0.42, 0.08),
			Kit.at(0, y - 0.22, z + 0.2),
			CHARCOAL,
			Enum.Material.SmoothPlastic
		)
	end

	b:box("MastTie", Vector3.new(2.1, 0.14, 0.16), Kit.at(0, 3.55, -0.7), steel, Enum.Material.Metal)
	b:box("Mast", Vector3.new(0.16, 1.15, 0.16), Kit.at(0, 4.08, -0.7), steel, Enum.Material.Metal)
	b:box("Console", Vector3.new(1.45, 0.7, 0.32), Kit.at(0, 4.8, -0.85), steel, Enum.Material.SmoothPlastic, true)
	local screen =
		b:box("Screen", Vector3.new(0.95, 0.38, 0.04), Kit.at(0, 4.9, -1.03), C.Screen, Enum.Material.SmoothPlastic)
	screen.Reflectance = 0.22
	b:light(screen, Enum.NormalId.Front, 0.4, 5, Color3.fromRGB(180, 205, 220))
	b:box(
		"Keys",
		Vector3.new(0.9, 0.08, 0.04),
		Kit.at(0, 4.58, -1.02),
		Color3.fromRGB(28, 30, 34),
		Enum.Material.SmoothPlastic
	)
	if accent then
		b:box("Accent", Vector3.new(1.0, 0.04, 0.02), Kit.at(0, 5.12, -1.02), C.MasonGreen, Enum.Material.SmoothPlastic)
	end
	b:cyl("CupL", 0.2, 0.16, Kit.vertical(-0.55, 4.55, -0.78), CHARCOAL, Enum.Material.SmoothPlastic)
	b:cyl("CupR", 0.2, 0.16, Kit.vertical(0.55, 4.55, -0.78), CHARCOAL, Enum.Material.SmoothPlastic)

	return b:done()
end

return StairClimber
