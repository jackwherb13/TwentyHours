--!strict
local P = require(script.Parent.Primitives)
local H = require(script.Parent.Heightfield)
local G = require(script.Parent.Parent.Build.Geometry)
local Landscape = {}

-- Generated meshes: trunk plus an irregular crown, not stacked discs or cones.
local DECIDUOUS_MESH = "rbxassetid://110305079240397"
local DECIDUOUS_TEX = "rbxassetid://138916508834826"
local PINE_MESH = "rbxassetid://134575217828136"
local PINE_TEX = "rbxassetid://83047659402289"

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

local function tree(parent: Instance, item: any, index: number)
	local p = item.at
	local scale = 0.85 + ((index * 13) % 5) * 0.08
	local height = math.clamp(item.height * scale, 16, 42)
	local y = H.height(p[1], p[2])
	local pine = item.species == "pine"
	local mesh = if pine then PINE_MESH else DECIDUOUS_MESH
	local tex = if pine then PINE_TEX else DECIDUOUS_TEX
	local authoredH = if pine then 22.45 else 25.85
	local authoredW = if pine then 14 else 18
	local part = Instance.new("MeshPart")
	part.Name = if pine then "Pine" else "ShadeTree"
	local s = height / authoredH
	part.Size = Vector3.new(authoredW * s, height, authoredW * s)
	part.CFrame = CFrame.new(p[1], y + height / 2, p[2]) * CFrame.Angles(0, math.rad((index * 47) % 360), 0)
	part.MeshId = mesh
	part.TextureID = tex
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.new(1, 1, 1)
	part.Anchored = true
	part.CanCollide = false
	part.DoubleSided = true
	part.Parent = parent
end

function Landscape.build(parent: Instance, site: any, props: any)
	local trees = P.folder(parent, "Trees")
	assert(#site.trees <= 150, "Tree budget exceeded")
	local entrance = site.entrance
	for i, item in site.trees do
		local at = item.at
		local dx, dz = at[1] - entrance.x, at[2] - entrance.z
		if dx * dx + dz * dz < 42 * 42 and at[2] > entrance.z - 8 then
			continue
		end
		local pads = site.terrain and site.terrain.padPolygons
		local blocked = false
		if pads then
			local reach = (item.radius or 8) + 2
			for _, polygon in pads do
				if G.contains(polygon, at[1], at[2]) then
					blocked = true
					break
				end
				for k = 0, 7 do
					local a = k * math.pi / 4
					if G.contains(polygon, at[1] + math.cos(a) * reach, at[2] + math.sin(a) * reach) then
						blocked = true
						break
					end
				end
				if blocked then
					break
				end
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
