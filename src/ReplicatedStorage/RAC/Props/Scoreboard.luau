--!strict
-- Wall scoreboard in the competition-gym style (IMG_0334, IMG_0336): dark green cabinet,
-- gold trim, neon gold LED digits. Static readout is a generic in-progress set, not a real match.
-- Face (digit side) is -Z. Pivot is the bottom of the cabinet.
local Kit = require(script.Parent.Kit)

local WIDTH = 12.2
local HEIGHT = 4.65
local DEPTH = 0.72

local Scoreboard = {
	kind = "scoreboard",
	size = Vector3.new(WIDTH + 0.15, HEIGHT, DEPTH + 0.2),
}

local CABINET = Color3.fromRGB(8, 34, 22)
local OFF = Color3.fromRGB(16, 40, 28)
local GOLD = Color3.fromRGB(255, 196, 40)

-- 1 top, 2 upper-left, 3 upper-right, 4 mid, 5 lower-left, 6 lower-right, 7 bottom
local ON: { [number]: { boolean } } = {
	[0] = { true, true, true, false, true, true, true },
	[1] = { false, false, true, false, false, true, false },
	[2] = { true, false, true, true, true, false, true },
	[3] = { true, false, true, true, false, true, true },
	[4] = { false, true, true, true, false, true, false },
	[5] = { true, true, false, true, false, true, true },
	[6] = { true, true, false, true, true, true, true },
	[7] = { true, false, true, false, false, true, false },
	[8] = { true, true, true, true, true, true, true },
	[9] = { true, true, true, true, false, true, true },
}

-- Unit-square strokes, origin bottom-left of the letter.
local GLYPH: { [string]: { { number } } } = {
	H = { { 0, 0, 0.18, 1 }, { 0.82, 0, 0.18, 1 }, { 0.1, 0.41, 0.8, 0.16 } },
	O = { { 0, 0.12, 0.18, 0.76 }, { 0.82, 0.12, 0.18, 0.76 }, { 0.1, 0.84, 0.8, 0.16 }, { 0.1, 0, 0.8, 0.16 } },
	M = { { 0, 0, 0.16, 1 }, { 0.84, 0, 0.16, 1 }, { 0.32, 0.42, 0.16, 0.58 }, { 0.52, 0.42, 0.16, 0.58 } },
	E = { { 0, 0, 0.18, 1 }, { 0.15, 0.84, 0.85, 0.16 }, { 0.15, 0.42, 0.7, 0.16 }, { 0.15, 0, 0.85, 0.16 } },
	G = {
		{ 0, 0.1, 0.18, 0.78 },
		{ 0.82, 0.1, 0.18, 0.42 },
		{ 0.12, 0.84, 0.88, 0.16 },
		{ 0.12, 0, 0.88, 0.16 },
		{ 0.48, 0.4, 0.52, 0.14 },
	},
	U = { { 0, 0.16, 0.18, 0.84 }, { 0.82, 0.16, 0.18, 0.84 }, { 0.12, 0, 0.76, 0.16 } },
	S = {
		{ 0.08, 0.84, 0.84, 0.16 },
		{ 0.08, 0.42, 0.84, 0.16 },
		{ 0.08, 0, 0.84, 0.16 },
		{ 0, 0.5, 0.18, 0.4 },
		{ 0.82, 0.12, 0.18, 0.36 },
	},
	T = { { 0.41, 0, 0.18, 0.86 }, { 0, 0.84, 1, 0.16 } },
	P = { { 0, 0, 0.18, 1 }, { 0.12, 0.84, 0.78, 0.16 }, { 0.12, 0.46, 0.74, 0.15 }, { 0.82, 0.56, 0.18, 0.34 } },
	R = {
		{ 0, 0, 0.18, 1 },
		{ 0.12, 0.84, 0.76, 0.16 },
		{ 0.12, 0.46, 0.7, 0.15 },
		{ 0.8, 0.58, 0.18, 0.32 },
		{ 0.55, 0, 0.2, 0.48 },
	},
	I = { { 0.38, 0, 0.24, 1 } },
	D = { { 0, 0, 0.18, 1 }, { 0.62, 0.12, 0.24, 0.76 }, { 0.1, 0.84, 0.7, 0.16 }, { 0.1, 0, 0.7, 0.16 } },
}

