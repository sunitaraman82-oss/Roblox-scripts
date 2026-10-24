local cloneref = cloneref or function(o) return o end
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local Workspace = cloneref(game:GetService("Workspace"))
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local lplr = Players.LocalPlayer
local PlayerGui = lplr:WaitForChild("PlayerGui")

local util, enum, FighterController, UseItemRemote, RespawnRemote
pcall(function()
    util = require(ReplicatedStorage.Modules.Utility)
    enum = require(ReplicatedStorage.Modules.EnumLibrary)
    FighterController = require(lplr.PlayerScripts.Controllers.FighterController)
    UseItemRemote = ReplicatedStorage.Remotes.Replication.Fighter.UseItem
    RespawnRemote = ReplicatedStorage.Remotes.Duels.RespawnNow
end)

local CONFIG = {
    MainBg = Color3.fromRGB(12, 10, 14), PanelBg = Color3.fromRGB(20, 15, 24), InputBg = Color3.fromRGB(35, 25, 40),
    Pink = Color3.fromRGB(255, 105, 180), Text = Color3.fromRGB(230, 230, 230), DimText = Color3.fromRGB(150, 150, 150),
    Font = Enum.Font.GothamMedium, FontBold = Enum.Font.GothamBold, Blossom = "rbxassetid://1316045217"
}

getgenv().Config = {
    AntiZombie = true, SilentAim = true, Rage = true, VoidSpam = false,
    AZ_FireRate = 0.05, SA_FireRate = 0.05, Rage_FireRate = 0.03, MaxDistance = 1000,
    WeaponSlot = "Primary", Hitpart = "Head",
    DesyncFeatures = true, DesyncMode = "offscreen", DesyncHeight = 1.0, DesyncBack = 2.0,
    AntiExplosion = true, AntiExplosionHeight = 300, AntiAim = true, AntiAimSpeed = 360
}

local slots = { Primary = 1, Secondary = 2, Melee = 3 }
local State = {
    AZ_lastFire = 0, SA_lastFire = 0, Rage_lastFire = 0,
    target = nil, restoreConn = nil, lastTargetScan = 0, cachedTargets = {}
}
local currentlyDodging = false

