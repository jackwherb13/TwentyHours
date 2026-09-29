-- Performance and walkability QA on a built RAC model.
--   lune run tools/check_perf.luau places/build.rbxm [blueprint dir]
-- Fails (exit 1) when SPEC.md part budgets are exceeded, stair risers > 0.9 ft,
-- unclimbable steps, ramps steeper than ~35 deg, doorways < 3 ft, or floor gaps
-- a default Humanoid can fall through.
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local file = process.args[1] or "places/build.rbxm"
local bpDir = process.args[2] or "blueprint"
local MAX_REPORT = 25

-- docs/SPEC.md (user 2026-09-28)
local BUDGET = {
	whole = 40000,
	shell = 12000,
	props = 20000,
	exterior = 6000,
	campus = 6000,
	horizon = 1500,
}

local MAX_RISER = 0.9
-- Default Humanoid HipHeight is 2; obstacles taller than ~1.5 ft are not walkable.
local MAX_STEP = 1.5
local MAX_RAMP_DEG = 35
local MIN_DOOR = 3.0
local FALL_GAP = 2.0

local issues: { [string]: { string } } = {
	budget = {},
	riser = {},
	step = {},
	ramp = {},
	door = {},
	gap = {},
}

local function add(kind: string, msg: string)
	table.insert(issues[kind], msg)
end

local function json(name: string): any?
	local path = `{bpDir}/{name}.json`
	if not fs.isFile(path) then
		return nil
	end
	return serde.decode("json", fs.readFile(path))
end

local function lower(s: string): string
	return string.lower(s)
end

local function fullPath(inst): string
	local names = {}
	local cur = inst
	while cur do
		table.insert(names, 1, cur.Name)
		cur = cur.Parent
	end
	return table.concat(names, ".")
end

if not fs.isFile(file) then
	print(`SKIP check_perf: missing {file}`)
	process.exit(0)
end

local modelRoots = roblox.deserializeModel(fs.readFile(file))
local rac = modelRoots[1]
for _, r in modelRoots do
	if r.Name == "RAC" then
		rac = r
		break
	end
end

local counts = {
	whole = 0,
	shell = 0,
	props = 0,
	exterior = 0,
	campus = 0,
	horizon = 0,
	lights = 0,
	lightsShadow = 0,
	decals = 0,
	textures = 0,
	unions = 0,
	meshes = 0,
	instances = 0,
}

local function categoryOf(path: string): string
	local p = lower(path)
	if string.find(p, "campus", 1, true) or string.find(p, "horizon", 1, true) then
		if string.find(p, "horizon", 1, true) then
			return "horizon"
		end
		return "campus"
	end
	if string.find(p, ".site.", 1, true) or string.find(p, ".facade", 1, true) or string.find(p, ".roofs", 1, true) then
		return "exterior"
	end
	if string.find(p, ".props.", 1, true) then
		return "props"
	end
	return "shell"
end

local floorParts = {}
local rampParts = {}

for _, d in rac:GetDescendants() do
	counts.instances += 1
	if d:IsA("BasePart") then
		counts.whole += 1
		local cat = categoryOf(fullPath(d))
		counts[cat] = (counts[cat] or 0) + 1
		if d:IsA("MeshPart") then
			counts.meshes += 1
			if d.CollisionFidelity ~= roblox.Enum.CollisionFidelity.Box then
				add("budget", `mesh CollisionFidelity not Box: {fullPath(d)}`)
			end
		end
		if d:IsA("UnionOperation") or d.ClassName == "UnionOperation" then
			counts.unions += 1
		end
		local lp = lower(fullPath(d))
		if string.find(lp, "ramp", 1, true) then
			table.insert(rampParts, d)
		end
		if d.CanCollide then
			local up = math.abs(d.CFrame.UpVector.Y)
			if up > 0.85 and (string.find(lp, "floor", 1, true) or string.find(lp, ".floors.", 1, true)) then
				table.insert(floorParts, d)
			end
			-- Walkable ramps only: name contains "ramp" (prop wedges and terrain
			-- pavement use rotation for shape, not circulation slope).
			if string.find(lp, "ramp", 1, true) and up < 0.85 and up > 0.2 then
				local slope = math.deg(math.acos(math.clamp(up, -1, 1)))
				if slope > MAX_RAMP_DEG + 0.5 then
					add(
						"ramp",
						`{fullPath(d)} slope ~{string.format("%.1f", slope)} deg (upY={string.format("%.2f", up)})`
					)
				end
			end
		end
	elseif d:IsA("SpotLight") or d:IsA("PointLight") or d:IsA("SurfaceLight") then
		counts.lights += 1
		if d.Shadows then
			counts.lightsShadow += 1
		end
	elseif d:IsA("Decal") or d:IsA("Texture") then
		if d:IsA("Decal") then
			counts.decals += 1
		else
			counts.textures += 1
		end
	end
