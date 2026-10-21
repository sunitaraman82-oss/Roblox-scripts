local repS  = cloneref(game:GetService("ReplicatedStorage"))
local plrs  = cloneref(game:GetService("Players"))
local runS  = cloneref(game:GetService("RunService"))
local ws    = cloneref(game:GetService("Workspace"))
local uis   = cloneref(game:GetService("UserInputService"))
local gethui = (getgenv().gethui or function() return game:GetService("CoreGui") end)
local lplr  = plrs.LocalPlayer

local util  = require(repS.Modules.Utility)
local enum  = require(repS.Modules.EnumLibrary)
local FighterController = require(lplr.PlayerScripts.Controllers.FighterController)

local Config = {
    Enabled      = true,
    FireRate     = 0.05,
    Slot         = "Secondary",
    ToggleKey    = Enum.KeyCode.RightShift,
    DesyncAim    = true,
    ProjectileFallback = true,
}
getgenv().RageZombieConfig = Config

local SLOT_NUM = { Primary = 1, Secondary = 2, Melee = 3 }
local function slotNum() return SLOT_NUM[Config.Slot] or 2 end

local RootDesync = {}
RootDesync.__index = RootDesync
function RootDesync.new(root)
    local self = setmetatable({ _root = root, _old = nil, _serverCF = nil }, RootDesync)
    self._conn = runS.Heartbeat:Connect(function()
        if self._serverCF ~= nil then
            self._old = self._root.CFrame
            self._root.CFrame = self._serverCF
        end
    end)
    return self
end
function RootDesync:Set(cf) self._serverCF = cf end
function RootDesync:Restore()
    if self._old ~= nil then self._root.CFrame = self._old self._old = nil end
    self._serverCF = nil
end
function RootDesync:Destroy() self:Restore() self._conn:Disconnect() end

local function getTarget()
    local char = lplr.Character
    if not char then return nil, nil end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil, nil end

    local camPos = workspace.CurrentCamera.CFrame.Position
    local best, bestHitbox, bestScore = nil, nil, math.huge

    for _, obj in ipairs(ws:GetDescendants()) do
        if obj:IsA("Model") then
            local hum = obj:FindFirstChildWhichIsA("Humanoid")
            if not hum or hum.Health <= 0 then continue end
            if obj == char or plrs:GetPlayerFromCharacter(obj) then continue end

            local hitbox =
                obj:FindFirstChild("HitboxHead")
                or obj:FindFirstChild("HitboxHeadSmall")
                or obj:FindFirstChild("Head")
                or obj:FindFirstChild("ZombieHead")
            if not hitbox then continue end

            local anchor =
                obj:FindFirstChild("HitboxBody")
                or obj:FindFirstChild("HitboxBodySmall")
                or obj:FindFirstChild("HumanoidRootPart")
                or hitbox

            local score = (camPos - anchor.Position).Magnitude
            if score < bestScore then
                bestScore, best, bestHitbox = score, anchor, hitbox
            end
        end
    end
    return best, bestHitbox
end

local function getSlotItem()
    local lf = FighterController.LocalFighter
    if not lf then return nil end
    local items = lf:GetItems()
    if not items then return nil end
    local n = slotNum()
    local it = items[n]
    if it and it.Info then return it end
    return nil
end

task.spawn(function()
    while not FighterController.LocalFighter do task.wait(0.1) end
    while true do
        if Config.Enabled then
            pcall(function()
                FighterController.LocalFighter:EquipItem(slotNum())
            end)
        end
        task.wait(1)
    end
end)

