--!strict
-- Isolated QA output; never overwrites the shared live build.
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local Loader = require("../../tests/lib/loader")
local loader = Loader.new()
local function json(name: string): any
	return serde.decode("json", fs.readFile("blueprint_interim/" .. name .. ".json"))
end
local raw = { site = json("site"), levels = { json("level1"), json("level2") } }
local data = loader.load("src/ReplicatedStorage/RAC/Site/Prepare").apply(raw)
local parent = roblox.Instance.new("Folder")
local stats = loader.load("src/ReplicatedStorage/RAC/Build/Build").build(parent, data)
local model = parent:FindFirstChild("RAC")
assert(model)
local builder = loader.load("src/ReplicatedStorage/RAC/Site/Builder")
local count = builder.build(model, data.site)
local again = builder.build(model, data.site)
assert(count == again, "Site build is not idempotent")
assert(stats.parts + count < 25000, "Combined model exceeds the map part budget")
fs.writeFile("verification/exterior/site_preview.rbxm", roblox.serializeModel({ model }))
local context = model.Site.Context
local independent = context:Clone()
independent.Name = "SiteContext"
fs.writeFile("verification/exterior/context_preview.rbxm", roblox.serializeModel({ independent }))
context:Destroy()
local props = model:FindFirstChild("Props")
if props then
	props:Destroy()
end
fs.writeFile("verification/exterior/building_preview.rbxm", roblox.serializeModel({ model }))
model.Site:Destroy()
fs.writeFile("verification/exterior/baseline_building.rbxm", roblox.serializeModel({ model }))
print(
	string.format(
		"PASS idempotent site build: %d site parts; %d building/prop parts; %d combined",
		count,
		stats.parts,
		count + stats.parts
	)
)
