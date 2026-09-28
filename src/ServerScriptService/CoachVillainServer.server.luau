-- CoachVillain server AI. Parent: ServerScriptService.CoachVillainServer
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CONFIG = {
	Debug = false,
	VillainWalkSpeed = 24.5, -- 1.75x faster than original 14
	VillainIdleSpeed = 14, -- scaled 1.75x with it
	PlayerWalkSpeed = 16,
	DetectionRadius = 150,
	CatchDistance = 3.5,
	PathRefreshTime = 0.5,
	RepathDistance = 5,
	CatchDuration = 3,
	RespawnDelay = 3,
	DirectChaseDistance = 28,
	LoseTargetRadius = 220,
	HeightReach = 8,
	StuckSeconds = 2.0,
	StuckMoveThreshold = 1.0,
	PatrolEnabled = true, -- wander randomly when he hasn't spotted anyone
	PatrolRadius = 36,
	PatrolWaitMin = 1.5,
	PatrolWaitMax = 3.5,
	AgentRadius = 2,
	AgentHeight = 6,
	AgentCanJump = true,
	AgentJumpHeight = 16,
	AgentMaxSlope = 45,
	RecoverTime = 1.25,
}

-- REPLACE these after you publish clips. Leave at 0 and the AI still runs.
local ANIMATIONS = {
	Idle = "rbxassetid://0", -- REPLACE_WITH_YOUR_IDLE_ANIM_ID
	Walk = "rbxassetid://913402848", -- Roblox default R15 run cycle
	Run = "rbxassetid://913402848", -- Roblox default R15 run cycle
	Catch = "rbxassetid://0", -- REPLACE_WITH_YOUR_CATCH_ANIM_ID
	Eat = "rbxassetid://0", -- REPLACE_WITH_YOUR_EAT_ANIM_ID
}

local SOUNDS = {
	Detect = "rbxassetid://0", -- REPLACE_WITH_YOUR_DETECT_SOUND_ID
	ChaseMusic = "rbxassetid://0", -- unused on server; client owns music
	Grab = "rbxassetid://0", -- REPLACE_WITH_YOUR_GRAB_SOUND_ID
	Bite = "rbxassetid://0", -- REPLACE_WITH_YOUR_BITE_SOUND_ID
	Gulp = "rbxassetid://0", -- REPLACE_WITH_YOUR_GULP_SOUND_ID
	Jumpscare = "rbxassetid://0", -- unused on server; client owns jumpscare
	Footstep = "rbxassetid://0", -- REPLACE_WITH_YOUR_FOOTSTEP_SOUND_ID
}

local STATE = {
	IDLE = "IDLE",
	PATROL = "PATROL",
	CHASE = "CHASE",
	CATCH = "CATCH",
	EAT = "EAT",
	RECOVER = "RECOVER",
}

local function dbg(...)
	if CONFIG.Debug then
		print("[CoachVillain]", ...)
	end
end

local remotes = ReplicatedStorage:WaitForChild("CoachVillainRemotes")
local ChaseStarted = remotes:WaitForChild("ChaseStarted")
local ChaseEnded = remotes:WaitForChild("ChaseEnded")
local CatchStarted = remotes:WaitForChild("CatchStarted")

local model = workspace:WaitForChild("Jay")
local humanoid = model:WaitForChild("Humanoid")
local root = model:WaitForChild("HumanoidRootPart")
local head = model:FindFirstChild("Head") or root
model.PrimaryPart = root

humanoid.WalkSpeed = CONFIG.VillainWalkSpeed
humanoid.JumpPower = 50
humanoid.AutoJumpEnabled = true
humanoid.BreakJointsOnDeath = false
humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
humanoid.HipHeight = 4.045 -- was 0, which sank him into the floor while pathing

-- RACBuild runs in a separate Script and may not be finished yet; poll briefly for the main
-- entrance so Jay can be placed outside the building instead of wherever he was left sitting.
do
	local mainEntrance
	for _ = 1, 100 do
		mainEntrance = workspace:FindFirstChild("MainEntrance", true)
		if mainEntrance then
			break
		end
		task.wait(0.1)
	end
	if mainEntrance then
		local doorCF = mainEntrance:IsA("Model") and mainEntrance:GetPivot() or mainEntrance.CFrame
		-- LookVector points outward (away from the lobby); stand him 25 studs out from the door,
		-- spawned a bit high so he drops cleanly onto the exterior ground/stairs.
		local outside = doorCF.Position + doorCF.LookVector * 25
		root.CFrame = CFrame.new(outside.X, outside.Y + 8, outside.Z)
	end