local function diagnose()
    local lines = {}
    local function L(s) table.insert(lines, s) end

    local lf = FighterController.LocalFighter
    if not lf then
        return "✗ LocalFighter not ready — wait until you've spawned."
    end

    local items = lf:GetItems()
    L(("LocalFighter: ok  |  items: %d  |  slot: %s (index %d)")
        :format(#items, Config.Slot, slotNum()))

    for i, it in ipairs(items) do
        local info = it.Info or {}
        L(("  slot %d: %s | Type=%s | IsRaycast=%s | Ammo=%s | Reserve=%s")
            :format(i, it.Name or "?",
                tostring(info.Type),
                tostring(it.IsRaycast),
                tostring(it.GetAmmo and it:GetAmmo() or "n/a"),
                tostring(it.GetAmmoReserve and it:GetAmmoReserve() or "n/a")))
    end

    local item = getSlotItem()
    if not item then
        L(("✗ Slot %s is empty — nothing to fire."):format(Config.Slot))
        return table.concat(lines, "\n")
    end

    L(("Selected item: %s | Type=%s | IsRaycast=%s")
        :format(item.Name, tostring(item.Info.Type), tostring(item.IsRaycast)))

    if item.Info.Type ~= "Gun" then
        L(("✗ Type is %q, not %q — rage loop will refuse to fire it.")
            :format(tostring(item.Info.Type), "Gun"))
        return table.concat(lines, "\n")
    end

    local equipped = lf.EquippedItem
    if equipped ~= item then
        L(("⚠ Equipped is %s, not selected %s — equip loop will retry.")
            :format(tostring(equipped and equipped.Name), item.Name))
    else
        L("✓ Selected item is currently equipped.")
    end

    if item.GetAmmo and item:GetAmmo() == 0 then
        L("⚠ No ammo — fire loop will call :Reload() instead of shooting.")
    end

    local root, hitbox = getTarget()
    if not root or not hitbox then
        L("✗ No zombie target in Workspace.")
    else
        L(("✓ Target: %s | hitbox: %s (%s)")
            :format(root.Parent.Name, hitbox.Name, hitbox.ClassName))
        L(("  hitbox in-bounds: %s"):format(tostring(hitbox:IsDescendantOf(ws))))
    end

    L("Hitbox resolution (Kicia dc.ResolveHitboxes):")
    local found = {}
    for _, name in ipairs({ "HitboxHead", "HitboxBody", "HitboxHeadSmall", "HitboxBodySmall",
                            "Head", "ZombieHead", "Torso", "ZombieTorso" }) do
        for _, m in ipairs(ws:GetDescendants()) do
            if m:IsA("Model") and m:FindFirstChild(name) then
                local hum = m:FindFirstChildWhichIsA("Humanoid")
                if hum and hum.Health > 0 and m ~= lplr.Character
                   and not plrs:GetPlayerFromCharacter(m) then
                    found[name] = m
                    break
                end
            end
        end
    end
    if next(found) then
        for name, m in pairs(found) do
            L(("  ✓ %s -> %s"):format(name, m.Name))
        end
    else
        L("  ✗ No zombie hitboxes found at all — map uses a different naming scheme.")
    end

    local branch = item.IsRaycast and "Hitscan (cameraData table)" or "Projectile (flat fields)"
    L(("Payload branch: %s"):format(branch))

    if item.IsRaycast and Config.ProjectileFallback then
        L("  note: IsRaycast=true, so cameraData table is used (secondary hitscan).")
    elseif not item.IsRaycast and not Config.ProjectileFallback then
        L("  ✗ Projectile weapon but ProjectileFallback=false — shots will be ignored.")
    elseif not item.IsRaycast then
        L("  ✓ Projectile fallback enabled — shots will use flat CFrame payload.")
    end

    return table.concat(lines, "\n")
end

local desync   = nil
local lastFire = 0

local function fakeCamOrigin(head)
    local char = lplr.Character
    if not char then return nil end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local offset = myRoot.CFrame * CFrame.new(0, 3, -2)
    return CFrame.lookAt(offset.Position, head.Position)
end

runS.Heartbeat:Connect(function()
    local char = lplr.Character
    if not char then
        if desync then desync:Destroy() desync = nil end
        return
    end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    if desync == nil or desync._root ~= myRoot then
        if desync then desync:Destroy() end
        desync = RootDesync.new(myRoot)
    end

    if not Config.Enabled then desync:Restore() return end

    local lf = FighterController.LocalFighter
    if not lf then desync:Restore() return end
    local item = getSlotItem()
    local equipped = lf.EquippedItem
    if not item or not equipped or equipped ~= item then
        pcall(function() lf:EquipItem(slotNum()) end)
        desync:Restore()
        return
    end
    local info = item.Info
    if not info or info.Type ~= "Gun" then desync:Restore() return end
    if item.GetAmmo and item:GetAmmo() == 0 then
        pcall(function() item:Reload() end)
        desync:Restore()
        return
    end

    local targetRoot, targetHitbox = getTarget()
    if not targetHitbox then desync:Restore() return end

    local aimCF = fakeCamOrigin(targetHitbox)
    if not aimCF then return end

    if Config.DesyncAim then desync:Set(aimCF) end

    if tick() - lastFire < Config.FireRate then return end
    lastFire = tick()

    if item.IsRaycast then
        local objOffset = targetHitbox.CFrame:ToObjectSpace(CFrame.new(targetHitbox.Position))
        local cameraData = {
            [utf8.char(1)] = {
                [utf8.char(0)] = util:EncodeCFrame(aimCF),
                [utf8.char(1)] = util:EncodeCFrame(targetHitbox.CFrame),
                [utf8.char(2)] = targetHitbox,
                [utf8.char(3)] = util:EncodeCFrame(objOffset),
            }
        }
        repS.Remotes.Replication.Fighter.UseItem:FireServer(
            item:Get("ObjectID"),
            enum:ToEnum("StartShooting"),
            cameraData,
            nil
        )
    elseif Config.ProjectileFallback then
        local flat = {
            [utf8.char(0)] = util:EncodeCFrame(aimCF),
            [utf8.char(1)] = util:EncodeCFrame(aimCF),
            [utf8.char(2)] = targetHitbox,
            [utf8.char(3)] = util:EncodeCFrame(CFrame.new(0, 0, 0)),
        }
        repS.Remotes.Replication.Fighter.UseItem:FireServer(
            item:Get("ObjectID"),
            enum:ToEnum("StartShooting"),
            flat,
            nil
        )
    end
end)

runS.RenderStepped:Connect(function()
    if desync then desync:Restore() end
end)

local COL = {
    BG      = Color3.fromRGB(18, 18, 20),
    PANEL   = Color3.fromRGB(26, 26, 30),
    ELEMENT = Color3.fromRGB(34, 34, 40),
    ACCENT  = Color3.fromRGB(200, 60, 60),
    TEXT    = Color3.fromRGB(230, 230, 230),
    MUTED   = Color3.fromRGB(150, 150, 160),
    OK      = Color3.fromRGB(90, 200, 120),
    WARN    = Color3.fromRGB(240, 190, 90),
}

local Font = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal)

local function make(className, props, children)
    local i = Instance.new(className)
    for k, v in pairs(props or {}) do i[k] = v end
    for _, c in ipairs(children or {}) do c.Parent = i end
    return i
end

local gui = make("ScreenGui", {
    Name = "RageZombieUI",
    DisplayOrder = 9999,
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = gethui(),
})

local win = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(420, 560),
    BackgroundColor3 = COL.BG,
    BorderSizePixel = 0,
    Visible = true,
}, {
    make("UICorner", { CornerRadius = UDim.new(0, 10) }),
    make("UIStroke", { Color = COL.ACCENT, Transparency = 0.4, Thickness = 1.5 }),
})
win.Parent = gui

