-- Delta-executor aimlock: locks camera onto nearest valid player, R15/R6, toggle GUI + keybind.

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Executor-safe local player wait (never assume it's ready)
local localPlayer
repeat
    localPlayer = Players.LocalPlayer
    task.wait(0.1)
until localPlayer

local camera = workspace.CurrentCamera

-- Persistent state across re-executes
getgenv().AimlockConfig = getgenv().AimlockConfig or {
    enabled = false,
    key = Enum.KeyCode.RightShift,
    lerp = 1,               -- 1 = snap, lower = smooth
    mode = "nearest",       -- "nearest" or "crosshair"
    teamCheck = false,      -- skip same-team players
}
local Config = getgenv().AimlockConfig

-- Pick a hidden GUI container (Delta supports gethui)
local function getGuiParent()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    if game:GetService("CoreGui") then
        return game:GetService("CoreGui")
    end
    return localPlayer:WaitForChild("PlayerGui")
end

local guiParent = getGuiParent()

-- Destroy prior instance so re-executes are clean
local existing = guiParent:FindFirstChild("AimlockGui")
if existing then existing:Destroy() end

-- Build ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimlockGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999
screenGui.Enabled = true
screenGui.Parent = guiParent

-- Main frame
local frame = Instance.new("Frame")
frame.Name = "Panel"
frame.Size = UDim2.new(0, 190, 0, 70)
frame.Position = UDim2.new(0, 20, 0.5, -35)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true              -- let the user move it
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 10)
frameCorner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 80, 80)
stroke.Thickness = 1
stroke.Parent = frame

-- Toggle button
local button = Instance.new("TextButton")
button.Name = "ToggleButton"
button.Size = UDim2.new(1, -16, 1, -16)
button.Position = UDim2.new(0, 8, 0, 8)
button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.Text = "Aimlock: OFF"
button.AutoButtonColor = true
button.Active = true
button.Parent = frame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = button

-- Protect the GUI from game cleanup if the executor supports it
if syn and syn.protect_gui then
    pcall(syn.protect_gui, screenGui)
elseif protect_gui then
    pcall(protect_gui, screenGui)
end

print("[Aimlock] GUI parented to:", guiParent:GetFullName())

-- Character validity: alive, has Head, not dead
local function isCharacterValid(character)
    if not character or not character.Parent then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    if not character:FindFirstChild("Head") then return false end
    return true
end

-- Aim point resolver covering R15 and R6
local function getAimPoint(character)
    if not character then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.RootPart then
        return humanoid.RootPart.Position
    end
    local r15 = character:FindFirstChild("UpperTorso") or character:FindFirstChild("LowerTorso")
    if r15 then return r15.Position end
    local torso = character:FindFirstChild("Torso")
    if torso then return torso.Position end
    local head = character:FindFirstChild("Head")
    if head then return head.Position end
    return nil
end

-- Target selection
local function pickTarget()
    local myChar = localPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local myTeam = localPlayer.Team
    local best, bestScore = nil, math.huge

    if Config.mode == "crosshair" then
        -- Score by angle to the camera's look direction (smaller = closer to crosshair)
        local camLook = camera.CFrame.LookVector
        local camPos = camera.CFrame.Position

        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= localPlayer and isCharacterValid(other.Character) then
                if Config.teamCheck and other.Team == myTeam then continue end
                local aimPos = getAimPoint(other.Character)
                if aimPos then
                    local dir = (aimPos - camPos)
                    if dir.Magnitude > 0 then
                        local dot = camLook:Dot(dir.Unit)
                        local score = -dot  -- higher dot = better
                        if score < bestScore then
                            bestScore = score
                            best = other.Character
                        end
                    end
                end
            end
        end
    else
        -- Nearest to local player
        local myPos = myRoot.Position
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= localPlayer and isCharacterValid(other.Character) then
                if Config.teamCheck and other.Team == myTeam then continue end
                local root = other.Character:FindFirstChild("HumanoidRootPart")
                    or other.Character:FindFirstChild("Torso")
                    or other.Character:FindFirstChild("Head")
                if root then
                    local dist = (root.Position - myPos).Magnitude
                    if dist < bestScore then
                        bestScore = dist
                        best = other.Character
                    end
                end
            end
        end
    end

    return best
end

-- UI state sync
local function refreshButton()
    if Config.enabled then
        button.Text = "Aimlock: ON  [" .. Config.key.Name .. "]"
        button.BackgroundColor3 = Color3.fromRGB(55, 140, 55)
    else
        button.Text = "Aimlock: OFF  [" .. Config.key.Name .. "]"
        button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    end
end

-- Toggle handler
local function setEnabled(state)
    Config.enabled = state
    if not state then
        getgenv().AimlockTarget = nil
    end
    refreshButton()
    print("[Aimlock] Enabled =", state)
end

refreshButton()

-- Button click
button.Activated:Connect(function()
    setEnabled(not Config.enabled)
end)

-- Keybind toggle
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Config.key then
        setEnabled(not Config.enabled)
    end
end)

-- Shared target reference for the render loop
getgenv().AimlockTarget = nil

-- Retarget on a slow loop to survive spawns/despawns
task.spawn(function()
    while task.wait(0.2) do
        if Config.enabled then
            getgenv().AimlockTarget = pickTarget()
        end
    end
end)

-- Per-frame camera lock
RunService.RenderStepped:Connect(function()
    if not Config.enabled then return end

    local target = getgenv().AimlockTarget
    if not target or not isCharacterValid(target) then
        target = pickTarget()
        getgenv().AimlockTarget = target
        if not target then return end
    end

    local aimPos = getAimPoint(target)
    if not aimPos then return end

    local camPos = camera.CFrame.Position
    local lookCF = CFrame.lookAt(camPos, aimPos)

    if Config.lerp >= 1 then
        camera.CFrame = lookCF
    else
        camera.CFrame = camera.CFrame:Lerp(lookCF, Config.lerp)
    end
end)

print("[Aimlock] Loaded. Mode =", Config.mode, "| Key =", Config.key.Name)