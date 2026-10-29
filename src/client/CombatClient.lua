local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(ReplicatedStorage.Shared.Theme)

local CombatClient = {}

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local lastFlash: { [Model]: number } = {}

local function toolIdOf(tool: Tool): string?
	return tool:GetAttribute("ToolId")
end

local function findEntity(inst: Instance?): Model?
	local current = inst
	while current and current ~= Workspace do
		if current:IsA("Model") then
			if CollectionService:HasTag(current, Config.TAG_HARVESTABLE)
				or CollectionService:HasTag(current, Config.TAG_EVENT_BOSS)
			then
				return current
			end
		end
		current = current.Parent
	end
	return nil
end

-- Short, cheap impact flash. Throttled per model so rapid hits stay readable.
local function flash(model: Model, crit: boolean)
	local now = os.clock()
	local previous = lastFlash[model]
	if previous and now - previous < 0.09 then
		return
	end
	lastFlash[model] = now

	local overlay = Instance.new("Highlight")
	overlay.FillColor = crit and Theme.Color.gold or Theme.Color.accent
	overlay.OutlineTransparency = 1
	overlay.FillTransparency = crit and 0.55 or 0.72
	overlay.DepthMode = Enum.HighlightDepthMode.Occluded
	overlay.Parent = model
	task.delay(crit and 0.16 or 0.11, function()
		overlay:Destroy()
	end)
end

local function beam(fromPos: Vector3, toPos: Vector3, color: Color3, width: number)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = color
	local delta = toPos - fromPos
	part.Size = Vector3.new(width, width, math.max(delta.Magnitude, 0.2))
	part.CFrame = CFrame.lookAt(fromPos + delta / 2, toPos)
	part.Parent = Workspace

	TweenService:Create(part, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 1,
		Size = Vector3.new(width * 0.2, width * 0.2, part.Size.Z),
	}):Play()
	task.delay(0.18, function()
		part:Destroy()
	end)
end

local function fireAt(tool: Tool)
	local id = toolIdOf(tool)
	local def = id and Config.Tools[id]
	if not def then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local targetPos = mouse.Hit.Position
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { character }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local origin = root.Position
	local direction = (targetPos - origin)
	if direction.Magnitude < 0.1 then
		direction = root.CFrame.LookVector * def.range
	else
		direction = direction.Unit * def.range
	end
	local result = Workspace:Raycast(origin, direction, params)
	local model = result and findEntity(result.Instance)
	if not model then
		local nearest: Model? = nil
		local nearestDist = def.range
		local tags = { Config.TAG_HARVESTABLE, Config.TAG_EVENT_BOSS }
		for _, tag in tags do
			for _, inst in CollectionService:GetTagged(tag) do
				if inst:IsA("Model") and inst:GetAttribute("Alive") ~= false then
					local part = inst.PrimaryPart or inst:FindFirstChild("Root")
					if part then
						local dist = (part.Position - origin).Magnitude
						if dist < nearestDist then
							nearest = inst
							nearestDist = dist
						end
					end
				end
			end
		end
		model = nearest
	end
	if model then
		local part = model.PrimaryPart or model:FindFirstChild("Root")
		if part then
			beam(origin, part.Position, def.color, id == "Laser" and 0.22 or (id == "Sonic" and 0.9 or 0.4))
		end
		Remotes.get("RequestHit"):FireServer(model)
	end
end

local function hookTool(tool: Tool)
	if not tool:GetAttribute("BrainrotTool") then
		return
	end
	if tool:GetAttribute("Hooked") then
		return
	end
	tool:SetAttribute("Hooked", true)
	tool.Activated:Connect(function()
		fireAt(tool)
	end)
end

function CombatClient.start()
	local function hookCharacter(character: Model)
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				hookTool(child)
			end
		end)
		for _, child in character:GetChildren() do
			if child:IsA("Tool") then
				hookTool(child)
			end
		end
	end
	player.CharacterAdded:Connect(hookCharacter)
	if player.Character then
		hookCharacter(player.Character)
	end
	local backpack = player:WaitForChild("Backpack")
	backpack.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			hookTool(child)
		end
	end)
	Remotes.get("HitConfirmed").OnClientEvent:Connect(function(model, _amount, isCrit)
		if typeof(model) == "Instance" and model:IsA("Model") then
			flash(model, isCrit == true)
		end
	end)
end

return CombatClient
