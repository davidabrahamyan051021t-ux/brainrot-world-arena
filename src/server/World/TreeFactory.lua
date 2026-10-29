-- Premium stylized Brainrot trees, assembled from parts.
--
-- Seven distinct families, each with its own silhouette, bark treatment and
-- canopy language so a forest reads as a place rather than a repeated asset:
--   Whisperoak   - common broadleaf, twisting trunk, layered leaf clusters
--   Gigglepod    - squat "brainrot" tree with a permanent grin in its bark
--   Twistpop     - candy corkscrew trunk with a spiral crown (unusual)
--   Crystalbloom - rare glass-leaf tree with a faint glow, visible from afar
--   Mirewillow   - drooping swamp tree with spore pods
--   Emberpine    - layered highland pine with ember tips
--   (the giant Greatbrain Ancient lives in Landmarks)
--
-- `detail` is either "full" (close to trails, ~20-26 parts) or "simple" (background
-- fill, 4-7 parts). Foliage never collides so players can walk through it, and it is
-- never queryable so the combat raycast ignores it.

local Build = require(script.Parent.Build)

local TreeFactory = {}

local LEAF = {
	deep = Color3.fromRGB(38, 104, 68),
	mid = Color3.fromRGB(58, 140, 82),
	light = Color3.fromRGB(88, 178, 96),
	highlight = Color3.fromRGB(138, 210, 110),
}

local BARK = {
	deep = Color3.fromRGB(74, 50, 38),
	mid = Color3.fromRGB(112, 78, 52),
	pale = Color3.fromRGB(186, 182, 174),
	ashen = Color3.fromRGB(146, 146, 158),
	dark = Color3.fromRGB(58, 42, 56),
}

local CANDY = {
	pink = Color3.fromRGB(255, 118, 186),
	mint = Color3.fromRGB(126, 236, 196),
	violet = Color3.fromRGB(186, 132, 255),
	gold = Color3.fromRGB(255, 206, 112),
}

local function tint(color: Color3, rng, amount: number): Color3
	local shift = rng(-amount, amount)
	if shift > 0 then
		return color:Lerp(Color3.fromRGB(255, 246, 214), shift)
	end
	return color:Lerp(Color3.fromRGB(24, 58, 44), -shift)
end

-- A few flattened "leaf blades" that break up an otherwise smooth canopy sphere.
local function leafBlades(parent, center: Vector3, count: number, radius: number, color: Color3, rng)
	for i = 1, count do
		local angle = (i / count) * math.pi * 2 + rng(-0.35, 0.35)
		local pos = Vector3.new(
			center.X + math.cos(angle) * radius,
			center.Y + rng(-1.6, 1.8),
			center.Z + math.sin(angle) * radius
		)
		Build.ball(
			parent,
			"LeafBlade",
			Vector3.new(rng(3.0, 4.4), 0.42, rng(1.3, 2.0)),
			CFrame.new(pos) * CFrame.Angles(rng(-0.2, 0.2), -angle, rng(-0.5, 0.4)),
			color,
			Enum.Material.LeafyGrass,
			{ shadow = false }
		)
	end
end

local function barkKnots(parent, base: CFrame, height: number, radius: number, rng, count: number)
	for i = 1, count do
		local angle = rng(0, math.pi * 2)
		local y = base.Y + height * rng(0.18, 0.7)
		local pos = Vector3.new(
			base.X + math.cos(angle) * radius,
			y,
			base.Z + math.sin(angle) * radius
		)
		Build.ball(
			parent,
			"BarkKnot",
			Vector3.new(rng(0.7, 1.1), rng(0.6, 1.4), rng(0.4, 0.7)),
			CFrame.new(pos) * CFrame.Angles(0, -angle, rng(-0.3, 0.3)),
			BARK.deep,
			Enum.Material.Wood,
			{ shadow = false }
		)
	end
end

