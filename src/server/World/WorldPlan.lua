-- Authored layout for the Main Forest. Pure data: no Roblox instances are created
-- here, so the same numbers drive terrain, props, trees and navigation signs.
--
-- World shape: a ~2,200 x 2,200 stud playable basin ringed by mountains that reach
-- out to ~3,000 studs. Everything is deterministic (fixed seed), so rebuilding the
-- world produces exactly the same forest.

local WorldPlan = {}

WorldPlan.SEED = 20261029
WorldPlan.PLAY_RADIUS = 1040
WorldPlan.TERRAIN_RADIUS = 1600
WorldPlan.SPAWN = Vector3.new(0, 0, 800)
WorldPlan.PLAZA = { center = Vector3.new(0, 0, 0), radius = 96 }

-- Open areas: no terrain mounds, no trees, no scatter. Paths are kept clear by
-- distance checks in Placement instead of by listing them here.
WorldPlan.clearings = {
	{ center = Vector3.new(0, 0, 0), radius = 124 },
	{ center = Vector3.new(0, 0, 800), radius = 84 },
	{ center = Vector3.new(520, 0, -120), radius = 96 },
	{ center = Vector3.new(-560, 0, -120), radius = 88 },
	{ center = Vector3.new(0, 0, -640), radius = 118 },
	{ center = Vector3.new(368, 0, 400), radius = 96 },
	{ center = Vector3.new(-420, 0, 420), radius = 120 },
	{ center = Vector3.new(630, 0, -430), radius = 104 },
	{ center = Vector3.new(300, 0, 250), radius = 54 },
}

-- Walking routes. Sampled as Catmull-Rom splines in Placement so the roads curve
-- instead of running as straight lines from A to B.
WorldPlan.paths = {
	{
		name = "Glade Road",
		width = 16,
		points = {
			Vector3.new(0, 0, 800),
			Vector3.new(24, 0, 660),
			Vector3.new(-18, 0, 500),
			Vector3.new(10, 0, 320),
			Vector3.new(-14, 0, 172),
			Vector3.new(0, 0, 96),
		},
	},
	{
		name = "East Road",
		width = 15,
		points = {
			Vector3.new(96, 0, 0),
			Vector3.new(250, 0, -40),
			Vector3.new(430, 0, 24),
			Vector3.new(700, 0, -30),
		},
	},
	{
		name = "West Road",
		width = 15,
		points = {
			Vector3.new(-96, 0, 0),
			Vector3.new(-250, 0, 52),
			Vector3.new(-430, 0, 12),
			Vector3.new(-700, 0, 40),
		},
	},
	{
		name = "North Road",
		width = 15,
		points = {
			Vector3.new(0, 0, -96),
			Vector3.new(16, 0, -280),
			Vector3.new(-14, 0, -460),
			Vector3.new(0, 0, -612),
		},
	},
	{
		name = "Brute Trail",
		width = 12,
		points = {
			Vector3.new(72, 0, 66),
			Vector3.new(190, 0, 200),
			Vector3.new(300, 0, 320),
			Vector3.new(368, 0, 392),
		},
	},
	{
		name = "Mire Trail",
		width = 12,
		points = {
			Vector3.new(-72, 0, 70),
			Vector3.new(-210, 0, 220),
			Vector3.new(-330, 0, 330),
			Vector3.new(-420, 0, 412),
		},
	},
	{
		name = "Crag Trail",
		width = 12,
		points = {
			Vector3.new(700, 0, -30),
			Vector3.new(720, 0, -170),
			Vector3.new(670, 0, -320),
			Vector3.new(622, 0, -412),
		},
	},
	{
		name = "North Loop",
		width = 12,
		points = {
			Vector3.new(-700, 0, 40),
			Vector3.new(-720, 0, -180),
			Vector3.new(-560, 0, -420),
			Vector3.new(-320, 0, -590),
			Vector3.new(0, 0, -612),
		},
	},
}

-- Forest sub-biomes. `families` are weighted picks from TreeFactory, `spacing` and
-- `density` control the jittered scatter grid, `maxTrees` caps the part budget.
WorldPlan.biomes = {
	{
		id = "Whisperwood",
		center = Vector3.new(560, 0, 20),
		radius = 350,
		spacing = 44,
		density = 0.62,
		maxTrees = 64,
		families = { { "Whisperoak", 8 }, { "Gigglepod", 2 }, { "Crystalbloom", 0.5 } },
		undergrowth = { fern = 4, bush = 4, flower = 3, mushroom = 2, log = 1 },
	},
	{
		id = "Tanglevine",
		center = Vector3.new(-570, 0, 20),
		radius = 340,
		spacing = 42,
		density = 0.6,
		maxTrees = 58,
		families = { { "Twistpop", 6 }, { "Gigglepod", 3 }, { "Whisperoak", 1 } },
		undergrowth = { fern = 3, bush = 3, mushroom = 4, flower = 2, log = 1 },
	},
	{
		id = "Crystal Hollow",
		center = Vector3.new(0, 0, -670),
		radius = 300,
		spacing = 46,
		density = 0.52,
		maxTrees = 46,
		families = { { "Crystalbloom", 3 }, { "Emberpine", 2 }, { "Whisperoak", 4 } },
		undergrowth = { fern = 2, bush = 2, flower = 3, mushroom = 1, log = 1 },
	},
	{
		id = "Brute Basin",
		center = Vector3.new(380, 0, 420),
		radius = 280,
		spacing = 50,
		density = 0.42,
		maxTrees = 32,
		families = { { "Emberpine", 4 }, { "Whisperoak", 2 } },
		undergrowth = { fern = 2, bush = 3, flower = 1, log = 1 },
	},
	{
		id = "Mirefen",
		center = Vector3.new(-430, 0, 430),
		radius = 310,
		spacing = 46,
		density = 0.5,
		maxTrees = 44,
		families = { { "Mirewillow", 7 }, { "Twistpop", 2 }, { "Gigglepod", 1 } },
		undergrowth = { fern = 5, bush = 3, mushroom = 3, flower = 1 },
	},
	{
		id = "Highland Crags",
		center = Vector3.new(630, 0, -430),
		radius = 300,
		spacing = 48,
		density = 0.46,
		maxTrees = 34,
		families = { { "Emberpine", 6 }, { "Whisperoak", 1 } },
		undergrowth = { fern = 1, bush = 2, flower = 1 },
	},
	{
		id = "Hollowheart Belt",
		center = Vector3.new(0, 0, 400),
		radius = 250,
		spacing = 46,
		density = 0.5,
		maxTrees = 40,
		families = { { "Whisperoak", 6 }, { "Gigglepod", 2 }, { "Twistpop", 1 } },
		undergrowth = { fern = 3, bush = 3, flower = 4, mushroom = 2, log = 1 },
	},
}

