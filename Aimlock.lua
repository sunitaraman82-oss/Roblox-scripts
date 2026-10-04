--// Advanced Dark AimAssist UI
--// For your own Roblox experience / Studio testing
--// UI + FOV visualization only

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local Settings = {
	AimAssist = false,
	TargetLock = true,
	WallCheck = true,
	TeamCheck = true,

	FOV = 250,
	Smoothness = 85,
	Prediction = 0.08,

	HitPart = "Head"
}

--==================================================
-- COLORS
--==================================================

local COLORS = {
	Background = Color3.fromRGB(14, 14, 19),
	Panel = Color3.fromRGB(22, 22, 29),
	Card = Color3.fromRGB(31, 31, 40),
	CardHover = Color3.fromRGB(40, 40, 51),

	Text = Color3.fromRGB(245, 245, 250),
	SubText = Color3.fromRGB(155, 155, 170),

	Blue = Color3.fromRGB(75, 130, 255),
	Green = Color3.fromRGB(55, 195, 105),
	Red = Color3.fromRGB(220, 75, 75),

	Bar = Color3.fromRGB(55, 55, 67)
}

--==================================================
-- SCREEN GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "AdvancedAimAssistUI"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = PlayerGui

--==================================================
-- FOV CIRCLE
--==================================================

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.fromScale(0.5, 0.5)
FOVCircle.Size = UDim2.fromOffset(
	Settings.FOV * 2,
	Settings.FOV * 2
)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.ZIndex = 1
FOVCircle.Parent = Gui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 2
FOVStroke.Color = COLORS.Blue
FOVStroke.Transparency = 0.1
FOVStroke.Parent = FOVCircle

--==================================================
-- MAIN PANEL
--==================================================

local Panel = Instance.new("Frame")
Panel.Name = "MainPanel"
Panel.Size = UDim2.fromOffset(320, 440)
Panel.Position = UDim2.new(0, 20, 0.5, -220)
Panel.BackgroundColor3 = COLORS.Background
Panel.BorderSizePixel = 0
Panel.ZIndex = 10
Panel.Parent = Gui

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 16)
PanelCorner.Parent = Panel

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Color = Color3.fromRGB(70, 70, 85)
PanelStroke.Transparency = 0.35
PanelStroke.Parent = Panel

--==================================================
-- HEADER
--==================================================

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 62)
Header.BackgroundTransparency = 1
Header.Parent = Panel

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 0, 28)
Title.Position = UDim2.fromOffset(18, 8)
Title.BackgroundTransparency = 1
Title.Text = "AimAssist"
Title.TextColor3 = COLORS.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -100, 0, 18)
Status.Position = UDim2.fromOffset(19, 36)
Status.BackgroundTransparency = 1
Status.Text = "●  DISABLED"
Status.TextColor3 = COLORS.SubText
Status.Font = Enum.Font.GothamMedium
Status.TextSize = 10
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Header

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(36, 36)
Minimize.Position = UDim2.new(1, -48, 0, 13)
Minimize.BackgroundColor3 = COLORS.Card
Minimize.Text = "—"
Minimize.TextColor3 = COLORS.Text
Minimize.TextSize = 20
Minimize.Font = Enum.Font.GothamBold
Minimize.BorderSizePixel = 0
Minimize.Parent = Header

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 10)
MinCorner.Parent = Minimize

--==================================================
-- CONTENT
--==================================================

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -24, 1, -72)
Content.Position = UDim2.fromOffset(12, 65)
Content.BackgroundTransparency = 1
Content.Parent = Panel

--==================================================
-- TABS
--==================================================

local Tabs = Instance.new("Frame")
Tabs.Size = UDim2.new(1, 0, 0, 42)
Tabs.BackgroundColor3 = COLORS.Panel
Tabs.BorderSizePixel = 0
Tabs.Parent = Content

local TabsCorner = Instance.new("UICorner")
TabsCorner.CornerRadius = UDim.new(0, 10)
TabsCorner.Parent = Tabs

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.Padding = UDim.new(0, 4)
TabLayout.Parent = Tabs

local function CreateTab(text)
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(0.31, 0, 0, 34)
	Button.BackgroundColor3 = COLORS.Panel
	Button.BorderSizePixel = 0
	Button.Text = text
	Button.TextColor3 = COLORS.SubText
	Button.Font = Enum.Font.GothamSemibold
	Button.TextSize = 11
	Button.Parent = Tabs

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = Button

	return Button
