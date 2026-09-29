--!strict
-- Commercial emergency exit sign with glowing red Neon letters.
-- Reference: IMG_0346, IMG_0339 (red LED exit sign hanging in corridors).
local Kit = require(script.Parent.Kit)

local ExitSign = {
	kind = "exit_sign",
	size = Vector3.new(1.3, 0.9, 0.3),
}

local HousingWhite = Color3.fromRGB(240, 240, 238)
local NeonRed = Color3.fromRGB(255, 30, 25)
local FaceplateGrey = Color3.fromRGB(220, 222, 225)
local StatusGreen = Color3.fromRGB(40, 220, 60)

function ExitSign.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("ExitSign", cf)

	local w, h, d = 1.3, 0.9, 0.3
	local bodyH = 0.65
	local canopyH = 0.25
	local bodyY = bodyH / 2
	local faceZ = -d / 2

	-- 1. Main rectangular housing body
	b:box("HousingBody", Vector3.new(w, bodyH, d), Kit.at(0, bodyY, 0), HousingWhite, Enum.Material.SmoothPlastic, true)

	-- Perimeter beveled frame on front and back faces
	for _, zSign in { -1, 1 } do
		local z = zSign * (d / 2 + 0.01)
		b:box(
			`BezelTop_{zSign}`,
			Vector3.new(w + 0.02, 0.04, 0.02),
			Kit.at(0, bodyH - 0.02, z),
			HousingWhite,
			Enum.Material.SmoothPlastic
		)
		b:box(
			`BezelBottom_{zSign}`,
			Vector3.new(w + 0.02, 0.04, 0.02),
			Kit.at(0, 0.02, z),
			HousingWhite,
			Enum.Material.SmoothPlastic
		)
		b:box(
			`BezelLeft_{zSign}`,
			Vector3.new(0.04, bodyH, 0.02),
			Kit.at(-w / 2 + 0.02, bodyY, z),
			HousingWhite,
			Enum.Material.SmoothPlastic
		)
		b:box(
			`BezelRight_{zSign}`,
			Vector3.new(0.04, bodyH, 0.02),
			Kit.at(w / 2 - 0.02, bodyY, z),
			HousingWhite,
			Enum.Material.SmoothPlastic
		)

		-- Faceplate backing
		b:box(
			`FacePlate_{zSign}`,
			Vector3.new(w - 0.08, bodyH - 0.08, 0.01),
			Kit.at(0, bodyY, z),
			FaceplateGrey,
			Enum.Material.SmoothPlastic
		)
	end

	-- 2. "EXIT" glowing red letters and chevrons on front face
	-- Letter E
	local letterY = bodyY
	local lz = faceZ - 0.015
	local eX = -0.32
	b:box("Letter_E_Spine", Vector3.new(0.04, 0.35, 0.01), Kit.at(eX - 0.06, letterY, lz), NeonRed, Enum.Material.Neon)
	b:box(
		"Letter_E_Top",
		Vector3.new(0.14, 0.04, 0.01),
		Kit.at(eX - 0.01, letterY + 0.155, lz),
		NeonRed,
		Enum.Material.Neon
	)
	b:box("Letter_E_Mid", Vector3.new(0.11, 0.04, 0.01), Kit.at(eX - 0.025, letterY, lz), NeonRed, Enum.Material.Neon)
	b:box(
		"Letter_E_Bot",
		Vector3.new(0.14, 0.04, 0.01),
		Kit.at(eX - 0.01, letterY - 0.155, lz),
		NeonRed,
		Enum.Material.Neon
	)

	-- Letter X
	local xX = -0.11
	b:box(
		"Letter_X_1",
		Vector3.new(0.04, 0.38, 0.01),
		Kit.at(xX, letterY, lz) * CFrame.Angles(0, 0, math.rad(28)),
		NeonRed,
		Enum.Material.Neon
	)
	b:box(
		"Letter_X_2",
		Vector3.new(0.04, 0.38, 0.01),
		Kit.at(xX, letterY, lz) * CFrame.Angles(0, 0, math.rad(-28)),
		NeonRed,
		Enum.Material.Neon
	)

	-- Letter I
	local iX = 0.1
	b:box("Letter_I", Vector3.new(0.045, 0.35, 0.01), Kit.at(iX, letterY, lz), NeonRed, Enum.Material.Neon)

	-- Letter T
	local tX = 0.3
	b:box("Letter_T_Stem", Vector3.new(0.045, 0.35, 0.01), Kit.at(tX, letterY, lz), NeonRed, Enum.Material.Neon)
	b:box("Letter_T_Cross", Vector3.new(0.16, 0.04, 0.01), Kit.at(tX, letterY + 0.155, lz), NeonRed, Enum.Material.Neon)

	-- Directional Chevrons
	-- Left chevron
	b:box(
		"Chevron_L1",
		Vector3.new(0.035, 0.1, 0.01),
		Kit.at(-w / 2 + 0.12, letterY + 0.03, lz) * CFrame.Angles(0, 0, math.rad(45)),
		NeonRed,
		Enum.Material.Neon
	)
	b:box(
		"Chevron_L2",
		Vector3.new(0.035, 0.1, 0.01),
		Kit.at(-w / 2 + 0.12, letterY - 0.03, lz) * CFrame.Angles(0, 0, math.rad(-45)),
		NeonRed,
		Enum.Material.Neon
	)
	-- Right chevron
	b:box(
		"Chevron_R1",
		Vector3.new(0.035, 0.1, 0.01),
		Kit.at(w / 2 - 0.12, letterY + 0.03, lz) * CFrame.Angles(0, 0, math.rad(-45)),
		NeonRed,
		Enum.Material.Neon
	)
	b:box(
		"Chevron_R2",
		Vector3.new(0.035, 0.1, 0.01),
		Kit.at(w / 2 - 0.12, letterY - 0.03, lz) * CFrame.Angles(0, 0, math.rad(45)),
		NeonRed,
		Enum.Material.Neon
	)

	-- 3. Top mounting canopy / stem (connecting body to ceiling or bracket)
	local canopyY = bodyH + canopyH / 2
	b:box(
		"MountStem",
		Vector3.new(0.12, canopyH, 0.12),
		Kit.at(0, canopyY, 0),
		HousingWhite,
		Enum.Material.SmoothPlastic
	)
	b:box("CeilingCanopyPlate", Vector3.new(0.5, 0.04, 0.5), Kit.at(0, h - 0.02, 0), HousingWhite, Enum.Material.Metal)

	-- 4. Status indicators & test button on bottom edge
	b:cyl(
		"TestButton",
		0.03,
		0.06,
		Kit.vertical(-0.35, 0.015, 0),
		Color3.fromRGB(60, 60, 65),
		Enum.Material.SmoothPlastic
	)
	local statusLed = b:ball("StatusLed", 0.04, Kit.at(0.35, 0.02, -d / 2 - 0.01), StatusGreen, Enum.Material.Neon)
	statusLed.CastShadow = false

	-- 5. Soft red ambient glow for horror atmosphere
	local redGlowPart =
		b:box("GlowEmitter", Vector3.new(0.8, 0.02, 0.02), Kit.at(0, 0.05, 0), NeonRed, Enum.Material.Neon)
	b:light(redGlowPart, Enum.NormalId.Bottom, 1.2, 10, Color3.fromRGB(255, 40, 30))

	return b:done()
end

return ExitSign
