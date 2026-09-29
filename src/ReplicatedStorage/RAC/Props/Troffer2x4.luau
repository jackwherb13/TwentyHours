--!strict
-- Standard 2x4 ft recessed ceiling troffer light with prismatic acrylic lens and downward SurfaceLight.
-- Reference: IMG_0325, IMG_0327, IMG_0323, IMG_0339, IMG_0346 (commercial grid troffers).
local Kit = require(script.Parent.Kit)

local Troffer2x4 = {
	kind = "troffer_2x4",
	size = Vector3.new(2.0, 0.4, 4.0),
}

local FrameWhite = Color3.fromRGB(242, 244, 245)
local HousingGrey = Color3.fromRGB(200, 204, 208)
local DiffuserColor = Color3.fromRGB(240, 244, 248)
local LedNeon = Color3.fromRGB(255, 252, 245)
local LightBeamColor = Color3.fromRGB(245, 248, 255)

function Troffer2x4.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("Troffer2x4", cf)
	local C = Kit.Color

	local w, h, d = 2.0, 0.4, 4.0
	local flangeW = 0.08
	local flangeH = 0.03

	-- 1. Outer perimeter T-grid resting flange (at ceiling line Y = 0.015)
	b:box(
		"Flange_Front",
		Vector3.new(w, flangeH, flangeW),
		Kit.at(0, flangeH / 2, -d / 2 + flangeW / 2),
		FrameWhite,
		Enum.Material.Metal
	)
	b:box(
		"Flange_Back",
		Vector3.new(w, flangeH, flangeW),
		Kit.at(0, flangeH / 2, d / 2 - flangeW / 2),
		FrameWhite,
		Enum.Material.Metal
	)
	b:box(
		"Flange_Left",
		Vector3.new(flangeW, flangeH, d - 2 * flangeW),
		Kit.at(-w / 2 + flangeW / 2, flangeH / 2, 0),
		FrameWhite,
		Enum.Material.Metal
	)
	b:box(
		"Flange_Right",
		Vector3.new(flangeW, flangeH, d - 2 * flangeW),
		Kit.at(w / 2 - flangeW / 2, flangeH / 2, 0),
		FrameWhite,
		Enum.Material.Metal
	)

	-- 2. Recessed housing box (above ceiling grid, Y from 0.05 to 0.4)
	local boxH = h - 0.05
	local boxY = 0.05 + boxH / 2
	b:box("HousingTop", Vector3.new(w - 0.16, 0.02, d - 0.16), Kit.at(0, h - 0.01, 0), HousingGrey, Enum.Material.Metal)
	b:box(
		"HousingSide_Left",
		Vector3.new(0.02, boxH, d - 0.16),
		Kit.at(-w / 2 + 0.09, boxY, 0),
		HousingGrey,
		Enum.Material.Metal
	)
	b:box(
		"HousingSide_Right",
		Vector3.new(0.02, boxH, d - 0.16),
		Kit.at(w / 2 - 0.09, boxY, 0),
		HousingGrey,
		Enum.Material.Metal
	)
	b:box(
		"HousingEnd_Front",
		Vector3.new(w - 0.16, boxH, 0.02),
		Kit.at(0, boxY, -d / 2 + 0.09),
		HousingGrey,
		Enum.Material.Metal
	)
	b:box(
		"HousingEnd_Back",
		Vector3.new(w - 0.16, boxH, 0.02),
		Kit.at(0, boxY, d / 2 - 0.09),
		HousingGrey,
		Enum.Material.Metal
	)

	-- 3. Hinged lens door frame
	local doorFlangeW = 0.06
	b:box(
		"DoorFrame_Front",
		Vector3.new(w - 0.16, 0.02, doorFlangeW),
		Kit.at(0, 0.04, -d / 2 + 0.12),
		FrameWhite,
		Enum.Material.Metal
	)
	b:box(
		"DoorFrame_Back",
		Vector3.new(w - 0.16, 0.02, doorFlangeW),
		Kit.at(0, 0.04, d / 2 - 0.12),
		FrameWhite,
		Enum.Material.Metal
	)
	b:box(
		"DoorFrame_Left",
		Vector3.new(doorFlangeW, 0.02, d - 0.24),
		Kit.at(-w / 2 + 0.12, 0.04, 0),
		FrameWhite,
		Enum.Material.Metal
	)
	b:box(
		"DoorFrame_Right",
		Vector3.new(doorFlangeW, 0.02, d - 0.24),
		Kit.at(w / 2 - 0.12, 0.04, 0),
		FrameWhite,
		Enum.Material.Metal
	)

	-- Frame cam latches
	for _, zSign in { -1, 1 } do
		b:box(
			`DoorLatch_{zSign}`,
			Vector3.new(0.06, 0.02, 0.08),
			Kit.at(w / 2 - 0.15, 0.03, zSign * 1.0),
			C.Chrome,
			Enum.Material.Metal
		)
	end

	-- 4. Diffuser lens (curved / angled center basket diffuser)
	-- Split in 2 along Z (2 ft each) to keep bounding sphere tight
	local lensW = w - 0.3
	local halfLen = (d - 0.3) / 2
	b:box(
		"DiffuserLens_1",
		Vector3.new(lensW, 0.04, halfLen),
		Kit.at(0, 0.08, -halfLen / 2),
		DiffuserColor,
		Enum.Material.Glass
	)
	b:box(
		"DiffuserLens_2",
		Vector3.new(lensW, 0.04, halfLen),
		Kit.at(0, 0.08, halfLen / 2),
		DiffuserColor,
		Enum.Material.Glass
	)

	-- Angled side reflector slopes
	for _, s in { -1, 1 } do
		local x = s * (w / 2 - 0.25)
		b:box(
			`Reflector_1_{s}`,
			Vector3.new(0.2, 0.1, halfLen),
			Kit.at(x, 0.14, -halfLen / 2) * CFrame.Angles(0, 0, s * math.rad(25)),
			FrameWhite,
			Enum.Material.SmoothPlastic
		)
		b:box(
			`Reflector_2_{s}`,
			Vector3.new(0.2, 0.1, halfLen),
			Kit.at(x, 0.14, halfLen / 2) * CFrame.Angles(0, 0, s * math.rad(25)),
			FrameWhite,
			Enum.Material.SmoothPlastic
		)
	end

	-- 5. LED light emitter strips inside
	local led1 = b:box(
		"LedEmitter_1",
		Vector3.new(0.12, 0.02, halfLen - 0.1),
		Kit.at(0, 0.18, -halfLen / 2),
		LedNeon,
		Enum.Material.Neon
	)
	local led2 = b:box(
		"LedEmitter_2",
		Vector3.new(0.12, 0.02, halfLen - 0.1),
		Kit.at(0, 0.18, halfLen / 2),
		LedNeon,
		Enum.Material.Neon
	)
	led1.CastShadow = false
	led2.CastShadow = false

	-- 6. SurfaceLight facing downward into the room
	b:light(led1, Enum.NormalId.Bottom, 4.2, 40, LightBeamColor)

	return b:done()
end

return Troffer2x4
