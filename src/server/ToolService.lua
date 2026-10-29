local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local PlayerData = require(script.Parent.PlayerData)
local ProgressionService = require(script.Parent.ProgressionService)
local HarvestService = require(script.Parent.HarvestService)

local ToolService = {}

local lastHit: { [number]: number } = {}
local eventDamage: ((Player, Model, number, boolean) -> boolean)? = nil

local function characterRoot(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function giveTools(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	for _, child in backpack:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("BrainrotTool") then
			child:Destroy()
		end
	end
	if player.Character then
		for _, child in player.Character:GetChildren() do
			if child:IsA("Tool") and child:GetAttribute("BrainrotTool") then
				child:Destroy()
			end
		end
	end
	for toolId, unlocked in data.unlockedTools do
		if unlocked and Config.Tools[toolId] then
			local def = Config.Tools[toolId]
			local tool = Instance.new("Tool")
			tool.Name = def.displayName
			tool.CanBeDropped = false
			tool.RequiresHandle = true
			tool:SetAttribute("BrainrotTool", true)
			tool:SetAttribute("ToolId", toolId)
			local handle = Instance.new("Part")
			handle.Name = "Handle"
			handle.Size = Vector3.new(0.45, 4.2, 0.45)
			handle.Color = def.color
			handle.Material = Enum.Material.SmoothPlastic
			handle.Massless = true
			handle.Parent = tool
			local tip = Instance.new("Part")
			tip.Name = "Tip"
			tip.Size = toolId == "Laser" and Vector3.new(0.35, 0.35, 1.8) or Vector3.new(1.3, 1.1, 1.3)
			tip.Color = def.color
			tip.Material = Enum.Material.Neon
			tip.Massless = true
			tip.CanCollide = false
			tip.Parent = tool
			local weld = Instance.new("Weld")
			weld.Part0 = handle
			weld.Part1 = tip
			weld.C0 = toolId == "Laser" and CFrame.new(0, 2.4, 0) or CFrame.new(0, 2.2, 0)
			weld.Parent = handle
			tool.Parent = backpack
			if data.equippedTool == toolId then
				task.defer(function()
					local character = player.Character
					local humanoid = character and character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid:EquipTool(tool)
					end
				end)
			end
		end
	end
end

function ToolService.setEventDamager(fn)
	eventDamage = fn
end

function ToolService.refresh(player: Player)
	giveTools(player)
end

local function validateHit(player: Player, model: Model): (boolean, number, boolean)
	if typeof(model) ~= "Instance" or not model:IsA("Model") then
		return false, 0, false
	end
	local data = PlayerData.get(player)
	if not data then
		return false, 0, false
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false, 0, false
	end
	local equipped = character:FindFirstChildOfClass("Tool")
	local toolId = equipped and equipped:GetAttribute("ToolId")
	if not toolId or not data.unlockedTools[toolId] then
		return false, 0, false
	end
	local def = Config.Tools[toolId]
	if not def then
		return false, 0, false
	end
	local now = os.clock()
	local prev = lastHit[player.UserId] or 0
	if now - prev < def.cooldown * 0.85 then
		return false, 0, false
	end
	local root = characterRoot(player)
	local target = model.PrimaryPart or model:FindFirstChild("Root")
	if not root or not target or not target:IsA("BasePart") then
		return false, 0, false
	end
	local distance = (root.Position - target.Position).Magnitude
	if distance > def.range + target.Size.Magnitude * 0.35 then
		return false, 0, false
	end
	lastHit[player.UserId] = now
	data.equippedTool = toolId
	local isCrit = math.random() < ProgressionService.critChance(player)
	local damage = def.damage
	if isCrit then
		damage = math.floor(damage * Config.CRIT_MULTIPLIER)
	end
	return true, damage, isCrit
end

function ToolService.start()
	Remotes.get("RequestHit").OnServerEvent:Connect(function(player: Player, model: Model)
		local ok, damage, isCrit = validateHit(player, model)
		if not ok then
			return
		end
		if model:GetAttribute("EntityType") == "EventBoss" or CollectionService:HasTag(model, Config.TAG_EVENT_BOSS) then
			if eventDamage then
				eventDamage(player, model, damage, isCrit)
			end
			return
		end
		HarvestService.damage(player, model, damage, isCrit)
	end)
	Remotes.get("UnlockTool").OnServerInvoke = function(player, toolId)
		local ok, err = ProgressionService.unlockTool(player, toolId)
		if ok then
			giveTools(player)
		end
		return ok, err
	end
	Remotes.get("BuyPerk").OnServerInvoke = function(player, perkId)
		return ProgressionService.buyPerk(player, perkId)
	end
	Remotes.get("EquipTool").OnServerInvoke = function(player, toolId)
		local ok, err = ProgressionService.equipTool(player, toolId)
		if ok then
			giveTools(player)
		end
		return ok, err
	end
	PlayerData.Loaded.Event:Connect(function(player: Player)
		if player.Character then
			giveTools(player)
		end
	end)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.2)
			giveTools(player)
		end)
	end)
	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function()
			task.wait(0.2)
			giveTools(player)
		end)
		if player.Character then
			giveTools(player)
		end
	end
end

return ToolService