end

if counts.whole > BUDGET.whole then
	add("budget", `whole map parts {counts.whole} > {BUDGET.whole}`)
end
if counts.shell > BUDGET.shell then
	add("budget", `building shell parts {counts.shell} > {BUDGET.shell}`)
end
if counts.props > BUDGET.props then
	add("budget", `props parts {counts.props} > {BUDGET.props}`)
end
if counts.exterior > BUDGET.exterior then
	add("budget", `exterior parts {counts.exterior} > {BUDGET.exterior}`)
end
if counts.campus > BUDGET.campus then
	add("budget", `campus parts {counts.campus} > {BUDGET.campus}`)
end
if counts.horizon > BUDGET.horizon then
	add("budget", `horizon parts {counts.horizon} > {BUDGET.horizon}`)
end

local l1 = json("level1")
local l2 = json("level2")
local levels = {}
if l1 then
	table.insert(levels, l1)
end
if l2 then
	table.insert(levels, l2)
end

for _, level in levels do
	if level.stairs then
		for _, stair in level.stairs do
			local rise = stair.rise or 0
			if rise > MAX_RISER then
				add("riser", `stair {stair.id} rise {rise} ft > {MAX_RISER}`)
			end
			if rise > MAX_STEP then
				add("step", `stair {stair.id} rise {rise} ft exceeds Humanoid walk-up (~{MAX_STEP} ft)`)
			end
			if stair.flights then
				for _, fl in stair.flights do
					local r = fl.rise or rise
					if r > MAX_RISER then
						add("riser", `flight {fl.id or stair.id} rise {r} ft > {MAX_RISER}`)
					end
					if r > MAX_STEP then
						add("step", `flight {fl.id or stair.id} rise {r} ft unclimbable`)
					end
				end
			end
		end
	end
	if level.walls then
		for _, wall in level.walls do
			if wall.openings then
				for _, op in wall.openings do
					if op.type == "door" and (op.width or 0) + 1e-6 < MIN_DOOR then
						add("door", `door on {wall.id} width {op.width} ft < {MIN_DOOR}`)
					end
				end
			end
		end
	end
end

-- Built stair treads: consecutive tread tops should differ by <= MAX_RISER.
local treadsByStair: { [string]: { any } } = {}
for _, d in rac:GetDescendants() do
	if d:IsA("BasePart") and string.find(d.Name, "Tread_", 1, true) == 1 then
		local parent = d.Parent
		local key = if parent then fullPath(parent) else "stair"
		treadsByStair[key] = treadsByStair[key] or {}
		table.insert(treadsByStair[key], d)
	end
end
for key, list in treadsByStair do
	table.sort(list, function(a, b)
		return a.CFrame.Position.Y < b.CFrame.Position.Y
	end)
	for i = 2, #list do
		local dy = (list[i].CFrame.Position.Y + list[i].Size.Y / 2)
			- (list[i - 1].CFrame.Position.Y + list[i - 1].Size.Y / 2)
		if dy > MAX_RISER + 0.02 then
			add("riser", `{key} tread rise {string.format("%.3f", dy)} ft`)
		end
		if dy > MAX_STEP + 0.02 then
			add("step", `{key} tread rise {string.format("%.3f", dy)} ft unclimbable`)
		end
	end
