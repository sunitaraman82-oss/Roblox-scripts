-- LocalScript
-- Place in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Configuration
local CONFIG = {
    MaxRange = 80,                    -- Maximum target distance in studs
    Smoothing = 8,                    -- Higher = faster rotation; never instant
    AimPoint = "Head",                -- "Head" or rig fallback
    ToggleKey = Enum.KeyCode.E,
    UpdateRate = 60,                  -- Maximum update frequency
}

-- State
local enabled = false
local currentTarget = nil
local accumulator = 0

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TargetLockGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Name = "ToggleButton"
button.Size = UDim2.fromOffset(180, 44)
button.Position = UDim2.new(0, 20, 0.5, -22)
button.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
button.TextColor3 = Color3.new(1, 1, 1)
button.TextSize = 16
button.Font = Enum.Font.GothamBold
button.Text = "Target Lock: OFF"
button.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = button

local function updateButton()
    button.Text = enabled and "Target Lock: ON" or "Target Lock: OFF"
    button.BackgroundColor3 = enabled
        and Color3.fromRGB(35, 145, 85)
        or Color3.fromRGB(65, 65, 65)
end

local function setEnabled(state)
    enabled = state
    currentTarget = nil
    updateButton()
end

button.Activated:Connect(function()
    setEnabled(not enabled)
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == CONFIG.ToggleKey then
        setEnabled(not enabled)
    end
end)

-- Get a valid R6 or R15 character and its aim point.
local function getCharacterInfo(player)
    if player == LocalPlayer then
        return nil
    end

    local character = player.Character
    if not character then
        return nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return nil
    end

    local rigType = humanoid.RigType
    if rigType ~= Enum.HumanoidRigType.R6
        and rigType ~= Enum.HumanoidRigType.R15 then
        return nil
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then
        return nil
    end

    local aimPart

    if CONFIG.AimPoint == "Head" then
        aimPart = character:FindFirstChild("Head")
    end

    -- Fall back to the appropriate torso if Head is unavailable.
    if not aimPart then
        if rigType == Enum.HumanoidRigType.R6 then
            aimPart = character:FindFirstChild("Torso")
        else
            aimPart = character:FindFirstChild("UpperTorso")
        end
    end

    if not aimPart or not aimPart:IsA("BasePart") then
        return nil
    end

    return character, humanoid, root, aimPart
end

-- Find the nearest valid player character within range.
local function findNearestTarget(origin)
    local nearestPlayer = nil
    local nearestDistance = CONFIG.MaxRange

    for _, player in ipairs(Players:GetPlayers()) do
        local character, humanoid, root, aimPart =
            getCharacterInfo(player)

        if character and humanoid and root and aimPart then
            local distance = (root.Position - origin).Magnitude

            if distance <= nearestDistance then
                nearestDistance = distance
                nearestPlayer = player
            end
        end
    end

    return nearestPlayer
end

local function getAimPoint(player)
    local character, humanoid, root, aimPart =
        getCharacterInfo(player)

    if not character then
        return nil
    end

    local localCharacter = LocalPlayer.Character
    if not localCharacter then
        return nil
    end

    local localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
    if not localRoot then
        return nil
    end

    if (root.Position - localRoot.Position).Magnitude > CONFIG.MaxRange then
        return nil
    end

    return aimPart.Position
end

-- Smoothly rotate the local character toward the target.
RunService.RenderStepped:Connect(function(dt)
    if not enabled then
        currentTarget = nil
        return
    end

    accumulator += dt
    local interval = 1 / math.max(CONFIG.UpdateRate, 1)

    if accumulator < interval then
        return
    end

    dt = accumulator
    accumulator = 0

    local character = LocalPlayer.Character
    if not character then
        currentTarget = nil
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or humanoid.Health <= 0 or not root then
        currentTarget = nil
        return
    end

    -- Acquire or refresh the nearest valid target.
    local nearest = findNearestTarget(root.Position)
    currentTarget = nearest

    if not currentTarget then
        return
    end

    local aimPosition = getAimPoint(currentTarget)
    if not aimPosition then
        currentTarget = nil
        return
    end

    local origin = root.Position
    local flatTarget = Vector3.new(
        aimPosition.X,
        origin.Y,
        aimPosition.Z
    )

    -- Avoid invalid look-at CFrames when positions overlap.
    if (flatTarget - origin).Magnitude < 0.001 then
        return
    end

    local targetCFrame = CFrame.lookAt(origin, flatTarget)

    -- Exponential smoothing makes rotation independent of frame rate.
    local alpha = 1 - math.exp(-CONFIG.Smoothing * dt)
    root.CFrame = root.CFrame:Lerp(targetCFrame, alpha)
end)

-- Initialize UI state.
updateButton()