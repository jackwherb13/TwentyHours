--!strict
local Blueprint = require(script.Parent.Blueprint)
local Geometry = require(script.Parent.Geometry)
local Parts = require(script.Parent.Parts)
local Roofs = {}

-- Open service yard west of the volleyball gym. A roof slab here boxed the dumpsters indoors.
local YARD: { { number } } = {
	{ -236.5, -214 },
	{ -193.5, -214 },
	{ -193.5, -186 },
	{ -236.5, -186 },
}

function Roofs.build(parent: Instance, site: Blueprint.Site)
	for index, roof in site.roofs do
		local group = Geometry.folder(parent, `Roof_{index}`)
		local canopy = roof.type == "canopy"
		assert(canopy or roof.type == "flat", `Unknown roof type {roof.type}`)
		local thickness = if canopy then 0.25 else 0.5
		local overhang = roof.overhang
		assert(overhang >= 0, "Negative roof overhang")
		local holes: { { { number } } }? = if canopy then nil else { YARD }
		for _, r in Geometry.rectangles(roof.polygon, holes) do
			Parts.box(
				group,
				if canopy then "Canopy" else "RoofSlab",
				Vector3.new(r.w + 2 * overhang, thickness, r.d + 2 * overhang),
				CFrame.new(r.x + r.w / 2, roof.height + thickness / 2, r.z + r.d / 2),
				if canopy then "steel" else "sealed_concrete"
			)
		end
		if canopy then
			-- Thick at the glass (minimum Z) and thin at the outer tip. Photos show a dark wedge soffit.
			local x0, x1, z0, z1 = math.huge, -math.huge, math.huge, -math.huge
			for _, point in roof.polygon do
				x0, x1 = math.min(x0, point[1]), math.max(x1, point[1])
				z0, z1 = math.min(z0, point[2]), math.max(z1, point[2])
			end
			local depth, span = z1 - z0, x1 - x0
			-- Keep the end faces off a wall that stops on the canopy's x edge.
			local spanInset = 0.15
			if depth > 1 and span > 1 + 2 * spanInset then
				local wedge = Instance.new("WedgePart")
				wedge.Name = "CanopySoffit"
				wedge.Size = Vector3.new(span - 2 * spanInset, 2.4, depth)
				-- Default wedge is thin toward local -Z. Rotate so the thin edge is the south tip.
				wedge.CFrame = CFrame.new((x0 + x1) / 2, roof.height - 1.22, (z0 + z1) / 2)
					* CFrame.Angles(0, math.pi, 0)
				wedge.Material = Enum.Material.Metal
				wedge.Color = Color3.fromRGB(43, 46, 48)
				wedge.Anchored = true
				wedge.CanCollide = true
				wedge.Parent = group
			end
			continue
		end
		for i, a in roof.polygon do
			local b = roof.polygon[i % #roof.polygon + 1]
			local cf, length = Geometry.frame(a, b, roof.height + thickness)
			Parts.box(group, "Parapet", Vector3.new(length, 2, 0.5), cf * CFrame.new(length / 2, 1, 0), "precast")
		end
	end
end
return Roofs
