--!strict
-- Regulation table tennis (ping-pong) table (9x5 ft playing surface, 2.5 ft high).
-- Features tournament blue/green surface with regulation boundary and doubles center lines,
-- heavy steel folding frame, caster wheels, regulation 6-inch overhanging net with clamps,
-- and resting paddles and balls.
-- Reference: GMU RAC Level 1 ping-pong recreation area (WALKTHROUGH.md).
local Kit = require(script.Parent.Kit)

local PingPongTable = {
	kind = "ping_pong_table",
	size = Vector3.new(6.0, 3.0, 9.0),
}

local SurfaceBlue = Color3.fromRGB(28, 86, 156) -- ITTF Tournament Blue
local SurfaceGreen = Color3.fromRGB(22, 92, 56) -- Mason / Classic Green
local LineWhite = Color3.fromRGB(248, 250, 252)
local SteelBlack = Color3.fromRGB(28, 30, 32)
local HardwareChrome = Color3.fromRGB(210, 214, 218)
local RubberBlack = Color3.fromRGB(20, 20, 22)
local NetMesh = Color3.fromRGB(25, 25, 28)
local PaddleRed = Color3.fromRGB(200, 35, 30)
local WoodHandle = Color3.fromRGB(195, 150, 100)

function PingPongTable.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("PingPongTable", cf)

	local tableW = 5.0
	local tableL = 9.0
	local tableH = 2.5
	local topThick = 0.12
	local topY = tableH - topThick / 2

	local isGreen = opts and (opts.color == "green" or opts.green == true)
	local topColor = if isGreen then SurfaceGreen else SurfaceBlue

	local halfL = 4.46
	local netGap = 0.08
	local halfZ = netGap / 2 + halfL / 2

	-- 1. Tabletop Halves (North -Z and South +Z)
	for _, sz in { -1, 1 } do
		local cz = sz * halfZ
		-- Playing top slab
		b:box(
			`TableTop_Half_{sz}`,
			Vector3.new(tableW, topThick, halfL),
			Kit.at(0, topY, cz),
			topColor,
			Enum.Material.SmoothPlastic,
			true
		)

		-- Outer boundary white lines (3/4" = 0.06 ft wide)
		local lineY = tableH + 0.008
		-- Side lines
		for _, sx in { -1, 1 } do
			b:box(
				`SideLine_{sz}_{sx}`,
				Vector3.new(0.06, 0.015, halfL),
				Kit.at(sx * (tableW / 2 - 0.03), lineY, cz),
				LineWhite,
				Enum.Material.SmoothPlastic
			)
		end
		-- End line
		b:box(
			`EndLine_{sz}`,
			Vector3.new(tableW, 0.015, 0.06),
			Kit.at(0, lineY, sz * (tableL / 2 - 0.03)),
			LineWhite,
			Enum.Material.SmoothPlastic
		)
		-- Doubles center line (1/8" = 0.02 ft wide)
		b:box(
			`DoublesLine_{sz}`,
			Vector3.new(0.025, 0.015, halfL),
			Kit.at(0, lineY, cz),
			LineWhite,
			Enum.Material.SmoothPlastic
		)

		-- Steel under-apron frame (1.5" = 0.12 ft tubing)
		local apronH = 0.14
		local apronY = topY - topThick / 2 - apronH / 2
		-- Long side aprons
		for _, sx in { -1, 1 } do
			b:box(
				`ApronSide_{sz}_{sx}`,
				Vector3.new(0.08, apronH, halfL - 0.1),
				Kit.at(sx * (tableW / 2 - 0.06), apronY, cz),
				SteelBlack,
				Enum.Material.Metal,
				true
			)
		end
		-- End apron
		b:box(
			`ApronEnd_{sz}`,
			Vector3.new(tableW - 0.2, apronH, 0.08),
			Kit.at(0, apronY, sz * (tableL / 2 - 0.06)),
			SteelBlack,
			Enum.Material.Metal,
			true
		)
		-- Center cross beam
		b:box(
			`ApronCross_{sz}`,
			Vector3.new(tableW - 0.2, apronH, 0.08),
			Kit.at(0, apronY, cz),
			SteelBlack,
			Enum.Material.Metal
		)
	end

	-- 2. Corner Protectors (4 outer corners)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			b:box(
				`CornerCap_{sx}_{sz}`,
				Vector3.new(0.14, topThick + 0.04, 0.14),
				Kit.at(sx * (tableW / 2 - 0.05), topY - 0.01, sz * (tableL / 2 - 0.05)),
				RubberBlack,
				Enum.Material.Rubber
			)
		end
	end

	-- 3. Center Carriage / Trolley Frame & Caster Wheels
	local carriageY = 0.95
	local innerLegX = 1.6
	local innerLegZ = 0.75
	-- Center chassis cross bars
	b:box(
		"CarriageSpine",
		Vector3.new(innerLegX * 2 + 0.2, 0.12, 0.12),
		Kit.at(0, carriageY, 0),
		SteelBlack,
		Enum.Material.Metal,
		true
	)
	for _, sx in { -1, 1 } do
		b:box(
			`CarriageSideBar_{sx}`,
			Vector3.new(0.12, 0.12, innerLegZ * 2 + 0.2),
			Kit.at(sx * innerLegX, carriageY, 0),
			SteelBlack,
			Enum.Material.Metal,
			true
		)
	end

	-- Inner vertical legs and casters
	local wheelRadius = 0.16
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local cx = sx * innerLegX
			local cz = sz * innerLegZ
			-- Vertical inner leg
			local vLegH = topY - topThick / 2 - 0.4
			b:box(
				`InnerLeg_{sx}_{sz}`,
				Vector3.new(0.12, vLegH, 0.12),
				Kit.at(cx, 0.4 + vLegH / 2, cz),
				SteelBlack,
				Enum.Material.Metal,
				true
			)
			-- Caster swivel fork
			b:box(
				`CasterFork_{sx}_{sz}`,
				Vector3.new(0.14, 0.22, 0.14),
				Kit.at(cx, wheelRadius + 0.12, cz),
				SteelBlack,
				Enum.Material.Metal
			)
			-- Rubber wheel
			b:cyl(
				`CasterWheel_{sx}_{sz}`,
				0.12,
				wheelRadius * 2,
				Kit.at(cx, wheelRadius, cz),
				RubberBlack,
				Enum.Material.Rubber
			)
			-- Wheel axle pin
			b:cyl(`WheelAxle_{sx}_{sz}`, 0.16, 0.03, Kit.at(cx, wheelRadius, cz), HardwareChrome, Enum.Material.Metal)
		end
	end

	-- 4. Outer Folding Legs and Diagonal Struts
	local outerLegX = 2.1
	local outerLegZ = 3.5
	local outerLegH = topY - topThick / 2 - 0.1
	for _, sz in { -1, 1 } do
		-- Horizontal cross stretcher connecting outer legs
		b:box(
			`OuterLegBar_{sz}`,
			Vector3.new(outerLegX * 2, 0.1, 0.1),
			Kit.at(0, 0.5, sz * outerLegZ),
			SteelBlack,
			Enum.Material.Metal,
			true
		)
		for _, sx in { -1, 1 } do
			local lx = sx * outerLegX
			local lz = sz * outerLegZ
			-- Leveling rubber foot pad resting on floor
			b:cyl(`FootPad_{sx}_{sz}`, 0.08, 0.16, Kit.vertical(lx, 0.04, lz), RubberBlack, Enum.Material.Rubber)
			-- Square outer leg
			b:box(
				`OuterLeg_{sx}_{sz}`,
				Vector3.new(0.12, outerLegH, 0.12),
				Kit.at(lx, 0.08 + outerLegH / 2, lz),
				SteelBlack,
				Enum.Material.Metal,
				true
			)
			-- Diagonal chrome folding brace rail
			b:box(
				`FoldingRail_{sx}_{sz}`,
				Vector3.new(0.04, 2.2, 0.04),
				Kit.at(lx * 0.7, 1.18, sz * 2.1),
				HardwareChrome,
				Enum.Material.Metal
			)
		end
	end

	-- 5. Regulation Net System (Center at Z = 0)
	local netH = 0.5 -- 6 inches high
	local netTotalW = 6.0 -- 5 ft table + 6 in overhang each side
	local netCenterY = tableH + netH / 2

	-- Black mesh net body
	b:box(
		"NetMesh",
		Vector3.new(netTotalW, netH - 0.04, 0.02),
		Kit.at(0, netCenterY - 0.02, 0),
		NetMesh,
		Enum.Material.Fabric
	)
	-- White top binding tape
	b:box(
		"NetTopTape",
		Vector3.new(netTotalW, 0.04, 0.035),
		Kit.at(0, tableH + netH - 0.02, 0),
		LineWhite,
		Enum.Material.SmoothPlastic
	)
	-- White bottom binding tape
	b:box(
		"NetBottomTape",
		Vector3.new(tableW, 0.02, 0.025),
		Kit.at(0, tableH + 0.01, 0),
		LineWhite,
		Enum.Material.SmoothPlastic
	)

	-- Net clamp posts on left (-X) and right (+X)
	for _, sx in { -1, 1 } do
		local px = sx * (tableW / 2 + 0.04)
		-- Clamp bracket gripping table edge
		b:box(
			`NetClampBody_{sx}`,
			Vector3.new(0.18, 0.16, 0.22),
			Kit.at(px, tableH - 0.02, 0),
			SteelBlack,
			Enum.Material.Metal
		)
		-- Clamp screw knob
		b:cyl(
			`NetClamp_Rail_Knob_{sx}`,
			0.08,
			0.1,
			Kit.vertical(px, tableH - 0.08, 0),
			HardwareChrome,
			Enum.Material.Metal
		)
		-- Vertical round net post
		b:cyl(`NetPost_{sx}`, 0.58, 0.05, Kit.vertical(px, tableH + 0.27, 0), SteelBlack, Enum.Material.Metal)
		-- Tension cord anchor / bead at top
		b:ball(`NetTensionBead_{sx}`, 0.06, Kit.at(px, tableH + netH + 0.01, 0), HardwareChrome, Enum.Material.Metal)
	end

	-- 6. Resting Table Tennis Paddles & Balls
	-- Paddle 1 (Red rubber)
	local p1X, p1Z = 1.3, -1.8
	local pY = tableH + 0.02
	b:cyl("Paddle1_Blade", 0.02, 0.5, Kit.vertical(p1X, pY, p1Z), PaddleRed, Enum.Material.Rubber)
	b:box("Paddle1_Handle", Vector3.new(0.08, 0.03, 0.3), Kit.at(p1X, pY, p1Z + 0.35), WoodHandle, Enum.Material.Wood)

	-- Paddle 2 (Black rubber)
	local p2X, p2Z = 1.8, -1.5
	b:cyl("Paddle2_Blade", 0.02, 0.5, Kit.vertical(p2X, pY, p2Z), SteelBlack, Enum.Material.Rubber)
	b:box("Paddle2_Handle", Vector3.new(0.08, 0.03, 0.3), Kit.at(p2X, pY, p2Z + 0.35), WoodHandle, Enum.Material.Wood)

	-- Ping pong balls (white 40mm)
	b:ball("Ball_1", 0.13, Kit.at(1.1, tableH + 0.065, -1.3), LineWhite, Enum.Material.SmoothPlastic)
	b:ball("Ball_2", 0.13, Kit.at(0.9, tableH + 0.065, -1.45), LineWhite, Enum.Material.SmoothPlastic)

	return b:done()
end

return PingPongTable
