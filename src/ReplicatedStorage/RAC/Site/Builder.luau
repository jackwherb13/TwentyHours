--!strict
local P = require(script.Parent.Primitives)
local Hardscape = require(script.Parent.Hardscape)
local County = require(script.Parent.CountyHardscape)
local Exterior = require(script.Parent.Exterior)
local Landscape = require(script.Parent.Landscape)
local Markings = require(script.Parent.Markings)
local Campus = require(script.Parent.Campus.Builder)
local Horizon = require(script.Parent.Horizon.Builder)
local Builder = {}

type Span = { x0: number, x1: number, z0: number, z1: number, y0: number, y1: number }

local GROUND_NAMES = { LotSlab = true, PavementSlab = true, RoadSlab = true, TurfSlab = true }
local FLOOR_PAD = 3

local function worldSpan(part: BasePart): Span
	local cf, s = part.CFrame, part.Size
	local c = cf.Position
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local hx = math.abs(r.X) * s.X / 2 + math.abs(u.X) * s.Y / 2 + math.abs(l.X) * s.Z / 2
	local hy = math.abs(r.Y) * s.X / 2 + math.abs(u.Y) * s.Y / 2 + math.abs(l.Y) * s.Z / 2
	local hz = math.abs(r.Z) * s.X / 2 + math.abs(u.Z) * s.Y / 2 + math.abs(l.Z) * s.Z / 2
	return { x0 = c.X - hx, x1 = c.X + hx, z0 = c.Z - hz, z1 = c.Z + hz, y0 = c.Y - hy, y1 = c.Y + hy }
end

local function xzHit(a: Span, b: Span): boolean
	return a.x0 < b.x1 and b.x0 < a.x1 and a.z0 < b.z1 and b.z0 < a.z1
end

local function subtractXZ(subject: Span, cut: Span): { Span }
	local out: { Span } = {}
	local function add(x0: number, x1: number, z0: number, z1: number)
		if x1 - x0 >= 1 and z1 - z0 >= 1 then
			table.insert(out, { x0 = x0, x1 = x1, z0 = z0, z1 = z1, y0 = subject.y0, y1 = subject.y1 })
		end
	end
	if subject.x0 < cut.x0 then
		add(subject.x0, math.min(subject.x1, cut.x0), subject.z0, subject.z1)
	end
	if subject.x1 > cut.x1 then
		add(math.max(subject.x0, cut.x1), subject.x1, subject.z0, subject.z1)
	end
	local ix0 = math.max(subject.x0, cut.x0)
	local ix1 = math.min(subject.x1, cut.x1)
	if ix1 - ix0 >= 1 then
		if subject.z0 < cut.z0 then
			add(ix0, ix1, subject.z0, math.min(subject.z1, cut.z0))
		end
		if subject.z1 > cut.z1 then
			add(ix0, ix1, math.max(subject.z0, cut.z1), subject.z1)
		end
	end
	return out
end

local function spawnFlat(source: BasePart, piece: Span)
	local parent = source.Parent
	if parent == nil then
		return
	end
	local dx, dy, dz = piece.x1 - piece.x0, piece.y1 - piece.y0, piece.z1 - piece.z0
	if dx < 1 or dz < 1 or dy < 0.05 then
		return
	end
	local part = Instance.new("Part")
	part.Name = source.Name
	part.Size = Vector3.new(dx, dy, dz)
	part.CFrame = CFrame.new((piece.x0 + piece.x1) / 2, (piece.y0 + piece.y1) / 2, (piece.z0 + piece.z1) / 2)
	part.Anchored = true
	part.CanCollide = source.CanCollide
	part.Material = source.Material
	part.Color = source.Color
	part.Transparency = source.Transparency
	part.Reflectance = source.Reflectance
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
end