local function roots(parent, base: CFrame, count: number, scale: number, color: Color3, rng)
	for i = 1, count do
		local angle = (i / count) * math.pi * 2 + rng(-0.25, 0.25)
		local offset = Vector3.new(math.cos(angle) * 1.7 * scale, 0.35 * scale, math.sin(angle) * 1.7 * scale)
		Build.ball(
			parent,
			"Root",
			Vector3.new(4.6 * scale, rng(1.2, 1.9) * scale, 2.1 * scale),
			base * CFrame.new(offset) * CFrame.Angles(0, -angle, rng(0.16, 0.32)),
			color,
			Enum.Material.Wood,
			{ shadow = false }
		)
	end
end

-- Eyes + a mouth. Used by the trees that have a face in their bark.
local function face(parent, cf: CFrame, scale: number, eyeColor: Color3, rng)
	local spread = 1.25 * scale
	for _, side in { -1, 1 } do
		Build.ball(
			parent,
			"Eye",
			Vector3.new(2.0, 2.2, 1.0) * scale,
			cf * CFrame.new(spread * side, 0.55 * scale, -0.15 * scale),
			Build.EYE,
			Enum.Material.SmoothPlastic,
			{ shadow = false }
		)
		Build.ball(
			parent,
			"Pupil",
			Vector3.new(0.85, 0.95, 0.5) * scale,
			cf * CFrame.new(spread * side + rng(-0.12, 0.12), 0.5 * scale, -0.72 * scale),
			Build.DARK,
			Enum.Material.SmoothPlastic,
			{ shadow = false }
		)
		Build.block(
			parent,
			"Brow",
			Vector3.new(1.5, 0.28, 0.42) * scale,
			cf * CFrame.new(spread * side, 1.55 * scale, -0.5 * scale)
				* CFrame.Angles(0, 0, rng(-0.2, 0.2) + side * 0.16),
			BARK.deep,
			Enum.Material.Wood,
			{ shadow = false }
		)
	end
	Build.block(
		parent,
		"Mouth",
		Vector3.new(2.9, 0.95, 0.5) * scale,
		cf * CFrame.new(0, -0.9 * scale, -0.5 * scale),
		Build.MOUTH,
		Enum.Material.SmoothPlastic,
		{ shadow = false }
	)
	for i = 1, 2 do
		Build.block(
			parent,
			"Tooth",
			Vector3.new(0.5, 0.45, 0.28) * scale,
			cf * CFrame.new(-0.7 * scale + (i - 1) * 1.4 * scale, -0.62 * scale, -0.78 * scale),
			Build.BONE,
			Enum.Material.SmoothPlastic,
			{ shadow = false }
		)
	end
end

-- ------------------------------------------------------------------ Whisperoak

local function whisperoak(model: Model, base: CFrame, rng, full: boolean)
	local s = rng(0.86, 1.3)
	local height = 24 * s
	local dia = 3.1 * s
	local bark = tint(BARK.mid, rng, 0.16)
	local leaf = tint(LEAF.mid, rng, 0.18)

	roots(model, base, full and 4 or 2, s, bark, rng)

	local leanA = rng(-0.05, 0.05)
	local leanB = rng(-0.06, 0.06)
	Build.column(model, "Trunk", height * 0.52, dia, base * CFrame.new(0, height * 0.26, 0) * CFrame.Angles(leanA, 0, leanB), bark, Enum.Material.Wood, { collide = true })
	if full then
		Build.column(model, "TrunkUpper", height * 0.34, dia * 0.76, base * CFrame.new(leanB * 6, height * 0.66, leanA * 6) * CFrame.Angles(leanB * 1.4, 0, -leanA), bark, Enum.Material.Wood, { shadow = false })
		barkKnots(model, base, height * 0.6, dia * 0.42, rng, 2)
	else
		Build.column(model, "TrunkUpper", height * 0.4, dia * 0.66, base * CFrame.new(0, height * 0.7, 0), bark, Enum.Material.Wood, { shadow = false })
	end

	if full then
		local branchCount = 3
		for i = 1, branchCount do
			local angle = (i / branchCount) * math.pi * 2 + rng(-0.4, 0.4)
			local y = height * rng(0.58, 0.8)
			local length = 7.2 * s
			local cf = base
				* CFrame.new(math.cos(angle) * dia * 0.4, y, math.sin(angle) * dia * 0.4)
				* CFrame.Angles(0, -angle, 0)
				* CFrame.Angles(0, 0, math.rad(52))
			Build.column(model, "Branch", length, 0.85 * s, cf * CFrame.new(0, length * 0.5, 0), bark, Enum.Material.Wood, { shadow = false })
		end
	end

	local crownY = height * 0.94
	Build.ball(model, "Canopy", Vector3.new(16, 9.6, 16) * s, base * CFrame.new(0, crownY, 0), leaf, Enum.Material.LeafyGrass, { shadow = true })
	Build.ball(model, "Canopy", Vector3.new(11.5, 7.6, 11.5) * s, base * CFrame.new(-5.2 * s, crownY - 2.4 * s, 1.6 * s) * CFrame.Angles(0, 0.5, 0.2), tint(LEAF.light, rng, 0.12), Enum.Material.LeafyGrass, { shadow = false })
	Build.ball(model, "Canopy", Vector3.new(12, 8, 12) * s, base * CFrame.new(5.4 * s, crownY - 1.4 * s, -2.2 * s) * CFrame.Angles(0.2, -0.4, -0.15), tint(LEAF.deep, rng, 0.1), Enum.Material.LeafyGrass, { shadow = false })
	if full then
		Build.ball(model, "Canopy", Vector3.new(9.6, 7.4, 9.6) * s, base * CFrame.new(0.8 * s, crownY + 4.2 * s, -1.2 * s) * CFrame.Angles(-0.16, 0.9, 0.1), tint(LEAF.highlight, rng, 0.1), Enum.Material.LeafyGrass, { shadow = false })
		leafBlades(model, Vector3.new(base.X, base.Y + crownY, base.Z), 6, 7.4 * s, tint(LEAF.deep, rng, 0.12), rng)
	end
