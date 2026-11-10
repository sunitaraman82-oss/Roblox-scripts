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
    WeaponSlot = "Primary",
    -- void spam
    VoidSpam = true,
    VoidInterval = 0.02,
    VoidMinDist = 100,
    VoidMaxDist = 150,
    -- attack dodge
    DodgeOnAttack = true,
    DodgeDepth = 500,          -- how far below the map we dive
    DodgeHold = 0.15,          -- seconds we stay in the void per detected attack
    -- anti-katana
    AntiKatana = true,
    KatanaMinDist = 120,       -- katana users never see us closer than this
    -- anti-subspace tripmine
    AntiTripmine = true,
    TripmineRadius = 15,       -- no hop lands within this of a mine
    MaxDist = 500
}

local slots = { Primary = 1, Secondary = 2, Melee = 3 }
local function getSlotNumber()
    return slots[getgenv().Config.WeaponSlot] or 1
end

-- equip keep-alive (holds primary, never swaps)
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
local attacking = {}   -- player -> timestamp of last detected attack
local katanaUsers = {} -- player -> bool
local restoreBound = false

plrs.PlayerRemoving:Connect(function(p)
    attacking[p] = nil
    katanaUsers[p] = nil
end)

-- per-frame fighter intel: who's attacking, who's holding a katana
local function updateFighterIntel()
    if not FighterController or not FighterController.Objects then return end
    for _, fighterObj in FighterController.Objects do
        local player = fighterObj.Player
        if not player then continue end
        if not fighterObj.Entity or not fighterObj.Entity:IsAlive() or fighterObj:Get("IsSpectating") then
            attacking[player] = nil
            katanaUsers[player] = false
            continue
        end
        local equipped = fighterObj.EquippedItem
        local vm = equipped and equipped.ViewModel
        if vm and vm.Name == "Katana" then
            katanaUsers[player] = true
            if equipped._attack_cooldown and equipped._attack_cooldown > tick() then
                attacking[player] = tick()
            end
        else
            katanaUsers[player] = false
            -- gun users: muzzle flash / firing anim on the viewmodel marks a shot
            if vm then
                local flash = vm:FindFirstChild("MuzzleFlash") or vm:FindFirstChild("Fire") or vm:FindFirstChild("Shoot")
                if flash and (flash:IsA("ParticleEmitter") and flash.Enabled) then
                    attacking[player] = tick()
                end
            end
        end
    end
end

local function isAttacking(player)
    local t = attacking[player]
    return t ~= nil and (tick() - t) < getgenv().Config.DodgeHold
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
        local score = dist + pHum.Health * 2
        if score < bestScore then
            bestScore = score
            bestPlayer, bestRoot, bestHead = player, pRoot, pHead
        end
    end
    return bestPlayer, bestRoot, bestHead
end

-- // ANTI-SUBSPACE TRIPMINE //
-- scan workspace for placed mines; also check if a player is holding one
local function findMines()
    local mines = {}
    for _, obj in ws:GetDescendants() do
        local n = obj.Name
        if n and (string.find(n, "Subspace", 1, true) or string.find(n, "Tripmine", 1, true)
            or string.find(n, "TripMine", 1, true)) then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
            if part then table.insert(mines, part) end
        end
    end
    return mines
end

local mineCache = {}
task.spawn(function()
    while true do
        task.wait(0.5)
        mineCache = findMines()
    end
end)

local function nearMine(pos, radius)
    for _, mine in mineCache do
        if mine and mine.Parent and (mine.Position - pos).Magnitude <= radius then
            return true
        end
    end
    return false
end

-- // UNPREDICTABLE VOID SPAM //
-- pattern roll: 1 = under (deep below), 2 = near (min dist), 3 = far (max dist)
-- then a fully random direction on the sphere so no two hops look alike
local lastHop = 0
local currentOffset = nil