end

for _, part in ipairs(model:GetDescendants()) do
	if part:IsA("BasePart") then
		part.Anchored = false
		pcall(function()
			part:SetNetworkOwner(nil)
		end)
		pcall(function()
			part.CollisionGroup = "CoachVillain"
		end)
	end
end

local function tagPlayerCharacter(character)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			pcall(function()
				part.CollisionGroup = "CoachPlayers"
			end)
		end
	end
	local hum = character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = CONFIG.PlayerWalkSpeed
	end
end

for _, plr in ipairs(Players:GetPlayers()) do
	if plr.Character then
		tagPlayerCharacter(plr.Character)
	end
	plr.CharacterAdded:Connect(tagPlayerCharacter)
end
Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(tagPlayerCharacter)
end)

local animator = humanoid:FindFirstChildOfClass("Animator")
if not animator then
	animator = Instance.new("Animator")
	animator.Parent = humanoid
end

local function loadAnim(id, priority, looped)
	if type(id) ~= "string" or id == "" or id == "rbxassetid://0" then
		return nil
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if not ok or not track then
		return nil
	end
	track.Priority = priority
	track.Looped = looped
	return track
end

local tracks = {
	Idle = loadAnim(ANIMATIONS.Idle, Enum.AnimationPriority.Idle, true),
	Walk = loadAnim(ANIMATIONS.Walk, Enum.AnimationPriority.Movement, true),
	Run = loadAnim(ANIMATIONS.Run, Enum.AnimationPriority.Movement, true),
	Catch = loadAnim(ANIMATIONS.Catch, Enum.AnimationPriority.Action4, false),
	Eat = loadAnim(ANIMATIONS.Eat, Enum.AnimationPriority.Action4, false),
}

local loco
local function playLoco(track)
	if loco == track then
		return
	end
	if loco then
		loco:Stop(0.12)
	end
	loco = track
	if track then
		track:Play(0.12)
	end
end

local function stopLoco()
	if loco then
		loco:Stop(0.08)
		loco = nil
	end
end

-- keep the leg-cycle rate matched to actual movement speed so he doesn't slide/skate at higher speeds
humanoid.Running:Connect(function(speed)
	if loco then
		loco:AdjustSpeed(math.clamp(speed / 16, 0.5, 3))
	end
end)

local function ensureSound(name, id, vol)
	local s = root:FindFirstChild(name)
	if not s then
		s = Instance.new("Sound")
		s.Name = name
		s.Parent = root
	end
	s.SoundId = id
	s.Volume = vol or 0.6
	s.RollOffMaxDistance = 80
	return s
end

local sndDetect = ensureSound("Detect", SOUNDS.Detect, 0.7)
local sndGrab = ensureSound("Grab", SOUNDS.Grab, 0.8)
local sndBite = ensureSound("Bite", SOUNDS.Bite, 0.8)
local sndGulp = ensureSound("Gulp", SOUNDS.Gulp, 0.85)
local sndStep = ensureSound("Footstep", SOUNDS.Footstep, 0.25)

local function playIfSet(sound)
	if sound and sound.SoundId ~= "" and sound.SoundId ~= "rbxassetid://0" then
		sound:Play()
	end
end

local currentState = STATE.IDLE
local targetPlayer = nil
local busy = false
local waypoints = {}
local wpIndex = 1
local lastPathAt = 0
local lastPos = root.Position
local lastMovedAt = os.clock()
local homePos = root.Position
local patrolDest = nil
local rng = Random.new()

model:SetAttribute("State", currentState)

local function setState(s)
	if currentState == s then
		return
	end
	currentState = s
	model:SetAttribute("State", s)
	dbg("State:", s)
end

local function notifyChase(player, on)
	if not player then
		return
	end
	if on then
		ChaseStarted:FireClient(player)
	else
		ChaseEnded:FireClient(player)
	end
