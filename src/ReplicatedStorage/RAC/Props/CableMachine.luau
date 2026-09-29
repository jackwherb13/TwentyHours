--!strict
-- Dual adjustable-pulley functional trainer (IMG_0318, IMG_0369).
-- Two black stacks, chrome guide rods, stirrup handles, chin bar. Mason-green stack stripe
-- matches the Matrix line on the RAC floor. Pivot bottom-center, front faces -Z.
local Kit = require(script.Parent.Kit)

local CableMachine = {
	kind = "cable_machine",
	size = Vector3.new(6.6, 7.5, 3.55),
}

local function optNum(opts: { [string]: any }?, key: string, default: number, lo: number, hi: number): number
	local v = if opts ~= nil then opts[key] else nil
	if type(v) == "number" then
		return math.clamp(v :: number, lo, hi)
	end
	return default
end

local function band(
	b: any,
	name: string,
	size: Vector3,
	x: number,
	y0: number,
	y1: number,
	z: number,
	color: Color3,
	collide: boolean?
)
	local n = math.max(1, math.ceil((y1 - y0) / 1.8))
	local h = (y1 - y0) / n
	for i = 1, n do
		b:box(
			`{name}{i}`,
			Vector3.new(size.X, h, size.Z),
			Kit.at(x, y0 + h * (i - 0.5), z),
			color,
			Enum.Material.Metal,
			collide == true and i == 1
		)
	end
end

local function vrod(b: any, name: string, x: number, y0: number, y1: number, z: number, dia: number, color: Color3)
	local n = math.max(1, math.ceil((y1 - y0) / 1.5))
	local h = (y1 - y0) / n
	for i = 1, n do
		b:cyl(`{name}{i}`, h, dia, Kit.vertical(x, y0 + h * (i - 0.5), z), color, Enum.Material.Metal)
	end
end

