--!strict
-- Commercial single door with integrated electronic digital keypad access lock,
-- heavy-duty stainless push/pull armor plate, tubular pull handle, closer, and kickplate.
-- Reuses the architectural hollow-metal frame from DoorSingle for 1:1 consistency.
-- Reference: GMU RAC Men's Volleyball Locker Room entrance (WALKTHROUGH.md, IMG_0376).
-- Fictional lock code: 15234.
local Kit = require(script.Parent.Kit)

local KeypadDoor = {
	kind = "keypad_door",
	size = Vector3.new(3.6, 7.2, 0.8),
}

local BeigeDoor = Color3.fromRGB(182, 178, 170) -- Warm institutional beige from IMG_0376
local SteelGrey = Color3.fromRGB(175, 178, 180)
local DoorWood = Color3.fromRGB(190, 140, 84)
local FrameGrey = Color3.fromRGB(140, 142, 145)
local KickplateSilver = Color3.fromRGB(205, 208, 212)
local HardwareChrome = Color3.fromRGB(220, 222, 225)
local CloserDark = Color3.fromRGB(80, 84, 88)
local KeypadHousing = Color3.fromRGB(70, 74, 78)
local ButtonBlack = Color3.fromRGB(28, 30, 32)
local KeypadScreen = Color3.fromRGB(16, 22, 24)

