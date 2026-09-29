--!strict
-- Standard 2x2 ft recessed ceiling troffer light with prismatic acrylic lens and downward SurfaceLight.
-- Reference: IMG_0346 (commercial grid troffers in corridors, restrooms, and offices).
local Kit = require(script.Parent.Kit)

local Troffer2x2 = {
	kind = "troffer_2x2",
	size = Vector3.new(2.0, 0.4, 2.0),
}

local FrameWhite = Color3.fromRGB(242, 244, 245)
local HousingGrey = Color3.fromRGB(200, 204, 208)
local DiffuserColor = Color3.fromRGB(240, 244, 248)
local LedNeon = Color3.fromRGB(255, 252, 245)
local LightBeamColor = Color3.fromRGB(245, 248, 255)

function Troffer2x2.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("Troffer2x2", cf)
	local C = Kit.Color

	local w, h, d = 2.0, 0.4, 2.0
	local flangeW = 0.08
	local flangeH = 0.03

	-- 1. Outer perimeter T-grid resting flange
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

	-- Frame latches & corner grid clips
	b:box("DoorLatch", Vector3.new(0.06, 0.02, 0.08), Kit.at(w / 2 - 0.15, 0.03, 0), C.Chrome, Enum.Material.Metal)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			b:box(
				`GridClip_{sx}_{sz}`,
				Vector3.new(0.04, 0.04, 0.04),
				Kit.at(sx * (w / 2 - 0.04), 0.03, sz * (d / 2 - 0.04)),
				HousingGrey,
				Enum.Material.Metal
			)
		end
	end

	-- 4. Diffuser lens (center basket diffuser)
	local lensW = w - 0.3
	local lensD = d - 0.3
	b:box("DiffuserLens", Vector3.new(lensW, 0.04, lensD), Kit.at(0, 0.08, 0), DiffuserColor, Enum.Material.Glass)

	-- Angled side reflector slopes
	for _, s in { -1, 1 } do
		local x = s * (w / 2 - 0.25)
		b:box(
			`Reflector_{s}`,
			Vector3.new(0.2, 0.1, lensD),
			Kit.at(x, 0.14, 0) * CFrame.Angles(0, 0, s * math.rad(25)),
			FrameWhite,
			Enum.Material.SmoothPlastic
		)
	end

	-- 5. LED light emitter strip inside
	local led =
		b:box("LedEmitter", Vector3.new(0.15, 0.02, lensD - 0.1), Kit.at(0, 0.18, 0), LedNeon, Enum.Material.Neon)
	led.CastShadow = false

	-- 6. SurfaceLight facing downward into the room
	b:light(led, Enum.NormalId.Bottom, 1.2, 18, LightBeamColor)

	return b:done()
end

return Troffer2x2