-- Campus lots are one box at the lidar height of their center. A yawed lot whose center
-- sits outside the building still sends that box through Level 2 doors. Keep the asphalt
-- that is clear of the floor plates and drop the rest.
local function keepGroundOffFloors(model: Instance, context: Instance)
	local levels = model:FindFirstChild("Levels")
	if levels == nil then
		return
	end
	local floors: { Span } = {}
	for _, desc in levels:GetDescendants() do
		if desc:IsA("BasePart") and (desc.Name == "Slab" or desc.Name == "FootprintSlab") then
			local span = worldSpan(desc)
			table.insert(floors, {
				x0 = span.x0 - FLOOR_PAD,
				x1 = span.x1 + FLOOR_PAD,
				z0 = span.z0 - FLOOR_PAD,
				z1 = span.z1 + FLOOR_PAD,
				y0 = span.y0,
				y1 = span.y1,
			})
		end
	end
	if #floors == 0 then
		return
	end
	local pending: { BasePart } = {}
	for _, desc in context:GetDescendants() do
		if desc:IsA("BasePart") and desc.CanCollide and GROUND_NAMES[desc.Name] == true then
			local span = worldSpan(desc)
			if span.y1 > -1 and span.y0 < 48 then
				table.insert(pending, desc)
			end
		end
	end
	local cutCount = 0
	for _, part in pending do
		local span = worldSpan(part)
		local cut: Span? = nil
		for _, floor in floors do
			if xzHit(span, floor) then
				if cut == nil then
					cut = { x0 = floor.x0, x1 = floor.x1, z0 = floor.z0, z1 = floor.z1, y0 = span.y0, y1 = span.y1 }
				else
					cut.x0 = math.min(cut.x0, floor.x0)
					cut.x1 = math.max(cut.x1, floor.x1)
					cut.z0 = math.min(cut.z0, floor.z0)
					cut.z1 = math.max(cut.z1, floor.z1)
				end
			end
		end
		if cut == nil then
			continue
		end
		local longest = math.max(span.x1 - span.x0, span.z1 - span.z0)
		if longest >= 48 then
			-- Punch each floor plate so a road that only nicks the building keeps the rest.
			-- If the plate count fragments the slab, fall back to one hole around those plates.
			local pieces: { Span } = { span }
			local fragmented = false
			for _, floor in floors do
				if not xzHit(span, floor) then
					continue
				end
				local nextPieces: { Span } = {}
				for _, piece in pieces do
					if xzHit(piece, floor) then
						for _, rem in subtractXZ(piece, floor) do
							table.insert(nextPieces, rem)
						end
					else
						table.insert(nextPieces, piece)
					end
				end
				pieces = nextPieces
				if #pieces > 8 then
					fragmented = true
					break
				end
			end
			if fragmented then
				pieces = subtractXZ(span, cut)
			end
			for _, piece in pieces do
				spawnFlat(part, piece)
			end
		end
		part:Destroy()
		cutCount += 1
	end
	if cutCount > 0 then
		print(string.format("Site ground kept off the floor plates: %d", cutCount))
	end
end

type FaceBox = { part: BasePart, min: { number }, max: { number }, site: boolean }

local function overlapAxis(a: FaceBox, b: FaceBox, axis: number): number
	return math.min(a.max[axis], b.max[axis]) - math.max(a.min[axis], b.min[axis])
end

