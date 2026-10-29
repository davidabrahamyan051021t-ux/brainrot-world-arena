local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)

local PlayerData = {}

PlayerData.Loaded = Instance.new("BindableEvent")

local store = DataStoreService:GetDataStore(Config.DataStoreName)
local cache: { [number]: any } = {}
local saving: { [number]: boolean } = {}

local function defaultData()
	return {
		coins = 0,
		xp = 0,
		level = 1,
		unlockedTools = { Chaotic = true },
		equippedTool = "Chaotic",
		perks = {
			MoveSpeed = 0,
			CritChance = 0,
			MaxHealth = 0,
		},
	}
end

local function leaderstats(player: Player, data)
	local folder = player:FindFirstChild("leaderstats")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "leaderstats"
		folder.Parent = player
	end
	local coins = folder:FindFirstChild("Coins")
	if not coins then
		coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Parent = folder
	end
	local level = folder:FindFirstChild("Level")
	if not level then
		level = Instance.new("IntValue")
		level.Name = "Level"
		level.Parent = folder
	end
	coins.Value = data.coins
	level.Value = data.level
end

function PlayerData.publicSnapshot(data)
	return {
		coins = data.coins,
		xp = data.xp,
		level = data.level,
		xpToNext = Config.xpToNext(data.level),
		unlockedTools = table.clone(data.unlockedTools),
		equippedTool = data.equippedTool,
		perks = table.clone(data.perks),
	}
end

function PlayerData.applyStats(player: Player)
	local data = cache[player.UserId]
	if not data then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local speedLevel = data.perks.MoveSpeed or 0
	local hpLevel = data.perks.MaxHealth or 0
	humanoid.WalkSpeed = Config.BASE_WALK_SPEED + speedLevel * Config.Perks.MoveSpeed.perLevel
	local maxHealth = Config.BASE_MAX_HEALTH + hpLevel * Config.Perks.MaxHealth.perLevel
	humanoid.MaxHealth = maxHealth
	if humanoid.Health > maxHealth then
		humanoid.Health = maxHealth
	elseif humanoid.Health <= 0 then
		return
	else
		humanoid.Health = math.max(humanoid.Health, math.min(maxHealth, humanoid.Health))
	end
end

function PlayerData.replicate(player: Player)
	local data = cache[player.UserId]
	if not data then
		return
	end
	leaderstats(player, data)
	Remotes.get("DataUpdated"):FireClient(player, PlayerData.publicSnapshot(data))
end

function PlayerData.get(player: Player)
	return cache[player.UserId]
end

function PlayerData.save(player: Player)
	local data = cache[player.UserId]
	if not data or saving[player.UserId] then
		return
	end
	saving[player.UserId] = true
	local ok, err = pcall(function()
		store:SetAsync("u_" .. player.UserId, data)
	end)
	saving[player.UserId] = false
	if not ok then
		warn("[PlayerData] save failed:", err)
	end
end

local function load(player: Player)
	local ok, result = pcall(function()
		return store:GetAsync("u_" .. player.UserId)
	end)
	local data = defaultData()
	if ok and typeof(result) == "table" then
		for key, value in result do
			if key == "unlockedTools" or key == "perks" then
				if typeof(value) == "table" then
					for k, v in value do
						data[key][k] = v
					end
				end
			else
				data[key] = value
			end
		end
		data.unlockedTools.Chaotic = true
		if not Config.Tools[data.equippedTool] then
			data.equippedTool = "Chaotic"
		end
	elseif not ok then
		warn("[PlayerData] load failed, using defaults:", result)
	end
	cache[player.UserId] = data
	leaderstats(player, data)
	PlayerData.replicate(player)
	PlayerData.applyStats(player)
	PlayerData.Loaded:Fire(player)
end

function PlayerData.start()
	Remotes.get("RequestData").OnServerEvent:Connect(function(player)
		PlayerData.replicate(player)
	end)
	Players.PlayerAdded:Connect(function(player)
		load(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.1)
			PlayerData.applyStats(player)
		end)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
		player.CharacterAdded:Connect(function()
			task.wait(0.1)
			PlayerData.applyStats(player)
		end)
	end
	Players.PlayerRemoving:Connect(function(player)
		PlayerData.save(player)
		cache[player.UserId] = nil
	end)
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			PlayerData.save(player)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(Config.AutoSaveSeconds)
			for _, player in Players:GetPlayers() do
				PlayerData.save(player)
			end
		end
	end)
end

return PlayerData
