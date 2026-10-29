-- Environmental props: rocks, undergrowth, crystals, woodwork, ruins and the
-- signage that makes the forest navigable. Everything is anchored and
-- non-queryable; only large rocks and trunks opt into collision.

local Build = require(script.Parent.Build)

local PropFactory = {}

local STONE = {
	mid = Color3.fromRGB(148, 146, 162),
	dark = Color3.fromRGB(108, 106, 124),
	light = Color3.fromRGB(186, 182, 196),
	moss = Color3.fromRGB(96, 150, 96),
}

local WOOD = {
	mid = Color3.fromRGB(116, 82, 54),
	dark = Color3.fromRGB(78, 54, 38),
	light = Color3.fromRGB(154, 114, 76),
}

local function stoneTint(rng, color: Color3): Color3
	return color:Lerp(rng() > 0.5 and STONE.light or STONE.dark, rng(0, 0.35))
end

function PropFactory.rock(parent: Instance, cf: CFrame, rng, scale: number?)
	local s = scale or 1
	local base = stoneTint(rng, STONE.mid)
	for i = 1, 3 do
		local size = Vector3.new(rng(3.4, 5.6), rng(2.4, 3.8), rng(3.0, 4.8)) * s
		local offset = Vector3.new(rng(-2.6, 2.6), size.Y * 0.28, rng(-2.6, 2.6)) * s
		Build.ball(
			parent,
			"Rock",
			size,
			cf * CFrame.new(offset) * CFrame.Angles(rng(-0.2, 0.2), rng(0, 6.2), rng(-0.2, 0.2)),
			stoneTint(rng, base),
			Enum.Material.Rock,
			{ collide = i == 1 and s > 0.9, shadow = i == 1 }
		)
	end
	Build.ball(parent, "RockMoss", Vector3.new(3.2, 0.5, 2.4) * s, cf * CFrame.new(rng(-1, 1) * s, 1.5 * s, rng(-1, 1) * s), STONE.moss, Enum.Material.Grass, { shadow = false })
	for i = 1, 2 do
		Build.ball(parent, "Pebble", Vector3.new(1.1, 0.9, 1.0) * s, cf * CFrame.new(rng(-3.4, 3.4) * s, 0.35, rng(-3.4, 3.4) * s), stoneTint(rng, base), Enum.Material.Rock, { shadow = false })
	end
end

function PropFactory.boulder(parent: Instance, cf: CFrame, rng, scale: number?)
	local s = scale or 1
	Build.ball(parent, "Boulder", Vector3.new(11, 9, 10) * s, cf * CFrame.new(0, 2.4 * s, 0) * CFrame.Angles(rng(-0.2, 0.2), rng(0, 6.2), rng(-0.25, 0.25)), stoneTint(rng, STONE.mid), Enum.Material.Rock, { collide = true })
	Build.ball(parent, "BoulderTop", Vector3.new(7, 5, 6) * s, cf * CFrame.new(2.4 * s, 5.4 * s, -1.2 * s) * CFrame.Angles(0.2, rng(0, 6.2), 0.3), stoneTint(rng, STONE.dark), Enum.Material.Rock, { shadow = false })
	Build.ball(parent, "BoulderMoss", Vector3.new(8, 1.0, 6) * s, cf * CFrame.new(0.4 * s, 6.1 * s, 0.6 * s), STONE.moss, Enum.Material.Grass, { shadow = false })
end

function PropFactory.bush(parent: Instance, cf: CFrame, rng, scale: number?)
	local s = scale or 1
	local green = Color3.fromRGB(62, 148, 88):Lerp(Color3.fromRGB(102, 186, 108), rng())
	for i = 1, 3 do
		Build.ball(
			parent,
			"Bush",
			Vector3.new(rng(3.0, 4.4), rng(2.2, 3.0), rng(3.0, 4.4)) * s,
			cf * CFrame.new(rng(-1.2, 1.2) * s, rng(0.9, 1.5) * s, rng(-1.2, 1.2) * s),
			green,
			Enum.Material.Grass,
			{ shadow = false }
		)
	end
	for i = 1, 3 do
		local angle = i * 2.1 + rng(-0.3, 0.3)
		Build.ball(parent, "BushBlade", Vector3.new(2.1, 0.3, 0.7) * s, cf * CFrame.new(math.cos(angle) * 1.6 * s, 1.7 * s, math.sin(angle) * 1.6 * s) * CFrame.Angles(0, -angle, -0.3), green, Enum.Material.Grass, { shadow = false })
	end
