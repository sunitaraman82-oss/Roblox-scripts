local cloneref = cloneref or function(o) return o end
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local Workspace = cloneref(game:GetService("Workspace"))
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local lplr = Players.LocalPlayer
local PlayerGui = lplr:WaitForChild("PlayerGui")

local util = require(ReplicatedStorage.Modules.Utility)
local enum = require(ReplicatedStorage.Modules.EnumLibrary)
local FighterController = require(lplr.PlayerScripts.Controllers.FighterController)
local RespawnRemote = ReplicatedStorage.Remotes.Duels.RespawnNow

local Colors = {
    Bg = Color3.fromRGB(25, 15, 35),
    Panel = Color3.fromRGB(40, 25, 55),
    Element = Color3.fromRGB(60, 40, 80),
    Accent = Color3.fromRGB(255, 105, 180),
    Text = Color3.fromRGB(240, 240, 240)
}

getgenv().Config = {
    -- Original Features
    Enabled = true,
    FireRate = 0.05,
    WeaponSlot = "Primary",
    MaxDistance = 2000,
    AutoCollectEnabled = true,
    CollectHP = true,
    CollectAmmo = true,
    CollectInterval = 0.10,
    
    -- New Rage & Desync Features
    Rage = true,
    RageFireRate = 0.001,
    VoidSpam = false,
    AntiExplosion = true,
    AntiExplosionHeight = 300,
    DesyncEnabled = true,
    DesyncMode = "offscreen",
    DesyncHeight = 1.0,
    DesyncBack = 2.0,
    AntiAim = true,
    AntiAimSpeed = 360
}

local slots = { Primary = 1, Secondary = 2, Melee = 3 }
local State = { 
    lastFire = 0, 
    lastRageFire = 0, 
    lastEquip = 0, 
    lastCollect = 0,
    target = nil, 
    restoreConn = nil,
    currentlyDodging = false
}

local function getSlotNumber() return slots[getgenv().Config.WeaponSlot] or 1 end

lplr.CharacterAdded:Connect(function()
    task.wait(0.1)
    if RespawnRemote then pcall(function() RespawnRemote:FireServer() end) end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if not getgenv().Config.Enabled and not getgenv().Config.Rage then continue end
        local localFighter = FighterController.LocalFighter
        if localFighter and localFighter.EquippedItem == nil then
            pcall(function() localFighter:EquipItem(getSlotNumber()) end)
        end
    end
end)

