local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local model = roblox.deserializeModel(fs.readFile("places/build.rbxm"))[1]

local yStats = {}
local function acc(key, y)
	local s = yStats[key]
	if not s then
		s = { n = 0, min = 1e9, max = -1e9, sum = 0 }
		yStats[key] = s
	end
	s.n += 1
	s.min = math.min(s.min, y)
	s.max = math.max(s.max, y)
	s.sum += y
end

local roofs = 0
local canopyRoof = 0
local names = {}
for _, d in model:GetDescendants() do
	if d:IsA("BasePart") then
		local path = d:GetFullName()
		local y = d.CFrame.Position.Y
		if d.Name == "CountySurfaceSlab" then
			acc("county", y)
		elseif d.Name == "Curb" then
			acc("curb", y)
		elseif string.find(path, "Roofs", 1, true) then
			roofs += 1
			acc("roof", y)
			if string.find(string.lower(d.Name), "canopy", 1, true) then
				canopyRoof += 1
				print("ROOF_CANOPY", path, d.Material, d.Size, y)
			end
		elseif d.Name == "Slab" then
			acc("slab", y)
		elseif d.Name == "TaperedCanopy" or d.Name == "CornerCanopy" then
			print("EXT_CANOPY", path, d.Material, d.Size, d.CFrame)
		end
		names[d.Name] = (names[d.Name] or 0) + 1
	end
end
print("roof parts", roofs, "named canopy", canopyRoof)
for k, s in yStats do
	print(string.format("%s n=%d min=%.2f max=%.2f avg=%.2f", k, s.n, s.min, s.max, s.sum / s.n))
end

print("-- frequent part names --")
local arr = {}
for n, c in names do
	if c > 50 then
		table.insert(arr, { n, c })
	end
end
table.sort(arr, function(a, b)
	return a[2] > b[2]
end)
for i = 1, math.min(30, #arr) do
	print(arr[i][2], arr[i][1])
end

-- props per room
local counts = {}
local props = model:FindFirstChild("Props")
if props then
	for _, lv in props:GetChildren() do
		for _, m in lv:GetChildren() do
			local room = m:GetAttribute("Room") or "?"
			counts[room] = (counts[room] or 0) + 1
		end
	end
end
print("-- rooms with few props --")
local bp1 = serde.decode("json", fs.readFile("blueprint/level1.json"))
local bp2 = serde.decode("json", fs.readFile("blueprint/level2.json"))
for _, lv in { bp1, bp2 } do
	for _, r in lv.rooms do
		if r.type ~= "void" then
			local n = counts[r.id] or 0
			if n < 4 then
				print(string.format("SPARSE %s type=%s props=%d floor=%s", r.id, r.type, n, tostring(r.floorMaterial)))
			end
		end
	end
end

-- stair rooms
print("-- stairs in model --")
for _, lv in model.Levels:GetChildren() do
	local st = lv:FindFirstChild("Stairs")
	if st then
		print(lv.Name, "stair parts", #st:GetDescendants())
		for _, c in st:GetChildren() do
			print(" ", c.Name)
		end
	end
end

-- lights per room
print("-- light models --")
local kinds = {}
for _, d in model:GetDescendants() do
	if d:IsA("Model") and (d.Name == "high_bay_light" or d.Name == "troffer_2x4" or d.Name == "troffer_2x2" or d.Name == "downlight") then
		kinds[d.Name] = (kinds[d.Name] or 0) + 1
		local room = d:GetAttribute("Room")
		if room == "main_stair" or room == "south_lobby" or (room and string.find(room, "stair", 1, true)) then
			print("LIGHT", d.Name, room, d:GetFullName())
		end
	end
end
for k, v in kinds do
	print("kind", k, v)
end

-- SurfaceLight brightness/range stats
local bmin, bmax, rmin, rmax = 1e9, -1e9, 1e9, -1e9
local n = 0
for _, d in model:GetDescendants() do
	if d.ClassName == "SurfaceLight" then
		n += 1
		bmin = math.min(bmin, d.Brightness)
		bmax = math.max(bmax, d.Brightness)
		rmin = math.min(rmin, d.Range)
		rmax = math.max(rmax, d.Range)
	end
end
print("SurfaceLight n", n, "bright", bmin, bmax, "range", rmin, rmax)
