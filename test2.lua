-- Vyrox-style developer/debug menu
-- Roblox Studio / your own game

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer

local Settings = {
    SilentAim = false,
    AimAssist = false,
    Triggerbot = false,

    ShowFOV = false,
    TeamCheck = true,
    WallCheck = false,
    HitPart = "Head",

    NoRecoil = false,
    NoSpread = false,

    EnemyESP = false,
    TeamESP = false,
    DummyESP = false
}

local gui = Instance.new("ScreenGui")
gui.Name = "VyroxDeveloperMenu"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Main window
local main = Instance.new("Frame")
main.Size = UDim2.fromScale(0.82, 0.78)
main.Position = UDim2.fromScale(0.09, 0.11)
main.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = main

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 200, 0, 55)
title.BackgroundTransparency = 1
title.Text = "Vyrox"
title.TextColor3 = Color3.fromRGB(235, 235, 235)
title.TextSize = 24
title.Font = Enum.Font.Gotham
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local titlePadding = Instance.new("UIPadding")
titlePadding.PaddingLeft = UDim.new(0, 20)
titlePadding.Parent = title

-- Close button
local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(45, 40)
close.Position = UDim2.new(1, -55, 0, 8)
close.Text = "X"
close.TextSize = 18
close.TextColor3 = Color3.new(1,1,1)
close.BackgroundColor3 = Color3.fromRGB(30,30,35)
close.Parent = main

close.MouseButton1Click:Connect(function()
    gui.Enabled = false
end)

-- Left navigation
local nav = Instance.new("Frame")
nav.Size = UDim2.new(0, 180, 1, -55)
nav.Position = UDim2.fromOffset(0, 55)
nav.BackgroundColor3 = Color3.fromRGB(10,10,12)
nav.BorderSizePixel = 0
nav.Parent = main

local navLayout = Instance.new("UIListLayout")
navLayout.Padding = UDim.new(0, 5)
navLayout.Parent = nav

local function navButton(text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 55)
    b.Text = text
    b.TextSize = 17
    b.TextColor3 = Color3.fromRGB(180,180,185)
    b.BackgroundColor3 = Color3.fromRGB(15,20,30)
    b.BorderSizePixel = 0
    b.Parent = nav
    return b
end

local mainButton = navButton("Main")
local settingsButton = navButton("Settings")

-- Content
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -195, 1, -65)
content.Position = UDim2.fromOffset(190, 60)
content.BackgroundTransparency = 1
content.Parent = main

-- Search
local search = Instance.new("TextBox")
search.Size = UDim2.new(1, -10, 0, 45)
search.PlaceholderText = "Search"
search.Text = ""
search.TextSize = 17
search.TextColor3 = Color3.new(1,1,1)
search.PlaceholderColor3 = Color3.fromRGB(120,120,120)
search.BackgroundColor3 = Color3.fromRGB(15,22,35)
search.BorderSizePixel = 0
search.Parent = content

local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 6)
searchCorner.Parent = search

local body = Instance.new("ScrollingFrame")
body.Size = UDim2.new(1, -10, 1, -55)
body.Position = UDim2.fromOffset(0, 55)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 5
body.Parent = content

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.Parent = body

local function section(name)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -5, 0, 55)
    frame.BackgroundColor3 = Color3.fromRGB(12,12,14)
    frame.BorderSizePixel = 0
    frame.Parent = body

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.fromOffset(10, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(230,230,230)
    label.TextSize = 18
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    return frame
end

local function toggle(name, key)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -5, 0, 45)
    frame.BackgroundColor3 = Color3.fromRGB(9,9,11)
    frame.BorderSizePixel = 0
    frame.Parent = body

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -75, 1, 0)
    label.Position = UDim2.fromOffset(12,0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(190,190,195)
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(48,26)
    button.Position = UDim2.new(1,-60,0.5,-13)
    button.Text = ""
    button.BorderSizePixel = 0
    button.Parent = frame

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(20,20)
    knob.Position = UDim2.fromOffset(3,3)
    knob.BackgroundColor3 = Color3.fromRGB(240,240,240)
    knob.Parent = button

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1,0)
    knobCorner.Parent = knob

    local function update()
        if Settings[key] then
            button.BackgroundColor3 = Color3.fromRGB(20,130,220)
            knob.Position = UDim2.new(1,-23,0,3)
        else
            button.BackgroundColor3 = Color3.fromRGB(35,45,55)
            knob.Position = UDim2.fromOffset(3,3)
        end
    end

    button.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        update()
    end)

    update()
end

local function dropdown(name, key, options)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -5, 0, 45)
    frame.BackgroundColor3 = Color3.fromRGB(9,9,11)
    frame.BorderSizePixel = 0
    frame.Parent = body

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5,0,1,0)
    label.Position = UDim2.fromOffset(12,0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(190,190,195)
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0,160,0,34)
    button.Position = UDim2.new(1,-170,0.5,-17)
    button.Text = Settings[key]
    button.TextSize = 15
    button.TextColor3 = Color3.fromRGB(220,220,220)
    button.BackgroundColor3 = Color3.fromRGB(15,25,40)
    button.BorderSizePixel = 0
    button.Parent = frame

    local index = 1

    button.MouseButton1Click:Connect(function()
        index += 1

        if index > #options then
            index = 1
        end

        Settings[key] = options[index]
        button.Text = options[index]
    end)
end

-- Sections
section("Combat")
toggle("Silent Aim", "SilentAim")
toggle("Aim Assist", "AimAssist")
toggle("Triggerbot", "Triggerbot")

section("Config")
toggle("Show FOV", "ShowFOV")
toggle("Team Check", "TeamCheck")
toggle("Wall Check", "WallCheck")
dropdown("Hit Part", "HitPart", {
    "Head",
    "Torso",
    "HumanoidRootPart"
})

section("Gun Mods")
toggle("No Recoil", "NoRecoil")
toggle("No Bullet Spread", "NoSpread")

section("Visual")
toggle("Enemy ESP", "EnemyESP")
toggle("Team ESP", "TeamESP")
toggle("Training Dummy ESP", "DummyESP")

section("Extra")

local discord = Instance.new("TextButton")
discord.Size = UDim2.new(1,-5,0,45)
discord.Text = "Join Discord"
discord.TextSize = 16
discord.TextColor3 = Color3.fromRGB(180,190,205)
discord.BackgroundColor3 = Color3.fromRGB(15,30,50)
discord.BorderSizePixel = 0
discord.Parent = body

-- Search filtering
search:GetPropertyChangedSignal("Text"):Connect(function()
    local query = search.Text:lower()

    for _, object in ipairs(body:GetChildren()) do
        if object:IsA("Frame") then
            local label = object:FindFirstChildWhichIsA("TextLabel")

            if label then
                object.Visible =
                    query == "" or
                    label.Text:lower():find(query, 1, true) ~= nil
            end
        end
    end
end)

-- Mobile-friendly scaling
local scale = Instance.new("UIScale")
scale.Scale = 1
scale.Parent = main

local function updateScale()
    local viewport = workspace.CurrentCamera.ViewportSize

    if viewport.X < 700 then
        scale.Scale = 0.78
    else
        scale.Scale = 1
    end
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
updateScale()

print("Vyrox developer menu loaded.")