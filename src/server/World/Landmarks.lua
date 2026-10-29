-- Hero landmarks: the spawn glade, the central plaza, and the eight discoveries
-- that give the forest a mental map (ancient tree, colossus, mushroom ring,
-- floating spire, waterfall grotto, watchtower, sunken arch, training camp).

local Build = require(script.Parent.Build)
local Placement = require(script.Parent.Placement)
local Prop = require(script.Parent.PropFactory)

local Landmarks = {}

local STONE = {
	mid = Color3.fromRGB(154, 150, 164),
	dark = Color3.fromRGB(104, 100, 120),
	light = Color3.fromRGB(196, 190, 202),
	moss = Color3.fromRGB(92, 148, 96),
}

local WOOD = {
	mid = Color3.fromRGB(122, 86, 56),
	dark = Color3.fromRGB(80, 56, 38),
}

local BARK = Color3.fromRGB(98, 72, 54)
local BARK_DEEP = Color3.fromRGB(64, 46, 38)
local GOLD = Color3.fromRGB(255, 206, 110)
local PINK = Color3.fromRGB(255, 104, 176)
local VIOLET = Color3.fromRGB(186, 128, 255)
local CYAN = Color3.fromRGB(120, 226, 255)

local LEAF = {
	Color3.fromRGB(44, 112, 74),
	Color3.fromRGB(62, 140, 86),
	Color3.fromRGB(88, 172, 100),
}

-- ------------------------------------------------------------------- the glade

function Landmarks.glade(parent: Instance, position: Vector3)
	local cf = CFrame.new(position)
	Build.disc(parent, "GladeFloor", 116, 0.5, cf * CFrame.new(0, 0.25, 0), Color3.fromRGB(120, 112, 116), Enum.Material.Cobblestone, { collide = true })
	Build.disc(parent, "GladeInlayOuter", 92, 0.12, cf * CFrame.new(0, 0.46, 0), GOLD, Enum.Material.Neon, { transparency = 0.6 })
	Build.disc(parent, "GladeInlayInner", 58, 0.1, cf * CFrame.new(0, 0.5, 0), PINK, Enum.Material.Neon, { transparency = 0.65 })

	-- steps down toward the Glade Road
	for i = 1, 4 do
		Build.block(
			parent,
			"GladeStep",
			Vector3.new(30 + i * 4, 0.45, 2.6),
			cf * CFrame.new(0, 0.5 - i * 0.14, -50 - i * 2.4),
			STONE.light:Lerp(STONE.mid, i * 0.2),
			Enum.Material.Cobblestone,
			{ collide = true, shadow = false }
		)
	end

	-- a welcoming arch on the road entrance
	Prop.arch(parent, cf * CFrame.new(0, 0.4, -54), PINK, 0.72)

	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2 + 0.5
		Prop.lantern(parent, cf * CFrame.new(math.cos(angle) * 56, 0.4, math.sin(angle) * 56), (i % 2 == 0) and PINK or GOLD, i % 3 == 0)
	end

	-- low stone benches facing the spawn
	for i = 1, 4 do
		local angle = math.pi * 0.25 + (i - 1) * math.pi * 0.5
		Build.block(
			parent,
			"Bench",
			Vector3.new(9, 0.8, 3),
			cf * CFrame.new(math.cos(angle) * 66, 1.2, math.sin(angle) * 66) * CFrame.Angles(0, -angle, 0),
			STONE.mid,
			Enum.Material.Granite,
			{ collide = true }
		)
	end

	Prop.fence(parent, position + Vector3.new(-74, 0.2, -24), position + Vector3.new(-78, 0.2, 44), PINK)
	Prop.fence(parent, position + Vector3.new(74, 0.2, -24), position + Vector3.new(78, 0.2, 44), PINK)

	Prop.shopStall(parent, cf * CFrame.new(40, 0.4, 18) * CFrame.Angles(0, -0.5, 0), PINK)
end

-- ------------------------------------------------------------------- the plaza