local function getClosestTarget()
    local char = lplr.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, closestDist = nil, getgenv().Config.MaxDistance
    local myPos = myRoot.Position
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= char then
            local pRoot = obj:FindFirstChild("HumanoidRootPart")
            local pHead = obj:FindFirstChild("Head") or obj:FindFirstChild("ZombieHead")
            local pHum = obj:FindFirstChildWhichIsA("Humanoid")
            if pRoot and pHead and pHum and pHum.Health > 0 then
                if not Players:GetPlayerFromCharacter(obj) then
                    local dist = (myPos - pRoot.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = { Model = obj, Root = pRoot, Head = pHead, Hum = pHum, Distance = dist }
                    end
                end
            end
        end
    end
    return closest
end

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

local function fireWithDesync(item, target, isRage)
    local char = lplr.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local cfg = getgenv().Config
    local originPos = myRoot.Position
    local aimPos = target.Head.Position

    if cfg.DesyncEnabled then
        local desyncCF = computeDesyncCFrame(target, myRoot)
        originPos = desyncCF.Position
        local oldCF, oldVel, oldRotVel = myRoot.CFrame, myRoot.Velocity, myRoot.RotVelocity
        myRoot.CFrame = desyncCF
        if State.restoreConn then State.restoreConn:Disconnect() end
        State.restoreConn = RunService.RenderStepped:Connect(function()
            if myRoot and myRoot.Parent then myRoot.CFrame, myRoot.Velocity, myRoot.RotVelocity = oldCF, oldVel, oldRotVel end
            if State.restoreConn then State.restoreConn:Disconnect(); State.restoreConn = nil end
        end)
    end
    
    if cfg.AntiAim and myRoot then
        local spinAngle = math.rad((tick() * cfg.AntiAimSpeed) % 360)
        myRoot.CFrame = CFrame.new(myRoot.Position) * CFrame.Angles(0, spinAngle, 0) * CFrame.Angles(math.rad(math.random(-90, 90)), 0, 0)
        if State.restoreConn then State.restoreConn:Disconnect() end
        State.restoreConn = RunService.RenderStepped:Connect(function()
            if myRoot and myRoot.Parent then myRoot.CFrame, myRoot.Velocity, myRoot.RotVelocity = oldCF, oldVel, oldRotVel end
            if State.restoreConn then State.restoreConn:Disconnect(); State.restoreConn = nil end
        end)
    end

    local aimCF = CFrame.lookAt(originPos, aimPos)
    local rand = Vector3.new((math.random()-0.5)*0.02, (math.random()-0.5)*0.02, (math.random()-0.5)*0.02)
    local objSpaceHead = target.Head.CFrame:ToObjectSpace(CFrame.new(aimPos + rand))
    local cameraData = { [utf8.char(1)] = { [utf8.char(0)] = util:EncodeCFrame(aimCF), [utf8.char(1)] = util:EncodeCFrame(target.Head.CFrame), [utf8.char(2)] = target.Head, [utf8.char(3)] = util:EncodeCFrame(objSpaceHead) } }
    
    pcall(function()
        ReplicatedStorage.Remotes.Replication.Fighter.UseItem:FireServer(item:Get("ObjectID"), enum:ToEnum("StartShooting"), cameraData, nil)
    end)
end

local function dodgeExplosion()
    if State.currentlyDodging or not getgenv().Config.AntiExplosion then return end
    local char = lplr.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    State.currentlyDodging = true
    local originalCF = myRoot.CFrame
    myRoot.CFrame = originalCF + Vector3.new(0, getgenv().Config.AntiExplosionHeight, 0)
    task.delay(0.15, function()
        if myRoot and myRoot.Parent then myRoot.CFrame = originalCF end
        State.currentlyDodging = false
    end)
end

RunService.Heartbeat:Connect(function()
    local cfg = getgenv().Config
    if not (cfg.Enabled or cfg.Rage) then return end
    
    local lf = FighterController.LocalFighter
    if not lf or not lf.EquippedItem then return end
    local target = getClosestTarget()
    State.target = target
    if not target then return end
    local now = tick()

    if cfg.Enabled and now - State.lastFire >= cfg.FireRate then
        State.lastFire = now
        fireWithDesync(lf.EquippedItem, target, false)
    end

    if cfg.Rage and now - State.lastRageFire >= cfg.RageFireRate then
        State.lastRageFire = now
        if target.Hum.Health > 0 and target.Hum.Health < (target.Hum.MaxHealth * 0.15) then
            dodgeExplosion()
        end
        if cfg.VoidSpam then
            pcall(function() target.Root.CFrame = target.Root.CFrame + Vector3.new(0, 1000, 0) end)
        else
            fireWithDesync(lf.EquippedItem, target, true)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not getgenv().Config.AutoCollectEnabled then return end
    local now = tick()
    if now - State.lastCollect < getgenv().Config.CollectInterval then return end
    State.lastCollect = now
    local char = lplr.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end
    local wantHP   = getgenv().Config.CollectHP and hum.Health < hum.MaxHealth
    local wantAmmo = getgenv().Config.CollectAmmo
    if not wantHP and not wantAmmo then return end
    local firetouch = firetouchinterest
    if not firetouch then return end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name == "_drop" and obj:IsA("BasePart") then
            local isHP   = obj:FindFirstChild("Health") ~= nil
            local isAmmo = obj:FindFirstChild("Ammo") ~= nil or obj:FindFirstChild("AmmoBalanced") ~= nil
            if (wantHP and isHP) or (wantAmmo and isAmmo) then
                pcall(function()
                    firetouch(hrp, obj, 0)
                    firetouch(hrp, obj, 1)
                end)
            end
        end
    end
end)

local function Create(className, properties)
    local instance = Instance.new(className)
    for k, v in pairs(properties) do instance[k] = v end
    return instance
end

local ScreenGui = Create("ScreenGui", { Name = "HalloweenUI", ResetOnSpawn = false, Parent = PlayerGui })
local ToggleBtn = Create("TextButton", { Size = UDim2.new(0, 80, 0, 35), Position = UDim2.new(0, 20, 0.5, -17), BackgroundColor3 = Colors.Panel, Text = "MENU", TextColor3 = Colors.Accent, Font = Enum.Font.GothamBold, TextSize = 14, Parent = ScreenGui })
Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ToggleBtn })
Create("UIStroke", { Color = Colors.Accent, Thickness = 1.5, Parent = ToggleBtn })

local MainFrame = Create("Frame", { Name = "Main", Size = UDim2.new(0, 500, 0, 420), Position = UDim2.new(0.5, -250, 0.5, -210), BackgroundColor3 = Colors.Bg, BorderSizePixel = 0, Parent = ScreenGui, ClipsDescendants = true, Visible = false })
Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = MainFrame })
Create("UIStroke", { Color = Colors.Accent, Thickness = 1.5, Parent = MainFrame })

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
    TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 500, 0, 420) }):Play()
end
ToggleBtn.MouseButton1Click:Connect(function() if isMenuOpen then closeMenu() else openMenu() end end)

