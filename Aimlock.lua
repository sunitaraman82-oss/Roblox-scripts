if getgenv().RivalsAimAssist and getgenv().RivalsAimAssist.Unload then
    pcall(getgenv().RivalsAimAssist.Unload)
end
if not game:IsLoaded() then game.Loaded:Wait() end

local K = { connections = {}, cleanups = {}, destroyed = false }
getgenv().RivalsAimAssist = K

local rawget, rawset = rawget, rawset

function K.fn(name)
    local v
    pcall(function() v = getfenv(0)[name] end)
    if type(v) ~= "function" then
        pcall(function() v = getfenv()[name] end)
    end
    return type(v) == "function" and v or nil
end

local cloneref_            = K.fn("cloneref") or function(x) return x end
local writefile_           = K.fn("writefile")
local readfile_            = K.fn("readfile")
local isfile_              = K.fn("isfile")
local hookmetamethod_      = K.fn("hookmetamethod")
local hookfunction_        = K.fn("hookfunction")
local getnamecallmethod_   = K.fn("getnamecallmethod")
local getgc_               = K.fn("getgc")
local getrenv_             = K.fn("getrenv")
local gethui_              = K.fn("gethui")

local Players          = cloneref_(game:GetService("Players"))
local RunService       = cloneref_(game:GetService("RunService"))
local UserInputService = cloneref_(game:GetService("UserInputService"))
local ReplicatedStorage= cloneref_(game:GetService("ReplicatedStorage"))
local HttpService      = cloneref_(game:GetService("HttpService"))
local CoreGui          = cloneref_(game:GetService("CoreGui"))

local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

