-- Client-side visual layer for Brainrot entities.
-- Everything here is cosmetic and local: idle bob/spin, distant-label culling,
-- damage numbers, hit bursts and the boss arrival shockwave. No remotes added.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(ReplicatedStorage.Shared.Theme)

local EntityFX = {}

local TAGS = { Config.TAG_HARVESTABLE, Config.TAG_EVENT_BOSS }

type SpinGroup = { model: Model, base: CFrame, speed: number }
type Tracked = {
	root: BasePart?,
	visual: Model?,
	basePivot: CFrame?,
	spins: { SpinGroup },
	label: BillboardGui?,
	labelDistance: number,
	phase: number,
	dist: number,
}

local tracked: { [Model]: Tracked } = {}
local recentHit: { [Model]: number } = {}

local floatPool = {}
local FLOAT_LIMIT = 16
local burstHost: Part
local burstEmitter: ParticleEmitter
local anchor: Part
local clock = 0

local function cameraPos(): Vector3
	local camera = Workspace.CurrentCamera
	return camera and camera.CFrame.Position or Vector3.zero
end

-- -------------------------------------------------------------------- effects

local function buildEffectHosts()
	anchor = Instance.new("Part")
	anchor.Name = "BrainrotFXAnchor"
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CastShadow = false
	anchor.CFrame = CFrame.new()
	anchor.Parent = Workspace

	burstHost = Instance.new("Part")
	burstHost.Name = "BrainrotHitBurst"
	burstHost.Size = Vector3.new(0.2, 0.2, 0.2)
	burstHost.Transparency = 1
	burstHost.Anchored = true
	burstHost.CanCollide = false
	burstHost.CanQuery = false
	burstHost.CanTouch = false
	burstHost.CastShadow = false
	burstHost.CFrame = CFrame.new(0, -60, 0)
	burstHost.Parent = Workspace

	burstEmitter = Instance.new("ParticleEmitter")
	burstEmitter.Name = "Burst"
	burstEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	burstEmitter.Color = ColorSequence.new(Theme.Color.accent)
	burstEmitter.LightEmission = 0.85
	burstEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.34),
		NumberSequenceKeypoint.new(0.6, 0.18),
		NumberSequenceKeypoint.new(1, 0.01),
	})
	burstEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	burstEmitter.Lifetime = NumberRange.new(0.22, 0.45)
	burstEmitter.Speed = NumberRange.new(9, 20)
	burstEmitter.SpreadAngle = Vector2.new(180, 180)
	burstEmitter.Rate = 0
	burstEmitter.Drag = 4
	burstEmitter.Acceleration = Vector3.new(0, -14, 0)
	burstEmitter.Parent = burstHost
end

local function burst(position: Vector3, color: Color3, amount: number)
	if not burstEmitter then
		return
	end
	burstHost.CFrame = CFrame.new(position)
	burstEmitter.Color = ColorSequence.new(color)
	burstEmitter:Emit(amount)
end

local function acquireFloat()
	for _, entry in floatPool do
		if not entry.inUse then
			entry.inUse = true
			return entry
		end
	end
	if #floatPool >= FLOAT_LIMIT then
		return nil
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "FloatText"
	gui.Size = UDim2.fromOffset(150, 34)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 160
	gui.Adornee = anchor
	gui.Enabled = false
	gui.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 20
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeColor3 = Color3.fromRGB(12, 8, 18)
	label.TextStrokeTransparency = 0.25
	label.Text = ""
	label.Parent = gui

	local entry = { gui = gui, label = label, inUse = true }
	table.insert(floatPool, entry)
	return entry
end

