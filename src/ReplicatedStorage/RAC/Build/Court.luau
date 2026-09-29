--!strict
-- Competition-gym volleyball paint. The slab is glossy maple (RAC_maple).
-- A Mason-green apron and gold lines are thin non-colliding sheets on that slab.
-- They sit 0.02 ft and 0.05 ft above the floor so they never share a plane with it.
local Blueprint = require(script.Parent.Blueprint)
local Parts = require(script.Parent.Parts)

local Court = {}
local GREEN = Color3.fromRGB(0, 78, 42)
local GOLD = Color3.fromRGB(212, 168, 42)

local CX = -136
local CZ = -206
local HALF_W = 29.5 / 2
local HALF_L = 59 / 2
local APRON = 8
local ATTACK = 9.84
local LINE = 0.45

local function paint(parent: Instance, name: string, x: number, z: number, w: number, d: number, y: number, color: Color3)
	local part = Parts.box(parent, name, Vector3.new(w, 0.02, d), CFrame.new(x, y, z), "maple", false)
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.MaterialVariant = ""
	part.Reflectance = 0.08
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
	local yLine = level.elevation + 0.05
	local innerW = HALF_W * 2
	local innerL = HALF_L * 2
	local outerW = innerW + APRON * 2
	local outerL = innerL + APRON * 2
	-- Frame only. The maple slab stays visible inside the lines.
	paint(group, "ApronWest", CX - HALF_W - APRON / 2, CZ, APRON, outerL, yGreen, GREEN)
	paint(group, "ApronEast", CX + HALF_W + APRON / 2, CZ, APRON, outerL, yGreen, GREEN)
	paint(group, "ApronNorth", CX, CZ - HALF_L - APRON / 2, innerW, APRON, yGreen, GREEN)
	paint(group, "ApronSouth", CX, CZ + HALF_L + APRON / 2, innerW, APRON, yGreen, GREEN)
	local function line(name: string, x: number, z: number, w: number, d: number)
		paint(group, name, x, z, w, d, yLine, GOLD)
	end
	line("SidelineWest", CX - HALF_W, CZ, LINE, innerL)
	line("SidelineEast", CX + HALF_W, CZ, LINE, innerL)
	line("EndlineNorth", CX, CZ - HALF_L, innerW, LINE)
	line("EndlineSouth", CX, CZ + HALF_L, innerW, LINE)
	line("CenterLine", CX, CZ, innerW, LINE)
	line("AttackNorth", CX, CZ - ATTACK, innerW, LINE)
	line("AttackSouth", CX, CZ + ATTACK, innerW, LINE)
end

return Court
