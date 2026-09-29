--!strict
-- Supplemental terrain-aware QA. The repository's AABB checker remains unchanged.
-- Checks actual oriented, same-facing coplanar rectangular faces; spheres have no planar faces.
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Loader = require("../../tests/lib/loader")
local H = Loader.new().load("src/ReplicatedStorage/RAC/Site/Heightfield")
local V = roblox.Vector3
local roots = roblox.deserializeModel(fs.readFile("verification/exterior/site_preview.rbxm"))
local root = roots[1].Site.Context
local boxes = {}
local cells = {}
local failures = {}
local function fail(message)
	table.insert(failures, message)
end
local function faces(p)
	local cf, s = p.CFrame, p.Size
	local axes = { cf.RightVector, cf.UpVector, -cf.LookVector }
	local sizes = { s.X, s.Y, s.Z }
	local result = {}
	for i = 1, 3 do
		local j, k = i % 3 + 1, (i + 1) % 3 + 1
		for _, sign in { -1, 1 } do
			local normal = axes[i] * sign
			local center = cf.Position + normal * sizes[i] / 2
			local u, v = axes[j] * sizes[j] / 2, axes[k] * sizes[k] / 2
			table.insert(result, { normal = normal, center = center, corners = { center + u + v, center - u + v, center - u - v, center + u - v }, axes = { axes[j], axes[k] } })
		end
	end
	return result
end
for _, p in root:GetDescendants() do
	if not p:IsA("BasePart") then
		continue
	end
	if not p.Anchored then
		fail("Unanchored " .. p:GetFullName())
	end
	if math.min(p.Size.X, p.Size.Y, p.Size.Z) < 0.01 then
		fail("Sliver " .. p:GetFullName())
	end
	-- Explicitly verify terrain-supported riprap rather than assuming y=0 is ground.
	if p.Name == "Rock" then
		local c = p.CFrame.Position
		if math.abs(c.Y - (H.height(c.X, c.Z) - 0.25)) > 0.02 then
			fail("Riprap is not embedded in sampled terrain")
		end
	end
	if p.ClassName ~= "Part" or p.Shape ~= roblox.Enum.PartType.Block then
		continue
	end
	local cf, s = p.CFrame, p.Size
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local half = V.new(math.abs(r.X) * s.X + math.abs(u.X) * s.Y + math.abs(l.X) * s.Z, math.abs(r.Y) * s.X + math.abs(u.Y) * s.Y + math.abs(l.Y) * s.Z, math.abs(r.Z) * s.X + math.abs(u.Z) * s.Y + math.abs(l.Z) * s.Z) / 2
	local low, high = cf.Position - half, cf.Position + half
	table.insert(boxes, { part = p, low = low, high = high, faces = faces(p) })
	local index = #boxes
	for x = math.floor(low.X / 16), math.floor(high.X / 16) do
		for z = math.floor(low.Z / 16), math.floor(high.Z / 16) do
			local key = `{x},{z}`
			cells[key] = cells[key] or {}
			table.insert(cells[key], index)
		end
	end
end
local function interval(corners, axis)
	local lo, hi = math.huge, -math.huge
	for _, q in corners do
		local n = q:Dot(axis)
		lo, hi = math.min(lo, n), math.max(hi, n)
	end
	return lo, hi
end
local function intersects(a, b)
	for _, q in a.corners do
		if math.abs((q - b.center):Dot(b.normal)) >= 0.005 then
			return false
		end
	end
	for _, q in b.corners do
		if math.abs((q - a.center):Dot(a.normal)) >= 0.005 then
			return false
		end
	end
	for _, axis in { a.axes[1], a.axes[2], b.axes[1], b.axes[2] } do
		local a0, a1 = interval(a.corners, axis)
		local b0, b1 = interval(b.corners, axis)
		if math.min(a1, b1) - math.max(a0, b0) < 0.04 then
			return false
		end
	end
	return true
end
local checked = {}
for _, list in cells do
	for i = 1, #list do
		for j = i + 1, #list do
			local ia, ib = list[i], list[j]
			local key = if ia < ib then `{ia}:{ib}` else `{ib}:{ia}`
			if checked[key] then
				continue
			end
			checked[key] = true
			local a, b = boxes[ia], boxes[ib]
			if a.high.Y < b.low.Y - 0.01 or b.high.Y < a.low.Y - 0.01 then
				continue
			end
			if a.part.Color == b.part.Color and a.part.Material == b.part.Material then
				continue
			end
			for _, fa in a.faces do
				for _, fb in b.faces do
					if fa.normal:Dot(fb.normal) > 0.999999 and math.abs((fa.center - fb.center):Dot(fa.normal)) < 0.005 and intersects(fa, fb) then
						fail(`Coplanar faces: {a.part:GetFullName()} / {b.part:GetFullName()}`)
					end
				end
			end
		end
	end
end
for _, message in failures do
	print("FAIL " .. message)
end
print(string.format("Terrain-aware oriented-face QA: %d planar parts, %d failures", #boxes, #failures))
process.exit(if #failures == 0 then 0 else 1)
