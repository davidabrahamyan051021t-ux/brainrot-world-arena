local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	"RequestHit",
	"HitConfirmed",
	"EntityShout",
	"DataUpdated",
	"EventState",
	"BuyPerk",
	"UnlockTool",
	"EquipTool",
	"RequestData",
}

local Remotes = {}

local function getFolder(): Folder
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if folder and folder:IsA("Folder") then
		return folder
	end
	if RunService:IsServer() then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
		return folder
	end
	return ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

local function ensureRemote(folder: Folder, name: string): RemoteEvent | RemoteFunction
	local existing = folder:FindFirstChild(name)
	if existing then
		return existing :: any
	end
	if not RunService:IsServer() then
		return folder:WaitForChild(name) :: any
	end
	local className = (name == "BuyPerk" or name == "UnlockTool" or name == "EquipTool") and "RemoteFunction"
		or "RemoteEvent"
	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = folder
	return remote
end

function Remotes.get(name: string): any
	return ensureRemote(getFolder(), name)
end

function Remotes.initServer()
	local folder = getFolder()
	for _, name in NAMES do
		ensureRemote(folder, name)
	end
end

return Remotes
