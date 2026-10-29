local Config = {}

Config.TAG_HARVESTABLE = "Harvestable"
Config.TAG_EVENT_BOSS = "EventBoss"
Config.STYLE_VERSION = 4

Config.BASE_WALK_SPEED = 16
Config.BASE_MAX_HEALTH = 100
Config.CRIT_MULTIPLIER = 2

Config.Tools = {
	Chaotic = {
		id = "Chaotic",
		displayName = "Chaotic Smasher",
		damage = 18,
		cooldown = 0.45,
		range = 18,
		starter = true,
		color = Color3.fromRGB(255, 90, 40),
		accent = Color3.fromRGB(255, 210, 120),
	},
	Laser = {
		id = "Laser",
		displayName = "Brainrot Laser",
		damage = 32,
		cooldown = 0.35,
		range = 42,
		unlockLevel = 3,
		unlockCoins = 150,
		color = Color3.fromRGB(80, 220, 255),
		accent = Color3.fromRGB(190, 250, 255),
	},
	Sonic = {
		id = "Sonic",
		displayName = "Sonic Wave",
		damage = 48,
		cooldown = 0.5,
		range = 28,
		legendary = true,
		color = Color3.fromRGB(255, 70, 200),
		accent = Color3.fromRGB(255, 190, 240),
	},
}

Config.Perks = {
	MoveSpeed = {
		id = "MoveSpeed",
		displayName = "Move Speed",
		costCoins = 80,
		maxLevel = 5,
		perLevel = 2,
	},
	CritChance = {
		id = "CritChance",
		displayName = "Crit Chance",
		costCoins = 100,
		maxLevel = 5,
		perLevel = 0.05,
	},
	MaxHealth = {
		id = "MaxHealth",
		displayName = "Max Health",
		costCoins = 90,
		maxLevel = 5,
		perLevel = 15,
	},
}

-- Every entity keeps its gameplay numbers. The extra fields below are purely
-- visual identity (see EntityFactory) plus label tuning (see EntityFX).
Config.Entities = {
	Small = {
		hp = 40,
		coins = { 8, 14 },
		xp = { 6, 10 },
		shout = "SKIBIDI??",
		displayName = "Skib Sprout",
		tier = "COMMON",
		color = Color3.fromRGB(92, 230, 130),
		accent = Color3.fromRGB(250, 255, 170),
		secondary = Color3.fromRGB(42, 150, 88),
		glow = Color3.fromRGB(150, 255, 190),
		tierColor = Color3.fromRGB(158, 236, 178),
		size = Vector3.new(4.2, 7.2, 4.2),
		respawn = 6,
		rareDropChance = 0,
		labelDistance = 26,
		labelWidth = 68,
		labelHeight = 18,
		bobAmplitude = 0.16,
		bobSpeed = 1.9,
	},
	Elite = {
		hp = 120,
		coins = { 22, 36 },
		xp = { 18, 28 },
		shout = "TRALALERO!!!",
		displayName = "Trala Brute",
		tier = "ELITE",
		color = Color3.fromRGB(255, 162, 48),
		accent = Color3.fromRGB(255, 230, 140),
		secondary = Color3.fromRGB(206, 96, 34),
		glow = Color3.fromRGB(255, 186, 96),
		tierColor = Color3.fromRGB(255, 198, 104),
		size = Vector3.new(6.2, 11.5, 6.2),
		respawn = 10,
		rareDropChance = 0.04,
		labelDistance = 34,
		labelWidth = 76,
		labelHeight = 20,
		bobAmplitude = 0.2,
		bobSpeed = 1.5,
	},
	Rare = {
		hp = 220,
		coins = { 50, 80 },
		xp = { 40, 60 },
		shout = "TUNG TUNG...",
		displayName = "Tung Crystal",
		tier = "RARE",
		color = Color3.fromRGB(168, 92, 255),
		accent = Color3.fromRGB(255, 150, 255),
		secondary = Color3.fromRGB(92, 52, 190),
		glow = Color3.fromRGB(206, 158, 255),
		tierColor = Color3.fromRGB(212, 158, 255),
		size = Vector3.new(7, 13.5, 7),
		respawn = 16,
		rareDropChance = 0.12,
		labelDistance = 40,
		labelWidth = 80,
		labelHeight = 20,
		bobAmplitude = 0.34,
		bobSpeed = 1.1,
	},
}

-- Boss arena + spawn anchors. Forest layout, biomes, trails and harvesting
-- clusters live in src/server/World/WorldPlan.lua.
Config.WorldLayout = {
	spawnPoint = Vector3.new(0, 2.2, 800),
	plazaRadius = 96,
	bossSpawn = Vector3.new(0, 1.7, 0),
}

Config.XP = {
	base = 50,
	growth = 25,
}

Config.Event = {
	interval = 180,
	firstDelay = 45,
	hp = 2500,
	coins = { 120, 200 },
	xp = { 80, 140 },
	legendaryChance = 0.25,
	duration = 90,
	size = Vector3.new(14, 24, 14),
	shout = "GIGANTIC BRAINROT HAS AWOKEN",
	tier = "GIGANTIC",
	spawn = Vector3.new(0, 0.3, 0),
	color = Color3.fromRGB(255, 58, 96),
	accent = Color3.fromRGB(255, 210, 90),
	secondary = Color3.fromRGB(150, 24, 60),
	glow = Color3.fromRGB(255, 92, 140),
	tierColor = Color3.fromRGB(255, 120, 150),
	bobAmplitude = 0.42,
	bobSpeed = 0.85,
}

Config.ShoutCooldown = 1.4
Config.AutoSaveSeconds = 60
Config.DataStoreName = "BrainrotWorld_v1"

function Config.xpToNext(level: number): number
	return Config.XP.base + (level - 1) * Config.XP.growth
end

function Config.rollRange(range: { number }): number
	return math.random(range[1], range[2])
end

return Config
