--!strict
-- Commercial single door in hollow-metal frame with lever hardware, closer, and kickplate.
-- Reference: IMG_0376, IMG_0340 (grey steel / wood door, 8" CMU frame, closer, kickplate).
local Kit = require(script.Parent.Kit)

local DoorSingle = {
	kind = "door_single",
	size = Vector3.new(3.6, 7.2, 0.8),
}

local SteelGrey = Color3.fromRGB(175, 178, 180)
local DoorWood = Color3.fromRGB(190, 140, 84)
local FrameGrey = Color3.fromRGB(140, 142, 145)
local KickplateSilver = Color3.fromRGB(205, 208, 212)
local HardwareChrome = Color3.fromRGB(220, 222, 225)
local CloserDark = Color3.fromRGB(80, 84, 88)
local ReaderBlack = Color3.fromRGB(30, 32, 35)

function DoorSingle.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("DoorSingle", cf)
	local C = Kit.Color

	local isWood = opts and opts.material == "wood"
	local isGlass = opts and opts.glass == true
	local hasVision = opts and opts.vision == true

	local leafMaterial = if isGlass
		then Enum.Material.Glass
		elseif isWood then Enum.Material.Wood
		else Enum.Material.Metal
	local leafColor = if isGlass then Color3.fromRGB(198, 214, 216) elseif isWood then DoorWood else SteelGrey

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

	-- Floor threshold plate (aluminum saddle threshold)
	b:box(
		"Threshold",
		Vector3.new(doorW + 0.1, 0.03, d * 0.7),
		Kit.at(0, 0.015, 0),
		KickplateSilver,
		Enum.Material.Metal
	)

	-- 2. Door leaf (split into 3 segments for bounding checks: Lower, Middle "Door", Upper)
	local doorSegH = doorH / 3
	-- Lower leaf segment
	local lowerDoor = b:box(
		"Door_Lower",
		Vector3.new(doorW, doorSegH, doorThick),
		Kit.at(0, doorSegH / 2, doorZ),
		leafColor,
		leafMaterial,
		true
	)
	-- Middle leaf segment (named "Door" for DoorService)
	local mainDoor = b:box(
		"Door",
		Vector3.new(doorW, doorSegH, doorThick),
		Kit.at(0, doorSegH + doorSegH / 2, doorZ),
		leafColor,
		leafMaterial,
		true
	)
	-- Hinge anchor part child for DoorService
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
	local upperDoor = b:box(
		"Door_Upper",
		Vector3.new(doorW, doorSegH, doorThick),
		Kit.at(0, 2 * doorSegH + doorSegH / 2, doorZ),
		leafColor,
		leafMaterial,
		true
	)
	if isGlass then
		for _, leaf in { lowerDoor, mainDoor, upperDoor } do
			leaf.Material = Enum.Material.Glass
			leaf.Color = Color3.fromRGB(198, 214, 216)
			leaf.Transparency = 0.42
			leaf.Reflectance = 0.08
		end
	end

	-- 3. Vision lite option (narrow glass window insert in upper middle)
	if hasVision then
		local liteW, liteH = 0.6, 2.2
		local liteY = 4.8
		b:box("VisionGlass", Vector3.new(liteW, liteH, 0.02), Kit.at(0.4, liteY, doorZ), C.Glass, Enum.Material.Glass)
		-- Glazing frame beads
		b:box(
			"VisionFrameTop",
			Vector3.new(liteW + 0.08, 0.04, doorThick + 0.02),
			Kit.at(0.4, liteY + liteH / 2, doorZ),
			FrameGrey,
			Enum.Material.Metal
		)
		b:box(
			"VisionFrameBottom",
			Vector3.new(liteW + 0.08, 0.04, doorThick + 0.02),
			Kit.at(0.4, liteY - liteH / 2, doorZ),
			FrameGrey,
			Enum.Material.Metal
		)
		b:box(
			"VisionFrameLeft",
			Vector3.new(0.04, liteH, doorThick + 0.02),
			Kit.at(0.4 - liteW / 2 - 0.02, liteY, doorZ),
			FrameGrey,
			Enum.Material.Metal
		)
		b:box(
			"VisionFrameRight",
			Vector3.new(0.04, liteH, doorThick + 0.02),
			Kit.at(0.4 + liteW / 2 + 0.02, liteY, doorZ),
			FrameGrey,
			Enum.Material.Metal
		)
	end

	-- 4. Stainless steel kickplate at bottom
	b:box(
		"KickPlate_Front",
		Vector3.new(doorW - 0.08, 0.83, 0.01),
		Kit.at(0, 0.42, doorZ - doorThick / 2 - 0.03),
		KickplateSilver,
		Enum.Material.Metal
	)
	b:box(
		"KickPlate_Back",
		Vector3.new(doorW - 0.08, 0.83, 0.01),
		Kit.at(0, 0.42, doorZ + doorThick / 2 + 0.03),
		KickplateSilver,
		Enum.Material.Metal
	)

	-- 5. Butt hinges (3 ball-bearing hinges on left jamb)
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

	-- 6. Lockset & Lever hardware
	local lockY = 3.2
	local lockX = doorW / 2 - 0.35
	-- Front escutcheon plate
	b:box(
		"EscutcheonFront",
		Vector3.new(0.22, 0.8, 0.02),
		Kit.at(lockX, lockY, doorZ - doorThick / 2 - 0.01),
		KickplateSilver,
		Enum.Material.Metal
	)
	-- Front lever handle
	b:cyl(
		"LeverFrontStem",
		0.08,
		0.04,
		Kit.alongZ(lockX, lockY, doorZ - doorThick / 2 - 0.05),
		HardwareChrome,
		Enum.Material.Metal
	)
	b:box(
		"LeverFrontBar",
		Vector3.new(0.4, 0.05, 0.03),
		Kit.at(lockX - 0.15, lockY, doorZ - doorThick / 2 - 0.09),
		HardwareChrome,
		Enum.Material.Metal
	)

	-- Electronic access card reader / keypad above handle (from IMG_0376)
	b:box(
		"CardReader",
		Vector3.new(0.2, 0.45, 0.04),
		Kit.at(lockX, lockY + 0.75, doorZ - doorThick / 2 - 0.02),
		ReaderBlack,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"ReaderKeypad",
		Vector3.new(0.14, 0.25, 0.01),
		Kit.at(lockX, lockY + 0.8, doorZ - doorThick / 2 - 0.045),
		Color3.fromRGB(60, 64, 68),
		Enum.Material.SmoothPlastic
	)
	local statusDot = b:ball(
		"ReaderLED",
		0.03,
		Kit.at(lockX, lockY + 0.58, doorZ - doorThick / 2 - 0.045),
		Color3.fromRGB(40, 220, 60),
		Enum.Material.Neon
	)
	statusDot.CastShadow = false

	-- Rear push/pull hardware
	b:box(
		"EscutcheonRear",
		Vector3.new(0.22, 0.8, 0.02),
		Kit.at(lockX, lockY, doorZ + doorThick / 2 + 0.01),
		KickplateSilver,
		Enum.Material.Metal
	)
	b:cyl(
		"LeverRearStem",
		0.08,
		0.04,
		Kit.alongZ(lockX, lockY, doorZ + doorThick / 2 + 0.05),
		HardwareChrome,
		Enum.Material.Metal
	)
	b:box(
		"LeverRearBar",
		Vector3.new(0.4, 0.05, 0.03),
		Kit.at(lockX - 0.15, lockY, doorZ + doorThick / 2 + 0.09),
		HardwareChrome,
		Enum.Material.Metal
	)

	-- 7. Overhead hydraulic door closer (mounted on frame head)
	local closerY = doorH + 0.08
	b:box(
		"CloserBody",
		Vector3.new(0.9, 0.22, 0.2),
		Kit.at(-0.4, closerY, doorZ - 0.15),
		CloserDark,
		Enum.Material.Metal
	)
	-- Scissor arm
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

return DoorSingle