end

-- ------------------------------------------------------------------- Gigglepod

local function gigglepod(model: Model, base: CFrame, rng, full: boolean)
	local s = rng(0.9, 1.2)
	local height = 13.5 * s
	local dia = 5.2 * s
	local bark = tint(Color3.fromRGB(128, 92, 66), rng, 0.12)
	local leaf = tint(LEAF.light, rng, 0.16)

	roots(model, base, 4, s * 0.9, bark, rng)
	Build.column(model, "Trunk", height * 0.66, dia, base * CFrame.new(0, height * 0.33, 0), bark, Enum.Material.Wood, { collide = true })
	Build.column(model, "TrunkUpper", height * 0.4, dia * 0.82, base * CFrame.new(0, height * 0.66, 0) * CFrame.Angles(0, 0.4, 0.04), bark, Enum.Material.Wood, { shadow = false })

	-- The face is the point of this tree: always visible, always grinning.
	face(model, base * CFrame.new(0, height * 0.48, -dia * 0.46), 0.95 * s, CANDY.pink, rng)

	-- Afro canopy: a ring of fat leaf blobs plus a taller centre.
	local ringY = height * 0.94
	local ringCount = full and 6 or 3
	for i = 1, ringCount do
		local angle = (i / ringCount) * math.pi * 2 + rng(-0.2, 0.2)
		local r = 3.4 * s
		Build.ball(
			model,
			"Canopy",
			Vector3.new(rng(5.6, 7.4), rng(4.4, 5.6), rng(5.6, 7.4)) * s,
			base * CFrame.new(math.cos(angle) * r, ringY + rng(-0.6, 0.8) * s, math.sin(angle) * r) * CFrame.Angles(rng(-0.2, 0.2), angle, rng(-0.2, 0.2)),
			i % 3 == 0 and tint(LEAF.highlight, rng, 0.1) or leaf,
			Enum.Material.LeafyGrass,
			{ shadow = i == 1 }
		)
	end
	Build.ball(model, "Canopy", Vector3.new(8.2, 5.6, 8.2) * s, base * CFrame.new(0, ringY + 3.2 * s, 0) * CFrame.Angles(0.1, 0.5, 0.06), leaf, Enum.Material.LeafyGrass, { shadow = true })

	if full then
		-- Two stubby arms holding candy pods.
		for _, side in { -1, 1 } do
			local armCf = base * CFrame.new(side * dia * 0.55, height * 0.5, 0) * CFrame.Angles(0, 0, side * 0.9)
			Build.column(model, "Arm", 4.4 * s, 0.8 * s, armCf * CFrame.new(0, 2.2 * s, 0), bark, Enum.Material.Wood, { shadow = false })
			Build.ball(model, "Pod", Vector3.new(1.7, 1.9, 1.7) * s, armCf * CFrame.new(0, 4.8 * s, 0), side > 0 and CANDY.pink or CANDY.mint, Enum.Material.SmoothPlastic, { shadow = false })
		end
		leafBlades(model, Vector3.new(base.X, base.Y + ringY, base.Z), 4, 5.4 * s, tint(LEAF.deep, rng, 0.1), rng)
	end
