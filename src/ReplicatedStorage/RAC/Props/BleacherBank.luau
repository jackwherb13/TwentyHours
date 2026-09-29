--!strict
-- Telescopic bleacher bank, closed by default (IMG_0332, IMG_0333, IMG_0337_f005–f007).
-- Green deck noses, gold vertical bands, recessed metal aisles, black aisle rails, steel end frames.
-- opts.length (ft), opts.rows, opts.extended (true = pulled out toward -Z).
-- Both poses are centered on the pivot. Extended depth is rows * TREAD; shift the pivot
-- toward +Z by half the added depth to keep the rear (wall) edge fixed.
local Kit = require(script.Parent.Kit)

local RISE = 0.85
local TREAD = 2.05
local SKIRT = 0.42
local CLOSED_D = 4.25
local RAIL_UP = 1.8
local DEFAULT_LENGTH = 34
local DEFAULT_ROWS = 14

local BleacherBank = {
	kind = "bleacher_bank",
	size = Vector3.new(DEFAULT_LENGTH, SKIRT + DEFAULT_ROWS * RISE + RAIL_UP, CLOSED_D),
}

local LATCH = Color3.fromRGB(232, 186, 42)
local TREAD_GREY = Color3.fromRGB(176, 178, 182)
local TREAD_DARK = Color3.fromRGB(92, 94, 98)

type Span = { a: number, b: number, kind: string }

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

local function along(pos: Vector3, dir: Vector3): CFrame
	local d = if dir.Magnitude < 1e-5 then Vector3.new(1, 0, 0) else dir.Unit
	local hint = if math.abs(d.Y) > 0.92 then Vector3.new(1, 0, 0) else Vector3.new(0, 1, 0)
	local yAxis = d:Cross(hint)
	if yAxis.Magnitude < 1e-5 then
		yAxis = d:Cross(Vector3.new(0, 0, 1))
	end
	return CFrame.fromMatrix(pos, d, yAxis.Unit)
end

local function spansFor(length: number): { Span }
	local cap = math.max(0.8, math.min(1.2, length * 0.032))
	local flank = 1.6
	local aisleW = 2.75
	local nAisle = if length >= 48 then 2 elseif length >= 22 then 1 else 0
	local widths: { number } = {}
	local kinds: { string } = {}
	local function add(w: number, k: string)
		if w > 0.2 then
			table.insert(widths, w)
			table.insert(kinds, k)
		end
	end
	local function greens(budget: number)
		if budget > 16 then
			local stripe = 1.5
			local g = (budget - stripe) / 2
			add(g, "green")
			add(stripe, "gold")
			add(g, "green")
		else
			add(budget, "green")
		end
	end

	add(cap, "gold")
	local middle = length - cap * 2
	if nAisle <= 0 then
		greens(middle)
	elseif nAisle == 1 then
		local block = flank * 2 + aisleW
		local g = (middle - block) / 2
		greens(g)
		add(flank, "gold")
		add(aisleW, "aisle")
		add(flank, "gold")
		greens(middle - block - g)
	else
		local block = flank * 2 + aisleW
		local g = (middle - block * 2) / 3
		greens(g)
		add(flank, "gold")
		add(aisleW, "aisle")
		add(flank, "gold")
		greens(g)
		add(flank, "gold")
		add(aisleW, "aisle")
		add(flank, "gold")
		greens(middle - block * 2 - g * 2)
	end
	add(cap, "gold")

	local sum = 0
	for _, w in widths do
		sum += w
	end
	local scale = length / math.max(sum, 0.01)
	local x = -length / 2
	local out: { Span } = {}
	for i, w in widths do
		local width = w * scale
		table.insert(out, { a = x, b = x + width, kind = kinds[i] })
		x += width
	end
	return out
end

