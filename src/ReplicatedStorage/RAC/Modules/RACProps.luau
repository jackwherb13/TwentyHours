-- ReplicatedStorage.RAC.Modules.RACProps
-- Recognizable furnishings. Representative, not one part per bleacher seat.
-- Edit positions here if you move a room in RACArchitecture.layout().

local RACUtil = require(script.Parent.RACUtil)
local CollectionService = game:GetService("CollectionService")

local Props = {}

local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

function Props.build(ctx, cfg)
	local folders = ctx.folders
	local P = folders.Props
	local pal = cfg.PALETTE

	local function box(name, size, pos, colorName, mat, extra)
		return RACUtil.part(
			P,
			name,
			size,
			CFrame.new(pos),
			RACUtil.color(pal, colorName),
			RACUtil.material(mat or "SmoothPlastic"),
			extra
		)
	end

	local function stripe(name, size, pos, color)
		return RACUtil.part(
			P,
			name,
			size,
			CFrame.new(pos),
			color,
			Enum.Material.SmoothPlastic,
			{ canCollide = false, castShadow = false }
		)
	end

	local function label(part, text, textColor, bg, face)
		RACUtil.sign(part, text, textColor or Color3.new(1, 1, 1), bg or Color3.fromRGB(0, 82, 45), face)
	end

	local function court(name, x, z, width, length, y)
		local white = Color3.fromRGB(245, 245, 245)
		local green = rgb(pal.CourtGreen)
		local gold = rgb(pal.GMGold)
		local t = 0.04
		local yy = y + 0.08
		stripe(name .. "_KeyS", Vector3.new(12, t, 19), Vector3.new(x + width * 0.5, yy, z + 9.5), green)
		stripe(name .. "_KeyN", Vector3.new(12, t, 19), Vector3.new(x + width * 0.5, yy, z + length - 9.5), green)
		local words =
			stripe(name .. "_Patriots", Vector3.new(10, t, 8), Vector3.new(x + width * 0.5, yy + 0.01, z + 14), green)
		label(words, "PATRIOTS", gold, green, Enum.NormalId.Top)
		local logo = stripe(
			name .. "_GM",
			Vector3.new(14, t, 10),
			Vector3.new(x + width * 0.5, yy + 0.01, z + length * 0.5),
			green
		)
		label(logo, "GM", gold, green, Enum.NormalId.Top)
		stripe(name .. "_S", Vector3.new(width, t, 0.2), Vector3.new(x + width * 0.5, yy + 0.02, z), white)
		stripe(name .. "_N", Vector3.new(width, t, 0.2), Vector3.new(x + width * 0.5, yy + 0.02, z + length), white)
		stripe(name .. "_W", Vector3.new(0.2, t, length), Vector3.new(x, yy + 0.02, z + length * 0.5), white)
		stripe(name .. "_E", Vector3.new(0.2, t, length), Vector3.new(x + width, yy + 0.02, z + length * 0.5), white)
		stripe(
			name .. "_Half",
			Vector3.new(width, t, 0.15),
			Vector3.new(x + width * 0.5, yy + 0.02, z + length * 0.5),
			white
		)
		stripe(name .. "_FTS", Vector3.new(12, t, 0.15), Vector3.new(x + width * 0.5, yy + 0.02, z + 19), white)
		stripe(
			name .. "_FTN",
			Vector3.new(12, t, 0.15),
			Vector3.new(x + width * 0.5, yy + 0.02, z + length - 19),
			white
		)
		local ring = Instance.new("Part")
		ring.Name = name .. "_Center"
		ring.Shape = Enum.PartType.Cylinder
		ring.Anchored = true
		ring.CanCollide = false
		ring.CastShadow = false
		ring.Size = Vector3.new(0.05, 12, 12)
		ring.CFrame = CFrame.new(x + width * 0.5, yy + 0.03, z + length * 0.5) * CFrame.Angles(0, 0, math.rad(90))
		ring.Color = white
		ring.Material = Enum.Material.SmoothPlastic
		ring.Parent = P
	end

	local function hoop(name, x, z, facingZ)
		local sign = if facingZ >= 0 then 1 else -1
		local base = box(name .. "_Pole", Vector3.new(0.6, 10, 0.6), Vector3.new(x, 5, z), "MetalDark", "Metal")
		base.Name = name .. "_Pole"
		box(name .. "_Arm", Vector3.new(0.4, 0.4, 6), Vector3.new(x, 10.2, z + sign * 3), "MetalDark", "Metal")
		local board =
			box(name .. "_Board", Vector3.new(6, 3.5, 0.3), Vector3.new(x, 10, z + sign * 6), "Wall", "SmoothPlastic")
		board.Color = Color3.fromRGB(250, 250, 250)
		local rim = Instance.new("Part")
		rim.Name = name .. "_Rim"
		rim.Shape = Enum.PartType.Cylinder
		rim.Anchored = true
		rim.CanCollide = false
		rim.Size = Vector3.new(0.15, 1.5, 1.5)
		rim.CFrame = CFrame.new(x, 9.2, z + sign * 7.2) * CFrame.Angles(0, 0, math.rad(90))
		rim.Color = Color3.fromRGB(220, 80, 20)
		rim.Material = Enum.Material.Metal
		rim.Parent = P
	end

	local function bleacherBank(name, x, z, length, rows, alongX)
		for i = 1, rows do
			local rise = 1.15
			local depth = 2.4
			local size
			local pos
			if alongX then
				size = Vector3.new(length, rise, depth)
				pos = Vector3.new(x + length * 0.5, rise * (i - 0.5), z + depth * (i - 0.5))
			else
				size = Vector3.new(depth, rise, length)
				pos = Vector3.new(x + depth * (i - 0.5), rise * (i - 0.5), z + length * 0.5)
			end
			local colorName = if i % 5 == 0 then "BleacherGold" else "Bleacher"
			box(name .. "_" .. i, size, pos, colorName, "SmoothPlastic", { castShadow = false })
		end
	end

	local function banner(name, x, y, z, text)
		local p =
			box(name, Vector3.new(6, 10, 0.2), Vector3.new(x, y, z), "Wall", "SmoothPlastic", { canCollide = false })
		label(p, text, rgb(pal.GMGreen), Color3.fromRGB(245, 245, 240))
	end

	local function signBoard(name, x, y, z, sx, sy, text, face)
		local p =
			box(name, Vector3.new(sx, sy, 0.25), Vector3.new(x, y, z), "Wall", "SmoothPlastic", { canCollide = false })
		label(p, text, Color3.new(1, 1, 1), rgb(pal.GMGreen), face)
		return p
	end

	court("RACCourt", 128, 136, 50, 94, 0)
	hoop("GymHoopSouth", 153, 140, 1)
	hoop("GymHoopNorth", 153, 226, -1)
	box("VolleyPoleW", Vector3.new(0.4, 8, 0.4), Vector3.new(128, 4, 183), "MetalDark", "Metal")
	box("VolleyPoleE", Vector3.new(0.4, 8, 0.4), Vector3.new(178, 4, 183), "MetalDark", "Metal")
	local net = box(
		"VolleyNet",
		Vector3.new(50, 3, 0.15),
		Vector3.new(153, 6.2, 183),
		"Wall",
		"SmoothPlastic",
		{ canCollide = false, transparency = 0.25 }
	)
	net.Color = Color3.fromRGB(230, 230, 230)
	bleacherBank("RACBleachers", 200, 150, 60, 14, false)
	local board = box(
		"Scoreboard",
		Vector3.new(14, 4, 0.6),
		Vector3.new(200, 22, 140),
		"GMGreen",
		"SmoothPlastic",
		{ canCollide = false }
	)
	label(board, "HOME    GUEST", rgb(pal.GMGold), rgb(pal.GMGreen))
	banner("BannerNCAA", 200, 28, 160, "NCAA\nWOMEN'S\nVOLLEYBALL")
	banner("BannerCAA", 220, 28, 160, "CAA\nCHAMPIONS")
	banner("BannerAcosta", 160, 16, 224, "UVALDO\nACOSTA\n#8\n1985-1988")
	box(
		"GymPadWest",
		Vector3.new(0.4, 6, 90),
		Vector3.new(111.2, 3, 180),
		"Pad",
		"SmoothPlastic",
		{ castShadow = false }
	)
	box(
		"GymPadNorth",
		Vector3.new(80, 6, 0.4),
		Vector3.new(190, 3, 228.6),
		"Pad",
		"SmoothPlastic",
		{ castShadow = false }
	)

	court("LinnCourt", -170, 58, 50, 84, 0)
	hoop("LinnHoopS", -145, 62, 1)
	hoop("LinnHoopN", -145, 138, -1)
	signBoard("LinnSign", -86, 8, 140, 8, 2, "JOHN LINN\nMEMORIAL GYM", Enum.NormalId.Right)

	court("CageCourtWest", -180, 236, 50, 94, 0)
	court("CageCourtEast", -110, 236, 50, 94, 0)
	hoop("CageHoopW1", -155, 240, 1)
	hoop("CageHoopW2", -155, 326, -1)
	hoop("CageHoopE1", -85, 240, 1)
	hoop("CageHoopE2", -85, 326, -1)
	signBoard("CageSign", -40.6, 9, 258, 0.3, 1.4, "CAGE GYM", Enum.NormalId.Right)

	box("ReceptionDesk", Vector3.new(14, 3.4, 3.2), Vector3.new(18, 1.7, 20), "Wood", "Wood")
	box(
		"ReceptionTop",
		Vector3.new(14.4, 0.2, 3.6),
		Vector3.new(18, 3.5, 20),
		"Wall",
		"SmoothPlastic",
		{ canCollide = false }
	)
	box("LobbyBench", Vector3.new(16, 1.4, 2.2), Vector3.new(-14, 0.7, 18), "Wood", "Wood")
	box("ColumnA", Vector3.new(2.2, 28, 2.2), Vector3.new(-16, 14, 22), "Wall", "Concrete")
	box("ColumnB", Vector3.new(2.2, 28, 2.2), Vector3.new(8, 14, 28), "Wall", "Concrete")
	box("MannequinLegs", Vector3.new(1.2, 3, 0.8), Vector3.new(24, 4.6, 20), "Wall", "SmoothPlastic")
	box("MannequinTorso", Vector3.new(1.6, 2.2, 0.9), Vector3.new(24, 7.2, 20), "GMGreen", "SmoothPlastic")
	local helmet = box("MannequinHead", Vector3.new(1.1, 1.1, 1.1), Vector3.new(24, 8.8, 20), "GMGold", "SmoothPlastic")
	helmet.Shape = Enum.PartType.Ball
	signBoard("AED", 4, 6, 8, 1.6, 1.6, "AED", Enum.NormalId.Front)

	local function pingPong(name, x, z)
		box(name .. "_Top", Vector3.new(9, 0.3, 5), Vector3.new(x, 2.5, z), "MetalDark", "SmoothPlastic")
		box(
			name .. "_Net",
			Vector3.new(0.15, 0.7, 5.2),
			Vector3.new(x, 3, z),
			"Wall",
			"SmoothPlastic",
			{ canCollide = false }
		)
		box(name .. "_Leg", Vector3.new(0.4, 2.4, 0.4), Vector3.new(x, 1.2, z), "MetalDark", "Metal")
	end
	pingPong("PingPongA", 48, 16)
	pingPong("PingPongB", 48, 28)
	box("LoungeCounter", Vector3.new(8, 3.4, 2.4), Vector3.new(66, 1.7, 18), "Wood", "Wood")
	local vender = box("LoungeVending", Vector3.new(3, 6.5, 2.4), Vector3.new(62, 3.3, 30), "GMGreen", "SmoothPlastic")
	label(vender, "VENDING", rgb(pal.GMGold), rgb(pal.GMGreen))

	signBoard("HallOfFame", -6.5, 6, 80, 0.3, 3, "HALL OF FAME", Enum.NormalId.Right)
	for i = 1, 4 do
		local case = box(
			"TrophyCase_" .. i,
			Vector3.new(4, 6, 1.2),
			Vector3.new(6.2, 3.2, 70 + i * 8),
			"Glass",
			"Glass",
			{ transparency = 0.45 }
		)
		case.CanCollide = true
	end
	for i = 0, 5 do
		box("DayLocker_" .. i, Vector3.new(1.4, 6, 1.4), Vector3.new(14, 3, 72 + i * 2.2), "GMGreen", "Metal")
	end
	local recre = box("Recrebox", Vector3.new(2.2, 6.5, 2.2), Vector3.new(20, 3.3, 214), "GMGreen", "SmoothPlastic")
	label(recre, "MASON\nRECREATION\nrecrebox", rgb(pal.GMGold), rgb(pal.GMGreen))
	local coke = box("CokeMachine", Vector3.new(3, 6.5, 2.4), Vector3.new(-16, 3.3, 220), "Pad", "SmoothPlastic")
	coke.Color = Color3.fromRGB(180, 20, 20)
	label(coke, "COLD\nDRINKS", Color3.new(1, 1, 1), Color3.fromRGB(160, 16, 16))

	box("WorkRoomDesk", Vector3.new(8, 2.6, 2.6), Vector3.new(-48, 1.3, 66), "Wall", "SmoothPlastic")
	box("MailSlots", Vector3.new(3.2, 4, 0.8), Vector3.new(-40, 4.5, 64), "Frame", "SmoothPlastic")
	signBoard("WorkRoomSign", -22.8, 6, 66, 0.2, 1.4, "WORK ROOM\n1120", Enum.NormalId.Left)
	box("BreakTable", Vector3.new(6, 2.4, 3), Vector3.new(-46, 1.2, 92), "Wood", "Wood")
	signBoard("BreakRoomSign", -22.8, 6, 90, 0.2, 1.4, "BREAK ROOM\n1122", Enum.NormalId.Left)
	signBoard("Room1115", -22.8, 6, 120, 0.2, 1.2, "1115", Enum.NormalId.Left)
	for i = 0, 3 do
		box(
			"Cubicle_" .. i,
			Vector3.new(6, 4.5, 6),
			Vector3.new(-60, 2.25, 78 + i * 10),
			"Frame",
			"Fabric",
			{ canCollide = true }
		)
	end

	local keyPad = box("StaffKeyPickup", Vector3.new(1.2, 0.3, 0.8), Vector3.new(-45, 2.8, 66), "GMGold", "Metal")
	keyPad:SetAttribute("KeyName", "StaffKey")
	local keyPrompt = Instance.new("ProximityPrompt")
	keyPrompt.ActionText = "Take"
	keyPrompt.ObjectText = "Staff Key"
	keyPrompt.MaxActivationDistance = 8
	keyPrompt.RequiresLineOfSight = false
	keyPrompt.Parent = keyPad
	local tool = Instance.new("Tool")
	tool.Name = "Template"
	tool.ToolTip = "StaffKey"
	tool.RequiresHandle = true
	tool.CanBeDropped = true
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.3, 1.4, 0.3)
	handle.Color = rgb(pal.GMGold)
	handle.Material = Enum.Material.Metal
	handle.Parent = tool
	tool.Parent = keyPad
	CollectionService:AddTag(keyPad, "RACKeyPickup")

	local function rack(name, x, z)
		box(name .. "_Upright", Vector3.new(4, 7, 0.4), Vector3.new(x, 3.5, z), "MetalDark", "Metal")
		box(
			name .. "_Bar",
			Vector3.new(5, 0.25, 0.25),
			Vector3.new(x, 5, z + 0.6),
			"MetalDark",
			"Metal",
			{ canCollide = false }
		)
	end
	rack("FitRackA", 28, 70)
	rack("FitRackB", 28, 86)
	rack("FitRackC", 50, 70)
	box("FitBench", Vector3.new(2, 1.4, 5), Vector3.new(40, 0.8, 80), "MetalDark", "Metal")
	box("FitTread", Vector3.new(3, 4, 7), Vector3.new(60, 2, 90), "MetalDark", "Metal")
	rack("HammerRackA", 96, 64)
	rack("HammerRackB", 96, 78)
	rack("HammerRackC", 108, 70)
	signBoard("HammerSign", 82, 8, 78, 0.2, 1.6, "HAMMER\nSTRENGTH", Enum.NormalId.Left)

	signBoard("WomensSign", 49.2, 6, 220, 0.2, 1.6, "WOMEN'S\nLOCKER ROOM\n1220", Enum.NormalId.Left)
	local mosaic = box(
		"VolleyballMosaic",
		Vector3.new(0.4, 8, 12),
		Vector3.new(1.2, 4.2, 256),
		"Glass",
		"Glass",
		{ canCollide = false }
	)
	mosaic.Color = Color3.fromRGB(70, 140, 110)
	label(mosaic, "GM\nHOME OF GMU\nVOLLEYBALL", rgb(pal.GMGreen), Color3.fromRGB(180, 210, 190), Enum.NormalId.Right)
	signBoard("StalickHeader", 14, 8.2, 263.4, 12, 2.2, "THE COACH WAYNE STALICK\nLOCKER ROOM", Enum.NormalId.Back)
	signBoard("Room1210", 2.4, 5, 262, 0.2, 1.6, "MEN'S VOLLEYBALL\nLOCKER ROOM\n1210", Enum.NormalId.Right)
	local fridge = box("NutritionFridge", Vector3.new(3.2, 6.5, 2.2), Vector3.new(16, 3.3, 272), "Wall", "Metal")
	label(fridge, "THE MATT CROSON\nNUTRITION STATION", rgb(pal.GMGold), Color3.fromRGB(30, 30, 30), Enum.NormalId.Back)

	local function lockerBank(originX, originZ, names)
		for i, stallName in names do
			local x = originX + (i - 1) * 3.1
			box("Stall_" .. stallName, Vector3.new(3, 6.5, 2), Vector3.new(x, 3.3, originZ), "LockerWood", "Wood")
			local plate = box(
				"Plate_" .. stallName,
				Vector3.new(2.4, 0.6, 0.1),
				Vector3.new(x, 5.4, originZ - 1.05),
				"GMGreen",
				"SmoothPlastic",
				{ canCollide = false }
			)
			label(plate, stallName, Color3.new(1, 1, 1), rgb(pal.GMGreen), Enum.NormalId.Front)
		end
	end
	lockerBank(-2, 292, { "METCALF #27", "HERBERT #20", "CAMPBELL #2", "MASON", "MASON", "MASON" })
	local cart = box("BallCart", Vector3.new(4, 3, 3), Vector3.new(8, 1.5, 278), "MetalDark", "Metal")
	label(cart, "molten", Color3.new(1, 1, 1), Color3.fromRGB(20, 20, 20))
	signBoard("AllAmerican", 40, 6, 300, 0.3, 8, "NCAA\nALL-AMERICANS\n\nNAIA\nALL-AMERICANS", Enum.NormalId.Left)

	for i = 0, 2 do
		local x = 2 + i * 8
		box("ShowerBase_" .. i, Vector3.new(6, 0.4, 6), Vector3.new(x, 0.3, 316), "Wall", "SmoothPlastic")
		local curtain = box(
			"ShowerCurtain_" .. i,
			Vector3.new(0.15, 6, 5),
			Vector3.new(x - 2.4, 3.4, 316),
			"GMGold",
			"Fabric",
			{ canCollide = false, transparency = 0.05 }
		)
		curtain.Color = rgb(pal.GMGreen)
	end
	box("ShowerColumn", Vector3.new(1.4, 8, 1.4), Vector3.new(14, 4, 316), "Wall", "Concrete")
	box("Urinal", Vector3.new(1.4, 2.2, 0.8), Vector3.new(36, 1.6, 284.5), "Wall", "SmoothPlastic")
	signBoard("Hydration", 40, 5, 286, 0.2, 2.4, "AM I HYDRATED?", Enum.NormalId.Back)
	box("SinkCounter", Vector3.new(10, 2.6, 2), Vector3.new(8, 1.4, 270), "Wall", "Marble")

	box("InBodyA", Vector3.new(1.2, 5, 1.2), Vector3.new(96, 2.5, 200), "MetalDark", "Metal")
	box("InBodyB", Vector3.new(1.2, 5, 1.2), Vector3.new(100, 2.5, 200), "MetalDark", "Metal")

	if ctx.R.squash then
		signBoard("SquashEstimated", 140, 8, 78, 8, 2, "SQUASH / RACQUETBALL\nESTIMATED", Enum.NormalId.Front)
	end
	if ctx.R.upperGym then
		signBoard("UpperGymEstimated", -54, cfg.LEVEL2 + 6, 60, 10, 2, "UPPER GYM\nESTIMATED", Enum.NormalId.Front)
	end

	local H = folders.HorrorGameplay
	local nodes = H:FindFirstChild("PatrolNodes") or Instance.new("Folder")
	nodes.Name = "PatrolNodes"
	nodes.Parent = H
	local route = {
		{ "Lobby", 0, 18 },
		{ "MainHall", 0, 100 },
		{ "Fitness", 40, 90 },
		{ "GymCorridor", 98, 170 },
		{ "GymFloor", 160, 180 },
		{ "LockerHall", 12, 224 },
		{ "Stalick", 16, 290 },
		{ "BackCorridor", -24, 280 },
		{ "Cage", -120, 270 },
		{ "Service", -100, 209 },
		{ "Linn", -140, 100 },
		{ "Offices", -50, 90 },
	}
	for index, node in route do
		local p = RACUtil.part(
			nodes,
			"Patrol_" .. index .. "_" .. node[1],
			Vector3.new(2, 2, 2),
			CFrame.new(node[2], 3, node[3]),
			Color3.new(1, 0, 0),
			Enum.Material.Neon,
			{ transparency = 1, canCollide = false, castShadow = false }
		)
		p:SetAttribute("PatrolOrder", index)
		p.CanQuery = false
	end

	local hides = H:FindFirstChild("HideSpots") or Instance.new("Folder")
	hides.Name = "HideSpots"
	hides.Parent = H
	local hideList = {
		{ "BehindReception", 18, 23 },
		{ "BleacherAisle", 210, 180 },
		{ "LockerBay", 4, 308 },
		{ "Cubicle", -60, 88 },
		{ "HammerRack", 100, 74 },
	}
	for _, h in hideList do
		local p = RACUtil.part(
			hides,
			"Hide_" .. h[1],
			Vector3.new(4, 5, 4),
			CFrame.new(h[2], 2.5, h[3]),
			Color3.new(0, 1, 0),
			Enum.Material.Neon,
			{ transparency = 1, canCollide = false, castShadow = false }
		)
		p:SetAttribute("HideSpot", true)
		p.CanQuery = false
	end

	local speakers = H:FindFirstChild("Speakers") or Instance.new("Folder")
	speakers.Name = "Speakers"
	speakers.Parent = H
	for index, pos in { { 0, 24, 20 }, { 0, 9, 120 }, { 160, 30, 180 }, { 16, 9, 290 } } do
		local sp = RACUtil.part(
			speakers,
			"Speaker_" .. index,
			Vector3.new(1.2, 0.4, 0.8),
			CFrame.new(pos[1], pos[2], pos[3]),
			RACUtil.color(pal, "MetalDark"),
			Enum.Material.Metal,
			{ canCollide = false, castShadow = false }
		)
		local sound = Instance.new("Sound")
		sound.Name = "Voice"
		sound.Volume = 0.8
		sound.RollOffMaxDistance = 80
		sound.Parent = sp
	end

	return P
end

return Props