function Landmarks.plaza(parent: Instance)
	Build.disc(parent, "PlazaFloor", 192, 0.5, CFrame.new(0, 0.22, 0), Color3.fromRGB(122, 112, 116), Enum.Material.Cobblestone, { collide = true })
	Build.disc(parent, "PlazaInner", 124, 0.2, CFrame.new(0, 0.36, 0), Color3.fromRGB(96, 90, 108), Enum.Material.Slate, { collide = true })
	Build.disc(parent, "PlazaRingViolet", 112, 0.1, CFrame.new(0, 0.44, 0), VIOLET, Enum.Material.Neon, { transparency = 0.6 })
	Build.disc(parent, "PlazaRingGold", 80, 0.1, CFrame.new(0, 0.46, 0), GOLD, Enum.Material.Neon, { transparency = 0.62 })
	Build.disc(parent, "BossSigil", 60, 0.1, CFrame.new(0, 0.48, 0), PINK, Enum.Material.Neon, { transparency = 0.45 })

	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		Build.block(
			parent,
			"SigilRune",
			Vector3.new(5.2, 0.1, 1.4),
			CFrame.new(math.cos(angle) * 38, 0.5, math.sin(angle) * 38) * CFrame.Angles(0, -angle, 0),
			GOLD,
			Enum.Material.Neon,
			{ transparency = 0.4, shadow = false }
		)
	end

	-- eight pillars, deliberately between the eight road entrances
	for i = 1, 8 do
		local angle = math.rad(22.5) + (i - 1) * math.pi * 0.25
		local x, z = math.cos(angle) * 74, math.sin(angle) * 74
		local base = CFrame.new(x, 0.3, z)
		local accent = (i % 2 == 0) and CYAN or PINK
		Build.block(parent, "PillarBase", Vector3.new(7.4, 2.2, 7.4), base * CFrame.new(0, 1.1, 0), STONE.dark, Enum.Material.Slate, { collide = true })
		Build.column(parent, "PillarShaft", 19, 4.2, base * CFrame.new(0, 9.4, 0), STONE.mid, Enum.Material.Granite, { collide = true })
		Build.block(parent, "PillarCap", Vector3.new(7.6, 1.4, 7.6), base * CFrame.new(0, 18.4, 0), STONE.light, Enum.Material.Granite, { collide = true })
		Build.disc(parent, "PillarRing", 6.6, 0.4, base * CFrame.new(0, 19.3, 0), accent, Enum.Material.Neon, { transparency = 0.25 })
		local shard = Build.block(
			parent,
			"PillarShard",
			Vector3.new(1.8, 6.4, 1.8),
			base * CFrame.new(0, 23.2, 0) * CFrame.Angles(0.2, angle, 0.16),
			accent,
			Enum.Material.Glass,
			{ transparency = 0.15, shadow = false }
		)
		Build.sparkle(shard, accent, 1.6, { size = 0.24, lifetime = Vector2.new(1, 2), light = 0.8 })
		if i % 2 == 0 then
			Build.glow(shard, accent, 0.6, 18)
		end
	end

	for i = 1, 4 do
		local angle = math.rad(22.5) + (i - 1) * math.pi * 0.5
		Prop.brazier(parent, CFrame.new(math.cos(angle) * 90, 0.3, math.sin(angle) * 90), (i % 2 == 0) and PINK or GOLD, true)
	end

	-- Hollowheart beacon: a floating shard that can be seen from most of the basin
	local beaconY = 64
	Build.disc(parent, "BeaconRingA", 26, 0.4, CFrame.new(0, beaconY - 12, 0), PINK, Enum.Material.Neon, { transparency = 0.55 })
	Build.disc(parent, "BeaconRingB", 16, 0.35, CFrame.new(0, beaconY - 6, 0), GOLD, Enum.Material.Neon, { transparency = 0.5 })
	local core = Build.block(
		parent,
		"BeaconCore",
		Vector3.new(5.5, 22, 5.5),
		CFrame.new(0, beaconY, 0) * CFrame.Angles(0, 0.8, 0.06),
		PINK,
		Enum.Material.Neon,
		{ transparency = 0.12, shadow = false }
	)
	Build.sparkle(core, PINK, 5, { size = 0.4, lifetime = Vector2.new(1.4, 2.8), light = 0.9 })
	Build.glow(core, PINK, 1.1, 40)
end

-- ------------------------------------------------------------- Greatbrain tree

