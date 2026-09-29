--!strict
local P = require(script.Parent.Primitives)
local H = require(script.Parent.Heightfield)
local G = require(script.Parent.Parent.Build.Geometry)
local Landscape = {}

local function onAsphalt(x: number, z: number): boolean
	local d = H.data
	local function raw(px: number, pz: number): boolean
		local u = math.clamp((px - d.x0) / d.step - 0.5, 0, d.nx - 1.001)
		local v = math.clamp((pz - d.z0) / d.step - 0.5, 0, d.nz - 1.001)
		local i, j = math.floor(u) + 1, math.floor(v) + 1
		return string.sub(d.materials[j], i, i) == "2"
	end
	if raw(x, z) then
		return true
	end
	local paved = 0
	for _, o in { { 4, 0 }, { -4, 0 }, { 0, 4 }, { 0, -4 } } do
		if raw(x + o[1], z + o[2]) then
			paved += 1
		end
	end
	return paved >= 2
end

local GREENS = {
	Color3.fromRGB(54, 88, 44),
	Color3.fromRGB(42, 74, 36),
	Color3.fromRGB(66, 98, 50),
	Color3.fromRGB(48, 80, 40),
}

local function foliageBall(parent: Instance, center: Vector3, diameter: number, color: Color3)
	local part = P.box(
		parent,
		"Crown",
		Vector3.new(diameter, diameter * 0.8, diameter * 0.92),
		CFrame.new(center),
		"leaf",
		false
	)
	part.Shape = Enum.PartType.Ball
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	return part
end

local function pineCone(parent: Instance, center: Vector3, diameter: number, height: number, color: Color3)
	local part = P.box(parent, "Crown", Vector3.new(diameter, height, diameter), CFrame.new(center), "pine", false)
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	local mesh = Instance.new("SpecialMesh")
	-- This runtime's MeshType has Pyramid, not Cone. A stacked pyramid is the pine silhouette.
	mesh.MeshType = Enum.MeshType.Pyramid
	mesh.Scale = Vector3.new(1, 1, 1)
	mesh.Parent = part
	return part
end

-- Trunk plus 4 ellipsoid clusters, or a pine of stacked cones. No wedge crowns.
local function tree(parent: Instance, item: any, index: number)
	local p = item.at
	local scale = 0.8 + ((index * 17) % 5) * 0.1
	local height = math.clamp(item.height * scale, 14, 24)
	local y = H.height(p[1], p[2])
	local pine = item.species == "pine" or (index % 5 == 0)
	local model = P.folder(parent, if pine then "PineCanopy" else "ShadeCanopy")
	local trunkH = if pine then height * 0.46 else height * 0.42
	local trunkW = if pine then 0.85 else 1.15
	local trunk = P.pole(model, "Trunk", Vector3.new(p[1], y, p[2]), trunkH, trunkW / 2, "bark", false)
	trunk.Color = Color3.fromRGB(92, 74, 56)
	if pine then
		local layers = {
			{ t = 0.34, d = 0.62, h = 0.36 },
			{ t = 0.52, d = 0.48, h = 0.3 },
			{ t = 0.68, d = 0.34, h = 0.26 },
			{ t = 0.82, d = 0.2, h = 0.22 },
		}
		for layerIndex, layer in layers do
			pineCone(
				model,
				Vector3.new(p[1], y + height * layer.t, p[2]),
				height * layer.d,
				height * layer.h,
				Color3.fromRGB(26 + layerIndex * 4, 56 + layerIndex * 3, 34)
			)
		end
	else
		local crown = height * 0.42
		local spots = {
			{ 0, crown * 0.12, 0, 1.15, 1 },
			{ crown * 0.32, crown * 0.02, crown * 0.14, 0.78, 2 },
			{ -crown * 0.26, -crown * 0.04, crown * 0.2, 0.7, 3 },
			{ crown * 0.06, crown * 0.34, -crown * 0.18, 0.62, 4 },
		}
		for _, spot in spots do
			foliageBall(
				model,
				Vector3.new(p[1] + spot[1], y + trunkH * 0.7 + spot[2], p[2] + spot[3]),
				crown * spot[4] * 1.45,
				GREENS[spot[5]]
			)
		end
	end
end

