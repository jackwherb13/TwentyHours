-- Offline inspect of places/build.rbxm (QA only)
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local model = roblox.deserializeModel(fs.readFile("places/build.rbxm"))[1]
print("root", model.Name)

local mats = {}
local variants = {}
local lights = 0
local surfaceLights = 0
local pointLights = 0
local grassParts = 0
local missingVariant = 0
local racMaple = 0
local rac_maple = 0
local parts = 0
local floors = {}
local neon = 0
local racMat = {}
local canopy = {}
local trees = 0
local lotSlabs = 0
local pavement = 0
local emptyRooms = {}
local roomProps = {}
local lightByRoom = {}
local hanging = { fountain = {}, treadmill = {} }

local function pos(p)
	local ok, cf = pcall(function()
		return p.CFrame
	end)
	if ok and cf then
		return cf.Position
	end
	return roblox.Vector3.new(0, 0, 0)
end

local function walk(inst)
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
			local m = tostring(d.Material)
			mats[m] = (mats[m] or 0) + 1
			local v = d.MaterialVariant or ""
			if v == "" then
				missingVariant += 1
			else
				variants[v] = (variants[v] or 0) + 1
			end
			if v == "RAC_Maple" then
				racMaple += 1
			end
			if v == "RAC_maple" then
				rac_maple += 1
			end
			local attr = d:GetAttribute("RACMaterial")
			if attr then
				racMat[attr] = (racMat[attr] or 0) + 1
			end
			if m == "Enum.Material.Neon" then
				neon += 1
			end
			local name = string.lower(d.Name)
			if m == "Enum.Material.Grass" or string.find(name, "grass", 1, true) then
				grassParts += 1
			end
			if d.Name == "Slab" or d.Name == "FootprintSlab" then
				local key = d.Name .. " " .. m .. " var=" .. tostring(v) .. " rac=" .. tostring(attr)
				floors[key] = (floors[key] or 0) + 1
			end
			if string.find(name, "canopy", 1, true) then
				table.insert(canopy, d:GetFullName() .. " " .. m .. " size=" .. tostring(d.Size))
			end
			if string.find(d:GetFullName(), "Tree_", 1, true) and d.Name == "Trunk" then
				trees += 1
			end
			if d.Name == "LotSlab" then
				lotSlabs += 1
			end
			if d.Name == "PavementSlab" then
				pavement += 1
			end
			if string.find(d:GetFullName(), "WaterFountain", 1, true) then
				local p = pos(d)
				local bottom = p.Y - d.Size.Y / 2
				table.insert(hanging.fountain, string.format("%s y=%.2f bottom=%.2f", d.Name, p.Y, bottom))
			end
			if string.find(d:GetFullName(), "Treadmill", 1, true) then
				local p = pos(d)
				local bottom = p.Y - d.Size.Y / 2
				if hanging.treadmill[d.Parent and d.Parent.Name or "?"] == nil then
					hanging.treadmill[d.Parent and d.Parent.Name or "?"] = 1e9
				end
				local k = d.Parent.Name
				hanging.treadmill[k] = math.min(hanging.treadmill[k], bottom)
			end
		end
		if d.ClassName == "SurfaceLight" or d.ClassName == "PointLight" or d.ClassName == "SpotLight" then
			lights += 1
			if d.ClassName == "SurfaceLight" then
				surfaceLights += 1
			end
			if d.ClassName == "PointLight" then
				pointLights += 1
			end
		end
		if d:IsA("Model") then
			local room = d:GetAttribute("Room")
			if room then
				roomProps[room] = (roomProps[room] or 0) + 1
			end
		end
	end
end
walk(model)

print("parts", parts)
print("lights", lights, "surface", surfaceLights, "point", pointLights)
print("missingVariant", missingVariant)
print("RAC_Maple", racMaple, "RAC_maple", rac_maple)
print("grassParts", grassParts)
print("neon", neon)
print("trees", trees)
print("lotSlabs", lotSlabs, "pavement", pavement)
print("root Lighting", model:FindFirstChild("Lighting"))
print("-- rac materials --")
for k, v in racMat do
	print(v, k)
end
print("-- variants --")
for k, v in variants do
	print(k, v)
end
print("-- mats --")
for k, v in mats do
	print(k, v)
end
print("-- floors --")
for k, v in floors do
	print(v, k)
end
print("-- canopy --")
for _, c in canopy do
	print(c)
end

local function countChildren(folder)
	if not folder then
		return
	end
	for _, c in folder:GetChildren() do
		print(" ", c.Name, c.ClassName)
	end
end
print("Site children")
countChildren(model:FindFirstChild("Site"))
print("Levels")
countChildren(model:FindFirstChild("Levels"))

-- gym slab
for _, d in model:GetDescendants() do
	if d.Name == "Slab" and d.Parent and d.Parent.Name == "competition_gym" then
		print(
			"gym slab",
			d.Material,
			"var=" .. tostring(d.MaterialVariant),
			"rac=" .. tostring(d:GetAttribute("RACMaterial")),
			"color=" .. tostring(d.Color),
			"size=" .. tostring(d.Size)
		)
		break
	end
end

print("-- fountain bottoms sample --")
table.sort(hanging.fountain)
for i = 1, math.min(8, #hanging.fountain) do
	print(hanging.fountain[i])
end
print("-- treadmill model min bottoms --")
local nfloat = 0
for k, y in hanging.treadmill do
	if y > 0.4 then
		nfloat += 1
		print("FLOAT?", k, y)
	end
end
print("treadmill models with minBottom>0.4", nfloat)

print("MaterialService in model?", model:FindFirstChild("MaterialService") or model:FindFirstChildWhichIsA("MaterialService"))

-- empty rooms: rooms from floors vs props
local floorRooms = {}
local levels = model:FindFirstChild("Levels")
if levels then
	for _, lv in levels:GetChildren() do
		local floorsF = lv:FindFirstChild("Floors")
		if floorsF then
			for _, r in floorsF:GetChildren() do
				floorRooms[r.Name] = true
			end
		end
		local lightsF = lv:FindFirstChild("Lights")
		if lightsF then
			print("Lights folder", lv.Name, #lightsF:GetChildren(), "children")
			for _, c in lightsF:GetChildren() do
				print("  light child", c.Name, c.ClassName, #c:GetChildren())
			end
		end
	end
end
print("floor room folders", 0)
local n = 0
for _ in floorRooms do
	n += 1
end
print("n floor rooms", n)
local empty = 0
for id in floorRooms do
	if (roomProps[id] or 0) == 0 then
		empty += 1
		if empty <= 25 then
			print("EMPTY_ROOM", id)
		end
	end
end
print("empty rooms (no prop with Room attr)", empty)
