--// Dark AimAssist UI
--// Standalone UI for your own Roblox Studio experience

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

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

local BG = Color3.fromRGB(15, 15, 20)
local PANEL = Color3.fromRGB(23, 23, 30)
local CARD = Color3.fromRGB(31, 31, 40)
local CARD_HOVER = Color3.fromRGB(39, 39, 50)
local TEXT = Color3.fromRGB(245, 245, 250)
local SUBTEXT = Color3.fromRGB(155, 155, 170)
local BLUE = Color3.fromRGB(75, 130, 255)
local GREEN = Color3.fromRGB(55, 190, 105)
local RED = Color3.fromRGB(220, 75, 75)

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "AdvancedAimUI"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = PlayerGui

--==================================================
-- MAIN PANEL
--==================================================

local Panel = Instance.new("Frame")
Panel.Size = UDim2.new(0, 320, 0, 430)
Panel.Position = UDim2.new(0, 20, 0.5, -215)
Panel.BackgroundColor3 = BG
Panel.BorderSizePixel = 0
Panel.Parent = Gui

Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 16)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(65, 65, 80)
Stroke.Transparency = 0.35
Stroke.Parent = Panel

--==================================================
-- TITLE BAR
--==================================================

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 62)
Header.BackgroundTransparency = 1
Header.Parent = Panel

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -90, 0, 28)
Title.Position = UDim2.fromOffset(18, 9)
Title.BackgroundTransparency = 1
Title.Text = "AimAssist"
Title.TextColor3 = TEXT
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -90, 0, 18)
Status.Position = UDim2.fromOffset(19, 35)
Status.BackgroundTransparency = 1
Status.Text = "●  DISABLED"
Status.TextColor3 = SUBTEXT
Status.Font = Enum.Font.GothamMedium
Status.TextSize = 10
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Header

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(36, 36)
Minimize.Position = UDim2.new(1, -48, 0, 13)
Minimize.BackgroundColor3 = CARD
Minimize.Text = "—"
Minimize.TextColor3 = TEXT
Minimize.TextSize = 20
Minimize.Font = Enum.Font.GothamBold
Minimize.Parent = Header

Instance.new("UICorner", Minimize).CornerRadius = UDim.new(0, 10)

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
Tabs.BackgroundColor3 = PANEL
Tabs.BorderSizePixel = 0
Tabs.Parent = Content

Instance.new("UICorner", Tabs).CornerRadius = UDim.new(0, 10)

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 4)
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.Parent = Tabs

local function CreateTab(Name)
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(0.31, 0, 0, 34)
	Button.BackgroundColor3 = PANEL
	Button.BorderSizePixel = 0
	Button.Text = Name
	Button.TextColor3 = SUBTEXT
	Button.Font = Enum.Font.GothamSemibold
	Button.TextSize = 11
	Button.Parent = Tabs

	Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)

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

local AimPage = Instance.new("ScrollingFrame")
AimPage.Size = UDim2.fromScale(1, 1)
AimPage.BackgroundTransparency = 1
AimPage.BorderSizePixel = 0
AimPage.ScrollBarThickness = 3
AimPage.CanvasSize = UDim2.new(0, 0, 0, 0)
AimPage.Parent = Pages

local VisualPage = AimPage:Clone()
VisualPage.Parent = Pages

local SettingsPage = AimPage:Clone()
SettingsPage.Parent = Pages

AimPage.Visible = true
VisualPage.Visible = false
SettingsPage.Visible = false

local function SetTab(tab, page)
	AimPage.Visible = false
	VisualPage.Visible = false
	SettingsPage.Visible = false

	page.Visible = true

	AimTab.BackgroundColor3 = PANEL
	VisualTab.BackgroundColor3 = PANEL
	SettingsTab.BackgroundColor3 = PANEL

	tab.BackgroundColor3 = CARD
end

AimTab.Activated:Connect(function()
	SetTab(AimTab, AimPage)
end)

VisualTab.Activated:Connect(function()
	SetTab(VisualTab, VisualPage)
end)

SettingsTab.Activated:Connect(function()
	SetTab(SettingsTab, SettingsPage)
end)

AimTab.BackgroundColor3 = CARD

--==================================================
-- UI HELPERS
--==================================================