function K.track(c)
    K.connections[#K.connections + 1] = c
    return c
end
function K.onUnload(f)
    K.cleanups[#K.cleanups + 1] = f
end

function K.Unload()
    if K.destroyed then return end
    K.destroyed = true
    for i = #K.connections, 1, -1 do
        pcall(function()
            local c = K.connections[i]
            if typeof(c) == "RBXScriptConnection" then
                c:Disconnect()
            elseif type(c) == "table" and type(c.Disconnect) == "function" then
                c:Disconnect()
            end
        end)
        K.connections[i] = nil
    end
    for _, f in ipairs(K.cleanups) do
        pcall(f)
    end
    if getgenv().RivalsAimAssist == K then
        getgenv().RivalsAimAssist = nil
    end
end

local SETTINGS_FILE = "rivals_aimassist.json"

local Settings = {
    Enabled       = false,
    TargetLock    = true,
    TeamCheck     = false,
    WallCheck     = true,
    UsePrediction = true,
    ShowFOV       = true,
    VisibleOnly   = true,
    TargetPart    = "Head",
    FOV           = 100,
    Smoothness    = 100,
    Prediction    = 5.0,
    AimMode       = "Spring",
    Priority      = "Angle",
}

local function loadSettings()
    if not readfile_ or not isfile_ then return end
    local ok, exists = pcall(isfile_, SETTINGS_FILE)
    if not ok or not exists then return end
    local ok2, raw = pcall(readfile_, SETTINGS_FILE)
    if not ok2 or raw == "" then return end
    local ok3, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok3 or type(decoded) ~= "table" then return end
    for k, v in next, decoded do
        if Settings[k] ~= nil and type(v) == type(Settings[k]) then
            Settings[k] = v
        end
    end
end

local function saveSettings()
    if not writefile_ then return end
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, Settings)
    if ok then
        pcall(writefile_, SETTINGS_FILE, encoded)
    end
end

loadSettings()

local Target = nil

local function getHitPart(character)
    if not character then return nil end
    local requested = character:FindFirstChild(Settings.TargetPart)
    if requested and requested:IsA("BasePart") then return requested end
    if Settings.TargetPart == "Torso" then
        return character:FindFirstChild("Torso")
            or character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("HumanoidRootPart")
    end
    if Settings.TargetPart == "UpperTorso" then
        return character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
            or character:FindFirstChild("HumanoidRootPart")
    end
    if Settings.TargetPart == "Head" then
        return character:FindFirstChild("Head")
            or character:FindFirstChild("HumanoidRootPart")
    end
    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Head")
end

local function isValidTarget(player)
    if not player or player == LocalPlayer then return false end
    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    if Settings.TeamCheck and LocalPlayer.Team ~= nil
        and player.Team == LocalPlayer.Team then
        return false
    end
    return getHitPart(character) ~= nil
end

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

local function isVisible(character, part)
    if not Settings.WallCheck then return true end
    if not character or not part then return false end
    local origin = Camera.CFrame.Position
    local direction = part.Position - origin
    local exclude = {}
    if LocalPlayer.Character then
        exclude[#exclude + 1] = LocalPlayer.Character
    end
    if Camera then
        exclude[#exclude + 1] = Camera
    end
    raycastParams.FilterDescendantsInstances = exclude
    local result = workspace:Raycast(origin, direction, raycastParams)
    if not result then return true end
    return result.Instance:IsDescendantOf(character)
end

local function scoreTarget(character, part, screenCenter)
    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen or screenPos.Z <= 0 then return nil end
    local pos2 = Vector2.new(screenPos.X, screenPos.Y)
    local angle = (pos2 - screenCenter).Magnitude
    if angle > Settings.FOV then return nil end
    if Settings.VisibleOnly and not isVisible(character, part) then
        return nil
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if Settings.Priority == "Health" then
        return (humanoid and humanoid.Health or math.huge)
    elseif Settings.Priority == "Distance" then
        return (part.Position - Camera.CFrame.Position).Magnitude
    end
    return angle
end

local function findTarget()
    local bestTarget, bestScore = nil, math.huge
    local viewport = Camera.ViewportSize
    local screenCenter = Vector2.new(viewport.X / 2, viewport.Y / 2)
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local character = player.Character
            local part = getHitPart(character)
            if part then
                local score = scoreTarget(character, part, screenCenter)
                if score and score < bestScore then
                    bestScore = score
                    bestTarget = player
                end
            end
        end
    end
    return bestTarget
end

local function targetStillValid(player)
    if not isValidTarget(player) then return false end
    local character = player.Character
    local part = getHitPart(character)
    if not part then return false end
    local viewport = Camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
    local position, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen or position.Z <= 0 then return false end
    local angle = (Vector2.new(position.X, position.Y) - center).Magnitude
    if angle > Settings.FOV then return false end
    return isVisible(character, part)
end

local Spring = {}
Spring.__index = Spring

function Spring.new(initial, speed, damper)
    return setmetatable({
        value    = initial or 0,
        velocity = 0,
        target   = initial or 0,
        speed    = speed or 16,
        damper   = damper or 1,
    }, Spring)
end

function Spring:step(dt)
    if dt > 0.05 then dt = 0.05 end
    local omega = self.speed
    local zeta  = self.damper
    local x     = self.value - self.target
    local v     = self.velocity
    local expTerm = math.exp(-zeta * omega * dt)
    local c1, c2
    if zeta < 1 then
        local omegaD = omega * math.sqrt(1 - zeta * zeta)
        local cosT = math.cos(omegaD * dt)
        local sinT = math.sin(omegaD * dt)
        c1 = expTerm * (x * cosT + (v + zeta * omega * x) / omegaD * sinT)
        c2 = expTerm * (v * cosT - omegaD * x * sinT
            - zeta * omega * (x * cosT + (v + zeta * omega * x) / omegaD * sinT))
    elseif zeta == 1 then
        c1 = (x + (v + omega * x) * dt) * expTerm
        c2 = (v - omega * (v + omega * x) * dt) * expTerm
    else
        local s = omega * math.sqrt(zeta * zeta - 1)
        local a, b = -zeta * omega + s, -zeta * omega - s
        local e1, e2 = math.exp(a * dt), math.exp(b * dt)
        c1 = (v - b * x) / (a - b) * e1 + (a * x - v) / (a - b) * e2
        c2 = a * (v - b * x) / (a - b) * e1 + b * (a * x - v) / (a - b) * e2
    end
    self.value    = c1 + self.target
    self.velocity = c2
    return self.value
end

local aimSpringYaw   = Spring.new(0, 18, 1)
local aimSpringPitch = Spring.new(0, 18, 1)

local function resetSprings()
    aimSpringYaw.value, aimSpringYaw.velocity, aimSpringYaw.target       = 0, 0, 0
    aimSpringPitch.value, aimSpringPitch.velocity, aimSpringPitch.target = 0, 0, 0
end

local function aimAt(player, deltaTime)
    if not player or not player.Character then return end
    local part = getHitPart(player.Character)
    if not part then return end
    local predicted = part.Position
    if Settings.UsePrediction then
        local vel = part.AssemblyLinearVelocity or Vector3.zero
        predicted = predicted + vel * Settings.Prediction
    end
    local camPos = Camera.CFrame.Position
    local direction = predicted - camPos
    if direction.Magnitude <= 0 then return end
    local targetCFrame = CFrame.lookAt(camPos, predicted)
    if Settings.AimMode == "Snap" then
        Camera.CFrame = targetCFrame
        return
    end
    local strength = math.clamp(Settings.Smoothness / 100, 0.01, 1)
    if Settings.AimMode == "Spring" then
        local rate = 8 + strength * 22
        aimSpringYaw.target   = 1
        aimSpringPitch.target = 1
        aimSpringYaw:step(deltaTime)
        local alpha = math.clamp(aimSpringYaw.value, 0, 1)
        if alpha > 0.995 then
            aimSpringYaw.value, aimSpringYaw.velocity = 0, 0
        end
        local frameStrength = 1 - math.exp(-deltaTime * rate)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, frameStrength)
    else
        local rate = strength * 60
        local frameStrength = 1 - math.exp(-deltaTime * rate)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, frameStrength)
    end
end
local function getUIParent()
    if gethui_ then
        local ok, h = pcall(gethui_)
        if ok and h then return h end
    end
    return CoreGui
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RivalsAimAssistUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
pcall(function() ScreenGui.Parent = getUIParent() end)
K.onUnload(function() pcall(function() ScreenGui:Destroy() end) end)

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Visible = Settings.ShowFOV
FOVCircle.Parent = ScreenGui

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = FOVCircle

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Thickness = 2
CircleStroke.Transparency = 0.15
CircleStroke.Color = Color3.fromRGB(255, 255, 255)
CircleStroke.Parent = FOVCircle

local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Size = UDim2.fromOffset(55, 55)
OpenButton.Position = UDim2.new(0, 15, 0.5, -25)
OpenButton.Text = "☰"
OpenButton.TextSize = 25
OpenButton.TextColor3 = Color3.new(1, 1, 1)
OpenButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
OpenButton.BackgroundTransparency = 0.15
OpenButton.AutoButtonColor = false
OpenButton.Active = true
OpenButton.Parent = ScreenGui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, 12)
OpenCorner.Parent = OpenButton