end

function PropFactory.fern(parent: Instance, cf: CFrame, rng)
	local green = Color3.fromRGB(74, 160, 96):Lerp(Color3.fromRGB(120, 196, 112), rng())
	for i = 1, 5 do
		local angle = (i / 5) * math.pi * 2 + rng(-0.3, 0.3)
		Build.ball(
			parent,
			"Fern",
			Vector3.new(0.9, rng(2.4, 3.6), 0.35),
			cf * CFrame.new(math.cos(angle) * 0.7, 1.2, math.sin(angle) * 0.7)
				* CFrame.Angles(0, -angle, 0.5 + rng(-0.2, 0.2)),
			green,
			Enum.Material.Grass,
			{ shadow = false }
		)
	end
end

function PropFactory.flower(parent: Instance, cf: CFrame, rng)
	local petals = {
		Color3.fromRGB(255, 128, 190),
		Color3.fromRGB(255, 210, 108),
		Color3.fromRGB(146, 196, 255),
		Color3.fromRGB(226, 160, 255),
	}
	local color = petals[math.clamp(math.floor(rng() * #petals) + 1, 1, #petals)]
	local height = rng(1.0, 1.8)
	Build.column(parent, "Stem", height, 0.16, cf * CFrame.new(0, height * 0.5, 0), Color3.fromRGB(72, 148, 82), Enum.Material.Grass, { shadow = false })
	for i = 1, 5 do
		local angle = (i / 5) * math.pi * 2
		Build.ball(parent, "Petal", Vector3.new(0.62, 0.24, 0.36), cf * CFrame.new(math.cos(angle) * 0.4, height, math.sin(angle) * 0.4) * CFrame.Angles(0, -angle, 0), color, Enum.Material.SmoothPlastic, { shadow = false })
	end
	Build.ball(parent, "FlowerCore", Vector3.new(0.4, 0.28, 0.4), cf * CFrame.new(0, height + 0.1, 0), Color3.fromRGB(255, 238, 160), Enum.Material.Neon, { shadow = false })
end

function PropFactory.mushroom(parent: Instance, cf: CFrame, rng, scale: number?, glow: boolean?)
	local s = scale or 1
	local capColor = glow and Color3.fromRGB(150, 255, 222) or Color3.fromRGB(238, 214, 214)
	local height = rng(1.6, 2.8) * s
	Build.column(parent, "Stem", height, 0.5 * s, cf * CFrame.new(0, height * 0.5, 0), Color3.fromRGB(242, 236, 226), Enum.Material.SmoothPlastic, { shadow = false })
	local cap = Build.ball(
		parent,
		"Cap",
		Vector3.new(2.6, 1.5, 2.6) * s,
		cf * CFrame.new(0, height + 0.25 * s, 0) * CFrame.Angles(rng(-0.1, 0.1), rng(0, 6.2), rng(-0.1, 0.1)),
		capColor,
		glow and Enum.Material.Neon or Enum.Material.SmoothPlastic,
		{ shadow = not glow }
	)
	for i = 1, 3 do
		local angle = (i / 3) * math.pi * 2
		Build.ball(parent, "Spot", Vector3.new(0.5, 0.26, 0.5) * s, cf * CFrame.new(math.cos(angle) * 0.8 * s, height + 0.9 * s, math.sin(angle) * 0.8 * s), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, { shadow = false })
	end
	if glow then
		Build.sparkle(cap, capColor, 1, { size = 0.16, lifetime = Vector2.new(0.8, 1.8), light = 0.9 })
		Build.glow(cap, capColor, 0.4, 12)
	end
end

function PropFactory.giantMushroom(parent: Instance, cf: CFrame, rng, scale: number?)
	local s = scale or 1
	local capColor = Color3.fromRGB(178, 132, 255):Lerp(Color3.fromRGB(255, 138, 200), rng())
	local height = rng(16, 26) * s
	Build.column(parent, "Stem", height, 3.4 * s, cf * CFrame.new(0, height * 0.5, 0) * CFrame.Angles(rng(-0.05, 0.05), 0, rng(-0.05, 0.05)), Color3.fromRGB(240, 232, 222), Enum.Material.SmoothPlastic, { collide = true })
	local cap = Build.ball(
		parent,
		"Cap",
		Vector3.new(16, 9, 16) * s,
		cf * CFrame.new(0, height + 1.4 * s, 0) * CFrame.Angles(rng(-0.08, 0.08), rng(0, 6.2), rng(-0.08, 0.08)),
		capColor,
		Enum.Material.SmoothPlastic,
		{ shadow = true }
	)
	Build.disc(parent, "Gills", 13 * s, 0.4, cf * CFrame.new(0, height - 1.6 * s, 0), Color3.fromRGB(255, 236, 248), Enum.Material.SmoothPlastic, { shadow = false })
	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2
		Build.ball(parent, "Spot", Vector3.new(2.4, 0.9, 2.4) * s, cf * CFrame.new(math.cos(angle) * 4.6 * s, height + 4.4 * s, math.sin(angle) * 4.6 * s), Color3.fromRGB(255, 248, 236), Enum.Material.SmoothPlastic, { shadow = false })
	end
	Build.sparkle(cap, capColor, 3, { size = 0.4, lifetime = Vector2.new(1.4, 2.6), light = 0.6 })
	Build.glow(cap, capColor, 0.9, 22)
end

function PropFactory.log(parent: Instance, cf: CFrame, rng)
	local s = rng(0.8, 1.2)
	local length = rng(9, 14) * s
	local bark = WOOD.dark:Lerp(WOOD.mid, rng())
	local yaw = rng(0, 6.2)
	local logCf = cf * CFrame.Angles(0, yaw, 0)
	Build.column(parent, "FallenLog", length, 2.2 * s, logCf * CFrame.new(0, 1.05 * s, 0), bark, Enum.Material.Wood, { collide = true })
	Build.disc(parent, "LogEnd", 2.1 * s, 0.3, logCf * CFrame.new(length * 0.5, 1.05 * s, 0), WOOD.light, Enum.Material.WoodPlanks, { shadow = false })
	Build.ball(parent, "LogMoss", Vector3.new(2.4, 0.9, 3.4) * s, cf * CFrame.new(rng(-3, 3), 1.9 * s, 0), STONE.moss, Enum.Material.Grass, { shadow = false })
	if rng() > 0.4 then
		PropFactory.mushroom(parent, cf * CFrame.new(rng(-3, 3), 0.6, rng(-1.4, 1.4)), rng, 0.55)
	end
end

function PropFactory.reed(parent: Instance, cf: CFrame, rng)
	local green = Color3.fromRGB(104, 168, 116):Lerp(Color3.fromRGB(146, 196, 118), rng())
	for i = 1, 5 do
		local angle = rng(0, 6.2)
		local height = rng(4, 7)
		Build.ball(
			parent,
			"Reed",
			Vector3.new(0.3, height, 0.3),
			cf * CFrame.new(math.cos(angle) * rng(0.4, 2.4), height * 0.5, math.sin(angle) * rng(0.4, 2.4)) * CFrame.Angles(rng(-0.1, 0.1), 0, rng(-0.12, 0.12)),
			green,
			Enum.Material.Grass,
			{ shadow = false }
		)
	end
end

function PropFactory.crystal(parent: Instance, cf: CFrame, rng, accent: Color3, scale: number?)
	local s = scale or 1
	local function shard(size: Vector3, offset: CFrame, material: Enum.Material, transparency: number)
		local p = Build.block(parent, "Crystal", size * s, cf * offset, accent, material, { transparency = transparency, shadow = false })
		p.CFrame = p.CFrame * CFrame.Angles(rng(-0.1, 0.1), 0, rng(-0.18, 0.18))
		return p
	end
	local main = shard(Vector3.new(1.6, 7.0, 1.6), CFrame.new(0, 3.2 * s, 0), Enum.Material.Glass, 0.15)
	shard(Vector3.new(1.0, 4.2, 1.0), CFrame.new(1.5 * s, 1.9 * s, 0.6 * s) * CFrame.Angles(0, 0.6, 0.3), Enum.Material.Ice, 0.22)
	shard(Vector3.new(0.9, 3.4, 0.9), CFrame.new(-1.3 * s, 1.5 * s, -0.8 * s) * CFrame.Angles(0, -0.5, -0.3), Enum.Material.Glass, 0.2)
	Build.sparkle(main, accent, 2, { size = 0.2, lifetime = Vector2.new(0.8, 1.8), light = 0.9 })
end

function PropFactory.lantern(parent: Instance, cf: CFrame, accent: Color3, light: boolean?)
	Build.column(parent, "LanternPost", 7, 0.45, cf * CFrame.new(0, 3.5, 0), WOOD.dark, Enum.Material.Wood, { collide = true })
	Build.block(parent, "LanternArm", Vector3.new(1.6, 0.25, 0.25), cf * CFrame.new(0.7, 6.9, 0), WOOD.dark, Enum.Material.Wood, { shadow = false })
	local lamp = Build.ball(parent, "Lantern", Vector3.new(1.5, 1.9, 1.5), cf * CFrame.new(1.3, 6.5, 0), accent, Enum.Material.Neon, { shadow = false })
	Build.sparkle(lamp, accent, 1.5, { size = 0.18, lifetime = Vector2.new(0.8, 1.6), light = 0.8 })
	if light then
		Build.glow(lamp, accent, 0.55, 15)
	end
end

function PropFactory.brazier(parent: Instance, cf: CFrame, accent: Color3, lit: boolean)
	Build.column(parent, "BrazierBase", 3.2, 1.5, cf * CFrame.new(0, 1.6, 0), STONE.dark, Enum.Material.Slate, { collide = true })
	Build.disc(parent, "BrazierBowl", 3.4, 0.7, cf * CFrame.new(0, 3.3, 0), STONE.mid, Enum.Material.Slate)
	local flame = Build.ball(parent, "BrazierFlame", Vector3.new(1.9, 2.7, 1.9), cf * CFrame.new(0, 4.4, 0), accent, Enum.Material.Neon, { transparency = 0.2, shadow = false })
	Build.sparkle(flame, accent, 5, { size = 0.26, lifetime = Vector2.new(0.9, 1.8), speed = Vector2.new(0.6, 1.8), light = 0.8 })
	if lit then
		Build.glow(flame, accent, 0.9, 18)
	end
end

function PropFactory.bonfire(parent: Instance, cf: CFrame)
	Build.disc(parent, "FirePit", 10, 0.4, cf * CFrame.new(0, 0.2, 0), STONE.dark, Enum.Material.Slate)
	for i = 1, 7 do
		local angle = (i / 7) * math.pi * 2
		Build.ball(parent, "PitStone", Vector3.new(2.0, 1.3, 2.0), cf * CFrame.new(math.cos(angle) * 4.6, 0.35, math.sin(angle) * 4.6), (i % 2 == 0) and STONE.mid or STONE.dark, Enum.Material.Rock, { collide = true })
	end
	local flame = Build.ball(parent, "Bonfire", Vector3.new(3.0, 4.4, 3.0), cf * CFrame.new(0, 2.2, 0), Color3.fromRGB(255, 186, 88), Enum.Material.Neon, { transparency = 0.18, shadow = false })
	Build.sparkle(flame, Color3.fromRGB(255, 196, 108), 9, { size = 0.32, lifetime = Vector2.new(1, 2), speed = Vector2.new(1, 2.6), spread = 26, light = 0.9 })
	Build.glow(flame, Color3.fromRGB(255, 196, 108), 1.3, 30)
	for i = 1, 5 do
		local angle = i * 1.3
		Build.column(parent, "LogSeat", 7, 1.6, cf * CFrame.new(math.cos(angle) * 7, 0.8, math.sin(angle) * 7) * CFrame.Angles(0, -angle, math.rad(90)), WOOD.dark, Enum.Material.Wood, { collide = true })
	end
end

function PropFactory.banner(parent: Instance, cf: CFrame, accent: Color3)
	Build.column(parent, "BannerPole", 13, 0.5, cf * CFrame.new(0, 6.5, 0), WOOD.dark, Enum.Material.Wood, { collide = true })
	Build.block(parent, "Banner", Vector3.new(0.2, 5.4, 3.4), cf * CFrame.new(-1.85, 8.6, 0), accent, Enum.Material.Fabric, { shadow = false })
	Build.block(parent, "BannerTrim", Vector3.new(0.28, 0.4, 3.4), cf * CFrame.new(-1.85, 6.1, 0), Color3.fromRGB(255, 206, 110), Enum.Material.Foil, { shadow = false })
	Build.ball(parent, "BannerTop", Vector3.new(0.6, 0.9, 0.6), cf * CFrame.new(0, 13.2, 0), Color3.fromRGB(255, 206, 110), Enum.Material.Foil, { shadow = false })
end

local function billboard(parent: BasePart, title: string, lines: { string }, accent: Color3, width: number, distance: number)
	local gui = Instance.new("BillboardGui")
	gui.Name = "SignText"
	gui.Size = UDim2.fromOffset(width, 26 + #lines * 16)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 0, 0.35)
	gui.MaxDistance = distance
	gui.LightInfluence = 0.15
	gui.AlwaysOnTop = false
	gui.Parent = parent

	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(16, 12, 24)
	back.BackgroundTransparency = 0.28
	back.BorderSizePixel = 0
	back.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = back
	local stroke = Instance.new("UIStroke")
	stroke.Color = accent
	stroke.Thickness = 1.5
	stroke.Transparency = 0.45
	stroke.Parent = back

	local heading = Instance.new("TextLabel")
	heading.BackgroundTransparency = 1
	heading.Size = UDim2.new(1, -10, 0, 22)
	heading.Position = UDim2.fromOffset(5, 3)
	heading.Font = Enum.Font.GothamBlack
	heading.TextSize = 14
	heading.TextColor3 = accent
	heading.TextXAlignment = Enum.TextXAlignment.Left
	heading.TextStrokeTransparency = 0.5
	heading.Text = title
	heading.Parent = back

	for i, line in lines do
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, -10, 0, 14)
		label.Position = UDim2.fromOffset(5, 22 + (i - 1) * 15)
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 11
		label.TextColor3 = Color3.fromRGB(232, 226, 244)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextStrokeTransparency = 0.6
		label.Text = line
		label.Parent = back
	end
end

function PropFactory.signpost(parent: Instance, cf: CFrame, title: string, lines: { string }, accent: Color3)
	Build.column(parent, "SignPost", 6.5, 0.6, cf * CFrame.new(0, 3.25, 0), WOOD.dark, Enum.Material.Wood, { collide = true })
	local board = Build.block(parent, "SignBoard", Vector3.new(8.6, 3.0, 0.35), cf * CFrame.new(0, 7.0, 0), WOOD.mid, Enum.Material.WoodPlanks, { collide = true })
	Build.block(parent, "SignTrim", Vector3.new(9.0, 0.35, 0.45), cf * CFrame.new(0, 8.55, 0), accent, Enum.Material.Neon, { transparency = 0.35, shadow = false })
	billboard(board, title, lines, accent, 210, 320)
end

function PropFactory.fence(parent: Instance, from: Vector3, to: Vector3, accent: Color3?)
	local delta = to - from
	local length = delta.Magnitude
	if length < 2 then
		return
	end
	local direction = delta.Unit
	local posts = math.max(1, math.floor(length / 7))
	for i = 0, posts do
		local pos = from + direction * (length * (i / posts))
		Build.column(parent, "FencePost", 3.4, 0.45, CFrame.new(pos + Vector3.new(0, 1.7, 0)), WOOD.dark, Enum.Material.Wood, { collide = true })
	end
	local mid = (from + to) * 0.5
	local railCf = CFrame.lookAt(Vector3.new(mid.X, from.Y + 2.1, mid.Z), Vector3.new(to.X, from.Y + 2.1, to.Z))
	Build.block(parent, "FenceRail", Vector3.new(0.24, 0.3, length), railCf, WOOD.mid, Enum.Material.Wood, { shadow = false })
	if accent then
		Build.block(parent, "FenceGlow", Vector3.new(0.12, 0.12, length), railCf * CFrame.new(0, -0.45, 0), accent, Enum.Material.Neon, { transparency = 0.4, shadow = false })
	end
end

function PropFactory.ruinColumn(parent: Instance, cf: CFrame, rng): CFrame
	local height = rng(7, 15)
	local radius = rng(1.5, 2.2)
	Build.disc(parent, "RuinBase", radius * 2.9, 0.7, cf * CFrame.new(0, 0.3, 0), STONE.dark, Enum.Material.Slate, { shadow = false })
	Build.column(parent, "RuinShaft", height, radius * 1.9, cf * CFrame.new(0, height * 0.5 + 0.6, 0) * CFrame.Angles(rng(-0.06, 0.06), 0, rng(-0.08, 0.08)), stoneTint(rng, STONE.mid), Enum.Material.Granite, { collide = true })
	if rng() > 0.45 then
		Build.block(parent, "RuinCap", Vector3.new(radius * 2.6, 0.6, radius * 2.6), cf * CFrame.new(0, height + 0.9, 0) * CFrame.Angles(0, rng(0, 1.5), 0), STONE.light, Enum.Material.Granite, { shadow = false })
	end
	Build.ball(parent, "RuinMoss", Vector3.new(radius * 2.4, 0.6, radius * 2.2), cf * CFrame.new(rng(-0.6, 0.6), rng(2, 5), rng(-0.6, 0.6)), STONE.moss, Enum.Material.Grass, { shadow = false })
	return cf
end

function PropFactory.arch(parent: Instance, cf: CFrame, accent: Color3, scale: number?)
	local s = scale or 1
	local width = 22 * s
	local height = 20 * s
	for _, side in { -1, 1 } do
		Build.block(parent, "ArchLeg", Vector3.new(3.4, height, 3.4) * 1, cf * CFrame.new(side * width * 0.5, height * 0.5, 0), STONE.mid, Enum.Material.Granite, { collide = true })
		Build.disc(parent, "ArchFoot", 5.2, 0.8, cf * CFrame.new(side * width * 0.5, 0.4, 0), STONE.dark, Enum.Material.Slate, { shadow = false })
	end
	Build.block(parent, "ArchLintel", Vector3.new(width + 5, 3.2, 4.2), cf * CFrame.new(0, height + 1.4, 0), STONE.light, Enum.Material.Granite, { collide = true })
	Build.block(parent, "ArchGlow", Vector3.new(width + 1, 0.4, 0.5), cf * CFrame.new(0, height - 0.3, -2.1), accent, Enum.Material.Neon, { transparency = 0.3, shadow = false })
	Build.ball(parent, "ArchMoss", Vector3.new(width * 0.8, 1.4, 3.4), cf * CFrame.new(0, height + 3.2, 0.4), STONE.moss, Enum.Material.Grass, { shadow = false })
	-- hanging vines
	for i = 1, 4 do
		local x = -width * 0.35 + (i - 1) * (width * 0.23)
		Build.ball(parent, "Vine", Vector3.new(0.5, 5.5 + (i % 3) * 2.4, 0.5), cf * CFrame.new(x, height - 4.0, 0), Color3.fromRGB(74, 138, 86), Enum.Material.Grass, { shadow = false })
	end
end

function PropFactory.bridge(parent: Instance, from: Vector3, to: Vector3, width: number, accent: Color3?)
	local delta = to - from
	local length = delta.Magnitude
	if length < 3 then
		return
	end
	local mid = (from + to) * 0.5
	local look = CFrame.lookAt(Vector3.new(mid.X, from.Y, mid.Z), Vector3.new(to.X, to.Y, to.Z))
	local planks = math.max(3, math.floor(length / 3))
	for i = 0, planks do
		local t = i / planks
		local pos = from:Lerp(to, t)
		Build.block(parent, "Plank", Vector3.new(width, 0.35, length / planks * 0.92), CFrame.new(pos + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, math.atan2(delta.X, delta.Z), 0), WOOD.mid:Lerp(WOOD.light, (i % 3) * 0.25), Enum.Material.WoodPlanks, { collide = true, shadow = false })
	end
	for _, side in { -1, 1 } do
		local offset = look.RightVector * (width * 0.5) * side
		Build.block(parent, "BridgeRail", Vector3.new(0.3, 0.3, length), CFrame.lookAt(Vector3.new(mid.X, from.Y + 3.2, mid.Z), Vector3.new(to.X, to.Y + 3.2, to.Z)) + offset, WOOD.dark, Enum.Material.Wood, { shadow = false })
		local posts = math.max(2, math.floor(length / 9))
		for i = 0, posts do
			local pos = from:Lerp(to, i / posts) + offset
			Build.column(parent, "RailPost", 3.6, 0.4, CFrame.new(pos + Vector3.new(0, 1.8, 0)), WOOD.dark, Enum.Material.Wood, { shadow = false })
		end
	end
	if accent then
		Build.block(parent, "BridgeTrim", Vector3.new(width, 0.12, length), CFrame.new(mid + Vector3.new(0, 0.32, 0)) * CFrame.Angles(0, math.atan2(delta.X, delta.Z), 0), accent, Enum.Material.Neon, { transparency = 0.5, shadow = false })
	end
end

function PropFactory.shopStall(parent: Instance, cf: CFrame, accent: Color3)
	Build.block(parent, "StallCounter", Vector3.new(14, 1.2, 6), cf * CFrame.new(0, 3.0, 0), WOOD.mid, Enum.Material.WoodPlanks, { collide = true })
	Build.block(parent, "StallBack", Vector3.new(14, 6, 0.6), cf * CFrame.new(0, 6.0, -2.7), WOOD.dark, Enum.Material.Wood, { collide = true })
	for _, side in { -1, 1 } do
		Build.column(parent, "StallPost", 8, 0.6, cf * CFrame.new(side * 6.6, 4, 2.2), WOOD.dark, Enum.Material.Wood, { collide = true })
	end
	local awning = Build.block(parent, "Awning", Vector3.new(15, 0.35, 8), cf * CFrame.new(0, 8.4, 0.6) * CFrame.Angles(-0.12, 0, 0), accent, Enum.Material.Fabric, { shadow = false })
	awning.CastShadow = false
	for i = 1, 4 do
		Build.block(parent, "AwningStripe", Vector3.new(15, 0.4, 0.8), cf * CFrame.new(0, 8.42, -2.4 + i * 2.0) * CFrame.Angles(-0.12, 0, 0), Color3.fromRGB(255, 246, 240), Enum.Material.Fabric, { shadow = false })
	end
	local board = Build.block(parent, "PriceBoard", Vector3.new(6.6, 3.2, 0.4), cf * CFrame.new(0, 7.4, -2.9), Color3.fromRGB(22, 16, 32), Enum.Material.SmoothPlastic, { shadow = false })
	billboard(board, "SHOP", { "PRESS  B  ANYWHERE" }, accent, 190, 260)
end

return PropFactory
