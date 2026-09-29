--!strict
local Blueprint = require(script.Parent.Blueprint)
local Geometry = require(script.Parent.Geometry)
local Parts = require(script.Parent.Parts)
local Floors = { THICKNESS = 0.5 }
function Floors.build(parent: Instance, level: Blueprint.Level, site: Blueprint.Site)
	local holes: { Blueprint.Polygon } = {}
	for _, void in level.voids do
		table.insert(holes, void.polygon)
	end
	for _, room in level.rooms do
		if room.type == "void" then
			table.insert(holes, room.polygon)
		end
	end
	local uncovered = table.clone(holes)
	for _, room in level.rooms do
		if room.type == "void" then
			continue
		end
		local group = Geometry.folder(parent, room.id)
		for _, r in Geometry.rectangles(room.polygon, holes) do
			Parts.box(
				group,
				"Slab",
				Vector3.new(r.w, Floors.THICKNESS, r.d),
				CFrame.new(r.x + r.w / 2, level.elevation - Floors.THICKNESS / 2, r.z + r.d / 2),
				room.floorMaterial
			)
		end
		table.insert(uncovered, room.polygon)
	end
	-- Fill unlabeled circulation/structure within the footprint on every level.
	for _, r in Geometry.rectangles(site.footprint, uncovered) do
		Parts.box(
			parent,
			"FootprintSlab",
			Vector3.new(r.w, Floors.THICKNESS, r.d),
			CFrame.new(r.x + r.w / 2, level.elevation - Floors.THICKNESS / 2, r.z + r.d / 2),
			"sealed_concrete"
		)
	end
end
return Floors
