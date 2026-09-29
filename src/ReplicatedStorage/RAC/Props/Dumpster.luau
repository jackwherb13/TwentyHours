--!strict
-- Open-top site dumpster. Pivot is the bottom center. The long side faces -Z.
local Kit = require(script.Parent.Kit)

local Dumpster = {
	kind = "dumpster",
	size = Vector3.new(8.0, 4.6, 4.2),
}

local GREEN = Color3.fromRGB(28, 92, 48)
local LID = Color3.fromRGB(48, 52, 50)

function Dumpster.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("Dumpster", cf)
	b:box("Body", Vector3.new(7.6, 3.6, 3.6), Kit.at(0, 2.3, 0), GREEN, Enum.Material.Metal, true)
	b:box("Rim", Vector3.new(7.8, 0.18, 3.8), Kit.at(0, 4.15, 0), LID, Enum.Material.Metal, true)
	-- Bottom sits 0.02 ft into the rim so the leaf is supported and the faces are not coplanar.
	b:box("LidLeaf", Vector3.new(7.4, 0.12, 1.7), Kit.at(0, 4.28, -0.8), LID, Enum.Material.Metal, true)
	for _, x in { -3.2, 3.2 } do
		b:box(`Wheel_{x}`, Vector3.new(0.5, 0.5, 0.4), Kit.at(x, 0.25, 1.4), LID, Enum.Material.Metal, true)
	end
	return b:done()
end

return Dumpster
