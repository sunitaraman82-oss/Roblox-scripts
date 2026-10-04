--// AIM ASSIST UI
--// Roblox Studio / Your Own Experience
--// Mobile + PC
--// UI + FOV system

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local Settings = {
    Enabled = false,
    TargetLock = true,
    WallCheck = true,
    TeamCheck = true,

    FOV = 250,
    Smoothness = 85,
    HitPart = "Head"
}

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "AimAssistUI"
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
FOVCircle.Size = UDim2.fromOffset(Settings.FOV * 2, Settings.FOV * 2)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Parent = Gui

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = FOVCircle

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Thickness = 2
CircleStroke.Color = Color3.fromRGB(255, 255, 255)
CircleStroke.Transparency = 0.1
CircleStroke.Parent = FOVCircle

--==================================================
-- MAIN PANEL
--==================================================

local Panel = Instance.new("Frame")
Panel.Size = UDim2.fromOffset(285, 390)
Panel.Position = UDim2.new(0, 20, 0.5, -195)
Panel.BackgroundColor3 = Color3.fromRGB(22, 20, 27)
Panel.BorderSizePixel = 0
Panel.Parent = Gui

Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 14)

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Color = Color3.fromRGB(80, 75, 90)
PanelStroke.Transparency = 0.2
PanelStroke.Parent = Panel

--==================================================
-- TITLE
--==================================================

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 0, 45)
Title.Position = UDim2.fromOffset(15, 5)
Title.BackgroundTransparency = 1
Title.Text = "AimAssist"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 19
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Panel

--==================================================
-- CLOSE
--==================================================

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(35, 35)
Close.Position = UDim2.new(1, -45, 0, 10)
Close.BackgroundColor3 = Color3.fromRGB(45, 42, 52)
Close.Text = "×"
Close.TextColor3 = Color3.new(1, 1, 1)
Close.TextSize = 23
Close.Font = Enum.Font.GothamBold
Close.Parent = Panel

Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 8)

--==================================================
-- OPEN
--==================================================

local Open = Instance.new("TextButton")
Open.Size = UDim2.fromOffset(52, 52)
Open.Position = UDim2.fromOffset(20, 20)
Open.BackgroundColor3 = Color3.fromRGB(30, 28, 36)
Open.Text = "☰"
Open.TextColor3 = Color3.new(1, 1, 1)
Open.TextSize = 23
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
-- UI HELPERS
--==================================================

local Y = 58

local function CreateButton(text)
    local Button = Instance.new("TextButton")

    Button.Size = UDim2.new(1, -30, 0, 40)
    Button.Position = UDim2.fromOffset(15, Y)
    Button.BackgroundColor3 = Color3.fromRGB(40, 37, 47)
    Button.BorderSizePixel = 0
    Button.Text = text
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.TextSize = 13
    Button.Font = Enum.Font.GothamSemibold
    Button.Parent = Panel

    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 9)

    Y += 47

    return Button
end

local function CreateLabel(text)
    local Label = Instance.new("TextLabel")

    Label.Size = UDim2.new(1, -30, 0, 22)
    Label.Position = UDim2.fromOffset(15, Y)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(205, 202, 215)
    Label.TextSize = 12
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Panel

    Y += 26

    return Label
end

--==================================================
-- AIM ASSIST
--==================================================

local AimButton = CreateButton("Aim Assist : OFF")

local function UpdateAim()
    if Settings.Enabled then
        AimButton.Text = "Aim Assist : ON"
        AimButton.BackgroundColor3 = Color3.fromRGB(45, 135, 75)
    else
        AimButton.Text = "Aim Assist : OFF"
        AimButton.BackgroundColor3 = Color3.fromRGB(40, 37, 47)
    end
end

AimButton.Activated:Connect(function()
    Settings.Enabled = not Settings.Enabled
    UpdateAim()
end)

--==================================================
-- TARGET LOCK
--==================================================

local LockButton = CreateButton("Target Lock : ON")

LockButton.Activated:Connect(function()
    Settings.TargetLock = not Settings.TargetLock

    LockButton.Text =
        "Target Lock : " ..
        (Settings.TargetLock and "ON" or "OFF")
end)

--==================================================
-- WALL CHECK
--==================================================

local WallButton = CreateButton("Wall Check : ON")

WallButton.Activated:Connect(function()
    Settings.WallCheck = not Settings.WallCheck

    WallButton.Text =
        "Wall Check : " ..
        (Settings.WallCheck and "ON" or "OFF")
end)

