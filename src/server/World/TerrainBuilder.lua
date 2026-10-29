-- Terrain, water and the distant mountain ring.
--
-- Sculpting is done with voxel fills (FillCylinder / FillBall / FillBlock) rather
-- than per-voxel arrays: it is bounded, deterministic and cheap enough to run once
-- on first boot. Sizes are kept under Roblox's per-call voxel budget.

local Build = require(script.Parent.Build)
local Placement = require(script.Parent.Placement)
local WorldPlan = require(script.Parent.WorldPlan)

local TerrainBuilder = {}

local PALETTE = {
	grass = Color3.fromRGB(84, 158, 96),
	rock = Color3.fromRGB(122, 118, 136),
	rockDark = Color3.fromRGB(92, 88, 108),
	rockLight = Color3.fromRGB(158, 152, 168),
	snow = Color3.fromRGB(244, 248, 255),
	pine = Color3.fromRGB(48, 92, 78),
}

local function clearWaterLook(terrain: Terrain)
	terrain.WaterColor = Color3.fromRGB(52, 138, 158)
	terrain.WaterTransparency = 0.18
	terrain.WaterWaveSize = 0.28
	terrain.WaterWaveSpeed = 5
	terrain.WaterReflectance = 0.14
	terrain.WaterWaveDirection = Vector3.new(0.06, 0, 0.1)
end

local function buildBase(terrain: Terrain)
	local radius = WorldPlan.TERRAIN_RADIUS
	-- Three stacked slabs keep every single call inside the voxel budget.
	terrain:FillCylinder(CFrame.new(0, -27, 0), 26, radius, Enum.Material.Rock)
	terrain:FillCylinder(CFrame.new(0, -7, 0), 14, radius, Enum.Material.Rock)
	terrain:FillCylinder(CFrame.new(0, -0.75, 0), 1.5, radius, Enum.Material.Grass)
	terrain:FillCylinder(CFrame.new(0, -3.2, 0), 3.4, radius, Enum.Material.Ground)
end

local function buildMounds(terrain: Terrain)
	local mounds = Placement.mounds()
	for _, m in mounds do
		terrain:FillBall(Vector3.new(m.x, m.base, m.z), m.r, m.material)
	end
	return #mounds
end

local function buildWater(terrain: Terrain)
	local level = WorldPlan.WATER_LEVEL
	for _, lake in WorldPlan.lakes do
		local c = lake.center
		-- carve the basin, lay a sandy bed, then fill to the water line
		terrain:FillCylinder(CFrame.new(c.X, -3, c.Z), 8, lake.radius, Enum.Material.Air)
		terrain:FillCylinder(CFrame.new(c.X, -8, c.Z), 2.2, lake.radius, Enum.Material.Sand)
		terrain:FillCylinder(CFrame.new(c.X, (level - 7) * 0.5, c.Z), 7 + level, lake.radius - 1.5, Enum.Material.Water)
		-- scalloped sandy shore so the waterline reads as a beach
		local patches = 14
		for i = 1, patches do
			local angle = (i / patches) * math.pi * 2
			local pos = CFrame.new(c.X + math.cos(angle) * (lake.radius + 9), -0.6, c.Z + math.sin(angle) * (lake.radius + 9))
			terrain:FillCylinder(pos, 1.6, 15, Enum.Material.Sand)
		end
	end
	for _, stream in WorldPlan.streams do
		local pts = stream.points
		for i = 1, #pts - 1 do
			local a, b = pts[i], pts[i + 1]
			local length = (b - a).Magnitude
			local steps = math.max(1, math.ceil(length / 9))
			for s = 0, steps do
				local p = a:Lerp(b, s / steps)
				terrain:FillCylinder(CFrame.new(p.X, -1, p.Z), 14, stream.width * 0.5 + 2, Enum.Material.Air)
				terrain:FillCylinder(CFrame.new(p.X, level - 2.5, p.Z), 5, stream.width * 0.5, Enum.Material.Water)
			end
		end
	end
end

