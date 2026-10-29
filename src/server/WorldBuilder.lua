local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Config = require(game.ReplicatedStorage.Shared.Config)
local EntityFactory = require(script.Parent.EntityFactory)

local Build = require(script.Parent.World.Build)
local Landmarks = require(script.Parent.World.Landmarks)
local Placement = require(script.Parent.World.Placement)
local Prop = require(script.Parent.World.PropFactory)
local TerrainBuilder = require(script.Parent.World.TerrainBuilder)
local TreeFactory = require(script.Parent.World.TreeFactory)
local WorldPlan = require(script.Parent.World.WorldPlan)

local WorldBuilder = {}

local STYLE = Config.STYLE_VERSION

local PALETTE = {
	path = Color3.fromRGB(196, 182, 160),
	pathAlt = Color3.fromRGB(174, 162, 146),
	curb = Color3.fromRGB(146, 136, 130),
	gold = Color3.fromRGB(255, 206, 110),
	pink = Color3.fromRGB(255, 104, 176),
	violet = Color3.fromRGB(186, 128, 255),
}

-- ----------------------------------------------------------------------- roads

local function buildRoads(parent: Instance)
	local roadFolder = Instance.new("Folder")
	roadFolder.Name = "Roads"
	roadFolder.Parent = parent

	local rng = Placement.rng(WorldPlan.SEED + 5)
	local lanternCount = 0
	for _, path in WorldPlan.paths do
		local samples = Placement.pathSamples(path.points, 20)
		for i = 1, #samples - 1 do
			local a, b = samples[i], samples[i + 1]
			local mid = (a + b) * 0.5
			local length = (b - a).Magnitude + 0.7
			local color = (i % 4 < 2) and PALETTE.path or PALETTE.pathAlt
			Build.block(
				roadFolder,
				"Road",
				Vector3.new(path.width, 0.6, length),
				CFrame.lookAt(Vector3.new(mid.X, 0.3, mid.Z), Vector3.new(b.X, 0.3, b.Z)),
				color,
				Enum.Material.Cobblestone,
				{ collide = true, shadow = false }
			)
			-- curb stones, every third tile, both sides
			if i % 3 == 1 then
				local dir = (b - a).Unit
				local side = Vector3.new(-dir.Z, 0, dir.X)
				for _, sign in { -1, 1 } do
					local pos = mid + side * (path.width * 0.5) * sign
					Build.block(
						roadFolder,
						"Curb",
						Vector3.new(1.6, 0.75, 2.6),
						CFrame.new(pos.X, 0.35, pos.Z) * CFrame.Angles(0, math.atan2(dir.X, dir.Z), 0) * CFrame.Angles(0, 0, rng(-0.06, 0.06)),
						PALETTE.curb,
						Enum.Material.Slate,
						{ collide = true, shadow = false }
					)
				end
			end
			-- lanterns on alternating sides
			if i % 7 == 4 then
				local dir = (b - a).Unit
				local side = Vector3.new(-dir.Z, 0, dir.X) * (path.width * 0.5 + 4) * ((i % 2 == 0) and 1 or -1)
				local pos = mid + side
				Prop.lantern(roadFolder, CFrame.new(pos.X, Placement.heightAt(pos.X, pos.Z), pos.Z), (lanternCount % 2 == 0) and PALETTE.pink or PALETTE.gold, lanternCount % 4 == 0)
				lanternCount += 1
			end
			-- junction markers where roads are wide
			if i % 11 == 5 then
				Build.disc(roadFolder, "RoadStud", 2.2, 0.12, CFrame.new(mid.X, 0.62, mid.Z), PALETTE.gold, Enum.Material.Neon, { transparency = 0.45 })
			end
		end
	end
	return lanternCount
end

-- ---------------------------------------------------------------------- forests

