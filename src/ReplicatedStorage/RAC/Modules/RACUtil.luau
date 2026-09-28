-- ReplicatedStorage.RAC.Modules.RACUtil
-- Shared constructors. Edit dimensions in RACConfig, not here.

local RACUtil = {}

local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

function RACUtil.color(palette, name)
	local c = palette[name]
	if not c then
		error("Missing palette color: " .. tostring(name))
	end
	return rgb(c)
end

function RACUtil.material(name)
	local m = Enum.Material[name]
	if not m then
		error("Missing material: " .. tostring(name))
	end
	return m
end

function RACUtil.ensure(parent, className, name)
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end
	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = parent
	return inst
end

function RACUtil.part(parent, name, size, cf, color, material, extra)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = true
	if extra then
		if extra.transparency then
			p.Transparency = extra.transparency
		end
		if extra.canCollide ~= nil then
			p.CanCollide = extra.canCollide
		end
		if extra.castShadow ~= nil then
			p.CastShadow = extra.castShadow
		end
		if extra.reflectance then
			p.Reflectance = extra.reflectance
		end
	end
	p.Parent = parent
	return p
end

function RACUtil.sign(part, text, textColor, bgColor, face)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Sign"
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.4
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundColor3 = bgColor or Color3.fromRGB(20, 40, 28)
	label.BackgroundTransparency = bgColor and 0 or 0.15
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(255, 204, 0)
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = gui
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.04, 0)
	pad.PaddingRight = UDim.new(0.04, 0)
	pad.PaddingTop = UDim.new(0.08, 0)
	pad.PaddingBottom = UDim.new(0.08, 0)
	pad.Parent = label
	return gui
end

function RACUtil.folders(root)
	local names = {
		"Exterior",
		"FirstFloor",
		"SecondFloor",
		"Gymnasium",
		"FitnessAreas",
		"Hallways",
		"Offices",
		"LockerAreas",
		"Staircases",
		"Doors",
		"Windows",
		"Props",
		"Lighting",
		"HorrorGameplay",
		"InvisibleCollisions",
	}
	local f = {}
	for _, name in names do
		f[name] = RACUtil.ensure(root, "Folder", name)
	end
	return f
end

