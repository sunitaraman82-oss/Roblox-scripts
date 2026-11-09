-- ============================================================
-- Pet GUI + Rage Suite + Visuals + ULTIMATE Combat (FIXED)
-- + Rivals Ragebot Enhancement (Silent Aim / Reposition / Dodge /
--   Always Backstab / Perfect Block / Anti-Knife / Ragebot engine)
-- + Advanced ESP Integration (BoxFill / Corner Box / Weapon / Ammo /
--   Reload / HealthBar SmoothDecay / Typewriter / Gradient Animations)
-- ============================================================
local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local cam     = workspace.CurrentCamera
local RunSvc  = game:GetService("RunService")
local LP      = Players.LocalPlayer

local scaleMult = 1
local pcButton  = false

local col = {
    bg = Color3.fromRGB(14, 14, 15),
    line = Color3.fromRGB(78, 82, 92),
    panel = Color3.fromRGB(17, 17, 18),
    panelLine = Color3.fromRGB(44, 44, 47),
    text = Color3.fromRGB(205, 205, 210),
    dim = Color3.fromRGB(150, 150, 156),
    off = Color3.fromRGB(95, 95, 100),
    accent = Color3.fromRGB(150, 195, 235),
    tab = Color3.fromRGB(20, 20, 22),
    tabOn = Color3.fromRGB(26, 27, 31),
    tabLine = Color3.fromRGB(40, 40, 43),
    tabLineOn = Color3.fromRGB(70, 74, 84),
    box = Color3.fromRGB(22, 22, 24),
    boxLine = Color3.fromRGB(52, 52, 56),
    fillA = Color3.fromRGB(122, 130, 145),
    fillB = Color3.fromRGB(84, 90, 102),
}
local font, fsize = Enum.Font.Arial, 13

