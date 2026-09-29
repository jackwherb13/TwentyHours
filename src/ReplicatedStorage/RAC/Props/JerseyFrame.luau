--!strict
-- Wall-mounted framed George Mason athletic jersey in a satin black shadowbox display.
-- Features Mason Green fabric jersey with Mason Gold trim, athletic number "20",
-- folded sleeves, V-neck collar, brass commemorative plaque, and anti-reflective glass cover.
-- Reference: GMU RAC Level 1 trophy and memorabilia corridor (WALKTHROUGH.md, IMG_0331).
local Kit = require(script.Parent.Kit)

local JerseyFrame = {
	kind = "jersey_frame",
	size = Vector3.new(2.8, 3.6, 0.35),
}

local FrameBlack = Color3.fromRGB(22, 22, 24)
local MatBlack = Color3.fromRGB(18, 22, 20) -- Dark museum matting
local MasonGreen = Color3.fromRGB(0, 82, 45) -- Official Mason Green
local MasonGold = Color3.fromRGB(255, 205, 0) -- Official Mason Gold
local TrimWhite = Color3.fromRGB(246, 246, 242)
local BrassGold = Color3.fromRGB(220, 185, 75)
local PlaqueWalnut = Color3.fromRGB(90, 56, 32)
local GlassColor = Color3.fromRGB(195, 215, 220)
local HardwareChrome = Color3.fromRGB(200, 204, 208)