function Landscape.build(parent: Instance, site: any, props: any)
	local trees = P.folder(parent, "Trees")
	assert(#site.trees <= 150, "Tree budget exceeded")
	for i, item in site.trees do
		local at = item.at
		-- Keep the south glass and the door-centered flight clear. The east lot still gets trees.
		if at[1] > -108 and at[1] < 18 and at[2] > -26 and at[2] < 20 then
			continue
		end
		if math.abs(at[1]) < 28 and at[2] > -4 and at[2] < 44 then
			continue
		end
		local pads = {}
		if site.terrain and site.terrain.padPolygons then
			for _, polygon in site.terrain.padPolygons do
				table.insert(pads, polygon)
			end
		end
		if site.footprint then
			table.insert(pads, site.footprint)
		end
		local blocked = false
		local reach = (item.radius or 8) + 8
		for _, polygon in pads do
			if G.contains(polygon, at[1], at[2]) then
				blocked = true
				break
			end
			for k = 0, 11 do
				local a = k * math.pi / 6
				if G.contains(polygon, at[1] + math.cos(a) * reach, at[2] + math.sin(a) * reach) then
					blocked = true
					break
				end
			end
			if blocked then
				break
			end
		end
		if blocked or onAsphalt(at[1], at[2]) then
			continue
		end
		tree(trees, item, i)
	end
	local function onPad(x: number, z: number): boolean
		for _, polygon in site.terrain.padPolygons do
			if G.contains(polygon, x, z) then
				return true
			end
		end
		return false
	end
	local fences = P.folder(parent, "Fences")
	for _, fence in site.fences do
		for i = 1, #fence.points - 1 do
			local a, b = fence.points[i], fence.points[i + 1]
			local length = Vector3.new(b[1] - a[1], 0, b[2] - a[2]).Magnitude
			local steps = math.max(1, math.ceil(length / 8))
			for k = 0, steps do
				local x, z = a[1] + (b[1] - a[1]) * k / steps, a[2] + (b[2] - a[2]) * k / steps
				if onPad(x, z) then
					continue
				end
				local y = H.height(x, z)
				P.pole(fences, "FencePost", Vector3.new(x, y, z), fence.height, 0.15, "dark", true)
				if k < steps then
					local x1 = a[1] + (b[1] - a[1]) * (k + 1) / steps
					local z1 = a[2] + (b[2] - a[2]) * (k + 1) / steps
					if onPad(x1, z1) then
						continue
					end
					local y1 = H.height(x1, z1)
					for _, lift in { 0.5, fence.height - 0.1 } do
						P.beam(
							fences,
							"FenceRail",
							Vector3.new(x, y + lift, z),
							Vector3.new(x1, y1 + lift, z1),
							0.3,
							0.3,
							"dark"
						)
					end
				end
			end
		end
	end
	for _, prop in props do
		if string.sub(prop.id, 1, 5) ~= "site_" then
			continue
		end
		local x, z = prop.at[1], prop.at[2]
		local y = H.height(x, z)
		local cf = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(prop.rotation), 0)
		if prop.kind == "site_lamp" then
			local base = y - 0.5
			local pole = P.box(
				parent,
				"LightPole",
				Vector3.new(0.32, y + 16 - base, 0.32),
				CFrame.new(x, (base + y + 16) / 2, z),
				"dark",
				true
			)
			pole.Material = Enum.Material.SmoothPlastic
			pole.Color = Color3.fromRGB(32, 34, 36)
			pole.Reflectance = 0
			local head = P.box(parent, "LightHead", Vector3.new(2.3, 0.38, 1.0), cf * CFrame.new(0, 16.35, 0), "dark")
			head.Material = Enum.Material.SmoothPlastic
			head.Color = Color3.fromRGB(28, 30, 32)
			head.Reflectance = 0
			local lens =
				P.box(parent, "LightHead", Vector3.new(1.8, 0.08, 0.58), cf * CFrame.new(0, 16.12, 0), "white", false)
			lens.Material = Enum.Material.SmoothPlastic
			lens.Color = Color3.fromRGB(255, 232, 196)
			local lamp = Instance.new("PointLight")
			lamp.Brightness = 1.2
			lamp.Range = 42
			lamp.Color = Color3.fromRGB(255, 228, 190)
			lamp.Parent = lens
		elseif prop.kind == "site_dumpster" then
			P.box(parent, "DumpsterBody", Vector3.new(6, 4, 3.7), cf * CFrame.new(0, 2, 0), "green", true)
			P.box(
				parent,
				"DumpsterLid",
				Vector3.new(6.2, 0.3, 3.9),
				cf * CFrame.new(0, 4.13, 0) * CFrame.Angles(0.04, 0, 0),
				"dark"
			)
			for _, off in { -2.5, 2.5 } do
				P.box(parent, "DumpsterForkPocket", Vector3.new(0.5, 0.6, 2), cf * CFrame.new(off, 2.2, 1.5), "dark")
			end
		elseif prop.kind == "site_shrub_bed" then
			P.box(parent, "PlanterSlab", Vector3.new(14, 0.4, 5), cf, "concrete")
			P.box(parent, "Hedge", Vector3.new(12.5, 2.4, 3.4), cf * CFrame.new(0, 1.4, 0), "shrub")
		end
	end
end
return Landscape