local function plantForests(parent: Instance)
	local treeFolder = Instance.new("Folder")
	treeFolder.Name = "Trees"
	treeFolder.Parent = parent
	local propFolder = Instance.new("Folder")
	propFolder.Name = "Props"
	propFolder.Parent = parent

	local rng = Placement.rng(WorldPlan.SEED + 31)
	local treeCount = 0
	local propCount = 0

	local function plantOne(x: number, z: number, families: { any }, detailBias: number): boolean
		if Placement.inClearing(x, z, 4) or Placement.inWater(x, z, 12) or Placement.inFarm(x, z, 6) then
			return false
		end
		local pathDist = Placement.distanceToPaths(x, z)
		if pathDist < Placement.pathWidthAt(x, z) * 0.5 + 9 then
			return false
		end
		if not Placement.isFree(x, z, 6) then
			return false
		end
		local y = Placement.heightAt(x, z) - 1.1
		local detail = (pathDist < 64 or rng() < detailBias) and "full" or "simple"
		local family = Placement.weighted(rng, families)
		TreeFactory.build(family, treeFolder, CFrame.new(x, y, z) * CFrame.Angles(0, rng(0, math.pi * 2), 0), rng, detail)
		Placement.reserve(x, z, 7)
		treeCount += 1
		return true
	end

	local function plantUndergrowth(x: number, z: number, mix): boolean
		if Placement.inClearing(x, z, 0) or Placement.inWater(x, z, 4) or Placement.inFarm(x, z, -8) then
			return false
		end
		if Placement.distanceToPaths(x, z) < Placement.pathWidthAt(x, z) * 0.5 + 3.5 then
			return false
		end
		if not Placement.isFree(x, z, 1.6) then
			return false
		end
		local y = Placement.heightAt(x, z) - 0.7
		local cf = CFrame.new(x, y, z) * CFrame.Angles(0, rng(0, math.pi * 2), 0)
		local kind = Placement.weighted(rng, mix)
		if kind == "fern" then
			Prop.fern(propFolder, cf, rng)
		elseif kind == "bush" then
			Prop.bush(propFolder, cf, rng, rng(0.7, 1.3))
		elseif kind == "flower" then
			Prop.flower(propFolder, cf, rng)
		elseif kind == "mushroom" then
			Prop.mushroom(propFolder, cf, rng, rng(0.7, 1.2), rng() > 0.75)
		else
			Prop.log(propFolder, cf, rng)
		end
		Placement.reserve(x, z, 2.4)
		propCount += 1
		return true
	end

	for _, biome in WorldPlan.biomes do
		local mix = {}
		for kind, weight in biome.undergrowth do
			table.insert(mix, { kind, weight })
		end
		Placement.scatterDisc(biome.center, biome.radius, biome.spacing, biome.density, rng, function(x, z)
			return plantOne(x, z, biome.families, 0.14)
		end, biome.maxTrees)
		Placement.scatterDisc(biome.center, biome.radius, 26, 0.30, rng, function(x, z)
			return plantUndergrowth(x, z, mix)
		end, 30)
	end

	-- basin fill so there are no bald stretches between biomes
	Placement.scatterDisc(Vector3.new(0, 0, 0), WorldPlan.wilds.radius, WorldPlan.wilds.spacing, WorldPlan.wilds.density, rng, function(x, z)
		if math.sqrt(x * x + z * z) < WorldPlan.wilds.innerRadius then
			return false
		end
		return plantOne(x, z, WorldPlan.wilds.families, 0.2)
	end, WorldPlan.wilds.maxTrees)

	-- rocks, boulders and shoreline reeds
	local scatterProps = Placement.rng(WorldPlan.SEED + 57)
	Placement.scatterDisc(Vector3.new(0, 0, 0), 980, 74, 0.30, scatterProps, function(x, z)
		if Placement.inClearing(x, z, 0) or Placement.distanceToPaths(x, z) < 14 then
			return false
		end
		if not Placement.isFree(x, z, 5) then
			return false
		end
		local y = Placement.heightAt(x, z) - 0.8
		if scatterProps() > 0.72 then
			Prop.boulder(propFolder, CFrame.new(x, y, z), scatterProps, scatterProps(0.8, 1.5))
		else
			Prop.rock(propFolder, CFrame.new(x, y, z), scatterProps, scatterProps(0.7, 1.4))
		end
		Placement.reserve(x, z, 6)
		propCount += 1
		return true
	end, 110)

	for _, lake in WorldPlan.lakes do
		for i = 1, 18 do
			local angle = (i / 18) * math.pi * 2 + scatterProps(-0.2, 0.2)
			local radius = lake.radius + scatterProps(4, 12)
			local x = lake.center.X + math.cos(angle) * radius
			local z = lake.center.Z + math.sin(angle) * radius
			Prop.reed(propFolder, CFrame.new(x, Placement.heightAt(x, z) - 0.3, z), scatterProps)
			propCount += 1
		end
	end

	return treeCount, propCount