local titleBar = make("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = COL.PANEL,
    BorderSizePixel = 0,
    Active = true,
}, {
    make("UICorner", { CornerRadius = UDim.new(0, 10) }),
})
titleBar.Parent = win

make("TextLabel", {
    Text = "Rage Zombie",
    FontFace = Font,
    TextSize = 16,
    TextColor3 = COL.TEXT,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -80, 1, 0),
    Position = UDim2.fromOffset(12, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = titleBar,
})

local enabledBtn = make("TextButton", {
    Size = UDim2.fromOffset(70, 26),
    Position = UDim2.new(1, -170, 0.5, -13),
    BackgroundColor3 = COL.ACCENT,
    Text = "ON",
    FontFace = Font,
    TextSize = 13,
    TextColor3 = COL.TEXT,
    AutoButtonColor = false,
    Parent = titleBar,
}, { make("UICorner", { CornerRadius = UDim.new(0, 6) }) })

local closeBtn = make("TextButton", {
    Size = UDim2.fromOffset(26, 26),
    Position = UDim2.new(1, -36, 0.5, -13),
    BackgroundColor3 = COL.ELEMENT,
    Text = "×",
    FontFace = Font,
    TextSize = 16,
    TextColor3 = COL.TEXT,
    AutoButtonColor = false,
    Parent = titleBar,
}, { make("UICorner", { CornerRadius = UDim.new(0, 6) }) })

