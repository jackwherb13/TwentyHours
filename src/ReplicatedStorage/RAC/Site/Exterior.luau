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
	-- Neon keeps the sun from blowing the sloped top out to white. The color stays charcoal.
	wedge.Material = Enum.Material.Neon
	wedge.Color = Color3.fromRGB(22, 24, 26)
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
		Vector3.new(length, 0.16, 0.16),
		CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0),
		"metal"
	)
	part.Shape = Enum.PartType.Cylinder
	part.Color = Color3.fromRGB(58, 62, 66)
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
	local n = math.clamp(math.round(-groundAt(probeX, 0) / rise), 8, 14)
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

	-- Sides plus three intermediate rails, the count visible across IMG_0365 / WEB_entrance_2.
	local railTop = Vector3.new(e.landingDepth - 0.5, 3, 0)
	local railBottom = Vector3.new(apronX + 1.2, -drop + 3, 0)
	for _, offset in { -width / 2 + 0.4, -width / 4, 0, width / 4, width / 2 - 0.4 } do
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

	-- Low planted cheek on the left when facing the doors. It stays on the landing,
	-- not a wall running the full grade drop.
	P.box(
		entrance,
		"PlanterCheek",
		Vector3.new(e.landingDepth + 6, 2.2, 3.2),
		CFrame.new((e.landingDepth + 6) / 2, 1.1, width / 2 + 2.4),
		"concrete",
		true
	)
	P.box(
		entrance,
		"PlanterHedge",
		Vector3.new(e.landingDepth + 5, 2.4, 2.6),
		CFrame.new((e.landingDepth + 5) / 2, 3.3, width / 2 + 2.4),
		"leaf"
	)

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
	local span = e.canopyWidth
	local thick = 6.5
	local soffit = 23.1
	-- Thick end on the glass, point at the outer edge. Top plane slopes down; the soffit stays flat.
	canopyWedge(
		canopy,
		"TaperedCanopy",
		Vector3.new(span, thick, depth),
		CFrame.fromMatrix(
			Vector3.new(depth / 2, soffit + thick / 2, 0),
			Vector3.new(0, 0, 1),
			Vector3.new(0, 1, 0),
			Vector3.new(-1, 0, 0)
		)
	)
	-- East return over the corner glass. Yaw -90 maps local -Z to world +X, so the tip points east.
	local projection = math.max(12, e.returnCanopyDepth)
	local cornerX = if e.glassCorner then e.glassCorner[1] else e.x + width / 2
	local cornerLocalZ = e.x - cornerX
	canopyWedge(
		canopy,
		"CornerCanopy",
		Vector3.new(24, thick, projection),
		CFrame.fromMatrix(
			Vector3.new(-2, soffit + thick / 2, cornerLocalZ - projection / 2),
			Vector3.new(1, 0, 0),
			Vector3.new(0, 1, 0),
			Vector3.new(0, 0, 1)
		)
	)
	for _, offset in { -width * 0.32, width * 0.32 } do
		local columnHeight = soffit - 0.08
		local column = P.box(
			canopy,
			"SupportColumn",
			Vector3.new(2, columnHeight, 2),
			CFrame.new(e.landingDepth - 2.5, columnHeight / 2, offset),
			"metal",
			true
		)
		-- Metal reflectance turns the pale columns sky-blue. The photos are matte concrete.
		column.Material = Enum.Material.Neon
		column.Color = Color3.fromRGB(42, 44, 46)
		column.Reflectance = 0
	end
	for _, lampZ in { -8, 8 } do
		local bulb = P.box(
			canopy,
			"SoffitLamp",
			Vector3.new(0.6, 0.12, 0.6),
			CFrame.new(e.landingDepth, soffit - 0.4, lampZ),
			"metal"
		)
		bulb.Material = Enum.Material.Neon
		bulb.Color = Color3.fromRGB(255, 232, 200)
		local light = Instance.new("PointLight")
		light.Brightness = 1.6
		light.Range = 40
		light.Color = Color3.fromRGB(255, 232, 200)
		light.Parent = bulb
	end

	local sign = P.box(entrance, "RACSign", Vector3.new(0.2, 22, 5), CFrame.new(0.4, 14, -8), "glass")
	sign.Transparency = 1
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Right
	gui.LightInfluence = 0
	gui.CanvasSize = Vector2.new(220, 900)
	gui.Parent = sign
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = "R\nA\nC"
	text.TextScaled = true
	text.TextColor3 = Color3.fromRGB(244, 244, 236)
	text.Parent = gui

	for _, item in entrance:GetDescendants() do
		if item:IsA("BasePart") then
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