local function Card(parent, height)
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, -4, 0, height)
	Frame.BackgroundColor3 = CARD
	Frame.BorderSizePixel = 0
	Frame.Parent = parent

	Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 11)

	return Frame
end

local function AddPadding(parent)
	local Padding = Instance.new("UIPadding")
	Padding.PaddingTop = UDim.new(0, 8)
	Padding.PaddingBottom = UDim.new(0, 8)
	Padding.PaddingLeft = UDim.new(0, 4)
	Padding.PaddingRight = UDim.new(0, 4)
	Padding.Parent = parent
end

AddPadding(AimPage)
AddPadding(VisualPage)
AddPadding(SettingsPage)

local function MakeToggle(parent, text, initial, callback)
	local Frame = Card(parent, 52)

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -70, 1, 0)
	Label.Position = UDim2.fromOffset(14, 0)
	Label.BackgroundTransparency = 1
	Label.Text = text
	Label.TextColor3 = TEXT
	Label.Font = Enum.Font.GothamMedium
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Frame

	local Toggle = Instance.new("TextButton")
	Toggle.Size = UDim2.fromOffset(45, 24)
	Toggle.Position = UDim2.new(1, -59, 0.5, -12)
	Toggle.Text = ""
	Toggle.BorderSizePixel = 0
	Toggle.Parent = Frame

	Instance.new("UICorner", Toggle).CornerRadius = UDim.new(1, 0)

	local Dot = Instance.new("Frame")
	Dot.Size = UDim2.fromOffset(18, 18)
	Dot.Position = UDim2.fromOffset(3, 3)
	Dot.BorderSizePixel = 0
	Dot.Parent = Toggle

	Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

	local State = initial

	local function Update()
		if State then
			Toggle.BackgroundColor3 = BLUE
			Dot.BackgroundColor3 = Color3.new(1, 1, 1)
			Dot.Position = UDim2.new(1, -21, 0, 3)
		else
			Toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
			Dot.BackgroundColor3 = SUBTEXT
			Dot.Position = UDim2.fromOffset(3, 3)
		end
	end

	Toggle.Activated:Connect(function()
		State = not State
		Update()
		callback(State)
	end)

	Update()
	return Frame
end

local function MakeSlider(parent, text, min, max, value, callback)
	local Frame = Card(parent, 64)

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -25, 0, 22)
	Label.Position = UDim2.fromOffset(13, 5)
	Label.BackgroundTransparency = 1
	Label.Text = text .. " : " .. value
	Label.TextColor3 = TEXT
	Label.Font = Enum.Font.GothamMedium
	Label.TextSize = 12
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Frame

	local Bar = Instance.new("Frame")
	Bar.Size = UDim2.new(1, -26, 0, 7)
	Bar.Position = UDim2.fromOffset(13, 40)
	Bar.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
	Bar.BorderSizePixel = 0
	Bar.Parent = Frame

	Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)

	local Fill = Instance.new("Frame")
	Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
	Fill.BackgroundColor3 = BLUE
	Fill.BorderSizePixel = 0
	Fill.Parent = Bar

	Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

	local dragging = false

	local function Update(x)
		local percent = math.clamp(
			(x - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X,
			0,
			1
		)

		local newValue = math.floor(
			min + (max - min) * percent
		)

		Fill.Size = UDim2.new(percent, 0, 1, 0)
		Label.Text = text .. " : " .. newValue

		callback(newValue)
	end

	Bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragging = true
			Update(input.Position.X)
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if dragging and (
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		) then
			Update(input.Position.X)
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return Frame
end

local function MakeButton(parent, text, callback)
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, -4, 0, 48)
	Button.BackgroundColor3 = CARD
	Button.BorderSizePixel = 0
	Button.Text = text
	Button.TextColor3 = TEXT
	Button.Font = Enum.Font.GothamMedium
	Button.TextSize = 13
	Button.Parent = parent

	Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 11)

	Button.Activated:Connect(callback)

	return Button
end

--==================================================
-- AIM PAGE
--==================================================

local AimLayout = Instance.new("UIListLayout")
AimLayout.Padding = UDim.new(0, 8)
AimLayout.Parent = AimPage