local OpenStroke = Instance.new("UIStroke")
OpenStroke.Color = Color3.fromRGB(255, 255, 255)
OpenStroke.Transparency = 0.8
OpenStroke.Parent = OpenButton

local Panel = Instance.new("Frame")
Panel.Name = "Panel"
Panel.Size = UDim2.fromOffset(260, 500)
Panel.Position = UDim2.new(0, 80, 0.5, -250)
Panel.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
Panel.BackgroundTransparency = 0.06
Panel.BorderSizePixel = 0
Panel.Parent = ScreenGui

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 14)
PanelCorner.Parent = Panel

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Color = Color3.fromRGB(255, 255, 255)
PanelStroke.Transparency = 0.88
PanelStroke.Parent = Panel

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 0, 45)
Title.Position = UDim2.fromOffset(14, 5)
Title.BackgroundTransparency = 1
Title.Text = "Aim Assist"
Title.TextSize = 20
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Panel

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.fromOffset(40, 40)
CloseButton.Position = UDim2.new(1, -45, 0, 5)
CloseButton.Text = "×"
CloseButton.TextSize = 25
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.BackgroundTransparency = 1
CloseButton.AutoButtonColor = false
CloseButton.Parent = Panel

local ButtonY = 55
local buttons = {}

local function createToggle(text, get, set)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 42)
    button.Position = UDim2.fromOffset(10, ButtonY)
    button.Text = text .. " : " .. (get() and "ON" or "OFF")
    button.TextSize = 15
    button.TextColor3 = Color3.new(1, 1, 1)
    button.BackgroundColor3 = get() and Color3.fromRGB(50, 90, 140)
        or Color3.fromRGB(35, 35, 38)
    button.BackgroundTransparency = 0.05
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamMedium
    button.AutoButtonColor = false
    button.Parent = Panel

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 9)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.82
    stroke.Parent = button

    local function refresh()
        local on = get()
        button.Text = text .. " : " .. (on and "ON" or "OFF")
        button.BackgroundColor3 = on and Color3.fromRGB(50, 90, 140)
            or Color3.fromRGB(35, 35, 38)
    end

    K.track(button.Activated:Connect(function()
        set(not get())
        refresh()
        saveSettings()
    end))

    ButtonY += 48
    table.insert(buttons, { button = button, refresh = refresh })
    return button