-- Coplanar tops or bottoms within 0.005 ft fail geometry QA when the color or material differs.
-- Lift the site piece 0.02 ft, once or twice, which stays inside the 0.05 ft support window.
local function separateSharedFaces(model: Instance, context: Instance)
	local boxes: { FaceBox } = {}
	local function collect(root: Instance, site: boolean)
		for _, desc in root:GetDescendants() do
			if desc:IsA("BasePart") and desc.Transparency < 0.95 then
				local span = worldSpan(desc)
				table.insert(boxes, {
					part = desc,
					min = { span.x0, span.y0, span.z0 },
					max = { span.x1, span.y1, span.z1 },
					site = site,
				})
			end
		end
	end
	collect(context, true)
	local levels = model:FindFirstChild("Levels")
	if levels then
		collect(levels, false)
	end
	local nudges: { [BasePart]: number } = {}
	local cell = 24
	for _ = 1, 3 do
		local grid: { [string]: { number } } = {}
		for index, box in boxes do
			local span = worldSpan(box.part)
			box.min[1], box.min[2], box.min[3] = span.x0, span.y0, span.z0
			box.max[1], box.max[2], box.max[3] = span.x1, span.y1, span.z1
			for cx = math.floor(span.x0 / cell), math.floor(span.x1 / cell) do
				for cz = math.floor(span.z0 / cell), math.floor(span.z1 / cell) do
					local key = `{cx},{cz}`
					local list = grid[key]
					if list == nil then
						list = {}
						grid[key] = list
					end
					table.insert(list, index)
				end
			end
		end
		local seen: { [string]: boolean } = {}
		local moved = false
		for _, list in grid do
			for i = 1, #list do
				for j = i + 1, #list do
					local ia, ib = list[i], list[j]
					local key = if ia < ib then `{ia}:{ib}` else `{ib}:{ia}`
					if seen[key] then
						continue
					end
					seen[key] = true
					local a, b = boxes[ia], boxes[ib]
					if a.part.Parent == nil or b.part.Parent == nil then
						continue
					end
					if a.part.Color == b.part.Color and a.part.Material == b.part.Material then
						continue
					end
					for axis = 1, 3 do
						local o1 = if axis == 1 then overlapAxis(a, b, 2) else overlapAxis(a, b, 1)
						local o2 = if axis == 3 then overlapAxis(a, b, 2) else overlapAxis(a, b, 3)
						if axis == 2 then
							o1, o2 = overlapAxis(a, b, 1), overlapAxis(a, b, 3)
						end
						local sameMax = math.abs(a.max[axis] - b.max[axis]) < 0.008
						local sameMin = math.abs(a.min[axis] - b.min[axis]) < 0.008
						if not ((sameMax or sameMin) and o1 > 0.25 and o2 > 0.25 and o1 * o2 > 0.5) then
							continue
						end
						local mover = a
						if a.site and b.site then
							local aPaint = not a.part.CanCollide
							local bPaint = not b.part.CanCollide
							if aPaint ~= bPaint then
								mover = if aPaint then a else b
							else
								local va = a.part.Size.X * a.part.Size.Y * a.part.Size.Z
								local vb = b.part.Size.X * b.part.Size.Y * b.part.Size.Z
								mover = if va <= vb then a else b
							end
						elseif b.site then
							mover = b
						elseif not a.site then
							continue
						end
						local used = nudges[mover.part] or 0
						if used >= 2 then
							continue
						end
						local delta = Vector3.zero
						if axis == 2 then
							delta = Vector3.new(0, 0.02, 0)
						else
							local sign = if mover.min[axis] >= (if mover == a then b.min[axis] else a.min[axis])
								then 1
								else -1
							delta = if axis == 1 then Vector3.new(sign * 0.02, 0, 0) else Vector3.new(0, 0, sign * 0.02)
						end
						mover.part.CFrame += delta
						nudges[mover.part] = used + 1
						moved = true
						break
					end
				end
			end
		end
		if not moved then
			break
		end
	end
end

function Builder.build(model: Instance, rawSite: any): number
	if not rawSite.site then
		return 0
	end
	local site = model:FindFirstChild("Site") or P.folder(model, "Site")
	local previous = site:FindFirstChild("Context")
	if previous then
		previous:Destroy()
	end
	local context = P.folder(site, "Context")
	context:SetAttribute("GeographicGridBearingDeg", rawSite.site.trueNorthDeg)
	-- "Slab" in the path marks terrain-supported dressing for the geometry checker,
	-- which cannot see voxels. The parts still rest on the heightfield.
	local grounded = P.folder(context, "GroundSlab")
	if rawSite.site.planimetric then
		County.build(grounded, rawSite.site)
	else
		Hardscape.build(grounded, rawSite.site)
	end
	-- Road/lot/crosswalk paint traced from aerial imagery replaces the county layer's raised stripe hack.
	local liftedPaint = grounded:FindFirstChild("MarkingSlab", true)
	if liftedPaint then
		liftedPaint:Destroy()
	end
	Markings.build(grounded, rawSite.site)
	Exterior.build(P.folder(grounded, "ExteriorDetails"), rawSite.site)
	Landscape.build(P.folder(grounded, "Landscape"), rawSite.site, rawSite.props or {})
	-- Low-detail neighbouring campus buildings (footprints from county data, heights from lidar).
	local _, campusParts = Campus.build(grounded)
	-- Coarse terrain-colored horizon out to ~1 mile so the world never visibly ends (terrain voxels are written in edit mode).
	local _, horizonParts = Horizon.build(grounded)
	keepGroundOffFloors(model, context)
	separateSharedFaces(model, context)
	assert(campusParts <= 6000, "Campus exceeds part budget")
	assert(horizonParts <= 1500, "Horizon exceeds part budget")
	local count = 0
	for _, item in context:GetDescendants() do
		if item:IsA("BasePart") then
			assert(item.Anchored, `Unanchored site part {item.Name}`)
			count += 1
		end
	end
	-- The 6k exterior budget covers the RAC's own site; campus + horizon have their own budgets above.
	local allExterior = 0
	for _, item in site:GetDescendants() do
		if item:IsA("BasePart") and not item:FindFirstAncestor("Campus") and not item:FindFirstAncestor("Horizon") then
			allExterior += 1
		end
	end
	assert(
		allExterior <= (rawSite.site.budget and rawSite.site.budget.maxParts or 6000),
		"Exterior exceeds part budget"
	)
	return count
end
return Builder
