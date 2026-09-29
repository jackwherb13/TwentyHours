--!strict
-- Commercial refrigerated beverage vending machine (Coca-Cola red style).
-- Reference: IMG_0339 (red cold drink vending machine in corridor).
local Kit = require(script.Parent.Kit)

local VendingMachine = {
	kind = "vending_machine",
	size = Vector3.new(3.8, 6.0, 3.2),
}

local MachineRed = Color3.fromRGB(205, 25, 30)
local DarkRed = Color3.fromRGB(150, 18, 22)
local CabinetBlack = Color3.fromRGB(28, 30, 32)
local DisplayGreen = Color3.fromRGB(50, 220, 90)
local CanWhite = Color3.fromRGB(240, 240, 245)
local DrinkBlue = Color3.fromRGB(20, 80, 190)

function VendingMachine.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("VendingMachine", cf)
	local C = Kit.Color

	local w, h, d = 3.5, 6.0, 3.0
	local rearPad = if opts and type(opts.rearPad) == "number" then opts.rearPad else 0
	local segH = h / 3
	local frontZ = -d / 2
	local rearZ = d / 2 - 0.05
	local baseH = 0.35

	-- 1. Cabinet Base & Leveling Feet
	b:box(
		"CabinetBase",
		Vector3.new(w - 0.2, baseH, d - 0.2),
		Kit.at(0, baseH / 2, 0.05),
		CabinetBlack,
		Enum.Material.Metal,
		true
	)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			b:cyl(
				`Leveler_{sx}_{sz}`,
				0.06,
				0.18,
				Kit.vertical(sx * (w / 2 - 0.3), 0.03, sz * (d / 2 - 0.3)),
				C.Chrome,
				Enum.Material.Metal
			)
		end
	end

	-- 2. Main Outer Cabinet (Split in 3 vertical segments for radial bounding check)
	for seg = 1, 3 do
		local sy = (seg - 0.5) * segH
		-- Left red side panel
		b:box(
			`SidePanel_L_{seg}`,
			Vector3.new(0.08, segH, d),
			Kit.at(-w / 2 + 0.04, sy, 0),
			MachineRed,
			Enum.Material.SmoothPlastic,
			true
		)
		-- Right red side panel
		b:box(
			`SidePanel_R_{seg}`,
			Vector3.new(0.08, segH, d),
			Kit.at(w / 2 - 0.04, sy, 0),
			MachineRed,
			Enum.Material.SmoothPlastic,
			true
		)
		-- Rear black wall
		b:box(
			`RearWall_{seg}`,
			Vector3.new(w - 0.16, segH, 0.06 + rearPad),
			Kit.at(0, sy, rearZ + rearPad / 2),
			CabinetBlack,
			Enum.Material.Metal
		)
		-- Internal partition between showcase and controls
		b:box(
			`ControlDivider_{seg}`,
			Vector3.new(0.04, segH, d * 0.8),
			Kit.at(w / 2 - 1.1, sy, 0),
			CabinetBlack,
			Enum.Material.Metal
		)
	end
	-- Cabinet top cap (split in 2 for bounds)
	b:box(
		"CabinetTop_1",
		Vector3.new(w / 2, 0.08, d),
		Kit.at(-w / 4, h - 0.04, 0),
		MachineRed,
		Enum.Material.SmoothPlastic,
		true
	)
	b:box(
		"CabinetTop_2",
		Vector3.new(w / 2, 0.08, d),
		Kit.at(w / 4, h - 0.04, 0),
		MachineRed,
		Enum.Material.SmoothPlastic,
		true
	)

	-- 3. Top Illuminated Header Graphic Panel ("ICE COLD DRINKS")
	local headerH = 0.85
	local headerY = h - 0.08 - headerH / 2
	b:box(
		"HeaderPanel",
		Vector3.new(w - 0.2, headerH, 0.06),
		Kit.at(0, headerY, frontZ + 0.03),
		DarkRed,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"HeaderGlow",
		Vector3.new(w - 0.3, headerH - 0.1, 0.02),
		Kit.at(0, headerY, frontZ),
		Color3.fromRGB(255, 230, 230),
		Enum.Material.Neon
	)

	-- 4. Left Showcase: Glass front displaying cold beverages
	local showW = w - 1.2
	local showX = -w / 2 + showW / 2 + 0.06
	local showH = 3.3
	local halfShowH = showH / 2
	local showBaseY = baseH + 1.2
	local showZ = frontZ + 0.1

	-- Outer showcase glass window (split in half)
	b:box(
		"ShowcaseGlass_1",
		Vector3.new(showW, halfShowH, 0.03),
		Kit.at(showX, showBaseY + halfShowH / 2, frontZ + 0.01),
		C.Glass,
		Enum.Material.Glass
	)
	b:box(
		"ShowcaseGlass_2",
		Vector3.new(showW, halfShowH, 0.03),
		Kit.at(showX, showBaseY + halfShowH + halfShowH / 2, frontZ + 0.01),
		C.Glass,
		Enum.Material.Glass
	)

	-- Showcase interior back panel (split in half)
	b:box(
		"ShowcaseBack_1",
		Vector3.new(showW - 0.06, halfShowH, 0.04),
		Kit.at(showX, showBaseY + halfShowH / 2, showZ + 1.0),
		CabinetBlack,
		Enum.Material.Metal
	)
	b:box(
		"ShowcaseBack_2",
		Vector3.new(showW - 0.06, halfShowH, 0.04),
		Kit.at(showX, showBaseY + halfShowH + halfShowH / 2, showZ + 1.0),
		CabinetBlack,
		Enum.Material.Metal
	)

	-- 4 Beverage shelves with bottles / cans
	for s = 1, 4 do
		local shelfY = baseH + 1.2 + (s - 0.5) * (showH / 4)
		-- Shelf wire tray
		b:box(
			`Shelf_{s}`,
			Vector3.new(showW - 0.1, 0.04, 0.9),
			Kit.at(showX, shelfY, showZ + 0.5),
			C.Chrome,
			Enum.Material.Metal
		)
		-- Row of drink bottles / cans on shelf
		for col = 1, 5 do
			local canX = showX - (showW / 2) + 0.2 + (col - 0.5) * 0.38
			local canColor = if col % 2 == 0 then DrinkBlue else CanWhite
			b:cyl(
				`DrinkCan_{s}_{col}`,
				0.45,
				0.22,
				Kit.vertical(canX, shelfY + 0.25, showZ + 0.3),
				canColor,
				Enum.Material.SmoothPlastic
			)
		end
	end
	-- Interior showcase illumination
	local showcaseLight = b:box(
		"ShowcaseLedStrip",
		Vector3.new(showW - 0.1, 0.04, 0.04),
		Kit.at(showX, showBaseY + showH - 0.05, frontZ + 0.1),
		Color3.fromRGB(255, 255, 250),
		Enum.Material.Neon
	)
	showcaseLight.CastShadow = false

	-- 5. Right User Interface Column (Controls, Payment, Selection)
	local ctrlW = 1.0
	local ctrlX = w / 2 - ctrlW / 2 - 0.06
	local ctrlY = baseH + 1.2 + showH / 2

	-- Control faceplate bezel (black & brushed aluminum, split in half)
	b:box(
		"ControlPanelBezel_1",
		Vector3.new(ctrlW, halfShowH, 0.05),
		Kit.at(ctrlX, showBaseY + halfShowH / 2, frontZ + 0.02),
		CabinetBlack,
		Enum.Material.Metal
	)
	b:box(
		"ControlPanelBezel_2",
		Vector3.new(ctrlW, halfShowH, 0.05),
		Kit.at(ctrlX, showBaseY + halfShowH + halfShowH / 2, frontZ + 0.02),
		CabinetBlack,
		Enum.Material.Metal
	)

	-- Digital LED vacuum fluorescent price display
	b:box(
		"DisplayBezel",
		Vector3.new(0.65, 0.2, 0.02),
		Kit.at(ctrlX, ctrlY + 1.1, frontZ - 0.01),
		CabinetBlack,
		Enum.Material.SmoothPlastic
	)
	local dispLed = b:box(
		"DisplayScreen",
		Vector3.new(0.55, 0.12, 0.01),
		Kit.at(ctrlX, ctrlY + 1.1, frontZ - 0.02),
		DisplayGreen,
		Enum.Material.Neon
	)
	dispLed.CastShadow = false

	-- Keypad buttons (selection matrix)
	for row = 1, 4 do
		for col = 1, 2 do
			local bx = ctrlX - 0.15 + (col - 1) * 0.3
			local by = ctrlY + 0.7 - (row - 1) * 0.22
			b:box(
				`KeypadBtn_{row}_{col}`,
				Vector3.new(0.12, 0.12, 0.02),
				Kit.at(bx, by, frontZ - 0.01),
				Color3.fromRGB(80, 85, 90),
				Enum.Material.SmoothPlastic
			)
		end
	end

	-- Bill validator slot (illuminated green bezel)
	b:box(
		"BillBezel",
		Vector3.new(0.55, 0.22, 0.03),
		Kit.at(ctrlX, ctrlY - 0.45, frontZ - 0.01),
		CabinetBlack,
		Enum.Material.SmoothPlastic
	)
	local billSlot = b:box(
		"BillSlotGlow",
		Vector3.new(0.42, 0.04, 0.01),
		Kit.at(ctrlX, ctrlY - 0.45, frontZ - 0.025),
		DisplayGreen,
		Enum.Material.Neon
	)
	billSlot.CastShadow = false

	-- Coin insert slot & coin return cup
	b:box(
		"CoinBezel",
		Vector3.new(0.2, 0.3, 0.02),
		Kit.at(ctrlX, ctrlY - 0.8, frontZ - 0.01),
		C.Chrome,
		Enum.Material.Metal
	)
	b:box(
		"CoinSlot",
		Vector3.new(0.03, 0.12, 0.01),
		Kit.at(ctrlX, ctrlY - 0.78, frontZ - 0.02),
		CabinetBlack,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"CoinReturnCup",
		Vector3.new(0.3, 0.25, 0.15),
		Kit.at(ctrlX, ctrlY - 1.25, frontZ + 0.05),
		CabinetBlack,
		Enum.Material.Metal
	)

	-- 6. Bottom Delivery Chute / Retrieval Bin
	local chuteW = w - 0.8
	local chuteH = 0.95
	local chuteY = baseH + chuteH / 2 + 0.1
	-- Chute opening recess
	b:box(
		"DeliveryChuteRecess",
		Vector3.new(chuteW, chuteH, 0.8),
		Kit.at(-0.1, chuteY, frontZ + 0.4),
		CabinetBlack,
		Enum.Material.Metal
	)
	-- Push flap door
	b:box(
		"DeliveryFlapDoor",
		Vector3.new(chuteW - 0.1, chuteH - 0.1, 0.04),
		Kit.at(-0.1, chuteY, frontZ + 0.05),
		Color3.fromRGB(45, 48, 52),
		Enum.Material.Metal
	)
	-- Flap handle bar
	b:box(
		"DeliveryHandleBar",
		Vector3.new(chuteW - 0.3, 0.05, 0.04),
		Kit.at(-0.1, chuteY + 0.2, frontZ + 0.01),
		C.Chrome,
		Enum.Material.Metal
	)

	return b:done()
end

return VendingMachine
