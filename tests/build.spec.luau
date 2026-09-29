--!strict
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local ROOT = "src/ReplicatedStorage/RAC"
local FIXTURE = "tests/fixtures/mini"
local warnings = {}
local loader = require("./lib/loader").new(function(message)
	table.insert(warnings, message)
end)
local load, node = loader.load, loader.node
local function json(name)
	return serde.decode("json", fs.readFile(FIXTURE .. "/" .. name .. ".json"))
end
local data = { site = json("site"), levels = { json("level1"), json("level2") } }
local converted = process.exec("python", { "tools/json2luau.py", FIXTURE, "tests/fixtures/generated" })
assert(converted.ok, converted.stderr)
local Blueprint = load(ROOT .. "/Build/Blueprint")
local generated = Blueprint.load(node("tests/fixtures/generated"))
assert(generated.levels[2].elevation == 14 and generated.site.footprint[3][1] == 80, "Generated data failed roundtrip")
local Geometry = load(ROOT .. "/Build/Geometry")
local function area(rects)
	local sum = 0
	for _, r in rects do
		sum += r.w * r.d
	end
	return sum
end
assert(
	area(Geometry.rectangles({ { 0, 0 }, { 6, 0 }, { 6, 2 }, { 2, 2 }, { 2, 6 }, { 0, 6 } })) == 20,
	"L decomposition"
)
assert(
	area(Geometry.rectangles({ { 0, 0 }, { 6, 0 }, { 6, 6 }, { 4, 6 }, { 4, 2 }, { 2, 2 }, { 2, 6 }, { 0, 6 } })) == 28,
	"U decomposition"
)
assert(
	area(
		Geometry.rectangles(
			{ { 0, 0 }, { 10, 0 }, { 10, 10 }, { 0, 10 } },
			{ { { 2, 2 }, { 8, 2 }, { 8, 8 }, { 2, 8 } } }
		)
	) == 64,
	"Hole subtraction"
)
local Build = load(ROOT .. "/Build/Build")
local parent = roblox.Instance.new("Folder")
local keep = roblox.Instance.new("Folder")
keep.Name = "Keep"
keep.Parent = parent
local stats = Build.build(parent, generated)
local model = parent:FindFirstChild("RAC")
assert(model, "No RAC model")
local partCount = 0
for _, p in model:GetDescendants() do
	if p:IsA("BasePart") then
		partCount += 1
		assert(p.Anchored and p.Size.X > 0 and p.Size.Y > 0 and p.Size.Z > 0, `Invalid part {p:GetFullName()} {p.Size}`)
		if p.Name == "Glass" then
			assert(math.abs(p.Transparency - 0.6) < 0.0001 and p.Material == roblox.Enum.Material.Glass)
		end
	end
end
assert(stats.parts == partCount and partCount > 100 and partCount < 25000, "Part statistics mismatch")
local sum = 0
for _, count in stats.byCategory do
	sum += count
end
assert(sum == partCount, "Category statistics mismatch")
local function overlap(a0, a1, b0, b1)
	return math.min(a1, b1) - math.max(a0, b0) > 0.0001