local function rollHop(targetRoot, isKatanaTarget)
    local cfg = getgenv().Config
    local minD = cfg.VoidMinDist
    local maxD = cfg.VoidMaxDist
    if isKatanaTarget and cfg.AntiKatana then
        minD = math.max(minD, cfg.KatanaMinDist) -- anti-katana: never close
        maxD = math.max(maxD, minD + 30)
    end
    local roll = math.random(1, 3)
    local dist
    local yBias = 0
    if roll == 1 then
        dist = math.random(minD, minD + 20)
        yBias = -math.random(40, 80) -- under them
    elseif roll == 2 then
        dist = math.random(minD, minD + 15) -- near edge
    else
        dist = math.random(maxD - 15, maxD) -- far edge
        yBias = math.random(-10, 40)
    end
    -- random direction on a sphere
    local theta = math.random() * math.pi * 2
    local phi = math.acos(2 * math.random() - 1)
    local dir = Vector3.new(
        math.sin(phi) * math.cos(theta),
        math.cos(phi),
        math.sin(phi) * math.sin(theta)
    )
    local offset = dir * dist + Vector3.new(0, yBias, 0)
    -- anti-tripsmine: if the landing zone is hot, mirror the hop instead
    if cfg.AntiTripmine then
        local landPos = targetRoot.Position + offset
        if nearMine(landPos, cfg.TripmineRadius) then
            offset = -offset
            if nearMine(targetRoot.Position + offset, cfg.TripmineRadius) then
                offset = offset + Vector3.new(0, cfg.TripmineRadius * 2, 0) -- hop above the blast
            end
        end
    end
    return offset
end

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
    updateFighterIntel()
    local cfg = getgenv().Config
    local targetPlayer, targetRoot, targetHead = pickTarget()
    local desyncCF = nil

    if targetRoot and targetHead then
        if cfg.DodgeOnAttack and isAttacking(targetPlayer) then
            -- they're swinging/shooting -> dive to the void, shots hit nothing
            local voidPos = targetRoot.Position + Vector3.new(0, -cfg.DodgeDepth, 0)
            desyncCF = CFrame.lookAt(voidPos, targetHead.Position)
        elseif cfg.VoidSpam then
            if tick() - lastHop >= cfg.VoidInterval then
                lastHop = tick()
                currentOffset = rollHop(targetRoot, cfg.AntiKatana and katanaUsers[targetPlayer] == true)
            end
            if currentOffset then
                local pos = targetRoot.Position + currentOffset
                desyncCF = CFrame.lookAt(pos, targetHead.Position)
            end
        end
    end

    if desyncCF then applyDesync(desyncCF) end

    if not cfg.Enabled then return end
    if not (targetPlayer and targetHead and targetRoot) then return end
    if not lplr.Character or not lplr.Character:FindFirstChild("HumanoidRootPart") then return end
    if not FighterController.LocalFighter then return end

    local item = FighterController.LocalFighter.EquippedItem
    if not item then return end

    local info = rawget(item, "Info")
    local data = rawget(item, "Data")
    if info and info.Type == "Gun" and data and data.Ammo <= 0 then return end

    if tick() - lastFire < cfg.FireRate then return end
    lastFire = tick()

    -- redirect: shot re-aims at the head from the real position every fire tick
    local aimCF = CFrame.lookAt(targetRoot.Position, targetHead.Position)
    local cameradata = {}
    cameradata[utf8.char(1)] = {
        [utf8.char(0)] = util:EncodeCFrame(aimCF),
        [utf8.char(1)] = util:EncodeCFrame(targetHead.CFrame),
        [utf8.char(2)] = targetHead,
        [utf8.char(3)] = util:EncodeCFrame(CFrame.new(0, 0, 0))
    }

    repS.Remotes.Replication.Fighter.UseItem:FireServer(
        item:Get("ObjectID"),
        enum:ToEnum("StartShooting"),
        cameradata,
        nil
    )
end)

