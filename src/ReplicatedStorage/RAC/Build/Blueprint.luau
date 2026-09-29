--!strict
-- Schema types are shared by every geometry builder. Decoding happens only at this boundary.
local Blueprint = {}
export type Point = { number }
export type Polygon = { Point }
export type Opening = {
	type: string,
	offset: number,
	width: number,
	sill: number,
	head: number,
	leaves: number?,
	tag: string?,
	mullionSpacing: number?,
}
export type Wall = {
	id: string,
	a: Point,
	b: Point,
	thickness: number,
	height: number,
	material: string,
	exterior: boolean,
	openings: { Opening },
}
export type Room = {
	id: string,
	name: string,
	type: string,
	polygon: Polygon,
	floorMaterial: string,
	ceilingHeight: number,
	ceilingType: string,
	wallFinish: string?,
}
export type Void = { id: string, polygon: Polygon }
export type Column = { id: string, at: Point, size: { number }, height: number }
export type Stair = {
	id: string,
	polygon: Polygon,
	fromLevel: number,
	toLevel: number,
	direction: Point,
	risers: number,
	rise: number,
	run: number,
	width: number,
}
export type Prop = { id: string, kind: string, at: Point, rotation: number, room: string }
export type Level = {
	level: number,
	elevation: number,
	rooms: { Room },
	walls: { Wall },
	columns: { Column },
	stairs: { Stair },
	voids: { Void },
	props: { Prop },
}
export type Facade = { a: Point, b: Point, style: string, height: number, base: number }
export type Roof = { polygon: Polygon, height: number, type: string, overhang: number }
export type Site = {
	units: string,
	trueNorthDeg: number,
	footprint: Polygon,
	levels: { { level: number, elevation: number } },
	facade: { Facade },
	roofs: { Roof },
}
export type Data = { site: Site, levels: { Level } }

function Blueprint.decode(raw: any): Data
	assert(type(raw) == "table" and type(raw.site) == "table", "Expected {site, levels} or {site, level1, level2}")
	assert(raw.site.units == "ft", "Blueprint units must be ft")
	local levels: { Level } = raw.levels or { raw.level1, raw.level2 }
	assert(#levels > 0, "Blueprint has no levels")
	local seen: { [number]: boolean } = {}
	for _, level in levels do
		assert(not seen[level.level], "Duplicate level")
		seen[level.level] = true
		assert(type(level.rooms) == "table" and type(level.walls) == "table", "Missing level arrays")
		local matched = false
		for _, descriptor in raw.site.levels do
			if descriptor.level == level.level then
				assert(math.abs(descriptor.elevation - level.elevation) < 0.001, "Level elevation disagrees with site")
				matched = true
			end
		end
		assert(matched, "Level missing from site.levels")
	end
	return { site = raw.site, levels = levels }
end

function Blueprint.elevation(data: Data, number: number): number
	for _, level in data.site.levels do
		if level.level == number then
			return level.elevation
		end
	end
	error(`Unknown level {number}`)
end

function Blueprint.load(folder: Instance?): Data
	local source = folder or script.Parent:FindFirstChild("Data")
	assert(source, "Generate Build/Data with tools/json2luau.py first")
	local siteModule = source:FindFirstChild("site")
	assert(siteModule and siteModule:IsA("ModuleScript"), "Missing generated site ModuleScript")
	local site = require(siteModule) :: Site
	local levels: { Level } = {}
	for _, descriptor in site.levels do
		local module = source:FindFirstChild(`level{descriptor.level}`)
		assert(module and module:IsA("ModuleScript"), "Missing generated level ModuleScript")
		table.insert(levels, require(module) :: Level)
	end
	return Blueprint.decode({ site = site, levels = levels })
end
return Blueprint