function CableMachine.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("CableMachine", cf)
	local C = Kit.Color
	local steel = C.SteelBlack
	local plates = math.floor(optNum(opts, "plates", 12, 8, 14) + 0.5)
	local showAccent = optNum(opts, "accent", 1, 0, 1) >= 0.5

	for _, x in { -2.45, 2.45 } do
		local tag = if x < 0 then "L" else "R"
		local outer = if x < 0 then -1 else 1
		band(b, `TowerF{tag}`, Vector3.new(1.15, 1, 0.08), x, 0.35, 7.08, -1.28, steel, true)
		band(b, `TowerO{tag}`, Vector3.new(0.08, 1, 2.5), x + outer * 0.58, 0.35, 7.08, 0.05, steel, false)
		band(b, `TowerI{tag}`, Vector3.new(0.08, 1, 2.2), x - outer * 0.52, 0.08, 6.5, 0.1, steel, false)
		b:box(`Foot{tag}`, Vector3.new(1.4, 0.12, 3.15), Kit.at(x, 0.06, 0.05), steel, Enum.Material.Metal, true)
		b:box(`Boot{tag}`, Vector3.new(1.35, 0.04, 2.9), Kit.at(x, 0.14, 0.05), C.RubberBlack, Enum.Material.Rubber)
		-- Stack window and plates.
		b:box(
			`Window{tag}`,
			Vector3.new(0.78, 2.15, 0.04),
			Kit.at(x, 1.85, -1.22),
			Color3.fromRGB(12, 12, 14),
			Enum.Material.SmoothPlastic
		)
		for i = 1, plates do
			local y = 0.85 + (i - 1) * (1.85 / plates)
			b:box(`P{tag}{i}`, Vector3.new(0.7, 0.07, 0.42), Kit.at(x, y, -1.02), steel, Enum.Material.Metal)
		end
		vrod(b, `RodA{tag}`, x - 0.22, 0.06, 2.9, -0.88, 0.045, C.Chrome)
		vrod(b, `RodB{tag}`, x + 0.22, 0.06, 2.9, -0.88, 0.045, C.Chrome)
		local pinY = 0.85 + 4 * (1.85 / plates)
		b:cyl(`Pin{tag}`, 0.28, 0.05, Kit.alongZ(x + 0.22, pinY, -1.22), C.MasonGold, Enum.Material.Metal)
		b:ball(`PinKnob{tag}`, 0.07, Kit.at(x + 0.22, pinY, -1.38), C.MasonGold, Enum.Material.SmoothPlastic)
		if showAccent then
			band(b, `Accent{tag}`, Vector3.new(0.08, 1, 0.02), x + outer * 0.42, 0.7, 4.4, -1.34, C.MasonGreen, false)
		end
		-- Adjustable carriage, pulley, cable, stirrup.
		vrod(b, `Guide{tag}`, x - outer * 0.62, 0.06, 6.4, -1.45, 0.05, C.Chrome)
		b:box(
			`Carriage{tag}`,
			Vector3.new(0.28, 0.35, 0.22),
			Kit.at(x - outer * 0.62, 4.7, -1.45),
			steel,
			Enum.Material.Metal
		)
		b:cyl(`Pulley{tag}`, 0.08, 0.32, Kit.at(x - outer * 0.62, 6.45, -1.35), C.SteelGrey, Enum.Material.Metal)
		b:cyl(`P2{tag}`, 0.08, 0.22, Kit.at(x - outer * 0.62, 4.7, -1.58), C.SteelGrey, Enum.Material.Metal)
		b:box(
			`Cable{tag}`,
			Vector3.new(0.025, 1.7, 0.025),
			Kit.at(x - outer * 0.62, 5.55, -1.4),
			C.RubberBlack,
			Enum.Material.SmoothPlastic
		)
		b:box(
			`Cable2{tag}`,
			Vector3.new(0.04, 1.3, 0.04),
			Kit.at(x - outer * 0.72, 4.08, -1.62),
			C.RubberBlack,
			Enum.Material.SmoothPlastic
		)
		local hx = x - outer * 0.72
		b:cyl(`Grip{tag}`, 0.42, 0.07, Kit.at(hx, 3.46, -1.62), C.RubberBlack, Enum.Material.Rubber)
		b:box(`StrapL{tag}`, Vector3.new(0.03, 0.28, 0.03), Kit.at(hx - 0.18, 3.52, -1.62), steel, Enum.Material.Metal)
		b:box(`StrapR{tag}`, Vector3.new(0.03, 0.28, 0.03), Kit.at(hx + 0.18, 3.52, -1.62), steel, Enum.Material.Metal)
		b:cyl(`Swivel{tag}`, 0.08, 0.06, Kit.vertical(hx, 3.68, -1.62), C.Chrome, Enum.Material.Metal)
	end

	b:box("TopBeam", Vector3.new(6.3, 0.28, 0.28), Kit.at(0, 7.05, -0.2), steel, Enum.Material.Metal, true)
	b:box("TopRear", Vector3.new(6.3, 0.16, 0.16), Kit.at(0, 6.95, 1.2), steel, Enum.Material.Metal)
	b:cyl("Chin", 3.4, 0.11, Kit.at(0, 7.12, -0.3), C.Chrome, Enum.Material.Metal)
	b:box("BaseBridge", Vector3.new(3.4, 0.16, 0.35), Kit.at(0, 0.16, 0.2), steel, Enum.Material.Metal, true)
	b:box("FootPlate", Vector3.new(1.4, 0.08, 0.7), Kit.at(0, 0.1, -0.85), C.RubberBlack, Enum.Material.Rubber, true)
	-- Stored lat bar on the top hooks.
	b:cyl("StoredBar", 4.0, 0.09, Kit.at(0, 6.55, -0.85), C.Chrome, Enum.Material.Metal)
	b:cyl("StoredGripL", 0.35, 0.08, Kit.vertical(-1.85, 6.4, -0.85), C.RubberBlack, Enum.Material.Rubber)
	b:cyl("StoredGripR", 0.35, 0.08, Kit.vertical(1.85, 6.4, -0.85), C.RubberBlack, Enum.Material.Rubber)
	for s = -1, 1, 2 do
		b:box(`Hook{s}`, Vector3.new(0.08, 0.2, 0.12), Kit.at(s * 0.8, 6.7, -0.85), steel, Enum.Material.Metal)
	end

	return b:done()
end

return CableMachine