end

-- ------------------------------------------------------------------ landmarks

local function buildLandmarks(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Landmarks"
	folder.Parent = parent

	Landmarks.greatbrain(folder, WorldPlan.landmarks[1].position, WorldPlan.landmarks[1].rotation)

	for index, landmark in WorldPlan.landmarks do
		if index > 1 then
			Landmarks.build(landmark.id, folder, landmark.position, landmark.rotation)
		end
		-- a signpost just off the landmark, facing the trail
		local signPos = landmark.position + Vector3.new(0, 0, 30)
		Prop.signpost(
			folder,
			CFrame.new(signPos.X, Placement.heightAt(signPos.X, signPos.Z), signPos.Z),
			landmark.label,
			{ "FOLLOW THE STONE ROAD" },
			PALETTE.gold
		)
	end

	for _, sign in WorldPlan.signs do
		Prop.signpost(
			folder,
			CFrame.new(sign.position.X, Placement.heightAt(sign.position.X, sign.position.Z), sign.position.Z)
				* CFrame.Angles(0, math.atan2(sign.facing.X, sign.facing.Z), 0),
			sign.title,
			sign.lines,
			PALETTE.gold
		)
	end
end

-- --------------------------------------------------------------------- lighting

local function applyLighting()
	Lighting.ClockTime = 15.1
	Lighting.Brightness = 2.6
	Lighting.ExposureCompensation = 0.12
	Lighting.Ambient = Color3.fromRGB(74, 68, 92)
	Lighting.OutdoorAmbient = Color3.fromRGB(142, 132, 150)
	Lighting.FogColor = Color3.fromRGB(206, 190, 208)
	Lighting.FogStart = 380
	Lighting.FogEnd = 1560
	Lighting.EnvironmentDiffuseScale = 0.55
	Lighting.EnvironmentSpecularScale = 0.35
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.4

	local function replace(className: string, name: string, apply)
		local existing = Lighting:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
		local inst = Instance.new(className)
		inst.Name = name
		apply(inst)
		inst.Parent = Lighting
	end

	replace("Atmosphere", "BrainrotAtmosphere", function(a)
		a.Density = 0.31
		a.Offset = 0.08
		a.Color = Color3.fromRGB(244, 228, 236)
		a.Decay = Color3.fromRGB(96, 84, 120)
		a.Glare = 0.1
		a.Haze = 1.9
	end)
	replace("BloomEffect", "BrainrotBloom", function(b)
		b.Intensity = 0.24
		b.Size = 20
		b.Threshold = 1.3
	end)
	replace("ColorCorrectionEffect", "BrainrotColor", function(c)
		c.Brightness = 0.015
		c.Contrast = 0.09
		c.Saturation = 0.12
		c.TintColor = Color3.fromRGB(255, 244, 248)
	end)
	replace("SunRaysEffect", "BrainrotSun", function(s)
		s.Intensity = 0.055
		s.Spread = 0.34
	end)
	replace("Sky", "BrainrotSky", function(s)
		s.CelestialBodiesShown = true
		s.StarCount = 1400
		s.SunAngularSize = 12
		s.MoonAngularSize = 7
	end)
end

-- ----------------------------------------------------------------------- world

local function ensureSpawn()
	local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
	if not spawn then
		spawn = Instance.new("SpawnLocation")
		spawn.Name = "SpawnLocation"
		spawn.Parent = Workspace
	end
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(WorldPlan.SPAWN.X, 1.0, WorldPlan.SPAWN.Z)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = PALETTE.pink
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn:SetAttribute("AutoGenerated", true)
end

local function wipeGenerated()
	for _, name in { "MainWorldBase", "WorldDecor", "Harvestables", "GeneratedWorld" } do
		local inst = Workspace:FindFirstChild(name)
		if inst then
			inst:Destroy()
		end
	end
	for _, inst in Workspace:GetChildren() do
		if inst.Name == "WorldBoundary" and inst:GetAttribute("AutoGenerated") then
			inst:Destroy()
		end
	end
	local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
	if spawn and spawn:GetAttribute("AutoGenerated") == true then
		spawn:Destroy()
	end
	Workspace.Terrain:Clear()
end

function WorldBuilder.createEntity(entityType: string, position: Vector3, extra: { [string]: any }?): Model
	local def = Config.Entities[entityType]
	assert(def, "Unknown entity type " .. tostring(entityType))
	local model = Instance.new("Model")
	model.Name = (extra and extra.name) or (def.displayName or (entityType .. "Brainrot"))
	local payload = extra and table.clone(extra) or {}
	local size = payload.size or def.size
	payload.cframe = CFrame.new(position + Vector3.new(0, size.Y / 2, 0))
	EntityFactory.assemble(model, entityType, payload)
	model:SetAttribute("EntityType", entityType)
	model:SetAttribute("MaxHP", (extra and extra.hp) or def.hp)
	model:SetAttribute("HP", (extra and extra.hp) or def.hp)
	model:SetAttribute("Alive", true)
	model:SetAttribute("VisualStyle", STYLE)
	CollectionService:AddTag(model, (extra and extra.tag) or Config.TAG_HARVESTABLE)
	model.Parent = (extra and extra.parent) or Workspace:FindFirstChild("Harvestables") or Workspace
	return model
end

local function needsRebuild(): boolean
	local base = Workspace:FindFirstChild("MainWorldBase")
	if not base then
		return true
	end
	return base:GetAttribute("StyleVersion") ~= STYLE
end

local function buildZones(folder: Instance)
	local rng = Placement.rng(WorldPlan.SEED + 401)
	local total = 0
	for entityType, clusters in WorldPlan.zones do
		for _, spec in clusters do
			local placed = 0
			Placement.scatterDisc(spec.center, spec.radius, 13, 0.8, rng, function(x, z)
				if placed >= spec.count then
					return false
				end
				if Placement.inWater(x, z, 14) then
					return false
				end
				if not Placement.isFree(x, z, 9) then
					return false
				end
				local y = Placement.heightAt(x, z) - 0.6
				WorldBuilder.createEntity(entityType, Vector3.new(x, y, z), { parent = folder })
				Placement.reserve(x, z, 12)
				placed += 1
				total += 1
				return true
			end, spec.count * 6)
		end
	end
	return total
end

function WorldBuilder.ensureWorld()
	Placement.init()
	applyLighting()

	local treeCount, propCount, entityCount = 0, 0, 0

	if needsRebuild() then
		wipeGenerated()

		local startClock = os.clock()
		local mounds = TerrainBuilder.build()

		local base = Instance.new("Folder")
		base.Name = "MainWorldBase"
		base:SetAttribute("StyleVersion", STYLE)
		base:SetAttribute("AutoGenerated", true)
		base.Parent = Workspace

		local decor = Instance.new("Folder")
		decor.Name = "Decor"
		decor.Parent = base

		local backdrop = Instance.new("Folder")
		backdrop.Name = "Backdrop"
		backdrop.Parent = base
		TerrainBuilder.buildBackdrop(backdrop)
		TerrainBuilder.buildBoundary(base)

		Landmarks.plaza(decor)
		Landmarks.glade(decor, WorldPlan.SPAWN)
		buildLandmarks(decor)
		local lanterns = buildRoads(decor)
		treeCount, propCount = plantForests(decor)

		ensureSpawn()

		print(string.format(
			"[Brainrot World] Built Main Forest: %d terrain mounds, %d trees, %d props, %d lanterns in %.1fs",
			mounds,
			treeCount,
			propCount,
			lanterns,
			os.clock() - startClock
		))
	else
		ensureSpawn()
	end

	local folder = Workspace:FindFirstChild("Harvestables")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Harvestables"
		folder.Parent = Workspace
	end

	local existing = CollectionService:GetTagged(Config.TAG_HARVESTABLE)
	for i = #existing, 1, -1 do
		local model = existing[i]
		if not model:IsA("Model") or model:GetAttribute("VisualStyle") ~= STYLE then
			if model:IsA("Model") then
				model:Destroy()
			end
			table.remove(existing, i)
		end
	end
	if #existing > 0 then
		return
	end

	entityCount = buildZones(folder)
	print(string.format("[Brainrot World] Spawned %d harvestable Brainrots across the forest", entityCount))
end

return WorldBuilder
