--!strict
-- Full regulation international squash court shell (32x21 ft, 15 ft front wall).
-- Features maple hardwood tongue-and-groove floor, official red court boundary markings,
-- 19-inch metal tin with red bevel sounding strip, service line, sloping side wall lines,
-- tempered safety glass back wall with glass spectator fins and access door,
-- and overhead sports troffer illumination.
-- Reference: GMU RAC Level 2 squash courts adjacent to gym overlook (WALKTHROUGH.md).
-- opts.backWallGlass (default true) toggles the tempered glass spectator back wall.
local Kit = require(script.Parent.Kit)

local SquashCourt = {
	kind = "squash_court",
	size = Vector3.new(21.0, 15.0, 32.0),
}

local MapleFloor = Color3.fromRGB(218, 180, 128)
local PlasterWhite = Color3.fromRGB(244, 246, 248)
local LineRed = Color3.fromRGB(215, 35, 30) -- Official squash court red
local TinMetal = Color3.fromRGB(150, 154, 158)
local HardwareChrome = Color3.fromRGB(215, 218, 222)
local GlassColor = Color3.fromRGB(195, 220, 228)
local RailGrey = Color3.fromRGB(120, 124, 128)

function SquashCourt.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("SquashCourt", cf)

	local courtW = 21.0
	local courtL = 32.0
	local wallH = 15.0
	local wallThick = 0.4
	local floorThick = 0.1

	local backWallGlass = if opts and opts.backWallGlass ~= nil then opts.backWallGlass == true else true

	-- Internal playable court dimensions:
	-- Width between side walls = courtW - wallThick * 2 = 20.2 ft (inner faces at X = ±10.1)
	-- Length between front and back walls = courtL - wallThick * 2 = 31.2 ft
	-- Front wall inner face at Z = -16.0 + wallThick = -15.6 ft
	-- Back wall inner face at Z = 16.0 - wallThick = +15.6 ft
	local innerW = courtW - wallThick * 2
	local innerL = courtL - wallThick * 2
	local frontFaceZ = -courtL / 2 + wallThick
	local backFaceZ = courtL / 2 - wallThick

	-- 1. Maple Hardwood Floor (inside walls: innerW x innerL, split into 3 X bays x 2 Z halves)
	local floorBayW = innerW / 3
	local halfFloorL = innerL / 2
	for bay = 1, 3 do
		local fx = -innerW / 2 + (bay - 0.5) * floorBayW
		for _, sz in { -1, 1 } do
			b:box(
				`Floor_Maple_{bay}_{sz}`,
				Vector3.new(floorBayW, floorThick, halfFloorL),
				Kit.at(fx, floorThick / 2, sz * (halfFloorL / 2)),
				MapleFloor,
				Enum.Material.WoodPlanks,
				true
			)
		end
	end

	-- 2. Regulation Floor Court Lines (Red, raised 0.015 ft above floor to avoid z-fighting)
	local lineThick = 0.015
	local lineW = 0.16 -- 2 inches wide
	local lineY = floorThick + lineThick / 2

	-- Short Line: transverse red line at 18.0 ft from front wall (-15.6 + 18.0 = +2.4 ft)
	-- Split across 3 bays
	local shortLineZ = frontFaceZ + 18.0
	local shortBayW = innerW / 3
	for bay = 1, 3 do
		local bx = -innerW / 2 + (bay - 0.5) * shortBayW
		b:box(
			`ShortLine_Floor_{bay}`,
			Vector3.new(shortBayW, lineThick, lineW),
			Kit.at(bx, lineY, shortLineZ),
			LineRed,
			Enum.Material.SmoothPlastic
		)
	end

	-- Half-Court Line: running from Short Line (+2.4) to Back Wall (+15.6) at X = 0
	local halfCourtLen = backFaceZ - shortLineZ
	b:box(
		"HalfCourtLine_Floor",
		Vector3.new(lineW, lineThick, halfCourtLen),
		Kit.at(0, lineY, shortLineZ + halfCourtLen / 2),
		LineRed,
		Enum.Material.SmoothPlastic
	)

	-- Service Boxes (Left & Right, 5.25 ft x 5.25 ft)
	local boxSize = 5.25
	local boxBackZ = shortLineZ + boxSize
	for _, sx in { -1, 1 } do
		local innerEdgeX = sx * (courtW / 2 - wallThick - boxSize)
		-- Transverse back line of service box
		b:box(
			`ServiceBoxBackLine_{sx}`,
			Vector3.new(boxSize, lineThick, lineW),
			Kit.at(sx * (courtW / 2 - wallThick - boxSize / 2), lineY, boxBackZ),
			LineRed,
			Enum.Material.SmoothPlastic
		)
		-- Longitudinal inner line of service box
		b:box(
			`ServiceBoxInnerLine_{sx}`,
			Vector3.new(lineW, lineThick, boxSize),
			Kit.at(innerEdgeX, lineY, shortLineZ + boxSize / 2),
			LineRed,
			Enum.Material.SmoothPlastic
		)
	end

	-- 3. Front Wall (at Z = -16.0 + wallThick / 2 = -15.8 ft)
	-- Solid white court front wall (split into 3 X bays x 2 height segments to keep radius small)
	local fBayW = courtW / 3
	local fHalfH = wallH / 2
	for bay = 1, 3 do
		local bx = -courtW / 2 + (bay - 0.5) * fBayW
		for hSeg = 1, 2 do
			local by = (hSeg - 0.5) * fHalfH
			b:box(
				`FrontWall_Carcass_{bay}_{hSeg}`,
				Vector3.new(fBayW, fHalfH, wallThick),
				Kit.at(bx, by, -courtL / 2 + wallThick / 2),
				PlasterWhite,
				Enum.Material.SmoothPlastic,
				true
			)
		end
	end

	-- The Tin: 19 inches (1.58 ft) high metal sound board at base of front wall (split into 3 bays)
	local tinH = 1.58
	local tinBayW = innerW / 3
	for bay = 1, 3 do
		local tx = -innerW / 2 + (bay - 0.5) * tinBayW
		b:box(
			`FrontTin_SheetMetal_{bay}`,
			Vector3.new(tinBayW, tinH - 0.16, 0.04),
			Kit.at(tx, floorThick + (tinH - 0.16) / 2, frontFaceZ + 0.02),
			TinMetal,
			Enum.Material.Metal,
			true
		)
		-- Tin red top bevel / sounding strip (0.16 ft high)
		b:box(
			`FrontTin_TopBevel_{bay}`,
			Vector3.new(tinBayW, 0.16, 0.06),
			Kit.at(tx, floorThick + tinH - 0.08, frontFaceZ + 0.03),
			LineRed,
			Enum.Material.SmoothPlastic
		)
		-- Front Wall Cut Line (Service Line at Y = 5.84 ft above floor)
		local cutLineY = floorThick + 5.84
		b:box(
			`FrontServiceLine_Board_{bay}`,
			Vector3.new(tinBayW, lineW, 0.015),
			Kit.at(tx, cutLineY, frontFaceZ + 0.01),
			LineRed,
			Enum.Material.SmoothPlastic
		)
		-- Front Out-of-Court Line (at top of front wall Y = 15.0 ft)
		b:box(
			`FrontOutLine_Board_{bay}`,
			Vector3.new(tinBayW, lineW, 0.015),
			Kit.at(tx, wallH - lineW / 2, frontFaceZ + 0.01),
			LineRed,
			Enum.Material.SmoothPlastic
		)
	end

	-- 4. Left & Right Side Walls (Clean non-intersecting boundary between frontFaceZ and backFaceZ)
	local sideL = innerL
	local sideHalfL = sideL / 2
	local lowerSideH = 7.0 -- Base side wall height matching back wall
	local upperSideH = wallH - lowerSideH -- 8.0 ft slope

	for _, sx in { -1, 1 } do
		local wx = sx * (courtW / 2 - wallThick / 2)
		local innerFaceX = sx * (courtW / 2 - wallThick)

		-- Lower side wall (7 ft high, split into North and South segments)
		for _, sz in { -1, 1 } do
			local wz = sz * (sideHalfL / 2)
			b:box(
				`SideWallLower_{sx}_{sz}`,
				Vector3.new(wallThick, lowerSideH, sideHalfL),
				Kit.at(wx, lowerSideH / 2, wz),
				PlasterWhite,
				Enum.Material.SmoothPlastic,
				true
			)
		end

		-- Upper tapered side wall: modeled as 4 stepped segments to form the diagonal slope
		local numSteps = 4
		local stepL = sideL / numSteps
		for step = 1, numSteps do
			local stepZ = frontFaceZ + (step - 0.5) * stepL
			-- Height decreases linearly from 8.0 ft at front to 0 ft at back
			local fraction = 1 - (step - 0.5) / numSteps
			local stepH = math.max(0.2, upperSideH * fraction)
			local stepY = lowerSideH + stepH / 2

			b:box(
				`SideWallUpperStep_{sx}_{step}`,
				Vector3.new(wallThick, stepH, stepL),
				Kit.at(wx, stepY, stepZ),
				PlasterWhite,
				Enum.Material.SmoothPlastic,
				true
			)

			-- Red sloping out-of-court line segment along the inner wall face
			b:box(
				`SideOutLine_Board_{sx}_{step}`,
				Vector3.new(0.015, lineW, stepL),
				Kit.at(innerFaceX - sx * 0.01, lowerSideH + upperSideH * fraction, stepZ),
				LineRed,
				Enum.Material.SmoothPlastic
			)
		end
	end

	-- 5. Back Wall (at Z = +16.0 ft)
	if backWallGlass then
		-- Tempered Safety Glass Spectator Wall (7 ft high)
		local glassH = 7.0
		local glassY = glassH / 2
		local doorW = 3.0
		local sidePaneW = (innerW - doorW) / 2
		local glassThick = 0.05
		local glassZ = backFaceZ - 0.02

		-- Bottom aluminum base channel track (split into 3 bays)
		for bay = 1, 3 do
			local bx = -innerW / 2 + (bay - 0.5) * shortBayW
			b:box(
				`GlassFloorTrack_Rail_{bay}`,
				Vector3.new(shortBayW, 0.1, 0.12),
				Kit.at(bx, floorThick + 0.05, glassZ),
				HardwareChrome,
				Enum.Material.Metal
			)
		end

		-- Left glass panel
		local leftGlass = b:box(
			"BackWall_Glass_Left",
			Vector3.new(sidePaneW, glassH - 0.1, glassThick),
			Kit.at(-doorW / 2 - sidePaneW / 2, floorThick + glassY, glassZ),
			GlassColor,
			Enum.Material.Glass,
			true
		)
		leftGlass.Transparency = 0.55

		-- Right glass panel
		local rightGlass = b:box(
			"BackWall_Glass_Right",
			Vector3.new(sidePaneW, glassH - 0.1, glassThick),
			Kit.at(doorW / 2 + sidePaneW / 2, floorThick + glassY, glassZ),
			GlassColor,
			Enum.Material.Glass,
			true
		)
		rightGlass.Transparency = 0.55

		-- Center glass door
		local glassDoor = b:box(
			"BackWall_Glass_Door",
			Vector3.new(doorW - 0.04, glassH - 0.14, glassThick),
			Kit.at(0, floorThick + glassY, glassZ),
			GlassColor,
			Enum.Material.Glass,
			true
		)
		glassDoor.Transparency = 0.55

		-- Door stainless steel pivot hinges and flush pull handle
		b:box(
			"GlassDoorHingeTop",
			Vector3.new(0.2, 0.08, 0.1),
			Kit.at(-doorW / 2 + 0.12, floorThick + glassH - 0.05, glassZ),
			HardwareChrome,
			Enum.Material.Metal
		)
		b:box(
			"GlassDoorHingeBottom",
			Vector3.new(0.2, 0.08, 0.1),
			Kit.at(-doorW / 2 + 0.12, floorThick + 0.12, glassZ),
			HardwareChrome,
			Enum.Material.Metal
		)
		b:cyl(
			"GlassDoorPull_Rail",
			0.8,
			0.05,
			Kit.vertical(doorW / 2 - 0.25, floorThick + 3.2, glassZ - 0.04),
			HardwareChrome,
			Enum.Material.Metal
		)

		-- Structural glass stiffener fins at door jambs (extending into gallery corridor)
		for _, sx in { -1, 1 } do
			local finGlass = b:box(
				`GlassFin_Stiffener_{sx}`,
				Vector3.new(glassThick, glassH - 0.2, 0.75),
				Kit.at(sx * (doorW / 2), floorThick + glassY, glassZ + 0.4),
				GlassColor,
				Enum.Material.Glass
			)
			finGlass.Transparency = 0.55
		end

		-- Back wall red out-of-court line across the top of the glass (split into 3 bays)
		for bay = 1, 3 do
			local bx = -innerW / 2 + (bay - 0.5) * shortBayW
			b:box(
				`BackOutLine_Glass_Board_{bay}`,
				Vector3.new(shortBayW, lineW, 0.03),
				Kit.at(bx, floorThick + glassH - lineW / 2, glassZ - 0.015),
				LineRed,
				Enum.Material.SmoothPlastic
			)
			-- Top spectator gallery guardrail over the back wall opening
			b:box(
				`GalleryTop_Rail_{bay}`,
				Vector3.new(shortBayW, 0.15, 0.25),
				Kit.at(bx, floorThick + glassH + 0.08, glassZ),
				RailGrey,
				Enum.Material.Metal,
				true
			)
		end
	else
		-- Solid white back wall option with single flush door
		b:box(
			"BackWall_Solid",
			Vector3.new(courtW, wallH, wallThick),
			Kit.at(0, wallH / 2, courtL / 2 - wallThick / 2),
			PlasterWhite,
			Enum.Material.SmoothPlastic,
			true
		)
	end

	-- 6. Overhead Court Troffer Light Fixtures
	-- 4 LED high-bay sports troffers mounted along upper side walls
	for _, sx in { -1, 1 } do
		local lx = sx * (innerW / 2 - 0.6)
		for lIdx, lz in { -8.0, 4.0 } do
			local lightY = if lz < 0 then 14.2 else 10.5
			local troffer = b:box(
				`CourtLight_Troffer_{sx}_{lIdx}`,
				Vector3.new(0.8, 0.2, 3.5),
				Kit.at(lx, lightY, lz),
				Color3.fromRGB(250, 252, 255),
				Enum.Material.Neon
			)
			b:light(troffer, Enum.NormalId.Bottom, 1.4, 22, Color3.fromRGB(245, 248, 255))
		end
	end

	return b:done()
end

return SquashCourt
