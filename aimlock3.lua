-- LocalScript
-- Place in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Configuration
local CONFIG = {
    MaxRange = 80,
    Smoothing = 8, -- Higher = faster turning, lower = smoother
    AimPoint = "Head",
    ToggleKey = Enum.KeyCode.E,
}

-- State
local enabled = false
local currentTarget = nil
local controlledCharacter = nil
local controlledHumanoid = nil
local originalAutoRotate = nil
local attachment = nil
local alignOrientation = nil

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "TargetLockGui"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Name = "ToggleButton"
button.Size = UDim2.fromOffset(190, 46)
button.Position = UDim2.new(0, 20, 0.5, -23)
button.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
button.TextColor3 = Color3.new(1, 1, 1)
button.TextSize = 16
button.Font = Enum.Font.GothamBold
button.Text = "Target Lock: OFF"
button.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = button

local function updateButton()
    button.Text = enabled and "Target Lock: ON" or "Target Lock: OFF"
    button.BackgroundColor3 = enabled
        and Color3.fromRGB(30, 145, 85)
        or Color3.fromRGB(65, 65, 65)
end

-- Restore the Humanoid's normal rotation behavior.
local function releaseTarget()
    currentTarget = nil

    if alignOrientation then
        alignOrientation.Enabled = false
    end

    if controlledHumanoid and controlledHumanoid.Parent
        and originalAutoRotate ~= nil then
        controlledHumanoid.AutoRotate = originalAutoRotate
    end

    controlledHumanoid = nil
    originalAutoRotate = nil
end

local function cleanupController()
    releaseTarget()

    if alignOrientation then
        alignOrientation:Destroy()
        alignOrientation = nil
    end

    if attachment then
        attachment:Destroy()
        attachment = nil
    end

    controlledCharacter = nil
end

local function setEnabled(state)
    enabled = state

    if not enabled then
        releaseTarget()
    end

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

-- Validate character, rig type, Humanoid, and aim part.
local function getTargetInfo(player)
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

    -- Fall back to the appropriate torso.
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

local function findNearestTarget(origin)
    local nearestPlayer = nil
    local nearestDistance = CONFIG.MaxRange

    for _, player in ipairs(Players:GetPlayers()) do
        local character, humanoid, root, aimPart =
            getTargetInfo(player)

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

-- Set up a physical orientation constraint for the current character.
local function setupController(character, humanoid, root)
    cleanupController()

    controlledCharacter = character
    controlledHumanoid = humanoid

    attachment = Instance.new("Attachment")
    attachment.Name = "TargetLockAttachment"
    attachment.Parent = root

    alignOrientation = Instance.new("AlignOrientation")
    alignOrientation.Name = "TargetLockOrientation"
    alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOrientation.Attachment0 = attachment
    alignOrientation.RigidityEnabled = false
    alignOrientation.Responsiveness = math.max(CONFIG.Smoothing, 0.1)
    alignOrientation.MaxTorque = 1000000
    alignOrientation.Enabled = false
    alignOrientation.Parent = root
end

-- Main update loop.
RunService.Heartbeat:Connect(function()
    if not enabled then
        return
    end

    local character = LocalPlayer.Character
    if not character then
        cleanupController()
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or humanoid.Health <= 0 or not root then
        cleanupController()
        return
    end

    -- Rebuild the controller after respawning.
    if controlledCharacter ~= character
        or not alignOrientation
        or not alignOrientation.Parent then

        setupController(character, humanoid, root)
    end

    -- Select the nearest eligible player every update.
    currentTarget = findNearestTarget(root.Position)

    if not currentTarget then
        releaseTarget()
        return
    end

    local targetCharacter, targetHumanoid, targetRoot, aimPart =
        getTargetInfo(currentTarget)

    if not targetCharacter or not targetHumanoid
        or not targetRoot or not aimPart then
        releaseTarget()
        return
    end

    if (targetRoot.Position - root.Position).Magnitude > CONFIG.MaxRange then
        releaseTarget()
        return
    end

    -- Remember the original setting before taking control.
    if controlledHumanoid ~= humanoid then
        releaseTarget()
        controlledHumanoid = humanoid
        originalAutoRotate = humanoid.AutoRotate
    elseif originalAutoRotate == nil then
        originalAutoRotate = humanoid.AutoRotate
    end

    humanoid.AutoRotate = false

    -- Rotate horizontally toward the target without changing position.
    local origin = root.Position
    local targetPosition = aimPart.Position

    local flatTarget = Vector3.new(
        targetPosition.X,
        origin.Y,
        targetPosition.Z
    )

    if (flatTarget - origin).Magnitude < 0.001 then
        return
    end

    alignOrientation.Responsiveness = math.max(CONFIG.Smoothing, 0.1)
    alignOrientation.CFrame = CFrame.lookAt(origin, flatTarget)
    alignOrientation.Enabled = true
end)

-- Clean up if the local player respawns.
LocalPlayer.CharacterAdded:Connect(function()
    cleanupController()
end)

-- Initial state.
updateButton()