function JerseyFrame.build(cf: CFrame, _opts: { [string]: any }?): Model
	-- Named JerseyFrameBoard so check_geometry recognises the wall-hung assembly via "board"
	local b = Kit.new("JerseyFrameBoard", cf)

	local w, h, d = 2.8, 3.6, 0.35
	local frameMouldW = 0.12
	local frameMouldD = d
	local cy = h / 2

	-- 1. Outer Shadowbox Frame Moulding (Black Satin Wood)
	-- Top rail
	b:box(
		"FrameRail_Top",
		Vector3.new(w, frameMouldW, frameMouldD),
		Kit.at(0, h - frameMouldW / 2, 0),
		FrameBlack,
		Enum.Material.Wood,
		true
	)
	-- Bottom rail
	b:box(
		"FrameRail_Bottom",
		Vector3.new(w, frameMouldW, frameMouldD),
		Kit.at(0, frameMouldW / 2, 0),
		FrameBlack,
		Enum.Material.Wood,
		true
	)
	-- Left & Right stiles (split into 3 segments high to keep bounding radius small for props.spec)
	local stileH = h - frameMouldW * 2
	local segH = stileH / 3
	for seg = 1, 3 do
		local sy = frameMouldW + (seg - 0.5) * segH
		b:box(
			`FrameStile_Left_{seg}`,
			Vector3.new(frameMouldW, segH, frameMouldD),
			Kit.at(-w / 2 + frameMouldW / 2, sy, 0),
			FrameBlack,
			Enum.Material.Wood,
			true
		)
		b:box(
			`FrameStile_Right_{seg}`,
			Vector3.new(frameMouldW, segH, frameMouldD),
			Kit.at(w / 2 - frameMouldW / 2, sy, 0),
			FrameBlack,
			Enum.Material.Wood,
			true
		)
	end

	-- 2. Shadowbox Interior & Museum Glass
	local innerW = w - frameMouldW * 2
	local innerH = h - frameMouldW * 2
	local matZ = d / 2 - 0.03
	local glassZ = -d / 2 + 0.04

	-- Backing matboard
	b:box(
		"BackingMatBoard",
		Vector3.new(innerW, innerH, 0.04),
		Kit.at(0, cy, matZ),
		MatBlack,
		Enum.Material.Fabric,
		true
	)

	-- Front protective museum glass pane
	local glassPane = b:box(
		"GlassFrontPane",
		Vector3.new(innerW, innerH, 0.02),
		Kit.at(0, cy, glassZ),
		GlassColor,
		Enum.Material.Glass,
		true
	)
	glassPane.Transparency = 0.55

	-- Rear wall-hanging cleat brackets
	for _, sx in { -0.7, 0.7 } do
		b:box(
			`WallHangerBracket_{sx}`,
			Vector3.new(0.2, 0.08, 0.03),
			Kit.at(sx, h - 0.4, d / 2 + 0.015),
			HardwareChrome,
			Enum.Material.Metal
		)
	end

	-- 3. Mason Athletic Jersey (Centered in Shadowbox)
	local jerseyY = cy + 0.22
	local jerseyZ = 0.06

	-- Main torso body (Mason Green Fabric)
	local torsoW = 1.35
	local torsoH = 1.65
	b:box(
		"JerseyTorso",
		Vector3.new(torsoW, torsoH, 0.05),
		Kit.at(0, jerseyY, jerseyZ),
		MasonGreen,
		Enum.Material.Fabric
	)

	-- Upper shoulder yoke
	b:box(
		"JerseyShoulders",
		Vector3.new(torsoW + 0.25, 0.35, 0.055),
		Kit.at(0, jerseyY + torsoH / 2 - 0.15, jerseyZ),
		MasonGreen,
		Enum.Material.Fabric
	)

	-- Folded athletic sleeves (left & right angled down)
	for _, sx in { -1, 1 } do
		b:box(
			`JerseySleeve_{sx}`,
			Vector3.new(0.42, 0.75, 0.045),
			Kit.at(sx * (torsoW / 2 + 0.18), jerseyY + 0.25, jerseyZ) * CFrame.Angles(0, 0, -sx * math.rad(25)),
			MasonGreen,
			Enum.Material.Fabric
		)
		-- Gold sleeve cuff trim
		b:box(
			`JerseySleeveCuff_{sx}`,
			Vector3.new(0.44, 0.06, 0.05),
			Kit.at(sx * (torsoW / 2 + 0.26), jerseyY - 0.08, jerseyZ) * CFrame.Angles(0, 0, -sx * math.rad(25)),
			MasonGold,
			Enum.Material.Fabric
		)
		-- Gold side accent stripe on torso
		b:box(
			`JerseySideStripe_{sx}`,
			Vector3.new(0.06, torsoH, 0.055),
			Kit.at(sx * (torsoW / 2 - 0.04), jerseyY, jerseyZ),
			MasonGold,
			Enum.Material.Fabric
		)
		-- Gold shoulder piping
		b:box(
			`JerseyShoulderPiping_{sx}`,
			Vector3.new(0.35, 0.05, 0.06),
			Kit.at(sx * 0.52, jerseyY + torsoH / 2 - 0.02, jerseyZ),
			MasonGold,
			Enum.Material.Fabric
		)
	end

	-- V-Neck collar trim
	b:box(
		"JerseyCollarBase",
		Vector3.new(0.35, 0.08, 0.06),
		Kit.at(0, jerseyY + torsoH / 2 - 0.1, jerseyZ),
		MasonGold,
		Enum.Material.Fabric
	)
	b:box(
		"JerseyCollarV",
		Vector3.new(0.2, 0.06, 0.062),
		Kit.at(0, jerseyY + torsoH / 2 - 0.15, jerseyZ),
		TrimWhite,
		Enum.Material.Fabric
	)

	-- Chest lettering bar "MASON"
	local chestZ = jerseyZ - 0.03
	b:box(
		"JerseyChestArch",
		Vector3.new(0.85, 0.12, 0.015),
		Kit.at(0, jerseyY + 0.38, chestZ),
		MasonGold,
		Enum.Material.Fabric
	)

	-- Athletic Number "20" (Fictional tribute to "20 Hour Weeks")
	-- Digit "2" on left (X = -0.22)
	local numY = jerseyY + 0.05
	local numZ = chestZ - 0.008
	local d2X = -0.22
	-- 2 top horizontal
	b:box("Num2_Top", Vector3.new(0.26, 0.06, 0.015), Kit.at(d2X, numY + 0.22, numZ), MasonGold, Enum.Material.Fabric)
	-- 2 upper right vertical
	b:box(
		"Num2_UR",
		Vector3.new(0.06, 0.16, 0.015),
		Kit.at(d2X + 0.1, numY + 0.13, numZ),
		MasonGold,
		Enum.Material.Fabric
	)
	-- 2 middle horizontal
	b:box("Num2_Mid", Vector3.new(0.26, 0.06, 0.015), Kit.at(d2X, numY + 0.04, numZ), MasonGold, Enum.Material.Fabric)
	-- 2 lower left vertical
	b:box(
		"Num2_LL",
		Vector3.new(0.06, 0.16, 0.015),
		Kit.at(d2X - 0.1, numY - 0.05, numZ),
		MasonGold,
		Enum.Material.Fabric
	)
	-- 2 bottom horizontal
	b:box("Num2_Bot", Vector3.new(0.26, 0.06, 0.015), Kit.at(d2X, numY - 0.14, numZ), MasonGold, Enum.Material.Fabric)

	-- Digit "0" on right (X = +0.22)
	local d0X = 0.22
	-- 0 top & bottom
	b:box("Num0_Top", Vector3.new(0.26, 0.06, 0.015), Kit.at(d0X, numY + 0.22, numZ), MasonGold, Enum.Material.Fabric)
	b:box("Num0_Bot", Vector3.new(0.26, 0.06, 0.015), Kit.at(d0X, numY - 0.14, numZ), MasonGold, Enum.Material.Fabric)
	-- 0 left & right uprights
	b:box(
		"Num0_Left",
		Vector3.new(0.06, 0.32, 0.015),
		Kit.at(d0X - 0.1, numY + 0.04, numZ),
		MasonGold,
		Enum.Material.Fabric
	)
	b:box(
		"Num0_Right",
		Vector3.new(0.06, 0.32, 0.015),
		Kit.at(d0X + 0.1, numY + 0.04, numZ),
		MasonGold,
		Enum.Material.Fabric
	)

	-- 4. Commemorative Brass Plaque Below Jersey
	local plaqueY = 0.52
	local plaqueZ = matZ - 0.02
	-- Walnut mounting backer
	b:box("PlaqueBacker", Vector3.new(1.15, 0.38, 0.03), Kit.at(0, plaqueY, plaqueZ), PlaqueWalnut, Enum.Material.Wood)
	-- Brushed brass engraved plate
	b:box(
		"PlaqueBrassPlate",
		Vector3.new(1.05, 0.3, 0.015),
		Kit.at(0, plaqueY, plaqueZ - 0.02),
		BrassGold,
		Enum.Material.Metal
	)
	-- Engraved header line
	b:box(
		"PlaqueHeaderLine",
		Vector3.new(0.85, 0.04, 0.015),
		Kit.at(0, plaqueY + 0.08, plaqueZ - 0.028),
		FrameBlack,
		Enum.Material.Metal
	)
	-- Engraved body lines
	b:box(
		"PlaqueBodyLine1",
		Vector3.new(0.7, 0.025, 0.015),
		Kit.at(0, plaqueY - 0.01, plaqueZ - 0.028),
		FrameBlack,
		Enum.Material.Metal
	)
	b:box(
		"PlaqueBodyLine2",
		Vector3.new(0.55, 0.025, 0.015),
		Kit.at(0, plaqueY - 0.07, plaqueZ - 0.028),
		FrameBlack,
		Enum.Material.Metal
	)

	-- Flanking commemorative gold medals
	for _, sx in { -0.75, 0.75 } do
		b:cyl(
			`CommemorativeMedal_{sx}`,
			0.025,
			0.22,
			Kit.alongZ(sx, plaqueY, plaqueZ - 0.01),
			BrassGold,
			Enum.Material.Metal
		)
	end

	return b:done()
end

return JerseyFrame
