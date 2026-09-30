--!strict
-- Schema gate for blueprint/. Silent on success. Prints FAIL lines and exits 1 otherwise.
--   lune run tools/validate_blueprint.luau

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local fails: { string } = {}

local function fail(msg: string)
	table.insert(fails, msg)
end

local ROOM_TYPES = {
	gym = true, corridor = true, lobby = true, office = true, fitness = true, locker = true,
	restroom = true, support = true, mechanical = true, stair = true, storage = true,
	racquetball = true, construction = true, void = true,
}
local FLOORS = {
	maple = true, terrazzo = true, porcelain_tile = true, carpet_tile = true, rubber = true,
	sealed_concrete = true, ceramic_tile = true, vinyl = true, racquetball_wood = true,
}
local CEILINGS = { act_2x2 = true, act_2x4 = true, gypsum = true, open_joist = true, none = true }
local WALL_MATS = { painted_cmu = true, brick = true, gypsum = true, glass = true, metal_panel = true, precast = true }
local OPENINGS = { door = true, window = true, opening = true, curtainwall = true }
local FACADE = { brick = true, precast_band = true, metal_panel = true, curtain_wall = true, sunshade_fins = true }
local ROOF_TYPES = { flat = true, canopy = true }
local IRREGULAR = { lobby = true, construction = true, exterior = true, canopy = true }

local function readJson(path: string): any
	if not fs.isFile(path) then
		fail("missing " .. path)
		return nil
	end
	local ok, value = pcall(function()
		return serde.decode("json", fs.readFile(path))
	end)
	if not ok then
		fail(path .. " is not JSON")
		return nil
	end
	return value
end

local function snapped(v: any): boolean
	if type(v) ~= "number" then
		return false
	end
	return math.abs(v * 2 - math.floor(v * 2 + 0.5)) < 1e-3
end

local function dist(a: { number }, b: { number }): number
	local dx = a[1] - b[1]
	local dz = a[2] - b[2]
	return math.sqrt(dx * dx + dz * dz)
end

