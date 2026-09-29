--!strict
-- Offline MaterialVariant smoke test. Run from repo root with Lune.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local service = roblox.Instance.new("MaterialService")
local env = {
	game = { GetService = function(_, name)
		assert(name == "MaterialService")
		return service
	end },
	Enum = roblox.Enum,
	Color3 = roblox.Color3,
	Instance = roblox.Instance,
	assert = assert,
}
local materials = luau.load(fs.readFile("src/ReplicatedStorage/RAC/Materials.luau"), { environment = env })()
local part = roblox.Instance.new("Part")
part.Transparency = 0.25
part.Anchored = true
for key, definition in materials do
	if key == "apply" then
		continue
	end
	assert(definition.assetId == nil)
	assert(definition.studsPerTile > 0)
	assert(definition.roughness >= 0 and definition.roughness <= 1)
	if definition.texture then
		assert(fs.isFile(definition.texture), definition.texture)
	end
	materials.apply(part, key)
	assert(part.Material == definition.base)
	assert(part.Color == definition.color)
	assert(part.MaterialVariant == "")
	assert(part:GetAttribute("RACMaterial") == key)
end
assert(part.Transparency == 0.25 and part.Anchored)
assert(#service:GetChildren() == 0)
local previous = part.Material
assert(not pcall(materials.apply, part, "unknown_material"))
assert(part.Material == previous)
materials.maple.assetId = "rbxassetid://123456789"
materials.apply(part, "maple")
materials.apply(part, "maple")
assert(#service:GetChildren() == 1, "repeated apply must reuse variant")
assert(part.MaterialVariant == "RAC_maple")
local variant = service:FindFirstChild("RAC_maple")
assert(variant.ColorMap == materials.maple.assetId)
assert(variant.StudsPerTile == materials.maple.studsPerTile)
assert(part.Color == roblox.Color3.new(1, 1, 1))
materials.apply(part, "glass")
assert(part.MaterialVariant == "" and part:GetAttribute("RACTexturePath") == nil)
print("PASS Materials: entries, local files, fallback, unknown key, idempotent variants, metadata cleanup")
