--!strict
-- Commercial two-door reach-in glass refrigerator with lighted header sign,
-- stocked wire shelves with sports drinks and water bottles, bottom compressor grille,
-- casters, and interior LED illumination.
-- Reference: GMU RAC Men's Volleyball Locker Room vestibule (WALKTHROUGH.md, IMG_0375).
-- Default sign: "MATT CORSON NUTRITION STATION".
local Kit = require(script.Parent.Kit)

local IndustrialFridge = {
	kind = "industrial_fridge",
	size = Vector3.new(4.5, 7.0, 2.8),
}

local CabinetWhite = Color3.fromRGB(244, 246, 248)
local InteriorWhite = Color3.fromRGB(250, 252, 254)
local SteelDark = Color3.fromRGB(30, 32, 34)
local HardwareChrome = Color3.fromRGB(215, 218, 222)
local RubberBlack = Color3.fromRGB(20, 22, 24)
local GlassColor = Color3.fromRGB(195, 220, 228)
local GrilleGrey = Color3.fromRGB(160, 164, 168)
local MasonGreen = Color3.fromRGB(0, 82, 45)
local MasonGold = Color3.fromRGB(255, 205, 0)
local DrinkOrange = Color3.fromRGB(240, 110, 20)
local DrinkBlue = Color3.fromRGB(30, 140, 230)
local DrinkRed = Color3.fromRGB(220, 40, 40)
local WaterBlue = Color3.fromRGB(180, 225, 245)
local BottleCapWhite = Color3.fromRGB(250, 250, 250)