local function make(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end
local function outline(o, c, t)
    return make("UIStroke", { Color = c, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end
local function shade(o, a, b)
    return make("UIGradient", { Color = ColorSequence.new(a, b), Rotation = 90 }, o)
end
local function label(parent, str, pos, size, c, align)
    return make("TextLabel", { BackgroundTransparency = 1, Text = str, Font = font, TextSize = fsize, TextColor3 = c or col.text, Position = pos, Size = size, TextXAlignment = align or Enum.TextXAlignment.Left }, parent)
end

local gui = make("ScreenGui", { Name = "PetRageSuite", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, Players.LocalPlayer:WaitForChild("PlayerGui"))

local crossGui = make("ScreenGui", { Name = "PetCrosshair", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 9999 }, Players.LocalPlayer:WaitForChild("PlayerGui"))
local crossCenter = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Visible = false }, crossGui)
local cLines = {}
for i = 1, 4 do
    cLines[i] = make("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, crossCenter)
end

local fovFrameAimbot = make("Frame", { Name = "FOVAimbot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 1 }, gui)
make("UICorner", { CornerRadius = UDim.new(1, 0) }, fovFrameAimbot)
make("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 0.5 }, fovFrameAimbot)

local fovFrameSilent = make("Frame", { Name = "FOVSilent", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 1 }, gui)
make("UICorner", { CornerRadius = UDim.new(1, 0) }, fovFrameSilent)
make("UIStroke", { Color = Color3.fromRGB(255, 100, 100), Thickness = 1, Transparency = 0.5 }, fovFrameSilent)

local main = make("Frame", { Size = UDim2.fromOffset(640, 590), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = col.bg, BorderSizePixel = 0 }, gui)
outline(main, col.line)

local uiscale = make("UIScale", {}, main)
local function fit()
    local vp = cam.ViewportSize
    local s = math.min(vp.X / 660, vp.Y / 620, 1) * scaleMult
    if UIS.TouchEnabled then s = math.max(s, 0.55) end
    uiscale.Scale = math.max(s, 0.4)
end
fit()
cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit)

local titleBar = make("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Active = true }, main)
make("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(9, 0), Size = UDim2.new(1, -36, 0, 25), Font = font, TextSize = fsize, TextColor3 = col.text, RichText = true, TextXAlignment = Enum.TextXAlignment.Left, Text = 'Rage <font color="rgb(170,178,192)">Suite + Ultimate Combat</font>' }, titleBar)

local minBtn = make("TextButton", { Name = "Minimize", Size = UDim2.fromOffset(24, 20), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 6), BackgroundColor3 = col.tab, BorderSizePixel = 0, AutoButtonColor = false, Text = "-", Font = font, TextSize = 16, TextColor3 = col.text }, titleBar)
outline(minBtn, col.tabLine)
make("Frame", { Position = UDim2.fromOffset(1, 25), Size = UDim2.new(1, -2, 0, 1), BackgroundColor3 = Color3.fromRGB(38, 38, 41), BorderSizePixel = 0 }, main)

local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function isMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end

local function drag(handle, target, onTap, thresh)
    thresh = thresh or 0
    local down, moved, press, start, origin
    handle.InputBegan:Connect(function(i)
        if not isPress(i) then return end
        down, moved, press = true, false, i
        start, origin = Vector2.new(i.Position.X, i.Position.Y), target.AbsolutePosition + target.AbsoluteSize / 2
        local c
        c = i.Changed:Connect(function()
            if i.UserInputState ~= Enum.UserInputState.End then return end
            c:Disconnect()
            if down then down = false; if not moved and onTap then onTap() end end
        end)
    end)
    UIS.InputChanged:Connect(function(i)
        if not down then return end
        local touch = press.UserInputType == Enum.UserInputType.Touch
        if touch and i ~= press then return end
        if not touch and i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local d = Vector2.new(i.Position.X, i.Position.Y) - start
        if not moved then if d.Magnitude < thresh then return end; moved = true end
        local vp, half = cam.ViewportSize, target.AbsoluteSize / 2
        local p = origin + d
        target.Position = UDim2.fromOffset(math.clamp(p.X, half.X, math.max(half.X, vp.X - half.X)), math.clamp(p.Y, half.Y, math.max(half.Y, vp.Y - half.Y)))
    end)
    UIS.WindowFocusReleased:Connect(function() down = false end)
end
drag(titleBar, main)

local function toggleGui() main.Visible = not main.Visible end
UIS.InputBegan:Connect(function(i, gp) if not gp and i.KeyCode == Enum.KeyCode.RightShift then toggleGui() end end)

local btn = make("TextButton", { Name = "Toggle", Size = UDim2.fromOffset(40, 40), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(44, 130), BackgroundColor3 = col.accent, BorderSizePixel = 0, AutoButtonColor = false, Text = "R", FontFace = Font.fromEnum(Enum.Font.GothamBold), TextSize = 22, TextColor3 = col.bg, Visible = UIS.TouchEnabled or pcButton, ZIndex = 10 }, gui)
shade(btn, Color3.new(1, 1, 1), Color3.fromRGB(205, 215, 230))
outline(btn, Color3.fromRGB(190, 220, 245))
drag(btn, btn, toggleGui, 6)

local function newToggle(parent, opts)
    local row = make("TextButton", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, parent)
    local box = make("Frame", { Position = UDim2.fromOffset(0, 5), Size = UDim2.fromOffset(12, 12), BorderSizePixel = 0 }, row)
    local line = outline(box, col.boxLine)
    local fill = shade(box, col.fillA, col.fillB)
    local txt  = label(row, opts.name, UDim2.fromOffset(22, 0), UDim2.new(1, -22, 1, 0))
    local state = { value = opts.default and true or false }
    local function draw()
        local on = state.value
        fill.Enabled = on
        box.BackgroundColor3 = on and Color3.new(1, 1, 1) or col.box
        line.Color = on and Color3.fromRGB(160, 168, 182) or col.boxLine
        txt.TextColor3 = on and col.text or col.off
    end
    draw()
    row.MouseButton1Click:Connect(function()
        state.value = not state.value; draw()
        if opts.callback then pcall(opts.callback, state.value) end
    end)
    return state
end

local sliding = nil
UIS.InputChanged:Connect(function(i) if sliding and isMove(i) then sliding(i.Position.X) end end)
UIS.InputEnded:Connect(function(i) if isPress(i) then sliding = nil end end)

local function newSlider(parent, opts)
    local min, max, step = opts.min or 0, opts.max or 1, opts.step or 0
    local holder = make("Frame", { Size = UDim2.new(1, 0, 0, 37), BackgroundTransparency = 1 }, parent)
    label(holder, opts.name, UDim2.new(), UDim2.new(1, 0, 0, 16), col.dim)
    local bar = make("TextButton", { Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 15), BackgroundColor3 = col.box, BorderSizePixel = 0, Text = "", AutoButtonColor = false }, holder)
    outline(bar, col.boxLine)
    local fill = make("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, bar)
    shade(fill, col.fillA, col.fillB)
    local val = label(bar, "", UDim2.new(), UDim2.fromScale(1, 1), col.text, Enum.TextXAlignment.Center)
    val.ZIndex = 3
    local function format(v)
        if opts.suffix then
            if step >= 1 then return string.format("%d%s", math.floor(v + 0.5), opts.suffix) end
            return string.format("%.2f%s", v, opts.suffix)
        end
        if step >= 1 then return string.format("%d", math.floor(v + 0.5)) end
        return string.format("%.2f", v)
    end
    local state = { value = opts.default or min }
    local function apply(v)
        if step > 0 then v = min + math.floor((v - min) / step + 0.5) * step end
        v = math.clamp(v, min, max)
        state.value = v
        fill.Size = UDim2.fromScale((v - min) / (max - min), 1)
        val.Text = format(v)
    end
    apply(state.value)
    local function fromX(x)
        local frac = (x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
        apply(min + math.clamp(frac, 0, 1) * (max - min))
        if opts.callback then pcall(opts.callback, state.value) end
    end
    bar.InputBegan:Connect(function(i) if isPress(i) then sliding = fromX; fromX(i.Position.X) end end)
    return state
end

local function newButton(parent, opts)
    local b = make("TextButton", { Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = col.box, BorderSizePixel = 0, AutoButtonColor = false, Text = "" }, parent)
    outline(b, col.boxLine)
    label(b, opts.name, UDim2.fromOffset(8, 0), UDim2.new(1, -16, 1, 0), col.text)
    b.MouseButton1Click:Connect(function() if opts.callback then pcall(opts.callback) end end)
    return b
end

local ddGui = make("ScreenGui", { Name = "PetDropdowns", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, Players.LocalPlayer:WaitForChild("PlayerGui"))
local openDropdown = nil
local function closeDropdown() if openDropdown then openDropdown:Destroy(); openDropdown = nil end end

local function newDropdown(parent, opts)
    local dd = { _items = opts.items, _value = opts.default or opts.items[1] }
    local row = make("TextButton", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, parent)
    label(row, opts.name, UDim2.fromOffset(0, 0), UDim2.new(0.5, 0, 1, 0), col.dim)
    local valueLabel = label(row, tostring(dd._value), UDim2.new(0.5, 0, 0, 0), UDim2.new(0.5, -14, 1, 0), col.text, Enum.TextXAlignment.Right)
    label(row, "v", UDim2.new(1, -12, 0, 0), UDim2.fromOffset(12, 22), col.dim)
    local function refresh() valueLabel.Text = (dd._value == "" and "(None)") or tostring(dd._value) end
    refresh()
    row.MouseButton1Click:Connect(function()
        closeDropdown()
        local bp, bs = row.AbsolutePosition, row.AbsoluteSize
        local frame = make("Frame", { Position = UDim2.fromOffset(bp.X, bp.Y + bs.Y), Size = UDim2.fromOffset(bs.X, math.min(#dd._items * 20 + 4, 220)), BackgroundColor3 = col.box, BorderSizePixel = 0, ZIndex = 5 }, ddGui)
        outline(frame, col.boxLine)
        local scroll = make("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, #dd._items * 20) }, frame)
        make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
        for _, opt in ipairs(dd._items) do
            local ib = make("TextButton", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = (opt == "" and "(None)") or tostring(opt), Font = font, TextSize = fsize, TextColor3 = (opt == dd._value) and col.accent or col.text, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false }, scroll)
            make("UIPadding", { PaddingLeft = UDim.new(0, 6) }, ib)
            ib.MouseButton1Click:Connect(function() dd._value = opt; refresh(); closeDropdown(); if opts.callback then pcall(opts.callback, opt) end end)
            ib.MouseEnter:Connect(function() ib.TextColor3 = col.accent end)
            ib.MouseLeave:Connect(function() if opt ~= dd._value then ib.TextColor3 = col.text end end)
        end
        openDropdown = frame
    end)
    function dd:SetItems(newItems) self._items = newItems; if not table.find(newItems, self._value) then self._value = newItems[1]; refresh() end end
    return dd
end

UIS.InputBegan:Connect(function(i)
    if not openDropdown then return end
    if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
    local m = UIS:GetMouseLocation()
    local p, s = openDropdown.AbsolutePosition, openDropdown.AbsoluteSize
    if m.X < p.X or m.X > p.X + s.X or m.Y < p.Y or m.Y > p.Y + s.Y then closeDropdown() end
end)

local function newKeybind(parent, opts)
    local row = make("TextButton", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, parent)
    label(row, opts.name or "Keybind", UDim2.fromOffset(0, 0), UDim2.new(0.6, 0, 1, 0), col.dim)
    local valueLabel = label(row, "None", UDim2.new(0.6, 0, 0, 0), UDim2.new(0.4, -8, 1, 0), col.text, Enum.TextXAlignment.Right)
    local listening, active = false, false
    row.MouseButton1Click:Connect(function() listening = true; valueLabel.Text = "Press..." end)
    UIS.InputBegan:Connect(function(i, gp)
        if not listening or gp then return end
        listening = false
        valueLabel.Text = i.KeyCode.Name
        active = not active
        if opts.callback then pcall(opts.callback, active) end
    end)
    return row
end

local function createPanel(tabContent, title)
    local panel = make("Frame", { BackgroundColor3 = col.panel, BorderSizePixel = 0, ClipsDescendants = true }, tabContent)
    outline(panel, col.panelLine)
    local top = make("Frame", { Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = Color3.fromRGB(225, 232, 242), BorderSizePixel = 0 }, panel)
    make("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }, top)
    label(panel, title, UDim2.fromOffset(9, 8), UDim2.new(1, -18, 0, 16))
    local scroll = make("ScrollingFrame", { Position = UDim2.fromOffset(9, 28), Size = UDim2.new(1, -18, 1, -34), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = col.tabLineOn, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y }, panel)
    make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, scroll)
    return scroll
end

local function makeSection(scroll)
    local sec = {}
    function sec:toggle(o)  return newToggle(scroll, { name = o.name, default = o.default, callback = o.callback }) end
    function sec:slider(o)  return newSlider(scroll, { name = o.name, min = o.min, max = o.max, step = o.interval or 1, default = o.default, suffix = o.suffix, callback = o.callback }) end
    function sec:dropdown(o) return newDropdown(scroll, { name = o.name, items = o.items, default = o.default, callback = o.callback }) end
    function sec:button(o)  return newButton(scroll, { name = o.name, callback = o.callback }) end
    function sec:keybind(o) return newKeybind(scroll, { name = o.name, callback = o.callback }) end
    function sec:label(o)   return label(scroll, o.name or "", UDim2.new(), UDim2.new(1, 0, 0, 16), col.dim) end
    function sec:settings()  return makeSection(scroll) end
    return sec
end

local function makeColumn(tabContent)
    local c = {}
    function c:section(opts)
        local scroll = createPanel(tabContent, opts.name)
        return makeSection(scroll)
    end
    return c
end

local PRESET_COLORS = { Red = Color3.fromRGB(255, 60, 60), Green = Color3.fromRGB(60, 255, 60), Blue = Color3.fromRGB(60, 120, 255), White = Color3.fromRGB(255, 255, 255), Cyan = Color3.fromRGB(60, 255, 255), Magenta = Color3.fromRGB(255, 60, 255), Yellow = Color3.fromRGB(255, 255, 60), Orange = Color3.fromRGB(255, 150, 60), Purple = Color3.fromRGB(180, 60, 255), Pink = Color3.fromRGB(255, 150, 200), Accent = Color3.fromRGB(150, 195, 235), Black = Color3.fromRGB(0, 0, 0), Gold = Color3.fromRGB(255, 215, 0) }
local PRESET_KEYS = {} for k in pairs(PRESET_COLORS) do PRESET_KEYS[#PRESET_KEYS+1] = k end table.sort(PRESET_KEYS)

-- END OF CHUNK 1 --
-- ============================================================
-- ADVANCED PLAYER ESP (integrated + upgraded from SCRIPT 2)
-- Adds: BoxFill, Corner Box mode, Animated gradients, Typewriter text,
--       HealthBar SmoothDecay + DynamicColor, Weapon + WeaponIcon,
--       Ammo counter, Reload indicator, Font / TextSize control.
-- ============================================================
local espGui = make("ScreenGui", { Name = "PetESP", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 5, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, Players.LocalPlayer:WaitForChild("PlayerGui"))

local esp = {
    enabled = false,
    teamCheck = false,
    infiniteMaxDist = false,
    maxDist = 2000,
    font = Enum.Font.GothamBold,
    textSize = 13,
    textAnimation = false,
    textAnimationSpeed = 30,
    tracer = true,
    tracerColor = PRESET_COLORS.Accent,
    -- legacy flat colors kept for backwards compat references
    boxColor = PRESET_COLORS.Cyan,
    nameColor = PRESET_COLORS.White,
    healthColor = PRESET_COLORS.Green,
    box = {
        enabled = true,
        mode = "Full",
        thickness = 1,
        animated = false,
        animationSpeed = 1,
        transparency = 0,
        cornerLength = 12,
        cornerThickness = 1,
        color1 = Color3.fromRGB(0, 255, 255),
        color2 = Color3.fromRGB(255, 20, 147),
    },
    boxFill = {
        enabled = false,
        animated = false,
        animationSpeed = 1,
        transparency = 0.9,
        color1 = Color3.fromRGB(0, 255, 255),
        color2 = Color3.fromRGB(0, 20, 147),
    },
    healthBar = {
        enabled = true,
        width = 1,
        offset = 5,
        showText = true,
        smoothDecay = true,
        useDynamicColor = true,
        color1 = Color3.fromRGB(50, 220, 90),
        color2 = Color3.fromRGB(255, 20, 147),
    },
    name = {
        enabled = true,
        animated = false,
        animationSpeed = 1,
        color1 = Color3.fromRGB(255, 255, 255),
        color2 = Color3.fromRGB(255, 20, 147),
    },
    distance = {
        enabled = true,
        animated = false,
        animationSpeed = 1,
        color1 = Color3.fromRGB(255, 255, 255),
        color2 = Color3.fromRGB(255, 20, 147),
    },
    weapon = {
        enabled = false,
        animated = false,
        animationSpeed = 1,
        color1 = Color3.fromRGB(255, 255, 255),
        color2 = Color3.fromRGB(255, 20, 147),
    },
    weaponIcon = {
        enabled = false,
        scale = 1,
    },
    ammo = {
        enabled = false,
        animated = false,
        animationSpeed = 1,
        color1 = Color3.fromRGB(255, 235, 59),
        color2 = Color3.fromRGB(0, 120, 0),
    },
    reload = {
        enabled = false,
        animated = true,
        color = Color3.fromRGB(255, 0, 255),
    },
}

local espFrames = {}

-- ------------------------------------------------------------------
-- Safe module loaders (Silent Aim + Weapon icon support)
-- ------------------------------------------------------------------
local _espModCache = {}
local function _tryRequire(key, getFn)
    if _espModCache[key] == false then return nil end
    if _espModCache[key] ~= nil then return _espModCache[key] end
    local ok, mod = pcall(getFn)
    if ok and mod then
        _espModCache[key] = mod
        return mod
    end
    _espModCache[key] = false
    return nil
end

local function getFighterController()
    return _tryRequire("FighterController", function()
        local c = LP.PlayerScripts:FindFirstChild("Controllers")
        return c and require(c.FighterController)
    end)
end

local function getItemLibrary()
    return _tryRequire("ItemLibrary", function()
        local RS = game:GetService("ReplicatedStorage")
        local m = RS:FindFirstChild("Modules")
        return m and require(m.ItemLibrary)
    end)
end

local function getCosmeticLibrary()
    return _tryRequire("CosmeticLibrary", function()
        local RS = game:GetService("ReplicatedStorage")
        local m = RS:FindFirstChild("Modules")
        return m and require(m.CosmeticLibrary)
    end)
end

local function getWeaponThumbnail(weaponName)
    if type(weaponName) ~= "string" or weaponName == "" or weaponName == "[None]" then
        return ""
    end
    local IL = getItemLibrary()
    if IL then
        local vm = IL.ViewModels and IL.ViewModels[weaponName]
        if vm then
            return vm.ImageHighResolution or vm.Image or ""
        end
        local item = IL.Items and IL.Items[weaponName]
        if item then
            return item.ImageHighResolution or item.Image or ""
        end
    end
    local CL = getCosmeticLibrary()
    if CL and CL.Cosmetics and CL.Cosmetics[weaponName] then
        local cos = CL.Cosmetics[weaponName]
        if cos.ImageHighResolution or cos.Image then
            return cos.ImageHighResolution or cos.Image
        end
        if cos.ItemName then
            local IL2 = getItemLibrary()
            if IL2 then
                local vm = IL2.ViewModels and IL2.ViewModels[cos.ItemName]
                if vm then return vm.ImageHighResolution or vm.Image or "" end
            end
        end
    end
    return ""
end

local function getEquippedWeaponInfo(plr, character)
    local FC = getFighterController()
    if FC then
        local ok, fighter = pcall(FC.GetFighter, FC, plr)
        if ok and fighter and fighter.EquippedItem then
            local item = fighter.EquippedItem
            local name = tostring(item.Name or "Unknown")
            local ammoStr = nil
            local data = item.Data
            if data and data.Ammo ~= nil then
                local ammo = tonumber(data.Ammo)
                local reserve = tonumber(data.AmmoReserve)
                if not ammo or ammo < 0 or ammo > 999999 then
                    ammoStr = "INF"
                elseif reserve and reserve >= 0 and reserve <= 999999 then
                    ammoStr = string.format("%d/%d", ammo, reserve)
                else
                    ammoStr = tostring(ammo)
                end
            end
            return name, ammoStr, fighter
        end
    end
    local tool = character and character:FindFirstChildOfClass("Tool")
    if tool then
        return tool.Name, nil, nil
    end
    return "[None]", nil, nil
end

local RELOAD_ANIM_NAMES = { "emptyreload", "emptyreloadstart", "emptyreloadsegment", "emptyreloadfinish", "reload" }
local function isReloading(fighter, character)
    if fighter then
        if fighter.IsReloading or fighter.Reloading then return true end
        if fighter.Data and (fighter.Data.IsReloading or fighter.Data.Reloading or fighter.Data.Reload) then return true end
        if fighter.States and (fighter.States.IsReloading or fighter.States.Reloading or fighter.States.Reload) then return true end
        local item = fighter.EquippedItem
        if item then
            if item.IsReloading or item.Reloading then return true end
            if item.Data and (item.Data.IsReloading or item.Data.Reloading or item.Data.Reload) then return true end
            local vm = item.ViewModel
            if vm and typeof(vm.IsAnimationPlaying) == "function" then
                for _, animName in ipairs(RELOAD_ANIM_NAMES) do
                    local ok, playing = pcall(vm.IsAnimationPlaying, vm, animName)
                    if ok and playing then return true end
                end
            end
        end
    end
    if character then
        local hum = character:FindFirstChildOfClass("Humanoid") or character:FindFirstChildOfClass("AnimationController")
        local animator = hum and (hum:FindFirstChildOfClass("Animator") or hum:FindFirstChild("Animator"))
        if animator and typeof(animator.GetPlayingAnimationTracks) == "function" then
            local ok, tracks = pcall(animator.GetPlayingAnimationTracks, animator)
            if ok and tracks then
                for _, track in ipairs(tracks) do
                    local nm = string.lower(track.Name or "")
                    if string.find(nm, "reload") then return true end
                end
            end
        end
    end
    return false
end

-- ------------------------------------------------------------------
-- Gradient helpers (ported from SCRIPT 2)
-- ------------------------------------------------------------------
local function makeStaticGradient(c1, c2)
    if typeof(c1) ~= "Color3" then c1 = Color3.new(1, 1, 1) end
    if typeof(c2) ~= "Color3" then c2 = c1 end
    return ColorSequence.new(c1, c2)
end

local function makeAnimatedGradient(c1, c2, clock, speed, phase)
    if typeof(c1) ~= "Color3" then c1 = Color3.new(1, 1, 1) end
    if typeof(c2) ~= "Color3" then c2 = c1 end
    clock = tonumber(clock) or 0
    speed = tonumber(speed) or 1
    phase = tonumber(phase) or 0
    local function sample(pos)
        local blend = (math.sin((pos * 2 - 1) * math.pi + clock * speed * 2 * math.pi + phase) + 1) * 0.5
        return c1:Lerp(c2, blend)
    end
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, sample(0)),
        ColorSequenceKeypoint.new(0.5, sample(0.5)),
        ColorSequenceKeypoint.new(1, sample(1)),
    })
end

local function applyGradient(parent, c1, c2, rotation)
    local grad = parent:FindFirstChildOfClass("UIGradient")
    if not grad then
        grad = Instance.new("UIGradient")
        grad.Parent = parent
    end
    grad.Color = makeStaticGradient(c1, c2)
    grad.Rotation = rotation or 0
    return grad
end

-- ------------------------------------------------------------------
-- Bounding box corners (8 points)
-- ------------------------------------------------------------------
local BOUNDING_BOX_CORNERS = {
    Vector3.new(-1, -1, -1), Vector3.new(-1, -1, 1),
    Vector3.new(-1, 1, -1), Vector3.new(-1, 1, 1),
    Vector3.new(1, -1, -1), Vector3.new(1, -1, 1),
    Vector3.new(1, 1, -1), Vector3.new(1, 1, 1),
}

local FULL_LINE_DEFS = {
    Top = { Pos = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, 1), Rot = 0, Phase = 0 },
    Right = { Pos = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), Rot = 90, Phase = 1.57 },
    Bottom = { Pos = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), Rot = 180, Phase = 3.14 },
    Left = { Pos = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, 1, 1, 0), Rot = 270, Phase = 4.71 },
}

local CORNER_LINE_DEFS = {
    TL_H = { Rot = 0, Phase = 0 },
    TR_V = { Rot = 90, Phase = 1.57 },
    BR_H = { Rot = 180, Phase = 3.14 },
    BL_V = { Rot = 270, Phase = 4.71 },
    TL_V = { Rot = 270, Phase = 0 },
    TR_H = { Rot = 0, Phase = 1.57 },
    BR_V = { Rot = 90, Phase = 3.14 },
    BL_H = { Rot = 180, Phase = 4.71 },
}

local RELOAD_DOTS = { "[RELOADING]", "[RELOADING.]", "[RELOADING..]", "[RELOADING...]" }

-- ------------------------------------------------------------------
-- ESP Frame factory
-- ------------------------------------------------------------------
local function createESPFrame(plr)
    local holder = make("Frame", { Name = plr.Name or "ESP", BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, Size = UDim2.fromOffset(0, 0) }, espGui)

    local boxFill = make("Frame", { BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.9, ZIndex = 1, Visible = false }, holder)
    local boxFillGradient = applyGradient(boxFill, esp.boxFill.color1, esp.boxFill.color2, 45)

    local fullLines = {}
    for name, def in pairs(FULL_LINE_DEFS) do
        local f = make("Frame", { Name = "Full_" .. name, Position = def.Pos, Size = def.Size, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 4, Visible = false }, holder)
        local stroke = outline(f, Color3.fromRGB(0, 0, 0), 1)
        local grad = applyGradient(f, esp.box.color1, esp.box.color2, def.Rot)
        fullLines[name] = { Frame = f, Stroke = stroke, Gradient = grad, Phase = def.Phase, Rot = def.Rot }
    end

    local cornerLines = {}
    for name, def in pairs(CORNER_LINE_DEFS) do
        local f = make("Frame", { Name = name, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 5, Size = UDim2.fromOffset(0, 0), Visible = false }, holder)
        local stroke = outline(f, Color3.fromRGB(0, 0, 0), 1)
        local grad = applyGradient(f, esp.box.color1, esp.box.color2, def.Rot)
        cornerLines[name] = { Frame = f, Stroke = stroke, Gradient = grad, Phase = def.Phase, Rot = def.Rot }
    end

    local healthBarBack = make("Frame", { BackgroundColor3 = Color3.fromRGB(10, 10, 10), BorderSizePixel = 0, Position = UDim2.fromOffset(-5, 0), Size = UDim2.new(0, 1, 1, 0), ZIndex = 7, Visible = false }, holder)
    outline(healthBarBack, Color3.fromRGB(0, 0, 0), 1)
    local healthGhost = make("Frame", { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.6, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 1, 0), ZIndex = 8 }, healthBarBack)
    local healthFill = make("Frame", { BackgroundColor3 = esp.healthBar.color1, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 1, 0), ZIndex = 9 }, healthBarBack)
    local hpText = make("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(0, -3, 1, 0), Size = UDim2.fromOffset(30, 10), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = esp.healthBar.color1, Font = esp.font, TextSize = 10, ZIndex = 11, Text = "" }, healthBarBack)
    outline(hpText, Color3.fromRGB(0, 0, 0), 1)

    local nameLabel = make("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -3), Size = UDim2.fromOffset(250, 16), TextColor3 = Color3.new(1, 1, 1), Font = esp.font, TextSize = 13, ZIndex = 12, TextXAlignment = Enum.TextXAlignment.Center, Text = "" }, holder)
    local nameGradient = applyGradient(nameLabel, esp.name.color1, esp.name.color2, 0)
    outline(nameLabel, Color3.fromRGB(0, 0, 0), 1)

    local weaponLabel = make("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(1, 4, 0, 0), Size = UDim2.new(0, 250, 0, 16), TextColor3 = Color3.new(1, 1, 1), Font = esp.font, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 12, Text = "" }, holder)
    local weaponGradient = applyGradient(weaponLabel, esp.weapon.color1, esp.weapon.color2, 0)
    outline(weaponLabel, Color3.fromRGB(0, 0, 0), 1)

    local ammoLabel = make("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(1, 4, 0, 16), Size = UDim2.new(0, 250, 0, 14), TextColor3 = Color3.fromRGB(255, 0, 0), Font = esp.font, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 12, Text = "" }, holder)
    local ammoGradient = applyGradient(ammoLabel, esp.ammo.color1, esp.ammo.color2, 0)
    outline(ammoLabel, Color3.fromRGB(0, 0, 0), 1)

    local reloadLabel = make("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(1, 4, 0, 30), Size = UDim2.new(0, 250, 0, 13), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Font = esp.font, TextSize = 11, ZIndex = 12, Text = "" }, holder)
    outline(reloadLabel, Color3.fromRGB(0, 0, 0), 1)

    local distLabel = make("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 3), Size = UDim2.fromOffset(250, 13), TextColor3 = Color3.fromRGB(0, 255, 255), Font = esp.font, TextSize = 12, ZIndex = 12, TextXAlignment = Enum.TextXAlignment.Center, Text = "" }, holder)
    local distGradient = applyGradient(distLabel, esp.distance.color1, esp.distance.color2, 0)
    outline(distLabel, Color3.fromRGB(0, 0, 0), 1)

    local weaponIconShadow = make("ImageLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 1, 1, 4), Size = UDim2.fromOffset(72, 36), Image = "", ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 0.35, ScaleType = Enum.ScaleType.Fit, Visible = false, ZIndex = 11 }, holder)
    local weaponIcon = make("ImageLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 3), Size = UDim2.fromOffset(72, 36), Image = "", ImageColor3 = Color3.new(1, 1, 1), ScaleType = Enum.ScaleType.Fit, Visible = false, ZIndex = 12 }, holder)

    local tracer = make("Frame", { BackgroundColor3 = esp.tracerColor, BorderSizePixel = 0, Size = UDim2.fromOffset(1, 1), Visible = false }, espGui)

    return {
        Holder = holder,
        BoxFill = boxFill,
        BoxFillGradient = boxFillGradient,
        FullLines = fullLines,
        CornerLines = cornerLines,
        HealthBarBack = healthBarBack,
        HealthFill = healthFill,
        HealthGhost = healthGhost,
        HpText = hpText,
        NameLabel = nameLabel,
        NameGradient = nameGradient,
        WeaponLabel = weaponLabel,
        WeaponGradient = weaponGradient,
        AmmoLabel = ammoLabel,
        AmmoGradient = ammoGradient,
        ReloadLabel = reloadLabel,
        DistLabel = distLabel,
        DistGradient = distGradient,
        WeaponIcon = weaponIcon,
        WeaponIconShadow = weaponIconShadow,
        WeaponIconName = nil,
        Tracer = tracer,
        CurrentGhostHp = 1,
        TypewriterProgress = 0,
        WasVisible = false,
        EquipClock = 0,
        EquipName = "[None]",
        EquipAmmo = nil,
        EquipFighter = nil,
        ReloadClock = 0,
        ReloadState = false,
        LastFont = nil,
    }
end

-- ------------------------------------------------------------------
-- ESP render loop
-- ------------------------------------------------------------------
local espAccum = 0
RunSvc.RenderStepped:Connect(function(dt)
    if not esp.enabled then
        for _, f in pairs(espFrames) do
            if f.Holder.Visible then f.Holder.Visible = false end
            if f.Tracer.Visible then f.Tracer.Visible = false end
        end
        return
    end

    espAccum = espAccum + dt
    if espAccum < 0.03 then return end
    local frameDt = espAccum
    espAccum = 0

    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    local vp = cam.ViewportSize
    local ox, oy = vp.X / 2, vp.Y
    local now = os.clock()
    local myTeam = LP:GetAttribute("TeamID")

    for _, plr in ipairs(Players:GetPlayers()) do
        local f = espFrames[plr]
        if not f then
            f = createESPFrame(plr)
            espFrames[plr] = f
        end

        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local visible = plr ~= LP and hrp and hum and hum.Health > 0

        if visible and esp.teamCheck then
            local pt = plr:GetAttribute("TeamID")
            if myTeam ~= nil and pt ~= nil and myTeam == pt then visible = false end
        end

        local dist = 0
        if visible then
            dist = (hrp.Position - myHRP.Position).Magnitude
            if not esp.infiniteMaxDist and dist > esp.maxDist then
                visible = false
            end
        end

        if not visible then
            f.Holder.Visible = false
            f.Tracer.Visible = false
        else
            local bbox, size = char:GetBoundingBox()
            local half = size * 0.5
            local minX, minY = math.huge, math.huge
            local maxX, maxY = -math.huge, -math.huge
            local allOnScreen = true
            for _, corner in ipairs(BOUNDING_BOX_CORNERS) do
                local worldPt = bbox:PointToWorldSpace(half * corner)
                local screenPt = cam:WorldToViewportPoint(worldPt)
                if screenPt.Z <= 0 then
                    allOnScreen = false
                    break
                end
                minX = math.min(minX, screenPt.X)
                minY = math.min(minY, screenPt.Y)
                maxX = math.max(maxX, screenPt.X)
                maxY = math.max(maxY, screenPt.Y)
            end

            if not allOnScreen then
                f.Holder.Visible = false
                f.Tracer.Visible = false
            else
                local w = math.floor(maxX - minX)
                local h = math.floor(maxY - minY)
                f.Holder.Position = UDim2.fromOffset(math.floor(minX), math.floor(minY))
                f.Holder.Size = UDim2.fromOffset(w, h)
                local scale = math.clamp(h / 1000, 0.7, 1)
                local textSize = math.clamp(math.round(esp.textSize * scale), 10, math.max(10, esp.textSize))

                if not f.WasVisible then
                    f.TypewriterProgress = 0
                    f.WasVisible = true
                end
                f.TypewriterProgress = f.TypewriterProgress + frameDt * (esp.textAnimationSpeed or 30)

                -- Apply font if changed
                if f.LastFont ~= esp.font then
                    f.LastFont = esp.font
                    f.NameLabel.Font = esp.font
                    f.DistLabel.Font = esp.font
                    f.WeaponLabel.Font = esp.font
                    f.AmmoLabel.Font = esp.font
                    f.ReloadLabel.Font = esp.font
                    f.HpText.Font = esp.font
                end

                -- BoxFill
                f.BoxFill.Visible = esp.boxFill.enabled
                if esp.boxFill.enabled then
                    f.BoxFill.BackgroundTransparency = esp.boxFill.transparency
                    if esp.boxFill.animated then
                        f.BoxFillGradient.Color = makeAnimatedGradient(esp.boxFill.color1, esp.boxFill.color2, now, esp.boxFill.animationSpeed or 1, 0)
                    else
                        f.BoxFillGradient.Color = makeStaticGradient(esp.boxFill.color1, esp.boxFill.color2)
                    end
                end

                -- Box lines
                local boxOn = esp.box.enabled
                local cornerMode = esp.box.mode == "Corner"
                local thickness = esp.box.thickness or 1
                local transparency = esp.box.transparency or 0
                local boxColorSeq
                if esp.box.animated then
                    boxColorSeq = nil
                else
                    boxColorSeq = makeStaticGradient(esp.box.color1, esp.box.color2)
                end

                for _, line in pairs(f.FullLines) do
                    local show = boxOn and not cornerMode
                    line.Frame.Visible = show
                    if show then
                        line.Frame.BackgroundTransparency = transparency
                        line.Stroke.Transparency = transparency
                        if esp.box.animated then
                            line.Gradient.Color = makeAnimatedGradient(esp.box.color1, esp.box.color2, now, esp.box.animationSpeed or 1, line.Phase)
                        else
                            line.Gradient.Color = boxColorSeq
                        end
                    end
                end

                for _, line in pairs(f.CornerLines) do
                    local show = boxOn and cornerMode
                    line.Frame.Visible = show
                    if show then
                        line.Frame.BackgroundTransparency = transparency
                        line.Stroke.Transparency = transparency
                        if esp.box.animated then
                            line.Gradient.Color = makeAnimatedGradient(esp.box.color1, esp.box.color2, now, esp.box.animationSpeed or 1, line.Phase)
                        else
                            line.Gradient.Color = boxColorSeq
                        end
                    end
                end

                if cornerMode and boxOn then
                    local cornerLen = math.clamp(esp.box.cornerLength or 12, 4, math.max(4, math.floor(math.min(w, h) * 0.45)))
                    local cornerThick = esp.box.cornerThickness or 1
                    local CL = f.CornerLines
                    CL.TL_H.Frame.Position = UDim2.fromOffset(0, 0)
                    CL.TL_H.Frame.Size = UDim2.fromOffset(cornerLen, cornerThick)
                    CL.TL_V.Frame.Position = UDim2.fromOffset(0, 0)
                    CL.TL_V.Frame.Size = UDim2.fromOffset(cornerThick, cornerLen)
                    CL.TR_H.Frame.Position = UDim2.new(1, -cornerLen, 0, 0)
                    CL.TR_H.Frame.Size = UDim2.fromOffset(cornerLen, cornerThick)
                    CL.TR_V.Frame.Position = UDim2.new(1, -cornerThick, 0, 0)
                    CL.TR_V.Frame.Size = UDim2.fromOffset(cornerThick, cornerLen)
                    CL.BL_H.Frame.Position = UDim2.new(0, 0, 1, -cornerThick)
                    CL.BL_H.Frame.Size = UDim2.fromOffset(cornerLen, cornerThick)
                    CL.BL_V.Frame.Position = UDim2.new(0, 0, 1, -cornerLen)
                    CL.BL_V.Frame.Size = UDim2.fromOffset(cornerThick, cornerLen)
                    CL.BR_H.Frame.Position = UDim2.new(1, -cornerLen, 1, -cornerThick)
                    CL.BR_H.Frame.Size = UDim2.fromOffset(cornerLen, cornerThick)
                    CL.BR_V.Frame.Position = UDim2.new(1, -cornerThick, 1, -cornerLen)
                    CL.BR_V.Frame.Size = UDim2.fromOffset(cornerThick, cornerLen)
                end

                -- HealthBar
                f.HealthBarBack.Visible = esp.healthBar.enabled
                if esp.healthBar.enabled then
                    local hpFrac = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
                    local hbWidth = esp.healthBar.width or 1
                    local hbOffset = esp.healthBar.offset or 5
                    f.HealthBarBack.Position = UDim2.fromOffset(-hbOffset, 0)
                    f.HealthBarBack.Size = UDim2.new(0, hbWidth, 1, 0)
                    f.HealthFill.Size = UDim2.new(1, 0, hpFrac, 0)
                    if esp.healthBar.smoothDecay then
                        f.CurrentGhostHp = math.clamp(f.CurrentGhostHp - frameDt * 0.8, hpFrac, 1)
                        f.HealthGhost.Size = UDim2.new(1, 0, f.CurrentGhostHp, 0)
                    else
                        f.HealthGhost.Size = UDim2.new(1, 0, hpFrac, 0)
                    end
                    local hpColor = esp.healthBar.color1
                    if esp.healthBar.useDynamicColor then
                        if hpFrac > 0.5 then
                            hpColor = Color3.fromRGB(255, 215, 0):Lerp(Color3.fromRGB(50, 220, 90), (hpFrac - 0.5) * 2)
                        else
                            hpColor = Color3.fromRGB(255, 50, 50):Lerp(Color3.fromRGB(255, 215, 0), hpFrac * 2)
                        end
                    end
                    f.HealthFill.BackgroundColor3 = hpColor
                    if esp.healthBar.showText and hpFrac < 0.99 then
                        f.HpText.Text = tostring(math.floor(hum.Health))
                        f.HpText.Position = UDim2.new(0, -3, 1 - hpFrac, 0)
                        f.HpText.TextSize = math.max(8, textSize - 4)
                        f.HpText.TextColor3 = hpColor
                        f.HpText.Visible = true
                    else
                        f.HpText.Visible = false
                    end
                end

                -- Name
                f.NameLabel.Visible = esp.name.enabled
                if esp.name.enabled then
                    local displayName = plr.DisplayName or plr.Name
                    if esp.textAnimation then
                        local chars = math.clamp(math.floor(f.TypewriterProgress), 0, #displayName)
                        f.NameLabel.Text = displayName:sub(1, chars)
                    else
                        f.NameLabel.Text = displayName
                    end
                    f.NameLabel.TextSize = textSize
                    if esp.name.animated then
                        f.NameGradient.Color = makeAnimatedGradient(esp.name.color1, esp.name.color2, now, esp.name.animationSpeed or 1, 0)
                    else
                        f.NameGradient.Color = makeStaticGradient(esp.name.color1, esp.name.color2)
                    end
                    f.NameLabel.Size = UDim2.fromOffset(250, textSize + 2)
                end

                -- Distance
                f.DistLabel.Visible = esp.distance.enabled
                if esp.distance.enabled then
                    f.DistLabel.Text = string.format("[ %dm ]", math.floor(dist))
                    f.DistLabel.TextSize = math.max(8, textSize - 4)
                    if esp.distance.animated then
                        f.DistGradient.Color = makeAnimatedGradient(esp.distance.color1, esp.distance.color2, now, esp.distance.animationSpeed or 1, 0)
                    else
                        f.DistGradient.Color = makeStaticGradient(esp.distance.color1, esp.distance.color2)
                    end
                end

                -- Weapon / Ammo / Reload
                local textY = 0
                local tsW = math.max(9, textSize - 1)
                local tsA = math.max(8, textSize - 3)
                local tsR = math.max(8, textSize - 3)
                if now - (f.EquipClock or 0) >= 0.1 then
                    f.EquipClock = now
                    local wName, wAmmo, wFighter = getEquippedWeaponInfo(plr, char)
                    f.EquipName = wName
                    f.EquipAmmo = wAmmo
                    f.EquipFighter = wFighter
                end
                local equipName = f.EquipName or "[None]"
                local equipAmmo = f.EquipAmmo
                local equipFighter = f.EquipFighter

                local iconOn = esp.weaponIcon.enabled
                if equipName ~= f.WeaponIconName then
                    local thumb = getWeaponThumbnail(equipName)
                    f.WeaponIconName = equipName
                    f.WeaponIcon.Image = thumb
                    f.WeaponIconShadow.Image = thumb
                end
                local iconVisible = iconOn and f.WeaponIcon.Image ~= ""
                f.WeaponIcon.Visible = iconVisible
                f.WeaponIconShadow.Visible = iconVisible
                if iconVisible then
                    local iconScale = math.clamp(tonumber(esp.weaponIcon.scale) or 1, 0.5, 2)
                    local iw = math.floor(72 * iconScale * scale + 0.5)
                    local ih = math.floor(54 * iconScale * scale + 0.5)
                    local iyOff = esp.distance.enabled and math.max(14, textSize) + 5 or 3
                    f.WeaponIcon.Position = UDim2.new(0.5, 0, 1, iyOff)
                    f.WeaponIcon.Size = UDim2.fromOffset(iw, ih)
                    f.WeaponIconShadow.Position = UDim2.new(0.5, 1, 1, iyOff + 1)
                    f.WeaponIconShadow.Size = UDim2.fromOffset(iw, ih)
                end

                f.WeaponLabel.Visible = esp.weapon.enabled
                if esp.weapon.enabled then
                    if esp.textAnimation then
                        local c = math.clamp(math.floor(f.TypewriterProgress), 0, #equipName)
                        f.WeaponLabel.Text = equipName:sub(1, c)
                    else
                        f.WeaponLabel.Text = equipName
                    end
                    f.WeaponLabel.TextSize = tsW
                    if esp.weapon.animated then
                        f.WeaponGradient.Color = makeAnimatedGradient(esp.weapon.color1, esp.weapon.color2, now, esp.weapon.animationSpeed or 1, 0)
                    else
                        f.WeaponGradient.Color = makeStaticGradient(esp.weapon.color1, esp.weapon.color2)
                    end
                    f.WeaponLabel.Position = UDim2.new(1, 4, 0, textY)
                    f.WeaponLabel.Size = UDim2.new(0, 250, 0, tsW)
                    textY = textY + tsW

                    local showAmmo = esp.ammo.enabled and equipAmmo and equipAmmo ~= ""
                    if showAmmo then
                        if esp.textAnimation then
                            local c = math.clamp(math.floor(f.TypewriterProgress), 0, #equipAmmo)
                            f.AmmoLabel.Text = equipAmmo:sub(1, c)
                        else
                            f.AmmoLabel.Text = equipAmmo
                        end
                        f.AmmoLabel.TextSize = tsA
                        if esp.ammo.animated then
                            f.AmmoGradient.Color = makeAnimatedGradient(esp.ammo.color1, esp.ammo.color2, now, esp.ammo.animationSpeed or 1, 0)
                        else
                            f.AmmoGradient.Color = makeStaticGradient(esp.ammo.color1, esp.ammo.color2)
                        end
                        f.AmmoLabel.Position = UDim2.new(1, 4, 0, textY)
                        f.AmmoLabel.Size = UDim2.new(0, 250, 0, tsA)
                        f.AmmoLabel.Visible = true
                        textY = textY + tsA
                    else
                        f.AmmoLabel.Visible = false
                    end
                else
                    f.WeaponLabel.Visible = false
                    f.AmmoLabel.Visible = false
                end

                local showReload = false
                if esp.reload.enabled then
                    if now - (f.ReloadClock or 0) >= 0.1 then
                        f.ReloadClock = now
                        f.ReloadState = isReloading(equipFighter, char)
                    end
                    showReload = f.ReloadState
                end
                if showReload then
                    f.ReloadLabel.TextSize = tsR
                    f.ReloadLabel.TextColor3 = esp.reload.color
                    f.ReloadLabel.Position = UDim2.new(1, 4, 0, textY)
                    f.ReloadLabel.Size = UDim2.new(0, 250, 0, tsR)
                    if esp.reload.animated then
                        f.ReloadLabel.Text = RELOAD_DOTS[math.floor(now * 3.5) % 4 + 1]
                    else
                        f.ReloadLabel.Text = "[RELOADING]"
                    end
                    f.ReloadLabel.Visible = true
                else
                    f.ReloadLabel.Visible = false
                end

                f.Holder.Visible = true

                -- Tracer
                if esp.tracer then
                    f.Tracer.Visible = true
                    local x1, y1 = ox, oy
                    local x2, y2 = minX + w / 2, maxY
                    local dx, dy = x2 - x1, y2 - y1
                    local len = math.sqrt(dx * dx + dy * dy)
                    f.Tracer.Size = UDim2.fromOffset(len, 1)
                    f.Tracer.AnchorPoint = Vector2.new(0.5, 0.5)
                    f.Tracer.Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2)
                    f.Tracer.Rotation = math.deg(math.atan2(dy, dx))
                    f.Tracer.BackgroundColor3 = esp.tracerColor
                else
                    f.Tracer.Visible = false
                end
            end
        end
    end

    for plr, f in pairs(espFrames) do
        if not plr.Parent then
            f.Holder:Destroy()
            f.Tracer:Destroy()
            espFrames[plr] = nil
        end
    end
end)

-- END OF CHUNK 2 --
-- ============================================================
-- CHAMS (kept from SCRIPT 1)
-- ============================================================
local chams = { enabled = false, teamCheck = true, fillColor = Color3.fromRGB(150, 60, 60), outlineColor = Color3.new(1, 1, 1), fillTransparency = 0.5 }
local chamsHighlights = {}
RunSvc.Heartbeat:Connect(function()
    if not chams.enabled then
        for _, h in pairs(chamsHighlights) do pcall(function() h:Destroy() end) end
        chamsHighlights = {}
        return
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        local isEnemy = plr ~= LP and char and (not chams.teamCheck or plr.Team == nil or plr.Team ~= LP.Team)
        if isEnemy then
            local h = chamsHighlights[plr]
            if not h or h.Parent ~= char or h.Adornee ~= char then
                if h then h:Destroy() end
                h = Instance.new("Highlight", char)
                h.Adornee = char
                chamsHighlights[plr] = h
            end
            h.FillColor = chams.fillColor
            h.OutlineColor = chams.outlineColor
            h.FillTransparency = chams.fillTransparency
            h.OutlineTransparency = 0
        else
            local h = chamsHighlights[plr]
            if h then h:Destroy(); chamsHighlights[plr] = nil end
        end
    end
    for plr, h in pairs(chamsHighlights) do
        if not plr.Parent or not plr.Character then h:Destroy(); chamsHighlights[plr] = nil end
    end
end)

-- ============================================================
-- TABS
-- ============================================================
local tabs = {
    { name = "Graviton", content = nil }, { name = "Underground", content = nil }, { name = "Ragebot", content = nil },
    { name = "Evasion", content = nil }, { name = "Void", content = nil }, { name = "Patterns", content = nil },
    { name = "Visuals", content = nil }, { name = "Combat", content = nil }, { name = "Orbit", content = nil },
}

local tabBar = make("Frame", { Position = UDim2.fromOffset(9, 33), Size = UDim2.fromOffset(622, 42), BackgroundTransparency = 1 }, main)
local buttons, current = {}, 1
for i, t in ipairs(tabs) do
    local c = make("ScrollingFrame", { Position = UDim2.fromOffset(9, 96), Size = UDim2.fromOffset(622, 440), BackgroundTransparency = 1, Visible = (i == 1), ScrollBarThickness = 4, ScrollBarImageColor3 = col.tabLineOn, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y }, main)
    t.content = c
    make("UIGridLayout", { CellSize = UDim2.fromOffset(306, 215), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }, c)

    local b = make("TextButton", { Position = UDim2.fromScale((i - 1) / #tabs, 0), Size = UDim2.fromScale(1 / #tabs, 1), BorderSizePixel = 0, AutoButtonColor = false, Text = t.name, Font = font, TextSize = fsize, TextTruncate = Enum.TextTruncate.AtEnd }, tabBar)
    buttons[i] = { btn = b, line = outline(b, col.tabLine) }
    b.MouseButton1Click:Connect(function()
        current = i
        for j, bb in ipairs(buttons) do
            local on = j == i
            bb.btn.BackgroundColor3 = on and col.tabOn or col.tab
            bb.btn.TextColor3      = on and col.accent or col.dim
            bb.line.Color          = on and col.tabLineOn or col.tabLine
        end
        for j, tt in ipairs(tabs) do tt.content.Visible = (j == i) end
    end)
    b.MouseEnter:Connect(function() if current ~= i then b.TextColor3 = col.text end end)
    b.MouseLeave:Connect(function() if current ~= i then b.TextColor3 = col.dim end end)
end

local foot = make("Frame", { Position = UDim2.fromOffset(9, 552), Size = UDim2.fromOffset(622, 26), BackgroundColor3 = col.panel, BorderSizePixel = 0 }, main)
outline(foot, col.panelLine)
label(foot, "welcome back", UDim2.fromOffset(8, 0), UDim2.new(0.6, 0, 1, 0), col.off)
label(foot, "[ ULTIMATE COMBAT ]", UDim2.new(0.4, -8, 0, 0), UDim2.new(0.6, 0, 1, 0), col.off, Enum.TextXAlignment.Right)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        main.Size = UDim2.fromOffset(640, 32); minBtn.Text = "+"; tabBar.Visible = false; foot.Visible = false
        for _, tt in ipairs(tabs) do tt.content.Visible = false end
    else
        main.Size = UDim2.fromOffset(640, 590); minBtn.Text = "-"; tabBar.Visible = true; foot.Visible = true
        for j, tt in ipairs(tabs) do tt.content.Visible = (j == current) end
    end
end)

-- ============================================================
-- COMBAT STATE (used by Combat tab, Aimbot, SilentAim, etc.)
-- ============================================================
local combat = {
    aim_enabled = false, aim_key = false, aim_fov = 120, aim_smooth = 0.5,
    aim_team = true, aim_wall = false, aim_part = "Head", aim_show_fov = true,
    aim_sticky = false, aim_target = nil, aim_prediction = 0.15,
    silent_enabled = false, silent_fov = 150, silent_team = true, silent_wall = false,
    silent_part = "Head", silent_show_fov = false, silent_target = nil,
    trigger_enabled = false, trigger_fov = 20, trigger_delay = 0.1, trigger_last = 0,
    auto_shoot = false, auto_shoot_delay = 0.1, auto_shoot_last = 0,
    hitbox_enabled = false, hitbox_size = 5, hitbox_trans = 0.5, hitbox_team = true,
    hitbox_original = {},
    cross_enabled = false, cross_color = Color3.new(1, 1, 1), cross_gap = 4, cross_thick = 1, cross_len = 6,
}

local function updateCrosshair()
    crossCenter.Visible = combat.cross_enabled
    if not combat.cross_enabled then return end
    cLines[1].BackgroundColor3 = combat.cross_color; cLines[1].Size = UDim2.fromOffset(combat.cross_thick, combat.cross_len); cLines[1].Position = UDim2.fromOffset(-combat.cross_thick/2, -combat.cross_gap - combat.cross_len)
    cLines[2].BackgroundColor3 = combat.cross_color; cLines[2].Size = UDim2.fromOffset(combat.cross_thick, combat.cross_len); cLines[2].Position = UDim2.fromOffset(-combat.cross_thick/2, combat.cross_gap)
    cLines[3].BackgroundColor3 = combat.cross_color; cLines[3].Size = UDim2.fromOffset(combat.cross_len, combat.cross_thick); cLines[3].Position = UDim2.fromOffset(-combat.cross_gap - combat.cross_len, -combat.cross_thick/2)
    cLines[4].BackgroundColor3 = combat.cross_color; cLines[4].Size = UDim2.fromOffset(combat.cross_len, combat.cross_thick); cLines[4].Position = UDim2.fromOffset(combat.cross_gap, -combat.cross_thick/2)
end

local function safeClick()
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        if vim then
            local pos = UIS:GetMouseLocation()
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
            task.wait(0.01)
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
        end
    end)
end

local function getTarget(fov, partName, teamCheck, wallCheck)
    local closest, shortest = nil, fov
    local mouse = UIS:GetMouseLocation()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local skip = false
                if teamCheck and p.Team == LP.Team then skip = true end
                if not skip then
                    local part = p.Character:FindFirstChild(partName) or p.Character:FindFirstChild("HumanoidRootPart")
                    if part then
                        local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude
                            if dist < shortest then
                                if wallCheck then
                                    local ray = Ray.new(cam.CFrame.Position, part.Position - cam.CFrame.Position)
                                    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LP.Character, p.Character})
                                    if not hit then
                                        shortest = dist
                                        closest = { player = p, part = part, hum = hum }
                                    end
                                else
                                    shortest = dist
                                    closest = { player = p, part = part, hum = hum }
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

local cachedSilentTarget = nil
RunSvc.RenderStepped:Connect(function()
    if combat.silent_enabled then
        cachedSilentTarget = getTarget(combat.silent_fov, combat.silent_part, combat.silent_team, combat.silent_wall)
    end
end)

RunSvc.RenderStepped:Connect(function(dt)
    if combat.aim_show_fov and (combat.aim_enabled or combat.aim_key) then
        fovFrameAimbot.Visible = true; fovFrameAimbot.Size = UDim2.fromOffset(combat.aim_fov * 2, combat.aim_fov * 2)
    else fovFrameAimbot.Visible = false end
    if combat.silent_show_fov and combat.silent_enabled then
        fovFrameSilent.Visible = true; fovFrameSilent.Size = UDim2.fromOffset(combat.silent_fov * 2, combat.silent_fov * 2)
    else fovFrameSilent.Visible = false end

    updateCrosshair()

    if combat.aim_enabled or combat.aim_key then
        if not combat.aim_sticky or not combat.aim_target or not combat.aim_target.part.Parent or combat.aim_target.hum.Health <= 0 then
            combat.aim_target = getTarget(combat.aim_fov, combat.aim_part, combat.aim_team, combat.aim_wall)
        end
        if combat.aim_target and combat.aim_target.part then
            local targetPos = combat.aim_target.part.Position
            if combat.aim_prediction > 0 then
                targetPos = targetPos + (combat.aim_target.part.AssemblyLinearVelocity * combat.aim_prediction)
            end
            local targetCF = CFrame.lookAt(cam.CFrame.Position, targetPos)
            cam.CFrame = cam.CFrame:Lerp(targetCF, combat.aim_smooth)
        end
    end

    if combat.auto_shoot and tick() - combat.auto_shoot_last > combat.auto_shoot_delay then
        local t = getTarget(combat.aim_fov, combat.aim_part, combat.aim_team, false)
        if t then
            combat.auto_shoot_last = tick()
            safeClick()
        end
    end
end)

RunSvc.Heartbeat:Connect(function()
    if not combat.trigger_enabled then return end
    local t = getTarget(combat.trigger_fov, combat.aim_part, combat.aim_team, false)
    if t and tick() - combat.trigger_last > combat.trigger_delay then
        combat.trigger_last = tick()
        safeClick()
    end
end)

pcall(function()
    if getgenv and hookmetamethod then
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", function(self, key)
            if not checkcaller() and combat.silent_enabled then
                if self == LP:GetMouse() or self == cam then
                    if key == "Hit" or key == "Target" then
                        if cachedSilentTarget and cachedSilentTarget.part then
                            if key == "Hit" then return CFrame.lookAt(cam.CFrame.Position, cachedSilentTarget.part.Position)
                            elseif key == "Target" then return cachedSilentTarget.part end
                        end
                    end
                end
            end
            return oldIndex(self, key)
        end)
    end
end)

RunSvc.Heartbeat:Connect(function()
    if not combat.hitbox_enabled then
        for p, parts in pairs(combat.hitbox_original) do
            for partName, origSize in pairs(parts) do
                local part = p.Character and p.Character:FindFirstChild(partName)
                if part then pcall(function() part.Size = origSize; part.Transparency = 0 end) end
            end
        end
        combat.hitbox_original = {}
        return
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and (not combat.hitbox_team or p.Team ~= LP.Team) then
            combat.hitbox_original[p] = combat.hitbox_original[p] or {}
            for _, partName in ipairs({"Head"}) do
                local part = p.Character:FindFirstChild(partName)
                if part then
                    if not combat.hitbox_original[p][partName] then
                        combat.hitbox_original[p][partName] = part.Size
                    end
                    if part.Size ~= Vector3.new(combat.hitbox_size, combat.hitbox_size, combat.hitbox_size) then
                        pcall(function()
                            part.Size = Vector3.new(combat.hitbox_size, combat.hitbox_size, combat.hitbox_size)
                            part.Transparency = combat.hitbox_trans
                            part.CanCollide = false
                        end)
                    end
                end
            end
        end
    end
end)

-- END OF CHUNK 3 --
-- ============================================================
-- COMBAT TAB (tabs[8]) + Silent Aim V2 (from SCRIPT 2)
-- Silent Aim V2 is placed at the TOP for visibility.
-- ============================================================
do
    local colC = makeColumn(tabs[8].content)

    -- ============================================================
    -- SILENT AIM V2 (transferred from SCRIPT 2) — placed first
    -- ============================================================
    local SA2 = {
        enabled = false,
        part = "Head",
        closestPart = false,
        followGunpoint = false,
        hitChance = 100,
        team = true,
        manipulation = false,
        checks = { shield = false, katana = false, wall = false },
        fov = {
            enabled = false,
            fill = false,
            radius = 180,
            lerp = 1,
            thickness = 2,
            speed = 90,
            transparency = 0.2,
            fillTransparency = 0.6,
            color1 = Color3.fromRGB(120, 81, 166),
            color2 = Color3.fromRGB(255, 255, 255),
            fillColor1 = Color3.fromRGB(120, 81, 166),
            fillColor2 = Color3.fromRGB(255, 0, 255),
        },
    }

    local sa2Cache = {}
    local function sa2GetFC()
        if sa2Cache.FC == false then return nil end
        if sa2Cache.FC then return sa2Cache.FC end
        local ok, m = pcall(function()
            local c = LP.PlayerScripts:FindFirstChild("Controllers")
            return c and require(c.FighterController)
        end)
        if ok and m then sa2Cache.FC = m; return m end
        sa2Cache.FC = false
        return nil
    end
    local function sa2GetUtil()
        if sa2Cache.util == false then return nil end
        if sa2Cache.util then return sa2Cache.util end
        local ok, m = pcall(function()
            local RS2 = game:GetService("ReplicatedStorage")
            return require(RS2.Modules.Utility)
        end)
        if ok and m then sa2Cache.util = m; return m end
        sa2Cache.util = false
        return nil
    end
    local function sa2GetEnumLib()
        if sa2Cache.enum == false then return nil end
        if sa2Cache.enum then return sa2Cache.enum end
        local ok, m = pcall(function()
            local RS2 = game:GetService("ReplicatedStorage")
            return require(RS2.Modules.EnumLibrary)
        end)
        if ok and m then sa2Cache.enum = m; return m end
        sa2Cache.enum = false
        return nil
    end
    local function sa2GetUseItem()
        if sa2Cache.useItem == false then return nil end
        if sa2Cache.useItem then return sa2Cache.useItem end
        local ok, r = pcall(function()
            local RS2 = game:GetService("ReplicatedStorage")
            local rep = RS2:FindFirstChild("Remotes")
            rep = rep and rep:FindFirstChild("Replication")
            rep = rep and rep:FindFirstChild("Fighter")
            return rep and rep:FindFirstChild("UseItem")
        end)
        if ok and r then sa2Cache.useItem = r; return r end
        sa2Cache.useItem = false
        return nil
    end

    -- ---- FOV Circle GUI ----
    local sa2Gui = make("ScreenGui", { Name = "SA2FovGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 9997 }, Players.LocalPlayer:WaitForChild("PlayerGui"))
    local sa2FovFrame = make("Frame", { Name = "FOV", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, Size = UDim2.fromOffset(0, 0), ZIndex = 2 }, sa2Gui)
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, sa2FovFrame)
    local sa2Fill = make("Frame", { Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, BackgroundTransparency = 1, ZIndex = 1 }, sa2FovFrame)
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, sa2Fill)
    local sa2FillGrad = make("UIGradient", {}, sa2Fill)
    local sa2Stroke = make("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 2, Transparency = 0.2, ZIndex = 3 }, sa2FovFrame)
    local sa2StrokeGrad = make("UIGradient", {}, sa2Stroke)

    local function sa2GetClosestPart(char, centre)
        local closest, minD = nil, math.huge
        for _, p in ipairs(char:GetChildren()) do
            if p:IsA("BasePart") then
                local sp, on = cam:WorldToViewportPoint(p.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - centre).Magnitude
                    if d < minD then minD = d; closest = p end
                end
            end
        end
        return closest
    end

    local function sa2PassesChecks(plr, part)
        if SA2.checks.shield then
            local vm = workspace:FindFirstChild("ViewModels")
            if vm and vm:FindFirstChild(plr.Name .. " - Riot Shield - Riot Shield") then return false end
        end
        if SA2.checks.katana then
            local FC = sa2GetFC()
            if FC then
                local ok, f = pcall(function()
                    local tbl = FC._player_to_fighter
                    return tbl and tbl[plr]
                end)
                if ok and f and f.EquippedItem and f.EquippedItem.Name == "Katana" then return false end
            end
        end
        if SA2.checks.wall and cam then
            local origin = cam.CFrame.Position
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            rp.FilterDescendantsInstances = { LP.Character, part.Parent, workspace:FindFirstChild("ViewModels") }
            local hit = workspace:Raycast(origin, part.Position - origin, rp)
            if hit then return false end
        end
        return true
    end

    local function sa2PickTarget()
        if not cam then return nil end
        local mouse = UIS:GetMouseLocation()
        local centre = SA2.followGunpoint and Vector2.new(mouse.X, mouse.Y) or (cam.ViewportSize * 0.5)
        local myTeam = LP:GetAttribute("TeamID")
        local myEnv = LP:GetAttribute("EnvironmentID")
        local best, bestDist = nil, SA2.fov.radius
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local char = plr.Character
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and char:FindFirstChild("HumanoidRootPart") then
                    local pEnv = plr:GetAttribute("EnvironmentID")
                    local skip = false
                    if SA2.team and myTeam ~= nil and plr:GetAttribute("TeamID") == myTeam then skip = true end
                    if myEnv and pEnv and pEnv ~= myEnv then skip = true end
                    if not skip then
                        local part
                        if SA2.closestPart then part = sa2GetClosestPart(char, centre)
                        else part = char:FindFirstChild(SA2.part) or char:FindFirstChild("HumanoidRootPart") end
                        if part and sa2PassesChecks(plr, part) then
                            local sp, on = cam:WorldToViewportPoint(part.Position)
                            if on then
                                local d = (Vector2.new(sp.X, sp.Y) - centre).Magnitude
                                if d < bestDist then
                                    bestDist = d
                                    best = { player = plr, part = part, char = char }
                                end
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    local function sa2GetOrigin(targetPart)
        if not cam then return nil end
        local origin = cam.CFrame.Position
        local target = targetPart.Position
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = { LP.Character, targetPart.Parent, workspace:FindFirstChild("ViewModels") }
        local hit = workspace:Raycast(origin, target - origin, rp)
        if not hit then return origin end
        local candidates = {}
        for _, d in ipairs({ 0.5, 1, 2, 4, 8 }) do
            candidates[#candidates + 1] = hit.Position + hit.Normal * d
        end
        candidates[#candidates + 1] = origin + Vector3.new(0, 1, 0)
        candidates[#candidates + 1] = origin + Vector3.new(0, 2, 0)
        candidates[#candidates + 1] = origin + Vector3.new(0, 3, 0)
        candidates[#candidates + 1] = origin - Vector3.new(0, 1, 0)
        candidates[#candidates + 1] = hit.Position - hit.Normal * 0.5
        for _, c in ipairs(candidates) do
            local h2 = workspace:Raycast(c, target - c, rp)
            if not h2 then return c end
        end
        return origin
    end

    local sa2CachedTarget, sa2CachedAt = nil, 0
    RunSvc.RenderStepped:Connect(function()
        if not SA2.enabled then sa2CachedTarget = nil; return end
        local t = sa2PickTarget()
        if t then
            sa2CachedTarget = t
            sa2CachedAt = tick()
        elseif tick() - sa2CachedAt > 0.3 then
            sa2CachedTarget = nil
        end
    end)

    local sa2HookInstalled = false
    local function sa2InstallHook()
        if sa2HookInstalled then return end
        local ok, GunMod = pcall(function() return require(LP.PlayerScripts.Modules.ItemTypes.Gun) end)
        if not ok or not GunMod or not GunMod.StartShooting then return end
        local priorStart = GunMod.StartShooting
        GunMod.StartShooting = function(self, ...)
            local ret = priorStart(self, ...)
            if not SA2.enabled then return ret end
            local t = sa2CachedTarget
            if not t or not t.part or not t.part.Parent then return ret end
            if math.random(1, 100) > SA2.hitChance then return ret end
            pcall(function()
                local FC = sa2GetFC()
                local Util = sa2GetUtil()
                local EnumLib = sa2GetEnumLib()
                local remote = sa2GetUseItem()
                if not (FC and Util and EnumLib and remote) then return end
                local lf = FC.LocalFighter
                if not lf or not lf.EquippedItem then return end
                local objId
                pcall(function() objId = lf.EquippedItem:Get("ObjectID") end)
                if not objId then return end
                local origin = cam.CFrame.Position
                if SA2.manipulation then
                    local better = sa2GetOrigin(t.part)
                    if better then origin = better end
                end
                local aimCF = CFrame.lookAt(origin, t.part.Position)
                local offset = t.part.CFrame:ToObjectSpace(CFrame.new(t.part.Position))
                local data = {
                    [utf8.char(1)] = {
                        [utf8.char(0)] = Util:EncodeCFrame(aimCF),
                        [utf8.char(1)] = Util:EncodeCFrame(t.part.CFrame),
                        [utf8.char(2)] = t.part,
                        [utf8.char(3)] = Util:EncodeCFrame(offset),
                    }
                }
                local en
                pcall(function() en = EnumLib:ToEnum("StartShooting") end)
                if not en then return end
                remote:FireServer(objId, en, data, nil)
            end)
            return ret
        end
        sa2HookInstalled = true
    end
    task.spawn(function()
        for _ = 1, 30 do
            sa2InstallHook()
            if sa2HookInstalled then break end
            task.wait(0.5)
        end
    end)

    local sa2CurrentRadius = SA2.fov.radius
    local sa2GradAngle = 0
    RunSvc.RenderStepped:Connect(function(dt)
        if not (SA2.fov.enabled and SA2.enabled) then
            if sa2FovFrame.Visible then sa2FovFrame.Visible = false end
            return
        end
        sa2FovFrame.Visible = true
        local alpha = math.clamp(SA2.fov.lerp or 1, 0.01, 1)
        if alpha >= 1 then
            sa2CurrentRadius = SA2.fov.radius
        else
            sa2CurrentRadius = sa2CurrentRadius + (SA2.fov.radius - sa2CurrentRadius) * alpha
        end
        sa2FovFrame.Size = UDim2.fromOffset(sa2CurrentRadius * 2, sa2CurrentRadius * 2)
        if SA2.followGunpoint then
            local m = UIS:GetMouseLocation()
            sa2FovFrame.Position = UDim2.fromOffset(m.X, m.Y)
        else
            sa2FovFrame.Position = UDim2.fromScale(0.5, 0.5)
        end
        sa2Stroke.Thickness = SA2.fov.thickness
        sa2Stroke.Transparency = SA2.fov.transparency
        sa2GradAngle = (sa2GradAngle + dt * SA2.fov.speed) % 360
        sa2StrokeGrad.Rotation = sa2GradAngle
        sa2StrokeGrad.Color = ColorSequence.new(SA2.fov.color1, SA2.fov.color2)
        if SA2.fov.fill then
            sa2Fill.BackgroundTransparency = 1 - SA2.fov.fillTransparency
            sa2FillGrad.Color = ColorSequence.new(SA2.fov.fillColor1, SA2.fov.fillColor2)
        else
            sa2Fill.BackgroundTransparency = 1
        end
    end)

    -- ---- Silent Aim V2 UI (first in the tab) ----
    local sa2Sec = colC:section({ name = "Silent Aim V2" })
    sa2Sec:toggle({ name = "Enable Silent Aim V2", default = false, callback = function(v) SA2.enabled = v end })
    sa2Sec:slider({ name = "Hit Chance %", min = 1, max = 100, interval = 1, default = 100, callback = function(v) SA2.hitChance = v end })
    sa2Sec:toggle({ name = "Closest Part", default = false, callback = function(v) SA2.closestPart = v end })
    sa2Sec:toggle({ name = "Follow Gunpoint", default = false, callback = function(v) SA2.followGunpoint = v end })
    sa2Sec:toggle({ name = "Team Check", default = true, callback = function(v) SA2.team = v end })
    sa2Sec:toggle({ name = "Shield Check", default = false, callback = function(v) SA2.checks.shield = v end })
    sa2Sec:toggle({ name = "Katana Check", default = false, callback = function(v) SA2.checks.katana = v end })
    sa2Sec:toggle({ name = "Wall Check", default = false, callback = function(v) SA2.checks.wall = v end })
    sa2Sec:toggle({ name = "Manipulation (through walls)", default = false, callback = function(v) SA2.manipulation = v end })
    sa2Sec:dropdown({ name = "Target Part", items = {"Head","HumanoidRootPart","UpperTorso","LowerTorso","HitboxHead","HitboxBody"}, default = "Head", callback = function(v) SA2.part = v end })

    local sa2FovSec = colC:section({ name = "Silent Aim V2 - FOV" })
    sa2FovSec:toggle({ name = "Show FOV Circle", default = false, callback = function(v) SA2.fov.enabled = v end })
    sa2FovSec:toggle({ name = "Fill", default = false, callback = function(v) SA2.fov.fill = v end })
    sa2FovSec:slider({ name = "Radius", min = 10, max = 500, interval = 1, default = 180, callback = function(v) SA2.fov.radius = v end })
    sa2FovSec:slider({ name = "Thickness", min = 1, max = 10, interval = 1, default = 2, callback = function(v) SA2.fov.thickness = v end })
    sa2FovSec:slider({ name = "Lerp", min = 0.01, max = 1, interval = 0.01, default = 1, callback = function(v) SA2.fov.lerp = v end })
    sa2FovSec:slider({ name = "Speed (rotation)", min = 0, max = 360, interval = 1, default = 90, callback = function(v) SA2.fov.speed = v end })
    sa2FovSec:slider({ name = "Transparency", min = 0, max = 1, interval = 0.05, default = 0.2, callback = function(v) SA2.fov.transparency = v end })
    sa2FovSec:slider({ name = "Fill Transparency", min = 0, max = 1, interval = 0.05, default = 0.6, callback = function(v) SA2.fov.fillTransparency = v end })
    sa2FovSec:dropdown({ name = "Stroke Color 1", items = PRESET_KEYS, default = "Purple", callback = function(v) SA2.fov.color1 = PRESET_COLORS[v] or SA2.fov.color1 end })
    sa2FovSec:dropdown({ name = "Stroke Color 2", items = PRESET_KEYS, default = "White", callback = function(v) SA2.fov.color2 = PRESET_COLORS[v] or SA2.fov.color2 end })
    sa2FovSec:dropdown({ name = "Fill Color 1", items = PRESET_KEYS, default = "Purple", callback = function(v) SA2.fov.fillColor1 = PRESET_COLORS[v] or SA2.fov.fillColor1 end })
    sa2FovSec:dropdown({ name = "Fill Color 2", items = PRESET_KEYS, default = "Magenta", callback = function(v) SA2.fov.fillColor2 = PRESET_COLORS[v] or SA2.fov.fillColor2 end })

    -- ============================================================
    -- ORIGINAL COMBAT TAB CONTENT
    -- ============================================================
    local aimSec = colC:section({ name = "Aimbot" })
    aimSec:toggle({ name = "Enable Aimbot", default = false, callback = function(v) combat.aim_enabled = v end })
    aimSec:keybind({ name = "Aim Key (Toggle)", callback = function(v) combat.aim_key = v end })
    aimSec:slider({ name = "FOV", min = 10, max = 500, interval = 1, default = 120, callback = function(v) combat.aim_fov = v end })
    aimSec:slider({ name = "Smoothness", min = 0.01, max = 1, interval = 0.01, default = 0.5, callback = function(v) combat.aim_smooth = v end })
    aimSec:slider({ name = "Prediction", min = 0, max = 1, interval = 0.01, default = 0.15, callback = function(v) combat.aim_prediction = v end })
    aimSec:toggle({ name = "Team Check", default = true, callback = function(v) combat.aim_team = v end })
    aimSec:toggle({ name = "Wall Check", default = false, callback = function(v) combat.aim_wall = v end })
    aimSec:toggle({ name = "Sticky Aim", default = false, callback = function(v) combat.aim_sticky = v end })
    aimSec:toggle({ name = "Show FOV Circle", default = true, callback = function(v) combat.aim_show_fov = v end })
    aimSec:dropdown({ name = "Target Part", items = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, default = "Head", callback = function(v) combat.aim_part = v end })

    local silentSec = colC:section({ name = "Silent Aim" })
    silentSec:toggle({ name = "Enable Silent Aim", default = false, callback = function(v) combat.silent_enabled = v end })
    silentSec:slider({ name = "FOV", min = 10, max = 500, interval = 1, default = 150, callback = function(v) combat.silent_fov = v end })
    silentSec:toggle({ name = "Team Check", default = true, callback = function(v) combat.silent_team = v end })
    silentSec:toggle({ name = "Wall Check", default = false, callback = function(v) combat.silent_wall = v end })
    silentSec:toggle({ name = "Show FOV Circle", default = false, callback = function(v) combat.silent_show_fov = v end })
    silentSec:dropdown({ name = "Target Part", items = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, default = "Head", callback = function(v) combat.silent_part = v end })

    local triggerSec = colC:section({ name = "Triggerbot / AutoShoot" })
    triggerSec:toggle({ name = "Enable Triggerbot", default = false, callback = function(v) combat.trigger_enabled = v end })
    triggerSec:slider({ name = "Trigger FOV", min = 5, max = 100, interval = 1, default = 20, callback = function(v) combat.trigger_fov = v end })
    triggerSec:slider({ name = "Trigger Delay", min = 0.01, max = 1, interval = 0.01, default = 0.1, callback = function(v) combat.trigger_delay = v end })
    triggerSec:toggle({ name = "Enable Auto Shoot", default = false, callback = function(v) combat.auto_shoot = v end })
    triggerSec:slider({ name = "Auto Shoot Delay", min = 0.01, max = 1, interval = 0.01, default = 0.1, callback = function(v) combat.auto_shoot_delay = v end })

    local hbSec = colC:section({ name = "Hitbox Expander" })
    hbSec:toggle({ name = "Enable Hitbox Expander", default = false, callback = function(v) combat.hitbox_enabled = v end })
    hbSec:slider({ name = "Hitbox Size", min = 1, max = 20, interval = 0.5, default = 5, callback = function(v) combat.hitbox_size = v end })
    hbSec:slider({ name = "Transparency", min = 0, max = 1, interval = 0.1, default = 0.5, callback = function(v) combat.hitbox_trans = v end })
    hbSec:toggle({ name = "Team Check", default = true, callback = function(v) combat.hitbox_team = v end })

    local crossSec = colC:section({ name = "Crosshair" })
    crossSec:toggle({ name = "Enable Crosshair", default = false, callback = function(v) combat.cross_enabled = v end })
    crossSec:slider({ name = "Gap", min = 0, max = 20, interval = 1, default = 4, callback = function(v) combat.cross_gap = v end })
    crossSec:slider({ name = "Thickness", min = 1, max = 5, interval = 1, default = 1, callback = function(v) combat.cross_thick = v end })
    crossSec:slider({ name = "Length", min = 1, max = 20, interval = 1, default = 6, callback = function(v) combat.cross_len = v end })
    crossSec:dropdown({ name = "Color", items = PRESET_KEYS, default = "White", callback = function(v) combat.cross_color = PRESET_COLORS[v] end })
end

-- END OF REPLACEMENT CHUNK 4 (v2) --
-- ============================================================
-- 1. GRAVITON RAGE (Expanded)
-- ============================================================
do
    local col1 = makeColumn(tabs[1].content)
    xpcall(function()
        local Players = game:GetService('Players')
        local RunService = game:GetService('RunService')
        local UIS = game:GetService('UserInputService')
        local RS_ = game:GetService('ReplicatedStorage')
        local LP = Players.LocalPlayer
        local GR = { on = false, rate = 0.001, slot = 1, desync = true, void = true, head = true, extra = true, knife = true, equip = true, fov = 9999 }
        local _FC, _SC, _util, _enum, _remote = false, false, false, false, false
        local alive = true
        task.spawn(function()
            for _ = 1, 60 do
                if not alive then return end
                pcall(function()
                    if not _util then _util = require(RS_.Modules.Utility) or false end
                    if not _enum then _enum = require(RS_.Modules.EnumLibrary) or false end
                    if not _FC   then _FC = require(LP.PlayerScripts.Controllers.FighterController) or false end
                    if not _SC   then _SC = require(LP.PlayerScripts.Controllers:WaitForChild('SpectateController', 3)) or false end
                    if not _remote then _remote = RS_.Remotes.Replication.Fighter.UseItem end
                end)
                if _util and _enum and _FC and _SC and _remote then break end
                task.wait(0.5)
            end
        end)
        local K0, K1, K2, K3 = utf8.char(0), utf8.char(1), utf8.char(2), utf8.char(3)
        local EYE = Vector3.new(0, 1.5, 0)
        local hb, equipLoop = nil, nil

        local function startEquip()
            if equipLoop then return end
            equipLoop = task.spawn(function()
                while GR.on and alive do
                    if _FC and _FC.LocalFighter then pcall(function() _FC.LocalFighter:EquipItem(GR.slot) end) end
                    task.wait(1)
                end
                equipLoop = nil
            end)
        end

        local deflecting, deflectAt = {}, 0
        Players.PlayerRemoving:Connect(function(p) deflecting[p] = nil end)
        local function updateDeflection()
            local now = os.clock()
            if now - deflectAt < 0.1 then return end
            deflectAt = now
            if not _FC or not _FC.Objects then return end
            for _, fo in _FC.Objects do
                local pl = fo.Player
                if pl then
                    local entity = fo.Entity
                    if not entity or not entity:IsAlive() then
                        deflecting[pl] = false
                    else
                        local eq = fo.EquippedItem
                        local vm = eq and eq.ViewModel
                        local d = false
                        if vm and vm.Name == 'Katana' then
                            d = (eq._attack_cooldown and eq._attack_cooldown > tick()) or false
                        end
                        deflecting[pl] = d
                    end
                end
            end
        end

        local IMMUNE = { 'IsInvincible', 'Immune', 'IsImmune', 'SpawnProtection' }
        local function isImmune(pl)
            local ch = pl.Character
            if ch then
                if ch:FindFirstChildOfClass('ForceField') then return true end
                for _, a in ipairs(IMMUNE) do if ch:GetAttribute(a) == true then return true end end
            end
            for _, a in ipairs(IMMUNE) do if pl:GetAttribute(a) == true then return true end end
            return false
        end
        local function isEnemy(pl)
            if pl == LP then return false end
            if _SC then
                local ok, res = pcall(function()
                    local duel = _SC.CurrentDuelSubject
                    local ld = duel and duel:GetDueler(LP)
                    local lt = ld and ld:Get('TeamID')
                    if lt and duel and duel.Duelers then
                        for _, d in duel.Duelers do if d.Player == pl then return d:Get('TeamID') ~= lt end end
                    end
                    return nil
                end)
                if ok and res ~= nil then return res end
            end
            local pt, lt = pl:GetAttribute('TeamID'), LP:GetAttribute('TeamID')
            if pt and lt then return pt ~= lt end
            return true
        end
        local function inFov(hrp)
            if GR.fov >= 9999 then return true end
            local cam = workspace.CurrentCamera
            local p3, on = cam:WorldToViewportPoint(hrp.Position)
            if not on then return false end
            return (Vector2.new(p3.X, p3.Y) - UIS:GetMouseLocation()).Magnitude <= GR.fov
        end
        local function hasKnifeVM(pl)
            local vm = workspace:FindFirstChild('ViewModels')
            if not vm then return false end
            for _, m in ipairs(vm:GetChildren()) do
                if m:IsA('Model') and string.find(m.Name, pl.Name, 1, true) and string.find(m.Name, 'Knife', 1, true) then return true end
            end
            return false
        end
        local ping, pingAt = 0.06, 0
        local function leadPos(hrp)
            if not GR.extra then return hrp.Position end
            local now = os.clock()
            if now - pingAt >= 1 then pingAt = now; pcall(function() ping = math.clamp(LP:GetNetworkPing(), 0, 0.5) end) end
            local vel = Vector3.zero
            pcall(function() vel = hrp.AssemblyLinearVelocity end)
            if vel.Magnitude < 0.05 then return hrp.Position end
            local look = (ping * 1.2 + 0.016) * (1 + math.clamp(vel.Magnitude / 40, 0, 1.6) * 0.4)
            return hrp.Position + vel * math.clamp(look, 0, 0.5)
        end
        local function hitbox(ch, head, body)
            local h = ch and ch:FindFirstChild(body and 'HitboxBody' or 'HitboxHead')
            if h and h:IsA('BasePart') then return h end
            return body and (ch:FindFirstChild('HumanoidRootPart') or head) or head
        end
        local pelItem, pelCount = nil, 1
        local function pellets(item)
            if item == pelItem then return pelCount end
            pelItem, pelCount = item, 1
            pcall(function() local n = item.Info and item.Info.ShootPellets; if type(n) == 'number' then pelCount = math.max(1, math.floor(n)) end end)
            return pelCount
        end
        local cdItem, cdVal = nil, 0
        local function cooldown(item)
            if item == cdItem then return cdVal end
            cdItem, cdVal = item, 0
            pcall(function()
                local info = item.Info
                if type(info) ~= 'table' then return end
                local cd = tonumber(info.ShootCooldown) or 0
                local burst = tonumber(info.BurstCount) or 1
                local bcd = tonumber(info.BurstCooldown)
                if burst > 1 and bcd then cd = math.min(cd, bcd) end
                cdVal = math.clamp(cd, 0, 5)
            end)
            return cdVal
        end

        local dsRoot, dsCF, dsVel, dsRot, dsBound, dsShown = nil, nil, Vector3.zero, Vector3.zero, false, nil
        local function flush()
            if dsBound then dsBound = false; pcall(function() RunService:UnbindFromRenderStep('GR_DsRestore') end) end
            local root, cf = dsRoot, dsCF
            dsRoot, dsCF, dsShown = nil, nil, nil
            if root and root.Parent and cf then
                pcall(function() root.CFrame = cf; root.AssemblyLinearVelocity = dsVel; root.AssemblyAngularVelocity = dsRot end)
            end
        end
        pcall(function()
            local pre = RunService.PreSimulation
            if typeof(pre) == 'RBXScriptSignal' then pre:Connect(function() if dsBound or dsCF then flush() end end) end
        end)
        local function apply(cf)
            local ch = LP.Character
            local root = ch and ch:FindFirstChild('HumanoidRootPart')
            if not root or not root:IsA('BasePart') then return false end
            local keep = dsCF ~= nil and (dsBound or (dsShown and (root.Position - dsShown.Position).Magnitude < 0.2))
            if not keep or dsRoot ~= root then dsRoot, dsCF, dsVel, dsRot = root, root.CFrame, root.AssemblyLinearVelocity, root.AssemblyAngularVelocity end
            root.CFrame = cf
            dsShown = cf
            if not dsBound then dsBound = true; RunService:BindToRenderStep('GR_DsRestore', Enum.RenderPriority.Camera.Value - 1, flush) end
            return true
        end
        local function voidCF()
            local u, v = math.random(), math.random()
            local th, ph = math.pi * 2 * u, math.acos(math.clamp(2 * v - 1, -1, 1))
            local R = 9000
            return CFrame.lookAt(Vector3.new(R * math.sin(ph) * math.cos(th), R * math.cos(ph), R * math.sin(ph) * math.sin(th)), Vector3.zero)
        end
        local function pickTarget()
            local myChar = LP.Character
            local myHRP = myChar and myChar:FindFirstChild('HumanoidRootPart')
            if not myHRP then return end
            local bp, bh, bhd, bd = nil, nil, nil, math.huge
            for _, pl in ipairs(Players:GetPlayers()) do
                if isEnemy(pl) and not isImmune(pl) then
                    local ch = pl.Character
                    local hrp = ch and ch:FindFirstChild('HumanoidRootPart')
                    local head = ch and ch:FindFirstChild('Head')
                    local hum = ch and ch:FindFirstChildOfClass('Humanoid')
                    if hrp and head and hum and hum.Health > 0 and inFov(hrp) then
                        local d = (myHRP.Position - hrp.Position).Magnitude
                        if d < bd then bp, bh, bhd, bd = pl, hrp, head, d end
                    end
                end
            end
            return bp, bh, bhd
        end
        local function fire(pl, hrp, head)
            if not (_util and _enum and _FC and _remote) then return end
            if not _FC.LocalFighter then return end
            local item = _FC.LocalFighter.EquippedItem
            if not item then return end
            local objectId; pcall(function() objectId = item:Get('ObjectID') end)
            if not objectId then return end
            local ch = hrp and hrp.Parent; if not (ch and head) then return end
            local hum = ch:FindFirstChildOfClass('Humanoid'); if not hum or hum.Health <= 0 then return end
            if GR.knife and deflecting[pl] then return end
            local part = hitbox(ch, head, not GR.head); local aimPos = leadPos(hrp); local hitPoint = part.Position; local dcf
            if hasKnifeVM(pl) then dcf = CFrame.lookAt(hrp.Position + Vector3.new(0, -5, 0), aimPos) else
                local f = hrp.CFrame.LookVector; local flat = Vector3.new(f.X, 0, f.Z)
                if flat.Magnitude < 0.05 then flat = Vector3.new(0, 0, -1) end
                dcf = CFrame.lookAt(hrp.Position + flat.Unit + Vector3.new(0, 1, 0), aimPos)
            end
            if GR.desync then apply(dcf) end
            local eye = dcf.Position + EYE
            if (eye - aimPos).Magnitude < 0.1 then eye = aimPos + Vector3.new(0, 0.2, 0) end
            local aimCF = CFrame.lookAt(eye, aimPos); local offset = part.CFrame:ToObjectSpace(CFrame.new(hitPoint)); local eAim, eOff
            if not pcall(function() eAim = _util:EncodeCFrame(aimCF); eOff = _util:EncodeCFrame(offset) end) or not eAim then return end
            local data = { [K1] = { [K0] = eAim, [K1] = eAim, [K2] = part, [K3] = eOff } }
            if pellets(item) > 1 then data[K2] = true end
            local en; pcall(function() en = _enum:ToEnum('StartShooting') end); if not en then return end
            pcall(function() _remote:FireServer(objectId, en, data, nil) end)
        end
        local lastFire = 0
        local function start()
            if hb then hb:Disconnect(); hb = nil end
            if GR.equip then startEquip() end
            hb = RunService.Heartbeat:Connect(function()
                if not GR.on then return end
                updateDeflection()
                local remaining = lastFire + GR.rate - tick()
                if remaining > 0.002 then
                    local item = _FC and _FC.LocalFighter and _FC.LocalFighter.EquippedItem
                    local cd = item and cooldown(item) or 0
                    if GR.void and cd > 0.05 then apply(voidCF()) end
                    return
                end
                local pl, hrp, head = pickTarget()
                if not pl then return end
                lastFire = tick(); task.spawn(fire, pl, hrp, head)
            end)
        end
        local function stop() GR.on = false; if hb then hb:Disconnect(); hb = nil end; flush() end

        pcall(function()
            local sec = col1:section({ name = "Graviton Rage" })
            sec:toggle({ name = "Graviton ragebot", default = false, callback = function(v) GR.on = v; if v then start() else stop() end end })
            pcall(function() sec:keybind({ name = "Graviton Rage toggle", callback = function(active) GR.on = active; if active then start() else stop() end end }) end)
            sec:toggle({ name = "Desync origin",       default = true, callback = function(v) GR.desync = v end })
            sec:toggle({ name = "Void park (shotgun)", default = true, callback = function(v) GR.void   = v end })
            sec:toggle({ name = "Aim head",            default = true, callback = function(v) GR.head   = v end })
            sec:toggle({ name = "Extrapolation",       default = true, callback = function(v) GR.extra  = v end })
            sec:toggle({ name = "Knife deflect check", default = true, callback = function(v) GR.knife  = v end })
            sec:toggle({ name = "Auto equip slot",     default = true, callback = function(v) GR.equip = v; if v and GR.on then startEquip() end end })
            local sec2 = col1:section({ name = "Graviton Settings" })
            sec2:slider({ name = "Fire rate (ms)", min = 1, max = 500, interval = 1, default = 1, suffix = " ms", callback = function(v) GR.rate = v / 1000 end })
            sec2:slider({ name = "FOV", min = 0, max = 9999, interval = 1, default = 9999, suffix = " px", callback = function(v) GR.fov = v end })
            sec2:dropdown({ name = "Weapon", items = { "Primary", "Secondary", "Melee" }, default = "Primary", callback = function(v) GR.slot = ({ Primary = 1, Secondary = 2, Melee = 3 })[v] or 1 end })
        end)
    end, function(e) warn('[Sniflva Graviton Rage] ' .. tostring(e)) end)
end

-- END OF CHUNK 5 --
-- ============================================================
-- 2. FAKE UNDERGROUND
-- ============================================================
do
    local col2 = makeColumn(tabs[2].content)
    xpcall(function()
        local Players = game:GetService('Players')
        local RunService = game:GetService('RunService')
        local lp = Players.LocalPlayer
        local FU = { on = false, depth = 5.8, walk = true, hide = true, camera = false, orbit = false, noclip = true, panic = false, pMin = -5, pMax = 5, pZ = false, anim = true, zeroVel = true, virtualCF = nil, saved = nil, track = nil, hb = nil, alive = true, rage = false, radius = 14, speed = 4, rate = 0.1, slot = 'Primary', maxDist = 400, team = true, ang = 0, target = nil, nextPick = 0, lastShot = 0, localCF = nil, status = nil }

        local function hideChar()
            local char = lp.Character; if not char then return end; FU.saved = {}
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA('BasePart') or part:IsA('Decal') then FU.saved[#FU.saved + 1] = { part = part, t = part.Transparency }; pcall(function() part.Transparency = 1 end) end
            end
        end
        local function showChar()
            if not FU.saved then return end
            for _, d in ipairs(FU.saved) do if d.part and d.part.Parent then pcall(function() d.part.Transparency = d.t end) end end
            FU.saved = nil
        end
        local function startAnim()
            local hum = lp.Character and lp.Character:FindFirstChildOfClass('Humanoid'); if not hum or FU.track then return end
            pcall(function()
                local a = Instance.new('Animation'); a.AnimationId = 'rbxassetid://10714003221'
                local t = hum:LoadAnimation(a); t:Play(0, 1, 0); t.TimePosition = 1.48; FU.track = t
            end)
        end
        local function stopAnim() if FU.track then pcall(function() FU.track:Stop(); FU.track:Destroy() end); FU.track = nil end end

        local RS_ = game:GetService('ReplicatedStorage'); local mods, modErr = nil, nil
        local function getMods()
            if mods then return mods end
            local ok, res = pcall(function() return { util = require(RS_.Modules.Utility), enumLib = require(RS_.Modules.EnumLibrary), FC = require(lp.PlayerScripts.Controllers.FighterController) } end)
            if ok then mods = res; modErr = nil else modErr = tostring(res) end
            return mods
        end
        local SLOT_IDX = { Primary = 1, Secondary = 2, Melee = 3 }
        local function validTarget(plr, myPos)
            if plr == lp then return nil end
            if FU.team and plr.Team ~= nil and plr.Team == lp.Team then return nil end
            local ch = plr.Character; local root = ch and ch:FindFirstChild('HumanoidRootPart'); local head = ch and ch:FindFirstChild('Head'); local hum = ch and ch:FindFirstChildOfClass('Humanoid')
            if not (root and head and hum) or hum.Health <= 0 then return nil end
            if root.Position.Y < -500 or root.Position.Y > 2000 then return nil end
            local d = (root.Position - myPos).Magnitude; if d > FU.maxDist then return nil end
            return root, head, d
        end
        local function pickTarget(myPos)
            local cur = FU.target
            if cur and cur.plr and cur.plr.Parent then local root, head = validTarget(cur.plr, myPos); if root then cur.root, cur.head = root, head; return cur end end
            local best, bestD = nil, math.huge
            for _, plr in ipairs(Players:GetPlayers()) do local root, head, d = validTarget(plr, myPos); if root and d < bestD then bestD = d; best = { plr = plr, root = root, head = head } end end
            FU.target = best; return best
        end
        local function shootAt(head, fromPos)
            local m = getMods(); if not m then return false end; local lf = m.FC.LocalFighter; if not lf then return false end
            if lf.EquippedItem == nil then pcall(function() lf:EquipItem(SLOT_IDX[FU.slot] or 1) end); return false end
            local hp = head.Position; local aimCF = CFrame.lookAt(fromPos + Vector3.new(0, 1.5, 0), hp); local objSpace = head.CFrame:ToObjectSpace(CFrame.new(hp)); local data = {}
            data[utf8.char(1)] = { [utf8.char(0)] = m.util:EncodeCFrame(aimCF), [utf8.char(1)] = m.util:EncodeCFrame(head.CFrame), [utf8.char(2)] = head, [utf8.char(3)] = m.util:EncodeCFrame(objSpace) }
            return pcall(function() RS_.Remotes.Replication.Fighter.UseItem:FireServer(lf.EquippedItem:Get('ObjectID'), m.enumLib:ToEnum('StartShooting'), data, nil) end)
        end

        local function turnOff()
            FU.on = false; FU.localCF = nil; FU.target = nil
            pcall(function() RunService:UnbindFromRenderStep('FU_OrbitUndo') end)
            if FU.hb then FU.hb:Disconnect(); FU.hb = nil end
            pcall(function() RunService:UnbindFromRenderStep('FU_SurfaceCamera') end)
            showChar(); stopAnim()
            local hrp = lp.Character and lp.Character:FindFirstChild('HumanoidRootPart')
            if hrp and FU.virtualCF then pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero; hrp.CFrame = FU.virtualCF end) end
            FU.virtualCF = nil
        end

        local function turnOn()
            FU.on = true; local hrp = lp.Character and lp.Character:FindFirstChild('HumanoidRootPart'); if hrp then FU.virtualCF = hrp.CFrame end
            if FU.hide then hideChar() end; if FU.anim then startAnim() end
            pcall(function() RunService:UnbindFromRenderStep('FU_SurfaceCamera') end)
            RunService:BindToRenderStep('FU_SurfaceCamera', 201, function()
                if FU.on and FU.camera then local cam = workspace.CurrentCamera; if cam and FU.depth > 0 then cam.CFrame = cam.CFrame + Vector3.new(0, FU.depth, 0) end end
            end)
            pcall(function() RunService:UnbindFromRenderStep('FU_OrbitUndo') end)
            RunService:BindToRenderStep('FU_OrbitUndo', Enum.RenderPriority.Camera.Value - 1, function()
                if FU.on and FU.localCF then local h = lp.Character and lp.Character:FindFirstChild('HumanoidRootPart'); if h then h.CFrame = FU.localCF end end
            end)
            FU.hb = RunService.Heartbeat:Connect(function(dt)
                if not FU.on then return end
                local char = lp.Character; local hrp2 = char and char:FindFirstChild('HumanoidRootPart'); local hum = char and char:FindFirstChildOfClass('Humanoid'); if not hrp2 or not hum then return end
                local cam = workspace.CurrentCamera; local look = cam and cam.CFrame.LookVector or Vector3.new(0, 0, -1); local rot = CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0)
                if not FU.virtualCF then FU.virtualCF = CFrame.new(hrp2.Position) * rot end
                local pos = FU.virtualCF.Position
                if FU.walk and hum.MoveDirection.Magnitude > 0 then pos = pos + hum.MoveDirection * (hum.WalkSpeed * dt) end
                FU.virtualCF = CFrame.new(pos) * rot; local under = pos - Vector3.new(0, FU.depth, 0)
                if FU.panic then local lo, hi = math.min(FU.pMin, FU.pMax), math.max(FU.pMin, FU.pMax); under = under + Vector3.new(lo + math.random() * (hi - lo), 0, FU.pZ and (math.random() - 0.5) * (hi - lo) or 0) end
                if FU.noclip then for _, p in ipairs(char:GetDescendants()) do if p:IsA('BasePart') and p.CanCollide then p.CanCollide = false end end end
                if FU.zeroVel then hrp2.AssemblyLinearVelocity  = Vector3.zero; hrp2.AssemblyAngularVelocity = Vector3.zero end
                local localCF = CFrame.new(under) * rot; FU.localCF = nil
                if FU.rage then
                    local tgt = pickTarget(pos)
                    if tgt and not FU.orbit then hrp2.CFrame = localCF; if tick() - FU.lastShot >= FU.rate then FU.lastShot = tick(); shootAt(tgt.head, localCF.Position) end
                    elseif tgt then
                        FU.ang = (FU.ang + FU.speed * dt) % (math.pi * 2); local tp = tgt.root.Position
                        local orbit = Vector3.new(tp.X + math.cos(FU.ang) * FU.radius, tp.Y - FU.depth, tp.Z + math.sin(FU.ang) * FU.radius)
                        local yaw = CFrame.new(orbit) * CFrame.Angles(0, math.atan2(-(tp.X - orbit.X), -(tp.Z - orbit.Z)), 0)
                        FU.localCF = localCF; hrp2.CFrame = yaw; if tick() - FU.lastShot >= FU.rate then FU.lastShot = tick(); shootAt(tgt.head, orbit) end
                    else hrp2.CFrame = localCF end
                else hrp2.CFrame = localCF end
                if FU.hide and FU.saved then for _, d in ipairs(FU.saved) do if d.part and d.part.Parent and d.part.Transparency ~= 1 then pcall(function() d.part.Transparency = 1 end) end end end
            end)
        end

        pcall(function()
            local sec = col2:section({ name = "Fake Underground" })
            sec:toggle({ name = "Fake Underground", default = false, callback = function(v) if v then turnOn() else turnOff() end end })
            sec:slider({ name = "Depth", min = 0, max = 150, interval = 1, default = 6, suffix = " studs", callback = function(v) FU.depth = v end })
            sec:toggle({ name = "Walk mode", default = true, callback = function(v) FU.walk = v end })
            sec:toggle({ name = "Surface camera", default = false, callback = function(v) FU.camera = v end })
            sec:toggle({ name = "Auto noclip", default = true, callback = function(v) FU.noclip = v end })
            sec:toggle({ name = "Hide my character", default = true, callback = function(v) FU.hide = v; if FU.on then if v then hideChar() else showChar() end end end })
            sec:toggle({ name = "Animation desync", default = true, callback = function(v) FU.anim = v; if FU.on then if v then startAnim() else stopAnim() end end end })
            sec:toggle({ name = "Panic jitter", default = false, callback = function(v) FU.panic = v end })
            sec:slider({ name = "Jitter min X", min = -50, max = 0, interval = 1, default = -5, callback = function(v) FU.pMin = v end })
            sec:slider({ name = "Jitter max X", min = 0, max = 50, interval = 1, default = 5, callback = function(v) FU.pMax = v end })
            sec:toggle({ name = "Jitter Z too", default = false, callback = function(v) FU.pZ = v end })
        end)

        pcall(function()
            local sec2 = col2:section({ name = "Underground Ragebot" })
            sec2:toggle({ name = "Underground ragebot", default = false, callback = function(v) FU.rage = v; FU.target = nil; if v then if not getMods() then warn("[Underground Ragebot] Modules not available: " .. tostring(modErr)) end; if not FU.on then turnOn() end end end })
            sec2:toggle({ name = "Orbit the target", default = false, callback = function(v) FU.orbit = v end })
            sec2:slider({ name = "Orbit radius", min = 3, max = 60, interval = 1, default = 14, suffix = " studs", callback = function(v) FU.radius = v end })
            sec2:slider({ name = "Orbit speed", min = 1, max = 20, interval = 1, default = 4, suffix = " rad/s", callback = function(v) FU.speed = v end })
            sec2:slider({ name = "Shoot delay", min = 0.01, max = 1, interval = 0.01, default = 0.1, suffix = "s", callback = function(v) FU.rate = v end })
            sec2:slider({ name = "Max target distance", min = 50, max = 2000, interval = 1, default = 400, suffix = " studs", callback = function(v) FU.maxDist = v end })
            sec2:dropdown({ name = "Weapon", items = { "Primary", "Secondary" }, default = "Primary", callback = function(v) FU.slot = v end })
            sec2:toggle({ name = "Skip teammates", default = true, callback = function(v) FU.team = v end })
        end)
        lp.CharacterAdded:Connect(function() if FU.on then task.wait(1); turnOff(); turnOn() end end)
    end, function(e) warn('[Sniflva Fake Underground] ' .. tostring(e)) end)
end

-- END OF CHUNK 6 --
-- ============================================================
-- RIVALS RAGEBOT ENHANCEMENT (from Elisium, minus anti-aim/void)
-- Silent Aim · Reposition · Dodge · Always Backstab · Perfect Block
-- · Advanced Anti-Knife · Ragebot Engine
-- ============================================================
do
    local colRivals = makeColumn(tabs[3].content)
    xpcall(function()
        local RS2 = game:GetService("ReplicatedStorage")
        local LP2 = Players.LocalPlayer

        -- ===== module loader =====
        local Utility, EnumLib, ItemLibrary, FighterController, ClientViewModel
        local function tryLoad()
            pcall(function()
                local mf = RS2:FindFirstChild("Modules")
                if mf then
                    local u  = mf:FindFirstChild("Utility")
                    local e  = mf:FindFirstChild("EnumLibrary")
                    local il = mf:FindFirstChild("ItemLibrary")
                    if u and not Utility  then Utility  = require(u)  end
                    if e and not EnumLib  then EnumLib  = require(e)  end
                    if il and not ItemLibrary then ItemLibrary = require(il) end
                end
                if not FighterController and LP2.PlayerScripts then
                    local c = LP2.PlayerScripts:FindFirstChild("Controllers")
                    if c and c:FindFirstChild("FighterController") then
                        FighterController = require(c.FighterController)
                    end
                end
                if not ClientViewModel and LP2.PlayerScripts then
                    local m = LP2.PlayerScripts:FindFirstChild("Modules")
                    if m then
                        local crc = m:FindFirstChild("ClientReplicatedClasses")
                        local cf  = crc and crc:FindFirstChild("ClientFighter")
                        local ci  = cf and cf:FindFirstChild("ClientItem")
                        local cv  = ci and ci:FindFirstChild("ClientViewModel")
                        if cv then ClientViewModel = require(cv) end
                    end
                end
            end)
        end
        for _ = 1, 80 do
            tryLoad()
            if Utility and EnumLib and FighterController then break end
            task.wait(0.25)
        end
        if not (Utility and EnumLib and FighterController) then
            warn("[RivalsRage] Modules not available — features will no-op")
            return
        end

        -- ===== locate UseItem remote =====
        local UseItemRemote = nil
        pcall(function()
            local rep = RS2:FindFirstChild("Remotes")
            rep = rep and rep:FindFirstChild("Replication")
            rep = rep and rep:FindFirstChild("Fighter")
            UseItemRemote = rep and rep:FindFirstChild("UseItem")
        end)
        if not UseItemRemote then
            pcall(function()
                UseItemRemote = RS2:FindFirstChild("UseItem", true)
            end)
        end
        local SetControlsRemote = nil
        pcall(function()
            local rep = RS2:FindFirstChild("Remotes")
            rep = rep and rep:FindFirstChild("Replication")
            rep = rep and rep:FindFirstChild("Fighter")
            SetControlsRemote = rep and rep:FindFirstChild("SetControls")
        end)
        local UpdateCameraRotation = nil
        pcall(function()
            local rep = RS2:FindFirstChild("Remotes")
            rep = rep and rep:FindFirstChild("Replication")
            rep = rep and rep:FindFirstChild("Fighter")
            UpdateCameraRotation = rep and rep:FindFirstChild("UpdateCameraRotation")
        end)

        -- ===== state =====
        local RS = {
            silent = {
                enabled=false, fov=180, part="Head", closest=false,
                team=true, wall=false, shield=false, katana=false,
                chance=100, showFov=false, followGunpoint=false,
                cachedTarget=nil, cachedTargetAt=0,
            },
            reposition = { enabled=false, offset=-5, anti=true, originalCF=nil, applied=false },
            dodge = { enabled=false, method="lay down", rangeBuffer=3, duration=0.85,
                      height=20, activeUntil=0, savedCF=nil },
            backstab = { enabled=false },
            block = { enabled=false, savedAutoRotate=nil, appliedHumanoid=nil },
            antiKnife = { enabled=false, range=14, retreat=18, onlyMelee=true, cool=0 },
            rage = {
                enabled=false, strategy="Orbit", attackMode="Gun",
                priority="primary", hitboxPart="Head",
                safeMethod="random pos", position="Inside",
                radius=5, height=-4, orbitSpeed=500, knifeDist=3,
                prediction=false, predMult=1.2, swapOnEmpty=false, autoCrouch=false,
                lastShot=0, target=nil, clientCF=nil, fakePart=nil,
                reloading=false, wasReloading=false, angle=0, cool=0,
            },
        }

        -- ===== shared helpers =====
        local function getMyHRP()
            local c = LP2.Character
            return c and c:FindFirstChild("HumanoidRootPart"), c
        end
        local function isEnemy(plr)
            if plr == LP2 then return false end
            if plr.Team and LP2.Team and plr.Team == LP2.Team then return false end
            local env = LP2:GetAttribute("EnvironmentID")
            local pEnv = plr:GetAttribute("EnvironmentID")
            if env and pEnv and env ~= pEnv then return false end
            return true
        end
        local function isAlive(plr)
            local c = plr.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            return h and h.Health > 0
        end
        local function isImmune(plr)
            local c = plr.Character
            if not c then return false end
            if c:FindFirstChildOfClass("ForceField") then return true end
            for _, a in ipairs({"IsInvincible", "Immune", "IsImmune", "SpawnProtection"}) do
                if c:GetAttribute(a) == true or plr:GetAttribute(a) == true then return true end
            end
            return false
        end
        local function getEquippedName(plr)
            local ok, r = pcall(function()
                local mod = FighterController
                local tbl = mod._player_to_fighter
                local f = tbl and tbl[plr]
                return f and f.EquippedItem and f.EquippedItem.Name
            end)
            return ok and r or nil
        end
        local knifeNames = { "knife","katana","sword","axe","scythe","chainsaw","dagger","hammer","bat","spear","blade","fists" }
        local function isMeleeName(n)
            n = tostring(n or ""):lower()
            for _, k in ipairs(knifeNames) do if n:find(k,1,true) then return true end end
            return false
        end
        local function hasShield(plr)
            local vm = workspace:FindFirstChild("ViewModels")
            if not vm then return false end
            return vm:FindFirstChild(plr.Name.." - Riot Shield - Riot Shield") ~= nil
        end
        local function hasWallBetween(fromPos, toPart)
            local ignore = { LP2.Character, toPart.Parent }
            local hit = workspace:FindPartOnRayWithIgnoreList(
                Ray.new(fromPos, toPart.Position - fromPos), ignore)
            return hit ~= nil
        end
        local function passesChecks(plr, checks, part)
            if checks.katana and getEquippedName(plr) == "Katana" then return false end
            if checks.shield and hasShield(plr) then return false end
            if checks.wall and cam then
                if hasWallBetween(cam.CFrame.Position, part) then return false end
            end
            return true
        end
        local function partOf(char, name)
            return char:FindFirstChild(name) or char:FindFirstChild("HumanoidRootPart")
        end

        -- ===== target picking =====
        local function pickTarget(cfg, requireAlive)
            if not cam then return nil end
            local mouse = UIS:GetMouseLocation()
            local centre = cfg.followGunpoint and Vector2.new(mouse.X, mouse.Y)
                or cam.ViewportSize * 0.5
            local best, bestDist = nil, cfg.fov
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP2 and isEnemy(plr) and isAlive(plr) then
                    if not (requireAlive and isImmune(plr)) then
                        local char = plr.Character
                        local part = partOf(char, cfg.part)
                        if part and passesChecks(plr, cfg, part) then
                            local sp, on = cam:WorldToViewportPoint(part.Position)
                            if on then
                                local d = (Vector2.new(sp.X, sp.Y) - centre).Magnitude
                                if d < bestDist then
                                    bestDist = d
                                    best = { player=plr, part=part, char=char, hum=char:FindFirstChildOfClass("Humanoid"), screen=Vector2.new(sp.X,sp.Y) }
                                end
                            end
                        end
                    end
                end
            end
            if best and cfg.closest then
                local bPart, bDist = nil, math.huge
                for _, p in ipairs(best.char:GetChildren()) do
                    if p:IsA("BasePart") then
                        local sp, on = cam:WorldToViewportPoint(p.Position)
                        if on then
                            local d = (Vector2.new(sp.X,sp.Y) - centre).Magnitude
                            if d < bDist then bDist, bPart = d, p end
                        end
                    end
                end
                if bPart then best.part = bPart end
            end
            return best
        end

        -- ===== desync =====
        local function setFakeCF(fakeCF)
            local root = getMyHRP()
            if not root then return end
            if not RS.rage.clientCF then RS.rage.clientCF = root.CFrame end
            pcall(function()
                if sethiddenproperty and getthreadidentity then
                    local old = getthreadidentity()
                    setthreadidentity(8)
                    sethiddenproperty(root, "PhysicsRepRootPart", nil)
                    setthreadidentity(old)
                end
            end)
            root.CFrame = fakeCF
        end
        local function restoreClientCF()
            local root = getMyHRP()
            if root and RS.rage.clientCF then root.CFrame = RS.rage.clientCF end
        end
        local function clearDesync()
            RS.rage.clientCF = nil
            pcall(function()
                if sethiddenproperty and getthreadidentity then
                    local root = getMyHRP()
                    if root then
                        local old = getthreadidentity()
                        setthreadidentity(8)
                        sethiddenproperty(root, "PhysicsRepRootPart", nil)
                        setthreadidentity(old)
                    end
                end
            end)
        end

        -- ===== silent aim =====
        local function fireSilentPayload(plr, part, originCF)
            if not UseItemRemote then return end
            local lf = FighterController.LocalFighter
            if not lf or not lf.EquippedItem then return end
            local item = lf.EquippedItem
            local objectId
            pcall(function() objectId = item:Get("ObjectID") end)
            if not objectId then return end
            local aimCF = CFrame.lookAt(originCF.Position, part.Position)
            local offset = part.CFrame:ToObjectSpace(CFrame.new(part.Position))
            local eAim, ePart, eOff
            if not pcall(function()
                eAim  = Utility:EncodeCFrame(aimCF)
                ePart = Utility:EncodeCFrame(part.CFrame)
                eOff  = Utility:EncodeCFrame(offset)
            end) then return end
            local en
            pcall(function() en = EnumLib:ToEnum("StartShooting") end)
            if not en then return end
            if math.random(1,100) > RS.silent.chance then return end
            local data = {}
            data[utf8.char(1)] = {
                [utf8.char(0)] = eAim,
                [utf8.char(1)] = ePart,
                [utf8.char(2)] = part,
                [utf8.char(3)] = eOff,
            }
            pcall(function() UseItemRemote:FireServer(objectId, en, data, nil) end)
        end
        RunSvc.RenderStepped:Connect(function()
            if not RS.silent.enabled then RS.silent.cachedTarget = nil; return end
            local t = pickTarget(RS.silent)
            if t then
                RS.silent.cachedTarget = t
                RS.silent.cachedTargetAt = tick()
            elseif tick() - RS.silent.cachedTargetAt > 0.3 then
                RS.silent.cachedTarget = nil
            end
        end)

        -- patch Gun.StartShooting so the trigger shot gets redirected
        local GunMod
        pcall(function() GunMod = require(LP2.PlayerScripts.Modules.ItemTypes.Gun) end)
        local origGunStart
        if GunMod and GunMod.StartShooting then
            origGunStart = GunMod.StartShooting
            GunMod.StartShooting = function(self, ...)
                local ret = origGunStart(self, ...)
                if RS.silent.enabled and self.ClientFighter and self.ClientFighter.IsLocalPlayer then
                    local t = RS.silent.cachedTarget
                    if t and t.part and t.part.Parent then
                        pcall(function()
                            if self.ClientFighter and self.ClientFighter.Entity and self.ClientFighter.Entity.RootPart then
                                local origin = cam.CFrame
                                fireSilentPayload(t.player, t.part, origin)
                            end
                        end)
                    end
                end
                return ret
            end
        end

        -- FOV circle for silent
        RunSvc.RenderStepped:Connect(function()
            if RS.silent.showFov and RS.silent.enabled then
                fovFrameSilent.Visible = true
                fovFrameSilent.Size = UDim2.fromOffset(RS.silent.fov * 2, RS.silent.fov * 2)
            else
                fovFrameSilent.Visible = false
            end
        end)

        -- ===== reposition =====
        RunSvc.Heartbeat:Connect(function()
            if not RS.reposition.enabled then
                if RS.reposition.applied and RS.reposition.originalCF then
                    local root = getMyHRP()
                    if root then pcall(function() root.CFrame = RS.reposition.originalCF end) end
                end
                RS.reposition.applied = false
                RS.reposition.originalCF = nil
                return
            end
            local root = getMyHRP()
            if not root then return end
            if not RS.reposition.originalCF then RS.reposition.originalCF = root.CFrame end
            pcall(function() root.CFrame = root.CFrame + Vector3.new(0, RS.reposition.offset, 0) end)
            RS.reposition.applied = true
        end)

        -- ===== dodge =====
        RunSvc.Heartbeat:Connect(function()
            if not RS.dodge.enabled then
                if RS.dodge.savedCF then
                    local root = getMyHRP()
                    if root then pcall(function() root.CFrame = RS.dodge.savedCF end) end
                end
                RS.dodge.savedCF = nil
                return
            end
            local root, ch = getMyHRP()
            if not root or not ch then return end
            local threat, td = nil, RS.antiKnife.range
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP2 and isEnemy(plr) and isAlive(plr) then
                    local t = plr.Character:FindFirstChild("HumanoidRootPart")
                    if t then
                        local d = (t.Position - root.Position).Magnitude
                        if d < td then threat, td = t, d end
                    end
                end
            end
            local now = tick()
            if threat then
                if not RS.dodge.savedCF then RS.dodge.savedCF = root.CFrame end
                local dest
                if RS.dodge.method == "up" then
                    dest = root.Position + Vector3.new(0, RS.dodge.height, 0)
                elseif RS.dodge.method == "random pos" then
                    local r = RS.dodge.rangeBuffer
                    dest = root.Position + Vector3.new(math.random(-r,r), 0, math.random(-r,r))
                else
                    local dir = root.Position - threat.Position
                    dir = Vector3.new(dir.X, 0, dir.Z)
                    if dir.Magnitude < 0.1 then dir = Vector3.new(1, 0, 0) end
                    dest = root.Position + dir.Unit * (RS.dodge.rangeBuffer + 3)
                end
                pcall(function() root.CFrame = CFrame.new(dest) end)
                RS.dodge.activeUntil = now + RS.dodge.duration
            elseif RS.dodge.savedCF and now >= RS.dodge.activeUntil then
                RS.dodge.savedCF = nil
            end
        end)

        -- ===== always backstab =====
        RunSvc.RenderStepped:Connect(function()
            if not RS.backstab.enabled then return end
            if not UpdateCameraRotation then return end
            local root = getMyHRP()
            if not root then return end
            local closest, cd = nil, math.huge
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP2 and isAlive(plr) then
                    local t = plr.Character:FindFirstChild("HumanoidRootPart")
                    if t then
                        local d = (t.Position - root.Position).Magnitude
                        if d < cd then closest, cd = t, d end
                    end
                end
            end
            if closest then
                pcall(function()
                    local yaw = math.atan2(closest.CFrame.LookVector.X, closest.CFrame.LookVector.Z) + math.pi
                    local enc = Utility:EncodeCameraRotation(Vector2.new(0, yaw))
                    UpdateCameraRotation:FireServer(enc, nil)
                end)
            end
        end)

        -- ===== perfect block =====
        RunSvc.RenderStepped:Connect(function()
            if not RS.block.enabled then
                if RS.block.appliedHumanoid then
                    pcall(function() RS.block.appliedHumanoid.AutoRotate = RS.block.savedAutoRotate end)
                end
                RS.block.appliedHumanoid = nil
                RS.block.savedAutoRotate = nil
                return
            end
            local root, ch = getMyHRP()
            if not root or not ch then return end
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            if RS.block.appliedHumanoid ~= hum then
                if RS.block.appliedHumanoid then
                    pcall(function() RS.block.appliedHumanoid.AutoRotate = RS.block.savedAutoRotate end)
                end
                RS.block.appliedHumanoid = hum
                RS.block.savedAutoRotate = hum.AutoRotate
            end
            hum.AutoRotate = false
            local closest, cd = nil, math.huge
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP2 and isAlive(plr) then
                    local t = plr.Character:FindFirstChild("HumanoidRootPart")
                    if t then
                        local d = (t.Position - root.Position).Magnitude
                        if d < cd then closest, cd = t, d end
                    end
                end
            end
            if closest then
                local dir = closest.Position - root.Position
                dir = Vector3.new(dir.X, 0, dir.Z)
                if dir.Magnitude > 0.1 then
                    pcall(function() root.CFrame = CFrame.lookAt(root.Position, root.Position - dir.Unit) end)
                end
            end
        end)

        -- ===== advanced anti-knife =====
        local function retreatFrom(threat)
            local root, ch = getMyHRP()
            if not root then return false end
            local away = root.Position - threat.Position
            away = Vector3.new(away.X, 0, away.Z)
            if away.Magnitude < 0.1 then away = Vector3.new(1,0,0) end
            away = away.Unit
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            rp.FilterDescendantsInstances = { ch }
            for _, m in ipairs({ 1, 0.7, 0.45 }) do
                local dist = RS.antiKnife.retreat * m
                if not workspace:Raycast(root.Position, away * dist, rp) then
                    local dest = root.Position + away * dist
                    local g = workspace:Raycast(dest + Vector3.new(0,5,0), Vector3.new(0,-80,0), rp)
                    if g then
                        pcall(function()
                            root.CFrame = CFrame.new(g.Position + Vector3.new(0,3,0)) * root.CFrame.Rotation
                            root.AssemblyLinearVelocity = Vector3.zero
                        end)
                        return true
                    end
                end
            end
            return false
        end
        RunSvc.Heartbeat:Connect(function()
            if not RS.antiKnife.enabled then return end
            if tick() < RS.antiKnife.cool then return end
            local root = getMyHRP()
            if not root then return end
            local closest, cd = nil, RS.antiKnife.range
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP2 and isEnemy(plr) and isAlive(plr) then
                    local t = plr.Character:FindFirstChild("HumanoidRootPart")
                    if t then
                        local d = (t.Position - root.Position).Magnitude
                        if d <= cd then
                            local ok = true
                            if RS.antiKnife.onlyMelee then
                                ok = isMeleeName(getEquippedName(plr))
                            end
                            if ok then closest, cd = t, d end
                        end
                    end
                end
            end
            if closest and retreatFrom(closest) then
                RS.antiKnife.cool = tick() + 0.35
            end
        end)

        -- ===== ragebot engine =====
        local function pickRageTarget()
            local root = getMyHRP()
            if not root then return nil end
            local best, bestD = nil, math.huge
            local priorityName = nil
            if RS.rage.priority and RS.rage.priority ~= "" then
                priorityName = Players:FindFirstChild(RS.rage.priority)
            end
            if priorityName and isEnemy(priorityName) and isAlive(priorityName) and not isImmune(priorityName) then
                best = priorityName
            else
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LP2 and isEnemy(plr) and isAlive(plr) and not isImmune(plr) then
                        local t = plr.Character:FindFirstChild("HumanoidRootPart")
                        if t then
                            local d = (t.Position - root.Position).Magnitude
                            if d < bestD then bestD, best = d, plr end
                        end
                    end
                end
            end
            return best
        end
        local function getHitboxPart(char, name)
            local p = char:FindFirstChild(name)
            if p and p:IsA("BasePart") then return p end
            return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        end
        local function targetVelocity(plr)
            local c = plr.Character
            local h = c and c:FindFirstChild("HumanoidRootPart")
            return h and h.AssemblyLinearVelocity or Vector3.zero
        end
        local function safeCFAround(tRoot)
            local basePos = tRoot.Position
            local offset
            local strat = RS.rage.strategy
            if strat == "Orbit" then
                RS.rage.angle = (RS.rage.angle + tick() * (RS.rage.orbitSpeed or 500) / 100) % (math.pi * 2)
                offset = Vector3.new(math.cos(RS.rage.angle), 0, math.sin(RS.rage.angle)) * math.max(RS.rage.radius or 5, 1)
                offset = offset + Vector3.new(0, RS.rage.height or -4, 0)
            else
                local posMode = string.lower(RS.rage.position or "inside")
                local look = tRoot.CFrame.LookVector
                local posDist = RS.rage.radius or 2
                if posMode == "front" then offset = look * posDist
                elseif posMode == "behind" then offset = -look * posDist
                elseif posMode == "above" then offset = Vector3.new(0, math.abs(RS.rage.height or 15) + 5, 0)
                elseif posMode == "below" then offset = Vector3.new(0, -(math.abs(RS.rage.height or 4) + 2), 0)
                else offset = Vector3.new(0, RS.rage.height or -4, 0) end
                if RS.rage.attackMode == "Knife" then offset = -look * (RS.rage.knifeDist or 3) end
            end
            local dest = basePos + offset
            if RS.rage.prediction then
                dest = dest + targetVelocity(RS.rage.target) * (RS.rage.predMult or 1.2) * 0.15
            end
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            rp.FilterDescendantsInstances = { LP2.Character }
            local hit = workspace:Raycast(dest + Vector3.new(0,80,0), Vector3.new(0,-200,0), rp)
            if hit then dest = Vector3.new(dest.X, hit.Position.Y + 3, dest.Z) end
            return CFrame.new(dest)
        end
        local function getItemBySlot(lf, slot)
            for _, item in pairs(lf.Items) do
                if item then
                    local ok, idx = pcall(function() return item:Get("ItemIndex") end)
                    if ok and idx == slot then return item end
                end
            end
            return nil
        end
        local function getAmmo(item)
            if not item then return 0, 0 end
            local ok1, a = pcall(function() return item:Get("Ammo") end)
            local ok2, r = pcall(function() return item:Get("AmmoReserve") end)
            return (ok1 and a or 0), (ok2 and r or 0)
        end
        local function reloadIfNeeded(lf, item)
            local vm = item and item.ViewModel
            if not vm then return end
            local playing = false
            for _, anim in ipairs({"EmptyReload","EmptyReloadStart","EmptyReloadSegment","EmptyReloadFinish","Reload"}) do
                local ok, p = pcall(function() return vm:IsAnimationPlaying(anim) end)
                if ok and p then playing = true; break end
            end
            if playing then RS.rage.reloading = true; return true end
            RS.rage.reloading = false
            return false
        end
        local function fireRageShot(targetPart, originCF)
            if not UseItemRemote then return end
            local lf = FighterController.LocalFighter
            if not lf or not lf.EquippedItem then return end
            local item = lf.EquippedItem
            local objectId
            pcall(function() objectId = item:Get("ObjectID") end)
            if not objectId then return end
            local aimCF = CFrame.lookAt(originCF.Position + Vector3.new(0,1.5,0), targetPart.Position)
            local offset = targetPart.CFrame:ToObjectSpace(CFrame.new(targetPart.Position))
            local eAim, ePart, eOff
            if not pcall(function()
                eAim  = Utility:EncodeCFrame(aimCF)
                ePart = Utility:EncodeCFrame(targetPart.CFrame)
                eOff  = Utility:EncodeCFrame(offset)
            end) then return end
            local en
            pcall(function() en = EnumLib:ToEnum("StartShooting") end)
            if not en then return end
            local data = {}
            data[utf8.char(1)] = {
                [utf8.char(0)] = eAim,
                [utf8.char(1)] = ePart,
                [utf8.char(2)] = targetPart,
                [utf8.char(3)] = eOff,
            }
            pcall(function() UseItemRemote:FireServer(objectId, en, data, nil) end)
        end
        RunSvc.Heartbeat:Connect(function(dt)
            if not RS.rage.enabled then
                if RS.rage.clientCF then clearDesync() end
                RS.rage.target = nil
                return
            end
            local lf = FighterController.LocalFighter
            if not lf then return end
            local target = pickRageTarget()
            RS.rage.target = target
            if not target then return end
            local tChar = target.Character
            local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
            local tPart = tChar and getHitboxPart(tChar, RS.rage.hitboxPart)
            if not tRoot or not tPart then return end
            local hum = LP2.Character and LP2.Character:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end) end
            -- weapon slot
            local mode = RS.rage.attackMode or "Gun"
            local desiredSlot
            if mode == "Melee" then desiredSlot = 3
            else desiredSlot = RS.rage.priority == "secondary" and 2 or 1 end
            local curItem = lf.EquippedItem
            local curIdx = nil
            if curItem then pcall(function() curIdx = curItem:Get("ItemIndex") end) end
            if curIdx ~= desiredSlot then
                pcall(function() lf:EquipItem(desiredSlot) end)
                return
            end
            -- reload
            if mode == "Gun" then
                if reloadIfNeeded(lf, curItem) then
                    return
                end
                local ammo, reserve = getAmmo(curItem)
                if ammo <= 0 then
                    if reserve > 0 then
                        pcall(function() curItem:Input("StartReloading") end)
                    elseif RS.rage.swapOnEmpty then
                        local other = getItemBySlot(lf, desiredSlot == 1 and 2 or 1)
                        if other then pcall(function() lf:EquipItem(other:Get("ItemIndex")) end) end
                    end
                    return
                end
            end
            -- compute safe pos + desync
            local safeCF = safeCFAround(tRoot)
            setFakeCF(safeCF)
            if tick() - RS.rage.lastShot > 0.01 then
                RS.rage.lastShot = tick()
                fireRageShot(tPart, safeCF)
            end
        end)
        RunSvc.RenderStepped:Connect(function()
            if RS.rage.enabled and RS.rage.clientCF then restoreClientCF() end
        end)

        -- ============ UI ============
        local silentSec = colRivals:section({ name = "Silent Aim" })
        silentSec:toggle({ name = "Enable Silent Aim", default = false, callback = function(v) RS.silent.enabled = v end })
        silentSec:slider({ name = "FOV", min = 10, max = 500, interval = 1, default = 180, callback = function(v) RS.silent.fov = v end })
        silentSec:slider({ name = "Hit Chance %", min = 1, max = 100, interval = 1, default = 100, callback = function(v) RS.silent.chance = v end })
        silentSec:toggle({ name = "Closest Part", default = false, callback = function(v) RS.silent.closest = v end })
        silentSec:toggle({ name = "Follow Gunpoint", default = false, callback = function(v) RS.silent.followGunpoint = v end })
        silentSec:toggle({ name = "Team Check", default = true, callback = function(v) RS.silent.team = v end })
        silentSec:toggle({ name = "Wall Check", default = false, callback = function(v) RS.silent.wall = v end })
        silentSec:toggle({ name = "Shield Check", default = false, callback = function(v) RS.silent.shield = v end })
        silentSec:toggle({ name = "Katana Check", default = false, callback = function(v) RS.silent.katana = v end })
        silentSec:toggle({ name = "Show FOV", default = false, callback = function(v) RS.silent.showFov = v end })
        silentSec:dropdown({ name = "Target Part",
            items = {"Head","HumanoidRootPart","UpperTorso","LowerTorso","HitboxHead","HitboxBody"},
            default = "Head", callback = function(v) RS.silent.part = v end })

        local rageSec = colRivals:section({ name = "Ragebot" })
        rageSec:toggle({ name = "Enable Ragebot", default = false, callback = function(v) RS.rage.enabled = v end })
        rageSec:dropdown({ name = "Strategy", items = {"Orbit", "TP"}, default = "Orbit", callback = function(v) RS.rage.strategy = v end })
        rageSec:dropdown({ name = "Attack Mode", items = {"Gun", "Melee", "Knife"}, default = "Gun", callback = function(v) RS.rage.attackMode = v end })
        rageSec:dropdown({ name = "Weapon", items = {"None","Primary","Secondary"}, default = "Primary", callback = function(v) RS.rage.priority = (v == "None") and "" or string.lower(v) end })
        rageSec:dropdown({ name = "Target Part",
            items = {"Head","UpperTorso","HumanoidRootPart","LowerTorso","RightUpperArm","LeftUpperArm"},
            default = "Head", callback = function(v) RS.rage.hitboxPart = v end })
        rageSec:dropdown({ name = "Position", items = {"Front","Behind","Above","Below","Inside"}, default = "Inside", callback = function(v) RS.rage.position = v end })
        rageSec:slider({ name = "Orbit Radius", min = 0, max = 100, interval = 1, default = 5, callback = function(v) RS.rage.radius = v end })
        rageSec:slider({ name = "Orbit Height", min = -100, max = 100, interval = 1, default = -4, callback = function(v) RS.rage.height = v end })
        rageSec:slider({ name = "Orbit Speed", min = 10, max = 5000, interval = 1, default = 500, callback = function(v) RS.rage.orbitSpeed = v end })
        rageSec:slider({ name = "Knife Distance", min = 1, max = 10, interval = 1, default = 3, callback = function(v) RS.rage.knifeDist = v end })
        rageSec:toggle({ name = "Bullet Prediction", default = false, callback = function(v) RS.rage.prediction = v end })
        rageSec:slider({ name = "Prediction Multiplier", min = 0.1, max = 3, interval = 0.1, default = 1.2, callback = function(v) RS.rage.predMult = v end })
        rageSec:toggle({ name = "Swap Weapon On Empty", default = false, callback = function(v) RS.rage.swapOnEmpty = v end })

        -- priority dropdown populated from players
        local function playerList()
            local l = { "" }
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP2 then l[#l+1] = p.Name end
            end
            return l
        end
        local prioDD = rageSec:dropdown({ name = "Priority", items = playerList(), default = "", callback = function(v) RS.rage.priority = v or "" end })
        Players.PlayerAdded:Connect(function() pcall(function() prioDD:SetItems(playerList()) end) end)
        Players.PlayerRemoving:Connect(function() task.defer(function() pcall(function() prioDD:SetItems(playerList()) end) end) end)

        local repSec = colRivals:section({ name = "Reposition" })
        repSec:toggle({ name = "Enable Reposition", default = false, callback = function(v) RS.reposition.enabled = v end })
        repSec:slider({ name = "Offset", min = -10, max = 10, interval = 0.5, default = -5, callback = function(v) RS.reposition.offset = v end })
        repSec:toggle({ name = "Anti Reposition", default = true, callback = function(v) RS.reposition.anti = v end })

        local dodgeSec = colRivals:section({ name = "Dodge & Block" })
        dodgeSec:toggle({ name = "Enable Dodge", default = false, callback = function(v) RS.dodge.enabled = v end })
        dodgeSec:dropdown({ name = "Dodge Method", items = {"lay down", "up", "random pos"}, default = "lay down", callback = function(v) RS.dodge.method = v end })
        dodgeSec:slider({ name = "Range Buffer", min = 0, max = 15, interval = 1, default = 3, callback = function(v) RS.dodge.rangeBuffer = v end })
        dodgeSec:slider({ name = "Duration", min = 0.2, max = 2, interval = 0.05, default = 0.85, callback = function(v) RS.dodge.duration = v end })
        dodgeSec:slider({ name = "Up Height", min = 8, max = 60, interval = 1, default = 20, callback = function(v) RS.dodge.height = v end })
        dodgeSec:toggle({ name = "Always Backstab", default = false, callback = function(v) RS.backstab.enabled = v end })
        dodgeSec:toggle({ name = "Perfect Block", default = false, callback = function(v) RS.block.enabled = v end })

        local akSec = colRivals:section({ name = "Anti-Knife" })
        akSec:toggle({ name = "Enable Anti-Knife", default = false, callback = function(v) RS.antiKnife.enabled = v end })
        akSec:slider({ name = "Trigger Range", min = 5, max = 40, interval = 1, default = 14, callback = function(v) RS.antiKnife.range = v end })
        akSec:slider({ name = "Retreat Distance", min = 5, max = 60, interval = 1, default = 18, callback = function(v) RS.antiKnife.retreat = v end })
        akSec:toggle({ name = "Only vs Melee", default = true, callback = function(v) RS.antiKnife.onlyMelee = v end })
    end, function(e) warn("[RivalsRage] " .. tostring(e)) end)
end

-- END OF CHUNK 7 --
-- ============================================================
-- COMBAT BYPASS + VOID MOVEMENT (from script 1, tab 3)
-- ============================================================
do
    local colBypass = makeColumn(tabs[3].content)
    xpcall(function()
        local RS2 = game:GetService("ReplicatedStorage")

        -- ============ COMBAT BYPASS ============
        local BYP = {
            daggerBypass=false, wallbang=false, rapidFire=false, fastMelee=false,
            underMap=false, underMapY=-500,
            aaPitch=0, aaYaw=0, aaSpin=false,
            riotEnabled=false, riotDist=300, riotX=30, riotY=8, riotZ=30, riotSpin=720,
            autoCollect=false, autoCollectRadius=60,
        }
        local wallbangBound = false
        local rapidFireConn, underMapConn, antiAimConn, riotAbuserConn, autoCollectConn
        local oldFireServer, lastWallbangShoot, riotAbuserOriginal, fastReloadRunning

        local function getLocalHrp()
            local ch = LP.Character
            return ch and ch:FindFirstChild("HumanoidRootPart")
        end
        local function getLocalClosest()
            local closest, minD = nil, math.huge
            local hrp = getLocalHrp()
            if not hrp then return nil end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    if LP.Team == nil or p.Team == nil or LP.Team ~= p.Team then
                        local hum = p.Character:FindFirstChild("Humanoid")
                        if hum and hum.Health > 0 then
                            local d = (hrp.Position - p.Character.HumanoidRootPart.Position).Magnitude
                            if d < minD then minD = d; closest = p end
                        end
                    end
                end
            end
            return closest
        end
        local function simpleSafeTeleport(pos)
            local hrp = getLocalHrp()
            if not hrp then return end
            local x, y, z = pos.X, pos.Y, pos.Z
            y = math.clamp(y, 2, hrp.Position.Y + 800)
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            rp.FilterDescendantsInstances = { LP.Character }
            local hit = workspace:Raycast(Vector3.new(x, y + 60, z), Vector3.new(0, -220, 0), rp)
            if hit then y = math.max(hit.Position.Y + 3, 2) end
            hrp.CFrame = CFrame.new(x, y, z)
        end
        local function installDaggerBypass()
            if oldFireServer then return end
            local ok = pcall(function()
                oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, newcclosure(function(self, ...)
                    if not checkcaller() and BYP.daggerBypass then
                        local n, a = self.Name:lower(), table.concat({ ... }, " "):lower()
                        if (n:find("dagger") or n:find("knife") or n:find("throw") or n:find("blade"))
                        and not (a:find(LP.Name:lower()) or a:find("owner")) then return end
                    end
                    return oldFireServer(self, ...)
                end))
            end)
            if not ok then oldFireServer = nil end
        end
        local function handleWallbang()
            if not BYP.wallbang then return end
            local cl = getLocalClosest(); local hrp = getLocalHrp(); local char = LP.Character
            if cl and cl.Character and cl.Character:FindFirstChild("Head") and hrp and char then
                local hd = cl.Character.Head
                local cam2 = workspace.CurrentCamera
                cam2.CFrame = CFrame.lookAt(cam2.CFrame.Position, hd.Position)
                local t = char:FindFirstChildOfClass("Tool")
                if t then pcall(function() t:Activate() end) end
                if tick() - lastWallbangShoot > 0.05 then
                    lastWallbangShoot = tick()
                    pcall(function()
                        if UIS.TouchEnabled and not UIS.KeyboardEnabled then
                            local center = cam2.ViewportSize / 2
                            if firetouchtap then firetouchtap(center) elseif touchtap then touchtap(center) end
                        else
                            if mouse1click then mouse1click() else
                                game:GetService("VirtualUser"):ClickButton1(Vector2.new(cam2.ViewportSize.X/2, cam2.ViewportSize.Y/2))
                            end
                        end
                    end)
                end
            end
        end
        local function startRapidFire()
            if rapidFireConn then return end
            rapidFireConn = RunSvc.Heartbeat:Connect(function()
                if BYP.rapidFire then
                    local t = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
                    if t then pcall(function() t:Activate() end) end
                end
            end)
        end
        local function stopRapidFire()
            if rapidFireConn then rapidFireConn:Disconnect(); rapidFireConn = nil end
        end
        local function startFastReload()
            if fastReloadRunning then return end
            fastReloadRunning = true
            task.spawn(function()
                local ok, ItemLibrary = pcall(function() return require(RS2.Modules.ItemLibrary) end)
                if not ok or not ItemLibrary then fastReloadRunning = false; return end
                local Items = rawget(ItemLibrary, "Items")
                if not Items then fastReloadRunning = false; return end
                while BYP.fastMelee do
                    for _, Item in pairs(Items) do
                        pcall(function()
                            local speed = Item.Name == "Daggers" and 0.09 or 0
                            rawset(Item, "ReloadLength", speed); rawset(Item, "FireRate", 0)
                            rawset(Item, "Cooldown", 0); rawset(Item, "AttackCooldown", 0)
                            rawset(Item, "SwingCooldown", 0); rawset(Item, "ThrowCooldown", 0)
                            rawset(Item, "RecoverTime", 0); rawset(Item, "WindupTime", 0)
                        end)
                    end
                    task.wait(0.1)
                end
                fastReloadRunning = false
            end)
        end
        local function startUnderMap()
            if underMapConn then return end
            underMapConn = RunSvc.Heartbeat:Connect(function()
                if not BYP.underMap or not getLocalHrp() then return end
                local hrp = getLocalHrp()
                if LP.Character then
                    for _, p in ipairs(LP.Character:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
                hrp.CFrame = CFrame.new(hrp.Position.X, BYP.underMapY, hrp.Position.Z)
            end)
        end
        local function stopUnderMap() if underMapConn then underMapConn:Disconnect(); underMapConn = nil end end
        local function startAntiAimLegacy()
            if antiAimConn then return end
            antiAimConn = RunSvc.Heartbeat:Connect(function()
                if BYP.aaPitch ~= 0 or BYP.aaYaw ~= 0 then
                    local hrp = getLocalHrp()
                    if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(BYP.aaPitch), math.rad(BYP.aaYaw), 0) end
                end
                if BYP.aaSpin then
                    local hrp = getLocalHrp()
                    if hrp then
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(math.random(-180, 180)), 0)
                        hrp.AssemblyLinearVelocity = Vector3.new(math.random(-200,200), 250, math.random(-200,200)) * 45
                    end
                end
            end)
        end
        local function stopAntiAimLegacy() if antiAimConn then antiAimConn:Disconnect(); antiAimConn = nil end end
        local function startRiotAbuser()
            if riotAbuserConn then riotAbuserConn:Disconnect(); riotAbuserConn = nil end
            local t0, seed = tick(), math.random(1e3, 9e3)
            local hrp = getLocalHrp()
            if hrp then riotAbuserOriginal = hrp.CFrame end
            riotAbuserConn = RunSvc.Heartbeat:Connect(function(dt)
                if not BYP.riotEnabled then return end
                local hrp2 = getLocalHrp(); if not hrp2 then return end
                local t = tick() - t0
                local yaw   = math.rad(BYP.riotSpin * dt)
                local pitch = math.rad(BYP.riotSpin * 0.37 * dt * math.sin(t * 3.1))
                local roll  = math.rad(BYP.riotSpin * 0.19 * dt * math.cos(t * 5.7 + seed))
                local spinCF = hrp2.CFrame * CFrame.Angles(pitch, yaw, roll)
                local spread = BYP.riotDist / 300
                local jX = (math.random() - 0.5) * BYP.riotX * spread * 2 + math.noise(t*9, seed, 0) * BYP.riotX * spread
                local jY = (math.random() - 0.5) * BYP.riotY * spread + math.noise(0, t*9, seed) * BYP.riotY * spread * 0.3
                local jZ = (math.random() - 0.5) * BYP.riotZ * spread * 2 + math.noise(0, 0, t*9+seed) * BYP.riotZ * spread
                local newY = math.max(spinCF.Position.Y + jY, 2)
                hrp2.CFrame = spinCF + Vector3.new(jX, newY - spinCF.Position.Y, jZ)
            end)
        end
        local function stopRiotAbuser()
            if riotAbuserConn then riotAbuserConn:Disconnect(); riotAbuserConn = nil end
            local hrp = getLocalHrp()
            if hrp and riotAbuserOriginal then hrp.CFrame = riotAbuserOriginal end
            riotAbuserOriginal = nil
        end
        local function startAutoCollect()
            if autoCollectConn then return end
            autoCollectConn = RunSvc.Heartbeat:Connect(function()
                if not BYP.autoCollect or not getLocalHrp() then return end
                local best, minD = nil, math.huge
                for _, o in ipairs(workspace:GetDescendants()) do
                    local n = o.Name:lower()
                    if n:find("heal") or n:find("health") or n:find("medkit") or n:find("bandage") then
                        local p = o:IsA("Model") and (o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart"))
                            or (o:IsA("BasePart") and o or nil)
                        if p then
                            local d = (p.Position - getLocalHrp().Position).Magnitude
                            if d < minD and d <= BYP.autoCollectRadius then minD = d; best = p.Position end
                        end
                    end
                end
                if best then simpleSafeTeleport(best) end
            end)
        end
        local function stopAutoCollect() if autoCollectConn then autoCollectConn:Disconnect(); autoCollectConn = nil end end
        local function stopAllBypass()
            BYP.rapidFire = false; stopRapidFire()
            BYP.underMap = false; stopUnderMap()
            BYP.aaSpin = false; BYP.aaPitch = 0; BYP.aaYaw = 0; stopAntiAimLegacy()
            BYP.riotEnabled = false; stopRiotAbuser()
            BYP.autoCollect = false; stopAutoCollect()
            BYP.fastMelee = false
            BYP.wallbang = false
            if wallbangBound then pcall(function() RunSvc:UnbindFromRenderStep("WB_AimFix") end); wallbangBound = false end
        end

        -- ---- Combat Bypass UI ----
        local bypassSec = colBypass:section({ name = "Combat Bypass" })
        bypassSec:toggle({ name = "Dagger Bypass", default = false, callback = function(v)
            BYP.daggerBypass = v
            if v then installDaggerBypass() end
        end })
        bypassSec:toggle({ name = "Wallbang Aim", default = false, callback = function(v)
            BYP.wallbang = v
            if v then
                if not wallbangBound then
                    pcall(function() RunSvc:BindToRenderStep("WB_AimFix", Enum.RenderPriority.Camera.Value + 1, handleWallbang) end)
                    wallbangBound = true
                end
            else
                if wallbangBound then pcall(function() RunSvc:UnbindFromRenderStep("WB_AimFix") end); wallbangBound = false end
            end
        end })
        bypassSec:toggle({ name = "Rapid Fire", default = false, callback = function(v)
            BYP.rapidFire = v
            if v then startRapidFire() else stopRapidFire() end
        end })
        bypassSec:toggle({ name = "Fast Melee / Fast Reload", default = false, callback = function(v)
            BYP.fastMelee = v
            if v then startFastReload() end
        end })
        bypassSec:button({ name = "Stop All Bypass", callback = function() stopAllBypass() end })

        local underAntiSec = colBypass:section({ name = "Underground & Anti Aim" })
        underAntiSec:toggle({ name = "Underground (Anti-Aim)", default = false, callback = function(v)
            BYP.underMap = v
            if v then startUnderMap() else stopUnderMap() end
        end })
        underAntiSec:slider({ name = "Underground Depth", min = -5000, max = -50, interval = 1, default = -500, callback = function(v) BYP.underMapY = v end })
        underAntiSec:toggle({ name = "Anti Aim (Legacy)", default = false, callback = function(v)
            if v then startAntiAimLegacy()
            elseif not BYP.aaSpin then stopAntiAimLegacy() end
        end })
        underAntiSec:slider({ name = "Pitch Shift", min = -180, max = 180, interval = 1, default = 0, callback = function(v) BYP.aaPitch = v end })
        underAntiSec:slider({ name = "Yaw Shift", min = -180, max = 180, interval = 1, default = 0, callback = function(v) BYP.aaYaw = v end })
        underAntiSec:toggle({ name = "Spin Bypass", default = false, callback = function(v)
            BYP.aaSpin = v
            if v and not antiAimConn then startAntiAimLegacy()
            elseif not v and antiAimConn and BYP.aaPitch == 0 and BYP.aaYaw == 0 then stopAntiAimLegacy() end
        end })

        local riotAbuserSec = colBypass:section({ name = "Riot Abuser" })
        riotAbuserSec:toggle({ name = "Riot Abuser", default = false, callback = function(v)
            BYP.riotEnabled = v
            if v then startRiotAbuser() else stopRiotAbuser() end
        end })
        riotAbuserSec:slider({ name = "Spread Distance", min = 10, max = 1000, interval = 1, default = 300, callback = function(v) BYP.riotDist = v end })
        riotAbuserSec:slider({ name = "X Jitter", min = 0, max = 200, interval = 1, default = 30, callback = function(v) BYP.riotX = v end })
        riotAbuserSec:slider({ name = "Y Jitter", min = 0, max = 100, interval = 1, default = 8, callback = function(v) BYP.riotY = v end })
        riotAbuserSec:slider({ name = "Z Jitter", min = 0, max = 200, interval = 1, default = 30, callback = function(v) BYP.riotZ = v end })
        riotAbuserSec:slider({ name = "Spin Speed", min = 0, max = 2000, interval = 1, default = 720, callback = function(v) BYP.riotSpin = v end })

        -- ============ VOID MOVEMENT (VM) ============
        local VM = {
            running=false, mode="VOID_SPAM", pattern="Random Far",
            distance=500, interval=0.035, jitter=14,
            distPlusX=200000, distMinusX=200000, distPlusY=200000, distMinusY=200000,
            distPlusZ=200000, distMinusZ=200000,
            conn=nil, originalCFrame=nil, hideLastCFrame=nil,
            lastTeleport=0, lastVelocityClear=0,
            voidX=math.random(-1e8,1e8), voidZ=math.random(-1e8,1e8),
            voidYOffset=0, voidYDir=1,
            voidDirX=math.random()*2-1, voidDirZ=math.random()*2-1,
            voidElapsed=0, voidYBase=1e10+math.random(-5e9,5e9),
            voidDriftSpeed=9e6, voidYDriftSpeed=4e6, voidYDriftRange=2e9, voidChaos=0.98,
        }
        local SAFE_FLOOR, SAFE_MAX_RISE = 2, 800

        local function vmGetHrp()
            local ch = LP.Character
            if not ch then return nil end
            return ch:FindFirstChild("HumanoidRootPart"), ch
        end
        local function vmResetPattern()
            VM.voidX=math.random(-1e8,1e8); VM.voidZ=math.random(-1e8,1e8)
            VM.voidYOffset=0; VM.voidYDir=1
            VM.voidDirX=math.random()*2-1; VM.voidDirZ=math.random()*2-1
            VM.voidElapsed=0; VM.voidYBase=1e10+math.random(-5e9,5e9)
        end
        local function vmSafeTeleport(pos)
            local hrp, ch = vmGetHrp(); if not hrp then return end
            local x, y, z = pos.X, math.clamp(pos.Y, SAFE_FLOOR, hrp.Position.Y + SAFE_MAX_RISE), pos.Z
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            rp.FilterDescendantsInstances = ch and { ch } or {}
            local hit = workspace:Raycast(Vector3.new(x, y + 500, z), Vector3.new(0, -1000, 0), rp)
            if hit then y = math.max(hit.Position.Y + 3, SAFE_FLOOR) end
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(x, y, z)
        end
        local function vmRawTeleport(pos)
            local hrp = vmGetHrp(); if not hrp then return end
            if tick() - VM.lastVelocityClear > 0.2 then
                VM.lastVelocityClear = tick()
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
            hrp.CFrame = CFrame.new(pos)
        end
        local function vmHidePos()
            local hrp = vmGetHrp(); if not hrp then return nil end
            return Vector3.new(hrp.Position.X + 2e15, 999999, hrp.Position.Z + 2e15)
        end
        local function vmDirLimitOffset()
            local raw = Vector3.new(
                math.random(-VM.distMinusX, VM.distPlusX),
                math.random(-VM.distMinusY, VM.distPlusY),
                math.random(-VM.distMinusZ, VM.distPlusZ))
            if raw.Magnitude <= 0 then return Vector3.zero end
            return raw.Unit * math.min(raw.Magnitude, VM.distance)
        end
        local function computeVoidDriftDir(t)
            local nx, nz, amp, freq = 0, 0, 1, 0.0001
            for _ = 1, 4 do
                nx = nx + math.noise(t*freq, 0) * amp
                nz = nz + math.noise(0, t*freq) * amp
                freq = freq * 2.37; amp = amp * 0.5
            end
            nx = nx + math.sin(t*0.00213)*math.cos(t*0.00344)*0.2
            nz = nz + math.cos(t*0.00131)*math.sin(t*0.00579)*0.2
            local len = math.sqrt(nx*nx + nz*nz)
            if len < 0.001 then return math.cos(t*0.1), math.sin(t*0.1) end
            return nx/len, nz/len
        end
        local function vmFarPosition(dt)
            VM.voidElapsed = VM.voidElapsed + dt
            local pat = VM.pattern
            if pat == "Still Point" then
                return Vector3.new(VM.voidX, VM.voidYBase + VM.voidYOffset, VM.voidZ)
            elseif pat == "Slow Drift" then
                local dx, dz = computeVoidDriftDir(VM.voidElapsed)
                VM.voidDirX = VM.voidDirX + (dx - VM.voidDirX) * VM.voidChaos * dt * 10
                VM.voidDirZ = VM.voidDirZ + (dz - VM.voidDirZ) * VM.voidChaos * dt * 10
                VM.voidX = VM.voidX + VM.voidDirX * VM.voidDriftSpeed * dt
                VM.voidZ = VM.voidZ + VM.voidDirZ * VM.voidDriftSpeed * dt
                VM.voidYOffset = VM.voidYOffset + VM.voidYDir * VM.voidYDriftSpeed * dt
                if math.abs(VM.voidYOffset) >= VM.voidYDriftRange then VM.voidYDir = -VM.voidYDir end
                return Vector3.new(VM.voidX, VM.voidYBase + VM.voidYOffset, VM.voidZ)
            elseif pat == "Circle" then
                local r = math.max(VM.distance*1000, 1e9) * (1 + math.sin(VM.voidElapsed))
                return Vector3.new(VM.voidX + math.cos(VM.voidElapsed*3)*r, VM.voidYBase + VM.voidYOffset, VM.voidZ + math.sin(VM.voidElapsed*3)*r)
            elseif pat == "Figure Eight" then
                local r = math.max(VM.distance*2000, 2e9)
                return Vector3.new(VM.voidX + math.sin(VM.voidElapsed*2)*r, VM.voidYBase + math.sin(VM.voidElapsed*4)*r*0.1, VM.voidZ + math.sin(VM.voidElapsed*3)*r)
            elseif pat == "Wide Sweep" then
                local t, r = VM.voidElapsed*15, math.max(VM.distance*10000, 1e10)
                return Vector3.new(VM.voidX + math.sin(t)*r, VM.voidYBase + math.cos(t*1.5)*r*0.1, VM.voidZ + math.cos(t)*r)
            elseif pat == "Fast Bounce" then
                local t, r = VM.voidElapsed*50, math.max(VM.distance*10000, 1e10) * math.sin(VM.voidElapsed*50)
                return Vector3.new(VM.voidX + r, VM.voidYBase + math.cos(t)*1e10, VM.voidZ + r)
            elseif pat == "Cross Sweep" then
                local r = math.max(VM.distance*6000, 4e9)
                local t = VM.voidElapsed*4
                local axis = math.floor(t) % 4
                local a = math.sin(t*math.pi) * r
                if axis==0 then return Vector3.new(VM.voidX + a, VM.voidYBase, VM.voidZ)
                elseif axis==1 then return Vector3.new(VM.voidX, VM.voidYBase + math.sin(t)*r*0.08, VM.voidZ + a)
                elseif axis==2 then return Vector3.new(VM.voidX - a, VM.voidYBase, VM.voidZ) end
                return Vector3.new(VM.voidX, VM.voidYBase - math.sin(t)*r*0.08, VM.voidZ - a)
            elseif pat == "Noise Cloud" then
                local r = math.max(VM.distance*5000, 4e9)
                local t = VM.voidElapsed*1.5
                return Vector3.new(VM.voidX + math.noise(t,0,0)*r, VM.voidYBase + math.noise(0,t,0)*r*0.25, VM.voidZ + math.noise(0,0,t)*r)
            end
            local r = math.max(VM.distance*10000, 1e11)
            local sign = math.random() > 0.5 and 1 or -1
            local jitter = Vector3.new(math.random(-1e9,1e9), math.random(-1e8,1e8), math.random(-1e9,1e9))
            return Vector3.new(VM.voidX + r*sign, VM.voidYBase + jitter.Y, VM.voidZ + r*sign) + jitter
        end
        local function vmStep(dt, phase)
            local hrp = vmGetHrp(); if not hrp then return false end
            dt = dt or VM.interval
            phase = phase or (VM.voidElapsed + dt * 28)
            if VM.mode == "VOID_HIDE" then
                if not VM.hideLastCFrame then VM.hideLastCFrame = hrp.CFrame end
                local hp = vmHidePos(); if hp then vmRawTeleport(hp) end
                return true
            end
            if VM.mode == "VOID_SPAM" then
                vmRawTeleport(vmFarPosition(dt))
                return true
            end
            local offset
            if VM.mode == "FORWARD" then
                offset = hrp.CFrame.LookVector * VM.distance
            elseif VM.mode == "CAMERA" and workspace.CurrentCamera then
                offset = workspace.CurrentCamera.CFrame.LookVector * VM.distance
            elseif VM.mode == "DIRECTIONAL" then
                offset = vmDirLimitOffset()
            else
                local r1 = VM.distance*(0.60+0.40*math.sin(phase*2.3))
                local r2 = VM.distance*(0.25+0.15*math.sin(phase*5.7))
                local r3 = VM.distance*(0.10+0.10*math.sin(phase*11.3))
                local oX = math.cos(phase*7.1)*r1 + math.cos(phase*13.4)*r2 + math.cos(phase*21.9)*r3
                local oZ = math.sin(phase*7.1)*r1 + math.sin(phase*13.4)*r2 + math.sin(phase*21.9)*r3
                local oY = math.sin(phase*9)*r1*0.4 + math.sin(phase*17)*r2*0.3
                local jX = math.noise(phase*6,0,0)*VM.jitter*3 + (math.random()-0.5)*VM.jitter*2.5
                local jY = math.noise(0,phase*6,0)*VM.jitter*1.5 + (math.random()-0.5)*VM.jitter*1.2
                local jZ = math.noise(0,0,phase*6)*VM.jitter*3 + (math.random()-0.5)*VM.jitter*2.5
                offset = Vector3.new(oX+jX, oY+jY, oZ+jZ)
            end
            vmSafeTeleport(hrp.Position + offset)
            return true
        end
        local function vmStart()
            if VM.conn then VM.conn:Disconnect() end
            local hrp = vmGetHrp()
            if hrp then VM.originalCFrame = hrp.CFrame end
            local phase = 0
            VM.conn = RunSvc.Heartbeat:Connect(function(dt)
                if not VM.running then return end
                if tick() - VM.lastTeleport < VM.interval then return end
                VM.lastTeleport = tick()
                phase = phase + dt * 28
                vmStep(dt, phase)
            end)
        end
        local function vmStop()
            VM.running = false
            if VM.conn then VM.conn:Disconnect(); VM.conn = nil end
            local hrp = vmGetHrp()
            if hrp then
                if VM.mode == "VOID_HIDE" and VM.hideLastCFrame then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    hrp.CFrame = VM.hideLastCFrame
                elseif VM.originalCFrame then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    hrp.CFrame = VM.originalCFrame
                end
            end
            VM.originalCFrame = nil
            VM.hideLastCFrame = nil
        end
        local function applyVoidProfile(value)
            if value == "Steady Scan" then
                VM.mode="VOID_SPAM"; VM.pattern="Slow Drift"
                VM.distance=2500000; VM.interval=0.08; VM.jitter=4
                VM.voidDriftSpeed=3500000; VM.voidYDriftSpeed=1600000
                VM.voidYDriftRange=900000000; VM.voidChaos=0.55
            elseif value == "Fast Sweep" then
                VM.mode="VOID_SPAM"; VM.pattern="Cross Sweep"
                VM.distance=12000000; VM.interval=0.025; VM.jitter=18
                VM.voidDriftSpeed=12000000; VM.voidYDriftSpeed=6000000
                VM.voidYDriftRange=3500000000; VM.voidChaos=0.9
            elseif value == "Deep Void" then
                VM.mode="VOID_SPAM"; VM.pattern="Noise Cloud"
                VM.distance=50000000; VM.interval=0.04; VM.jitter=8
                VM.voidDriftSpeed=18000000; VM.voidYDriftSpeed=9000000
                VM.voidYDriftRange=7000000000; VM.voidChaos=0.75
            elseif value == "Stress Test" then
                VM.mode="VOID_SPAM"; VM.pattern="Fast Bounce"
                VM.distance=50000000; VM.interval=0.01; VM.jitter=45
                VM.voidDriftSpeed=30000000; VM.voidYDriftSpeed=16000000
                VM.voidYDriftRange=12000000000; VM.voidChaos=0.98
            end
            vmResetPattern()
        end

        -- ---- Void Movement UI ----
        local vmSec = colBypass:section({ name = "Void Movement" })
        vmSec:toggle({ name = "Enable Void Movement", default = false, callback = function(v)
            VM.running = v
            if v then vmStart() else vmStop() end
        end })
        vmSec:keybind({ name = "Void Movement Toggle", callback = function(active)
            VM.running = active
            if active then vmStart() else vmStop() end
        end })
        vmSec:dropdown({ name = "Movement Mode", default = "VOID_SPAM",
            items = { "VOID_SPAM", "VOID_HIDE", "RANDOM", "CAMERA", "FORWARD", "DIRECTIONAL" },
            callback = function(v) VM.mode = v end })
        vmSec:dropdown({ name = "Void Pattern", default = "Random Far",
            items = { "Random Far", "Still Point", "Slow Drift", "Circle", "Figure Eight", "Wide Sweep", "Fast Bounce", "Cross Sweep", "Noise Cloud" },
            callback = function(v) VM.pattern = v end })
        vmSec:button({ name = "Reset Pattern", callback = function() vmResetPattern() end })
        vmSec:slider({ name = "Distance", min = 50, max = 50000000, interval = 1, default = 500, suffix = " studs", callback = function(v) VM.distance = v end })
        vmSec:slider({ name = "Step Interval", min = 0.01, max = 2, interval = 0.01, default = 0.035, suffix = "s", callback = function(v) VM.interval = v end })
        vmSec:slider({ name = "Jitter Strength", min = 0, max = 60, interval = 1, default = 14, callback = function(v) VM.jitter = v end })
        vmSec:dropdown({ name = "Movement Preset", default = "Manual",
            items = { "Manual", "Steady Scan", "Fast Sweep", "Deep Void", "Stress Test" },
            callback = function(v) if v ~= "Manual" then applyVoidProfile(v) end end })

        local vdmSec = colBypass:section({ name = "Void Directional Limits" })
        vdmSec:slider({ name = "+X Limit", min = 50, max = 50000000, interval = 1, default = 200000, callback = function(v) VM.distPlusX = v end })
        vdmSec:slider({ name = "-X Limit", min = 50, max = 50000000, interval = 1, default = 200000, callback = function(v) VM.distMinusX = v end })
        vdmSec:slider({ name = "+Y Limit", min = 50, max = 50000000, interval = 1, default = 200000, callback = function(v) VM.distPlusY = v end })
        vdmSec:slider({ name = "-Y Limit", min = 50, max = 50000000, interval = 1, default = 200000, callback = function(v) VM.distMinusY = v end })
        vdmSec:slider({ name = "+Z Limit", min = 50, max = 50000000, interval = 1, default = 200000, callback = function(v) VM.distPlusZ = v end })
        vdmSec:slider({ name = "-Z Limit", min = 50, max = 50000000, interval = 1, default = 200000, callback = function(v) VM.distMinusZ = v end })
        vdmSec:button({ name = "Mirror Limits", callback = function()
            local x = math.max(VM.distPlusX, VM.distMinusX)
            local y = math.max(VM.distPlusY, VM.distMinusY)
            local z = math.max(VM.distPlusZ, VM.distMinusZ)
            VM.distPlusX = x; VM.distMinusX = x
            VM.distPlusY = y; VM.distMinusY = y
            VM.distPlusZ = z; VM.distMinusZ = z
        end })
        vdmSec:button({ name = "Reset Limits", callback = function()
            VM.distPlusX = 200000; VM.distMinusX = 200000
            VM.distPlusY = 200000; VM.distMinusY = 200000
            VM.distPlusZ = 200000; VM.distMinusZ = 200000
        end })
    end, function(e) warn("[CombatBypass/VM] " .. tostring(e)) end)
end

-- END OF CHUNK 8 --
-- ============================================================
-- SPINBOT + AUTO-HEAL (Evasion tab)
-- ============================================================
do
    local colEv = makeColumn(tabs[4].content)

    -- ---- Auto Heal (Medkit) ----
    local AH = { on=false, below=45, stopAt=90, hide=false, back=true, busy=false, cool=0, acc=0 }
    local function ahName(it)
        if it == nil then return nil end
        for _, g in ipairs({
            function() return it.Name end,
            function() return it.DisplayName end,
            function() return it.Info and it.Info.Name end,
            function() return it.Data and it.Data.Name end,
        }) do
            local ok, n = pcall(g)
            if ok and type(n)=="string" and n~="" then return n end
        end
        return nil
    end
    local function ahFighter()
        local ok, mod = pcall(function() return require(LP.PlayerScripts.Controllers.FighterController) end)
        return ok and mod and mod.LocalFighter or nil
    end
    local function ahMedkit(f)
        if type(f)~="table" or type(f.Items)~="table" then return nil end
        for s = 1, 4 do
            local n = ahName(f.Items[s])
            if n and n:lower()=="medkit" then return s end
        end
        return nil
    end
    local function ahSlot(f)
        if type(f.Items)~="table" or f.EquippedItem==nil then return nil end
        for s = 1, 4 do if f.Items[s] == f.EquippedItem then return s end end
        return nil
    end
    local function ahHP()
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h and h.MaxHealth > 0 and h.Health > 0 then return h.Health / h.MaxHealth * 100 end
        return nil
    end
    local function ahHeal()
        if AH.busy then return end
        AH.busy = true
        task.spawn(function()
            local home, root
            pcall(function()
                local f = ahFighter(); if not f then return end
                local s = ahMedkit(f); if not s then return end
                local prev = ahSlot(f)
                root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if AH.hide and root then home = root.CFrame end
                f:EquipItem(s)
                local t0 = tick()
                while AH.on and tick() - t0 < 5 do
                    local pct = ahHP()
                    if not pct or pct >= AH.stopAt then break end
                    if home and root and root.Parent then
                        root.CFrame = home + Vector3.new(0, 300, 0)
                        root.AssemblyLinearVelocity = Vector3.zero
                    end
                    pcall(function()
                        local v = game:GetService("VirtualInputManager")
                        v:CaptureController(); v:ClickButton1(Vector2.new(0,0))
                    end)
                    task.wait(0.25)
                end
                if AH.back and prev and prev ~= s then pcall(function() f:EquipItem(prev) end) end
            end)
            if home and root and root.Parent then pcall(function() root.CFrame = home; root.AssemblyLinearVelocity = Vector3.zero end) end
            AH.cool = tick() + 3
            AH.busy = false
        end)
    end
    RunSvc.Heartbeat:Connect(function(dt)
        if not AH.on or AH.busy then return end
        AH.acc = AH.acc + dt
        if AH.acc < 0.3 then return end
        AH.acc = 0
        if tick() < AH.cool then return end
        local pct = ahHP()
        if pct and pct <= AH.below then pcall(ahHeal) end
    end)
    local ahSec = colEv:section({ name = "Auto Heal" })
    ahSec:toggle({ name = "Auto heal (Medkit)", default = false, callback = function(v) AH.on = v end })
    ahSec:slider({ name = "Heal below %", min = 10, max = 90, interval = 1, default = 45, callback = function(v) AH.below = v end })
    ahSec:slider({ name = "Stop at %", min = 50, max = 100, interval = 1, default = 90, callback = function(v) AH.stopAt = v end })
    ahSec:toggle({ name = "Hide while healing", default = false, callback = function(v) AH.hide = v end })
    ahSec:toggle({ name = "Switch back to weapon", default = true, callback = function(v) AH.back = v end })

    -- ---- Spinbot ----
    local SB = { on=false, mode="Spin", speed=720, dir="Right", angle=90, flip=false, acc=0, ang=0, conn=nil,
                 hideSelf=true, camSpin=true, cang=0, off=nil }
    local function sbAutoRotate(v)
        pcall(function()
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.AutoRotate = v end
        end)
    end
    local function sbUndo()
        if not SB.off then return end
        local off = SB.off; SB.off = nil
        local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if r then r.CFrame = r.CFrame * off:Inverse() end
    end
    local function sbStop()
        if SB.conn then SB.conn:Disconnect(); SB.conn = nil end
        pcall(function() RunSvc:UnbindFromRenderStep("SB_CamSpin") end)
        pcall(function() RunSvc:UnbindFromRenderStep("SB_UndoSpin") end)
        pcall(sbUndo)
        sbAutoRotate(true)
    end
    local function sbStart()
        if SB.conn then return end
        sbAutoRotate(false)
        pcall(function() RunSvc:UnbindFromRenderStep("SB_UndoSpin") end)
        RunSvc:BindToRenderStep("SB_UndoSpin", Enum.RenderPriority.Camera.Value - 1, function()
            if SB.hideSelf then pcall(sbUndo) else SB.off = nil end
        end)
        pcall(function() RunSvc:UnbindFromRenderStep("SB_CamSpin") end)
        RunSvc:BindToRenderStep("SB_CamSpin", Enum.RenderPriority.Last.Value, function(dt)
            if not SB.camSpin then return end
            local c = workspace.CurrentCamera; if not c then return end
            local yaw
            if SB.mode == "Spin" then
                local sgn = (SB.dir == "Left") and -1 or 1
                if SB.dir == "Alternate" then sgn = SB.flip and -1 or 1 end
                SB.cang = (SB.cang + SB.speed * dt * sgn) % 360
                yaw = SB.cang
            elseif SB.mode == "Jitter" then yaw = SB.flip and SB.angle or -SB.angle
            elseif SB.mode == "Random" then yaw = math.random(-180, 180) end
            if yaw then c.CFrame = c.CFrame * CFrame.Angles(0, math.rad(yaw), 0) end
        end)
        SB.conn = RunSvc.Heartbeat:Connect(function(dt)
            local ch = LP.Character
            local r = ch and ch:FindFirstChild("HumanoidRootPart")
            local h = ch and ch:FindFirstChildOfClass("Humanoid")
            if not (r and h and h.Health > 0) then return end
            if h.AutoRotate then h.AutoRotate = false end
            if SB.off then pcall(sbUndo) end
            local real = r.CFrame; local off
            if SB.mode == "Spin" then
                local sgn = 1
                if SB.dir == "Left" then sgn = -1
                elseif SB.dir == "Alternate" then
                    SB.acc = SB.acc + dt
                    if SB.acc >= 0.5 then SB.acc = 0; SB.flip = not SB.flip end
                    sgn = SB.flip and -1 or 1
                end
                SB.ang = (SB.ang + SB.speed * dt * sgn) % 360
                off = CFrame.Angles(0, math.rad(SB.ang), 0)
            elseif SB.mode == "Jitter" then
                off = CFrame.Angles(0, math.rad(SB.flip and SB.angle or -SB.angle), 0)
                SB.flip = not SB.flip
            elseif SB.mode == "Random" then
                off = CFrame.Angles(0, math.rad(math.random(-180, 180)), 0)
            elseif SB.mode == "Backwards" then
                local c = workspace.CurrentCamera
                if c then
                    local look = c.CFrame.LookVector
                    local tgt = CFrame.new(real.Position, real.Position - Vector3.new(look.X, 0, look.Z))
                    off = real:Inverse() * tgt
                end
            end
            if off then r.CFrame = real * off; SB.off = off end
        end)
    end
    local sbSec = colEv:section({ name = "Spinbot" })
    sbSec:toggle({ name = "Spinbot", default = false, callback = function(v) SB.on = v; if v then sbStart() else sbStop() end end })
    sbSec:dropdown({ name = "Mode", items = { "Spin", "Jitter", "Random", "Backwards" }, default = "Spin", callback = function(v) SB.mode = v end })
    sbSec:slider({ name = "Spin speed", min = 50, max = 5000, interval = 1, default = 720, suffix = " deg/s", callback = function(v) SB.speed = v end })
    sbSec:dropdown({ name = "Direction", items = { "Right", "Left", "Alternate" }, default = "Right", callback = function(v) SB.dir = v end })
    sbSec:slider({ name = "Jitter angle", min = 10, max = 180, interval = 1, default = 90, suffix = " deg", callback = function(v) SB.angle = v end })
    sbSec:toggle({ name = "Hide my own spin", default = true, callback = function(v) SB.hideSelf = v end })
    sbSec:toggle({ name = "Spin my camera too", default = true, callback = function(v) SB.camSpin = v end })
end

-- ============================================================
-- VOID TAB (voidspam + directions)
-- ============================================================
do
    local colVoid = makeColumn(tabs[5].content)
    local VS = {
        on=false, mode="Random", pattern="Triangle",
        speed=10000000, total=500, minDist=0, maxDist=50000,
        xp=5000, xn=5000, yp=5000, yn=5000, zp=5000, zn=5000,
        axisX=false, axisY=false, axisZ=false,
        smooth=false, smoothAlpha=0.5, distPerTp=1000,
        conn=nil, lastPos=nil, lastTp=0,
    }
    local function getOrderOffset(order, frac, i, ph, radius)
        local o = Vector3.zero
        if order=="Triangle" then
            local seg=math.floor(frac*3); local f=(frac*3)-seg
            if seg==0 then o=Vector3.new(0,radius,0):Lerp(Vector3.new(radius,-radius,0),f)
            elseif seg==1 then o=Vector3.new(radius,-radius,0):Lerp(Vector3.new(-radius,-radius,0),f)
            else o=Vector3.new(-radius,-radius,0):Lerp(Vector3.new(0,radius,0),f) end
        elseif order=="Circle" then o=Vector3.new(math.cos(ph)*radius,0,math.sin(ph)*radius)
        elseif order=="Square" then
            local seg=math.floor(frac*4); local f=(frac*4)-seg
            if seg==0 then o=Vector3.new(radius,-radius,0):Lerp(Vector3.new(radius,radius,0),f)
            elseif seg==1 then o=Vector3.new(radius,radius,0):Lerp(Vector3.new(-radius,radius,0),f)
            elseif seg==2 then o=Vector3.new(-radius,radius,0):Lerp(Vector3.new(-radius,-radius,0),f)
            else o=Vector3.new(-radius,-radius,0):Lerp(Vector3.new(radius,-radius,0),f) end
        elseif order=="Spiral" then
            local a=frac*math.pi*6; local r=frac*radius
            o=Vector3.new(math.cos(a)*r,math.sin(frac*math.pi*2)*radius*0.5,math.sin(a)*r)
        elseif order=="Star" then
            local seg=math.floor(frac*10); local f=(frac*10)-seg
            local ro=radius; local ri=radius*0.4
            local r1=seg%2==0 and ro or ri; local r2=seg%2==0 and ri or ro
            local a1=(seg/10)*math.pi*2; local a2=((seg+1)/10)*math.pi*2
            o=Vector3.new(math.cos(a1)*r1,0,math.sin(a1)*r1):Lerp(Vector3.new(math.cos(a2)*r2,0,math.sin(a2)*r2),f)
        else o=Vector3.new(math.cos(ph)*radius,0,math.sin(ph)*radius) end
        return o
    end
    local function startVS()
        if VS.conn then return end
        VS.conn = RunSvc.Heartbeat:Connect(function(dt)
            if not VS.on then if VS.conn then VS.conn:Disconnect(); VS.conn=nil end return end
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then return end
            if hum:GetState() ~= Enum.HumanoidStateType.Physics then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end) end
            if tick() - VS.lastTp < 0.001 then return end
            VS.lastTp = tick()
            local iters = math.clamp(VS.total, 1, 500)
            for i = 1, iters do
                local frac=(i-1)/iters; local ph=frac*math.pi*2; local radius=50000
                local offset = getOrderOffset(VS.pattern, frac, i, ph, radius)
                local finalPos
                if VS.mode=="Random" then
                    finalPos = hrp.Position + offset + Vector3.new(math.random(-500,500),math.random(-500,500),math.random(-500,500))
                elseif VS.mode=="Camera" then
                    local c = workspace.CurrentCamera
                    if c then finalPos = c.CFrame.Position + c.CFrame.LookVector*radius + offset end
                elseif VS.mode=="Forward" then
                    finalPos = hrp.Position + hrp.CFrame.LookVector*radius + offset
                elseif VS.mode=="Directional" then
                    local raw = Vector3.new(
                        math.random(-VS.xn, VS.xp), math.random(-VS.yn, VS.yp), math.random(-VS.zn, VS.zp))
                    if raw.Magnitude > 0 then
                        local dir = raw.Unit
                        finalPos = (VS.lastPos or hrp.Position) + dir * (VS.distPerTp or 1000)
                    end
                end
                if finalPos then
                    VS.lastPos = finalPos
                    hrp.CFrame = CFrame.new(finalPos)
                end
            end
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end
    local function stopVS()
        VS.on = false
        if VS.conn then VS.conn:Disconnect(); VS.conn = nil end
        VS.lastPos = nil
    end
    local vsSec = colVoid:section({ name = "Void Teleport" })
    vsSec:toggle({ name = "Voidspam", default = false, callback = function(v) VS.on = v; if v then startVS() else stopVS() end end })
    vsSec:dropdown({ name = "Voidspam Type", items = { "Random","Camera","Forward","Directional" }, default = "Random", callback = function(v) VS.mode = v end })
    vsSec:dropdown({ name = "Burst Pattern", default = "Triangle",
        items = { 'Triangle','Circle','Square','Spiral','Star' },
        callback = function(v) VS.pattern = v end })
    vsSec:slider({ name = "Burst Count", min = 1, max = 500, interval = 1, default = 500, callback = function(v) VS.total = v end })
    local vd = colVoid:section({ name = "Directions" })
    vd:slider({ name = "Min Distance", min = 0, max = 50000, interval = 1, default = 0, callback = function(v) VS.minDist = v end })
    vd:slider({ name = "Max Distance", min = 10, max = 500000, interval = 1, default = 50000, callback = function(v) VS.maxDist = v end })
    vd:slider({ name = "X+", min = 0, max = 50000, interval = 1, default = 5000, callback = function(v) VS.xp = v end })
    vd:slider({ name = "X-", min = 0, max = 50000, interval = 1, default = 5000, callback = function(v) VS.xn = v end })
    vd:slider({ name = "Y+", min = 0, max = 50000, interval = 1, default = 5000, callback = function(v) VS.yp = v end })
    vd:slider({ name = "Y-", min = 0, max = 50000, interval = 1, default = 5000, callback = function(v) VS.yn = v end })
    vd:slider({ name = "Z+", min = 0, max = 50000, interval = 1, default = 5000, callback = function(v) VS.zp = v end })
    vd:slider({ name = "Z-", min = 0, max = 50000, interval = 1, default = 5000, callback = function(v) VS.zn = v end })
end

-- ============================================================
-- PATTERNS TAB (more patterns + emergency stop)
-- ============================================================
do
    local colPat = makeColumn(tabs[6].content)
    local PAT = { pattern="random", axisX=false, axisY=false, axisZ=false, smooth=false, smoothAlpha=0.5 }
    local vp = colPat:section({ name = "More Patterns" })
    vp:dropdown({ name = "Pattern Settings", default = "random",
        items = { 'random','spiral','wave','bounce','chaos','cross','helix','strobe','rhombus','infinity','flower','butterfly','tornado','heart','hexagon','octagon','star','crescent','vortex' },
        callback = function(v) PAT.pattern = v end })
    vp:toggle({ name = "Axis X", default = false, callback = function(v) PAT.axisX = v end })
    vp:toggle({ name = "Axis Y", default = false, callback = function(v) PAT.axisY = v end })
    vp:toggle({ name = "Axis Z", default = false, callback = function(v) PAT.axisZ = v end })
    vp:toggle({ name = "Smooth Mode", default = false, callback = function(v) PAT.smooth = v end })
    vp:slider({ name = "Smoothness", min = 1, max = 100, interval = 1, default = 50, callback = function(v) PAT.smoothAlpha = v / 100 end })

    local stop = colPat:section({ name = "Emergency Stop" })
    stop:button({ name = "Stop all Rage features", callback = function()
        for _, key in ipairs({"aim_enabled","silent_enabled","trigger_enabled","auto_shoot","hitbox_enabled","cross_enabled"}) do
            combat[key] = false
        end
        pcall(function() combat.aim_target = nil end)
        pcall(function() combat.silent_target = nil end)
        pcall(function() cachedSilentTarget = nil end)
        pcall(function() stopAllBypass() end)
    end })
end

-- ============================================================
-- VISUALS TAB (ESP + ViewModel features from SCRIPT 2)
-- ============================================================
do
    local colV = makeColumn(tabs[7].content)

    -- Font map (standard Roblox fonts)
    local ESP_FONTS = {
        ["Arial"] = Enum.Font.Arial,
        ["Arial Bold"] = Enum.Font.ArialBold,
        ["Gotham"] = Enum.Font.Gotham,
        ["Gotham Bold"] = Enum.Font.GothamBold,
        ["Gotham Black"] = Enum.Font.GothamBlack,
        ["Source Sans"] = Enum.Font.SourceSans,
        ["Source Sans Bold"] = Enum.Font.SourceSansBold,
        ["Code"] = Enum.Font.Code,
        ["Roboto"] = Enum.Font.Roboto,
        ["Roboto Mono"] = Enum.Font.RobotoMono,
        ["Ubuntu"] = Enum.Font.Ubuntu,
        ["Antique"] = Enum.Font.Antique,
        ["Fantasy"] = Enum.Font.Fantasy,
        ["SciFi"] = Enum.Font.SciFi,
    }
    local ESP_FONT_KEYS = {}
    for k in pairs(ESP_FONTS) do ESP_FONT_KEYS[#ESP_FONT_KEYS + 1] = k end
    table.sort(ESP_FONT_KEYS)

    -- -------- Player ESP (main) --------
    local espSec = colV:section({ name = "Player ESP" })
    espSec:toggle({ name = "Enable ESP", default = false, callback = function(v) esp.enabled = v end })
    espSec:toggle({ name = "Team check", default = false, callback = function(v) esp.teamCheck = v end })
    espSec:toggle({ name = "Infinite max distance", default = false, callback = function(v) esp.infiniteMaxDist = v end })
    espSec:slider({ name = "Max distance", min = 100, max = 5000, interval = 50, default = 2000, suffix = " studs", callback = function(v) esp.maxDist = v end })
    espSec:dropdown({ name = "Font", items = ESP_FONT_KEYS, default = "Gotham Bold", callback = function(v) esp.font = ESP_FONTS[v] or Enum.Font.GothamBold end })
    espSec:slider({ name = "Text size", min = 8, max = 24, interval = 1, default = 13, callback = function(v) esp.textSize = v end })
    espSec:toggle({ name = "Typewriter animation", default = false, callback = function(v) esp.textAnimation = v end })
    espSec:slider({ name = "Typewriter speed", min = 1, max = 200, interval = 1, default = 30, callback = function(v) esp.textAnimationSpeed = v end })
    espSec:toggle({ name = "Tracers", default = true, callback = function(v) esp.tracer = v end })
    espSec:dropdown({ name = "Tracer color", items = PRESET_KEYS, default = "Accent", callback = function(v) esp.tracerColor = PRESET_COLORS[v] or esp.tracerColor end })

    -- -------- Box --------
    local boxSec = colV:section({ name = "Box" })
    boxSec:toggle({ name = "Enable box", default = true, callback = function(v) esp.box.enabled = v end })
    boxSec:dropdown({ name = "Mode", items = { "Full", "Corner" }, default = "Full", callback = function(v) esp.box.mode = v end })
    boxSec:slider({ name = "Thickness", min = 1, max = 6, interval = 1, default = 1, callback = function(v) esp.box.thickness = v end })
    boxSec:slider({ name = "Transparency", min = 0, max = 1, interval = 0.05, default = 0, callback = function(v) esp.box.transparency = v end })
    boxSec:toggle({ name = "Animated gradient", default = false, callback = function(v) esp.box.animated = v end })
    boxSec:slider({ name = "Animation speed", min = 0.1, max = 5, interval = 0.1, default = 1, callback = function(v) esp.box.animationSpeed = v end })
    boxSec:slider({ name = "Corner length", min = 4, max = 60, interval = 1, default = 12, callback = function(v) esp.box.cornerLength = v end })
    boxSec:slider({ name = "Corner thickness", min = 1, max = 6, interval = 1, default = 1, callback = function(v) esp.box.cornerThickness = v end })
    boxSec:dropdown({ name = "Color 1", items = PRESET_KEYS, default = "Cyan", callback = function(v) esp.box.color1 = PRESET_COLORS[v] or esp.box.color1 end })
    boxSec:dropdown({ name = "Color 2", items = PRESET_KEYS, default = "Pink", callback = function(v) esp.box.color2 = PRESET_COLORS[v] or esp.box.color2 end })

    -- -------- Box Fill --------
    local fillSec = colV:section({ name = "Box Fill" })
    fillSec:toggle({ name = "Enable box fill", default = false, callback = function(v) esp.boxFill.enabled = v end })
    fillSec:slider({ name = "Transparency", min = 0, max = 1, interval = 0.05, default = 0.9, callback = function(v) esp.boxFill.transparency = v end })
    fillSec:toggle({ name = "Animated gradient", default = false, callback = function(v) esp.boxFill.animated = v end })
    fillSec:slider({ name = "Animation speed", min = 0.1, max = 5, interval = 0.1, default = 1, callback = function(v) esp.boxFill.animationSpeed = v end })
    fillSec:dropdown({ name = "Color 1", items = PRESET_KEYS, default = "Cyan", callback = function(v) esp.boxFill.color1 = PRESET_COLORS[v] or esp.boxFill.color1 end })
    fillSec:dropdown({ name = "Color 2", items = PRESET_KEYS, default = "Blue", callback = function(v) esp.boxFill.color2 = PRESET_COLORS[v] or esp.boxFill.color2 end })

    -- -------- Health Bar --------
    local hbSec = colV:section({ name = "Health Bar" })
    hbSec:toggle({ name = "Enable health bar", default = true, callback = function(v) esp.healthBar.enabled = v end })
    hbSec:slider({ name = "Width", min = 1, max = 8, interval = 1, default = 1, callback = function(v) esp.healthBar.width = v end })
    hbSec:slider({ name = "Offset", min = 0, max = 20, interval = 1, default = 5, callback = function(v) esp.healthBar.offset = v end })
    hbSec:toggle({ name = "Show text", default = true, callback = function(v) esp.healthBar.showText = v end })
    hbSec:toggle({ name = "Smooth decay", default = true, callback = function(v) esp.healthBar.smoothDecay = v end })
    hbSec:toggle({ name = "Dynamic color", default = true, callback = function(v) esp.healthBar.useDynamicColor = v end })
    hbSec:dropdown({ name = "Color 1", items = PRESET_KEYS, default = "Green", callback = function(v) esp.healthBar.color1 = PRESET_COLORS[v] or esp.healthBar.color1 end })
    hbSec:dropdown({ name = "Color 2", items = PRESET_KEYS, default = "Pink", callback = function(v) esp.healthBar.color2 = PRESET_COLORS[v] or esp.healthBar.color2 end })

    -- -------- Name & Distance --------
    local nameSec = colV:section({ name = "Name & Distance" })
    nameSec:toggle({ name = "Show name", default = true, callback = function(v) esp.name.enabled = v end })
    nameSec:toggle({ name = "Name animated", default = false, callback = function(v) esp.name.animated = v end })
    nameSec:slider({ name = "Name anim speed", min = 0.1, max = 5, interval = 0.1, default = 1, callback = function(v) esp.name.animationSpeed = v end })
    nameSec:dropdown({ name = "Name color 1", items = PRESET_KEYS, default = "White", callback = function(v) esp.name.color1 = PRESET_COLORS[v] or esp.name.color1 end })
    nameSec:dropdown({ name = "Name color 2", items = PRESET_KEYS, default = "Pink", callback = function(v) esp.name.color2 = PRESET_COLORS[v] or esp.name.color2 end })
    nameSec:toggle({ name = "Show distance", default = true, callback = function(v) esp.distance.enabled = v end })
    nameSec:toggle({ name = "Distance animated", default = false, callback = function(v) esp.distance.animated = v end })
    nameSec:slider({ name = "Distance anim speed", min = 0.1, max = 5, interval = 0.1, default = 1, callback = function(v) esp.distance.animationSpeed = v end })
    nameSec:dropdown({ name = "Distance color 1", items = PRESET_KEYS, default = "White", callback = function(v) esp.distance.color1 = PRESET_COLORS[v] or esp.distance.color1 end })
    nameSec:dropdown({ name = "Distance color 2", items = PRESET_KEYS, default = "Pink", callback = function(v) esp.distance.color2 = PRESET_COLORS[v] or esp.distance.color2 end })

    -- -------- Weapon & Ammo --------
    local weapSec = colV:section({ name = "Weapon & Ammo" })
    weapSec:toggle({ name = "Show weapon name", default = false, callback = function(v) esp.weapon.enabled = v end })
    weapSec:toggle({ name = "Weapon animated", default = false, callback = function(v) esp.weapon.animated = v end })
    weapSec:slider({ name = "Weapon anim speed", min = 0.1, max = 5, interval = 0.1, default = 1, callback = function(v) esp.weapon.animationSpeed = v end })
    weapSec:dropdown({ name = "Weapon color 1", items = PRESET_KEYS, default = "White", callback = function(v) esp.weapon.color1 = PRESET_COLORS[v] or esp.weapon.color1 end })
    weapSec:dropdown({ name = "Weapon color 2", items = PRESET_KEYS, default = "Pink", callback = function(v) esp.weapon.color2 = PRESET_COLORS[v] or esp.weapon.color2 end })
    weapSec:toggle({ name = "Show weapon icon", default = false, callback = function(v) esp.weaponIcon.enabled = v end })
    weapSec:slider({ name = "Icon scale", min = 0.5, max = 2, interval = 0.1, default = 1, callback = function(v) esp.weaponIcon.scale = v end })
    weapSec:toggle({ name = "Show ammo", default = false, callback = function(v) esp.ammo.enabled = v end })
    weapSec:toggle({ name = "Ammo animated", default = false, callback = function(v) esp.ammo.animated = v end })
    weapSec:slider({ name = "Ammo anim speed", min = 0.1, max = 5, interval = 0.1, default = 1, callback = function(v) esp.ammo.animationSpeed = v end })
    weapSec:dropdown({ name = "Ammo color 1", items = PRESET_KEYS, default = "Yellow", callback = function(v) esp.ammo.color1 = PRESET_COLORS[v] or esp.ammo.color1 end })
    weapSec:dropdown({ name = "Ammo color 2", items = PRESET_KEYS, default = "Green", callback = function(v) esp.ammo.color2 = PRESET_COLORS[v] or esp.ammo.color2 end })

    -- -------- Reload indicator --------
    local reloadSec = colV:section({ name = "Reload Indicator" })
    reloadSec:toggle({ name = "Show reload indicator", default = false, callback = function(v) esp.reload.enabled = v end })
    reloadSec:toggle({ name = "Animated dots", default = true, callback = function(v) esp.reload.animated = v end })
    reloadSec:dropdown({ name = "Reload color", items = PRESET_KEYS, default = "Magenta", callback = function(v) esp.reload.color = PRESET_COLORS[v] or esp.reload.color end })

    -- ============================================================
    -- VIEWMODEL FEATURES (from SCRIPT 2)
    -- Gun Material · Gun Highlight · Arm Chams · Arm Highlight
    -- ============================================================
    local vmState = {
        gunMat = {
            enabled = false,
            material = "Neon",
            colorMode = "solid",
            color = Color3.fromRGB(255, 255, 255),
            color2 = Color3.fromRGB(120, 81, 166),
            colorMiddle = Color3.fromRGB(188, 168, 211),
            gradientAxis = "length",
            cycleSpeed = 1,
        },
        gunHL = {
            enabled = false,
            fillColor = Color3.new(1, 1, 1),
            fillTransparency = 0.5,
            outlineColor = Color3.new(1, 1, 1),
            outlineTransparency = 0,
            above = false,
        },
        armChams = {
            enabled = false,
            material = "Neon",
            color = Color3.fromRGB(255, 0, 255),
            transparency = 0,
            above = false,
        },
        armHL = {
            enabled = false,
            fillColor = Color3.fromRGB(255, 0, 255),
            fillTransparency = 0.5,
            outlineColor = Color3.fromRGB(255, 255, 0),
            outlineTransparency = 0,
        },
    }

    local VM_MATERIALS = {
        "SmoothPlastic","Neon","Glass","ForceField","Metal","CorrodedMetal","DiamondPlate","Foil",
        "Wood","WoodPlanks","Marble","Slate","Concrete","Granite","Brick","Pebble","Cobblestone",
        "Rock","Sandstone","Basalt","Grass","LeafyGrass","Sand","Fabric","Snow","Ice","Mud","Ground","Asphalt",
    }

    local ARM_PART_NAMES = {
        ["LeftArm"]=true,["RightArm"]=true,["LeftArmWrapped"]=true,["RightArmWrapped"]=true,
        ["Left Arm"]=true,["Right Arm"]=true,
        ["LeftUpperArm"]=true,["RightUpperArm"]=true,
        ["LeftLowerArm"]=true,["RightLowerArm"]=true,
        ["LeftHand"]=true,["RightHand"]=true,
    }
    local function isArmPart(part)
        if ARM_PART_NAMES[part.Name] then return true end
        local n = part.Name
        return (n:find("Arm") or n:find("Hand") or n:find("Wrist")) ~= nil
    end

    -- Per-part snapshot helpers (attributes)
    local function snapshotPart(part, prefix)
        if part:GetAttribute(prefix.."_snap") then return end
        part:SetAttribute(prefix.."_snap", true)
        part:SetAttribute(prefix.."_mat", part.Material.Name)
        part:SetAttribute(prefix.."_col", part.Color:ToHex())
        part:SetAttribute(prefix.."_trans", part.Transparency)
    end
    local function restorePart(part, prefix)
        if not part:GetAttribute(prefix.."_snap") then return end
        local mat = part:GetAttribute(prefix.."_mat")
        local col = part:GetAttribute(prefix.."_col")
        local trans = part:GetAttribute(prefix.."_trans")
        if mat then pcall(function() part.Material = Enum.Material[mat] end) end
        if col then pcall(function() part.Color = Color3.fromHex(col) end) end
        if trans ~= nil then part.Transparency = trans end
        part:SetAttribute(prefix.."_snap", nil)
        part:SetAttribute(prefix.."_mat", nil)
        part:SetAttribute(prefix.."_col", nil)
        part:SetAttribute(prefix.."_trans", nil)
    end

    -- Highlight tracking
    local gunHLInstance = nil
    local armHLInstances = {}
    local function clearGunHighlight()
        if gunHLInstance then pcall(function() gunHLInstance:Destroy() end); gunHLInstance = nil end
    end
    local function clearArmHighlights()
        for _, h in pairs(armHLInstances) do pcall(function() h:Destroy() end) end
        armHLInstances = {}
    end

    -- Retry-aware FC getter (independent of Chunk 2's _espModCache)
    local vmFC, vmFCTriedAt = nil, 0
    local function vmGetFC()
        if vmFC then return vmFC end
        if tick() - vmFCTriedAt < 2 then return nil end
        vmFCTriedAt = tick()
        local ok, m = pcall(function()
            local c = LP.PlayerScripts:FindFirstChild("Controllers")
            return c and require(c.FighterController)
        end)
        if ok and m then vmFC = m; return m end
        return nil
    end

    -- ---- Render loop for all 4 ViewModel features ----
    RunSvc.RenderStepped:Connect(function(dt)
        local FC = vmGetFC()
        if not FC then
            clearGunHighlight()
            clearArmHighlights()
            return
        end
        local lf = FC.LocalFighter
        if not lf or not lf.EquippedItem then
            clearGunHighlight()
            clearArmHighlights()
            return
        end
        local item = lf.EquippedItem
        local vm = item.ViewModel
        if not vm or not vm.ItemModel then
            clearGunHighlight()
            clearArmHighlights()
            return
        end
        local itemModel = vm.ItemModel
        local armsRoot = itemModel.Parent or itemModel

        -- ==== Gun Material ====
        if vmState.gunMat.enabled then
            local pivot = itemModel:GetPivot()
            local matEnum = Enum.Material[vmState.gunMat.material] or Enum.Material.Neon
            local mode = vmState.gunMat.colorMode
            local c1, c2, cMid = vmState.gunMat.color, vmState.gunMat.color2, vmState.gunMat.colorMiddle
            local axis = vmState.gunMat.gradientAxis
            local cycleSpeed = vmState.gunMat.cycleSpeed or 1
            for _, part in ipairs(itemModel:GetDescendants()) do
                if part:IsA("BasePart") then
                    snapshotPart(part, "gm")
                    pcall(function() part.Material = matEnum end)
                    if mode == "solid" then
                        part.Color = c1
                    elseif mode == "gradient" then
                        local lp = pivot:PointToObjectSpace(part.Position)
                        local t
                        if axis == "width" then t = (lp.X + 3) / 6
                        elseif axis == "height" then t = (lp.Y + 3) / 6
                        else t = (lp.Z + 5) / 10 end
                        t = math.clamp(t, 0, 1)
                        local mid = cMid or c1:Lerp(c2, 0.5)
                        if t < 0.5 then part.Color = c1:Lerp(mid, t * 2)
                        else part.Color = mid:Lerp(c2, (t - 0.5) * 2) end
                    elseif mode == "cycle" then
                        local hue = (tick() * cycleSpeed * 0.15) % 1
                        part.Color = Color3.fromHSV(hue, 1, 1)
                    end
                end
            end
        else
            for _, part in ipairs(itemModel:GetDescendants()) do
                if part:IsA("BasePart") then restorePart(part, "gm") end
            end
        end

        -- ==== Gun Highlight ====
        if vmState.gunHL.enabled then
            if not gunHLInstance or gunHLInstance.Parent ~= itemModel then
                clearGunHighlight()
                gunHLInstance = Instance.new("Highlight")
                gunHLInstance.Name = "Pet_GunHighlight"
                gunHLInstance.Adornee = itemModel
                gunHLInstance.Parent = itemModel
            end
            gunHLInstance.FillColor = vmState.gunHL.fillColor
            gunHLInstance.FillTransparency = vmState.gunHL.fillTransparency
            gunHLInstance.OutlineColor = vmState.gunHL.outlineColor
            gunHLInstance.OutlineTransparency = vmState.gunHL.outlineTransparency
            gunHLInstance.DepthMode = vmState.gunHL.above and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        else
            clearGunHighlight()
        end

        -- ==== Collect arm parts ====
        local armParts = {}
        if armsRoot and armsRoot ~= workspace then
            for _, d in ipairs(armsRoot:GetDescendants()) do
                if d:IsA("BasePart") and isArmPart(d) and not d:IsDescendantOf(itemModel) then
                    armParts[#armParts + 1] = d
                end
            end
        end

        -- ==== Arm Chams ====
        if vmState.armChams.enabled then
            local matEnum = Enum.Material[vmState.armChams.material] or Enum.Material.Neon
            for _, part in ipairs(armParts) do
                snapshotPart(part, "ac")
                pcall(function() part.Material = matEnum end)
                part.Color = vmState.armChams.color
                part.Transparency = vmState.armChams.transparency
            end
        else
            for _, part in ipairs(armParts) do restorePart(part, "ac") end
        end

        -- ==== Arm Highlight (also doubles as Arm Chams "Above" passthrough) ====
        local useHL = vmState.armHL.enabled or (vmState.armChams.enabled and vmState.armChams.above)
        if useHL then
            local dColor, dFill, dOutline, dTrans, dAbove
            if vmState.armHL.enabled then
                dColor, dFill = vmState.armHL.fillColor, vmState.armHL.fillTransparency
                dOutline, dTrans = vmState.armHL.outlineColor, vmState.armHL.outlineTransparency
                dAbove = false
            else
                dColor, dFill = vmState.armChams.color, vmState.armChams.transparency
                dOutline, dTrans = vmState.armChams.color, 1
                dAbove = true
            end
            for _, part in ipairs(armParts) do
                local h = armHLInstances[part]
                if not h or h.Parent ~= part then
                    if h then pcall(function() h:Destroy() end) end
                    h = Instance.new("Highlight")
                    h.Name = "Pet_ArmHL"
                    h.Adornee = part
                    h.Parent = part
                    armHLInstances[part] = h
                end
                h.FillColor = dColor
                h.FillTransparency = dFill
                h.OutlineColor = dOutline
                h.OutlineTransparency = dTrans
                h.DepthMode = dAbove and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            end
            -- Cleanup orphaned
            for part, h in pairs(armHLInstances) do
                if not part.Parent then pcall(function() h:Destroy() end); armHLInstances[part] = nil end
            end
        else
            clearArmHighlights()
        end
    end)

    -- ---- UI: Gun Material ----
    local gmSec = colV:section({ name = "Gun Material" })
    gmSec:toggle({ name = "Enable Gun Material", default = false, callback = function(v) vmState.gunMat.enabled = v end })
    gmSec:dropdown({ name = "Material", items = VM_MATERIALS, default = "Neon", callback = function(v) vmState.gunMat.material = v end })
    gmSec:dropdown({ name = "Color Mode", items = {"solid","gradient","cycle"}, default = "solid", callback = function(v) vmState.gunMat.colorMode = v end })
    gmSec:dropdown({ name = "Color 1", items = PRESET_KEYS, default = "White", callback = function(v) vmState.gunMat.color = PRESET_COLORS[v] or vmState.gunMat.color end })
    gmSec:dropdown({ name = "Color 2", items = PRESET_KEYS, default = "Purple", callback = function(v) vmState.gunMat.color2 = PRESET_COLORS[v] or vmState.gunMat.color2 end })
    gmSec:dropdown({ name = "Color Middle", items = PRESET_KEYS, default = "Purple", callback = function(v) vmState.gunMat.colorMiddle = PRESET_COLORS[v] or vmState.gunMat.colorMiddle end })
    gmSec:dropdown({ name = "Gradient Axis", items = {"length","width","height"}, default = "length", callback = function(v) vmState.gunMat.gradientAxis = v end })
    gmSec:slider({ name = "Cycle Speed", min = 0.1, max = 5, interval = 0.1, default = 1, callback = function(v) vmState.gunMat.cycleSpeed = v end })

    -- ---- UI: Gun Highlight ----
    local ghSec = colV:section({ name = "Gun Highlight" })
    ghSec:toggle({ name = "Enable Gun Highlight", default = false, callback = function(v) vmState.gunHL.enabled = v end })
    ghSec:dropdown({ name = "Fill Color", items = PRESET_KEYS, default = "White", callback = function(v) vmState.gunHL.fillColor = PRESET_COLORS[v] or vmState.gunHL.fillColor end })
    ghSec:slider({ name = "Fill Transparency", min = 0, max = 1, interval = 0.05, default = 0.5, callback = function(v) vmState.gunHL.fillTransparency = v end })
    ghSec:dropdown({ name = "Outline Color", items = PRESET_KEYS, default = "White", callback = function(v) vmState.gunHL.outlineColor = PRESET_COLORS[v] or vmState.gunHL.outlineColor end })
    ghSec:slider({ name = "Outline Transparency", min = 0, max = 1, interval = 0.05, default = 0, callback = function(v) vmState.gunHL.outlineTransparency = v end })
    ghSec:toggle({ name = "Render Above (through walls)", default = false, callback = function(v) vmState.gunHL.above = v end })

    -- ---- UI: Arm Chams ----
    local acSec = colV:section({ name = "Arm Chams" })
    acSec:toggle({ name = "Enable Arm Chams", default = false, callback = function(v) vmState.armChams.enabled = v end })
    acSec:dropdown({ name = "Material", items = VM_MATERIALS, default = "Neon", callback = function(v) vmState.armChams.material = v end })
    acSec:dropdown({ name = "Color", items = PRESET_KEYS, default = "Magenta", callback = function(v) vmState.armChams.color = PRESET_COLORS[v] or vmState.armChams.color end })
    acSec:slider({ name = "Transparency", min = 0, max = 1, interval = 0.05, default = 0, callback = function(v) vmState.armChams.transparency = v end })
    acSec:toggle({ name = "Render Above (through walls)", default = false, callback = function(v) vmState.armChams.above = v end })

    -- ---- UI: Arm Highlight ----
    local ahSec = colV:section({ name = "Arm Highlight" })
    ahSec:toggle({ name = "Enable Arm Highlight", default = false, callback = function(v) vmState.armHL.enabled = v end })
    ahSec:dropdown({ name = "Fill Color", items = PRESET_KEYS, default = "Magenta", callback = function(v) vmState.armHL.fillColor = PRESET_COLORS[v] or vmState.armHL.fillColor end })
    ahSec:slider({ name = "Fill Transparency", min = 0, max = 1, interval = 0.05, default = 0.5, callback = function(v) vmState.armHL.fillTransparency = v end })
    ahSec:dropdown({ name = "Outline Color", items = PRESET_KEYS, default = "Yellow", callback = function(v) vmState.armHL.outlineColor = PRESET_COLORS[v] or vmState.armHL.outlineColor end })
    ahSec:slider({ name = "Outline Transparency", min = 0, max = 1, interval = 0.05, default = 0, callback = function(v) vmState.armHL.outlineTransparency = v end })

    -- -------- Chams --------
    local chamsSec = colV:section({ name = "Chams" })
    chamsSec:toggle({ name = "Enable Chams", default = false, callback = function(v) chams.enabled = v end })
    chamsSec:toggle({ name = "Team check", default = true, callback = function(v) chams.teamCheck = v end })
    chamsSec:slider({ name = "Fill transparency", min = 0, max = 100, interval = 1, default = 50, callback = function(v) chams.fillTransparency = v / 100 end })
    chamsSec:dropdown({ name = "Fill color", items = PRESET_KEYS, default = "Red", callback = function(v) chams.fillColor = PRESET_COLORS[v] or chams.fillColor end })
    chamsSec:dropdown({ name = "Outline color", items = PRESET_KEYS, default = "White", callback = function(v) chams.outlineColor = PRESET_COLORS[v] or chams.outlineColor end })

    -- -------- World --------
    local Lighting = game:GetService("Lighting")
    local orig = { Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
                   Brightness = Lighting.Brightness, FogEnd = Lighting.FogEnd }
    local worldSec = colV:section({ name = "World" })
    worldSec:toggle({ name = "Fullbright", default = false, callback = function(v)
        if v then
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            Lighting.Brightness = 2
        else
            Lighting.Ambient = orig.Ambient
            Lighting.OutdoorAmbient = orig.OutdoorAmbient
            Lighting.Brightness = orig.Brightness
        end
    end })
    worldSec:toggle({ name = "No fog", default = false, callback = function(v)
        Lighting.FogEnd = v and 1e6 or orig.FogEnd
    end })
    worldSec:slider({ name = "Camera FOV", min = 40, max = 130, interval = 1, default = 70, callback = function(v)
        local c = workspace.CurrentCamera
        if c then c.FieldOfView = v end
    end })

    -- -------- Cleanup --------
    local miscSec = colV:section({ name = "Cleanup" })
    miscSec:button({ name = "Clear all Visuals", callback = function()
        esp.enabled = false
        for _, f in pairs(espFrames) do
            pcall(function() f.Holder:Destroy() end)
            pcall(function() f.Tracer:Destroy() end)
        end
        espFrames = {}
        chams.enabled = false
        for _, h in pairs(chamsHighlights) do pcall(function() h:Destroy() end) end
        chamsHighlights = {}
        -- Reset all ViewModel features
        vmState.gunMat.enabled = false
        vmState.gunHL.enabled = false
        vmState.armChams.enabled = false
        vmState.armHL.enabled = false
        clearGunHighlight()
        clearArmHighlights()
    end })
end

-- END OF REPLACEMENT CHUNK 9 --
-- ============================================================
-- ORBIT TAB
-- ============================================================
do
    local colO = makeColumn(tabs[9].content)
    xpcall(function()
        local cfg = { speed=500, distance=5, height=-4, maxDistance=800, useDesync=false }
        local S = { on=false, conn=nil, charConn=nil, diedConn=nil, lastAngle=0, lastPos=nil,
                    targetReady=false, lobbyLeft=0, cooldown=0, client=nil, renderBound=false }
        local RENDER_NAME = "SniflvaOrbitSimpleDesync"

        local function getRoot(char)
            return char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
        end
        local function alive(char)
            local h = char and char:FindFirstChildOfClass("Humanoid")
            return h ~= nil and h.Health > 0
        end
        local function inLobby()
            local ok, res = pcall(function()
                local gui = LP:FindFirstChild("PlayerGui")
                local main = gui and gui:FindFirstChild("MainGui")
                local frame = main and main:FindFirstChild("MainFrame")
                local lobby = frame and frame:FindFirstChild("Lobby")
                local currency = lobby and lobby:FindFirstChild("Currency")
                return currency and currency.Visible
            end)
            return ok and res == true
        end
        local function resetState() S.client = nil; S.targetReady = false; S.lobbyLeft = 0 end
        local function stopRender()
            if S.renderBound then pcall(function() RunSvc:UnbindFromRenderStep(RENDER_NAME) end); S.renderBound = false end
        end
        local function startRender()
            stopRender(); S.renderBound = true
            RunSvc:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.First.Value, function()
                if not (cfg.useDesync and S.on) then return end
                if S.cooldown > tick() then return end
                local char = LP.Character; if not alive(char) then return end
                local root = getRoot(char); if root and S.client then root.CFrame = S.client end
            end)
        end
        local function nearest()
            local myRoot = getRoot(LP.Character); if not myRoot then return nil end
            local best, bestD = nil, cfg.maxDistance
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP then
                    local c = plr.Character; local r = getRoot(c)
                    if r and alive(c) then
                        local d = (r.Position - myRoot.Position).Magnitude
                        if d < bestD then bestD = d; best = plr end
                    end
                end
            end
            return best
        end
        local function hookChar(char)
            S.lastPos = nil
            if S.diedConn then pcall(function() S.diedConn:Disconnect() end); S.diedConn = nil end
            local hum = char and char:WaitForChild("Humanoid", 5)
            if not hum or not S.on then return end
            if cfg.useDesync then startRender() end
            S.diedConn = hum.Died:Connect(function() resetState() end)
        end
        local function step(dt)
            local char = LP.Character; local root = getRoot(char); if not root then return end
            if not S.lastPos then S.lastPos = root.Position
            else
                local d = (root.Position - S.lastPos).Magnitude; S.lastPos = root.Position
                if d > 80 then S.cooldown = tick() + 1.2; resetState(); return end
            end
            if S.cooldown > tick() then return end
            if inLobby() then resetState(); return end
            if not S.targetReady then
                if S.lobbyLeft == 0 then S.lobbyLeft = tick(); return end
                if tick() - S.lobbyLeft >= 1 then S.targetReady = true else return end
            end
            if not alive(char) then return end
            if cfg.useDesync then S.client = root.CFrame end
            local target = nearest()
            if target and target.Character and alive(target.Character) then
                local tr = getRoot(target.Character)
                if tr then
                    S.lastAngle = S.lastAngle + dt * cfg.speed * math.rad(360)
                    local radius = cfg.distance + math.random(-3, 3); local height = cfg.height + math.random(-6, 6)
                    local angle = S.lastAngle + math.rad(math.random(-20, 20)); local center = tr.Position
                    root.CFrame = CFrame.new(center + Vector3.new(math.cos(angle)*radius, height, math.sin(angle)*radius), center)
                end
            end
        end
        local function setOrbit(on)
            if S.conn then pcall(function() S.conn:Disconnect() end); S.conn = nil end
            if S.charConn then pcall(function() S.charConn:Disconnect() end); S.charConn = nil end
            if S.diedConn then pcall(function() S.diedConn:Disconnect() end); S.diedConn = nil end
            stopRender(); resetState()
            S.on = on and true or false
            if not S.on then return end
            S.lastPos = nil
            S.conn = RunSvc.Heartbeat:Connect(function(dt) pcall(step, dt) end)
            S.charConn = LP.CharacterAdded:Connect(function(c) task.spawn(hookChar, c) end)
            if cfg.useDesync then startRender() end
            if LP.Character then task.spawn(hookChar, LP.Character) end
        end
        local sec1 = colO:section({ name = "Orbit (Simple)" })
        sec1:toggle({ name = "Enabled", default = false, callback = function(v) setOrbit(v) end })
        sec1:toggle({ name = "Desync", default = false, callback = function(v) cfg.useDesync = v; if not v then S.client = nil; stopRender() elseif S.on then startRender() end end })
        sec1:slider({ name = "Speed", min = 100, max = 1000, interval = 1, default = 500, callback = function(v) cfg.speed = v end })
        sec1:slider({ name = "Distance", min = 3, max = 15, interval = 0.1, default = 5, callback = function(v) cfg.distance = v end })
        sec1:slider({ name = "Height", min = -10, max = 20, interval = 0.1, default = -4, callback = function(v) cfg.height = v end })
        sec1:slider({ name = "Max Distance", min = 100, max = 1500, interval = 1, default = 800, suffix = " studs", callback = function(v) cfg.maxDistance = v end })

        local orbitCfg = { enabled=false, speed=90, radius=8, height=0, smoothing=0.30, mode='Circle', predict=false, predStrength=0.20, faceTarget=true, autoLockDist=50 }
        local orbitAngle, orbitElapsed, orbitCurrentRadius = 0, 0, 8
        local orbitConn = nil
        local function getFeatureRoot() local ch = LP and LP.Character; return ch and ch:FindFirstChild('HumanoidRootPart'), ch end
        local function closestOrbitPlayer(maxDist)
            local root = getFeatureRoot(); if not root then return nil end
            local best, bestDist = nil, maxDist or math.huge
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP and plr.Character then
                    local hrp = plr.Character:FindFirstChild('HumanoidRootPart'); local hum = plr.Character:FindFirstChildOfClass('Humanoid')
                    if hrp and hum and hum.Health > 0 then
                        local d = (root.Position - hrp.Position).Magnitude
                        if d < bestDist then best, bestDist = plr, d end
                    end
                end
            end
            return best
        end
        local function startOrbitModes()
            if orbitConn then orbitConn:Disconnect(); orbitConn = nil end
            orbitAngle, orbitElapsed = 0, 0; orbitCurrentRadius = orbitCfg.radius
            orbitConn = RunSvc.Heartbeat:Connect(function(dt)
                if not orbitCfg.enabled then if orbitConn then orbitConn:Disconnect(); orbitConn = nil end return end
                local root = getFeatureRoot(); if not root then return end
                local target = closestOrbitPlayer(orbitCfg.autoLockDist); if not target or not target.Character then return end
                local hrp = target.Character:FindFirstChild('HumanoidRootPart'); if not hrp then return end
                local targetPos = hrp.Position
                if orbitCfg.predict then targetPos = targetPos + hrp.AssemblyLinearVelocity * orbitCfg.predStrength end
                orbitAngle = orbitAngle + math.rad(orbitCfg.speed) * dt; orbitElapsed = orbitElapsed + dt
                local r, h = orbitCfg.radius, orbitCfg.height; local x, y, z = 0, h, 0
                if orbitCfg.mode == 'Circle' then x, z = math.cos(orbitAngle)*r, math.sin(orbitAngle)*r
                elseif orbitCfg.mode == 'Figure 8' then x, z = math.sin(orbitAngle)*r, math.sin(orbitAngle)*math.cos(orbitAngle)*r*0.7
                elseif orbitCfg.mode == 'Spiral In' then orbitCurrentRadius = math.max(1, orbitCurrentRadius - dt*2); x, z = math.cos(orbitAngle)*orbitCurrentRadius, math.sin(orbitAngle)*orbitCurrentRadius
                elseif orbitCfg.mode == 'Spiral Out' then orbitCurrentRadius = math.min(r*2, orbitCurrentRadius + dt*2); x, z = math.cos(orbitAngle)*orbitCurrentRadius, math.sin(orbitAngle)*orbitCurrentRadius
                elseif orbitCfg.mode == 'Bounce' then x, z = math.cos(orbitAngle)*r, math.sin(orbitAngle)*r; y = h + math.sin(orbitElapsed*3)*5 end
                local dst = targetPos + Vector3.new(x,y,z); local smooth = root.Position:Lerp(dst, math.clamp(orbitCfg.smoothing, 0.01, 1))
                if orbitCfg.faceTarget then root.CFrame = CFrame.new(smooth, Vector3.new(targetPos.X, smooth.Y, targetPos.Z)) else root.CFrame = CFrame.new(smooth) end
            end)
        end
        local function stopOrbitModes() if orbitConn then orbitConn:Disconnect(); orbitConn = nil end; orbitCfg.enabled = false end
        local sec2 = colO:section({ name = "Orbit (Modes)" })
        sec2:toggle({ name = "Enable Orbit", default = false, callback = function(v) orbitCfg.enabled = v; if v then startOrbitModes() else stopOrbitModes() end end })
        sec2:dropdown({ name = "Orbit Mode", items = { 'Circle', 'Figure 8', 'Spiral In', 'Spiral Out', 'Bounce' }, default = 'Circle', callback = function(v) orbitCfg.mode = v; orbitCurrentRadius = orbitCfg.radius end })
        sec2:slider({ name = "Speed (deg/s)", min = 5, max = 720, interval = 1, default = 90, callback = function(v) orbitCfg.speed = v end })
        sec2:slider({ name = "Radius", min = 1, max = 200, interval = 1, default = 8, callback = function(v) orbitCfg.radius = v; orbitCurrentRadius = v end })
        sec2:slider({ name = "Height Offset", min = -200, max = 200, interval = 1, default = 0, callback = function(v) orbitCfg.height = v end })
        sec2:slider({ name = "Smoothing %", min = 1, max = 100, interval = 1, default = 30, callback = function(v) orbitCfg.smoothing = v / 100 end })
        local sec3 = colO:section({ name = "Orbit (Modes) Advanced" })
        sec3:toggle({ name = "Face Target", default = true, callback = function(v) orbitCfg.faceTarget = v end })
        sec3:toggle({ name = "Prediction", default = false, callback = function(v) orbitCfg.predict = v end })
        sec3:slider({ name = "Prediction Strength %", min = 0, max = 100, interval = 1, default = 20, callback = function(v) orbitCfg.predStrength = v / 100 end })
        sec3:slider({ name = "Max Auto-Lock Dist", min = 10, max = 500, interval = 1, default = 50, callback = function(v) orbitCfg.autoLockDist = v end })
    end, function(e) warn('[Orbit Tab] ' .. tostring(e)) end)
end

-- ============================================================
-- PT 9: FULL ELISIUM RAGEBOT ENGINE + DODGE FIX
-- ============================================================
do
    local colRageFull = makeColumn(tabs[3].content)
    local colEvFull = makeColumn(tabs[4].content)

    xpcall(function()
        local RS2 = game:GetService("ReplicatedStorage")
        local LP2 = Players.LocalPlayer

        -- 1. Module Loader (Won't early-return, so UI always loads)
        local Utility, EnumLib, FighterController
        task.spawn(function()
            for _ = 1, 40 do
                pcall(function()
                    if not Utility then
                        local u = RS2:FindFirstChild("Modules") and RS2.Modules:FindFirstChild("Utility")
                        if u then Utility = require(u) end
                    end
                    if not EnumLib then
                        local e = RS2:FindFirstChild("Modules") and RS2.Modules:FindFirstChild("EnumLibrary")
                        if e then EnumLib = require(e) end
                    end
                    if not FighterController and LP2.PlayerScripts then
                        local c = LP2.PlayerScripts:FindFirstChild("Controllers")
                        if c and c:FindFirstChild("FighterController") then
                            FighterController = require(c.FighterController)
                        end
                    end
                end)
                if Utility and EnumLib and FighterController then break end
                task.wait(0.5)
            end
        end)

        local UseItemRemote = nil
        pcall(function()
            local rep = RS2:FindFirstChild("Remotes") and RS2.Remotes:FindFirstChild("Replication")
            UseItemRemote = rep and rep:FindFirstChild("Fighter") and rep.Fighter:FindFirstChild("UseItem")
        end)

        -- 2. State
        local RS = {
            silent = { enabled=false, fov=180, chance=100, closest=false, team=true, wall=false, shield=false, katana=false, part="Head", showFov=false, target=nil },
            rage = { enabled=false, strategy="Orbit", attackMode="Gun", priority="Primary", hitboxPart="Head", radius=5, height=-4, orbitSpeed=500, knifeDist=3, prediction=false, predMult=1.2, swapOnEmpty=false, lastShot=0, target=nil, clientCF=nil, angle=0 },
            reposition = { enabled=false, offset=-5, originalCF=nil, applied=false },
            dodge = { enabled=false, method="lay down", rangeBuffer=3, duration=0.85, height=20, activeUntil=0, savedCF=nil },
            backstab = { enabled=false },
            block = { enabled=false, savedAutoRotate=nil, appliedHumanoid=nil },
            antiKnife = { enabled=false, range=14, retreat=18, onlyMelee=true, cool=0 },
        }

        -- 3. Helpers
        local function getMyHRP() local c = LP2.Character; return c and c:FindFirstChild("HumanoidRootPart"), c end
        local function isEnemy(plr)
            if plr == LP2 then return false end
            if plr.Team and LP2.Team and plr.Team == LP2.Team then return false end
            return true
        end
        local function isAlive(plr) local c = plr.Character; local h = c and c:FindFirstChildOfClass("Humanoid"); return h and h.Health > 0 end
        local function isImmune(plr)
            local c = plr.Character; if not c then return false end
            if c:FindFirstChildOfClass("ForceField") then return true end
            for _, a in ipairs({"IsInvincible","Immune","IsImmune","SpawnProtection"}) do
                if c:GetAttribute(a) == true or plr:GetAttribute(a) == true then return true end
            end
            return false
        end
        local function getEquipped(plr)
            local ok, r = pcall(function()
                local f = FighterController and FighterController._player_to_fighter
                local t = f and f[plr]
                return t and t.EquippedItem and t.EquippedItem.Name
            end)
            return ok and r or nil
        end
        local meleeNames = { "knife","katana","sword","axe","scythe","chainsaw","dagger","hammer","bat","spear","blade" }
        local function isMelee(n)
            n = tostring(n or ""):lower()
            for _, k in ipairs(meleeNames) do if n:find(k,1,true) then return true end end
            return false
        end
        local function hasShield(plr)
            local vm = workspace:FindFirstChild("ViewModels")
            return vm and vm:FindFirstChild(plr.Name.." - Riot Shield - Riot Shield") ~= nil
        end
        local function passesChecks(plr, cfg, part)
            if cfg.katana and getEquipped(plr) == "Katana" then return false end
            if cfg.shield and hasShield(plr) then return false end
            if cfg.wall and cam then
                local hit = workspace:FindPartOnRayWithIgnoreList(Ray.new(cam.CFrame.Position, part.Position - cam.CFrame.Position), {LP2.Character, part.Parent})
                if hit then return false end
            end
            return true
        end

        -- 4. Target Picking
        local function pickTarget(cfg)
            if not cam then return nil end
            local mouse = UIS:GetMouseLocation(); local center = cam.ViewportSize * 0.5
            local best, bestDist = nil, cfg.fov
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP2 and isEnemy(plr) and isAlive(plr) and not isImmune(plr) then
                    local char = plr.Character
                    local part = char:FindFirstChild(cfg.part) or char:FindFirstChild("HumanoidRootPart")
                    if part and passesChecks(plr, cfg, part) then
                        local sp, on = cam:WorldToViewportPoint(part.Position)
                        if on then
                            local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if d < bestDist then
                                bestDist = d
                                best = { player=plr, part=part, char=char, hum=char:FindFirstChildOfClass("Humanoid") }
                            end
                        end
                    end
                end
            end
            return best
        end

        -- 5. Silent Aim Hook
        RunSvc.RenderStepped:Connect(function()
            if not RS.silent.enabled then return end
            RS.silent.target = pickTarget(RS.silent)
        end)

        local GunMod
        pcall(function() GunMod = require(LP2.PlayerScripts.Modules.ItemTypes.Gun) end)
        if GunMod and GunMod.StartShooting then
            local oldStart = GunMod.StartShooting
            GunMod.StartShooting = function(self, ...)
                local ret = oldStart(self, ...)
                if RS.silent.enabled and self.ClientFighter and self.ClientFighter.IsLocalPlayer and RS.silent.target then
                    local t = RS.silent.target
                    if t.part and t.part.Parent and math.random(1,100) <= RS.silent.chance then
                        pcall(function()
                            local lf = FighterController.LocalFighter
                            if lf and lf.EquippedItem and UseItemRemote then
                                local origin = cam.CFrame
                                local aimCF = CFrame.lookAt(origin.Position, t.part.Position)
                                local offset = t.part.CFrame:ToObjectSpace(CFrame.new(t.part.Position))
                                local eAim = Utility:EncodeCFrame(aimCF)
                                local ePart = Utility:EncodeCFrame(t.part.CFrame)
                                local eOff = Utility:EncodeCFrame(offset)
                                local data = { [utf8.char(1)] = { [utf8.char(0)]=eAim, [utf8.char(1)]=ePart, [utf8.char(2)]=t.part, [utf8.char(3)]=eOff } }
                                UseItemRemote:FireServer(lf.EquippedItem:Get("ObjectID"), EnumLib:ToEnum("StartShooting"), data, nil)
                            end
                        end)
                    end
                end
                return ret
            end
        end

        -- 6. Ragebot Engine
        local function getHitbox(char, name)
            local p = char:FindFirstChild(name); return (p and p:IsA("BasePart")) and p or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        end
        RunSvc.Heartbeat:Connect(function()
            if not RS.rage.enabled then if RS.rage.clientCF then local r = getMyHRP(); if r then r.CFrame = RS.rage.clientCF end RS.rage.clientCF = nil end return end
            local hrp = getMyHRP(); local lf = FighterController and FighterController.LocalFighter
            if not hrp or not lf then return end
            
            local bestT, bestD = nil, math.huge
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP2 and isEnemy(plr) and isAlive(plr) and not isImmune(plr) then
                    local t = plr.Character:FindFirstChild("HumanoidRootPart")
                    if t then local d = (t.Position - hrp.Position).Magnitude; if d < bestD then bestD = d; bestT = plr end end
                end
            end
            if not bestT then return end
            local tRoot = bestT.Character:FindFirstChild("HumanoidRootPart")
            local tPart = getHitbox(bestT.Character, RS.rage.hitboxPart)
            
            -- Weapon swap
            local mode = RS.rage.attackMode
            local desired = mode == "Melee" and 3 or (RS.rage.priority == "Secondary" and 2 or 1)
            local curIdx = lf.EquippedItem and lf.EquippedItem:Get("ItemIndex")
            if curIdx ~= desired then pcall(function() lf:EquipItem(desired) end); return end
            
            -- Teleport/Orbit
            local hum = LP2.Character and LP2.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Physics then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end) end
            
            local offset = Vector3.zero
            if RS.rage.strategy == "Orbit" then
                RS.rage.angle = (RS.rage.angle + tick() * RS.rage.orbitSpeed / 100) % (math.pi*2)
                offset = Vector3.new(math.cos(RS.rage.angle)*RS.rage.radius, RS.rage.height, math.sin(RS.rage.angle)*RS.rage.radius)
            else
                offset = Vector3.new(0, RS.rage.height, 0)
                if mode == "Knife" then offset = -tRoot.CFrame.LookVector * RS.rage.knifeDist end
            end
            
            local dest = tRoot.Position + offset
            if RS.rage.prediction then dest = dest + tRoot.AssemblyLinearVelocity * (RS.rage.predMult * 0.15) end
            
            if not RS.rage.clientCF then RS.rage.clientCF = hrp.CFrame end
            hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero
            pcall(function() hrp.CFrame = CFrame.new(dest) end)
            
            -- Fire
            if mode ~= "Knife" and tick() - RS.rage.lastShot > 0.05 then
                RS.rage.lastShot = tick()
                pcall(function()
                    local origin = CFrame.new(dest)
                    local aimCF = CFrame.lookAt(origin.Position, tPart.Position)
                    local offset2 = tPart.CFrame:ToObjectSpace(CFrame.new(tPart.Position))
                    local data = { [utf8.char(1)] = { [utf8.char(0)]=Utility:EncodeCFrame(aimCF), [utf8.char(1)]=Utility:EncodeCFrame(tPart.CFrame), [utf8.char(2)]=tPart, [utf8.char(3)]=Utility:EncodeCFrame(offset2) } }
                    UseItemRemote:FireServer(lf.EquippedItem:Get("ObjectID"), EnumLib:ToEnum("StartShooting"), data, nil)
                end)
            end
        end)

        -- 7. Reposition
        RunSvc.Heartbeat:Connect(function()
            if not RS.reposition.enabled then
                if RS.reposition.applied and RS.reposition.originalCF then local r = getMyHRP(); if r then r.CFrame = RS.reposition.originalCF end end
                RS.reposition.applied = false; RS.reposition.originalCF = nil; return
            end
            local hrp = getMyHRP(); if not hrp then return end
            if not RS.reposition.originalCF then RS.reposition.originalCF = hrp.CFrame end
            pcall(function() hrp.CFrame = hrp.CFrame + Vector3.new(0, RS.reposition.offset, 0) end)
            RS.reposition.applied = true
        end)

        -- 8. Dodge (Fixed with Down option)
        RunSvc.Heartbeat:Connect(function()
            if not RS.dodge.enabled then
                if RS.dodge.savedCF then local r = getMyHRP(); if r then r.CFrame = RS.dodge.savedCF end end
                RS.dodge.savedCF = nil; return
            end
            local hrp = getMyHRP(); if not hrp then return end
            local threat, td = nil, RS.antiKnife.range
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP2 and isEnemy(plr) and isAlive(plr) then
                    local t = plr.Character:FindFirstChild("HumanoidRootPart")
                    if t then local d = (t.Position - hrp.Position).Magnitude; if d < td then threat, td = t, d end end
                end
            end
            local now = tick()
            if threat then
                if not RS.dodge.savedCF then RS.dodge.savedCF = hrp.CFrame end
                local dest
                if RS.dodge.method == "up" then
                    dest = hrp.Position + Vector3.new(0, RS.dodge.height, 0)
                elseif RS.dodge.method == "down" then
                    dest = hrp.Position - Vector3.new(0, RS.dodge.height, 0)
                elseif RS.dodge.method == "random pos" then
                    dest = hrp.Position + Vector3.new(math.random(-RS.dodge.rangeBuffer,RS.dodge.rangeBuffer), 0, math.random(-RS.dodge.rangeBuffer,RS.dodge.rangeBuffer))
                else
                    local dir = hrp.Position - threat.Position; dir = Vector3.new(dir.X, 0, dir.Z)
                    if dir.Magnitude < 0.1 then dir = Vector3.new(1,0,0) end
                    dest = hrp.Position + dir.Unit * (RS.dodge.rangeBuffer + 3)
                end
                pcall(function() hrp.CFrame = CFrame.new(dest) end)
                RS.dodge.activeUntil = now + RS.dodge.duration
            elseif RS.dodge.savedCF and now >= RS.dodge.activeUntil then
                RS.dodge.savedCF = nil
            end
        end)

        -- 9. Backstab & Perfect Block & Anti-Knife
        RunSvc.RenderStepped:Connect(function()
            if not RS.backstab.enabled then return end
            local hrp = getMyHRP(); if not hrp then return end
            local tRoot, td = nil, math.huge
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP2 and isAlive(plr) then
                    local t = plr.Character:FindFirstChild("HumanoidRootPart")
                    if t then local d = (t.Position - hrp.Position).Magnitude; if d < td then tRoot, td = t, d end end
                end
            end
            if tRoot then
                pcall(function()
                    local yaw = math.atan2(tRoot.CFrame.LookVector.X, tRoot.CFrame.LookVector.Z) + math.pi
                    local rep = RS2:FindFirstChild("Remotes") and RS2.Remotes:FindFirstChild("Replication")
                    local ucr = rep and rep:FindFirstChild("Fighter") and rep.Fighter:FindFirstChild("UpdateCameraRotation")
                    if ucr then ucr:FireServer(Utility:EncodeCameraRotation(Vector2.new(0, yaw)), nil) end
                end)
            end
        end)

        RunSvc.RenderStepped:Connect(function()
            if not RS.block.enabled then
                if RS.block.appliedHumanoid then pcall(function() RS.block.appliedHumanoid.AutoRotate = RS.block.savedAutoRotate end) end
                RS.block.appliedHumanoid = nil; RS.block.savedAutoRotate = nil; return
            end
            local hrp, ch = getMyHRP(); if not hrp or not ch then return end
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if RS.block.appliedHumanoid ~= hum then
                if RS.block.appliedHumanoid then pcall(function() RS.block.appliedHumanoid.AutoRotate = RS.block.savedAutoRotate end) end
                RS.block.appliedHumanoid = hum; RS.block.savedAutoRotate = hum.AutoRotate
            end
            hum.AutoRotate = false
            local tRoot, td = nil, math.huge
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP2 and isAlive(plr) then
                    local t = plr.Character:FindFirstChild("HumanoidRootPart")
                    if t then local d = (t.Position - hrp.Position).Magnitude; if d < td then tRoot, td = t, d end end
                end
            end
            if tRoot then
                local dir = tRoot.Position - hrp.Position; dir = Vector3.new(dir.X, 0, dir.Z)
                if dir.Magnitude > 0.1 then pcall(function() hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position - dir.Unit) end) end
            end
        end)

        -- 10. UI
        local sSec = colRageFull:section({ name = "Elisium Silent Aim" })
        sSec:toggle({ name = "Enable Silent Aim", default = false, callback = function(v) RS.silent.enabled = v end })
        sSec:slider({ name = "FOV", min = 10, max = 500, interval = 1, default = 180, callback = function(v) RS.silent.fov = v end })
        sSec:toggle({ name = "Team Check", default = true, callback = function(v) RS.silent.team = v end })
        sSec:toggle({ name = "Wall Check", default = false, callback = function(v) RS.silent.wall = v end })
        sSec:dropdown({ name = "Target Part", items = {"Head","HumanoidRootPart","HitboxHead","HitboxBody"}, default = "Head", callback = function(v) RS.silent.part = v end })

        local rSec = colRageFull:section({ name = "Elisium Ragebot" })
        rSec:toggle({ name = "Enable Ragebot", default = false, callback = function(v) RS.rage.enabled = v end })
        rSec:dropdown({ name = "Attack Mode", items = {"Gun", "Melee", "Knife"}, default = "Gun", callback = function(v) RS.rage.attackMode = v end })
        rSec:dropdown({ name = "Strategy", items = {"Orbit", "TP"}, default = "Orbit", callback = function(v) RS.rage.strategy = v end })
        rSec:dropdown({ name = "Weapon", items = {"Primary", "Secondary"}, default = "Primary", callback = function(v) RS.rage.priority = v end })
        rSec:dropdown({ name = "Target Part", items = {"Head","UpperTorso","HumanoidRootPart"}, default = "Head", callback = function(v) RS.rage.hitboxPart = v end })
        rSec:slider({ name = "Orbit Radius", min = 0, max = 100, interval = 1, default = 5, callback = function(v) RS.rage.radius = v end })
        rSec:slider({ name = "Orbit Height", min = -100, max = 100, interval = 1, default = -4, callback = function(v) RS.rage.height = v end })
        rSec:slider({ name = "Orbit Speed", min = 10, max = 5000, interval = 1, default = 500, callback = function(v) RS.rage.orbitSpeed = v end })
        rSec:slider({ name = "Knife Distance", min = 1, max = 10, interval = 1, default = 3, callback = function(v) RS.rage.knifeDist = v end })
        rSec:toggle({ name = "Prediction", default = false, callback = function(v) RS.rage.prediction = v end })

        local dSec = colRageFull:section({ name = "Elisium Dodge & Block" })
        dSec:toggle({ name = "Enable Dodge", default = false, callback = function(v) RS.dodge.enabled = v end })
        dSec:dropdown({ name = "Dodge Method", items = {"lay down", "up", "down", "random pos"}, default = "lay down", callback = function(v) RS.dodge.method = v end })
        dSec:slider({ name = "Height / Dist", min = 5, max = 60, interval = 1, default = 20, callback = function(v) RS.dodge.height = v end })
        dSec:toggle({ name = "Always Backstab", default = false, callback = function(v) RS.backstab.enabled = v end })
        dSec:toggle({ name = "Perfect Block", default = false, callback = function(v) RS.block.enabled = v end })

        local aSec = colRageFull:section({ name = "Elisium Anti-Knife" })
        aSec:toggle({ name = "Enable Anti-Knife", default = false, callback = function(v) RS.antiKnife.enabled = v end })
        aSec:slider({ name = "Trigger Range", min = 5, max = 40, interval = 1, default = 14, callback = function(v) RS.antiKnife.range = v end })
        aSec:slider({ name = "Retreat Dist", min = 5, max = 60, interval = 1, default = 18, callback = function(v) RS.antiKnife.retreat = v end })

        -- Ragebot 2 (Original) UI + Logic was already pasted in PT 8, keeping it here just in case you removed it.
        local rb2 = colRageFull:section({ name = "Ragebot 2 (Original)" })
        rb2:toggle({ name = "Ragebot 2", default = false, callback = function(v) 
            if v then warn("Ragebot 2 engine is handled by the original code above.") end 
        end })

    end, function(e) warn("[PT 9 Engine] " .. tostring(e)) end)
end