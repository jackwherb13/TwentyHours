-- Geometry QA on a built model (the actual Parts, not the blueprint). Run:
--   lune run tools/check_geometry.luau places/build.rbxm [blueprint dir]
-- Fails (exit 1) on: intersecting walls, z-fighting (coplanar overlapping faces), floating parts, degenerate parts,
-- small gaps between wall ends, and walls/solids blocking door openings from the blueprint.
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local file = process.args[1] or "places/build.rbxm"
local bpDir = process.args[2] or "blueprint"
local EPS = 0.02
local MAX_REPORT = 25

type Box = { part: any, name: string, path: string, min: { number }, max: { number }, wall: boolean, solid: boolean, hung: boolean }

local HUNG = { "ceiling", "light", "troffer", "highbay", "high_bay", "downlight", "sign", "banner", "flag", "hoop", "scoreboard",
	"joist", "deck", "roof", "duct", "tv", "mirror", "clock", "window", "glass", "mullion", "head", "lintel", "above", "slab",
	"level2", "canopy", "grid", "tbar", "speaker", "rail", "pad", "board", "cabinet", "exit", "extinguisher", "shelf", "cubby" }

local function lower(s: string): string
	return string.lower(s)
end

local function isHung(path: string): boolean
	local p = lower(path)
	for _, k in HUNG do
		if string.find(p, k, 1, true) then
			return true
		end
	end
	return false
end

local function aabb(p): ({ number }, { number })
	local cf, s = p.CFrame, p.Size
	local c = cf.Position
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local hx = math.abs(r.X) * s.X / 2 + math.abs(u.X) * s.Y / 2 + math.abs(l.X) * s.Z / 2
	local hy = math.abs(r.Y) * s.X / 2 + math.abs(u.Y) * s.Y / 2 + math.abs(l.Y) * s.Z / 2
	local hz = math.abs(r.Z) * s.X / 2 + math.abs(u.Z) * s.Y / 2 + math.abs(l.Z) * s.Z / 2
	return { c.X - hx, c.Y - hy, c.Z - hz }, { c.X + hx, c.Y + hy, c.Z + hz }
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

local model = roblox.deserializeModel(fs.readFile(file))
local boxes: { Box } = {}
for _, root in model do
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 0.95 then
			local mn, mx = aabb(d)
			local path = fullPath(d)
			local lname = lower(d.Name)
			table.insert(boxes, {
				part = d,
				name = d.Name,
				path = path,
				min = mn,
				max = mx,
				wall = string.find(lname, "wall", 1, true) ~= nil and not string.find(lname, "pad", 1, true),
				solid = d.CanCollide,
				hung = isHung(path),
			})
		end
	end
end

-- spatial hash on 8 ft cells (x,z)
local CELL = 8
local grid: { [string]: { number } } = {}
for i, b in boxes do
	for cx = math.floor(b.min[1] / CELL), math.floor(b.max[1] / CELL) do
		for cz = math.floor(b.min[3] / CELL), math.floor(b.max[3] / CELL) do
			local k = `{cx},{cz}`
			grid[k] = grid[k] or {}
			table.insert(grid[k], i)
		end
	end
end

local issues: { [string]: { string } } = {
	intersect = {},
	zfight = {},
	floating = {},
	degenerate = {},
	gap = {},
	doorBlocked = {},
}
local function add(kind: string, msg: string)
	table.insert(issues[kind], msg)
end

local function overlap(a: Box, b: Box, k: number): number
	return math.min(a.max[k], b.max[k]) - math.max(a.min[k], b.min[k])
end

local checked: { [string]: boolean } = {}
for _, list in grid do
	for x = 1, #list do
		for y = x + 1, #list do
			local i, j = list[x], list[y]
			local key = if i < j then `{i}:{j}` else `{j}:{i}`
			if checked[key] then
				continue
			end
			checked[key] = true
			local a, b = boxes[i], boxes[j]
			local ox, oy, oz = overlap(a, b, 1), overlap(a, b, 2), overlap(a, b, 3)
			-- interpenetrating walls (ignore corner/tee joints, where overlap is limited to the wall thickness)
			if a.wall and b.wall and ox > EPS and oy > EPS and oz > EPS then
				local ta = math.min(a.max[1] - a.min[1], a.max[3] - a.min[3])
				local tb = math.min(b.max[1] - b.min[1], b.max[3] - b.min[3])
				local joint = math.max(ta, tb) + 0.1
				if not (ox <= joint and oz <= joint) then
					add("intersect", string.format("%s  x  %s  (overlap %.1f x %.1f x %.1f ft)", a.path, b.path, ox, oy, oz))
				end
			end
			-- z-fighting: same-facing coplanar faces with real overlap area
			for axis = 1, 3 do
				local o1 = axis == 1 and oy or ox
				local o2 = axis == 3 and oy or oz
				if axis == 2 then
					o1, o2 = ox, oz
				end
				if o1 > 0.25 and o2 > 0.25 and o1 * o2 > 0.5 then
					local sameMax = math.abs(a.max[axis] - b.max[axis]) < 0.005
					local sameMin = math.abs(a.min[axis] - b.min[axis]) < 0.005
					if (sameMax or sameMin) and (a.part.Color ~= b.part.Color or a.part.Material ~= b.part.Material) then
						add("zfight", string.format("%s  /  %s  (axis %s, %.1f sqft)", a.path, b.path, ({ "X", "Y", "Z" })[axis], o1 * o2))
					end
				end
			end
		end
	end
