--!strict
-- Wall-hung bi-level fountain with a bottle filler. Stainless basins, Mason-green filler panel.
-- Bottom of the back splash is about 18 in off the floor (ADA lower basin). Pivot is the floor
-- because blueprint props have no elevation. Basins face -Z.
local Kit = require(script.Parent.Kit)

local WaterFountain = {
	kind = "water_fountain",
	size = Vector3.new(3.25, 5.35, 1.25),
}

local STEEL = Color3.fromRGB(186, 190, 196)
local BASIN = Color3.fromRGB(150, 156, 162)

local function optNum(opts: { [string]: any }?, key: string, default: number, lo: number, hi: number): number
	local v = if opts ~= nil then opts[key] else nil
	if type(v) == "number" then
		return math.clamp(v :: number, lo, hi)
	end
	return default
end

local function basin(b: any, name: string, x: number, rim: number)
	local C = Kit.Color
	b:box(`{name}Bowl`, Vector3.new(0.85, 0.22, 0.7), Kit.at(x, rim - 0.12, -0.28), BASIN, Enum.Material.Metal, true)
	b:box(
		`{name}Well`,
		Vector3.new(0.62, 0.06, 0.42),
		Kit.at(x, rim - 0.08, -0.28),
		Color3.fromRGB(40, 70, 78),
		Enum.Material.SmoothPlastic
	)
	local water = b:box(
		`{name}Water`,
		Vector3.new(0.4, 0.02, 0.22),
		Kit.at(x, rim - 0.04, -0.28),
		Color3.fromRGB(80, 150, 170),
		Enum.Material.Glass
	)
	water.Transparency = 0.35
	b:box(`{name}Grate`, Vector3.new(0.18, 0.02, 0.12), Kit.at(x, rim - 0.02, -0.4), C.SteelGrey, Enum.Material.Metal)
	b:cyl(`{name}Bubbler`, 0.14, 0.06, Kit.vertical(x, rim + 0.08, -0.42), C.Chrome, Enum.Material.Metal)
	b:cyl(`{name}Nozzle`, 0.08, 0.035, Kit.alongZ(x, rim + 0.12, -0.38), C.Chrome, Enum.Material.Metal)
	b:box(`{name}Bar`, Vector3.new(0.55, 0.06, 0.08), Kit.at(x, rim - 0.02, -0.62), C.Chrome, Enum.Material.Metal)
	b:box(`{name}Skirt`, Vector3.new(0.9, 0.72, 0.14), Kit.at(x, rim - 0.55, -0.06), STEEL, Enum.Material.Metal)
end

function WaterFountain.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("WaterFountain", cf)
	local C = Kit.Color
	local accent = optNum(opts, "accent", 1, 0, 1) >= 0.5

	b:box("BackA", Vector3.new(2.9, 3.1, 0.08), Kit.at(0, 1.55, 0.28), STEEL, Enum.Material.Metal, true)
	b:box("BackB", Vector3.new(2.9, 1.5, 0.08), Kit.at(0, 3.85, 0.28), STEEL, Enum.Material.Metal, true)
	b:box("BackC", Vector3.new(1.15, 1.15, 0.1), Kit.at(0, 4.7, 0.26), STEEL, Enum.Material.Metal, true)
	for s = -1, 1, 2 do
		b:cyl(`Mount{s}`, 0.05, 0.08, Kit.alongZ(s * 1.15, 2.0, 0.32), C.SteelGrey, Enum.Material.Metal)
		b:cyl(`MountH{s}`, 0.05, 0.08, Kit.alongZ(s * 0.35, 4.9, 0.32), C.SteelGrey, Enum.Material.Metal)
	end

	-- Adult basin on the left (rim ~40 in), accessible basin on the right (rim ~34 in).
	basin(b, "Hi", -0.7, 3.35)
	basin(b, "Lo", 0.75, 2.85)
	b:box("Pedestal", Vector3.new(2.4, 1.8, 0.5), Kit.at(0.05, 0.9, -0.05), STEEL, Enum.Material.Metal, true)
	b:box("Apron", Vector3.new(2.7, 0.7, 0.55), Kit.at(0.05, 2.15, -0.05), STEEL, Enum.Material.Metal, true)
	b:box("TrapL", Vector3.new(0.12, 2.025, 0.12), Kit.at(-0.7, 1.0125, -0.12), C.Chrome, Enum.Material.Metal)
	b:box("TrapR", Vector3.new(0.12, 1.95, 0.12), Kit.at(0.75, 0.975, -0.12), C.Chrome, Enum.Material.Metal)

	-- Bottle filler cabinet centered above the basins.
	b:box("Filler", Vector3.new(1.05, 1.35, 0.55), Kit.at(0, 4.35, 0.06), STEEL, Enum.Material.Metal, true)
	b:box("FillerHood", Vector3.new(1.1, 0.1, 0.48), Kit.at(0, 5.05, -0.02), C.SteelGrey, Enum.Material.Metal)
	b:box(
		"Recess",
		Vector3.new(0.55, 0.7, 0.12),
		Kit.at(0, 4.25, -0.22),
		Color3.fromRGB(30, 34, 38),
		Enum.Material.SmoothPlastic
	)
	b:cyl("FillerNozzle", 0.16, 0.05, Kit.vertical(0, 4.5, -0.28), C.Chrome, Enum.Material.Metal)
	b:box("Drip", Vector3.new(0.4, 0.04, 0.22), Kit.at(0, 3.85, -0.28), C.SteelGrey, Enum.Material.Metal)
	for i = -1, 1 do
		b:box(
			`DripBar{i}`,
			Vector3.new(0.32, 0.015, 0.02),
			Kit.at(0, 3.88, -0.22 + i * 0.05),
			C.Chrome,
			Enum.Material.Metal
		)
	end
	b:box("Sensor", Vector3.new(0.28, 0.16, 0.02), Kit.at(0, 4.7, -0.24), C.SteelBlack, Enum.Material.SmoothPlastic)
	if accent then
		b:box("Badge", Vector3.new(0.7, 0.28, 0.02), Kit.at(0, 4.85, -0.24), C.MasonGreen, Enum.Material.SmoothPlastic)
		b:box(
			"BadgeMark",
			Vector3.new(0.16, 0.12, 0.015),
			Kit.at(0, 4.85, -0.255),
			C.OffWhite,
			Enum.Material.SmoothPlastic
		)
	end
	local led = b:box(
		"Ready",
		Vector3.new(0.06, 0.04, 0.015),
		Kit.at(0.28, 4.55, -0.25),
		Color3.fromRGB(40, 200, 90),
		Enum.Material.Neon
	)
	led.Transparency = 0.15

	return b:done()
end

return WaterFountain
