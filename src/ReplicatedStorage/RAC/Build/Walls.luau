--!strict
local Blueprint = require(script.Parent.Blueprint)
local Geometry = require(script.Parent.Geometry)
local Parts = require(script.Parent.Parts)
local Layout = require(script.Parent.WallLayout)
local PropRegistry = require(script.Parent.PropRegistry)
local Walls = {}
local TRIM = 2 / 12

-- Local X runs along the wall; local Y is height above the level.
function Walls.glazing(parent: Instance, cf: CFrame, width: number, height: number, spacing: number, window: boolean?)
	assert(spacing > 0 and width > 0 and height > 0, "Invalid glazing dimensions")
	local nx = if window then 2 else math.max(1, math.ceil(width / spacing))
	local ny = if window then 1 else math.max(1, math.ceil(height / spacing))
	for x = 0, nx do
		Parts.box(
			parent,
			"Mullion",
			Vector3.new(TRIM, height, 0.25),
			cf * CFrame.new(x * width / nx, height / 2, 0),
			"steel",
			false
		)
	end
	for y = 0, ny do
		Parts.box(
			parent,
			"Transom",
			Vector3.new(width, TRIM, 0.25),
			cf * CFrame.new(width / 2, y * height / ny, 0),
			"steel",
			false
		)
	end
	for x = 1, nx do
		for y = 1, ny do
			Parts.box(
				parent,
				"Glass",
				Vector3.new(width / nx, height / ny, 0.08),
				cf * CFrame.new((x - 0.5) * width / nx, (y - 0.5) * height / ny, 0),
				"glass",
				true
			)
		end
	end
end

local function frame(parent: Instance, cf: CFrame, opening: Blueprint.Opening, depth: number)
	local h = opening.head - opening.sill
	for _, x in { opening.offset + TRIM / 2, opening.offset + opening.width - TRIM / 2 } do
		Parts.box(
			parent,
			"Jamb",
			Vector3.new(TRIM, h - 2 * TRIM, depth),
			cf * CFrame.new(x, opening.sill + h / 2, 0),
			"metal_panel",
			false
		)
	end
	for _, y in { opening.sill + TRIM / 2, opening.head - TRIM / 2 } do
		Parts.box(
			parent,
			if y < opening.sill + h / 2 then "Sill" else "Head",
			Vector3.new(opening.width, TRIM, depth),
			cf * CFrame.new(opening.offset + opening.width / 2, y, 0),
			"metal_panel",
			false
		)
	end
end

-- Horizontal metal rails with a wood cap (IMG_0343, IMG_0369, WEB_entrance_from_level2).
-- Guard walls are the short glass segments the blueprint compiler emits. A solid
-- glass panel is not the balcony rail in the photos.
local function buildHorizontalRail(group: Folder, cf: CFrame, length: number)
	local postCount = math.max(2, math.ceil(length / 4))
	local span = math.max(length - 0.4, 0.5)
	local x0 = (length - span) / 2
	for i = 0, postCount do
		local x = x0 + span * i / postCount
		Parts.box(group, "RailPost", Vector3.new(0.16, 3.42, 0.16), cf * CFrame.new(x, 1.71, 0), "steel", true)
	end
	for _, y in { 0.55, 1.25, 1.95, 2.65 } do
		Parts.box(
			group,
			"RailBar",
			Vector3.new(span, 0.12, 0.1),
			cf * CFrame.new(length / 2, y, 0),
			"metal_panel",
			true
		)
	end
	Parts.box(group, "RailCap", Vector3.new(span, 0.18, 0.28), cf * CFrame.new(length / 2, 3.35, 0), "maple", true)
end

function Walls.build(parent: Instance, level: Blueprint.Level, data: any)
	for wallIndex, wall in level.walls do
		local group = Geometry.folder(parent, wall.id)
		local cf = Geometry.frame(wall.a, wall.b, level.elevation)
		local dx = wall.b[1] - wall.a[1]
		local dz = wall.b[2] - wall.a[2]
		local length = math.sqrt(dx * dx + dz * dz)
		if wall.height <= 4 and wall.material == "glass" and #wall.openings == 0 and length > 1 then
			buildHorizontalRail(group, cf, length)
			continue
		end
		for _, r in Layout.rectangles(level, wallIndex, data) do
			Parts.box(
				group,
				"WallSegment",
				Vector3.new(r.w, r.d, wall.thickness),
				cf * CFrame.new(r.x + r.w / 2, r.z + r.d / 2, 0),
				wall.material
			)
		end
		for index, o in wall.openings do
			local openingGroup = Geometry.folder(group, `Opening_{index}`)
			if o.type == "door" then
				local door = PropRegistry.build(
					if o.leaves == 2 then "door_double" else "door_single",
					cf * CFrame.new(o.offset + o.width / 2, o.sill, 0),
					{
						width = o.width,
						height = o.head - o.sill,
						depth = wall.thickness,
						leaves = o.leaves,
						tag = o.tag,
					}
				)
				-- Fit the library's complete frame inside the measured rough opening.
				-- The prop owns its frame; adding a second casing would overlap it.
				local doorCF = cf * CFrame.new(o.offset + o.width / 2, o.sill, 0)
				local header = door:FindFirstChild("FrameHeader")
				if header and header:IsA("BasePart") then
					local hp = doorCF:PointToObjectSpace(header.CFrame.Position)
					local scale = Vector3.new(
						o.width / header.Size.X,
						(o.head - o.sill) / (hp.Y + header.Size.Y / 2),
						(wall.thickness + 0.15) / header.Size.Z
					)
					for _, part in door:GetDescendants() do
						if part:IsA("BasePart") then
							local localCF = doorCF:ToObjectSpace(part.CFrame)
							local function scaledAxis(v: Vector3): number
								return (v * scale).Magnitude
							end
							part.Size *= Vector3.new(
								scaledAxis(localCF.RightVector),
								scaledAxis(localCF.UpVector),
								scaledAxis(localCF.LookVector)
							)
							part.CFrame = doorCF * CFrame.new(localCF.Position * scale) * localCF.Rotation
						end
					end
				end
				if o.tag then
					door:AddTag(o.tag)
				end
				door.Parent = openingGroup
			elseif o.type == "window" then
				frame(openingGroup, cf, o, wall.thickness + 0.15)
				Walls.glazing(
					openingGroup,
					cf * CFrame.new(o.offset + TRIM, o.sill + TRIM, 0),
					o.width - 2 * TRIM,
					o.head - o.sill - 2 * TRIM,
					math.max(o.width / 2, o.head - o.sill),
					true
				)
			elseif o.type == "curtainwall" then
				Walls.glazing(
					openingGroup,
					cf * CFrame.new(o.offset, o.sill, 0),
					o.width,
					o.head - o.sill,
					o.mullionSpacing or 5
				)
			else
				assert(o.type == "opening", `Unknown opening type {o.type}`)
			end
		end
	end
end
return Walls