end

local AimTab = CreateTab("AIM")
local VisualTab = CreateTab("VISUALS")
local SettingsTab = CreateTab("SETTINGS")

--==================================================
-- PAGES
--==================================================

local Pages = Instance.new("Frame")
Pages.Size = UDim2.new(1, 0, 1, -50)
Pages.Position = UDim2.fromOffset(0, 50)
Pages.BackgroundTransparency = 1
Pages.Parent = Content

local function CreatePage()
	local Page = Instance.new("ScrollingFrame")
	Page.Size = UDim2.fromScale(1, 1)
	Page.BackgroundTransparency = 1
	Page.BorderSizePixel = 0
	Page.ScrollBarThickness = 3
	Page.ScrollBarImageColor3 = COLORS.Blue
	Page.CanvasSize = UDim2.new(0, 0, 0, 0)
	Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Page.Parent = Pages

	local Padding = Instance.new("UIPadding")
	Padding.PaddingTop = UDim.new(0, 4)
	Padding.PaddingBottom = UDim.new(0, 8)
	Padding.PaddingLeft = UDim.new(0, 2)
	Padding.PaddingRight = UDim.new(0, 2)
	Padding.Parent = Page

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0, 8)
	Layout.Parent = Page

	return Page
end

local AimPage = CreatePage()
local VisualPage = CreatePage()
local SettingsPage = CreatePage()

VisualPage.Visible = false
SettingsPage.Visible = false

local function SetPage(tab, page)
	AimPage.Visible = false
	VisualPage.Visible = false
	SettingsPage.Visible = false

	AimTab.BackgroundColor3 = COLORS.Panel
	VisualTab.BackgroundColor3 = COLORS.Panel
	SettingsTab.BackgroundColor3 = COLORS.Panel

	page.Visible = true
	tab.BackgroundColor3 = COLORS.Card
end

SetPage(AimTab, AimPage)

AimTab.Activated:Connect(function()
	SetPage(AimTab, AimPage)
end)

VisualTab.Activated:Connect(function()
	SetPage(VisualTab, VisualPage)
end)

SettingsTab.Activated:Connect(function()
	SetPage(SettingsTab, SettingsPage)
end)

--==================================================
-- CARD
--==================================================

local function CreateCard(parent, height)
	local Card = Instance.new("Frame")
	Card.Size = UDim2.new(1, 0, 0, height)
	Card.BackgroundColor3 = COLORS.Card
	Card.BorderSizePixel = 0
	Card.Parent = parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 11)
	Corner.Parent = Card

	return Card
end

--==================================================
-- TOGGLE
--==================================================

local function CreateToggle(parent, text, value, callback)

	local Card = CreateCard(parent, 52)

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -75, 1, 0)
	Label.Position = UDim2.fromOffset(14, 0)
	Label.BackgroundTransparency = 1
	Label.Text = text
	Label.TextColor3 = COLORS.Text
	Label.Font = Enum.Font.GothamMedium
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Card

	local Toggle = Instance.new("TextButton")
	Toggle.Size = UDim2.fromOffset(46, 25)
	Toggle.Position = UDim2.new(1, -60, 0.5, -12)
	Toggle.Text = ""
	Toggle.BorderSizePixel = 0
	Toggle.Parent = Card

	local ToggleCorner = Instance.new("UICorner")
	ToggleCorner.CornerRadius = UDim.new(1, 0)
	ToggleCorner.Parent = Toggle

	local Dot = Instance.new("Frame")
	Dot.Size = UDim2.fromOffset(19, 19)
	Dot.BorderSizePixel = 0
	Dot.Parent = Toggle

	local DotCorner = Instance.new("UICorner")
	DotCorner.CornerRadius = UDim.new(1, 0)
	DotCorner.Parent = Dot

	local State = value

	local function Update()
		if State then
			Toggle.BackgroundColor3 = COLORS.Blue
			Dot.BackgroundColor3 = Color3.new(1, 1, 1)
			Dot.Position = UDim2.new(1, -22, 0, 3)
		else
			Toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
			Dot.BackgroundColor3 = COLORS.SubText
			Dot.Position = UDim2.fromOffset(3, 3)
		end
	end

	Toggle.Activated:Connect(function()
		State = not State
		Update()
		callback(State)
	end)

	Update()

	return Card
