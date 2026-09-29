--!strict
-- Pair of padded volleyball standards, net, and sideline antennas (IMG_0334).
-- opts.net = false leaves the uprights only. opts.height is the top of the net in feet
-- (default 7.35, NCAA women's). Posts are 36 ft apart. Front of the net faces -Z.
local Kit = require(script.Parent.Kit)

local SPAN = 36
local POST_H = 8.85
local PAD_H = 6.15
local NET_TOP = 7.35
local NET_DROP = 3.28
local ANTENNA_X = 14.76

local VolleyballStandard = {
	kind = "volleyball_standard",
	size = Vector3.new(SPAN + 0.9, POST_H, 1.7),
}

local NET = Color3.fromRGB(236, 236, 232)
local ANT_RED = Color3.fromRGB(186, 28, 36)
local PAD = Color3.fromRGB(16, 22, 18)

local function along(pos: Vector3, dir: Vector3): CFrame
	local d = if dir.Magnitude < 1e-5 then Vector3.new(1, 0, 0) else dir.Unit
	local hint = if math.abs(d.Y) > 0.92 then Vector3.new(1, 0, 0) else Vector3.new(0, 1, 0)
	local yAxis = d:Cross(hint)
	if yAxis.Magnitude < 1e-5 then
		yAxis = d:Cross(Vector3.new(0, 0, 1))
	end
	return CFrame.fromMatrix(pos, d, yAxis.Unit)
end

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

function VolleyballStandard.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("VolleyballStandard", cf)
	local C = Kit.Color
	local withNet = not (opts ~= nil and opts.net == false)
	local netTop = optNum(opts, "height", NET_TOP, 6.6, 8.15)
	local postH = math.max(POST_H, netTop + 1.35)

	local function upright(side: number)
		local x = side * (SPAN / 2)
		local tag = if side < 0 then "W" else "E"
		b:box(`Base{tag}`, Vector3.new(1.15, 0.1, 1.55), Kit.at(x, 0.05, 0), C.SteelBlack, Enum.Material.Metal, true)
		b:box(`BasePad{tag}`, Vector3.new(1.25, 0.06, 0.35), Kit.at(x, 0.08, 0.72), C.RubberBlack, Enum.Material.Rubber)
		b:cyl(`Pole{tag}`, postH, 0.28, Kit.vertical(x, postH / 2, 0), C.SteelGrey, Enum.Material.Metal)
		b:box(
			`Pad{tag}`,
			Vector3.new(0.78, PAD_H, 0.78),
			Kit.at(x, 0.1 + PAD_H / 2, 0),
			PAD,
			Enum.Material.Leather,
			true
		)
		b:box(
			`PadBand{tag}`,
			Vector3.new(0.82, 0.14, 0.82),
			Kit.at(x, 3.15, 0),
			C.BleacherGold,
			Enum.Material.SmoothPlastic
		)
		b:box(
			`PadMark{tag}`,
			Vector3.new(0.02, 0.42, 0.32),
			Kit.at(x, 3.7, -0.4),
			C.BleacherGreen,
			Enum.Material.SmoothPlastic
		)
		b:cyl(`Collar{tag}`, 0.1, 0.4, Kit.vertical(x, 0.1 + PAD_H + 0.05, 0), C.SteelGrey, Enum.Material.Metal)
		b:box(
			`Ratchet{tag}`,
			Vector3.new(0.28, 0.34, 0.16),
			Kit.at(x + side * 0.22, netTop - 0.15, 0),
			C.SteelBlack,
			Enum.Material.Metal
		)
		b:cyl(`RatchetHub{tag}`, 0.1, 0.16, Kit.at(x + side * 0.38, netTop - 0.15, 0), C.Chrome, Enum.Material.Metal)
		b:box(`Cap{tag}`, Vector3.new(0.32, 0.1, 0.32), Kit.at(x, postH, 0), C.SteelBlack, Enum.Material.Metal)
		b:cyl(`Pulley{tag}`, 0.08, 0.18, Kit.at(x, netTop + 0.28, 0), C.SteelGrey, Enum.Material.Metal)
	end

	upright(-1)
	upright(1)

	if not withNet then
		return b:done()
	end

	local half = SPAN / 2 - 0.55
	b:box("TopTape", Vector3.new(half * 2, 0.16, 0.07), Kit.at(0, netTop - 0.08, 0), NET, Enum.Material.SmoothPlastic)
	b:box("BotTape", Vector3.new(half * 2, 0.1, 0.05), Kit.at(0, netTop - NET_DROP, 0), NET, Enum.Material.Fabric)
	b:cyl("TopCable", half * 2, 0.035, Kit.at(0, netTop + 0.02, 0), C.SteelBlack, Enum.Material.Metal)
	for side = -1, 1, 2 do
		b:box(
			`SideTape{side}`,
			Vector3.new(0.08, NET_DROP, 0.06),
			Kit.at(side * half, netTop - NET_DROP / 2, 0),
			NET,
			Enum.Material.SmoothPlastic
		)
		local p0 = Vector3.new(side * (SPAN / 2), netTop + 0.28, 0)
		local p1 = Vector3.new(side * half, netTop, 0)
		b:cyl(`Lead{side}`, (p1 - p0).Magnitude, 0.03, along((p0 + p1) / 2, p1 - p0), C.SteelGrey, Enum.Material.Metal)
	end

	local cords = 6
	for i = 1, cords do
		local y = netTop - 0.2 - (NET_DROP - 0.28) * (i / (cords + 1))
		local mesh =
			b:box(`MeshH{i}`, Vector3.new(half * 2 - 0.1, 0.02, 0.02), Kit.at(0, y, 0), NET, Enum.Material.Fabric)
		mesh.Transparency = 0.15
	end
	local verts = 15
	local meshBottom = netTop - NET_DROP - 0.06
	local meshTop = netTop - 0.12
	local meshH = meshTop - meshBottom
	for i = 1, verts do
		local x = -half + (half * 2) * (i / (verts + 1))
		local mesh = b:box(
			`MeshV{i}`,
			Vector3.new(0.018, meshH, 0.018),
			Kit.at(x, (meshTop + meshBottom) / 2, 0),
			NET,
			Enum.Material.Fabric
		)
		mesh.Transparency = 0.15
	end

	local bandH = 0.72
	local bands = 7
	for side = -1, 1, 2 do
		for i = 0, bands - 1 do
			local y = (netTop - NET_DROP - 0.02) + bandH * (i + 0.5)
			local red = i % 2 == 0
			b:cyl(
				`Ant{side}_{i}`,
				bandH * 0.98,
				0.035,
				Kit.vertical(side * ANTENNA_X, y, -0.02),
				if red then ANT_RED else NET,
				Enum.Material.SmoothPlastic
			)
		end
		b:box(
			`AntClip{side}`,
			Vector3.new(0.08, 0.16, 0.08),
			Kit.at(side * ANTENNA_X, netTop - 0.05, -0.06),
			C.SteelBlack,
			Enum.Material.Metal
		)
	end

	return b:done()
end

return VolleyballStandard
