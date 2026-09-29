--!strict
-- Restroom lavatory: solid-surface counter, undermount basins, chrome faucets,
-- exposed traps, backsplash, and a frameless mirror. opts.sinks (default 2).
-- You stand on the -Z side. Counter height is 34 in.
local Kit = require(script.Parent.Kit)

local SINK_PITCH = 2.7
local DEPTH = 2.05
local TOP_Y = 2.83
local DEFAULT_N = 2

local SinkCounter = {
	kind = "sink_counter",
	size = Vector3.new(DEFAULT_N * SINK_PITCH + 0.7, 5.85, DEPTH + 0.15),
}

local TOP = Color3.fromRGB(232, 228, 220)
local BOWL = Color3.fromRGB(248, 248, 246)
local BASIN = Color3.fromRGB(198, 206, 208)

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

function SinkCounter.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("SinkCounter", cf)
	local C = Kit.Color
	local n = math.floor(optNum(opts, "sinks", DEFAULT_N, 1, 5) + 0.5)
	local length = n * SINK_PITCH + 0.7
	local backZ = DEPTH / 2

	b:box("Deck", Vector3.new(length, 0.16, DEPTH), Kit.at(0, TOP_Y - 0.08, 0), TOP, Enum.Material.SmoothPlastic, true)
	b:box(
		"Apron",
		Vector3.new(length, 0.42, 0.1),
		Kit.at(0, TOP_Y - 0.38, -DEPTH / 2 + 0.06),
		TOP,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"Splash",
		Vector3.new(length, 0.55, 0.08),
		Kit.at(0, TOP_Y + 0.22, backZ - 0.06),
		TOP,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"SplashCap",
		Vector3.new(length, 0.06, 0.1),
		Kit.at(0, TOP_Y + 0.5, backZ - 0.05),
		C.Beige,
		Enum.Material.SmoothPlastic
	)

	local mirror = b:box(
		"Mirror",
		Vector3.new(length - 0.4, 2.15, 0.06),
		Kit.at(0, 4.45, backZ - 0.02),
		C.Glass,
		Enum.Material.Glass
	)
	mirror.Transparency = 0.35
	mirror.Reflectance = 0.25
	b:box("MirrorFrameT", Vector3.new(length - 0.28, 0.06, 0.08), Kit.at(0, 5.55, backZ), C.Chrome, Enum.Material.Metal)
	b:box("MirrorFrameB", Vector3.new(length - 0.28, 0.06, 0.08), Kit.at(0, 3.35, backZ), C.Chrome, Enum.Material.Metal)
	b:box(
		"MirrorFrameL",
		Vector3.new(0.06, 2.25, 0.08),
		Kit.at(-length / 2 + 0.22, 4.45, backZ),
		C.Chrome,
		Enum.Material.Metal
	)
	b:box(
		"MirrorFrameR",
		Vector3.new(0.06, 2.25, 0.08),
		Kit.at(length / 2 - 0.22, 4.45, backZ),
		C.Chrome,
		Enum.Material.Metal
	)

	local brackets = n + 1
	for i = 0, brackets - 1 do
		local x = -length / 2 + length * ((i + 0.5) / brackets)
		b:box(
			`Arm{i}`,
			Vector3.new(0.12, 0.1, DEPTH - 0.35),
			Kit.at(x, TOP_Y - 0.28, 0.05),
			C.SteelGrey,
			Enum.Material.Metal
		)
		local legH = TOP_Y - 0.32
		b:box(
			`Leg{i}`,
			Vector3.new(0.1, legH, 0.1),
			Kit.at(x, legH / 2, backZ - 0.2),
			C.SteelGrey,
			Enum.Material.Metal,
			true
		)
		b:box(
			`Foot{i}`,
			Vector3.new(0.28, 0.06, 0.36),
			Kit.at(x, 0.03, backZ - 0.2),
			C.SteelBlack,
			Enum.Material.Metal,
			true
		)
		local p0 = Vector3.new(x, 0.35, backZ - 0.2)
		local p1 = Vector3.new(x, TOP_Y - 0.55, -DEPTH / 2 + 0.1)
		b:cyl(`Brace{i}`, (p1 - p0).Magnitude, 0.07, along((p0 + p1) / 2, p1 - p0), C.SteelGrey, Enum.Material.Metal)
	end

	for i = 0, n - 1 do
		local x = -length / 2 + 0.35 + SINK_PITCH * (i + 0.5)
		b:box(
			`Rim{i}`,
			Vector3.new(1.35, 0.08, 0.95),
			Kit.at(x, TOP_Y - 0.14, -0.12),
			BOWL,
			Enum.Material.SmoothPlastic
		)
		b:box(
			`Basin{i}`,
			Vector3.new(1.05, 0.32, 0.7),
			Kit.at(x, TOP_Y - 0.36, -0.1),
			BASIN,
			Enum.Material.SmoothPlastic
		)
		b:cyl(`Drain{i}`, 0.05, 0.12, Kit.vertical(x, TOP_Y - 0.52, -0.08), C.Chrome, Enum.Material.Metal)
		b:cyl(`Faucet{i}`, 0.16, 0.1, Kit.vertical(x, TOP_Y + 0.06, 0.42), C.Chrome, Enum.Material.Metal)
		b:cyl(`Spout{i}`, 0.55, 0.05, Kit.alongZ(x, TOP_Y + 0.22, 0.18), C.Chrome, Enum.Material.Metal)
		b:cyl(`SpoutDrop{i}`, 0.28, 0.045, Kit.vertical(x, TOP_Y + 0.08, -0.08), C.Chrome, Enum.Material.Metal)
		for side = -1, 1, 2 do
			b:cyl(
				`Handle{i}_{side}`,
				0.1,
				0.07,
				Kit.vertical(x + side * 0.28, TOP_Y + 0.05, 0.38),
				C.Chrome,
				Enum.Material.Metal
			)
		end
		b:cyl(`Tail{i}`, 0.55, 0.045, Kit.vertical(x, TOP_Y - 0.85, -0.08), C.Chrome, Enum.Material.Metal)
		b:cyl(`TrapArm{i}`, 0.7, 0.05, Kit.alongZ(x, TOP_Y - 1.15, 0.22), C.Chrome, Enum.Material.Metal)
		b:cyl(`Trap{i}`, 0.22, 0.1, Kit.at(x, TOP_Y - 1.15, -0.08), C.Chrome, Enum.Material.Metal)
	end

	b:box("Soap", Vector3.new(0.16, 0.28, 0.12), Kit.at(0, TOP_Y + 0.13, 0.35), C.Chrome, Enum.Material.Metal)
	b:cyl("SoapPump", 0.1, 0.06, Kit.vertical(0, TOP_Y + 0.31, 0.35), C.Chrome, Enum.Material.Metal)
	return b:done()
end

return SinkCounter
