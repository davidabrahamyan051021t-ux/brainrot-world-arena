local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local Theme = require(game.ReplicatedStorage.Shared.Theme)

local HUD = {}

local player = Players.LocalPlayer
local data = nil
local eventState = nil
local shopOpen = false

local function tween(instance: Instance, info: TweenInfo, props): Tween
	local t = TweenService:Create(instance, info, props)
	t:Play()
	return t
end

function HUD.start()
	local playerGui = player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 5
	gui.Parent = playerGui

	-- A fixed 1280x720 design canvas keeps every panel aligned on any screen.
	local canvas = Instance.new("Frame")
	canvas.Name = "Canvas"
	canvas.AnchorPoint = Vector2.new(0.5, 0.5)
	canvas.Position = UDim2.fromScale(0.5, 0.5)
	canvas.Size = UDim2.fromOffset(1280, 720)
	canvas.BackgroundTransparency = 1
	canvas.Parent = gui

	local uiScale = Instance.new("UIScale")
	uiScale.Parent = canvas

	local function applyScale()
		local camera = Workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
		uiScale.Scale = Theme.scaleFor(viewport)
	end
	applyScale()

	local function makePanel(parent: Instance, name: string, position: UDim2, size: UDim2, radius: number?): Frame
		local f = Instance.new("Frame")
		f.Name = name
		f.Position = position
		f.Size = size
		f.BackgroundColor3 = Color3.new(1, 1, 1)
		f.BackgroundTransparency = 0.04
		f.BorderSizePixel = 0
		f.Parent = parent
		Theme.corner(f, radius or 14)
		Theme.gradient(f, Theme.Color.panelRaised, Theme.Color.panel, 90)
		Theme.stroke(f, Theme.Color.stroke, 1, 0.45)
		Theme.shadow(f, 0.62)
		return f
	end

	local function makeText(
		parent: Instance,
		name: string,
		text: string,
		position: UDim2,
		size: UDim2,
		font: Enum.Font,
		textSize: number,
		color: Color3
	): TextLabel
		local label = Instance.new("TextLabel")
		label.Name = name
		label.BackgroundTransparency = 1
		label.Position = position
		label.Size = size
		label.Font = font
		label.TextSize = textSize
		label.TextColor3 = color
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Text = text
		label.RichText = true
		label.Parent = parent
		return label
	end

	local function makePill(parent: Instance, name: string, position: UDim2, size: UDim2, color: Color3): (Frame, TextLabel)
		local pill = Instance.new("Frame")
		pill.Name = name
		pill.Position = position
		pill.Size = size
		pill.BackgroundColor3 = color
		pill.BackgroundTransparency = 0.85
		pill.BorderSizePixel = 0
		pill.Parent = parent
		Theme.corner(pill, size.Y.Offset / 2)
		Theme.stroke(pill, color, 1, 0.55)
		local label = makeText(pill, "Value", "", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Theme.Font.bold, 12, color)
		label.TextXAlignment = Enum.TextXAlignment.Center
		return pill, label
	end

	-- ------------------------------------------------------------------ toasts

	local toastHolder = Instance.new("Frame")
	toastHolder.Name = "Toasts"
	toastHolder.AnchorPoint = Vector2.new(0.5, 0)
	toastHolder.Position = UDim2.fromOffset(640, 112)
	toastHolder.Size = UDim2.fromOffset(460, 0)
	toastHolder.AutomaticSize = Enum.AutomaticSize.Y
	toastHolder.BackgroundTransparency = 1
	toastHolder.Parent = canvas

	local toastLayout = Instance.new("UIListLayout")
	toastLayout.Padding = UDim.new(0, 6)
	toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
	toastLayout.Parent = toastHolder

	local toastOrder = 0

	local function toast(text: string, color: Color3)
		toastOrder += 1
		local item = Instance.new("Frame")
		item.Name = "Toast"
		item.Size = UDim2.fromOffset(420, 38)
		item.BackgroundColor3 = Color3.new(1, 1, 1)
		item.BackgroundTransparency = 0.08
		item.LayoutOrder = toastOrder
		item.Parent = toastHolder
		Theme.corner(item, 10)
		Theme.gradient(item, Theme.Color.panelRaised, Theme.Color.panel, 90)
		Theme.stroke(item, color, 1, 0.35)

		local stripe = Instance.new("Frame")
		stripe.Size = UDim2.new(0, 3, 1, -12)
		stripe.Position = UDim2.fromOffset(8, 6)
		stripe.BackgroundColor3 = color
		stripe.BorderSizePixel = 0
		stripe.Parent = item
		Theme.corner(stripe, 2)

		local label = makeText(item, "Text", text, UDim2.fromOffset(20, 0), UDim2.new(1, -32, 1, 0), Theme.Font.bold, 13, Theme.Color.text)
		label.TextXAlignment = Enum.TextXAlignment.Center

		task.delay(2.2, function()
			local fade = TweenService:Create(item, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
			fade:Play()
			TweenService:Create(label, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
			stripe.Visible = false
			fade.Completed:Once(function()
				item:Destroy()
			end)
		end)

		-- keep the stack short
		local count = 0
		for _, child in toastHolder:GetChildren() do
			if child:IsA("Frame") then
				count += 1
			end
		end
		if count > 3 then
			local oldest = nil
			for _, child in toastHolder:GetChildren() do
				if child:IsA("Frame") and (not oldest or child.LayoutOrder < oldest.LayoutOrder) then
					oldest = child
				end
			end
			if oldest then
				oldest:Destroy()
			end
		end
	end

	-- ------------------------------------------------------------- stats panel

	local statsPanel = makePanel(canvas, "Stats", UDim2.fromOffset(22, 18), UDim2.fromOffset(318, 82), 15)

	local coinDot = Instance.new("Frame")
	coinDot.Name = "CoinDot"
	coinDot.Position = UDim2.fromOffset(16, 14)
	coinDot.Size = UDim2.fromOffset(28, 28)
	coinDot.BackgroundColor3 = Color3.new(1, 1, 1)
	coinDot.BorderSizePixel = 0
	coinDot.Parent = statsPanel
	Theme.corner(coinDot, 14)
	Theme.gradient(coinDot, Theme.Color.gold, Theme.Color.goldDeep, 90)
	Theme.stroke(coinDot, Theme.Color.gold, 1, 0.2)

	local coinDotCore = Instance.new("Frame")
	coinDotCore.AnchorPoint = Vector2.new(0.5, 0.5)
	coinDotCore.Position = UDim2.fromScale(0.5, 0.5)
	coinDotCore.Size = UDim2.fromOffset(12, 12)
	coinDotCore.BackgroundColor3 = Theme.Color.goldDeep
	coinDotCore.BackgroundTransparency = 0.15
	coinDotCore.BorderSizePixel = 0
	coinDotCore.Parent = coinDot
	Theme.corner(coinDotCore, 6)

	local coinsValue = makeText(statsPanel, "Coins", "0", UDim2.fromOffset(52, 8), UDim2.fromOffset(168, 30), Theme.Font.display, 21, Theme.Color.text)
	local coinGain = makeText(statsPanel, "Gain", "", UDim2.fromOffset(52, 36), UDim2.fromOffset(120, 14), Theme.Font.bold, 12, Theme.Color.gold)
	coinGain.TextTransparency = 1

	local levelPill, levelText = makePill(statsPanel, "LevelPill", UDim2.fromOffset(226, 12), UDim2.fromOffset(78, 26), Theme.Color.violet)
	levelText.Text = "LV 1"
	levelText.TextSize = 13
	levelText.Font = Theme.Font.display

	local xpBack = Instance.new("Frame")
	xpBack.Name = "XPBack"
	xpBack.Position = UDim2.fromOffset(14, 54)
	xpBack.Size = UDim2.new(1, -28, 0, 15)
	xpBack.BackgroundColor3 = Theme.Color.shadow
	xpBack.BackgroundTransparency = 0.35
	xpBack.BorderSizePixel = 0
	xpBack.Parent = statsPanel
	Theme.corner(xpBack, 8)

	local xpFill = Instance.new("Frame")
	xpFill.Name = "XPFill"
	xpFill.Size = UDim2.fromScale(0, 1)
	xpFill.BackgroundColor3 = Color3.new(1, 1, 1)
	xpFill.BorderSizePixel = 0
	xpFill.Parent = xpBack
	Theme.corner(xpFill, 8)
	Theme.gradient(xpFill, Theme.Color.xp, Theme.Color.violet, 0)

	local xpLabel = makeText(xpBack, "XPText", "0 / 50 XP", UDim2.new(), UDim2.fromScale(1, 1), Theme.Font.bold, 10, Color3.new(1, 1, 1))
	xpLabel.TextXAlignment = Enum.TextXAlignment.Center
	xpLabel.TextStrokeTransparency = 0.55

	-- -------------------------------------------------------------- boss bar

	local bossPanel = makePanel(canvas, "Boss", UDim2.new(0.5, 0, 0, 18), UDim2.fromOffset(480, 76), 15)
	bossPanel.AnchorPoint = Vector2.new(0.5, 0)
	bossPanel.Visible = false

	makeText(bossPanel, "Name", "GIGANTIC BRAINROT", UDim2.fromOffset(18, 8), UDim2.fromOffset(280, 20), Theme.Font.display, 15, Theme.Color.danger)
	local bossTier = makeText(bossPanel, "Tier", "WORLD EVENT", UDim2.new(1, -110, 0, 10), UDim2.fromOffset(92, 16), Theme.Font.bold, 9, Theme.Color.warn)
	bossTier.TextXAlignment = Enum.TextXAlignment.Right

	local bossHpText = makeText(bossPanel, "HP", "", UDim2.fromOffset(18, 52), UDim2.fromOffset(240, 16), Theme.Font.bold, 10, Theme.Color.textDim)

	local timerPill, timerText = makePill(bossPanel, "TimerPill", UDim2.new(1, -18, 0, 48), UDim2.fromOffset(84, 22), Theme.Color.gold)
	timerPill.AnchorPoint = Vector2.new(1, 0)
	timerText.Text = "1:30"
	timerText.TextSize = 11

	local bossBarBack = Instance.new("Frame")
	bossBarBack.Name = "Bar"
	bossBarBack.Position = UDim2.fromOffset(18, 32)
	bossBarBack.Size = UDim2.new(1, -36, 0, 16)
	bossBarBack.BackgroundColor3 = Theme.Color.shadow
	bossBarBack.BackgroundTransparency = 0.3
	bossBarBack.BorderSizePixel = 0
	bossBarBack.Parent = bossPanel
	Theme.corner(bossBarBack, 9)
	Theme.stroke(bossBarBack, Theme.Color.danger, 1, 0.6)

	local bossFill = Instance.new("Frame")
	bossFill.Name = "Fill"
	bossFill.Size = UDim2.fromScale(1, 1)
	bossFill.BackgroundColor3 = Color3.new(1, 1, 1)
	bossFill.BorderSizePixel = 0
	bossFill.Parent = bossBarBack
	Theme.corner(bossFill, 9)
	Theme.gradient(bossFill, Theme.Color.danger, Theme.Color.accent, 0)

	-- ------------------------------------------------------------ equipped tool

	local toolPanel = makePanel(canvas, "Tool", UDim2.fromOffset(22, 634), UDim2.fromOffset(300, 62), 14)

	local toolIcon = Instance.new("Frame")
	toolIcon.Name = "ToolIcon"
	toolIcon.Position = UDim2.fromOffset(12, 12)
	toolIcon.Size = UDim2.fromOffset(38, 38)
	toolIcon.BackgroundColor3 = Color3.new(1, 1, 1)
	toolIcon.BorderSizePixel = 0
	toolIcon.Parent = toolPanel
	Theme.corner(toolIcon, 11)
	Theme.stroke(toolIcon, Theme.Color.stroke, 1, 0.4)

	local toolGradient = Theme.gradient(toolIcon, Theme.Color.accent, Theme.Color.panel, 90)

	local toolIconCore = Instance.new("Frame")
	toolIconCore.AnchorPoint = Vector2.new(0.5, 0.5)
	toolIconCore.Position = UDim2.fromScale(0.5, 0.5)
	toolIconCore.Size = UDim2.fromOffset(14, 14)
	toolIconCore.BackgroundColor3 = Color3.new(1, 1, 1)
	toolIconCore.BorderSizePixel = 0
	toolIconCore.Parent = toolIcon
	Theme.corner(toolIconCore, 4)

	local toolName = makeText(toolPanel, "ToolName", "Chaotic Smasher", UDim2.fromOffset(60, 10), UDim2.fromOffset(190, 20), Theme.Font.bold, 14, Theme.Color.text)
	local toolInfo = makeText(toolPanel, "ToolInfo", "LEFT CLICK · 18 DMG", UDim2.fromOffset(60, 30), UDim2.fromOffset(190, 16), Theme.Font.medium, 9, Theme.Color.textDim)
	local toolTag = makeText(toolPanel, "ToolTag", "EQUIPPED", UDim2.new(1, -78, 0, 10), UDim2.fromOffset(66, 16), Theme.Font.bold, 8, Theme.Color.good)
	toolTag.TextXAlignment = Enum.TextXAlignment.Right

	-- ------------------------------------------------------------- shop button

	local shopButton = Instance.new("TextButton")
	shopButton.Name = "ShopButton"
	shopButton.Position = UDim2.fromOffset(1088, 644)
	shopButton.Size = UDim2.fromOffset(170, 52)
	shopButton.BackgroundColor3 = Color3.new(1, 1, 1)
	shopButton.AutoButtonColor = false
	shopButton.Text = ""
	shopButton.Parent = canvas
	Theme.corner(shopButton, 13)
	Theme.gradient(shopButton, Theme.Color.accent, Theme.Color.accentDeep, 90)
	Theme.stroke(shopButton, Color3.new(1, 1, 1), 1, 0.7)
	Theme.shadow(shopButton, 0.55)

	local shopLabel = makeText(shopButton, "Label", "SHOP", UDim2.fromOffset(20, 0), UDim2.fromOffset(100, 52), Theme.Font.display, 18, Color3.new(1, 1, 1))
	local keyChip = Instance.new("Frame")
	keyChip.AnchorPoint = Vector2.new(1, 0.5)
	keyChip.Position = UDim2.new(1, -14, 0.5, 0)
	keyChip.Size = UDim2.fromOffset(26, 26)
	keyChip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	keyChip.BackgroundTransparency = 0.82
	keyChip.BorderSizePixel = 0
	keyChip.Parent = shopButton
	Theme.corner(keyChip, 7)
	local keyLabel = makeText(keyChip, "Key", "B", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Theme.Font.display, 13, Color3.new(1, 1, 1))
	keyLabel.TextXAlignment = Enum.TextXAlignment.Center

	-- -------------------------------------------------------------- shop panel

	local shop = makePanel(canvas, "Shop", UDim2.fromOffset(852, 176), UDim2.fromOffset(404, 456), 16)
	shop.Visible = false
	shop.ClipsDescendants = true

	makeText(shop, "Title", "PERKS & GEAR", UDim2.fromOffset(18, 14), UDim2.fromOffset(220, 24), Theme.Font.display, 18, Theme.Color.text)
	makeText(shop, "Subtitle", "Spend coins. Get louder.", UDim2.fromOffset(18, 38), UDim2.fromOffset(240, 16), Theme.Font.medium, 11, Theme.Color.textDim)

	local balancePill = Instance.new("Frame")
	balancePill.AnchorPoint = Vector2.new(1, 0)
	balancePill.Position = UDim2.new(1, -46, 0, 16)
	balancePill.Size = UDim2.fromOffset(94, 26)
	balancePill.BackgroundColor3 = Theme.Color.gold
	balancePill.BackgroundTransparency = 0.86
	balancePill.BorderSizePixel = 0
	balancePill.Parent = shop
	Theme.corner(balancePill, 8)
	Theme.stroke(balancePill, Theme.Color.gold, 1, 0.55)

	local balanceDot = Instance.new("Frame")
	balanceDot.Position = UDim2.fromOffset(8, 8)
	balanceDot.Size = UDim2.fromOffset(10, 10)
	balanceDot.BackgroundColor3 = Theme.Color.gold
	balanceDot.BorderSizePixel = 0
	balanceDot.Parent = balancePill
	Theme.corner(balanceDot, 5)

	local balanceText = makeText(balancePill, "Balance", "0", UDim2.fromOffset(24, 0), UDim2.new(1, -28, 1, 0), Theme.Font.bold, 12, Theme.Color.gold)
	balanceText.TextXAlignment = Enum.TextXAlignment.Left

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "Close"
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.new(1, -14, 0, 14)
	closeButton.Size = UDim2.fromOffset(26, 26)
	closeButton.BackgroundColor3 = Color3.new(1, 1, 1)
	closeButton.BackgroundTransparency = 0.9
	closeButton.Text = "×"
	closeButton.Font = Theme.Font.bold
	closeButton.TextSize = 18
	closeButton.TextColor3 = Theme.Color.textDim
	closeButton.AutoButtonColor = false
	closeButton.Parent = shop
	Theme.corner(closeButton, 8)

	local divider = Instance.new("Frame")
	divider.Position = UDim2.fromOffset(18, 66)
	divider.Size = UDim2.new(1, -36, 0, 1)
	divider.BackgroundColor3 = Theme.Color.strokeSoft
	divider.BackgroundTransparency = 0.3
	divider.BorderSizePixel = 0
	divider.Parent = shop

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "List"
	scroll.Position = UDim2.fromOffset(12, 76)
	scroll.Size = UDim2.fromOffset(380, 368)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = Theme.Color.stroke
	scroll.ScrollBarImageTransparency = 0.2
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = shop

	local scrollLayout = Instance.new("UIListLayout")
	scrollLayout.Padding = UDim.new(0, 8)
	scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
	scrollLayout.Parent = scroll

	local function sectionHeader(text: string, order: number)
		local header = makeText(scroll, "Section" .. order, text, UDim2.new(), UDim2.new(1, -6, 0, 16), Theme.Font.bold, 9, Theme.Color.textFaint)
		header.LayoutOrder = order
		return header
	end

	local function makeCard(order: number, accent: Color3)
		local card = Instance.new("TextButton")
		card.Name = "Card"
		card.Size = UDim2.new(1, -6, 0, 64)
		card.BackgroundColor3 = Color3.new(1, 1, 1)
		card.BackgroundTransparency = 0.16
		card.AutoButtonColor = false
		card.Text = ""
		card.LayoutOrder = order
		card.Parent = scroll
		Theme.corner(card, 10)
		Theme.gradient(card, Theme.Color.panelRaised, Theme.Color.panel, 90)
		local stroke = Theme.stroke(card, Theme.Color.strokeSoft, 1, 0.5)

		local stripe = Instance.new("Frame")
		stripe.Size = UDim2.new(0, 3, 1, -16)
		stripe.Position = UDim2.fromOffset(0, 8)
		stripe.BackgroundColor3 = accent
		stripe.BorderSizePixel = 0
		stripe.Parent = card
		Theme.corner(stripe, 2)

		local icon = Instance.new("Frame")
		icon.Position = UDim2.fromOffset(13, 15)
		icon.Size = UDim2.fromOffset(34, 34)
		icon.BackgroundColor3 = Color3.new(1, 1, 1)
		icon.BorderSizePixel = 0
		icon.Parent = card
		Theme.corner(icon, 10)
		Theme.gradient(icon, accent, Theme.Color.panel, 90)
		Theme.stroke(icon, accent, 1, 0.4)

		local title = makeText(card, "Title", "", UDim2.fromOffset(58, 11), UDim2.new(1, -170, 0, 18), Theme.Font.bold, 14, Theme.Color.text)
		local meta = makeText(card, "Meta", "", UDim2.fromOffset(58, 31), UDim2.new(1, -170, 0, 16), Theme.Font.medium, 10, Theme.Color.textDim)
		meta.TextTruncate = Enum.TextTruncate.AtEnd

		local pill = Instance.new("Frame")
		pill.AnchorPoint = Vector2.new(1, 0.5)
		pill.Position = UDim2.new(1, -12, 0.5, 0)
		pill.Size = UDim2.fromOffset(88, 28)
		pill.BackgroundColor3 = Theme.Color.panelRaised
		pill.BackgroundTransparency = 0.1
		pill.BorderSizePixel = 0
		pill.Parent = card
		Theme.corner(pill, 8)

		local pillText = makeText(pill, "Value", "", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Theme.Font.bold, 11, Theme.Color.text)
		pillText.TextXAlignment = Enum.TextXAlignment.Center

		card.MouseEnter:Connect(function()
			tween(card, TweenInfo.new(0.12), { BackgroundTransparency = 0.02 })
			stroke.Color = accent
			stroke.Transparency = 0.35
		end)
		card.MouseLeave:Connect(function()
			tween(card, TweenInfo.new(0.15), { BackgroundTransparency = 0.16 })
			stroke.Color = Theme.Color.strokeSoft
			stroke.Transparency = 0.5
		end)

		return { button = card, title = title, meta = meta, pill = pill, pillText = pillText, stroke = stroke, accent = stripe }
	end

	local function setCard(
		card,
		title: string,
		meta: string,
		pillText: string,
		pillColor: Color3,
		affordable: boolean
	)
		card.title.Text = title
		card.meta.Text = meta
		card.pillText.Text = pillText
		card.pillText.TextColor3 = pillColor
		card.pill.BackgroundColor3 = pillColor
		card.pill.BackgroundTransparency = affordable and 0.78 or 0.92
		card.title.TextColor3 = affordable and Theme.Color.text or Theme.Color.textDim
	end

	-- sections + rows
	sectionHeader("PERKS", 1)

	local perkRows = {}
	local perkOrder = 2
	local perkAccents = {
		MoveSpeed = Theme.Color.accentAlt,
		CritChance = Theme.Color.gold,
		MaxHealth = Theme.Color.good,
	}
	local perkBlurbs = {
		MoveSpeed = "+%d walk speed",
		CritChance = "+%d%% critical chance",
		MaxHealth = "+%d max health",
	}
	for _, perkId in { "MoveSpeed", "CritChance", "MaxHealth" } do
		local card = makeCard(perkOrder, perkAccents[perkId])
		perkRows[perkId] = card
		card.button.MouseButton1Click:Connect(function()
			if not data then
				return
			end
			local ok, err = Remotes.get("BuyPerk"):InvokeServer(perkId)
			if not ok then
				toast(err or "Can't buy that", Theme.Color.danger)
			end
		end)
		perkOrder += 1
	end

	sectionHeader("GEAR", 10)

	local toolOrder = 11
	local toolAccents = {
		Chaotic = Color3.fromRGB(255, 90, 40),
		Laser = Color3.fromRGB(80, 220, 255),
		Sonic = Color3.fromRGB(255, 70, 200),
	}
	local toolRows = {}
	for _, toolId in { "Chaotic", "Laser", "Sonic" } do
		local card = makeCard(toolOrder, toolAccents[toolId])
		toolRows[toolId] = card
		card.button.MouseButton1Click:Connect(function()
			if not data then
				return
			end
			if data.unlockedTools[toolId] then
				local ok, err = Remotes.get("EquipTool"):InvokeServer(toolId)
				if not ok then
					toast(err or "Can't equip that", Theme.Color.danger)
				end
			else
				local ok, err = Remotes.get("UnlockTool"):InvokeServer(toolId)
				if not ok then
					toast(err or "Can't unlock that", Theme.Color.danger)
				end
			end
		end)
		toolOrder += 1
	end

	-- -------------------------------------------------------------- refreshers

	local xpTween: Tween? = nil
	local coinGainTween: Tween? = nil
	local function showCoinGain(amount: number)
		if amount <= 0 then
			return
		end
		coinGain.Text = "+" .. Theme.formatNumber(amount)
		coinGain.Position = UDim2.fromOffset(52, 40)
		coinGain.TextTransparency = 0
		if coinGainTween then
			coinGainTween:Cancel()
		end
		coinGainTween = tween(coinGain, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 1,
			Position = UDim2.fromOffset(52, 24),
		})
		local dotScale = coinDot:FindFirstChildOfClass("UIScale")
		if not dotScale then
			dotScale = Instance.new("UIScale")
			dotScale.Parent = coinDot
		end
		dotScale.Scale = 1.25
		tween(dotScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
	end

	local function refreshTool()
		if not data then
			return
		end
		local def = Config.Tools[data.equippedTool] or Config.Tools.Chaotic
		toolName.Text = def.displayName
		toolInfo.Text = string.format("LEFT CLICK · %d DMG · %d RNG", def.damage, def.range)
		toolGradient.Color = ColorSequence.new(def.color, def.accent or def.color)
		toolIconCore.BackgroundColor3 = def.accent or def.color
		toolTag.Text = def.legendary and "LEGENDARY" or (def.starter and "STARTER" or "UNLOCKED")
		toolTag.TextColor3 = def.color
	end

	local function refreshShop()
		if not data then
			return
		end
		balanceText.Text = Theme.formatNumber(data.coins)

		for perkId, card in perkRows do
			local perk = Config.Perks[perkId]
			local level = data.perks[perkId] or 0
			local maxed = level >= perk.maxLevel
			local affordable = data.coins >= perk.costCoins
			local bonus = math.floor(perk.perLevel * level * (perkId == "CritChance" and 100 or 1))
			local meta = string.format("Lv %d/%d · %s", level, perk.maxLevel, string.format(perkBlurbs[perkId], bonus))
			local pill = maxed and "MAXED" or Theme.formatNumber(perk.costCoins)
			local color = maxed and Theme.Color.good or (affordable and Theme.Color.gold or Theme.Color.textFaint)
			setCard(card, perk.displayName, meta, pill, color, (not maxed) and affordable)
		end

		for toolId, card in toolRows do
			local def = Config.Tools[toolId]
			local unlocked = data.unlockedTools[toolId] == true
			local equipped = data.equippedTool == toolId
			local title = def.displayName
			local meta = string.format("%d DMG · %d RNG", def.damage, def.range)
			local pill, color, affordable

			if unlocked then
				if equipped then
					pill, color, affordable = "EQUIPPED", Theme.Color.good, true
					meta = meta .. "  ·  IN HAND"
				else
					pill, color, affordable = "EQUIP", Theme.Color.accentAlt, true
				end
			elseif toolId == "Sonic" then
				pill, color, affordable = "BOSS DROP", Theme.Color.textFaint, false
				meta = "Defeat the Gigantic Brainrot"
			elseif toolId == "Laser" then
				local levelOk = data.level >= (def.unlockLevel or 1)
				local coinOk = data.coins >= (def.unlockCoins or 0)
				pill = "UNLOCK"
				color = (levelOk and coinOk) and Theme.Color.gold or Theme.Color.textFaint
				affordable = levelOk and coinOk
				meta = string.format("Lv %d + %s coins · %d DMG", def.unlockLevel or 1, Theme.formatNumber(def.unlockCoins or 0), def.damage)
			else
				pill, color, affordable = "LOCKED", Theme.Color.textFaint, false
			end

			setCard(card, title, meta, pill, color, affordable)
		end
	end

	local function refreshStats(instant: boolean?)
		if not data then
			return
		end
		coinsValue.Text = Theme.formatNumber(data.coins)
		levelText.Text = "LV " .. data.level
		local need = data.xpToNext or Config.xpToNext(data.level)
		xpLabel.Text = string.format("%s / %s XP", Theme.formatNumber(data.xp), Theme.formatNumber(need))
		local fraction = math.clamp(data.xp / math.max(need, 1), 0, 1)
		if instant then
			xpFill.Size = UDim2.fromScale(fraction, 1)
		else
			if xpTween then
				xpTween:Cancel()
			end
			xpTween = tween(xpFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.fromScale(fraction, 1),
			})
		end
		refreshTool()
		refreshShop()
	end

	local function updateBoss()
		local state = eventState
		if not state or not state.active then
			return
		end
		local fraction = math.clamp((state.hp or 0) / math.max(state.maxHp or 1, 1), 0, 1)
		bossFill.Size = UDim2.fromScale(fraction, 1)
		bossHpText.Text = string.format("%s / %s", Theme.formatNumber(state.hp or 0), Theme.formatNumber(state.maxHp or 0))
		local left = math.max(0, math.floor((state.endsAt or 0) - workspace:GetServerTimeNow()))
		timerText.Text = string.format("%d:%02d", math.floor(left / 60), left % 60)
		timerText.TextColor3 = left <= 15 and Theme.Color.danger or Theme.Color.gold
	end

	local function setBossVisible(visible: boolean)
		if bossPanel.Visible == visible then
			return
		end
		if visible then
			bossPanel.Visible = true
			bossPanel.Position = UDim2.new(0.5, 0, 0, 4)
			tween(bossPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, 0, 0, 18),
			})
		else
			local t = tween(bossPanel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, 0, 4),
			})
			t.Completed:Once(function()
				bossPanel.Visible = false
			end)
		end
	end

	local function setShopOpen(open: boolean)
		shopOpen = open
		if open then
			refreshShop()
			shop.Visible = true
			shop.Position = UDim2.fromOffset(852, 190)
			tween(shop, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.fromOffset(852, 176),
			})
			shopLabel.Text = "CLOSE"
		else
			shop.Visible = false
			shopLabel.Text = "SHOP"
		end
	end

	-- ---------------------------------------------------------------- wiring

	shopButton.MouseButton1Click:Connect(function()
		setShopOpen(not shopOpen)
	end)
	closeButton.MouseButton1Click:Connect(function()
		setShopOpen(false)
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.B then
			setShopOpen(not shopOpen)
		end
	end)

	Remotes.get("DataUpdated").OnClientEvent:Connect(function(snapshot)
		local previous = data
		data = snapshot
		refreshStats(previous == nil)
		if previous then
			if snapshot.coins > previous.coins then
				showCoinGain(snapshot.coins - previous.coins)
			end
			if snapshot.level > previous.level then
				toast(string.format("LEVEL UP  ·  LV %d", snapshot.level), Theme.Color.gold)
			end
			if snapshot.unlockedTools.Laser and not previous.unlockedTools.Laser then
				toast("BRAINROT LASER UNLOCKED", Theme.Color.accentAlt)
			end
			if snapshot.unlockedTools.Sonic and not previous.unlockedTools.Sonic then
				toast("SONIC WAVE UNLOCKED  ·  EQUIP IT IN SHOP", Theme.Color.accent)
			end
		end
	end)

	Remotes.get("EventState").OnClientEvent:Connect(function(state)
		eventState = state
		if not state or not state.active then
			setBossVisible(false)
			if state and state.kind == "killed" then
				toast("GIGANTIC BRAINROT DEFEATED", Theme.Color.good)
			elseif state and state.kind == "timeout" then
				toast("THE GIGANTIC ESCAPED", Theme.Color.warn)
			end
			return
		end
		setBossVisible(true)
		updateBoss()
		if state.kind == "spawn" then
			toast("GIGANTIC BRAINROT HAS AWAKENED", Theme.Color.danger)
		end
	end)

	-- Ask for a data snapshot in case the initial push landed before this script ran.
	task.spawn(function()
		for _ = 1, 4 do
			if data then
				return
			end
			Remotes.get("RequestData"):FireServer()
			task.wait(1)
		end
	end)

	task.spawn(function()
		local scaleTimer = 0
		while gui.Parent do
			local dt = task.wait(0.25)
			scaleTimer += dt
			if scaleTimer >= 2 then
				scaleTimer = 0
				applyScale()
			end
			if eventState and eventState.active then
				updateBoss()
			end
		end
	end)
end

return HUD
