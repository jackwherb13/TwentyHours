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
			"mullion_aluminum",
			false
		)
	end
	for y = 0, ny do
		Parts.box(
			parent,
			"Transom",
			Vector3.new(width, TRIM, 0.25),
			cf * CFrame.new(width / 2, y * height / ny, 0),
			"mullion_aluminum",
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
	local postCount = math.max(2, math.ceil(length / 3))
	local span = math.max(length - 0.4, 0.5)
	local x0 = (length - span) / 2
	for i = 0, postCount do
		local x = x0 + span * i / postCount
		Parts.box(group, "RailPost", Vector3.new(0.16, 3.42, 0.16), cf * CFrame.new(x, 1.71, 0), "stainless", true)
	end
	for _, y in { 0.55, 1.25, 1.95, 2.65 } do
		Parts.box(group, "RailBar", Vector3.new(span, 0.12, 0.1), cf * CFrame.new(length / 2, y, 0), "stainless", true)
	end
	Parts.box(
		group,
		"RailCap",
		Vector3.new(span, 0.22, 0.32),
		cf * CFrame.new(length / 2, 3.35, 0),
		"wood_cap_rail",
		true
	)
end

local function doorNotice(parent: Instance, doorCF: CFrame, opening: any, thickness: number)
	local text = opening.label
	local code = opening.keypadCode
	local shown = if type(text) == "string" then text else ""
	if shown == "BASKETBALL - OFF LIMITS" then
		shown = "BASKETBALL — OFF LIMITS"
	end
	if type(code) == "string" and code ~= "" then
		shown = if shown ~= "" then shown .. "\n" .. code else code
	end
	if shown == "" then
		return
	end
	local width = math.clamp(math.max(opening.width + 1.5, 9), 4, 12)
	local height = if string.find(shown, "\n", 1, true) then 1.6 else 1.15
	local y = opening.head + 0.12 + height / 2
	for _, side in { -1, 1 } do
		local plate = Parts.box(
			parent,
			"DoorSign",
			Vector3.new(width, height, 0.04),
			doorCF * CFrame.new(0, y, side * (thickness / 2 + 0.06)),
			"sign_paint",
			false
		)
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Sign"
		gui.Face = if side < 0 then Enum.NormalId.Front else Enum.NormalId.Back
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 42
		gui.LightInfluence = 0.15
		gui.Parent = plate
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Text = shown
		label.TextColor3 = Color3.fromRGB(255, 204, 0)
		label.TextScaled = true
		label.TextWrapped = true
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Parent = gui
	end
end

local function onGuard(level: Blueprint.Level, wall: Blueprint.Wall): boolean
	local guards = (level :: any).guards
	if typeof(guards) ~= "table" then
		return false
	end
	local ax, az = wall.a[1], wall.a[2]
	local bx, bz = wall.b[1], wall.b[2]
	local horizontal = math.abs(az - bz) < 0.05
	local vertical = math.abs(ax - bx) < 0.05
	if not horizontal and not vertical then
		return false
	end
	for _, guard in guards do
		local ga = guard.a
		local gb = guard.b
		if typeof(ga) ~= "table" or typeof(gb) ~= "table" then
			continue
		end
		if horizontal and math.abs(ga[2] - gb[2]) < 0.05 and math.abs(az - ga[2]) < 0.08 then
			local overlap = math.min(math.max(ax, bx), math.max(ga[1], gb[1]))
				- math.max(math.min(ax, bx), math.min(ga[1], gb[1]))
			if overlap > math.abs(bx - ax) * 0.75 and overlap > 1 then
				return true
			end
		elseif vertical and math.abs(ga[1] - gb[1]) < 0.05 and math.abs(ax - ga[1]) < 0.08 then
			local overlap = math.min(math.max(az, bz), math.max(ga[2], gb[2]))
				- math.max(math.min(az, bz), math.min(ga[2], gb[2]))
			if overlap > math.abs(bz - az) * 0.75 and overlap > 1 then
				return true
			end
		end
	end
	return false
end

-- Interior brick is only the locker-corridor accent/portals (IMG_0339, 0340, 0372, 0373).
-- Envelope walls stay brick on the exterior skin (Facade); the body uses the room finish.
local function lockerAccent(x: number, z: number): boolean
	return x >= -250 and x <= -190 and z >= -150 and z <= -95
end

local function interiorFinish(level: Blueprint.Level, wall: Blueprint.Wall): string
	if wall.material == "glass" or wall.material == "metal_panel" or wall.material == "precast" then
		return wall.material
	end
	local mx = (wall.a[1] + wall.b[1]) / 2
	local mz = (wall.a[2] + wall.b[2]) / 2
	if wall.material == "brick" and lockerAccent(mx, mz) then
		return "brick"
	end
	local dx = wall.b[1] - wall.a[1]
	local dz = wall.b[2] - wall.a[2]
	local length = math.sqrt(dx * dx + dz * dz)
	if length < 0.01 then
		if wall.exterior and wall.material == "brick" then
			return "brick"
		end
		if wall.exterior then
			return "painted_cmu"
		end
		if wall.material == "brick" then
			return "painted_cmu"
		end
		return wall.material
	end
	local nx, nz = -dz / length, dx / length
	local function rank(finish: string): number
		if finish == "painted_cmu" or finish == "ceramic_tile" then
			return 3
		end
		if finish == "gypsum" then
			return 2
		end
		return 1
	end
	local chosen: string? = nil
	local chosenRank = 0
	local entryGypsum = false
	for _, sign in { -1, 1 } do
		local x = mx + nx * sign * (wall.thickness / 2 + 0.8)
		local z = mz + nz * sign * (wall.thickness / 2 + 0.8)
		for _, room in level.rooms do
			local finish = room.wallFinish
			if finish and finish ~= "" and Geometry.contains(room.polygon, x, z) then
				local r = rank(finish)
				if r >= chosenRank then
					chosen = finish
					chosenRank = r
				end
				if
					finish == "gypsum"
					and not wall.exterior
					and (room.id == "lobby" or room.id == "south_vestibule" or room.id == "corridor_south_link")
				then
					entryGypsum = true
				end
			end
		end
	end
	-- The stair well shares a wall with the lobby. CMU bond reads as interior brick
	-- from the entry. Those faces are gypsum; the envelope stays brick.
	if entryGypsum then
		return "gypsum"
	end
	if chosen and chosen ~= "brick" then
		return chosen
	end
	if wall.exterior and wall.material == "brick" and chosen == nil then
		return "brick"
	end
	if wall.material == "brick" or wall.exterior then
		return "painted_cmu"
	end
	return wall.material
end

function Walls.build(parent: Instance, level: Blueprint.Level, data: any)
	for wallIndex, wall in level.walls do
		local group = Geometry.folder(parent, wall.id)
		local cf = Geometry.frame(wall.a, wall.b, level.elevation)
		local dx = wall.b[1] - wall.a[1]
		local dz = wall.b[2] - wall.a[2]
		local length = math.sqrt(dx * dx + dz * dz)
		local rail = (wall.height <= 4 and wall.material == "glass" and #wall.openings == 0 and length > 1)
			or (onGuard(level, wall) and #wall.openings == 0 and length > 1)
		if rail then
			buildHorizontalRail(group, cf, length)
			continue
		end
		local finish = interiorFinish(level, wall)
		for _, r in Layout.rectangles(level, wallIndex, data) do
			Parts.box(
				group,
				"WallSegment",
				Vector3.new(r.w, r.d, wall.thickness),
				cf * CFrame.new(r.x + r.w / 2, r.z + r.d / 2, 0),
				finish
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
				doorNotice(openingGroup, doorCF, o, wall.thickness)
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
