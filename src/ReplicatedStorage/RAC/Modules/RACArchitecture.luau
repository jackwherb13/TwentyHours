-- ReplicatedStorage.RAC.Modules.RACArchitecture
-- Structural blockout. Tweak the rectangles in layout() if a room needs to move.
-- All numbers are feet (studs). Origin is the main-entrance threshold:
--   +X east, +Z north (into the building), +Y up. Interior floor Y = 0.
--   Exterior grade is Y = -4 under the south entry stairs.

local RACUtil = require(script.Parent.RACUtil)

local Architecture = {}

local function layout(cfg)
	local L2 = cfg.LEVEL2
	local R = {
		lobby = { x = -30, z = 0, w = 62, d = 46, h = 28, ceil = 28, folder = "FirstFloor", zone = "Lobby" },
		lounge = { x = 32, z = 0, w = 44, d = 40, h = 12, ceil = 12, folder = "FirstFloor", zone = "Lounge" },
		hall = { x = -8, z = 46, w = 16, d = 154, h = 10, ceil = 10, folder = "Hallways", zone = "MainHall" },
		fitness = { x = 8, z = 46, w = 72, d = 84, h = 28, ceil = 28, folder = "FitnessAreas", zone = "Fitness" },
		hammer = { x = 80, z = 50, w = 42, d = 54, h = 14, ceil = 14, folder = "FitnessAreas", zone = "Hammer" },
		officeHall = {
			x = -22,
			z = 50,
			w = 14,
			d = 80,
			h = 10,
			ceil = 10,
			folder = "Offices",
			zone = "Offices",
			color = "Carpet",
			mat = "Fabric",
		},
		offices = {
			x = -84,
			z = 50,
			w = 62,
			d = 80,
			h = 10,
			ceil = 10,
			folder = "Offices",
			zone = "Offices",
			color = "Carpet",
			mat = "Fabric",
		},
		linn = {
			x = -200,
			z = 48,
			w = 116,
			d = 102,
			h = 24,
			ceil = 24,
			folder = "Gymnasium",
			zone = "LinnGym",
			color = "Wood",
			mat = "Wood",
		},
		courtHall = { x = -84, z = 130, w = 76, d = 20, h = 12, ceil = 12, folder = "Hallways", zone = "CourtHall" },
		link = { x = 8, z = 130, w = 78, d = 16, h = 12, ceil = 12, folder = "Hallways", zone = "GymCorridor" },
		gymCorr = { x = 86, z = 120, w = 24, d = 110, h = 14, ceil = 14, folder = "Hallways", zone = "GymCorridor" },
		gym = {
			x = 110,
			z = 118,
			w = 150,
			d = 112,
			h = 36,
			ceil = 36,
			folder = "Gymnasium",
			zone = "Gym",
			color = "Wood",
			mat = "Wood",
		},
		locker = { x = -24, z = 200, w = 72, d = 48, h = 28, ceil = 28, folder = "LockerAreas", zone = "LockerHall" },
		vestibule = { x = 0, z = 248, w = 28, d = 16, h = 10, ceil = 10, folder = "LockerAreas", zone = "LockerSuite" },
		suite = { x = -8, z = 264, w = 52, d = 64, h = 10, ceil = 10, folder = "LockerAreas", zone = "LockerSuite" },
		womens = { x = 48, z = 208, w = 28, d = 24, h = 10, ceil = 10, folder = "LockerAreas", zone = "Womens" },
		service = { x = -200, z = 200, w = 176, d = 18, h = 12, ceil = 12, folder = "Hallways", zone = "Service" },
		cage = {
			x = -200,
			z = 218,
			w = 160,
			d = 112,
			h = 26,
			ceil = 26,
			folder = "Gymnasium",
			zone = "Cage",
			color = "Wood",
			mat = "Wood",
		},
		backConn = { x = -40, z = 218, w = 16, d = 30, h = 10, ceil = 10, folder = "Hallways", zone = "Service" },
		backCorr = { x = -40, z = 248, w = 32, d = 80, h = 10, ceil = 10, folder = "Hallways", zone = "Service" },
	}
	if cfg.INCLUDE_ESTIMATED then
		R.squash = {
			x = 122,
			z = 50,
			w = 36,
			d = 54,
			h = 14,
			ceil = 14,
			folder = "Gymnasium",
			zone = "Hammer",
			estimated = true,
			color = "Wood",
			mat = "Wood",
		}
		R.upperGym = {
			x = -80,
			z = 52,
			w = 52,
			d = 46,
			y = L2,
			h = 10,
			ceil = 10,
			folder = "SecondFloor",
			zone = "SecondFloor",
			estimated = true,
			color = "Wood",
			mat = "Wood",
		}
	end
	return R
