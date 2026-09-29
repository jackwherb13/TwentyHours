--!strict
-- Office workstation cubicle with acoustic fabric panels (~5 ft tall).
-- Reference: IMG_0325, IMG_0327 (grey fabric panels, dark trim, L-shaped desk, overhead bin).
local Kit = require(script.Parent.Kit)

local Cubicle = {
	kind = "cubicle",
	size = Vector3.new(6.6, 5.0, 6.6),
}

local FabricGrey = Color3.fromRGB(185, 187, 188)
local TrimDark = Color3.fromRGB(45, 48, 52)
local DeskTopColor = Color3.fromRGB(225, 222, 215)
local TackNoteColor1 = Color3.fromRGB(255, 255, 230)
local TackNoteColor2 = Color3.fromRGB(220, 240, 255)

function Cubicle.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("Cubicle", cf)
	local C = Kit.Color

	local w, h, d = 6.0, 5.0, 6.0
	local panelThick = 0.18
	local trimHeight = 0.12
	local deskH = 2.5

	-- Helper to create a framed acoustic partition panel (in modular 3ft sections)
	local function addPanelSegment(name: string, segLen: number, pCenter: Vector3, isAlongX: boolean)
		local fabricH = h - 0.35 - trimHeight

		-- Bottom electrical/data raceway (dark metal)
		b:box(
			`{name}_Raceway`,
			if isAlongX then Vector3.new(segLen, 0.35, panelThick) else Vector3.new(panelThick, 0.35, segLen),
			Kit.at(pCenter.X, 0.175, pCenter.Z),
			TrimDark,
			Enum.Material.Metal
		)

		-- Main acoustic fabric panel
		b:box(
			`{name}_Fabric`,
			if isAlongX
				then Vector3.new(segLen - 0.04, fabricH, panelThick - 0.02)
				else Vector3.new(panelThick - 0.02, fabricH, segLen - 0.04),
			Kit.at(pCenter.X, 0.35 + fabricH / 2, pCenter.Z),
			FabricGrey,
			Enum.Material.Fabric,
			true
		)

		-- Top trim rail
		b:box(
			`{name}_TopTrim`,
			if isAlongX
				then Vector3.new(segLen, trimHeight, panelThick + 0.02)
				else Vector3.new(panelThick + 0.02, trimHeight, segLen),
			Kit.at(pCenter.X, h - trimHeight / 2, pCenter.Z),
			TrimDark,
			Enum.Material.Metal
		)
	end

	-- 1. Back wall (2 segments of 3 ft along X at Z = d/2 - panelThick/2)
	local backZ = d / 2 - panelThick / 2
	addPanelSegment("Back1", 3.0, Vector3.new(-1.5, 0, backZ), true)
	addPanelSegment("Back2", 3.0, Vector3.new(1.5, 0, backZ), true)

	-- 2. Left side wall (2 segments of 3 ft along Z at X = -w/2 + panelThick/2)
	local leftX = -w / 2 + panelThick / 2
	addPanelSegment("Left1", 3.0, Vector3.new(leftX, 0, -1.5), false)
	addPanelSegment("Left2", 3.0, Vector3.new(leftX, 0, 1.5), false)

	-- 3. Front wing (1 segment of 3 ft along X at Z = -d/2 + panelThick/2)
	local frontZ = -d / 2 + panelThick / 2
	addPanelSegment("FrontWing", 3.0, Vector3.new(-w / 2 + 1.5, 0, frontZ), true)

	-- Corner posts / junction connectors (dark metal vertical posts)
	for _, pos in
		{
			Vector3.new(-w / 2 + panelThick / 2, h / 2, d / 2 - panelThick / 2), -- rear-left corner
			Vector3.new(w / 2 - panelThick / 2, h / 2, d / 2 - panelThick / 2), -- rear-right end
			Vector3.new(-w / 2 + panelThick / 2, h / 2, -d / 2 + panelThick / 2), -- front-left corner
			Vector3.new(-w / 2 + 3.0, h / 2, -d / 2 + panelThick / 2), -- front wing end post
		}
	do
		b:box(
			"JunctionPost",
			Vector3.new(panelThick + 0.04, h, panelThick + 0.04),
			Kit.at(pos.X, pos.Y, pos.Z),
			TrimDark,
			Enum.Material.Metal
		)
	end

	-- L-Shaped Desk:
	-- Main back desk surface (along back wall)
	local mainDeskW = 4.8
	local mainDeskD = 2.2
	local mainDeskX = -0.4
	local mainDeskZ = d / 2 - panelThick - mainDeskD / 2
	b:box(
		"MainDeskSurface",
		Vector3.new(mainDeskW, 0.1, mainDeskD),
		Kit.at(mainDeskX, deskH - 0.05, mainDeskZ),
		DeskTopColor,
		Enum.Material.SmoothPlastic,
		true
	)

	-- Left return desk surface (along left wall)
	local retDeskW = 1.8
	local retDeskD = 2.8
	local retDeskX = -w / 2 + panelThick + retDeskW / 2
	local retDeskZ = mainDeskZ - mainDeskD / 2 - retDeskD / 2
	b:box(
		"ReturnDeskSurface",
		Vector3.new(retDeskW, 0.1, retDeskD),
		Kit.at(retDeskX, deskH - 0.05, retDeskZ),
		DeskTopColor,
		Enum.Material.SmoothPlastic,
		true
	)

	-- Desk steel supporting legs & brackets
	-- Corner leg
	b:box(
		"DeskLeg_InnerCorner",
		Vector3.new(0.15, deskH - 0.1, 0.15),
		Kit.at(mainDeskX - mainDeskW / 2 + retDeskW, (deskH - 0.1) / 2, mainDeskZ - mainDeskD / 2),
		TrimDark,
		Enum.Material.Metal
	)
	-- Outer right leg
	b:box(
		"DeskLeg_Right",
		Vector3.new(0.15, deskH - 0.1, mainDeskD * 0.8),
		Kit.at(mainDeskX + mainDeskW / 2 - 0.2, (deskH - 0.1) / 2, mainDeskZ),
		TrimDark,
		Enum.Material.Metal
	)
	-- Outer front return leg
	b:box(
		"DeskLeg_FrontReturn",
		Vector3.new(retDeskW * 0.8, deskH - 0.1, 0.15),
		Kit.at(retDeskX, (deskH - 0.1) / 2, retDeskZ - retDeskD / 2 + 0.2),
		TrimDark,
		Enum.Material.Metal
	)

	-- Overhead flipper-door storage cabinet mounted on back partition
	local cabW, cabH, cabD = 4.0, 1.2, 1.1
	local cabY = 4.0
	local cabZ = d / 2 - panelThick - cabD / 2
	b:box(
		"OverheadCabinet",
		Vector3.new(cabW, cabH, cabD),
		Kit.at(mainDeskX, cabY, cabZ),
		TrimDark,
		Enum.Material.Metal,
		true
	)
	-- Cabinet door face / handle
	b:box(
		"OverheadDoorFace",
		Vector3.new(cabW - 0.1, cabH - 0.1, 0.04),
		Kit.at(mainDeskX, cabY, cabZ - cabD / 2 - 0.02),
		DeskTopColor,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"OverheadHandle",
		Vector3.new(0.8, 0.04, 0.05),
		Kit.at(mainDeskX, cabY - 0.35, cabZ - cabD / 2 - 0.06),
		C.Chrome,
		Enum.Material.Metal
	)
	-- Task light under overhead cabinet
	local taskLight = b:box(
		"TaskLightFixture",
		Vector3.new(3.0, 0.06, 0.3),
		Kit.at(mainDeskX, cabY - cabH / 2 - 0.03, cabZ),
		Color3.fromRGB(250, 250, 240),
		Enum.Material.Neon
	)
	b:light(taskLight, Enum.NormalId.Bottom, 1.0, 6, Color3.fromRGB(255, 250, 235))

	-- Mobile under-desk pedestal drawer unit (under main desk right side)
	local pedW, pedH, pedD = 1.3, 2.0, 1.8
	local pedX = mainDeskX + mainDeskW / 2 - pedW / 2 - 0.2
	local pedZ = mainDeskZ
	b:box(
		"PedestalBody",
		Vector3.new(pedW, pedH, pedD),
		Kit.at(pedX, pedH / 2 + 0.08, pedZ),
		TrimDark,
		Enum.Material.Metal
	)
	-- 3 Drawers & handles
	for dIdx = 1, 3 do
		local dy = 0.35 + (dIdx - 1) * 0.6
		b:box(
			`PedDrawer_{dIdx}`,
			Vector3.new(pedW - 0.08, 0.52, 0.04),
			Kit.at(pedX, dy, pedZ - pedD / 2 - 0.02),
			Color3.fromRGB(60, 64, 68),
			Enum.Material.Metal
		)
		b:box(
			`PedHandle_{dIdx}`,
			Vector3.new(0.4, 0.04, 0.05),
			Kit.at(pedX, dy, pedZ - pedD / 2 - 0.05),
			C.Chrome,
			Enum.Material.Metal
		)
	end
	-- Casters on pedestal
	for _, cz in { -pedD / 2 + 0.2, pedD / 2 - 0.2 } do
		for _, cx in { -pedW / 2 + 0.2, pedW / 2 - 0.2 } do
			b:cyl(
				`PedCaster_{cx}_{cz}`,
				0.06,
				0.12,
				Kit.alongZ(pedX + cx, 0.04, pedZ + cz),
				C.RubberBlack,
				Enum.Material.Rubber
			)
		end
	end

	-- Desk cable grommets
	b:cyl(
		"DeskGrommet1",
		0.02,
		0.25,
		Kit.vertical(mainDeskX + 1.2, deskH + 0.01, mainDeskZ + 0.7),
		TrimDark,
		Enum.Material.SmoothPlastic
	)
	b:cyl(
		"DeskGrommet2",
		0.02,
		0.25,
		Kit.vertical(retDeskX - 0.4, deskH + 0.01, retDeskZ - 0.8),
		TrimDark,
		Enum.Material.SmoothPlastic
	)

	-- Pinned notes / memos on back fabric panel under cabinet
	b:box(
		"PinnedNote1",
		Vector3.new(0.7, 0.9, 0.01),
		Kit.at(mainDeskX - 1.2, 3.0, d / 2 - panelThick - 0.01),
		TackNoteColor1,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"PinnedNote2",
		Vector3.new(0.6, 0.7, 0.01),
		Kit.at(mainDeskX - 0.3, 2.9, d / 2 - panelThick - 0.01),
		TackNoteColor2,
		Enum.Material.SmoothPlastic
	)
	-- Pushpins
	b:ball(
		"PushPin1",
		0.06,
		Kit.at(mainDeskX - 1.2, 3.4, d / 2 - panelThick - 0.02),
		Color3.fromRGB(220, 40, 30),
		Enum.Material.SmoothPlastic
	)
	b:ball(
		"PushPin2",
		0.06,
		Kit.at(mainDeskX - 0.3, 3.2, d / 2 - panelThick - 0.02),
		Color3.fromRGB(30, 100, 220),
		Enum.Material.SmoothPlastic
	)

	-- Computer display & keyboard on return desk
	b:box(
		"MonitorStand",
		Vector3.new(0.6, 0.03, 0.5),
		Kit.at(retDeskX, deskH + 0.02, retDeskZ + 0.5),
		TrimDark,
		Enum.Material.Metal
	)
	b:box(
		"MonitorArm",
		Vector3.new(0.12, 0.7, 0.1),
		Kit.at(retDeskX, deskH + 0.37, retDeskZ + 0.5),
		TrimDark,
		Enum.Material.Metal
	)
	local screen = b:box(
		"MonitorScreen",
		Vector3.new(1.6, 1.0, 0.06),
		Kit.at(retDeskX - 0.9, deskH + 0.9, retDeskZ + 0.5),
		Color3.fromRGB(186, 214, 232),
		Enum.Material.SmoothPlastic
	)
	screen.Material = Enum.Material.SmoothPlastic
	b:box(
		"MonitorScreen2",
		Vector3.new(1.4, 0.9, 0.06),
		Kit.at(retDeskX + 0.9, deskH + 0.85, retDeskZ + 0.5),
		Color3.fromRGB(176, 206, 224),
		Enum.Material.SmoothPlastic
	)
	b:box(
		"DeskPaper",
		Vector3.new(0.85, 0.01, 0.65),
		Kit.at(retDeskX, deskH + 0.02, retDeskZ - 0.55),
		Color3.fromRGB(244, 242, 232),
		Enum.Material.SmoothPlastic
	)
	b:box(
		"Keyboard",
		Vector3.new(1.3, 0.03, 0.45),
		Kit.at(retDeskX, deskH + 0.02, retDeskZ - 0.2),
		TrimDark,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"MousePad",
		Vector3.new(0.5, 0.01, 0.5),
		Kit.at(retDeskX + 0.55, deskH + 0.01, retDeskZ - 0.2),
		Color3.fromRGB(30, 30, 32),
		Enum.Material.Fabric
	)

	return b:done()
end

return Cubicle