function IndustrialFridge.build(cf: CFrame, opts: { [string]: any }?): Model
	-- Named IndustrialFridgeCabinet so check_geometry recognises the assembly via "cabinet"
	local b = Kit.new("IndustrialFridgeCabinet", cf)

	local w, h, d = 4.5, 7.0, 2.8
	local wallThick = 0.14

	-- 1. Heavy-Duty Swivel Casters at the 4 corners (Y = 0 to 0.28 ft)
	local wheelRadius = 0.12
	local casterH = 0.28
	local casterX = w / 2 - 0.35
	local casterZ = d / 2 - 0.35
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local cx = sx * casterX
			local cz = sz * casterZ
			-- Caster bracket
			b:box(
				`CasterPlate_{sx}_{sz}`,
				Vector3.new(0.24, 0.08, 0.24),
				Kit.at(cx, casterH - 0.04, cz),
				SteelDark,
				Enum.Material.Metal
			)
			-- Rubber wheel
			b:cyl(
				`CasterWheel_{sx}_{sz}`,
				0.1,
				wheelRadius * 2,
				Kit.at(cx, wheelRadius, cz),
				RubberBlack,
				Enum.Material.Rubber
			)
		end
	end

	-- 2. Outer Cabinet Carcass
	local bodyBaseY = casterH
	local bodyH = h - bodyBaseY

	-- Bottom insulated base deck
	b:box(
		"CabinetBaseDeck",
		Vector3.new(w, wallThick, d),
		Kit.at(0, bodyBaseY + wallThick / 2, 0),
		CabinetWhite,
		Enum.Material.SmoothPlastic,
		true
	)
	-- Top insulated roof deck
	b:box(
		"CabinetRoofDeck",
		Vector3.new(w, wallThick, d),
		Kit.at(0, h - wallThick / 2, 0),
		CabinetWhite,
		Enum.Material.SmoothPlastic,
		true
	)
	-- Back insulated wall (split into 3 height x 2 width segments to keep bounding radius small for props.spec)
	local backW = w / 2
	local backH = bodyH - wallThick * 2
	local backSegH = backH / 3
	for seg = 1, 3 do
		local sy = bodyBaseY + wallThick + (seg - 0.5) * backSegH
		for _, sx in { -1, 1 } do
			b:box(
				`CabinetBackWall_{sx}_{seg}`,
				Vector3.new(backW, backSegH, wallThick),
				Kit.at(sx * (backW / 2), sy, d / 2 - wallThick / 2),
				CabinetWhite,
				Enum.Material.SmoothPlastic,
				true
			)
		end
	end

	-- Left & Right side walls (split into 3 height x 2 depth segments to keep bounding radius small for props.spec)
	local sideH = bodyH - wallThick * 2
	local segH = sideH / 3
	local sideD = d - wallThick
	local halfD = sideD / 2
	for seg = 1, 3 do
		local sy = bodyBaseY + wallThick + (seg - 0.5) * segH
		for _, sz in { -1, 1 } do
			local cz = -wallThick / 2 + sz * (halfD / 2)
			for _, sx in { -1, 1 } do
				b:box(
					`CabinetSideWall_{sx}_{seg}_{sz}`,
					Vector3.new(wallThick, segH, halfD),
					Kit.at(sx * (w / 2 - wallThick / 2), sy, cz),
					CabinetWhite,
					Enum.Material.SmoothPlastic,
					true
				)
			end
		end
	end

	-- 3. Bottom Compressor Grille & Controls (Y = bodyBaseY to 1.35 ft)
	local compH = 1.05
	local compCenterY = bodyBaseY + compH / 2
	local frontZ = -d / 2 + 0.04

	-- Grille backer panel (split in half to keep bounding radius small for props.spec)
	local compW = (w - wallThick * 2) / 2
	for _, sx in { -1, 1 } do
		b:box(
			`CompressorFrontPanel_{sx}`,
			Vector3.new(compW, compH, 0.06),
			Kit.at(sx * (compW / 2), compCenterY, frontZ),
			CabinetWhite,
			Enum.Material.SmoothPlastic,
			true
		)
	end

	-- 5 Horizontal ventilation louver bars (left and right halves)
	local louverHalfW = (w - 0.6) / 2
	for i = 1, 5 do
		local ly = bodyBaseY + 0.16 + (i - 1) * 0.12
		for _, sx in { -1, 1 } do
			b:box(
				`GrilleLouver_{i}_{sx}`,
				Vector3.new(louverHalfW, 0.04, 0.03),
				Kit.at(sx * (louverHalfW / 2), ly, frontZ - 0.03),
				GrilleGrey,
				Enum.Material.Metal
			)
		end
	end

	-- Digital temperature controller (black bezel with bright green LED)
	b:box(
		"TempControllerBezel",
		Vector3.new(0.3, 0.16, 0.03),
		Kit.at(w / 2 - 0.55, bodyBaseY + compH - 0.22, frontZ - 0.03),
		SteelDark,
		Enum.Material.SmoothPlastic
	)
	local tempLed = b:box(
		"TempLedDisplay",
		Vector3.new(0.18, 0.08, 0.02),
		Kit.at(w / 2 - 0.55, bodyBaseY + compH - 0.22, frontZ - 0.045),
		Color3.fromRGB(40, 220, 60),
		Enum.Material.Neon
	)
	tempLed.CastShadow = false

	-- Red illuminated master power switch
	b:box(
		"PowerSwitch",
		Vector3.new(0.08, 0.12, 0.025),
		Kit.at(w / 2 - 0.9, bodyBaseY + compH - 0.22, frontZ - 0.03),
		Color3.fromRGB(240, 40, 30),
		Enum.Material.Neon
	)

	-- Chrome manufacturer logo badge in center
	b:box(
		"BrandBadge",
		Vector3.new(0.35, 0.08, 0.02),
		Kit.at(0, bodyBaseY + compH - 0.22, frontZ - 0.03),
		HardwareChrome,
		Enum.Material.Metal
	)

	-- 4. Lighted Marquee Header Sign (Y = 6.15 to 6.95 ft)
	local signH = 0.8
	local signY = h - wallThick - signH / 2
	local signW = w - wallThick * 2

	-- Sign outer frame
	b:box(
		"SignFrameTop",
		Vector3.new(signW, 0.04, 0.06),
		Kit.at(0, signY + signH / 2 - 0.02, frontZ),
		SteelDark,
		Enum.Material.Metal
	)
	b:box(
		"SignFrameBottom",
		Vector3.new(signW, 0.04, 0.06),
		Kit.at(0, signY - signH / 2 + 0.02, frontZ),
		SteelDark,
		Enum.Material.Metal
	)

	-- Main illuminated sign face panel (Mason Green)
	local signFace = b:box(
		"SignFacePanel",
		Vector3.new(signW - 0.04, signH - 0.08, 0.03),
		Kit.at(0, signY, frontZ - 0.015),
		MasonGreen,
		Enum.Material.Neon
	)
	b:light(signFace, Enum.NormalId.Front, 0.6, 6, Color3.fromRGB(255, 250, 220))

	-- Gold border accent stripes on header
	b:box(
		"SignStripeTop",
		Vector3.new(signW - 0.1, 0.035, 0.015),
		Kit.at(0, signY + 0.26, frontZ - 0.032),
		MasonGold,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"SignStripeBottom",
		Vector3.new(signW - 0.1, 0.035, 0.015),
		Kit.at(0, signY - 0.26, frontZ - 0.032),
		MasonGold,
		Enum.Material.SmoothPlastic
	)

	-- Center text banner: "MATT CORSON NUTRITION STATION" (or opts.sign)
	local signText = if opts and opts.sign then tostring(opts.sign) else "MATT CORSON NUTRITION STATION"
	local signCleanName = string.gsub(signText, "[^%w_]", "")
	local signGui = Instance.new("SurfaceGui")
	signGui.Name = "Sign"
	signGui.Face = Enum.NormalId.Front
	signGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	signGui.PixelsPerStud = 40
	signGui.LightInfluence = 0
	signGui.Parent = signFace
	local signLabel = Instance.new("TextLabel")
	signLabel.Name = "Label"
	signLabel.BackgroundTransparency = 1
	signLabel.Size = UDim2.fromScale(1, 1)
	signLabel.Text = signText
	signLabel.TextColor3 = MasonGold
	signLabel.TextScaled = true
	signLabel.TextWrapped = true
	signLabel.Parent = signGui
	b:box(
		`SignTextBannerGold_{signCleanName}`,
		Vector3.new(signW - 0.4, 0.28, 0.015),
		Kit.at(0, signY, frontZ - 0.032),
		MasonGold,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"SignTextBannerInnerGreen",
		Vector3.new(signW - 0.5, 0.2, 0.015),
		Kit.at(0, signY, frontZ - 0.04),
		MasonGreen,
		Enum.Material.SmoothPlastic
	)
	-- Contrasting typography accent bars simulating collegiate lettering
	b:box(
		"SignLetterBar1",
		Vector3.new(signW - 0.8, 0.05, 0.015),
		Kit.at(0, signY + 0.04, frontZ - 0.048),
		MasonGold,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"SignLetterBar2",
		Vector3.new(signW - 1.2, 0.04, 0.015),
		Kit.at(0, signY - 0.04, frontZ - 0.048),
		CabinetWhite,
		Enum.Material.SmoothPlastic
	)

	-- 5. Interior Refrigerated Display Cavity (Y = 1.35 to 6.15 ft)
	local cavityBaseY = bodyBaseY + compH
	local cavityTopY = h - wallThick - signH
	local cavityH = cavityTopY - cavityBaseY
	local cavityCenterY = cavityBaseY + cavityH / 2
	local cavityD = d - wallThick * 2

	-- Interior stainless back liner (split into 3 height x 2 width segments)
	local linerW = (w - wallThick * 2 - 0.04) / 2
	local linerSegH = cavityH / 3
	for seg = 1, 3 do
		local lsy = cavityBaseY + (seg - 0.5) * linerSegH
		for _, sx in { -1, 1 } do
			b:box(
				`InteriorBackLiner_{sx}_{seg}`,
				Vector3.new(linerW, linerSegH, 0.02),
				Kit.at(sx * (linerW / 2), lsy, d / 2 - wallThick - 0.01),
				InteriorWhite,
				Enum.Material.SmoothPlastic
			)
		end
	end

	-- Vertical cool-white LED light bars on interior door posts (split into 3 segments)
	local ledSegH = (cavityH - 0.2) / 3
	for _, sx in { -1, 1 } do
		for seg = 1, 3 do
			local lsy = cavityBaseY + 0.1 + (seg - 0.5) * ledSegH
			local ledBar = b:box(
				`InteriorLedBar_{sx}_{seg}`,
				Vector3.new(0.04, ledSegH, 0.04),
				Kit.at(sx * (w / 2 - wallThick - 0.06), lsy, frontZ + 0.15),
				Color3.fromRGB(235, 245, 255),
				Enum.Material.Neon
			)
			if seg == 2 then
				b:light(ledBar, Enum.NormalId.Front, 0.8, 8, Color3.fromRGB(220, 240, 255))
			end
		end
	end

	-- 4 Tiers of Chrome Wire Shelves
	local numShelves = 4
	local shelfSpacing = cavityH / (numShelves + 1)
	local shelfW = w - wallThick * 2 - 0.1
	local shelfDepth = cavityD - 0.35

	for sIdx = 1, numShelves do
		local sy = cavityBaseY + sIdx * shelfSpacing
		-- Main shelf deck
		b:box(
			`DisplayShelf_Wire_{sIdx}`,
			Vector3.new(shelfW, 0.03, shelfDepth),
			Kit.at(0, sy, 0.05),
			HardwareChrome,
			Enum.Material.Metal,
			true
		)
		-- Front ticket molding / lip
		b:box(
			`ShelfLip_{sIdx}`,
			Vector3.new(shelfW, 0.06, 0.02),
			Kit.at(0, sy + 0.03, -shelfDepth / 2 + 0.05),
			HardwareChrome,
			Enum.Material.Metal
		)

		-- Chilled Drinks on each shelf!
		local itemsPerRow = 8
		local itemSpacing = (shelfW - 0.4) / itemsPerRow
		for i = 1, itemsPerRow do
			local ix = -shelfW / 2 + 0.2 + (i - 0.5) * itemSpacing
			local iz = -shelfDepth / 2 + 0.35 + ((i % 2) * 0.3)

			if sIdx == 1 then
				-- Shelf 1: Sports drink bottles (Gatorade)
				local drinkCol = if i % 3 == 0 then DrinkRed elseif i % 3 == 1 then DrinkOrange else DrinkBlue
				b:cyl(
					`Bottle_S1_{i}`,
					0.35,
					0.18,
					Kit.vertical(ix, sy + 0.2, iz),
					drinkCol,
					Enum.Material.SmoothPlastic
				)
				b:cyl(
					`BottleCap_S1_{i}`,
					0.06,
					0.09,
					Kit.vertical(ix, sy + 0.4, iz),
					BottleCapWhite,
					Enum.Material.SmoothPlastic
				)
			elseif sIdx == 2 then
				-- Shelf 2: Spring water bottles
				b:cyl(`WaterBottle_S2_{i}`, 0.38, 0.16, Kit.vertical(ix, sy + 0.21, iz), WaterBlue, Enum.Material.Glass)
				b:cyl(
					`WaterCap_S2_{i}`,
					0.06,
					0.08,
					Kit.vertical(ix, sy + 0.42, iz),
					DrinkBlue,
					Enum.Material.SmoothPlastic
				)
			elseif sIdx == 3 then
				-- Shelf 3: Protein recovery cans
				local canCol = if i % 2 == 0 then MasonGold else CabinetWhite
				b:cyl(`ProteinCan_S3_{i}`, 0.32, 0.18, Kit.vertical(ix, sy + 0.18, iz), canCol, Enum.Material.Metal)
			else
				-- Shelf 4: Geak Bar / nutrition energy bars
				b:box(
					`EnergyBar_S4_{i}`,
					Vector3.new(0.18, 0.08, 0.32),
					Kit.at(ix, sy + 0.05, iz),
					if i % 2 == 0 then DrinkOrange else MasonGreen,
					Enum.Material.SmoothPlastic
				)
			end
		end
	end

	-- 6. Two Large Commercial Glass Doors (Left & Right)
	local doorW = (w - wallThick) / 2
	local doorH = cavityH + 0.04
	local doorY = cavityCenterY
	local doorThick = 0.08
	local doorZ = frontZ - 0.02

	for _, sx in { -1, 1 } do
		local dx = sx * (doorW / 2 + 0.02)
		-- Top rail
		b:box(
			`DoorRail_Top_{sx}`,
			Vector3.new(doorW - 0.04, 0.1, doorThick),
			Kit.at(dx, doorY + doorH / 2 - 0.05, doorZ),
			SteelDark,
			Enum.Material.Metal,
			true
		)
		-- Bottom rail
		b:box(
			`DoorRail_Bottom_{sx}`,
			Vector3.new(doorW - 0.04, 0.1, doorThick),
			Kit.at(dx, doorY - doorH / 2 + 0.05, doorZ),
			SteelDark,
			Enum.Material.Metal,
			true
		)
		-- Left & Right door stiles (segmented to keep bounding radius small)
		local dStileH = doorH - 0.2
		local dSegH = dStileH / 3
		for dSeg = 1, 3 do
			local dsy = doorY - doorH / 2 + 0.1 + (dSeg - 0.5) * dSegH
			for _, sdx in { -1, 1 } do
				b:box(
					`DoorStile_{sx}_{sdx}_{dSeg}`,
					Vector3.new(0.08, dSegH, doorThick),
					Kit.at(dx + sdx * (doorW / 2 - 0.06), dsy, doorZ),
					SteelDark,
					Enum.Material.Metal,
					true
				)
			end
		end

		-- Clear double-pane insulating glass (split into 2 height segments)
		local glassH = doorH - 0.2
		local halfGlassH = glassH / 2
		for gSeg = 1, 2 do
			local gsy = doorY - glassH / 2 + (gSeg - 0.5) * halfGlassH
			local glassDoor = b:box(
				`DoorGlassPane_{sx}_{gSeg}`,
				Vector3.new(doorW - 0.16, halfGlassH, 0.02),
				Kit.at(dx, gsy, doorZ),
				GlassColor,
				Enum.Material.Glass,
				true
			)
			glassDoor.Transparency = 0.55
		end

		-- Vertical black door handle (split into 2 segments of 1.2 ft)
		local handleX = dx - sx * (doorW / 2 - 0.16)
		for hSeg = 1, 2 do
			local hsy = doorY - 0.6 + (hSeg - 0.5) * 1.2
			b:cyl(
				`DoorHandle_{sx}_{hSeg}`,
				1.2,
				0.06,
				Kit.vertical(handleX, hsy, doorZ - 0.08),
				SteelDark,
				Enum.Material.Metal
			)
		end
		-- Handle standoff mounts
		for _, hy in { -0.9, 0.9 } do
			b:cyl(
				`HandleMount_{sx}_{hy}`,
				0.08,
				0.04,
				Kit.alongZ(handleX, doorY + hy, doorZ - 0.04),
				HardwareChrome,
				Enum.Material.Metal
			)
		end
	end

	-- Center mullion seal between the two doors (split into 3 segments)
	local mullionSegH = doorH / 3
	for mSeg = 1, 3 do
		local msy = doorY - doorH / 2 + (mSeg - 0.5) * mullionSegH
		b:box(
			`CenterDoorMullion_{mSeg}`,
			Vector3.new(0.06, mullionSegH, doorThick + 0.02),
			Kit.at(0, msy, doorZ),
			SteelDark,
			Enum.Material.Metal,
			true
		)
	end

	return b:done()
end

return IndustrialFridge
