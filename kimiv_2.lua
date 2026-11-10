local cloneref = cloneref or function(o) return o end
local repS = cloneref(game:GetService("ReplicatedStorage"))
local plrs = cloneref(game:GetService("Players"))
local runS = cloneref(game:GetService("RunService"))
local ws = cloneref(game:GetService("Workspace"))
local lplr = plrs.LocalPlayer

local util = require(repS.Modules.Utility)
local enum = require(repS.Modules.EnumLibrary)
local FighterController = require(lplr.PlayerScripts.Controllers.FighterController)
local SpectateController = require(lplr.PlayerScripts.Controllers:WaitForChild("SpectateController"))

getgenv().Config = {
    Enabled = true,
    FireRate = 0.0005,
    WeaponSlot = "Melee",
    DesyncMode = "KnifeAware",
    JitterRange = 3,
    OrbitSpeed = 6.0,
    OrbitRadius = 14,
    LowestHealth = true,
    FFAMode = false,
    FFAFireBoost = true,
    KnifeHoverHeight = 9,
    KnifeBehindOffset = -4,
    MaxDist = 500
}

local slots = { Primary = 1, Secondary = 2, Melee = 3 }
local function getSlotNumber() return slots[getgenv().Config.WeaponSlot] or 3 end

task.spawn(function()
    while not FighterController.LocalFighter do task.wait(0.1) end
    pcall(function() FighterController.LocalFighter:EquipItem(getSlotNumber()) end)
    while true do
        task.wait(1)
        if getgenv().Config.Enabled and FighterController.LocalFighter then
            pcall(function() FighterController.LocalFighter:EquipItem(getSlotNumber()) end)
        end
    end
end)

local lastFire = 0
local deflecting = {}
plrs.PlayerRemoving:Connect(function(p) deflecting[p] = nil end)

local function updateDeflection()
    if not FighterController or not FighterController.Objects then return end
    for _, fighterObj in FighterController.Objects do
        local player = fighterObj.Player
        if not player then continue end
        if not fighterObj.Entity or not fighterObj.Entity:IsAlive() or fighterObj:Get("IsSpectating") then
            deflecting[player] = false
            continue
        end
        local equipped = fighterObj.EquippedItem
        local isKatana = equipped and equipped.ViewModel and equipped.ViewModel.Name == "Katana"
        local isDeflecting = false
        if isKatana then
            isDeflecting = (equipped._attack_cooldown and equipped._attack_cooldown > tick()) or false
        end
        deflecting[player] = isDeflecting
    end
end

local function isEnemy(player)
    if player == lplr then return false end
    local duel = SpectateController.CurrentDuelSubject
    local localDueler = duel and duel:GetDueler(lplr)
    local localTeam = localDueler and localDueler:Get("TeamID") or nil
    if localTeam and duel and duel.Duelers then
        for _, dueler in duel.Duelers do
            if dueler.Player == player then
                return dueler:Get("TeamID") ~= localTeam
            end
        end
    end
    local pTeam = player:GetAttribute("TeamID")
    local lTeam = lplr:GetAttribute("TeamID")
    if pTeam and lTeam then return pTeam ~= lTeam end
    return true
end

local function pickTarget()
    local char = lplr.Character
    if not char then return nil, nil, nil end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil, nil, nil end
    local cfg = getgenv().Config
    local bestPlayer, bestRoot, bestHead = nil, nil, nil
    local bestScore = math.huge
    for _, player in plrs:GetPlayers() do
        if not isEnemy(player) then continue end
        local pChar = player.Character
        if not pChar then continue end
        if pChar:FindFirstChildOfClass("ForceField") then continue end
        local pHum = pChar:FindFirstChildWhichIsA("Humanoid")
        if not pHum or pHum.Health <= 0 then continue end
        local pRoot = pChar:FindFirstChild("HumanoidRootPart")
        local pHead = pChar:FindFirstChild("Head")
        if not (pRoot and pHead) then continue end
        local dist = (myRoot.Position - pRoot.Position).Magnitude
        if dist > cfg.MaxDist then continue end
        local score = dist
        if deflecting[player] then score = score + 1000 end
        if cfg.LowestHealth then score = score + pHum.Health * 2 end
        if score < bestScore then
            bestScore = score
            bestPlayer, bestRoot, bestHead = player, pRoot, pHead
        end
    end
    return bestPlayer, bestRoot, bestHead
