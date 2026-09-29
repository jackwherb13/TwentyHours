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
	wedge.Color = Color3.fromRGB(28, 30, 32)
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
	part.Color = Color3.fromRGB(42, 44, 46)
	part.Reflectance = 0.08
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
	-- Photos show one flight of about 8–10 risers. The top stays at FFE 0.
	local n = math.clamp(math.round(-groundAt(probeX, 0) / rise), 8, 10)
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
	-- Stop the flat pad where the lidar slope falls away, so the apron does not hover over the road.
	local apronLen = 8
	for len = 8, 34, 2 do
		if groundAt(apronX + len, 0) >= -drop - 0.55 then
			apronLen = len
		end
	end
	P.box(
		entrance,
		"ApronSlab",
		Vector3.new(apronLen, rise, width + 10),
		CFrame.new(apronX + apronLen / 2, -drop - rise / 2, 0),
		"concrete",
		true
	)
	-- Smooth strips over the lidar slope so the 4 ft terrain mesh does not read as broken steps.
	local stripLen = 6
	for s = 0, 7 do
		local nearX = apronX + apronLen + s * stripLen
		local farX = nearX + stripLen
		local y0 = math.min(groundAt(nearX, 0), -drop + 0.05)
		local y1 = math.min(groundAt(farX, 0), y0)
		local pitch = math.atan2(y1 - y0, stripLen)
		P.box(
			entrance,
			"ApproachSlab",
			Vector3.new(stripLen + 0.25, 0.4, width + 22),
			CFrame.new((nearX + farX) / 2, (y0 + y1) / 2 + 0.22, -4) * CFrame.Angles(0, 0, pitch),
			"concrete",
			true
		)
	end

	-- Three pipe runs: both cheeks and the center, matching the short flight in the entrance photos.
	local railTop = Vector3.new(e.landingDepth - 0.5, 3.1, 0)
	local railBottom = Vector3.new(apronX + 1.2, -drop + 3.1, 0)
	for _, offset in { -width / 2 + 0.7, 0, width / 2 - 0.7 } do
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
	for i = 0, 4 do
		local lx = 2 + (apronX - 4) * i / 4
		local along = (lx - 0.6) / math.max(apronX - 0.6, 1)
		local wallCenter = 1.7 + -drop * along
		local finish = if i % 2 == 0 then "shrub" else "barberry"
		P.box(entrance, "CheekShrub", Vector3.new(2.6, 1.35, 1.4), CFrame.new(lx, wallCenter + 2.35, cheekZ), finish)
	end

	-- East ramp, 1:12, the right-hand run in WEB_entrance_1 / IMG_0365. Stems carry it where the lidar slope is steeper.
	local rampWidth = 5.2
	local rampZ = -width / 2 - 1.4 - rampWidth / 2
	local rampStartX = e.landingDepth
	local bestLen = drop * 12
	local bestErr = math.huge
	for len = 48, 96, 4 do
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
	local depth = e.canopyDepth
	-- World X = entrance.x - local Z. Cover the south glass (about x=-97..10), not only the door.
	local coverWest = if e.coverWest ~= nil then e.coverWest else e.x - e.canopyWidth / 2
	local coverEast = if e.coverEast ~= nil then e.coverEast else e.x + e.canopyWidth / 2
	local zWest, zEast = e.x - coverWest, e.x - coverEast
	-- 0.3 ft soffit everywhere; the wedge adds 1.2 ft at the glass and dies out at the lip (1.5 → 0.3).
	local soffit = 23.1
	local tip = 0.3
	local canopyRise = 1.2
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
		plate.Color = Color3.fromRGB(28, 30, 32)
		plate.Reflectance = 0
		canopyWedge(
			canopy,
			"TaperedCanopy",
			Vector3.new(length, canopyRise, depth),
			CFrame.fromMatrix(
				Vector3.new(depth / 2 + 0.35, soffit + tip + canopyRise / 2, midZ),
				Vector3.new(0, 0, 1),
				Vector3.new(0, 1, 0),
				Vector3.new(-1, 0, 0)
			)
		)
	end
	local lo, hi = math.min(zWest, zEast), math.max(zWest, zEast)
	spanCanopy(lo, -9)
	spanCanopy(9, hi)
	-- East return over the corner glass. Yaw -90 maps local -Z to world +X, so the tip points east.
	local projection = math.max(12, e.returnCanopyDepth)
	local cornerX = if e.glassCorner then e.glassCorner[1] else e.x + width / 2
	local cornerLocalZ = e.x - cornerX
	local cornerPlate = P.box(
		canopy,
		"CanopySoffit",
		Vector3.new(28, tip, projection),
		CFrame.fromMatrix(
			Vector3.new(-6, soffit + tip / 2, cornerLocalZ - projection / 2),
			Vector3.new(1, 0, 0),
			Vector3.new(0, 1, 0),
			Vector3.new(0, 0, 1)
		),
		"dark",
		true
	)
	cornerPlate.Material = Enum.Material.SmoothPlastic
	cornerPlate.Color = Color3.fromRGB(28, 30, 32)
	cornerPlate.Reflectance = 0
	canopyWedge(
		canopy,
		"CornerCanopy",
		Vector3.new(28, rise, projection),
		CFrame.fromMatrix(
			Vector3.new(-6, soffit + tip + rise / 2, cornerLocalZ - projection / 2),
			Vector3.new(1, 0, 0),
			Vector3.new(0, 1, 0),
			Vector3.new(0, 0, 1)
		)
	)
	-- Slender round posts. The 1.7 ft black cylinders read as columns through the soffit.
	local columnHeight = soffit - 0.12
	for _, offset in { -16, 16 } do
		local column =
			P.pole(canopy, "SupportColumn", Vector3.new(8.5, 0.08, offset), columnHeight, 0.38, "metal", true)
		column.Material = Enum.Material.SmoothPlastic
		column.Color = Color3.fromRGB(78, 80, 82)
		column.Reflectance = 0
	end
	local function soffitLamp(lx: number, lz: number)
		local bulb =
			P.box(canopy, "SoffitLamp", Vector3.new(0.45, 0.08, 0.45), CFrame.new(lx, soffit - 0.12, lz), "metal")
		bulb.Material = Enum.Material.Neon
		bulb.Color = Color3.fromRGB(255, 236, 210)
		local light = Instance.new("PointLight")
		light.Brightness = 0.55
		light.Range = 14
		light.Color = Color3.fromRGB(255, 236, 210)
		light.Parent = bulb
	end
	for _, lz in { -24, -40, 20, 48, 76 } do
		if lz > lo + 3 and lz < hi - 3 and math.abs(lz) > 10 then
			soffitLamp(depth * 0.45, lz)
		end
	end

	-- Opaque white letters on the south curtain wall, just outside the glass.
	local function letter(sx: number, sy: number, sz: number, x: number, y: number, z: number)
		local part = P.box(entrance, "RACLetter", Vector3.new(sx, sy, sz), CFrame.new(x, y, z), "white")
		part.Material = Enum.Material.SmoothPlastic
		part.Color = Color3.fromRGB(248, 248, 244)
		part.Reflectance = 0
	end
	local sx, sz = 1.05, 24
	letter(0.32, 4.6, 0.42, sx, 17.2, sz - 1.15)
	letter(0.32, 0.42, 2.3, sx, 19.2, sz)
	letter(0.32, 0.42, 2.1, sx, 17.1, sz - 0.1)
	letter(0.32, 1.7, 0.42, sx, 18.2, sz + 0.95)
	letter(0.32, 2.1, 0.42, sx, 15.6, sz + 0.85)
	letter(0.32, 4.4, 0.42, sx, 11.4, sz - 1.15)
	letter(0.32, 0.42, 2.2, sx, 13.4, sz)
	letter(0.32, 0.42, 2.2, sx, 9.4, sz)
	letter(0.32, 4.4, 0.42, sx, 11.4, sz + 1.05)
	letter(0.32, 4.2, 0.42, sx, 5.6, sz - 1.15)
	letter(0.32, 0.42, 2.2, sx, 7.5, sz)
	letter(0.32, 0.42, 2.2, sx, 3.7, sz)
	letter(0.32, 4.2, 0.42, sx, 5.6, sz + 1.05)

	local hydrantAt = Vector3.new(apronX + 3, -drop, -width / 2 + 4)
	local hydrant = P.pole(entrance, "Hydrant", hydrantAt, 2.15, 0.28, "metal", true)
	hydrant.Color = Color3.fromRGB(176, 36, 32)
	hydrant.Material = Enum.Material.SmoothPlastic
	local cap = P.box(
		entrance,
		"HydrantCap",
		Vector3.new(0.62, 0.22, 0.62),
		CFrame.new(hydrantAt + Vector3.new(0, 2.32, 0)),
		"metal"
	)
	cap.Color = Color3.fromRGB(40, 40, 42)
	cap.Material = Enum.Material.Metal
	for _, side in { -1, 1 } do
		local nozzle = P.box(
			entrance,
			"HydrantNozzle",
			Vector3.new(0.55, 0.28, 0.28),
			CFrame.new(hydrantAt + Vector3.new(side * 0.4, 1.35, 0)),
			"metal"
		)
		nozzle.Color = Color3.fromRGB(176, 36, 32)
		nozzle.Material = Enum.Material.SmoothPlastic
	end

	-- Three hoops on the west landing. Dark metal, not a pipe pile in the lawn.
	for i = 0, 2 do
		local z = width / 2 + 6 + i * 2.2
		pipe(entrance, "BikeRack", Vector3.new(4.2, 0.4, z), Vector3.new(4.2, 2.15, z))
		pipe(entrance, "BikeRack", Vector3.new(3.5, 0.4, z), Vector3.new(4.9, 0.4, z))
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
