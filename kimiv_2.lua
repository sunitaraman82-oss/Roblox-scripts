local repS = cloneref(game:GetService("ReplicatedStorage"))
local plrs = cloneref(game:GetService("Players"))
local runS = cloneref(game:GetService("RunService"))
local ws = cloneref(game:GetService("Workspace"))
local uis = cloneref(game:GetService("UserInputService"))
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
    AimFromDesync = true,
    Prediction = true,
    PredictionTime = 0.05,
    StickyTarget = true,
    OrbitSpeed = 2.0,
    OrbitRadius = 14,
    JitterRange = 3,
    MaxDist = 500
}

local slots = { Primary = 1, Secondary = 2, Melee = 3 }
local function getSlotNumber()
    return slots[getgenv().Config.WeaponSlot] or 3
end

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
local lockedTarget = nil
local deflecting = {}
plrs.PlayerRemoving:Connect(function(p)
    deflecting[p] = nil
    if lockedTarget == p then lockedTarget = nil end
end)

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

local function scoreTarget(player, root, dist)
    local score = dist
    if deflecting[player] then score = score + 1000 end
    if lockedTarget == player then score = score - 250 end
    return score
end

local function pickTarget()
    local char = lplr.Character
    if not char then return nil, nil, nil end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil, nil, nil end
    local bestPlayer, bestRoot, bestHead, bestScore = nil, nil, nil, math.huge
    for _, player in plrs:GetPlayers() do
        if not isEnemy(player) then continue end
        local pChar = player.Character
        if not pChar then continue end
        if pChar:FindFirstChildOfClass("ForceField") then continue end
        local pRoot = pChar:FindFirstChild("HumanoidRootPart")
        local pHead = pChar:FindFirstChild("Head")
        local pHum = pChar:FindFirstChildWhichIsA("Humanoid")
        if not (pRoot and pHead and pHum and pHum.Health > 0) then continue end
        local dist = (myRoot.Position - pRoot.Position).Magnitude
        if dist > getgenv().Config.MaxDist then continue end
        local score = scoreTarget(player, pRoot, dist)
        if score < bestScore then
            bestScore = score
            bestPlayer, bestRoot, bestHead = player, pRoot, pHead
        end
    end
    return bestPlayer, bestRoot, bestHead
end

local function getTarget()
    local cfg = getgenv().Config
    if cfg.StickyTarget and lockedTarget then
        local pChar = lockedTarget.Character
        local ok = pChar
            and isEnemy(lockedTarget)
            and not pChar:FindFirstChildOfClass("ForceField")
            and pChar:FindFirstChildWhichIsA("Humanoid")
            and pChar:FindFirstChildWhichIsA("Humanoid").Health > 0
        if ok then
            local pRoot = pChar:FindFirstChild("HumanoidRootPart")
            local pHead = pChar:FindFirstChild("Head")
            local myRoot = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
            if pRoot and pHead and myRoot then
                if (myRoot.Position - pRoot.Position).Magnitude <= cfg.MaxDist then
                    return lockedTarget, pRoot, pHead
                end
            end
        end
        lockedTarget = nil
    end
    local tp, tr, th = pickTarget()
    if tp then lockedTarget = tp end
    return tp, tr, th
end

local function hasKnifeViewModel(targetPlayer)
    if not targetPlayer then return false end
    local viewModels = ws:FindFirstChild("ViewModels")
    if not viewModels then return false end
    local targetName = targetPlayer.Name
    for _, model in viewModels:GetChildren() do
        if model:IsA("Model")
            and string.find(model.Name, targetName, 1, true)
            and string.find(model.Name, "Knife", 1, true) then
            return true
        end
    end
    return false
end