-- Remaining basin fill, so there are no bald patches between the biomes.
WorldPlan.wilds = {
	radius = 1010,
	innerRadius = 150,
	spacing = 92,
	density = 0.34,
	maxTrees = 30,
	families = { { "Whisperoak", 6 }, { "Gigglepod", 2 }, { "Emberpine", 2 }, { "Twistpop", 1 } },
}

-- Harvesting clusters. Gameplay numbers stay in Config.Entities; this is placement.
WorldPlan.zones = {
	Small = {
		{ center = Vector3.new(430, 0, 90), radius = 46, count = 8 },
		{ center = Vector3.new(180, 0, 620), radius = 38, count = 6 },
		{ center = Vector3.new(-430, 0, 90), radius = 44, count = 8 },
		{ center = Vector3.new(-300, 0, 300), radius = 34, count = 6 },
		{ center = Vector3.new(80, 0, 380), radius = 36, count = 5 },
	},
	Elite = {
		{ center = Vector3.new(300, 0, 350), radius = 40, count = 5 },
		{ center = Vector3.new(680, 0, -80), radius = 34, count = 3 },
		{ center = Vector3.new(640, 0, -330), radius = 32, count = 3 },
	},
	Rare = {
		{ center = Vector3.new(-60, 0, -540), radius = 36, count = 3 },
		{ center = Vector3.new(-640, 0, -160), radius = 30, count = 2 },
		{ center = Vector3.new(-330, 0, 560), radius = 30, count = 2 },
	},
}

-- Water. Carved to y = -10 and filled up to WATER_LEVEL so banks read as beaches.
WorldPlan.WATER_LEVEL = -2.6
WorldPlan.lakes = {
	{ center = Vector3.new(-430, 0, 470), radius = 118 },
	{ center = Vector3.new(-620, 0, 300), radius = 36 },
	{ center = Vector3.new(300, 0, 150), radius = 30 },
}
WorldPlan.streams = {
	{
		points = {
			Vector3.new(-452, 0, 470),
			Vector3.new(-520, 0, 452),
			Vector3.new(-576, 0, 414),
			Vector3.new(-615, 0, 352),
			Vector3.new(-620, 0, 306),
		},
		width = 16,
	},
}

-- Sense-of-place landmarks, also used to place navigation signs.
WorldPlan.landmarks = {
	{ id = "greatbrain", position = Vector3.new(-70, 0, 748), rotation = -1.1, label = "GREATBRAIN ANCIENT" },
	{ id = "colossus", position = Vector3.new(520, 0, -120), rotation = -0.4, label = "COLOSSUS RUINS" },
	{ id = "mushroomRing", position = Vector3.new(-560, 0, -120), rotation = 0.9, label = "MUSHROOM RING" },
	{ id = "spire", position = Vector3.new(0, 0, -646), rotation = 0, label = "STARFALL SPIRE" },
	{ id = "grotto", position = Vector3.new(624, 0, -438), rotation = 0.2, label = "SKYFALL GROTTO" },
	{ id = "watchtower", position = Vector3.new(300, 0, 250), rotation = 0.3, label = "OLD WATCHTOWER" },
	{ id = "sunkenArch", position = Vector3.new(-414, 0, 556), rotation = -0.35, label = "SUNKEN ARCH" },
	{ id = "trainingCamp", position = Vector3.new(368, 0, 400), rotation = 0, label = "TRAINING CAMP" },
}

-- Direction signs at the plaza and the glade.
WorldPlan.signs = {
	{ position = Vector3.new(34, 0, 84), facing = Vector3.new(0, 0, -1), title = "HOLLOWHEART PLAZA", lines = { "GLADE  ·  SOUTH", "CRYSTAL HOLLOW  ·  NORTH" } },
	{ position = Vector3.new(-34, 0, 84), facing = Vector3.new(0, 0, -1), title = "TRAILS", lines = { "WHISPERWOOD  ·  EAST", "TANGLEVINE  ·  WEST" } },
	{ position = Vector3.new(26, 0, 742), facing = Vector3.new(0, 0, 1), title = "GREATBRAIN GLADE", lines = { "PLAZA  ·  700 STUDS NORTH", "SHOP: PRESS  B" } },
	{ position = Vector3.new(-26, 0, 742), facing = Vector3.new(0, 0, 1), title = "BIOME TRAILS", lines = { "BRUTE BASIN  ·  SOUTH-EAST", "MIREFEN  ·  SOUTH-WEST" } },
}

return WorldPlan
