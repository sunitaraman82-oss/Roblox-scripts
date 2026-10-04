--==================================================
-- MOBILE AIMASSIST UI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "AimAssistUI"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- COLORS
--==================================================

local BG = Color3.fromRGB(12, 12, 14)
local PANEL = Color3.fromRGB(18, 18, 21)
local CARD = Color3.fromRGB(27, 27, 31)
local CARD2 = Color3.fromRGB(34, 34, 39)

local ORANGE = Color3.fromRGB(255, 170, 15)
local ORANGE_DARK = Color3.fromRGB(105, 72, 8)

local WHITE = Color3.fromRGB(235, 235, 235)
local GRAY = Color3.fromRGB(145, 145, 150)
local PURPLE = Color3.fromRGB(165, 75, 255)

--==================================================
-- FOV CIRCLE
--==================================================

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOV"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.fromScale(0.5, 0.5)
FOVCircle.Size = UDim2.fromOffset(Settings.FOV * 2, Settings.FOV * 2)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Visible = true
FOVCircle.Parent = Gui

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = FOVCircle

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Thickness = 2
CircleStroke.Color = WHITE
CircleStroke.Parent = FOVCircle

--==================================================
-- MAIN PANEL
--==================================================

local Panel = Instance.new("Frame")
Panel.Name = "MainPanel"
Panel.Size = UDim2.fromOffset(360, 470)
Panel.Position = UDim2.new(0, 18, 0.5, -235)
Panel.BackgroundColor3 = BG
Panel.BorderSizePixel = 0
Panel.Parent = Gui

Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 12)

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Color = Color3.fromRGB(45, 45, 48)
PanelStroke.Thickness = 1
PanelStroke.Parent = Panel

--==================================================
-- TOP BAR
--==================================================

local Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, 58)
Top.BackgroundColor3 = PANEL
Top.BorderSizePixel = 0
Top.Parent = Panel

local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.fromOffset(45, 50)
Logo.Position = UDim2.fromOffset(10, 4)
Logo.BackgroundTransparency = 1
Logo.Text = "L"
Logo.TextColor3 = ORANGE
Logo.Font = Enum.Font.GothamBold
Logo.TextSize = 34
Logo.Parent = Top

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -110, 0, 28)
Title.Position = UDim2.fromOffset(58, 7)
Title.BackgroundTransparency = 1
Title.Text = "AimAssist"
Title.TextColor3 = ORANGE
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Top

local Version = Instance.new("TextLabel")
Version.Size = UDim2.new(1, -110, 0, 20)
Version.Position = UDim2.fromOffset(58, 29)
Version.BackgroundTransparency = 1
Version.Text = "Mobile Edition"
Version.TextColor3 = GRAY
Version.Font = Enum.Font.Gotham
Version.TextSize = 10
Version.TextXAlignment = Enum.TextXAlignment.Left
Version.Parent = Top

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(35, 35)
Close.Position = UDim2.new(1, -45, 0, 11)
Close.BackgroundColor3 = CARD2
Close.Text = "×"
Close.TextColor3 = WHITE
Close.TextSize = 23
Close.Font = Enum.Font.GothamBold
Close.Parent = Top

Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 8)

--==================================================
-- TAB BAR
--==================================================

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -24, 0, 43)
TabBar.Position = UDim2.fromOffset(12, 65)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Panel

local LegitTab = Instance.new("TextButton")
LegitTab.Size = UDim2.new(0.5, -5, 1, 0)
LegitTab.Position = UDim2.fromOffset(0, 0)
LegitTab.BackgroundTransparency = 1
LegitTab.Text = "Legit"
LegitTab.TextColor3 = WHITE
LegitTab.Font = Enum.Font.GothamMedium
LegitTab.TextSize = 16
LegitTab.Parent = TabBar

local LegitLine = Instance.new("Frame")
LegitLine.Size = UDim2.new(1, -20, 0, 3)
LegitLine.Position = UDim2.new(0, 10, 1, -3)
LegitLine.BackgroundColor3 = ORANGE
LegitLine.BorderSizePixel = 0
LegitLine.Parent = LegitTab

local SilentTab = Instance.new("TextButton")
SilentTab.Size = UDim2.new(0.5, -5, 1, 0)
SilentTab.Position = UDim2.new(0.5, 5, 0, 0)
SilentTab.BackgroundTransparency = 1
SilentTab.Text = "pSilent"
SilentTab.TextColor3 = GRAY
SilentTab.Font = Enum.Font.GothamMedium
SilentTab.TextSize = 16
SilentTab.Parent = TabBar

