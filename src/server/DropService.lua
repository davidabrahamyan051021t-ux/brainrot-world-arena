local Config = require(game.ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)
local ProgressionService = require(script.Parent.ProgressionService)

local DropService = {}

function DropService.grantKill(player: Player, entityType: string, extras: { [string]: any }?)
	local def = extras or Config.Entities[entityType]
	if not def then
		return
	end
	local coins = Config.rollRange(def.coins)
	local xp = Config.rollRange(def.xp)
	ProgressionService.addCoins(player, coins)
	ProgressionService.addXP(player, xp)
	local chance = def.rareDropChance or 0
	if chance > 0 and math.random() < chance then
		ProgressionService.addCoins(player, math.floor(coins * 0.5))
	end
	PlayerData.replicate(player)
	return coins, xp
end

function DropService.grantEvent(player: Player, wonLegendary: boolean)
	local coins = Config.rollRange(Config.Event.coins)
	local xp = Config.rollRange(Config.Event.xp)
	ProgressionService.addCoins(player, coins)
	ProgressionService.addXP(player, xp)
	if wonLegendary then
		ProgressionService.unlockTool(player, "Sonic", true)
	end
	PlayerData.replicate(player)
	return coins, xp
end

return DropService