end

local function setTarget(player)
	if targetPlayer == player then
		return
	end
	if targetPlayer then
		notifyChase(targetPlayer, false)
	end
	targetPlayer = player
	if player then
		notifyChase(player, true)
		playIfSet(sndDetect)
		dbg("Target acquired:", player.Name)
	else
		dbg("Target cleared")
	end
end

local function aliveChar(character)
	if not character then
		return false
	end
	local hum = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	return hum ~= nil and hrp ~= nil and hum.Health > 0
end

local function validPlayer(player)
	return player ~= nil and player.Parent == Players and aliveChar(player.Character)
end

local function getHRP(player)
	return player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function lineOfSight(targetHRP)
	local origin = head.Position
	local delta = targetHRP.Position - origin
	if delta.Magnitude > CONFIG.DetectionRadius then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model, targetHRP.Parent }
	params.IgnoreWater = true
	return workspace:Raycast(origin, delta, params) == nil
end

-- Only counts as "spotting" a player if there's an actual unbroken line of sight to them
-- (used to START a chase -- eye contact -- not to keep one going, see the main loop below).
local function nearestPlayer()
	local best, bestD = nil, CONFIG.DetectionRadius
	for _, player in ipairs(Players:GetPlayers()) do
		if validPlayer(player) then
			local hrp = getHRP(player)
			local d = (hrp.Position - root.Position).Magnitude
			if d <= bestD and lineOfSight(hrp) then
				best = player
				bestD = d
			end
		end
	end
	return best
end

local pathObj = PathfindingService:CreatePath({
	AgentRadius = CONFIG.AgentRadius,
	AgentHeight = CONFIG.AgentHeight,
	AgentCanJump = CONFIG.AgentCanJump,
	AgentJumpHeight = CONFIG.AgentJumpHeight,
	AgentMaxSlope = CONFIG.AgentMaxSlope,
	WaypointSpacing = 4,
	Costs = { Water = 25 },
})

