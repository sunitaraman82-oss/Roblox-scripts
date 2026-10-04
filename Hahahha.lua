--// TARGET SYSTEM
--// For your own Roblox experience

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- SETTINGS
--==================================================

local Settings = {
    AimLock = false,
    TargetLock = false,
    AutoTarget = false,

    TargetPart = "Head",

    -- Maximum distance in studs
    MaxDistance = 1000,

    -- Screen-space FOV
    FOV = 300,

    -- Higher = faster camera movement
    Smoothness = 0.18,

    -- Set true if teams should be ignored
    TeamCheck = true,
}

local CurrentTarget = nil

--==================================================
-- UI
--==================================================

local GUI = Instance.new("ScreenGui")
GUI.Name = "TargetSystem"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(425, 350)
Main.Position = UDim2.new(0, 80, 0.5, -175)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Main.BackgroundTransparency = 0.08
Main.BorderSizePixel = 0
Main.Parent = GUI

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 18)
MainCorner.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 65)
Title.BackgroundTransparency = 1
Title.Text = "TARGET SYSTEM"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.TextSize = 30
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

local function MakeButton(name, text, y)
    local Button = Instance.new("TextButton")

    Button.Name = name
    Button.Size = UDim2.new(1, -40, 0, 70)
    Button.Position = UDim2.new(0, 20, 0, y)

    Button.BackgroundColor3 = Color3.fromRGB(45,45,45)
    Button.TextColor3 = Color3.fromRGB(255,255,255)

    Button.Text = text
    Button.TextSize = 22
    Button.Font = Enum.Font.GothamMedium

    Button.AutoButtonColor = false
    Button.BorderSizePixel = 0

    Button.Parent = Main

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 14)
    Corner.Parent = Button

    return Button
end

local AimButton =
    MakeButton("AimLock", "Aim Lock: OFF", 75)

local TargetButton =
    MakeButton("TargetLock", "Target Lock: OFF", 155)

local AutoButton =
    MakeButton("AutoTarget", "Auto Target: OFF", 235)

--==================================================
-- BUTTON COLORS
--==================================================

local function SetButton(Button, Enabled, Name)
    if Enabled then
        Button.Text = Name .. ": ON"
        Button.BackgroundColor3 = Color3.fromRGB(40,150,75)
    else
        Button.Text = Name .. ": OFF"
        Button.BackgroundColor3 = Color3.fromRGB(45,45,45)
    end
end

--==================================================
-- TARGET VALIDATION
--==================================================

local function IsValidTarget(Player)

    if not Player then
        return false
    end

    if Player == LocalPlayer then
        return false
    end

    if Settings.TeamCheck then
        if LocalPlayer.Team ~= nil and Player.Team ~= nil then
            if LocalPlayer.Team == Player.Team then
                return false
            end
        end
    end

    local Character = Player.Character

    if not Character then
        return false
    end

    local Humanoid =
        Character:FindFirstChildOfClass("Humanoid")

    local Root =
        Character:FindFirstChild("HumanoidRootPart")

    local Head =
        Character:FindFirstChild(Settings.TargetPart)

    if not Humanoid or Humanoid.Health <= 0 then
        return false
    end

    if not Root or not Head then
        return false
    end

    local MyCharacter = LocalPlayer.Character

    if not MyCharacter then
        return false
    end

    local MyRoot =
        MyCharacter:FindFirstChild("HumanoidRootPart")

    if not MyRoot then
        return false
    end

    local Distance =
        (Root.Position - MyRoot.Position).Magnitude

    if Distance > Settings.MaxDistance then
        return false
    end

    return true
end

--==================================================
-- SCREEN / FOV TARGET SELECTION
--==================================================

local function GetBestTarget()

    local BestPlayer = nil
    local BestScore = math.huge

    local ScreenCenter = Vector2.new(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y / 2
    )

    for _, Player in ipairs(Players:GetPlayers()) do

        if IsValidTarget(Player) then

            local Character = Player.Character
            local Head =
                Character:FindFirstChild(Settings.TargetPart)

            local ScreenPosition, Visible =
                Camera:WorldToViewportPoint(Head.Position)

            if Visible and ScreenPosition.Z > 0 then

                local ScreenPoint = Vector2.new(
                    ScreenPosition.X,
                    ScreenPosition.Y
                )

                local ScreenDistance =
                    (ScreenPoint - ScreenCenter).Magnitude

                if ScreenDistance <= Settings.FOV then

                    -- Prefer targets closer to crosshair
                    if ScreenDistance < BestScore then
                        BestScore = ScreenDistance
                        BestPlayer = Player
                    end
                end
            end
        end
    end

    return BestPlayer
