--// Dark Mobile + PC Aim UI
--// Roblox Studio / your own experience

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local Settings = {
	AimAssist = false,
	TargetLock = false,
	WallCheck = true,
	TeamCheck = true,

	ShowFOV = true,
	FOV = 250,
	Smoothness = 85,

	HitPart = "Head"
}

--==================================================
-- COLORS
--==================================================

local BG = Color3.fromRGB(18, 18, 22)
local PANEL = Color3.fromRGB(25, 25, 30)
local ELEMENT = Color3.fromRGB(34, 34, 42)
local BLUE = Color3.fromRGB(75, 130, 255)
local WHITE = Color3.fromRGB(235, 235, 240)
local GRAY = Color3.fromRGB(150, 150, 160)

--==================================================
-- MAIN GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "DarkAimUI"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 100
Gui.Parent = PlayerGui

--==================================================
-- FOV GUI
--==================================================

local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "FOVDisplay"
FOVGui.ResetOnSpawn = false
FOVGui.IgnoreGuiInset = true
FOVGui.DisplayOrder = 999
FOVGui.Parent = PlayerGui

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Visible = Settings.ShowFOV
FOVCircle.ZIndex = 100
FOVCircle.Parent = FOVGui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 3
FOVStroke.Color = BLUE
FOVStroke.Transparency = 0
FOVStroke.Parent = FOVCircle

--==================================================
-- UPDATE FOV
--==================================================

local function UpdateFOV()
	local Camera = workspace.CurrentCamera
	if not Camera then
		return
	end

	FOVCircle.Position = UDim2.fromOffset(
		Camera.ViewportSize.X / 2,
		Camera.ViewportSize.Y / 2
	)

	FOVCircle.Size = UDim2.fromOffset(
		Settings.FOV * 2,
		Settings.FOV * 2
	)

	FOVCircle.Visible = Settings.ShowFOV
end

RunService.RenderStepped:Connect(UpdateFOV)

--==================================================
-- MAIN PANEL
--==================================================

local Panel = Instance.new("Frame")
Panel.Name = "MainPanel"
Panel.Size = UDim2.fromOffset(330, 390)
Panel.Position = UDim2.new(0.5, -165, 0.5, -195)
Panel.BackgroundColor3 = BG
Panel.BorderSizePixel = 0
Panel.ZIndex = 10
Panel.Parent = Gui

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 12)
PanelCorner.Parent = Panel

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Color = Color3.fromRGB(50, 50, 60)
PanelStroke.Thickness = 1
PanelStroke.Parent = Panel

--==================================================
-- TITLE
--==================================================

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 0, 45)
Title.Position = UDim2.fromOffset(15, 5)
Title.BackgroundTransparency = 1
Title.Text = "AIM ASSIST"
Title.TextColor3 = WHITE
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 11
Title.Parent = Panel

--==================================================
-- CLOSE BUTTON
--==================================================

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(35, 35)
Close.Position = UDim2.new(1, -42, 0, 10)
Close.BackgroundColor3 = ELEMENT
Close.Text = "×"
Close.TextColor3 = WHITE
Close.TextSize = 24
Close.Font = Enum.Font.GothamBold
Close.ZIndex = 12
Close.Parent = Panel

Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 8)

--==================================================
-- CONTENT
--==================================================

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -20, 1, -60)
Content.Position = UDim2.fromOffset(10, 55)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.CanvasSize = UDim2.fromOffset(0, 520)
Content.ZIndex = 11
Content.Parent = Panel

--==================================================
-- HELPER
--==================================================

local Y = 0

local function CreateToggle(name, default, callback)

	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, -5, 0, 45)
	Button.Position = UDim2.fromOffset(0, Y)
	Button.BackgroundColor3 = ELEMENT
	Button.BorderSizePixel = 0
	Button.Text = ""
	Button.ZIndex = 12
	Button.Parent = Content

	Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -65, 1, 0)
	Label.Position = UDim2.fromOffset(15, 0)
	Label.BackgroundTransparency = 1
	Label.Text = name
	Label.TextColor3 = WHITE
	Label.TextSize = 14
	Label.Font = Enum.Font.Gotham
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.ZIndex = 13
	Label.Parent = Button

	local Switch = Instance.new("Frame")
	Switch.Size = UDim2.fromOffset(40, 22)
	Switch.Position = UDim2.new(1, -52, 0.5, -11)
	Switch.BackgroundColor3 = default and BLUE or Color3.fromRGB(70,70,80)
	Switch.ZIndex = 13
	Switch.Parent = Button

	Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)

	local Dot = Instance.new("Frame")
	Dot.Size = UDim2.fromOffset(18, 18)
	Dot.Position = default
		and UDim2.new(1, -20, 0.5, -9)
		or UDim2.fromOffset(2, 2)
	Dot.BackgroundColor3 = WHITE
	Dot.ZIndex = 14
	Dot.Parent = Switch

	Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

	local State = default

	Button.Activated:Connect(function()
		State = not State

		Switch.BackgroundColor3 =
			State and BLUE or Color3.fromRGB(70,70,80)

		Dot.Position =
			State
			and UDim2.new(1, -20, 0.5, -9)
			or UDim2.fromOffset(2, 2)

		callback(State)
	end)

	Y += 52
	return Button
