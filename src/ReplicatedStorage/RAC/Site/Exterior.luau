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

local function darkMetal(part: BasePart)
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.fromRGB(32, 34, 36)
	part.Reflectance = 0
end

local function lampHead(parent: Instance, at: Vector3)
	local head = P.box(parent, "LightHead", Vector3.new(2.2, 0.36, 0.95), CFrame.new(at), "dark", false)
	darkMetal(head)
	local lens = P.box(
		parent,
		"LightHead",
		Vector3.new(1.7, 0.08, 0.55),
		CFrame.new(at + Vector3.new(0, -0.22, 0)),
		"white",
		false
	)
	lens.Material = Enum.Material.SmoothPlastic
	lens.Color = Color3.fromRGB(255, 232, 196)
	lens.CanCollide = false
	local lamp = Instance.new("PointLight")
	lamp.Brightness = 0.8
	lamp.Range = 36
	lamp.Color = Color3.fromRGB(255, 220, 180)
	lamp.Parent = lens
end

function Exterior.build(parent: Instance, site: any)
	local e = site.entrance
	local entrance = P.folder(parent, "Entrance")
	-- Scene stores the old west-stair center. The glass door on l1_w096 is at x = 0.
	local rotation = e.rotationDeg or -90
	local yaw = if math.abs(rotation + 90) < 1 then math.rad(rotation) else math.rad(-90)
	local frame = CFrame.new(0, 0, 0) * CFrame.Angles(0, yaw, 0)
	local function groundAt(lx: number, lz: number): number
		local world = frame:PointToWorldSpace(Vector3.new(lx, 0, lz))
		return H.height(world.X, world.Z)
	end

	-- 22 ft flight centered on the door. Eleven 7 in risers land on lidar near z = 30.
	local width = 22
	local n = 11
	local rise = 7 / 12
	local landingX = 0.65
	local landingDepth = 6
	local flightStart = landingX + landingDepth
	local toe = 30.2
	local run = (toe - flightStart) / n
	local drop = n * rise
	local function walkY(lx: number): number
		if lx <= flightStart then
			return 0
		end
		local step = math.floor((lx - flightStart) / run) + 1
		return -math.clamp(step, 1, n) * rise
	end

	P.box(
		entrance,
		"LandingSlab",
		Vector3.new(landingDepth, rise, width),
		CFrame.new(landingX + landingDepth / 2, -rise / 2, 0),
		"concrete",
		true
	)
	for i = 1, n do
		local top = -i * rise
		P.box(
			entrance,
			`StairTread_{i}`,
			Vector3.new(run, rise, width),
			CFrame.new(flightStart + (i - 0.5) * run, top - rise / 2, 0),
			"concrete",
			true
		)
	end
	local apronLen = 4
	P.box(
		entrance,
		"ApronSlab",
		Vector3.new(apronLen, 0.45, width),
		CFrame.new(toe + apronLen / 2, -drop - 0.225, 0),
		"concrete",
		true
	)

	-- Both cheeks and a center rail. The center pipe is the split in the entrance photos.
	local railTop = Vector3.new(landingX + 0.3, 3.15, 0)
	local railBottom = Vector3.new(toe + 0.8, -drop + 3.15, 0)
	for _, offset in { -width / 2 + 0.55, 0, width / 2 - 0.55 } do
		local a = railTop + Vector3.new(0, 0, offset)
		local b = railBottom + Vector3.new(0, 0, offset)
		pipe(entrance, "StairHandrail", a, b)
		local posts = math.max(2, math.ceil((b - a).Magnitude / 5))
		for k = 0, posts do
			local at = a:Lerp(b, k / posts)
			local foot = walkY(at.X)
			local height = at.Y - foot
			if height > 0.4 then
				local post = P.pole(entrance, "RailPost", Vector3.new(at.X, foot, at.Z), height, 0.075, "metal")
				post.Color = Color3.fromRGB(176, 180, 184)
			end
		end
	end

	-- East ramp beside the flight, same toe as the stairs. The hillside falls steeper than 1:12.
	local rampWidth = 5.2
	local rampZ = -width / 2 - 1.15 - rampWidth / 2
	local z0 = rampZ - rampWidth / 2
	local z1 = -width / 2
	P.box(
		entrance,
		"RampLanding",
		Vector3.new(landingDepth, rise, z1 - z0),
		CFrame.new(landingX + landingDepth / 2, -rise / 2, (z0 + z1) / 2),
		"concrete",
		true
	)
	P.beam(
		entrance,
		"RampRun",
		Vector3.new(flightStart, -0.18, rampZ),
		Vector3.new(toe, -drop - 0.18, rampZ),
		rampWidth,
		0.34,
		"concrete",
		true
	)
	P.box(
		entrance,
		"RampToe",
		Vector3.new(3.4, 0.4, rampWidth),
		CFrame.new(toe + 1.7, -drop - 0.2, rampZ),
		"concrete",
		true
	)
	local function rampFoot(lx: number): number
		if lx <= flightStart then
			return 0
		end
		local t = math.clamp((lx - flightStart) / (toe - flightStart), 0, 1)
		return -t * drop
	end
	for _, side in { -1, 1 } do
		local lz = rampZ + side * (rampWidth / 2 - 0.28)
		local a = Vector3.new(landingX + 0.4, 3.05, lz)
		local b = Vector3.new(toe + 1.2, -drop + 3.05, lz)
		pipe(entrance, "RampHandrail", a, b)
		local posts = math.max(2, math.ceil((b - a).Magnitude / 6))
		for k = 0, posts do
			local at = a:Lerp(b, k / posts)
			local foot = rampFoot(at.X)
			if at.Y - foot > 0.4 then
				local post =
					P.pole(entrance, "RampRailPost", Vector3.new(at.X, foot, at.Z), at.Y - foot, 0.075, "metal")
				post.Color = Color3.fromRGB(176, 180, 184)
			end
		end
	end

	-- Red barberry clumps on the west cheek, off the treads. Balls, not flat boxes.
	for i = 1, 3 do
		local lx = flightStart + (toe - flightStart) * (i - 0.35) / 3
		local foot = walkY(lx)
		local lz = width / 2 + 3.6
		local spots = {
			{ 0, 0.85, 0, 1.7 },
			{ 0.85, 0.5, 0.4, 1.15 },
			{ -0.7, 0.45, -0.35, 1.05 },
		}
		for _, spot in spots do
			local clump = P.box(
				entrance,
				"EntryBed",
				Vector3.new(spot[4], spot[4] * 0.72, spot[4] * 0.9),
				CFrame.new(lx + spot[1], foot + spot[2], lz + spot[3]),
				"barberry"
			)
			clump.Shape = Enum.PartType.Ball
			clump.CanCollide = false
		end
	end

	local canopy = P.folder(entrance, "Canopy")
	-- East-west wedge: thick at the west pier, knife at the east free edge. South view is the triangle.
	local soffit = 24.2
	local thick = 1.55
	local depth = 11
	local startX = 0.9
	local zWest = 12.2
	local zEast = -16
	local span = zWest - zEast
	local midZ = (zWest + zEast) / 2
	canopyWedge(
		canopy,
		"TaperedCanopy",
		Vector3.new(depth, thick, span),
		CFrame.new(startX + depth / 2, soffit + thick / 2, midZ)
	)
	-- Dark fascia hides the brick band above the door bay so the glass reads as ending at the soffit.
	local fascia =
		P.box(canopy, "CanopyFascia", Vector3.new(0.18, 8.15, span), CFrame.new(0.62, 28.22, midZ), "dark", true)
	fascia.Material = Enum.Material.SmoothPlastic
	fascia.Color = Color3.fromRGB(20, 22, 24)
	fascia.Reflectance = 0
	-- Thin return over the east glass, continuing the knife edge around the SE corner.
	local retZ0, retZ1 = -10.5, -16
	local retX0, retX1 = -12, 0.7
	local ret = P.box(
		canopy,
		"ReturnCanopy",
		Vector3.new(retX1 - retX0, 0.3, retZ0 - retZ1),
		CFrame.new((retX0 + retX1) / 2, soffit + 0.15, (retZ0 + retZ1) / 2),
		"dark",
		true
	)
	ret.Material = Enum.Material.SmoothPlastic
	ret.Color = Color3.fromRGB(20, 22, 24)
	ret.Reflectance = 0
	local eastFascia = P.box(
		canopy,
		"CanopyFascia",
		Vector3.new(retX1 - retX0 - 0.3, 8.15, 0.16),
		CFrame.new((retX0 + retX1) / 2 - 0.15, 28.22, -10.32),
		"dark",
		true
	)
	eastFascia.Material = Enum.Material.SmoothPlastic
	eastFascia.Color = Color3.fromRGB(20, 22, 24)
	eastFascia.Reflectance = 0

	-- Square dark columns under the soffit, just outside the door leaves.
	for _, lz in { 8.2, -7.6 } do
		local column =
			P.box(canopy, "SupportColumn", Vector3.new(1.45, 24.2, 1.45), CFrame.new(1.85, 12.05, lz), "dark", true)
		darkMetal(column)
	end
	for _, lz in { 6, 0, -6, -12 } do
		local mark =
			P.box(canopy, "SoffitLight", Vector3.new(0.7, 0.08, 0.7), CFrame.new(4.2, soffit - 0.08, lz), "dark")
		darkMetal(mark)
		mark.CanCollide = false
		local lamp = Instance.new("PointLight")
		lamp.Brightness = 0.35
		lamp.Range = 16
		lamp.Color = Color3.fromRGB(255, 214, 170)
		lamp.Parent = mark
	end

	local hx, hz = toe + 1.4, rampZ - rampWidth / 2 - 1.8
	local hy = groundAt(hx, hz)
	local barrel = P.pole(entrance, "Hydrant", Vector3.new(hx, hy, hz), 2.6, 0.32, "metal", false)
	barrel.Color = Color3.fromRGB(176, 32, 28)
	barrel.Material = Enum.Material.SmoothPlastic
	local cap = P.box(entrance, "HydrantCap", Vector3.new(0.7, 0.28, 0.7), CFrame.new(hx, hy + 2.7, hz), "metal", false)
	cap.Color = Color3.fromRGB(186, 188, 190)
	cap.Material = Enum.Material.SmoothPlastic

	local lampLx, lampLz = 18, -30
	local lampBase = groundAt(lampLx, lampLz)
	local walkLamp = P.pole(entrance, "LightPole", Vector3.new(lampLx, lampBase, lampLz), 16, 0.16, "dark", true)
	darkMetal(walkLamp)
	lampHead(entrance, Vector3.new(lampLx, lampBase + 16.35, lampLz))

	for i = 0, 1 do
		local z = rampZ - 6 - i * 2.6
		local by = groundAt(12, z)
		pipe(entrance, "BikeRack", Vector3.new(12, by + 0.15, z), Vector3.new(12, by + 1.9, z))
		pipe(entrance, "BikeRack", Vector3.new(11.2, by + 0.15, z), Vector3.new(12.8, by + 0.15, z))
	end

	-- One applied graphic. Stud-block RAC letters read as chunks on the glass.
	local letters = P.folder(entrance, "RACLetterSign")
	local sign = P.box(letters, "RACLetters", Vector3.new(0.08, 12, 2.0), CFrame.new(1.15, 16, -8.4), "metal", false)
	sign.Color = Color3.fromRGB(248, 248, 246)
	sign.Material = Enum.Material.SmoothPlastic
	sign.Transparency = 0.15
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
		local gui = Instance.new("SurfaceGui")
		gui.Name = "RAC"
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 42
		gui.LightInfluence = 0.25
		gui.Parent = sign
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = "R\nA\nC"
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextScaled = true
		label.Parent = gui
	end

	for _, item in entrance:GetDescendants() do
		if item:IsA("BasePart") then
			if
				item.Name == "LandingSlab"
				or item.Name == "ApronSlab"
				or item.Name == "RampLanding"
				or item.Name == "RampRun"
				or item.Name == "RampToe"
				or string.sub(item.Name, 1, 10) == "StairTread"
			then
				item.Color = Color3.fromRGB(148, 146, 138)
			end
			item.CFrame = frame * item.CFrame
		end
	end

	-- Service yard west of the volleyball gym. Lidar is flat near x=-204 and jumps at x=-214.
	local yard = P.folder(parent, "ServiceYard")
	local yardY = H.height(-203, -252)
	P.box(yard, "ServiceAsphalt", Vector3.new(14, 0.35, 40), CFrame.new(-203, yardY + 0.12, -252), "asphalt", true)
	local screenY = H.height(-209.2, -252)
	local screen =
		P.box(yard, "YardScreen", Vector3.new(0.7, 7.4, 38), CFrame.new(-209.2, screenY + 3.7, -252), "concrete", true)
	screen.Color = Color3.fromRGB(168, 164, 156)
	local endWall = P.box(
		yard,
		"YardScreen",
		Vector3.new(12, 7.4, 0.7),
		CFrame.new(-203.5, screenY + 3.7, -271.2),
		"concrete",
		true
	)
	endWall.Color = Color3.fromRGB(168, 164, 156)
	for _, z in { -240, -252, -264 } do
		local py = H.height(-209.2, z)
		P.pole(yard, "YardPost", Vector3.new(-209.2, py + 7.2, z), 2.2, 0.1, "dark", false)
	end
	P.beam(
		yard,
		"YardRail",
		Vector3.new(-209.2, screenY + 8.6, -268),
		Vector3.new(-209.2, screenY + 8.6, -236),
		0.16,
		0.16,
		"dark"
	)
	local function dumpster(x: number, z: number)
		local y = H.height(x, z)
		local dump = CFrame.new(x, y, z)
		P.box(yard, "DumpsterBody", Vector3.new(7.2, 4.2, 3.6), dump * CFrame.new(0, 2.42, 0), "green", true)
		P.box(yard, "DumpsterLid", Vector3.new(7.45, 0.28, 3.85), dump * CFrame.new(0, 4.62, 0), "dark", true)
	end
	dumpster(-204.5, -246)
	dumpster(-204.5, -260)
	local barY = H.height(-203, -233.5)
	P.beam(
		yard,
		"StopBar",
		Vector3.new(-208.5, barY + 0.28, -233.5),
		Vector3.new(-197.5, barY + 0.28, -233.5),
		1.4,
		0.08,
		"yellow",
		false
	)

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