--==================================================
-- TEAM CHECK
--==================================================

local TeamButton = CreateButton("Team Check : ON")

TeamButton.Activated:Connect(function()
    Settings.TeamCheck = not Settings.TeamCheck

    TeamButton.Text =
        "Team Check : " ..
        (Settings.TeamCheck and "ON" or "OFF")
end)

--==================================================
-- HIT PART
--==================================================

local HitParts = {
    "Head",
    "Torso",
    "HumanoidRootPart"
}

local HitIndex = 1

local HitButton = CreateButton("Hit Part : Head")

HitButton.Activated:Connect(function()
    HitIndex += 1

    if HitIndex > #HitParts then
        HitIndex = 1
    end

    Settings.HitPart = HitParts[HitIndex]
    HitButton.Text = "Hit Part : " .. Settings.HitPart
end)

--==================================================
-- FOV
--==================================================

local FOVLabel = CreateLabel("FOV : " .. Settings.FOV)

local FOVBar = Instance.new("Frame")
FOVBar.Size = UDim2.new(1, -30, 0, 8)
FOVBar.Position = UDim2.fromOffset(15, Y)
FOVBar.BackgroundColor3 = Color3.fromRGB(55, 52, 63)
FOVBar.BorderSizePixel = 0
FOVBar.Parent = Panel

Instance.new("UICorner", FOVBar).CornerRadius = UDim.new(1, 0)

local FOVFill = Instance.new("Frame")
FOVFill.Size = UDim2.new(Settings.FOV / 500, 0, 1, 0)
FOVFill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
FOVFill.BorderSizePixel = 0
FOVFill.Parent = FOVBar

Instance.new("UICorner", FOVFill).CornerRadius = UDim.new(1, 0)

Y += 25

--==================================================
-- SMOOTHNESS
--==================================================

local SmoothLabel = CreateLabel(
    "Smoothness : " .. Settings.Smoothness
)

local SmoothBar = Instance.new("Frame")
SmoothBar.Size = UDim2.new(1, -30, 0, 8)
SmoothBar.Position = UDim2.fromOffset(15, Y)
SmoothBar.BackgroundColor3 = Color3.fromRGB(55, 52, 63)
SmoothBar.BorderSizePixel = 0
SmoothBar.Parent = Panel

Instance.new("UICorner", SmoothBar).CornerRadius = UDim.new(1, 0)

local SmoothFill = Instance.new("Frame")
SmoothFill.Size = UDim2.new(
    Settings.Smoothness / 100,
    0,
    1,
    0
)
SmoothFill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
SmoothFill.BorderSizePixel = 0
SmoothFill.Parent = SmoothBar

Instance.new("UICorner", SmoothFill).CornerRadius = UDim.new(1, 0)

--==================================================
-- SLIDER
--==================================================

local function MakeSlider(bar, fill, minimum, maximum, callback)

    local dragging = false

    local function Update(x)

        local percent = math.clamp(
            (x - bar.AbsolutePosition.X)
            / bar.AbsoluteSize.X,
            0,
            1
        )

        local value = math.floor(
            minimum + ((maximum - minimum) * percent)
        )

        fill.Size = UDim2.new(
            percent,
            0,
            1,
            0
        )

        callback(value)
    end

    bar.InputBegan:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            Update(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)

        if not dragging then
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

            dragging = false
        end
    end)
end

MakeSlider(
    FOVBar,
    FOVFill,
    50,
    500,
    function(value)
        Settings.FOV = value
        FOVLabel.Text = "FOV : " .. value

        FOVCircle.Size =
            UDim2.fromOffset(value * 2, value * 2)
    end
)

MakeSlider(
    SmoothBar,
    SmoothFill,
    10,
    100,
    function(value)
        Settings.Smoothness = value
        SmoothLabel.Text =
            "Smoothness : " .. value
    end
)

--==================================================
-- DRAG PANEL
--==================================================

local draggingPanel = false
local dragStart
local panelStart

Title.InputBegan:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        draggingPanel = true
        dragStart = input.Position
        panelStart = Panel.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)

    if not draggingPanel then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

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

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        draggingPanel = false
    end
end)

--==================================================
-- START
--==================================================

FOVCircle.Visible = true
Panel.Visible = true
Open.Visible = false

print("AimAssist UI loaded successfully.")