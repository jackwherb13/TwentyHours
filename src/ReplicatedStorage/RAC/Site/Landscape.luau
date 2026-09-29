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

local function leafWedge(parent: Instance, cf: CFrame, size: Vector3, pine: boolean)
	local wedge = Instance.new("WedgePart")
	wedge.Name = "Crown"
	wedge.Size = size
	wedge.CFrame = cf
	wedge.Anchored = true
	wedge.CanCollide = false
	wedge.Material = Enum.Material.SmoothPlastic
	wedge.Color = if pine then Color3.fromRGB(28, 58, 36) else Color3.fromRGB(54, 86, 42)
	wedge.Parent = parent
end

-- Trunk plus layered wedges. Stacked balls read as lollipops.
local function tree(parent: Instance, item: any, index: number)
	local p = item.at
	local scale = 0.85 + ((index * 13) % 5) * 0.08
	local height = math.clamp(item.height * scale, 18, 36)
	local y = H.height(p[1], p[2])
	local pine = item.species == "pine" or (index % 5 == 0)
	local model = P.folder(parent, if pine then "PineCanopy" else "ShadeCanopy")
	local trunkH = if pine then height * 0.55 else height * 0.48
	local trunkW = if pine then 1.15 else 1.55
	local trunk = P.pole(model, "Trunk", Vector3.new(p[1], y, p[2]), trunkH, trunkW / 2, "bark", false)
	trunk.Color = Color3.fromRGB(92, 74, 56)
	local yaw = math.rad((index * 47) % 360)
	-- Tip of a WedgePart is local -Z. Pitch that tip up so the crown is a cone, not a stack of plates.
	local function crown(origin: Vector3, face: number, tilt: number, size: Vector3)
		leafWedge(
			model,
			CFrame.new(origin)
				* CFrame.Angles(0, face, 0)
				* CFrame.Angles(tilt, 0, 0)
				* CFrame.new(0, 0, -size.Z * 0.32),
			size,
			pine
		)
	end
	if pine then
		for layer = 0, 2 do
			local t = layer / 2
			local len = height * (0.42 - 0.2 * t)
			local cy = y + trunkH * 0.28 + t * height * 0.52
			for k = 0, 2 do
				crown(
					Vector3.new(p[1], cy, p[2]),
					yaw + layer * 0.7 + k * math.pi * 2 / 3,
					math.rad(60),
					Vector3.new(len * 0.78, len * 0.22, len)
				)
			end
		end
	else
		local crownR = height * 0.42
		for tier = 0, 1 do
			local len = crownR * (1.2 - 0.38 * tier)
			local cy = y + trunkH * 0.78 + tier * crownR * 0.55
			for k = 0, 4 do
				crown(
					Vector3.new(p[1], cy, p[2]),
					yaw + tier * 0.55 + k * math.pi * 2 / 5,
					math.rad(32 + tier * 10),
					Vector3.new(len * 0.62, len * 0.34, len)
				)
			end
		end
	end
end

function Landscape.build(parent: Instance, site: any, props: any)
	local trees = P.folder(parent, "Trees")
	assert(#site.trees <= 150, "Tree budget exceeded")
	local entrance = site.entrance
	for i, item in site.trees do
		local at = item.at
		local dx, dz = at[1] - entrance.x, at[2] - entrance.z
		-- Keep the south glass, the canopy, and the stair clear. Crowns were growing through the lobby.
		if at[1] > -120 and at[1] < 36 and at[2] > -40 and at[2] < 68 then
			continue
		end
		if dx * dx + dz * dz < 56 * 56 and at[2] > entrance.z - 12 then
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
			P.box(
				parent,
				"LightPole",
				Vector3.new(0.28, y + 16 - base, 0.28),
				CFrame.new(x, (base + y + 16) / 2, z),
				"dark",
				true
			)
			local globe = P.box(parent, "LightGlobe", Vector3.new(1.2, 1.2, 1.2), cf * CFrame.new(0, 16.6, 0), "metal")
			globe.Shape = Enum.PartType.Ball
			globe.Material = Enum.Material.SmoothPlastic
			globe.Color = Color3.fromRGB(255, 236, 200)
			local lamp = Instance.new("PointLight")
			lamp.Brightness = 1.5
			lamp.Range = 48
			lamp.Color = Color3.fromRGB(255, 236, 200)
			lamp.Parent = globe
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
