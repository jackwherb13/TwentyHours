--!strict
-- Athletic-training ice machine. Pivot is the bottom center. Door faces -Z.
local Kit = require(script.Parent.Kit)

local IceMachine = {
	kind = "ice_machine",
	size = Vector3.new(2.6, 3.4, 2.4),
}

function IceMachine.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("IceMachine", cf)
	local steel = Color3.fromRGB(186, 190, 194)
	local dark = Color3.fromRGB(40, 44, 48)
	b:box("Body", Vector3.new(2.4, 2.7, 2.1), Kit.at(0, 1.45, 0), steel, Enum.Material.Metal, true)
	b:box("Door", Vector3.new(1.5, 1.3, 0.08), Kit.at(0, 1.15, -1.05), dark, Enum.Material.Metal, false)
	b:box("Bin", Vector3.new(2.2, 0.7, 1.9), Kit.at(0, 0.4, 0), Color3.fromRGB(210, 214, 216), Enum.Material.Metal, true)
	b:box("Vent", Vector3.new(1.6, 0.35, 0.04), Kit.at(0, 2.5, -1.1), dark, Enum.Material.Metal, false)
	return b:done()
end

return IceMachine
