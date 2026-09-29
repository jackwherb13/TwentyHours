--!strict
-- Shower stall: white tile walls, molded pan, chrome fixtures, curtain on a rod.
-- IMG_0380, IMG_0381. The curtain is white with green and gold bands — not a copy
-- of the printed logo curtain in the photos. Opening faces -Z.
local Kit = require(script.Parent.Kit)

local WIDTH = 3.5
local DEPTH = 4.0
local HEIGHT = 7.5

local ShowerStall = {
	kind = "shower_stall",
	size = Vector3.new(WIDTH, HEIGHT, DEPTH),
}

local TILE = Color3.fromRGB(242, 242, 238)
local GROUT = Color3.fromRGB(198, 196, 190)
local CURTAIN = Color3.fromRGB(248, 246, 240)

function ShowerStall.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("ShowerStall", cf)
	local C = Kit.Color
	local backZ = DEPTH / 2 - 0.08
	local leftX = -WIDTH / 2 + 0.08
	local rightX = WIDTH / 2 - 0.08
	local innerW = WIDTH - 0.32
	local innerD = DEPTH - 0.4

	local function chunk(
		name: string,
		size: Vector3,
		center: Vector3,
		color: Color3,
		material: Enum.Material,
		collide: boolean?
	)
		local limit = 2.35
		local nx = math.max(1, math.ceil(size.X / limit - 1e-4))
		local ny = math.max(1, math.ceil(size.Y / limit - 1e-4))
		local nz = math.max(1, math.ceil(size.Z / limit - 1e-4))
		local sx, sy, sz = size.X / nx, size.Y / ny, size.Z / nz
		local origin = center - size / 2
		for ix = 0, nx - 1 do
			for iy = 0, ny - 1 do
				for iz = 0, nz - 1 do
					b:box(
						`{name}_{ix}{iy}{iz}`,
						Vector3.new(sx, sy, sz),
						Kit.at(origin.X + sx * (ix + 0.5), origin.Y + sy * (iy + 0.5), origin.Z + sz * (iz + 0.5)),
						color,
						material,
						collide
					)
				end
			end
		end
	end

	chunk(
		"BackWall",
		Vector3.new(WIDTH, HEIGHT, 0.16),
		Vector3.new(0, HEIGHT / 2, backZ),
		TILE,
		Enum.Material.SmoothPlastic,
		true
	)
	chunk(
		"LeftWall",
		Vector3.new(0.16, HEIGHT, DEPTH),
		Vector3.new(leftX, HEIGHT / 2, 0),
		TILE,
		Enum.Material.SmoothPlastic,
		true
	)
	chunk(
		"RightWall",
		Vector3.new(0.16, HEIGHT, DEPTH),
		Vector3.new(rightX, HEIGHT / 2, 0),
		TILE,
		Enum.Material.SmoothPlastic,
		true
	)

	local function groutWall(tag: string, axis: string, span: number, height: number, at: (number, number) -> CFrame)
		local step = 0.67
		local i = 0
		local y = step
		while y < height - 0.15 do
			b:box(
				`{tag}H{i}`,
				Vector3.new(if axis == "x" then span else 0.025, 0.025, if axis == "x" then 0.025 else span),
				at(0, y),
				GROUT,
				Enum.Material.SmoothPlastic
			)
			y += step
			i += 1
		end
		local t = step
		local j = 0
		while t < span - 0.1 do
			local ox = if axis == "x" then -span / 2 + t else 0
			local oz = if axis == "x" then 0 else -span / 2 + t
			local groutH = height - 0.3
			local nSeg = math.ceil(groutH / 2.2)
			local segH = groutH / nSeg
			for s = 0, nSeg - 1 do
				b:box(
					`{tag}V{j}_{s}`,
					Vector3.new(0.025, segH, 0.025),
					at(if axis == "x" then ox else oz, segH * (s + 0.5) + 0.15),
					GROUT,
					Enum.Material.SmoothPlastic
				)
			end
			t += step
			j += 1
		end
	end

	groutWall("Back", "x", innerW, HEIGHT, function(x: number, y: number): CFrame
		return Kit.at(x, y, backZ - 0.09)
	end)
	groutWall("Left", "z", innerD, HEIGHT, function(z: number, y: number): CFrame
		return Kit.at(leftX + 0.1, y, z)
	end)
	groutWall("Right", "z", innerD, HEIGHT, function(z: number, y: number): CFrame
		return Kit.at(rightX - 0.1, y, z)
	end)

	b:box("Pan", Vector3.new(innerW, 0.14, innerD), Kit.at(0, 0.07, 0.12), TILE, Enum.Material.SmoothPlastic, true)
	b:box(
		"Curb",
		Vector3.new(innerW, 0.38, 0.18),
		Kit.at(0, 0.19, -DEPTH / 2 + 0.22),
		TILE,
		Enum.Material.SmoothPlastic,
		true
	)
	b:cyl("Drain", 0.05, 0.28, Kit.vertical(0.35, 0.16, 0.45), C.Chrome, Enum.Material.Metal)
	b:box("DrainGrate", Vector3.new(0.22, 0.02, 0.22), Kit.at(0.35, 0.16, 0.45), C.Chrome, Enum.Material.Metal)

	for side = -1, 1, 2 do
		local x = side * (WIDTH / 2 - 0.12)
		for k = 0, 14 do
			b:box(
				`Jamb{side}_{k}`,
				Vector3.new(0.18, 0.28, 0.06),
				Kit.at(x, 0.45 + k * 0.32, -DEPTH / 2 + 0.08),
				TILE,
				Enum.Material.SmoothPlastic
			)
		end
	end

	local rodY = 6.55
	b:cyl("Rod", innerW + 0.15, 0.07, Kit.at(0, rodY, -DEPTH / 2 + 0.28), C.Chrome, Enum.Material.Metal)
	b:box(
		"RodBracketL",
		Vector3.new(0.1, 0.16, 0.12),
		Kit.at(leftX + 0.12, rodY, -DEPTH / 2 + 0.22),
		C.Chrome,
		Enum.Material.Metal
	)
	b:box(
		"RodBracketR",
		Vector3.new(0.1, 0.16, 0.12),
		Kit.at(rightX - 0.12, rodY, -DEPTH / 2 + 0.22),
		C.Chrome,
		Enum.Material.Metal
	)

	local function curtain(tag: string, x: number)
		local z = -DEPTH / 2 + 0.18
		local clothH = 5.35
		local clothY = rodY - 0.15 - clothH / 2
		local nCloth = 3
		local pieceH = clothH / nCloth
		local clothBottom = clothY - clothH / 2
		for s = 0, nCloth - 1 do
			b:box(
				`{tag}Cloth{s}`,
				Vector3.new(1.22, pieceH, 0.03),
				Kit.at(x, clothBottom + pieceH * (s + 0.5), z),
				CURTAIN,
				Enum.Material.Fabric
			)
		end
		b:box(
			`{tag}Green`,
			Vector3.new(1.18, 0.55, 0.035),
			Kit.at(x, clothY - 0.35, z - 0.01),
			C.MasonGreen,
			Enum.Material.Fabric
		)
		b:box(
			`{tag}Gold`,
			Vector3.new(1.18, 0.28, 0.035),
			Kit.at(x, clothY - 0.8, z - 0.012),
			C.MasonGold,
			Enum.Material.Fabric
		)
		b:box(
			`{tag}Hem`,
			Vector3.new(1.18, 0.1, 0.04),
			Kit.at(x, clothY - clothH / 2 + 0.06, z),
			C.BleacherGreen,
			Enum.Material.Fabric
		)
		for r = -2, 2 do
			b:cyl(`{tag}Ring{r}`, 0.1, 0.07, Kit.vertical(x + r * 0.24, rodY + 0.02, z), C.Chrome, Enum.Material.Metal)
		end
	end
	curtain("CurtL", -0.7)
	curtain("CurtR", 0.72)

	local fixX = leftX + 0.18
	b:cyl("Arm", 0.55, 0.045, Kit.at(fixX + 0.15, 6.35, 0.15), C.Chrome, Enum.Material.Metal)
	b:ball("Head", 0.16, Kit.at(fixX + 0.42, 6.28, 0.15), C.Chrome, Enum.Material.Metal)
	b:cyl("HeadFace", 0.03, 0.14, Kit.alongZ(fixX + 0.42, 6.22, 0.08), C.SteelGrey, Enum.Material.Metal)
	b:box("ValvePlate", Vector3.new(0.16, 0.28, 0.06), Kit.at(fixX, 3.7, 0.35), C.Chrome, Enum.Material.Metal)
	b:cyl("Valve", 0.08, 0.12, Kit.at(fixX + 0.06, 3.7, 0.35), C.Chrome, Enum.Material.Metal)
	b:cyl("Handle", 0.16, 0.04, Kit.vertical(fixX + 0.12, 3.7, 0.35), C.Chrome, Enum.Material.Metal)
	local hookX = leftX + 0.12
	b:box("HoseHook", Vector3.new(0.22, 0.18, 0.12), Kit.at(hookX, 3.18, 0.35), C.Chrome, Enum.Material.Metal)
	b:cyl("Hose1", 0.56, 0.032, Kit.vertical(fixX + 0.04, 3.46, 0.35), C.Chrome, Enum.Material.Metal)
	b:cyl("Hose2", 0.5, 0.032, Kit.alongZ(fixX + 0.04, 3.2, 0.58), C.Chrome, Enum.Material.Metal)
	b:cyl("Hose3", 0.84, 0.032, Kit.vertical(fixX + 0.04, 3.6, 0.82), C.Chrome, Enum.Material.Metal)
	b:box("WandCradle", Vector3.new(0.1, 0.16, 0.1), Kit.at(fixX, 3.98, 0.8), C.Chrome, Enum.Material.Metal)
	b:ball("Wand", 0.08, Kit.at(fixX + 0.06, 4.02, 0.78), C.Chrome, Enum.Material.Metal)
	b:box("SlideBar", Vector3.new(0.06, 1.4, 0.06), Kit.at(fixX, 4.5, 0.85), C.Chrome, Enum.Material.Metal)
	b:cyl("Grab", 1.7, 0.07, Kit.alongZ(fixX + 0.02, 3.15, 1.55), C.Chrome, Enum.Material.Metal)
	b:box("GrabFlangeA", Vector3.new(0.1, 0.12, 0.1), Kit.at(fixX, 3.15, 0.75), C.Chrome, Enum.Material.Metal)
	b:box("GrabFlangeB", Vector3.new(0.1, 0.12, 0.1), Kit.at(fixX, 3.15, 2.35), C.Chrome, Enum.Material.Metal)
	b:box("Soap", Vector3.new(0.28, 0.08, 0.16), Kit.at(fixX + 0.02, 4.15, 1.15), C.Chrome, Enum.Material.Metal)
	b:box("Seat", Vector3.new(0.9, 0.08, 0.9), Kit.at(0.55, 1.55, 1.15), TILE, Enum.Material.SmoothPlastic)
	b:cyl("SeatPost", 1.45, 0.08, Kit.vertical(0.55, 0.8, 1.15), C.Chrome, Enum.Material.Metal)

	return b:done()
end

return ShowerStall
