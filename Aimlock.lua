
if getgenv().ZK_Unload then pcall(getgenv().ZK_Unload) end

local repS = cloneref(game:GetService("ReplicatedStorage"))
local plrs = cloneref(game:GetService("Players"))
local runS = cloneref(game:GetService("RunService"))
local ws   = cloneref(game:GetService("Workspace"))
local uis  = cloneref(game:GetService("UserInputService"))
local lplr = plrs.LocalPlayer
local PlayerGui = lplr:WaitForChild("PlayerGui")

local util = require(repS.Modules.Utility)
local enum = require(repS.Modules.EnumLibrary)
local FighterController = require(lplr.PlayerScripts.Controllers.FighterController)
local UseItemRemote = repS.Remotes.Replication.Fighter.UseItem
local RespawnRemote = repS.Remotes.Duels.RespawnNow

getgenv().Config = {
    Enabled        = true,
    FireRate       = 0.001,
    WeaponSlot     = "Primary",
    MaxDistance    = 1000,
    
    AntiExplosion  = true,
    AntiExplosionHeight = 300,
    
    DesyncEnabled  = true,
    DesyncMode     = "offscreen",
    DesyncHeight   = 1.0,
    DesyncBack     = 2.0,

    AntiAim        = true,
    AntiAimSpeed   = 360,
}

local slots = { Primary = 1, Secondary = 2, Melee = 3 }
local State = { unloaded = false, lastFire = 0, lastEquip = 0, target = nil, restoreConn = nil, connections = {} }

local function track(c)
    table.insert(State.connections, c)
    return c
end

track(lplr.CharacterAdded:Connect(function()
    task.wait(0.1)
    local char = lplr.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        pcall(function() RespawnRemote:FireServer() end)
    end
end))

track(task.spawn(function()
    while not State.unloaded do
        task.wait(0.5)
        if not getgenv().Config.Enabled then continue end
        if tick() - State.lastEquip < 0.5 then continue end
        State.lastEquip = tick()
        local lf = FighterController.LocalFighter
        if lf and not lf.EquippedItem then
            pcall(function() lf:EquipItem(slots[getgenv().Config.WeaponSlot] or 1) end)
        end
    end
end))

local function getClosestTarget()
    local char = lplr.Character
    if not char then return nil end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local closest, closestDist = nil, getgenv().Config.MaxDistance
    local myPos = myRoot.Position

    for _, obj in ipairs(ws:GetDescendants()) do
        if obj:IsA("Model") and obj ~= char and not plrs:GetPlayerFromCharacter(obj) then
            local hum = obj:FindFirstChildWhichIsA("Humanoid")
            if hum and hum.Health > 0 then
                local root = obj:FindFirstChild("HumanoidRootPart")
                local head = obj:FindFirstChild("Head") or obj:FindFirstChild("ZombieHead")
                
                if root and head then
                    local d = (myPos - root.Position).Magnitude
                    if d < closestDist then
                        closestDist = d
                        closest = { Model = obj, Root = root, Head = head, Hum = hum, Distance = d }
                    end
                end
            end
        end
    end
    return closest
end

local function computeDesyncCFrame(target, myRoot)
    local root, head = target.Root, target.Head
    local cfg = getgenv().Config
    local offset

    if cfg.DesyncMode == "offscreen" then
        return CFrame.lookAt(root.Position + Vector3.new(0, 1000, 0), head.Position)
    elseif cfg.DesyncMode == "behind" then
        offset = CFrame.new(0, cfg.DesyncHeight, cfg.DesyncBack)
    elseif cfg.DesyncMode == "front" then
        offset = CFrame.new(0, cfg.DesyncHeight, -cfg.DesyncBack)
    else
        offset = CFrame.new(0, cfg.DesyncHeight + 2, 0)
    end

    return CFrame.lookAt((root.CFrame * offset).Position, head.Position)
end

