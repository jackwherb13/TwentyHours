--!strict
-- lune run tools/build_rac.luau [blueprint directory] [output model]
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local Loader = require("../tests/lib/loader")

local blueprint = process.args[1] or "blueprint"
local output = process.args[2] or "places/build.rbxm"

-- Called by the PowerShell wrapper only when full-model QA fails. Never infer
-- success from the checker's truncated human-readable diagnostics.
if process.args[3] == "--check-building" then
	local roots = roblox.deserializeModel(fs.readFile(output))
	assert(#roots == 1 and roots[1].Name == "RAC", "Expected one RAC model")
	local props = roots[1]:FindFirstChild("Props")
	if props then
		props:Destroy()
	end
	-- Draped site context is terrain dressing. Building QA covers walls, facade and roofs.
	local siteFolder = roots[1]:FindFirstChild("Site")
	local context = siteFolder and siteFolder:FindFirstChild("Context")
	if context then
		context:Destroy()
	end
	local temporary = output .. ".building-qa-" .. tostring(os.clock()) .. ".rbxm"
	local ok, result = pcall(function()
		fs.writeFile(temporary, roblox.serializeModel(roots))
		return process.exec("lune", { "run", "tools/check_geometry.luau", temporary, blueprint })
	end)
	if fs.isFile(temporary) then
		fs.removeFile(temporary)
	end
	assert(ok, result)
	print(result.stdout)
	if result.stderr ~= "" then
		warn(result.stderr)
	end
	process.exit(if result.ok then 0 else 1)
end

local started = os.clock()
local function json(name: string): any
	local path = blueprint .. "/" .. name .. ".json"
	assert(fs.isFile(path), "Missing blueprint file: " .. path)
	return serde.decode("json", fs.readFile(path))
end
local loader = Loader.new()
local data = { site = json("site"), levels = { json("level1"), json("level2") } }
-- Site-owned glass overrides. Does not rewrite level JSON on disk.
data = loader.load("src/ReplicatedStorage/RAC/Site/Prepare").apply(data)
local Build = loader.load("src/ReplicatedStorage/RAC/Build/Build")
local parent = roblox.Instance.new("Folder")
local stats = Build.build(parent, data)
local model = parent:FindFirstChild("RAC")
assert(model, "Build.build did not produce RAC")
local siteParts = loader.load("src/ReplicatedStorage/RAC/Site/Builder").build(model, data.site)
stats.parts += siteParts
stats.byCategory.SiteContext = siteParts
local directory = string.match(string.gsub(output, "\\", "/"), "^(.*)/[^/]+$")
if directory and directory ~= "" then
	fs.writeDir(directory)
end
fs.writeFile(output, roblox.serializeModel({ model }))
print("Built " .. output .. " from " .. blueprint)
local categories = {}
for category in stats.byCategory do
	table.insert(categories, category)
end
table.sort(categories)
print("Part counts by category:")
for _, category in categories do
	print(string.format("  %-12s %d", category, stats.byCategory[category]))
end
print(string.format("Total: %d parts; build time: %.3f s", stats.parts, os.clock() - started))
