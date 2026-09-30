--!strict
-- Read-only dump of places/build.rbxm for QA. Does not modify the model.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local file = "places/build.rbxm"
local models = roblox.deserializePlace and nil
local ok, rootOrErr = pcall(function()
	return roblox.deserializeModel(fs.readFile(file))
end)
if not ok then
	print("deserializeModel failed", rootOrErr)
	ok, rootOrErr = pcall(function()
		return { (roblox :: any).deserializePlace(fs.readFile(file)) }
	end)
end
assert(ok, tostring(rootOrErr))
local models = rootOrErr :: { any }
local rac = models[1]
print("root", rac.ClassName, rac.Name, "children", #rac:GetChildren())

local function dumpPart(p: any)
	local pos = p.CFrame.Position
	local mv = ""
	pcall(function()
		mv = tostring(p.MaterialVariant)
	end)
	print(
		string.format(
			"%s | %s pos=(%.2f,%.2f,%.2f) size=(%.2f,%.2f,%.2f) mat=%s var=%s color=%.2f,%.2f,%.2f collide=%s query=%s",
			p:GetFullName(),
			p.ClassName,
			pos.X,
			pos.Y,
			pos.Z,
			p.Size.X,
			p.Size.Y,
			p.Size.Z,
			tostring(p.Material),
			mv,
			p.Color.R,
			p.Color.G,
			p.Color.B,
			tostring(p.CanCollide),
			tostring(p.CanQuery)
		)
	)
end

local counts: { [string]: number } = {}
local lights = 0
local zones = 0
local floating = 0
local grass = 0
local maple = 0
local brick = 0
local tinyNoCollideStairs = 0
local lightingFolder = false

local KEY = {
	TaperedCanopy = true,
	ReturnCanopy = true,
	LandingSlab = true,
	ApronSlab = true,
	RampRun = true,
	SupportColumn = true,
	RACLetters = true,
	DumpsterBody = true,
	LobbySpawn = true,
}

for _, d in rac:GetDescendants() do
	local cls = d.ClassName
	counts[cls] = (counts[cls] or 0) + 1
	if d:IsA("Light") then
		lights += 1
	end
	if d.Name == "Lighting" and d.ClassName == "Folder" then
		lightingFolder = true
		print("LIGHTING_FOLDER parent", d.Parent and d.Parent.Name, "children", #d:GetChildren())
	end
	if d:GetAttribute("RAC_Zone") == true or d:GetAttribute("id") then
		zones += 1
	end
	local name = d.Name
	if KEY[name] or string.sub(name, 1, 10) == "StairTread" or string.sub(name, 1, 4) == "Pine" or name == "Crown" or name == "Trunk" or name == "ShadeCanopy" then
		if d:IsA("BasePart") then
			dumpPart(d)
		else
			print("MODEL", d:GetFullName(), d.ClassName, #d:GetChildren())
		end
	end
	if d:IsA("BasePart") then
		local matOk, mat = pcall(function()
			return d.Material
		end)
		local varOk, variant = pcall(function()
			return tostring(d.MaterialVariant)
		end)
		if string.find(string.lower(name), "maple", 1, true) or (varOk and (variant == "RAC_maple" or variant == "maple")) then
			maple += 1
			if maple <= 8 then
				dumpPart(d)
			end
		end
		if matOk and (mat == Enum.Material.Brick or (varOk and string.find(string.lower(variant), "brick", 1, true))) then
			brick += 1
		end
		if matOk and (mat == Enum.Material.Grass or mat == Enum.Material.LeafyGrass) then
			grass += 1
			if grass <= 12 then
				dumpPart(d)
			end
		end
		local path = string.lower(d:GetFullName())
		local sizeOk, size = pcall(function()
			return d.Size
		end)
		if sizeOk and string.find(path, "stair", 1, true) and d.CanCollide == false and math.min(size.X, size.Y, size.Z) < 0.5 then
			tinyNoCollideStairs += 1
			if tinyNoCollideStairs <= 8 then
				dumpPart(d)
			end
		end
	end
end

print("COUNTS")
local keys = {}
for k in counts do
	table.insert(keys, k)
end
table.sort(keys)
for _, k in keys do
	print(k, counts[k])
end
print("lights", lights, "zoneAttrs", zones, "lightingFolder", lightingFolder, "mapleParts", maple, "brickParts", brick, "grassParts", grass, "tinyNoCollideStairs", tinyNoCollideStairs)

-- Named folders
for _, c in rac:GetChildren() do
	print("CHILD", c.Name, c.ClassName, #c:GetChildren())
end