function KeypadDoor.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("KeypadDoor", cf)

	local isWood = opts and opts.material == "wood"
	local isGrey = opts and opts.material == "steel"
	local leafColor = if isWood then DoorWood elseif isGrey then SteelGrey else BeigeDoor
	local leafMaterial = if isWood then Enum.Material.Wood else Enum.Material.Metal

	local w, h, d = 3.6, 7.2, 0.8
	local frameThick = 0.2
	local doorW = 3.0
	local doorH = 7.0
	local doorThick = 0.15
	local doorZ = 0.05

	-- 1. Hollow-metal door frame (3 segments high to keep bounding radius small)
	local segH = (h - frameThick) / 3
	for seg = 1, 3 do
		local sy = (seg - 0.5) * segH
		-- Left jamb
		b:box(
			`JambLeft_{seg}`,
			Vector3.new(frameThick, segH, d),
			Kit.at(-w / 2 + frameThick / 2, sy, 0),
			FrameGrey,
			Enum.Material.Metal,
			true
		)
		-- Right jamb
		b:box(
			`JambRight_{seg}`,
			Vector3.new(frameThick, segH, d),
			Kit.at(w / 2 - frameThick / 2, sy, 0),
			FrameGrey,
			Enum.Material.Metal,
			true
		)
		-- Door stop molding (interior frame stop)
		b:box(
			`DoorStopLeft_{seg}`,
			Vector3.new(0.06, segH, 0.08),
			Kit.at(-doorW / 2 + 0.03, sy, doorZ + doorThick / 2 + 0.04),
			FrameGrey,
			Enum.Material.Metal
		)
		b:box(
			`DoorStopRight_{seg}`,
			Vector3.new(0.06, segH, 0.08),
			Kit.at(doorW / 2 - 0.03, sy, doorZ + doorThick / 2 + 0.04),
			FrameGrey,
			Enum.Material.Metal
		)
	end

	-- Head frame (header)
	b:box(
		"FrameHeader",
		Vector3.new(w, frameThick, d),
		Kit.at(0, h - frameThick / 2, 0),
		FrameGrey,
		Enum.Material.Metal,
		true
	)
	b:box(
		"DoorStopHead",
		Vector3.new(doorW, 0.06, 0.08),
		Kit.at(0, doorH - 0.03, doorZ + doorThick / 2 + 0.04),
		FrameGrey,
		Enum.Material.Metal
	)

	-- Floor threshold saddle plate
	b:box(
		"Threshold",
		Vector3.new(doorW + 0.1, 0.03, d * 0.7),
		Kit.at(0, 0.015, 0),
		KickplateSilver,
		Enum.Material.Metal
	)

	-- 2. Door leaf (split into 3 segments for bounding checks: Lower, Middle "Door", Upper)
	local doorSegH = doorH / 3
	b:box(
		"Door_Lower",
		Vector3.new(doorW, doorSegH, doorThick),
		Kit.at(0, doorSegH / 2, doorZ),
		leafColor,
		leafMaterial,
		true
	)
	-- Middle leaf segment (named "Door" with Hinge child for DoorService compatibility)
	local mainDoor = b:box(
		"Door",
		Vector3.new(doorW, doorSegH, doorThick),
		Kit.at(0, doorSegH + doorSegH / 2, doorZ),
		leafColor,
		leafMaterial,
		true
	)
	local hingePart = b:cyl(
		"Hinge",
		doorSegH * 0.9,
		0.04,
		Kit.vertical(-doorW / 2 + 0.02, doorSegH + doorSegH / 2, doorZ),
		HardwareChrome,
		Enum.Material.Metal
	)
	hingePart.Parent = mainDoor

	-- Upper leaf segment
	b:box(
		"Door_Upper",
		Vector3.new(doorW, doorSegH, doorThick),
		Kit.at(0, 2 * doorSegH + doorSegH / 2, doorZ),
		leafColor,
		leafMaterial,
		true
	)

	-- 3. Stainless steel kickplates at bottom
	b:box(
		"KickPlate_Front",
		Vector3.new(doorW - 0.08, 0.83, 0.015),
		Kit.at(0, 0.42, doorZ - doorThick / 2 - 0.03),
		KickplateSilver,
		Enum.Material.Metal
	)
	b:box(
		"KickPlate_Back",
		Vector3.new(doorW - 0.08, 0.83, 0.015),
		Kit.at(0, 0.42, doorZ + doorThick / 2 + 0.03),
		KickplateSilver,
		Enum.Material.Metal
	)

	-- 4. Butt hinges (3 ball-bearing hinges on left jamb)
	for _, hy in { 0.8, 3.5, 6.2 } do
		b:box(
			`HingeLeaf_{hy}`,
			Vector3.new(0.02, 0.35, 0.06),
			Kit.at(-doorW / 2 + 0.01, hy, doorZ - doorThick / 4),
			HardwareChrome,
			Enum.Material.Metal
		)
		b:cyl(
			`HingePin_{hy}`,
			0.38,
			0.04,
			Kit.vertical(-doorW / 2 + 0.02, hy, doorZ - doorThick / 2),
			HardwareChrome,
			Enum.Material.Metal
		)
	end

	-- 5. Heavy-Duty Latch-Side Hardware (from IMG_0376)
	local latchX = doorW / 2 - 0.38
	local pullY = 2.85
	local frontFaceZ = doorZ - doorThick / 2

	-- Large stainless push/pull armor plate on latch side
	local plateH = 1.45
	local plateW = 0.65
	b:box(
		"ArmorPlate_Front",
		Vector3.new(plateW, plateH, 0.02),
		Kit.at(latchX, pullY, frontFaceZ - 0.01),
		KickplateSilver,
		Enum.Material.Metal
	)

	-- Tubular vertical stainless pull bar handle mounted on armor plate
	b:cyl(
		"PullHandleBar",
		1.0,
		0.06,
		Kit.vertical(latchX, pullY, frontFaceZ - 0.1),
		HardwareChrome,
		Enum.Material.Metal
	)
	-- Pull bar mounting standoffs
	for _, sy in { -0.42, 0.42 } do
		b:cyl(
			`PullStandoff_{sy}`,
			0.08,
			0.04,
			Kit.alongZ(latchX, pullY + sy, frontFaceZ - 0.05),
			HardwareChrome,
			Enum.Material.Metal
		)
	end

	-- 6. Commercial Electronic Digital Keypad Lock (mounted directly above armor plate at Y = 4.25 ft)
	local keypadY = 4.22
	local keypadZ = frontFaceZ - 0.035
	local lockW, lockH = 0.28, 0.82

	-- Keypad brushed metal housing
	b:box(
		"KeypadHousing",
		Vector3.new(lockW, lockH, 0.05),
		Kit.at(latchX, keypadY, keypadZ),
		KeypadHousing,
		Enum.Material.Metal
	)
	-- Keypad beveled face plate
	b:box(
		"KeypadBevelPlate",
		Vector3.new(lockW - 0.04, lockH - 0.06, 0.02),
		Kit.at(latchX, keypadY, keypadZ - 0.026),
		ButtonBlack,
		Enum.Material.SmoothPlastic
	)

	-- Digital status LCD screen at top of keypad
	b:box(
		"KeypadScreen",
		Vector3.new(0.18, 0.08, 0.015),
		Kit.at(latchX, keypadY + 0.28, keypadZ - 0.03),
		KeypadScreen,
		Enum.Material.SmoothPlastic
	)

	-- Bi-Color Status LEDs (Red & Green)
	local ledGreen = b:ball(
		"KeypadLED_Green",
		0.03,
		Kit.at(latchX - 0.06, keypadY + 0.35, keypadZ - 0.035),
		Color3.fromRGB(40, 220, 60),
		Enum.Material.Neon
	)
	ledGreen.CastShadow = false
	local ledRed = b:ball(
		"KeypadLED_Red",
		0.03,
		Kit.at(latchX + 0.06, keypadY + 0.35, keypadZ - 0.035),
		Color3.fromRGB(220, 40, 30),
		Enum.Material.Neon
	)
	ledRed.CastShadow = false

	-- 12-Key Numeric Keypad Matrix (Rows 1-4, Cols 1-3)
	-- Represents keys 1-9, *, 0, #
	local btnW, btnH = 0.045, 0.045
	local btnSpacingX, btnSpacingY = 0.065, 0.065
	for row = 1, 4 do
		for col = 1, 3 do
			local bx = latchX + (col - 2) * btnSpacingX
			local by = (keypadY + 0.18) - (row - 1) * btnSpacingY
			b:box(
				`KeypadBtn_{row}_{col}`,
				Vector3.new(btnW, btnH, 0.015),
				Kit.at(bx, by, keypadZ - 0.035),
				HardwareChrome,
				Enum.Material.Metal
			)
		end
	end

	-- Mechanical Key Override Cylinder at bottom of keypad unit
	b:cyl(
		"KeyOverrideCylinder",
		0.025,
		0.06,
		Kit.alongZ(latchX, keypadY - 0.3, keypadZ - 0.03),
		HardwareChrome,
		Enum.Material.Metal
	)

	-- 7. Rear (Interior) Door Hardware
	local rearFaceZ = doorZ + doorThick / 2
	-- Rear stainless escutcheon plate
	b:box(
		"EscutcheonRear",
		Vector3.new(0.24, 0.9, 0.02),
		Kit.at(latchX, pullY + 0.3, rearFaceZ + 0.01),
		KickplateSilver,
		Enum.Material.Metal
	)
	-- Rear ADA lever handle
	b:cyl(
		"LeverRearStem",
		0.08,
		0.04,
		Kit.alongZ(latchX, pullY + 0.3, rearFaceZ + 0.05),
		HardwareChrome,
		Enum.Material.Metal
	)
	b:box(
		"LeverRearBar",
		Vector3.new(0.4, 0.05, 0.03),
		Kit.at(latchX - 0.15, pullY + 0.3, rearFaceZ + 0.09),
		HardwareChrome,
		Enum.Material.Metal
	)

	-- 8. Overhead hydraulic door closer (mounted on frame head)
	local closerY = doorH + 0.08
	b:box(
		"CloserBody",
		Vector3.new(0.9, 0.22, 0.2),
		Kit.at(-0.4, closerY, doorZ - 0.15),
		CloserDark,
		Enum.Material.Metal
	)
	b:box(
		"CloserArm1",
		Vector3.new(0.7, 0.04, 0.03),
		Kit.at(-0.15, closerY - 0.06, doorZ - 0.1) * CFrame.Angles(0, math.rad(25), 0),
		CloserDark,
		Enum.Material.Metal
	)
	b:box(
		"CloserArm2",
		Vector3.new(0.6, 0.04, 0.03),
		Kit.at(0.25, closerY - 0.06, doorZ - 0.05) * CFrame.Angles(0, math.rad(-25), 0),
		CloserDark,
		Enum.Material.Metal
	)
	b:box(
		"CloserShoe",
		Vector3.new(0.2, 0.04, 0.08),
		Kit.at(0.45, doorH - 0.02, doorZ - doorThick / 2 - 0.01),
		CloserDark,
		Enum.Material.Metal
	)

	return b:done()
end

return KeypadDoor