MakeToggle(AimPage, "Aim Assist", Settings.AimAssist, function(value)
	Settings.AimAssist = value

	if value then
		Status.Text = "●  ACTIVE"
		Status.TextColor3 = GREEN
	else
		Status.Text = "●  DISABLED"
		Status.TextColor3 = SUBTEXT
	end
end)

MakeToggle(AimPage, "Target Lock", Settings.TargetLock, function(value)
	Settings.TargetLock = value
end)

MakeSlider(AimPage, "FOV", 50, 500, Settings.FOV, function(value)
	Settings.FOV = value
end)

MakeSlider(AimPage, "Smoothness", 10, 100, Settings.Smoothness, function(value)
	Settings.Smoothness = value
end)

--==================================================
-- VISUAL PAGE
--==================================================

local VisualLayout = Instance.new("UIListLayout")
VisualLayout.Padding = UDim.new(0, 8)
VisualLayout.Parent = VisualPage

MakeToggle(VisualPage, "Wall Check", Settings.WallCheck, function(value)
	Settings.WallCheck = value
end)

MakeToggle(VisualPage, "Team Check", Settings.TeamCheck, function(value)
	Settings.TeamCheck = value
end)

local HitButton

local HitParts = {
	"Head",
	"UpperTorso",
	"HumanoidRootPart"
}

local HitIndex = 1

HitButton = MakeButton(VisualPage, "Hit Part : " .. Settings.HitPart, function()
	HitIndex += 1

	if HitIndex > #HitParts then
		HitIndex = 1
	end

	Settings.HitPart = HitParts[HitIndex]
	HitButton.Text = "Hit Part : " .. Settings.HitPart
end)

--==================================================
-- SETTINGS PAGE
--==================================================

local SettingsLayout = Instance.new("UIListLayout")
SettingsLayout.Padding = UDim.new(0, 8)
SettingsLayout.Parent = SettingsPage

MakeButton(SettingsPage, "Reset Settings", function()
	Settings.AimAssist = false
	Settings.TargetLock = true
	Settings.WallCheck = true
	Settings.TeamCheck = true
	Settings.FOV = 250
	Settings.Smoothness = 85
	Settings.Prediction = 0.08
	Settings.HitPart = "Head"

	Status.Text = "●  DISABLED"
	Status.TextColor3 = SUBTEXT
end)

MakeButton(SettingsPage, "UI Information", function()
	print("AimAssist UI loaded successfully.")
	print("FOV:", Settings.FOV)
	print("Smoothness:", Settings.Smoothness)
	print("Prediction:", Settings.Prediction)
	print("HitPart:", Settings.HitPart)
end)

--==================================================
-- MINIMIZE BUTTON
--==================================================

local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.fromOffset(52, 52)
OpenButton.Position = UDim2.fromOffset(18, 18)
OpenButton.BackgroundColor3 = PANEL
OpenButton.BorderSizePixel = 0
OpenButton.Text = "☰"
OpenButton.TextColor3 = TEXT
OpenButton.TextSize = 21
OpenButton.Font = Enum.Font.GothamBold
OpenButton.Visible = false
OpenButton.Parent = Gui

Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(0, 13)

Minimize.Activated:Connect(function()
	Panel.Visible = false
	OpenButton.Visible = true
end)

OpenButton.Activated:Connect(function()
	Panel.Visible = true
	OpenButton.Visible = false
end)

--==================================================
-- PC + MOBILE DRAGGING
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

UIS.InputChanged:Connect(function(input)
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

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		Dragging = false
	end
end)

--==================================================
-- RESPONSIVE MOBILE SIZE
--==================================================

local function ResizeUI()
	local Camera = workspace.CurrentCamera

	if not Camera then
		return
	end

	local Viewport = Camera.ViewportSize

	if Viewport.X < 500 then
		Panel.Size = UDim2.new(0.82, 0, 0, 430)
		Panel.Position = UDim2.new(0.09, 0, 0.5, -215)
	else
		Panel.Size = UDim2.fromOffset(320, 430)

		if Panel.Position.X.Scale == 0 then
			Panel.Position = UDim2.new(
				0,
				20,
				0.5,
				-215
			)
		end
	end
end

ResizeUI()

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(
	ResizeUI
)

print("Advanced Dark UI loaded.")