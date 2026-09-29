--!strict
-- 50 in wall display, mounted at the column height in IMG_0318 (center about 7.6 ft).
-- The pivot is on the finished floor because blueprint props have no elevation.
-- Black bezel, glossy screen, tilt-free wall plate. Screen faces -Z.
local Kit = require(script.Parent.Kit)

local WallTv = {
	kind = "wall_tv",
	size = Vector3.new(4.05, 8.95, 0.55),
}

local function optNum(opts: { [string]: any }?, key: string, default: number, lo: number, hi: number): number
	local v = if opts ~= nil then opts[key] else nil
	if type(v) == "number" then
		return math.clamp(v :: number, lo, hi)
	end
	return default
end

function WallTv.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("WallTv", cf)
	local C = Kit.Color
	-- bottom is the bezel's lower edge. Clamped so the panel stays inside size.Y.
	local lift = optNum(opts, "bottom", 6.55, 5.8, 6.6)
	local w, h = 3.72, 2.16
	local cy = lift + h / 2

	b:box("WallPlate", Vector3.new(0.7, 0.45, 0.06), Kit.at(0, cy, 0.2), C.SteelGrey, Enum.Material.Metal, true)
	b:box("Arm", Vector3.new(0.16, 0.12, 0.22), Kit.at(0, cy, 0.08), C.SteelBlack, Enum.Material.Metal)
	b:box("Vesa", Vector3.new(0.45, 0.3, 0.05), Kit.at(0, cy, -0.02), C.SteelBlack, Enum.Material.Metal)
	for s = -1, 1, 2 do
		for t = -1, 1, 2 do
			b:cyl(`Screw{s}{t}`, 0.04, 0.04, Kit.alongZ(s * 0.16, cy + t * 0.1, 0.18), C.SteelGrey, Enum.Material.Metal)
		end
	end

	b:box("Bezel", Vector3.new(w, h, 0.08), Kit.at(0, cy, -0.08), C.SteelBlack, Enum.Material.SmoothPlastic, true)
	b:box(
		"TrimL",
		Vector3.new(0.06, h, 0.09),
		Kit.at(-w / 2, cy, -0.08),
		Color3.fromRGB(12, 12, 14),
		Enum.Material.SmoothPlastic
	)
	b:box(
		"TrimR",
		Vector3.new(0.06, h, 0.09),
		Kit.at(w / 2, cy, -0.08),
		Color3.fromRGB(12, 12, 14),
		Enum.Material.SmoothPlastic
	)
	b:box(
		"TrimT",
		Vector3.new(w, 0.06, 0.09),
		Kit.at(0, lift + h, -0.08),
		Color3.fromRGB(12, 12, 14),
		Enum.Material.SmoothPlastic
	)
	b:box(
		"Ir",
		Vector3.new(0.08, 0.04, 0.015),
		Kit.at(-w * 0.32, lift + 0.08, -0.135),
		Color3.fromRGB(8, 8, 10),
		Enum.Material.SmoothPlastic
	)
	b:box(
		"Chin",
		Vector3.new(w, 0.16, 0.09),
		Kit.at(0, lift + 0.08, -0.08),
		Color3.fromRGB(16, 16, 18),
		Enum.Material.SmoothPlastic
	)
	local screen = b:box(
		"Screen",
		Vector3.new(w - 0.16, h - 0.28, 0.02),
		Kit.at(0, cy + 0.05, -0.13),
		C.Screen,
		Enum.Material.SmoothPlastic
	)
	screen.Reflectance = 0.4
	b:light(screen, Enum.NormalId.Front, 0.7, 10, Color3.fromRGB(200, 214, 230))
	local glint = b:box(
		"Glint",
		Vector3.new(w - 0.5, 0.045, 0.012),
		Kit.at(0, cy + 0.45, -0.145),
		C.OffWhite,
		Enum.Material.SmoothPlastic
	)
	glint.Transparency = 0.5
	b:box(
		"Led",
		Vector3.new(0.06, 0.035, 0.015),
		Kit.at(w * 0.38, lift + 0.08, -0.13),
		Color3.fromRGB(40, 200, 90),
		Enum.Material.Neon
	)
	for i = -1, 1 do
		b:box(
			`Speaker{i}`,
			Vector3.new(0.28, 0.03, 0.015),
			Kit.at(i * 0.4, lift + 0.07, -0.13),
			C.SteelGrey,
			Enum.Material.SmoothPlastic
		)
	end

	-- Short conduit down the wall so the panel reads as mounted, not floating.
	b:box("Race", Vector3.new(0.08, 1.4, 0.05), Kit.at(0.55, lift - 0.7, 0.16), C.SteelGrey, Enum.Material.Metal)
	b:box("Race2", Vector3.new(0.08, 1.3, 0.05), Kit.at(0.55, lift - 2.05, 0.16), C.SteelGrey, Enum.Material.Metal)
	b:box(
		"Whip",
		Vector3.new(0.04, 0.04, 0.2),
		Kit.at(0.4, lift + 0.05, 0.02),
		C.SteelBlack,
		Enum.Material.SmoothPlastic
	)

	return b:done()
end

return WallTv