end

-- -------------------------------------------------------------------- Twistpop

local function twistpop(model: Model, base: CFrame, rng, full: boolean)
	local s = rng(0.9, 1.25)
	local segments = full and 6 or 4
	local segHeight = 3.6 * s
	local twist = rng(0.85, 1.15) * 0.95
	local bark = tint(Color3.fromRGB(168, 122, 96), rng, 0.14)

	for i = 1, segments do
		local t = (i - 1) / segments
		local angle = i * twist
		local radius = 0.9 * s
		local cf = base
			* CFrame.new(math.cos(angle) * radius, segHeight * (i - 0.5), math.sin(angle) * radius)
			* CFrame.Angles(math.sin(angle) * 0.16, -angle, math.cos(angle) * 0.16)
		Build.column(
			model,
			"Trunk",
			segHeight * 1.12,
			(2.9 - t * 1.3) * s,
			cf,
			i % 3 == 1 and tint(bark, rng, 0.1) or bark,
			Enum.Material.Wood,
			{ collide = i == 1, shadow = i <= 2 }
		)
	end

	local top = base * CFrame.new(0, segHeight * segments + 1.2 * s, 0)
	-- Spiral crown: candy blobs climbing around a central leaf ball.
	for i = 1, 5 do
		local angle = i * 1.4
		local radius = 3.6 * s
		Build.ball(
			model,
			"Canopy",
			Vector3.new(6.4, 3.0, 6.4) * s,
			top * CFrame.new(math.cos(angle) * radius, i * 0.85 * s, math.sin(angle) * radius) * CFrame.Angles(0.1, -angle, 0.12),
			i % 2 == 0 and tint(LEAF.mid, rng, 0.1) or CANDY.mint,
			Enum.Material.LeafyGrass,
			{ shadow = i == 2 }
		)
	end
	Build.ball(model, "Canopy", Vector3.new(5.6, 4.4, 5.6) * s, top * CFrame.new(0, 5.4 * s, 0), tint(LEAF.highlight, rng, 0.1), Enum.Material.LeafyGrass, { shadow = false })

	if full then
		for i = 1, 3 do
			local angle = i * 2.1
			Build.ball(
				model,
				"CandyPod",
				Vector3.new(1.0, 1.3, 1.0) * s,
				top * CFrame.new(math.cos(angle) * 4.6 * s, 0.4 * s, math.sin(angle) * 4.6 * s),
				i == 1 and CANDY.pink or (i == 2 and CANDY.gold or CANDY.violet),
				Enum.Material.SmoothPlastic,
				{ shadow = false }
			)
		end
	end
end

-- ----------------------------------------------------------------- Crystalbloom