local function checkPoly(poly: any, where: string, maxVerts: number?)
	if type(poly) ~= "table" or #poly < 3 then
		fail(where .. " needs a polygon of at least 3 points")
		return
	end
	if maxVerts and #poly > maxVerts then
		fail(where .. " has " .. tostring(#poly) .. " vertices (max " .. tostring(maxVerts) .. ")")
	end
	local area2 = 0
	for i, point in poly do
		local nxt = poly[(i % #poly) + 1]
		if type(point) ~= "table" or not snapped(point[1]) or not snapped(point[2]) then
			fail(where .. " has a point that is not snapped to 0.5 ft")
			return
		end
		if type(nxt) == "table" then
			area2 += point[1] * nxt[2] - nxt[1] * point[2]
		end
	end
	local first, last = poly[1], poly[#poly]
	if type(first) == "table" and type(last) == "table" and first[1] == last[1] and first[2] == last[2] then
		fail(where .. " repeats its closing point")
	end
	if area2 <= 1 then
		fail(where .. " is not counter-clockwise")
	end
end

local function checkLevel(doc: any, expected: number)
	if type(doc) ~= "table" then
		return
	end
	local tag = "level" .. tostring(expected)
	if doc.level ~= expected then
		fail(tag .. " level field is " .. tostring(doc.level))
	end
	if type(doc.elevation) ~= "number" then
		fail(tag .. " missing elevation")
	end
	if type(doc.rooms) ~= "table" then
		fail(tag .. " missing rooms")
		return
	end
	local ids: { [string]: boolean } = {}
	for _, room in doc.rooms do
		local id = tostring(room.id)
		if ids[id] then
			fail(tag .. " duplicate room " .. id)
		end
		ids[id] = true
		for _, key in { "id", "name", "type", "polygon", "floorMaterial", "ceilingHeight", "ceilingType", "wallFinish" } do
			if room[key] == nil then
				fail(tag .. " room " .. id .. " missing " .. key)
			end
		end
		if not ROOM_TYPES[room.type] then
			fail(tag .. " room " .. id .. " has type " .. tostring(room.type))
		end
		if not FLOORS[room.floorMaterial] then
			fail(tag .. " room " .. id .. " has floor " .. tostring(room.floorMaterial))
		end
		if not CEILINGS[room.ceilingType] then
			fail(tag .. " room " .. id .. " has ceiling " .. tostring(room.ceilingType))
		end
		if type(room.ceilingHeight) ~= "number" then
			fail(tag .. " room " .. id .. " ceilingHeight is not a number")
		end
		local cap = if IRREGULAR[room.type] then 24 else 12
		checkPoly(room.polygon, tag .. " room " .. id, cap)
		if room.type == "racquetball" and type(room.polygon) == "table" then
			local xs, zs = {}, {}
			for _, p in room.polygon do
				table.insert(xs, p[1])
				table.insert(zs, p[2])
			end
			table.sort(xs)
			table.sort(zs)
			local w = xs[#xs] - xs[1]
			local d = zs[#zs] - zs[1]
			local long = math.max(w, d)
			local short = math.min(w, d)
			if math.abs(long - 40) > 0.1 or math.abs(short - 20) > 0.1 then
				fail(tag .. " " .. id .. " is " .. tostring(w) .. " x " .. tostring(d) .. " (want 40 x 20)")
			end
		end
	end
	if type(doc.walls) ~= "table" then
		fail(tag .. " missing walls")
		return
	end
	local wallIds: { [string]: boolean } = {}
	for _, wall in doc.walls do
		local id = tostring(wall.id)
		if wallIds[id] then
			fail(tag .. " duplicate wall " .. id)
		end
		wallIds[id] = true
		if type(wall.a) ~= "table" or type(wall.b) ~= "table" or not snapped(wall.a[1]) or not snapped(wall.a[2]) or not snapped(wall.b[1]) or not snapped(wall.b[2]) then
			fail(tag .. " wall " .. id .. " endpoints are not snapped")
		end
		if type(wall.a) == "table" and type(wall.b) == "table" then
			local length = dist(wall.a, wall.b)
			if length < 2 then
				fail(tag .. " wall " .. id .. " is " .. string.format("%.2f", length) .. " ft")
			end
			if type(wall.openings) ~= "table" then
				fail(tag .. " wall " .. id .. " missing openings")
			else
				for _, opening in wall.openings do
					if not OPENINGS[opening.type] then
						fail(tag .. " wall " .. id .. " opening type " .. tostring(opening.type))
					end
					if type(opening.offset) ~= "number" or type(opening.width) ~= "number" then
						fail(tag .. " wall " .. id .. " opening missing offset/width")
					elseif opening.offset < -0.01 or opening.offset + opening.width > length + 0.05 then
						fail(tag .. " wall " .. id .. " opening runs past the wall")
					elseif not snapped(opening.offset) or not snapped(opening.width) then
						fail(tag .. " wall " .. id .. " opening is not snapped to 0.5 ft")
					end
					if type(opening.sill) ~= "number" or type(opening.head) ~= "number" or opening.head <= opening.sill then
						fail(tag .. " wall " .. id .. " opening head/sill")
					elseif type(wall.height) == "number" and opening.head > wall.height + 0.01 then
						fail(tag .. " wall " .. id .. " opening head above the wall")
					end
				end
			end
		end
		if not WALL_MATS[wall.material] then
			fail(tag .. " wall " .. id .. " material " .. tostring(wall.material))
		end
		if type(wall.thickness) ~= "number" or type(wall.height) ~= "number" or type(wall.exterior) ~= "boolean" then
			fail(tag .. " wall " .. id .. " missing thickness, height, or exterior")
		end
	end
	if type(doc.stairs) ~= "table" then
		fail(tag .. " missing stairs")
	else
		for _, stair in doc.stairs do
			checkPoly(stair.polygon, tag .. " stair " .. tostring(stair.id), 12)
			if stair.fromLevel ~= 1 or stair.toLevel ~= 2 then
				fail(tag .. " stair " .. tostring(stair.id) .. " from/to")
			end
			if type(stair.rise) ~= "number" or type(stair.run) ~= "number" or stair.rise <= 0 or stair.run <= 0 then
				fail(tag .. " stair " .. tostring(stair.id) .. " rise/run")
			end
			if type(stair.direction) ~= "table" or #stair.direction ~= 2 then
				fail(tag .. " stair " .. tostring(stair.id) .. " direction")
			end
		end
	end
	if type(doc.voids) ~= "table" then
		fail(tag .. " missing voids")
	else
		for _, void in doc.voids do
			checkPoly(void.polygon, tag .. " void " .. tostring(void.id), 12)
		end
	end
	if type(doc.columns) ~= "table" then
		fail(tag .. " missing columns")
	else
		for _, column in doc.columns do
			if type(column.at) ~= "table" or not snapped(column.at[1]) or not snapped(column.at[2]) then
				fail(tag .. " column " .. tostring(column.id) .. " is not snapped")
			end
		end
	end
	if type(doc.props) ~= "table" then
		fail(tag .. " missing props")
	else
		for _, prop in doc.props do
			if type(prop.kind) ~= "string" or type(prop.at) ~= "table" or not snapped(prop.at[1]) or not snapped(prop.at[2]) then
				fail(tag .. " prop " .. tostring(prop.id) .. " is incomplete or not snapped")
			end
		end
	end
end

local level1 = readJson("blueprint/level1.json")
local level2 = readJson("blueprint/level2.json")
local site = readJson("blueprint/site.json")
local calibration = readJson("blueprint/calibration.json")
local photos = readJson("blueprint/photo_stations.json")

checkLevel(level1, 1)
checkLevel(level2, 2)

if type(site) == "table" then
	if site.units ~= "ft" then
		fail("site units")
	end
	if type(site.trueNorthDeg) ~= "number" then
		fail("site missing trueNorthDeg")
	end
	if type(site.origin) ~= "table" or type(site.origin.lat) ~= "number" or type(site.origin.lon) ~= "number" then
		fail("site origin")
	end
	checkPoly(site.footprint, "site footprint", 40)
	if type(site.levels) ~= "table" or site.levels[1] == nil or site.levels[1].elevation ~= 0 or site.levels[2] == nil or math.abs((site.levels[2].elevation or 0) - 20) > 1.5 then
		fail("site levels must be 1 at 0 ft and 2 at ~20 ft (user: Level 2 is about 20 ft up)")
	end
	if type(site.facade) ~= "table" then
		fail("site missing facade")
	else
		for index, seg in site.facade do
			if not FACADE[seg.style] then
				fail("facade " .. tostring(index) .. " style " .. tostring(seg.style))
			end
			if type(seg.a) ~= "table" or type(seg.b) ~= "table" or dist(seg.a, seg.b) < 2 then
				fail("facade " .. tostring(index) .. " is shorter than 2 ft")
			end
			if type(seg.height) ~= "number" then
				fail("facade " .. tostring(index) .. " missing height")
			end
		end
	end
	if type(site.roofs) ~= "table" or #site.roofs == 0 then
		fail("site missing roofs")
	else
		for _, roof in site.roofs do
			checkPoly(roof.polygon, "roof", 12)
			if not ROOF_TYPES[roof.type] then
				fail("roof type " .. tostring(roof.type))
			end
			if type(roof.height) ~= "number" then
				fail("roof missing height")
			end
		end
	end
	if site.calibration ~= "calibration.json" then
		fail("site.calibration")
	end
end

if type(calibration) == "table" then
	if calibration.trueNorthDeg ~= (if type(site) == "table" then site.trueNorthDeg else nil) then
		fail("calibration trueNorthDeg does not match site.json")
	end
	if type(calibration.courts) ~= "table" then
		fail("calibration missing courts")
	else
		for _, court in calibration.courts do
			if type(court.error) ~= "table" then
				fail("court " .. tostring(court.name) .. " missing error")
			else
				for _, err in court.error do
					if type(err) ~= "number" or math.abs(err) > 0.04 then
						fail("court " .. tostring(court.name) .. " error " .. tostring(err) .. " is outside ±4%")
					end
				end
			end
		end
	end
	local osm = calibration.osm
	if type(osm) ~= "table" or type(osm.iouOrthogonalVsRaw) ~= "number" or osm.iouOrthogonalVsRaw < 0.92 then
		fail("calibration OSM IoU is under 0.92")
	end
end

if type(photos) == "table" and type(photos.stations) == "table" then
	local seen: { [string]: boolean } = {}
	for _, station in photos.stations do
		local id = tostring(station.id)
		if seen[id] then
			fail("duplicate photo station " .. id)
		end
		seen[id] = true
		if type(station.position) ~= "table" or #station.position ~= 3 then
			fail(id .. " position")
		elseif station.position[2] < -60 or station.position[2] > 150 then
			-- stations may be on Level 2 (~25.2 ft) or on sloped terrain outside; only reject absurd heights
			fail(id .. " camera height is " .. tostring(station.position[2]))
		end
		if type(station.look) ~= "table" or #station.look ~= 3 then
			fail(id .. " look")
		end
		if station.fovVertical ~= 55 then
			fail(id .. " fovVertical")
		end
	end
else
	fail("photo_stations.json needs a stations array")
end

if #fails > 0 then
	for _, msg in fails do
		print("FAIL " .. msg)
	end
	process.exit(1)
end
