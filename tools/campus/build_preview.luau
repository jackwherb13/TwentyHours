--!strict
-- Isolated campus + horizon QA. Does not overwrite places/build.rbxm.
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Loader = require("../../tests/lib/loader")

local loader = Loader.new()
local parent = roblox.Instance.new("Folder")
parent.Name = "World"
local Campus = loader.load("src/ReplicatedStorage/RAC/Site/Campus/Builder")
local Horizon = loader.load("src/ReplicatedStorage/RAC/Site/Horizon/Builder")
local model, count = Campus.build(parent)
assert(model.Name == "Campus")
local againModel, again = Campus.build(parent)
assert(count == again, "Campus build is not idempotent")
assert(count <= 6000, `Campus over budget {count}`)
local hModel, hCount = Horizon.build(parent)
assert(hModel.Name == "Horizon")
local hAgainModel, hAgain = Horizon.build(parent)
assert(hCount == hAgain, "Horizon build is not idempotent")
assert(hCount <= 1500, `Horizon over budget {hCount}`)
fs.writeDir("verification/campus")
fs.writeFile("verification/campus/campus_preview.rbxm", roblox.serializeModel({ againModel }))
fs.writeFile("verification/campus/horizon_preview.rbxm", roblox.serializeModel({ hAgainModel }))
print(string.format("PASS campus preview: %d parts (budget 6000)", count))
print(string.format("PASS horizon preview: %d parts (budget 1500)", hCount))
local check =
	process.exec("lune", { "run", "tools/check_geometry.luau", "verification/campus/campus_preview.rbxm", "none" })
print(check.stdout)
if check.stderr ~= "" then
	warn(check.stderr)
end
if not check.ok then
	process.exit(1)
end
local hcheck =
	process.exec("lune", { "run", "tools/check_geometry.luau", "verification/campus/horizon_preview.rbxm", "none" })
print(hcheck.stdout)
if hcheck.stderr ~= "" then
	warn(hcheck.stderr)
end
if not hcheck.ok then
	process.exit(1)
end