local SilentLine = Instance.new("Frame")
SilentLine.Size = UDim2.new(1, -20, 0, 3)
SilentLine.Position = UDim2.new(0, 10, 1, -3)
SilentLine.BackgroundColor3 = ORANGE
SilentLine.BorderSizePixel = 0
SilentLine.Visible = false
SilentLine.Parent = SilentTab

--==================================================
-- CONTENT
--==================================================

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -24, 1, -165)
Content.Position = UDim2.fromOffset(12, 112)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = ORANGE
Content.CanvasSize = UDim2.new(0, 0, 0, 600)
Content.Parent = Panel

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 7)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Content

--==================================================
-- HELPERS
--==================================================

local function ComponentLabel(text)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 0, 24)
	l.BackgroundTransparency = 1
	l.Text = "◆  " .. text
	l.TextColor3 = PURPLE
	l.TextSize = 12
	l.Font = Enum.Font.GothamBold
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = Content
	return l
end

local function Toggle(text, state, callback)

	local Row = Instance.new("Frame")
	Row.Size = UDim2.new(1, 0, 0, 48)
	Row.BackgroundTransparency = 1
	Row.Parent = Content

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -75, 1, 0)
	Label.BackgroundTransparency = 1
	Label.Text = text
	Label.TextColor3 = WHITE
	Label.TextSize = 14
	Label.Font = Enum.Font.Gotham
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Row

	local Switch = Instance.new("TextButton")
	Switch.Size = UDim2.fromOffset(58, 30)
	Switch.Position = UDim2.new(1, -60, 0.5, -15)
	Switch.Text = ""
	Switch.BorderSizePixel = 0
	Switch.Parent = Row

	Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)

	local Knob = Instance.new("Frame")
	Knob.Size = UDim2.fromOffset(24, 24)
	Knob.BorderSizePixel = 0
	Knob.Parent = Switch

	Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

	local current = state

	local function Update()
		if current then
			Switch.BackgroundColor3 = ORANGE_DARK
			Knob.BackgroundColor3 = ORANGE
			Knob.Position = UDim2.new(1, -27, 0.5, -12)
		else
			Switch.BackgroundColor3 = CARD2
			Knob.BackgroundColor3 = Color3.fromRGB(110, 110, 115)
			Knob.Position = UDim2.new(0, 3, 0.5, -12)
		end
	end

	Switch.Activated:Connect(function()
		current = not current
		Update()
		callback(current)
	end)

	Update()

	return Row
end

local function Slider(text, min, max, default, callback)

	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, 0, 0, 62)
	Frame.BackgroundTransparency = 1
	Frame.Parent = Content

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, 0, 0, 25)
	Label.BackgroundTransparency = 1
	Label.Text = text .. " : " .. default
	Label.TextColor3 = WHITE
	Label.TextSize = 13
	Label.Font = Enum.Font.Gotham
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Frame

	local Bar = Instance.new("Frame")
	Bar.Size = UDim2.new(1, 0, 0, 7)
	Bar.Position = UDim2.fromOffset(0, 38)
	Bar.BackgroundColor3 = CARD2
	Bar.BorderSizePixel = 0
	Bar.Parent = Frame

	Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)

	local Fill = Instance.new("Frame")
	Fill.Size = UDim2.new(
		(default - min) / (max - min),
		0,
		1,
		0
	)
	Fill.BackgroundColor3 = ORANGE
	Fill.BorderSizePixel = 0
	Fill.Parent = Bar

	Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

	local dragging = false

	local function Update(x)

		local percent = math.clamp(
			(x - Bar.AbsolutePosition.X) /
			Bar.AbsoluteSize.X,
			0,
			1
		)

		local value = math.floor(
			min + ((max - min) * percent)
		)

		Fill.Size = UDim2.new(percent, 0, 1, 0)
		Label.Text = text .. " : " .. value

		callback(value)
	end

	Bar.InputBegan:Connect(function(input)

		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1 then

			dragging = true
			Update(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)

		if not dragging then
			return
		end

		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseMovement then

			Update(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)

		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1 then

			dragging = false
		end
	end)

	return Frame
end

local function Dropdown(text, options, default, callback)

	local current = default

	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, 0, 0, 45)
	Button.BackgroundColor3 = CARD
	Button.BorderSizePixel = 0
	Button.Text = text .. "        " .. current
	Button.TextColor3 = WHITE
	Button.TextSize = 13
	Button.Font = Enum.Font.Gotham
	Button.TextXAlignment = Enum.TextXAlignment.Left
	Button.Parent = Content

	Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)

	Button.Activated:Connect(function()

		local index = table.find(options, current) or 1

		index += 1

		if index > #options then
			index = 1
		end

		current = options[index]

		Button.Text = text .. "        " .. current

		callback(current)
	end)

	return Button
