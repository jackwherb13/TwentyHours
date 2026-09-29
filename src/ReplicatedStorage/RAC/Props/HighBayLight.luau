--!strict
-- Suspended linear LED high-bay luminaire for gymnasiums.
-- Reference: IMG_0333, IMG_0334 (linear LED high-bay fixtures suspended from steel bar joists).
local Kit = require(script.Parent.Kit)

local HighBayLight = {
	kind = "high_bay_light",
	size = Vector3.new(1.3, 1.2, 4.0),
}

local FixtureWhite = Color3.fromRGB(245, 246, 248)
local HeatsinkGrey = Color3.fromRGB(180, 185, 190)
local WireSteel = Color3.fromRGB(130, 134, 140)
local LedNeon = Color3.fromRGB(255, 255, 250)
local GymLightBeam = Color3.fromRGB(250, 252, 255)

function HighBayLight.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("HighBayLight", cf)
	local C = Kit.Color

	local totalLen = (opts and opts.length) or 4.0
	local w = 1.3
	local h = 1.2
	local bodyH = 0.35
	local bodyY = 0.22 -- bottom of fixture at Y = 0.05
	local halfLen = totalLen / 2

	-- 1. Main extruded aluminum chassis (split into 2 segments along Z for bounding checks)
	for seg = 1, 2 do
		local zOffset = -halfLen + (seg - 0.5) * halfLen
		-- Main center channel
		b:box(
			`ChassisBase_{seg}`,
			Vector3.new(w, 0.04, halfLen),
			Kit.at(0, bodyY, zOffset),
			FixtureWhite,
			Enum.Material.Metal,
			true
		)
		b:box(
			`ChassisTop_{seg}`,
			Vector3.new(w - 0.2, 0.04, halfLen),
			Kit.at(0, bodyY + bodyH, zOffset),
			FixtureWhite,
			Enum.Material.Metal
		)

		-- Top heatsink longitudinal fins
		for _, finX in { -0.35, -0.15, 0.15, 0.35 } do
			b:box(
				`HeatsinkFin_{seg}_{finX}`,
				Vector3.new(0.04, 0.08, halfLen),
				Kit.at(finX, bodyY + bodyH + 0.04, zOffset),
				HeatsinkGrey,
				Enum.Material.Metal
			)
		end
	end

	-- 2. Heavy-duty end plates
	for _, s in { -1, 1 } do
		local z = s * (totalLen / 2 - 0.02)
		b:box(
			`EndPlate_{s}`,
			Vector3.new(w + 0.04, bodyH + 0.08, 0.04),
			Kit.at(0, bodyY + bodyH / 2, z),
			FixtureWhite,
			Enum.Material.Metal
		)
		-- Electrical knockout plug
		b:cyl(
			`Knockout_{s}`,
			0.05,
			0.15,
			Kit.alongZ(0, bodyY + bodyH * 0.6, z),
			Color3.fromRGB(60, 62, 65),
			Enum.Material.Metal
		)
	end

	-- 3. Center LED driver / ballast enclosure on top
	b:box(
		"DriverHousing",
		Vector3.new(0.5, 0.18, 1.8),
		Kit.at(0, bodyY + bodyH + 0.09, 0),
		FixtureWhite,
		Enum.Material.Metal
	)
	-- Conduit connector fitting
	b:cyl("ConduitFitting", 0.08, 0.1, Kit.vertical(0, bodyY + bodyH + 0.22, 0.6), C.Chrome, Enum.Material.Metal)

	-- 4. 3 Linear LED channels with frosted diffuse optic lenses
	-- Channels at X = -0.35, 0.0, +0.35
	local primaryLedPart: any = nil
	for _, chanX in { -0.36, 0.0, 0.36 } do
		for seg = 1, 2 do
			local zOffset = -halfLen + (seg - 0.5) * halfLen
			-- Reflector tray
			b:box(
				`LedTray_{chanX}_{seg}`,
				Vector3.new(0.24, 0.03, halfLen - 0.06),
				Kit.at(chanX, bodyY + 0.03, zOffset),
				FixtureWhite,
				Enum.Material.Metal
			)
			-- Glowing LED lens emitter
			local emitter = b:box(
				`LedEmitter_{chanX}_{seg}`,
				Vector3.new(0.2, 0.03, halfLen - 0.08),
				Kit.at(chanX, bodyY - 0.01, zOffset),
				LedNeon,
				Enum.Material.Neon
			)
			emitter.CastShadow = false
			if chanX == 0.0 and seg == 1 then
				primaryLedPart = emitter
			end
		end
	end

	-- 5. Wire protective guard cage (gym ball impact protection)
	-- Longitudinal guard wires
	for _, wireX in { -0.55, -0.28, 0.0, 0.28, 0.55 } do
		for seg = 1, 2 do
			local zOffset = -halfLen + (seg - 0.5) * halfLen
			b:box(
				`GuardWire_{wireX}_{seg}`,
				Vector3.new(0.02, 0.02, halfLen),
				Kit.at(wireX, bodyY - 0.05, zOffset),
				WireSteel,
				Enum.Material.Metal
			)
		end
	end
	-- Cross guard ribs
	for _, ribZ in { -1.5, -0.75, 0.0, 0.75, 1.5 } do
		b:box(
			`GuardRib_{ribZ}`,
			Vector3.new(w - 0.1, 0.02, 0.02),
			Kit.at(0, bodyY - 0.05, ribZ),
			WireSteel,
			Enum.Material.Metal
		)
	end

	-- 6. Suspension assembly: Dual V-hangers & aircraft cables extending upward
	local cableTopY = h - 0.04
	for _, s in { -1, 1 } do
		local z = s * (totalLen / 2 - 0.5)
		-- V-hanger steel bracket on fixture
		b:box(
			`VBracket_{s}`,
			Vector3.new(0.6, 0.04, 0.06),
			Kit.at(0, bodyY + bodyH + 0.06, z),
			WireSteel,
			Enum.Material.Metal
		)
		-- Angled hanger arms converging upward
		b:box(
			`HangerArm_L_{s}`,
			Vector3.new(0.03, 0.45, 0.03),
			Kit.at(-0.15, bodyY + bodyH + 0.25, z) * CFrame.Angles(0, 0, math.rad(-25)),
			WireSteel,
			Enum.Material.Metal
		)
		b:box(
			`HangerArm_R_{s}`,
			Vector3.new(0.03, 0.45, 0.03),
			Kit.at(0.15, bodyY + bodyH + 0.25, z) * CFrame.Angles(0, 0, math.rad(25)),
			WireSteel,
			Enum.Material.Metal
		)
		-- Central suspension eyebolt ring
		b:cyl(`SuspensionRing_{s}`, 0.04, 0.1, Kit.alongZ(0, bodyY + bodyH + 0.45, z), C.Chrome, Enum.Material.Metal)
		-- Aircraft cable extending to ceiling beam clamp
		b:cyl(`SuspensionCable_{s}`, 0.35, 0.03, Kit.vertical(0, cableTopY - 0.18, z), WireSteel, Enum.Material.Metal)
		-- Beam clamp block at joist connection
		b:box(
			`BeamClamp_{s}`,
			Vector3.new(0.2, 0.08, 0.2),
			Kit.at(0, cableTopY, z),
			Color3.fromRGB(50, 52, 55),
			Enum.Material.Metal
		)
	end

	-- 7. High-output downward SurfaceLight
	if primaryLedPart then
		b:light(primaryLedPart, Enum.NormalId.Bottom, 2.5, 40, GymLightBeam)
	end

	return b:done()
end

return HighBayLight