end

local function CreateButton(name, callback)

	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, -5, 0, 45)
	Button.Position = UDim2.fromOffset(0, Y)
	Button.BackgroundColor3 = ELEMENT
	Button.BorderSizePixel = 0
	Button.Text = name
	Button.TextColor3 = WHITE
	Button.TextSize = 14
	Button.Font = Enum.Font.Gotham
	Button.ZIndex = 12
	Button.Parent = Content

	Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)

	Button.Activated:Connect(callback)

	Y += 52
	return Button
end

--==================================================
-- TOGGLES
--==================================================

CreateToggle("Aim Assist", Settings.AimAssist, function(value)
	Settings.AimAssist = value
end)

CreateToggle("Target Lock", Settings.TargetLock, function(value)
	Settings.TargetLock = value
end)

CreateToggle("Wall Check", Settings.WallCheck, function(value)
	Settings.WallCheck = value
end)

CreateToggle("Team Check", Settings.TeamCheck, function(value)
	Settings.TeamCheck = value
end)

CreateToggle("Show FOV Circle", Settings.ShowFOV, function(value)
	Settings.ShowFOV = value
	FOVCircle.Visible = value
end)

--==================================================
-- FOV BUTTON
--==================================================

CreateButton("FOV: 250", function()

	Settings.FOV += 25

	if Settings.FOV > 500 then
		Settings.FOV = 100
	end

	FOVCircle.Size = UDim2.fromOffset(
		Settings.FOV * 2,
		Settings.FOV * 2
	)

end)

--==================================================
-- SMOOTHNESS
--==================================================

CreateButton("Smoothness: 85", function()

	Settings.Smoothness += 5

	if Settings.Smoothness > 100 then
		Settings.Smoothness = 5
	end

end)

--==================================================
-- HIT PART
--==================================================

CreateButton("Hit Part: Head", function()

	if Settings.HitPart == "Head" then
		Settings.HitPart = "Torso"

	elseif Settings.HitPart == "Torso" then
		Settings.HitPart = "HumanoidRootPart"

	else
		Settings.HitPart = "Head"
	end

end)

--==================================================
-- RESET
--==================================================

CreateButton("Reset Settings", function()

	Settings.AimAssist = false
	Settings.TargetLock = false
	Settings.WallCheck = true
	Settings.TeamCheck = true
	Settings.ShowFOV = true
	Settings.FOV = 250
	Settings.Smoothness = 85
	Settings.HitPart = "Head"

	UpdateFOV()
end)

--==================================================
-- CLOSE / OPEN
--==================================================

Close.Activated:Connect(function()
	Panel.Visible = false
end)

local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.fromOffset(55, 55)
OpenButton.Position = UDim2.fromOffset(15, 120)
OpenButton.BackgroundColor3 = BG
OpenButton.Text = "☰"
OpenButton.TextColor3 = WHITE
OpenButton.TextSize = 24
OpenButton.Font = Enum.Font.GothamBold
OpenButton.Visible = false
OpenButton.ZIndex = 50
OpenButton.Parent = Gui

Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(1, 0)

OpenButton.Activated:Connect(function()
	Panel.Visible = true
	OpenButton.Visible = false
end)

--==================================================
-- DRAG SUPPORT: PC + MOBILE
--==================================================

local dragging = false
local dragStart
local startPosition

local function StartDrag(input)

	dragging = true
	dragStart = input.Position
	startPosition = Panel.Position

	input.Changed:Connect(function()
		if input.UserInputState == Enum.UserInputState.End then
			dragging = false
		end
	end)
end

local function UpdateDrag(input)

	if not dragging then
		return
	end

	local delta = input.Position - dragStart

	Panel.Position = UDim2.new(
		startPosition.X.Scale,
		startPosition.X.Offset + delta.X,
		startPosition.Y.Scale,
		startPosition.Y.Offset + delta.Y
	)
end

Title.InputBegan:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		StartDrag(input)
	end
end)

UserInputService.InputChanged:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then

		UpdateDrag(input)
	end
end)

--==================================================
-- MOBILE RESIZE
--==================================================

local function UpdatePanelSize()

	local Camera = workspace.CurrentCamera

	if not Camera then
		return
	end

	local viewport = Camera.ViewportSize

	if viewport.X < 500 then
		Panel.Size = UDim2.fromOffset(
			math.min(300, viewport.X - 30),
			380
		)

		Panel.Position = UDim2.new(
			0.5,
			-Panel.Size.X.Offset / 2,
			0.5,
			-190
		)
	else
		Panel.Size = UDim2.fromOffset(330, 390)
	end
end

UpdatePanelSize()

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(
		UpdatePanelSize
	)
end

--==================================================
-- START
--==================================================

UpdateFOV()

print("Dark Aim UI loaded successfully.")
print("FOV Circle:", Settings.FOV)