--!strict
-- Office mail sorter / slot cabinet unit.
-- Reference: IMG_0323 (grey laminate 3-column multi-slot mail organizer).
local Kit = require(script.Parent.Kit)

local MailSlots = {
	kind = "mail_slots",
	size = Vector3.new(2.8, 3.5, 1.2),
}

local CabinetGrey = Color3.fromRGB(195, 198, 200)
local ShelfGrey = Color3.fromRGB(215, 218, 220)
local LabelStripColor = Color3.fromRGB(150, 155, 160)
local ManilaPaper = Color3.fromRGB(230, 215, 180)
local WhiteMail = Color3.fromRGB(245, 245, 245)

function MailSlots.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("MailSlots", cf)

	local w, h, d = 2.8, 3.5, 1.2
	local t = 0.06 -- panel thickness
	local halfH = h / 2
	local rearZ = d / 2 - t / 2
	local midZ = -t / 2

	-- Top & Bottom horizontal panels
	b:box("CabinetTop", Vector3.new(w, t, d), Kit.at(0, h - t / 2, 0), CabinetGrey, Enum.Material.SmoothPlastic, true)
	b:box("CabinetBottom", Vector3.new(w, t, d), Kit.at(0, t / 2, 0), CabinetGrey, Enum.Material.SmoothPlastic, true)

	-- Back panel (split in 2 for bounds)
	b:box(
		"BackLower",
		Vector3.new(w - 2 * t, halfH, t),
		Kit.at(0, halfH / 2, rearZ),
		CabinetGrey,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"BackUpper",
		Vector3.new(w - 2 * t, halfH, t),
		Kit.at(0, halfH + halfH / 2, rearZ),
		CabinetGrey,
		Enum.Material.SmoothPlastic
	)

	-- Left and right outer side panels (each split into lower and upper halves)
	for _, s in { -1, 1 } do
		local x = s * (w / 2 - t / 2)
		b:box(
			`SideLower_{s}`,
			Vector3.new(t, halfH, d),
			Kit.at(x, halfH / 2, 0),
			CabinetGrey,
			Enum.Material.SmoothPlastic,
			true
		)
		b:box(
			`SideUpper_{s}`,
			Vector3.new(t, halfH, d),
			Kit.at(x, halfH + halfH / 2, 0),
			CabinetGrey,
			Enum.Material.SmoothPlastic,
			true
		)
	end

	-- 2 vertical dividers separating the 3 columns
	local colW = (w - 4 * t) / 3
	for c = 1, 2 do
		local x = -w / 2 + t + c * colW + (c - 0.5) * t
		b:box(
			`DividerLower_{c}`,
			Vector3.new(t, halfH, d - t),
			Kit.at(x, halfH / 2, midZ),
			CabinetGrey,
			Enum.Material.SmoothPlastic
		)
		b:box(
			`DividerUpper_{c}`,
			Vector3.new(t, halfH, d - t),
			Kit.at(x, halfH + halfH / 2, midZ),
			CabinetGrey,
			Enum.Material.SmoothPlastic
		)
	end

	-- 8 horizontal shelves across the 3 columns
	local numShelves = 8
	local shelfSpacing = (h - 2 * t) / (numShelves + 1)
	for s = 1, numShelves do
		local sy = t + s * shelfSpacing
		-- Shelf across entire width
		b:box(
			`Shelf_{s}`,
			Vector3.new(w - 2 * t, 0.03, d - t),
			Kit.at(0, sy, midZ),
			ShelfGrey,
			Enum.Material.SmoothPlastic
		)
		-- Label holder trim strip on front edge
		b:box(
			`LabelStrip_{s}`,
			Vector3.new(w - 2 * t, 0.04, 0.02),
			Kit.at(0, sy, -d / 2 + 0.02),
			LabelStripColor,
			Enum.Material.Metal
		)
	end

	-- Inserted mail items in several slots
	local mailSlots = {
		{ col = 1, row = 2, color = ManilaPaper, len = 0.7, thick = 0.08, protrude = 0.15 },
		{ col = 2, row = 4, color = WhiteMail, len = 0.65, thick = 0.04, protrude = 0.1 },
		{ col = 3, row = 1, color = ManilaPaper, len = 0.72, thick = 0.1, protrude = 0.2 },
		{ col = 1, row = 6, color = WhiteMail, len = 0.68, thick = 0.03, protrude = 0.08 },
		{ col = 2, row = 7, color = ManilaPaper, len = 0.7, thick = 0.06, protrude = 0.12 },
		{ col = 3, row = 5, color = WhiteMail, len = 0.6, thick = 0.05, protrude = 0.14 },
	}

	for idx, item in ipairs(mailSlots) do
		local colCenterX = -w / 2 + t + (item.col - 0.5) * colW + (item.col - 1) * t
		local shelfTop = if item.row == 1 then t else t + (item.row - 1) * shelfSpacing + 0.015
		local itemY = shelfTop + item.thick / 2
		b:box(
			`MailItem_{idx}`,
			Vector3.new(colW * 0.85, item.thick, item.len),
			Kit.at(colCenterX, itemY, -d / 2 + item.len / 2 - item.protrude),
			item.color,
			Enum.Material.SmoothPlastic
		)
	end

	return b:done()
end

return MailSlots
