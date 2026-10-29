-- Low-level part construction shared by every world module (terrain props, trees,
-- landmarks). Scenery is anchored and non-queried by default so the combat raycast
-- in CombatClient passes through decorative leaves instead of stopping on them.

local Build = {}

Build.DARK = Color3.fromRGB(26, 20, 32)
Build.BONE = Color3.fromRGB(246, 238, 214)
Build.EYE = Color3.fromRGB(252, 252, 255)
Build.MOUTH = Color3.fromRGB(44, 22, 34)

type Opts = {
	collide: boolean?,
	transparency: number?,
	shape: Enum.PartType?,
	shadow: boolean?,
	query: boolean?,
	reflectance: number?,
	canTouch: boolean?,
}

local function finish(part: Part, opts: Opts?): Part
	local o = opts or {}
	part.Anchored = true
	part.CanCollide = o.collide == true
	part.CanTouch = o.canTouch == true
	part.CanQuery = o.query == true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Transparency = o.transparency or 0
	part.CastShadow = o.shadow ~= false
	part.Reflectance = o.reflectance or 0
	if o.shape then
		part.Shape = o.shape
	end
	return part
end

function Build.part(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	opts: Opts?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return finish(p, opts)
end

function Build.block(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	opts: Opts?
): Part
	return Build.part(parent, name, size, cf, color, material, opts)
end

function Build.wedge(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	opts: Opts?
): Part
	local o = table.clone(opts or {})
	o.shape = Enum.PartType.Wedge
	return Build.part(parent, name, size, cf, color, material, o)
end

-- Ellipsoid: a Part sized to the bounding box with a sphere mesh fills that box,
-- which gives non-uniform organic shapes (canopies, boulders, faces).
function Build.ball(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	opts: Opts?
): Part
	local p = Build.part(parent, name, size, cf, color, material, opts)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

-- Vertical cylinder. `cf` is the centre of the cylinder.
function Build.column(
	parent: Instance,
	name: string,
	height: number,
	diameter: number,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	opts: Opts?
): Part
	local o = table.clone(opts or {})
	o.shape = Enum.PartType.Cylinder
	local p = Build.part(parent, name, Vector3.new(height, diameter, diameter), cf, color, material, o)
	p.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	return p
end

-- Flat disc lying on the ground (auras, plates, dais rings).
function Build.disc(
	parent: Instance,
	name: string,
	diameter: number,
	thickness: number,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	opts: Opts?
): Part
	local o = table.clone(opts or {})
	o.shape = Enum.PartType.Cylinder
	o.shadow = false
	local p = Build.part(parent, name, Vector3.new(thickness, diameter, diameter), cf, color, material, o)
	p.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	p.CanCollide = o.collide == true
	return p
end

function Build.group(parent: Instance, name: string, cf: CFrame): Model
	local model = Instance.new("Model")
	model.Name = name
	local pivot = Instance.new("Part")
	pivot.Name = "Pivot"
	pivot.Size = Vector3.new(0.1, 0.1, 0.1)
	pivot.Transparency = 1
	pivot.CFrame = cf
	pivot.Anchored = true
	pivot.CanCollide = false
	pivot.CanQuery = false
	pivot.CanTouch = false
	pivot.Parent = model
	model.PrimaryPart = pivot
	model.Parent = parent
	return model
end

function Build.sparkle(parent: BasePart, color: Color3, rate: number, opts: {
	size: number?,
	lifetime: Vector2?,
	speed: Vector2?,
	spread: number?,
	light: number?,
}?)
	local o = opts or {}
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Sparkle"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = o.light or 0.5
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, o.size or 0.24),
		NumberSequenceKeypoint.new(1, 0.02),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	local life = o.lifetime or Vector2.new(1, 2)
	emitter.Lifetime = NumberRange.new(life.X, life.Y)
	emitter.Rate = rate
	local speed = o.speed or Vector2.new(0.4, 1.2)
	emitter.Speed = NumberRange.new(speed.X, speed.Y)
	local spread = o.spread or 30
	emitter.SpreadAngle = Vector2.new(spread, spread)
	emitter.RotSpeed = NumberRange.new(-40, 40)
	emitter.Acceleration = Vector3.new(0, 0.7, 0)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent = parent
	return emitter
end

function Build.glow(parent: BasePart, color: Color3, brightness: number, range: number): PointLight
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Shadows = false
	light.Parent = parent
	return light
end

return Build
