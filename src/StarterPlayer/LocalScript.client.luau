-- StarterPlayer.StarterPlayerScripts.PAClient
-- Subtitles for server PA announcements. Architecture stays the RAC; horror text is layered on top.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local rac = ReplicatedStorage:WaitForChild("RAC")
local remote = rac:WaitForChild("PA")

local gui = Instance.new("ScreenGui")
gui.Name = "RACPA"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local label = Instance.new("TextLabel")
label.Name = "Subtitle"
label.AnchorPoint = Vector2.new(0.5, 1)
label.Position = UDim2.new(0.5, 0, 0.86, 0)
label.Size = UDim2.new(0.7, 0, 0.12, 0)
label.BackgroundTransparency = 0.35
label.BackgroundColor3 = Color3.fromRGB(8, 10, 8)
label.TextColor3 = Color3.fromRGB(255, 214, 120)
label.Font = Enum.Font.GothamMedium
label.TextScaled = true
label.TextWrapped = true
label.Visible = false
label.Parent = gui

local hideToken = 0
remote.OnClientEvent:Connect(function(message)
	hideToken += 1
	local token = hideToken
	label.Text = message
	label.Visible = true
	task.delay(4.5, function()
		if hideToken == token then
			label.Visible = false
		end
	end)
end)