function Scoreboard.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("Scoreboard", cf)
	local C = Kit.Color
	local faceZ = -DEPTH / 2 - 0.02

	local shell = b:box(
		"Cabinet",
		Vector3.new(WIDTH, HEIGHT, DEPTH),
		Kit.at(0, HEIGHT / 2, 0),
		CABINET,
		Enum.Material.SmoothPlastic,
		true
	)
	b:light(shell, Enum.NormalId.Front, 0.35, 14, GOLD)

	local t = 0.1
	b:box(
		"TrimTop",
		Vector3.new(WIDTH + 0.08, t, 0.12),
		Kit.at(0, HEIGHT - t / 2, faceZ),
		C.BleacherGold,
		Enum.Material.Metal
	)
	b:box("TrimBot", Vector3.new(WIDTH + 0.08, t, 0.12), Kit.at(0, t / 2, faceZ), C.BleacherGold, Enum.Material.Metal)
	b:box(
		"TrimL",
		Vector3.new(t, HEIGHT, 0.12),
		Kit.at(-WIDTH / 2, HEIGHT / 2, faceZ),
		C.BleacherGold,
		Enum.Material.Metal
	)
	b:box(
		"TrimR",
		Vector3.new(t, HEIGHT, 0.12),
		Kit.at(WIDTH / 2, HEIGHT / 2, faceZ),
		C.BleacherGold,
		Enum.Material.Metal
	)
	b:box(
		"DivL",
		Vector3.new(0.06, HEIGHT - 0.45, 0.08),
		Kit.at(-2.15, HEIGHT / 2 - 0.05, faceZ),
		C.BleacherGold,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"DivR",
		Vector3.new(0.06, HEIGHT - 0.45, 0.08),
		Kit.at(2.15, HEIGHT / 2 - 0.05, faceZ),
		C.BleacherGold,
		Enum.Material.SmoothPlastic
	)

	for side = -1, 1, 2 do
		b:cyl(
			`Standoff{side}`,
			0.28,
			0.16,
			Kit.alongZ(side * 3.4, HEIGHT * 0.62, DEPTH / 2 + 0.1),
			C.SteelGrey,
			Enum.Material.Metal
		)
		b:box(
			`Mount{side}`,
			Vector3.new(0.7, 0.45, 0.08),
			Kit.at(side * 3.4, HEIGHT * 0.62, DEPTH / 2 + 0.22),
			C.SteelGrey,
			Enum.Material.Metal
		)
	end

	local function digit(prefix: string, cx: number, cy: number, value: number, w: number, h: number)
		local thick = math.max(0.05, h * 0.1)
		local hw = w * 0.7
		local vh = h * 0.34
		local mask = ON[value] or ON[0]
		local function seg(idx: number, size: Vector3, ox: number, oy: number)
			local on = mask[idx] == true
			b:box(
				`{prefix}{idx}`,
				size,
				Kit.at(cx + ox, cy + oy, faceZ - 0.04),
				if on then GOLD else OFF,
				if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
			)
		end
		seg(1, Vector3.new(hw, thick, thick), 0, h * 0.4)
		seg(2, Vector3.new(thick, vh, thick), -w * 0.32, h * 0.19)
		seg(3, Vector3.new(thick, vh, thick), w * 0.32, h * 0.19)
		seg(4, Vector3.new(hw, thick, thick), 0, 0)
		seg(5, Vector3.new(thick, vh, thick), -w * 0.32, -h * 0.19)
		seg(6, Vector3.new(thick, vh, thick), w * 0.32, -h * 0.19)
		seg(7, Vector3.new(hw, thick, thick), 0, -h * 0.4)
	end

	local function number2(prefix: string, cx: number, cy: number, n: number, w: number, h: number)
		local gap = w * 1.35
		digit(`{prefix}T`, cx - gap / 2, cy, math.floor(n / 10) % 10, w, h)
		digit(`{prefix}O`, cx + gap / 2, cy, n % 10, w, h)
	end

	local function word(text: string, cx: number, cy: number, letterW: number, letterH: number)
		local gap = letterW * 0.22
		local total = #text * letterW + math.max(#text - 1, 0) * gap
		local x = cx - total / 2
		for i = 1, #text do
			local ch = string.sub(text, i, i)
			local glyph = GLYPH[ch]
			if glyph ~= nil then
				for s, rect in glyph do
					local rx, ry, rw, rh = rect[1], rect[2], rect[3], rect[4]
					b:box(
						`W{text}{i}_{s}`,
						Vector3.new(math.max(rw * letterW, 0.03), math.max(rh * letterH, 0.03), 0.035),
						Kit.at(x + (rx + rw / 2) * letterW, cy + (ry + rh / 2 - 0.5) * letterH, faceZ - 0.045),
						GOLD,
						Enum.Material.Neon
					)
				end
			end
			x += letterW + gap
		end
	end

	number2("Home", -4.15, 2.05, 21, 0.62, 1.45)
	digit("Set", 0, 2.15, 3, 0.5, 1.15)
	number2("Guest", 4.15, 2.05, 18, 0.62, 1.45)
	word("HOME", -4.15, 3.55, 0.28, 0.42)
	word("PERIOD", 0, 3.62, 0.2, 0.32)
	word("GUEST", 4.15, 3.55, 0.26, 0.42)

	b:box(
		"Hairline",
		Vector3.new(WIDTH - 0.6, 0.025, 0.02),
		Kit.at(0, 3.15, faceZ - 0.03),
		C.BleacherGold,
		Enum.Material.Neon
	)
	for _, x in { -4.9, -3.4, 3.4, 4.9 } do
		digit(`F{x}`, x, 0.72, 0, 0.22, 0.42)
	end
	word("FOULS", -4.15, 1.15, 0.1, 0.16)
	word("FOULS", 4.15, 1.15, 0.1, 0.16)

	return b:done()
end

return Scoreboard
