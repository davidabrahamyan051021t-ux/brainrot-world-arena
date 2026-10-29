local Config = require(game.ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

local ProgressionService = {}

function ProgressionService.addCoins(player: Player, amount: number)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	data.coins += math.max(0, math.floor(amount))
end

function ProgressionService.addXP(player: Player, amount: number)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	data.xp += math.max(0, math.floor(amount))
	while data.xp >= Config.xpToNext(data.level) do
		data.xp -= Config.xpToNext(data.level)
		data.level += 1
	end
end

function ProgressionService.unlockTool(player: Player, toolId: string, free: boolean?): (boolean, string?)
	local data = PlayerData.get(player)
	local tool = Config.Tools[toolId]
	if not data or not tool then
		return false, "Unknown tool"
	end
	if data.unlockedTools[toolId] then
		return false, "Already unlocked"
	end
	if not free then
		if tool.unlockLevel and data.level < tool.unlockLevel then
			return false, "Need level " .. tool.unlockLevel
		end
		if tool.unlockCoins and data.coins < tool.unlockCoins then
			return false, "Need " .. tool.unlockCoins .. " coins"
		end
		if tool.unlockCoins then
			data.coins -= tool.unlockCoins
		end
	end
	data.unlockedTools[toolId] = true
	data.equippedTool = toolId
	PlayerData.replicate(player)
	return true, nil
end

function ProgressionService.buyPerk(player: Player, perkId: string): (boolean, string?)
	local data = PlayerData.get(player)
	local perk = Config.Perks[perkId]
	if not data or not perk then
		return false, "Unknown perk"
	end
	local current = data.perks[perkId] or 0
	if current >= perk.maxLevel then
		return false, "Maxed"
	end
	if data.coins < perk.costCoins then
		return false, "Need " .. perk.costCoins .. " coins"
	end
	data.coins -= perk.costCoins
	data.perks[perkId] = current + 1
	PlayerData.applyStats(player)
	PlayerData.replicate(player)
	return true, nil
end

function ProgressionService.equipTool(player: Player, toolId: string): (boolean, string?)
	local data = PlayerData.get(player)
	if not data then
		return false, "No data"
	end
	if not data.unlockedTools[toolId] then
		return false, "Locked"
	end
	data.equippedTool = toolId
	PlayerData.replicate(player)
	return true, nil
end

function ProgressionService.critChance(player: Player): number
	local data = PlayerData.get(player)
	if not data then
		return 0
	end
	return (data.perks.CritChance or 0) * Config.Perks.CritChance.perLevel
end

return ProgressionService
