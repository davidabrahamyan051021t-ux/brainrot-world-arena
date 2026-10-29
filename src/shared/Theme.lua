-- Shared UI design tokens + tiny helpers so the HUD, shop, damage numbers and
-- entity effects all read as one product. No gameplay logic lives here.

local Theme = {}

Theme.Font = {
	display = Enum.Font.GothamBlack,
	bold = Enum.Font.GothamBold,
	medium = Enum.Font.GothamMedium,
	regular = Enum.Font.Gotham,
	mono = Enum.Font.Code,
}

Theme.Color = {
	backdrop = Color3.fromRGB(13, 9, 21),
	panel = Color3.fromRGB(22, 16, 33),
	panelRaised = Color3.fromRGB(34, 26, 48),
	panelHover = Color3.fromRGB(48, 37, 66),
	stroke = Color3.fromRGB(78, 60, 108),
	strokeSoft = Color3.fromRGB(54, 42, 76),
	text = Color3.fromRGB(246, 240, 255),
	textDim = Color3.fromRGB(176, 164, 202),
	textFaint = Color3.fromRGB(124, 112, 150),
	gold = Color3.fromRGB(255, 206, 84),
	goldDeep = Color3.fromRGB(214, 148, 26),
	accent = Color3.fromRGB(255, 86, 168),
	accentDeep = Color3.fromRGB(198, 44, 128),
	accentAlt = Color3.fromRGB(110, 222, 255),
	good = Color3.fromRGB(122, 240, 158),
	warn = Color3.fromRGB(255, 188, 88),
	danger = Color3.fromRGB(255, 74, 96),
	xp = Color3.fromRGB(255, 104, 196),
	violet = Color3.fromRGB(170, 120, 255),
	shadow = Color3.fromRGB(4, 2, 8),
}

function Theme.corner(gui: GuiObject, radius: number): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = gui
	return c
end

function Theme.stroke(gui: GuiObject, color: Color3?, thickness: number?, transparency: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Color.strokeSoft
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0.35
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = gui
	return s
end

function Theme.padding(gui: GuiObject, px: number, vertical: number?): UIPadding
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, vertical or px)
	p.PaddingBottom = UDim.new(0, vertical or px)
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.Parent = gui
	return p
end

function Theme.gradient(
	gui: GuiObject,
	from: Color3,
	to: Color3,
	rotation: number?
): UIGradient
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(from, to)
	g.Rotation = rotation or 90
	g.Parent = gui
	return g
end

function Theme.shadow(gui: GuiObject, transparency: number?)
	local s = Instance.new("UIStroke")
	s.Color = Theme.Color.shadow
	s.Thickness = 3
	s.Transparency = transparency or 0.72
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = gui
	return s
end

-- 1234567 -> "1,234,567"
function Theme.formatNumber(value: number): string
	local text = tostring(math.max(0, math.floor(value + 0.5)))
	local out = text:reverse():gsub("(%d%d%d)", "%1,")
	out = out:reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return out
end

function Theme.scaleFor(viewport: Vector2): number
	local base = math.min(viewport.X / 1280, viewport.Y / 720)
	return math.clamp(base, 0.48, 1.24)
end

return Theme
