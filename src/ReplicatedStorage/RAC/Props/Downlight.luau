--!strict
-- Architectural recessed circular LED can downlight (pot light) with downward SurfaceLight.
-- Reference: IMG_0376 (recessed downlights in corridor ceilings).
local Kit = require(script.Parent.Kit)

local Downlight = {
	kind = "downlight",
	size = Vector3.new(0.8, 0.6, 0.8),
}

local TrimWhite = Color3.fromRGB(246, 246, 244)
local BaffleGrey = Color3.fromRGB(160, 164, 168)
local CanMetal = Color3.fromRGB(190, 194, 198)
local JBoxDark = Color3.fromRGB(110, 114, 118)
local LedNeon = Color3.fromRGB(255, 252, 240)
local WarmDownlight = Color3.fromRGB(255, 245, 230)

function Downlight.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("Downlight", cf)
	local C = Kit.Color

	local outerDiam = 0.78
	local canDiam = 0.62
	local canH = 0.52

	-- 1. Outer circular ceiling trim ring (flush at ceiling line Y = 0.02)
	b:cyl("TrimRingOuter", 0.03, outerDiam, Kit.vertical(0, 0.015, 0), TrimWhite, Enum.Material.SmoothPlastic)
	b:cyl("TrimBevel", 0.02, outerDiam * 0.92, Kit.vertical(0, 0.035, 0), TrimWhite, Enum.Material.SmoothPlastic)

	-- 2. Recessed stepped baffle / reflector cone inside the can
	b:cyl("BaffleStep1", 0.04, 0.56, Kit.vertical(0, 0.06, 0), BaffleGrey, Enum.Material.Metal)
	b:cyl("BaffleStep2", 0.04, 0.50, Kit.vertical(0, 0.10, 0), BaffleGrey, Enum.Material.Metal)
	b:cyl("BaffleStep3", 0.04, 0.44, Kit.vertical(0, 0.14, 0), BaffleGrey, Enum.Material.Metal)
	b:cyl("BaffleCone", 0.12, 0.38, Kit.vertical(0, 0.22, 0), Color3.fromRGB(220, 224, 228), Enum.Material.Metal)

	-- 3. Recessed LED COB chip / optic lens
	local led = b:cyl("LedEmitter", 0.03, 0.28, Kit.vertical(0, 0.29, 0), LedNeon, Enum.Material.Neon)
	led.CastShadow = false

	-- 4. Cylindrical galvanized steel can housing above ceiling
	b:cyl("CanHousing", canH - 0.2, canDiam, Kit.vertical(0, 0.35, 0), CanMetal, Enum.Material.Metal)
	b:cyl("CanTopCap", 0.04, canDiam * 0.95, Kit.vertical(0, 0.52, 0), CanMetal, Enum.Material.Metal)

	-- 5. Electrical junction box mounted to side of can
	b:box("JunctionBox", Vector3.new(0.24, 0.22, 0.2), Kit.at(0.28, 0.42, 0), JBoxDark, Enum.Material.Metal)
	b:cyl("ConduitKnockout", 0.04, 0.08, Kit.at(0.41, 0.45, 0), C.Chrome, Enum.Material.Metal)
	b:box(
		"GroundScrew",
		Vector3.new(0.02, 0.02, 0.02),
		Kit.at(0.4, 0.35, 0.08),
		Color3.fromRGB(40, 180, 50),
		Enum.Material.Metal
	)

	-- 6. Adjustable T-bar grid hanger bars (expanding left and right)
	for _, s in { -1, 1 } do
		-- Hanger bracket on can
		b:box(
			`HangerBracket_{s}`,
			Vector3.new(0.06, 0.08, 0.04),
			Kit.at(0, 0.25, s * 0.32),
			CanMetal,
			Enum.Material.Metal
		)
		-- Horizontal bar segment
		b:box(`HangerBar_{s}`, Vector3.new(0.7, 0.04, 0.03), Kit.at(0, 0.25, s * 0.35), CanMetal, Enum.Material.Metal)
		-- Grid clip tabs
		b:box(
			`GridTab_L_{s}`,
			Vector3.new(0.06, 0.06, 0.04),
			Kit.at(-0.33, 0.25, s * 0.35),
			CanMetal,
			Enum.Material.Metal
		)
		b:box(
			`GridTab_R_{s}`,
			Vector3.new(0.06, 0.06, 0.04),
			Kit.at(0.33, 0.25, s * 0.35),
			CanMetal,
			Enum.Material.Metal
		)
	end

	-- Thermal protector sensor clip
	b:box(
		"ThermalProtector",
		Vector3.new(0.08, 0.06, 0.06),
		Kit.at(-0.25, 0.46, 0),
		Color3.fromRGB(50, 52, 55),
		Enum.Material.SmoothPlastic
	)

	-- 7. Downward SurfaceLight
	b:light(led, Enum.NormalId.Bottom, 2.2, 24, WarmDownlight)

	return b:done()
end

return Downlight