local function refreshTargets()
    local list = {}
    local char = lplr.Character
    if not char then State.cachedTargets = list; return end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= char and not Players:GetPlayerFromCharacter(obj) then
            local hum = obj:FindFirstChildWhichIsA("Humanoid")
            if hum and hum.Health > 0 then
                local root = obj:FindFirstChild("HumanoidRootPart")
                local head = obj:FindFirstChild("Head") or obj:FindFirstChild("ZombieHead")
                if root and head then
                    list[#list + 1] = { Model = obj, Root = root, Head = head, Hum = hum }
                end
            end
        end
    end
    State.cachedTargets = list
end

local function getClosestTarget()
    local now = tick()
    if now - State.lastTargetScan > 0.2 then
        State.lastTargetScan = now
        refreshTargets()
    end
    local char = lplr.Character
    if not char then return nil end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local myPos = myRoot.Position
    local maxDist = getgenv().Config.MaxDistance
    local closest, closestDist = nil, maxDist
    local hitpart = getgenv().Config.Hitpart
    for _, t in ipairs(State.cachedTargets) do
        if t.Root.Parent and t.Hum.Health > 0 then
            local d = (myPos - t.Root.Position).Magnitude
            if d < closestDist then
                local targetPart = t.Head
                if hitpart == "Torso" then
                    targetPart = t.Model:FindFirstChild("UpperTorso") or t.Model:FindFirstChild("Torso") or t.Head
                elseif hitpart == "Random" then
                    local parts = {"Head", "UpperTorso", "LowerTorso", "Torso"}
                    targetPart = t.Model:FindFirstChild(parts[math.random(#parts)]) or t.Head
                end
                closestDist = d
                closest = { Model = t.Model, Root = t.Root, Head = targetPart, Hum = t.Hum, Distance = d }
            end
        end
    end
    return closest
end

local function safeFire(itemId, ...)
    return pcall(UseItemRemote.FireServer, UseItemRemote, itemId, ...)
end

local function buildCameraData(target, originPos)
    local aimCF = CFrame.lookAt(originPos, target.Head.Position)
    local rand = Vector3.new((math.random() - 0.5) * 0.02, (math.random() - 0.5) * 0.02, (math.random() - 0.5) * 0.02)
    local objSpaceHead = target.Head.CFrame:ToObjectSpace(CFrame.new(target.Head.Position + rand))
    return {
        [utf8.char(1)] = {
            [utf8.char(0)] = util:EncodeCFrame(aimCF),
            [utf8.char(1)] = util:EncodeCFrame(target.Head.CFrame),
            [utf8.char(2)] = target.Head,
            [utf8.char(3)] = util:EncodeCFrame(objSpaceHead),
        }
    }, aimCF
end

lplr.CharacterAdded:Connect(function()
    task.wait(0.1)
    if RespawnRemote then pcall(function() RespawnRemote:FireServer() end) end
end)

task.spawn(function()
    while true do
        task.wait(2)
        if not getgenv().Config.AntiZombie or not FighterController then continue end
        local lf = FighterController.LocalFighter
        if lf and not lf.EquippedItem then
            pcall(function() lf:EquipItem(slots[getgenv().Config.WeaponSlot] or 1) end)
        end
    end
end)

local function computeDesyncCFrame(target, myRoot)
    local cfg = getgenv().Config
    local offset
    if cfg.DesyncMode == "offscreen" then
        return CFrame.lookAt(target.Root.Position + Vector3.new(0, 1000, 0), target.Head.Position)
    elseif cfg.DesyncMode == "behind" then
        offset = CFrame.new(0, cfg.DesyncHeight, cfg.DesyncBack)
    elseif cfg.DesyncMode == "front" then
        offset = CFrame.new(0, cfg.DesyncHeight, -cfg.DesyncBack)
    else
        offset = CFrame.new(0, cfg.DesyncHeight + 2, 0)
    end
    return CFrame.lookAt((target.Root.CFrame * offset).Position, target.Head.Position)
end

local function applyDesync(myRoot, target)
    if State.restoreConn then return end
    local desyncCF = computeDesyncCFrame(target, myRoot)
    local oldCF, oldVel, oldRotVel = myRoot.CFrame, myRoot.Velocity, myRoot.RotVelocity
    myRoot.CFrame = desyncCF
    State.restoreConn = RunService.RenderStepped:Connect(function()
        if myRoot and myRoot.Parent then
            myRoot.CFrame, myRoot.Velocity, myRoot.RotVelocity = oldCF, oldVel, oldRotVel
        end
        if State.restoreConn then
            State.restoreConn:Disconnect()
            State.restoreConn = nil
        end
    end)
end

local function dodgeExplosion()
    if currentlyDodging or not getgenv().Config.AntiExplosion then return end
    local myRoot = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    currentlyDodging = true
    local originalCF = myRoot.CFrame
    myRoot.CFrame = originalCF + Vector3.new(0, getgenv().Config.AntiExplosionHeight, 0)
    task.delay(0.15, function()
        if myRoot and myRoot.Parent then myRoot.CFrame = originalCF end
        currentlyDodging = false
    end)
end

RunService.Heartbeat:Connect(function()
    local cfg = getgenv().Config
    if not (cfg.AntiZombie or cfg.SilentAim or cfg.Rage) then return end
    local lf = FighterController and FighterController.LocalFighter
    if not lf or not lf.EquippedItem then return end
    local target = getClosestTarget()
    if not target then return end
    local now = tick()
    local char = lplr.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local itemId = lf.EquippedItem:Get("ObjectID")
    local originPos = myRoot.Position

    if cfg.Rage and target.Hum.Health > 0 and target.Hum.Health < (target.Hum.MaxHealth * 0.15) then
        dodgeExplosion()
    end

    if cfg.DesyncFeatures then
        applyDesync(myRoot, target)
    elseif cfg.AntiAim then
        if not State.restoreConn then
            local oldCF, oldVel, oldRotVel = myRoot.CFrame, myRoot.Velocity, myRoot.RotVelocity
            local spinAngle = math.rad((tick() * cfg.AntiAimSpeed) % 360)
            myRoot.CFrame = CFrame.new(myRoot.Position)
                * CFrame.Angles(0, spinAngle, 0)
                * CFrame.Angles(math.rad(math.random(-90, 90)), 0, 0)
            State.restoreConn = RunService.RenderStepped:Connect(function()
                if myRoot and myRoot.Parent then
                    myRoot.CFrame, myRoot.Velocity, myRoot.RotVelocity = oldCF, oldVel, oldRotVel
                end
                if State.restoreConn then
                    State.restoreConn:Disconnect()
                    State.restoreConn = nil
                end
            end)
        end
    end

    local cameraData = buildCameraData(target, originPos)

    if cfg.AntiZombie and now - State.AZ_lastFire >= cfg.AZ_FireRate then
        State.AZ_lastFire = now
        safeFire(itemId, enum:ToEnum("StartShooting"), cameraData, nil)
    end
    if cfg.SilentAim and now - State.SA_lastFire >= cfg.SA_FireRate then
        State.SA_lastFire = now
        safeFire(itemId, enum:ToEnum("StartShooting"), cameraData, nil)
    end
    if cfg.Rage and now - State.Rage_lastFire >= cfg.Rage_FireRate then
        State.Rage_lastFire = now
        State.target = target
        if cfg.VoidSpam then
            pcall(function()
                target.Root.CFrame = target.Root.CFrame + Vector3.new(0, 1000, 0)
            end)
        else
            safeFire(itemId, enum:ToEnum("StartShooting"), cameraData, nil)
        end
    end
end)

local function Create(className, properties)
    local instance = Instance.new(className)
    for k, v in pairs(properties) do instance[k] = v end
    return instance
end
local function AddCorner(parent, radius) Create("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent }) end
local function AddStroke(parent, color, thickness, transparency) return Create("UIStroke", { Color = color or CONFIG.Pink, Thickness = thickness or 1, Transparency = transparency or 0, Parent = parent }) end

local ScreenGui = Create("ScreenGui", { Name = "HalloweenTowerUI", ResetOnSpawn = false, Parent = PlayerGui })
local ToggleBtn = Create("TextButton", { Size = UDim2.new(0, 80, 0, 35), Position = UDim2.new(0, 20, 0.5, -17), BackgroundColor3 = CONFIG.PanelBg, Text = "MENU", TextColor3 = CONFIG.Pink, Font = CONFIG.FontBold, TextSize = 14, Parent = ScreenGui })
AddCorner(ToggleBtn, 6); AddStroke(ToggleBtn, CONFIG.Pink, 2, 0)

local MainFrame = Create("Frame", { Name = "Main", Size = UDim2.new(0, 600, 0, 480), Position = UDim2.new(0.5, -300, 0.5, -240), BackgroundColor3 = CONFIG.MainBg, BorderSizePixel = 0, Parent = ScreenGui, ClipsDescendants = true, Visible = false })
AddCorner(MainFrame, 12); AddStroke(MainFrame, CONFIG.Pink, 1.5, 0.2)

Create("ImageLabel", { Image = CONFIG.Blossom, Size = UDim2.new(0, 400, 0, 400), Position = UDim2.new(1, -200, 0, -150), BackgroundTransparency = 1, ImageTransparency = 0.85, ImageColor3 = CONFIG.Pink, Parent = MainFrame })

local isMenuOpen = false
local function closeMenu()
    isMenuOpen = false
    local t = TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = UDim2.new(0, 0, 0, 0) })
    t:Play(); t.Completed:Connect(function() MainFrame.Visible = false end)
end
local function openMenu()
    isMenuOpen = true
    MainFrame.Visible = true
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 600, 0, 480) }):Play()
end
ToggleBtn.MouseButton1Click:Connect(function()
    if isMenuOpen then closeMenu() else openMenu() end
end)

