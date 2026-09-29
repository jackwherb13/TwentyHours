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
function Stairs.build(parent: Instance, level: Blueprint.Level, data: Blueprint.Data)
	for _, stair in level.stairs do
		-- Stairs are emitted once, by their source level.
		if stair.fromLevel ~= level.level then
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
