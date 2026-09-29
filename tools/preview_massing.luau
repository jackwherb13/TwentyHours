-- Quick visual preview: extrude a blueprint's walls + room floors into places/massing_preview.rbxm.
-- Usage: lune run tools/preview_massing.luau <blueprint dir>
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local Instance, Vector3, CFrame, Color3, Enum = roblox.Instance, roblox.Vector3, roblox.CFrame, roblox.Color3, roblox.Enum
local dir = process.args[1] or "blueprint"

local root = Instance.new("Model")
root.Name = "RAC_MassingPreview"

local floorColors = {
	gym = Color3.fromRGB(214, 176, 124),
	lobby = Color3.fromRGB(200, 196, 188),
	corridor = Color3.fromRGB(205, 200, 190),
	fitness = Color3.fromRGB(40, 40, 42),
	office = Color3.fromRGB(80, 86, 96),
	locker = Color3.fromRGB(190, 180, 160),
	construction = Color3.fromRGB(150, 120, 90),
}

local function part(name, size, cf, color, material, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.Parent = parent
	return p
end

for _, lv in { "level1", "level2" } do
	local path = `{dir}/{lv}.json`
	if not fs.isFile(path) then
		continue
	end
	local d = serde.decode("json", fs.readFile(path))
	local elev = d.elevation or 0
	local folder = Instance.new("Folder")
	folder.Name = lv
	folder.Parent = root
	for _, w in d.walls or {} do
		local a = Vector3.new(w.a[1], 0, w.a[2])
		local b = Vector3.new(w.b[1], 0, w.b[2])
		local len = (b - a).Magnitude
		if len > 0.1 then
			local h = w.height or 12
			local mid = (a + b) / 2 + Vector3.new(0, elev + h / 2, 0)
			local cf = CFrame.lookAt(mid, mid + (b - a).Unit)
			local color = w.exterior and Color3.fromRGB(150, 78, 60) or Color3.fromRGB(236, 234, 228)
			part("Wall", Vector3.new(w.thickness or 0.67, h, len), cf, color, Enum.Material.SmoothPlastic, folder)
		end
	end
	for _, r in d.rooms or {} do
		local xs, zs = {}, {}
		for _, p in r.polygon do
			table.insert(xs, p[1])
			table.insert(zs, p[2])
		end
		local x0, x1 = math.min(table.unpack(xs)), math.max(table.unpack(xs))
		local z0, z1 = math.min(table.unpack(zs)), math.max(table.unpack(zs))
		if lv == "level1" and (x1 - x0) * (z1 - z0) < 60000 then
			part(`Floor_{r.id}`, Vector3.new(x1 - x0, 0.3, z1 - z0), CFrame.new((x0 + x1) / 2, elev - 0.15, (z0 + z1) / 2),
				floorColors[r.type] or Color3.fromRGB(190, 188, 184), Enum.Material.SmoothPlastic, folder)
		end
	end
end

fs.writeDir("places")
fs.writeFile("places/massing_preview.rbxm", roblox.serializeModel({ root }))
print(`wrote places/massing_preview.rbxm ({#root:GetDescendants()} instances)`)