local function fireWithDesync(item, target)
    local char = lplr.Character
    if not char then return end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local cfg = getgenv().Config
    local originPos, aimPos = myRoot.Position, target.Head.Position

    if cfg.DesyncEnabled then
        local desyncCF = computeDesyncCFrame(target, myRoot)
        originPos = desyncCF.Position

        local oldCF, oldVel, oldRotVel = myRoot.CFrame, myRoot.Velocity, myRoot.RotVelocity
        myRoot.CFrame = desyncCF

        if State.restoreConn then State.restoreConn:Disconnect() end
        State.restoreConn = runS.RenderStepped:Connect(function()
            if myRoot and myRoot.Parent then
                myRoot.CFrame, myRoot.Velocity, myRoot.RotVelocity = oldCF, oldVel, oldRotVel
            end
            if State.restoreConn then State.restoreConn:Disconnect(); State.restoreConn = nil end
        end)
    end
    
    if cfg.AntiAim and myRoot then
        local spinAngle = math.rad((tick() * cfg.AntiAimSpeed) % 360)
        -- Spin the server-side CFrame violently to break zombie attacks/explosions
        myRoot.CFrame = CFrame.new(myRoot.Position) * CFrame.Angles(0, spinAngle, 0) * CFrame.Angles(math.rad(math.random(-90, 90)), 0, 0)
        
        if State.restoreConn then State.restoreConn:Disconnect() end
        State.restoreConn = runS.RenderStepped:Connect(function()
            if myRoot and myRoot.Parent then
                myRoot.CFrame, myRoot.Velocity, myRoot.RotVelocity = oldCF, oldVel, oldRotVel
            end
            if State.restoreConn then State.restoreConn:Disconnect(); State.restoreConn = nil end
        end)
    end

    local aimCF = CFrame.lookAt(originPos, aimPos)
    local rand = Vector3.new((math.random()-0.5)*0.02, (math.random()-0.5)*0.02, (math.random()-0.5)*0.02)
    local objSpaceHead = target.Head.CFrame:ToObjectSpace(CFrame.new(aimPos + rand))

    local cameraData = {
        [utf8.char(1)] = {
            [utf8.char(0)] = util:EncodeCFrame(aimCF),
            [utf8.char(1)] = util:EncodeCFrame(target.Head.CFrame),
            [utf8.char(2)] = target.Head,
            [utf8.char(3)] = util:EncodeCFrame(objSpaceHead),
        }
    }

    pcall(function()
        UseItemRemote:FireServer(item:Get("ObjectID"), enum:ToEnum("StartShooting"), cameraData, nil)
    end)
end

local currentlyDodging = false

local function dodgeExplosion()
    if currentlyDodging or not getgenv().Config.AntiExplosion then return end
    local char = lplr.Character
    if not char then return end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    currentlyDodging = true
    local originalCF = myRoot.CFrame
    
    myRoot.CFrame = originalCF + Vector3.new(0, getgenv().Config.AntiExplosionHeight, 0)
    
    task.delay(0.15, function()
        if myRoot and myRoot.Parent then
            myRoot.CFrame = originalCF
        end
        currentlyDodging = false
    end)
end

track(runS.Heartbeat:Connect(function()
    if State.unloaded or not getgenv().Config.Enabled then return end

    local target = State.target
    if target and target.Model and target.Model.Parent and target.Hum then
        if target.Hum.Health > 0 and target.Hum.Health < (target.Hum.MaxHealth * 0.15) then
            dodgeExplosion()
        end
    end

    local lf = FighterController.LocalFighter
    if not lf or not lf.EquippedItem then return end

    local newTarget = getClosestTarget()
    State.target = newTarget
    if not newTarget then return end

    if tick() - State.lastFire < getgenv().Config.FireRate then return end
    State.lastFire = tick()
    fireWithDesync(lf.EquippedItem, newTarget)
end))

local gui = Instance.new("ScreenGui")
gui.Name = "ZK_CustomUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.fromOffset(280, 450)
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true 
mainFrame.Visible = false
mainFrame.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 180, 80)
stroke.Thickness = 1.5
stroke.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "Zombie Killer"
title.TextColor3 = Color3.fromRGB(80, 180, 80)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = mainFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(32, 32)
closeBtn.Position = UDim2.new(1, -38, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.Parent = mainFrame
Instance.new("UICorner").Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -50)
scroll.Position = UDim2.fromOffset(10, 45)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 180, 80)
scroll.Parent = mainFrame

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 10)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = scroll

local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.fromOffset(50, 50)
floatBtn.Position = UDim2.new(0, 20, 0.5, 0)
floatBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
floatBtn.Text = "ZK"
floatBtn.TextColor3 = Color3.new(1,1,1)
floatBtn.Font = Enum.Font.GothamBold
floatBtn.TextSize = 18
floatBtn.BorderSizePixel = 0
floatBtn.Draggable = true
floatBtn.Parent = gui
Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(1, 0)

floatBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end
local function addToggle(text, getter, setter)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 35)
    row.BackgroundTransparency = 1
    row.Parent = scroll

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(50, 26)
    btn.Position = UDim2.new(1, -50, 0.5, -13)
    btn.BackgroundColor3 = getter() and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(60, 60, 65)
    btn.Text = getter() and "ON" or "OFF"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        setter(not getter())
        btn.Text = getter() and "ON" or "OFF"
        btn.BackgroundColor3 = getter() and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(60, 60, 65)
    end)
end

local function addSlider(text, min, max, getter, setter, isFloat)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 50)
    row.BackgroundTransparency = 1
    row.Parent = scroll

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. ": " .. tostring(getter())
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 8)
    bar.Position = UDim2.new(0, 0, 0, 32)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    bar.BorderSizePixel = 0
    bar.Parent = row
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale((getter() - min) / (max - min), 1)
    fill.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = bar

    local dragging = false
    local function update(input)
        local p = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = min + (max - min) * p
        if not isFloat then v = math.floor(v) else v = tonumber(string.format("%.3f", v)) end
        setter(v)
        fill.Size = UDim2.fromScale(p, 1)
        lbl.Text = text .. ": " .. tostring(v)
    end

    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(i)
        end
    end)
    track(uis.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            update(i)
        end
    end))
    track(uis.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

local function addDropdown(text, options, getter, setter)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 50)
    row.BackgroundTransparency = 1
    row.Parent = scroll

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 26)
    btn.Position = UDim2.new(0, 0, 0, 22)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    btn.Text = tostring(getter())
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local currentIndex = 1
    for i, v in ipairs(options) do if v == getter() then currentIndex = i break end end

    btn.MouseButton1Click:Connect(function()
        currentIndex = currentIndex % #options + 1
        setter(options[currentIndex])
        btn.Text = tostring(options[currentIndex])
    end)
end


addToggle("Enable Auto-Shoot", function() return getgenv().Config.Enabled end, function(v) getgenv().Config.Enabled = v end)
addToggle("Anti-Explosion (Dodges Blast)", function() return getgenv().Config.AntiExplosion end, function(v) getgenv().Config.AntiExplosion = v end)
addDropdown("Weapon Slot", {"Primary", "Secondary", "Melee"}, function() return getgenv().Config.WeaponSlot end, function(v) getgenv().Config.WeaponSlot = v end)
addSlider("Fire Rate (seconds)", 0.00, 0.2, function() return getgenv().Config.FireRate end, function(v) getgenv().Config.FireRate = v end, true)
addSlider("Max Distance", 50, 2000, function() return getgenv().Config.MaxDistance end, function(v) getgenv().Config.MaxDistance = v end, false)

addToggle("Desync (Safe Shooting)", function() return getgenv().Config.DesyncEnabled end, function(v) getgenv().Config.DesyncEnabled = v end)
addDropdown("Desync Mode", {"offscreen", "behind", "front", "above"}, function() return getgenv().Config.DesyncMode end, function(v) getgenv().Config.DesyncMode = v end)
addSlider("Desync Height", 0, 10, function() return getgenv().Config.DesyncHeight end, function(v) getgenv().Config.DesyncHeight = v end, true)
addSlider("Desync Back", -5, 10, function() return getgenv().Config.DesyncBack end, function(v) getgenv().Config.DesyncBack = v end, true)

addToggle("Anti-Aim (Spin Server Hitbox)", function() return getgenv().Config.AntiAim end, function(v) getgenv().Config.AntiAim = v end)
addSlider("Anti-Aim Speed", 100, 1000, function() return getgenv().Config.AntiAimSpeed end, function(v) getgenv().Config.AntiAimSpeed = v end, false)

scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y)

getgenv().ZK_Unload = function()
    if State.unloaded then return end
    State.unloaded = true
    for _, c in ipairs(State.connections) do pcall(function() c:Disconnect() end) end
    State.connections = {}
    if State.restoreConn then State.restoreConn:Disconnect() end
    if gui then gui:Destroy() end
end

print("[ZK] Loaded! Anti-Aim is ON by default.")