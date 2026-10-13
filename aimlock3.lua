-- Mobile-first aimlock: big touch button, drag-friendly panel, R15/R6, nil-safe.

print("[Aimlock] script start")

-- Services
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Local player
local localPlayer = Players.LocalPlayer
if not localPlayer then
    repeat task.wait(0.1) until Players.LocalPlayer
    localPlayer = Players.LocalPlayer
end

-- Camera
local camera = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera then camera = workspace.CurrentCamera end
end)
if not camera then
    repeat task.wait(0.1) until workspace.CurrentCamera
    camera = workspace.CurrentCamera
end

-- Config (persists across re-executes)
getgenv().AimlockConfig = getgenv().AimlockConfig or {
    enabled = false,
    lerp    = 1,
    mode    = "nearest",
}
local Config = getgenv().AimlockConfig
getgenv().AimlockTarget = nil

-- Hidden GUI parent (Delta-safe)
local guiParent
do
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then
        guiParent = hui
    else
        guiParent = game:GetService("CoreGui") or localPlayer:WaitForChild("PlayerGui", 10)
    end
end

-- Cleanup old
pcall(function()
    local old = guiParent:FindFirstChild("AimlockGui")
    if old then old:Destroy() end
end)

-- ScreenGui
local screenGui          = Instance.new("ScreenGui")
screenGui.Name           = "AimlockGui"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder   = 999
pcall(function()
    if syn and syn.protect_gui then syn.protect_gui(screenGui)
    elseif protect_gui then protect_gui(screenGui) end
end)
screenGui.Parent = guiParent

-- Big touch-friendly button (mobile thumb sized)
local button                = Instance.new("TextButton")
button.Name                 = "ToggleButton"
button.Size                 = UDim2.new(0, 140, 0, 56)          -- bigger touch target
button.Position             = UDim2.new(0, 20, 0.5, -28)
button.BackgroundColor3     = Color3.fromRGB(40, 40, 40)
button.TextColor3           = Color3.fromRGB(255, 255, 255)
button.TextScaled           = true
button.Font                 = Enum.Font.GothamBold
button.Text                 = "AIMLOCK: OFF"
button.AutoButtonColor      = false
button.Active               = true
button.Parent               = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = button

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(90, 90, 90)
stroke.Thickness = 2
stroke.Parent = button

-- Manual touch drag (mobile-safe, no deprecated .Draggable)
do
    local dragging, dragStart, startPos
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = button.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            button.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- Helpers
local function isCharacterValid(character)
    if not character or not character.Parent then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    if not character:FindFirstChild("Head") then return false end
    return true
end

local function getAimPoint(character)
    if not character then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.RootPart then
        return humanoid.RootPart.Position
    end
    local part = character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("LowerTorso")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("Head")
    return part and part.Position or nil
end

local function pickTarget()
    local myChar = localPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local myPos = myRoot.Position
    local best, bestScore = nil, math.huge

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= localPlayer then
            local char = other.Character
            if isCharacterValid(char) then
                local aimPos = getAimPoint(char)
                if aimPos then
                    local dist = (aimPos - myPos).Magnitude
                    if dist < bestScore then
                        bestScore, best = dist, char
                    end
                end
            end
        end
    end

    return best
end

-- UI refresh
local function refreshButton()
    if Config.enabled then
        button.Text             = "AIMLOCK: ON"
        button.BackgroundColor3 = Color3.fromRGB(46, 160, 67)
        stroke.Color            = Color3.fromRGB(120, 220, 140)
    else
        button.Text             = "AIMLOCK: OFF"
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        stroke.Color            = Color3.fromRGB(90, 90, 90)
    end
end

local function setEnabled(state)
    Config.enabled = state
    if not state then
        getgenv().AimlockTarget = nil
    end
    refreshButton()
    print("[Aimlock] Enabled =", state)
end

refreshButton()

-- Tap to toggle (primary mobile control)
button.Activated:Connect(function()
    setEnabled(not Config.enabled)
end)

-- Optional keybind (still works if a keyboard is connected)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        setEnabled(not Config.enabled)
    end
end)

-- Retarget loop
task.spawn(function()
    while task.wait(0.2) do
        if Config.enabled then
            getgenv().AimlockTarget = pickTarget()
        end
    end
end)

-- Per-frame aim
RunService.RenderStepped:Connect(function()
    if not Config.enabled then return end
    if not camera then return end

    local target = getgenv().AimlockTarget
    if not target or not isCharacterValid(target) then
        target = pickTarget()
        getgenv().AimlockTarget = target
        if not target then return end
    end

    local aimPos = getAimPoint(target)
    if not aimPos then return end

    local lookCF = CFrame.lookAt(camera.CFrame.Position, aimPos)
    if Config.lerp >= 1 then
        camera.CFrame = lookCF
    else
        camera.CFrame = camera.CFrame:Lerp(lookCF, Config.lerp)
    end
end)

print("[Aimlock] Loaded. Touch the button to toggle.")