--!strict
-- Four-post power rack, Hammer Strength HD-style (IMG_0318, IMG_0328).
-- 49 in inside width, 36 in depth, 90 in tall. Side plate horns and a loaded Olympic bar.
-- Black steel, black bumper plates, machined hubs. Pivot bottom-center, front faces -Z.
local Kit = require(script.Parent.Kit)

local PowerRack = {
	kind = "power_rack",
	size = Vector3.new(7.4, 7.6, 5.15),
}

local HOLE = Color3.fromRGB(86, 88, 92)

local function optNum(opts: { [string]: any }?, key: string, default: number, lo: number, hi: number): number
	local v = if opts ~= nil then opts[key] else nil
	if type(v) == "number" then
		return math.clamp(v :: number, lo, hi)
	end
	return default
end

local function upright(b: any, name: string, x: number, z: number, color: Color3)
	local h = 1.875
	for i = 1, 4 do
		b:box(`{name}{i}`, Vector3.new(0.28, h, 0.28), Kit.at(x, h * (i - 0.5), z), color, Enum.Material.Metal, true)
		b:box(
			`{name}S{i}`,
			Vector3.new(0.12, h - 0.04, 0.03),
			Kit.at(x, h * (i - 0.5), z - 0.155),
			HOLE,
			Enum.Material.Metal
		)
	end
end

