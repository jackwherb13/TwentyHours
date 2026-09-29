--!strict
-- Dark green vinyl wall pads, 6 ft tall, about 2 inches thick (IMG_0335).
-- opts.length is the run in feet (default 12). Panels are ~2 ft wide. Face is -Z.
local Kit = require(script.Parent.Kit)

local DEFAULT_LENGTH = 12
local HEIGHT = 6

local WallPad = {
	kind = "wall_pad",
	size = Vector3.new(DEFAULT_LENGTH, HEIGHT, 0.36),
}

local BIND = Color3.fromRGB(12, 28, 20)
local CLIP = Color3.fromRGB(90, 92, 96)

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

function WallPad.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("WallPad", cf)
	local C = Kit.Color
	local length = optNum(opts, "length", DEFAULT_LENGTH, 2, 40)
	local n = math.max(1, math.floor(length / 2 + 0.5))
	local pw = length / n
	local faceZ = -0.02

	b:box(
		"Backer",
		Vector3.new(length, HEIGHT - 0.04, 0.08),
		Kit.at(0, HEIGHT / 2, 0.1),
		BIND,
		Enum.Material.SmoothPlastic
	)

	for i = 0, n - 1 do
		local x = -length / 2 + pw * (i + 0.5)
		b:box(
			`Panel{i}`,
			Vector3.new(pw - 0.06, HEIGHT - 0.34, 0.2),
			Kit.at(x, 0.22 + (HEIGHT - 0.34) / 2, faceZ),
			C.BleacherGreen,
			Enum.Material.SmoothPlastic,
			true
		)
		b:box(
			`Kick{i}`,
			Vector3.new(pw - 0.06, 0.22, 0.22),
			Kit.at(x, 0.11, faceZ - 0.01),
			C.RubberBlack,
			Enum.Material.Rubber,
			true
		)
		b:box(
			`Bind{i}`,
			Vector3.new(pw - 0.05, 0.07, 0.22),
			Kit.at(x, HEIGHT - 0.05, faceZ),
			BIND,
			Enum.Material.SmoothPlastic
		)
		b:box(
			`Seam{i}`,
			Vector3.new(0.035, HEIGHT - 0.16, 0.03),
			Kit.at(x - pw / 2, HEIGHT / 2, faceZ - 0.1),
			BIND,
			Enum.Material.SmoothPlastic
		)
		b:box(`Clip{i}`, Vector3.new(0.16, 0.08, 0.06), Kit.at(x, HEIGHT - 0.16, 0.16), CLIP, Enum.Material.Metal)
		b:cyl(`Bolt{i}a`, 0.04, 0.06, Kit.at(x - pw * 0.28, 0.55, faceZ - 0.12), C.SteelGrey, Enum.Material.Metal)
		b:cyl(
			`Bolt{i}b`,
			0.04,
			0.06,
			Kit.at(x + pw * 0.28, HEIGHT - 0.45, faceZ - 0.12),
			C.SteelGrey,
			Enum.Material.Metal
		)
	end

	b:box(
		"EndL",
		Vector3.new(0.06, HEIGHT, 0.24),
		Kit.at(-length / 2 + 0.03, HEIGHT / 2, 0.02),
		BIND,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"EndR",
		Vector3.new(0.06, HEIGHT, 0.24),
		Kit.at(length / 2 - 0.03, HEIGHT / 2, 0.02),
		BIND,
		Enum.Material.SmoothPlastic
	)
	return b:done()
end

return WallPad
