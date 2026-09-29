--!strict
-- Floor-mounted restroom stall, warm grey phenolic, overhead braced (IMG_0379).
-- One closed stall. Door faces -Z. opts.stalls repeats stalls along +X (default 1).
local Kit = require(script.Parent.Kit)

local STALL_W = 3.15
local DEPTH = 5.05
local GAP = 0.95
local PANEL_H = 5.7
local DEFAULT_N = 1

local ToiletPartition = {
	kind = "toilet_partition",
	size = Vector3.new(STALL_W + 0.35, GAP + PANEL_H + 0.28, DEPTH),
}

local PANEL = Color3.fromRGB(168, 166, 160)
local PANEL_DARK = Color3.fromRGB(128, 126, 120)

local function optNum(opts: { [string]: any }?, key: string, default: number, lo: number, hi: number): number
	local n = default
	if opts ~= nil then
		local v = opts[key]
		if type(v) == "number" then
			n = v :: number
		end
	end
	return math.max(lo, math.min(hi, n))
end

function ToiletPartition.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("ToiletPartition", cf)
	local C = Kit.Color
	local n = math.floor(optNum(opts, "stalls", DEFAULT_N, 1, 4) + 0.5)
	local length = n * STALL_W + 0.2
	local y0 = GAP

	local function sliceY(
		name: string,
		size: Vector3,
		x: number,
		y: number,
		z: number,
		color: Color3,
		material: Enum.Material,
		collide: boolean?
	)
		local nSeg = math.max(1, math.ceil(size.Y / 2.8))
		local h = size.Y / nSeg
		local bottom = y - size.Y / 2
		for s = 0, nSeg - 1 do
			b:box(
				`{name}_{s}`,
				Vector3.new(size.X, h, size.Z),
				Kit.at(x, bottom + h * (s + 0.5), z),
				color,
				material,
				collide
			)
		end
	end
	local yc = y0 + PANEL_H / 2
	local frontZ = -DEPTH / 2
	local backZ = DEPTH / 2

	local function shoe(name: string, x: number, z: number)
		b:box(name .. "Plate", Vector3.new(0.28, 0.06, 0.28), Kit.at(x, 0.03, z), C.Chrome, Enum.Material.Metal)
		b:box(name .. "Post", Vector3.new(0.1, GAP - 0.04, 0.1), Kit.at(x, GAP / 2, z), C.Chrome, Enum.Material.Metal)
	end

	for i = 0, n do
		local x = -length / 2 + 0.1 + i * STALL_W
		local isEnd = i == 0 or i == n
		local sideDepth = if isEnd then DEPTH - 0.15 else 0.55
		local sideZ = if isEnd then (frontZ + backZ) / 2 + 0.05 else frontZ + 0.35
		sliceY(`Side{i}`, Vector3.new(0.08, PANEL_H, sideDepth), x, yc, sideZ, PANEL, Enum.Material.SmoothPlastic, true)
		sliceY(
			`Pilaster{i}`,
			Vector3.new(0.42, PANEL_H, 0.08),
			x,
			yc,
			frontZ + 0.08,
			PANEL,
			Enum.Material.SmoothPlastic,
			true
		)
		shoe(`Shoe{i}`, x, frontZ + 0.1)
		if isEnd then
			shoe(`ShoeB{i}`, x, backZ - 0.15)
		end
	end

	b:box(
		"Headrail",
		Vector3.new(length, 0.1, 0.12),
		Kit.at(0, y0 + PANEL_H + 0.08, frontZ + 0.08),
		C.Chrome,
		Enum.Material.Metal
	)
	for i = 0, n do
		local x = -length / 2 + 0.1 + i * STALL_W
		b:box(
			`Bracket{i}`,
			Vector3.new(0.16, 0.12, 0.16),
			Kit.at(x, y0 + PANEL_H + 0.02, frontZ + 0.08),
			C.Chrome,
			Enum.Material.Metal
		)
	end

	for i = 0, n - 1 do
		local xL = -length / 2 + 0.1 + i * STALL_W
		local xR = xL + STALL_W
		local doorW = STALL_W - 0.62
		local doorX = (xL + xR) / 2 + 0.06
		b:box(
			`Door{i}`,
			Vector3.new(doorW, PANEL_H - 0.08, 0.07),
			Kit.at(doorX, yc, frontZ - 0.02),
			PANEL,
			Enum.Material.SmoothPlastic,
			true
		)
		b:box(
			`DoorEdge{i}`,
			Vector3.new(0.05, PANEL_H - 0.12, 0.09),
			Kit.at(doorX - doorW / 2, yc, frontZ - 0.02),
			PANEL_DARK,
			Enum.Material.SmoothPlastic
		)
		for h, hy in { 0.72, 0.5, 0.28 } do
			local y = y0 + PANEL_H * hy
			b:cyl(
				`Hinge{i}_{h}`,
				0.14,
				0.09,
				Kit.vertical(doorX - doorW / 2 + 0.02, y, frontZ - 0.02),
				C.Chrome,
				Enum.Material.Metal
			)
		end
		local latchX = doorX + doorW / 2 - 0.12
		b:box(
			`Latch{i}`,
			Vector3.new(0.22, 0.1, 0.08),
			Kit.at(latchX, 3.35, frontZ - 0.08),
			C.Chrome,
			Enum.Material.Metal
		)
		b:box(
			`Keeper{i}`,
			Vector3.new(0.08, 0.16, 0.06),
			Kit.at(xR - 0.12, 3.35, frontZ + 0.02),
			C.Chrome,
			Enum.Material.Metal
		)
		b:cyl(
			`Hook{i}`,
			0.12,
			0.06,
			Kit.alongZ(doorX + 0.15, y0 + PANEL_H - 0.55, frontZ - 0.08),
			C.Chrome,
			Enum.Material.Metal
		)
		b:box(
			`Bumper{i}`,
			Vector3.new(0.1, 0.16, 0.06),
			Kit.at(doorX + doorW * 0.2, y0 + 0.35, frontZ - 0.07),
			C.RubberBlack,
			Enum.Material.Rubber
		)
		b:cyl(
			`Indicator{i}`,
			0.03,
			0.08,
			Kit.alongZ(latchX, 3.55, frontZ - 0.1),
			Color3.fromRGB(40, 140, 70),
			Enum.Material.SmoothPlastic
		)
		b:box(
			`Pull{i}`,
			Vector3.new(0.08, 0.28, 0.08),
			Kit.at(latchX - 0.15, 3.15, frontZ - 0.08),
			C.Chrome,
			Enum.Material.Metal
		)
	end

	return b:done()
end

return ToiletPartition
