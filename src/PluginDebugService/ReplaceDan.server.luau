-- Runs in Studio edit mode (not when you press Play) and replaces Dan in the open place.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

if not RunService:IsStudio() or not RunService:IsEdit() then
	return
end

local build = require(ReplicatedStorage:WaitForChild("Characters"):WaitForChild("StJBuild"))

local function replaceAll()
	local found = false
	for _, inst in workspace:GetDescendants() do
		if inst.Name == "Dan" and inst:IsA("Model") and inst:FindFirstChildOfClass("Humanoid") then
			found = true
			build.swap(inst)
		end
	end
	if found then
		ChangeHistoryService:SetWaypoint("Replace Dan with ST·J trainer")
	end
end

replaceAll()
workspace.DescendantAdded:Connect(function(inst)
	if inst.Name == "Dan" and inst:IsA("Model") then
		task.defer(function()
			if inst.Parent and inst:FindFirstChildOfClass("Humanoid") then
				build.swap(inst)
			end
		end)
	end
end)
