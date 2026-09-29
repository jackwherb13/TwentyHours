--!strict
-- RAC Lobby Front Reception Desk.
-- Reference: IMG_0369 (long counter with translucent frosted panels, bronze frame, white quartz top, clerk desk behind).
local Kit = require(script.Parent.Kit)

local FrontDesk = {
	kind = "front_desk",
	size = Vector3.new(16.0, 4.8, 7.5),
}

local Bronze = Color3.fromRGB(85, 75, 65)
local CounterWhite = Color3.fromRGB(245, 245, 242)
local FrostedGlass = Color3.fromRGB(215, 225, 228)
local DeskGrey = Color3.fromRGB(210, 210, 205)
local DarkMetal = Color3.fromRGB(40, 42, 45)
local MasonGreen = Color3.fromRGB(0, 110, 52)
local MasonGold = Color3.fromRGB(235, 185, 45)

local function buildU(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("FrontDesk", cf)
	local length = (opts and opts.length) or 12
	local depth = (opts and opts.depth) or 6
	local counterH = 3.6
	local frontZ = -depth / 2 + 0.55
	local armX = length / 2 - 0.35
	b:box(
		"FrontCounter",
		Vector3.new(length, 0.16, 1.15),
		Kit.at(0, counterH, frontZ),
		CounterWhite,
		Enum.Material.SmoothPlastic,
		true
	)
	b:box(
		"FrontPanel",
		Vector3.new(length - 0.2, counterH - 0.2, 0.12),
		Kit.at(0, counterH / 2, frontZ - 0.45),
		CounterWhite,
		Enum.Material.SmoothPlastic,
		true
	)
	b:box(
		"LeftReturn",
		Vector3.new(0.7, counterH, depth - 1.4),
		Kit.at(-armX, counterH / 2, 0.3),
		CounterWhite,
		Enum.Material.SmoothPlastic,
		true
	)
	b:box(
		"RightReturn",
		Vector3.new(0.7, counterH, depth - 1.4),
		Kit.at(armX, counterH / 2, 0.3),
		CounterWhite,
		Enum.Material.SmoothPlastic,
		true
	)
	b:box(
		"LeftTop",
		Vector3.new(0.85, 0.16, depth - 1.2),
		Kit.at(-armX, counterH, 0.3),
		CounterWhite,
		Enum.Material.SmoothPlastic,
		true
	)
	b:box(
		"RightTop",
		Vector3.new(0.85, 0.16, depth - 1.2),
		Kit.at(armX, counterH, 0.3),
		CounterWhite,
		Enum.Material.SmoothPlastic,
		true
	)
	local mark = b:box(
		"MarkPlate",
		Vector3.new(2.4, 1.1, 0.08),
		Kit.at(0, 2.05, frontZ - 0.52),
		MasonGreen,
		Enum.Material.SmoothPlastic,
		false
	)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Logo"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 64
	gui.LightInfluence = 0.15
	gui.Parent = mark
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "GM"
	label.TextColor3 = MasonGold
	label.TextScaled = true
	label.Parent = gui
	-- Staff counter fills the open well. Stations and screens stack on it; each bottom meets the piece under it.
	local topY = 2.46
	b:box(
		"StaffModesty",
		Vector3.new(length - 3.4, 2.4, 0.16),
		Kit.at(0, 1.2, 0.2),
		CounterWhite,
		Enum.Material.SmoothPlastic,
		true
	)
	b:box(
		"StaffTop",
		Vector3.new(length - 2.2, 0.12, 2.2),
		Kit.at(0, topY, 0.2),
		CounterWhite,
		Enum.Material.SmoothPlastic,
		true
	)
	local stationBottom = topY + 0.06 - 0.02
	local stationH = 0.08
	local screenH = 0.7
	for index, x in { -length * 0.28, -length * 0.1, length * 0.08, length * 0.26 } do
		b:box(
			`Station_{index}`,
			Vector3.new(1.4, stationH, 0.7),
			Kit.at(x, stationBottom + stationH / 2, 0.2),
			CounterWhite,
			Enum.Material.SmoothPlastic,
			true
		)
		b:box(
			`Screen_{index}`,
			Vector3.new(1.1, screenH, 0.5),
			Kit.at(x, stationBottom + stationH + screenH / 2 - 0.01, 0.05),
			DarkMetal,
			Enum.Material.SmoothPlastic,
			false
		)
	end
	return b:done()
end

function FrontDesk.build(cf: CFrame, opts: { [string]: any }?): Model
	if opts ~= nil and opts.shape == "u" then
		return buildU(cf, opts)
	end
	local b = Kit.new("FrontDesk", cf)
	local C = Kit.Color

	local numBays = (opts and opts.bays) or 4
	local totalLength = (opts and opts.length) or 16.0
	local totalDepth = (opts and opts.depth) or 7.5
	local counterHeight = 3.6
	local deskHeight = 2.5
	local bayWidth = totalLength / numBays

	-- Front transaction counter is at -Z (z = -totalDepth/2 + 0.6)
	-- Clerk desk surface is at +Z (z = 0.3)
	local frontFaceZ = -totalDepth / 2 + 0.25

	-- Base kickplate (recessed, dark)
	b:box(
		"BaseKick",
		Vector3.new(totalLength - 0.2, 0.35, 0.15),
		Kit.at(0, 0.175, frontFaceZ + 0.15),
		DarkMetal,
		Enum.Material.SmoothPlastic
	)

	-- Upper transaction countertop (white quartz / solid surface)
	b:box(
		"TransactionCounter",
		Vector3.new(totalLength + 0.2, 0.15, 1.3),
		Kit.at(0, counterHeight - 0.075, frontFaceZ + 0.5),
		CounterWhite,
		Enum.Material.SmoothPlastic,
		true
	)
	-- Counter front nosing trim
	b:box(
		"CounterNosing",
		Vector3.new(totalLength + 0.25, 0.08, 0.1),
		Kit.at(0, counterHeight - 0.08, frontFaceZ - 0.16),
		CounterWhite,
		Enum.Material.SmoothPlastic
	)

	-- Lower horizontal rail above base
	b:box("LowerRail", Vector3.new(totalLength, 0.1, 0.15), Kit.at(0, 0.4, frontFaceZ), Bronze, Enum.Material.Metal)
	-- Upper horizontal rail below counter
	b:box(
		"UpperRail",
		Vector3.new(totalLength, 0.1, 0.15),
		Kit.at(0, counterHeight - 0.2, frontFaceZ),
		Bronze,
		Enum.Material.Metal
	)

	-- Vertical mullions / posts dividing bays
	for i = 0, numBays do
		local x = -totalLength / 2 + i * bayWidth
		b:box(
			`Mullion_{i}`,
			Vector3.new(0.12, counterHeight - 0.5, 0.18),
			Kit.at(x, (counterHeight + 0.35) / 2, frontFaceZ),
			Bronze,
			Enum.Material.Metal
		)
	end

	-- Bay panels (translucent frosted panels with backlit warmth)
	local panelHeight = counterHeight - 0.65
	local panelWidth = bayWidth - 0.15
	for i = 1, numBays do
		local x = -totalLength / 2 + (i - 0.5) * bayWidth
		-- Frosted front panel
		local panel = b:box(
			`FrostedPanel_{i}`,
			Vector3.new(panelWidth, panelHeight, 0.08),
			Kit.at(x, 0.45 + panelHeight / 2, frontFaceZ),
			FrostedGlass,
			Enum.Material.Glass,
			true
		)
		panel.Transparency = 0.45
		-- Backlit glow behind panel
		local glow = b:box(
			`PanelGlow_{i}`,
			Vector3.new(panelWidth - 0.1, panelHeight - 0.1, 0.04),
			Kit.at(x, 0.45 + panelHeight / 2, frontFaceZ + 0.08),
			Color3.fromRGB(240, 230, 205),
			Enum.Material.Neon
		)
		glow.CastShadow = false
	end

	-- Clerk work desk surface (lower tier behind transaction wall)
	local clerkDeskZ = totalDepth * 0.12
	local deskDepth = math.max(2.1, totalDepth * 0.42)
	b:box(
		"ClerkDeskSurface",
		Vector3.new(totalLength - 0.3, 0.1, deskDepth),
		Kit.at(0, deskHeight - 0.05, clerkDeskZ),
		DeskGrey,
		Enum.Material.SmoothPlastic,
		true
	)

	-- Clerk knee-wall divider supporting the counter
	b:box(
		"KneePanel",
		Vector3.new(totalLength - 0.3, counterHeight - 0.2, 0.2),
		Kit.at(0, (counterHeight - 0.2) / 2, frontFaceZ + 1.1),
		Bronze,
		Enum.Material.SmoothPlastic,
		true
	)

	-- Left and right desk end panels / gables
	for s = -1, 1, 2 do
		local x = s * (totalLength / 2 - 0.08)
		b:box(
			`EndPanel_{s}`,
			Vector3.new(0.12, counterHeight, totalDepth - 0.4),
			Kit.at(x, counterHeight / 2, 0.1),
			Bronze,
			Enum.Material.SmoothPlastic,
			true
		)
	end

	-- Storage cubbies / drawer pedestals under clerk desk
	for _, xOffset in { -totalLength * 0.3, totalLength * 0.3 } do
		b:box(
			`Pedestal_{xOffset}`,
			Vector3.new(1.3, deskHeight - 0.15, 1.8),
			Kit.at(xOffset, (deskHeight - 0.15) / 2 + 0.05, clerkDeskZ),
			Bronze,
			Enum.Material.SmoothPlastic
		)
		for d = 1, 3 do
			local dy = 0.2 + (d - 1) * 0.7
			b:box(
				`DrawerHandle_{xOffset}_{d}`,
				Vector3.new(0.4, 0.04, 0.06),
				Kit.at(xOffset, dy, clerkDeskZ + 0.93),
				C.Chrome,
				Enum.Material.Metal
			)
		end
	end

	-- Clerk computer monitors & wire grommets
	for _, stationX in { -totalLength * 0.25, totalLength * 0.25 } do
		-- Grommet cap
		b:cyl(
			`Grommet_{stationX}`,
			0.02,
			0.25,
			Kit.vertical(stationX + 0.8, deskHeight + 0.01, clerkDeskZ - 0.6),
			DarkMetal,
			Enum.Material.SmoothPlastic
		)
		-- Monitor base
		b:box(
			`MonitorBase_{stationX}`,
			Vector3.new(0.8, 0.04, 0.6),
			Kit.at(stationX, deskHeight + 0.02, clerkDeskZ - 0.2),
			DarkMetal,
			Enum.Material.Metal
		)
		-- Monitor stand neck
		b:box(
			`MonitorNeck_{stationX}`,
			Vector3.new(0.15, 0.8, 0.1),
			Kit.at(stationX, deskHeight + 0.42, clerkDeskZ - 0.2),
			DarkMetal,
			Enum.Material.Metal
		)
		-- Monitor display
		b:box(
			`MonitorBezel_{stationX}`,
			Vector3.new(1.8, 1.1, 0.08),
			Kit.at(stationX, deskHeight + 1.0, clerkDeskZ - 0.2),
			DarkMetal,
			Enum.Material.SmoothPlastic
		)
		b:box(
			`MonitorScreen_{stationX}`,
			Vector3.new(1.7, 1.0, 0.02),
			Kit.at(stationX, deskHeight + 1.0, clerkDeskZ - 0.15),
			C.Screen,
			Enum.Material.SmoothPlastic
		)
		-- Keyboard
		b:box(
			`Keyboard_{stationX}`,
			Vector3.new(1.4, 0.04, 0.45),
			Kit.at(stationX, deskHeight + 0.02, clerkDeskZ + 0.4),
			DarkMetal,
			Enum.Material.SmoothPlastic
		)
	end

	return b:done()
end

return FrontDesk