local body = make("ScrollingFrame", {
    Size = UDim2.new(1, -20, 1, -50),
    Position = UDim2.fromOffset(10, 45),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = COL.ACCENT,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, {
    make("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }),
    make("UIPadding", { PaddingBottom = UDim.new(0, 10) }),
})
body.Parent = win

local function section(text)
    make("TextLabel", {
        Text = text,
        FontFace = Font,
        TextSize = 12,
        TextColor3 = COL.MUTED,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = body,
    })
end

local function row(height)
    return make("Frame", {
        Size = UDim2.new(1, 0, 0, height or 36),
        BackgroundColor3 = COL.ELEMENT,
        BorderSizePixel = 0,
        Parent = body,
    }, { make("UICorner", { CornerRadius = UDim.new(0, 6) }) })
end

local function label(parent, text, x, w)
    return make("TextLabel", {
        Text = text,
        FontFace = Font,
        TextSize = 13,
        TextColor3 = COL.TEXT,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(x, 0),
        Size = UDim2.new(0, w, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent,
    })
end

section("WEAPON SLOT")
local slotRow = row(40)
local slotBtns = {}
local slotOrder = { "Primary", "Secondary", "Melee" }

local function refreshSlotBtns()
    for name, b in pairs(slotBtns) do
        if name == Config.Slot then
            b.BackgroundColor3 = COL.ACCENT
            b.TextColor3 = COL.TEXT
        else
            b.BackgroundColor3 = COL.ELEMENT
            b.TextColor3 = COL.MUTED
        end
    end
end

for i, name in ipairs(slotOrder) do
    local btn = make("TextButton", {
        Text = name,
        FontFace = Font,
        TextSize = 13,
        TextColor3 = COL.MUTED,
        BackgroundColor3 = COL.ELEMENT,
        AutoButtonColor = false,
        Position = UDim2.new(0, (i - 1) * (1/3) + 0.01, 0, 4),
        Size = UDim2.new(1/3 - 0.02, 0, 1, -8),
        Parent = slotRow,
    }, { make("UICorner", { CornerRadius = UDim.new(0, 5) }) })

    btn.MouseButton1Click:Connect(function()
        Config.Slot = name
        refreshSlotBtns()
    end)

    slotBtns[name] = btn
end
refreshSlotBtns()

section("FIRE RATE (s)")
local rateRow = row(36)
local rateLabel = make("TextLabel", {
    Text = string.format("%.2f", Config.FireRate),
    FontFace = Font,
    TextSize = 13,
    TextColor3 = COL.TEXT,
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -60, 0, 0),
    Size = UDim2.fromOffset(50, 36),
    Parent = rateRow,
})
local rateBox = make("TextBox", {
    Text = tostring(Config.FireRate),
    FontFace = Font,
    TextSize = 13,
    TextColor3 = COL.TEXT,
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -110, 0, 0),
    Size = UDim2.fromOffset(50, 36),
    ClearTextOnFocus = true,
    Parent = rateRow,
})
label(rateRow, "Delay between shots", 10, 200)
rateBox.FocusLost:Connect(function()
    local n = tonumber(rateBox.Text)
    if n and n >= 0.01 and n <= 2 then
        Config.FireRate = n
        rateLabel.Text = string.format("%.2f", n)
    else
        rateBox.Text = tostring(Config.FireRate)
    end
end)

section("OPTIONS")
local desyncRow = row(36)
local desyncBtn = make("TextButton", {
    Text = "ON",
    FontFace = Font,
    TextSize = 13,
    TextColor3 = COL.TEXT,
    BackgroundColor3 = COL.ACCENT,
    AutoButtonColor = false,
    Position = UDim2.new(1, -66, 0.5, -13),
    Size = UDim2.fromOffset(56, 26),
    Parent = desyncRow,
}, { make("UICorner", { CornerRadius = UDim.new(0, 5) }) })
label(desyncRow, "Aim desync", 10, 200)
desyncBtn.MouseButton1Click:Connect(function()
    Config.DesyncAim = not Config.DesyncAim
    desyncBtn.Text = Config.DesyncAim and "ON" or "OFF"
    desyncBtn.BackgroundColor3 = Config.DesyncAim and COL.ACCENT or COL.ELEMENT
end)

local projRow = row(36)
local projBtn = make("TextButton", {
    Text = "ON",
    FontFace = Font,
    TextSize = 13,
    TextColor3 = COL.TEXT,
    BackgroundColor3 = COL.ACCENT,
    AutoButtonColor = false,
    Position = UDim2.new(1, -66, 0.5, -13),
    Size = UDim2.fromOffset(56, 26),
    Parent = projRow,
}, { make("UICorner", { CornerRadius = UDim.new(0, 5) }) })
label(projRow, "Projectile fallback", 10, 200)
projBtn.MouseButton1Click:Connect(function()
    Config.ProjectileFallback = not Config.ProjectileFallback
    projBtn.Text = Config.ProjectileFallback and "ON" or "OFF"
    projBtn.BackgroundColor3 = Config.ProjectileFallback and COL.ACCENT or COL.ELEMENT
end)

section("SECONDARY HITTING CHECK")
local diagRow = row(36)
local diagBtn = make("TextButton", {
    Text = "Run Check",
    FontFace = Font,
    TextSize = 13,
    TextColor3 = COL.TEXT,
    BackgroundColor3 = COL.ACCENT,
    AutoButtonColor = false,
    Position = UDim2.new(0, 10, 0, 4),
    Size = UDim2.new(1, -20, 1, -8),
    Parent = diagRow,
}, { make("UICorner", { CornerRadius = UDim.new(0, 5) }) })

local diagOut = make("TextLabel", {
    Text = "Click Run Check to inspect secondary hitboxes, IsRaycast, ammo, and payload branch.",
    FontFace = Font,
    TextSize = 12,
    TextColor3 = COL.MUTED,
    BackgroundColor3 = COL.PANEL,
    BackgroundTransparency = 0,
    Size = UDim2.new(1, 0, 0, 220),
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    RichText = true,
    Parent = body,
}, { make("UICorner", { CornerRadius = UDim.new(0, 6) }),
     make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
                          PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }) })