local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local TopBar = Create("Frame", { Size = UDim2.new(1, 0, 0, 45), BackgroundTransparency = 1, Parent = MainFrame })
Create("TextLabel", { Text = "Halloween Tower | By Noami", Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 20, 0, 0), BackgroundTransparency = 1, TextColor3 = CONFIG.Pink, Font = CONFIG.FontBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar })
local CloseBtn = Create("TextButton", { Text = "X", Size = UDim2.new(0, 45, 0, 45), Position = UDim2.new(1, -45, 0, 0), BackgroundTransparency = 1, TextColor3 = CONFIG.Text, Font = CONFIG.FontBold, TextSize = 14, Parent = TopBar })
CloseBtn.MouseButton1Click:Connect(closeMenu)
Create("Frame", { Size = UDim2.new(1, -40, 0, 1), Position = UDim2.new(0, 20, 0, 45), BackgroundColor3 = CONFIG.Pink, BackgroundTransparency = 0.6, BorderSizePixel = 0, Parent = MainFrame })

local ContentArea = Create("Frame", { Size = UDim2.new(1, -40, 1, -65), Position = UDim2.new(0, 20, 0, 55), BackgroundTransparency = 1, Parent = MainFrame })
local LeftPanel = Create("Frame", { Size = UDim2.new(0.5, -10, 1, 0), BackgroundColor3 = CONFIG.PanelBg, Parent = ContentArea })
AddCorner(LeftPanel, 8); AddStroke(LeftPanel, CONFIG.Pink, 1, 0.7)
Create("TextLabel", { Text = "Combat & Aim", Size = UDim2.new(1, -20, 0, 25), Position = UDim2.new(0, 15, 0, 10), BackgroundTransparency = 1, TextColor3 = CONFIG.Text, Font = CONFIG.FontBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = LeftPanel })
local LeftScroll = Create("ScrollingFrame", { Size = UDim2.new(1, -20, 1, -45), Position = UDim2.new(0, 10, 0, 35), BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = CONFIG.Pink, CanvasSize = UDim2.new(0, 0, 0, 0), Parent = LeftPanel })
Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12), Parent = LeftScroll })