local function floatText(position: Vector3, text: string, color: Color3, textSize: number, rise: number?)
	local entry = acquireFloat()
	if not entry then
		return
	end
	local gui = entry.gui
	local label = entry.label
	local width = math.clamp(#text * textSize * 0.68, 64, 240)
	gui.Size = UDim2.fromOffset(width, 38)
	gui.StudsOffsetWorldSpace = position
	gui.Enabled = true

	label.Text = text
	label.TextColor3 = color
	label.TextSize = textSize
	label.TextTransparency = 0
	label.TextStrokeTransparency = 0.25

	local travel = rise or 3.4
	local tweenInfo = TweenInfo.new(0.72, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fade = TweenService:Create(label, tweenInfo, { TextTransparency = 1, TextStrokeTransparency = 1 })
	TweenService:Create(gui, tweenInfo, { StudsOffsetWorldSpace = position + Vector3.new(0, travel, 0) }):Play()
	fade.Completed:Once(function()
		gui.Enabled = false
		entry.inUse = false
	end)
	fade:Play()
end

-- ------------------------------------------------------------------- tracking

local function track(model: Model)
	if tracked[model] then
		return
	end
	local root = model.PrimaryPart or model:FindFirstChild("Root")
	if not root or not root:IsA("BasePart") then
		return
	end
	local state: Tracked = {
		root = root,
		spins = {},
		phase = math.random() * math.pi * 2,
		dist = math.huge,
		labelDistance = 28,
	}

	local visual = model:FindFirstChild("Visual")
	if visual and visual:IsA("Model") and visual.PrimaryPart then
		state.visual = visual
		state.basePivot = visual:GetPivot()
		for _, inst in visual:GetDescendants() do
			if inst:IsA("Model") then
				local speed = inst:GetAttribute("FXSpin")
				if typeof(speed) == "number" and inst.PrimaryPart then
					table.insert(state.spins, { model = inst, base = inst:GetPivot(), speed = speed })
				end
			end
		end
	end

	local label = root:FindFirstChild("Label")
	if label and label:IsA("BillboardGui") then
		state.label = label
		if label.MaxDistance > 0 then
			state.labelDistance = label.MaxDistance
		end
	end

	tracked[model] = state
end

local function untrack(model: Model)
	tracked[model] = nil
	recentHit[model] = nil
end

local function refreshTracked()
	for model in tracked do
		if not model.Parent then
			untrack(model)
		end
	end
	for _, tag in TAGS do
		for _, inst in CollectionService:GetTagged(tag) do
			if inst:IsA("Model") then
				track(inst)
			end
		end
	end
end

-- ---------------------------------------------------------------- label culling

local function updateLabels()
	local cam = cameraPos()
	local now = os.clock()
	local nearest: Model? = nil
	local nearestDist = math.huge

	for model, state in tracked do
		local root = state.root
		if root and root.Parent then
			state.dist = (root.Position - cam).Magnitude
			if state.dist < nearestDist then
				nearest = model
				nearestDist = state.dist
			end
		end
	end

	local shown = 0
	-- Priority pass: recently damaged enemies and whatever you are standing next to.
	for model, state in tracked do
		local label = state.label
		if label then
			local alive = model:GetAttribute("Alive") ~= false and state.root ~= nil and state.root.Parent ~= nil
			local isRecent = (recentHit[model] or 0) + 3.5 > now
			local isNearest = model == nearest and state.dist < 60
			if alive and (isRecent or isNearest) then
				label.Enabled = true
				shown += 1
			else
				label.Enabled = false
			end
		end
	end

	-- Secondary pass: only a couple of nearby plates, never the whole screen.
	for model, state in tracked do
		local label = state.label
		if label and not label.Enabled and shown < 5 then
			local alive = model:GetAttribute("Alive") ~= false and state.root ~= nil and state.root.Parent ~= nil
			local radius = state.labelDistance * 0.62
			if alive and state.dist <= radius then
				label.Enabled = true
				shown += 1
			end
		end
	end
end

-- ------------------------------------------------------------------- animation

local ANIM_RADIUS = 145
local ANIM_LIMIT = 26
local animAccumulator = 0
local labelAccumulator = 0

local function animate(dt: number)
	local cam = cameraPos()
	local budget = 0

	for model, state in tracked do
		local visual = state.visual
		local root = state.root
		if visual and state.basePivot and root and root.Parent and budget < ANIM_LIMIT then
			local alive = model:GetAttribute("Alive") ~= false
			local distance = (root.Position - cam).Magnitude
			state.dist = distance
			if alive and distance <= ANIM_RADIUS then
				budget += 1
				local amplitude = visual:GetAttribute("BobAmplitude") or 0.18
				local speed = visual:GetAttribute("BobSpeed") or 1.6
				local wave = math.sin(clock * speed + state.phase)
				local bob = wave * amplitude
				local sway = math.cos(clock * speed * 0.6 + state.phase) * 0.03
				visual:PivotTo(state.basePivot * CFrame.new(0, bob, 0) * CFrame.Angles(0, sway, sway * 0.4))
				for _, spin in state.spins do
					spin.model:PivotTo(spin.base * CFrame.Angles(0, clock * spin.speed, 0))
				end
			end
		end
	end
end

-- -------------------------------------------------------------------- feedback

local function onHit(model, amount: number, isCrit: boolean, hp: number)
	recentHit[model] = os.clock()
	local state = tracked[model]
	local root = state and state.root
	if not root or not root.Parent then
		return
	end
	local position = root.Position
	local camera = Workspace.CurrentCamera
	if camera and (position - camera.CFrame.Position).Magnitude > 110 then
		return
	end

	local offset = Vector3.new((math.random() - 0.5) * 2.6, 1.2 + math.random() * 1.6, (math.random() - 0.5) * 2.6)
	local text = isCrit and string.format("%d CRIT", math.floor(amount)) or tostring(math.floor(amount))
	local color = isCrit and Theme.Color.gold or Color3.fromRGB(255, 246, 255)
	floatText(position + offset + Vector3.new(0, (root.Size.Y * 0.5) * 0.35, 0), text, color, isCrit and 26 or 20, isCrit and 4.2 or 3.2)

	burst(position + offset * 0.4, isCrit and Theme.Color.gold or Theme.Color.accent, isCrit and 16 or 9)

	if hp <= 0 then
		burst(position, Theme.Color.accentAlt, 22)
	end
end

local function onShout(model, shout: string)
	local state = tracked[model]
	local root = state and state.root
	if not root or not root.Parent or typeof(shout) ~= "string" then
		return
	end
	local camera = Workspace.CurrentCamera
	if not camera or (root.Position - camera.CFrame.Position).Magnitude > 55 then
		return
	end
	local isBoss = model:GetAttribute("EntityType") == "EventBoss"
	floatText(
		root.Position + Vector3.new(0, root.Size.Y * 0.5 + 3.4, 0),
		shout,
		isBoss and Theme.Color.danger or Theme.Color.gold,
		isBoss and 24 or 17,
		2.4
	)
end

function EntityFX.bossArrival()
	local spawn = Config.Event.spawn
	local ring = Instance.new("Part")
	ring.Name = "BossShockwave"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.3, 8, 8)
	ring.CFrame = CFrame.new(spawn + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = Config.Event.glow
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.25
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	ring.Parent = Workspace

	TweenService
		:Create(ring, TweenInfo.new(1.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.3, 92, 92),
			Transparency = 1,
		})
		:Play()
	task.delay(1.3, function()
		ring:Destroy()
	end)
	burst(spawn + Vector3.new(0, 3, 0), Config.Event.glow, 44)
end

function EntityFX.start()
	buildEffectHosts()
	refreshTracked()

	for _, tag in TAGS do
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst)
			if inst:IsA("Model") then
				task.defer(function()
					if inst.Parent then
						track(inst)
					end
				end)
			end
		end)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(function(inst)
			if inst:IsA("Model") then
				untrack(inst)
			end
		end)
	end

	Remotes.get("HitConfirmed").OnClientEvent:Connect(function(model, amount, isCrit, hp)
		if typeof(model) == "Instance" and model:IsA("Model") then
			onHit(model, amount or 0, isCrit == true, hp or 1)
		end
	end)

	Remotes.get("EntityShout").OnClientEvent:Connect(function(model, shout)
		if typeof(model) == "Instance" and model:IsA("Model") then
			onShout(model, shout)
		end
	end)

	Remotes.get("EventState").OnClientEvent:Connect(function(state)
		if state and state.kind == "spawn" then
			EntityFX.bossArrival()
		end
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			refreshTracked()
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		clock += dt
		animAccumulator += dt
		labelAccumulator += dt

		if animAccumulator >= 1 / 40 then
			animate(animAccumulator)
			animAccumulator = 0
		end
		if labelAccumulator >= 0.2 then
			labelAccumulator = 0
			updateLabels()
		end
	end)

	-- one immediate pass so labels don't flash across the screen on spawn
	task.defer(updateLabels)
end

return EntityFX