end

local function hasKnifeViewModel(targetPlayer)
    if not targetPlayer then return false end
    local viewModels = ws:FindFirstChild("ViewModels")
    if not viewModels then return false end
    local targetName = targetPlayer.Name
    for _, model in viewModels:GetChildren() do
        if model:IsA("Model") and string.find(model.Name, targetName, 1, true) and string.find(model.Name, "Knife", 1, true) then
            return true
        end
    end
    return false
end

local restoreBound = false
local function applyDesync(desyncCF)
    local myRoot = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local oldCF, oldVel, oldRotVel = myRoot.CFrame, myRoot.Velocity, myRoot.RotVelocity
    myRoot.CFrame = desyncCF
    if restoreBound then return end
    restoreBound = true
    runS:BindToRenderStep("__restore", 101, function()
        if myRoot then
            myRoot.CFrame = oldCF
            myRoot.Velocity = oldVel
            myRoot.RotVelocity = oldRotVel
        end
        runS:UnbindFromRenderStep("__restore")
        restoreBound = false
    end)
end

runS.Heartbeat:Connect(function()
    updateDeflection()
    local cfg = getgenv().Config
    local targetPlayer, targetRoot, targetHead = pickTarget()
    local desyncCF = nil

    if targetRoot and targetHead then
        if cfg.DesyncMode == "KnifeAware" then
            if hasKnifeViewModel(targetPlayer) then
                desyncCF = CFrame.lookAt((targetRoot.CFrame * CFrame.new(0, cfg.KnifeHoverHeight, cfg.KnifeBehindOffset)).Position, targetHead.Position)
            else
                desyncCF = CFrame.lookAt((targetRoot.CFrame * CFrame.new(0, 3, -20)).Position, targetHead.Position)
            end
        elseif cfg.DesyncMode == "Jitter" then
            local r = cfg.JitterRange
            local jitterPos = targetHead.Position + Vector3.new(math.random(-r, r), math.random(-r, r), math.random(-r, r))
            desyncCF = CFrame.lookAt(jitterPos, targetHead.Position)
        elseif cfg.DesyncMode == "Orbit" then
            local a = tick() * cfg.OrbitSpeed
            local offset = CFrame.new(math.cos(a) * cfg.OrbitRadius, 4, math.sin(a) * cfg.OrbitRadius)
            desyncCF = CFrame.lookAt((targetRoot.CFrame * offset).Position, targetHead.Position)
        end
    end

    if desyncCF then applyDesync(desyncCF) end

    if not cfg.Enabled then return end
    if not (targetPlayer and targetHead and targetRoot) then return end
    if deflecting[targetPlayer] then return end
    if not lplr.Character or not lplr.Character:FindFirstChild("HumanoidRootPart") then return end
    if not FighterController.LocalFighter then return end

    local item = FighterController.LocalFighter.EquippedItem
    if not item then return end

    local info = rawget(item, "Info")
    local data = rawget(item, "Data")
    if info and info.Type == "Gun" and data and data.Ammo <= 0 then return end

    local rate = (cfg.FFAMode and cfg.FFAFireBoost) and 0 or cfg.FireRate
    if tick() - lastFire < rate then return end
    lastFire = tick()

    local originPos = targetRoot.Position
    local aimCF = CFrame.lookAt(originPos, targetHead.Position)

    local cameradata = {}
    cameradata[utf8.char(1)] = {
        [utf8.char(0)] = util:EncodeCFrame(aimCF),
        [utf8.char(1)] = util:EncodeCFrame(targetHead.CFrame),
        [utf8.char(2)] = targetHead,
        [utf8.char(3)] = util:EncodeCFrame(CFrame.new(0, 0, 0))
    }

    if info and info.Type == "Melee" then
        local anim = enum:ToEnum("AttackAnimation1")
        if anim then
            repS.Remotes.Replication.Fighter.UseItem:FireServer(item:Get("ObjectID"), enum:ToEnum("StartShooting"), { [utf8.char(1)] = cameradata[utf8.char(1)], [utf8.char(2)] = anim }, nil)
            return
        end
    end

    repS.Remotes.Replication.Fighter.UseItem:FireServer(item:Get("ObjectID"), enum:ToEnum("StartShooting"), cameradata, nil)
end)

