-- ReplicatedStorage.RAC.Modules.RACConfig
-- Scale and palette. 1 stud = 1 foot.
-- Room rectangles live in RACArchitecture so walls and floors stay locked together.
-- Flip INCLUDE_ESTIMATED to false to skip squash courts and the upper gym that
-- are known to exist but were not clearly photographed.

local RACConfig = {
	STUD_PER_FOOT = 1,
	INCLUDE_ESTIMATED = true,
	WALL_T = 0.75,

	-- Floor-to-floor for balconies and the gym viewing mezzanine.
	LEVEL2 = 16,

	PALETTE = {
		Wall = { 232, 230, 224 },
		Ceiling = { 245, 245, 242 },
		Tile = { 186, 178, 166 },
		TileDark = { 150, 144, 134 },
		Wood = { 196, 154, 98 },
		CourtGreen = { 0, 90, 52 },
		GMGreen = { 0, 82, 45 },
		GMGold = { 255, 205, 0 },
		Brick = { 142, 72, 58 },
		Glass = { 170, 200, 205 },
		Frame = { 150, 150, 148 },
		Door = { 186, 178, 164 },
		MetalDark = { 42, 44, 48 },
		Rail = { 176, 180, 184 },
		Carpet = { 78, 82, 86 },
		Fixture = { 248, 246, 236 },
		Stair = { 168, 164, 156 },
		Pad = { 10, 74, 48 },
		Bleacher = { 18, 70, 46 },
		BleacherGold = { 212, 168, 32 },
		LockerWood = { 168, 132, 86 },
		Concrete = { 190, 188, 184 },
		Grass = { 74, 130, 62 },
		Canopy = { 28, 30, 34 },
	},
}

return RACConfig