-- Axis-aligned or rotated wall from a to b (XZ). Openings are centered at `dist` from a.
-- kind: "none" | "window" | "single" | "double"
function RACUtil.wall(ctx, spec)
	local palette = ctx.palette
	local folders = ctx.folders
	local a = Vector3.new(spec.a[1], 0, spec.a[2])
	local b = Vector3.new(spec.b[1], 0, spec.b[2])
	local delta = b - a
	local length = delta.Magnitude
	if length < 0.25 then
		warn("RAC wall too short: " .. spec.name)
		return
	end
	local dir = delta.Unit
	local baseY = spec.y or 0
	local height = spec.h
	local thickness = spec.t or ctx.wallT or 0.8
	local color = RACUtil.color(palette, spec.color or "Wall")
	local material = RACUtil.material(spec.mat or "SmoothPlastic")
	local parent = folders[spec.folder or "FirstFloor"]
	local transparency = spec.transparency or 0
	local openings = {}
	for _, o in spec.openings or {} do
		table.insert(openings, o)
	end
	table.sort(openings, function(p, q)
		return p.dist < q.dist
	end)

	local function segment(fromDist, toDist, segY, segH, nameSuffix, segTrans, segColor, segMat, canCollide)
		local segLen = toDist - fromDist
		if segLen < 0.15 or segH < 0.15 then
			return nil
		end
		local midDist = (fromDist + toDist) * 0.5
		local mid = a + dir * midDist
		local pos = Vector3.new(mid.X, segY + segH * 0.5, mid.Z)
		local cf = CFrame.fromMatrix(pos, dir, Vector3.yAxis)
		local p = RACUtil.part(
			parent,
			spec.name .. nameSuffix,
			Vector3.new(segLen, segH, thickness),
			cf,
			segColor or color,
			segMat or material,
			{
				transparency = segTrans or transparency,
				canCollide = if canCollide == nil then true else canCollide,
			}
		)
		if spec.estimated then
			p:SetAttribute("Estimated", true)
		end
		return p
	end

	local cursor = 0
	for index, opening in openings do
		local half = opening.w * 0.5
		local startDist = opening.dist - half
		local endDist = opening.dist + half
		if startDist < -0.05 or endDist > length + 0.05 then
			warn(
				string.format(
					"RAC opening out of range on %s (dist %.1f width %.1f length %.1f)",
					spec.name,
					opening.dist,
					opening.w,
					length
				)
			)
		end
		startDist = math.clamp(startDist, 0, length)
		endDist = math.clamp(endDist, 0, length)
		segment(cursor, startDist, baseY, height, "_S" .. index)
		local sill = opening.sill or 0
		local openH = opening.h or (height - sill)
		if sill > 0 then
			segment(startDist, endDist, baseY, sill, "_Sill" .. index)
		end
		local headerBottom = baseY + sill + openH
		local headerH = (baseY + height) - headerBottom
		if headerH > 0.15 then
			segment(startDist, endDist, headerBottom, headerH, "_Head" .. index)
		end
		local kind = opening.kind or "none"
		local center = a + dir * opening.dist
		local centerPos = Vector3.new(center.X, baseY + sill + openH * 0.5, center.Z)
		local normal = dir:Cross(Vector3.yAxis)
		if kind == "window" then
			local glass = RACUtil.part(
				folders.Windows,
				spec.name .. "_Window" .. index,
				Vector3.new(math.max(opening.w - 0.2, 0.4), math.max(openH - 0.15, 0.4), 0.25),
				CFrame.fromMatrix(centerPos, dir, Vector3.yAxis),
				RACUtil.color(palette, "Glass"),
				Enum.Material.Glass,
				{ transparency = 0.45, reflectance = 0.15 }
			)
			glass:SetAttribute("Zone", spec.zone or "Exterior")
		elseif kind == "single" or kind == "double" then
			RACUtil.door(ctx, {
				name = opening.name or (spec.name .. "_Door" .. index),
				center = center,
				dir = dir,
				normal = normal,
				baseY = baseY + sill,
				width = opening.w,
				height = openH,
				kind = kind,
				glass = opening.glass,
				locked = opening.locked,
				requiresKey = opening.requiresKey,
				keyName = opening.keyName,
				openAngle = opening.openAngle,
				openTime = opening.openTime,
				autoClose = opening.autoClose,
				autoCloseDelay = opening.autoCloseDelay,
				zone = spec.zone,
				estimated = spec.estimated or opening.estimated,
			})
		end
		cursor = endDist
	end
	segment(cursor, length, baseY, height, "_SEnd")
end

