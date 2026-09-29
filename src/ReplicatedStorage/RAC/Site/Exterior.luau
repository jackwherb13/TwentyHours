--!strict
local P = require(script.Parent.Primitives)
local H = require(script.Parent.Heightfield)
local G = require(script.Parent.Parent.Build.Geometry)
local Exterior = {}

-- WedgePart is thick on local +Z and the sloped face is the top. The tip is local -Z, level with the bottom.
local function canopyWedge(parent: Instance, name: string, size: Vector3, cf: CFrame)
	local wedge = Instance.new("WedgePart")
	wedge.Name = name
	wedge.Size = size
	wedge.CFrame = cf
	-- Matte charcoal. Neon read as a glowing slab and washed out in the sun.
	wedge.Material = Enum.Material.SmoothPlastic
	wedge.Color = Color3.fromRGB(20, 22, 24)
	wedge.Reflectance = 0
	wedge.Anchored = true
	wedge.CanCollide = true
	wedge.Parent = parent
end

local function pipe(parent: Instance, name: string, a: Vector3, b: Vector3)
	local length = (b - a).Magnitude
	if length < 0.25 then
		return
	end
	local part = P.box(
		parent,
		name,
		Vector3.new(length, 0.22, 0.22),
		CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0),
		"metal"
	)
	part.Shape = Enum.PartType.Cylinder
	part.Material = Enum.Material.Metal
	part.Color = Color3.fromRGB(186, 190, 194)
	part.Reflectance = 0.28
end