end

local function zoneFolders(lighting, names)
	local map = {}
	for _, name in names do
		local folder = RACUtil.ensure(lighting, "Folder", name)
		local mode = folder:FindFirstChild("Mode")
		if not mode then
			mode = Instance.new("StringValue")
			mode.Name = "Mode"
			mode.Value = "normal"
			mode.Parent = folder
		end
		map[name] = folder
	end
	local master = lighting:FindFirstChild("MasterMode")
	if not master then
		master = Instance.new("StringValue")
		master.Name = "MasterMode"
		master.Value = "zoned"
		master.Parent = lighting
	end
	return map
end

function Architecture.build(root, cfg)
	local folders = RACUtil.folders(root)
	local lightZones = zoneFolders(folders.Lighting, {
		"Lobby",
		"Lounge",
		"MainHall",
		"Fitness",
		"Hammer",
		"Offices",
		"LinnGym",
		"CourtHall",
		"GymCorridor",
		"Gym",
		"LockerHall",
		"LockerSuite",
		"Womens",
		"Service",
		"Cage",
		"SecondFloor",
		"Exterior",
	})
	local ctx = {
		palette = cfg.PALETTE,
		folders = folders,
		wallT = cfg.WALL_T,
		lightZones = lightZones,
	}
	local R = layout(cfg)
	local L2 = cfg.LEVEL2

	local function F(rect, overrides)
		overrides = overrides or {}
		RACUtil.floor(ctx, {
			name = overrides.name or rect.name,
			x = rect.x,
			z = rect.z,
			w = rect.w,
			d = rect.d,
			y = overrides.y or rect.y or 0,
			color = overrides.color or rect.color or "Tile",
			mat = overrides.mat or rect.mat or "Concrete",
			folder = overrides.folder or rect.folder,
			ceil = if overrides.ceil == false then nil else (overrides.ceil or rect.ceil),
			estimated = rect.estimated,
		})
	end

	for key, rect in R do
		rect.name = key
	end

	RACUtil.floor(ctx, {
		name = "Grass",
		x = -260,
		z = -80,
		w = 580,
		d = 460,
		y = -4,
		thick = 1.2,
		color = "Grass",
		mat = "Grass",
		folder = "Exterior",
	})
	RACUtil.floor(ctx, {
		name = "EntryPlaza",
		x = -36,
		z = -34,
		w = 120,
		d = 34,
		y = -4,
		color = "Concrete",
		mat = "Concrete",
		folder = "Exterior",
	})
	RACUtil.floor(ctx, {
		name = "EntryLanding",
		x = -12,
		z = -12,
		w = 24,
		d = 12,
		y = 0,
		color = "Concrete",
		mat = "Concrete",
		folder = "Exterior",
	})

	for _, key in
		{
			"lobby",
			"lounge",
			"hall",
			"fitness",
			"hammer",
			"officeHall",
			"offices",
			"linn",
			"courtHall",
			"link",
			"gymCorr",
			"gym",
			"locker",
			"vestibule",
			"suite",
			"womens",
			"service",
			"cage",
			"backConn",
			"backCorr",
			"squash",
			"upperGym",
		}
	do
		if R[key] then
			F(R[key])
		end
	end

	local decks = {
		{ name = "LobbyNorthBalcony", x = -16, z = 32, w = 42, d = 12 },
		{ name = "LobbyEastBalcony", x = 16, z = 6, w = 14, d = 26 },
		{ name = "FitnessGallery", x = 40, z = 50, w = 36, d = 54 },
		{ name = "UpperLinkToGym", x = 40, z = 104, w = 128, d = 14 },
		{ name = "GymSouthMezz", x = 140, z = 122, w = 112, d = 20 },
		{ name = "GymWestMezz", x = 114, z = 142, w = 22, d = 78 },
		{ name = "UpperWestLink", x = -80, z = 36, w = 60, d = 16 },
	}
	for _, deck in decks do
		RACUtil.floor(ctx, {
			name = deck.name,
			x = deck.x,
			z = deck.z,
			w = deck.w,
			d = deck.d,
			y = L2,
			color = "Tile",
			mat = "Concrete",
			folder = "SecondFloor",
		})
	end
	RACUtil.floor(ctx, {
		name = "GymSouthDoorLanding",
		x = 152,
		z = 118.4,
		w = 16,
		d = 4,
		y = L2,
		color = "Tile",
		mat = "Concrete",
		folder = "SecondFloor",
	})
	RACUtil.floor(ctx, {
		name = "GymStairLanding",
		x = 132,
		z = 124,
		w = 10,
		d = 14,
		y = L2,
		color = "Tile",
		mat = "Concrete",
		folder = "SecondFloor",
	})
	RACUtil.floor(ctx, {
		name = "UpperExitDeck",
		x = 48,
		z = 234,
		w = 16,
		d = 16,
		y = L2,
		color = "Concrete",
		mat = "Concrete",
		folder = "Exterior",
	})

	local function W(name, ax, az, bx, bz, h, openings, opts)
		opts = opts or {}
		RACUtil.wall(ctx, {
			name = name,
			a = { ax, az },
			b = { bx, bz },
			y = opts.y or 0,
			h = h,
			color = opts.color,
			mat = opts.mat,
			folder = opts.folder,
			transparency = opts.transparency,
			zone = opts.zone,
			estimated = opts.estimated,
			openings = openings or {},
		})
	end

	local function single(dist, name, extra)
		extra = extra or {}
		return {
			dist = dist,
			w = extra.w or 4.6,
			h = extra.h or 7.4,
			sill = extra.sill or 0,
			kind = "single",
			name = name,
			glass = extra.glass,
			locked = extra.locked,
			requiresKey = extra.requiresKey,
			keyName = extra.keyName,
			openAngle = extra.openAngle,
			autoClose = extra.autoClose,
			autoCloseDelay = extra.autoCloseDelay,
			estimated = extra.estimated,
		}
	end

	local function double(dist, name, extra)
		extra = extra or {}
		extra.w = extra.w or 7.2
		local o = single(dist, name, extra)
		o.kind = "double"
		return o
	end

	local function hole(dist, w, h, sill)
		return { dist = dist, w = w, h = h or 8, sill = sill or 0, kind = "none" }
	end

	local function window(dist, w, h, sill)
		return { dist = dist, w = w, h = h, sill = sill or 3, kind = "window" }
	end

	W("LobbySouth", -30, 0, 32, 0, 28, {
		double(
			31,
			"MainEntrance",
			{ w = 8, h = 8, glass = true, autoClose = true, autoCloseDelay = 3, openAngle = 90 }
		),
		window(10, 12, 16, 2),
		window(52, 12, 16, 2),
	}, { color = "Glass", mat = "Glass", transparency = 0.35, folder = "Exterior", zone = "Lobby" })
	W("LobbyWest", -30, 0, -30, 46, 28, {}, { folder = "Exterior", zone = "Lobby" })
	W("LobbyNorth", -30, 46, 32, 46, 28, {
		hole(30, 16, 10, 0),
	}, { zone = "Lobby" })
	W("LobbyEast", 32, 0, 32, 46, 28, {
		hole(18, 10, 10, 0),
	}, { zone = "Lobby" })

	W(
		"LoungeSouth",
		32,
		0,
		76,
		0,
		12,
		{ window(22, 28, 6, 2) },
		{ folder = "Exterior", zone = "Lounge", color = "Glass", mat = "Glass", transparency = 0.4 }
	)
	W(
		"LoungeEast",
		76,
		0,
		76,
		40,
		12,
		{ window(20, 18, 6, 2) },
		{ folder = "Exterior", zone = "Lounge", color = "Glass", mat = "Glass", transparency = 0.4 }
	)
	W("LoungeNorth", 32, 40, 76, 40, 12, {}, { folder = "Exterior", zone = "Lounge" })

	W("HallWest_South", -8, 46, -8, 130, 10, {
		single(40, "OfficeHallDoor", { openAngle = -90 }),
	}, { zone = "MainHall", folder = "Hallways" })
	W("HallWest_North", -8, 130, -8, 200, 12, {
		double(16, "CourtHallFromMain", { openAngle = -90 }),
	}, { zone = "MainHall", folder = "Hallways" })
	W("HallEast_Fitness", 8, 46, 8, 130, 28, {
		hole(50, 18, 8, 3.6),
		single(20, "FitnessEntryDoor", { openAngle = 90 }),
	}, { zone = "Fitness", folder = "FitnessAreas" })
	W("HallEast_Link", 8, 130, 8, 200, 12, {
		hole(10, 12, 10, 0),
	}, { zone = "GymCorridor", folder = "Hallways" })
	W("HallNorth", -8, 200, 8, 200, 12, {
		double(8, "HallToLocker", { openAngle = 90 }),
	}, { zone = "MainHall", folder = "Hallways" })

	W("FitnessSouth", 32, 46, 80, 46, 28, {}, { zone = "Fitness", folder = "FitnessAreas" })
	W("FitnessEast", 80, 46, 80, 130, 28, {
		double(40, "HammerEntry", { openAngle = 90 }),
	}, { zone = "Fitness", folder = "FitnessAreas" })
	W("FitnessNorth", 8, 130, 80, 130, 28, {
		hole(36, 14, 10, 0),
	}, { zone = "Fitness", folder = "FitnessAreas" })
	W("HammerSouth", 80, 50, 122, 50, 14, {}, { folder = "Exterior", zone = "Hammer" })
	local hammerOpenings = {
		window(27, 24, 5, 4),
	}
	if R.squash then
		table.insert(
			hammerOpenings,
			single(10, "SquashEntry", {
				locked = true,
				requiresKey = true,
				keyName = "StaffKey",
				estimated = true,
				openAngle = 90,
			})
		)
	end
	W("HammerEast", 122, 50, 122, 104, 14, hammerOpenings, { folder = "Exterior", zone = "Hammer" })
	W("HammerNorth", 80, 104, 122, 104, 14, {}, { zone = "Hammer", folder = "FitnessAreas" })

	W("OfficesWestShared", -84, 50, -84, 130, 24, {
		window(20, 16, 5, 3),
		window(48, 16, 5, 3),
		window(70, 12, 5, 3),
	}, { zone = "LinnGym", folder = "Gymnasium" })
	W("OfficePartition", -22, 50, -22, 130, 10, {
		single(16, "WorkRoomDoor", { openAngle = -90 }),
		single(40, "BreakRoomDoor", { openAngle = -90 }),
		single(70, "CubicleDoor", { openAngle = -90 }),
	}, { zone = "Offices", folder = "Offices" })
	W("OfficesSouth", -84, 50, -22, 50, 10, {}, { zone = "Offices", folder = "Offices" })
	W("OfficesNorth", -84, 130, -22, 130, 12, {
		single(30, "OfficeToCourtHall", { openAngle = 90 }),
	}, { zone = "Offices", folder = "Offices" })
	W("LinnSouth", -200, 48, -84, 48, 24, {}, { folder = "Exterior", zone = "LinnGym" })
	W("LinnWest", -200, 48, -200, 150, 24, {
		window(30, 18, 8, 8),
		window(70, 18, 8, 8),
	}, { folder = "Exterior", zone = "LinnGym" })
	W("LinnNorth", -200, 150, -84, 150, 24, {}, { folder = "Exterior", zone = "LinnGym" })
	W("LinnEastDoors", -84, 130, -84, 150, 24, {
		double(10, "LinnGymDoors", { openAngle = -90 }),
	}, { zone = "LinnGym", folder = "Gymnasium" })
	W("CourtHallSouthOpen", -22, 130, -8, 130, 12, {
		hole(7, 12, 10, 0),
	}, { zone = "CourtHall", folder = "Hallways" })
	W("CourtHallNorth", -84, 150, -8, 150, 12, {}, { zone = "CourtHall", folder = "Hallways" })

	W("LinkNorth", 8, 146, 86, 146, 12, {}, { zone = "GymCorridor", folder = "Hallways" })
	W("GymCorrWest", 86, 120, 86, 230, 14, {
		hole(20, 14, 10, 0),
	}, { zone = "GymCorridor", folder = "Hallways" })
	W("GymCorrNorth", 86, 230, 110, 230, 14, {}, { folder = "Exterior", zone = "GymCorridor" })
	W("GymWestGlass", 110, 120, 110, 230, 36, {
		window(40, 36, 10, 1),
		double(78, "GymWestDoors", { w = 8, h = 8, glass = true, openAngle = 90, autoCloseDelay = 6 }),
		window(120, 40, 10, 1),
	}, { zone = "Gym", folder = "Gymnasium", color = "Wall" })
	W("GymSouth", 110, 118, 260, 118, 36, {
		hole(50, 8, 8, L2),
		window(20, 16, 6, 18),
		window(100, 20, 6, 18),
	}, { zone = "Gym", folder = "Gymnasium" })
	W("GymEast", 260, 118, 260, 230, 36, {
		window(30, 16, 8, 16),
		window(70, 16, 8, 16),
	}, { folder = "Exterior", zone = "Gym", color = "Brick", mat = "Brick" })
	W("GymNorth", 110, 230, 260, 230, 36, {
		double(40, "GymNorthExit", { glass = true, openAngle = -90 }),
	}, { folder = "Exterior", zone = "Gym" })

	W("LockerSouthWest", -24, 200, -8, 200, 28, {}, { zone = "LockerHall", folder = "LockerAreas" })
	W("LockerSouthEast", 8, 200, 48, 200, 28, {}, { zone = "LockerHall", folder = "LockerAreas" })
	W("LockerWest", -24, 200, -24, 248, 28, {
		single(14, "ServiceFromLocker", { openAngle = -90 }),
	}, { zone = "LockerHall", folder = "LockerAreas" })
	W("LockerEast", 48, 200, 48, 248, 28, {
		single(20, "WomensLockerDoor", { openAngle = 90 }),
		single(38, "UpperEastExit", { sill = L2, h = 7.4, glass = true, openAngle = 90, autoCloseDelay = 5 }),
	}, { zone = "LockerHall", folder = "LockerAreas", color = "Brick", mat = "Brick" })
	W("LockerNorth", -24, 248, 48, 248, 28, {
		double(38, "MosaicVestibuleDoor", { openAngle = 90 }),
	}, { zone = "LockerHall", folder = "LockerAreas" })

	W("VestibuleEast", 28, 248, 28, 264, 10, {}, { zone = "LockerSuite", folder = "LockerAreas" })
	W("VestibuleWest", 0, 248, 0, 264, 10, {}, { zone = "LockerSuite", folder = "LockerAreas" })
	W("VestibuleNorth", 0, 264, 28, 264, 10, {
		single(14, "StalickEntry", { openAngle = 90 }),
	}, { zone = "LockerSuite", folder = "LockerAreas" })

	W("SuiteSouthExtra", -8, 264, 0, 264, 10, {}, { zone = "LockerSuite", folder = "LockerAreas" })
	W("SuiteSouthExtra2", 28, 264, 44, 264, 10, {}, { zone = "LockerSuite", folder = "LockerAreas" })
	W("SuiteWest", -8, 264, -8, 328, 10, {
		single(30, "SuiteToBack", { openAngle = -90 }),
	}, { zone = "LockerSuite", folder = "LockerAreas" })
	W("SuiteEast", 44, 264, 44, 328, 10, {}, { folder = "Exterior", zone = "LockerSuite" })
	W("SuiteNorth", -8, 328, 44, 328, 10, {}, { folder = "Exterior", zone = "LockerSuite" })

	W("ShowerPartition", -8, 300, 28, 300, 8, {
		hole(18, 4, 7, 0),
	}, { zone = "LockerSuite", folder = "LockerAreas", color = "Tile" })
	W("UrinalPartition", 30, 286, 42, 286, 7, {
		hole(6, 2.6, 6.5, 0),
	}, { zone = "LockerSuite", folder = "LockerAreas" })

	W("WomensNorth", 48, 232, 76, 232, 10, {}, { folder = "Exterior", zone = "Womens" })
	W("WomensEast", 76, 208, 76, 232, 10, {}, { folder = "Exterior", zone = "Womens" })
	W("WomensSouth", 48, 208, 76, 208, 10, {}, { folder = "Exterior", zone = "Womens" })

	W("ServiceSouth", -200, 200, -24, 200, 12, {}, { folder = "Exterior", zone = "Service" })
	W("ServiceNorth", -200, 218, -40, 218, 12, {
		double(80, "CageGymDoors", { w = 8, openAngle = 90 }),
	}, { zone = "Cage", folder = "Gymnasium" })
	W("ServiceNorthEast", -40, 218, -24, 218, 12, {
		single(8, "BackConnDoor", { openAngle = 90 }),
	}, { zone = "Service", folder = "Hallways" })
	W("CageWest", -200, 218, -200, 330, 26, {}, { folder = "Exterior", zone = "Cage", color = "Brick", mat = "Brick" })
	W("CageNorth", -200, 330, -40, 330, 26, {
		double(40, "CageNorthExit", { openAngle = -90 }),
	}, { folder = "Exterior", zone = "Cage" })
	W("CageEast", -40, 218, -40, 330, 26, {
		single(50, "CageToBack", { openAngle = 90 }),
	}, { zone = "Cage", folder = "Gymnasium" })
	W("BackConnEast", -24, 218, -24, 248, 10, {}, { zone = "Service", folder = "Hallways" })
	W("BackCorrNorth", -40, 328, -8, 328, 10, {
		double(16, "ServiceNorthExit", { glass = true, openAngle = -90 }),
	}, { folder = "Exterior", zone = "Service" })

	if R.squash then
		W(
			"SquashEast",
			158,
			50,
			158,
			104,
			14,
			{ window(27, 16, 4, 5) },
			{ folder = "Exterior", estimated = true, zone = "Hammer" }
		)
		W("SquashNorth", 122, 104, 158, 104, 14, {}, { folder = "Exterior", estimated = true, zone = "Hammer" })
		W("SquashSouth", 122, 50, 158, 50, 14, {}, { folder = "Exterior", estimated = true, zone = "Hammer" })
		W("SquashSplit", 140, 50, 140, 104, 12, {
			single(54, "SquashInner", { locked = true, estimated = true }),
		}, { estimated = true, zone = "Hammer", folder = "Gymnasium" })
	end

	if R.upperGym then
		local y = L2
		W("UpperGymSouth", -80, 52, -28, 52, 10, {
			double(26, "UpperGymDoors", { openAngle = 90, estimated = true }),
		}, { y = y, estimated = true, zone = "SecondFloor", folder = "SecondFloor" })
		W(
			"UpperGymWest",
			-80,
			52,
			-80,
			98,
			10,
			{},
			{ y = y, estimated = true, folder = "SecondFloor", zone = "SecondFloor" }
		)
		W(
			"UpperGymNorth",
			-80,
			98,
			-28,
			98,
			10,
			{},
			{ y = y, estimated = true, folder = "SecondFloor", zone = "SecondFloor" }
		)
		W(
			"UpperGymEast",
			-28,
			52,
			-28,
			98,
			10,
			{},
			{ y = y, estimated = true, folder = "SecondFloor", zone = "SecondFloor" }
		)
	end

	W("PodiumSouth", -30, 0, 76, 0, 4, {}, { y = -4, folder = "Exterior", color = "Concrete", mat = "Concrete" })
	W("PodiumWest", -30, 0, -30, 46, 4, {}, { y = -4, folder = "Exterior", color = "Brick", mat = "Brick" })

	RACUtil.part(
		folders.Exterior,
		"EntryCanopy",
		Vector3.new(70, 1.2, 18),
		CFrame.new(1, 12, -8),
		RACUtil.color(cfg.PALETTE, "Canopy"),
		Enum.Material.Metal
	)
	for _, x in { -24, 26 } do
		RACUtil.part(
			folders.Exterior,
			"CanopyColumn",
			Vector3.new(1.6, 16, 1.6),
			CFrame.new(x, 4, -14),
			RACUtil.color(cfg.PALETTE, "MetalDark"),
			Enum.Material.Metal
		)
	end

	local sign = RACUtil.part(
		folders.Exterior,
		"RAC_Letters",
		Vector3.new(18, 8, 0.4),
		CFrame.new(18, 16, -0.6),
		RACUtil.color(cfg.PALETTE, "Wall"),
		Enum.Material.SmoothPlastic,
		{ canCollide = false }
	)
	RACUtil.sign(sign, "RAC", Color3.fromRGB(255, 255, 255), Color3.fromRGB(20, 22, 24), Enum.NormalId.Back)

	local steps = 22
	local rise = L2 / steps
	RACUtil.stairs(ctx, {
		name = "LobbyMainStair",
		origin = { -26, 0, 10 },
		dir = { 0, 1 },
		steps = steps,
		rise = rise,
		run = 0.95,
		width = 5.5,
		landing = { x = -29, z = 30.2, w = 14, d = 2.2 },
	})
	RACUtil.stairs(ctx, {
		name = "GymMezzStair",
		origin = { 116, 0, 128 },
		dir = { 1, 0 },
		steps = steps,
		rise = rise,
		run = 0.9,
		width = 6,
	})
	RACUtil.stairs(ctx, {
		name = "LockerHallStair",
		origin = { 30, 0, 212 },
		dir = { 0, 1 },
		steps = steps,
		rise = rise,
		run = 0.85,
		width = 5.5,
		landing = { x = 26, z = 230, w = 22, d = 16 },
	})
	RACUtil.stairs(ctx, {
		name = "EntrySteps",
		origin = { 0, -4, -24 },
		dir = { 0, 1 },
		steps = 8,
		rise = 4 / 8,
		run = 1.5,
		width = 22,
	})
	RACUtil.stairs(ctx, {
		name = "UpperExitSteps",
		origin = { 78, -4, 242 },
		dir = { -1, 0 },
		steps = 26,
		rise = (L2 + 4) / 26,
		run = 0.85,
		width = 5,
	})

	local function rail(name, ax, az, bx, bz)
		RACUtil.rail(ctx, { name = name, a = { ax, az }, b = { bx, bz }, y = L2, folder = "SecondFloor" })
	end
	rail("BalconySouthEdge", -12, 32, 26, 32)
	rail("BalconyEastEdge", 16, 6, 16, 32)
	rail("FitnessGalleryWest", 40, 50, 40, 104)
	rail("UpperLinkNorth", 40, 118, 154, 118)
	rail("UpperLinkSouth", 40, 104, 168, 104)
	rail("GymMezzNorth", 140, 142, 252, 142)
	rail("GymWestMezzCourt", 136, 142, 136, 220)
	rail("UpperWestLinkSouth", -80, 36, -20, 36)

	local function row(zone, x1, z1, x2, z2, y, spacing, brightness, range, emergency)
		RACUtil.rowLights(ctx, {
			zone = zone,
			x1 = x1,
			z1 = z1,
			x2 = x2,
			z2 = z2,
			y = y,
			spacing = spacing,
			brightness = brightness,
			range = range,
			emergency = emergency,
			size = if zone == "Gym" or zone == "Cage" or zone == "LinnGym" then { 8, 0.3, 2 } else { 4, 0.22, 1.3 },
		})
	end
	row("Lobby", -10, 12, -10, 40, 26, 14, 1.3, 28)
	row("Lobby", 8, 12, 8, 40, 26, 14, 1.3, 28)
	row("Lounge", 40, 8, 40, 32, 10.5, 12, 1.0, 18)
	row("MainHall", 0, 54, 0, 190, 9, 14, 1.05, 20)
	row("Fitness", 24, 56, 24, 120, 26, 16, 1.2, 26)
	row("Fitness", 56, 56, 56, 120, 26, 16, 1.2, 26)
	row("Hammer", 100, 60, 100, 96, 12, 14, 1.1, 20)
	row("Offices", -50, 60, -50, 120, 9, 12, 0.9, 16)
	row("LinnGym", -170, 70, -170, 130, 22, 18, 1.4, 36)
	row("LinnGym", -120, 70, -120, 130, 22, 18, 1.4, 36)
	row("GymCorridor", 98, 130, 98, 220, 12, 16, 1.0, 18)
	row("Gym", 150, 150, 150, 210, 32, 22, 1.6, 48)
	row("Gym", 200, 150, 200, 210, 32, 22, 1.6, 48)
	row("LockerHall", 10, 210, 10, 240, 12, 14, 1.0, 20)
	row("LockerSuite", 16, 276, 16, 316, 9, 12, 0.85, 16)
	row("Womens", 62, 214, 62, 228, 9, 12, 0.8, 14)
	row("Service", -120, 209, -40, 209, 10, 18, 0.7, 16)
	row("Cage", -160, 250, -160, 310, 23, 20, 1.3, 40)
	row("Cage", -80, 250, -80, 310, 23, 20, 1.3, 40)
	row("SecondFloor", 0, 36, 20, 36, L2 + 10, 16, 0.9, 18)
	local emergencies = {
		{ "Lobby", 0, 8 },
		{ "MainHall", 0, 196 },
		{ "Gym", 150, 126 },
		{ "Cage", -120, 324 },
		{ "LockerHall", 40, 240 },
	}
	for index, e in emergencies do
		RACUtil.fixture(ctx, {
			name = "Emergency_" .. index,
			x = e[2],
			y = 9,
			z = e[3],
			zone = e[1],
			emergency = true,
			brightness = 1.4,
			range = 16,
			size = { 0.8, 0.2, 0.8 },
		})
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.CFrame = CFrame.new(0, 0.5, 14)
	spawn.Color = RACUtil.color(cfg.PALETTE, "GMGreen")
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Parent = folders.FirstFloor

	local scale = RACUtil.part(
		folders.Props,
		"ScaleReference_6ft",
		Vector3.new(1.4, 6, 0.6),
		CFrame.new(-14, 3, 8),
		Color3.fromRGB(255, 80, 80),
		Enum.Material.Neon,
		{ canCollide = false }
	)
	RACUtil.sign(scale, "6 FT", Color3.new(1, 1, 1), Color3.fromRGB(120, 20, 20))

	return {
		folders = folders,
		R = R,
		L2 = L2,
	}
end

return Architecture
