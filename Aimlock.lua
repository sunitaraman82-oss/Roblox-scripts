--// Aim / Target System
--// For your own Roblox experience

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// Settings
local AimLock = false
local TargetLock = false
local AutoTarget = false

local FOV = 250
local TargetPart = "Head"

local CurrentTarget = nil

--// UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TargetSystemUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.fromOffset(230, 190)
Frame.Position = UDim2.new(0, 20, 0.5, -95)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BackgroundTransparency = 0.1
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "TARGET SYSTEM"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.Parent = Frame

local function createButton(text, y)
    local Button = Instance.new("TextButton")

    Button.Size = UDim2.new(1, -20, 0, 38)
    Button.Position = UDim2.new(0, 10, 0, y)
    Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.TextSize = 15
    Button.Font = Enum.Font.GothamSemibold
    Button.Text = text
    Button.AutoButtonColor = true
    Button.Parent = Frame

    local C = Instance.new("UICorner")
    C.CornerRadius = UDim.new(0, 8)
    C.Parent = Button

    return Button
end

local AimButton = createButton("Aim Lock: OFF", 40)
local TargetButton = createButton("Target Lock: OFF", 83)
local AutoButton = createButton("Auto Target: OFF", 126)

--// Find nearest valid player
local function GetNearestTarget()
    local Character = LocalPlayer.Character

    if not Character then
        return nil
    end

    local Root = Character:FindFirstChild("HumanoidRootPart")

    if not Root then
        return nil
    end

    local BestTarget = nil
    local BestDistance = FOV

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then

            local TargetCharacter = Player.Character
            if TargetCharacter then

                local Humanoid = TargetCharacter:FindFirstChildOfClass("Humanoid")
                local Part = TargetCharacter:FindFirstChild(TargetPart)

                if Humanoid and Part and Humanoid.Health > 0 then

                    local ScreenPosition, OnScreen =
                        Camera:WorldToViewportPoint(Part.Position)

                    if OnScreen then
                        local Center =
                            Vector2.new(
                                Camera.ViewportSize.X / 2,
                                Camera.ViewportSize.Y / 2
                            )

                        local Distance =
                            (Vector2.new(ScreenPosition.X, ScreenPosition.Y) - Center).Magnitude

                        if Distance < BestDistance then
                            BestDistance = Distance
                            BestTarget = Player
                        end
                    end
                end
            end
        end
    end

    return BestTarget
end

--// Aim camera toward target
local function AimAtTarget(Player)
    if not Player then
        return
    end

    local Character = Player.Character
    if not Character then
        return
    end

    local Part = Character:FindFirstChild(TargetPart)
    if not Part then
        return
    end

    Camera.CFrame = CFrame.lookAt(
        Camera.CFrame.Position,
        Part.Position
    )
end

--// Aim Lock
AimButton.MouseButton1Click:Connect(function()
    AimLock = not AimLock

    if AimLock then
        AimButton.Text = "Aim Lock: ON"
        AimButton.BackgroundColor3 = Color3.fromRGB(40, 130, 70)
    else
        AimButton.Text = "Aim Lock: OFF"
        AimButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    end
end)

--// Target Lock
TargetButton.MouseButton1Click:Connect(function()
    TargetLock = not TargetLock

    if TargetLock then
        TargetButton.Text = "Target Lock: ON"
        TargetButton.BackgroundColor3 = Color3.fromRGB(40, 130, 70)

        CurrentTarget = GetNearestTarget()
    else
        TargetButton.Text = "Target Lock: OFF"
        TargetButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)

        CurrentTarget = nil
    end
end)

--// Auto Target
AutoButton.MouseButton1Click:Connect(function()
    AutoTarget = not AutoTarget

    if AutoTarget then
        AutoButton.Text = "Auto Target: ON"
        AutoButton.BackgroundColor3 = Color3.fromRGB(40, 130, 70)
    else
        AutoButton.Text = "Auto Target: OFF"
        AutoButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)

        CurrentTarget = nil
    end
end)

--// Main loop
RunService.RenderStepped:Connect(function()

    -- Automatically find a target
    if AutoTarget then
        if not CurrentTarget
            or not CurrentTarget.Character
            or not CurrentTarget.Character:FindFirstChild(TargetPart) then

            CurrentTarget = GetNearestTarget()
        end
    end

    -- Target lock selects a target
    if TargetLock and not CurrentTarget then
        CurrentTarget = GetNearestTarget()
    end

    -- Aim toward target
    if AimLock and CurrentTarget then
        AimAtTarget(CurrentTarget)
    end
end)