end

--==================================================
-- AIMBOT PAGE
--==================================================

ComponentLabel("Component 1")

Toggle("Aim", Settings.Enabled, function(value)
	Settings.Enabled = value

	if not value then
		Target = nil
	end
end)

ComponentLabel("Component 2")

Toggle("Show Range", true, function(value)
	FOVCircle.Visible = value
end)

Toggle("Target Lock", Settings.TargetLock, function(value)
	Settings.TargetLock = value
end)

Toggle("Wall Check", Settings.WallCheck, function(value)
	Settings.WallCheck = value
end)

Toggle("Team Check", Settings.TeamCheck, function(value)
	Settings.TeamCheck = value
end)

ComponentLabel("Aim Settings")

Slider(
	"FOV",
	50,
	500,
	Settings.FOV,
	function(value)
		Settings.FOV = value
	end
)

Slider(
	"Smoothness",
	10,
	100,
	Settings.Smoothness,
	function(value)
		Settings.Smoothness = value
	end
)

Dropdown(
	"Bone",
	{
		"Head",
		"Torso",
		"HumanoidRootPart"
	},
	"Head",
	function(value)
		Settings.HitPart = value
	end
)

--==================================================
-- BOTTOM NAVIGATION
--==================================================

local Bottom = Instance.new("Frame")
Bottom.Size = UDim2.new(1, 0, 0, 53)
Bottom.Position = UDim2.new(0, 0, 1, -53)
Bottom.BackgroundColor3 = PANEL
Bottom.BorderSizePixel = 0
Bottom.Parent = Panel

local NavNames = {
	"AIMBOT",
	"VISUALS",
	"WEAPON",
	"MISC",
	"SETTINGS"
}

local NavSymbols = {
	"◎",
	"◉",
	"▰",
	"•••",
	"⚙"
}

for i, name in ipairs(NavNames) do

	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(0.2, 0, 1, 0)
	Button.Position = UDim2.new((i - 1) * 0.2, 0, 0, 0)
	Button.BackgroundTransparency = 1
	Button.Text = NavSymbols[i] .. "\n" .. name
	Button.TextColor3 = i == 1 and ORANGE or GRAY
	Button.TextSize = 10
	Button.Font = Enum.Font.GothamMedium
	Button.Parent = Bottom

	Button.Activated:Connect(function()

		for _, child in ipairs(Bottom:GetChildren()) do
			if child:IsA("TextButton") then
				child.TextColor3 = GRAY
			end
		end

		Button.TextColor3 = ORANGE

		-- Only Aimbot is implemented in this script.
		if i ~= 1 then
			Button.TextColor3 = GRAY
		end
	end)
end

--==================================================
-- TAB SWITCHING
--==================================================

LegitTab.Activated:Connect(function()

	LegitTab.TextColor3 = WHITE
	SilentTab.TextColor3 = GRAY

	LegitLine.Visible = true
	SilentLine.Visible = false

	Content.Visible = true
end)

SilentTab.Activated:Connect(function()

	SilentTab.TextColor3 = WHITE
	LegitTab.TextColor3 = GRAY

	LegitLine.Visible = false
	SilentLine.Visible = true

	-- No silent-aim implementation here.
	-- This tab is UI-only.
end)

--==================================================
-- OPEN / CLOSE
--==================================================

local Open = Instance.new("TextButton")
Open.Size = UDim2.fromOffset(52, 52)
Open.Position = UDim2.fromOffset(18, 18)
Open.BackgroundColor3 = PANEL
Open.Text = "L"
Open.TextColor3 = ORANGE
Open.TextSize = 26
Open.Font = Enum.Font.GothamBold
Open.Visible = false
Open.Parent = Gui

Instance.new("UICorner", Open).CornerRadius = UDim.new(0, 12)

Close.Activated:Connect(function()
	Panel.Visible = false
	Open.Visible = true
end)

Open.Activated:Connect(function()
	Panel.Visible = true
	Open.Visible = false
end)

--==================================================
-- DRAG / MOVE PANEL
--==================================================

local dragging = false
local dragStart
local panelStart

Top.InputBegan:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then

		dragging = true
		dragStart = input.Position
		panelStart = Panel.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)

	if not dragging then
		return
	end

	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseMovement then

		local delta = input.Position - dragStart

		Panel.Position = UDim2.new(
			panelStart.X.Scale,
			panelStart.X.Offset + delta.X,
			panelStart.Y.Scale,
			panelStart.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then

		dragging = false
	end
end)