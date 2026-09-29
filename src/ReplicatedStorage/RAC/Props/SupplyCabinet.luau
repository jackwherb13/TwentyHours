--!strict
-- Training-room supply cabinet. Pivot is the bottom center. Doors face -Z.
local Kit = require(script.Parent.Kit)

local SupplyCabinet = {
	kind = "supply_cabinet",
	size = Vector3.new(4.6, 6.2, 2.4),
}

function SupplyCabinet.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("SupplyCabinet", cf)
	local body = Color3.fromRGB(232, 230, 222)
	local trim = Color3.fromRGB(70, 74, 78)
	b:box("Carcass", Vector3.new(3.0, 5.8, 1.4), Kit.at(0, 3.0, 0), body, Enum.Material.SmoothPlastic, true)
	b:box("DoorL", Vector3.new(1.35, 5.2, 0.06), Kit.at(-0.7, 3.0, -0.72), trim, Enum.Material.Metal, false)
	b:box("DoorR", Vector3.new(1.35, 5.2, 0.06), Kit.at(0.7, 3.0, -0.72), trim, Enum.Material.Metal, false)
	b:box(
		"Kick",
		Vector3.new(2.9, 0.2, 1.3),
		Kit.at(0, 0.1, 0.05),
		Color3.fromRGB(30, 32, 34),
		Enum.Material.Metal,
		true
	)
	return b:done()
end

return SupplyCabinet
