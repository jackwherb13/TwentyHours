--!strict
local Blueprint = require(script.Parent.Blueprint)
local Geometry = require(script.Parent.Geometry)
local Parts = require(script.Parent.Parts)
local Floors = { THICKNESS = 0.5 }
function Floors.build(parent: Instance, level: Blueprint.Level, site: Blueprint.Site, data: Blueprint.Data?)
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
		local finish = if room.type == "racquetball" then "racquetball_wood" else room.floorMaterial
		local group = Geometry.folder(parent, room.id)
		for _, r in Geometry.rectangles(room.polygon, holes) do
			Parts.box(
				group,
				"Slab",
				Vector3.new(r.w, Floors.THICKNESS, r.d),
				CFrame.new(r.x + r.w / 2, level.elevation - Floors.THICKNESS / 2, r.z + r.d / 2),
				finish
			)
		end
		table.insert(uncovered, room.polygon)
	end
	-- Footprint fill only. Lower-level rooms stay open above so Level 2 does not
	-- deck over the gym, the foyer, or any other Level 1 volume.
	if data ~= nil and level.level > 1 then
		for _, other in data.levels do
			if other.level < level.level then
				for _, room in other.rooms do
					if room.type ~= "void" then
						table.insert(uncovered, room.polygon)
					end
				end
			end
		end
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