local RightPanel = Create("Frame", { Size = UDim2.new(0.5, -10, 1, 0), Position = UDim2.new(0.5, 10, 0, 0), BackgroundColor3 = CONFIG.PanelBg, Parent = ContentArea })
AddCorner(RightPanel, 8); AddStroke(RightPanel, CONFIG.Pink, 1, 0.7)
Create("TextLabel", { Text = "Rage & Desync", Size = UDim2.new(1, -20, 0, 25), Position = UDim2.new(0, 15, 0, 10), BackgroundTransparency = 1, TextColor3 = CONFIG.Text, Font = CONFIG.FontBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = RightPanel })
local RightScroll = Create("ScrollingFrame", { Size = UDim2.new(1, -20, 1, -45), Position = UDim2.new(0, 10, 0, 35), BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = CONFIG.Pink, CanvasSize = UDim2.new(0, 0, 0, 0), Parent = RightPanel })
Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12), Parent = RightScroll })

local function CreateHeader(text, parent)
    local frame = Create("Frame", { Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1, Parent = parent })
    Create("TextLabel", { Text = text, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = CONFIG.DimText, Font = CONFIG.FontBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
end

local function CreateToggle(name, featureKey, parent)
    local isChecked = getgenv().Config[featureKey]
    local frame = Create("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Parent = parent })
    Create("TextLabel", { Text = name, Size = UDim2.new(0.75, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = CONFIG.Text, Font = CONFIG.Font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
    local Pill = Create("Frame", { Size = UDim2.new(0, 34, 0, 16), Position = UDim2.new(1, -34, 0.5, -8), BackgroundColor3 = isChecked and CONFIG.Pink or CONFIG.InputBg, Parent = frame })
    AddCorner(Pill, 8)
    if isChecked then AddStroke(Pill, CONFIG.Pink, 1, 0) end
    local Knob = Create("Frame", { Size = UDim2.new(0, 12, 0, 12), Position = isChecked and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Parent = Pill })
    AddCorner(Knob, 6)
    local Btn = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = frame })
    Btn.MouseButton1Click:Connect(function()
        isChecked = not isChecked
        getgenv().Config[featureKey] = isChecked
        TweenService:Create(Pill, TweenInfo.new(0.2), { BackgroundColor3 = isChecked and CONFIG.Pink or CONFIG.InputBg }):Play()
        TweenService:Create(Knob, TweenInfo.new(0.2, Enum.EasingStyle.Quart), { Position = isChecked and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6) }):Play()
    end)
end

local function CreateSlider(name, min, max, default, parent, callback)
    local frame = Create("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = parent })
    local Top = Create("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Parent = frame })
    Create("TextLabel", { Text = name, Size = UDim2.new(0.7, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = CONFIG.Text, Font = CONFIG.Font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = Top })
    local ValLabel = Create("TextLabel", { Text = tostring(default), Size = UDim2.new(0.3, 0, 1, 0), Position = UDim2.new(0.7, 0, 0, 0), BackgroundTransparency = 1, TextColor3 = CONFIG.Pink, Font = CONFIG.FontBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Parent = Top })
    local Bar = Create("Frame", { Size = UDim2.new(1, 0, 0, 5), Position = UDim2.new(0, 0, 0, 22), BackgroundColor3 = CONFIG.InputBg, Parent = frame })
    AddCorner(Bar, 3)
    local Fill = Create("Frame", { Size = UDim2.new((default - min) / (max - min), 0, 1, 0), BackgroundColor3 = CONFIG.Pink, Parent = Bar })
    AddCorner(Fill, 3)
    local Knob = Create("Frame", { Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6), BackgroundColor3 = CONFIG.Pink, Parent = Bar })
    AddCorner(Knob, 6); AddStroke(Knob, Color3.fromRGB(255, 255, 255), 1.5, 0.3)
    local Btn = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = Bar })
    local dragging = false
    local function update(input)
        local percent = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * percent)
        if max <= 1 or (max - min) < 10 then val = math.round((min + (max - min) * percent) * 100) / 100 end
        TweenService:Create(Fill, TweenInfo.new(0.05), { Size = UDim2.new(percent, 0, 1, 0) }):Play()
        TweenService:Create(Knob, TweenInfo.new(0.05), { Position = UDim2.new(percent, -6, 0.5, -6) }):Play()
        ValLabel.Text = tostring(val)
        if callback then callback(val) end
    end
    Btn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; update(input) end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
    UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input) end end)
