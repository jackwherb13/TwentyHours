--!strict
-- Hanging championship banner. Generic green/gold/white panels — no names, years, or logos
-- copied from the gym (those banners commemorate real athletes). Pivot is the bottom hem.
-- Decorated face is -Z; the back repeats the same layout.
local Kit = require(script.Parent.Kit)

local W = 3.35
local H = 8.15
local HANGER = 1.35

local Banner = {
	kind = "banner",
	size = Vector3.new(W + 0.2, H + HANGER, 0.42),
}

local NAVY = Color3.fromRGB(18, 42, 92)
local GREEN = Color3.fromRGB(0, 78, 42)

function Banner.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("Banner", cf)
	local C = Kit.Color

	local function sliceY(
		name: string,
		size: Vector3,
		x: number,
		y: number,
		z: number,
		color: Color3,
		material: Enum.Material,
		limit: number
	)
		local nSeg = math.max(1, math.ceil(size.Y / limit))
		local h = size.Y / nSeg
		local bottom = y - size.Y / 2
		for s = 0, nSeg - 1 do
			b:box(`{name}_{s}`, Vector3.new(size.X, h, size.Z), Kit.at(x, bottom + h * (s + 0.5), z), color, material)
		end
	end

	sliceY("Cloth", Vector3.new(W, H, 0.05), 0, H / 2, 0, C.OffWhite, Enum.Material.Fabric, 4)
	b:box("Hem", Vector3.new(W, 0.1, 0.08), Kit.at(0, 0.05, 0), GREEN, Enum.Material.Fabric)
	b:cyl("Dowel", W + 0.35, 0.1, Kit.at(0, H + 0.02, 0), C.Maple, Enum.Material.Wood)
	b:box("Sleeve", Vector3.new(W, 0.16, 0.1), Kit.at(0, H - 0.06, 0), C.OffWhite, Enum.Material.Fabric)
	for side = -1, 1, 2 do
		b:cyl(
			`Cord{side}`,
			HANGER,
			0.035,
			Kit.vertical(side * (W * 0.32), H + HANGER / 2, 0),
			C.SteelBlack,
			Enum.Material.Metal
		)
	end
	b:cyl("CeilingBar", W * 0.75, 0.06, Kit.at(0, H + HANGER, 0), C.SteelGrey, Enum.Material.Metal)

	local function face(sign: number, tag: string)
		local z = sign * 0.045
		b:box(`{tag}Head`, Vector3.new(W - 0.12, 1.55, 0.02), Kit.at(0, H - 0.95, z), GREEN, Enum.Material.Fabric)
		b:cyl(`{tag}Seal`, 0.04, 0.95, Kit.alongZ(0, H - 0.95, z + sign * 0.02), NAVY, Enum.Material.SmoothPlastic)
		b:cyl(
			`{tag}SealIn`,
			0.03,
			0.55,
			Kit.alongZ(0, H - 0.95, z + sign * 0.035),
			C.MasonGold,
			Enum.Material.SmoothPlastic
		)
		b:box(`{tag}Band`, Vector3.new(W - 0.12, 0.85, 0.02), Kit.at(0, H - 2.35, z), GREEN, Enum.Material.Fabric)
		b:box(
			`{tag}Gold1`,
			Vector3.new(W - 0.28, 0.1, 0.025),
			Kit.at(0, H - 2.85, z),
			C.MasonGold,
			Enum.Material.SmoothPlastic
		)
		b:box(`{tag}Title`, Vector3.new(W * 0.62, 0.22, 0.02), Kit.at(0, H - 3.2, z), NAVY, Enum.Material.SmoothPlastic)
		b:box(`{tag}Sub`, Vector3.new(W * 0.78, 0.14, 0.02), Kit.at(0, H - 3.5, z), GREEN, Enum.Material.SmoothPlastic)
		for i = 0, 5 do
			local y = H - 4.15 - i * 0.42
			local barW = W * (0.55 - (i % 2) * 0.12)
			b:box(
				`{tag}Row{i}`,
				Vector3.new(barW, 0.1, 0.02),
				Kit.at(0, y, z),
				if i % 2 == 0 then GREEN else NAVY,
				Enum.Material.SmoothPlastic
			)
			b:box(
				`{tag}Dot{i}`,
				Vector3.new(0.1, 0.1, 0.02),
				Kit.at(-barW / 2 - 0.16, y, z),
				C.MasonGold,
				Enum.Material.SmoothPlastic
			)
		end
		b:box(
			`{tag}Foot`,
			Vector3.new(W - 0.12, 0.7, 0.02),
			Kit.at(0, 0.55, z),
			C.MasonGold,
			Enum.Material.SmoothPlastic
		)
		b:box(
			`{tag}FootMark`,
			Vector3.new(0.7, 0.38, 0.02),
			Kit.at(0, 0.55, z + sign * 0.015),
			GREEN,
			Enum.Material.SmoothPlastic
		)
		sliceY(
			`{tag}EdgeL`,
			Vector3.new(0.06, H - 0.2, 0.03),
			-W / 2 + 0.05,
			H / 2,
			z,
			GREEN,
			Enum.Material.Fabric,
			2.4
		)
		sliceY(`{tag}EdgeR`, Vector3.new(0.06, H - 0.2, 0.03), W / 2 - 0.05, H / 2, z, GREEN, Enum.Material.Fabric, 2.4)
	end

	face(-1, "F")
	face(1, "B")
	return b:done()
end

return Banner
