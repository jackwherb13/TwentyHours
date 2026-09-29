--!strict
-- Ceiling-mounted retractable hoop in the down (playing) position. IMG_0333, IMG_0336.
-- Pivot is the bottom of the hanging net, not the floor. Rim center is local y = RIM_Y;
-- place the model so that point is 10 ft above the court. Glass faces -Z (the rim side).
local Kit = require(script.Parent.Kit)

local RIM_Y = 1.22
local RIM_R = 0.75
local GLASS_W = 6.0
local GLASS_H = 3.5
local GLASS_Z = -3.05
local RIM_Z = -4.3
local MAST_Z = -2.35
local TOP_Y = 17.15

local BasketballHoopCeiling = {
	kind = "basketball_hoop_ceiling",
	size = Vector3.new(8.8, TOP_Y + 0.35, 10.4),
}

local RIM_ORANGE = Color3.fromRGB(214, 96, 22)
local NET_WHITE = Color3.fromRGB(238, 238, 234)
local TARGET = Color3.fromRGB(245, 245, 242)

local function along(pos: Vector3, dir: Vector3): CFrame
	local d = if dir.Magnitude < 1e-5 then Vector3.new(1, 0, 0) else dir.Unit
	local hint = if math.abs(d.Y) > 0.92 then Vector3.new(1, 0, 0) else Vector3.new(0, 1, 0)
	local yAxis = d:Cross(hint)
	if yAxis.Magnitude < 1e-5 then
		yAxis = d:Cross(Vector3.new(0, 0, 1))
	end
	return CFrame.fromMatrix(pos, d, yAxis.Unit)
end

local function ring(
	b: any,
	prefix: string,
	y: number,
	z: number,
	radius: number,
	tube: number,
	n: number,
	color: Color3,
	mat: Enum.Material
)
	local chord = 2 * radius * math.sin(math.pi / n) * 1.02
	for i = 0, n - 1 do
		local a = (i + 0.5) * (math.pi * 2 / n)
		local yaw = math.atan2(-math.cos(a), -math.sin(a))
		b:cyl(
			`{prefix}{i}`,
			chord,
			tube,
			CFrame.new(math.cos(a) * radius, y, z + math.sin(a) * radius) * CFrame.Angles(0, yaw, 0),
			color,
			mat
		)
	end
end