local function computePath(dest)
	local ok = pcall(function()
		pathObj:ComputeAsync(root.Position, dest)
	end)
	if not ok or pathObj.Status ~= Enum.PathStatus.Success then
		waypoints = {}
		wpIndex = 1
		dbg("Path failed, recalculating later")
		return false
	end
	waypoints = pathObj:GetWaypoints()
	wpIndex = math.min(2, #waypoints)
	lastPathAt = os.clock()
	return #waypoints > 0
end

local function followPath()
	if wpIndex > #waypoints then
		return false
	end
	local wp = waypoints[wpIndex]
	if not wp then
		return false
	end
	if wp.Action == Enum.PathWaypointAction.Jump then
		humanoid.Jump = true
	end
	humanoid:MoveTo(wp.Position)
	local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
	local wflat = Vector3.new(wp.Position.X, 0, wp.Position.Z)
	if (flat - wflat).Magnitude <= 3.5 then
		wpIndex += 1
	end
	return true
end

local function antiStuck()
	local now = os.clock()
	local moved = (root.Position - lastPos).Magnitude
	if moved > CONFIG.StuckMoveThreshold then
		lastPos = root.Position
		lastMovedAt = now
		return
	end
	if now - lastMovedAt < CONFIG.StuckSeconds then
		return
	end
	lastMovedAt = now
	lastPos = root.Position
	dbg("Anti-stuck: jump + repath")
	humanoid.Jump = true
	waypoints = {}
	wpIndex = 1
	lastPathAt = 0
end

local function face(targetHRP)
	local look = Vector3.new(targetHRP.Position.X, root.Position.Y, targetHRP.Position.Z)
	if (look - root.Position).Magnitude > 0.05 then
		root.CFrame = CFrame.lookAt(root.Position, look)
	end
end

local savedMove = {}
local function lockPlayer(player, locked)
	local character = player.Character
	if not character then
		return
	end
	local hum = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then
		return
	end
	if locked then
		savedMove[player] = {
			WalkSpeed = hum.WalkSpeed,
			JumpPower = hum.JumpPower,
			JumpHeight = hum.JumpHeight,
			AutoRotate = hum.AutoRotate,
		}
		hum.WalkSpeed = 0
		hum.JumpPower = 0
		hum.JumpHeight = 0
		hum.AutoRotate = false
		hum:Move(Vector3.zero)
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	else
		local saved = savedMove[player]
		if saved and hum.Health > 0 then
			hum.WalkSpeed = saved.WalkSpeed
			hum.JumpPower = saved.JumpPower
			hum.JumpHeight = saved.JumpHeight
			hum.AutoRotate = saved.AutoRotate
		end
		savedMove[player] = nil
	end
end

local function swallowVisual(player)
	local character = player.Character
	if not character then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.Massless = true
		elseif d:IsA("Accessory") or d:IsA("Hat") then
			for _, p in ipairs(d:GetDescendants()) do
				if p:IsA("BasePart") then
					p.Transparency = 1
					p.CanCollide = false
				end
			end
		end
	end
	local t0 = os.clock()
	local dur = 1.4
	while os.clock() - t0 < dur do
		if not player.Parent or not character.Parent or not hrp or not hrp.Parent then
			break
		end
		local a = (os.clock() - t0) / dur
		local mouth = head.Position + head.CFrame.LookVector * 1.15
		hrp.CFrame = CFrame.new(hrp.Position:Lerp(mouth, 0.18 + a * 0.25))
		for _, d in ipairs(character:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
				d.Transparency = math.clamp(a * 1.15, 0, 1)
			end
		end
		task.wait(0.04)
	end
end

local function runCatch(player)
	if busy then
		return
	end
	if not validPlayer(player) then
		return
	end
	local character = player.Character
	local targetHRP = getHRP(player)
	local targetHum = character and character:FindFirstChildOfClass("Humanoid")
	if not targetHRP or not targetHum then
		return
	end
	local dist = (targetHRP.Position - root.Position).Magnitude
	if dist > CONFIG.CatchDistance + 1.2 then
		return
	end
	if math.abs(targetHRP.Position.Y - root.Position.Y) > CONFIG.HeightReach then
		return
	end

	busy = true
	setState(STATE.CATCH)
	dbg("Catching:", player.Name)
	humanoid.WalkSpeed = 0
	humanoid:Move(Vector3.zero)
	stopLoco()
	lockPlayer(player, true)
	face(targetHRP)

	local stand = root.Position + root.CFrame.LookVector * 2.55
	targetHRP.CFrame = CFrame.lookAt(
		Vector3.new(stand.X, targetHRP.Position.Y, stand.Z),
		Vector3.new(root.Position.X, targetHRP.Position.Y, root.Position.Z)
	)

	CatchStarted:FireClient(player, model)
	playIfSet(sndGrab)
	if tracks.Catch then
		tracks.Catch:Play(0.05)
	end

	-- 0.0 grab already posed
	task.wait(0.5)
	if not validPlayer(player) then
		lockPlayer(player, false)
		busy = false
		setState(STATE.RECOVER)
		return
	end

	-- 1.0 lift toward face
	setState(STATE.EAT)
	if tracks.Eat then
		tracks.Eat:Play(0.05)
	end
	playIfSet(sndBite)
	targetHRP = getHRP(player)
	if targetHRP then
		local lift = head.Position + head.CFrame.LookVector * 1.35 + Vector3.new(0, 0.35, 0)
		targetHRP.CFrame = CFrame.new(lift, head.Position)
	end
	task.wait(0.5)

	-- 1.5-2.3 shrink / fade / pull
	swallowVisual(player)
	playIfSet(sndGulp)
	task.wait(0.35)
	-- 2.8 satisfied beat is the remaining eat clip
	task.wait(0.35)

	if validPlayer(player) then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Health = 0
		end
	end
	savedMove[player] = nil
	setTarget(nil)
	setState(STATE.RECOVER)
	dbg("Recovering")
	task.wait(CONFIG.RecoverTime)
	humanoid.WalkSpeed = CONFIG.VillainWalkSpeed
	busy = false
	waypoints = {}
	lastPathAt = 0
	setState(STATE.IDLE)
end

local function pickPatrol()
	local folder = workspace:FindFirstChild("CoachVillainPatrolPoints")
	if folder then
		local pts = {}
		for _, c in ipairs(folder:GetChildren()) do
			if c:IsA("BasePart") then
				table.insert(pts, c.Position)
			end
		end
		if #pts > 0 then
			return pts[rng:NextInteger(1, #pts)]
		end
	end
	local ang = rng:NextNumber(0, math.pi * 2)
	local rad = rng:NextNumber(8, CONFIG.PatrolRadius)
	return homePos + Vector3.new(math.cos(ang) * rad, 0, math.sin(ang) * rad)
end

task.spawn(function()
	while model.Parent do
		task.wait(0.12)
		if busy then
			continue
		end
		if humanoid.Health <= 0 then
			continue
		end

		pcall(function()
			root:SetNetworkOwner(nil)
		end)

		if validPlayer(targetPlayer) then
			-- Already latched onto someone after eye contact: keep hunting them down even if they
			-- duck out of sight for a moment, only give up once they're too far away (LoseTargetRadius).
			local hrp = getHRP(targetPlayer)
			local d = (hrp.Position - root.Position).Magnitude
			if d > CONFIG.LoseTargetRadius then
				setTarget(nil)
			end
		else
			if targetPlayer then
				setTarget(nil)
			end
			local spotted = nearestPlayer() -- requires real eye contact to acquire
			if spotted then
				setTarget(spotted)
			end
		end

		if targetPlayer then
			if currentState ~= STATE.CATCH and currentState ~= STATE.EAT and currentState ~= STATE.RECOVER then
				setState(STATE.CHASE)
			end
		else
			if currentState == STATE.CHASE then
				setState(CONFIG.PatrolEnabled and STATE.PATROL or STATE.IDLE)
			end
		end

		if currentState == STATE.CHASE and validPlayer(targetPlayer) then
			humanoid.WalkSpeed = CONFIG.VillainWalkSpeed
			playLoco(tracks.Run or tracks.Walk)
			local targetHRP = getHRP(targetPlayer)
			local dist = (targetHRP.Position - root.Position).Magnitude
			if
				dist <= CONFIG.CatchDistance
				and math.abs(targetHRP.Position.Y - root.Position.Y) <= CONFIG.HeightReach
			then
				task.spawn(runCatch, targetPlayer)
				continue
			end
			local now = os.clock()
			local los = lineOfSight(targetHRP)
			local needPath = (now - lastPathAt) >= CONFIG.PathRefreshTime or wpIndex > #waypoints
			if lastPathAt > 0 and #waypoints > 0 then
				local dest = waypoints[#waypoints]
				if dest and (dest.Position - targetHRP.Position).Magnitude >= CONFIG.RepathDistance then
					needPath = true
				end
			end
			if los and dist <= CONFIG.DirectChaseDistance then
				humanoid:MoveTo(targetHRP.Position)
			else
				if needPath then
					if not computePath(targetHRP.Position) then
						humanoid:MoveTo(targetHRP.Position)
					end
				end
				followPath()
			end
			antiStuck()
		elseif currentState == STATE.PATROL and CONFIG.PatrolEnabled then
			humanoid.WalkSpeed = CONFIG.VillainIdleSpeed
			playLoco(tracks.Walk or tracks.Idle)
			if not patrolDest or (root.Position - patrolDest).Magnitude < 4 then
				playLoco(tracks.Idle)
				task.wait(rng:NextNumber(CONFIG.PatrolWaitMin, CONFIG.PatrolWaitMax))
				if busy then
					continue
				end
				patrolDest = pickPatrol()
				computePath(patrolDest)
			else
				if os.clock() - lastPathAt >= CONFIG.PathRefreshTime * 2 then
					computePath(patrolDest)
				end
				followPath()
				antiStuck()
			end
		else
			humanoid.WalkSpeed = CONFIG.VillainIdleSpeed
			playLoco(tracks.Idle)
			humanoid:Move(Vector3.zero)
		end
	end
end)

task.spawn(function()
	while model.Parent do
		task.wait(0.4)
		if not busy and humanoid.MoveDirection.Magnitude > 0.2 then
			playIfSet(sndStep)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	savedMove[player] = nil
	if targetPlayer == player then
		setTarget(nil)
		if not busy then
			setState(STATE.IDLE)
		end
	end
end)

dbg("AI running. speed=" .. CONFIG.VillainWalkSpeed)
print("[CoachVillain] Server AI started")
