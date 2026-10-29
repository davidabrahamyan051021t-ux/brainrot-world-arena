local Config = require(game.ReplicatedStorage.Shared.Config)

local EntityFactory = {}

local DARK = Color3.fromRGB(20, 16, 26)
local BONE = Color3.fromRGB(244, 236, 214)
local MOUTH = Color3.fromRGB(38, 20, 30)

local function mark(part: BasePart, collide: boolean?)
	part:SetAttribute("BaseTransparency", part.Transparency)
	part:SetAttribute("BaseCanCollide", collide == true)
	part.CanCollide = collide == true
	part.Anchored = true
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CastShadow = true
end

local function basePart(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	mark(p, false)
	p.Parent = parent
	return p
end

local function block(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
): Part
	local p = basePart(parent, name, size, cf, color, material or Enum.Material.SmoothPlastic)
	p.Transparency = transparency or 0
	p:SetAttribute("BaseTransparency", p.Transparency)
	return p
end

local function ball(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
): Part
	local p = basePart(parent, name, size, cf, color, material or Enum.Material.SmoothPlastic)
	p.Transparency = transparency or 0
	p:SetAttribute("BaseTransparency", p.Transparency)
	local m = Instance.new("SpecialMesh")
	m.MeshType = Enum.MeshType.Sphere
	m.Parent = p
	return p
end

-- A vertical cylinder (Roblox cylinder parts are X-aligned, so rotate them upright).
local function column(
	parent: Instance,
	name: string,
	height: number,
	diameter: number,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local p = basePart(parent, name, Vector3.new(height, diameter, diameter), cf, color, material or Enum.Material.SmoothPlastic)
	p.Shape = Enum.PartType.Cylinder
	p.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	return p
end

-- A flat disc lying on the ground (used for auras, halos and lair plates).
local function disc(
	parent: Instance,
	name: string,
	diameter: number,
	thickness: number,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
): Part
	local p = basePart(parent, name, Vector3.new(thickness, diameter, diameter), cf, color, material or Enum.Material.Neon)
	p.Shape = Enum.PartType.Cylinder
	p.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	p.Transparency = transparency or 0
	p:SetAttribute("BaseTransparency", p.Transparency)
	return p
end

local function sparkle(parent: BasePart, color: Color3, rate: number, size: number?)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Sparkle"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.55
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size or 0.22),
		NumberSequenceKeypoint.new(1, 0.02),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(0.7, 1.4)
	emitter.Rate = rate
	emitter.Speed = NumberRange.new(0.5, 1.4)
	emitter.SpreadAngle = Vector2.new(45, 45)
	emitter.RotSpeed = NumberRange.new(-50, 50)
	emitter.Acceleration = Vector3.new(0, 0.6, 0)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent = parent
	return emitter
end

local function glowLight(parent: BasePart, color: Color3, brightness: number, range: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Shadows = false
	light.Parent = parent
	return light
end

-- Groups a set of decorative parts so the client can bob/spin them as one unit.
local function group(parent: Instance, name: string, centerCf: CFrame): Model
	local g = Instance.new("Model")
	g.Name = name
	g.Parent = parent
	local pivot = Instance.new("Part")
	pivot.Name = "Pivot"
	pivot.Size = Vector3.new(0.1, 0.1, 0.1)
	pivot.Transparency = 1
	pivot.CFrame = centerCf
	pivot.CanCollide = false
	pivot.CanQuery = false
	pivot.Massless = true
	pivot.Anchored = true
	pivot:SetAttribute("BaseTransparency", 1)
	pivot:SetAttribute("BaseCanCollide", false)
	pivot.Parent = g
	g.PrimaryPart = pivot
	return g
end

local function tierStripe(parent: Instance, color: Color3)
	local stripe = Instance.new("Frame")
	stripe.Name = "TierStripe"
	stripe.Size = UDim2.new(0, 2, 1, -4)
	stripe.Position = UDim2.fromOffset(2, 2)
	stripe.BackgroundColor3 = color
	stripe.BorderSizePixel = 0
	stripe.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = stripe
end

-- Small, readable name plate. Deliberately minimal: tier stripe, short name and a
-- 3px health bar. Distance culling is handled client-side (EntityFX).
local function compactLabel(root: BasePart, title: string, tier: string, color: Color3, tierColor: Color3, width: number, height: number, maxDistance: number)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(width, height)
	gui.StudsOffsetWorldSpace = Vector3.new(0, root.Size.Y * 0.5 + 0.9, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = maxDistance
	gui.LightInfluence = 0.25
	gui.ResetOnSpawn = false
	gui.ClipsDescendants = false
	gui.Parent = root

	local back = Instance.new("Frame")
	back.Name = "Back"
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(14, 10, 22)
	back.BackgroundTransparency = 0.35
	back.BorderSizePixel = 0
	back.Parent = gui
	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(0, 5)
	backCorner.Parent = back
	local backStroke = Instance.new("UIStroke")
	backStroke.Color = color
	backStroke.Thickness = 1
	backStroke.Transparency = 0.7
	backStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	backStroke.Parent = back

	tierStripe(back, tierColor)

	local name = Instance.new("TextLabel")
	name.Name = "Title"
	name.BackgroundTransparency = 1
	name.Size = UDim2.new(1, -12, 0, height - 7)
	name.Position = UDim2.fromOffset(6, 0)
	name.Font = Enum.Font.GothamBold
	name.TextSize = 9
	name.TextColor3 = Color3.fromRGB(246, 240, 255)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.RichText = true
	name.Text = string.format('<font color="#%02X%02X%02X">%s</font>  %s', math.floor(tierColor.R * 255), math.floor(tierColor.G * 255), math.floor(tierColor.B * 255), tier, title)
	name.Parent = back

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.new(1, -12, 0, 3)
	bar.Position = UDim2.new(0, 6, 1, -5)
	bar.BackgroundColor3 = Color3.fromRGB(34, 26, 46)
	bar.BorderSizePixel = 0
	bar.Parent = back
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = bar

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = bar
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill
	local fillGradient = Instance.new("UIGradient")
	fillGradient.Color = ColorSequence.new(color, Color3.new(1, 1, 1):Lerp(color, 0.55))
	fillGradient.Rotation = 0
	fillGradient.Parent = fill

	return gui
end

local function newVisual(model: Model, rootCf: CFrame, def): Model
	local visual = group(model, "Visual", rootCf)
	visual:SetAttribute("BobAmplitude", def.bobAmplitude or 0.18)
	visual:SetAttribute("BobSpeed", def.bobSpeed or 1.6)
	return visual
end

-- COMMON: a leafy little sprout with googly eyes.
local function buildSmall(model: Model, rootCf: CFrame, def)
	local v = newVisual(model, rootCf, def)
	local p, a, s = def.color, def.accent, def.secondary

	ball(v, "FootL", Vector3.new(1.5, 0.9, 1.9), rootCf * CFrame.new(-1.0, -3.05, -0.3), s)
	ball(v, "FootR", Vector3.new(1.5, 0.9, 1.9), rootCf * CFrame.new(1.0, -3.05, -0.3), s)
	local body = ball(v, "Body", Vector3.new(3.3, 3.1, 2.9), rootCf * CFrame.new(0, -1.35, 0), p, Enum.Material.SmoothPlastic)
	ball(v, "Belly", Vector3.new(2.1, 1.9, 0.9), rootCf * CFrame.new(0, -1.75, -1.3), a)
	ball(v, "Head", Vector3.new(3.1, 2.9, 3.0), rootCf * CFrame.new(0, 1.25, 0), p)

	ball(v, "EyeL", Vector3.new(1.2, 1.35, 0.55), rootCf * CFrame.new(-0.68, 1.5, -1.28), Color3.fromRGB(252, 252, 255))
	ball(v, "EyeR", Vector3.new(1.2, 1.35, 0.55), rootCf * CFrame.new(0.68, 1.5, -1.28), Color3.fromRGB(252, 252, 255))
	ball(v, "PupilL", Vector3.new(0.5, 0.62, 0.3), rootCf * CFrame.new(-0.6, 1.42, -1.55), DARK)
	ball(v, "PupilR", Vector3.new(0.5, 0.62, 0.3), rootCf * CFrame.new(0.6, 1.42, -1.55), DARK)
	block(v, "BrowL", Vector3.new(0.72, 0.16, 0.24), rootCf * CFrame.new(-0.7, 2.1, -1.32) * CFrame.Angles(0, 0, -0.18), s)
	block(v, "BrowR", Vector3.new(0.72, 0.16, 0.24), rootCf * CFrame.new(0.7, 2.1, -1.32) * CFrame.Angles(0, 0, 0.18), s)
	block(v, "Mouth", Vector3.new(1.15, 0.42, 0.3), rootCf * CFrame.new(0, 0.5, -1.4), MOUTH)
	block(v, "ToothL", Vector3.new(0.22, 0.26, 0.12), rootCf * CFrame.new(-0.24, 0.66, -1.5), BONE)
	block(v, "ToothR", Vector3.new(0.22, 0.26, 0.12), rootCf * CFrame.new(0.24, 0.66, -1.5), BONE)

	column(v, "Stem", 1.5, 0.4, rootCf * CFrame.new(0, 2.85, 0.1), Color3.fromRGB(66, 158, 86), Enum.Material.Grass)
	ball(v, "LeafL", Vector3.new(1.9, 0.3, 1.0), rootCf * CFrame.new(-0.85, 3.5, 0) * CFrame.Angles(0, 0.4, -0.35), Color3.fromRGB(108, 220, 122), Enum.Material.Grass)
	ball(v, "LeafR", Vector3.new(1.7, 0.28, 0.95), rootCf * CFrame.new(0.8, 3.6, 0.1) * CFrame.Angles(0, -0.3, 0.4), Color3.fromRGB(90, 206, 108), Enum.Material.Grass)

	ball(v, "ArmL", Vector3.new(0.55, 1.5, 0.55), rootCf * CFrame.new(-1.78, -1.2, 0) * CFrame.Angles(0, 0, 0.32), s)
	ball(v, "ArmR", Vector3.new(0.55, 1.5, 0.55), rootCf * CFrame.new(1.78, -1.2, 0) * CFrame.Angles(0, 0, -0.32), s)

	local crown = group(v, "Crown", rootCf * CFrame.new(0, 3.95, 0))
	crown:SetAttribute("FXSpin", 0.55)
	disc(crown, "Ring", 1.9, 0.1, rootCf * CFrame.new(0, 3.95, 0), a, Enum.Material.Neon, 0.25)

	sparkle(body, def.glow, 1.2, 0.18)
end

-- ELITE: chunky armored brute with a foil crown and a furnace core.
local function buildElite(model: Model, rootCf: CFrame, def)
	local v = newVisual(model, rootCf, def)
	local p, a, s = def.color, def.accent, def.secondary

	block(v, "LegL", Vector3.new(1.8, 2.6, 2.0), rootCf * CFrame.new(-1.55, -4.2, 0), s, Enum.Material.Concrete)
	block(v, "LegR", Vector3.new(1.8, 2.6, 2.0), rootCf * CFrame.new(1.55, -4.2, 0), s, Enum.Material.Concrete)
	block(v, "FootL", Vector3.new(2.0, 0.8, 2.6), rootCf * CFrame.new(-1.55, -5.3, -0.2), DARK, Enum.Material.SmoothPlastic)
	block(v, "FootR", Vector3.new(2.0, 0.8, 2.6), rootCf * CFrame.new(1.55, -5.3, -0.2), DARK, Enum.Material.SmoothPlastic)

	local torso = block(v, "Body", Vector3.new(4.8, 4.0, 3.2), rootCf * CFrame.new(0, -1.9, 0), p, Enum.Material.Concrete)
	block(v, "ChestPlate", Vector3.new(4.2, 2.3, 0.5), rootCf * CFrame.new(0, -1.5, -1.6), s, Enum.Material.Slate)
	block(v, "Belt", Vector3.new(4.6, 0.7, 3.4), rootCf * CFrame.new(0, -3.2, 0), DARK, Enum.Material.SmoothPlastic)
	block(v, "Buckle", Vector3.new(1.0, 0.8, 0.3), rootCf * CFrame.new(0, -3.2, -1.75), a, Enum.Material.Foil)

	ball(v, "ShoulderL", Vector3.new(2.8, 2.4, 2.8), rootCf * CFrame.new(-2.7, -0.35, 0), s, Enum.Material.Metal)
	ball(v, "ShoulderR", Vector3.new(2.8, 2.4, 2.8), rootCf * CFrame.new(2.7, -0.35, 0), s, Enum.Material.Metal)
	block(v, "ArmL", Vector3.new(1.5, 3.0, 1.5), rootCf * CFrame.new(-3.15, -2.4, 0) * CFrame.Angles(0, 0, 0.16), p, Enum.Material.Concrete)
	block(v, "ArmR", Vector3.new(1.5, 3.0, 1.5), rootCf * CFrame.new(3.15, -2.4, 0) * CFrame.Angles(0, 0, -0.16), p, Enum.Material.Concrete)
	ball(v, "FistL", Vector3.new(2.0, 1.9, 2.0), rootCf * CFrame.new(-3.25, -4.1, 0), s, Enum.Material.Concrete)
	ball(v, "FistR", Vector3.new(2.0, 1.9, 2.0), rootCf * CFrame.new(3.25, -4.1, 0), s, Enum.Material.Concrete)

	local head = ball(v, "Head", Vector3.new(3.4, 3.0, 3.1), rootCf * CFrame.new(0, 2.3, 0), p)
	block(v, "Brow", Vector3.new(2.9, 0.5, 0.45), rootCf * CFrame.new(0, 3.25, -1.3), s)
	ball(v, "EyeL", Vector3.new(0.62, 0.78, 0.32), rootCf * CFrame.new(-0.8, 2.55, -1.42), a, Enum.Material.Neon)
	ball(v, "EyeR", Vector3.new(0.62, 0.78, 0.32), rootCf * CFrame.new(0.8, 2.55, -1.42), a, Enum.Material.Neon)
	block(v, "Jaw", Vector3.new(2.9, 0.9, 1.1), rootCf * CFrame.new(0, 1.25, -1.45), MOUTH)
	block(v, "TuskL", Vector3.new(0.34, 1.0, 0.34), rootCf * CFrame.new(-1.1, 1.55, -1.95) * CFrame.Angles(0, 0, 0.2), BONE, Enum.Material.SmoothPlastic)
	block(v, "TuskR", Vector3.new(0.34, 1.0, 0.34), rootCf * CFrame.new(1.1, 1.55, -1.95) * CFrame.Angles(0, 0, -0.2), BONE, Enum.Material.SmoothPlastic)

	block(v, "HornL", Vector3.new(0.6, 1.9, 0.6), rootCf * CFrame.new(-1.95, 3.85, 0.15) * CFrame.Angles(0, 0, 0.42), s, Enum.Material.Metal)
	block(v, "HornR", Vector3.new(0.6, 1.9, 0.6), rootCf * CFrame.new(1.95, 3.85, 0.15) * CFrame.Angles(0, 0, -0.42), s, Enum.Material.Metal)

	local crown = group(v, "Crown", rootCf * CFrame.new(0, 4.15, 0))
	crown:SetAttribute("FXSpin", 0.35)
	disc(crown, "Band", 2.7, 0.35, rootCf * CFrame.new(0, 4.15, 0), a, Enum.Material.Foil, 0.05)
	for i = 1, 5 do
		local angle = (i / 5) * math.pi * 2
		local offset = Vector3.new(math.cos(angle) * 1.15, 0, math.sin(angle) * 1.15)
		block(crown, "Spike" .. i, Vector3.new(0.3, 0.85, 0.3), rootCf * CFrame.new(offset + Vector3.new(0, 4.4, 0)), a, Enum.Material.Foil)
	end

	local core = ball(v, "Core", Vector3.new(1.5, 1.5, 1.2), rootCf * CFrame.new(0, -1.5, -1.85), a, Enum.Material.Neon)
	glowLight(core, def.glow, 0.6, 11)
	sparkle(core, def.glow, 3, 0.2)

	local aura = group(v, "Aura", rootCf * CFrame.new(0, -5.68, 0))
	aura:SetAttribute("FXSpin", 0.8)
	disc(aura, "Ring", 7.4, 0.08, rootCf * CFrame.new(0, -5.68, 0), def.glow, Enum.Material.Neon, 0.6)
end

-- RARE: hovering crystal sentinel built from glass shards and neon rings.
local function buildRare(model: Model, rootCf: CFrame, def)
	local v = newVisual(model, rootCf, def)
	local p, a, s = def.color, def.accent, def.secondary

	local core = ball(v, "Core", Vector3.new(3.2, 4.0, 3.2), rootCf * CFrame.new(0, 0.3, 0), p, Enum.Material.Neon)
	ball(v, "Shell", Vector3.new(4.2, 5.2, 4.2), rootCf * CFrame.new(0, 0.3, 0), a, Enum.Material.Glass, 0.62)

	for i = 1, 5 do
		local angle = (i / 5) * math.pi * 2 + 0.3
		local offset = Vector3.new(math.cos(angle) * 2.5, -0.4 + (i % 2) * 0.5, math.sin(angle) * 2.5)
		local cf = rootCf * CFrame.new(offset) * CFrame.Angles(0, -angle, math.rad(14)) * CFrame.Angles(0.22, 0, 0.18)
		block(v, "Shard" .. i, Vector3.new(0.85, 4.2, 0.85), cf, i % 2 == 0 and a or s, Enum.Material.Glass, 0.18)
	end

	-- tapered spike below, like an inverted crystal point
	ball(v, "Base", Vector3.new(3.0, 3.2, 3.0), rootCf * CFrame.new(0, -2.6, 0), s, Enum.Material.Glass, 0.35)
	ball(v, "BaseTip", Vector3.new(1.4, 2.2, 1.4), rootCf * CFrame.new(0, -4.3, 0), p, Enum.Material.Glass, 0.25)

	block(v, "EyeL", Vector3.new(1.05, 0.42, 0.4), rootCf * CFrame.new(-0.85, 0.55, -1.95) * CFrame.Angles(0, 0, 0.12), Color3.fromRGB(255, 246, 255), Enum.Material.Neon)
	block(v, "EyeR", Vector3.new(1.05, 0.42, 0.4), rootCf * CFrame.new(0.85, 0.55, -1.95) * CFrame.Angles(0, 0, -0.12), Color3.fromRGB(255, 246, 255), Enum.Material.Neon)
	block(v, "Mouth", Vector3.new(0.9, 0.24, 0.3), rootCf * CFrame.new(0, -0.15, -1.9), Color3.fromRGB(60, 20, 70), Enum.Material.Neon)

	local crown = group(v, "Crown", rootCf * CFrame.new(0, 3.5, 0))
	crown:SetAttribute("FXSpin", 0.5)
	for i = 1, 3 do
		local angle = (i / 3) * math.pi * 2
		block(
			crown,
			"Spike" .. i,
			Vector3.new(0.6, 2.0, 0.6),
			rootCf * CFrame.new(math.cos(angle) * 1.15, 3.9, math.sin(angle) * 1.15) * CFrame.Angles(0.2, angle, 0.25),
			a,
			Enum.Material.Neon
		)
	end

	local halo = group(v, "Halo", rootCf * CFrame.new(0, 1.5, 0) * CFrame.Angles(0.16, 0, 0))
	halo:SetAttribute("FXSpin", 1.4)
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local pos = rootCf * CFrame.new(math.cos(angle) * 3.1, 1.5, math.sin(angle) * 3.1)
		block(halo, "Bead" .. i, Vector3.new(0.5, 0.16, 0.5), pos * CFrame.Angles(0, angle, 0), a, Enum.Material.Neon)
	end

	local aura = group(v, "Aura", rootCf * CFrame.new(0, -6.62, 0))
	aura:SetAttribute("FXSpin", 0.55)
	disc(aura, "Ring", 9.5, 0.1, rootCf * CFrame.new(0, -6.62, 0), def.glow, Enum.Material.Neon, 0.62)
	disc(aura, "RingInner", 5.2, 0.08, rootCf * CFrame.new(0, -6.6, 0), a, Enum.Material.Neon, 0.7)

	glowLight(core, p, 0.9, 18)
	sparkle(core, a, 5, 0.24)
end

-- GIGANTIC: the event boss. Bigger silhouette, crown, furnace core, ground aura.
local function buildBoss(model: Model, rootCf: CFrame)
	local def = Config.Event
	local v = newVisual(model, rootCf, def)
	local p, a, s = def.color, def.accent, def.secondary

	block(v, "LegL", Vector3.new(3.0, 4.6, 3.2), rootCf * CFrame.new(-3.2, -9.2, 0), s, Enum.Material.Concrete)
	block(v, "LegR", Vector3.new(3.0, 4.6, 3.2), rootCf * CFrame.new(3.2, -9.2, 0), s, Enum.Material.Concrete)
	block(v, "FootL", Vector3.new(3.4, 1.2, 4.2), rootCf * CFrame.new(-3.2, -11.4, -0.4), DARK, Enum.Material.SmoothPlastic)
	block(v, "FootR", Vector3.new(3.4, 1.2, 4.2), rootCf * CFrame.new(3.2, -11.4, -0.4), DARK, Enum.Material.SmoothPlastic)

	local torso = block(v, "Body", Vector3.new(8.6, 7.2, 6.0), rootCf * CFrame.new(0, -4.0, 0), p, Enum.Material.Concrete)
	block(v, "ChestPlate", Vector3.new(7.4, 3.6, 0.8), rootCf * CFrame.new(0, -3.4, -3.0), s, Enum.Material.Slate)
	block(v, "Belt", Vector3.new(8.2, 1.1, 6.2), rootCf * CFrame.new(0, -7.1, 0), DARK, Enum.Material.SmoothPlastic)
	block(v, "Buckle", Vector3.new(2.0, 1.5, 0.5), rootCf * CFrame.new(0, -7.1, -3.2), a, Enum.Material.Foil)

	ball(v, "ShoulderL", Vector3.new(4.8, 4.2, 4.8), rootCf * CFrame.new(-5.0, -0.6, 0), s, Enum.Material.Metal)
	ball(v, "ShoulderR", Vector3.new(4.8, 4.2, 4.8), rootCf * CFrame.new(5.0, -0.6, 0), s, Enum.Material.Metal)
	block(v, "ArmL", Vector3.new(2.6, 5.4, 2.6), rootCf * CFrame.new(-5.7, -4.6, 0) * CFrame.Angles(0, 0, 0.16), p, Enum.Material.Concrete)
	block(v, "ArmR", Vector3.new(2.6, 5.4, 2.6), rootCf * CFrame.new(5.7, -4.6, 0) * CFrame.Angles(0, 0, -0.16), p, Enum.Material.Concrete)
	ball(v, "FistL", Vector3.new(3.2, 3.0, 3.2), rootCf * CFrame.new(-5.9, -7.6, 0), s, Enum.Material.Concrete)
	ball(v, "FistR", Vector3.new(3.2, 3.0, 3.2), rootCf * CFrame.new(5.9, -7.6, 0), s, Enum.Material.Concrete)

	local head = ball(v, "Head", Vector3.new(6.4, 5.4, 5.4), rootCf * CFrame.new(0, 3.4, 0), p)
	block(v, "Brow", Vector3.new(5.4, 0.9, 0.9), rootCf * CFrame.new(0, 5.9, -2.5), s, Enum.Material.Slate)
	ball(v, "EyeL", Vector3.new(1.5, 1.8, 0.7), rootCf * CFrame.new(-1.6, 4.7, -2.6), a, Enum.Material.Neon)
	ball(v, "EyeR", Vector3.new(1.5, 1.8, 0.7), rootCf * CFrame.new(1.6, 4.7, -2.6), a, Enum.Material.Neon)
	block(v, "Jaw", Vector3.new(5.0, 1.6, 2.0), rootCf * CFrame.new(0, 2.3, -2.6), MOUTH)
	for i = 1, 4 do
		local x = -1.5 + (i - 1)
		block(v, "Tooth" .. i, Vector3.new(0.42, 0.8, 0.3), rootCf * CFrame.new(x, 2.9, -3.3), BONE)
	end
	block(v, "TuskL", Vector3.new(0.7, 2.4, 0.7), rootCf * CFrame.new(-2.5, 1.9, -2.8) * CFrame.Angles(0, 0, 0.22), BONE, Enum.Material.SmoothPlastic)
	block(v, "TuskR", Vector3.new(0.7, 2.4, 0.7), rootCf * CFrame.new(2.5, 1.9, -2.8) * CFrame.Angles(0, 0, -0.22), BONE, Enum.Material.SmoothPlastic)

	block(v, "HornL", Vector3.new(1.3, 4.2, 1.3), rootCf * CFrame.new(-3.0, 7.4, 0.2) * CFrame.Angles(0, 0, 0.42), s, Enum.Material.Metal)
	block(v, "HornR", Vector3.new(1.3, 4.2, 1.3), rootCf * CFrame.new(3.0, 7.4, 0.2) * CFrame.Angles(0, 0, -0.42), s, Enum.Material.Metal)

	local crown = group(v, "Crown", rootCf * CFrame.new(0, 6.9, 0))
	crown:SetAttribute("FXSpin", 0.22)
	disc(crown, "Band", 5.6, 0.7, rootCf * CFrame.new(0, 6.9, 0), a, Enum.Material.Foil, 0.02)
	for i = 1, 7 do
		local angle = (i / 7) * math.pi * 2
		block(
			crown,
			"Spike" .. i,
			Vector3.new(0.55, 1.9, 0.55),
			rootCf * CFrame.new(math.cos(angle) * 2.4, 7.7, math.sin(angle) * 2.4) * CFrame.Angles(0.12, angle, 0.1),
			a,
			Enum.Material.Foil
		)
	end

	local core = ball(v, "Core", Vector3.new(3.0, 3.0, 1.8), rootCf * CFrame.new(0, -3.2, -3.2), a, Enum.Material.Neon)
	glowLight(core, p, 1.4, 34)
	glowLight(torso, a, 0.5, 22)

	local aura = group(v, "Aura", rootCf * CFrame.new(0, -11.85, 0))
	aura:SetAttribute("FXSpin", 0.5)
	disc(aura, "Ring", 26, 0.14, rootCf * CFrame.new(0, -11.85, 0), p, Enum.Material.Neon, 0.55)
	disc(aura, "RingInner", 15, 0.1, rootCf * CFrame.new(0, -11.82, 0), a, Enum.Material.Neon, 0.65)

	local orbit = group(v, "Orbit", rootCf * CFrame.new(0, 0, 0))
	orbit:SetAttribute("FXSpin", 0.9)
	for i = 1, 4 do
		local angle = (i / 4) * math.pi * 2
		block(
			orbit,
			"Shard" .. i,
			Vector3.new(0.5, 1.5, 0.5),
			rootCf * CFrame.new(math.cos(angle) * 8.0, 2.0 + i * 0.6, math.sin(angle) * 8.0) * CFrame.Angles(0.3, angle, 0.2),
			a,
			Enum.Material.Neon
		)
	end

	sparkle(core, a, 10, 0.32)

	local hl = Instance.new("Highlight")
	hl.FillColor = p
	hl.OutlineColor = a
	hl.FillTransparency = 0.84
	hl.OutlineTransparency = 0.35
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Parent = model
end

function EntityFactory.updateHealthBar(model: Model, hp: number, maxHp: number)
	local root = model.PrimaryPart or model:FindFirstChild("Root")
	if not root then
		return
	end
	local gui = root:FindFirstChild("Label")
	if not gui then
		return
	end
	local back = gui:FindFirstChild("Back")
	local bar = back and back:FindFirstChild("Bar")
	local fill = bar and bar:FindFirstChild("Fill")
	if fill and fill:IsA("GuiObject") then
		fill.Size = UDim2.fromScale(math.clamp(hp / math.max(maxHp, 1), 0, 1), 1)
	end
end

function EntityFactory.assemble(model: Model, entityType: string, extra: { [string]: any }?)
	local def = Config.Entities[entityType] or Config.Entities.Small
	local isBoss = extra and extra.visual == "Boss"
	local size = (extra and extra.size) or def.size
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = size
	root.Transparency = 1
	root.Material = Enum.Material.SmoothPlastic
	root.Color = (extra and extra.color) or def.color
	root.CFrame = (extra and extra.cframe) or CFrame.new()
	mark(root, true)
	root.Parent = model
	model.PrimaryPart = root

	local rootCf = root.CFrame
	if isBoss then
		buildBoss(model, rootCf)
	elseif entityType == "Elite" then
		buildElite(model, rootCf, def)
	elseif entityType == "Rare" then
		buildRare(model, rootCf, def)
	else
		buildSmall(model, rootCf, def)
	end

	model:SetAttribute("BobAmplitude", isBoss and Config.Event.bobAmplitude or def.bobAmplitude)
	model:SetAttribute("BobSpeed", isBoss and Config.Event.bobSpeed or def.bobSpeed)
	model:SetAttribute("HasLabel", not isBoss)

	if not isBoss then
		local title = (extra and extra.name) or def.displayName or model.Name
		local color = (extra and extra.color) or def.color
		compactLabel(
			root,
			title,
			def.tier or "",
			color,
			def.tierColor or def.accent,
			def.labelWidth or 72,
			def.labelHeight or 19,
			def.labelDistance or 30
		)
	end
end

function EntityFactory.setAlive(model: Model, alive: boolean)
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") then
			local baseT = inst:GetAttribute("BaseTransparency")
			if typeof(baseT) ~= "number" then
				baseT = 0
			end
			inst.Transparency = alive and baseT or 1
			inst.CanCollide = alive and inst:GetAttribute("BaseCanCollide") == true
		elseif inst:IsA("ParticleEmitter") or inst:IsA("PointLight") or inst:IsA("Highlight") then
			inst.Enabled = alive
		elseif inst:IsA("BillboardGui") then
			inst.Enabled = alive
		end
	end
	model:SetAttribute("Alive", alive)
end

return EntityFactory