local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
MainFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local TopBar = Create("Frame", { Size = UDim2.new(1, 0, 0, 45), BackgroundTransparency = 1, Parent = MainFrame })
Create("TextLabel", { Text = "Halloween Script | By Noami", Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, TextColor3 = Colors.Accent, Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar })
local CloseBtn = Create("TextButton", { Text = "X", Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -40, 0.5, -15), BackgroundTransparency = 1, TextColor3 = Colors.Text, Font = Enum.Font.GothamBold, TextSize = 16, Parent = TopBar })
CloseBtn.MouseButton1Click:Connect(closeMenu)
Create("Frame", { Size = UDim2.new(1, -30, 0, 1), Position = UDim2.new(0, 15, 0, 45), BackgroundColor3 = Colors.Accent, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = MainFrame })

local ContentArea = Create("Frame", { Size = UDim2.new(1, -30, 1, -65), Position = UDim2.new(0, 15, 0, 55), BackgroundTransparency = 1, Parent = MainFrame })
local LeftPanel = Create("Frame", { Size = UDim2.new(0.5, -8, 1, 0), BackgroundColor3 = Colors.Panel, Parent = ContentArea })
Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = LeftPanel })
Create("UIStroke", { Color = Colors.Accent, Thickness = 1, Transparency = 0.5, Parent = LeftPanel })
Create("TextLabel", { Text = "Combat", Size = UDim2.new(1, -20, 0, 25), Position = UDim2.new(0, 10, 0, 5), BackgroundTransparency = 1, TextColor3 = Colors.Text, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = LeftPanel })
local LeftScroll = Create("ScrollingFrame", { Size = UDim2.new(1, -20, 1, -40), Position = UDim2.new(0, 10, 0, 35), BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = Colors.Accent, CanvasSize = UDim2.new(0, 0, 0, 0), Parent = LeftPanel })
Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = LeftScroll })

local RightPanel = Create("Frame", { Size = UDim2.new(0.5, -8, 1, 0), Position = UDim2.new(0.5, 8, 0, 0), BackgroundColor3 = Colors.Panel, Parent = ContentArea })
Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = RightPanel })
Create("UIStroke", { Color = Colors.Accent, Thickness = 1, Transparency = 0.5, Parent = RightPanel })
Create("TextLabel", { Text = "Rage & Desync", Size = UDim2.new(1, -20, 0, 25), Position = UDim2.new(0, 10, 0, 5), BackgroundTransparency = 1, TextColor3 = Colors.Text, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = RightPanel })
local RightScroll = Create("ScrollingFrame", { Size = UDim2.new(1, -20, 1, -40), Position = UDim2.new(0, 10, 0, 35), BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = Colors.Accent, CanvasSize = UDim2.new(0, 0, 0, 0), Parent = RightPanel })
Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = RightScroll })

local function CreateHeader(text, parent)
    local frame = Create("Frame", { Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1, Parent = parent })
    Create("TextLabel", { Text = text, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = Colors.Accent, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
end

local function CreateToggle(name, featureKey, parent)
    local isChecked = getgenv().Config[featureKey]
    local frame = Create("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Parent = parent })
    Create("TextLabel", { Text = name, Size = UDim2.new(0.75, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = Colors.Text, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
    
    local Pill = Create("Frame", { Size = UDim2.new(0, 34, 0, 16), Position = UDim2.new(1, -34, 0.5, -8), BackgroundColor3 = isChecked and Colors.Accent or Colors.Element, Parent = frame })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Pill })
    local Knob = Create("Frame", { Size = UDim2.new(0, 12, 0, 12), Position = isChecked and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6), BackgroundColor3 = Color3.fromRGB(255,255,255), Parent = Pill })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Knob })
    
    local Btn = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = frame })
    Btn.MouseButton1Click:Connect(function()
        isChecked = not isChecked
        getgenv().Config[featureKey] = isChecked
        TweenService:Create(Pill, TweenInfo.new(0.2), { BackgroundColor3 = isChecked and Colors.Accent or Colors.Element }):Play()
        TweenService:Create(Knob, TweenInfo.new(0.2), { Position = isChecked and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6) }):Play()
    end)
end