end

createToggle("Aim Assist", function() return Settings.Enabled end,
    function(v) Settings.Enabled = v; if not v then Target = nil; resetSprings() end end)
createToggle("Target Lock", function() return Settings.TargetLock end,
    function(v) Settings.TargetLock = v; if not v then Target = nil end end)
createToggle("Team Check", function() return Settings.TeamCheck end,
    function(v) Settings.TeamCheck = v; Target = nil end end)
createToggle("Wall Check", function() return Settings.WallCheck end,
    function(v) Settings.WallCheck = v; Target = nil end end)
createToggle("Prediction", function() return Settings.UsePrediction end,
    function(v) Settings.UsePrediction = v end)
createToggle("Show FOV", function() return Settings.ShowFOV end,
    function(v) Settings.ShowFOV = v; FOVCircle.Visible = v end)

local HitPartButton = Instance.new("TextButton")
HitPartButton.Size = UDim2.new(1, -20, 0, 42)
HitPartButton.Position = UDim2.fromOffset(10, ButtonY)
HitPartButton.Text = "Hit Part : " .. Settings.TargetPart
HitPartButton.TextSize = 15
HitPartButton.TextColor3 = Color3.new(1, 1, 1)
HitPartButton.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
HitPartButton.BackgroundTransparency = 0.05
HitPartButton.BorderSizePixel = 0
HitPartButton.Font = Enum.Font.GothamMedium
HitPartButton.AutoButtonColor = false
HitPartButton.Parent = Panel

local hpCorner = Instance.new("UICorner")
hpCorner.CornerRadius = UDim.new(0, 9)
hpCorner.Parent = HitPartButton

local hpStroke = Instance.new("UIStroke")
hpStroke.Color = Color3.fromRGB(255, 255, 255)
hpStroke.Transparency = 0.82
hpStroke.Parent = HitPartButton

