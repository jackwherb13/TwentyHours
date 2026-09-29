--!strict
-- Circular wall clock with silver bezel, hour markers, and hands.
-- Reference: IMG_0323 (standard institutional circular wall clock).
local Kit = require(script.Parent.Kit)

local WallClock = {
	kind = "wall_clock",
	size = Vector3.new(1.2, 1.2, 0.25),
}

local BezelSilver = Color3.fromRGB(205, 210, 215)
local DialWhite = Color3.fromRGB(250, 250, 248)
local HandBlack = Color3.fromRGB(25, 25, 28)
local SecondRed = Color3.fromRGB(210, 30, 20)

function WallClock.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("WallClock", cf)
	local C = Kit.Color

	local diam = 1.2
	local centerY = diam / 2 -- 0.6 ft above bottom
	local faceZ = -0.04
	local dialRadius = 0.52

	-- Rear wall-mount housing
	b:cyl(
		"MountHousing",
		0.08,
		diam * 0.95,
		Kit.alongZ(0, centerY, 0.08),
		Color3.fromRGB(50, 52, 55),
		Enum.Material.SmoothPlastic
	)

	-- Outer silver bezel ring
	b:cyl("OuterBezel", 0.12, diam, Kit.alongZ(0, centerY, 0.02), BezelSilver, Enum.Material.Metal)

	-- Dial face (white disc)
	b:cyl("DialFace", 0.02, dialRadius * 2, Kit.alongZ(0, centerY, faceZ), DialWhite, Enum.Material.SmoothPlastic)

	-- 12 Hour tick marks around the perimeter
	for hour = 1, 12 do
		local angle = math.rad(hour * 30)
		local sinA = math.sin(angle)
		local cosA = math.cos(angle)
		local isMajor = (hour % 3 == 0)
		local markLen = if isMajor then 0.1 else 0.06
		local markThick = if isMajor then 0.035 else 0.02
		local rPos = dialRadius - markLen / 2 - 0.02

		local markX = sinA * rPos
		local markY = centerY + cosA * rPos
		local rot = CFrame.Angles(0, 0, -angle)

		b:box(
			`HourTick_{hour}`,
			Vector3.new(markThick, markLen, 0.01),
			Kit.at(markX, markY, faceZ - 0.01) * rot,
			HandBlack,
			Enum.Material.SmoothPlastic
		)
	end

	-- Center hub cap
	b:cyl("CenterCap", 0.03, 0.08, Kit.alongZ(0, centerY, faceZ - 0.03), HandBlack, Enum.Material.SmoothPlastic)

	-- Hour hand (pointing ~10 o'clock: angle ~-60 deg)
	local hourAngle = math.rad(-60)
	local hourLen = 0.28
	local hourX = math.sin(hourAngle) * (hourLen / 2)
	local hourY = centerY + math.cos(hourAngle) * (hourLen / 2)
	b:box(
		"HourHand",
		Vector3.new(0.03, hourLen, 0.01),
		Kit.at(hourX, hourY, faceZ - 0.02) * CFrame.Angles(0, 0, -hourAngle),
		HandBlack,
		Enum.Material.SmoothPlastic
	)

	-- Minute hand (pointing ~2 o'clock: angle ~60 deg)
	local minAngle = math.rad(60)
	local minLen = 0.42
	local minX = math.sin(minAngle) * (minLen / 2)
	local minY = centerY + math.cos(minAngle) * (minLen / 2)
	b:box(
		"MinuteHand",
		Vector3.new(0.02, minLen, 0.01),
		Kit.at(minX, minY, faceZ - 0.025) * CFrame.Angles(0, 0, -minAngle),
		HandBlack,
		Enum.Material.SmoothPlastic
	)

	-- Second hand (thin red needle pointing down-right ~4 o'clock: angle ~120 deg)
	local secAngle = math.rad(120)
	local secLen = 0.46
	local secX = math.sin(secAngle) * (secLen / 2)
	local secY = centerY + math.cos(secAngle) * (secLen / 2)
	b:box(
		"SecondHand",
		Vector3.new(0.01, secLen, 0.005),
		Kit.at(secX, secY, faceZ - 0.03) * CFrame.Angles(0, 0, -secAngle),
		SecondRed,
		Enum.Material.SmoothPlastic
	)
	-- Second hand center dot
	b:ball("SecondHubDot", 0.04, Kit.at(0, centerY, faceZ - 0.035), SecondRed, Enum.Material.SmoothPlastic)

	-- Front glass lens
	b:cyl("FrontLens", 0.01, dialRadius * 2, Kit.alongZ(0, centerY, faceZ - 0.04), C.Glass, Enum.Material.Glass)

	return b:done()
end

return WallClock