end

-- floating: bottom face not resting on anything (and not a hung element)
for i, b in boxes do
	local sx, sy, sz = b.max[1] - b.min[1], b.max[2] - b.min[2], b.max[3] - b.min[3]
	if math.min(sx, sy, sz) < 0.004 then
		add("degenerate", string.format("%s  size %.3f x %.3f x %.3f", b.path, sx, sy, sz))
	end
	if b.hung or b.min[2] < 0.3 then
		continue
	end
	local supported = false
	for cx = math.floor(b.min[1] / CELL), math.floor(b.max[1] / CELL) do
		for cz = math.floor(b.min[3] / CELL), math.floor(b.max[3] / CELL) do
			for _, j in grid[`{cx},{cz}`] or {} do
				if j ~= i then
					local o = boxes[j]
					if o.max[2] >= b.min[2] - 0.05 and o.min[2] <= b.min[2] + 0.05 and overlap(b, o, 1) > -0.05 and overlap(b, o, 3) > -0.05 then
						supported = true
						break
					end
				end
			end
			if supported then
				break
			end
		end
		if supported then
			break
		end
	end
	if not supported then
		add("floating", string.format("%s  bottom at y=%.2f", b.path, b.min[2]))
	end
end

-- small gaps between wall ends (0.05..1.5 ft) = sloppy geometry / light leaks
local walls = {}
for _, b in boxes do
	if b.wall then
		table.insert(walls, b)
	end
end
for i, a in walls do
	for j = i + 1, #walls do
		local b = walls[j]
		if overlap(a, b, 2) > 1 then
			local gx = math.max(a.min[1] - b.max[1], b.min[1] - a.max[1])
			local gz = math.max(a.min[3] - b.max[3], b.min[3] - a.max[3])
			local alongX = gz < 0 and gx > 0.05 and gx < 1.5 and overlap(a, b, 3) > 0.3
			local alongZ = gx < 0 and gz > 0.05 and gz < 1.5 and overlap(a, b, 1) > 0.3
			if alongX or alongZ then
				add("gap", string.format("%s  <->  %s  gap %.2f ft", a.path, b.path, math.max(gx, gz)))
			end
		end
	end
end

-- door openings from the blueprint must be clear of walls and solid parts (door props/frames excluded)
for _, lv in { "level1", "level2" } do
	local path = `{bpDir}/{lv}.json`
	if not fs.isFile(path) then
		continue
	end
	local d = serde.decode("json", fs.readFile(path))
	local elev = d.elevation or 0
	for _, w in d.walls or {} do
		local ax, az, bx, bz = w.a[1], w.a[2], w.b[1], w.b[2]
		local len = math.sqrt((bx - ax) ^ 2 + (bz - az) ^ 2)
		if len == 0 then
			continue
		end
		local ux, uz = (bx - ax) / len, (bz - az) / len
		for _, o in w.openings or {} do
			if o.type ~= "door" and o.type ~= "opening" then
				continue
			end
			local m0, m1 = o.offset + 0.3, o.offset + o.width - 0.3
			local x0, x1 = math.min(ax + ux * m0, ax + ux * m1), math.max(ax + ux * m0, ax + ux * m1)
			local z0, z1 = math.min(az + uz * m0, az + uz * m1), math.max(az + uz * m0, az + uz * m1)
			local t = (w.thickness or 0.67) / 2 + 0.5
			if math.abs(ux) > math.abs(uz) then
				z0, z1 = z0 - t, z1 + t
			else
				x0, x1 = x0 - t, x1 + t
			end
			local y0, y1 = elev + 0.3, elev + (o.head or 7) - 0.3
			for cx = math.floor(x0 / CELL), math.floor(x1 / CELL) do
				for cz = math.floor(z0 / CELL), math.floor(z1 / CELL) do
					for _, j in grid[`{cx},{cz}`] or {} do
						local p = boxes[j]
						local lp = lower(p.path)
						if (p.wall or p.solid) and not string.find(lp, "door", 1, true) and not string.find(lp, "frame", 1, true) then
							if p.min[1] < x1 and p.max[1] > x0 and p.min[3] < z1 and p.max[3] > z0 and p.min[2] < y1 and p.max[2] > y0 then
								add("doorBlocked", string.format("%s door on %s @%.1f blocked by %s", lv, tostring(w.id), o.offset, p.path))
							end
						end
					end
				end
			end
		end
	end
end

local total = 0
for kind, list in issues do
	-- dedupe
	local seen, uniq = {}, {}
	for _, m in list do
		if not seen[m] then
			seen[m] = true
			table.insert(uniq, m)
		end
	end
	total += #uniq
	print(string.format("%-12s %d", kind, #uniq))
	for n = 1, math.min(#uniq, MAX_REPORT) do
		print("   " .. uniq[n])
	end
end
print(string.format("%d parts checked, %d issues", #boxes, total))
if total > 0 then
	process.exit(1)
end
