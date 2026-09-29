--!strict
-- United States flag hanging flat, stripes horizontal, canton to the viewer's left
-- when looking at the -Z face (IMG_0333). Proportions follow the 1 : 1.9 flag spec.
-- Pivot is the bottom hem. Stars are on both faces.
local Kit = require(script.Parent.Kit)

local HOIST = 5
local FLY = HOIST * 1.9
local HANGER = 1.15
local STRIPE = HOIST / 13
local CANTON_H = STRIPE * 7
local CANTON_W = HOIST * 0.76

local Flag = {
	kind = "flag",
	size = Vector3.new(FLY, HOIST + HANGER, 0.36),
}

local RED = Color3.fromRGB(191, 10, 48)
local BLUE = Color3.fromRGB(10, 49, 97)
local WHITE = Color3.fromRGB(250, 250, 250)

function Flag.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("Flag", cf)
	local C = Kit.Color
	local left = -FLY / 2

	for i = 0, 12 do
		local red = i % 2 == 0
		local color = if red then RED else WHITE
		local y = HOIST - STRIPE * (i + 0.5)
		if i < 7 then
			local w = FLY - CANTON_W
			local x = left + CANTON_W + w / 2
			b:box(`Stripe{i}`, Vector3.new(w, STRIPE, 0.035), Kit.at(x, y, 0), color, Enum.Material.Fabric)
		else
			b:box(`Stripe{i}`, Vector3.new(FLY, STRIPE, 0.04), Kit.at(0, y, 0), color, Enum.Material.Fabric)
		end
	end

	local cantonX = left + CANTON_W / 2
	local cantonY = HOIST - CANTON_H / 2
	b:box("Canton", Vector3.new(CANTON_W, CANTON_H, 0.045), Kit.at(cantonX, cantonY, 0), BLUE, Enum.Material.Fabric)

	local insetX = CANTON_W * 0.065
	local insetY = CANTON_H * 0.07
	local pitchX = (CANTON_W - insetX * 2) / 5
	local pitchY = (CANTON_H - insetY * 2) / 8
	local starD = 0.145
	for row = 0, 8 do
		local count = if row % 2 == 0 then 6 else 5
		local y = (HOIST - insetY) - row * pitchY
		local x0 = left + insetX + (if count == 5 then pitchX / 2 else 0)
		for col = 0, count - 1 do
			local x = x0 + col * pitchX
			for _, z in { -0.045, 0.045 } do
				b:ball(
					`Star{row}_{col}{if z < 0 then "F" else "B"}`,
					starD,
					Kit.at(x, y, z),
					WHITE,
					Enum.Material.SmoothPlastic
				)
			end
		end
	end

	b:cyl("Rod", FLY + 0.15, 0.09, Kit.at(0, HOIST + 0.02, 0), C.SteelGrey, Enum.Material.Metal)
	b:box("Sleeve", Vector3.new(FLY, 0.1, 0.07), Kit.at(0, HOIST - 0.02, 0), WHITE, Enum.Material.Fabric)
	for side = -1, 1, 2 do
		b:cyl(
			`Cord{side}`,
			HANGER,
			0.03,
			Kit.vertical(side * FLY * 0.28, HOIST + HANGER / 2 + 0.02, 0),
			C.SteelBlack,
			Enum.Material.Metal
		)
	end
	b:cyl("CeilingBar", FLY * 0.62, 0.05, Kit.at(0, HOIST + HANGER + 0.02, 0), C.SteelGrey, Enum.Material.Metal)
	b:box("FlyHem", Vector3.new(0.06, HOIST, 0.05), Kit.at(FLY / 2 - 0.03, HOIST / 2, 0), WHITE, Enum.Material.Fabric)
	return b:done()
end

return Flag
