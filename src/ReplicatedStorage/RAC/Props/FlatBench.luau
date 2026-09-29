--!strict
-- Commercial flat weight bench (~4 ft long, 1 ft wide pad, 17.5 in pad height). Reference: IMG_0318, IMG_0328.
local Kit = require(script.Parent.Kit)

local FlatBench = {
	kind = "flat_bench",
	size = Vector3.new(1.6, 1.5, 4.2),
}

function FlatBench.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("FlatBench", cf)
	local C = Kit.Color
	b:box("Pad", Vector3.new(1.0, 0.25, 4.0), Kit.at(0, 1.33, 0), C.Upholstery, Enum.Material.Leather, true)
	b:box("PadBase", Vector3.new(0.9, 0.12, 3.9), Kit.at(0, 1.15, 0), C.SteelBlack, Enum.Material.Metal)
	b:box("Spine", Vector3.new(0.25, 0.25, 3.4), Kit.at(0, 0.95, 0), C.SteelBlack, Enum.Material.Metal)
	for i, z in { -1.6, 1.6 } do
		b:box(`Post{i}`, Vector3.new(0.25, 0.9, 0.25), Kit.at(0, 0.5, z), C.SteelBlack, Enum.Material.Metal)
		b:box(`Foot{i}`, Vector3.new(1.6, 0.18, 0.3), Kit.at(0, 0.09, z), C.SteelBlack, Enum.Material.Metal)
		for s = -1, 1, 2 do
			b:box(
				`Cap{i}_{s}`,
				Vector3.new(0.12, 0.2, 0.32),
				Kit.at(s * 0.82, 0.1, z),
				C.RubberBlack,
				Enum.Material.Rubber
			)
		end
	end
	return b:done()
end

return FlatBench
