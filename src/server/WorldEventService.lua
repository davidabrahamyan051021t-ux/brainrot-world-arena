local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local WorldBuilder = require(script.Parent.WorldBuilder)
local DropService = require(script.Parent.DropService)
local ToolService = require(script.Parent.ToolService)

local WorldEventService = {}

local active: Model? = nil
local hp = 0
local maxHp = Config.Event.hp
local damagers: { [number]: Player } = {}
local endsAt = 0

local function broadcast(kind: string)
	Remotes.get("EventState"):FireAllClients({
		kind = kind,
		hp = hp,
		maxHp = maxHp,
		endsAt = endsAt,
		active = active ~= nil,
	})
end

local function despawn(reason: string)
	if active then
		active:Destroy()
		active = nil
	end
	table.clear(damagers)
	hp = 0
	broadcast(reason)
end

local function spawnBoss()
	if active then
		active:Destroy()
	end
	damagers = {}
	maxHp = Config.Event.hp
	hp = maxHp
	endsAt = workspace:GetServerTimeNow() + Config.Event.duration
	local model = WorldBuilder.createEntity("Rare", Config.Event.spawn, {
		name = "Gigantic Brainrot",
		hp = maxHp,
		size = Config.Event.size,
		color = Config.Event.color,
		tag = Config.TAG_EVENT_BOSS,
		parent = Workspace,
		visual = "Boss",
	})
	model:SetAttribute("EntityType", "EventBoss")
	CollectionService:RemoveTag(model, Config.TAG_HARVESTABLE)
	CollectionService:AddTag(model, Config.TAG_EVENT_BOSS)
	active = model
	Remotes.get("EntityShout"):FireAllClients(model, Config.Event.shout)
	broadcast("spawn")
	task.delay(Config.Event.duration, function()
		if active == model then
			despawn("timeout")
		end
	end)
end

local function onDamage(player: Player, model: Model, amount: number, isCrit: boolean)
	if active ~= model or hp <= 0 then
		return false
	end
	hp = math.max(0, hp - amount)
	damagers[player.UserId] = player
	model:SetAttribute("HP", hp)
	Remotes.get("HitConfirmed"):FireClient(player, model, amount, isCrit, hp, maxHp)
	broadcast("hit")
	if hp <= 0 then
		for _, fighter in damagers do
			if fighter.Parent then
				local legendary = math.random() < Config.Event.legendaryChance
				DropService.grantEvent(fighter, legendary)
				if legendary then
					ToolService.refresh(fighter)
				end
			end
		end
		despawn("killed")
	end
	return true
end

function WorldEventService.start()
	ToolService.setEventDamager(onDamage)
	Players.PlayerAdded:Connect(function(player)
		if active then
			Remotes.get("EventState"):FireClient(player, {
				kind = "sync",
				hp = hp,
				maxHp = maxHp,
				endsAt = endsAt,
				active = true,
			})
		end
	end)
	task.spawn(function()
		task.wait(Config.Event.firstDelay)
		while true do
			spawnBoss()
			while active do
				task.wait(1)
			end
			task.wait(Config.Event.interval)
		end
	end)
end

return WorldEventService