function PowerRack.build(cf: CFrame, opts: { [string]: any }?): Model
	-- Bar plates set the front of the box; storage plates set the back. Shift so the pivot is the center.
	local b = Kit.new("PowerRack", cf * CFrame.new(0, 0, 0.24))
	local C = Kit.Color
	local steel = C.SteelBlack
	local perSide = math.floor(optNum(opts, "plates", 2, 0, 3) + 0.5)
	local xL, xR = -2.17, 2.17
	local zF, zB = -1.72, 1.52

	upright(b, "FL", xL, zF, steel)
	upright(b, "FR", xR, zF, steel)
	upright(b, "BL", xL, zB, steel)
	upright(b, "BR", xR, zB, steel)

	-- Numbered-hole dots on the front uprights (the face you see from the platform).
	for _, x in { xL, xR } do
		local tag = if x < 0 then "L" else "R"
		for i = 0, 11 do
			b:box(
				`Hole{tag}{i}`,
				Vector3.new(0.07, 0.045, 0.02),
				Kit.at(x, 1.55 + i * 0.42, zF - 0.175),
				C.SteelBlack,
				Enum.Material.Metal
			)
		end
	end

	for _, x in { xL, xR } do
		local tag = if x < 0 then "L" else "R"
		for _, z in { zF, zB } do
			local endTag = if z < 0 then "F" else "B"
			b:box(
				`Foot{tag}{endTag}`,
				Vector3.new(0.72, 0.1, 0.5),
				Kit.at(x, 0.05, z),
				steel,
				Enum.Material.Metal,
				true
			)
			b:box(
				`Pad{tag}{endTag}`,
				Vector3.new(0.78, 0.04, 0.56),
				Kit.at(x, 0.02, z),
				C.RubberBlack,
				Enum.Material.Rubber
			)
		end
	end

	b:box("Header", Vector3.new(4.7, 0.62, 0.34), Kit.at(0, 7.15, zF), steel, Enum.Material.Metal, true)
	b:box("HeaderRear", Vector3.new(4.7, 0.28, 0.22), Kit.at(0, 7.28, zB), steel, Enum.Material.Metal, true)
	b:box("Chin", Vector3.new(3.6, 0.1, 0.12), Kit.at(0, 7.38, zF - 0.12), C.Chrome, Enum.Material.Metal)
	for s = -1, 1, 2 do
		b:cyl(`Grip{s}`, 0.48, 0.09, Kit.alongZ(s * 1.2, 7.22, zF - 0.42), C.Chrome, Enum.Material.Metal)
		b:box(`GripCap{s}`, Vector3.new(0.12, 0.12, 0.1), Kit.at(s * 1.2, 7.22, zF - 0.68), steel, Enum.Material.Metal)
	end
	b:cyl("SideTopL", 3.15, 0.14, Kit.alongZ(xL, 7.22, -0.1), steel, Enum.Material.Metal)
	b:cyl("SideTopR", 3.15, 0.14, Kit.alongZ(xR, 7.22, -0.1), steel, Enum.Material.Metal)
	b:box("BaseFront", Vector3.new(4.34, 0.16, 0.16), Kit.at(0, 0.2, zF), steel, Enum.Material.Metal, true)
	b:box("BaseRear", Vector3.new(4.34, 0.16, 0.16), Kit.at(0, 0.2, zB), steel, Enum.Material.Metal, true)
	b:cyl("SideBotL", 3.15, 0.14, Kit.alongZ(xL, 0.28, -0.1), steel, Enum.Material.Metal)
	b:cyl("SideBotR", 3.15, 0.14, Kit.alongZ(xR, 0.28, -0.1), steel, Enum.Material.Metal)
	b:box("StringerL", Vector3.new(0.14, 0.16, 3.05), Kit.at(xL + 0.22, 4.15, -0.1), steel, Enum.Material.Metal)
	b:box("StringerR", Vector3.new(0.14, 0.16, 3.05), Kit.at(xR - 0.22, 4.15, -0.1), steel, Enum.Material.Metal)

	-- Spotter arms inside the cage, lip at the front so a bar cannot roll off.
	for s = -1, 1, 2 do
		b:box(`Safe{s}`, Vector3.new(0.32, 0.22, 3.4), Kit.at(s * 2.02, 2.35, -0.05), steel, Enum.Material.Metal, true)
		b:box(
			`SafeLip{s}`,
			Vector3.new(0.32, 0.32, 0.12),
			Kit.at(s * 2.02, 2.52, zF + 0.22),
			steel,
			Enum.Material.Metal
		)
		b:cyl(`Cup{s}`, 0.42, 0.1, Kit.alongZ(s * 1.95, 3.58, zF - 0.28), steel, Enum.Material.Metal)
		b:box(`CupLip{s}`, Vector3.new(0.16, 0.28, 0.08), Kit.at(s * 1.95, 3.74, zF - 0.5), steel, Enum.Material.Metal)
		b:cyl(`CupPad{s}`, 0.16, 0.12, Kit.alongZ(s * 1.95, 3.64, zF - 0.28), C.RubberBlack, Enum.Material.Rubber)
	end

	-- Olympic bar (7.2 ft) resting in the J-cups. Shaft, sleeves, knurl, collars, plates.
	local barY, barZ = 3.7, zF - 0.28
	local shaft = b:cyl("Shaft", 4.4, 0.092, Kit.at(0, barY, barZ), C.Chrome, Enum.Material.Metal)
	shaft.Reflectance = 0.35
	b:cyl("KnurlL", 0.7, 0.1, Kit.at(-0.85, barY, barZ), C.SteelGrey, Enum.Material.Metal)
	b:cyl("KnurlR", 0.7, 0.1, Kit.at(0.85, barY, barZ), C.SteelGrey, Enum.Material.Metal)
	b:cyl("KnurlC", 0.4, 0.098, Kit.at(0, barY, barZ), C.SteelGrey, Enum.Material.Metal)
	for s = -1, 1, 2 do
		local sleeve = b:cyl(`Sleeve{s}`, 1.4, 0.15, Kit.at(s * 2.9, barY, barZ), C.Chrome, Enum.Material.Metal)
		sleeve.Reflectance = 0.3
		for p = 1, perSide do
			local px = s * (2.28 + (p - 0.5) * 0.2)
			b:cyl(`BarPlate{s}{p}`, 0.17, 1.48, Kit.at(px, barY, barZ), C.RubberBlack, Enum.Material.Rubber)
			b:cyl(`BarHub{s}{p}`, 0.19, 0.4, Kit.at(px, barY, barZ), C.Chrome, Enum.Material.Metal)
			b:box(
				`BarTag{s}{p}`,
				Vector3.new(0.02, 0.2, 0.14),
				Kit.at(px + s * 0.09, barY + 0.28, barZ),
				C.OffWhite,
				Enum.Material.SmoothPlastic
			)
		end
		local collarX = s * (2.28 + perSide * 0.2 + 0.08)
		b:cyl(`Collar{s}`, 0.1, 0.2, Kit.at(collarX, barY, barZ), C.SteelBlack, Enum.Material.Metal)
	end

	-- Side plate storage on the rear uprights: 45s, 25s, 10s.
	local horns = {
		{ y = 1.15, d = 1.48, t = 0.16, n = 2 },
		{ y = 2.4, d = 1.1, t = 0.12, n = 2 },
		{ y = 3.55, d = 0.84, t = 0.08, n = 1 },
	}
	for s = -1, 1, 2 do
		for i, horn in horns do
			b:cyl(`Horn{s}{i}`, 0.72, 0.08, Kit.at(s * (2.17 + 0.36), horn.y, zB), C.Chrome, Enum.Material.Metal)
			for p = 1, horn.n do
				local px = s * (2.42 + (p - 0.5) * (horn.t + 0.02))
				b:cyl(`Store{s}{i}{p}`, horn.t, horn.d, Kit.at(px, horn.y, zB), C.RubberBlack, Enum.Material.Rubber)
				b:box(
					`StoreRib{s}{i}{p}`,
					Vector3.new(horn.t * 0.55, horn.d - 0.04, 0.05),
					Kit.at(px, horn.y, zB),
					C.RubberBlack,
					Enum.Material.Rubber
				)
				b:cyl(
					`StoreHub{s}{i}{p}`,
					horn.t + 0.02,
					horn.d * 0.28,
					Kit.at(px, horn.y, zB),
					C.Chrome,
					Enum.Material.Metal
				)
			end
		end
	end

	return b:done()
end

return PowerRack