local ffa = { AutoRespawn = true, DropVacuum = true }
getgenv().FFA = ffa

local function forceRemoteRespawn()
    pcall(function()
        local remotesFolder = repS:FindFirstChild("Remotes")
        if not remotesFolder then return end
        local duelsFolder = remotesFolder:FindFirstChild("Duels")
        if not duelsFolder then return end
        local respawnRemote = duelsFolder:FindFirstChild("RespawnNow")
        if respawnRemote and respawnRemote:IsA("RemoteEvent") then
            respawnRemote:FireServer()
        end
    end)
end

lplr.CharacterAdded:Connect(function(newCharacter)
    local humanoid = newCharacter:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        if not ffa.AutoRespawn then return end
        task.spawn(function()
            while ffa.AutoRespawn do
                local char = lplr.Character
                if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then break end
                forceRemoteRespawn()
                task.wait(0.1)
            end
        end)
    end)
end)

local visitedDrops = {}
local function handleNewDrop(object)
    if not ffa.DropVacuum then return end
    if not (object:IsA("BasePart") and object.Name == "_drop") then return end
    if visitedDrops[object] then return end
    visitedDrops[object] = true
    task.wait()
    pcall(function()
        local char = lplr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if object:IsDescendantOf(ws) and hrp then
            object.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
            object.Anchored = true
            object.CanCollide = false
            object.Transparency = 1
            for _, child in pairs(object:GetDescendants()) do
                if child:IsA("BasePart") or child:IsA("UnionOperation") or child:IsA("MeshPart") then
                    pcall(function() child.Transparency = 1; child.CanCollide = false end)
                elseif child:IsA("BillboardGui") or child:IsA("SurfaceGui") or child:IsA("ParticleEmitter") or child:IsA("SelectionBox") then
                    pcall(function() child.Enabled = false end)
                end
            end
        end
    end)
end

for _, object in ipairs(ws:GetDescendants()) do
    if object:IsA("BasePart") and object.Name == "_drop" then visitedDrops[object] = true end
end
ws.DescendantAdded:Connect(handleNewDrop)
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local Colors = {
    Bg = Color3.fromRGB(25, 15, 35),
    Panel = Color3.fromRGB(40, 25, 55),
    Element = Color3.fromRGB(60, 40, 80),
    Accent = Color3.fromRGB(255, 105, 180),
    Text = Color3.fromRGB(240, 240, 240)
}

local function Create(className, properties)
    local instance = Instance.new(className)
    for k, v in pairs(properties) do instance[k] = v end
    return instance
end

local ScreenGui = Create("ScreenGui", { Name = "BestRageV3_UI", ResetOnSpawn = false, Parent = PlayerGui })
local ToggleBtn = Create("TextButton", { Size = UDim2.new(0, 80, 0, 35), Position = UDim2.new(0, 20, 0.5, -17), BackgroundColor3 = Colors.Panel, Text = "MENU", TextColor3 = Colors.Accent, Font = Enum.Font.GothamBold, TextSize = 14, Parent = ScreenGui })
Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ToggleBtn })
Create("UIStroke", { Color = Colors.Accent, Thickness = 1.5, Parent = ToggleBtn })

-- Mobile friendly compact size
local MainFrame = Create("Frame", { Name = "Main", Size = UDim2.new(0, 320, 0, 380), Position = UDim2.new(0.5, -160, 0.5, -190), BackgroundColor3 = Colors.Bg, BorderSizePixel = 0, Parent = ScreenGui, ClipsDescendants = true, Visible = false })
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
    TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 320, 0, 380) }):Play()
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

