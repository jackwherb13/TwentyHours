--!strict
-- Vertical Olympic plate tree (IMG_0318). Grey post, black bumper plates, chrome hubs.
-- Horns point front and back so the plate faces read from the aisle. 45 / 25 / 10 / 5 lb.
-- Pivot bottom-center, front faces -Z.
local Kit = require(script.Parent.Kit)

local PlateTree = {
	kind = "plate_tree",
	size = Vector3.new(1.75, 4.9, 2.55),
}

local function optNum(opts: { [string]: any }?, key: string, default: number, lo: number, hi: number): number
	local v = if opts ~= nil then opts[key] else nil
	if type(v) == "number" then
		return math.clamp(v :: number, lo, hi)
	end
	return default
end

function PlateTree.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("PlateTree", cf)
	local C = Kit.Color
	local post = C.SteelGrey
	local extra = math.floor(optNum(opts, "extra", 0, 0, 1) + 0.5)
	local levels = {
		{ y = 1.2, d = 1.48, t = 0.16, n = 2 },
		{ y = 2.35, d = 1.12, t = 0.12, n = 2 },
		{ y = 3.3, d = 0.86, t = 0.08, n = 1 },
		{ y = 4.05, d = 0.7, t = 0.06, n = 1 },
	}

	for i = 1, 3 do
		local h = 1.45
		b:box(`Post{i}`, Vector3.new(0.2, h, 0.2), Kit.at(0, h * (i - 0.5) + 0.12, 0), post, Enum.Material.Metal, true)
	end
	b:cyl("Cap", 0.14, 0.26, Kit.vertical(0, 4.55, 0), post, Enum.Material.Metal)
	b:box("Base", Vector3.new(1.15, 0.1, 2.05), Kit.at(0, 0.08, 0), C.SteelBlack, Enum.Material.Metal, true)
	b:box("FootF", Vector3.new(0.55, 0.1, 0.28), Kit.at(0, 0.05, -1.05), C.SteelBlack, Enum.Material.Metal, true)
	b:box("FootB", Vector3.new(0.55, 0.1, 0.28), Kit.at(0, 0.05, 1.05), C.SteelBlack, Enum.Material.Metal, true)
	b:box("BootF", Vector3.new(0.62, 0.04, 0.32), Kit.at(0, 0.02, -1.05), C.RubberBlack, Enum.Material.Rubber)
	b:box("BootB", Vector3.new(0.62, 0.04, 0.32), Kit.at(0, 0.02, 1.05), C.RubberBlack, Enum.Material.Rubber)

	for i, level in levels do
		local count = level.n + extra
		for s = -1, 1, 2 do
			b:cyl(`Horn{s}{i}`, 0.9, 0.07, Kit.alongZ(0, level.y, s * 0.5), C.Chrome, Enum.Material.Metal)
			for p = 1, count do
				local pz = s * (0.26 + (p - 0.5) * (level.t + 0.03))
				b:cyl(
					`Plate{s}{i}{p}`,
					level.t,
					level.d,
					Kit.alongZ(0, level.y, pz),
					C.RubberBlack,
					Enum.Material.Rubber
				)
				local hub = b:cyl(
					`Hub{s}{i}{p}`,
					level.t + 0.02,
					math.max(0.22, level.d * 0.28),
					Kit.alongZ(0, level.y, pz),
					C.Chrome,
					Enum.Material.Metal
				)
				hub.Reflectance = 0.22
				b:box(
					`Tag{s}{i}{p}`,
					Vector3.new(level.d * 0.1, level.d * 0.16, 0.015),
					Kit.at(0, level.y + level.d * 0.22, pz + s * (level.t / 2 + 0.012)),
					C.OffWhite,
					Enum.Material.SmoothPlastic
				)
			end
		end
	end

	return b:done()
end

return PlateTree