-- // UI //
local function buildUI()
    local parent = (gethui and gethui()) or cloneref(game:GetService("CoreGui"))
    local old = parent:FindFirstChild("VoidRageUI")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "VoidRageUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = parent

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 270, 0, 320)
    main.Position = UDim2.new(0.5, -135, 0.5, -160)
    main.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    main.BorderSizePixel = 0
    main.Active = true
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Color3.fromRGB(130, 0, 75)
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
    title.Text = "VOID RAGE — WHERED HE GO"
    title.TextColor3 = Color3.fromRGB(255, 180, 220)
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
    scroll.ScrollBarImageColor3 = Color3.fromRGB(130, 0, 75)
    scroll.Parent = main

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    local function cfgGet(key) return getgenv().Config[key] end
    local function cfgSet(key, val) getgenv().Config[key] = val end

    local builders = {}

    builders.toggle = function(spec)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -50, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = spec.name
        lbl.TextColor3 = Color3.fromRGB(210, 200, 210)
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = btn

        local ind = Instance.new("Frame")
        ind.Size = UDim2.new(0, 30, 0, 16)
        ind.Position = UDim2.new(1, -40, 0.5, -8)
        ind.BackgroundColor3 = spec.get() and Color3.fromRGB(180, 0, 100) or Color3.fromRGB(40, 40, 45)
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
            ind.BackgroundColor3 = spec.get() and Color3.fromRGB(180, 0, 100) or Color3.fromRGB(40, 40, 45)
            knob.Position = spec.get() and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        end)
    end

    builders.slider = function(spec)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 45)
        frame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        frame.Parent = scroll
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -10, 0, 20)
        lbl.Position = UDim2.new(0, 10, 0, 4)
        lbl.BackgroundTransparency = 1
        lbl.Text = spec.name .. ": " .. tostring(spec.get())
        lbl.TextColor3 = Color3.fromRGB(210, 200, 210)
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
        fill.BackgroundColor3 = Color3.fromRGB(180, 0, 100)
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

    local specs = {
        { kind = "toggle", name = "Rage (Master)",        get = function() return cfgGet("Enabled") end,      set = function(v) cfgSet("Enabled", v) end },
        { kind = "toggle", name = "UI Visible",           get = function() return getgenv().UIVisible end,    set = function(v) getgenv().UIVisible = v gui.Enabled = v end },
        { kind = "toggle", name = "Void Spam",            get = function() return cfgGet("VoidSpam") end,     set = function(v) cfgSet("VoidSpam", v) end },
        { kind = "toggle", name = "Dodge On Attack",      get = function() return cfgGet("DodgeOnAttack") end, set = function(v) cfgSet("DodgeOnAttack", v) end },
        { kind = "toggle", name = "Anti Katana",          get = function() return cfgGet("AntiKatana") end,   set = function(v) cfgSet("AntiKatana", v) end },
        { kind = "toggle", name = "Anti Subspace Mine",   get = function() return cfgGet("AntiTripmine") end, set = function(v) cfgSet("AntiTripmine", v) end },
        { kind = "slider", name = "Fire Rate (0=inst)",   min = 0, max = 0.1,                                get = function() return cfgGet("FireRate") end,     set = function(v) cfgSet("FireRate", v) end },
        { kind = "slider", name = "TP Interval (s)",      min = 0.01, max = 0.2,                             get = function() return cfgGet("VoidInterval") end, set = function(v) cfgSet("VoidInterval", v) end },
        { kind = "slider", name = "Void Min Dist",        min = 50, max = 140,                                get = function() return cfgGet("VoidMinDist") end,  set = function(v) cfgSet("VoidMinDist", v) end },
        { kind = "slider", name = "Void Max Dist",        min = 100, max = 200,                               get = function() return cfgGet("VoidMaxDist") end,  set = function(v) cfgSet("VoidMaxDist", v) end },
        { kind = "slider", name = "Dodge Depth",          min = 100, max = 800,                               get = function() return cfgGet("DodgeDepth") end,   set = function(v) cfgSet("DodgeDepth", v) end },
        { kind = "slider", name = "Katana Min Dist",      min = 60, max = 200,                                get = function() return cfgGet("KatanaMinDist") end, set = function(v) cfgSet("KatanaMinDist", v) end },
        { kind = "slider", name = "Mine Safe Radius",     min = 5, max = 40,                                  get = function() return cfgGet("TripmineRadius") end, set = function(v) cfgSet("TripmineRadius", v) end },
    }

    getgenv().UIVisible = true

    for _, spec in specs do
        builders[spec.kind](spec)
    end

    uis.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
            getgenv().UIVisible = not getgenv().UIVisible
            gui.Enabled = getgenv().UIVisible
        end
    end)
end

buildUI()
print("[VoidRage] loaded | RightShift = UI | void spam 100-150st @0.02s | attack-dodge | anti-katana | anti-tripmine")