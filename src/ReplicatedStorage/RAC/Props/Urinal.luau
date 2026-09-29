--!strict
-- Wall-hung porcelain urinal with a chrome flushometer (IMG_0379).
-- Pivot is the bottom of the china, which sits about 10 in above the finished floor
-- on the real fixture — raise the model by that amount when placing it.
-- Bowl opens toward -Z. The handle sticks out to +X.
local Kit = require(script.Parent.Kit)

local Urinal = {
	kind = "urinal",
	size = Vector3.new(1.85, 3.55, 1.72),
}

local CHINA = Color3.fromRGB(244, 244, 240)
local SHADOW = Color3.fromRGB(186, 196, 198)
local WATER = Color3.fromRGB(176, 206, 210)

function Urinal.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("Urinal", cf)
	local C = Kit.Color

	b:box("Back", Vector3.new(1.12, 2.05, 0.32), Kit.at(0, 1.28, 0.55), CHINA, Enum.Material.SmoothPlastic, true)
	b:box("Shoulder", Vector3.new(1.28, 0.7, 0.55), Kit.at(0, 1.72, 0.28), CHINA, Enum.Material.SmoothPlastic)
	b:box("Rim", Vector3.new(1.38, 0.22, 1.05), Kit.at(0, 1.42, 0.02), CHINA, Enum.Material.SmoothPlastic, true)
	b:box("Basin", Vector3.new(1.12, 0.38, 0.78), Kit.at(0, 1.12, 0.08), SHADOW, Enum.Material.SmoothPlastic)
	b:box("Water", Vector3.new(0.72, 0.06, 0.42), Kit.at(0, 1.22, -0.02), WATER, Enum.Material.Glass)
	b:box("Skirt", Vector3.new(0.92, 0.62, 0.62), Kit.at(0, 0.72, 0.28), CHINA, Enum.Material.SmoothPlastic)
	b:box("SkirtLow", Vector3.new(0.55, 0.42, 0.4), Kit.at(0, 0.28, 0.38), CHINA, Enum.Material.SmoothPlastic)
	b:cyl("Drain", 0.08, 0.16, Kit.vertical(0, 0.08, 0.32), C.Chrome, Enum.Material.Metal)
	b:box("Lip", Vector3.new(1.22, 0.08, 0.1), Kit.at(0, 1.32, -0.46), CHINA, Enum.Material.SmoothPlastic)
	for side = -1, 1, 2 do
		b:box(
			`Cheek{side}`,
			Vector3.new(0.1, 0.85, 0.7),
			Kit.at(side * 0.58, 1.35, 0.18),
			CHINA,
			Enum.Material.SmoothPlastic
		)
	end

	b:cyl("Spud", 0.12, 0.12, Kit.vertical(0, 2.38, 0.48), C.Chrome, Enum.Material.Metal)
	b:cyl("Supply", 0.85, 0.07, Kit.vertical(0, 2.85, 0.62), C.Chrome, Enum.Material.Metal)
	b:cyl("Valve", 0.22, 0.18, Kit.vertical(0, 3.22, 0.62), C.Chrome, Enum.Material.Metal)
	b:box("ValveCap", Vector3.new(0.16, 0.08, 0.16), Kit.at(0, 3.36, 0.62), C.Chrome, Enum.Material.Metal)
	b:cyl("Handle", 0.42, 0.045, Kit.at(0.28, 3.2, 0.62), C.Chrome, Enum.Material.Metal)
	b:ball("HandleTip", 0.07, Kit.at(0.5, 3.2, 0.62), C.Chrome, Enum.Material.Metal)
	b:cyl("Escutcheon", 0.04, 0.16, Kit.alongZ(0, 3.09, 0.78), C.Chrome, Enum.Material.Metal)
	b:cyl("WallPipe", 0.32, 0.1, Kit.alongZ(0, 3.05, 0.68), C.Chrome, Enum.Material.Metal)
	for side = -1, 1, 2 do
		b:cyl(`Bolt{side}`, 0.04, 0.08, Kit.alongZ(side * 0.38, 2.15, 0.74), C.Chrome, Enum.Material.Metal)
	end
	b:box("Flange", Vector3.new(0.55, 0.7, 0.05), Kit.at(0, 2.55, 0.74), C.Chrome, Enum.Material.Metal)

	return b:done()
end

return Urinal
