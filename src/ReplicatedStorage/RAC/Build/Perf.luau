--!strict
-- Post-build collision/streaming pass. No visual change: flags and grouping only.
local Perf = {}

export type Snapshot = {
	parts: number,
	canCollide: number,
	canTouch: number,
	canQuery: number,
	castShadow: number,
	meshes: number,
	propGroups: number,
}

local STRUCTURAL: { string } = {
	"floor",
	"slab",
	"wall",
	"column",
	"stair",
	"tread",
	"riser",
	"stringer",
	"landing",
	"spawn",
	"roof",
	"deck",
	"parapet",
	"door",
}

local FURNITURE: { string } = {
	"desk",
	"table",
	"bench",
	"locker",
	"rack",
	"machine",
	"treadmill",
	"elliptical",
	"rower",
	"bike",
	"press",
	"fridge",
	"vending",
	"cubicle",
	"bleacher",
	"partition",
	"counter",
	"stall",
	"cabinet",
	"case",
}

local TRIM: { string } = {
	"trim",
	"base",
	"mullion",
	"fin",
	"stripe",
	"label",
	"sign",
	"banner",
	"flag",
	"clock",
	"outlet",
	"thermostat",
	"pad",
	"light",
	"troffer",
	"high_bay",
	"highbay",
	"downlight",
	"fixture",
	"joist",
	"tbar",
	"grid",
	"glass",
	"canopy_fin",
}

local function lower(s: string): string
	return string.lower(s)
end

local function pathOf(inst: Instance): string
	local names = {}
	local cur: Instance? = inst
	while cur do
		table.insert(names, 1, cur.Name)
		cur = cur.Parent
	end
	return lower(table.concat(names, "."))
end

local function hasAny(hay: string, keys: { string }): boolean
	for _, k in keys do
		if string.find(hay, k, 1, true) then
			return true
		end
	end
	return false
end

local function minAxis(s: Vector3): number
	return math.min(s.X, s.Y, s.Z)
end

local function maxAxis(s: Vector3): number
	return math.max(s.X, s.Y, s.Z)
end

local function snapshot(root: Instance): Snapshot
	local s: Snapshot = {
		parts = 0,
		canCollide = 0,
		canTouch = 0,
		canQuery = 0,
		castShadow = 0,
		meshes = 0,
		propGroups = 0,
	}
	local function tally(p: Instance)
		if p:IsA("BasePart") then
			s.parts += 1
			if p.CanCollide then
				s.canCollide += 1
			end
			if p.CanTouch then
				s.canTouch += 1
			end
			if p.CanQuery then
				s.canQuery += 1
			end
			if p.CastShadow then
				s.castShadow += 1
			end
			if p:IsA("MeshPart") then
				s.meshes += 1
			end
		elseif p:IsA("Model") and p:GetAttribute("PerfPropGroup") == true then
			s.propGroups += 1
		end
	end
	tally(root)
	for _, d in root:GetDescendants() do
		tally(d)
	end
	return s
end

local function isStructural(path: string): boolean
	if string.find(path, ".floors.", 1, true) then
		return true
	end
	if string.find(path, ".walls.", 1, true) and not hasAny(path, { "trim", "baseboard", "sign" }) then
		return true
	end
	if string.find(path, ".stairs.", 1, true) then
		return true
	end
	if string.find(path, ".columns.", 1, true) then
		return true
	end
	if string.find(path, ".roofs.", 1, true) then
		return true
	end
	if string.find(path, "lobbyspawn", 1, true) then
		return true
	end
	return hasAny(path, STRUCTURAL)
end

local function isFurnitureBody(path: string, size: Vector3): boolean
	if not string.find(path, ".props.", 1, true) then
		return false
	end
	if hasAny(path, TRIM) then
		return false
	end
	return hasAny(path, FURNITURE) and minAxis(size) >= 0.06 and size.X * size.Y * size.Z >= 0.45
end

function Perf.snapshot(root: Instance): Snapshot
	return snapshot(root)
end

function Perf.apply(root: Instance): { before: Snapshot, after: Snapshot }
	local before = snapshot(root)
	for _, d in root:GetDescendants() do
		if d:IsA("MeshPart") then
			d.CollisionFidelity = Enum.CollisionFidelity.Box
		end
		if d:IsA("BasePart") then
			local path = pathOf(d)
			local size = d.Size
			local structural = isStructural(path)
			local furniture = isFurnitureBody(path, size)
			local trim = hasAny(path, TRIM)
			local tiny = minAxis(size) < 0.5
			local interactive = string.find(path, "door", 1, true) ~= nil
				or string.find(path, "prompt", 1, true) ~= nil
				or d.Name == "LobbySpawn"

			if not interactive then
				d.CanTouch = false
			end
			if not structural and not furniture and not interactive then
				d.CanQuery = false
			end
			if maxAxis(size) < 2 then
				d.CastShadow = false
			end
			if (trim or tiny) and not structural and not furniture then
				d.CanCollide = false
			end
		end
	end

	local props = root:FindFirstChild("Props")
	if props then
		for _, levelFolder in props:GetChildren() do
			local byKind: { [string]: { Instance } } = {}
			for _, child in levelFolder:GetChildren() do
				if child:IsA("Model") and child:GetAttribute("PerfPropGroup") ~= true then
					local kind = child:GetAttribute("Kind")
					if type(kind) == "string" then
						local list = byKind[kind]
						if list == nil then
							list = {}
							byKind[kind] = list
						end
						table.insert(list, child)
					end
				end
			end
			for kind, list in byKind do
				if #list >= 2 then
					local group = Instance.new("Model")
					group.Name = kind .. "_group"
					group:SetAttribute("PerfPropGroup", true)
					pcall(function()
						group.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
					end)
					group.Parent = levelFolder
					for _, inst in list do
						inst.Parent = group
					end
				elseif #list == 1 then
					pcall(function()
						(list[1] :: Model).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
					end)
				end
			end
		end
	end

	pcall(function()
		if root:IsA("Model") then
			(root :: Model).ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		end
	end)
	root:SetAttribute("PerfApplied", true)

	local after = snapshot(root)
	root:SetAttribute("PerfParts", after.parts)
	root:SetAttribute("PerfCanCollide", after.canCollide)
	root:SetAttribute("PerfCastShadow", after.castShadow)
	root:SetAttribute("PerfPropGroups", after.propGroups)
	print(
		`[RAC Perf] parts {before.parts}->{after.parts} collide {before.canCollide}->{after.canCollide} touch {before.canTouch}->{after.canTouch} query {before.canQuery}->{after.canQuery} shadow {before.castShadow}->{after.castShadow} groups {after.propGroups}`
	)
	return { before = before, after = after }
end

return Perf