end

--==================================================
-- TARGET LOCK
--==================================================

local function UpdateTarget()

    if CurrentTarget and IsValidTarget(CurrentTarget) then
        return
    end

    CurrentTarget = GetBestTarget()
end

--==================================================
-- SMOOTH AIM
--==================================================

local function AimAtTarget(Player)

    if not IsValidTarget(Player) then
        return
    end

    local Character = Player.Character

    local Head =
        Character:FindFirstChild(Settings.TargetPart)

    if not Head then
        return
    end

    local CameraPosition =
        Camera.CFrame.Position

    local DesiredCFrame =
        CFrame.lookAt(
            CameraPosition,
            Head.Position
        )

    Camera.CFrame =
        Camera.CFrame:Lerp(
            DesiredCFrame,
            Settings.Smoothness
        )
end

--==================================================
-- AIM LOCK BUTTON
--==================================================

AimButton.Activated:Connect(function()

    Settings.AimLock =
        not Settings.AimLock

    SetButton(
        AimButton,
        Settings.AimLock,
        "Aim Lock"
    )

    if Settings.AimLock then
        UpdateTarget()
    end
end)

--==================================================
-- TARGET LOCK BUTTON
--==================================================

TargetButton.Activated:Connect(function()

    Settings.TargetLock =
        not Settings.TargetLock

    SetButton(
        TargetButton,
        Settings.TargetLock,
        "Target Lock"
    )

    if Settings.TargetLock then
        UpdateTarget()
    else
        CurrentTarget = nil
    end
end)

--==================================================
-- AUTO TARGET BUTTON
--==================================================

AutoButton.Activated:Connect(function()

    Settings.AutoTarget =
        not Settings.AutoTarget

    SetButton(
        AutoButton,
        Settings.AutoTarget,
        "Auto Target"
    )

    if Settings.AutoTarget then
        UpdateTarget()
    else
        if not Settings.TargetLock then
            CurrentTarget = nil
        end
    end
end)

--==================================================
-- MAIN LOOP
--==================================================

RunService.RenderStepped:Connect(function()

    -- Automatically find/reacquire target
    if Settings.AutoTarget then
        UpdateTarget()
    end

    -- Target lock
    if Settings.TargetLock then

        if not CurrentTarget
            or not IsValidTarget(CurrentTarget) then

            CurrentTarget = GetBestTarget()
        end
    end

    -- Aim
    if Settings.AimLock and CurrentTarget then
        AimAtTarget(CurrentTarget)
    end
end)

--==================================================
-- CLEAR TARGET WHEN PLAYER LEAVES
--==================================================

Players.PlayerRemoving:Connect(function(Player)

    if CurrentTarget == Player then
        CurrentTarget = nil
    end
end)

--==================================================
-- OPTIONAL KEYBOARD SUPPORT
--==================================================

UserInputService.InputBegan:Connect(function(Input, Processed)

    if Processed then
        return
    end

    if Input.KeyCode == Enum.KeyCode.Q then

        Settings.AimLock =
            not Settings.AimLock

        SetButton(
            AimButton,
            Settings.AimLock,
            "Aim Lock"
        )

        if Settings.AimLock then
            UpdateTarget()
        end
    end

    if Input.KeyCode == Enum.KeyCode.T then

        Settings.TargetLock =
            not Settings.TargetLock

        SetButton(
            TargetButton,
            Settings.TargetLock,
            "Target Lock"
        )

        if Settings.TargetLock then
            UpdateTarget()
        else
            CurrentTarget = nil
        end
    end

    if Input.KeyCode == Enum.KeyCode.Y then

        Settings.AutoTarget =
            not Settings.AutoTarget

        SetButton(
            AutoButton,
            Settings.AutoTarget,
            "Auto Target"
        )
    end
end)
