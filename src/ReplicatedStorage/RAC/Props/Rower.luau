--!strict
-- Indoor rower, Concept2-style: 8 ft rail, fan cage, sliding seat, PM monitor.
-- Nickel rail, black frame, grey fan housing. Pivot bottom-center; the fan faces -Z.
local Kit = require(script.Parent.Kit)

local Rower = {
	kind = "rower",
	size = Vector3.new(2.05, 2.55, 8.15),
}

local function optNum(opts: { [string]: any }?, key: string, default: number, lo: number, hi: number): number
	local v = if opts ~= nil then opts[key] else nil
	if type(v) == "number" then
		return math.clamp(v :: number, lo, hi)
	end
	return default
end

function Rower.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("Rower", cf * CFrame.new(0, 0, -0.32))
	local C = Kit.Color
	local steel = C.SteelBlack
	local accent = optNum(opts, "accent", 1, 0, 1) >= 0.5

	b:box("Rail", Vector3.new(0.14, 0.16, 7.55), Kit.at(0, 0.52, 0.45), C.SteelGrey, Enum.Material.Metal, true)
	b:box("RailTop", Vector3.new(0.08, 0.04, 7.45), Kit.at(0, 0.62, 0.45), C.Chrome, Enum.Material.Metal)
	b:box("RearCap", Vector3.new(0.22, 0.2, 0.2), Kit.at(0, 0.5, 4.22), steel, Enum.Material.Metal)
	b:box("RearFoot", Vector3.new(0.9, 0.08, 0.28), Kit.at(0, 0.06, 4.12), steel, Enum.Material.Metal, true)
	b:box("RearBoot", Vector3.new(0.98, 0.04, 0.34), Kit.at(0, 0.02, 4.12), C.RubberBlack, Enum.Material.Rubber)

	-- Fan housing at the front.
	b:box(
		"Cage",
		Vector3.new(1.35, 1.25, 0.55),
		Kit.at(0, 0.75, -3.15),
		Color3.fromRGB(176, 180, 184),
		Enum.Material.SmoothPlastic,
		true
	)
	b:cyl("Fan", 0.28, 1.05, Kit.alongZ(0, 0.78, -3.15), C.SteelGrey, Enum.Material.Metal)
	b:cyl("FanHub", 0.34, 0.22, Kit.alongZ(0, 0.78, -3.15), steel, Enum.Material.Metal)
	for i = 0, 5 do
		local ang = math.rad(i * 60)
		local ox = math.cos(ang) * 0.28
		local oy = math.sin(ang) * 0.28
		local spoke = CFrame.new(ox, 0.78 + oy, -3.38) * CFrame.Angles(0, 0, ang)
		b:box(`Spoke{i}`, Vector3.new(0.035, 0.34, 0.02), spoke, C.SteelGrey, Enum.Material.Metal)
	end
	b:box("CageFoot", Vector3.new(1.7, 0.1, 0.45), Kit.at(0, 0.08, -3.2), steel, Enum.Material.Metal, true)
	for s = -1, 1, 2 do
		b:box(
			`CageBoot{s}`,
			Vector3.new(0.24, 0.04, 0.4),
			Kit.at(s * 0.7, 0.02, -3.2),
			C.RubberBlack,
			Enum.Material.Rubber
		)
	end
	b:box("Tank", Vector3.new(0.9, 0.35, 0.7), Kit.at(0, 0.4, -2.55), steel, Enum.Material.Metal, true)

	-- Foot stretchers.
	local foot = CFrame.new(0, 0.7, -2.35) * CFrame.Angles(math.rad(-38), 0, 0)
	b:box(
		"FootL",
		Vector3.new(0.4, 0.7, 0.08),
		foot * CFrame.new(-0.28, 0, 0),
		C.RubberBlack,
		Enum.Material.Rubber,
		true
	)
	b:box(
		"FootR",
		Vector3.new(0.4, 0.7, 0.08),
		foot * CFrame.new(0.28, 0, 0),
		C.RubberBlack,
		Enum.Material.Rubber,
		true
	)
	b:box("Heel", Vector3.new(0.95, 0.1, 0.12), Kit.at(0, 0.42, -2.15), steel, Enum.Material.Metal)
	b:box(
		"StrapL",
		Vector3.new(0.28, 0.03, 0.04),
		foot * CFrame.new(-0.28, 0.05, -0.05),
		C.SteelGrey,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"StrapR",
		Vector3.new(0.28, 0.03, 0.04),
		foot * CFrame.new(0.28, 0.05, -0.05),
		C.SteelGrey,
		Enum.Material.SmoothPlastic
	)

	-- Seat mid-stroke, handle and chain.
	b:box("Seat", Vector3.new(0.85, 0.08, 0.7), Kit.at(0, 0.78, 0.6), C.RubberBlack, Enum.Material.Rubber, true)
	b:box("SeatFrame", Vector3.new(0.4, 0.1, 0.55), Kit.at(0, 0.68, 0.6), steel, Enum.Material.Metal)
	for s = -1, 1, 2 do
		b:cyl(`SeatWheel{s}a`, 0.06, 0.1, Kit.at(s * 0.12, 0.6, 0.4), C.SteelGrey, Enum.Material.Metal)
		b:cyl(`SeatWheel{s}b`, 0.06, 0.1, Kit.at(s * 0.12, 0.6, 0.8), C.SteelGrey, Enum.Material.Metal)
	end
	b:cyl("Handle", 1.15, 0.08, Kit.at(0, 0.85, -1.15), C.RubberBlack, Enum.Material.Rubber)
	b:box("Chain", Vector3.new(0.025, 0.025, 1.7), Kit.at(0, 0.7, -2.05), C.SteelGrey, Enum.Material.Metal)
	b:cyl("HandleEndL", 0.08, 0.1, Kit.vertical(-0.55, 0.85, -1.15), C.Chrome, Enum.Material.Metal)
	b:cyl("HandleEndR", 0.08, 0.1, Kit.vertical(0.55, 0.85, -1.15), C.Chrome, Enum.Material.Metal)

	b:box("Arm", Vector3.new(0.08, 0.9, 0.08), Kit.at(0.35, 1.55, -2.85), steel, Enum.Material.Metal)
	b:box("Monitor", Vector3.new(0.55, 0.32, 0.08), Kit.at(0.15, 2.1, -2.9), steel, Enum.Material.SmoothPlastic)
	local screen =
		b:box("Screen", Vector3.new(0.4, 0.2, 0.02), Kit.at(0.15, 2.12, -2.95), C.Screen, Enum.Material.SmoothPlastic)
	screen.Reflectance = 0.2
	b:light(screen, Enum.NormalId.Front, 0.25, 3, Color3.fromRGB(160, 200, 180))
	if accent then
		b:box(
			"Accent",
			Vector3.new(0.4, 0.025, 0.015),
			Kit.at(0.15, 2.25, -2.96),
			C.MasonGreen,
			Enum.Material.SmoothPlastic
		)
	end

	return b:done()
end

return Rower