local TopBar = Create("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = MainFrame })
Create("TextLabel", { Text = "CRISIS+ | MOBILE", Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, TextColor3 = Colors.Accent, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar })
local CloseBtn = Create("TextButton", { Text = "X", Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -40, 0.5, -15), BackgroundTransparency = 1, TextColor3 = Colors.Text, Font = Enum.Font.GothamBold, TextSize = 16, Parent = TopBar })
CloseBtn.MouseButton1Click:Connect(closeMenu)

-- Tab System
local TabContainer = Create("Frame", { Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 10, 0, 45), BackgroundTransparency = 1, Parent = MainFrame })
Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), Parent = TabContainer })

local CombatBtn = Create("TextButton", { Size = UDim2.new(0.33, -3, 1, 0), BackgroundColor3 = Colors.Accent, Text = "Combat", TextColor3 = Colors.Bg, Font = Enum.Font.GothamBold, TextSize = 12, Parent = TabContainer })
Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = CombatBtn })
local DesyncBtn = Create("TextButton", { Size = UDim2.new(0.33, -3, 1, 0), BackgroundColor3 = Colors.Element, Text = "Desync", TextColor3 = Colors.Text, Font = Enum.Font.GothamBold, TextSize = 12, Parent = TabContainer })
Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = DesyncBtn })
local FFABtn = Create("TextButton", { Size = UDim2.new(0.33, -3, 1, 0), BackgroundColor3 = Colors.Element, Text = "FFA", TextColor3 = Colors.Text, Font = Enum.Font.GothamBold, TextSize = 12, Parent = TabContainer })
Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = FFABtn })

local ContentArea = Create("Frame", { Size = UDim2.new(1, -20, 1, -90), Position = UDim2.new(0, 10, 0, 80), BackgroundColor3 = Colors.Panel, Parent = MainFrame })
Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ContentArea })
Create("UIStroke", { Color = Colors.Accent, Thickness = 1, Transparency = 0.5, Parent = ContentArea })

local function CreatePage()
    local page = Create("ScrollingFrame", { Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0, 5, 0, 5), BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = Colors.Accent, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false, Parent = ContentArea })
    Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = page })
    return page
end

local CombatPage = CreatePage()
local DesyncPage = CreatePage()
local FFAPage = CreatePage()

local function SwitchTab(page, btn)
    CombatPage.Visible = false; DesyncPage.Visible = false; FFAPage.Visible = false
    page.Visible = true
    CombatBtn.BackgroundColor3 = Colors.Element; DesyncBtn.BackgroundColor3 = Colors.Element; FFABtn.BackgroundColor3 = Colors.Element
    CombatBtn.TextColor3 = Colors.Text; DesyncBtn.TextColor3 = Colors.Text; FFABtn.TextColor3 = Colors.Text
    btn.BackgroundColor3 = Colors.Accent; btn.TextColor3 = Colors.Bg
end

CombatBtn.MouseButton1Click:Connect(function() SwitchTab(CombatPage, CombatBtn) end)
DesyncBtn.MouseButton1Click:Connect(function() SwitchTab(DesyncPage, DesyncBtn) end)
FFABtn.MouseButton1Click:Connect(function() SwitchTab(FFAPage, FFABtn) end)

