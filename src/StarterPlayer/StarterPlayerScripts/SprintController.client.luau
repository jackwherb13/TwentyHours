-- Sprint meter + speed boost so the player can outrun CoachVillain in short bursts.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local MAX_STAMINA = 100
local DRAIN_RATE = 26 -- per second while sprinting and moving
local REGEN_RATE = 16 -- per second while not sprinting
local SPRINT_MULTIPLIER = 1.6
local MIN_STAMINA_TO_RESTART = 15 -- must regen above this before sprint can re-engage after hitting 0

local stamina = MAX_STAMINA
local sprinting = false
local canSprint = true
local baseWalkSpeed = 16

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "SprintMeterGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local barBack = Instance.new("Frame")
barBack.Name = "StaminaBarBack"
barBack.AnchorPoint = Vector2.new(0.5, 1)
barBack.Position = UDim2.new(0.5, 0, 1, -34)
barBack.Size = UDim2.new(0, 200, 0, 6)
barBack.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
barBack.BackgroundTransparency = 0.85
barBack.BorderSizePixel = 0
barBack.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = barBack

local strokeOuter = Instance.new("UIStroke")
strokeOuter.Color = Color3.fromRGB(255, 255, 255)
strokeOuter.Transparency = 0.75
strokeOuter.Thickness = 1
strokeOuter.Parent = barBack

local barFill = Instance.new("Frame")
barFill.Name = "StaminaFill"
barFill.Size = UDim2.new(1, 0, 1, 0)
barFill.Position = UDim2.new(0, 0, 0, 0)
barFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
barFill.BackgroundTransparency = 0.15
barFill.BorderSizePixel = 0
barFill.Parent = barBack

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = barFill

local label = Instance.new("TextLabel")
label.Name = "SprintLabel"
label.BackgroundTransparency = 1
label.Size = UDim2.new(0, 40, 0, 14)
label.AnchorPoint = Vector2.new(0.5, 1)
label.Position = UDim2.new(0.5, 0, 1, -20)
label.Text = "\226\128\148" -- em dash
label.Font = Enum.Font.SourceSansBold
label.TextSize = 16
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextTransparency = 0.35
label.TextStrokeTransparency = 1
label.Parent = gui

local sprintButton = Instance.new("TextButton")
sprintButton.Name = "SprintButton"
sprintButton.AnchorPoint = Vector2.new(1, 1)
sprintButton.Position = UDim2.new(1, -24, 1, -110)
sprintButton.Size = UDim2.new(0, 88, 0, 88)
sprintButton.BackgroundColor3 = Color3.fromRGB(40, 6, 8)
sprintButton.BackgroundTransparency = 0.35
sprintButton.Text = "RUN"
sprintButton.Font = Enum.Font.SourceSansBold
sprintButton.TextSize = 18
sprintButton.TextColor3 = Color3.fromRGB(230, 210, 210)
sprintButton.AutoButtonColor = false
sprintButton.Parent = gui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(1, 0)
btnCorner.Parent = sprintButton

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(120, 20, 24)
btnStroke.Thickness = 2
btnStroke.Parent = sprintButton

-- character tracking
local character = player.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")

local function onCharacterAdded(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	baseWalkSpeed = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or 16
	stamina = MAX_STAMINA
	sprinting = false
	canSprint = true
end
player.CharacterAdded:Connect(onCharacterAdded)
if character then
	onCharacterAdded(character)
end

local function setSprinting(state)
	if state and not canSprint then
		return
	end
	sprinting = state
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		setSprinting(true)
	end
end)
UserInputService.InputEnded:Connect(function(input, _processed)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		setSprinting(false)
	end
end)

sprintButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		setSprinting(true)
	end
end)
sprintButton.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		setSprinting(false)
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	local moving = humanoid.MoveDirection.Magnitude > 0.1

	if sprinting and moving and stamina > 0 then
		stamina = math.max(0, stamina - DRAIN_RATE * dt)
		humanoid.WalkSpeed = baseWalkSpeed * SPRINT_MULTIPLIER
		if stamina <= 0 then
			canSprint = false
			sprinting = false
		end
	else
		stamina = math.min(MAX_STAMINA, stamina + REGEN_RATE * dt)
		humanoid.WalkSpeed = baseWalkSpeed
		if not canSprint and stamina >= MIN_STAMINA_TO_RESTART then
			canSprint = true
		end
	end

	local frac = stamina / MAX_STAMINA
	barFill.Size = UDim2.new(frac, 0, 1, 0)
	barFill.BackgroundTransparency = frac < 0.25 and 0 or 0.15
end)