local function colorLine(line)
    if line:sub(1, 1) == "✓" then return '<font color="#5AC878">' .. line .. '</font>' end
    if line:sub(1, 1) == "✗" then return '<font color="#E85A5A">' .. line .. '</font>' end
    if line:sub(1, 1) == "⚠" then return '<font color="#F0BE5A">' .. line .. '</font>' end
    return line
end

diagBtn.MouseButton1Click:Connect(function()
    local out = diagnose()
    local colored = {}
    for line in (out .. "\n"):gmatch("(.-)\n") do
        table.insert(colored, colorLine(line))
    end
    diagOut.Text = table.concat(colored, "\n")
    diagOut.TextColor3 = COL.TEXT
end)

local function setEnabled(v)
    Config.Enabled = v
    enabledBtn.Text = v and "ON" or "OFF"
    enabledBtn.BackgroundColor3 = v and COL.ACCENT or COL.ELEMENT
end
enabledBtn.MouseButton1Click:Connect(function()
    setEnabled(not Config.Enabled)
end)

local function setVisible(v)
    win.Visible = v
end
closeBtn.MouseButton1Click:Connect(function()
    setVisible(false)
end)

uis.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Config.ToggleKey then
        setVisible(not win.Visible)
    end
end)

local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = win.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
uis.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
       or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                  startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)