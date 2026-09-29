--!strict
-- Commercial wall-mounted cork bulletin board with aluminum frame, flyers, and pushpins.
-- Reference: Corridors and offices (IMG_0346, IMG_0323).
local Kit = require(script.Parent.Kit)

local BulletinBoard = {
	kind = "bulletin_board",
	size = Vector3.new(4.0, 3.0, 0.25),
}

local FrameAluminum = Color3.fromRGB(180, 184, 188)
local CorkTan = Color3.fromRGB(198, 172, 136)
local FlyerWhite = Color3.fromRGB(246, 246, 242)
local FlyerYellow = Color3.fromRGB(250, 240, 185)
local FlyerGreen = Color3.fromRGB(0, 82, 45) -- Mason Green
local FlyerRed = Color3.fromRGB(215, 40, 35)

function BulletinBoard.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("BulletinBoard", cf)
	local C = Kit.Color

	local w = (opts and opts.width) or 4.0
	local h = 3.0
	local d = 0.25
	local frameW = 0.12
	local frameThick = 0.06
	local backZ = d / 2 - 0.02
	local corkZ = 0.02

	-- 1. Outer Anodized Aluminum Perimeter Frame
	-- Top rail
	b:box(
		"FrameTop",
		Vector3.new(w, frameW, frameThick),
		Kit.at(0, h - frameW / 2, corkZ),
		FrameAluminum,
		Enum.Material.Metal,
		true
	)
	-- Bottom rail
	b:box(
		"FrameBottom",
		Vector3.new(w, frameW, frameThick),
		Kit.at(0, frameW / 2, corkZ),
		FrameAluminum,
		Enum.Material.Metal,
		true
	)
	-- Left stile
	b:box(
		"FrameLeft",
		Vector3.new(frameW, h - 2 * frameW, frameThick),
		Kit.at(-w / 2 + frameW / 2, h / 2, corkZ),
		FrameAluminum,
		Enum.Material.Metal,
		true
	)
	-- Right stile
	b:box(
		"FrameRight",
		Vector3.new(frameW, h - 2 * frameW, frameThick),
		Kit.at(w / 2 - frameW / 2, h / 2, corkZ),
		FrameAluminum,
		Enum.Material.Metal,
		true
	)

	-- Bottom marker / thumb-tack shelf ledge
	b:box(
		"BottomShelf",
		Vector3.new(w - 0.2, 0.04, 0.15),
		Kit.at(0, frameW + 0.02, -0.05),
		FrameAluminum,
		Enum.Material.Metal
	)

	-- 2. Corkboard Surface (Split in 2 along X for bounding check)
	local corkW = w - 2 * frameW
	local corkH = h - 2 * frameW
	local halfCorkW = corkW / 2
	b:box(
		"CorkSurface_1",
		Vector3.new(halfCorkW, corkH, 0.03),
		Kit.at(-halfCorkW / 2, h / 2, corkZ + 0.01),
		CorkTan,
		Enum.Material.Wood,
		true
	)
	b:box(
		"CorkSurface_2",
		Vector3.new(halfCorkW, corkH, 0.03),
		Kit.at(halfCorkW / 2, h / 2, corkZ + 0.01),
		CorkTan,
		Enum.Material.Wood,
		true
	)

	-- Rear wall mounting brackets
	b:box(
		"MountBracket_L",
		Vector3.new(0.2, 0.4, 0.03),
		Kit.at(-w / 3, h * 0.75, backZ),
		Color3.fromRGB(60, 62, 65),
		Enum.Material.Metal
	)
	b:box(
		"MountBracket_R",
		Vector3.new(0.2, 0.4, 0.03),
		Kit.at(w / 3, h * 0.75, backZ),
		Color3.fromRGB(60, 62, 65),
		Enum.Material.Metal
	)

	-- 3. Pinned Notices, Posters, and Flyers
	local notices = {
		-- Mason Recreation Schedule (Mason Green & Gold flyer)
		{ name = "MasonRecSchedule", x = -1.1, y = 2.1, w = 0.85, h = 1.1, color = FlyerGreen, rot = -2 },
		{
			name = "MasonScheduleInner",
			x = -1.1,
			y = 2.05,
			w = 0.75,
			h = 0.8,
			color = FlyerWhite,
			rot = -2,
			zOffset = -0.01,
		},
		-- Safety & Emergency Notice (Red header)
		{ name = "SafetyNoticeHeader", x = 0.0, y = 2.25, w = 0.9, h = 0.25, color = FlyerRed, rot = 1 },
		{ name = "SafetyNoticeBody", x = 0.0, y = 1.65, w = 0.9, h = 0.95, color = FlyerWhite, rot = 1 },
		-- Campus Activity Flyer (Yellow paper)
		{ name = "ActivityFlyer", x = 1.1, y = 2.0, w = 0.8, h = 1.0, color = FlyerYellow, rot = -3 },
		-- Policy Memo (White letter)
		{ name = "PolicyMemo", x = -1.0, y = 0.9, w = 0.75, h = 0.85, color = FlyerWhite, rot = 2 },
		-- Small Note
		{ name = "SmallNote", x = 1.05, y = 0.85, w = 0.6, h = 0.65, color = FlyerYellow, rot = 4 },
	}

	for _, n in ipairs(notices) do
		local rotCF = CFrame.Angles(0, 0, math.rad(n.rot))
		local z = corkZ - 0.01 + (n.zOffset or 0)
		b:box(n.name, Vector3.new(n.w, n.h, 0.005), Kit.at(n.x, n.y, z) * rotCF, n.color, Enum.Material.SmoothPlastic)
	end

	-- 4. Colorful Pushpins / Thumbtacks
	local pins = {
		{ x = -1.1, y = 2.6, color = Color3.fromRGB(220, 30, 20) }, -- Red pin
		{ x = 0.0, y = 2.35, color = Color3.fromRGB(30, 100, 220) }, -- Blue pin
		{ x = 1.1, y = 2.45, color = Color3.fromRGB(255, 205, 0) }, -- Gold pin
		{ x = -1.0, y = 1.3, color = Color3.fromRGB(40, 180, 50) }, -- Green pin
		{ x = 1.05, y = 1.15, color = Color3.fromRGB(220, 30, 20) }, -- Red pin
	}

	for idx, pin in ipairs(pins) do
		b:ball(`PushPin_{idx}`, 0.05, Kit.at(pin.x, pin.y, corkZ - 0.025), pin.color, Enum.Material.SmoothPlastic)
		b:cyl(`PinStem_{idx}`, 0.03, 0.015, Kit.alongZ(pin.x, pin.y, corkZ - 0.01), C.Chrome, Enum.Material.Metal)
	end

	return b:done()
end

return BulletinBoard