end

--==================================================
-- SLIDER
--==================================================

local function CreateSlider(parent, text, min, max, value, callback)

	local Card = CreateCard(parent, 66)

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -25, 0, 22)
	Label.Position = UDim2.fromOffset(13, 5)
	Label.BackgroundTransparency = 1
	Label.Text = text .. " : " .. value
	Label.TextColor3 = COLORS.Text
	Label.Font = Enum.Font.GothamMedium
	Label.TextSize = 12
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Card

	local Bar = Instance.new("Frame")
	Bar.Size = UDim2.new(1, -26, 0, 8)
	Bar.Position = UDim2.fromOffset(13, 43)
	Bar.BackgroundColor3 = COLORS.Bar
	Bar.BorderSizePixel = 0
	Bar.Parent = Card

	local BarCorner = Instance.new("UICorner")
	BarCorner.CornerRadius = UDim.new(1, 0)
	BarCorner.Parent = Bar

	local Fill = Instance.new("Frame")
	Fill.Size = UDim2.new(
		(value - min) / (max - min),
		0,
		1,
		0
	)
	Fill.BackgroundColor3 = COLORS.Blue
	Fill.BorderSizePixel = 0
	Fill.Parent = Bar

	local FillCorner = Instance.new("UICorner")
	FillCorner.CornerRadius = UDim.new(1, 0)
	FillCorner.Parent = Fill

	local Knob = Instance.new("Frame")
	Knob.Size = UDim2.fromOffset(16, 16)
	Knob.AnchorPoint = Vector2.new(0.5, 0.5)
	Knob.Position = UDim2.new(
		(value - min) / (max - min),
		0,
		0.5,
		0
	)
	Knob.BackgroundColor3 = Color3.new(1, 1, 1)
	Knob.BorderSizePixel = 0
	Knob.ZIndex = 3
	Knob.Parent = Bar

	local KnobCorner = Instance.new("UICorner")
	KnobCorner.CornerRadius = UDim.new(1, 0)
	KnobCorner.Parent = Knob

	local Dragging = false

	local function Update(x)

		local Percent = math.clamp(
			(x - Bar.AbsolutePosition.X) /
			Bar.AbsoluteSize.X,
			0,
			1
		)

		local NewValue = math.floor(
			min + ((max - min) * Percent)
		)

		Fill.Size = UDim2.new(Percent, 0, 1, 0)
		Knob.Position = UDim2.new(Percent, 0, 0.5, 0)

		Label.Text = text .. " : " .. NewValue

		callback(NewValue)
	end

	Bar.InputBegan:Connect(function(input)

		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			Dragging = true
			Update(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)

		if not Dragging then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then

			Update(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)

		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			Dragging = false
		end
	end)

	return Card
end

--==================================================
-- BUTTON
--==================================================

local function CreateButton(parent, text, callback)

	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, 0, 0, 50)
	Button.BackgroundColor3 = COLORS.Card
	Button.BorderSizePixel = 0
	Button.Text = text
	Button.TextColor3 = COLORS.Text
	Button.Font = Enum.Font.GothamMedium
	Button.TextSize = 13
	Button.Parent = parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 11)
	Corner.Parent = Button

	Button.Activated:Connect(callback)

	return Button
end

--==================================================
-- AIM PAGE
--==================================================

CreateToggle(
	AimPage,
	"Aim Assist",
	Settings.AimAssist,
	function(value)

		Settings.AimAssist = value

		if value then
			Status.Text = "●  ACTIVE"
			Status.TextColor3 = COLORS.Green
		else
			Status.Text = "●  DISABLED"
			Status.TextColor3 = COLORS.SubText
		end
	end
)

CreateToggle(
	AimPage,
	"Target Lock",
	Settings.TargetLock,
	function(value)
		Settings.TargetLock = value
	end
)

CreateSlider(
	AimPage,
	"FOV",
	50,
	500,
	Settings.FOV,
	function(value)

		Settings.FOV = value

		-- Update the visible FOV circle
		FOVCircle.Size = UDim2.fromOffset(
			value * 2,
			value * 2
		)
	end
)

CreateSlider(
	AimPage,
	"Smoothness",
	10,
	100,
	Settings.Smoothness,
	function(value)
		Settings.Smoothness = value
	end
)

