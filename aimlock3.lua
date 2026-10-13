
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Camera = game:GetService("Workspace"):WaitForChild("Camera")

local aimbotSettings = {
    Smoothness = 50,
    HitChance = 90,
    WallCheck = true,
    TargetPart = "head"  -- Options: "random", "head", "body"
}

local screenGui = Instance.new("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"))
local toggleButton = Instance.new("TextButton")

toggleButton.Size = UDim2.new(0, 100, 0, 50)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.Text = "Toggle Aimbot"

local aimbotEnabled = false
local fovCircle = Instance.new("Part", workspace)
fovCircle.Shape = Enum.PartType.Ball
fovCircle.Size = Vector3.new(10, 1, 10)
fovCircle.Transparency = 0.5
fovCircle.Color = Color3.new(1, 0, 0)
fovCircle.CanCollide = false

local function toggleAimbot()
    aimbotEnabled = not aimbotEnabled
    toggleButton.Text = aimbotEnabled and "Aimbot On" or "Aimbot Off"

    if not aimbotEnabled then
        fovCircle.Position = Vector3.new(0, -10, 0) -- Hide circle upon closing UI
    else
        fovCircle.Position = Players.LocalPlayer.Character.HumanoidRootPart.Position
    end
end

toggleButton.MouseButton1Click:Connect(toggleAimbot)

toggleButton.Parent = screenGui

local function aimbot()
    while aimbotEnabled do
        local closestTarget, closestDistance = nil, math.huge

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer then
                local character = player.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local distance = (character.HumanoidRootPart.Position - Players.LocalPlayer.Character.HumanoidRootPart.Position).magnitude

                    if distance < closestDistance then
                        closestDistance = distance
                        closestTarget = character
                    end
                end
            end
        end

        if closestTarget then
            local targetPosition = closestTarget[aimbotSettings.TargetPart].Position
            local currentPosition = Players.LocalPlayer.Character.HumanoidRootPart.Position
            local direction = (targetPosition - currentPosition).unit

            -- Smoothness implementation
            local newPos = currentPosition + (direction * (1/aimbotSettings.Smoothness))
            Camera.CFrame = CFrame.new(newPos)
        end

        wait(aimbotSettings.HitChance / 100)
    end
end

-- Start aimbot loop
spawn(aimbot)