--!strict
-- Commercial indoor heavy-duty waste container with swing-flap lid and bag liner.
-- Reference: RAC corridors and offices (standard commercial Slim Jim container).
local Kit = require(script.Parent.Kit)

local TrashBin = {
	kind = "trash_bin",
	size = Vector3.new(1.8, 2.8, 1.2),
}

local BinCharcoal = Color3.fromRGB(42, 45, 48)
local LidBlack = Color3.fromRGB(26, 28, 30)
local FlapGrey = Color3.fromRGB(60, 64, 68)
local BagBlack = Color3.fromRGB(20, 20, 22)
local LabelWhite = Color3.fromRGB(240, 240, 245)

function TrashBin.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("TrashBin", cf)
	local C = Kit.Color

	local w, h, d = 1.8, 2.8, 1.2
	local bodyH = 2.3
	local halfBodyH = bodyH / 2
	local lidH = 0.5

	-- 1. Base footprint & feet
	b:box(
		"BaseRim",
		Vector3.new(w - 0.25, 0.08, d - 0.2),
		Kit.at(0, 0.04, 0),
		LidBlack,
		Enum.Material.SmoothPlastic,
		true
	)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			b:box(
				`Foot_{sx}_{sz}`,
				Vector3.new(0.12, 0.04, 0.12),
				Kit.at(sx * (w / 2 - 0.2), 0.02, sz * (d / 2 - 0.18)),
				C.RubberBlack,
				Enum.Material.Rubber
			)
		end
	end

	-- 2. Tapered bin body (split in 2 vertical segments for bounding checks)
	-- Lower body segment
	b:box(
		"BodyLower",
		Vector3.new(w - 0.2, halfBodyH - 0.05, d - 0.15),
		Kit.at(0, halfBodyH / 2 + 0.05, 0),
		BinCharcoal,
		Enum.Material.SmoothPlastic,
		true
	)
	-- Upper body segment
	b:box(
		"BodyUpper",
		Vector3.new(w - 0.1, halfBodyH, d - 0.08),
		Kit.at(0, halfBodyH + halfBodyH / 2, 0),
		BinCharcoal,
		Enum.Material.SmoothPlastic,
		true
	)

	-- Side venting channels (molded exterior ribs preventing liner vacuum)
	for _, s in { -1, 1 } do
		local x = s * (w / 2 - 0.04)
		for rib = 1, 2 do
			local z = (rib - 1.5) * 0.35
			b:box(
				`VentRibLower_{s}_{rib}`,
				Vector3.new(0.04, halfBodyH - 0.1, 0.06),
				Kit.at(x, halfBodyH / 2 + 0.05, z),
				LidBlack,
				Enum.Material.SmoothPlastic
			)
			b:box(
				`VentRibUpper_{s}_{rib}`,
				Vector3.new(0.04, halfBodyH - 0.1, 0.06),
				Kit.at(x, halfBodyH + halfBodyH / 2, z),
				LidBlack,
				Enum.Material.SmoothPlastic
			)
		end
	end

	-- 3. Upper rim collar & molded side carry handles
	b:box("RimCollar", Vector3.new(w, 0.16, d), Kit.at(0, bodyH - 0.06, 0), LidBlack, Enum.Material.SmoothPlastic, true)
	for _, s in { -1, 1 } do
		-- Molded handle pocket
		b:box(
			`HandlePocket_{s}`,
			Vector3.new(0.06, 0.1, 0.4),
			Kit.at(s * (w / 2 + 0.02), bodyH - 0.07, 0),
			FlapGrey,
			Enum.Material.SmoothPlastic
		)
		-- Bag cinch tab
		b:box(
			`CinchTab_{s}`,
			Vector3.new(0.04, 0.06, 0.12),
			Kit.at(s * (w / 2 - 0.02), bodyH - 0.15, 0.25),
			LidBlack,
			Enum.Material.SmoothPlastic
		)
	end

	-- Folded trash bag liner cuff over rim
	b:box(
		"BagLinerCuff_Front",
		Vector3.new(w - 0.1, 0.1, 0.04),
		Kit.at(0, bodyH - 0.1, -d / 2 - 0.01),
		BagBlack,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"BagLinerCuff_Back",
		Vector3.new(w - 0.1, 0.1, 0.04),
		Kit.at(0, bodyH - 0.1, d / 2 + 0.01),
		BagBlack,
		Enum.Material.SmoothPlastic
	)

	-- 4. Swing-top lid assembly
	-- Outer lid perimeter housing
	b:box(
		"LidHousing",
		Vector3.new(w - 0.05, lidH * 0.5, d - 0.05),
		Kit.at(0, bodyH + lidH * 0.25, 0),
		LidBlack,
		Enum.Material.SmoothPlastic,
		true
	)
	b:box(
		"LidTopBevel",
		Vector3.new(w - 0.15, lidH * 0.5, d - 0.15),
		Kit.at(0, bodyH + lidH * 0.75, 0),
		LidBlack,
		Enum.Material.SmoothPlastic
	)

	-- Center drop opening recess
	local openW = w * 0.65
	local openD = d * 0.65
	b:box(
		"LidOpeningRecess",
		Vector3.new(openW, 0.04, openD),
		Kit.at(0, h - 0.05, 0),
		Color3.fromRGB(15, 15, 18),
		Enum.Material.SmoothPlastic
	)

	-- Dual balanced swing flap doors (angled slightly inward)
	for _, sz in { -1, 1 } do
		local flapD = openD * 0.46
		local flapZ = sz * (flapD / 2 + 0.02)
		b:box(
			`SwingFlap_{sz}`,
			Vector3.new(openW - 0.06, 0.03, flapD),
			Kit.at(0, h - 0.04, flapZ) * CFrame.Angles(sz * math.rad(15), 0, 0),
			FlapGrey,
			Enum.Material.SmoothPlastic
		)
		-- Hinge pin on edge
		b:cyl(
			`FlapHinge_{sz}`,
			openW * 0.95,
			0.03,
			Kit.at(0, h - 0.01, sz * (openD / 2)),
			C.Chrome,
			Enum.Material.Metal
		)
	end

	-- 5. Front "TRASH" label badge
	b:box(
		"TrashLabelBadge",
		Vector3.new(0.6, 0.22, 0.01),
		Kit.at(0, bodyH - 0.45, -d / 2 + 0.04),
		LidBlack,
		Enum.Material.SmoothPlastic
	)
	b:box(
		"TrashLabelStripe",
		Vector3.new(0.48, 0.06, 0.01),
		Kit.at(0, bodyH - 0.45, -d / 2 + 0.03),
		LabelWhite,
		Enum.Material.SmoothPlastic
	)

	return b:done()
end

return TrashBin
