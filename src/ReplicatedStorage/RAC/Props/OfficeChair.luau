--!strict
-- Ergonomic office swivel task chair with 5-star caster base, mesh back, and adjustable armrests.
local Kit = require(script.Parent.Kit)

local OfficeChair = {
	kind = "office_chair",
	size = Vector3.new(2.2, 3.5, 2.2),
}

local CharcoalPlastic = Color3.fromRGB(35, 36, 40)
local MeshBack = Color3.fromRGB(45, 48, 52)
local LumbarPad = Color3.fromRGB(28, 30, 32)
local Chrome = Color3.fromRGB(210, 215, 220)

function OfficeChair.build(cf: CFrame, _opts: { [string]: any }?): Model
	local b = Kit.new("OfficeChair", cf)
	local C = Kit.Color

	-- 1. Base: 5-Star caster base
	local hubY = 0.22
	b:cyl("BaseHub", 0.15, 0.4, Kit.vertical(0, hubY, 0), CharcoalPlastic, Enum.Material.SmoothPlastic)

	for i = 0, 4 do
		local angle = math.rad(i * 72)
		local dirX = math.sin(angle)
		local dirZ = math.cos(angle)
		local legLen = 0.85
		local legMidX = dirX * (legLen / 2 + 0.1)
		local legMidZ = dirZ * (legLen / 2 + 0.1)
		local legRot = CFrame.Angles(0, angle, 0)

		-- Radial prong
		b:box(
			`BaseLeg_{i}`,
			Vector3.new(0.12, 0.08, legLen),
			Kit.at(legMidX, hubY - 0.02, legMidZ) * legRot,
			CharcoalPlastic,
			Enum.Material.SmoothPlastic
		)

		-- Caster wheel at tip of each leg
		local tipX = dirX * (legLen + 0.08)
		local tipZ = dirZ * (legLen + 0.08)
		b:cyl(`CasterStem_{i}`, 0.08, 0.04, Kit.vertical(tipX, 0.12, tipZ), Chrome, Enum.Material.Metal)
		b:cyl(`CasterWheel_{i}`, 0.08, 0.16, Kit.alongZ(tipX, 0.07, tipZ), C.RubberBlack, Enum.Material.Rubber)
	end

	-- 2. Pneumatic gas lift cylinder
	b:cyl("GasCylinderOuter", 0.4, 0.2, Kit.vertical(0, 0.45, 0), CharcoalPlastic, Enum.Material.SmoothPlastic)
	b:cyl("GasCylinderShaft", 0.5, 0.12, Kit.vertical(0, 0.8, 0), Chrome, Enum.Material.Metal)

	-- 3. Under-seat tilt mechanism
	local mechY = 1.2
	b:box("TiltMechanism", Vector3.new(0.7, 0.25, 0.7), Kit.at(0, mechY, 0), CharcoalPlastic, Enum.Material.Metal)
	-- Tension knob (facing -Z front)
	b:cyl("TensionKnob", 0.2, 0.18, Kit.alongZ(0, mechY - 0.05, -0.42), CharcoalPlastic, Enum.Material.SmoothPlastic)
	-- Height adjustment lever (on right side +X)
	b:cyl("LiftLeverRod", 0.3, 0.04, Kit.at(0.45, mechY, 0), Chrome, Enum.Material.Metal)
	b:box(
		"LiftPaddle",
		Vector3.new(0.15, 0.03, 0.2),
		Kit.at(0.62, mechY, 0),
		CharcoalPlastic,
		Enum.Material.SmoothPlastic
	)

	-- 4. Contoured seat cushion
	local seatY = 1.45
	-- Under-seat structural plastic pan
	b:box(
		"SeatPan",
		Vector3.new(1.6, 0.08, 1.55),
		Kit.at(0, seatY - 0.06, 0.05),
		CharcoalPlastic,
		Enum.Material.SmoothPlastic
	)
	-- Padded seat cushion
	b:box(
		"SeatCushion",
		Vector3.new(1.6, 0.18, 1.55),
		Kit.at(0, seatY + 0.05, 0.05),
		C.Upholstery,
		Enum.Material.Fabric,
		true
	)
	-- Waterfall front cushion roll
	b:cyl("SeatFrontRoll", 1.55, 0.18, Kit.at(0, seatY + 0.02, -0.7), C.Upholstery, Enum.Material.Fabric)

	-- 5. Backrest spine and mesh back
	-- Spine bracket from under seat
	b:box(
		"BackSpineLower",
		Vector3.new(0.2, 0.15, 0.5),
		Kit.at(0, mechY + 0.1, 0.55),
		CharcoalPlastic,
		Enum.Material.Metal
	)
	-- Vertical upright spine
	b:box(
		"BackSpineVertical",
		Vector3.new(0.18, 1.4, 0.12),
		Kit.at(0, 2.2, 0.8),
		CharcoalPlastic,
		Enum.Material.SmoothPlastic
	)

	-- Mesh backrest perimeter frame
	local backY = 2.45
	local backZ = 0.72
	-- Top rail
	b:box(
		"BackFrameTop",
		Vector3.new(1.5, 0.12, 0.1),
		Kit.at(0, backY + 0.85, backZ),
		CharcoalPlastic,
		Enum.Material.SmoothPlastic
	)
	-- Bottom rail
	b:box(
		"BackFrameBottom",
		Vector3.new(1.4, 0.12, 0.1),
		Kit.at(0, backY - 0.7, backZ),
		CharcoalPlastic,
		Enum.Material.SmoothPlastic
	)
	-- Left stile
	b:box(
		"BackFrameLeft",
		Vector3.new(0.1, 1.5, 0.1),
		Kit.at(-0.7, backY + 0.08, backZ),
		CharcoalPlastic,
		Enum.Material.SmoothPlastic
	)
	-- Right stile
	b:box(
		"BackFrameRight",
		Vector3.new(0.1, 1.5, 0.1),
		Kit.at(0.7, backY + 0.08, backZ),
		CharcoalPlastic,
		Enum.Material.SmoothPlastic
	)
	-- Breathable mesh central panel
	b:box("BackMeshPanel", Vector3.new(1.3, 1.45, 0.03), Kit.at(0, backY + 0.08, backZ), MeshBack, Enum.Material.Fabric)

	-- Adjustable lumbar support pad
	b:box(
		"LumbarPad",
		Vector3.new(1.1, 0.35, 0.08),
		Kit.at(0, backY - 0.25, backZ - 0.04),
		LumbarPad,
		Enum.Material.Rubber
	)

	-- 6. Adjustable T-armrests (Left and Right)
	for _, s in { -1, 1 } do
		local armX = s * 0.9
		-- Horizontal attachment arm from under seat
		b:box(
			`ArmBase_{s}`,
			Vector3.new(0.3, 0.08, 0.15),
			Kit.at(s * 0.75, mechY + 0.1, 0.1),
			CharcoalPlastic,
			Enum.Material.Metal
		)
		-- Vertical upright post
		b:box(`ArmPost_{s}`, Vector3.new(0.1, 0.7, 0.15), Kit.at(armX, 1.6, 0.1), CharcoalPlastic, Enum.Material.Metal)
		-- Height adjustment release button
		b:cyl(`ArmButton_{s}`, 0.04, 0.06, Kit.at(armX + s * 0.06, 1.55, 0.1), Chrome, Enum.Material.Metal)
		-- Armrest pad (contoured soft polyurethane)
		b:box(`ArmPad_{s}`, Vector3.new(0.24, 0.08, 0.8), Kit.at(armX, 1.98, 0.05), C.Upholstery, Enum.Material.Rubber)
	end

	return b:done()
end

return OfficeChair