local hitPartOrder = { "Head", "Torso", "UpperTorso", "HumanoidRootPart" }
K.track(HitPartButton.Activated:Connect(function()
    local idx = table.find(hitPartOrder, Settings.TargetPart) or 1
    idx = (idx % #hitPartOrder) + 1
    Settings.TargetPart = hitPartOrder[idx]
    HitPartButton.Text = "Hit Part : " .. Settings.TargetPart
    Target = nil
    saveSettings()
end))
ButtonY += 48

local FOVButton = Instance.new("TextButton")
FOVButton.Size = UDim2.new(1, -20, 0, 42)
FOVButton.Position = UDim2.fromOffset(10, ButtonY)
FOVButton.Text = "FOV : " .. Settings.FOV
FOVButton.TextSize = 15
FOVButton.TextColor3 = Color3.new(1, 1, 1)
FOVButton.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
FOVButton.BackgroundTransparency = 0.05
FOVButton.BorderSizePixel = 0
FOVButton.Font = Enum.Font.GothamMedium
FOVButton.AutoButtonColor = false
FOVButton.Parent = Panel

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(0, 9)
fovCorner.Parent = FOVButton

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(255, 255, 255)
fovStroke.Transparency = 0.82
fovStroke.Parent = FOVButton

K.track(FOVButton.Activated:Connect(function()
    Settings.FOV = Settings.FOV + 10
    if Settings.FOV > 300 then Settings.FOV = 50 end
    FOVButton.Text = "FOV : " .. Settings.FOV
    Target = nil
    saveSettings()
end))
ButtonY += 48

local AimModeButton = Instance.new("TextButton")
AimModeButton.Size = UDim2.new(1, -20, 0, 42)
AimModeButton.Position = UDim2.fromOffset(10, ButtonY)
AimModeButton.Text = "Mode : " .. Settings.AimMode
AimModeButton.TextSize = 15
AimModeButton.TextColor3 = Color3.new(1, 1, 1)
AimModeButton.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
AimModeButton.BackgroundTransparency = 0.05
AimModeButton.BorderSizePixel = 0
AimModeButton.Font = Enum.Font.GothamMedium
AimModeButton.AutoButtonColor = false
AimModeButton.Parent = Panel

local amCorner = Instance.new("UICorner")
amCorner.CornerRadius = UDim.new(0, 9)
amCorner.Parent = AimModeButton

local amStroke = Instance.new("UIStroke")
amStroke.Color = Color3.fromRGB(255, 255, 255)
amStroke.Transparency = 0.82
amStroke.Parent = AimModeButton

local aimModeOrder = { "Smooth", "Spring", "Snap" }
K.track(AimModeButton.Activated:Connect(function()
    local idx = table.find(aimModeOrder, Settings.AimMode) or 1
    idx = (idx % #aimModeOrder) + 1
    Settings.AimMode = aimModeOrder[idx]
    AimModeButton.Text = "Mode : " .. Settings.AimMode
    saveSettings()
end))
ButtonY += 48

local PriorityButton = Instance.new("TextButton")
PriorityButton.Size = UDim2.new(1, -20, 0, 42)
PriorityButton.Position = UDim2.fromOffset(10, ButtonY)
PriorityButton.Text = "Priority : " .. Settings.Priority
PriorityButton.TextSize = 15
PriorityButton.TextColor3 = Color3.new(1, 1, 1)
PriorityButton.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
PriorityButton.BackgroundTransparency = 0.05
PriorityButton.BorderSizePixel = 0
PriorityButton.Font = Enum.Font.GothamMedium
PriorityButton.AutoButtonColor = false
PriorityButton.Parent = Panel

local prCorner = Instance.new("UICorner")
prCorner.CornerRadius = UDim.new(0, 9)
prCorner.Parent = PriorityButton

local prStroke = Instance.new("UIStroke")
prStroke.Color = Color3.fromRGB(255, 255, 255)
prStroke.Transparency = 0.82
prStroke.Parent = PriorityButton

local priorityOrder = { "Angle", "Distance", "Health" }
K.track(PriorityButton.Activated:Connect(function()
    local idx = table.find(priorityOrder, Settings.Priority) or 1
    idx = (idx % #priorityOrder) + 1
    Settings.Priority = priorityOrder[idx]
    PriorityButton.Text = "Priority : " .. Settings.Priority
    Target = nil
    saveSettings()
end))

local function makeDraggable(frame, dragTarget)
    dragTarget = dragTarget or frame
    local dragging, dragStart, startPos = false, nil, nil

    K.track(dragTarget.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end))

    K.track(dragTarget.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    K.track(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))
end

makeDraggable(Panel, Title)
makeDraggable(OpenButton, OpenButton)

K.track(CloseButton.Activated:Connect(function()
    Panel.Visible = false
end))
K.track(OpenButton.Activated:Connect(function()
    Panel.Visible = true
end))

K.track(UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        Panel.Visible = not Panel.Visible
    end
end))

K.track(RunService:BindToRenderStep("RivalsAimAssist", Enum.RenderPriority.Camera.Value + 1,
    function(deltaTime)
        local viewport = Camera.ViewportSize
        if Settings.ShowFOV then
            FOVCircle.Size = UDim2.fromOffset(Settings.FOV * 2, Settings.FOV * 2)
            FOVCircle.Position = UDim2.fromOffset(viewport.X / 2, viewport.Y / 2)
        end
        if not Settings.Enabled then
            Target = nil
            return
        end
        if Settings.TargetLock then
            if not Target or not targetStillValid(Target) then
                Target = findTarget()
            end
        else
            Target = findTarget()
        end
        if Target then
            aimAt(Target, deltaTime)
        end
    end))

K.onUnload(function()
    pcall(function()
        RunService:UnbindFromRenderStep("RivalsAimAssist")
    end)
end)

pcall(function()
    if not hookfunction_ or not getrenv_ then return end
    local setmetatable_orig = getrenv().setmetatable
    if type(setmetatable_orig) ~= "function" then return end
    local _stbl
    _stbl = hookfunction_(setmetatable_orig, newcclosure(function(tbl, mt)
        if mt and typeof(mt) == "table" and rawget(mt, "__mode") == "kv" then
            local tr = debug.traceback()
            if tr:find("MiscellaneousController") then
                return _stbl({1, 2, 3}, {})
            end
        end
        return _stbl(tbl, mt)
    end))
end)

pcall(function()
    local tagSet = {
        anticheat = true, ac = true, detection = true, ban = true,
        kick = true, security = true, moderation = true,
    }
    local function proc(o)
        pcall(function()
            if o:IsA("LocalScript") or o:IsA("ModuleScript") then
                local ok, nm = pcall(function() return o.Name:lower() end)
                if not ok or not nm then return end
                for tag in next, tagSet do
                    if nm:find(tag) then
                        pcall(function() o.Disabled = true end)
                        return
                    end
                end
            end
        end)
    end
    for _, d in ipairs(game:GetDescendants()) do proc(d) end
    pcall(function()
        K.track(game.DescendantAdded:Connect(proc))
    end)
end)

pcall(function()
    local rf = game:GetService("ReplicatedFirst")
    local tgt = rf:FindFirstChild("LocalScript3")
    if not tgt then return end
    if getgc_ then
        for _, fn in ipairs(getgc_(false)) do
            if type(fn) == "function" then
                local ok1, env = pcall(getfenv, fn)
                if ok1 and type(env) == "table" then
                    local ok2, scr = pcall(function() return rawget(env, "script") end)
                    if ok2 and typeof(scr) == "Instance" and scr == tgt then
                        pcall(function() hookfunction_(fn, function() end) end)
                    end
                end
            end
        end
    end
end)

pcall(function()
    if not hookmetamethod_ or not getnamecallmethod_ then return end
    local ps = LocalPlayer:FindFirstChild("PlayerScripts")
    if not ps then return end
    local ctrl = ps:FindFirstChild("Controllers")
    local mods = ReplicatedStorage:FindFirstChild("Modules")
    if not ctrl or not mods then return end
    local cosLibFile = mods:FindFirstChild("CosmeticLibrary")
    local datCtrlFile = ctrl:FindFirstChild("PlayerDataController")
    if not cosLibFile or not datCtrlFile then return end
    local cosLib, datCtrl
    local okA, a = pcall(require, cosLibFile); if okA then cosLib = a end
    local okB, b = pcall(require, datCtrlFile); if okB then datCtrl = b end
    if not cosLib or not datCtrl then return end
    local cosTypes = { Skin = true, Wrap = true, Charm = true, Dance = true, Emote = true }
    local function isCosType(c) return c and cosTypes[c.Type] end
    local origOwns = cosLib.OwnsCosmetic
    cosLib.OwnsCosmetic = function(self, inv, nm, wep)
        local c = cosLib.Cosmetics[nm]
        if isCosType(c) and not nm:find("MISSING_") then
            return true
        end
        return origOwns and origOwns(self, inv, nm, wep)
    end
    local origGet = datCtrl.Get
    datCtrl.Get = function(self, key)
        local val = origGet(self, key)
        if key == "CosmeticInventory" then
            local prox = {}
            if val then
                for k, v in next, val do
                    if isCosType(cosLib.Cosmetics[k]) then prox[k] = v end
                end
            end
            return setmetatable(prox, {
                __index = function(_, k)
                    if isCosType(cosLib.Cosmetics[k]) then return true end
                    return nil
                end,
            })
        end
        return val
    end
end)

for _, entry in ipairs(buttons) do
    pcall(entry.refresh)
end
HitPartButton.Text = "Hit Part : " .. Settings.TargetPart
FOVButton.Text = "FOV : " .. Settings.FOV
AimModeButton.Text = "Mode : " .. Settings.AimMode
PriorityButton.Text = "Priority : " .. Settings.Priority
FOVCircle.Visible = Settings.ShowFOV

K.onUnload(saveSettings)