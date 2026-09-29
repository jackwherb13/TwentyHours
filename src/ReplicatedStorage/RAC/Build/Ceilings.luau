--!strict
local Blueprint = require(script.Parent.Blueprint)
local Geometry = require(script.Parent.Geometry)
local Parts = require(script.Parent.Parts)
local Ceilings = {}
function Ceilings.build(parent: Instance, level: Blueprint.Level)
	for _, room in level.rooms do
		local kind = room.ceilingType
		if kind == "none" or room.type == "void" then
			continue
		end
		local group = Geometry.folder(parent, room.id)
		local y = level.elevation + room.ceilingHeight
		assert(
			kind == "act_2x2" or kind == "act_2x4" or kind == "gypsum" or kind == "open_joist",
			`Unknown ceiling type {kind}`
		)
		for _, r in Geometry.rectangles(room.polygon) do
			if kind == "open_joist" then
				Parts.box(
					group,
					"Deck",
					Vector3.new(r.w, 0.2, r.d),
					CFrame.new(r.x + r.w / 2, y + 1.1, r.z + r.d / 2),
					"metal_panel",
					false
				)
				for x = math.ceil(r.x / 6) * 6, r.x + r.w - 0.001, 6 do
					for _, h in { 0.05, 0.95 } do
						Parts.box(
							group,
							"JoistChord",
							Vector3.new(0.2, 0.1, r.d),
							CFrame.new(x, y + h, r.z + r.d / 2),
							"steel",
							false
						)
					end
					Parts.box(
						group,
						"JoistWeb",
						Vector3.new(0.08, 0.8, r.d),
						CFrame.new(x, y + 0.5, r.z + r.d / 2),
						"steel",
						false
					)
				end
			else
				Parts.box(
					group,
					"Ceiling",
					Vector3.new(r.w, 0.15, r.d),
					CFrame.new(r.x + r.w / 2, y + 0.075, r.z + r.d / 2),
					if kind == "gypsum" then "gypsum" else "acoustic",
					false
				)
				if kind == "gypsum" then
					continue
				end
				local spacingZ = if kind == "act_2x4" then 4 else 2
				for x = math.ceil(r.x / 2) * 2, r.x + r.w, 2 do
					Parts.box(
						group,
						"TBar",
						Vector3.new(0.06, 0.06, r.d),
						CFrame.new(x, y - 0.03, r.z + r.d / 2),
						"metal_panel",
						false
					)
				end
				for z = math.ceil(r.z / spacingZ) * spacingZ, r.z + r.d, spacingZ do
					Parts.box(
						group,
						"TBar",
						Vector3.new(r.w, 0.06, 0.06),
						CFrame.new(r.x + r.w / 2, y - 0.03, z),
						"metal_panel",
						false
					)
				end
			end
		end
	end
end
return Ceilings