-- UI Builders
local function CreateHeader(text, parent)
    local frame = Create("Frame", { Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1, Parent = parent })
    Create("TextLabel", { Text = text, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = Colors.Accent, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
end

local function CreateToggle(name, getState, setState, parent)
    local isChecked = getState()
    local frame = Create("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Parent = parent })
    Create("TextLabel", { Text = name, Size = UDim2.new(0.75, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = Colors.Text, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
    
    local Pill = Create("Frame", { Size = UDim2.new(0, 34, 0, 16), Position = UDim2.new(1, -34, 0.5, -8), BackgroundColor3 = isChecked and Colors.Accent or Colors.Element, Parent = frame })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Pill })
    local Knob = Create("Frame", { Size = UDim2.new(0, 12, 0, 12), Position = isChecked and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6), BackgroundColor3 = Color3.fromRGB(255,255,255), Parent = Pill })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Knob })
    
    local Btn = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = frame })
    Btn.MouseButton1Click:Connect(function()
        isChecked = not isChecked
        setState(isChecked)
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
        local val = min + (max - min) * percent
        if max <= 1 or (max - min) < 10 then val = math.round(val * 1000) / 1000 else val = math.floor(val) end
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

-- PAGE 1: COMBAT
CreateHeader("GENERAL", CombatPage)
CreateToggle("Rage (Master)", function() return getgenv().Config.Enabled end, function(v) getgenv().Config.Enabled = v end, CombatPage)
CreateDropdown("Weapon Slot", {"Primary", "Secondary", "Melee"}, getgenv().Config.WeaponSlot, CombatPage, function(val) getgenv().Config.WeaponSlot = val end)
CreateToggle("Lowest Health Target", function() return getgenv().Config.LowestHealth end, function(v) getgenv().Config.LowestHealth = v end, CombatPage)
CreateSlider("Fire Rate (0=inst)", 0, 0.1, getgenv().Config.FireRate, CombatPage, function(val) getgenv().Config.FireRate = val end)
CreateSlider("Max Distance", 50, 500, getgenv().Config.MaxDist, CombatPage, function(val) getgenv().Config.MaxDist = val end)

-- PAGE 2: DESYNC
CreateHeader("DESYNC SETTINGS", DesyncPage)
CreateDropdown("Desync Mode", {"KnifeAware", "Jitter", "Orbit", "Off"}, getgenv().Config.DesyncMode, DesyncPage, function(val) getgenv().Config.DesyncMode = val end)
CreateSlider("Knife Hover Height", 5, 15, getgenv().Config.KnifeHoverHeight, DesyncPage, function(val) getgenv().Config.KnifeHoverHeight = val end)
CreateSlider("Knife Behind Offset", -8, 0, getgenv().Config.KnifeBehindOffset, DesyncPage, function(val) getgenv().Config.KnifeBehindOffset = val end)
CreateSlider("Jitter Range", 1, 8, getgenv().Config.JitterRange, DesyncPage, function(val) getgenv().Config.JitterRange = val end)
CreateSlider("Orbit Speed", 1, 12, getgenv().Config.OrbitSpeed, DesyncPage, function(val) getgenv().Config.OrbitSpeed = val end)
CreateSlider("Orbit Radius", 6, 30, getgenv().Config.OrbitRadius, DesyncPage, function(val) getgenv().Config.OrbitRadius = val end)

-- PAGE 3: FFA
CreateHeader("FREE FOR ALL SETTINGS", FFAPage)
CreateToggle("FFA Mode (Boost)", function() return getgenv().Config.FFAMode end, function(v) getgenv().Config.FFAMode = v end, FFAPage)
CreateToggle("FFA Fire Boost", function() return getgenv().Config.FFAFireBoost end, function(v) getgenv().Config.FFAFireBoost = v end, FFAPage)
CreateToggle("FFA Auto-Respawn", function() return getgenv().FFA.AutoRespawn end, function(v) getgenv().FFA.AutoRespawn = v end, FFAPage)
CreateToggle("FFA Drop Vacuum", function() return getgenv().FFA.DropVacuum end, function(v) getgenv().FFA.DropVacuum = v end, FFAPage)

local UnloadBtn = Create("TextButton", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Colors.Element, Text = "Unload Script", TextColor3 = Colors.Text, Font = Enum.Font.GothamBold, TextSize = 12, Parent = FFAPage })
Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = UnloadBtn })
UnloadBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Initialize UI and auto-size scrollbars
SwitchTab(CombatPage, CombatBtn)

local function UpdateCanvas(page)
    page.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, page.UIListLayout.AbsoluteContentSize.Y + 10)
    end)
    task.wait()
    page.CanvasSize = UDim2.new(0, 0, 0, page.UIListLayout.AbsoluteContentSize.Y + 10)
end
UpdateCanvas(CombatPage)
UpdateCanvas(DesyncPage)
UpdateCanvas(FFAPage)

print("[BestRage v3.1] Mobile Tabbed UI Loaded")