--!strict
-- Wall-mounted emergency fire extinguisher cabinet with glass viewing window and extinguisher.
-- Reference: IMG_0346 (white recessed cabinet with vertical window, corridor wall).
local Kit = require(script.Parent.Kit)

local FireExtinguisherCabinet = {
	kind = "fire_extinguisher_cabinet",
	size = Vector3.new(1.2, 2.6, 0.6),
}

local CabinetWhite = Color3.fromRGB(240, 240, 238)
local ExtinguisherRed = Color3.fromRGB(205, 30, 25)
local ValveBrass = Color3.fromRGB(195, 160, 80)
local DarkHose = Color3.fromRGB(30, 32, 35)

function FireExtinguisherCabinet.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("FireExtinguisherCabinet", cf)
	local C = Kit.Color

	local w, h, d = 1.2, 2.6, 0.6
	local halfH = h / 2
	local t = 0.05
	local frontZ = -d / 2
	local backZ = d / 2 - t / 2

	-- 1. Outer cabinet box (white enamel)
	b:box("CabinetTop", Vector3.new(w, t, d), Kit.at(0, h - t / 2, 0), CabinetWhite, Enum.Material.SmoothPlastic, true)
	b:box("CabinetBottom", Vector3.new(w, t, d), Kit.at(0, t / 2, 0), CabinetWhite, Enum.Material.SmoothPlastic, true)

	-- Back wall (split into lower and upper for radial bounds)
	b:box(
		"BackLower",
		Vector3.new(w - 2 * t, halfH, t),
		Kit.at(0, halfH / 2, backZ),
		CabinetWhite,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"BackUpper",
		Vector3.new(w - 2 * t, halfH, t),
		Kit.at(0, halfH + halfH / 2, backZ),
		CabinetWhite,
		Enum.Material.SmoothPlastic
	)

	-- Side walls (split in half)
	for _, s in { -1, 1 } do
		local x = s * (w / 2 - t / 2)
		b:box(
			`SideLower_{s}`,
			Vector3.new(t, halfH, d),
			Kit.at(x, halfH / 2, 0),
			CabinetWhite,
			Enum.Material.SmoothPlastic,
			true
		)
		b:box(
			`SideUpper_{s}`,
			Vector3.new(t, halfH, d),
			Kit.at(x, halfH + halfH / 2, 0),
			CabinetWhite,
			Enum.Material.SmoothPlastic,
			true
		)
	end

	-- Wall mounting trim flange (around front edge)
	b:box(
		"FlangeTop",
		Vector3.new(w + 0.1, 0.08, 0.04),
		Kit.at(0, h + 0.02, frontZ - 0.01),
		CabinetWhite,
		Enum.Material.Metal
	)
	b:box(
		"FlangeBottom",
		Vector3.new(w + 0.1, 0.08, 0.04),
		Kit.at(0, -0.02, frontZ - 0.01),
		CabinetWhite,
		Enum.Material.Metal
	)
	for _, s in { -1, 1 } do
		local x = s * (w / 2 + 0.03)
		b:box(
			`FlangeSideLower_{s}`,
			Vector3.new(0.06, halfH, 0.04),
			Kit.at(x, halfH / 2, frontZ - 0.01),
			CabinetWhite,
			Enum.Material.Metal
		)
		b:box(
			`FlangeSideUpper_{s}`,
			Vector3.new(0.06, halfH, 0.04),
			Kit.at(x, halfH + halfH / 2, frontZ - 0.01),
			CabinetWhite,
			Enum.Material.Metal
		)
	end

	-- 2. Cabinet Door with vertical glass viewing panel
	local doorW = w - 0.04
	local glassW = 0.45
	local stileW = (doorW - glassW) / 2
	local railH = 0.25

	-- Door rails (top & bottom)
	b:box(
		"DoorRailTop",
		Vector3.new(doorW, railH, 0.04),
		Kit.at(0, h - railH / 2 - 0.02, frontZ),
		CabinetWhite,
		Enum.Material.Metal
	)
	b:box(
		"DoorRailBottom",
		Vector3.new(doorW, railH, 0.04),
		Kit.at(0, railH / 2 + 0.02, frontZ),
		CabinetWhite,
		Enum.Material.Metal
	)

	-- Door stiles (left & right, split in half)
	local doorMidH = h - 2 * railH - 0.04
	local doorHalfMidH = doorMidH / 2
	for _, s in { -1, 1 } do
		local sx = s * (doorW / 2 - stileW / 2)
		b:box(
			`DoorStileLower_{s}`,
			Vector3.new(stileW, doorHalfMidH, 0.04),
			Kit.at(sx, railH + doorHalfMidH / 2, frontZ),
			CabinetWhite,
			Enum.Material.Metal
		)
		b:box(
			`DoorStileUpper_{s}`,
			Vector3.new(stileW, doorHalfMidH, 0.04),
			Kit.at(sx, railH + doorHalfMidH + doorHalfMidH / 2, frontZ),
			CabinetWhite,
			Enum.Material.Metal
		)
	end

	-- Vertical glass viewing window (split in half)
	b:box(
		"GlassWindowLower",
		Vector3.new(glassW, doorHalfMidH, 0.02),
		Kit.at(0, railH + doorHalfMidH / 2, frontZ),
		C.Glass,
		Enum.Material.Glass
	)
	b:box(
		"GlassWindowUpper",
		Vector3.new(glassW, doorHalfMidH, 0.02),
		Kit.at(0, railH + doorHalfMidH + doorHalfMidH / 2, frontZ),
		C.Glass,
		Enum.Material.Glass
	)

	-- Piano hinge along left edge
	b:cyl(
		"PianoHingeLower",
		halfH * 0.9,
		0.03,
		Kit.vertical(-doorW / 2, halfH / 2, frontZ),
		C.Chrome,
		Enum.Material.Metal
	)
	b:cyl(
		"PianoHingeUpper",
		halfH * 0.9,
		0.03,
		Kit.vertical(-doorW / 2, halfH + halfH / 2, frontZ),
		C.Chrome,
		Enum.Material.Metal
	)

	-- Flush pull handle on right edge
	b:box(
		"DoorHandleRecess",
		Vector3.new(0.08, 0.4, 0.02),
		Kit.at(doorW / 2 - 0.12, halfH, frontZ - 0.01),
		Color3.fromRGB(50, 50, 52),
		Enum.Material.Metal
	)
	b:box(
		"DoorHandleBar",
		Vector3.new(0.03, 0.28, 0.03),
		Kit.at(doorW / 2 - 0.12, halfH, frontZ - 0.02),
		C.Chrome,
		Enum.Material.Metal
	)

	-- Red text indicator on glass
	b:box(
		"RedIndicatorStripe",
		Vector3.new(glassW * 0.8, 0.12, 0.01),
		Kit.at(0, h - railH - 0.15, frontZ - 0.015),
		ExtinguisherRed,
		Enum.Material.SmoothPlastic
	)

	-- 3. Fire Extinguisher inside
	local extCenterY = 1.15
	local extZ = 0.05
	-- Wall mounting bracket
	b:box(
		"MountBracket",
		Vector3.new(0.3, 0.5, 0.15),
		Kit.at(0, extCenterY, backZ - 0.1),
		C.SteelBlack,
		Enum.Material.Metal
	)
	b:box("BracketStrap", Vector3.new(0.48, 0.06, 0.48), Kit.at(0, extCenterY, extZ), C.Chrome, Enum.Material.Metal)

	-- Main red cylinder tank
	b:cyl("ExtTankBody", 1.1, 0.42, Kit.vertical(0, extCenterY, extZ), ExtinguisherRed, Enum.Material.SmoothPlastic)
	-- Rounded dome top and bottom
	b:ball("ExtTankTop", 0.42, Kit.at(0, extCenterY + 0.55, extZ), ExtinguisherRed, Enum.Material.SmoothPlastic)
	b:ball("ExtTankBottom", 0.42, Kit.at(0, extCenterY - 0.55, extZ), ExtinguisherRed, Enum.Material.SmoothPlastic)
	-- Base foot ring
	b:cyl("ExtBaseRing", 0.06, 0.44, Kit.vertical(0, extCenterY - 0.65, extZ), DarkHose, Enum.Material.Rubber)

	-- Valve and handle assembly
	local valveY = extCenterY + 0.82
	b:box("ValveBody", Vector3.new(0.12, 0.18, 0.12), Kit.at(0, valveY, extZ), ValveBrass, Enum.Material.Metal)
	-- Carrying handle (fixed bottom lever)
	b:box(
		"CarryHandle",
		Vector3.new(0.04, 0.04, 0.35),
		Kit.at(0, valveY + 0.04, extZ + 0.1),
		ValveBrass,
		Enum.Material.Metal
	)
	-- Squeeze trigger (upper lever)
	b:box(
		"SqueezeLever",
		Vector3.new(0.04, 0.03, 0.38),
		Kit.at(0, valveY + 0.14, extZ + 0.1),
		ExtinguisherRed,
		Enum.Material.Metal
	)
	-- Safety pull-pin with pull ring
	b:cyl("PullPinRing", 0.02, 0.12, Kit.alongZ(0.1, valveY + 0.08, extZ), C.Chrome, Enum.Material.Metal)
	-- Pressure gauge
	b:cyl("PressureGauge", 0.05, 0.08, Kit.at(-0.1, valveY + 0.06, extZ), C.Chrome, Enum.Material.Metal)

	-- Discharge hose and nozzle
	b:cyl("HoseConnector", 0.08, 0.06, Kit.alongZ(0, valveY - 0.02, extZ - 0.1), DarkHose, Enum.Material.Rubber)
	b:cyl("DischargeHose", 0.9, 0.06, Kit.vertical(-0.24, extCenterY + 0.2, extZ), DarkHose, Enum.Material.Rubber)
	b:cyl("HoseNozzle", 0.25, 0.08, Kit.vertical(-0.24, extCenterY - 0.35, extZ), DarkHose, Enum.Material.SmoothPlastic)

	return b:done()
end

return FireExtinguisherCabinet