local function predictPoint(targetRoot, targetHead)
    local cfg = getgenv().Config
    if not cfg.Prediction then return targetHead.Position end
    local vel = targetRoot.AssemblyLinearVelocity
    if not vel then return targetHead.Position end
    return targetHead.Position + vel * cfg.PredictionTime
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
    local targetPlayer, targetRoot, targetHead = getTarget()
    local desyncCF = nil

    if targetRoot and targetHead then
        if cfg.DesyncMode == "KnifeAware" then
            local offset = hasKnifeViewModel(targetPlayer)
                and CFrame.new(0, 6, 0)
                or CFrame.new(0, 3, -20)
            desyncCF = CFrame.lookAt((targetRoot.CFrame * offset).Position, targetHead.Position)
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

    if tick() - lastFire < cfg.FireRate then return end
    lastFire = tick()

    local aimPoint = predictPoint(targetRoot, targetHead)
    local originPos = (desyncCF and cfg.AimFromDesync) and desyncCF.Position or targetRoot.Position
    local aimCF = CFrame.lookAt(originPos, aimPoint)

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
            repS.Remotes.Replication.Fighter.UseItem:FireServer(
                item:Get("ObjectID"),
                enum:ToEnum("StartShooting"),
                { [utf8.char(1)] = cameradata[utf8.char(1)], [utf8.char(2)] = anim },
                nil
            )
            return
        end
    end

    repS.Remotes.Replication.Fighter.UseItem:FireServer(
        item:Get("ObjectID"),
        enum:ToEnum("StartShooting"),
        cameradata,
        nil
    )
end)

