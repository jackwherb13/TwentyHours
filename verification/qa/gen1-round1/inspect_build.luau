-- QA inspect of places/build.rbxm (read-only)
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
local siteParts = 0
local floors = {}
local missingVariant = 0
local racMaple = 0
local rac_maple = 0
local parts = 0

local function walk(inst)
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
			local m = tostring(d.Material)
			mats[m] = (mats[m] or 0) + 1
			local v = d.MaterialVariant
			if v == nil or v == "" then
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
			if m == "Enum.Material.Grass" or string.find(string.lower(d.Name), "grass", 1, true) then
				grassParts += 1
				print("GRASS", d:GetFullName(), d.Position, d.Size)
			end
			local path = d:GetFullName()
			if string.find(path, "Site", 1, true) then
				siteParts += 1
			end
			if d.Name == "Slab" or d.Name == "FootprintSlab" then
				local key = d.Name .. " " .. m .. " var=" .. tostring(v) .. " color=" .. tostring(d.Color)
				floors[key] = (floors[key] or 0) + 1
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
	end
end
walk(model)

print("parts", parts)
print("lights", lights, "surface", surfaceLights, "point", pointLights)
print("missingVariant", missingVariant)
print("RAC_Maple", racMaple, "RAC_maple", rac_maple)
print("siteParts", siteParts)
print("grassParts", grassParts)
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

local site = model:FindFirstChild("Site")
if site then
	print("Site children:")
	for _, c in site:GetChildren() do
		print(" ", c.Name, c.ClassName)
	end
end
local lighting = model:FindFirstChild("Lighting")
print("Lighting folder", lighting)

-- sample gym slab
for _, d in model:GetDescendants() do
	if d.Name == "Slab" and d.Parent and d.Parent.Name == "competition_gym" then
		print("gym slab", d.Material, d.MaterialVariant, d.Color, d.Size)
		break
	end
end

local lightHosts = {}
for _, d in model:GetDescendants() do
	if d.ClassName == "SurfaceLight" or d.ClassName == "PointLight" or d.ClassName == "SpotLight" then
		local host = d.Parent and d.Parent.Name or "?"
		local modelName = "?"
		local cur = d.Parent
		while cur and cur ~= model do
			if cur.ClassName == "Model" then
				modelName = cur.Name
				break
			end
			cur = cur.Parent
		end
		local key = modelName .. "/" .. host .. "/" .. d.ClassName
		lightHosts[key] = (lightHosts[key] or 0) + 1
	end
end
print("-- lights by host --")
for k, v in lightHosts do
	print(v, k)
end

local props = model:FindFirstChild("Props")
if props then
	local l2 = props:FindFirstChild("2")
	if l2 then
		for _, m in l2:GetChildren() do
			if string.find(string.lower(m.Name), "water") or string.find(string.lower(m.Name), "tread") then
				local minY = 1e9
				for _, p in m:GetDescendants() do
					if p:IsA("BasePart") then
						local y = p.Position.Y - p.Size.Y / 2
						if y < minY then
							minY = y
						end
					end
				end
				print("L2 prop", m.Name, "minBottom", minY, "attrRoom", m:GetAttribute("Room"))
			end
		end
	end
end