function BasketballHoopCeiling.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("BasketballHoopCeiling", cf)
	local C = Kit.Color

	local glass = b:box(
		"Glass",
		Vector3.new(GLASS_W, GLASS_H, 0.08),
		Kit.at(0, 0.72 + GLASS_H / 2, GLASS_Z),
		C.Glass,
		Enum.Material.Glass,
		true
	)
	glass.Transparency = 0.45
	glass.Reflectance = 0.08

	b:box(
		"BottomPad",
		Vector3.new(6.28, 0.2, 0.5),
		Kit.at(0, 0.58, GLASS_Z - 0.12),
		C.RubberBlack,
		Enum.Material.Rubber,
		true
	)
	b:box(
		"PadLeft",
		Vector3.new(0.16, 0.55, 0.42),
		Kit.at(-3.06, 0.78, GLASS_Z - 0.08),
		C.RubberBlack,
		Enum.Material.Rubber
	)
	b:box(
		"PadRight",
		Vector3.new(0.16, 0.55, 0.42),
		Kit.at(3.06, 0.78, GLASS_Z - 0.08),
		C.RubberBlack,
		Enum.Material.Rubber
	)

	local frameZ = GLASS_Z - 0.06
	b:box(
		"FrameTop",
		Vector3.new(6.2, 0.1, 0.12),
		Kit.at(0, 0.72 + GLASS_H - 0.02, frameZ),
		C.Chrome,
		Enum.Material.Metal
	)
	b:box("FrameBot", Vector3.new(6.2, 0.08, 0.12), Kit.at(0, 0.78, frameZ), C.Chrome, Enum.Material.Metal)
	b:box(
		"FrameL",
		Vector3.new(0.1, GLASS_H, 0.12),
		Kit.at(-3.05, 0.72 + GLASS_H / 2, frameZ),
		C.Chrome,
		Enum.Material.Metal
	)
	b:box(
		"FrameR",
		Vector3.new(0.1, GLASS_H, 0.12),
		Kit.at(3.05, 0.72 + GLASS_H / 2, frameZ),
		C.Chrome,
		Enum.Material.Metal
	)

	local targetY = RIM_Y + 0.95
	local targetZ = GLASS_Z - 0.08
	b:box(
		"TargetTop",
		Vector3.new(2.02, 0.045, 0.03),
		Kit.at(0, targetY + 0.74, targetZ),
		TARGET,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"TargetBot",
		Vector3.new(2.02, 0.045, 0.03),
		Kit.at(0, targetY - 0.74, targetZ),
		TARGET,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"TargetL",
		Vector3.new(0.045, 1.5, 0.03),
		Kit.at(-0.99, targetY, targetZ),
		TARGET,
		Enum.Material.SmoothPlastic
	)
	b:box("TargetR", Vector3.new(0.045, 1.5, 0.03), Kit.at(0.99, targetY, targetZ), TARGET, Enum.Material.SmoothPlastic)

	b:box(
		"RimPlate",
		Vector3.new(0.7, 0.42, 0.16),
		Kit.at(0, RIM_Y + 0.05, GLASS_Z - 0.16),
		C.SteelGrey,
		Enum.Material.Metal
	)
	for side = -1, 1, 2 do
		local p0 = Vector3.new(side * 0.22, RIM_Y + 0.02, GLASS_Z - 0.2)
		local p1 = Vector3.new(side * 0.7, RIM_Y, RIM_Z + 0.15)
		b:cyl(
			`RimArm{side}`,
			(p1 - p0).Magnitude,
			0.06,
			along((p0 + p1) / 2, p1 - p0),
			C.SteelGrey,
			Enum.Material.Metal
		)
	end
	ring(b, "Rim", RIM_Y, RIM_Z, RIM_R, 0.055, 14, RIM_ORANGE, Enum.Material.Metal)

	for i = 0, 9 do
		local a = (i + 0.5) * (math.pi * 2 / 10)
		local top = Vector3.new(math.cos(a) * (RIM_R - 0.02), RIM_Y - 0.03, RIM_Z + math.sin(a) * (RIM_R - 0.02))
		local bot = Vector3.new(math.cos(a) * 0.4, RIM_Y - 1.08, RIM_Z + math.sin(a) * 0.4)
		local cord = b:cyl(
			`Net{i}`,
			(top - bot).Magnitude,
			0.022,
			along((top + bot) / 2, top - bot),
			NET_WHITE,
			Enum.Material.Fabric
		)
		cord.Transparency = 0.12
	end
	ring(b, "NetRing", RIM_Y - 1.08, RIM_Z, 0.4, 0.02, 8, NET_WHITE, Enum.Material.Fabric)

	local mastBottom = 3.15
	local mastTop = 15.7
	local mastLen = mastTop - mastBottom
	b:cyl("Mast", mastLen, 0.32, Kit.vertical(0, (mastBottom + mastTop) / 2, MAST_Z), C.SteelBlack, Enum.Material.Metal)
	b:box(
		"GoalArm",
		Vector3.new(0.28, 0.28, 0.85),
		Kit.at(0, 3.35, (GLASS_Z + MAST_Z) / 2),
		C.SteelBlack,
		Enum.Material.Metal
	)
	b:box("Backer", Vector3.new(1.4, 2.2, 0.12), Kit.at(0, 2.5, GLASS_Z + 0.14), C.SteelBlack, Enum.Material.Metal)

	local boomY = 15.35
	b:cyl("Boom", 7.6, 0.22, Kit.at(0, boomY, MAST_Z), C.SteelBlack, Enum.Material.Metal)
	b:cyl("Spreader", 4.2, 0.14, Kit.at(0, 8.4, MAST_Z - 0.15), C.SteelBlack, Enum.Material.Metal)
	local braceFrom = {
		Vector3.new(-1.9, 8.4, MAST_Z - 0.1),
		Vector3.new(1.9, 8.4, MAST_Z - 0.1),
		Vector3.new(-0.15, 4.4, MAST_Z),
		Vector3.new(0.15, 4.4, MAST_Z),
	}
	local braceTo = {
		Vector3.new(-3.55, boomY, MAST_Z),
		Vector3.new(3.55, boomY, MAST_Z),
		Vector3.new(-3.3, boomY - 0.1, MAST_Z),
		Vector3.new(3.3, boomY - 0.1, MAST_Z),
	}
	for i = 1, 4 do
		local p0 = braceFrom[i]
		local p1 = braceTo[i]
		b:cyl(`Brace{i}`, (p1 - p0).Magnitude, 0.1, along((p0 + p1) / 2, p1 - p0), C.SteelBlack, Enum.Material.Metal)
	end

	local railY = 16.55
	local railZ0 = -3.6
	local railZ1 = 4.7
	local railLen = railZ1 - railZ0
	local railMid = (railZ0 + railZ1) / 2
	for side = -1, 1, 2 do
		local x = side * 1.55
		b:cyl(`Track{side}`, railLen, 0.16, Kit.alongZ(x, railY, railMid), C.SteelBlack, Enum.Material.Metal)
		b:cyl(`Hanger{side}`, 0.7, 0.1, Kit.vertical(x, railY + 0.4, railMid - 1.4), C.SteelGrey, Enum.Material.Metal)
		b:cyl(`HangerB{side}`, 0.7, 0.1, Kit.vertical(x, railY + 0.4, railMid + 1.6), C.SteelGrey, Enum.Material.Metal)
		for k, z in { railZ0 + 0.4, railMid, railZ1 - 0.35 } do
			b:cyl(`Wheel{side}_{k}`, 0.08, 0.22, Kit.at(x, railY - 0.16, z), C.SteelGrey, Enum.Material.Metal)
		end
	end
	for k, z in { railZ0 + 0.7, railMid - 0.4, railMid + 1.1, railZ1 - 0.5 } do
		b:cyl(`TrussX{k}`, 3.1, 0.08, Kit.at(0, railY + 0.15, z), C.SteelBlack, Enum.Material.Metal)
	end
	b:box("Motor", Vector3.new(1.35, 0.7, 1.15), Kit.at(0, railY - 0.55, 2.4), C.SteelBlack, Enum.Material.Metal)
	b:cyl("Winch", 0.7, 0.38, Kit.at(0, railY - 0.95, 2.4), C.SteelGrey, Enum.Material.Metal)
	local cableA = Vector3.new(0, railY - 0.95, 2.4)
	local cableB = Vector3.new(0, mastTop - 0.2, MAST_Z)
	b:cyl(
		"HoistCable",
		(cableA - cableB).Magnitude,
		0.035,
		along((cableA + cableB) / 2, cableA - cableB),
		C.SteelBlack,
		Enum.Material.Metal
	)

	local linkA = Vector3.new(0, mastTop, MAST_Z)
	local linkB = Vector3.new(0, railY - 0.2, 0.4)
	b:cyl(
		"MastLink",
		(linkA - linkB).Magnitude,
		0.16,
		along((linkA + linkB) / 2, linkA - linkB),
		C.SteelBlack,
		Enum.Material.Metal
	)
	b:box(
		"CeilingPlate",
		Vector3.new(3.4, 0.1, 1.2),
		Kit.at(0, railY + 0.78, railMid),
		C.SteelGrey,
		Enum.Material.Metal
	)

	return b:done()
end

return BasketballHoopCeiling
