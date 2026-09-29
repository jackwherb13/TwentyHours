--!strict
-- Athletic training room treatment / taping table with green upholstered top,
-- solid wood base, lower storage shelf, elevating headrest, and exam paper roll dispenser.
-- Reference: GMU RAC Athletic Training Room (WALKTHROUGH.md).
local Kit = require(script.Parent.Kit)

local TrainingTable = {
	kind = "training_table",
	size = Vector3.new(2.6, 2.8, 6.5),
}

local TopGreen = Color3.fromRGB(0, 82, 45) -- Mason Green vinyl
local PipingGreen = Color3.fromRGB(0, 68, 36)
local WoodBase = Color3.fromRGB(182, 138, 86) -- Natural oak / maple
local WoodDark = Color3.fromRGB(148, 108, 65)
local HardwareChrome = Color3.fromRGB(215, 218, 222)
local PaperWhite = Color3.fromRGB(246, 246, 242)
local GlideBlack = Color3.fromRGB(28, 28, 30)
local TowelGreen = Color3.fromRGB(22, 92, 54)

function TrainingTable.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("TrainingTable", cf)

	local w, l = 2.5, 6.4
	local legThick = 0.22
	local legH = 2.25
	local legX = w / 2 - legThick / 2 - 0.05
	local legZ = l / 2 - legThick / 2 - 0.15

	-- 1. Base Legs and Leveler Glides
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local lx = sx * legX
			local lz = sz * legZ
			-- Leveler foot glide
			b:cyl(`Glide_{sx}_{sz}`, 0.05, 0.16, Kit.vertical(lx, 0.025, lz), GlideBlack, Enum.Material.Rubber)
			-- Wood leg
			b:box(
				`Leg_{sx}_{sz}`,
				Vector3.new(legThick, legH, legThick),
				Kit.at(lx, 0.05 + legH / 2, lz),
				WoodBase,
				Enum.Material.Wood,
				true
			)
			-- Leg bottom collar
			b:box(
				`LegCollar_{sx}_{sz}`,
				Vector3.new(legThick + 0.02, 0.06, legThick + 0.02),
				Kit.at(lx, 0.08, lz),
				WoodDark,
				Enum.Material.Wood
			)
		end
	end

	-- 2. Lower Storage Shelf & Stretchers
	local shelfY = 0.68
	local shelfThick = 0.08
	local shelfW = w - 0.2
	local shelfL = l - 0.7
	b:box(
		"LowerShelf",
		Vector3.new(shelfW, shelfThick, shelfL),
		Kit.at(0, shelfY, 0),
		WoodBase,
		Enum.Material.Wood,
		true
	)
	-- Shelf end lips / stretchers
	for _, sz in { -1, 1 } do
		b:box(
			`ShelfStretcher_Z{sz}`,
			Vector3.new(shelfW, 0.14, 0.08),
			Kit.at(0, shelfY + 0.07, sz * (shelfL / 2 - 0.04)),
			WoodDark,
			Enum.Material.Wood
		)
	end
	for _, sx in { -1, 1 } do
		b:box(
			`ShelfStretcher_X{sx}`,
			Vector3.new(0.08, 0.14, shelfL - 0.16),
			Kit.at(sx * (shelfW / 2 - 0.04), shelfY + 0.07, 0),
			WoodDark,
			Enum.Material.Wood
		)
	end

	-- 3. Upper Aprons / Sub-frame
	local apronY = 2.25
	local apronH = 0.2
	-- Long side aprons
	for _, sx in { -1, 1 } do
		b:box(
			`ApronSide_{sx}`,
			Vector3.new(0.08, apronH, l - 0.4),
			Kit.at(sx * legX, apronY, 0),
			WoodBase,
			Enum.Material.Wood,
			true
		)
	end
	-- End aprons
	for _, sz in { -1, 1 } do
		b:box(
			`ApronEnd_{sz}`,
			Vector3.new(w - 0.4, apronH, 0.08),
			Kit.at(0, apronY, sz * legZ),
			WoodBase,
			Enum.Material.Wood,
			true
		)
	end

	-- Plywood sub-top deck
	local deckY = 2.38
	b:box("SubDeck", Vector3.new(w - 0.05, 0.08, l - 0.05), Kit.at(0, deckY, 0), WoodDark, Enum.Material.Wood, true)

	-- 4. Upholstered Padded Top (Mason Green)
	local padThick = 0.32
	local padY = deckY + 0.04 + padThick / 2
	local splitZ = 0.95
	local mainPadLen = (l / 2 + splitZ) - 0.04
	local headPadLen = (l / 2 - splitZ) - 0.04

	-- Main body section (-Z side)
	local mainPadZ = -l / 2 + mainPadLen / 2
	b:box(
		"MainPad",
		Vector3.new(w, padThick, mainPadLen),
		Kit.at(0, padY, mainPadZ),
		TopGreen,
		Enum.Material.Leather,
		true
	)
	-- Piping trim for main pad
	b:box(
		"MainPadPiping_Front",
		Vector3.new(w + 0.02, 0.04, 0.04),
		Kit.at(0, padY + padThick / 2 - 0.02, -l / 2 + 0.02),
		PipingGreen,
		Enum.Material.Leather
	)

	-- Elevating head section (+Z side)
	local headPadZ = splitZ + 0.04 + headPadLen / 2
	b:box(
		"HeadPad",
		Vector3.new(w, padThick, headPadLen),
		Kit.at(0, padY, headPadZ),
		TopGreen,
		Enum.Material.Leather,
		true
	)
	-- Piping trim for head pad
	b:box(
		"HeadPadPiping_Back",
		Vector3.new(w + 0.02, 0.04, 0.04),
		Kit.at(0, padY + padThick / 2 - 0.02, l / 2 - 0.02),
		PipingGreen,
		Enum.Material.Leather
	)

	-- Chrome hinge mechanism plates at split
	for _, sx in { -0.85, 0.85 } do
		b:box(
			`HingePlate_{sx}`,
			Vector3.new(0.08, 0.1, 0.16),
			Kit.at(sx, deckY + 0.02, splitZ),
			HardwareChrome,
			Enum.Material.Metal
		)
		-- Tilt lift strut under headrest
		b:cyl(
			`TiltStrut_{sx}`,
			0.45,
			0.04,
			Kit.at(sx, deckY - 0.06, splitZ + 0.5) * CFrame.Angles(0, 0, math.rad(15)),
			HardwareChrome,
			Enum.Material.Metal
		)
	end

	-- 5. Sanitary Exam Paper Dispenser (Head End at +Z)
	local paperZ = l / 2 + 0.08
	local paperY = padY - 0.05
	-- Left & right chrome mounting brackets
	for _, sx in { -w / 2 + 0.12, w / 2 - 0.12 } do
		b:box(
			`PaperBracket_{sx}`,
			Vector3.new(0.04, 0.22, 0.16),
			Kit.at(sx, paperY, paperZ - 0.08),
			HardwareChrome,
			Enum.Material.Metal
		)
	end
	-- Paper roll cylinder
	b:cyl("PaperRoll", w - 0.45, 0.34, Kit.at(0, paperY, paperZ), PaperWhite, Enum.Material.SmoothPlastic)
	-- Spindle core rod
	b:cyl("PaperSpindle", w - 0.2, 0.04, Kit.at(0, paperY, paperZ), HardwareChrome, Enum.Material.Metal)
	-- Paper tear strap / guide across head pad
	b:box(
		"PaperTearStrap",
		Vector3.new(w - 0.35, 0.02, 0.05),
		Kit.at(0, padY + padThick / 2 + 0.015, l / 2 - 0.25),
		HardwareChrome,
		Enum.Material.Metal
	)
	-- Paper sheet strip extending forward
	b:box(
		"PaperSheet",
		Vector3.new(w - 0.5, 0.01, 1.2),
		Kit.at(0, padY + padThick / 2 + 0.01, l / 2 - 0.85),
		PaperWhite,
		Enum.Material.SmoothPlastic
	)

	-- 6. Accessories on lower shelf
	-- Folded athletic towels
	b:box(
		"TowelStack",
		Vector3.new(0.8, 0.22, 0.9),
		Kit.at(-0.4, shelfY + 0.15, -1.2),
		TowelGreen,
		Enum.Material.Fabric
	)
	-- Taping rolls
	for i = 1, 3 do
		b:cyl(
			`TapeRoll_{i}`,
			0.14,
			0.28,
			Kit.vertical(0.5, shelfY + 0.11, -1.0 + (i - 1) * 0.35),
			PaperWhite,
			Enum.Material.Fabric
		)
	end

	return b:done()
end

return TrainingTable