-- Distant mountains: overlapping rock ellipsoids read as ridges and cost a few
-- parts each, which is far cheaper (and cleaner) than terrain at this distance.
local function addPeak(parent: Instance, cf: CFrame, rng, scale: number, snowy: boolean)
	local peakHeight = rng(90, 210) * scale
	local width = rng(120, 240) * scale
	local rotation = CFrame.Angles(0, rng(0, math.pi * 2), 0)
	Build.ball(
		parent,
		"Peak",
		Vector3.new(width, peakHeight, width * rng(0.7, 1.1)),
		cf * rotation * CFrame.new(0, peakHeight * 0.28, 0),
		PALETTE.rock:Lerp(PALETTE.rockDark, rng()),
		Enum.Material.Rock,
		{ shadow = true }
	)
	Build.ball(
		parent,
		"PeakShoulder",
		Vector3.new(width * 0.72, peakHeight * 0.62, width * 0.66),
		cf * rotation * CFrame.new(rng(-0.35, 0.35) * width, peakHeight * 0.1, rng(-0.3, 0.3) * width),
		PALETTE.rockDark,
		Enum.Material.Rock,
		{ shadow = false }
	)
	Build.ball(
		parent,
		"PeakFoot",
		Vector3.new(width * 1.25, peakHeight * 0.26, width * 1.1),
		cf * rotation * CFrame.new(0, peakHeight * 0.02, 0),
		PALETTE.rock:Lerp(PALETTE.rockLight, 0.25),
		Enum.Material.Rock,
		{ shadow = false }
	)
	if snowy and peakHeight > 150 then
		Build.ball(
			parent,
			"SnowCap",
			Vector3.new(width * 0.4, peakHeight * 0.3, width * 0.36),
			cf * rotation * CFrame.new(0, peakHeight * 0.62, 0),
			PALETTE.snow,
			Enum.Material.Snow,
			{ shadow = false }
		)
	end
	if rng() > 0.55 then
		Build.ball(
			parent,
			"RidgePine",
			Vector3.new(width * 0.34, peakHeight * 0.2, width * 0.34),
			cf * rotation * CFrame.new(rng(-0.2, 0.2) * width, peakHeight * 0.12, rng(-0.2, 0.2) * width),
			PALETTE.pine,
			Enum.Material.Grass,
			{ shadow = false }
		)
	end
end

function TerrainBuilder.buildBackdrop(parent: Instance)
	local rng = Placement.rng(WorldPlan.SEED + 991)
	local peaks = 26
	for i = 1, peaks do
		local angle = (i / peaks) * math.pi * 2 + rng(-0.06, 0.06)
		local radius = rng(1210, 1460)
		local cf = CFrame.new(math.cos(angle) * radius, -18, math.sin(angle) * radius)
		addPeak(parent, cf, rng, rng(1.0, 1.5), true)
		if i % 2 == 0 then
			local outer = radius + rng(160, 320)
			addPeak(parent, CFrame.new(math.cos(angle + 0.09) * outer, -18, math.sin(angle + 0.09) * outer), rng, rng(1.3, 1.9), true)
		end
	end
	-- Mid-distance ridges hide the edge of the playable bowl from every angle.
	local ridges = 34
	for i = 1, ridges do
		local angle = (i / ridges) * math.pi * 2 + rng(-0.05, 0.05)
		local radius = rng(1060, 1180)
		local cf = CFrame.new(math.cos(angle) * radius, -14, math.sin(angle) * radius)
		addPeak(parent, cf, rng, rng(0.34, 0.62), false)
	end
end

function TerrainBuilder.buildBoundary(parent: Instance)
	local radius = WorldPlan.PLAY_RADIUS
	for _, dir in { Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) } do
		local wall = Instance.new("Part")
		wall.Name = "WorldBoundary"
		wall.Size = Vector3.new(
			math.abs(dir.X) > 0 and 8 or radius * 2,
			320,
			math.abs(dir.Z) > 0 and 8 or radius * 2
		)
		wall.CFrame = CFrame.new(dir.X * radius, 120, dir.Z * radius)
		wall.Anchored = true
		wall.CanCollide = true
		wall.CanQuery = false
		wall.CanTouch = false
		wall.Transparency = 1
		wall.CastShadow = false
		wall.Parent = parent
		wall:SetAttribute("AutoGenerated", true)
	end
end

function TerrainBuilder.build()
	local terrain = workspace.Terrain
	terrain:Clear()
	clearWaterLook(terrain)
	buildBase(terrain)
	local moundCount = buildMounds(terrain)
	buildWater(terrain)
	return moundCount
end

return TerrainBuilder
