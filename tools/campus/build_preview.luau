--!strict
-- Isolated campus QA. Does not overwrite places/build.rbxm.
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Loader = require("../../tests/lib/loader")

local loader = Loader.new()
local parent = roblox.Instance.new("Folder")
parent.Name = "World"
local Campus = loader.load("src/ReplicatedStorage/RAC/Site/Campus/Builder")
local model, count = Campus.build(parent)
assert(model.Name == "Campus")
local againModel, again = Campus.build(parent)
assert(count == again, "Campus build is not idempotent")
assert(count <= 4000, `Campus over budget {count}`)
fs.writeDir("verification/campus")
fs.writeFile("verification/campus/campus_preview.rbxm", roblox.serializeModel({ againModel }))
print(string.format("PASS campus preview: %d parts (budget 4000)", count))
local check =
	process.exec("lune", { "run", "tools/check_geometry.luau", "verification/campus/campus_preview.rbxm", "none" })
print(check.stdout)
if check.stderr ~= "" then
	warn(check.stderr)
end
if not check.ok then
	process.exit(1)
end
