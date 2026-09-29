--!strict
-- Commercial aluminum double doors with 3 horizontal glass lites each and panic push bars.
-- Reference: IMG_0320, IMG_0321 (gym double doors with 3 horizontal glass lites, exit devices).
local Kit = require(script.Parent.Kit)

local DoorDouble = {
	kind = "door_double",
	size = Vector3.new(6.8, 7.2, 0.8),
}

local AluminumGrey = Color3.fromRGB(165, 168, 172)
local FrameGrey = Color3.fromRGB(140, 142, 145)
local PushBarChrome = Color3.fromRGB(220, 224, 228)
local DarkTrim = Color3.fromRGB(45, 48, 52)
local CloserDark = Color3.fromRGB(80, 84, 88)

function DoorDouble.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("DoorDouble", cf)
	local C = Kit.Color

	local w, h, d = 6.8, 7.2, 0.8
	local frameThick = 0.2
	local doorW = 3.0
	local doorH = 7.0
	local doorThick = 0.16
	local doorZ = 0.05

	-- 1. Hollow-metal frame (split into 3 height segments)
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
	end
	-- Frame header
	b:box(
		"FrameHeader",
		Vector3.new(w, frameThick, d),
		Kit.at(0, h - frameThick / 2, 0),
		FrameGrey,
		Enum.Material.Metal,
		true
	)
	-- Floor threshold
	b:box(
		"Threshold",
		Vector3.new(doorW * 2 + 0.2, 0.03, d * 0.7),
		Kit.at(0, 0.015, 0),
		AluminumGrey,
		Enum.Material.Metal
	)

	-- 2. Left and Right door leaves
	-- Leaf centers at X = -doorW/2 (-1.5) and X = +doorW/2 (+1.5)
	local stileW = 0.38
	local topRailH = 0.5
	local botRailH = 0.85
	local midRailH = 0.32
	local liteW = doorW - 2 * stileW

	-- Vertical breakdown of door leaf:
	-- Bottom rail: Y = 0 to 0.85
	-- Lite 1 (lower): Y = 0.85 to 2.45 (height 1.6)
	-- Mid rail 1: Y = 2.45 to 2.77 (height 0.32)
	-- Lite 2 (middle): Y = 2.77 to 4.37 (height 1.6)
	-- Mid rail 2: Y = 4.37 to 4.69 (height 0.32)
	-- Lite 3 (upper): Y = 4.69 to 6.50 (height 1.81)
	-- Top rail: Y = 6.50 to 7.00 (height 0.5)

	for _, sideSign in { -1, 1 } do
		local leafName = if sideSign == -1 then "Left" else "Right"
		local leafX = sideSign * (doorW / 2)
		local hingeX = leafX + sideSign * (-doorW / 2 + 0.02)

		-- Outer and inner vertical stiles (each split into 3 segments for bounding checks)
		local stileSegH = doorH / 3
		for sSeg = 1, 3 do
			local sty = (sSeg - 0.5) * stileSegH
			-- Outer stile (hinge side)
			b:box(
				`StileOuter_{leafName}_{sSeg}`,
				Vector3.new(stileW, stileSegH, doorThick),
				Kit.at(leafX + sideSign * (-doorW / 2 + stileW / 2), sty, doorZ),
				AluminumGrey,
				Enum.Material.Metal,
				true
			)
			-- Inner stile (meeting side)
			b:box(
				`StileInner_{leafName}_{sSeg}`,
				Vector3.new(stileW, stileSegH, doorThick),
				Kit.at(leafX + sideSign * (doorW / 2 - stileW / 2), sty, doorZ),
				AluminumGrey,
				Enum.Material.Metal,
				true
			)
		end

		-- Horizontal rails
		b:box(
			`BotRail_{leafName}`,
			Vector3.new(liteW, botRailH, doorThick),
			Kit.at(leafX, botRailH / 2, doorZ),
			AluminumGrey,
			Enum.Material.Metal,
			true
		)
		b:box(
			`MidRail1_{leafName}`,
			Vector3.new(liteW, midRailH, doorThick),
			Kit.at(leafX, 2.45 + midRailH / 2, doorZ),
			AluminumGrey,
			Enum.Material.Metal
		)
		b:box(
			`MidRail2_{leafName}`,
			Vector3.new(liteW, midRailH, doorThick),
			Kit.at(leafX, 4.37 + midRailH / 2, doorZ),
			AluminumGrey,
			Enum.Material.Metal
		)
		b:box(
			`TopRail_{leafName}`,
			Vector3.new(liteW, topRailH, doorThick),
			Kit.at(leafX, 6.50 + topRailH / 2, doorZ),
			AluminumGrey,
			Enum.Material.Metal,
			true
		)

		-- 3 Horizontal glass lites
		-- Lite 1 (bottom)
		b:box(
			`GlassLite1_{leafName}`,
			Vector3.new(liteW, 1.6, 0.02),
			Kit.at(leafX, 0.85 + 0.8, doorZ),
			C.Glass,
			Enum.Material.Glass
		)
		-- Lite 2 (middle)
		b:box(
			`GlassLite2_{leafName}`,
			Vector3.new(liteW, 1.6, 0.02),
			Kit.at(leafX, 2.77 + 0.8, doorZ),
			C.Glass,
			Enum.Material.Glass
		)
		-- Lite 3 (top)
		b:box(
			`GlassLite3_{leafName}`,
			Vector3.new(liteW, 1.81, 0.02),
			Kit.at(leafX, 4.69 + 0.9, doorZ),
			C.Glass,
			Enum.Material.Glass
		)

		-- Main reference part named "Door" for DoorService
		local mainDoorPart = b:box(
			`Door_{leafName}`,
			Vector3.new(0.04, 0.04, 0.04),
			Kit.at(leafX, 3.5, doorZ),
			AluminumGrey,
			Enum.Material.Metal
		)
		local hinge =
			b:cyl("Hinge", doorH * 0.9, 0.04, Kit.vertical(hingeX, 3.5, doorZ), PushBarChrome, Enum.Material.Metal)
		hinge.Parent = mainDoorPart

		-- 3. Panic push bars (crash exit devices) on inside face (-Z)
		local pushBarY = 3.3
		-- Push bar chassis mounts
		b:box(
			`PushChassis1_{leafName}`,
			Vector3.new(0.2, 0.25, 0.12),
			Kit.at(leafX - doorW / 2 + 0.25, pushBarY, doorZ - doorThick / 2 - 0.06),
			DarkTrim,
			Enum.Material.Metal
		)
		b:box(
			`PushChassis2_{leafName}`,
			Vector3.new(0.2, 0.25, 0.12),
			Kit.at(leafX + doorW / 2 - 0.25, pushBarY, doorZ - doorThick / 2 - 0.06),
			DarkTrim,
			Enum.Material.Metal
		)
		-- Horizontal push bar
		b:box(
			`PushBar_{leafName}`,
			Vector3.new(doorW - 0.45, 0.1, 0.06),
			Kit.at(leafX, pushBarY, doorZ - doorThick / 2 - 0.12),
			PushBarChrome,
			Enum.Material.Metal
		)

		-- 4. Exterior pull handle / lever on outside face (+Z)
		b:box(
			`ExtEscutcheon_{leafName}`,
			Vector3.new(0.18, 0.7, 0.02),
			Kit.at(leafX + sideSign * (doorW / 2 - 0.25), pushBarY, doorZ + doorThick / 2 + 0.01),
			PushBarChrome,
			Enum.Material.Metal
		)
		b:cyl(
			`ExtHandleStem_{leafName}`,
			0.08,
			0.04,
			Kit.alongZ(leafX + sideSign * (doorW / 2 - 0.25), pushBarY, doorZ + doorThick / 2 + 0.05),
			PushBarChrome,
			Enum.Material.Metal
		)
		b:box(
			`ExtHandleBar_{leafName}`,
			Vector3.new(0.35, 0.05, 0.03),
			Kit.at(leafX + sideSign * (doorW / 2 - 0.4), pushBarY, doorZ + doorThick / 2 + 0.09),
			PushBarChrome,
			Enum.Material.Metal
		)

		-- 5. Overhead door closer
		local closerY = doorH + 0.08
		b:box(
			`CloserBody_{leafName}`,
			Vector3.new(0.85, 0.2, 0.18),
			Kit.at(leafX - sideSign * 0.4, closerY, doorZ - 0.14),
			CloserDark,
			Enum.Material.Metal
		)
		b:box(
			`CloserArm_{leafName}`,
			Vector3.new(0.7, 0.04, 0.03),
			Kit.at(leafX, closerY - 0.06, doorZ - 0.08),
			CloserDark,
			Enum.Material.Metal
		)

		-- 6. Hinges on outer jamb
		for _, hy in { 0.8, 3.5, 6.2 } do
			b:cyl(
				`Hinge_{leafName}_{hy}`,
				0.35,
				0.04,
				Kit.vertical(hingeX, hy, doorZ - doorThick / 4),
				PushBarChrome,
				Enum.Material.Metal
			)
		end
	end

	-- Center meeting astragal seal strip between leaves
	b:box("AstragalSeal", Vector3.new(0.04, doorH, 0.04), Kit.at(0, doorH / 2, doorZ), DarkTrim, Enum.Material.Rubber)

	return b:done()
end

return DoorDouble
