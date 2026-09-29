--!strict
-- Competition-gym volleyball paint. The slab is glossy maple (RAC_maple).
-- A Mason-green apron, gold lines, GEORGE/MASON, and a center logo sit on that slab.
-- Sheets sit 0.02 ft and 0.05 ft above the floor so they never share a plane with it.
local Blueprint = require(script.Parent.Blueprint)
local Parts = require(script.Parent.Parts)

local Court = {}
local GREEN = Color3.fromRGB(0, 110, 52)
local GOLD = Color3.fromRGB(214, 172, 44)
local LOGO_GREEN = Color3.fromRGB(0, 70, 38)

local HALF_W = 29.5 / 2
local HALF_L = 59 / 2
local ATTACK = 9.84
local LINE = 0.5

local function paint(
	parent: Instance,
	name: string,
	x: number,
	z: number,
	w: number,
	d: number,
	y: number,
	color: Color3
)
	local part = Parts.box(parent, name, Vector3.new(w, 0.02, d), CFrame.new(x, y, z), "metal_panel", false)
	part.Color = color
	part.Material = Enum.Material.Metal
	part.MaterialVariant = "RAC_metal_panel"
	part.Reflectance = 0.08
	part.CanCollide = false
	return part
end

-- 5x7 strokes for capital letters, cells are on/off.
local GLYPH: { [string]: { string } } = {
	G = { "01110", "10001", "10000", "10111", "10001", "10001", "01110" },
	E = { "11111", "10000", "10000", "11110", "10000", "10000", "11111" },
	O = { "01110", "10001", "10001", "10001", "10001", "10001", "01110" },
	R = { "11110", "10001", "10001", "11110", "10100", "10010", "10001" },
	M = { "10001", "11011", "10101", "10101", "10001", "10001", "10001" },
	A = { "01110", "10001", "10001", "11111", "10001", "10001", "10001" },
	S = { "01111", "10000", "10000", "01110", "00001", "00001", "11110" },
	N = { "10001", "11001", "10101", "10101", "10011", "10001", "10001" },
}

local function word(parent: Instance, name: string, text: string, cx: number, cz: number, y: number, alongZ: boolean)
	local cell = 1.1
	local gap = 0.4
	local letterW = 5 * cell
	local n = #text
	local total = n * letterW + (n - 1) * gap
	for i = 1, n do
		local ch = string.sub(text, i, i)
		local glyph = GLYPH[ch]
		if glyph == nil then
			continue
		end
		local origin = (i - 1) * (letterW + gap) - total / 2
		for row = 1, 7 do
			local bits = glyph[row]
			for col = 1, 5 do
				if string.sub(bits, col, col) == "1" then
					local u = origin + (col - 0.5) * cell
					local v = (4 - row) * cell
					local px = if alongZ then cx + v else cx + u
					local pz = if alongZ then cz + u else cz + v
					paint(
						parent,
						name .. ch .. tostring(row) .. tostring(col),
						px,
						pz,
						cell * 0.85,
						cell * 0.85,
						y,
						GOLD
					)
				end
			end
		end
	end
end

local function logo(parent: Instance, cx: number, cz: number, y: number)
	paint(parent, "LogoOuter", cx, cz, 8.5, 8.5, y, GOLD)
	paint(parent, "LogoRing", cx, cz, 7.6, 7.6, y + 0.01, LOGO_GREEN)
	paint(parent, "LogoInner", cx, cz, 6.2, 6.2, y + 0.02, GOLD)
	paint(parent, "LogoFace", cx, cz, 5.4, 5.4, y + 0.03, GREEN)
	paint(parent, "LogoG", cx - 1.2, cz, 1.8, 3.6, y + 0.04, GOLD)
	paint(parent, "LogoM", cx + 1.2, cz, 1.8, 3.6, y + 0.04, GOLD)
end

function Court.build(parent: Instance, level: Blueprint.Level)
	if level.level ~= 1 then
		return
	end
	local gym: Blueprint.Room? = nil
	for _, room in level.rooms do
		if room.id == "competition_gym" then
			gym = room
			break
		end
	end
	if gym == nil then
		return
	end
	local minX, maxX = gym.polygon[1][1], gym.polygon[1][1]
	local minZ, maxZ = gym.polygon[1][2], gym.polygon[1][2]
	for _, p in gym.polygon do
		minX = math.min(minX, p[1])
		maxX = math.max(maxX, p[1])
		minZ = math.min(minZ, p[2])
		maxZ = math.max(maxZ, p[2])
	end
	local cx = (minX + maxX) / 2
	local cz = (minZ + maxZ) / 2
	local innerW = HALF_W * 2
	local innerL = HALF_L * 2
	-- Eight-foot Mason-green border only. The rest of the slab stays glossy maple.
	local apronX = 8
	local apronZ = 8
	local outerL = innerL + apronZ * 2
	local group = Instance.new("Folder")
	group.Name = "Court"
	group.Parent = parent
	local yGreen = level.elevation + 0.02
	local yLine = level.elevation + 0.05
	paint(group, "ApronWest", cx - HALF_W - apronX / 2, cz, apronX, outerL, yGreen, GREEN)
	paint(group, "ApronEast", cx + HALF_W + apronX / 2, cz, apronX, outerL, yGreen, GREEN)
	paint(group, "ApronNorth", cx, cz - HALF_L - apronZ / 2, innerW, apronZ, yGreen, GREEN)
	paint(group, "ApronSouth", cx, cz + HALF_L + apronZ / 2, innerW, apronZ, yGreen, GREEN)
	local function line(name: string, x: number, z: number, w: number, d: number)
		paint(group, name, x, z, w, d, yLine, GOLD)
	end
	line("SidelineWest", cx - HALF_W, cz, LINE, innerL)
	line("SidelineEast", cx + HALF_W, cz, LINE, innerL)
	line("EndlineNorth", cx, cz - HALF_L, innerW, LINE)
	line("EndlineSouth", cx, cz + HALF_L, innerW, LINE)
	line("CenterLine", cx, cz, innerW, LINE)
	line("AttackNorth", cx, cz - ATTACK, innerW, LINE)
	line("AttackSouth", cx, cz + ATTACK, innerW, LINE)
	word(group, "George", "GEORGE", cx - HALF_W - apronX * 0.45, cz, yLine, true)
	word(group, "Mason", "MASON", cx + HALF_W + apronX * 0.45, cz, yLine, true)
	logo(group, cx, cz, yLine)
end

return Court
