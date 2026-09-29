--!strict
-- Blue commercial recycling bin (rolling cart toter style as seen in IMG_0373 foreground, or slim station style).
-- Reference: IMG_0373 (blue rolling recycling toter with lid, wheels, handle, and blue bag liner).
local Kit = require(script.Parent.Kit)

local RecycleBin = {
	kind = "recycle_bin",
	size = Vector3.new(2.0, 3.2, 2.2),
}

local RecycleBlue = Color3.fromRGB(0, 95, 185)
local LidDarkBlue = Color3.fromRGB(0, 68, 140)
local BagLinerBlue = Color3.fromRGB(35, 145, 235)
local WheelBlack = Color3.fromRGB(25, 26, 28)
local WheelRimGrey = Color3.fromRGB(180, 185, 190)
local AxleSteel = Color3.fromRGB(150, 154, 160)
local LabelWhite = Color3.fromRGB(245, 245, 250)

function RecycleBin.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("RecycleBin", cf)
	local C = Kit.Color

	local w, _h, d = 2.0, 3.2, 2.2
	local bodyH = 2.6
	local halfBodyH = bodyH / 2
	local rearZ = d / 2 - 0.25
	local frontZ = -d / 2 + 0.2

	-- 1. Wheels and Steel Axle at rear base
	local wheelY = 0.35
	local wheelRadius = 0.35
	local wheelDiam = wheelRadius * 2
	local axleZ = rearZ - 0.1
	-- Steel axle rod
	b:cyl("WheelAxle", w - 0.2, 0.05, Kit.at(0, wheelY, axleZ), AxleSteel, Enum.Material.Metal)

	-- Left and right rubber wheels
	for _, s in { -1, 1 } do
		local wx = s * (w / 2 - 0.12)
		-- Rubber tire
		b:cyl(`WheelTire_{s}`, 0.12, wheelDiam, Kit.at(wx, wheelY, axleZ), WheelBlack, Enum.Material.Rubber)
		-- Hub / rim
		b:cyl(`WheelHub_{s}`, 0.14, wheelDiam * 0.55, Kit.at(wx, wheelY, axleZ), WheelRimGrey, Enum.Material.Metal)
		-- Axle end cap
		b:cyl(`AxleCap_{s}`, 0.04, 0.08, Kit.at(s * (w / 2 - 0.02), wheelY, axleZ), C.Chrome, Enum.Material.Metal)
	end

	-- Front foot rest / kick stand (bottom front)
	b:box(
		"FrontRestFoot",
		Vector3.new(w - 0.6, 0.25, 0.3),
		Kit.at(0, 0.125, frontZ + 0.15),
		LidDarkBlue,
		Enum.Material.SmoothPlastic,
		true
	)
	-- Rear tilt step bar
	b:box("TiltStepBar", Vector3.new(0.6, 0.08, 0.1), Kit.at(0, 0.35, rearZ + 0.1), AxleSteel, Enum.Material.Metal)

	-- 2. Tapered Recycled Plastic Bin Body (Split in 2 vertical segments)
	-- Lower body segment
	b:box(
		"BodyLower",
		Vector3.new(w - 0.35, halfBodyH - 0.2, d - 0.5),
		Kit.at(0, halfBodyH / 2 + 0.1, 0),
		RecycleBlue,
		Enum.Material.SmoothPlastic,
		true
	)
	-- Upper body segment
	b:box(
		"BodyUpper",
		Vector3.new(w - 0.15, halfBodyH, d - 0.3),
		Kit.at(0, halfBodyH + halfBodyH / 2, 0),
		RecycleBlue,
		Enum.Material.SmoothPlastic,
		true
	)

	-- Front molded reinforcement rib
	b:box(
		"FrontRibLower",
		Vector3.new(0.12, halfBodyH - 0.2, 0.06),
		Kit.at(0, halfBodyH / 2 + 0.1, frontZ - 0.04),
		LidDarkBlue,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"FrontRibUpper",
		Vector3.new(0.12, halfBodyH - 0.1, 0.06),
		Kit.at(0, halfBodyH + halfBodyH / 2, frontZ - 0.08),
		LidDarkBlue,
		Enum.Material.SmoothPlastic
	)

	-- 3. Top Rim Collar & Rear Push Handle
	b:box(
		"RimCollar",
		Vector3.new(w, 0.16, d - 0.1),
		Kit.at(0, bodyH - 0.06, 0.05),
		LidDarkBlue,
		Enum.Material.SmoothPlastic,
		true
	)

	-- Rear molded push handle bar
	local handleY = bodyH - 0.05
	local handleZ = rearZ + 0.25
	b:box(
		"HandleMount_L",
		Vector3.new(0.08, 0.1, 0.3),
		Kit.at(-w / 2 + 0.25, handleY, handleZ - 0.15),
		LidDarkBlue,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"HandleMount_R",
		Vector3.new(0.08, 0.1, 0.3),
		Kit.at(w / 2 - 0.25, handleY, handleZ - 0.15),
		LidDarkBlue,
		Enum.Material.SmoothPlastic
	)
	b:cyl("HandleBar", w - 0.4, 0.12, Kit.at(0, handleY, handleZ), LidDarkBlue, Enum.Material.SmoothPlastic)

	-- 4. Blue Plastic Liner Bag Cuff under lid
	b:box(
		"BagLinerFront",
		Vector3.new(w - 0.1, 0.12, 0.05),
		Kit.at(0, bodyH - 0.06, frontZ - 0.1),
		BagLinerBlue,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"BagLinerLeft",
		Vector3.new(0.05, 0.12, d - 0.4),
		Kit.at(-w / 2 + 0.02, bodyH - 0.06, 0),
		BagLinerBlue,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"BagLinerRight",
		Vector3.new(0.05, 0.12, d - 0.4),
		Kit.at(w / 2 - 0.02, bodyH - 0.06, 0),
		BagLinerBlue,
		Enum.Material.SmoothPlastic
	)

	-- 5. Hinged Lid Assembly with recycle slots
	-- Main lid top cover
	b:box(
		"LidTopCover",
		Vector3.new(w - 0.05, 0.1, d - 0.1),
		Kit.at(0, bodyH + 0.1, 0.05),
		LidDarkBlue,
		Enum.Material.SmoothPlastic,
		true
	)
	-- Beveled top contour
	b:box(
		"LidBevel",
		Vector3.new(w - 0.25, 0.1, d - 0.3),
		Kit.at(0, bodyH + 0.2, 0.05),
		LidDarkBlue,
		Enum.Material.SmoothPlastic
	)

	-- Lid rear hinge knuckles
	for _, hx in { -0.5, 0.5 } do
		b:cyl(
			`LidHinge_{hx}`,
			0.18,
			0.1,
			Kit.at(hx, bodyH + 0.08, rearZ + 0.05),
			LidDarkBlue,
			Enum.Material.SmoothPlastic
		)
	end

	-- Recycle bottle/can circular drop hole (center-left)
	b:cyl(
		"BottleOpeningRing",
		0.02,
		0.45,
		Kit.vertical(-0.35, bodyH + 0.26, 0),
		WheelBlack,
		Enum.Material.SmoothPlastic
	)
	b:cyl(
		"BottleOpeningHole",
		0.03,
		0.38,
		Kit.vertical(-0.35, bodyH + 0.25, 0),
		WheelBlack,
		Enum.Material.SmoothPlastic
	)

	-- Paper / cardboard slot opening (center-right)
	b:box(
		"PaperSlotRecess",
		Vector3.new(0.12, 0.02, 0.8),
		Kit.at(0.35, bodyH + 0.26, 0),
		WheelBlack,
		Enum.Material.SmoothPlastic
	)

	-- 6. Front "RECYCLE ONLY" / Mobius Loop Decal Plate
	b:box(
		"RecycleLabelPlate",
		Vector3.new(0.7, 0.4, 0.01),
		Kit.at(0, bodyH - 0.5, frontZ - 0.1),
		LabelWhite,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"RecycleIconBar1",
		Vector3.new(0.2, 0.04, 0.01),
		Kit.at(0, bodyH - 0.42, frontZ - 0.11),
		RecycleBlue,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"RecycleIconBar2",
		Vector3.new(0.04, 0.15, 0.01),
		Kit.at(-0.1, bodyH - 0.52, frontZ - 0.11),
		RecycleBlue,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"RecycleIconBar3",
		Vector3.new(0.04, 0.15, 0.01),
		Kit.at(0.1, bodyH - 0.52, frontZ - 0.11),
		RecycleBlue,
		Enum.Material.SmoothPlastic
	)

	return b:done()
end

return RecycleBin
