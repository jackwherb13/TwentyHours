--!strict
-- Dev-only PathfindingService walk between walkthrough rooms.
-- Disabled by default. Enable with:
--   workspace.RAC:SetAttribute("NavCheck", true)
-- or this script's Enabled attribute true, then run a playtest.
local PathfindingService = game:GetService("PathfindingService")
local CollectionService = game:GetService("CollectionService")

if script:GetAttribute("Enabled") ~= true then
	local rac = workspace:FindFirstChild("RAC")
	if rac == nil or rac:GetAttribute("NavCheck") ~= true then
		return
	end
end

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
	"stair_main",
}

local function hip(part: BasePart): Vector3
	return part.Position + Vector3.new(0, 3, 0)
end

local function rooms(): { [string]: Vector3 }
	local found: { [string]: Vector3 } = {}
	for _, inst in CollectionService:GetTagged("Zone") do
		local id = inst:GetAttribute("id")
		if type(id) == "string" and table.find(KEY, id) and inst:IsA("BasePart") then
			if not found[id] then
				found[id] = hip(inst)
			end
		end
	end
	return found
end

task.defer(function()
	task.wait(1)
	local pts = rooms()
	local names = {}
	for _, id in KEY do
		if pts[id] then
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
