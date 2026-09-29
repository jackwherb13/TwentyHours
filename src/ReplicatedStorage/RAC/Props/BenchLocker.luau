--!strict
-- Locker-room bench: maple slats on steel pedestals. opts.length in feet (default 8).
-- Seat height 18 in. Long axis is X; you sit facing -Z.
local Kit = require(script.Parent.Kit)

local DEFAULT_LENGTH = 8
local SEAT_H = 1.5
local SEAT_D = 1.05

local BenchLocker = {
	kind = "bench_locker",
	size = Vector3.new(DEFAULT_LENGTH, SEAT_H + 0.08, SEAT_D + 0.15),
}

function BenchLocker.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("BenchLocker", cf)
	local C = Kit.Color
	local length = DEFAULT_LENGTH
	if opts ~= nil and type(opts.length) == "number" then
		length = math.max(3, math.min(16, opts.length :: number))
	end

	local slats = 4
	local gap = 0.045
	local slatD = (SEAT_D - gap * (slats - 1)) / slats
	for i = 0, slats - 1 do
		local z = -SEAT_D / 2 + slatD / 2 + i * (slatD + gap)
		b:box(`Slat{i}`, Vector3.new(length, 0.12, slatD), Kit.at(0, SEAT_H, z), C.Maple, Enum.Material.Wood, true)
	end
	b:box(
		"Apron",
		Vector3.new(length - 0.15, 0.1, SEAT_D - 0.08),
		Kit.at(0, SEAT_H - 0.12, 0),
		C.WoodLocker,
		Enum.Material.Wood
	)

	local nPed = if length > 10 then 4 elseif length > 5.5 then 3 else 2
	for i = 0, nPed - 1 do
		local x = -length / 2 + length * ((i + 0.5) / nPed)
		local inset = if i == 0 or i == nPed - 1 then length * 0.08 else 0
		local px = x + (if i == 0 then inset elseif i == nPed - 1 then -inset else 0)
		b:box(
			`Post{i}`,
			Vector3.new(0.16, SEAT_H - 0.2, 0.16),
			Kit.at(px, (SEAT_H - 0.2) / 2 + 0.06, 0),
			C.SteelBlack,
			Enum.Material.Metal,
			true
		)
		b:box(
			`Foot{i}`,
			Vector3.new(0.55, 0.08, SEAT_D + 0.05),
			Kit.at(px, 0.04, 0),
			C.SteelBlack,
			Enum.Material.Metal,
			true
		)
		b:box(`CapL{i}`, Vector3.new(0.12, 0.1, 0.16), Kit.at(px - 0.24, 0.06, 0), C.RubberBlack, Enum.Material.Rubber)
		b:box(`CapR{i}`, Vector3.new(0.12, 0.1, 0.16), Kit.at(px + 0.24, 0.06, 0), C.RubberBlack, Enum.Material.Rubber)
		b:box(`Bracket{i}`, Vector3.new(0.34, 0.08, 0.7), Kit.at(px, SEAT_H - 0.2, 0), C.SteelGrey, Enum.Material.Metal)
		for s = -1, 1, 2 do
			b:cyl(
				`Bolt{i}_{s}`,
				0.03,
				0.06,
				Kit.vertical(px + s * 0.1, SEAT_H + 0.04, s * 0.22),
				C.SteelGrey,
				Enum.Material.Metal
			)
		end
	end

	b:box("Stretcher", Vector3.new(length * 0.78, 0.08, 0.1), Kit.at(0, 0.32, 0), C.SteelBlack, Enum.Material.Metal)
	b:box(
		"EndL",
		Vector3.new(0.08, 0.16, SEAT_D),
		Kit.at(-length / 2 + 0.04, SEAT_H, 0),
		C.WoodLocker,
		Enum.Material.Wood
	)
	b:box(
		"EndR",
		Vector3.new(0.08, 0.16, SEAT_D),
		Kit.at(length / 2 - 0.04, SEAT_H, 0),
		C.WoodLocker,
		Enum.Material.Wood
	)
	return b:done()
end

return BenchLocker
