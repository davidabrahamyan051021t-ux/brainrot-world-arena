local CollectionService = game:GetService("CollectionService")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local DropService = require(script.Parent.DropService)
local EntityFactory = require(script.Parent.EntityFactory)

local HarvestService = {}

type EntityState = {
	model: Model,
	alive: boolean,
	hp: number,
	maxHp: number,
	entityType: string,
	origin: CFrame,
	lastShout: number,
	respawn: number,
}

local states: { [Model]: EntityState } = {}

local function rootOf(model: Model): BasePart?
	return model.PrimaryPart or model:FindFirstChild("Root") :: BasePart?
end

local function setVisualAlive(model: Model, alive: boolean)
	EntityFactory.setAlive(model, alive)
end

local function updateHpLabel(state: EntityState)
	state.model:SetAttribute("HP", state.hp)
	EntityFactory.updateHealthBar(state.model, state.hp, state.maxHp)
end

function HarvestService.register(model: Model)
	if states[model] then
		return
	end
	local entityType = model:GetAttribute("EntityType") or "Small"
	local def = Config.Entities[entityType] or Config.Entities.Small
	local maxHp = model:GetAttribute("MaxHP") or def.hp
	local root = rootOf(model)
	local state: EntityState = {
		model = model,
		alive = true,
		hp = model:GetAttribute("HP") or maxHp,
		maxHp = maxHp,
		entityType = entityType,
		origin = root and root.CFrame or CFrame.new(),
		lastShout = 0,
		respawn = def.respawn,
	}
	states[model] = state
	model:SetAttribute("Alive", true)
	updateHpLabel(state)
end

function HarvestService.unregister(model: Model)
	states[model] = nil
end

function HarvestService.get(model: Model): EntityState?
	return states[model]
end

function HarvestService.damage(player: Player, model: Model, amount: number, isCrit: boolean): boolean
	local state = states[model]
	if not state or not state.alive then
		return false
	end
	state.hp -= amount
	updateHpLabel(state)
	local now = os.clock()
	if now - state.lastShout >= Config.ShoutCooldown then
		state.lastShout = now
		local def = Config.Entities[state.entityType]
		local shout = def and def.shout or "BRAINROT!"
		Remotes.get("EntityShout"):FireAllClients(model, shout)
	end
	Remotes.get("HitConfirmed"):FireClient(player, model, amount, isCrit, state.hp, state.maxHp)
	if state.hp <= 0 then
		state.alive = false
		state.hp = 0
		setVisualAlive(model, false)
		DropService.grantKill(player, state.entityType)
		task.delay(state.respawn, function()
			if not model.Parent then
				return
			end
			state.alive = true
			state.hp = state.maxHp
			local root = rootOf(model)
			if root then
				root.CFrame = state.origin
			end
			setVisualAlive(model, true)
			updateHpLabel(state)
		end)
	end
	return true
end

function HarvestService.start()
	for _, model in CollectionService:GetTagged(Config.TAG_HARVESTABLE) do
		if model:IsA("Model") then
			HarvestService.register(model)
		end
	end
	CollectionService:GetInstanceAddedSignal(Config.TAG_HARVESTABLE):Connect(function(inst)
		if inst:IsA("Model") then
			HarvestService.register(inst)
		end
	end)
	CollectionService:GetInstanceRemovedSignal(Config.TAG_HARVESTABLE):Connect(function(inst)
		if inst:IsA("Model") then
			HarvestService.unregister(inst)
		end
	end)
end

return HarvestService
