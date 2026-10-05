-- Play / published-server fallback. In Studio edit mode, ReplaceDan under
-- PluginDebugService already swaps Dan so you can see him without pressing Play.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local build = require(ReplicatedStorage:WaitForChild("Characters"):WaitForChild("StJBuild"))

local function consider(inst: Instance)
	if inst.Name == "Dan" and inst:IsA("Model") then
		task.defer(function()
			if inst.Parent then
				build.swap(inst)
			end
		end)
	end
end

for _, inst in workspace:GetDescendants() do
	consider(inst)
end
workspace.DescendantAdded:Connect(consider)
