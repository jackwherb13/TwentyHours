--!strict
local P = require(script.Parent.Primitives)
local H = require(script.Parent.Heightfield)
local G = require(script.Parent.Parent.Build.Geometry)
local Landscape = {}

-- Horizontal disc. Cylinder axis is X; a quarter-turn about Z stands it up. Thickness is vertical, not the tree height.
local function disc(parent: Instance, center: Vector3, diameter: number, thickness: number, finish: string)
	local part = P.box(
		parent,
		"Crown",
		Vector3.new(math.max(0.8, thickness), math.max(1.5, diameter), math.max(1.5, diameter)),
		CFrame.new(center) * CFrame.Angles(0, 0, math.pi / 2),
		finish
	)
	part.Shape = Enum.PartType.Cylinder
end

local function tree(parent: Instance, item: any, index: number)
	local p, height, radius = item.at, item.height, item.radius
	local y = H.height(p[1], p[2])
	local model = Instance.new("Model")
	model.Name = `Tree_{index}`
	local pine = item.species == "pine"
	local trunkH = height * (if pine then 0.42 else 0.36)
	local trunkR = math.clamp(0.22 + height * 0.009, 0.35, 1.25)
	P.pole(model, "Trunk", Vector3.new(p[1], y, p[2]), trunkH, trunkR, "bark", true)
	local crownH = math.max(4, height - trunkH * 0.82)
	local base = y + trunkH * 0.9
	if pine then
		-- Overlapping discs, each smaller than the one below, so the silhouette is a cone rather than shelves.
		local scales = { 1, 0.9, 0.78, 0.64, 0.5, 0.36, 0.22, 0.1 }
		for i, scale in scales do
			local t = (i - 0.4) / #scales
			disc(model, Vector3.new(p[1], base + t * crownH, p[2]), radius * 2 * scale, crownH / #scales * 2.8, "pine")
		end
	else
		-- Thin overlapping discs. Thick ones read as stacked plates when the crown is close.
		local layers = {
			{ 0.1, 0.5, 0.2 },
			{ 0.24, 0.78, 0.22 },
			{ 0.38, 0.96, 0.22 },
			{ 0.5, 1, 0.2 },
			{ 0.62, 0.9, 0.2 },
			{ 0.74, 0.7, 0.18 },
			{ 0.86, 0.46, 0.16 },
			{ 0.95, 0.24, 0.14 },
		}
		for _, layer in layers do
			disc(
				model,
				Vector3.new(p[1], base + layer[1] * crownH, p[2]),
				radius * 2 * layer[2],
				crownH * layer[3],
				"leaf"
			)
		end
	end
	model.Parent = parent
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
			P.pole(parent, "LightPole", Vector3.new(x, base, z), y + 18 - base, 0.18, "dark", true)
			P.box(parent, "LightHead", Vector3.new(1.8, 0.3, 0.8), cf * CFrame.new(0.6, 18, 0), "dark")
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
			P.box(parent, "Hedge", Vector3.new(12.5, 2.4, 3.4), cf * CFrame.new(0, 1.4, 0), "leaf")
		end
	end
end
return Landscape
