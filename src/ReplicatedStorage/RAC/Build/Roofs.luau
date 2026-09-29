--!strict
local Blueprint = require(script.Parent.Blueprint)
local Geometry = require(script.Parent.Geometry)
local Parts = require(script.Parent.Parts)
local Roofs = {}
function Roofs.build(parent: Instance, site: Blueprint.Site)
	for index, roof in site.roofs do
		local group = Geometry.folder(parent, `Roof_{index}`)
		local canopy = roof.type == "canopy"
		assert(canopy or roof.type == "flat", `Unknown roof type {roof.type}`)
		local thickness = if canopy then 0.25 else 0.5
		local overhang = roof.overhang
		assert(overhang >= 0, "Negative roof overhang")
		for _, r in Geometry.rectangles(roof.polygon) do
			Parts.box(
				group,
				if canopy then "Canopy" else "RoofSlab",
				Vector3.new(r.w + 2 * overhang, thickness, r.d + 2 * overhang),
				CFrame.new(r.x + r.w / 2, roof.height + thickness / 2, r.z + r.d / 2),
				if canopy then "steel" else "sealed_concrete"
			)
		end
		if canopy then
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
