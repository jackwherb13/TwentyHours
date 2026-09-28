-- ServerScriptService.RACBuild
-- Script, NOT a ModuleScript, NOT a LocalScript.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local function banner(text, bad)
	warn("[RAC] " .. text)
	local old = StarterGui:FindFirstChild("RACBuildStatus")
	if old then
		old:Destroy()
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "RACBuildStatus"
	gui.ResetOnSpawn = false
	gui.Parent = StarterGui
	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = bad and Color3.fromRGB(110, 16, 16) or Color3.fromRGB(0, 70, 36)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextWrapped = true
	label.Size = UDim2.new(0.72, 0, 0.22, 0)
	label.Position = UDim2.new(0.14, 0, 0.06, 0)
	label.Text = text
	label.Parent = gui
end

local rac = ReplicatedStorage:FindFirstChild("RAC")
local modules = rac and rac:FindFirstChild("Modules")
if not modules then
	banner("Missing folder ReplicatedStorage.RAC.Modules. The map was not built.", true)
	return
end

for _, name in ipairs({ "RACConfig", "RACUtil", "RACArchitecture", "RACProps", "BuildAll" }) do
	local inst = modules:FindFirstChild(name)
	if not inst then
		banner("Missing ModuleScript ReplicatedStorage.RAC.Modules." .. name, true)
		return
	end
	if not inst:IsA("ModuleScript") then
		banner(name .. " is a " .. inst.ClassName .. ". It must be a ModuleScript.", true)
		return
	end
end

local okRequire, BuildAllOrErr = pcall(function()
	return require(modules.BuildAll)
end)
if not okRequire then
	banner("Could not load BuildAll:\n" .. tostring(BuildAllOrErr), true)
	return
end

local okRun, builtOrErr = pcall(function()
	return BuildAllOrErr.run()
end)
if not okRun then
	banner("Build crashed:\n" .. tostring(builtOrErr), true)
	return
end

pcall(function()
	-- selene: allow(incorrect_standard_library_use)
	workspace.StreamingEnabled = false
end)

for _, inst in ipairs(workspace:GetDescendants()) do
	if inst:IsA("SpawnLocation") and inst.Name ~= "LobbySpawn" then
		inst.Neutral = false
		inst.Enabled = false
	end
end

local count = 0
for _, inst in ipairs(builtOrErr:GetDescendants()) do
	if inst:IsA("BasePart") then
		count += 1
	end
end
banner("RAC is built (" .. count .. " parts). You spawn in the lobby.", false)
