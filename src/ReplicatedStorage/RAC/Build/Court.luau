--!strict
-- Competition-gym volleyball paint. The slab is glossy maple. A Mason-green apron
-- and gold lines sit on it (IMG_0332–0337). Paint does not collide.
local Blueprint = require(script.Parent.Blueprint)
local Parts = require(script.Parent.Parts)

local Court = {}
local GREEN = Color3.fromRGB(0, 78, 42)
local GOLD = Color3.fromRGB(212, 168, 42)
local MAPLE = Color3.fromRGB(214, 168, 112)

local CX = -136
local CZ = -206
local HALF_W = 29.5 / 2
local HALF_L = 59 / 2
local APRON = 8
local ATTACK = 9.84
local LINE = 0.16

local function sheet(parent: Instance, name: string, x: number, z: number, w: number, d: number, y: number, color: Color3)
	local part = Parts.box(parent, name, Vector3.new(w, 0.02, d), CFrame.new(x, y, z), "maple", false)
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.MaterialVariant = ""
	part.Reflectance = if color == MAPLE then 0.28 else 0.08
	part.CanCollide = false
	return part
end

function Court.build(parent: Instance, level: Blueprint.Level)
	if level.level ~= 1 then
		return
	end
	local group = Instance.new("Folder")
	group.Name = "Court"
	group.Parent = parent
	local yGreen = level.elevation + 0.02
	local yLine = level.elevation + 0.045
	local yWood = level.elevation + 0.03
	local outerW = (HALF_W + APRON) * 2
	local outerL = (HALF_L + APRON) * 2
	sheet(group, "Apron", CX, CZ, outerW, outerL, yGreen, GREEN)
	sheet(group, "PlayingSurface", CX, CZ, HALF_W * 2, HALF_L * 2, yWood, MAPLE)
	local function line(name: string, x: number, z: number, w: number, d: number)
		sheet(group, name, x, z, w, d, yLine, GOLD)
	end
	line("SidelineWest", CX - HALF_W, CZ, LINE, HALF_L * 2)
	line("SidelineEast", CX + HALF_W, CZ, LINE, HALF_L * 2)
	line("EndlineNorth", CX, CZ - HALF_L, HALF_W * 2, LINE)
	line("EndlineSouth", CX, CZ + HALF_L, HALF_W * 2, LINE)
	line("CenterLine", CX, CZ, HALF_W * 2, LINE)
	line("AttackNorth", CX, CZ - ATTACK, HALF_W * 2, LINE)
	line("AttackSouth", CX, CZ + ATTACK, HALF_W * 2, LINE)
end

return Court
