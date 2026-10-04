--// PRIVATE AIM ASSIST TEST
--// For your own Roblox Studio experience

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- SETTINGS
--==================================================

local Settings = {
    AimAssist = false,
    TargetLock = false,
    ESP = false,
    WallCheck = true,
    TeamCheck = true,

    HitPart = "Random",

    FOVEnabled = true,
    FOV = 75,

    Smoothness = 50,
}

--==================================================
-- GUI
--==================================================

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Gui = Instance.new("ScreenGui")
Gui.Name = "PrivateAimAssist"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = PlayerGui

-- Main panel
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 300, 0, 430)
Main.Position = UDim2.new(0, 20, 0.5, -215)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Main.BorderSizePixel = 0
Main.Parent = Gui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Main

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 0, 45)
Title.Position = UDim2.new(0, 15, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "AIM ASSIST"
Title.TextColor3 = Color3.fromRGB(230, 230, 230)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

-- Close button
local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 35, 0, 35)
Close.Position = UDim2.new(1, -43, 0, 10)
Close.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.TextSize = 24
Close.Font = Enum.Font.GothamBold
Close.Parent = Main

Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 8)

-- Open button
local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.new(0, 55, 0, 55)
OpenButton.Position = UDim2.new(0, 20, 0.5, -27)
OpenButton.BackgroundColor3 = Color3.fromRGB(25, 130, 255)
OpenButton.Text = "☰"
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.TextSize = 25
OpenButton.Font = Enum.Font.GothamBold
OpenButton.Visible = false
OpenButton.Parent = Gui

Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(1, 0)

--==================================================
-- DRAGGING
--==================================================

local dragging = false
local dragStart
local startPosition

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

Close.MouseButton1Click:Connect(function()
    Main.Visible = false
    OpenButton.Visible = true
end)

OpenButton.MouseButton1Click:Connect(function()
    Main.Visible = true
    OpenButton.Visible = false
end)

--==================================================
-- UI HELPERS
--==================================================

local Y = 55

local function CreateToggle(name, default, callback)

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -30, 0, 42)
    Button.Position = UDim2.new(0, 15, 0, Y)
    Button.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    Button.TextColor3 = Color3.fromRGB(220, 220, 220)
    Button.TextSize = 14
    Button.Font = Enum.Font.GothamMedium
    Button.Parent = Main

    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 7)

    local State = default

    local function Update()
        if State then
            Button.Text = name .. "    [ON]"
            Button.BackgroundColor3 = Color3.fromRGB(35, 105, 170)
        else
            Button.Text = name .. "    [OFF]"
            Button.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
        end
    end

    Button.MouseButton1Click:Connect(function()
        State = not State
        Update()
        callback(State)
    end)

    Update()

    Y = Y + 48

    return Button
end

local function CreateCycle(name, values, current, callback)

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -30, 0, 42)
    Button.Position = UDim2.new(0, 15, 0, Y)
    Button.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    Button.TextColor3 = Color3.fromRGB(220, 220, 220)
    Button.TextSize = 14
    Button.Font = Enum.Font.GothamMedium
    Button.Parent = Main

    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 7)

    local index = table.find(values, current) or 1

    local function Update()
        Button.Text = name .. ": " .. tostring(values[index])
    end

    Button.MouseButton1Click:Connect(function()
        index = index + 1

        if index > #values then
            index = 1
        end

        callback(values[index])
        Update()
    end)

    Update()

    Y = Y + 48

    return Button
end

--==================================================
-- FEATURES
--==================================================

CreateToggle("Aim Assist", Settings.AimAssist, function(v)
    Settings.AimAssist = v
end)

CreateToggle("Target Lock", Settings.TargetLock, function(v)
    Settings.TargetLock = v
end)

CreateToggle("ESP", Settings.ESP, function(v)
    Settings.ESP = v
end)

CreateToggle("Wall Check", Settings.WallCheck, function(v)
    Settings.WallCheck = v
end)

CreateToggle("Team Check", Settings.TeamCheck, function(v)
    Settings.TeamCheck = v
end)

CreateCycle(
    "Hit Part",
    {"Random", "Head", "Body"},
    Settings.HitPart,
    function(v)
        Settings.HitPart = v
    end
)

CreateToggle("FOV Circle", Settings.FOVEnabled, function(v)
    Settings.FOVEnabled = v
end)

--==================================================
-- FOV SIZE
--==================================================

local FOVButton = Instance.new("TextButton")
FOVButton.Size = UDim2.new(1, -30, 0, 42)
FOVButton.Position = UDim2.new(0, 15, 0, Y)
FOVButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
FOVButton.TextColor3 = Color3.fromRGB(220, 220, 220)
FOVButton.TextSize = 14
FOVButton.Font = Enum.Font.GothamMedium
FOVButton.Parent = Main

Instance.new("UICorner", FOVButton).CornerRadius = UDim.new(0, 7)

FOVButton.Text = "FOV Size: " .. Settings.FOV

FOVButton.MouseButton1Click:Connect(function()

    Settings.FOV = Settings.FOV + 10

    if Settings.FOV > 100 then
        Settings.FOV = 50
    end

    FOVButton.Text = "FOV Size: " .. Settings.FOV
end)

Y = Y + 48

--==================================================
-- SMOOTHNESS
--==================================================

local SmoothButton = Instance.new("TextButton")
SmoothButton.Size = UDim2.new(1, -30, 0, 42)
SmoothButton.Position = UDim2.new(0, 15, 0, Y)
SmoothButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
SmoothButton.TextColor3 = Color3.fromRGB(220, 220, 220)
SmoothButton.TextSize