--!strict
local Blueprint = require(script.Parent.Blueprint)
local Geometry = require(script.Parent.Geometry)
local Parts = require(script.Parent.Parts)
local Stairs = {}
local function beam(parent: Instance, name: string, a: Vector3, b: Vector3, width: number, height: number)
	local forward = (b - a).Unit
	local right = forward:Cross(Vector3.yAxis).Unit
	local up = right:Cross(forward)
	Parts.box(
		parent,
		name,
		Vector3.new(width, height, (b - a).Magnitude),
		CFrame.fromMatrix((a + b) / 2, right, up, -forward),
		"steel",
		false
	)
end
local function pointInside(poly: { { number } }, x: number, z: number): boolean
	local inside = false
	local j = #poly
	for i, a in poly do
		local b = poly[j]
		if (a[2] > z) ~= (b[2] > z) and x < (b[1] - a[1]) * (z - a[2]) / (b[2] - a[2]) + a[1] then
			inside = not inside
		end
		j = i
	end
	return inside
end

-- One straight run whose treads start at baseElevation, not necessarily at a level.
local function buildRun(group: Folder, flight: any)
	local base = flight.baseElevation or 0
	local rise = flight.rise
	local direction = Vector3.new(flight.direction[1], 0, flight.direction[2])
	direction = direction.Unit
	local side = Vector3.new(-direction.Z, 0, direction.X)
	local alongMin, alongMax = math.huge, -math.huge
	local sideMin, sideMax = math.huge, -math.huge
	for _, point in flight.polygon do
		local v = Vector3.new(point[1], 0, point[2])
		alongMin = math.min(alongMin, v:Dot(direction))
		alongMax = math.max(alongMax, v:Dot(direction))
		sideMin = math.min(sideMin, v:Dot(side))
		sideMax = math.max(sideMax, v:Dot(side))
	end
	local length = flight.risers * flight.run
	assert(
		length <= alongMax - alongMin + 0.001 and flight.width <= sideMax - sideMin + 0.001,
		`Flight {flight.id} does not fit its polygon`
	)
	local top = rise * flight.risers
	local origin = direction * alongMin + side * ((sideMin + sideMax) / 2) + Vector3.new(0, base, 0)
	local cf = CFrame.fromMatrix(origin, side, Vector3.yAxis, -direction)
	local folder = Geometry.folder(group, flight.id)
	for step = 1, flight.risers do
		local y = step * rise
		Parts.box(
			folder,
			`Tread_{step}`,
			Vector3.new(flight.width, 0.12, flight.run),
			cf * CFrame.new(0, y - 0.06, -(step - 0.5) * flight.run),
			"sealed_concrete"
		)
		Parts.box(
			folder,
			`Riser_{step}`,
			Vector3.new(flight.width, rise, 0.08),
			cf * CFrame.new(0, y - rise / 2, -(step - 1) * flight.run - 0.04),
			"sealed_concrete"
		)
	end
	for _, sign in { -1, 1 } do
		local x = sign * (flight.width / 2 - 0.1)
		beam(
			folder,
			"Stringer",
			cf:PointToWorldSpace(Vector3.new(x, 0, 0)),
			cf:PointToWorldSpace(Vector3.new(x, top - 0.2, -length)),
			0.18,
			0.3
		)
		beam(
			folder,
			"Handrail",
			cf:PointToWorldSpace(Vector3.new(x, 3, 0)),
			cf:PointToWorldSpace(Vector3.new(x, top + 3, -length)),
			0.12,
			0.12
		)
		local posts = math.ceil(length / 4)
		for index = 0, posts do
			local fraction = index / posts
			Parts.box(
				folder,
				"RailPost",
				Vector3.new(0.12, 3, 0.12),
				cf * CFrame.new(x, fraction * top + 1.5, -fraction * length),
				"steel",
				false
			)
		end
	end
end

-- A rail on the stair-room boundary sits in the wall or in the exit door.
local function edgeOnRoom(poly: any, ax: number, az: number, bx: number, bz: number): boolean
	if type(poly) ~= "table" then
		return false
	end
	local function near(x: number, z: number): boolean
		local n = #poly
		for i = 1, n do
			local p = poly[i]
			local q = poly[(i % n) + 1]
			local ex, ez = q[1] - p[1], q[2] - p[2]
			local len2 = ex * ex + ez * ez
			if len2 > 1e-6 then
				local t = math.clamp(((x - p[1]) * ex + (z - p[2]) * ez) / len2, 0, 1)
				local dx = x - (p[1] + ex * t)
				local dz = z - (p[2] + ez * t)
				if dx * dx + dz * dz <= 0.04 then
					return true
				end
			end
		end
		return false
	end
	return near(ax, az) and near(bx, bz)
end