local function buildUI()
    local parent = (gethui and gethui()) or cloneref(game:GetService("CoreGui"))
    local old = parent:FindFirstChild("BestRageV2")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "BestRageV2"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = parent

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 270, 0, 300)
    main.Position = UDim2.new(0.5, -135, 0.5, -150)
    main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    main.BorderSizePixel = 0
    main.Active = true
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Color3.fromRGB(75, 0, 130)
    stroke.Thickness = 1.5

    local dragging, dragInput, dragStart, startPos
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    uis.InputChanged:Connect(function(input)
        if dragging and dragInput and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 35)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "BEST RAGE v2 — CRISIS PROTOCOL"
    title.TextColor3 = Color3.fromRGB(220, 180, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = main

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 25, 0, 25)
    close.Position = UDim2.new(1, -32, 0, 5)
    close.BackgroundColor3 = Color3.fromRGB(45, 20, 20)
    close.Text = "X"
    close.TextColor3 = Color3.fromRGB(255, 100, 100)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 12
    close.Parent = main
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 5)
    close.MouseButton1Click:Connect(function() gui.Enabled = false end)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -45)
    scroll.Position = UDim2.new(0, 10, 0, 40)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Color3.fromRGB(75, 0, 130)
    scroll.Parent = main

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    local builders = {}

    builders.toggle = function(spec)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -50, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = spec.name
        lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = btn

        local ind = Instance.new("Frame")
        ind.Size = UDim2.new(0, 30, 0, 16)
        ind.Position = UDim2.new(1, -40, 0.5, -8)
        ind.BackgroundColor3 = spec.get() and Color3.fromRGB(100, 0, 180) or Color3.fromRGB(40, 40, 45)
        ind.Parent = btn
        Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 12, 0, 12)
        knob.Position = spec.get() and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.Parent = ind
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        btn.MouseButton1Click:Connect(function()
            spec.set(not spec.get())
            ind.BackgroundColor3 = spec.get() and Color3.fromRGB(100, 0, 180) or Color3.fromRGB(40, 40, 45)
            knob.Position = spec.get() and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        end)
    end

    builders.slider = function(spec)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 45)
        frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        frame.Parent = scroll
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -10, 0, 20)
        lbl.Position = UDim2.new(0, 10, 0, 4)
        lbl.BackgroundTransparency = 1
        lbl.Text = spec.name .. ": " .. tostring(spec.get())
        lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frame

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -20, 0, 6)
        track.Position = UDim2.new(0, 10, 0, 30)
        track.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        track.Parent = frame
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((spec.get() - spec.min) / (spec.max - spec.min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(100, 0, 180)
        fill.Parent = track
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local sliding = false
        local function update(input)
            local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = spec.min + (spec.max - spec.min) * pos
            if spec.max <= 0.5 then val = math.floor(val * 10000) / 10000 else val = math.floor(val * 10) / 10 end
            spec.set(val)
            lbl.Text = spec.name .. ": " .. tostring(val)
            fill.Size = UDim2.new(pos, 0, 1, 0)
        end
        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = true
                update(input)
            end
        end)
        uis.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliding = false end
        end)
        uis.InputChanged:Connect(function(input)
            if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input) end
        end)
    end

    builders.dropdown = function(spec)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 55)
        frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        frame.Parent = scroll
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -10, 0, 20)
        lbl.Position = UDim2.new(0, 10, 0, 4)
        lbl.BackgroundTransparency = 1
        lbl.Text = spec.name
        lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frame

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 24)
        btn.Position = UDim2.new(0, 10, 0, 26)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        btn.Text = spec.get()
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 12
        btn.Parent = frame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

        btn.MouseButton1Click:Connect(function()
            local idx = (table.find(spec.options, spec.get()) or 1) % #spec.options + 1
            spec.set(spec.options[idx])
            btn.Text = spec.options[idx]
        end)
    end

    local function cfgGet(key) return getgenv().Config[key] end
    local function cfgSet(key, val) getgenv().Config[key] = val end

    local specs = {
        { kind = "toggle",   name = "Rage (Master)",        get = function() return cfgGet("Enabled") end,            set = function(v) cfgSet("Enabled", v) end },
        { kind = "dropdown", name = "Weapon Slot",          options = {"Primary", "Secondary", "Melee"},               get = function() return cfgGet("WeaponSlot") end,         set = function(v) cfgSet("WeaponSlot", v) end },
        { kind = "dropdown", name = "Desync Mode",          options = {"KnifeAware", "Jitter", "Orbit", "Off"},        get = function() return cfgGet("DesyncMode") end,         set = function(v) cfgSet("DesyncMode", v) end },
        { kind = "toggle",   name = "Aim From Desync Pos",  get = function() return cfgGet("AimFromDesync") end,      set = function(v) cfgSet("AimFromDesync", v) end },
        { kind = "toggle",   name = "Sticky Target",        get = function() return cfgGet("StickyTarget") end,       set = function(v) cfgSet("StickyTarget", v) end },
        { kind = "toggle",   name = "Velocity Prediction",  get = function() return cfgGet("Prediction") end,         set = function(v) cfgSet("Prediction", v) end },
        { kind = "slider",   name = "Fire Rate (0=inst)",   min = 0, max = 0.1,                                        get = function() return cfgGet("FireRate") end,           set = function(v) cfgSet("FireRate", v) end },
        { kind = "slider",   name = "Prediction Lead (s)",  min = 0, max = 0.3,                                        get = function() return cfgGet("PredictionTime") end,     set = function(v) cfgSet("PredictionTime", v) end },
        { kind = "slider",   name = "Orbit Speed",          min = 0.5, max = 8,                                        get = function() return cfgGet("OrbitSpeed") end,         set = function(v) cfgSet("OrbitSpeed", v) end },
        { kind = "slider",   name = "Orbit Radius",         min = 6, max = 30,                                         get = function() return cfgGet("OrbitRadius") end,        set = function(v) cfgSet("OrbitRadius", v) end },
        { kind = "slider",   name = "Jitter Range",         min = 1, max = 8,                                          get = function() return cfgGet("JitterRange") end,        set = function(v) cfgSet("JitterRange", v) end },
    }

    for _, spec in specs do
        builders[spec.kind](spec)
    end

    uis.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
            gui.Enabled = not gui.Enabled
        end
    end)
end

buildUI()
print("[BestRage v2] loaded | RightShift = UI | no auto-swap | sticky target + prediction + orbit desync")