end

local function CreateDropdown(name, options, default, parent, callback)
    local frame = Create("Frame", { Size = UDim2.new(1, 0, 0, 45), BackgroundTransparency = 1, Parent = parent })
    Create("TextLabel", { Text = name, Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1, TextColor3 = CONFIG.Text, Font = CONFIG.Font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
    local Btn = Create("TextButton", { Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 0, 18), BackgroundColor3 = CONFIG.InputBg, Text = "", Parent = frame })
    AddCorner(Btn, 4); AddStroke(Btn, CONFIG.Pink, 1, 0.5)
    local Label = Create("TextLabel", { Text = default, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, TextColor3 = CONFIG.Text, Font = CONFIG.Font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = Btn })
    Create("TextLabel", { Text = "▼", Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -20, 0, 0), BackgroundTransparency = 1, TextColor3 = CONFIG.Pink, Font = CONFIG.FontBold, TextSize = 10, Parent = Btn })
    local currentIndex = 1
    for i, v in ipairs(options) do if v == default then currentIndex = i; break end end
    Btn.MouseButton1Click:Connect(function()
        currentIndex = currentIndex % #options + 1
        Label.Text = options[currentIndex]
        if callback then callback(options[currentIndex]) end
    end)
end

CreateHeader("Anti Zombie", LeftScroll)
CreateToggle("Anti Zombie Enabled", "AntiZombie", LeftScroll)
CreateDropdown("Weapon Slot", {"Primary", "Secondary", "Melee"}, getgenv().Config.WeaponSlot, LeftScroll, function(val) getgenv().Config.WeaponSlot = val end)
CreateSlider("Anti-Zombie Fire Rate", 0.01, 0.5, getgenv().Config.AZ_FireRate, LeftScroll, function(val) getgenv().Config.AZ_FireRate = val end)

