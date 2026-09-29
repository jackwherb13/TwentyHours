-- CoachVillain client effects. Parent: StarterPlayer.StarterPlayerScripts.CoachVillainClient
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local remotes = ReplicatedStorage:FindFirstChild("CoachVillainRemotes")
if remotes == nil then
	return
end
local ChaseStarted = remotes:WaitForChild("ChaseStarted")
local ChaseEnded = remotes:WaitForChild("ChaseEnded")
local CatchStarted = remotes:WaitForChild("CatchStarted")

-- REPLACE after you upload audio. rbxassetid://0 is ignored safely.
local CHASE_MUSIC_ID = "rbxassetid://9114353372" -- Evil Drone Deep Unsetting Rumbly Keening (Pro Sound Effects catalog, free, licensed)
local JUMPSCARE_ID = "rbxassetid://130285917830946" -- Scream_Jumpscare (Roblox catalog, free)
local PLAYER_CAUGHT_ANIM = "rbxassetid://0" -- REPLACE_WITH_YOUR_PLAYER_CAUGHT_ANIM_ID

local gui = player:WaitForChild("PlayerGui"):FindFirstChild("CoachVillainGui")
if not gui then
	gui = Instance.new("ScreenGui")
	gui.Name = "CoachVillainGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
end
local fade = gui:FindFirstChild("Fade")
if not fade then
	fade = Instance.new("Frame")
	fade.Name = "Fade"
	fade.BackgroundColor3 = Color3.new(0, 0, 0)
	fade.BackgroundTransparency = 1
	fade.BorderSizePixel = 0
	fade.Size = UDim2.fromScale(1, 1)
	fade.ZIndex = 50
	fade.Parent = gui
end

local function tweenFade(trans, dur)
	TweenService:Create(fade, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = trans,
	}):Play()
end

local function restoreCamera()
	camera.CameraType = Enum.CameraType.Custom
	pcall(function()
		camera.FieldOfView = 70
	end)
	tweenFade(1, 0.35)
end

local chaseSound = SoundService:FindFirstChild("CoachVillainChaseMusic")
if not chaseSound then
	chaseSound = Instance.new("Sound")
	chaseSound.Name = "CoachVillainChaseMusic"
	chaseSound.Looped = true
	chaseSound.Volume = 0
	chaseSound.Parent = SoundService
end
chaseSound.SoundId = CHASE_MUSIC_ID

local scareSound = SoundService:FindFirstChild("CoachVillainJumpscare")
if not scareSound then
	scareSound = Instance.new("Sound")
	scareSound.Name = "CoachVillainJumpscare"
	scareSound.Volume = 0.9
	scareSound.Parent = SoundService
end
scareSound.SoundId = JUMPSCARE_ID

local musicTween
local chasing = false
local function fadeMusic(vol, dur)
	if musicTween then
		musicTween:Cancel()
	end
	musicTween = TweenService:Create(chaseSound, TweenInfo.new(dur, Enum.EasingStyle.Quad), { Volume = vol })
	musicTween:Play()
end

local function hasId(id)
	return type(id) == "string" and id ~= "" and id ~= "rbxassetid://0"
end

ChaseStarted.OnClientEvent:Connect(function()
	if chasing then
		return
	end
	chasing = true
	if not hasId(CHASE_MUSIC_ID) then
		return
	end
	if not chaseSound.IsPlaying then
		chaseSound:Play()
	end
	fadeMusic(0.45, 0.4)
end)

ChaseEnded.OnClientEvent:Connect(function()
	if not chasing then
		return
	end
	chasing = false
	fadeMusic(0, 0.8)
	task.delay(0.85, function()
		if not chasing and chaseSound.IsPlaying then
			chaseSound:Stop()
		end
	end)
end)

local shakeConn
local function stopShake()
	if shakeConn then
		shakeConn:Disconnect()
		shakeConn = nil
	end
end

CatchStarted.OnClientEvent:Connect(function(villain)
	chasing = false
	fadeMusic(0, 0.12)
	if hasId(JUMPSCARE_ID) then
		scareSound:Play()
	end

	local character = player.Character
	if character and hasId(PLAYER_CAUGHT_ANIM) then
		local hum = character:FindFirstChildOfClass("Humanoid")
		local animator = hum and hum:FindFirstChildOfClass("Animator")
		if animator then
			local a = Instance.new("Animation")
			a.AnimationId = PLAYER_CAUGHT_ANIM
			local ok, track = pcall(function()
				return animator:LoadAnimation(a)
			end)
			if ok and track then
				track.Priority = Enum.AnimationPriority.Action4
				track:Play(0.05)
			end
		end
	end

	local vHead = villain and (villain:FindFirstChild("Head") or villain:FindFirstChild("HumanoidRootPart"))
	if not vHead then
		tweenFade(0, 0.4)
		return
	end

	camera.CameraType = Enum.CameraType.Scriptable
	pcall(function()
		camera.FieldOfView = 62
	end)
	local elapsed = 0
	stopShake()
	shakeConn = RunService.RenderStepped:Connect(function(dt)
		elapsed += dt
		local shake = math.noise(elapsed * 26, 1.7) * 0.11
		local push = math.clamp(elapsed / 1.15, 0, 1)
		local dist = 3.15 - push * 1.35
		camera.CFrame = CFrame.new(
			vHead.Position + vHead.CFrame.LookVector * dist + Vector3.new(shake, 0.18, shake * 0.35),
			vHead.Position
		)
		pcall(function()
			camera.FieldOfView = 62 - push * 8
		end)
	end)

	task.delay(2.35, function()
		tweenFade(0, 0.35)
	end)
	task.delay(3.1, function()
		stopShake()
	end)
end)

player.CharacterAdded:Connect(function(character)
	stopShake()
	restoreCamera()
	chasing = false
	fadeMusic(0, 0.1)
	if chaseSound.IsPlaying then
		chaseSound:Stop()
	end
	local hum = character:WaitForChild("Humanoid", 8)
	if hum then
		hum.WalkSpeed = 16
	end
end)
