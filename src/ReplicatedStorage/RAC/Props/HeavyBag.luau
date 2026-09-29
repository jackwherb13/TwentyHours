--!strict
-- Freestanding heavy bag (punching bag) on a steel A-frame. ~14 in diameter, 4 ft bag.
-- Pivot bottom-center of the stand footprint; bag hangs on the -Z side of the yoke.
local Kit = require(script.Parent.Kit)

local HeavyBag = {
	kind = "heavy_bag",
	size = Vector3.new(6.8, 8.2, 6.8),
}

function HeavyBag.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("HeavyBagRail", cf)
	local C = Kit.Color
	local steel = C.SteelBlack
	local leather = Color3.fromRGB(42, 28, 22)
	local stitch = Color3.fromRGB(90, 70, 52)

	b:box("BasePad", Vector3.new(3.6, 0.08, 3.8), Kit.at(0, 0.04, 0.15), C.RubberBlack, Enum.Material.Rubber, true)
	b:box("BasePlate", Vector3.new(2.4, 0.1, 2.6), Kit.at(0, 0.13, 0.2), steel, Enum.Material.Metal, true)

	for s = -1, 1, 2 do
		b:box(`Leg{s}`, Vector3.new(0.16, 0.12, 3.4), Kit.at(s * 1.15, 0.2, 0.15), steel, Enum.Material.Metal, true)
		b:box(`Upright{s}`, Vector3.new(0.18, 7.4, 0.18), Kit.at(s * 1.15, 3.9, 1.55), steel, Enum.Material.Metal, true)
		b:box(`Brace{s}`, Vector3.new(0.12, 0.12, 2.2), Kit.at(s * 1.15, 2.4, 0.45), steel, Enum.Material.Metal)
		b:box(`Foot{s}`, Vector3.new(0.55, 0.08, 0.7), Kit.at(s * 1.15, 0.1, -1.45), steel, Enum.Material.Metal, true)
	end

	b:box("Yoke", Vector3.new(2.6, 0.16, 0.16), Kit.at(0, 7.55, 1.55), steel, Enum.Material.Metal, true)
	b:box("Arm", Vector3.new(0.14, 0.14, 2.4), Kit.at(0, 7.55, 0.4), steel, Enum.Material.Metal, true)
	b:cyl("HeadHook", 0.28, 0.12, Kit.vertical(0, 7.35, -0.7), C.SteelGrey, Enum.Material.Metal)

	b:cyl("HeadSwivel", 0.2, 0.18, Kit.vertical(0, 7.05, -0.7), C.Chrome, Enum.Material.Metal)
	b:cyl("HeadChain", 0.55, 0.06, Kit.vertical(0, 6.65, -0.7), C.SteelGrey, Enum.Material.Metal)

	b:cyl("HeadBag", 4.05, 1.15, Kit.vertical(0, 4.35, -0.7), leather, Enum.Material.Leather)
	b:cyl("HeadBagTop", 0.22, 1.05, Kit.vertical(0, 6.4, -0.7), leather, Enum.Material.Leather)
	b:cyl("HeadBagBottom", 0.18, 1.08, Kit.vertical(0, 2.28, -0.7), leather, Enum.Material.Leather)
	for i = 0, 3 do
		local y = 3.0 + i * 0.85
		b:cyl(`HeadBand{i}`, 0.04, 1.18, Kit.vertical(0, y, -0.7), stitch, Enum.Material.SmoothPlastic)
	end
	b:box("HeadLogo", Vector3.new(0.02, 0.55, 0.45), Kit.at(0, 4.6, -1.28), C.MasonGold, Enum.Material.SmoothPlastic)

	return b:done()
end

return HeavyBag
