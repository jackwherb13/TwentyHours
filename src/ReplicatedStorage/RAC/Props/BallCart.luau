--!strict
-- Wire cart of volleyballs. Pivot is the bottom center. Handle faces +Z.
local Kit = require(script.Parent.Kit)

local BallCart = {
	kind = "ball_cart",
	size = Vector3.new(3.2, 3.6, 2.4),
}

function BallCart.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("BallCart", cf)
	local steel = Color3.fromRGB(150, 154, 158)
	local ball = Color3.fromRGB(245, 245, 240)
	b:box("Deck", Vector3.new(2.8, 0.12, 1.8), Kit.at(0, 0.5, 0), steel, Enum.Material.Metal, true)
	for _, x in { -1.2, 1.2 } do
		for _, z in { -0.7, 0.7 } do
			b:box("Leg", Vector3.new(0.1, 0.5, 0.1), Kit.at(x, 0.25, z), steel, Enum.Material.Metal, true)
			b:cyl("Wheel", 0.12, 0.36, Kit.at(x, 0.18, z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(30, 30, 32), Enum.Material.Plastic)
		end
	end
	b:box("Rail", Vector3.new(2.8, 0.08, 0.08), Kit.at(0, 2.4, -0.85), steel, Enum.Material.Metal, false)
	b:box("RailBack", Vector3.new(2.8, 0.08, 0.08), Kit.at(0, 2.4, 0.85), steel, Enum.Material.Metal, false)
	local n = 0
	for row = 0, 2 do
		for col = 0, 3 do
			n += 1
			b:ball("Ball" .. n, 0.68, Kit.at(-1.05 + col * 0.7, 0.95 + row * 0.7, 0), ball, Enum.Material.SmoothPlastic)
		end
	end
	return b:done()
end

return BallCart
