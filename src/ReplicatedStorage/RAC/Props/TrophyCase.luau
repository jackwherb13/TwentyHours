--!strict
-- Wall-length illuminated trophy display cabinet with oak base cabinet, sliding glass doors,
-- tempered glass shelves, integrated warm LED canopy strip lighting, and collegiate athletics trophies.
-- Reference: GMU RAC main Level 1 corridor trophy displays (WALKTHROUGH.md, IMG_0331).
-- opts.length (default 8 ft, range 4–24 ft) sets the cabinet width.
local Kit = require(script.Parent.Kit)

local TrophyCase = {
	kind = "trophy_case",
	size = Vector3.new(8.0, 7.0, 1.8),
}

local WoodBase = Color3.fromRGB(182, 140, 88) -- Oak / maple veneer
local WoodDark = Color3.fromRGB(135, 98, 58)
local ToeKickBlack = Color3.fromRGB(24, 25, 26)
local FrameGrey = Color3.fromRGB(140, 142, 145)
local HardwareChrome = Color3.fromRGB(220, 224, 228)
local GoldMetal = Color3.fromRGB(235, 185, 45) -- Trophy gold
local MarbleBase = Color3.fromRGB(42, 44, 46) -- Black marble pedestal
local GlassColor = Color3.fromRGB(195, 215, 220)
local PlaqueWood = Color3.fromRGB(115, 72, 40) -- Dark walnut plaque

local function optNum(opts: { [string]: any }?, key: string, default: number, lo: number, hi: number): number
	if opts ~= nil and type(opts[key]) == "number" then
		return math.clamp(opts[key] :: number, lo, hi)
	end
	return default
end

