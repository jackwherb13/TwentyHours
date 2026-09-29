--!strict
-- 8 x 8 ft Olympic lifting platform (IMG_0328). 4 ft maple center lane, 2 ft rubber each side.
-- About 2 in tall. Pivot bottom-center; the lifter faces -Z and the wood runs front to back.
local Kit = require(script.Parent.Kit)

local LiftingPlatform = {
	kind = "lifting_platform",
	size = Vector3.new(8, 0.28, 8),
}

local function optNum(opts: { [string]: any }?, key: string, default: number, lo: number, hi: number): number
	local v = if opts ~= nil then opts[key] else nil
	if type(v) == "number" then
		return math.clamp(v :: number, lo, hi)
	end
	return default
end

function LiftingPlatform.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("LiftingPlatform", cf)
	local C = Kit.Color
	local boltsOn = optNum(opts, "bolts", 1, 0, 1) >= 0.5

	for _, side in { -1, 1 } do
		for row = 0, 3 do
			b:box(
				`Rubber{side}{row}`,
				Vector3.new(1.92, 0.15, 1.92),
				Kit.at(side * 3, 0.075, -3 + row * 2),
				C.RubberBlack,
				Enum.Material.Rubber,
				true
			)
		end
	end

	for i, x in { -1.5, -0.5, 0.5, 1.5 } do
		local shade = if i % 2 == 0 then C.Maple else Color3.fromRGB(204, 166, 114)
		b:box(`Wood{i}`, Vector3.new(0.94, 0.16, 7.88), Kit.at(x, 0.09, 0), shade, Enum.Material.Wood, true)
	end

	for _, x in { -2.02, 2.02 } do
		local tag = if x < 0 then "L" else "R"
		for i = 0, 3 do
			b:box(
				`Seam{tag}{i}`,
				Vector3.new(0.05, 0.17, 1.92),
				Kit.at(x, 0.085, -3 + i * 2),
				C.SteelBlack,
				Enum.Material.Metal
			)
		end
	end

	for i = 0, 3 do
		local x = -3 + i * 2
		local z = -3 + i * 2
		b:box(`EdgeN{i}`, Vector3.new(1.92, 0.08, 0.07), Kit.at(x, 0.04, -3.96), C.SteelBlack, Enum.Material.Rubber)
		b:box(`EdgeS{i}`, Vector3.new(1.92, 0.08, 0.07), Kit.at(x, 0.04, 3.96), C.SteelBlack, Enum.Material.Rubber)
		b:box(`EdgeW{i}`, Vector3.new(0.07, 0.08, 1.92), Kit.at(-3.96, 0.04, z), C.SteelBlack, Enum.Material.Rubber)
		b:box(`EdgeE{i}`, Vector3.new(0.07, 0.08, 1.92), Kit.at(3.96, 0.04, z), C.SteelBlack, Enum.Material.Rubber)
	end

	for _, x in { -3.75, 3.75 } do
		for _, z in { -3.75, 3.75 } do
			b:box(`Corner{x}{z}`, Vector3.new(0.22, 0.03, 0.22), Kit.at(x, 0.165, z), C.SteelGrey, Enum.Material.Metal)
		end
	end

	if boltsOn then
		for _, x in { -1.9, 1.9 } do
			for _, z in { -3.5, 0, 3.5 } do
				b:cyl(`Bolt{x}{z}`, 0.03, 0.07, Kit.vertical(x, 0.185, z), C.SteelGrey, Enum.Material.Metal)
			end
		end
	end

	return b:done()
end

return LiftingPlatform