end
local levels = model:FindFirstChild("Levels")
for _, level in data.levels do
	local root = levels:FindFirstChild(tostring(level.level))
	for _, wall in level.walls do
		local group = root.Walls:FindFirstChild(wall.id)
		local cf, length = Geometry.frame(wall.a, wall.b, level.elevation)
		local actualArea = 0
		for _, part in group:GetChildren() do
			if not part:IsA("BasePart") then
				continue
			end
			local pos = cf:PointToObjectSpace(part.CFrame.Position)
			actualArea += part.Size.X * part.Size.Y
			for _, opening in wall.openings do
				assert(
					not (
							overlap(
								pos.X - part.Size.X / 2,
								pos.X + part.Size.X / 2,
								opening.offset,
								opening.offset + opening.width
							)
							and overlap(pos.Y - part.Size.Y / 2, pos.Y + part.Size.Y / 2, opening.sill, opening.head)
						),
					`Wall intersects opening: {wall.id}`
				)
			end
		end
		local Layout = load(ROOT .. "/Build/WallLayout")
		local expectedArea = area(Layout.rectangles(level, table.find(level.walls, wall), data))
		assert(math.abs(actualArea - expectedArea) < 0.01, `Missing wall material around openings: {wall.id}`)
	end
	for _, room in level.rooms do
		if room.type == "void" then
			continue
		end
		local floor = root.Floors:FindFirstChild(room.id)
		assert(floor and #floor:GetChildren() > 0, `Missing floor for {room.id}`)
	end
	local floorArea = 0
	for _, floor in root.Floors:GetDescendants() do
		if not floor:IsA("BasePart") then
			continue
		end
		floorArea += floor.Size.X * floor.Size.Z
		assert(
			math.abs(floor.CFrame.Position.Y + floor.Size.Y / 2 - level.elevation) < 0.001,
			"Finished floor elevation"
		)
		for _, void in level.voids do
			for _, r in Geometry.rectangles(void.polygon) do
				assert(
					not (
							overlap(
								floor.CFrame.Position.X - floor.Size.X / 2,
								floor.CFrame.Position.X + floor.Size.X / 2,
								r.x,
								r.x + r.w
							)
							and overlap(
								floor.CFrame.Position.Z - floor.Size.Z / 2,
								floor.CFrame.Position.Z + floor.Size.Z / 2,
								r.z,
								r.z + r.d
							)
						),
					`Floor covers {void.id}`
				)
			end
		end
	end
	local holes = {}
	for _, void in level.voids do
		table.insert(holes, void.polygon)
	end
	assert(
		math.abs(floorArea - area(Geometry.rectangles(data.site.footprint, holes))) < 0.01,
		"Footprint coverage has gaps or overlaps"
	)
end
local stair = levels["1"].Stairs.stair_one
assert(stair:GetAttribute("FromElevation") == 0 and stair:GetAttribute("ToElevation") == 14)
for index = 1, 24 do
	local tread = stair:FindFirstChild(`Tread_{index}`)
	assert(math.abs(tread.CFrame.Position.Y + tread.Size.Y / 2 - index * 14 / 24) < 0.00001, "Stair tread elevation")
end
-- Exterior skins must preserve the corresponding north-wall window as well.
local facade = model.Site.Facade.Facade_6
local skinArea = 0
for _, part in facade:GetDescendants() do
	if part:IsA("BasePart") then
		skinArea += part.Size.X * part.Size.Y
		assert(not part.CanCollide, "Facade detail collision")
		local p = part.CFrame.Position
		assert(
			not (
					overlap(p.X - part.Size.X / 2, p.X + part.Size.X / 2, 4, 12)
					and overlap(p.Y - part.Size.Y / 2, p.Y + part.Size.Y / 2, 3, 8)
				),
			"Facade seals window"
		)
	end
end
assert(math.abs(skinArea - 200) < 0.001, "Facade aperture area")
local glassCount, mullionCount = 0, 0
for _, part in levels["1"].Walls.north.Opening_1:GetChildren() do
	if part.Name == "Glass" then
		glassCount += 1
	end
	if part.Name == "Mullion" then
		mullionCount += 1
	end
end
assert(glassCount == 2 and mullionCount == 3, "Window must have center mullion")
assert(levels["1"].Floors.support_l:GetChildren()[1].Material == roblox.Enum.Material.Rubber)
local top = stair.Tread_24.CFrame.Position
assert(math.abs(top.Z - 30.5) < 0.001, `Stair direction/landing: {top}`)
-- Exercise all cardinal stair orientations; a height-only test misses reversed runs.
local Stairs = load(ROOT .. "/Build/Stairs")
for _, direction in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
	local alongX = direction[1] ~= 0
	local width, depth = if alongX then 24 else 6, if alongX then 6 else 24
	local spec = table.clone(data.levels[1].stairs[1])
	spec.polygon = { { 0, 0 }, { width, 0 }, { width, depth }, { 0, depth } }
	spec.direction = direction
	local level = table.clone(data.levels[1])
	level.stairs = { spec }
	local group = roblox.Instance.new("Folder")
	Stairs.build(group, level, data)
	local tread = group.stair_one.Tread_24
	local actual = tread.CFrame.Position
	local expectedX = if alongX then (if direction[1] > 0 then 23.5 else 0.5) else 3
	local expectedZ = if alongX then 3 else (if direction[2] > 0 then 23.5 else 0.5)
	assert(
		math.abs(actual.X - expectedX) < 0.001 and math.abs(actual.Z - expectedZ) < 0.001,
		"Cardinal stair orientation"
	)
	group:Destroy()
end
local registry = load(ROOT .. "/Build/PropRegistry")
local missing = registry.build("not_a_schema_kind", roblox.CFrame.new(), nil)
assert(missing.Name == "MISSING_not_a_schema_kind" and #warnings > 0)
assert(missing:GetChildren()[1].Size == roblox.Vector3.new(2, 2, 2))
local second = Build.build(parent, generated)
assert(
	second.parts == stats.parts and #parent:GetChildren() == 2 and parent:FindFirstChild("Keep") == keep,
	"Build not idempotent"
)
-- The preview path is the explicit deliverable requested for this test.
fs.writeDir("places")
fs.writeFile("places/build_preview.rbxm", roblox.serializeModel({ parent:FindFirstChild("RAC") }))
print(`PASS build: {stats.parts} parts; openings, floors, voids, stairs, generated data, placeholders, idempotence`)
print(`Missing-prop warnings captured: {#warnings}; preview: places/build_preview.rbxm`)

-- Run the production checker on the entire building, including installed doors.
-- Only the independent room prop library is excluded from this builder regression.
local buildingOnly = parent:FindFirstChild("RAC"):Clone()
buildingOnly.Props:Destroy()
local qaPath = "tests/fixtures/build_geometry.rbxm"
fs.writeFile(qaPath, roblox.serializeModel({ buildingOnly }))
local qa = process.exec("lune", { "run", "tools/check_geometry.luau", qaPath, FIXTURE })
print(qa.stdout)
assert(qa.ok, "Building geometry regression: " .. qa.stdout .. qa.stderr)
buildingOnly:Destroy()

-- Stronger than the checker: structural walls and cladding may not share volume,
-- including same-material corner joints and cladding (which is not a wall).
local Vector3 = roblox.Vector3
local boxes = {}
for _, part in parent.RAC:GetDescendants() do
	if part:IsA("BasePart") and (part.Name == "WallSegment" or part.Name == "CladdingPanel") then
		local c, size = part.CFrame, part.Size
		local half = (
			Vector3.new(math.abs(c.RightVector.X), math.abs(c.RightVector.Y), math.abs(c.RightVector.Z)) * size.X
			+ Vector3.new(math.abs(c.UpVector.X), math.abs(c.UpVector.Y), math.abs(c.UpVector.Z)) * size.Y
			+ Vector3.new(math.abs(c.LookVector.X), math.abs(c.LookVector.Y), math.abs(c.LookVector.Z)) * size.Z
		) / 2
		table.insert(boxes, { part = part, low = c.Position - half, high = c.Position + half })
	end
end
for i, a in boxes do
	for j = i + 1, #boxes do
		local b = boxes[j]
		local delta = Vector3.new(
			math.min(a.high.X, b.high.X) - math.max(a.low.X, b.low.X),
			math.min(a.high.Y, b.high.Y) - math.max(a.low.Y, b.low.Y),
			math.min(a.high.Z, b.high.Z) - math.max(a.low.Z, b.low.Z)
		)
		assert(
			math.min(delta.X, delta.Y, delta.Z) < 0.001,
			`Construction volumes overlap: {a.part:GetFullName()} / {b.part:GetFullName()}`
		)
	end
end
local function wallTopAt(x)
	local top = 0
	for _, part in parent.RAC.Levels["1"].Walls.north:GetChildren() do
		if
			part:IsA("BasePart")
			and x > part.CFrame.Position.X - part.Size.X / 2
			and x < part.CFrame.Position.X + part.Size.X / 2
		then
			top = math.max(top, part.CFrame.Position.Y + part.Size.Y / 2)
		end
	end
	return top
end
assert(math.abs(wallTopAt(20) - 13.5) < 0.001, "Lower wall must stop at slab soffit")
assert(math.abs(wallTopAt(70) - 26) < 0.001, "Wall under gym void must retain full height")
print("PASS construction volumes, slab soffit, and full-height void wall")