function BleacherBank.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("BleacherBank", cf)
	local C = Kit.Color
	local length = optNum(opts, "length", DEFAULT_LENGTH, 10, 72)
	local rows = math.floor(optNum(opts, "rows", DEFAULT_ROWS, 4, 18) + 0.5)
	local extended = opts ~= nil and opts.extended == true
	local spans = spansFor(length)
	local stackH = SKIRT + rows * RISE

	local function rail(tag: string, x: number, z: number, y0: number, y1: number)
		local h = math.max(y1 - y0, 0.4)
		local yc = (y0 + y1) / 2
		for j, dx in { -0.15, 0.15 } do
			b:cyl(`{tag}P{j}`, h, 0.07, Kit.vertical(x + dx, yc, z), C.SteelBlack, Enum.Material.Metal)
		end
		b:cyl(`{tag}Top`, 0.4, 0.065, Kit.at(x, y1, z), C.SteelBlack, Enum.Material.Metal)
		b:cyl(`{tag}Hook`, 0.32, 0.055, Kit.alongZ(x, y1 - 0.02, z - 0.14), C.SteelBlack, Enum.Material.Metal)
	end

	local function endFrame(side: number, depth: number, height: number)
		local x = side * (length / 2 - 0.16)
		local zF = -depth / 2 + 0.55
		local zB = depth / 2 - 0.4
		b:cyl(`EndF{side}`, height, 0.14, Kit.vertical(x, height / 2, zF), C.SteelGrey, Enum.Material.Metal)
		b:cyl(`EndR{side}`, height * 0.92, 0.14, Kit.vertical(x, height * 0.46, zB), C.SteelBlack, Enum.Material.Metal)
		local a = Vector3.new(x, 0.35, zF)
		local c = Vector3.new(x, height * 0.78, zB)
		b:cyl(`EndD{side}`, (c - a).Magnitude, 0.09, along((a + c) / 2, c - a), C.SteelGrey, Enum.Material.Metal)
		b:box(
			`EndShoe{side}`,
			Vector3.new(0.46, 0.08, depth * 0.72),
			Kit.at(x, 0.04, (zF + zB) / 2),
			C.SteelBlack,
			Enum.Material.Metal,
			true
		)
		for k, t in { 0.25, 0.5, 0.75 } do
			b:cyl(
				`EndBolt{side}_{k}`,
				0.06,
				0.1,
				Kit.at(x + side * 0.02, height * t, zF + 0.12),
				C.Chrome,
				Enum.Material.Metal
			)
		end
	end

	if not extended then
		local faceZ = -CLOSED_D / 2 + 0.22
		b:box(
			"Carriage",
			Vector3.new(length - 0.3, stackH, CLOSED_D - 0.85),
			Kit.at(0, stackH / 2, 0.22),
			C.SteelBlack,
			Enum.Material.Metal,
			true
		)
		b:box(
			"Skirt",
			Vector3.new(length, SKIRT, 0.62),
			Kit.at(0, SKIRT / 2, -CLOSED_D / 2 + 0.28),
			C.Maple,
			Enum.Material.Wood,
			true
		)
		b:box(
			"TopNose",
			Vector3.new(length, 0.08, 0.5),
			Kit.at(0, stackH - 0.04, faceZ),
			C.SteelBlack,
			Enum.Material.Metal
		)

		for r = 0, rows - 1 do
			local y = SKIRT + RISE * (r + 0.5)
			-- 0.04 ft shadow gap so each board rests on the skirt or the board below.
			local fh = RISE - 0.04
			for s, span in spans do
				local w = span.b - span.a
				local xc = (span.a + span.b) / 2
				if span.kind == "aisle" then
					b:box(
						`Step{r}_{s}`,
						Vector3.new(w - 0.08, fh * 0.92, 0.28),
						Kit.at(xc, y, faceZ + 0.32),
						if r % 2 == 0 then TREAD_GREY else TREAD_DARK,
						Enum.Material.Metal,
						true
					)
				else
					local color = if span.kind == "gold" then C.BleacherGold else C.BleacherGreen
					b:box(
						`Nose{r}_{s}`,
						Vector3.new(w - 0.06, fh, 0.42),
						Kit.at(xc, y, faceZ),
						color,
						Enum.Material.SmoothPlastic,
						true
					)
					if span.kind == "green" and w > 3 then
						local n = if w > 9 then 2 else 1
						for k = 1, n do
							local lx = span.a + w * (k / (n + 1))
							b:box(
								`Latch{r}_{s}_{k}`,
								Vector3.new(0.22, 0.07, 0.05),
								Kit.at(lx, y, faceZ - 0.23),
								LATCH,
								Enum.Material.SmoothPlastic
							)
						end
					end
				end
			end
		end

		local railZ = faceZ + 0.15
		local y0 = SKIRT + RISE * 2.2
		local y1 = stackH + RAIL_UP
		for s, span in spans do
			if span.kind == "aisle" then
				rail(`Rail{s}L`, span.a + 0.18, railZ, y0, y1)
				rail(`Rail{s}R`, span.b - 0.18, railZ, y0, y1)
				b:cyl(
					`Chain{s}`,
					stackH * 0.55,
					0.035,
					Kit.vertical((span.a + span.b) / 2, stackH * 0.42, railZ + 0.2),
					C.SteelBlack,
					Enum.Material.Metal
				)
			end
		end
		endFrame(-1, CLOSED_D, stackH)
		endFrame(1, CLOSED_D, stackH)
		return b:done()
	end

	local depth = rows * TREAD
	for r = 0, rows - 1 do
		local z0 = -depth / 2 + r * TREAD
		local zc = z0 + TREAD / 2
		local deckTop = (r + 1) * RISE
		b:box(
			`Deck{r}`,
			Vector3.new(length - 0.2, 0.1, TREAD - 0.06),
			Kit.at(0, deckTop - 0.08, zc),
			C.SteelGrey,
			Enum.Material.Metal,
			true
		)
		for s, span in spans do
			local w = span.b - span.a - 0.06
			local xc = (span.a + span.b) / 2
			if span.kind == "aisle" then
				b:box(
					`Aisle{r}_{s}`,
					Vector3.new(math.max(w, 0.3), 0.08, TREAD * 0.72),
					Kit.at(xc, deckTop + 0.02, zc + 0.12),
					TREAD_GREY,
					Enum.Material.DiamondPlate,
					true
				)
				b:box(
					`AisleNose{r}_{s}`,
					Vector3.new(math.max(w, 0.3), RISE * 0.8, 0.08),
					Kit.at(xc, deckTop - RISE * 0.45, z0 + 0.06),
					TREAD_DARK,
					Enum.Material.Metal
				)
			else
				local color = if span.kind == "gold" then C.BleacherGold else C.BleacherGreen
				b:box(
					`Riser{r}_{s}`,
					Vector3.new(w, RISE * 0.82, 0.1),
					Kit.at(xc, deckTop - RISE * 0.48, z0 + 0.06),
					color,
					Enum.Material.SmoothPlastic
				)
				b:box(
					`Seat{r}_{s}`,
					Vector3.new(w, 0.14, 0.92),
					Kit.at(xc, deckTop + 0.06, z0 + 0.52),
					color,
					Enum.Material.SmoothPlastic,
					true
				)
			end
		end
	end

	local front = -depth / 2
	local back = depth / 2
	for s, span in spans do
		if span.kind == "aisle" then
			local edgeN = 0
			for _, edge in { span.a + 0.16, span.b - 0.16 } do
				edgeN += 1
				local tag = `XRail{s}_{edgeN}`
				local yA = 2.55
				local yB = rows * RISE + 2.15
				local p0 = Vector3.new(edge, yA, front + 0.3)
				local p1 = Vector3.new(edge, yB, back - 0.2)
				b:cyl(tag, (p1 - p0).Magnitude, 0.08, along((p0 + p1) / 2, p1 - p0), C.SteelBlack, Enum.Material.Metal)
				for r = 0, rows - 1, 3 do
					local t = (r + 0.5) / rows
					local px = edge
					local py = yA + (yB - yA) * t
					local pz = (front + 0.3) + (back - 0.2 - (front + 0.3)) * t
					local postH = 2.1
					b:cyl(
						`{tag}S{r}`,
						postH,
						0.06,
						Kit.vertical(px, py - postH / 2, pz),
						C.SteelBlack,
						Enum.Material.Metal
					)
				end
			end
		end
	end

	endFrame(-1, depth, rows * RISE)
	endFrame(1, depth, rows * RISE)
	b:box("FrontSkirt", Vector3.new(length, 0.16, 0.2), Kit.at(0, 0.08, -depth / 2 + 0.08), C.Maple, Enum.Material.Wood)
	return b:done()
end

return BleacherBank
