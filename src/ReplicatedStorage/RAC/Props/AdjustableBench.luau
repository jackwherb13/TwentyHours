--!strict
-- Commercial adjustable bench (IMG_0318, IMG_0328). Black vinyl, black steel.
-- Seat height 17 in. Default back angle 28 deg. Ladder, wheels, transport handle.
-- Pivot bottom-center, foot end faces -Z. opts.incline = degrees (0 to 40).
local Kit = require(script.Parent.Kit)

local AdjustableBench = {
	kind = "adjustable_bench",
	size = Vector3.new(2.15, 2.8, 4.3),
}

local function optNum(opts: { [string]: any }?, key: string, default: number, lo: number, hi: number): number
	local v = if opts ~= nil then opts[key] else nil
	if type(v) == "number" then
		return math.clamp(v :: number, lo, hi)
	end
	return default
end

function AdjustableBench.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("AdjustableBench", cf)
	local C = Kit.Color
	local steel = C.SteelBlack
	local incline = math.rad(optNum(opts, "incline", 28, 0, 40))
	local backLen = 2.3
	local hingeY, hingeZ = 1.32, 0.05

	-- Seat pad, 12 in wide, slightly nose-down like a commercial bench.
	local seat = CFrame.new(0, 1.4, -0.72) * CFrame.Angles(math.rad(-4), 0, 0)
	b:box("Seat", Vector3.new(1.05, 0.22, 1.25), seat, C.Upholstery, Enum.Material.Leather, true)
	b:box(
		"SeatTop",
		Vector3.new(0.92, 0.03, 1.12),
		seat * CFrame.new(0, 0.12, 0),
		Color3.fromRGB(18, 18, 20),
		Enum.Material.Leather
	)
	b:box("SeatPan", Vector3.new(0.9, 0.08, 1.15), seat * CFrame.new(0, -0.14, 0), steel, Enum.Material.Metal)

	-- Positive incline raises the head (+Z). Rx(negative) tilts local +Z upward.
	local back = CFrame.new(0, hingeY, hingeZ) * CFrame.Angles(-incline, 0, 0) * CFrame.new(0, 0.12, backLen * 0.5)
	b:box("Back", Vector3.new(1.05, 0.22, backLen), back, C.Upholstery, Enum.Material.Leather, true)
	b:box(
		"BackTop",
		Vector3.new(0.92, 0.03, backLen - 0.12),
		back * CFrame.new(0, 0.12, 0),
		Color3.fromRGB(18, 18, 20),
		Enum.Material.Leather
	)
	b:box(
		"BackPan",
		Vector3.new(0.85, 0.08, backLen - 0.28),
		back * CFrame.new(0, -0.1, 0.08),
		steel,
		Enum.Material.Metal
	)
	b:cyl("Hinge", 1.15, 0.1, Kit.at(0, hingeY, hingeZ), C.SteelGrey, Enum.Material.Metal)
	for s = -1, 1, 2 do
		b:ball(`HingeCap{s}`, 0.14, Kit.at(s * 0.58, hingeY, hingeZ), steel, Enum.Material.Metal)
	end

	-- Spine and two A-style leg pairs.
	b:box("Spine", Vector3.new(0.22, 0.16, 3.5), Kit.at(0, 0.95, -0.15), steel, Enum.Material.Metal, true)
	b:box("FrontPost", Vector3.new(0.22, 0.85, 0.22), Kit.at(0, 0.5, -1.45), steel, Enum.Material.Metal, true)
	b:box("RearPost", Vector3.new(0.22, 0.7, 0.22), Kit.at(0, 0.45, 1.15), steel, Enum.Material.Metal, true)
	b:box("FrontFoot", Vector3.new(1.9, 0.12, 0.28), Kit.at(0, 0.1, -1.55), steel, Enum.Material.Metal, true)
	b:box("RearFoot", Vector3.new(1.7, 0.12, 0.28), Kit.at(0, 0.1, 1.85), steel, Enum.Material.Metal, true)
	for s = -1, 1, 2 do
		b:box(
			`FrontCap{s}`,
			Vector3.new(0.16, 0.1, 0.34),
			Kit.at(s * 0.88, 0.08, -1.55),
			C.RubberBlack,
			Enum.Material.Rubber
		)
		b:box(
			`RearCap{s}`,
			Vector3.new(0.16, 0.1, 0.34),
			Kit.at(s * 0.78, 0.08, 1.85),
			C.RubberBlack,
			Enum.Material.Rubber
		)
		b:cyl(`Wheel{s}`, 0.12, 0.28, Kit.vertical(s * 0.55, 0.16, -1.85), C.RubberBlack, Enum.Material.Rubber)
		b:cyl(`Axle{s}`, 0.2, 0.06, Kit.at(s * 0.55, 0.16, -1.85), C.SteelGrey, Enum.Material.Metal)
	end

	-- Backrest ladder and pop-pin at the head end.
	b:box("LadderRailL", Vector3.new(0.08, 0.85, 0.08), Kit.at(-0.28, 0.7, 1.55), steel, Enum.Material.Metal)
	b:box("LadderRailR", Vector3.new(0.08, 0.85, 0.08), Kit.at(0.28, 0.7, 1.55), steel, Enum.Material.Metal)
	for i = 0, 4 do
		b:cyl(`Rung{i}`, 0.5, 0.06, Kit.at(0, 0.4 + i * 0.16, 1.55), C.Chrome, Enum.Material.Metal)
	end
	b:cyl("Pin", 0.55, 0.07, Kit.at(0, 0.72, 1.62), C.MasonGold, Enum.Material.Metal)
	b:ball("PinKnob", 0.1, Kit.at(0.32, 0.72, 1.62), C.MasonGold, Enum.Material.SmoothPlastic)

	-- Transport handle at the foot.
	b:cyl("Handle", 0.7, 0.07, Kit.at(0, 0.55, -1.85), C.Chrome, Enum.Material.Metal)
	b:box("HandleL", Vector3.new(0.06, 0.42, 0.08), Kit.at(-0.32, 0.34, -1.84), steel, Enum.Material.Metal)
	b:box("HandleR", Vector3.new(0.06, 0.42, 0.08), Kit.at(0.32, 0.34, -1.84), steel, Enum.Material.Metal)

	-- Seat strut and a small foot roller.
	b:box("SeatStrut", Vector3.new(0.16, 0.35, 0.16), Kit.at(0, 1.05, -0.7), steel, Enum.Material.Metal)
	b:cyl("FootRoller", 1.15, 0.16, Kit.at(0, 0.42, -1.45), C.RubberBlack, Enum.Material.Rubber)

	return b:done()
end

return AdjustableBench