function TrophyCase.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("TrophyCabinet", cf)

	local length = optNum(opts, "length", 8.0, 4.0, 24.0)
	local h = 7.0
	local d = 1.8

	-- 1. Recessed Base Toe-Kick (sitting on floor Y = 0 to 0.25 ft)
	local kickH = 0.25
	local kickSetback = 0.12
	b:box(
		"ToeKickFront",
		Vector3.new(length - kickSetback * 2, kickH, 0.08),
		Kit.at(0, kickH / 2, -d / 2 + kickSetback),
		ToeKickBlack,
		Enum.Material.SmoothPlastic,
		true
	)
	for _, sx in { -1, 1 } do
		b:box(
			`ToeKickSide_{sx}`,
			Vector3.new(0.08, kickH, d - kickSetback - 0.05),
			Kit.at(sx * (length / 2 - kickSetback), kickH / 2, kickSetback / 2),
			ToeKickBlack,
			Enum.Material.SmoothPlastic,
			true
		)
	end

	-- 2. Lower Wood Base Cabinet (Y = 0.25 to 1.8 ft)
	local baseTopY = 1.8
	local baseH = baseTopY - kickH
	local baseCenterY = kickH + baseH / 2
	-- Main carcass body
	b:box(
		"BaseCabinetCarcass",
		Vector3.new(length, baseH - 0.08, d),
		Kit.at(0, baseCenterY - 0.04, 0),
		WoodBase,
		Enum.Material.Wood,
		true
	)
	-- Solid countertop / display bottom floor
	local counterThick = 0.08
	b:box(
		"DisplayCounterTop",
		Vector3.new(length, counterThick, d),
		Kit.at(0, baseTopY - counterThick / 2, 0),
		WoodBase,
		Enum.Material.Wood,
		true
	)

	-- Base cabinet sliding door panels on front (-Z)
	local numDoors = math.max(2, math.floor(length / 2.5 + 0.5))
	local doorW = length / numDoors
	for i = 1, numDoors do
		local dx = -length / 2 + (i - 0.5) * doorW
		local doorZ = -d / 2 - 0.015 - (i % 2) * 0.02
		b:box(
			`BaseDoor_{i}`,
			Vector3.new(doorW - 0.04, baseH - 0.16, 0.04),
			Kit.at(dx, baseCenterY - 0.04, doorZ),
			WoodDark,
			Enum.Material.Wood
		)
		-- Recessed finger pull
		b:box(
			`BaseDoorPull_{i}`,
			Vector3.new(0.08, 0.25, 0.02),
			Kit.at(dx + (if i % 2 == 1 then doorW * 0.3 else -doorW * 0.3), baseCenterY + 0.1, doorZ - 0.02),
			HardwareChrome,
			Enum.Material.Metal
		)
	end

	-- 3. Upper Display Case Enclosure (Y = 1.8 to 7.0 ft)
	local canopyH = 0.35
	local canopyY = h - canopyH / 2
	local glassH = h - baseTopY - canopyH
	local glassCenterY = baseTopY + glassH / 2

	-- Top canopy header
	b:box("CanopyTop", Vector3.new(length, canopyH, d), Kit.at(0, canopyY, 0), WoodBase, Enum.Material.Wood, true)

	-- Rear mirrored back wall (flush at +Z)
	b:box(
		"BackMirrorWall",
		Vector3.new(length - 0.1, glassH, 0.04),
		-- 0.05 ft further in than the carcass so the mirror misses the corridor wall by under 0.05 ft.
		Kit.at(0, glassCenterY, d / 2 - 0.08),
		GlassColor,
		Enum.Material.Glass,
		true
	)

	-- Left and right side glass end panels
	for _, sx in { -1, 1 } do
		local endGlass = b:box(
			`EndGlass_{sx}`,
			Vector3.new(0.04, glassH, d - 0.15),
			Kit.at(sx * (length / 2 - 0.03), glassCenterY, 0),
			GlassColor,
			Enum.Material.Glass,
			true
		)
		endGlass.Transparency = 0.5

		-- Vertical front corner mullion
		b:box(
			`CornerMullion_{sx}`,
			Vector3.new(0.08, glassH, 0.08),
			Kit.at(sx * (length / 2 - 0.04), glassCenterY, -d / 2 + 0.04),
			FrameGrey,
			Enum.Material.Metal,
			true
		)
	end

	-- Front sliding glass doors (two large bypassing panes)
	local halfLen = length / 2 + 0.1
	for _, sx in { -1, 1 } do
		local paneX = sx * (length / 4)
		local paneZ = -d / 2 + 0.04 + (if sx > 0 then 0.03 else 0.0)
		local frontGlass = b:box(
			`FrontGlassDoor_{sx}`,
			Vector3.new(halfLen, glassH - 0.06, 0.02),
			Kit.at(paneX, glassCenterY, paneZ),
			GlassColor,
			Enum.Material.Glass,
			true
		)
		frontGlass.Transparency = 0.55

		-- Ground glass finger pull / metal lock
		b:cyl(
			`GlassFingerPull_{sx}`,
			0.03,
			0.14,
			Kit.alongZ(paneX - sx * 0.8, glassCenterY - 0.4, paneZ - 0.015),
			HardwareChrome,
			Enum.Material.Metal
		)
	end

	-- 4. Tempered Glass Shelves & Chrome Standards
	local shelfY1 = baseTopY + glassH * 0.36 -- ~3.55 ft
	local shelfY2 = baseTopY + glassH * 0.70 -- ~5.20 ft
	local shelfD = d - 0.35

	for sIdx, sy in { shelfY1, shelfY2 } do
		local shelf = b:box(
			`DisplayShelf_Glass_{sIdx}`,
			Vector3.new(length - 0.16, 0.04, shelfD),
			Kit.at(0, sy, 0.05),
			GlassColor,
			Enum.Material.Glass,
			true
		)
		shelf.Transparency = 0.45
	end

	-- Vertical slotted shelf standards on rear wall
	local numStandards = math.max(3, math.floor(length / 2.2 + 0.5))
	for i = 1, numStandards do
		local stdX = -length / 2 + (i - 0.5) * (length / numStandards)
		b:box(
			`ShelfStandard_{i}`,
			Vector3.new(0.04, glassH - 0.1, 0.03),
			Kit.at(stdX, glassCenterY, d / 2 - 0.07),
			HardwareChrome,
			Enum.Material.Metal
		)
		-- Shelf support brackets at each tier
		for _, sy in { shelfY1, shelfY2 } do
			b:box(
				`ShelfBracket_{i}_{sy}`,
				Vector3.new(0.03, 0.08, 0.4),
				Kit.at(stdX, sy - 0.04, d / 2 - 0.28),
				HardwareChrome,
				Enum.Material.Metal
			)
		end
	end

	-- 5. Integrated LED Strip Lighting inside Canopy
	local ledStrip = b:box(
		"LED_Light_Bar",
		Vector3.new(length - 0.4, 0.04, 0.08),
		Kit.at(0, h - canopyH - 0.02, -0.2),
		Color3.fromRGB(255, 248, 230),
		Enum.Material.Neon
	)
	b:light(ledStrip, Enum.NormalId.Bottom, 1.2, 10, Color3.fromRGB(255, 245, 220))

	-- 6. Collegiate Trophies & Awards across the bays
	local numBays = math.max(2, math.floor(length / 2.4))
	local bayW = length / numBays

	for bIdx = 1, numBays do
		local bx = -length / 2 + (bIdx - 0.5) * bayW

		-- Tier 1 (on wood base counter Y = baseTopY):
		-- Large Championship Cup Trophy
		local t1BaseY = baseTopY + 0.08
		b:box(
			`TrophyBase_T1_{bIdx}`,
			Vector3.new(0.42, 0.16, 0.42),
			Kit.at(bx - 0.25, t1BaseY, 0.05),
			MarbleBase,
			Enum.Material.Metal
		)
		-- Brass engraved plate on base
		b:box(
			`TrophyPlate_T1_{bIdx}`,
			Vector3.new(0.3, 0.08, 0.015),
			Kit.at(bx - 0.25, t1BaseY, -0.17),
			GoldMetal,
			Enum.Material.Metal
		)
		-- Cup stem and chalice bowl
		b:cyl(
			`TrophyStem_T1_{bIdx}`,
			0.14,
			0.1,
			Kit.vertical(bx - 0.25, t1BaseY + 0.15, 0.05),
			GoldMetal,
			Enum.Material.Metal
		)
		b:cyl(
			`TrophyCup_T1_{bIdx}`,
			0.35,
			0.32,
			Kit.vertical(bx - 0.25, t1BaseY + 0.38, 0.05),
			GoldMetal,
			Enum.Material.Metal
		)
		b:ball(`TrophyFinial_T1_{bIdx}`, 0.12, Kit.at(bx - 0.25, t1BaseY + 0.58, 0.05), GoldMetal, Enum.Material.Metal)

		-- Walnut Championship Plaque
		b:box(
			`PlaqueWood_T1_{bIdx}`,
			Vector3.new(0.35, 0.45, 0.04),
			Kit.at(bx + 0.3, baseTopY + 0.24, 0.15) * CFrame.Angles(math.rad(-15), 0, 0),
			PlaqueWood,
			Enum.Material.Wood
		)
		b:box(
			`PlaqueBrass_T1_{bIdx}`,
			Vector3.new(0.28, 0.36, 0.015),
			Kit.at(bx + 0.3, baseTopY + 0.24, 0.12) * CFrame.Angles(math.rad(-15), 0, 0),
			GoldMetal,
			Enum.Material.Metal
		)

		-- Tier 2 (on Shelf 1 Y = shelfY1):
		-- Dual-Column Trophy
		local t2Y = shelfY1 + 0.02 + 0.05
		b:box(
			`TrophyBase_T2_{bIdx}`,
			Vector3.new(0.48, 0.1, 0.26),
			Kit.at(bx, t2Y, 0.05),
			MarbleBase,
			Enum.Material.Metal
		)
		-- Twin gold fluted columns
		for _, cx in { -0.15, 0.15 } do
			b:cyl(
				`TrophyCol_{bIdx}_{cx}`,
				0.52,
				0.06,
				Kit.vertical(bx + cx, t2Y + 0.31, 0.05),
				GoldMetal,
				Enum.Material.Metal
			)
		end
		-- Column cap beam
		b:box(
			`TrophyCap_T2_{bIdx}`,
			Vector3.new(0.44, 0.06, 0.22),
			Kit.at(bx, t2Y + 0.6, 0.05),
			MarbleBase,
			Enum.Material.Metal
		)
		-- Gold victory figure topper
		b:ball(`TrophyTopper_T2_{bIdx}`, 0.15, Kit.at(bx, t2Y + 0.72, 0.05), GoldMetal, Enum.Material.Metal)

		-- Tier 3 (on Shelf 2 Y = shelfY2):
		-- Classic Gold Cup
		local t3Y = shelfY2 + 0.02 + 0.05
		b:cyl(`TrophyPedestal_T3_{bIdx}`, 0.12, 0.28, Kit.vertical(bx, t3Y, 0.05), MarbleBase, Enum.Material.Metal)
		b:cyl(`TrophyBowl_T3_{bIdx}`, 0.28, 0.26, Kit.vertical(bx, t3Y + 0.2, 0.05), GoldMetal, Enum.Material.Metal)
		b:ball(`TrophyKnob_T3_{bIdx}`, 0.08, Kit.at(bx, t3Y + 0.36, 0.05), GoldMetal, Enum.Material.Metal)
	end

	return b:done()
end

return TrophyCase
