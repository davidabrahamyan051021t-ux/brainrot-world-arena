local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
Remotes.initServer()

local PlayerData = require(script.PlayerData)
local WorldBuilder = require(script.WorldBuilder)
local HarvestService = require(script.HarvestService)
local ToolService = require(script.ToolService)
local WorldEventService = require(script.WorldEventService)

PlayerData.start()
WorldBuilder.ensureWorld()
HarvestService.start()
ToolService.start()
WorldEventService.start()

print("[Brainrot World] Main World MVP running")
