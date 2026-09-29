--!strict
-- Isolated markings preview. Does not overwrite places/build.rbxm.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local Loader = require("../../tests/lib/loader")
local loader = Loader.new()
local parent = roblox.Instance.new("Folder")
parent.Name = "MarkingsPreview"
local Markings = loader.load("src/ReplicatedStorage/RAC/Site/Markings/init")
local n = Markings.build(parent, {})
local clone = roblox.Instance.new("Folder")
clone.Name = "MarkingsPreview2"
local again = Markings.build(clone, {})
assert(n == again, "Markings.build is not idempotent")
assert(n <= 2500, `Markings exceed budget: {n}`)
fs.writeFile("verification/site_markings/markings_preview.rbxm", roblox.serializeModel({ parent }))
print(string.format("PASS markings build: %d parts", n))