function Exterior.build(parent: Instance, site: any)
	local e = site.entrance
	local entrance = P.folder(parent, "Entrance")
	local width = e.width
	local rise = e.rise
	local run = e.run
	local frame = CFrame.new(e.x, 0, e.z) * CFrame.Angles(0, math.rad(e.rotationDeg or 0), 0)
	local function groundAt(lx: number, lz: number): number
		local world = frame:PointToWorldSpace(Vector3.new(lx, 0, lz))
		return H.height(world.X, world.Z)
	end
	-- Seven risers from the L1 sill. Heightfield drops the same 7*(7/12) ft to the toe.
	local n = 7
	local drop = n * rise
	local function walkY(lx: number): number
		if lx <= e.landingDepth then
			return 0
		end
		local step = math.floor((lx - e.landingDepth) / run) + 1
		return -math.clamp(step, 1, n) * rise
	end

	P.box(
		entrance,
		"LandingSlab",
		Vector3.new(e.landingDepth, rise, width),
		CFrame.new(e.landingDepth / 2, -rise / 2, 0),
		"concrete",
		true
	)
	for i = 1, n do
		local top = -i * rise
		P.box(
			entrance,
			`StairTread_{i}`,
			Vector3.new(run, rise, width),
			CFrame.new(e.landingDepth + (i - 0.5) * run, top - rise / 2, 0),
			"concrete",
			true
		)
	end
	local apronX = e.landingDepth + n * run
	-- A short toe pad. The drive beyond it is terrain, not a grey terrace.
	local apronLen = 8
	for len = 8, 10, 2 do
		if groundAt(apronX + len, 0) >= -drop - 0.55 then
			apronLen = len
		end
	end
	P.box(
		entrance,
		"ApronSlab",
		Vector3.new(apronLen, rise, width),
		CFrame.new(apronX + apronLen / 2, -drop - rise / 2, 0),
		"concrete",
		true
	)
	-- A short walk at the toe. The lawn on either side stays terrain, not a terrace.
	local stripLen = 6
	for s = 0, 2 do
		local nearX = apronX + apronLen + s * stripLen
		local farX = nearX + stripLen
		local y0 = math.min(groundAt(nearX, 0), -drop + 0.05)
		local y1 = math.min(groundAt(farX, 0), y0)
		local pitch = math.atan2(y1 - y0, stripLen)
		P.box(
			entrance,
			"ApproachSlab",
			Vector3.new(stripLen + 0.25, 0.35, width * 0.55),
			CFrame.new((nearX + farX) / 2, (y0 + y1) / 2 + 0.2, 0) * CFrame.Angles(0, 0, pitch),
			"concrete",
			true
		)
	end

	-- Three pipe runs: both cheeks and the center, matching the short flight in the entrance photos.
	local railTop = Vector3.new(e.landingDepth - 0.5, 3.1, 0)
	local railBottom = Vector3.new(apronX + 1.2, -drop + 3.1, 0)
	for _, offset in { -width / 2 + 0.7, -2.15, 2.15, width / 2 - 0.7 } do
		local a = railTop + Vector3.new(0, 0, offset)
		local b = railBottom + Vector3.new(0, 0, offset)
		pipe(entrance, "StairHandrail", a, b)
		local posts = math.max(2, math.ceil((b - a).Magnitude / 4.5))
		for k = 0, posts do
			local at = a:Lerp(b, k / posts)
			local foot = walkY(at.X)
			local height = at.Y - foot
			if height > 0.4 then
				local post = P.pole(entrance, "RailPost", Vector3.new(at.X, foot, at.Z), height, 0.08, "metal")
				post.Color = Color3.fromRGB(176, 180, 184)
			end
		end
	end

	-- Board-formed cheek beside the flight. Shrubs sit on the wall, not on the treads.
	local cheekZ = width / 2 + 1.6
	local cheek = P.beam(
		entrance,
		"CheekWall",
		Vector3.new(0.6, 1.7, cheekZ),
		Vector3.new(apronX, -drop + 1.7, cheekZ),
		1.15,
		3.2,
		"concrete",
		true
	)
	cheek.Color = Color3.fromRGB(128, 130, 126)
	for i = 1, 4 do
		local along = (i - 0.5) / 4
		local lx = 2 + (apronX - 3) * along
		local foot = walkY(lx)
		local clump = P.box(
			entrance,
			"CheekPlant",
			Vector3.new(2.4, 1.1, 1.6),
			CFrame.new(lx, foot + 0.55, cheekZ + 2.1),
			if i % 2 == 0 then "barberry" else "shrub"
		)
		clump.CanCollide = false
	end

	-- West ramp, 1:12, off the frontal cameras. Stems carry it where the slope is steeper.
	local rampWidth = 5.2
	local rampZ = width / 2 + 1.4 + rampWidth / 2
	local rampStartX = e.landingDepth
	local bestLen = drop * 12
	local bestErr = math.huge
	for len = 36, 72, 4 do
		local err = math.abs(groundAt(rampStartX + len, rampZ) + len / 12)
		if err < bestErr then
			bestErr = err
			bestLen = len
		end
	end
	local y1 = -bestLen / 12
	local padNear = width / 2 + 0.4
	local padFar = rampZ - rampWidth / 2 - 0.25
	P.box(
		entrance,
		"RampLandingSlab",
		Vector3.new(e.landingDepth - 0.6, rise, padFar - padNear),
		CFrame.new(0.6 + (e.landingDepth - 0.6) / 2, -rise / 2, (padNear + padFar) / 2),
		"concrete",
		true
	)
	local rampA = Vector3.new(rampStartX, -0.16, rampZ)
	local rampB = Vector3.new(rampStartX + bestLen, y1 - 0.16, rampZ)
	P.beam(entrance, "AccessibleRampSlab", rampA, rampB, rampWidth, 0.32, "concrete", true)
	P.box(
		entrance,
		"RampToeSlab",
		Vector3.new(6, rise, rampWidth),
		CFrame.new(rampStartX + bestLen + 3, y1 - rise / 2, rampZ),
		"concrete",
		true
	)
	local function rampFoot(lx: number): number
		if lx <= rampStartX then
			return 0
		end
		local t = math.clamp((lx - rampStartX) / bestLen, 0, 1)
		return -t * bestLen / 12
	end
	local eastZ = rampZ - rampWidth / 2 + 0.25
	local westZ = rampZ + rampWidth / 2 - 0.25
	local guards = {
		{ Vector3.new(1.2, 3, eastZ), Vector3.new(rampStartX, 3, eastZ) },
		{ Vector3.new(rampStartX, 3, eastZ), Vector3.new(rampStartX + bestLen + 1, y1 + 3, eastZ) },
		{ Vector3.new(rampStartX, 3, westZ), Vector3.new(rampStartX + bestLen + 1, y1 + 3, westZ) },
	}
	for _, pair in guards do
		local a, b = pair[1], pair[2]
		pipe(entrance, "RampHandrail", a, b)
		local posts = math.max(2, math.ceil((b - a).Magnitude / 5))
		for k = 0, posts do
			local at = a:Lerp(b, k / posts)
			local foot = rampFoot(at.X)
			if at.Y - foot > 0.4 then
				local post = P.pole(entrance, "RampRailPost", Vector3.new(at.X, foot, at.Z), at.Y - foot, 0.08, "metal")
				post.Color = Color3.fromRGB(176, 180, 184)
			end
		end
	end
	local panels = math.max(4, math.ceil(bestLen / 8))
	for k = 1, panels - 1 do
		local lx = rampStartX + bestLen * k / panels
		local top = rampFoot(lx) - 0.05
		local gy = groundAt(lx, rampZ)
		if top > gy + 0.35 then
			P.box(
				entrance,
				"RampStem",
				Vector3.new(bestLen / panels + 0.15, top - gy, rampWidth - 0.4),
				CFrame.new(lx, (top + gy) / 2, rampZ),
				"concrete",
				true
			)
		end
	end

	local canopy = P.folder(entrance, "Canopy")
	-- Thin dark wedge over the south curtain wall only. World X maps to local Z by e.x - worldX.
	local depth = 18
	local soffit = 30.55
	local tip = 0.35
	local canopyRise = 1.4
	local zGlassWest = e.x - -96
	local zGlassEast = e.x - 8
	local function spanCanopy(z0: number, z1: number)
		if z1 < z0 then
			z0, z1 = z1, z0
		end
		local length = z1 - z0
		if length < 2 then
			return
		end
		local midZ = (z0 + z1) / 2
		local plate = P.box(
			canopy,
			"CanopySoffit",
			Vector3.new(length, tip, depth),
			CFrame.fromMatrix(
				Vector3.new(depth / 2 + 0.35, soffit + tip / 2, midZ),
				Vector3.new(0, 0, 1),
				Vector3.new(0, 1, 0),
				Vector3.new(-1, 0, 0)
			),
			"dark",
			true
		)
		plate.Material = Enum.Material.SmoothPlastic
		plate.Color = Color3.fromRGB(22, 24, 26)
		plate.Reflectance = 0
		canopyWedge(
			canopy,
			"TaperedCanopy",
			Vector3.new(length, canopyRise, depth),
			CFrame.fromMatrix(
				Vector3.new(depth / 2 + 0.35, soffit + tip + canopyRise / 2 + 0.02, midZ),
				Vector3.new(0, 0, 1),
				Vector3.new(0, 1, 0),
				Vector3.new(-1, 0, 0)
			)
		)
	end
	local lo, hi = math.min(zGlassWest, zGlassEast), math.max(zGlassWest, zGlassEast)
	spanCanopy(lo, hi)
	-- Two round grey pipes in the glass plane, flanking the entrance doors.
	for _, lz in { 16, -16 } do
		local column = P.pole(canopy, "SupportColumn", Vector3.new(0.55, 0.02, lz), soffit - 0.08, 0.7, "metal", true)
		column.Material = Enum.Material.SmoothPlastic
		column.Color = Color3.fromRGB(118, 122, 126)
		column.Reflectance = 0.04
	end
	-- Discrete warm downlights. The housings stay matte charcoal, not a white grid.
	for lz = lo + 10, hi - 10, 16 do
		local mark = P.box(
			canopy,
			"SoffitLight",
			Vector3.new(0.7, 0.08, 0.7),
			CFrame.new(depth * 0.42, soffit - 0.05, lz),
			"dark"
		)
		mark.Color = Color3.fromRGB(18, 18, 20)
		mark.Material = Enum.Material.SmoothPlastic
		mark.CanCollide = false
		local lamp = Instance.new("PointLight")
		lamp.Brightness = 0.35
		lamp.Range = 16
		lamp.Color = Color3.fromRGB(255, 214, 170)
		lamp.Parent = mark
	end
	-- Red shrubs along the west glass. The east side is a concrete planter, not a bed on the treads.
	for i = 2, 4 do
		local bed = P.box(entrance, "EntryBed", Vector3.new(2.6, 1.5, 4.2), CFrame.new(2.2, 0.75, i * 5.4), "barberry")
		bed.CanCollide = false
	end
	local planterZ = -width / 2 - 9
	local planter =
		P.box(entrance, "PlanterWall", Vector3.new(3.6, 2.8, 18), CFrame.new(8, 1.4, planterZ), "concrete", true)
	planter.Color = Color3.fromRGB(168, 166, 158)
	local hedge = P.box(entrance, "PlanterHedge", Vector3.new(2.8, 1.7, 16), CFrame.new(8, 3.3, planterZ), "shrub")
	hedge.CanCollide = false
	-- Full-size hydrant at the east curb of the stair toe, on the walk not the landing.
	local hydrantAt = Vector3.new(apronX + 4, -drop, -width / 2 - 3.2)
	local barrel = P.pole(entrance, "Hydrant", hydrantAt, 3.05, 0.38, "metal", false)
	barrel.Color = Color3.fromRGB(176, 32, 28)
	barrel.Material = Enum.Material.SmoothPlastic
	local cap = P.box(
		entrance,
		"HydrantCap",
		Vector3.new(0.85, 0.32, 0.85),
		CFrame.new(hydrantAt.X, -drop + 3.15, hydrantAt.Z),
		"metal",
		false
	)
	cap.Color = Color3.fromRGB(186, 188, 190)
	cap.Material = Enum.Material.SmoothPlastic
	for _, side in { -0.55, 0.55 } do
		local nozzle = P.box(
			entrance,
			"HydrantCap",
			Vector3.new(0.55, 0.22, 0.22),
			CFrame.new(hydrantAt.X, -drop + 1.7, hydrantAt.Z + side),
			"metal",
			false
		)
		nozzle.Color = Color3.fromRGB(186, 188, 190)
	end
	-- Clear glass leaves in the curtain, south of the mullions.
	for _, side in { -1.55, 1.55 } do
		local leaf =
			P.box(entrance, "EntranceDoor", Vector3.new(0.1, 8.4, 2.85), CFrame.new(0.85, 4.25, side), "glass", false)
		leaf.Transparency = 0.55
		leaf.Color = Color3.fromRGB(176, 198, 196)
		leaf.Reflectance = 0.06
	end
	P.box(entrance, "EntranceDoor", Vector3.new(0.16, 8.6, 0.16), CFrame.new(0.9, 4.3, 0), "metal", false)
	-- Grade wings so the glass meets L1 outside the stair width.
	local function collar(z0: number, z1: number)
		if z1 < z0 then
			z0, z1 = z1, z0
		end
		local length = z1 - z0
		if length < 3 then
			return
		end
		local slab = P.box(
			entrance,
			"GradeCollarSlab",
			Vector3.new(12, 0.4, length - 0.4),
			CFrame.new(6, -0.22, (z0 + z1) / 2),
			"concrete",
			true
		)
		slab.Color = Color3.fromRGB(148, 146, 138)
	end
	collar(22.6, zGlassWest - 0.6)
	collar(zGlassEast + 0.6, -22.6)
	local lampY = groundAt(22, 20)
	local walkLamp = P.pole(entrance, "LightPole", Vector3.new(22, lampY, 20), 14, 0.16, "dark", true)
	walkLamp.Color = Color3.fromRGB(48, 50, 52)
	local globe =
		P.box(entrance, "LightGlobe", Vector3.new(1.1, 0.6, 1.1), CFrame.new(22, lampY + 14.4, 20), "metal", false)
	globe.Material = Enum.Material.SmoothPlastic
	globe.Color = Color3.fromRGB(255, 236, 200)

	-- Hoop racks on the east lawn and one bay at the west toe.
	for i = 0, 3 do
		local z = -width / 2 - 8 - i * 2.4
		pipe(entrance, "BikeRack", Vector3.new(8, 0.35, z), Vector3.new(8, 2.1, z))
		pipe(entrance, "BikeRack", Vector3.new(7.2, 0.35, z), Vector3.new(8.8, 0.35, z))
	end
	local rackY = -drop + 0.35
	pipe(
		entrance,
		"BikeRack",
		Vector3.new(apronX - 1, rackY, width / 2 + 5),
		Vector3.new(apronX - 1, rackY + 1.7, width / 2 + 5)
	)
	pipe(
		entrance,
		"BikeRack",
		Vector3.new(apronX - 1.8, rackY, width / 2 + 5),
		Vector3.new(apronX - 0.2, rackY, width / 2 + 5)
	)

	-- Vertical white RAC letters on the east glass, each about 4 ft (IMG_0368).
	local letters = P.folder(entrance, "RACLetterSign")
	local glyphs = {
		R = { "11110", "10001", "10001", "11110", "10100", "10010", "10001" },
		A = { "01110", "10001", "10001", "11111", "10001", "10001", "10001" },
		C = { "01110", "10001", "10000", "10000", "10000", "10001", "01110" },
	}
	local cell = 0.82
	local order = { "R", "A", "C" }
	local letterH = 7 * cell
	local gap = 0.55
	local letterZ = -24
	for index, ch in order do
		local top = 24.2 - (index - 1) * (letterH + gap)
		local rows = glyphs[ch]
		for row, bits in rows do
			for col = 1, 5 do
				if string.sub(bits, col, col) == "1" then
					local block = P.box(
						letters,
						"Letter",
						Vector3.new(0.22, cell * 0.9, cell * 0.9),
						CFrame.new(0.55, top - (row - 0.5) * cell, letterZ + (3 - col) * cell),
						"metal",
						false
					)
					block.Color = Color3.fromRGB(245, 245, 242)
					block.Material = Enum.Material.SmoothPlastic
				end
			end
		end
	end

	for _, item in entrance:GetDescendants() do
		if item:IsA("BasePart") then
			if
				item.Name == "LandingSlab"
				or item.Name == "ApronSlab"
				or item.Name == "ApproachSlab"
				or string.sub(item.Name, 1, 10) == "StairTread"
				or string.sub(item.Name, 1, 4) == "Ramp"
				or item.Name == "GradeCollarSlab"
			then
				item.Color = Color3.fromRGB(148, 146, 138)
			end
			item.CFrame = frame * item.CFrame
		end
	end

	-- South brick service court along l1_w079 (z = 47). Asphalt, precast brow, fence, dumpster.
	local yard = P.folder(parent, "ServiceYard")
	local yardY = H.height(-160, 64)
	P.box(yard, "ServiceAsphalt", Vector3.new(124, 0.4, 34), CFrame.new(-158, yardY + 0.16, 65), "asphalt", true)
	P.box(yard, "ServiceCanopy", Vector3.new(64, 1.1, 7.5), CFrame.new(-178, 13.4, 52.4), "concrete", true)
	for t = 0, 5 do
		P.box(
			yard,
			"ServiceCanopyFin",
			Vector3.new(0.35, 0.7, 6.2),
			CFrame.new(-202 + t * 10, 12.5, 52.6),
			"concrete",
			false
		)
	end
	local fenceZ = 80
	for x = -220, -120, 8 do
		P.pole(yard, "YardPost", Vector3.new(x, yardY, fenceZ), 6, 0.12, "dark", false)
	end
	P.beam(
		yard,
		"YardRail",
		Vector3.new(-220, yardY + 5.4, fenceZ),
		Vector3.new(-120, yardY + 5.4, fenceZ),
		0.2,
		0.2,
		"dark"
	)
	P.beam(
		yard,
		"YardRail",
		Vector3.new(-220, yardY + 0.8, fenceZ),
		Vector3.new(-120, yardY + 0.8, fenceZ),
		0.2,
		0.2,
		"dark"
	)
	local link =
		P.box(yard, "YardRailPanel", Vector3.new(100, 4.6, 0.12), CFrame.new(-170, yardY + 3.1, fenceZ), "metal", false)
	link.Transparency = 0.55
	link.Color = Color3.fromRGB(40, 42, 44)
	local dump = CFrame.new(-128, yardY, 58)
	P.box(yard, "DumpsterBody", Vector3.new(7.5, 4.4, 4.2), dump * CFrame.new(0, 2.2, 0), "green", true)
	P.box(yard, "DumpsterLid", Vector3.new(7.8, 0.35, 4.4), dump * CFrame.new(0, 4.5, 0), "dark", true)
	-- Double doors are on the brick wall. A dark glass leaf pair sits in front of the east door opening.
	P.box(yard, "ServiceDoor", Vector3.new(6, 7, 0.2), CFrame.new(-118, 3.6, 47.8), "glass", false)

	for _, d in site.details do
		if d.kind == "sunshade" or d.kind == "panel_joints" then
			local cf, length = G.frame(d.a, d.b, 0)
			if d.kind == "sunshade" then
				for t = 2, length - 2, d.spacing do
					local a = cf:PointToWorldSpace(Vector3.new(t, d.height - 1.5, -0.85))
					local b = cf:PointToWorldSpace(Vector3.new(t, d.height + 0.7, -d.projection))
					P.beam(parent, "SunshadeRoofFin", a, b, 0.3, 0.38, "metal")
				end
			end
		elseif d.kind == "hvac" then
			local cf = CFrame.new(d.at[1], d.y + 0.75, d.at[2])
			P.box(
				parent,
				"RoofHVACCurb",
				Vector3.new(d.size[1] + 0.3, 0.8, d.size[3] + 0.3),
				cf * CFrame.new(0, 0.4, 0),
				"dark"
			)
			P.box(
				parent,
				"RoofHVACCasing",
				Vector3.new(d.size[1], d.size[2], d.size[3]),
				cf * CFrame.new(0, d.size[2] / 2 + 0.8, 0),
				"metal"
			)
		end
	end
end
return Exterior
