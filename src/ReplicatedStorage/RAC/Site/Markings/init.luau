--!strict
-- Painted lane lines, stalls, crosswalks, islands. Call Markings.build(parent, site).
-- Lune loader uses .../Markings/init (Parent=Markings). Rojo Parent=Site.
local function loadFirst(candidates: { any }): any
	local last: any = nil
	for _, ref in candidates do
		local ok, mod = pcall(require, ref)
		if ok then
			return mod
		end
		last = mod
	end
	error(last)
end
local P = loadFirst({ script.Parent.Primitives, script.Parent.Parent.Primitives })
local H = loadFirst({ script.Parent.Heightfield, script.Parent.Parent.Heightfield })
local Data = loadFirst({ script.Data, script.Parent.Data })

local Markings = {}

local STRIPE_H = 0.06
local RISE = 0.3 -- clear of the lidar slab top (~height+0.08)

local extra: { [string]: { Enum.Material | Color3 } } = {
	blue = { Enum.Material.SmoothPlastic, Color3.fromRGB(40, 82, 168) },
	concrete = { Enum.Material.Concrete, Color3.fromRGB(188, 184, 168) },
}

local function paintBox(parent: Instance, name: string, size: Vector3, cf: CFrame, finish: string): Part
	if extra[finish] then
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame = name, size, cf
		p.Anchored, p.CanCollide = true, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Material = extra[finish][1] :: Enum.Material
		p.Color = extra[finish][2] :: Color3
		p.Parent = parent
		return p
	end
	return P.box(parent, name, size, cf, finish, false)
end

local KIND_LIFT: { [string]: number } = {
	double_yellow = 0.00,
	dashed_yellow = 0.05,
	white_edge = 0.06,
	bike_lane = 0.16,
	dashed_white = 0.12,
	stall = 0.00,
	crosswalk = 0.48,
	stop_bar = 0.26,
	arrow = 0.10,
	symbol = 0.14,
	island = 0.72,
}

local function draped(
	parent: Instance,
	name: string,
	a: { number },
	b: { number },
	width: number,
	finish: string,
	depth: number,
	lift: number
): Part?
	local ax, az, bx, bz = a[1], a[2], b[1], b[2]
	local dx, dz = bx - ax, bz - az
	local length = math.sqrt(dx * dx + dz * dz)
	if length < 0.4 then
		return nil
	end
	local y0 = H.height(ax, az) + RISE + lift
	local y1 = H.height(bx, bz) + RISE + lift
	return paintBox(
		parent,
		name,
		Vector3.new(math.max(width, 0.12), depth, length),
		CFrame.lookAt(Vector3.new((ax + bx) / 2, (y0 + y1) / 2, (az + bz) / 2), Vector3.new(bx, y1, bz)),
		finish
	)
end

function Markings.build(parent: Instance, _site: any): number
	local folder = P.folder(parent, "SiteMarkingsSlab")
	local n = 0
	local budget = 2500
	for _, feat in Data.features do
		if n >= budget then
			break
		end
		local kind = feat.kind
		local color = feat.color
		local finish = if color == "yellow"
			then "yellow"
			elseif color == "blue" then "blue"
			elseif color == "concrete" then "concrete"
			else "white"
		local width = feat.width or 0.333
		if kind == "stall" then
			width = math.max(width, 0.55)
		end
		local depth = if kind == "island" then 0.5 else STRIPE_H
		local lift = KIND_LIFT[kind] or 0
		local pts = feat.points
		local name = if kind == "island"
			then "CurbIslandSlab"
			elseif kind == "crosswalk" then "CrosswalkSlab"
			elseif kind == "stall" then "StallStripeSlab"
			elseif kind == "stop_bar" then "StopBarSlab"
			else "LaneStripeSlab"
		for i = 1, #pts - 1 do
			if n >= budget then
				break
			end
			local a, b = pts[i], pts[i + 1]
			local dx, dz = b[1] - a[1], b[2] - a[2]
			local length = math.sqrt(dx * dx + dz * dz)
			local maxSeg = if kind == "stall" or kind == "crosswalk" then 40 else 8
			local pieces = math.max(1, math.ceil(length / maxSeg))
			for k = 0, pieces - 1 do
				if n >= budget then
					break
				end
				local t0, t1 = k / pieces, (k + 1) / pieces
				local p0 = { a[1] + dx * t0, a[2] + dz * t0 }
				local p1 = { a[1] + dx * t1, a[2] + dz * t1 }
				local jitter = (math.abs(p0[2]) % 11) * 0.012 + (math.abs(p0[1]) % 5) * 0.007
				local part = draped(folder, name, p0, p1, width, finish, depth, lift + jitter)
				if part then
					n += 1
				end
			end
		end
	end
	return n
end

return Markings