local function CreateSlider(name, min, max, default, parent, callback)
    local frame = Create("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = parent })
    local Top = Create("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Parent = frame })
    Create("TextLabel", { Text = name, Size = UDim2.new(0.7, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = Colors.Text, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = Top })
    local ValLabel = Create("TextLabel", { Text = tostring(default), Size = UDim2.new(0.3, 0, 1, 0), Position = UDim2.new(0.7, 0, 0, 0), BackgroundTransparency = 1, TextColor3 = Colors.Accent, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Parent = Top })
    
    local Bar = Create("Frame", { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 22), BackgroundColor3 = Colors.Element, Parent = frame })
    Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = Bar })
    local Fill = Create("Frame", { Size = UDim2.new((default - min) / (max - min), 0, 1, 0), BackgroundColor3 = Colors.Accent, Parent = Bar })
    Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = Fill })
    local Knob = Create("Frame", { Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6), BackgroundColor3 = Colors.Accent, Parent = Bar })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Knob })
    
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
    Create("TextLabel", { Text = name, Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1, TextColor3 = Colors.Text, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
    
    local Btn = Create("TextButton", { Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 0, 18), BackgroundColor3 = Colors.Element, Text = "", Parent = frame })
    Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Btn })
    local Label = Create("TextLabel", { Text = default, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, TextColor3 = Colors.Text, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = Btn })
    Create("TextLabel", { Text = "v", Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -20, 0, 0), BackgroundTransparency = 1, TextColor3 = Colors.Accent, Font = Enum.Font.GothamBold, TextSize = 12, Parent = Btn })
    
    local currentIndex = 1
    for i, v in ipairs(options) do if v == default then currentIndex = i break end end
    Btn.MouseButton1Click:Connect(function()
        currentIndex = currentIndex % #options + 1
        Label.Text = options[currentIndex]
        if callback then callback(options[currentIndex]) end
    end)
end

-- LEFT PANEL (Combat & Items)
CreateHeader("AUTO SHOOT", LeftScroll)
CreateToggle("Enable Auto-Shoot", "Enabled", LeftScroll)
CreateDropdown("Weapon Slot", {"Primary", "Secondary", "Melee"}, getgenv().Config.WeaponSlot, LeftScroll, function(val) getgenv().Config.WeaponSlot = val end)
CreateSlider("Fire Rate (s)", 0.01, 0.5, getgenv().Config.FireRate, LeftScroll, function(val) getgenv().Config.FireRate = val end)
CreateSlider("Max Distance", 50, 5000, getgenv().Config.MaxDistance, LeftScroll, function(val) getgenv().Config.MaxDistance = val end)

CreateHeader("AUTO COLLECT", LeftScroll)
CreateToggle("Enable Auto Collect", "AutoCollectEnabled", LeftScroll)
CreateToggle("Health Packs", "CollectHP", LeftScroll)
CreateToggle("Ammo Packs", "CollectAmmo", LeftScroll)
CreateSlider("Collect Rate", 0.05, 1, getgenv().Config.CollectInterval, LeftScroll, function(val) getgenv().Config.CollectInterval = val end)

-- RIGHT PANEL (Rage & Desync)
CreateHeader("RAGE FEATURES", RightScroll)
CreateToggle("Enable Rage", "Rage", RightScroll)
CreateToggle("Void Spam", "VoidSpam", RightScroll)
CreateSlider("Rage Fire Rate (s)", 0.001, 0.5, getgenv().Config.RageFireRate, RightScroll, function(val) getgenv().Config.RageFireRate = val end)

CreateHeader("DESYNC SETTINGS", RightScroll)
CreateToggle("Enable Desync", "DesyncEnabled", RightScroll)
CreateDropdown("Desync Mode", {"offscreen", "behind", "front", "above"}, getgenv().Config.DesyncMode, RightScroll, function(val) getgenv().Config.DesyncMode = val end)
CreateSlider("Desync Height", 0, 50, getgenv().Config.DesyncHeight, RightScroll, function(val) getgenv().Config.DesyncHeight = val end)
CreateSlider("Desync Back", -5, 10, getgenv().Config.DesyncBack, RightScroll, function(val) getgenv().Config.DesyncBack = val end)

CreateHeader("PROTECTION", RightScroll)
CreateToggle("Anti-Explosion", "AntiExplosion", RightScroll)
CreateToggle("Anti-Aim (Spin)", "AntiAim", RightScroll)
CreateSlider("Anti-Aim Speed", 100, 1000, getgenv().Config.AntiAimSpeed, RightScroll, function(val) getgenv().Config.AntiAimSpeed = val end)

LeftScroll.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() LeftScroll.CanvasSize = UDim2.new(0, 0, 0, LeftScroll.UIListLayout.AbsoluteContentSize.Y + 20) end)
RightScroll.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() RightScroll.CanvasSize = UDim2.new(0, 0, 0, RightScroll.UIListLayout.AbsoluteContentSize.Y + 20) end)
task.wait()
LeftScroll.CanvasSize = UDim2.new(0, 0, 0, LeftScroll.UIListLayout.AbsoluteContentSize.Y + 20)
RightScroll.CanvasSize = UDim2.new(0, 0, 0, RightScroll.UIListLayout.AbsoluteContentSize.Y + 20)