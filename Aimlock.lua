--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "AimAssistUI"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- COLORS
--==================================================

local BG = Color3.fromRGB(10, 10, 11)
local PANEL = Color3.fromRGB(17, 17, 19)
local ROW = Color3.fromRGB(28, 28, 31)

local ORANGE = Color3.fromRGB(255, 170, 15)
local ORANGE_DARK = Color3.fromRGB(100, 70, 8)

local WHITE = Color3.fromRGB(235, 235, 235)
local GRAY = Color3.fromRGB(145, 145, 150)
local PURPLE = Color3.fromRGB(170, 70, 255)

--==================================================
-- FOV CIRCLE
--==================================================

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOV"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.fromScale(0.5, 0.5)
FOVCircle.Size = UDim2.fromOffset(
	Settings.FOV * 2,
	Settings.FOV * 2
)
FOVCircle.BackgroundTransparency = 1
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
Panel.Name = "Panel"
Panel.Size = UDim2.fromOffset(320, 430)
Panel.Position = UDim2.new(0, 18, 0.5, -215)
Panel.BackgroundColor3 = BG
Panel.BorderSizePixel = 0
Panel.Parent = Gui

Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 12)

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Color = Color3.fromRGB(45, 45, 48)
PanelStroke.Transparency = 0.25
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
Logo.Size = UDim2.fromOffset(45, 55)
Logo.Position = UDim2.fromOffset(10, 0)
Logo.BackgroundTransparency = 1
Logo.Text = "L"
Logo.TextColor3 = ORANGE
Logo.Font = Enum.Font.GothamBold
Logo.TextSize = 34
Logo.Parent = Top

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 0, 27)
Title.Position = UDim2.fromOffset(58, 6)
Title.BackgroundTransparency = 1
Title.Text = "AimAssist"
Title.TextColor3 = ORANGE
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Top

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -100, 0, 18)
SubTitle.Position = UDim2.fromOffset(58, 29)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "Mobile"
SubTitle.TextColor3 = GRAY
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 10
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = Top

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(34, 34)
Close.Position = UDim2.new(1, -45, 0, 12)
Close.BackgroundColor3 = ROW
Close.Text = "×"
Close.TextColor3 = WHITE
Close.TextSize = 22
Close.Font = Enum.Font.GothamBold
Close.Parent = Top

Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 8)

--==================================================
-- TABS
--==================================================

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -24, 0, 40)
TabBar.Position = UDim2.fromOffset(12, 65)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Panel

local LegitTab = Instance.new("TextButton")
LegitTab.Size = UDim2.new(0.5, -5, 1, 0)
LegitTab.BackgroundTransparency = 1
LegitTab.Text = "Legit"
LegitTab.TextColor3 = WHITE
LegitTab.TextSize = 16
LegitTab.Font = Enum.Font.GothamMedium
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
SilentTab.TextSize = 16
SilentTab.Font = Enum.Font.GothamMedium
SilentTab.Parent = TabBar

--==================================================
-- CONTENT
--==================================================

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -24, 1, -170)
Content.Position = UDim2.fromOffset(12, 112)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = ORANGE
Content.CanvasSize = UDim2.new(0, 0, 0, 600)
Content.Parent = Panel

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 4)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Content

--==================================================
-- UI HELPERS
--==================================================

local function Component(text)

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, 0, 0, 25)
	Label.BackgroundTransparency = 1
	Label.Text = "◆ " .. text
	Label.TextColor3 = PURPLE
	Label.TextSize = 12
	Label.Font = Enum.Font.GothamBold
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Content

	return Label
end

local function Toggle(text, value, callback)

	local Row = Instance.new("Frame")
	Row.Size = UDim2.new(1, 0, 0, 42)
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
	Switch.Size = UDim2.fromOffset(56, 28)
	Switch.Position = UDim2.new(1, -56, 0.5, -14)
	Switch.Text = ""
	Switch.BorderSizePixel = 0
	Switch.Parent = Row

	Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)

	local Knob = Instance.new("Frame")
	Knob.Size = UDim2.fromOffset(22, 22)
	Knob.BorderSizePixel = 0
	Knob.Parent = Switch

	Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

	local enabled = value

	local function Update()

		if enabled then
			Switch.BackgroundColor3 = ORANGE_DARK
			Knob.BackgroundColor3 = ORANGE
			Knob.Position = UDim2.new(1, -25, 0.5, -11)
		else
			Switch.BackgroundColor3 = ROW
			Knob.BackgroundColor3 = Color3.fromRGB(100, 100, 105)
			Knob.Position = UDim2.new(0, 3, 0.5, -11)
		end
	end

	Switch.Activated:Connect(function()

		enabled = not enabled

		Update()
		callback(enabled)
	end)

	Update()

	return Row
end

local function Slider(text, minimum, maximum, default, callback)

	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, 0, 0, 58)
	Frame.BackgroundTransparency = 1
	Frame.Parent = Content

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, 0, 0, 22)
	Label.BackgroundTransparency = 1
	Label.Text = text .. " : " .. default
	Label.TextColor3 = WHITE
	Label.TextSize = 13
	Label.Font = Enum.Font.Gotham
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Frame

	local Bar = Instance.new("Frame")
	Bar.Size = UDim2.new(1, 0, 0, 7)
	Bar.Position = UDim2.fromOffset(0, 34)
	Bar.BackgroundColor3 = ROW
	Bar.BorderSizePixel = 0
	Bar.Parent = Frame

	Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)

	local Fill = Instance.new("Frame")
	Fill.Size = UDim2.new(
		(default - minimum) / (maximum - minimum),
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
			minimum +
			((maximum - minimum) * percent)
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

		if dragging then

			if input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType ==