--!strict
-- Fail if a visible building part uses a material/color/variant outside docs/MATERIALS_TEMPLATE.md.
-- Usage: lune run tools/check_materials.luau [places/build.rbxm]
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local file = process.args[1] or "places/build.rbxm"
local SKIP_KEYS = { apply = true, install = true }
local PROP_TRIM = {
	bolt = true,
	screw = true,
	pin = true,
	hinge = true,
	handle = true,
	knob = true,
	label = true,
	trim = true,
	cap = true,
	nut = true,
	washer = true,
	rivet = true,
	grommet = true,
	clip = true,
	wire = true,
	cord = true,
}

local env = {
	game = {
		GetService = function(_, name)
			assert(name == "MaterialService")
			return roblox.Instance.new("MaterialService")
		end,
	},
	Enum = roblox.Enum,
	Color3 = roblox.Color3,
	Instance = roblox.Instance,
	assert = assert,
}
local materials = luau.load(fs.readFile("src/ReplicatedStorage/RAC/Materials.luau"), { environment = env })()

local allowed: { [string]: any } = {}
local colorOk: { [string]: boolean } = {}
for key, definition in materials do
	if SKIP_KEYS[key] then
		continue
	end
	allowed[key] = definition
	local c = definition.color
	colorOk[string.format("%d,%d,%d", math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255))] = true
	if definition.texture then
		assert(fs.isFile(definition.texture), "missing color map " .. definition.texture)
	end
	if definition.normal then
		assert(fs.isFile(definition.normal), "missing normal map " .. definition.normal)
	end
	if definition.roughnessMap then
		assert(fs.isFile(definition.roughnessMap), "missing roughness map " .. definition.roughnessMap)
	end
end

local function fullPath(inst): string
	local names = {}
	local cur = inst
	while cur do
		table.insert(names, 1, cur.Name)
		cur = cur.Parent
	end
	return table.concat(names, ".")
end

local function isProp(path: string, inst: any): boolean
	local p = string.lower(path)
	if string.find(p, ".props.", 1, true) ~= nil or string.find(p, ".prop.", 1, true) ~= nil then
		return true
	end
	-- Doors and other library models hang under wall openings.
	local cur = inst.Parent
	while cur do
		if cur:IsA("Model") and cur.Name ~= "RAC" then
			return true
		end
		cur = cur.Parent
	end
	return false
end

local function isBuilding(path: string): boolean
	local p = string.lower(path)
	if string.find(p, ".site.", 1, true) or string.find(p, "campus", 1, true) or string.find(p, "horizon", 1, true) then
		return false
	end
	if string.find(p, ".props.", 1, true) or string.find(p, ".lighting.", 1, true) then
		return false
	end
	return string.find(p, ".floors.", 1, true) ~= nil
		or string.find(p, ".walls.", 1, true) ~= nil
		or string.find(p, ".ceilings.", 1, true) ~= nil
		or string.find(p, ".columns.", 1, true) ~= nil
		or string.find(p, ".stairs.", 1, true) ~= nil
		or string.find(p, ".court.", 1, true) ~= nil
		or string.find(p, ".facade", 1, true) ~= nil
		or string.find(p, ".roofs.", 1, true) ~= nil
		or string.find(p, ".levels.", 1, true) ~= nil
end

local function smallTrim(part, path: string): boolean
	local n = string.lower(part.Name)
	if PROP_TRIM[n] then
		return true
	end
	local s = part.Size
	local minDim = math.min(s.X, s.Y, s.Z)
	return minDim < 0.35
end

local function colorKey(c): string
	return string.format("%d,%d,%d", math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255))
end

if not fs.isFile(file) then
	print("SKIP check_materials: " .. file .. " missing")
	process.exit(0)
end

local model = roblox.deserializeModel(fs.readFile(file))
local fails = {}
local checked = 0
for _, root in model do
	for _, d in root:GetDescendants() do
		if not d:IsA("BasePart") then
			continue
		end
		if d.Transparency >= 0.95 then
			continue
		end
		local path = fullPath(d)
		local prop = isProp(path, d)
		if not isBuilding(path) or prop then
			if prop and smallTrim(d, path) then
				continue
			end
			if prop then
				local key = d:GetAttribute("RACMaterial")
				if typeof(key) == "string" and allowed[key] then
					continue
				end
				if smallTrim(d, path) then
					continue
				end
				-- Props may use template colors even without the attribute.
				if colorOk[colorKey(d.Color)] then
					continue
				end
				continue
			end
			continue
		end
		checked += 1
		local key = d:GetAttribute("RACMaterial")
		if typeof(key) ~= "string" or allowed[key] == nil then
			table.insert(fails, path .. " missing template RACMaterial")
			continue
		end
		local def = allowed[key]
		local dc = def.color
		local pc = d.Color
		if math.abs(dc.R - pc.R) > 0.02 or math.abs(dc.G - pc.G) > 0.02 or math.abs(dc.B - pc.B) > 0.02 then
			table.insert(fails, path .. " color not in template (" .. key .. ")")
		end
		local expectedVariant = if def.assetId then "RAC_" .. key else ""
		if d.MaterialVariant ~= expectedVariant and d.MaterialVariant ~= "" and expectedVariant ~= "" then
			table.insert(fails, path .. " variant " .. tostring(d.MaterialVariant) .. " not template")
		end
	end
end

if #fails > 0 then
	print("FAIL check_materials: " .. tostring(#fails) .. " issues (checked " .. tostring(checked) .. ")")
	for i, line in fails do
		if i > 40 then
			print("...")
			break
		end
		print("  " .. line)
	end
	process.exit(1)
end
print("PASS check_materials: " .. tostring(checked) .. " building parts in template")
