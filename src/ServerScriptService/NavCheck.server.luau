--!strict
-- Dev-only PathfindingService walk between walkthrough rooms.
-- Disabled by default. Enable with:
--   workspace.RAC:SetAttribute("NavCheck", true)
-- or this script's Enabled attribute true, then run a playtest.
local PathfindingService = game:GetService("PathfindingService")
local CollectionService = game:GetService("CollectionService")

-- Rectangle centers land inside the desk, a floor hole, or a stall. These are
-- the walkable hips used once the matching Zone exists.
local SAMPLE = {
	lobby = Vector3.new(0, 5, -3),
	competition_gym = Vector3.new(-136, 5, -232.8),
	south_gym = Vector3.new(-166.8, 5, -7.5),
	fitness_center = Vector3.new(-35.8, 5, -139.2),
	training_room = Vector3.new(-221, 5, -165),
	locker_volleyball = Vector3.new(-210, 5, -128),
	public_locker = Vector3.new(-110, 5, -22),
	racquetball_1 = Vector3.new(-285, 25, -70),
	basketball_approach = Vector3.new(-347.5, 25, -112.5),
	cage_gym = Vector3.new(-288.2, 25, -156.2),
	stair_main_L1 = Vector3.new(6, 5, -24.2),
	stair_main_L2 = Vector3.new(-16, 25, -44),
}

local KEY = {
	"lobby",
	"competition_gym",
	"south_gym",
	"fitness_center",
	"training_room",
	"locker_volleyball",
	"public_locker",
	"racquetball_1",
	"basketball_approach",
	"cage_gym",
	"stair_main_L1",
	"stair_main_L2",
}

local function enabled(): boolean
	if script:GetAttribute("Enabled") == true then
		return true
	end
	local rac = workspace:FindFirstChild("RAC")
	return rac ~= nil and rac:GetAttribute("NavCheck") == true
end

local function zonesPresent(): { [string]: boolean }
	local found: { [string]: boolean } = {}
	for _, inst in CollectionService:GetTagged("Zone") do
		local id = inst:GetAttribute("id")
		if type(id) ~= "string" then
			continue
		end
		local key = id
		if id == "stair_main" then
			key = if inst:GetAttribute("level") == 2 then "stair_main_L2" else "stair_main_L1"
		end
		if SAMPLE[key] then
			found[key] = true
		end
	end
	return found
end

-- Tags.apply bakes NavCheck=false. A play session can flip it true before this deadline.
task.spawn(function()
	local deadline = os.clock() + 8
	while not enabled() and os.clock() < deadline do
		task.wait(0.25)
	end
	if not enabled() then
		return
	end
	local present = zonesPresent()
	local pts: { [string]: Vector3 } = {}
	local names = {}
	for _, id in KEY do
		if present[id] then
			pts[id] = SAMPLE[id]
			table.insert(names, id)
		else
			warn("[NavCheck] missing zone " .. id)
		end
	end
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 6,
		AgentCanJump = true,
		AgentJumpHeight = 16,
		AgentMaxSlope = 45,
		WaypointSpacing = 4,
		Costs = { Door = 1, Stairs = 1 },
	})
	local lines = { "# NavCheck", "" }
	local fail = 0
	local pass = 0
	for i = 1, #names do
		for j = 1, #names do
			if i == j then
				continue
			end
			local a, b = names[i], names[j]
			local ok, err = pcall(function()
				path:ComputeAsync(pts[a], pts[b])
			end)
			local status = if ok then tostring(path.Status) else tostring(err)
			local row = `{a} -> {b}: {status}`
			if ok and path.Status == Enum.PathStatus.Success then
				pass += 1
				print("[NavCheck] PASS " .. row)
			else
				fail += 1
				local from, to = pts[a], pts[b]
				warn(`[NavCheck] FAIL {row} from=({from.X},{from.Y},{from.Z}) to=({to.X},{to.Y},{to.Z})`)
			end
			table.insert(lines, row)
		end
	end
	print(`[NavCheck] done pass={pass} fail={fail}`)
	local folder = workspace:FindFirstChild("RAC")
	if folder then
		local report = folder:FindFirstChild("NavCheckReport")
		if report == nil then
			report = Instance.new("StringValue")
			report.Name = "NavCheckReport"
			report.Parent = folder
		end
		if report:IsA("StringValue") then
			report.Value = table.concat(lines, "\n")
		end
	end
end)