local function crystalbloom(model: Model, base: CFrame, rng, full: boolean)
	local s = rng(0.95, 1.3)
	local height = 22 * s
	local dia = 2.7 * s
	local bark = BARK.pale
	local accent = rng() > 0.5 and Color3.fromRGB(198, 142, 255) or Color3.fromRGB(255, 138, 220)

	Build.column(model, "Trunk", height * 0.62, dia, base * CFrame.new(0, height * 0.31, 0) * CFrame.Angles(0.03, 0, -0.02), bark, Enum.Material.Marble, { collide = true })
	Build.column(model, "TrunkUpper", height * 0.42, dia * 0.7, base * CFrame.new(0.1, height * 0.7, 0), bark, Enum.Material.Marble, { shadow = false })
	Build.disc(model, "Collar", 5.2 * s, 0.5, base * CFrame.new(0, height * 0.5, 0), accent, Enum.Material.Glass, { transparency = 0.45, shadow = false })

	if full then
		for i = 1, 4 do
			local angle = (i / 4) * math.pi * 2 + 0.4
			local cf = base
				* CFrame.new(math.cos(angle) * dia * 0.5, height * 0.72, math.sin(angle) * dia * 0.5)
				* CFrame.Angles(0, -angle, 0)
				* CFrame.Angles(0, 0, math.rad(46))
			Build.block(model, "ShardBranch", Vector3.new(0.7, 6.5, 0.7) * s, cf * CFrame.new(0, 3.4 * s, 0), accent, Enum.Material.Glass, { transparency = 0.35, shadow = false })
		end
	end

	local crown = base * CFrame.new(0, height * 0.98, 0)
	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2
		Build.block(
			model,
			"ShardLeaf",
			Vector3.new(1.5, rng(5, 7.5), 1.5) * s,
			crown * CFrame.new(math.cos(angle) * 2.2 * s, rng(0.4, 2.6) * s, math.sin(angle) * 2.2 * s)
				* CFrame.Angles(0.24, -angle, 0.3),
			accent,
			Enum.Material.Glass,
			{ transparency = 0.25, shadow = false }
		)
	end
	for i = 1, 3 do
		local angle = i * 2.2
		local fruit = Build.ball(
			model,
			"Fruit",
			Vector3.new(1.5, 1.7, 1.5) * s,
			crown * CFrame.new(math.cos(angle) * 3.4 * s, -1.6 * s, math.sin(angle) * 3.4 * s),
			Color3.fromRGB(255, 240, 255),
			Enum.Material.Neon,
			{ shadow = false }
		)
		if i == 1 then
			Build.sparkle(fruit, accent, full and 2 or 1, { size = 0.22, lifetime = Vector2.new(1, 2), light = 0.8 })
			if full then
				Build.glow(fruit, accent, 0.6, 15)
			end
		end
	end
	Build.disc(model, "GroundGlow", 9 * s, 0.05, base * CFrame.new(0, 0.16, 0), accent, Enum.Material.Neon, { transparency = 0.78, shadow = false })
end

-- ------------------------------------------------------------------ Mirewillow

local function mirewillow(model: Model, base: CFrame, rng, full: boolean)
	local s = rng(0.9, 1.25)
	local height = 19 * s
	local dia = 3.4 * s
	local bark = tint(BARK.ashen, rng, 0.14)
	local frondColor = Color3.fromRGB(120, 178, 132)

	roots(model, base, full and 4 or 2, s, bark, rng)
	Build.column(model, "Trunk", height * 0.55, dia, base * CFrame.new(0, height * 0.28, 0) * CFrame.Angles(0.06, 0, 0.05), bark, Enum.Material.Wood, { collide = true })
	Build.column(model, "TrunkUpper", height * 0.45, dia * 0.72, base * CFrame.new(1.2 * s, height * 0.72, 0) * CFrame.Angles(0.12, 0.5, 0.1), bark, Enum.Material.Wood, { shadow = false })

	local crown = base * CFrame.new(1.5 * s, height * 0.96, 0)
	Build.ball(model, "Canopy", Vector3.new(10.5, 5.6, 10.5) * s, crown, tint(frondColor, rng, 0.12), Enum.Material.LeafyGrass, { shadow = true })

	local fronds = full and 7 or 4
	for i = 1, fronds do
		local angle = (i / fronds) * math.pi * 2 + rng(-0.2, 0.2)
		local reach = rng(3.6, 5.4) * s
		Build.ball(
			model,
			"Frond",
			Vector3.new(1.1, rng(6, 9) * s, 1.1),
			crown * CFrame.new(math.cos(angle) * reach, -4.2 * s, math.sin(angle) * reach)
				* CFrame.Angles(math.cos(angle) * 0.12, -angle, -math.sin(angle) * 0.34),
			tint(frondColor, rng, 0.16),
			Enum.Material.Grass,
			{ shadow = false }
		)
	end
	if full then
		for i = 1, 3 do
			local angle = i * 2.0
			Build.block(
				model,
				"Moss",
				Vector3.new(0.4, rng(3, 5), 1.6) * s,
				crown * CFrame.new(math.cos(angle) * 3.2 * s, -3.4 * s, math.sin(angle) * 3.2 * s),
				Color3.fromRGB(88, 132, 96),
				Enum.Material.Grass,
				{ transparency = 0.25, shadow = false }
			)
		end
	end
	for i = 1, 3 do
		local angle = i * 2.4
		local pod = Build.ball(
			model,
			"SporePod",
			Vector3.new(0.9, 1.1, 0.9) * s,
			crown * CFrame.new(math.cos(angle) * 3.8 * s, -2.4 * s, math.sin(angle) * 3.8 * s),
			Color3.fromRGB(198, 255, 196),
			Enum.Material.Neon,
			{ shadow = false }
		)
		if i == 1 then
			Build.sparkle(pod, Color3.fromRGB(186, 255, 176), 1, { size = 0.18, lifetime = Vector2.new(0.8, 1.6), light = 0.7 })
		end
	end