function RACUtil.door(ctx, spec)
	local folders = ctx.folders
	local palette = ctx.palette
	local model = Instance.new("Model")
	model.Name = spec.name
	model.Parent = folders.Doors
	model:SetAttribute("Locked", spec.locked or false)
	model:SetAttribute("RequiresKey", spec.requiresKey or false)
	model:SetAttribute("KeyName", spec.keyName or "")
	model:SetAttribute("OpenTime", spec.openTime or 0.45)
	model:SetAttribute("AutoClose", if spec.autoClose == nil then true else spec.autoClose)
	model:SetAttribute("AutoCloseDelay", spec.autoCloseDelay or 4)
	model:SetAttribute("IsOpen", false)
	model:SetAttribute("Zone", spec.zone or "")
	if spec.estimated then
		model:SetAttribute("Estimated", true)
	end
	pcall(function()
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)

	local leaves = 1
	if spec.kind == "double" then
		leaves = 2
	end
	local gap = 0.15
	local leafW = if leaves == 2 then (spec.width * 0.5 - gap) else (spec.width - 0.35)
	leafW = math.max(leafW, 1.5)
	local leafH = math.max((spec.height or 7) - 0.15, 6)
	local doorColor = if spec.glass
		then RACUtil.color(palette, "Glass")
		else RACUtil.color(palette, spec.doorColor or "Door")
	local doorMat = if spec.glass then Enum.Material.Glass else Enum.Material.SmoothPlastic
	local doorTrans = if spec.glass then 0.4 else 0

	local function makeLeaf(leafName, hingeWorld, xAxis, angle)
		local center = hingeWorld + xAxis * (leafW * 0.5)
		local hinge = RACUtil.part(
			model,
			leafName .. "Hinge",
			Vector3.new(0.35, leafH, 0.35),
			CFrame.fromMatrix(hingeWorld, xAxis, Vector3.yAxis),
			RACUtil.color(palette, "Frame"),
			Enum.Material.Metal,
			{ canCollide = false, castShadow = false }
		)
		local door = RACUtil.part(
			model,
			"Door",
			Vector3.new(leafW, leafH, 0.22),
			CFrame.fromMatrix(center + Vector3.new(0, 0, 0), xAxis, Vector3.yAxis),
			doorColor,
			doorMat,
			{ transparency = doorTrans, reflectance = if spec.glass then 0.1 else 0.02 }
		)
		door.Name = "Door"
		door:SetAttribute("Leaf", leafName)
		door:SetAttribute("OpenAngle", angle)
		hinge.Name = "Hinge"
		hinge.Parent = door

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ProximityPrompt"
		prompt.ActionText = "Open"
		prompt.ObjectText = spec.name
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 8
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.Parent = door

		local sounds = Instance.new("Folder")
		sounds.Name = "Sounds"
		sounds.Parent = door
		for _, soundName in { "Open", "Close", "Locked" } do
			local s = Instance.new("Sound")
			s.Name = soundName
			s.Volume = 0.7
			s.RollOffMaxDistance = 40
			s.Parent = sounds
		end
		return door
	end

	local mid = Vector3.new(spec.center.X, spec.baseY + leafH * 0.5, spec.center.Z)
	local dir = spec.dir.Unit
	if leaves == 1 then
		local angle = spec.openAngle or 90
		local hinge = mid - dir * (leafW * 0.5)
		makeLeaf("Single", hinge, dir, angle)
	else
		local angle = spec.openAngle or 90
		local leftHinge = mid - dir * (spec.width * 0.5 - 0.05)
		local rightHinge = mid + dir * (spec.width * 0.5 - 0.05)
		makeLeaf("Left", leftHinge, dir, angle)
		makeLeaf("Right", rightHinge, -dir, -angle)
	end

	local marker = RACUtil.part(
		model,
		"FrameMarker",
		Vector3.new(spec.width, 0.18, 0.4),
		CFrame.fromMatrix(Vector3.new(spec.center.X, spec.baseY + leafH + 0.1, spec.center.Z), dir, Vector3.yAxis),
		RACUtil.color(palette, "Frame"),
		Enum.Material.Metal,
		{ canCollide = false, castShadow = false }
	)
	marker.Parent = model

	local CollectionService = game:GetService("CollectionService")
	CollectionService:AddTag(model, "RACDoor")
	return model
end