CreateHeader("Silent Aim", LeftScroll)
CreateToggle("Silent Aim Enabled", "SilentAim", LeftScroll)
CreateSlider("Silent Aim Fire Rate", 0.01, 0.5, getgenv().Config.SA_FireRate, LeftScroll, function(val) getgenv().Config.SA_FireRate = val end)

CreateHeader("Global Settings", LeftScroll)
CreateSlider("Max Distance", 50, 2000, getgenv().Config.MaxDistance, LeftScroll, function(val) getgenv().Config.MaxDistance = val end)
CreateDropdown("Hitpart", {"Head", "Torso", "Random"}, getgenv().Config.Hitpart, LeftScroll, function(val) getgenv().Config.Hitpart = val end)

CreateHeader("Rage Features", RightScroll)
CreateToggle("Rage Enabled", "Rage", RightScroll)
CreateToggle("Void Spam", "VoidSpam", RightScroll)
CreateSlider("Rage Fire Rate", 0.01, 0.5, getgenv().Config.Rage_FireRate, RightScroll, function(val) getgenv().Config.Rage_FireRate = val end)

CreateHeader("Desync Settings", RightScroll)
CreateToggle("Desync Features", "DesyncFeatures", RightScroll)
CreateDropdown("Desync Mode", {"offscreen", "behind", "front", "above"}, getgenv().Config.DesyncMode, RightScroll, function(val) getgenv().Config.DesyncMode = val end)
CreateSlider("Desync Height", 0, 50, getgenv().Config.DesyncHeight, RightScroll, function(val) getgenv().Config.DesyncHeight = val end)
CreateSlider("Desync Back", -5, 10, getgenv().Config.DesyncBack, RightScroll, function(val) getgenv().Config.DesyncBack = val end)

CreateHeader("Protection / Anti-Aim", RightScroll)
CreateToggle("Anti-Explosion", "AntiExplosion", RightScroll)
CreateToggle("Anti-Aim (Spin Server)", "AntiAim", RightScroll)
CreateSlider("Anti-Aim Speed", 100, 1000, getgenv().Config.AntiAimSpeed, RightScroll, function(val) getgenv().Config.AntiAimSpeed = val end)

LeftScroll.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() LeftScroll.CanvasSize = UDim2.new(0, 0, 0, LeftScroll.UIListLayout.AbsoluteContentSize.Y + 20) end)
RightScroll.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() RightScroll.CanvasSize = UDim2.new(0, 0, 0, RightScroll.UIListLayout.AbsoluteContentSize.Y + 20) end)
task.wait()
LeftScroll.CanvasSize = UDim2.new(0, 0, 0, LeftScroll.UIListLayout.AbsoluteContentSize.Y + 20)
RightScroll.CanvasSize = UDim2.new(0, 0, 0, RightScroll.UIListLayout.AbsoluteContentSize.Y + 20)