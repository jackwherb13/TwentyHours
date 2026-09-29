--!strict
local Blueprint = require(script.Parent.Blueprint)
local Geometry = require(script.Parent.Geometry)
local Parts = require(script.Parent.Parts)
local Walls = require(script.Parent.Walls)
local Facade = {}
function Facade.build(parent: Instance, site: Blueprint.Site, levels: { Blueprint.Level }?)
	for index, face in site.facade do
		local group = Geometry.folder(parent, `Facade_{index}`)
		local cf, length = Geometry.frame(face.a, face.b, face.base)
		if face.style == "curtain_wall" then
			Walls.glazing(group, cf, length, face.height, 5)
		elseif face.style == "sunshade_fins" then
			local count = math.max(1, math.ceil(length / 4))
			for i = 0, count do
				Parts.box(
					group,
					"Fin",
					Vector3.new(0.15, face.height, 2),
					cf * CFrame.new(i * length / count, face.height / 2, 0),
					"metal_panel",
					false
				)
			end
		else
			local material = if face.style == "precast_band" then "precast" else face.style
			assert(
				material == "precast" or material == "brick" or material == "metal_panel",
				`Unknown facade {face.style}`
			)
			-- Project matching wall apertures onto the skin so facade panels cannot seal doors/windows.
			local openings: { Blueprint.Opening } = {}
			local backing = 0
			local sourceLevels: { Blueprint.Level } = levels or {}
			for _, level in sourceLevels do
				for _, wall in level.walls do
					local wa = cf:PointToObjectSpace(Vector3.new(wall.a[1], 0, wall.a[2]))
					local wb = cf:PointToObjectSpace(Vector3.new(wall.b[1], 0, wall.b[2]))
					if math.abs(wa.Z - wb.Z) > 0.001 or math.abs(wa.Z) > wall.thickness / 2 + 0.1 then
						continue
					end
					if math.max(wa.X, wb.X) > 0 and math.min(wa.X, wb.X) < length then
						backing = math.max(backing, wall.thickness / 2 + math.abs(wa.Z))
					end
					local wallFrame = Geometry.frame(wall.a, wall.b, level.elevation)
					for _, o in wall.openings do
						local a = cf:PointToObjectSpace(wallFrame:PointToWorldSpace(Vector3.new(o.offset, o.sill, 0)))
						local b = cf:PointToObjectSpace(
							wallFrame:PointToWorldSpace(Vector3.new(o.offset + o.width, o.head, 0))
						)
						local left, right = math.max(0, math.min(a.X, b.X)), math.min(length, math.max(a.X, b.X))
						local sill, head = math.max(0, a.Y), math.min(face.height, b.Y)
						if right > left and head > sill then
							table.insert(
								openings,
								{ type = "opening", offset = left, width = right - left, sill = sill, head = head }
							)
						end
					end
				end
			end
			-- Resolve outside from the footprint, independent of segment winding.
			local middle = cf:PointToWorldSpace(Vector3.new(length / 2, 0, 0.01))
			local sign = if Geometry.contains(site.footprint, middle.X, middle.Z) then -1 else 1
			-- 0.065 ft clear of the wall face. A flush skin shares that face and z-fights.
			local shift = cf:VectorToWorldSpace(Vector3.new(0, 0, sign * (backing + 0.14)))
			local skin: Blueprint.Wall = {
				id = "Skin",
				a = { face.a[1] + shift.X, face.a[2] + shift.Z },
				b = { face.b[1] + shift.X, face.b[2] + shift.Z },
				thickness = 0.15,
				height = face.height,
				material = material,
				exterior = true,
				openings = openings,
			}
			Walls.build(group, {
				level = 0,
				elevation = face.base,
				rooms = {},
				walls = { skin },
				columns = {},
				stairs = {},
				voids = {},
				props = {},
			})
			for _, part in group:GetDescendants() do
				if part:IsA("BasePart") then
					part.CanCollide = false
					part.Name = "CladdingPanel"
				end
			end
		end
	end
end
return Facade
