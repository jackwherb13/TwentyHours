--!strict
-- Gym mirror bay (IMG_0318 dumbbell wall). Bottom sits just off the floor, top near 7 ft.
-- Segmented glass, grey mullions, standoff clips. Pivot bottom-center, glass faces -Z.
-- opts.width (4–10 ft) and opts.rows (2–3) rescale the bay; the declared size is the default.
local Kit = require(script.Parent.Kit)

local WallMirror = {
	kind = "wall_mirror",
	size = Vector3.new(6.15, 7.15, 0.35),
}

local function optNum(opts: { [string]: any }?, key: string, default: number, lo: number, hi: number): number
	local v = if opts ~= nil then opts[key] else nil
	if type(v) == "number" then
		return math.clamp(v :: number, lo, hi)
	end
	return default
end

function WallMirror.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("WallMirror", cf)
	local C = Kit.Color
	local width = optNum(opts, "width", 6, 4, 8)
	local rows = math.floor(optNum(opts, "rows", 3, 2, 3) + 0.5)
	local cols = math.floor(optNum(opts, "cols", 3, 2, 4) + 0.5)
	-- Keep the default inside the declared box; wider opts are for a placer that knows.
	if opts == nil then
		width = 6
		rows = 3
		cols = 3
	end
	local glassH = 6.5
	local y0 = 0.28
	local paneW = (width - 0.08 * (cols + 1)) / cols
	local paneH = (glassH - 0.06 * (rows + 1)) / rows
	local frame = C.FrameGrey

	b:box(
		"Back",
		Vector3.new(width, glassH, 0.06),
		Kit.at(0, y0 + glassH / 2, 0.08),
		Color3.fromRGB(70, 74, 78),
		Enum.Material.Metal,
		true
	)
	b:box("FrameL", Vector3.new(0.06, 2.1, 0.08), Kit.at(-width / 2, y0 + 1.05, 0.02), frame, Enum.Material.Metal)
	b:box("FrameL2", Vector3.new(0.06, 2.1, 0.08), Kit.at(-width / 2, y0 + 3.15, 0.02), frame, Enum.Material.Metal)
	b:box("FrameL3", Vector3.new(0.06, 2.2, 0.08), Kit.at(-width / 2, y0 + 5.3, 0.02), frame, Enum.Material.Metal)
	b:box("FrameR", Vector3.new(0.06, 2.1, 0.08), Kit.at(width / 2, y0 + 1.05, 0.02), frame, Enum.Material.Metal)
	b:box("FrameR2", Vector3.new(0.06, 2.1, 0.08), Kit.at(width / 2, y0 + 3.15, 0.02), frame, Enum.Material.Metal)
	b:box("FrameR3", Vector3.new(0.06, 2.2, 0.08), Kit.at(width / 2, y0 + 5.3, 0.02), frame, Enum.Material.Metal)
	b:box("FrameB", Vector3.new(width, 0.08, 0.08), Kit.at(0, y0, 0.02), frame, Enum.Material.Metal)
	b:box("FrameT", Vector3.new(width, 0.08, 0.08), Kit.at(0, y0 + glassH, 0.02), frame, Enum.Material.Metal)

	for col = 0, cols - 1 do
		local x = -width / 2 + 0.08 + paneW / 2 + col * (paneW + 0.08)
		if col > 0 then
			b:box(
				`Mullion{col}a`,
				Vector3.new(0.05, 2.1, 0.05),
				Kit.at(x - paneW / 2 - 0.04, y0 + 1.1, 0),
				frame,
				Enum.Material.Metal
			)
			b:box(
				`Mullion{col}b`,
				Vector3.new(0.05, 2.1, 0.05),
				Kit.at(x - paneW / 2 - 0.04, y0 + 3.2, 0),
				frame,
				Enum.Material.Metal
			)
			b:box(
				`Mullion{col}c`,
				Vector3.new(0.05, 2.1, 0.05),
				Kit.at(x - paneW / 2 - 0.04, y0 + 5.2, 0),
				frame,
				Enum.Material.Metal
			)
		end
		for row = 0, rows - 1 do
			local y = y0 + 0.06 + paneH / 2 + row * (paneH + 0.06)
			local glass = b:box(
				`Glass{col}{row}`,
				Vector3.new(paneW, paneH, 0.03),
				Kit.at(x, y, -0.02),
				Color3.fromRGB(168, 184, 190),
				Enum.Material.Glass
			)
			glass.Transparency = 0.18
			glass.Reflectance = 0.42
			if row > 0 then
				b:box(
					`Rail{col}{row}`,
					Vector3.new(paneW, 0.04, 0.04),
					Kit.at(x, y - paneH / 2 - 0.03, 0),
					frame,
					Enum.Material.Metal
				)
			end
		end
	end

	-- Standoff clips, two columns.
	for _, x in { -width / 2 + 0.15, width / 2 - 0.15 } do
		for i, y in { 0.6, 3.4, 6.4 } do
			b:cyl(`Clip{x}{i}`, 0.08, 0.08, Kit.alongZ(x, y, 0.06), C.SteelGrey, Enum.Material.Metal)
		end
	end

	return b:done()
end

return WallMirror