end

for _, p in rampParts do
	local size = p.Size
	local run = math.max(size.X, size.Z)
	local rise = size.Y
	if run > 0.01 then
		local deg = math.deg(math.atan(rise / run))
		if deg > MAX_RAMP_DEG + 0.5 then
			add("ramp", `{fullPath(p)} named ramp atan(Y/run)={string.format("%.1f", deg)} deg`)
		end
	end
end

-- Floor gaps: 4 ft cells covering colliding floor AABBs; empty cells between occupied neighbors.
local function aabb(p)
	local cf, s = p.CFrame, p.Size
	local c = cf.Position
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local hx = math.abs(r.X) * s.X / 2 + math.abs(u.X) * s.Y / 2 + math.abs(l.X) * s.Z / 2
	local hy = math.abs(r.Y) * s.X / 2 + math.abs(u.Y) * s.Y / 2 + math.abs(l.Y) * s.Z / 2
	local hz = math.abs(r.Z) * s.X / 2 + math.abs(u.Z) * s.Y / 2 + math.abs(l.Z) * s.Z / 2
	return { c.X - hx, c.Y - hy, c.Z - hz }, { c.X + hx, c.Y + hy, c.Z + hz }
end

local CELL = FALL_GAP
local occ: { [string]: boolean } = {}
local yBand: { [string]: number } = {}
for _, p in floorParts do
	local mn, mx = aabb(p)
	local y = (mn[2] + mx[2]) / 2
	local yk = tostring(math.floor(y / 8 + 0.5) * 8)
	for cx = math.floor(mn[1] / CELL), math.floor(mx[1] / CELL) do
		for cz = math.floor(mn[3] / CELL), math.floor(mx[3] / CELL) do
			occ[`{yk}:{cx},{cz}`] = true
			yBand[yk] = y
		end
	end
end

-- Only flag a hole when all 4-neighbors are occupied (interior hole), not building edge.
local holeCount = 0
local seenHole: { [string]: boolean } = {}
for key in occ do
	local yk, rest = string.match(key, "^([^:]+):(.+)$")
	if yk and rest then
		local cx, cz = string.match(rest, "^(-?%d+),(-?%d+)$")
		if cx then
			local x = tonumber(cx) :: number
			local z = tonumber(cz) :: number
			for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
				local nk = `{yk}:{x + d[1]},{z + d[2]}`
				if not occ[nk] and not seenHole[nk] then
					local n = 0
					for _, e in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
						if occ[`{yk}:{x + d[1] + e[1]},{z + d[2] + e[2]}`] then
							n += 1
						end
					end
					if n >= 4 then
						seenHole[nk] = true
						holeCount += 1
						if holeCount <= MAX_REPORT then
							add("gap", `floor hole ~{CELL} ft at y~{yBand[yk]} cell ({x + d[1]},{z + d[2]})`)
						end
					end
				end
			end
		end
	end
end

print("check_perf counts:")
print(
	`  parts whole={counts.whole} shell={counts.shell} props={counts.props} exterior={counts.exterior} campus={counts.campus} horizon={counts.horizon}`
)
print(
	`  instances={counts.instances} meshes={counts.meshes} unions={counts.unions} decals={counts.decals} textures={counts.textures}`
)
print(`  lights={counts.lights} lightsWithShadows={counts.lightsShadow}`)
print(`  budgets whole<={BUDGET.whole} shell<={BUDGET.shell} props<={BUDGET.props} exterior<={BUDGET.exterior}`)

local failed = false
for kind, list in issues do
	if #list > 0 then
		failed = true
		print(`FAIL {kind} ({#list})`)
		for i, msg in list do
			if i <= MAX_REPORT then
				print("  " .. msg)
			end
		end
		if #list > MAX_REPORT then
			print(`  ... +{#list - MAX_REPORT} more`)
		end
	end
end

if failed then
	process.exit(1)
end
print("PASS check_perf")
process.exit(0)
