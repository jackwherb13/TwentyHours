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
	wedge.Color = Color3.fromRGB(12, 12, 14)
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
	-- Foot of the flight is one landing plus the treads south of the glass. Count risers from that lidar sample.
	local probeX = e.landingDepth + e.risers * run + 4
	-- Top of the flight is the glass threshold (L1). The toe sits on the raised south walk, not in a pit.
	local n = math.clamp(math.round(-groundAt(probeX, 0) / rise), 4, 7)
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
				post.Color = Color3.fromRGB(58, 62, 66)
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

	-- East ramp, 1:12, the right-hand run in WEB_entrance_1 / IMG_0365. Stems carry it where the lidar slope is steeper.
	local rampWidth = 5.2
	local rampZ = -width / 2 - 1.4 - rampWidth / 2
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
	local padNear = -width / 2 + 1.5
	local padFar = rampZ - rampWidth / 2
	P.box(
		entrance,
		"RampLandingSlab",
		Vector3.new(e.landingDepth - 0.6, rise, padNear - padFar),
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
				post.Color = Color3.fromRGB(58, 62, 66)
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
	-- Small canopy over the south door. The glass hall to the west stays open.
	local depth = 8
	local southWest, southEast = -14, 14
	local zWest, zEast = e.x - southWest, e.x - southEast
	-- Curtain head is 30 ft. The soffit sits just above it.
	local soffit = 30.5
	local tip = 0.4
	local canopyRise = 1.55
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
		plate.Color = Color3.fromRGB(14, 14, 16)
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
	local lo, hi = math.min(zWest, zEast), math.max(zWest, zEast)
	spanCanopy(lo, hi)
	-- Dark square piers, one on the door and one at the east end of the south glass.
	local columnHeight = soffit - 0.2
	local eastColumnZ = e.x - southEast
	for _, at in { Vector3.new(depth - 3, 0, 0), Vector3.new(depth - 3, 0, eastColumnZ + 2.2) } do
		local column = P.box(
			canopy,
			"SupportColumn",
			Vector3.new(2.4, columnHeight, 2.4),
			CFrame.new(at.X, columnHeight / 2 + 0.06, at.Z),
			"dark",
			true
		)
		column.Material = Enum.Material.SmoothPlastic
		column.Color = Color3.fromRGB(16, 16, 18)
		column.Reflectance = 0
	end
	-- A few dark recesses, not a white neon ceiling.
	for lz = lo + 8, hi - 8, 14 do
		for _, lx in { depth * 0.35, depth * 0.7 } do
			local mark =
				P.box(canopy, "SoffitMark", Vector3.new(0.35, 0.04, 0.35), CFrame.new(lx, soffit - 0.04, lz), "dark")
			mark.Color = Color3.fromRGB(18, 18, 18)
			mark.Material = Enum.Material.SmoothPlastic
		end
	end
	-- Red shrubs along the west glass. The east side is a concrete planter, not a bed on the treads.
	for i = 2, 4 do
		local bed = P.box(entrance, "EntryBed", Vector3.new(2.6, 1.5, 4.2), CFrame.new(2.2, 0.75, i * 5.4), "barberry")
		bed.CanCollide = false
	end
	local planter =
		P.box(entrance, "PlanterWall", Vector3.new(3.4, 2.7, 16), CFrame.new(7.5, 1.35, -16), "concrete", true)
	planter.Color = Color3.fromRGB(168, 166, 158)
	local hedge = P.box(entrance, "PlanterHedge", Vector3.new(2.6, 1.6, 14.4), CFrame.new(7.5, 3.2, -16), "shrub")
	hedge.CanCollide = false
	-- Red hydrant at the west curb of the stair toe (IMG_0368), off the landing.
	local hydrantAt = Vector3.new(apronX + 1.2, -drop, width / 2 + 2.6)
	local barrel = P.pole(entrance, "Hydrant", hydrantAt, 2.15, 0.32, "metal", false)
	barrel.Color = Color3.fromRGB(168, 32, 28)
	barrel.Material = Enum.Material.SmoothPlastic
	local cap = P.box(
		entrance,
		"HydrantCap",
		Vector3.new(0.7, 0.28, 0.7),
		CFrame.new(hydrantAt.X, -drop + 2.25, hydrantAt.Z),
		"metal",
		false
	)
	cap.Color = Color3.fromRGB(168, 32, 28)
	cap.Material = Enum.Material.SmoothPlastic

	-- Photo-placed hoop racks east of the ramp, not the west lawn pipes.
	for i = 0, 3 do
		local z = -width / 2 - 8 - i * 2.4
		pipe(entrance, "BikeRack", Vector3.new(6.2, 0.35, z), Vector3.new(6.2, 2.1, z))
		pipe(entrance, "BikeRack", Vector3.new(5.4, 0.35, z), Vector3.new(7.0, 0.35, z))
	end

	-- Vertical white RAC letters on the east glass, each about 4 ft (IMG_0368).
	local letters = P.folder(entrance, "RACLetterSign")
	local glyphs = {
		R = { "11110", "10001", "10001", "11110", "10100", "10010", "10001" },
		A = { "01110", "10001", "10001", "11111", "10001", "10001", "10001" },
		C = { "01110", "10001", "10000", "10000", "10000", "10001", "01110" },
	}
	local cell = 0.58
	local order = { "R", "A", "C" }
	local letterH = 7 * cell
	local gap = 0.45
	local letterZ = -30
	for index, ch in order do
		local top = 23.5 - (index - 1) * (letterH + gap)
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