function RACUtil.floor(ctx, spec)
	local folders = ctx.folders
	local parent = folders[spec.folder or "FirstFloor"]
	local y = spec.y or 0
	local thick = spec.thick or 1
	local cf = CFrame.new(spec.x + spec.w * 0.5, y - thick * 0.5, spec.z + spec.d * 0.5)
	local p = RACUtil.part(
		parent,
		spec.name,
		Vector3.new(spec.w, thick, spec.d),
		cf,
		RACUtil.color(ctx.palette, spec.color or "Tile"),
		RACUtil.material(spec.mat or "Concrete"),
		{ castShadow = false }
	)
	if spec.estimated then
		p:SetAttribute("Estimated", true)
	end
	if spec.ceil then
		local ceilH = spec.ceil
		local slab = spec.ceilThick or 0.6
		local c = RACUtil.part(
			parent,
			spec.name .. "_Ceiling",
			Vector3.new(spec.w, slab, spec.d),
			CFrame.new(spec.x + spec.w * 0.5, y + ceilH + slab * 0.5, spec.z + spec.d * 0.5),
			RACUtil.color(ctx.palette, spec.ceilColor or "Ceiling"),
			RACUtil.material(spec.ceilMat or "SmoothPlastic"),
			{ castShadow = false }
		)
		if spec.estimated then
			c:SetAttribute("Estimated", true)
		end
	end
	return p
end

function RACUtil.rail(ctx, spec)
	local y = spec.y or 0
	local a = Vector3.new(spec.a[1], y, spec.a[2])
	local b = Vector3.new(spec.b[1], y, spec.b[2])
	local delta = b - a
	local length = delta.Magnitude
	if length < 0.2 then
		return
	end
	local dir = delta.Unit
	local mid = (a + b) * 0.5
	local parent = ctx.folders[spec.folder or "SecondFloor"]
	local color = RACUtil.color(ctx.palette, "Rail")
	RACUtil.part(
		parent,
		(spec.name or "Rail") .. "_Top",
		Vector3.new(length, 0.25, 0.25),
		CFrame.fromMatrix(mid + Vector3.new(0, 3.4, 0), dir, Vector3.yAxis),
		color,
		Enum.Material.Metal
	)
	RACUtil.part(
		parent,
		(spec.name or "Rail") .. "_Mid",
		Vector3.new(length, 0.15, 0.15),
		CFrame.fromMatrix(mid + Vector3.new(0, 2.0, 0), dir, Vector3.yAxis),
		color,
		Enum.Material.Metal,
		{ castShadow = false }
	)
	local posts = math.max(2, math.floor(length / 6))
	for i = 0, posts do
		local p0 = a + dir * (length * (i / posts))
		RACUtil.part(
			parent,
			(spec.name or "Rail") .. "_Post" .. i,
			Vector3.new(0.2, 3.5, 0.2),
			CFrame.new(p0 + Vector3.new(0, 1.75, 0)),
			color,
			Enum.Material.Metal,
			{ castShadow = false }
		)
	end
	local blocker = RACUtil.part(
		ctx.folders.InvisibleCollisions,
		(spec.name or "Rail") .. "_Blocker",
		Vector3.new(length, 4.2, 0.4),
		CFrame.fromMatrix(mid + Vector3.new(0, 2.1, 0), dir, Vector3.yAxis),
		Color3.new(1, 1, 1),
		Enum.Material.SmoothPlastic,
		{ transparency = 1, castShadow = false }
	)
	blocker.CanQuery = false
end