local function buildLanding(group: Folder, landing: any, flights: { any }, roomPoly: any)
	local x0, x1 = math.huge, -math.huge
	local z0, z1 = math.huge, -math.huge
	for _, point in landing.polygon do
		x0, x1 = math.min(x0, point[1]), math.max(x1, point[1])
		z0, z1 = math.min(z0, point[2]), math.max(z1, point[2])
	end
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	Parts.box(
		group,
		landing.id,
		Vector3.new(x1 - x0, 0.4, z1 - z0),
		CFrame.new(cx, landing.elevation - 0.2, cz),
		"sealed_concrete"
	)
	local edges = {
		{ x0, z0, x1, z0 },
		{ x1, z0, x1, z1 },
		{ x1, z1, x0, z1 },
		{ x0, z1, x0, z0 },
	}
	for index, edge in edges do
		local mx, mz = (edge[1] + edge[3]) / 2, (edge[2] + edge[4]) / 2
		local ox, oz = mx + (mx - cx) * 0.15, mz + (mz - cz) * 0.15
		local meetsFlight = false
		for _, flight in flights do
			if pointInside(flight.polygon, ox, oz) then
				meetsFlight = true
				break
			end
		end
		if meetsFlight or edgeOnRoom(roomPoly, edge[1], edge[2], edge[3], edge[4]) then
			continue
		end
		local length = math.max(math.abs(edge[3] - edge[1]), math.abs(edge[4] - edge[2]))
		if length < 1 then
			continue
		end
		beam(
			group,
			`LandingRail_{index}`,
			Vector3.new(edge[1], landing.elevation + 3, edge[2]),
			Vector3.new(edge[3], landing.elevation + 3, edge[4]),
			0.12,
			0.12
		)
	end
end

function Stairs.build(parent: Instance, level: Blueprint.Level, data: Blueprint.Data)
	for _, stair in level.stairs do
		-- Stairs are emitted once, by their source level.
		if stair.fromLevel ~= level.level then
			continue
		end
		local flights = (stair :: any).flights
		if type(flights) == "table" and #flights > 0 then
			local low = Blueprint.elevation(data, stair.fromLevel)
			local high = Blueprint.elevation(data, stair.toLevel)
			local group = Geometry.folder(parent, stair.id)
			group:SetAttribute("FromElevation", low)
			group:SetAttribute("ToElevation", high)
			for _, flight in flights do
				assert(flight.risers > 0 and flight.risers % 1 == 0 and flight.run > 0 and flight.width > 0, flight.id)
				buildRun(group, flight)
			end
			local landings = (stair :: any).landings
			if type(landings) == "table" then
				for _, landing in landings do
					buildLanding(group, landing, flights, stair.polygon)
				end
			end
			continue
		end
		local low = Blueprint.elevation(data, stair.fromLevel)
		local high = Blueprint.elevation(data, stair.toLevel)
		assert(
			high > low and stair.risers > 0 and stair.risers % 1 == 0 and stair.run > 0 and stair.width > 0,
			`Invalid stair {stair.id}`
		)
		-- Survey values are commonly rounded (e.g. .583 ft); distribute that residual over all risers.
		assert(
			math.abs(stair.rise * stair.risers - (high - low)) <= 0.05,
			`Stair {stair.id} rise disagrees with elevations`
		)
		local rise = (high - low) / stair.risers
		local direction = Vector3.new(stair.direction[1], 0, stair.direction[2])
		assert(direction.Magnitude > 0, "Missing stair direction")
		direction = direction.Unit
		local side = Vector3.new(-direction.Z, 0, direction.X)
		local alongMin, alongMax = math.huge, -math.huge
		local sideMin, sideMax = math.huge, -math.huge
		for _, point in stair.polygon do
			local v = Vector3.new(point[1], 0, point[2])
			alongMin = math.min(alongMin, v:Dot(direction))
			alongMax = math.max(alongMax, v:Dot(direction))
			sideMin = math.min(sideMin, v:Dot(side))
			sideMax = math.max(sideMax, v:Dot(side))
		end
		local length = stair.risers * stair.run
		assert(
			length <= alongMax - alongMin + 0.001 and stair.width <= sideMax - sideMin + 0.001,
			`Stair {stair.id} does not fit its polygon`
		)
		local origin = direction * alongMin + side * ((sideMin + sideMax) / 2) + Vector3.new(0, low, 0)
		local cf = CFrame.fromMatrix(origin, side, Vector3.yAxis, -direction)
		local group = Geometry.folder(parent, stair.id)
		group:SetAttribute("FromElevation", low)
		group:SetAttribute("ToElevation", high)
		group:SetAttribute("EffectiveRise", rise)
		for step = 1, stair.risers do
			local y = step * rise
			Parts.box(
				group,
				`Tread_{step}`,
				Vector3.new(stair.width, 0.12, stair.run),
				cf * CFrame.new(0, y - 0.06, -(step - 0.5) * stair.run),
				"sealed_concrete"
			)
			Parts.box(
				group,
				`Riser_{step}`,
				Vector3.new(stair.width, rise, 0.08),
				cf * CFrame.new(0, y - rise / 2, -(step - 1) * stair.run - 0.04),
				"sealed_concrete"
			)
		end
		for _, sign in { -1, 1 } do
			local x = sign * (stair.width / 2 - 0.1)
			beam(
				group,
				"Stringer",
				cf:PointToWorldSpace(Vector3.new(x, 0, 0)),
				cf:PointToWorldSpace(Vector3.new(x, high - low - 0.2, -length)),
				0.18,
				0.3
			)
			beam(
				group,
				"Handrail",
				cf:PointToWorldSpace(Vector3.new(x, 3, 0)),
				cf:PointToWorldSpace(Vector3.new(x, high - low + 3, -length)),
				0.12,
				0.12
			)
			local posts = math.ceil(length / 4)
			for index = 0, posts do
				local fraction = index / posts
				Parts.box(
					group,
					"RailPost",
					Vector3.new(0.12, 3, 0.12),
					cf * CFrame.new(x, fraction * (high - low) + 1.5, -fraction * length),
					"steel",
					false
				)
			end
		end
	end
end
return Stairs