function Landmarks.greatbrain(parent: Instance, position: Vector3, rotation: number)
	local cf = CFrame.new(position) * CFrame.Angles(0, rotation, 0)

	local trunks = {
		{ 0, 0, 17, 74 },
		{ 4.5, 3, 14, 86 },
		{ -4.5, -2, 15, 80 },
	}
	for i, t in trunks do
		Build.column(
			parent,
			"AncientTrunk",
			t[4],
			t[3],
			cf * CFrame.new(t[1], t[4] * 0.5, t[2]) * CFrame.Angles(0.02 * i, 0.5 * i, -0.025 * i),
			i == 1 and BARK or BARK_DEEP,
			Enum.Material.Wood,
			{ collide = true }
		)
	end

	-- buttress roots
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		Build.ball(
			parent,
			"AncientRoot",
			Vector3.new(32, 12, 15),
			cf * CFrame.new(math.cos(angle) * 15, 3.4, math.sin(angle) * 15) * CFrame.Angles(0, -angle, 0.24),
			BARK_DEEP,
			Enum.Material.Wood,
			{ collide = i % 2 == 0, shadow = i <= 4 }
		)
	end

	-- bark ridges
	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2 + 0.3
		Build.block(
			parent,
			"BarkRidge",
			Vector3.new(2.4, 30, 1.2),
			cf * CFrame.new(math.cos(angle) * 8.4, 24, math.sin(angle) * 8.4) * CFrame.Angles(0, -angle, 0.02),
			BARK_DEEP,
			Enum.Material.Wood,
			{ shadow = false }
		)
	end

	-- the face
	local faceCf = cf * CFrame.new(0, 50, -8.2)
	for _, side in { -1, 1 } do
		Build.ball(parent, "AncientEye", Vector3.new(6.6, 7.0, 2.8), faceCf * CFrame.new(side * 5.2, 3.6, -0.2), Build.EYE, Enum.Material.SmoothPlastic, { shadow = false })
		Build.ball(parent, "AncientPupil", Vector3.new(2.4, 2.8, 1.4), faceCf * CFrame.new(side * 5.0, 3.4, -1.8), Color3.fromRGB(255, 236, 150), Enum.Material.Neon, { shadow = false })
		Build.block(
			parent,
			"AncientBrow",
			Vector3.new(8.4, 1.2, 1.6),
			faceCf * CFrame.new(side * 5.4, 8.4, -0.8) * CFrame.Angles(0, 0, side * 0.2),
			BARK_DEEP,
			Enum.Material.Wood,
			{ shadow = false }
		)
	end
	Build.block(parent, "AncientMouth", Vector3.new(13, 2.8, 1.8), faceCf * CFrame.new(0, -4.2, -0.4) * CFrame.Angles(0, 0, 0.05), Build.MOUTH, Enum.Material.SmoothPlastic, { shadow = false })
	for i = 1, 5 do
		Build.block(
			parent,
			"AncientTooth",
			Vector3.new(1.5, 1.7, 1.0),
			faceCf * CFrame.new(-4.8 + (i - 1) * 2.4, -3.4, -1.2),
			Build.BONE,
			Enum.Material.SmoothPlastic,
			{ shadow = false }
		)
	end

	-- gnarled branches
	for i = 1, 6 do
		local angle = i * 1.05
		local y = 54 + i * 3.4
		local length = 30 + (i % 3) * 5
		local from = cf * CFrame.new(math.cos(angle) * 6, y, math.sin(angle) * 6) * CFrame.Angles(0, -angle, 0)
		local seg1 = from * CFrame.Angles(0, 0, math.rad(56 - i * 2))
		Build.column(parent, "AncientBranch", length * 0.62, 4.4, seg1 * CFrame.new(0, length * 0.31, 0), BARK, Enum.Material.Wood, { shadow = false })
		local seg2 = seg1 * CFrame.new(0, length * 0.62, 0) * CFrame.Angles(0, 0, math.rad(-22))
		Build.column(parent, "AncientBranchTip", length * 0.42, 3.2, seg2 * CFrame.new(0, length * 0.21, 0), BARK, Enum.Material.Wood, { shadow = false })
	end

	-- canopy
	local canopy = {
		{ 0, 104, 0, 58, 32, 54 },
		{ 0, 92, 0, 46, 24, 44 },
		{ -28, 100, 8, 40, 24, 38 },
		{ 30, 98, -8, 38, 22, 36 },
		{ 4, 114, -22, 36, 22, 34 },
		{ 8, 110, 26, 34, 20, 32 },
		{ -16, 118, -12, 28, 18, 26 },
		{ 18, 116, 14, 26, 16, 24 },
		{ -6, 116, 2, 30, 18, 28 },
	}
	for i, c in canopy do
		local roll = (i % 2 == 0) and 0.06 or -0.06
		Build.ball(
			parent,
			"AncientCanopy",
			Vector3.new(c[4], c[5], c[6]),
			cf * CFrame.new(c[1], c[2], c[3]) * CFrame.Angles(0.1 * (i % 3), i * 0.7, roll),
			LEAF[(i % #LEAF) + 1],
			Enum.Material.LeafyGrass,
			{ shadow = i <= 3 }
		)
	end

	-- hanging lanterns in the lower canopy
	for i = 1, 4 do
		local angle = (i / 4) * math.pi * 2 + 0.4
		local x, z = math.cos(angle) * 30, math.sin(angle) * 30
		Build.column(parent, "LanternCord", 12, 0.3, cf * CFrame.new(x, 80, z), BARK_DEEP, Enum.Material.Wood, { shadow = false })
		local lamp = Build.ball(parent, "GlowLantern", Vector3.new(2.4, 3.0, 2.4), cf * CFrame.new(x, 73, z), (i % 2 == 0) and GOLD or PINK, Enum.Material.Neon, { shadow = false })
		Build.sparkle(lamp, (i % 2 == 0) and GOLD or PINK, 2, { size = 0.2, lifetime = Vector2.new(1, 2), light = 0.9 })
		if i <= 2 then
			Build.glow(lamp, (i % 2 == 0) and GOLD or PINK, 0.8, 24)
		end
	end

	-- glowing runes carved into the bark
	for i, y in { 20, 30, 40, 62 } do
		local rune = Build.block(parent, "BarkRune", Vector3.new(2.0, 3.4, 0.6), cf * CFrame.new(math.cos(1.1) * 8.6, y, math.sin(1.1) * 8.6 - 0.4) * CFrame.Angles(0, -1.1, 0), VIOLET, Enum.Material.Neon, { shadow = false })
		if i == 1 then
			Build.glow(rune, VIOLET, 0.5, 14)
		end
	end

	-- hanging vines
	for i = 1, 4 do
		local angle = i * 1.7
		Build.ball(
			parent,
			"Vine",
			Vector3.new(1.1, 22 + i * 3, 1.1),
			cf * CFrame.new(math.cos(angle) * 32, 82, math.sin(angle) * 32) * CFrame.Angles(0.04, 0, 0.03),
			Color3.fromRGB(74, 138, 88),
			Enum.Material.Grass,
			{ shadow = false }
		)
	end
end

-- ------------------------------------------------------------------- colossus

function Landmarks.colossus(parent: Instance, position: Vector3, rotation: number)
	local cf = CFrame.new(position) * CFrame.Angles(0, rotation, 0)
	Build.disc(parent, "ColossusBase", 66, 0.9, cf * CFrame.new(0, 0.3, 0), STONE.dark, Enum.Material.Slate, { collide = true })
	Build.disc(parent, "ColossusStep", 46, 1.4, cf * CFrame.new(0, 1.2, 0), STONE.mid, Enum.Material.Granite, { collide = true })

	for _, side in { -1, 1 } do
		Build.block(parent, "ColossusLeg", Vector3.new(10, 24, 10), cf * CFrame.new(side * 7.5, 13.6, 0), STONE.mid, Enum.Material.Granite, { collide = true })
		Build.block(parent, "ColossusFoot", Vector3.new(13, 3.4, 16), cf * CFrame.new(side * 7.5, 3.4, -1.4), STONE.dark, Enum.Material.Granite, { collide = true })
	end
	Build.block(parent, "ColossusTorso", Vector3.new(24, 20, 14), cf * CFrame.new(0, 34, 0) * CFrame.Angles(0.1, 0, 0.04), STONE.light, Enum.Material.Granite, { collide = true })
	Build.block(parent, "ColossusChest", Vector3.new(18, 10, 1.6), cf * CFrame.new(0, 36, -7.4) * CFrame.Angles(0.1, 0, 0), STONE.mid, Enum.Material.Slate, { shadow = false })
	Build.ball(parent, "ColossusShoulder", Vector3.new(13, 10, 12), cf * CFrame.new(-13.5, 43, 0), STONE.mid, Enum.Material.Granite, { shadow = false })
	Build.ball(parent, "ColossusShoulderBroken", Vector3.new(11, 8, 10), cf * CFrame.new(13.5, 43, 0) * CFrame.Angles(0, 0, -0.2), STONE.dark, Enum.Material.Granite, { shadow = false })

	-- left arm still holding its pedestal
	local armCf = cf * CFrame.new(-17, 38, 0) * CFrame.Angles(0, 0, math.rad(14))
	Build.column(parent, "ColossusArm", 16, 8, armCf * CFrame.new(0, -8, 0), STONE.mid, Enum.Material.Granite, { collide = true })
	Build.ball(parent, "ColossusFist", Vector3.new(11, 9, 11), cf * CFrame.new(-20, 20, 0), STONE.light, Enum.Material.Granite, { collide = true })
	-- broken right arm: stump only
	Build.column(parent, "ColossusStump", 7, 8, cf * CFrame.new(16, 38, 0) * CFrame.Angles(0, 0, math.rad(-24)), STONE.dark, Enum.Material.Granite, { shadow = false })

	-- fallen head
	local headCf = cf * CFrame.new(19, 4.6, -12) * CFrame.Angles(0.2, -0.7, 0.5)
	Build.ball(parent, "ColossusHead", Vector3.new(14, 12, 13), headCf, STONE.mid, Enum.Material.Granite, { collide = true })
	Build.ball(parent, "ColossusEye", Vector3.new(1.8, 2.2, 0.8), headCf * CFrame.new(-2.6, 1.4, -6.6), CYAN, Enum.Material.Neon, { shadow = false })
	Build.ball(parent, "ColossusEyeDead", Vector3.new(1.8, 2.2, 0.8), headCf * CFrame.new(2.8, 1.4, -6.6), STONE.dark, Enum.Material.Slate, { shadow = false })
	Build.block(parent, "ColossusJaw", Vector3.new(8, 2.4, 6), headCf * CFrame.new(0, -4.4, -4.4), STONE.dark, Enum.Material.Granite, { shadow = false })

	-- rubble and fallen columns
	for i = 1, 7 do
		local angle = i * 1.3
		Prop.rock(parent, cf * CFrame.new(math.cos(angle) * (24 + i * 2), 0.9, math.sin(angle) * (24 + i * 2)), Placement.rng(i * 13), 0.8 + (i % 3) * 0.25)
	end
	for i = 1, 3 do
		Prop.ruinColumn(parent, cf * CFrame.new(-26 + i * 24, 0.8, 22 - i * 6), Placement.rng(i + 20))
	end
	Prop.brazier(parent, cf * CFrame.new(-22, 1.4, -16), CYAN, true)
	Prop.brazier(parent, cf * CFrame.new(22, 1.4, -16), CYAN, false)
end

-- -------------------------------------------------------------- mushroom ring

function Landmarks.mushroomRing(parent: Instance, position: Vector3, rotation: number)
	local cf = CFrame.new(position) * CFrame.Angles(0, rotation, 0)
	Build.disc(parent, "RingMoss", 84, 0.4, cf * CFrame.new(0, 0.2, 0), STONE.moss, Enum.Material.Grass, { collide = true })
	local pool = Build.disc(parent, "RingPool", 26, 0.2, cf * CFrame.new(0, 0.42, 0), Color3.fromRGB(140, 246, 236), Enum.Material.Neon, { transparency = 0.62 })
	Build.sparkle(pool, Color3.fromRGB(180, 255, 246), 2, { size = 0.3, lifetime = Vector2.new(1, 2), light = 0.9 })

	for i = 1, 7 do
		local angle = (i / 7) * math.pi * 2
		Prop.giantMushroom(
			parent,
			cf * CFrame.new(math.cos(angle) * 27, 0.3, math.sin(angle) * 27),
			Placement.rng(i * 7),
			0.82 + (i % 3) * 0.18
		)
	end
	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2 + 0.2
		Prop.mushroom(parent, cf * CFrame.new(math.cos(angle) * 38, 0.3, math.sin(angle) * 38), Placement.rng(i + 40), 1.2, true)
	end
	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2
		local lamp = Build.ball(parent, "FairyLamp", Vector3.new(1.2, 1.4, 1.2), cf * CFrame.new(math.cos(angle) * 12, 7.5 + (i % 3) * 1.6, math.sin(angle) * 12), Color3.fromRGB(190, 255, 220), Enum.Material.Neon, { shadow = false })
		Build.sparkle(lamp, Color3.fromRGB(190, 255, 220), 1.5, { size = 0.2, lifetime = Vector2.new(1, 2), light = 0.9 })
	end
	Prop.brazier(parent, cf * CFrame.new(46, 0.3, 0), VIOLET, false)
end

-- -------------------------------------------------------------- starfall spire

function Landmarks.spire(parent: Instance, position: Vector3, rotation: number)
	local cf = CFrame.new(position) * CFrame.Angles(0, rotation, 0)
	Build.disc(parent, "SpireDaisOuter", 76, 0.8, cf * CFrame.new(0, 0.3, 0), Color3.fromRGB(58, 50, 74), Enum.Material.Slate, { collide = true })
	Build.disc(parent, "SpireDaisMid", 58, 0.8, cf * CFrame.new(0, 1.1, 0), Color3.fromRGB(74, 64, 96), Enum.Material.Slate, { collide = true })
	Build.disc(parent, "SpireDaisInner", 40, 0.8, cf * CFrame.new(0, 1.9, 0), Color3.fromRGB(92, 80, 118), Enum.Material.Slate, { collide = true })
	Build.disc(parent, "SpireRing", 48, 0.16, cf * CFrame.new(0, 2.4, 0), VIOLET, Enum.Material.Neon, { transparency = 0.5 })

	-- floating crystal
	local core = Build.block(parent, "SpireCore", Vector3.new(7, 34, 7), cf * CFrame.new(0, 30, 0) * CFrame.Angles(0.1, 0.6, 0.04), VIOLET, Enum.Material.Neon, { transparency = 0.15, shadow = false })
	Build.block(parent, "SpireTip", Vector3.new(3.4, 12, 3.4), cf * CFrame.new(0, 51, 0) * CFrame.Angles(0, 0.9, 0), CYAN, Enum.Material.Glass, { transparency = 0.2, shadow = false })
	Build.disc(parent, "SpireHaloA", 36, 0.4, cf * CFrame.new(0, 26, 0), CYAN, Enum.Material.Neon, { transparency = 0.55 })
	Build.disc(parent, "SpireHaloB", 26, 0.4, cf * CFrame.new(0, 36, 0) * CFrame.Angles(0.5, 0, 0.2), VIOLET, Enum.Material.Neon, { transparency = 0.5 })
	Build.disc(parent, "SpireHaloC", 20, 0.35, cf * CFrame.new(0, 44, 0) * CFrame.Angles(-0.35, 0, 0.3), CYAN, Enum.Material.Neon, { transparency = 0.45 })
	Build.sparkle(core, VIOLET, 6, { size = 0.4, lifetime = Vector2.new(1.4, 3), light = 0.9 })
	Build.glow(core, VIOLET, 1.2, 46)
	Build.glow(Build.block(parent, "SpireBase", Vector3.new(18, 2.4, 18), cf * CFrame.new(0, 3.4, 0) * CFrame.Angles(0, 0.4, 0), Color3.fromRGB(64, 56, 82), Enum.Material.Slate, { collide = true }), VIOLET, 0.6, 20)

	for i = 1, 4 do
		local angle = (i / 4) * math.pi * 2 + 0.4
		Prop.crystal(parent, cf * CFrame.new(math.cos(angle) * 33, 2.2, math.sin(angle) * 33), Placement.rng(i + 60), (i % 2 == 0) and CYAN or VIOLET, 1.5)
		local floatAngle = angle + 0.6
		Build.ball(
			parent,
			"FloatingRock",
			Vector3.new(9, 6, 8),
			cf * CFrame.new(math.cos(floatAngle) * 46, 12 + i * 3.5, math.sin(floatAngle) * 46) * CFrame.Angles(0.2 * i, floatAngle, 0.1),
			Color3.fromRGB(80, 70, 100),
			Enum.Material.Rock,
			{ shadow = false }
		)
	end
	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2
		Prop.brazier(parent, cf * CFrame.new(math.cos(angle) * 66, 0.3, math.sin(angle) * 66), (i % 2 == 0) and CYAN or VIOLET, false)
	end
end

-- --------------------------------------------------------------------- grotto

function Landmarks.grotto(parent: Instance, position: Vector3, rotation: number)
	local cf = CFrame.new(position) * CFrame.Angles(0, rotation, 0)
	local rockColor = Color3.fromRGB(96, 94, 112)

	-- cliff wall
	for i = 1, 7 do
		local x = -36 + (i - 1) * 12
		local height = 34 + (i % 3) * 14
		Build.ball(
			parent,
			"CliffRock",
			Vector3.new(24, height, 22),
			cf * CFrame.new(x, height * 0.30, -26) * CFrame.Angles(0.1 * (i % 2), i * 0.6, 0.06 * (i % 3)),
			rockColor:Lerp(Color3.fromRGB(140, 136, 152), (i % 3) * 0.2),
			Enum.Material.Rock,
			{ collide = true, shadow = i % 2 == 0 }
		)
	end
	Build.ball(parent, "CliffTop", Vector3.new(96, 26, 30), cf * CFrame.new(0, 52, -28), Color3.fromRGB(112, 108, 126), Enum.Material.Rock, { shadow = false })

	-- plunge pool
	Build.disc(parent, "GrottoPoolRim", 52, 1.0, cf * CFrame.new(0, 0.3, 4), Color3.fromRGB(84, 82, 98), Enum.Material.Slate)
	local pool = Build.disc(parent, "GrottoPool", 42, 0.4, cf * CFrame.new(0, 0.85, 4), Color3.fromRGB(112, 208, 236), Enum.Material.Glass, { transparency = 0.28, reflectance = 0.12 })
	Build.sparkle(pool, Color3.fromRGB(186, 240, 255), 3, { size = 0.3, lifetime = Vector2.new(1, 2), light = 0.7 })

	-- waterfall
	local fall = Build.block(parent, "Waterfall", Vector3.new(11, 40, 2.2), cf * CFrame.new(-2, 24, -14) * CFrame.Angles(0.02, 0, 0.01), Color3.fromRGB(178, 236, 255), Enum.Material.Glass, { transparency = 0.35, shadow = false })
	local mist = Build.sparkle(fall, Color3.fromRGB(214, 246, 255), 14, { size = 0.9, lifetime = Vector2.new(0.8, 1.8), speed = Vector2.new(2, 5), spread = 40, light = 0.5 })
	mist.EmissionDirection = Enum.NormalId.Bottom
	Build.sparkle(pool, Color3.fromRGB(226, 250, 255), 5, { size = 0.6, lifetime = Vector2.new(1, 2.2), speed = Vector2.new(0.6, 2), light = 0.5 })

	-- cave mouth behind the falls
	Build.ball(parent, "CaveBack", Vector3.new(30, 22, 16), cf * CFrame.new(-2, 11, -33), Color3.fromRGB(34, 30, 42), Enum.Material.Slate, { shadow = false })
	for i = 1, 4 do
		Prop.crystal(parent, cf * CFrame.new(-12 + i * 7, 1.2, -27 + (i % 2) * 5), Placement.rng(i + 90), (i % 2 == 0) and CYAN or VIOLET, 0.9)
	end

	-- wooden lookout platform, reachable by a ramp
	Build.block(parent, "LookoutDeck", Vector3.new(22, 0.6, 16), cf * CFrame.new(26, 7.6, 2), WOOD.mid, Enum.Material.WoodPlanks, { collide = true })
	for _, p in { Vector3.new(16, 0, -5), Vector3.new(36, 0, -5), Vector3.new(16, 0, 9), Vector3.new(36, 0, 9) } do
		Build.column(parent, "DeckPost", 8.2, 0.9, cf * CFrame.new(p.X, 3.8, p.Z), WOOD.dark, Enum.Material.Wood, { collide = true })
	end
	for _, p in { Vector3.new(16, 0, 9), Vector3.new(36, 0, 9) } do
		Build.block(parent, "DeckRail", Vector3.new(21, 0.3, 0.3), cf * CFrame.new(26, 10.4, p.Z), WOOD.dark, Enum.Material.Wood, { shadow = false })
	end
	Build.block(parent, "DeckRamp", Vector3.new(9, 0.6, 20), cf * CFrame.new(26, 4.0, 17) * CFrame.Angles(math.rad(-20), 0, 0), WOOD.mid, Enum.Material.WoodPlanks, { collide = true })
	Prop.lantern(parent, cf * CFrame.new(36, 7.6, 8), CYAN, true)
	Prop.brazier(parent, cf * CFrame.new(-24, 0.4, 10), CYAN, true)
end

-- ------------------------------------------------------------------ watchtower

function Landmarks.watchtower(parent: Instance, position: Vector3, rotation: number)
	local cf = CFrame.new(position) * CFrame.Angles(0, rotation, 0)
	Build.disc(parent, "TowerBase", 54, 0.8, cf * CFrame.new(0, 0.3, 0), STONE.dark, Enum.Material.Slate)
	Build.disc(parent, "TowerCourt", 40, 0.5, cf * CFrame.new(0, 0.55, 0), STONE.mid, Enum.Material.Cobblestone)

	-- One continuous flight of 10 steps (0.84 rise, 2.2 run) up to the deck, so the
	-- landmark is reliably walkable instead of relying on tier-to-tier jumps.
	for i = 1, 10 do
		Build.block(
			parent,
			"TowerStep",
			Vector3.new(11, 0.84, 2.6),
			cf * CFrame.new(0, 0.84 * i - 0.42, 33 - 2.2 * i),
			STONE.mid,
			Enum.Material.WoodPlanks,
			{ collide = true, shadow = false }
		)
	end

	-- deck (top surface at 8.8)
	Build.block(parent, "TowerDeck", Vector3.new(20, 0.8, 20), cf * CFrame.new(0, 8.4, 0), WOOD.mid, Enum.Material.WoodPlanks, { collide = true })
	for _, corner in { Vector2.new(-1, -1), Vector2.new(1, -1), Vector2.new(-1, 1), Vector2.new(1, 1) } do
		Build.column(parent, "TowerPost", 8.4, 1.0, cf * CFrame.new(corner.X * 8.6, 4.2, corner.Y * 8.6), WOOD.dark, Enum.Material.Wood, { collide = true })
	end

	-- railings, with a gap on the +Z side where the stairs arrive
	for _, side in { -1, 1 } do
		Build.block(parent, "TowerRail", Vector3.new(20, 0.3, 0.3), cf * CFrame.new(0, 9.9, side * 9.7), WOOD.dark, Enum.Material.Wood, { shadow = false })
		Build.block(parent, "TowerRail", Vector3.new(0.3, 0.3, 20), cf * CFrame.new(side * 9.7, 9.9, 0), WOOD.dark, Enum.Material.Wood, { shadow = false })
	end
	for _, side in { -1, 1 } do
		Build.block(parent, "TowerRail", Vector3.new(5.0, 0.3, 0.3), cf * CFrame.new(side * 7.2, 9.9, 9.7), WOOD.dark, Enum.Material.Wood, { shadow = false })
	end
	for i = 1, 4 do
		local angle = (i / 4) * math.pi * 2
		Prop.lantern(parent, cf * CFrame.new(math.cos(angle) * 8.6, 8.8, math.sin(angle) * 8.6), GOLD, i == 1)
	end

	-- roof
	for _, corner in { Vector2.new(-1, -1), Vector2.new(1, -1), Vector2.new(-1, 1), Vector2.new(1, 1) } do
		Build.column(parent, "RoofPost", 5.6, 0.8, cf * CFrame.new(corner.X * 7, 11.6, corner.Y * 7), WOOD.dark, Enum.Material.Wood, { shadow = false })
	end
	Build.block(parent, "RoofBeam", Vector3.new(16, 0.4, 16), cf * CFrame.new(0, 14.2, 0), WOOD.dark, Enum.Material.Wood, { shadow = false })
	for i = 1, 3 do
		Build.disc(parent, "RoofTier", 24 - i * 5, 1.2, cf * CFrame.new(0, 14.6 + i * 1.5, 0), i % 2 == 0 and Color3.fromRGB(198, 84, 96) or Color3.fromRGB(160, 62, 74), Enum.Material.Fabric, { shadow = false })
	end
	local lamp = Build.ball(parent, "TowerLamp", Vector3.new(2.6, 3.2, 2.6), cf * CFrame.new(0, 20.2, 0), GOLD, Enum.Material.Neon, { shadow = false })
	Build.sparkle(lamp, GOLD, 3, { size = 0.24, lifetime = Vector2.new(1, 2), light = 0.9 })
	Build.glow(lamp, GOLD, 1.0, 30)
	Prop.banner(parent, cf * CFrame.new(-9.2, 0.6, 0), PINK)
	Prop.fence(parent, position + Vector3.new(-24, 0.6, -14), position + Vector3.new(-24, 0.6, 14), PINK)
	Prop.fence(parent, position + Vector3.new(24, 0.6, -14), position + Vector3.new(24, 0.6, 14), PINK)
end

-- ----------------------------------------------------------------- sunken arch

function Landmarks.sunkenArch(parent: Instance, position: Vector3, rotation: number)
	local cf = CFrame.new(position) * CFrame.Angles(0, rotation, 0)
	-- an islet so the ruin stands in shallow water; it reaches below the water line
	Build.disc(parent, "IsletSkirt", 74, 9.4, cf * CFrame.new(0, -3.6, 0), Color3.fromRGB(210, 190, 148), Enum.Material.Sand, { collide = true })
	Build.disc(parent, "IsletTop", 56, 0.8, cf * CFrame.new(0, 0.3, 0), STONE.moss, Enum.Material.Grass, { collide = true })
	Build.disc(parent, "IsletStone", 34, 0.5, cf * CFrame.new(0, 0.6, 0), STONE.mid, Enum.Material.Slate)

	Prop.arch(parent, cf * CFrame.new(0, 0.5, 0) * CFrame.Angles(0.1, 0, 0.06), CYAN, 1.45)

	for i = 1, 4 do
		local angle = i * 1.5
		Prop.ruinColumn(parent, cf * CFrame.new(math.cos(angle) * 22, 0.8, math.sin(angle) * 22) * CFrame.Angles(0.12 * (i % 2), i, 0.16), Placement.rng(i + 120))
	end
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		Prop.reed(parent, cf * CFrame.new(math.cos(angle) * 33, 0.2, math.sin(angle) * 33), Placement.rng(i + 130))
	end
	Prop.crystal(parent, cf * CFrame.new(-16, 0.9, -8), Placement.rng(140), CYAN, 1.2)
	Prop.brazier(parent, cf * CFrame.new(16, 0.9, 10), CYAN, true)
end

-- --------------------------------------------------------------- training camp

function Landmarks.trainingCamp(parent: Instance, position: Vector3, rotation: number)
	local cf = CFrame.new(position) * CFrame.Angles(0, rotation, 0)
	Build.disc(parent, "CampGround", 80, 0.4, cf * CFrame.new(0, 0.2, 0), Color3.fromRGB(128, 108, 86), Enum.Material.Ground, { collide = true })
	Prop.bonfire(parent, cf * CFrame.new(0, 0.3, 0))

	for i = 1, 2 do
		local x = i == 1 and -18 or 18
		Prop.banner(parent, cf * CFrame.new(x, 0.3, -14), PINK)
	end

	-- weapon rack
	local rack = cf * CFrame.new(16, 0.3, -4)
	Build.column(parent, "RackPost", 5, 0.5, rack * CFrame.new(-2.4, 2.5, 0), WOOD.dark, Enum.Material.Wood, { collide = true })
	Build.column(parent, "RackPost", 5, 0.5, rack * CFrame.new(2.4, 2.5, 0), WOOD.dark, Enum.Material.Wood, { collide = true })
	Build.block(parent, "RackBar", Vector3.new(5.4, 0.35, 0.35), rack * CFrame.new(0, 4.3, 0), GOLD, Enum.Material.Metal, { shadow = false })
	for i = 1, 3 do
		Build.block(parent, "RackBlade", Vector3.new(0.4, 3.0, 0.4), rack * CFrame.new(-1.4 + (i - 1) * 1.4, 2.8, 0) * CFrame.Angles(0, 0, 0.14 * (i - 2)), STONE.light, Enum.Material.Metal, { shadow = false })
	end

	-- bone spikes
	for i = 1, 5 do
		local angle = 0.5 + i * 1.2
		Build.block(
			parent,
			"BoneSpike",
			Vector3.new(1.0, 5.4, 1.0),
			cf * CFrame.new(math.cos(angle) * 26, 2.6, math.sin(angle) * 26) * CFrame.Angles(0.1 * i, angle, 0.16),
			Build.BONE,
			Enum.Material.SmoothPlastic,
			{ shadow = false }
		)
	end

	-- tents: two leaning fabric panels meeting at a ridge
	for i = 1, 2 do
		local angle = math.pi * 0.5 + i * 0.7
		local tent = cf * CFrame.new(math.cos(angle) * 30, 0.3, math.sin(angle) * 30) * CFrame.Angles(0, -angle + 0.4, 0)
		for _, side in { -1, 1 } do
			Build.block(
				parent,
				"TentPanel",
				Vector3.new(7.4, 0.4, 12),
				tent * CFrame.new(side * 3.1, 3.5, 0) * CFrame.Angles(0, 0, side * math.rad(38)),
				side < 0 and Color3.fromRGB(176, 74, 82) or Color3.fromRGB(150, 60, 70),
				Enum.Material.Fabric,
				{ collide = true, shadow = false }
			)
		end
		Build.block(parent, "TentRidge", Vector3.new(1.0, 0.5, 12.4), tent * CFrame.new(0, 5.6, 0), WOOD.dark, Enum.Material.Wood, { shadow = false })
	end

	Prop.fence(parent, position + Vector3.new(-34, 0.2, -26), position + Vector3.new(-34, 0.2, 26), PINK)
	for i = 1, 3 do
		Build.block(parent, "Crate", Vector3.new(3.4, 3.4, 3.4), cf * CFrame.new(-12 + i * 3.6, 1.9, 18) * CFrame.Angles(0, i * 0.4, 0), WOOD.mid, Enum.Material.WoodPlanks, { collide = true })
	end
end

-- ------------------------------------------------------------------- dispatch

local BUILDERS = {
	greatbrain = function(parent, position, rotation)
		Landmarks.greatbrain(parent, position, rotation)
	end,
	colossus = function(parent, position, rotation)
		Landmarks.colossus(parent, position, rotation)
	end,
	mushroomRing = function(parent, position, rotation)
		Landmarks.mushroomRing(parent, position, rotation)
	end,
	spire = function(parent, position, rotation)
		Landmarks.spire(parent, position, rotation)
	end,
	grotto = function(parent, position, rotation)
		Landmarks.grotto(parent, position, rotation)
	end,
	watchtower = function(parent, position, rotation)
		Landmarks.watchtower(parent, position, rotation)
	end,
	sunkenArch = function(parent, position, rotation)
		Landmarks.sunkenArch(parent, position, rotation)
	end,
	trainingCamp = function(parent, position, rotation)
		Landmarks.trainingCamp(parent, position, rotation)
	end,
}

function Landmarks.build(id: string, parent: Instance, position: Vector3, rotation: number)
	local builder = BUILDERS[id]
	if builder then
		builder(parent, position, rotation)
	end
end

return Landmarks