function RACUtil.stairs(ctx, spec)
	local parent = ctx.folders.Staircases
	local origin = Vector3.new(spec.origin[1], spec.origin[2], spec.origin[3])
	local dir = Vector3.new(spec.dir[1], 0, spec.dir[2]).Unit
	-- selene: allow(incorrect_standard_library_use)
	local right = Vector3.yAxis:Cross(dir)
	local steps = spec.steps
	local rise = spec.rise
	local run = spec.run
	local width = spec.width or 6
	local color = RACUtil.color(ctx.palette, spec.color or "Stair")
	local mat = RACUtil.material(spec.mat or "Concrete")
	for i = 1, steps do
		local center = origin + dir * (run * (i - 0.5)) + Vector3.new(0, rise * (i - 0.5), 0)
		RACUtil.part(
			parent,
			spec.name .. "_" .. i,
			Vector3.new(width, rise, run),
			CFrame.fromMatrix(center, right, Vector3.yAxis),
			color,
			mat,
			{ castShadow = false }
		)
	end
	local totalRise = rise * steps
	local totalRun = run * steps
	local side = right * (width * 0.5 + 0.15)
	for index, sign in { 1, -1 } do
		local a = origin + side * sign
		local b = origin + dir * totalRun + side * sign
		local mid = (a + b) * 0.5 + Vector3.new(0, totalRise * 0.5, 0)
		local along = (b - a).Unit
		RACUtil.part(
			ctx.folders.InvisibleCollisions,
			spec.name .. "_SideBlock" .. index,
			Vector3.new(totalRun, totalRise + 4, 0.45),
			CFrame.fromMatrix(mid + Vector3.new(0, 1.5, 0), along, Vector3.yAxis),
			Color3.new(1, 1, 1),
			Enum.Material.SmoothPlastic,
			{ transparency = 1, castShadow = false }
		)
		RACUtil.part(
			parent,
			spec.name .. "_Hand" .. index,
			Vector3.new(totalRun, 0.2, 0.2),
			CFrame.fromMatrix(
				b + Vector3.new(0, 3.2, 0) + (a - b) * 0.5 + Vector3.new(0, totalRise * 0.15, 0),
				along,
				Vector3.yAxis
			),
			RACUtil.color(ctx.palette, "Rail"),
			Enum.Material.Metal,
			{ canCollide = false, castShadow = false }
		)
	end
	if spec.landing then
		local L = spec.landing
		RACUtil.floor(ctx, {
			name = spec.name .. "_Landing",
			x = L.x,
			z = L.z,
			w = L.w,
			d = L.d,
			y = spec.origin[2] + totalRise,
			color = "Tile",
			mat = "Concrete",
			folder = "SecondFloor",
		})
	end
end

function RACUtil.fixture(ctx, spec)
	local zoneFolder = ctx.lightZones[spec.zone]
	if not zoneFolder then
		error("Unknown light zone " .. tostring(spec.zone))
	end
	local pos = Vector3.new(spec.x, spec.y, spec.z)
	local size = spec.size or { 4, 0.25, 1.4 }
	local fixture = RACUtil.part(
		zoneFolder,
		spec.name or (spec.zone .. "Fixture"),
		Vector3.new(size[1], size[2], size[3]),
		CFrame.new(pos),
		RACUtil.color(ctx.palette, "Fixture"),
		Enum.Material.SmoothPlastic,
		{ canCollide = false, castShadow = false }
	)
	local light = Instance.new("PointLight")
	light.Name = if spec.emergency then "EmergencyLight" else "NormalLight"
	light.Brightness = spec.brightness or 1.1
	light.Range = spec.range or 22
	light.Color = if spec.emergency then Color3.fromRGB(255, 60, 40) else Color3.fromRGB(255, 244, 220)
	light.Shadows = false
	light.Enabled = not spec.emergency
	light.Parent = fixture
	local CollectionService = game:GetService("CollectionService")
	CollectionService:AddTag(light, if spec.emergency then "EmergencyLight" else "NormalLight")
	light:SetAttribute("Zone", spec.zone)
	return fixture
end

function RACUtil.rowLights(ctx, spec)
	local a = Vector3.new(spec.x1, 0, spec.z1)
	local b = Vector3.new(spec.x2, 0, spec.z2)
	local length = (b - a).Magnitude
	local dir = (b - a).Unit
	local count = math.max(1, math.floor(length / spec.spacing))
	for i = 0, count do
		local p = a + dir * (if count == 0 then length * 0.5 else (length * i / count))
		RACUtil.fixture(ctx, {
			name = spec.zone .. "_L" .. i .. "_" .. (spec.row or 1),
			x = p.X,
			y = spec.y,
			z = p.Z,
			zone = spec.zone,
			brightness = spec.brightness,
			range = spec.range,
			size = spec.size,
			emergency = spec.emergency,
		})
	end
end

return RACUtil