--==================================================
-- VISUAL PAGE
--==================================================

CreateToggle(
	VisualPage,
	"Show FOV Circle",
	true,
	function(value)
		FOVCircle.Visible = value
	end
)

CreateToggle(
	VisualPage,
	"Wall Check",
	Settings.WallCheck,
	function(value)
		Settings.WallCheck = value
	end
)

CreateToggle(
	VisualPage,
	"Team Check",
	Settings.TeamCheck,
	function(value)
		Settings.TeamCheck = value
	end
)

local HitParts = {
	"Head",
	"UpperTorso",
	"HumanoidRootPart"
}

local HitIndex = 1

local HitButton = CreateButton(
	VisualPage,
	"Hit Part : Head",
	function()

		HitIndex += 1

		if HitIndex > #HitParts then
			HitIndex = 1
		end

		Settings.HitPart = HitParts[HitIndex]

		HitButton.Text =
			"Hit Part : " .. Settings.HitPart
	end
)

--==================================================
-- SETTINGS PAGE
--==================================================

CreateButton(
	SettingsPage,
	"Reset Settings",
	function()

		Settings.AimAssist = false
		Settings.TargetLock = true
		Settings.WallCheck = true
		Settings.TeamCheck = true

		Settings.FOV = 250
		Settings.Smoothness = 85
		Settings.Prediction = 0.08
		Settings.HitPart = "Head"

		FOVCircle.Size = UDim2.fromOffset(
			500,
			500
		)

		Status.Text = "●  DISABLED"
		Status.TextColor3 = COLORS.SubText

		HitButton.Text = "Hit Part : Head"
	end
)

CreateButton(
	SettingsPage,
	"Print Current Settings",
	function()

		print("===== AimAssist Settings =====")
		print("AimAssist:", Settings.AimAssist)
		print("TargetLock:", Settings.TargetLock)
		print("WallCheck:", Settings.WallCheck)
		print("TeamCheck:", Settings.TeamCheck)
		print("FOV:", Settings.FOV)
		print("Smoothness:", Settings.Smoothness)
		print("Prediction:", Settings.Prediction)
		print("HitPart:", Settings.HitPart)
		print("==============================")
	end
)

--==================================================
-- MINIMIZE / OPEN
--==================================================

local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.fromOffset(54, 54)
OpenButton.Position = UDim2.fromOffset(18, 18)
OpenButton.BackgroundColor3 = COLORS.Panel
OpenButton.BorderSizePixel = 0
OpenButton.Text = "☰"
OpenButton.TextColor3 = COLORS.Text
OpenButton.TextSize = 22
OpenButton.Font = Enum.Font.GothamBold
OpenButton.Visible = false
OpenButton.ZIndex = 20
OpenButton.Parent = Gui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, 13)
OpenCorner.Parent = OpenButton

Minimize.Activated:Connect(function()
	Panel.Visible = false
	OpenButton.Visible = true
end)

OpenButton.Activated:Connect(function()
	Panel.Visible = true
	OpenButton.Visible = false
end)

--==================================================
-- PC + MOBILE DRAG
--==================================================

local Dragging = false
local DragStart
local StartPosition

Header.InputBegan:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		Dragging = true
		DragStart = input.Position
		StartPosition = Panel.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)

	if not Dragging then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then

		local Delta = input.Position - DragStart

		Panel.Position = UDim2.new(
			StartPosition.X.Scale,
			StartPosition.X.Offset + Delta.X,
			StartPosition.Y.Scale,
			StartPosition.Y.Offset + Delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		Dragging = false
	end
end)

--==================================================
-- RESPONSIVE SIZE
--==================================================

local function Resize()

	local Camera = workspace.CurrentCamera

	if not Camera then
		return
	end

	local Viewport = Camera.ViewportSize

	if Viewport.X < 500 then

		Panel.Size = UDim2.new(
			0.84,
			0,
			0,
			440
		)

		Panel.Position = UDim2.new(
			0.08,
			0,
			0.5,
			-220
		)

	else

		Panel.Size = UDim2.fromOffset(
			320,
			440
		)

		Panel.Position = UDim2.new(
			0,
			20,
			0.5,
			-220
		)
	end
end

Resize()

workspace.CurrentCamera:GetPropertyChangedSignal(
	"ViewportSize"
):Connect(Resize)

print("Advanced Dark AimAssist UI loaded successfully.")