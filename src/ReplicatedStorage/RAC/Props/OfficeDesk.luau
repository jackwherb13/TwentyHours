--!strict
-- Standard commercial office desk with steel frame, drawer pedestal, modesty panel, and monitor setup.
local Kit = require(script.Parent.Kit)

local OfficeDesk = {
	kind = "office_desk",
	size = Vector3.new(5.0, 4.0, 2.5),
}

local TopColor = Color3.fromRGB(225, 222, 215)
local SteelDark = Color3.fromRGB(45, 48, 52)
local DrawerGrey = Color3.fromRGB(75, 78, 82)
local BlotterColor = Color3.fromRGB(35, 38, 42)

function OfficeDesk.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("OfficeDesk", cf)
	local C = Kit.Color

	local deskW, deskD, deskH = 5.0, 2.5, 2.5
	local legThick = 0.15

	-- 1. Desktop surface (bevel-trimmed laminate top)
	b:box(
		"DeskTop",
		Vector3.new(deskW, 0.1, deskD),
		Kit.at(0, deskH - 0.05, 0),
		TopColor,
		Enum.Material.SmoothPlastic,
		true
	)

	-- 2. Steel structural frame under top
	b:box(
		"FrameSpine",
		Vector3.new(deskW - 0.6, 0.12, 0.12),
		Kit.at(0, deskH - 0.16, 0.4),
		SteelDark,
		Enum.Material.Metal
	)

	-- 3. U-shaped steel legs on left and right
	for _, xSign in { -1, 1 } do
		local x = xSign * (deskW / 2 - 0.25)
		-- Front upright
		b:box(
			`LegFront_{xSign}`,
			Vector3.new(legThick, deskH - 0.1, legThick),
			Kit.at(x, (deskH - 0.1) / 2 + 0.04, -deskD / 2 + 0.25),
			SteelDark,
			Enum.Material.Metal
		)
		-- Rear upright
		b:box(
			`LegRear_{xSign}`,
			Vector3.new(legThick, deskH - 0.1, legThick),
			Kit.at(x, (deskH - 0.1) / 2 + 0.04, deskD / 2 - 0.25),
			SteelDark,
			Enum.Material.Metal
		)
		-- Bottom horizontal foot bar connecting front and rear
		b:box(
			`LegFoot_{xSign}`,
			Vector3.new(legThick, 0.08, deskD - 0.3),
			Kit.at(x, 0.07, 0),
			SteelDark,
			Enum.Material.Metal
		)
		-- Top horizontal mounting bar connecting uprights to top
		b:box(
			`LegTopBar_{xSign}`,
			Vector3.new(legThick, 0.08, deskD - 0.3),
			Kit.at(x, deskH - 0.14, 0),
			SteelDark,
			Enum.Material.Metal
		)
		-- Leveling glides
		for _, zSign in { -1, 1 } do
			b:cyl(
				`Glide_{xSign}_{zSign}`,
				0.04,
				0.12,
				Kit.vertical(x, 0.02, zSign * (deskD / 2 - 0.3)),
				C.Chrome,
				Enum.Material.Metal
			)
		end
	end

	-- 4. Modesty panel (suspended at rear +Z)
	b:box(
		"ModestyPanel",
		Vector3.new(deskW - 0.8, 1.2, 0.04),
		Kit.at(0, deskH - 0.8, deskD / 2 - 0.28),
		SteelDark,
		Enum.Material.Metal
	)

	-- 5. Under-desk 3-drawer pedestal unit (right side)
	local pedW, pedH, pedD = 1.25, 2.0, 1.8
	local pedX = deskW / 2 - pedW / 2 - 0.4
	local pedZ = 0.05
	b:box(
		"PedestalCasing",
		Vector3.new(pedW, pedH, pedD),
		Kit.at(pedX, pedH / 2 + 0.08, pedZ),
		SteelDark,
		Enum.Material.Metal
	)
	-- Drawer faces & handles
	for d = 1, 3 do
		local dy = 0.35 + (d - 1) * 0.6
		b:box(
			`DrawerFace_{d}`,
			Vector3.new(pedW - 0.08, 0.54, 0.03),
			Kit.at(pedX, dy, pedZ - pedD / 2 - 0.02),
			DrawerGrey,
			Enum.Material.Metal
		)
		b:box(
			`DrawerHandle_{d}`,
			Vector3.new(0.4, 0.04, 0.05),
			Kit.at(pedX, dy, pedZ - pedD / 2 - 0.05),
			C.Chrome,
			Enum.Material.Metal
		)
	end
	-- Lock cylinder on top drawer
	b:cyl(
		"PedLock",
		0.03,
		0.06,
		Kit.alongZ(pedX + pedW / 2 - 0.15, 1.75, pedZ - pedD / 2 - 0.02),
		C.Chrome,
		Enum.Material.Metal
	)

	-- 6. Cable management
	b:cyl(
		"Grommet_Left",
		0.02,
		0.22,
		Kit.vertical(-deskW / 2 + 0.6, deskH + 0.01, deskD / 2 - 0.4),
		SteelDark,
		Enum.Material.SmoothPlastic
	)
	b:cyl(
		"Grommet_Right",
		0.02,
		0.22,
		Kit.vertical(deskW / 2 - 0.6, deskH + 0.01, deskD / 2 - 0.4),
		SteelDark,
		Enum.Material.SmoothPlastic
	)
	-- Under-desk wire raceway tray
	b:box(
		"CableTray",
		Vector3.new(deskW - 1.8, 0.15, 0.4),
		Kit.at(-0.4, deskH - 0.35, 0.4),
		SteelDark,
		Enum.Material.Metal
	)

	-- 7. Desktop blotter & accessories
	b:box(
		"DeskBlotter",
		Vector3.new(2.4, 0.01, 1.4),
		Kit.at(-0.3, deskH + 0.005, -0.2),
		BlotterColor,
		Enum.Material.Leather
	)
	b:box(
		"Keyboard",
		Vector3.new(1.3, 0.03, 0.42),
		Kit.at(-0.3, deskH + 0.025, -0.2),
		SteelDark,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"Mouse",
		Vector3.new(0.2, 0.04, 0.3),
		Kit.at(0.65, deskH + 0.03, -0.2),
		SteelDark,
		Enum.Material.SmoothPlastic
	)

	-- 8. Computer monitor on articulated arm
	local monX, monZ = -0.3, 0.5
	b:box(
		"MonitorArmBase",
		Vector3.new(0.3, 0.06, 0.3),
		Kit.at(monX, deskH + 0.03, monZ),
		SteelDark,
		Enum.Material.Metal
	)
	b:cyl("MonitorArmPost", 0.8, 0.08, Kit.vertical(monX, deskH + 0.43, monZ), C.Chrome, Enum.Material.Metal)
	b:box(
		"MonitorArmJoint",
		Vector3.new(0.12, 0.52, 0.35),
		Kit.at(monX, deskH + 0.65, monZ - 0.15),
		SteelDark,
		Enum.Material.Metal
	)
	b:box(
		"MonitorBezel",
		Vector3.new(1.8, 1.1, 0.08),
		Kit.at(monX, deskH + 0.95, monZ - 0.3),
		SteelDark,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"MonitorScreen",
		Vector3.new(1.7, 1.0, 0.02),
		Kit.at(monX, deskH + 0.95, monZ - 0.35),
		C.Screen,
		Enum.Material.SmoothPlastic
	)

	-- 9. Pencil cup
	b:cyl("PencilCup", 0.32, 0.25, Kit.vertical(-deskW / 2 + 0.8, deskH + 0.16, 0.1), C.Chrome, Enum.Material.Metal)

	return b:done()
end

return OfficeDesk