end

-- ------------------------------------------------------------------- Emberpine

local function emberpine(model: Model, base: CFrame, rng, full: boolean)
	local s = rng(0.85, 1.2)
	local height = 21 * s
	local dia = 2.4 * s
	local bark = tint(BARK.dark, rng, 0.1)
	local needle = tint(Color3.fromRGB(46, 96, 82), rng, 0.14)
	local tiers = full and 5 or 4

	Build.column(model, "Trunk", height * 0.62, dia, base * CFrame.new(0, height * 0.31, 0), bark, Enum.Material.Wood, { collide = true })
	Build.column(model, "TrunkUpper", height * 0.42, dia * 0.7, base * CFrame.new(0, height * 0.72, 0), bark, Enum.Material.Wood, { shadow = false })

	for i = 1, tiers do
		local t = (i - 1) / tiers
		local y = height * (0.34 + t * 0.6)
		local spread = (10.5 - t * 6.4) * s
		Build.disc(
			model,
			"Tier",
			spread,
			rng(2.2, 3.2) * s,
			base * CFrame.new(0, y, 0) * CFrame.Angles(rng(-0.05, 0.05), rng(0, 1), rng(-0.05, 0.05)),
			i % 2 == 0 and tint(needle, rng, 0.1) or needle,
			Enum.Material.Grass,
			{ shadow = i > tiers - 2, transparency = 0 }
		)
		if full and i % 2 == 1 then
			Build.ball(
				model,
				"EmberTip",
				Vector3.new(0.7, 0.7, 0.7) * s,
				base * CFrame.new(spread * 0.42, y + 1.0 * s, spread * 0.3),
				Color3.fromRGB(255, 168, 84),
				Enum.Material.Neon,
				{ shadow = false }
			)
		end
	end
	Build.ball(model, "Crown", Vector3.new(2.6, 3.4, 2.6) * s, base * CFrame.new(0, height * 0.98, 0), needle, Enum.Material.Grass, { shadow = false })
	if full then
		local tip = Build.ball(model, "CrownTip", Vector3.new(1.0, 1.6, 1.0) * s, base * CFrame.new(0, height * 1.03, 0), Color3.fromRGB(255, 196, 120), Enum.Material.Neon, { shadow = false })
		Build.sparkle(tip, Color3.fromRGB(255, 176, 96), 2, { size = 0.2, lifetime = Vector2.new(0.6, 1.4), speed = Vector2.new(0.2, 0.8), light = 0.9 })
	end
end

-- --------------------------------------------------------------------- factory

local BUILDERS = {
	Whisperoak = whisperoak,
	Gigglepod = gigglepod,
	Twistpop = twistpop,
	Crystalbloom = crystalbloom,
	Mirewillow = mirewillow,
	Emberpine = emberpine,
}

function TreeFactory.build(family: string, parent: Instance, baseCf: CFrame, rng, detail: string?): Model
	local builder = BUILDERS[family] or whisperoak
	local model = Instance.new("Model")
	model.Name = family
	model:SetAttribute("Decorative", true)
	model:SetAttribute("TreeFamily", family)
	builder(model, baseCf, rng, detail ~= "simple")
	model.Parent = parent
	return model
end

return TreeFactory
