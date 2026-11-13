if not game:IsLoaded() then game.Loaded:Wait() end
warn("[vercel.cc] executing")
if getgenv().vercel_unload then pcall(getgenv().vercel_unload) end
getgenv().vercel_unload = nil
getgenv().vercel_loaded = true
local __ok, __err = xpcall(function()
warn("[vercel.cc] starting")

-- vercel.cc | Free Version
local SOURCE = [==========[
local InputService = game:GetService('UserInputService')
local TextService = game:GetService('TextService')
local CoreGui = game:GetService('CoreGui')
local Teams = game:GetService('Teams')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local Lighting = game:GetService('Lighting')
local RenderStepped = RunService.RenderStepped
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer and LocalPlayer:GetMouse()

local function Vercel_getgenv()
    if type(getgenv) == "function" then
        return getgenv()
    end
    return _G
end
local OldLibrary = Vercel_getgenv().Vercel_Library
if type(OldLibrary) == 'table' and OldLibrary.IsVercel then
    pcall(function()
        if OldLibrary.Unload then OldLibrary:Unload() end
        if OldLibrary.ScreenGui and OldLibrary.ScreenGui.Parent then
            OldLibrary.ScreenGui:Destroy()
        end
    end)
end
pcall(function()
    local cg = game:GetService('CoreGui')
    local oldMob = cg:FindFirstChild('Vercel_MobileUI')
    if oldMob then oldMob:Destroy() end
end)

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end)

local ScreenGui = Instance.new('ScreenGui')
ProtectGui(ScreenGui)
ScreenGui.Name = 'VercelUI'
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 100
ScreenGui.Parent = CoreGui

local Toggles = {}
local Options = {}
pcall(function()
    local g = Vercel_getgenv()
    g.Vercel_Toggles = Toggles
    g.Vercel_Options = Options
    local foreign = type(g.Library) == "table" and g.Library.IsVercel ~= true
    if not foreign then
        if g.Toggles == nil then g.Toggles = Toggles end
        if g.Options == nil then g.Options = Options end
    end
end)

local function ContrastColor(c)
    local lum = 0.299*c.R + 0.587*c.G + 0.114*c.B
    if lum > 0.55 then
        return Color3.fromRGB(20, 20, 20)
    end
    return Color3.fromRGB(240, 240, 240)
end

local Library = {
    IsVercel = true,
    Name = "Vercel",
    IsMobile = false,
    PerformanceMode = true,
    Registry = {},
    RegistryMap = {},
    HudRegistry = {},
    FontColor = Color3.fromRGB(160, 160, 160),
    MainColor = Color3.fromRGB(24, 24, 24),
    BackgroundColor = Color3.fromRGB(19, 19, 19),
    AccentColor = Color3.fromRGB(245, 20, 136),
    OutlineColor = Color3.fromRGB(54, 54, 54),
    RiskColor = Color3.fromRGB(255, 50, 50),
    GlassEnabled = false,
    GlassTransparency = 0.92,
    GlassGloss = true,
    Black = Color3.new(0, 0, 0),
    Font = Enum.Font.Code,
    FontSize = 14,
    OpenedFrames = {},
    DependencyBoxes = {},
    Signals = {},
    ScreenGui = ScreenGui,
    Toggled = false,
    WireframeDrag = true,
    UseBlur = false,
    BlurSize = 24,
    UseDarken = true,
    DarkenAmount = 55,
    KeybindMode = 'All',
    NotifyConfig = {
        ClipDescendants = false,
        MaxHeight = 200,
        PosX = 50,
        PosY = 60,
        Transparency = 60,
        Alignment = "Center",
        BarSide = "Bottom",
        SortOrder = "Time",
    },
    NotifyQueue = {},
    ActiveNotifyCount = 0,
    NotifyCounter = 0,
    _GlassDirty = false,
    _LastGlassApply = 0,
}

Library.KeyPickerList = {}
Library.SliderAnimations = true

Library.BlurEffect = Instance.new("BlurEffect")
Library.BlurEffect.Name = "LinoriaBlur"
Library.BlurEffect.Size = 0
Library.BlurEffect.Enabled = false
pcall(function() Library.BlurEffect.Parent = Lighting end)

do
    local OverlayGui = Instance.new("ScreenGui")
    OverlayGui.Name = "LinoriaBlurOverlay"
    OverlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    OverlayGui.DisplayOrder = -9999
    ProtectGui(OverlayGui)
    OverlayGui.Parent = CoreGui
    Library.DarkOverlay = Instance.new("Frame")
    Library.DarkOverlay.Name = "DarkOverlay"
    Library.DarkOverlay.Size = UDim2.new(10, 0, 10, 0)
    Library.DarkOverlay.Position = UDim2.new(-5, 0, -5, 0)
    Library.DarkOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
    Library.DarkOverlay.BackgroundTransparency = 1
    Library.DarkOverlay.BorderSizePixel = 0
    Library.DarkOverlay.ZIndex = 1
    Library.DarkOverlay.Parent = OverlayGui
end

function Library:UpdateBlur()
    local open = Library.Toggled == true
    local useBlur = open and Library.UseBlur and not (Library.IsMobile == true)
    if Library.BlurEffect then
        if useBlur then
            Library.BlurEffect.Enabled = true
            local base = Library.BlurSize or 18
            if Library.GlassEnabled then
                base = math.clamp(base, 16, 32)
            end
            Library.BlurEffect.Size = base
        else
            Library.BlurEffect.Size = 0
            Library.BlurEffect.Enabled = false
        end
    end
    if Library.DarkOverlay then
        if open and Library.UseDarken then
            local amt = math.clamp(Library.DarkenAmount or 12, 0, 30)
            Library.DarkOverlay.BackgroundTransparency = 1 - (amt / 100)
        else
            Library.DarkOverlay.BackgroundTransparency = 1
        end
    end
end

function Library:SetBlur(Size)
    Library.BlurSize = math.clamp(Size, 0, 56)
    if Library.Toggled and Library.UseBlur then
        Library.BlurEffect.Size = Library.BlurSize
    end
end

function Library:AddBlurSlider(Groupbox)
    Groupbox:AddToggle('LinoriaUseBlur', {
        Text = 'Background Blur',
        Default = Library.UseBlur,
        Tooltip = 'Blur the background when the menu is open',
        Callback = function(Value)
            Library.UseBlur = Value
            Library:UpdateBlur()
        end,
    })
    Groupbox:AddSlider('LinoriaBlurSize', {
        Text = 'Blur Amount',
        Default = Library.BlurSize,
        Min = 0,
        Max = 56,
        Rounding = 0,
        Callback = function(Value)
            Library:SetBlur(Value)
        end,
    })
end

function Library:AddDarkenSlider(Groupbox)
    Groupbox:AddToggle('LinoriaUseDarken', {
        Text = 'Background Darken',
        Default = Library.UseDarken,
        Tooltip = 'Darken the background when the menu is open',
        Callback = function(Value)
            Library.UseDarken = Value
            Library:UpdateBlur()
        end,
    })
    Groupbox:AddSlider('LinoriaDarkenAmount', {
        Text = 'Darken Amount',
        Default = Library.DarkenAmount,
        Min = 0,
        Max = 100,
        Rounding = 0,
        Suffix = '%',
        Callback = function(Value)
            Library.DarkenAmount = Value
            Library:UpdateBlur()
        end,
    })
end

function Library:SetKeybindTransparency(Value)
    Value = math.clamp(Value, 0, 1)
    local Inner = Library.KeybindInner
    if Library.KeybindFrame then
        Library.KeybindFrame.BackgroundTransparency = Value
        Library.KeybindFrame.BorderSizePixel = Value >= 1 and 0 or 1
        if not Inner then
            Inner = Library.KeybindFrame:FindFirstChildOfClass('Frame')
        end
    end
    if Inner then
        Inner.BackgroundTransparency = Value
        Inner.BorderSizePixel = Value >= 1 and 0 or 1
    end
    if Library.KeybindColorFrame then
        Library.KeybindColorFrame.BackgroundTransparency = Value
    end
end

function Library:AddKeybindTransparencySlider(Groupbox)
    Groupbox:AddSlider('LinoriaKeybindTransparency', {
        Text = 'Keybind Transparency',
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 0,
        Suffix = '%',
        Callback = function(Value)
            Library:SetKeybindTransparency(Value / 100)
        end,
    })
end

function Library:SetFontSize(Size)
    Library.FontSize = Size
    for _, descendant in pairs(ScreenGui:GetDescendants()) do
        if descendant:IsA("TextLabel") or descendant:IsA("TextBox") or descendant:IsA("TextButton") then
            local offset = descendant:GetAttribute("FontSizeOffset")
            if offset then
                descendant.TextSize = Size + offset
            end
        end
    end
    local mobileUI = CoreGui:FindFirstChild("Vercel_MobileUI")
    if mobileUI then
        for _, descendant in pairs(mobileUI:GetDescendants()) do
            if descendant:IsA("TextLabel") or descendant:IsA("TextBox") or descendant:IsA("TextButton") then
                local offset = descendant:GetAttribute("FontSizeOffset")
                if offset then
                    descendant.TextSize = Size + offset
                end
            end
        end
    end
end

local RainbowStep = 0
local Hue = 0
table.insert(Library.Signals, RunService.Heartbeat:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta
    local interval = (Library.IsMobile == true) and (1 / 20) or (1 / 30)
    if RainbowStep >= interval then
        RainbowStep = 0
        Hue = Hue + (1 / 400)
        if Hue > 1 then Hue = 0 end
        Library.CurrentRainbowHue = Hue
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1)
    end
end))

local function GetPlayersString()
    local PlayerList = Players:GetPlayers()
    for i = 1, #PlayerList do
        PlayerList[i] = PlayerList[i].Name
    end
    table.sort(PlayerList, function(str1, str2) return str1 < str2 end)
    return PlayerList
end

local function GetTeamsString()
    local TeamList = Teams:GetTeams()
    for i = 1, #TeamList do
        TeamList[i] = TeamList[i].Name
    end
    table.sort(TeamList, function(str1, str2) return str1 < str2 end)
    return TeamList
end

function Library:SafeCallback(f, ...)
    if not f then return end
    if not Library.NotifyOnError then return f(...) end
    local success, event = pcall(f, ...)
    if not success then
        local _, i = event:find(":%d+: ")
        if not i then
            return Library:Notify(tostring(event), 3)
        end
        return Library:Notify(event:sub(i + 1), 3)
    end
end

function Library:AttemptSave()
    if Library.SaveManager then Library.SaveManager:Save() end
end

function Library:Create(Class, Properties)
    local _Instance = Class
    if type(Class) == 'string' then _Instance = Instance.new(Class) end
    for Property, Value in next, Properties do
        pcall(function() _Instance[Property] = Value end)
    end
    if _Instance:IsA("TextLabel") or _Instance:IsA("TextBox") or _Instance:IsA("TextButton") then
        if Properties.TextSize then
            _Instance:SetAttribute("FontSizeOffset", Properties.TextSize - Library.FontSize)
        else
            _Instance:SetAttribute("FontSizeOffset", 0)
        end
    end
    return _Instance
end

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1
    Library:Create('UIStroke', {
        Color = Color3.new(0, 0, 0),
        Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Parent = Inst,
    })
end

function Library:ApplyGlow(Inst) end

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextColor3 = Library.FontColor,
        TextSize = Library.FontSize + 2,
        TextStrokeTransparency = 0,
    })
    Library:ApplyTextStroke(_Instance)
    Library:AddToRegistry(_Instance, { TextColor3 = 'FontColor' }, IsHud)
    return Library:Create(_Instance, Properties)
end

function Library:MakeDraggable(Instance, Cutoff, IsWindow)
    Instance.Active = true
    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            local StartPos = Instance.Position
            local DragStart = Input.Position
            if (DragStart.Y - Instance.AbsolutePosition.Y) > (Cutoff or 40) then return end
            local Dragging = true
            local HasMoved = false
            local Wireframe = nil
            local ChangedConn, EndedConn
            ChangedConn = InputService.InputChanged:Connect(function(Change)
                if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                    local Delta = Change.Position - DragStart
                    if IsWindow and Library.WireframeDrag then
                        if not HasMoved and Delta.Magnitude > 2 then
                            HasMoved = true
                            Wireframe = Library:Create("Frame", {
                                Size = Instance.Size,
                                Position = Instance.Position,
                                AnchorPoint = Instance.AnchorPoint,
                                BackgroundColor3 = Library.MainColor,
                                BackgroundTransparency = 0.5,
                                Active = false,
                                ZIndex = 100000,
                                Parent = ScreenGui,
                            })
                            Library:Create("UIStroke", {
                                Color = Library.AccentColor,
                                Thickness = 1,
                                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                                Parent = Wireframe,
                            })
                        end
                        if HasMoved and Wireframe then
                            Wireframe.Position = UDim2.new(
                                StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                                StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
                            )
                        end
                    else
                        Instance.Position = UDim2.new(
                            StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                            StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
                        )
                    end
                end
            end)
            EndedConn = InputService.InputEnded:Connect(function(EndInput)
                if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                    Dragging = false
                    ChangedConn:Disconnect()
                    EndedConn:Disconnect()
                    if IsWindow and Library.WireframeDrag and HasMoved and Wireframe then
                        Instance.Position = Wireframe.Position
                        Wireframe:Destroy()
                        Wireframe = nil
                    end
                end
            end)
        end
    end)
end

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, Library.FontSize)
    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Size = UDim2.fromOffset(X + 5, Y + 4),
        ZIndex = 100,
        Parent = Library.ScreenGui,
        Visible = false,
    })
    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(3, 1),
        Size = UDim2.fromOffset(X, Y),
        TextSize = Library.FontSize,
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = Tooltip.ZIndex + 1,
        Parent = Tooltip,
    })
    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = 'MainColor',
        BorderColor3 = 'OutlineColor',
    })
    Library:AddToRegistry(Label, { TextColor3 = 'FontColor' })
    local IsHovering = false
    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then return end
        IsHovering = true
        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible = true
        while IsHovering do
            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end
    end)
    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        Tooltip.Visible = false
    end)
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    HighlightInstance.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Instance]
        for Property, ColorIdx in next, Properties do
            Instance[Property] = Library[ColorIdx] or ColorIdx
            if Reg and Reg.Properties[Property] then Reg.Properties[Property] = ColorIdx end
        end
    end)
    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Instance]
        for Property, ColorIdx in next, PropertiesDefault do
            Instance[Property] = Library[ColorIdx] or ColorIdx
            if Reg and Reg.Properties[Property] then Reg.Properties[Property] = ColorIdx end
        end
    end)
end

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
        if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
            and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
            return true
        end
    end
end

function Library:IsMouseOverFrame(Frame)
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
        return true
    end
end

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        Depbox:Update()
    end
end

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB
end

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color)
    return Color3.fromHSV(H, S, V / 1.5)
end

Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)

do
    local mobile = false
    pcall(function()
        if InputService.TouchEnabled then
            mobile = true
        end
    end)
    Library.IsMobile = mobile
    if mobile then
        Library.UseBlur = false
        Library.BlurSize = 0
        Library.UseDarken = true
        Library.DarkenAmount = 8
        Library.WireframeDrag = false
        Library.PerformanceMode = true
    else
        Library.PerformanceMode = true
    end
end

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1
    local Data = { Instance = Instance, Properties = Properties, Idx = Idx }
    table.insert(Library.Registry, Data)
    Library.RegistryMap[Instance] = Data
    if IsHud then table.insert(Library.HudRegistry, Data) end
end

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance]
    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then table.remove(Library.Registry, Idx) end
        end
        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then table.remove(Library.HudRegistry, Idx) end
        end
        Library.RegistryMap[Instance] = nil
    end
end

function Library:UpdateColorsUsingRegistry()
    for Idx, Object in next, Library.Registry do
        local inst = Object.Instance
        if inst and inst.Parent then
            for Property, ColorIdx in next, Object.Properties do
                if type(ColorIdx) == 'string' then
                    pcall(function() inst[Property] = Library[ColorIdx] end)
                elseif type(ColorIdx) == 'function' then
                    pcall(function() inst[Property] = ColorIdx() end)
                end
            end
        end
    end
    for _, Slider in pairs(Options) do
        if type(Slider) == 'table' and Slider.Type == 'Slider' and Slider._RefreshContrast then
            pcall(Slider._RefreshContrast)
        end
    end
end

function Library:GiveSignal(Signal) table.insert(Library.Signals, Signal) end

function Library:Unload()
    pcall(function()
        for Idx = #Library.Signals, 1, -1 do
            local Connection = table.remove(Library.Signals, Idx)
            pcall(function() Connection:Disconnect() end)
        end
    end)
    pcall(function() if Library.OnUnload then Library.OnUnload() end end)
    pcall(function() if Library.BlurEffect then Library.BlurEffect:Destroy() end end)
    pcall(function()
        if Library.DarkOverlay and Library.DarkOverlay.Parent then
            Library.DarkOverlay.Parent:Destroy()
        end
    end)
    pcall(function() Library:DestroyLiveStudUI() end)
    pcall(function()
        if Library._LogoGui then Library._LogoGui:Destroy() end
        if Library._LogoSpinConn then Library._LogoSpinConn:Disconnect() end
    end)
    pcall(function()
        local cg = game:GetService("CoreGui")
        local mob = cg:FindFirstChild("Vercel_MobileUI")
        if mob then mob:Destroy() end
    end)
    pcall(function()
        if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
    end)
    pcall(function()
        local g = Vercel_getgenv()
        if not Library._IsolatedMode then
            if Library._PrevLibrary ~= nil then
                g.Library = Library._PrevLibrary
            elseif g.Library == Library then
                g.Library = nil
            end
            if Library._PrevToggles ~= nil then
                g.Toggles = Library._PrevToggles
            elseif g.Toggles == Toggles then
                g.Toggles = nil
            end
            if Library._PrevOptions ~= nil then
                g.Options = Library._PrevOptions
            elseif g.Options == Options then
                g.Options = nil
            end
        end
        if g.Vercel_Library == Library then g.Vercel_Library = nil end
        if g.Vercel_Toggles == Toggles then g.Vercel_Toggles = nil end
        if g.Vercel_Options == Options then g.Vercel_Options = nil end
    end)
end

function Library:OnUnload(Callback) Library.OnUnload = Callback end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then Library:RemoveFromRegistry(Instance) end
end))

Library.PresetConfigs = {}

Library.PresetConfigs.Default = {
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    Noclip = false,
    Gravity = 196.2,
    FogDistance = 1000,
    GlassEnabled = false,
    GlassTransparency = 0.92,
    UseBlur = true,
    BlurSize = 24,
    UseDarken = true,
    DarkenAmount = 55,
    FontSize = 14,
    KeybindMode = "All",
    AccentColor = Color3.fromRGB(170, 170, 170),
    MainColor = Color3.fromRGB(10, 10, 10),
    BackgroundColor = Color3.fromRGB(0, 0, 0),
    OutlineColor = Color3.fromRGB(42, 42, 42),
    FontColor = Color3.fromRGB(225, 225, 225),
}

Library.PresetConfigs.PvP = {
    WalkSpeed = 22,
    JumpPower = 55,
    InfiniteJump = false,
    Noclip = false,
    Gravity = 196.2,
    FogDistance = 2000,
    GlassEnabled = false,
    GlassTransparency = 0.85,
    UseBlur = true,
    BlurSize = 12,
    UseDarken = true,
    DarkenAmount = 35,
    FontSize = 14,
    KeybindMode = "Active",
    AccentColor = Color3.fromRGB(170, 170, 170),
    MainColor = Color3.fromRGB(10, 10, 10),
    BackgroundColor = Color3.fromRGB(0, 0, 0),
    OutlineColor = Color3.fromRGB(42, 42, 42),
    FontColor = Color3.fromRGB(225, 225, 225),
}

Library.PresetConfigs.Stealth = {
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    Noclip = false,
    Gravity = 196.2,
    FogDistance = 800,
    GlassEnabled = false,
    GlassTransparency = 0.94,
    UseBlur = true,
    BlurSize = 20,
    UseDarken = true,
    DarkenAmount = 70,
    FontSize = 12,
    KeybindMode = "Toggled",
    AccentColor = Color3.fromRGB(170, 170, 170),
    MainColor = Color3.fromRGB(10, 10, 10),
    BackgroundColor = Color3.fromRGB(0, 0, 0),
    OutlineColor = Color3.fromRGB(42, 42, 42),
    FontColor = Color3.fromRGB(225, 225, 225),
}

Library.PresetConfigs.Rivals = {
    WalkSpeed = 20,
    JumpPower = 52,
    InfiniteJump = false,
    Noclip = false,
    Gravity = 196.2,
    FogDistance = 3000,
    GlassEnabled = false,
    GlassTransparency = 0.88,
    UseBlur = true,
    BlurSize = 8,
    UseDarken = true,
    DarkenAmount = 45,
    FontSize = 14,
    KeybindMode = "All",
    AccentColor = Color3.fromRGB(170, 170, 170),
    MainColor = Color3.fromRGB(10, 10, 10),
    BackgroundColor = Color3.fromRGB(0, 0, 0),
    OutlineColor = Color3.fromRGB(42, 42, 42),
    FontColor = Color3.fromRGB(225, 225, 225),
}

Library.PresetConfigs.Minimal = {
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    Noclip = false,
    Gravity = 196.2,
    FogDistance = 1000,
    GlassEnabled = false,
    GlassTransparency = 1,
    UseBlur = false,
    BlurSize = 0,
    UseDarken = false,
    DarkenAmount = 0,
    FontSize = 14,
    KeybindMode = "All",
    AccentColor = Color3.fromRGB(170, 170, 170),
    MainColor = Color3.fromRGB(10, 10, 10),
    BackgroundColor = Color3.fromRGB(0, 0, 0),
    OutlineColor = Color3.fromRGB(42, 42, 42),
    FontColor = Color3.fromRGB(225, 225, 225),
}

function Library:LoadPreset(Name)
    local preset = Library.PresetConfigs[Name]
    if not preset then
        Library:Notify("Preset '" .. tostring(Name) .. "' not found", 3)
        return
    end
    Library.AccentColor = preset.AccentColor or Library.AccentColor
    Library.MainColor = preset.MainColor or Library.MainColor
    Library.BackgroundColor = preset.BackgroundColor or Library.BackgroundColor
    Library.OutlineColor = preset.OutlineColor or Library.OutlineColor
    Library.FontColor = preset.FontColor or Library.FontColor
    Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
    Library.UseBlur = preset.UseBlur == true
    Library.BlurSize = preset.BlurSize or Library.BlurSize
    Library.UseDarken = preset.UseDarken == true
    Library.DarkenAmount = preset.DarkenAmount or Library.DarkenAmount
    Library.GlassEnabled = preset.GlassEnabled ~= false
    Library.GlassTransparency = preset.GlassTransparency or Library.GlassTransparency
    pcall(function() Library:SetFontSize(preset.FontSize or Library.FontSize) end)
    pcall(function() Library:SetKeybindMode(preset.KeybindMode or Library.KeybindMode) end)
    pcall(function() Library:UpdateColorsUsingRegistry() end)
    pcall(function() Library:SetGlass(Library.GlassEnabled, Library.GlassTransparency) end)
    pcall(function() Library:UpdateBlur() end)
    if Toggles then
        if Toggles.InfiniteJump then Toggles.InfiniteJump:SetValue(preset.InfiniteJump == true) end
        if Toggles.Noclip then Toggles.Noclip:SetValue(preset.Noclip == true) end
    end
    if Options then
        if Options.WalkSpeed then Options.WalkSpeed:SetValue(preset.WalkSpeed or 16) end
        if Options.JumpPower then Options.JumpPower:SetValue(preset.JumpPower or 50) end
        if Options.Gravity then Options.Gravity:SetValue(preset.Gravity or 196.2) end
        if Options.FogEnd then Options.FogEnd:SetValue(preset.FogDistance or 1000) end
    end
    pcall(function() Library:AttemptSave() end)
    Library:Notify("Preset loaded: " .. tostring(Name), 3)
end

function Library:AddPresetDropdown(Groupbox)
    local presetNames = {}
    for name, _ in pairs(Library.PresetConfigs) do
        table.insert(presetNames, name)
    end
    table.sort(presetNames)
    Groupbox:AddLabel("Custom Preset Configs")
    Groupbox:AddDropdown("Vercel_PresetSelect", {
        Text = "Preset",
        Values = presetNames,
        Default = 1,
        Callback = function(v) end,
    })
    Groupbox:AddButton("Load Selected Preset", function()
        local selected = Options and Options.Vercel_PresetSelect
        local name = selected and selected.Value
        if name then Library:LoadPreset(name) end
    end)
    Groupbox:AddButton("Save Current As Preset", function()
        Library:Notify("Preset saved to memory", 3)
    end)
end

function Library:ShowLiveStud(title)
    pcall(function()
        Library:CreateLiveStudUI({ Title = title or Library.ScriptName or "vercel.cc" })
    end)
end


local BaseAddons = {}
do
    local Funcs = {}

    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel
        assert(Info.Default, 'AddColorPicker: Missing default value.')
        local ColorPicker = {
            Value = Info.Default,
            Transparency = Info.Transparency or 0,
            Type = 'ColorPicker',
            Title = type(Info.Title) == 'string' and Info.Title or 'Color picker',
            Callback = Info.Callback or function(Color) end,
        }
        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color)
            ColorPicker.Hue = H
            ColorPicker.Sat = S
            ColorPicker.Vib = V
        end
        ColorPicker:SetHSVFromRGB(ColorPicker.Value)
        local DisplayFrame = Library:Create('Frame', {
            BackgroundColor3 = ColorPicker.Value,
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value),
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(0, 28, 0, 14),
            ZIndex = 6,
            Parent = ToggleLabel,
        })
        Library:Create('ImageLabel', {
            BorderSizePixel = 0,
            Size = UDim2.new(0, 27, 0, 13),
            ZIndex = 5,
            Image = 'http://www.roblox.com/asset/?id=12977615774',
            Visible = not not Info.Transparency,
            Parent = DisplayFrame,
        })
        local PickerFrameOuter = Library:Create('Frame', {
            Name = 'Color',
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253),
            Visible = false,
            ZIndex = 15,
            Parent = ScreenGui,
        })
        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18)
        end)
        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 16,
            Parent = PickerFrameOuter,
        })
        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 2),
            ZIndex = 17,
            Parent = PickerFrameInner,
        })
        local SatVibMapOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.new(0, 4, 0, 25),
            Size = UDim2.new(0, 200, 0, 200),
            ZIndex = 17,
            Parent = PickerFrameInner,
        })
        local SatVibMapInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 18,
            Parent = SatVibMapOuter,
        })
        local SatVibMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 18,
            Image = 'rbxassetid://4155801252',
            Parent = SatVibMapInner,
        })
        local CursorOuter = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, 6, 0, 6),
            BackgroundTransparency = 1,
            Image = 'http://www.roblox.com/asset/?id=9619665977',
            ImageColor3 = Color3.new(0, 0, 0),
            ZIndex = 19,
            Parent = SatVibMap,
        })
        Library:Create('ImageLabel', {
            Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2),
            Position = UDim2.new(0, 1, 0, 1),
            BackgroundTransparency = 1,
            Image = 'http://www.roblox.com/asset/?id=9619665977',
            ZIndex = 20,
            Parent = CursorOuter,
        })
        local HueSelectorOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.new(0, 208, 0, 25),
            Size = UDim2.new(0, 15, 0, 200),
            ZIndex = 17,
            Parent = PickerFrameInner,
        })
        local HueSelectorInner = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 18,
            Parent = HueSelectorOuter,
        })
        local HueCursor = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1),
            AnchorPoint = Vector2.new(0, 0.5),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, 0, 0, 1),
            ZIndex = 18,
            Parent = HueSelectorInner,
        })
        local HueBoxOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.fromOffset(4, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            ZIndex = 18,
            Parent = PickerFrameInner,
        })
        local HueBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 18,
            Parent = HueBoxOuter,
        })
        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212)),
            }),
            Rotation = 90,
            Parent = HueBoxInner,
        })
        local HueBox = Library:Create('TextBox', {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 5, 0, 0),
            Size = UDim2.new(1, -5, 1, 0),
            Font = Library.Font,
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190),
            PlaceholderText = 'Hex color',
            Text = '#FFFFFF',
            TextColor3 = Library.FontColor,
            TextSize = Library.FontSize,
            TextStrokeTransparency = 0,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 20,
            Parent = HueBoxInner,
        })
        Library:ApplyTextStroke(HueBox)
        local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            Parent = PickerFrameInner,
        })
        local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild('TextBox'), {
            Text = '255, 255, 255',
            PlaceholderText = 'RGB color',
            TextColor3 = Library.FontColor,
        })
        local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor
        if Info.Transparency then
            TransparencyBoxOuter = Library:Create('Frame', {
                BorderColor3 = Color3.new(0, 0, 0),
                Position = UDim2.fromOffset(4, 251),
                Size = UDim2.new(1, -8, 0, 15),
                ZIndex = 19,
                Parent = PickerFrameInner,
            })
            TransparencyBoxInner = Library:Create('Frame', {
                BackgroundColor3 = ColorPicker.Value,
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 19,
                Parent = TransparencyBoxOuter,
            })
            Library:AddToRegistry(TransparencyBoxInner, { BorderColor3 = 'OutlineColor' })
            Library:Create('ImageLabel', {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Image = 'http://www.roblox.com/asset/?id=12978095818',
                ZIndex = 20,
                Parent = TransparencyBoxInner,
            })
            TransparencyCursor = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(1, 1, 1),
                AnchorPoint = Vector2.new(0.5, 0),
                BorderColor3 = Color3.new(0, 0, 0),
                Size = UDim2.new(0, 1, 1, 0),
                ZIndex = 21,
                Parent = TransparencyBoxInner,
            })
        end
        Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 14),
            Position = UDim2.fromOffset(5, 5),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextSize = Library.FontSize,
            Text = ColorPicker.Title,
            TextWrapped = false,
            ZIndex = 16,
            Parent = PickerFrameInner,
        })
        local ContextMenu = {}
        do
            ContextMenu.Options = {}
            ContextMenu.Container = Library:Create('Frame', {
                BorderColor3 = Color3.new(),
                ZIndex = 14,
                Visible = false,
                Parent = ScreenGui,
            })
            ContextMenu.Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.fromScale(1, 1),
                ZIndex = 15,
                Parent = ContextMenu.Container,
            })
            Library:Create('UIListLayout', {
                Name = 'Layout',
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = ContextMenu.Inner,
            })
            Library:Create('UIPadding', {
                Name = 'Padding',
                PaddingLeft = UDim.new(0, 4),
                Parent = ContextMenu.Inner,
            })
            local function updateMenuPosition()
                ContextMenu.Container.Position = UDim2.fromOffset(
                    (DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
                    DisplayFrame.AbsolutePosition.Y + 1
                )
            end
            local function updateMenuSize()
                local menuWidth = 60
                for i, label in next, ContextMenu.Inner:GetChildren() do
                    if label:IsA('TextLabel') then
                        menuWidth = math.max(menuWidth, label.TextBounds.X)
                    end
                end
                ContextMenu.Container.Size = UDim2.fromOffset(
                    menuWidth + 8,
                    ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
                )
            end
            DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateMenuPosition)
            ContextMenu.Inner.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateMenuSize)
            task.spawn(updateMenuPosition)
            task.spawn(updateMenuSize)
            Library:AddToRegistry(ContextMenu.Inner, {
                BackgroundColor3 = 'BackgroundColor',
                BorderColor3 = 'OutlineColor',
            })
            function ContextMenu:Show() self.Container.Visible = true end
            function ContextMenu:Hide() self.Container.Visible = false end
            function ContextMenu:AddOption(Str, Callback)
                if type(Callback) ~= 'function' then Callback = function() end end
                local Button = Library:CreateLabel({
                    Active = false,
                    Size = UDim2.new(1, 0, 0, 15),
                    TextSize = Library.FontSize - 1,
                    Text = Str,
                    ZIndex = 16,
                    Parent = self.Inner,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                Library:OnHighlight(Button, Button,
                    { TextColor3 = 'AccentColor' },
                    { TextColor3 = 'FontColor' }
                )
                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end
                    Callback()
                end)
            end
            ContextMenu:AddOption('Copy color', function()
                Library.ColorClipboard = ColorPicker.Value
                Library:Notify('Copied color!', 2)
            end)
            ContextMenu:AddOption('Paste color', function()
                if not Library.ColorClipboard then return Library:Notify('You have not copied a color!', 2) end
                ColorPicker:SetValueRGB(Library.ColorClipboard)
            end)
            ContextMenu:AddOption('Copy HEX', function()
                pcall(setclipboard, ColorPicker.Value:ToHex())
                Library:Notify('Copied hex code to clipboard!', 2)
            end)
            ContextMenu:AddOption('Copy RGB', function()
                pcall(setclipboard, table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', '))
                Library:Notify('Copied RGB values to clipboard!', 2)
            end)
        end
        Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = 'BackgroundColor', BorderColor3 = 'OutlineColor' })
        Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor' })
        Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = 'BackgroundColor', BorderColor3 = 'OutlineColor' })
        Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = 'MainColor', BorderColor3 = 'OutlineColor' })
        Library:AddToRegistry(RgbBoxBase.Frame, { BackgroundColor3 = 'MainColor', BorderColor3 = 'OutlineColor' })
        Library:AddToRegistry(RgbBox, { TextColor3 = 'FontColor' })
        Library:AddToRegistry(HueBox, { TextColor3 = 'FontColor' })
        local SequenceTable = {}
        for Hue = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)))
        end
        Library:Create('UIGradient', {
            Color = ColorSequence.new(SequenceTable),
            Rotation = 90,
            Parent = HueSelectorInner,
        })
        HueBox.FocusLost:Connect(function(enter)
            if enter then
                local success, result = pcall(Color3.fromHex, HueBox.Text)
                if success and typeof(result) == 'Color3' then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
                end
            end
            ColorPicker:Display()
        end)
        RgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r, g, b = RgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
                if r and g and b then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r, g, b))
                end
            end
            ColorPicker:Display()
        end)
        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)
            Library:Create(DisplayFrame, {
                BackgroundColor3 = ColorPicker.Value,
                BackgroundTransparency = ColorPicker.Transparency,
                BorderColor3 = Library:GetDarkerColor(ColorPicker.Value),
            })
            if TransparencyBoxInner then
                TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value
                TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0)
            end
            CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0)
            HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0)
            HueBox.Text = '#' .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', ')
            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
        end
        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func
            Func(ColorPicker.Value)
        end
        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then
                    Frame.Visible = false
                    Library.OpenedFrames[Frame] = nil
                end
            end
            PickerFrameOuter.Visible = true
            Library.OpenedFrames[PickerFrameOuter] = true
        end
        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false
            Library.OpenedFrames[PickerFrameOuter] = nil
        end
        function ColorPicker:SetValue(HSV, Transparency)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])
            ColorPicker.Transparency = Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Display()
        end
        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Display()
        end
        SatVibMap.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local function UpdateColor(PosX, PosY)
                    local MinX = SatVibMap.AbsolutePosition.X
                    local MaxX = MinX + SatVibMap.AbsoluteSize.X
                    local MouseX = math.clamp(PosX, MinX, MaxX)
                    local MinY = SatVibMap.AbsolutePosition.Y
                    local MaxY = MinY + SatVibMap.AbsoluteSize.Y
                    local MouseY = math.clamp(PosY, MinY, MaxY)
                    ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX)
                    ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY))
                    ColorPicker:Display()
                end
                UpdateColor(Input.Position.X, Input.Position.Y)
                local ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                        UpdateColor(Change.Position.X, Change.Position.Y)
                    end
                end)
                local EndedConn
                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                        ChangedConn:Disconnect()
                        EndedConn:Disconnect()
                        Library:AttemptSave()
                    end
                end)
            end
        end)
        HueSelectorInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local function UpdateHue(PosY)
                    local MinY = HueSelectorInner.AbsolutePosition.Y
                    local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y
                    local MouseY = math.clamp(PosY, MinY, MaxY)
                    ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY))
                    ColorPicker:Display()
                end
                UpdateHue(Input.Position.Y)
                local ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                        UpdateHue(Change.Position.Y)
                    end
                end)
                local EndedConn
                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                        ChangedConn:Disconnect()
                        EndedConn:Disconnect()
                        Library:AttemptSave()
                    end
                end)
            end
        end)
        DisplayFrame.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                if PickerFrameOuter.Visible then
                    ColorPicker:Hide()
                else
                    ContextMenu:Hide()
                    ColorPicker:Show()
                end
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ContextMenu:Show()
                ColorPicker:Hide()
            end
        end)
        if TransparencyBoxInner then
            TransparencyBoxInner.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    local function UpdateAlpha(PosX)
                        local MinX = TransparencyBoxInner.AbsolutePosition.X
                        local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X
                        local MouseX = math.clamp(PosX, MinX, MaxX)
                        ColorPicker.Transparency = 1 - ((MouseX - MinX) / (MaxX - MinX))
                        ColorPicker:Display()
                    end
                    UpdateAlpha(Input.Position.X)
                    local ChangedConn = InputService.InputChanged:Connect(function(Change)
                        if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                            UpdateAlpha(Change.Position.X)
                        end
                    end)
                    local EndedConn
                    EndedConn = InputService.InputEnded:Connect(function(EndInput)
                        if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                            ChangedConn:Disconnect()
                            EndedConn:Disconnect()
                            Library:AttemptSave()
                        end
                    end)
                end
            end)
        end
        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize
                local DFPos = DisplayFrame.AbsolutePosition
                local DFSize = DisplayFrame.AbsoluteSize
                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < DFPos.Y or Mouse.Y > AbsPos.Y + AbsSize.Y then
                    if not (Mouse.X >= DFPos.X and Mouse.X <= DFPos.X + DFSize.X
                        and Mouse.Y >= DFPos.Y and Mouse.Y <= DFPos.Y + DFSize.Y) then
                        ColorPicker:Hide()
                    end
                end
                if not Library:IsMouseOverFrame(ContextMenu.Container) then
                    ContextMenu:Hide()
                end
            end
            if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
                if not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(DisplayFrame) then
                    ContextMenu:Hide()
                end
            end
        end))
        function ColorPicker:GetTransparency() return ColorPicker.Transparency end
        function ColorPicker:OnTransparencyChanged(Func)
            ColorPicker.TransparencyChanged = Func
            Func(ColorPicker.Transparency)
        end
        local _OrigDisplay = ColorPicker.Display
        ColorPicker.Display = function(self)
            _OrigDisplay(self)
            Library:SafeCallback(ColorPicker.TransparencyChanged, ColorPicker.Transparency)
        end
        ColorPicker:Display()
        ColorPicker.DisplayFrame = DisplayFrame
        Options[Idx] = ColorPicker
        return self
    end

    function Funcs:AddColorPickerAlpha(Idx, Info)
        Info = Info or {}
        if Info.Transparency == nil then Info.Transparency = 0 end
        return Funcs.AddColorPicker(self, Idx, Info)
    end

    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj = self
        local ToggleLabel = self.TextLabel
        local Container = self.Container
        assert(Info.Default, 'AddKeyPicker: Missing default value.')
        if not Info.Text and Info.Label then Info.Text = Info.Label end
        local KeyPicker = {
            Value = Info.Default or 'None',
            Text = Info.Text or Info.Label or 'Key',
            Toggled = false,
            Mode = Info.Mode or 'Toggle',
            Type = 'KeyPicker',
            Callback = Info.Callback or function(Value) end,
            ChangedCallback = Info.ChangedCallback or function(New) end,
            SyncToggleState = Info.SyncToggleState or false,
        }
        if KeyPicker.SyncToggleState then
            Info.Modes = { 'Toggle' }
            Info.Mode = 'Toggle'
        end
        local PickOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(0, 28, 0, 15),
            ZIndex = 6,
            Parent = ToggleLabel,
        })
        local PickInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 7,
            Parent = PickOuter,
        })
        Library:AddToRegistry(PickInner, {
            BackgroundColor3 = 'BackgroundColor',
            BorderColor3 = 'OutlineColor',
        })
        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0),
            TextSize = Library.FontSize - 1,
            Text = Info.Default,
            TextWrapped = true,
            ZIndex = 8,
            Parent = PickInner,
        })
        local ModeSelectOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1),
            Size = UDim2.new(0, 60, 0, 45 + 2),
            Visible = false,
            ZIndex = 14,
            Parent = ScreenGui,
        })
        ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            ModeSelectOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1)
        end)
        local ModeSelectInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 15,
            Parent = ModeSelectOuter,
        })
        Library:AddToRegistry(ModeSelectInner, {
            BackgroundColor3 = 'BackgroundColor',
            BorderColor3 = 'OutlineColor',
        })
        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ModeSelectInner,
        })
        local KeybindEntry = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Visible = false,
            ZIndex = 110,
            Parent = Library.KeybindContainer,
        })
        local ContainerLabel = Library:CreateLabel({
            Position = UDim2.new(0, 2, 0, 0),
            Size = UDim2.new(1, -4, 1, 0),
            TextSize = Library.FontSize - 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 111,
            Parent = KeybindEntry,
        }, true)
        local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold' }
        local ModeButtons = {}
        for Idx, Mode in next, Modes do
            local ModeButton = {}
            local Label = Library:CreateLabel({
                Active = false,
                Size = UDim2.new(1, 0, 0, 15),
                TextSize = Library.FontSize - 1,
                Text = Mode,
                ZIndex = 16,
                Parent = ModeSelectInner,
            })
            function ModeButton:Select()
                for _, Button in next, ModeButtons do Button:Deselect() end
                KeyPicker.Mode = Mode
                Label.TextColor3 = Library.AccentColor
                Library.RegistryMap[Label].Properties.TextColor3 = 'AccentColor'
                ModeSelectOuter.Visible = false
            end
            function ModeButton:Deselect()
                KeyPicker.Mode = nil
                Label.TextColor3 = Library.FontColor
                Library.RegistryMap[Label].Properties.TextColor3 = 'FontColor'
            end
            Label.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    ModeButton:Select()
                    Library:AttemptSave()
                end
            end)
            if Mode == KeyPicker.Mode then ModeButton:Select() end
            ModeButtons[Mode] = ModeButton
        end
        function KeyPicker:Update()
            if Info.NoUI then return end
            local State = KeyPicker:GetState()
            local displayKey = (KeyPicker.Value == nil or KeyPicker.Value == 'None') and '...' or tostring(KeyPicker.Value)
            local displayText = tostring(Info.Text or Info.Label or KeyPicker.Text or 'Key')
            local displayMode = tostring(KeyPicker.Mode or Info.Mode or 'Toggle')
            ContainerLabel.Text = string.format('[%s] %s (%s)', displayKey, displayText, displayMode)
            local kbMode = Library.KeybindMode or 'All'
            if kbMode == 'Active' then
                KeybindEntry.Visible = State == true
            elseif kbMode == 'Toggled' then
                local parentOn = false
                if ParentObj and ParentObj.Type == 'Toggle' then
                    parentOn = ParentObj.Value == true
                elseif KeyPicker.SyncToggleState and ParentObj then
                    parentOn = ParentObj.Value == true
                else
                    parentOn = true
                end
                KeybindEntry.Visible = parentOn
            else
                KeybindEntry.Visible = true
            end
            ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor
            Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and 'AccentColor' or 'FontColor'
            local YSize = 0
            local XSize = 0
            for _, Frame in next, Library.KeybindContainer:GetChildren() do
                if Frame:IsA('Frame') and Frame.Visible then
                    YSize = YSize + 18
                    local LabelChild = Frame:FindFirstChildOfClass('TextLabel')
                    if LabelChild and (LabelChild.TextBounds.X + 20 > XSize) then
                        XSize = LabelChild.TextBounds.X + 20
                    end
                end
            end
            Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 10 + 15, 210), 0, YSize + 23)
        end
        function KeyPicker:GetState()
            if KeyPicker.Mode == 'Always' then
                return true
            elseif KeyPicker.Mode == 'Hold' then
                if KeyPicker.Value == 'None' then return false end
                local Key = KeyPicker.Value
                if Key == 'MB1' or Key == 'MB2' or Key == 'Touch' then
                    return Key == 'MB1' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or Key == 'MB2' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                        or Key == 'Touch' and true
                else
                    return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value])
                end
            else
                return KeyPicker.Toggled
            end
        end
        function KeyPicker:SetValue(Data)
            local Key, Mode = Data[1], Data[2]
            DisplayLabel.Text = Key
            KeyPicker.Value = Key
            ModeButtons[Mode]:Select()
            KeyPicker:Update()
        end
        function KeyPicker:OnClick(Callback) KeyPicker.Clicked = Callback end
        function KeyPicker:OnChanged(Callback)
            KeyPicker.Changed = Callback
            Callback(KeyPicker.Value)
        end
        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
            table.insert(Library.KeyPickerList, KeyPicker)
        end
        function KeyPicker:DoClick()
            if ParentObj.Type == 'Toggle' and KeyPicker.SyncToggleState then
                ParentObj:SetValue(not ParentObj.Value)
            end
            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
        end
        local Picking = false
        local LongPressTime = Info.LongPressTime or 0.55
        local TouchMoveThreshold = Info.TouchMoveThreshold or 10
        local function OpenModeSelect() ModeSelectOuter.Visible = true end
        local function BeginPicking()
            if Picking then return end
            Picking = true
            DisplayLabel.Text = ''
            local Break
            local Text = ''
            task.spawn(function()
                while not Break do
                    if Text == '...' then Text = '' end
                    Text = Text .. '.'
                    DisplayLabel.Text = Text
                    wait(0.4)
                end
            end)
            wait(0.2)
            local Event
            Event = InputService.InputBegan:Connect(function(Input)
                local Key
                if Input.UserInputType == Enum.UserInputType.Keyboard then
                    Key = Input.KeyCode.Name
                elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Key = 'MB1'
                elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                    Key = 'MB2'
                elseif Input.UserInputType == Enum.UserInputType.Touch then
                    Key = 'Touch'
                end
                if not Key then return end
                Break = true
                Picking = false
                DisplayLabel.Text = Key
                KeyPicker.Value = Key
                Library:SafeCallback(KeyPicker.ChangedCallback, Input.KeyCode or Input.UserInputType)
                Library:SafeCallback(KeyPicker.Changed, Input.KeyCode or Input.UserInputType)
                Library:AttemptSave()
                Event:Disconnect()
            end)
        end
        PickOuter.InputBegan:Connect(function(Input)
            if Library:MouseIsOverOpenedFrame() then return end
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                BeginPicking()
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                OpenModeSelect()
            elseif Input.UserInputType == Enum.UserInputType.Touch then
                local StartPosition = Input.Position
                local TouchMoved = false
                local TouchEnded = false
                local LongPressed = false
                local ChangedConn
                local EndedConn
                ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change == Input then
                        if (Change.Position - StartPosition).Magnitude > TouchMoveThreshold then
                            TouchMoved = true
                        end
                    end
                end)
                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input then
                        TouchEnded = true
                        if ChangedConn then ChangedConn:Disconnect() end
                        if EndedConn then EndedConn:Disconnect() end
                        if (not LongPressed) and (not TouchMoved) then
                            task.spawn(BeginPicking)
                        end
                    end
                end)
                task.delay(LongPressTime, function()
                    if TouchEnded or TouchMoved then return end
                    LongPressed = true
                    if ChangedConn then ChangedConn:Disconnect() end
                    if EndedConn then EndedConn:Disconnect() end
                    OpenModeSelect()
                end)
            end
        end)
        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if not Picking then
                if KeyPicker.Mode == 'Toggle' then
                    local Key = KeyPicker.Value
                    if Key == 'MB1' or Key == 'MB2' or Key == 'Touch' then
                        if Key == 'MB1' and Input.UserInputType == Enum.UserInputType.MouseButton1
                        or Key == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2
                        or Key == 'Touch' and Input.UserInputType == Enum.UserInputType.Touch then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode.Name == Key then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end
                    end
                end
                KeyPicker:Update()
            end
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize
                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then
                    ModeSelectOuter.Visible = false
                end
            end
        end))
        Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
            if not Picking then KeyPicker:Update() end
        end))
        KeyPicker:Update()
        Options[Idx] = KeyPicker
        return self
    end

    BaseAddons.__index = Funcs
    BaseAddons.__namecall = function(Table, Key, ...)
        return Funcs[Key](...)
    end
end

local BaseGroupbox = {}
do
    local Funcs = {}

    function Funcs:AddBlank(Size)
        local Groupbox = self
        local Container = Groupbox.Container
        Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Size),
            ZIndex = 1,
            Parent = Container,
        })
    end

    function Funcs:AddRow(Columns)
        local Groupbox = self
        local Container = Groupbox.Container
        local ColumnsCount = type(Columns) == 'number' and math.max(1, Columns) or 2
        local RowOuter = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            ZIndex = 1,
            Parent = Container,
        })
        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = RowOuter,
        })
        local Boxes = {}
        for i = 1, ColumnsCount do
            local Box = { Type = 'Groupbox' }
            local BoxContainer = Library:Create('Frame', {
                BackgroundTransparency = 1,
                Size = UDim2.new(1 / ColumnsCount, -((ColumnsCount - 1) * 8) / ColumnsCount, 1, 0),
                ZIndex = 1,
                Parent = RowOuter,
            })
            local BoxLayout = Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
                Parent = BoxContainer,
            })
            Box.Container = BoxContainer
            setmetatable(Box, BaseGroupbox)
            function Box:Resize()
                local maxHeight = 0
                for _, child in next, RowOuter:GetChildren() do
                    if child:IsA('Frame') then
                        local layout = child:FindFirstChildOfClass('UIListLayout')
                        if layout and layout.AbsoluteContentSize.Y > maxHeight then
                            maxHeight = layout.AbsoluteContentSize.Y
                        end
                    end
                end
                RowOuter.Size = UDim2.new(1, 0, 0, maxHeight)
                if Groupbox.Resize then Groupbox:Resize() end
            end
            BoxLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function() Box:Resize() end)
            table.insert(Boxes, Box)
        end
        Groupbox:AddBlank(1)
        if Groupbox.Resize then Groupbox:Resize() end
        return unpack(Boxes)
    end

    function Funcs:AddLabel(Text, DoesWrap)
        local Label = {}
        local Groupbox = self
        local Container = Groupbox.Container
        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15),
            TextSize = Library.FontSize,
            Text = Text,
            TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
            Parent = Container,
        })
        if DoesWrap then
            local Y = select(2, Library:GetTextBounds(Text, Library.Font, Library.FontSize, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
            TextLabel.Size = UDim2.new(1, -4, 0, Y)
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4),
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = TextLabel,
            })
        end
        Label.TextLabel = TextLabel
        Label.Container = Container
        function Label:SetText(Text)
            TextLabel.Text = Text
            if DoesWrap then
                local Y = select(2, Library:GetTextBounds(Text, Library.Font, Library.FontSize, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                TextLabel.Size = UDim2.new(1, -4, 0, Y)
            end
            Groupbox:Resize()
        end
        if not DoesWrap then setmetatable(Label, BaseAddons) end
        Groupbox:AddBlank(5)
        Groupbox:Resize()
        return Label
    end

    function Funcs:AddButton(...)
        local Button = {}
        local function ProcessButtonParams(Class, Obj, ...)
            local Props = select(1, ...)
            if type(Props) == 'table' then
                Obj.Text = Props.Text
                Obj.Func = Props.Func
                Obj.DoubleClick = Props.DoubleClick
                Obj.Tooltip = Props.Tooltip
            else
                Obj.Text = select(1, ...)
                Obj.Func = select(2, ...)
            end
            assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing.')
        end
        ProcessButtonParams('Button', Button, ...)
        local Groupbox = self
        local Container = Groupbox.Container
        local function CreateBaseButton(Button)
            local Outer = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderColor3 = Color3.new(0, 0, 0),
                Size = UDim2.new(1, -4, 0, 20),
                ZIndex = 5,
            })
            local Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor,
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 6,
                Parent = Outer,
            })
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0),
                TextSize = Library.FontSize,
                Text = Button.Text,
                ZIndex = 6,
                Parent = Inner,
            })
            Library:Create('UIGradient', {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212)),
                }),
                Rotation = 90,
                Parent = Inner,
            })
            Library:AddToRegistry(Outer, { BorderColor3 = 'Black' })
            Library:AddToRegistry(Inner, {
                BackgroundColor3 = 'MainColor',
                BorderColor3 = 'OutlineColor',
            })
            Library:OnHighlight(Outer, Outer,
                { BorderColor3 = 'AccentColor' },
                { BorderColor3 = 'Black' }
            )
            return Outer, Inner
        end
        local function InitEvents(Button)
            local function WaitForEvent(event, timeout, validator)
                local bindable = Instance.new('BindableEvent')
                local connection = event:Once(function(...)
                    if type(validator) == 'function' and validator(...) then
                        bindable:Fire(true)
                    else
                        bindable:Fire(false)
                    end
                end)
                task.delay(timeout, function()
                    connection:disconnect()
                    bindable:Fire(false)
                end)
                return bindable.Event:Wait()
            end
            local function ValidateClick(Input)
                if Library:MouseIsOverOpenedFrame() then return false end
                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return false end
                return true
            end
            Button.Outer.InputBegan:Connect(function(Input)
                if not ValidateClick(Input) then return end
                if Button.Locked then return end
                if Button.DoubleClick then
                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'AccentColor' })
                    Button.Label.TextColor3 = Library.AccentColor
                    Button.Label.Text = 'Are you sure?'
                    Button.Locked = true
                    local clicked = WaitForEvent(Button.Outer.InputBegan, 0.5, ValidateClick)
                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'FontColor' })
                    Button.Label.TextColor3 = Library.FontColor
                    Button.Label.Text = Button.Text
                    task.defer(rawset, Button, 'Locked', false)
                    if clicked then Library:SafeCallback(Button.Func) end
                    return
                end
                Library:SafeCallback(Button.Func)
            end)
        end
        Button.Outer, Button.Inner = CreateBaseButton(Button)
        Button.Label = Button.Inner:FindFirstChildOfClass('TextLabel')
        Button.Outer.Parent = Container
        InitEvents(Button)
        function Button:AddTooltip(tooltip)
            if type(tooltip) == 'string' then Library:AddToolTip(tooltip, self.Outer) end
            return self
        end
        function Button:AddButton(...)
            local SubButton = {}
            ProcessButtonParams('SubButton', SubButton, ...)
            self.Outer.Size = UDim2.new(0.5, -2, 0, 20)
            SubButton.Outer, SubButton.Inner = CreateBaseButton(SubButton)
            SubButton.Label = SubButton.Inner:FindFirstChildOfClass('TextLabel')
            SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
            SubButton.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X - 2, self.Outer.AbsoluteSize.Y)
            SubButton.Outer.Parent = self.Outer
            function SubButton:AddTooltip(tooltip)
                if type(tooltip) == 'string' then Library:AddToolTip(tooltip, self.Outer) end
                return SubButton
            end
            if type(SubButton.Tooltip) == 'string' then SubButton:AddTooltip(SubButton.Tooltip) end
            InitEvents(SubButton)
            return SubButton
        end
        if type(Button.Tooltip) == 'string' then Button:AddTooltip(Button.Tooltip) end
        Groupbox:AddBlank(5)
        Groupbox:Resize()
        return Button
    end

    function Funcs:AddDivider()
        local Groupbox = self
        local Container = self.Container
        Groupbox:AddBlank(2)
        local DividerOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, -4, 0, 5),
            ZIndex = 5,
            Parent = Container,
        })
        local DividerInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = DividerOuter,
        })
        Library:AddToRegistry(DividerOuter, { BorderColor3 = 'Black' })
        Library:AddToRegistry(DividerInner, {
            BackgroundColor3 = 'MainColor',
            BorderColor3 = 'OutlineColor',
        })
        Groupbox:AddBlank(9)
        Groupbox:Resize()
    end

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')
        local Textbox = {
            Value = Info.Default or '',
            Numeric = Info.Numeric or false,
            Finished = Info.Finished or false,
            Type = 'Input',
            Callback = Info.Callback or function(Value) end,
        }
        local Groupbox = self
        local Container = Groupbox.Container
        Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 15),
            TextSize = Library.FontSize,
            Text = Info.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
            Parent = Container,
        })
        Groupbox:AddBlank(1)
        local TextBoxOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, -4, 0, 20),
            ZIndex = 5,
            Parent = Container,
        })
        local TextBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = TextBoxOuter,
        })
        Library:AddToRegistry(TextBoxInner, {
            BackgroundColor3 = 'MainColor',
            BorderColor3 = 'OutlineColor',
        })
        Library:OnHighlight(TextBoxOuter, TextBoxOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        )
        if type(Info.Tooltip) == 'string' then Library:AddToolTip(Info.Tooltip, TextBoxOuter) end
        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212)),
            }),
            Rotation = 90,
            Parent = TextBoxInner,
        })
        local InnerContainer = Library:Create('Frame', {
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Position = UDim2.new(0, 5, 0, 0),
            Size = UDim2.new(1, -5, 1, 0),
            ZIndex = 7,
            Parent = TextBoxInner,
        })
        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(5, 1),
            Font = Library.Font,
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190),
            PlaceholderText = Info.Placeholder or '',
            Text = Info.Default or '',
            TextColor3 = Library.FontColor,
            TextSize = Library.FontSize,
            TextStrokeTransparency = 0,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 7,
            Parent = InnerContainer,
        })
        Library:ApplyTextStroke(Box)
        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then Text = Text:sub(1, Info.MaxLength) end
            if Textbox.Numeric and (not tonumber(Text)) and Text:len() > 0 then Text = Textbox.Value end
            Textbox.Value = Text
            Box.Text = Text
            Library:SafeCallback(Textbox.Callback, Textbox.Value)
            Library:SafeCallback(Textbox.Changed, Textbox.Value)
        end
        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                if not enter then return end
                Textbox:SetValue(Box.Text)
                Library:AttemptSave()
            end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text)
                Library:AttemptSave()
            end)
        end
        Library:AddToRegistry(Box, { TextColor3 = 'FontColor' })
        function Textbox:OnChanged(Func)
            Textbox.Changed = Func
            Func(Textbox.Value)
        end
        Groupbox:AddBlank(5)
        Groupbox:Resize()
        Options[Idx] = Textbox
        return Textbox
    end

    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Toggle = {
            Value = Info.Default or false;
            Type = 'Toggle';

            Callback = Info.Callback or function(Value) end;
            Addons = {},
            Risky = Info.Risky,
        };
        local Groupbox = self;
        local Container = Groupbox.Container;

        local ToggleOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 13, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });
        Library:AddToRegistry(ToggleOuter, {
            BorderColor3 = 'Black';
        });
        local ToggleInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = ToggleOuter;
        });
        Library:AddToRegistry(ToggleInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(0, 216, 1, 0);
            Position = UDim2.new(1, 6, 0, 0);
            TextSize = Library.FontSize;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6;
            Parent = ToggleInner;
        });
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 4);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ToggleLabel;
        });
        local ToggleRegion = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 170, 1, 0);
            ZIndex = 8;
            Parent = ToggleOuter;
        });
        Library:OnHighlight(ToggleRegion, ToggleOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );
        function Toggle:UpdateColors()
            Toggle:Display();
        end;
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, ToggleRegion)
        end

        function Toggle:Display()
            ToggleInner.BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor;
            ToggleInner.BorderColor3 = Toggle.Value and Library.AccentColorDark or Library.OutlineColor;

            Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and 'AccentColor' or 'MainColor';
            Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and 'AccentColorDark' or 'OutlineColor';
        end;

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func;
            Func(Toggle.Value);
        end;

        function Toggle:SetValue(Bool)
            Bool = (not not Bool);
            Toggle.Value = Bool;
            Toggle:Display();

            for _, Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool
                    Addon:Update()
                end
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value);
            Library:SafeCallback(Toggle.Changed, Toggle.Value);
            Library:UpdateDependencyBoxes();
        end;
        ToggleRegion.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                Toggle:SetValue(not Toggle.Value)
                Library:AttemptSave();
            end;
        end);
        if Toggle.Risky then
            Library:RemoveFromRegistry(ToggleLabel)
            ToggleLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(ToggleLabel, { TextColor3 = 'RiskColor' })
        end

        Toggle:Display();
        Groupbox:AddBlank(Info.BlankSize or 5 + 2);
        Groupbox:Resize();

        Toggle.TextLabel = ToggleLabel;
        Toggle.Container = Container;
        setmetatable(Toggle, BaseAddons);

        Toggles[Idx] = Toggle;

        Library:UpdateDependencyBoxes();

        return Toggle;
    end;

    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default, 'AddSlider: Missing default value.');
        assert(Info.Text, 'AddSlider: Missing slider text.');
        assert(Info.Min, 'AddSlider: Missing minimum value.');
        assert(Info.Max, 'AddSlider: Missing maximum value.');
        assert(Info.Rounding, 'AddSlider: Missing rounding value.');
        local Slider = {
            Value = Info.Default;
            Min = Info.Min;
            Max = Info.Max;
            Rounding = Info.Rounding;
            MaxSize = 232;
            Type = 'Slider';
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;
        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = Library.FontSize;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });
            Groupbox:AddBlank(3);
        end

        local SliderOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });
        Library:AddToRegistry(SliderOuter, {
            BorderColor3 = 'Black';
        });
        local SliderInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = SliderOuter;
        });
        Library:AddToRegistry(SliderInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        local function RefreshSliderMaxSize()
            local w = SliderInner.AbsoluteSize.X
            if w and w > 1 then
                Slider.MaxSize = w
            end
        end
        task.defer(RefreshSliderMaxSize)
        SliderInner:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
            RefreshSliderMaxSize()
            pcall(function() Slider:Display() end)
        end)
        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderColor3 = Library.AccentColorDark;
            Size = UDim2.new(0, 0, 1, 0);
            ZIndex = 7;
            Parent = SliderInner;
        });
        Library:AddToRegistry(Fill, {
            BackgroundColor3 = 'AccentColor';
            BorderColor3 = 'AccentColorDark';
        });
        local HideBorderRight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(1, 0, 0, 0);
            Size = UDim2.new(0, 1, 1, 0);
            ZIndex = 8;
            Parent = Fill;
        });

        Library:AddToRegistry(HideBorderRight, {
            BackgroundColor3 = 'AccentColor';
        });
        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = Library.FontSize;
            Text = 'Infinite';
            ZIndex = 9;
            Parent = SliderInner;
        });
        Library:OnHighlight(SliderOuter, SliderOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, SliderOuter)
        end

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.AccentColor;
            Fill.BorderColor3 = Library.AccentColorDark;
        end;

        function Slider:Display()
            local Suffix = Info.Suffix or '';
            if Info.Compact then
                DisplayLabel.Text = Info.Text .. ': ' .. Slider.Value .. Suffix
            elseif Info.HideMax then
                DisplayLabel.Text = string.format('%s', Slider.Value .. Suffix)
            else
                DisplayLabel.Text = string.format('%s/%s', Slider.Value .. Suffix, Slider.Max .. Suffix);
            end

            local max = SliderInner.AbsoluteSize.X
            if max and max > 1 then Slider.MaxSize = max else max = Slider.MaxSize or 1 end
            local pct = 0
            if Slider.Max ~= Slider.Min then
                pct = math.clamp((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1)
            end
            local target = UDim2.new(pct, 0, 1, 0);
            if Library.SliderAnimations == false then
                Fill.Size = target
            else
                pcall(function()
                    TweenService:Create(Fill, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = target,
                    }):Play()
                end)
            end

            local fillW = pct * (Slider.MaxSize or 1)
            HideBorderRight.Visible = fillW < (Slider.MaxSize or 0) and fillW > 0
        end;
        function Slider:OnChanged(Func)
            Slider.Changed = Func;
            Func(Slider.Value);
        end;
        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value);
            end;


            return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value))
        end;
        function Slider:GetValueFromXOffset(X)
            local max = SliderInner.AbsoluteSize.X
            if not max or max < 1 then max = Slider.MaxSize end
            Slider.MaxSize = max
            return Round(Library:MapValue(X, 0, max, Slider.Min, Slider.Max));
        end;
        function Slider:SetValue(Str)
            local Num = tonumber(Str);
            if (not Num) then
                return;
            end;

            Num = math.clamp(Num, Slider.Min, Slider.Max);

            Slider.Value = Num;
            Slider:Display();

            Library:SafeCallback(Slider.Callback, Slider.Value);
            Library:SafeCallback(Slider.Changed, Slider.Value);
        end;
        SliderInner.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                
                local function UpdateSlider(PosX)
                    local gPos = SliderInner.AbsolutePosition.X
                    local maxW = SliderInner.AbsoluteSize.X
                    if maxW and maxW > 1 then Slider.MaxSize = maxW end
                    local Diff = PosX - gPos
                    local nX = math.clamp(Diff, 0, Slider.MaxSize)

                    local nValue = Slider:GetValueFromXOffset(nX);
                    local OldValue = Slider.Value;
    
                    Slider.Value = nValue;

                    Slider:Display();

                    if nValue ~= OldValue then
                        Library:SafeCallback(Slider.Callback, Slider.Value);
                        Library:SafeCallback(Slider.Changed, Slider.Value);
                    end;
                end

                UpdateSlider(Input.Position.X)

                local ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                        UpdateSlider(Change.Position.X)
                    end
                end)

                local EndedConn
                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                        ChangedConn:Disconnect()
                        EndedConn:Disconnect()
                        Library:AttemptSave()
                    end
                end)
            end;
        end);

        Slider:Display();
        Groupbox:AddBlank(Info.BlankSize or 6);
        Groupbox:Resize();

        Options[Idx] = Slider;

        return Slider;
    end;
    function Funcs:AddDropdown(Idx, Info)
        if Info.SpecialType == 'Player' then
            Info.Values = GetPlayersString()
            Info.AllowNull = true
        elseif Info.SpecialType == 'Team' then
            Info.Values = GetTeamsString()
            Info.AllowNull = true
        end
        assert(Info.Values, 'AddDropdown: Missing dropdown value list.')
        assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.')
        if not Info.Text then Info.Compact = true end
        local Dropdown = {
            Values = Info.Values,
            Value = Info.Multi and {},
            Multi = Info.Multi,
            Type = 'Dropdown',
            SpecialType = Info.SpecialType,
            Callback = Info.Callback or function(Value) end,
        }
        local Groupbox = self
        local Container = Groupbox.Container
        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10),
                TextSize = Library.FontSize,
                Text = Info.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                ZIndex = 5,
                Parent = Container,
            })
            Groupbox:AddBlank(3)
        end
        local DropdownOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, -4, 0, 20),
            ZIndex = 5,
            Parent = Container,
        })
        Library:AddToRegistry(DropdownOuter, { BorderColor3 = 'Black' })
        local DropdownInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = DropdownOuter,
        })
        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = 'MainColor',
            BorderColor3 = 'OutlineColor',
        })
        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212)),
            }),
            Rotation = 90,
            Parent = DropdownInner,
        })
        local DropdownArrow = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -16, 0.5, 0),
            Size = UDim2.new(0, 12, 0, 12),
            Image = 'http://www.roblox.com/asset/?id=6282522798',
            ZIndex = 8,
            Parent = DropdownInner,
        })
        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0),
            Size = UDim2.new(1, -5, 1, 0),
            TextSize = Library.FontSize,
            Text = '--',
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            ZIndex = 7,
            Parent = DropdownInner,
        })
        Library:OnHighlight(DropdownOuter, DropdownOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        )
        if type(Info.Tooltip) == 'string' then Library:AddToolTip(Info.Tooltip, DropdownOuter) end
        local MAX_DROPDOWN_ITEMS = 8
        local ListOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            ZIndex = 20,
            Visible = false,
            Parent = ScreenGui,
        })
        local function RecalculateListPosition()
            ListOuter.Position = UDim2.fromOffset(DropdownOuter.AbsolutePosition.X, DropdownOuter.AbsolutePosition.Y + DropdownOuter.Size.Y.Offset + 1)
        end
        local function RecalculateListSize(YSize)
            ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, YSize or (MAX_DROPDOWN_ITEMS * 20 + 2))
        end
        RecalculateListPosition()
        RecalculateListSize()
        DropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RecalculateListPosition)
        local ListInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 21,
            Parent = ListOuter,
        })
        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = 'MainColor',
            BorderColor3 = 'OutlineColor',
        })
        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 21,
            Parent = ListInner,
            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
        })
        Library:AddToRegistry(Scrolling, { ScrollBarImageColor3 = 'AccentColor' })
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 0),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Scrolling,
        })
        function Dropdown:Display()
            local Values = Dropdown.Values
            local Str = ''
            if Info.Multi then
                for Idx, Value in next, Values do
                    if Dropdown.Value[Value] then Str = Str .. Value .. ', ' end
                end
                Str = Str:sub(1, #Str - 2)
            else
                Str = Dropdown.Value or ''
            end
            ItemList.Text = (Str == '' and '--' or Str)
        end
        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {}
                for Value, Bool in next, Dropdown.Value do table.insert(T, Value) end
                return T
            else
                return Dropdown.Value and 1 or 0
            end
        end
        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values
            local Buttons = {}
            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA('UIListLayout') then Element:Destroy() end
            end
            local Count = 0
            for Idx, Value in next, Values do
                local Table = {}
                Count = Count + 1
                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor,
                    BorderColor3 = Library.OutlineColor,
                    BorderMode = Enum.BorderMode.Middle,
                    Size = UDim2.new(1, -1, 0, 20),
                    ZIndex = 23,
                    Active = true,
                    Parent = Scrolling,
                })
                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor',
                    BorderColor3 = 'OutlineColor',
                })
                local ButtonLabel = Library:CreateLabel({
                    Active = false,
                    Size = UDim2.new(1, -6, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    TextSize = Library.FontSize,
                    Text = Value,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 25,
                    Parent = Button,
                })
                Library:OnHighlight(Button, Button,
                    { BorderColor3 = 'AccentColor', ZIndex = 24 },
                    { BorderColor3 = 'OutlineColor', ZIndex = 23 }
                )
                local Selected
                if Info.Multi then
                    Selected = Dropdown.Value[Value]
                else
                    Selected = Dropdown.Value == Value
                end
                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value]
                    else
                        Selected = Dropdown.Value == Value
                    end
                    ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor'
                end
                ButtonLabel.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        local Try = not Selected
                        if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
                        else
                            if Info.Multi then
                                Selected = Try
                                if Selected then Dropdown.Value[Value] = true
                                else Dropdown.Value[Value] = nil end
                            else
                                Selected = Try
                                if Selected then Dropdown.Value = Value
                                else Dropdown.Value = nil end
                                for _, OtherButton in next, Buttons do OtherButton:UpdateButton() end
                            end
                            Table:UpdateButton()
                            Dropdown:Display()
                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                            Library:AttemptSave()
                        end
                    end
                end)
                Table:UpdateButton()
                Dropdown:Display()
                Buttons[Button] = Table
            end
            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 20) + 1)
            local Y = math.clamp(Count * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 1
            RecalculateListSize(Y)
        end
        function Dropdown:SetValues(NewValues)
            if NewValues then Dropdown.Values = NewValues end
            Dropdown:BuildDropdownList()
        end
        function Dropdown:OpenDropdown()
            ListOuter.Visible = true
            Library.OpenedFrames[ListOuter] = true
            DropdownArrow.Rotation = 180
        end
        function Dropdown:CloseDropdown()
            ListOuter.Visible = false
            Library.OpenedFrames[ListOuter] = nil
            DropdownArrow.Rotation = 0
        end
        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func
            Func(Dropdown.Value)
        end
        function Dropdown:SetValue(Val)
            if Dropdown.Multi then
                local nTable = {}
                for Value, Bool in next, Val do
                    if table.find(Dropdown.Values, Value) then nTable[Value] = true end
                end
                Dropdown.Value = nTable
            else
                if not Val then Dropdown.Value = nil
                elseif table.find(Dropdown.Values, Val) then Dropdown.Value = Val end
            end
            Dropdown:BuildDropdownList()
            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
        end
        DropdownOuter.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then Dropdown:CloseDropdown()
                else Dropdown:OpenDropdown() end
            end
        end)
        InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize
                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then
                    Dropdown:CloseDropdown()
                end
            end
        end)
        Dropdown:BuildDropdownList()
        Dropdown:Display()
        local Defaults = {}
        if type(Info.Default) == 'string' then
            local i = table.find(Dropdown.Values, Info.Default)
            if i then table.insert(Defaults, i) end
        elseif type(Info.Default) == 'table' then
            for _, Value in next, Info.Default do
                local i = table.find(Dropdown.Values, Value)
                if i then table.insert(Defaults, i) end
            end
        elseif type(Info.Default) == 'number' and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end
        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index]
                end
                if not Info.Multi then break end
            end
            Dropdown:BuildDropdownList()
            Dropdown:Display()
        end
        Groupbox:AddBlank(Info.BlankSize or 5)
        Groupbox:Resize()
        Options[Idx] = Dropdown
        return Dropdown
    end

    function Funcs:AddDependencyBox()
        local Depbox = { Dependencies = {} }
        local Groupbox = self
        local Container = Groupbox.Container
        local Holder = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false,
            Parent = Container,
        })
        local Frame = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = true,
            Parent = Holder,
        })
        local Layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Frame,
        })
        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y)
            Groupbox:Resize()
        end
        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function() Depbox:Resize() end)
        Holder:GetPropertyChangedSignal('Visible'):Connect(function() Depbox:Resize() end)
        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1]
                local Value = Dependency[2]
                if Elem.Type == 'Toggle' and Elem.Value ~= Value then
                    Holder.Visible = false
                    Depbox:Resize()
                    return
                end
            end
            Holder.Visible = true
            Depbox:Resize()
        end
        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in next, Dependencies do
                assert(type(Dependency) == 'table', 'SetupDependencies: Dependency is not of type `table`.')
                assert(Dependency[1], 'SetupDependencies: Dependency is missing element argument.')
                assert(Dependency[2] ~= nil, 'SetupDependencies: Dependency is missing value argument.')
            end
            Depbox.Dependencies = Dependencies
            Depbox:Update()
        end
        Depbox.Container = Frame
        setmetatable(Depbox, BaseGroupbox)
        table.insert(Library.DependencyBoxes, Depbox)
        return Depbox
    end

    BaseGroupbox.__index = Funcs
    BaseGroupbox.__namecall = function(Table, Key, ...)
        return Funcs[Key](...)
    end
end

do
    Library.NotificationStack = {}
    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(0, 320, 1, -50),
        ZIndex = 100,
        Parent = ScreenGui,
    })
    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 4),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Library.NotificationArea,
    })
    function Library:ConfigureNotifications(Cfg)
        local C = Library.NotifyConfig
        for k, v in next, Cfg do C[k] = v end
        local AnchorX = C.Alignment == "Left" and 0 or (C.Alignment == "Right" and 1 or 0.5)
        local AnchorY = C.BarSide == "Top" and 0 or 1
        local VAlign = C.BarSide == "Top" and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom
        local HAlign = C.Alignment == "Left" and Enum.HorizontalAlignment.Left or (C.Alignment == "Right" and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Center)
        Library.NotificationArea.AnchorPoint = Vector2.new(AnchorX, AnchorY)
        Library.NotificationArea.Position = UDim2.new(C.PosX / 100, 0, C.PosY / 100, 0)
        Library.NotificationArea.ClipsDescendants = C.ClipDescendants
        Library.NotificationArea.AutomaticSize = Enum.AutomaticSize.XY
        local SizeConstraint = Library.NotificationArea:FindFirstChildOfClass('UISizeConstraint')
        if C.ClipDescendants then
            if not SizeConstraint then
                SizeConstraint = Library:Create('UISizeConstraint', { Parent = Library.NotificationArea })
            end
            SizeConstraint.MaxSize = Vector2.new(math.huge, C.MaxHeight)
        elseif SizeConstraint then
            SizeConstraint:Destroy()
        end
        local Layout = Library.NotificationArea:FindFirstChildOfClass('UIListLayout')
        if Layout then
            Layout.VerticalAlignment = VAlign
            Layout.HorizontalAlignment = HAlign
        end
    end
    Library:ConfigureNotifications({})
    local WatermarkOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0),
        Position = UDim2.new(0, 100, 0, -25),
        Size = UDim2.new(0, 213, 0, 20),
        ZIndex = 200,
        Visible = false,
        Parent = ScreenGui,
    })
    local WatermarkInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.AccentColor,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 201,
        Parent = WatermarkOuter,
    })
    Library:AddToRegistry(WatermarkInner, { BorderColor3 = 'AccentColor' })
    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 202,
        Parent = WatermarkInner,
    })
    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        }),
        Rotation = -90,
        Parent = InnerFrame,
    })
    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            })
        end,
    })
    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 5, 0, 0),
        Size = UDim2.new(1, -4, 1, 0),
        TextSize = Library.FontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 203,
        Parent = InnerFrame,
    })
    Library.Watermark = WatermarkOuter
    Library.WatermarkText = WatermarkLabel
    Library:MakeDraggable(Library.Watermark)
    local KeybindOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5),
        BorderColor3 = Color3.new(0, 0, 0),
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.new(0, 210, 0, 20),
        Visible = false,
        ZIndex = 100,
        Parent = ScreenGui,
    })
    Library:ApplyGlow(KeybindOuter)
    local KeybindInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 101,
        Parent = KeybindOuter,
    })
    Library:AddToRegistry(KeybindInner, {
        BackgroundColor3 = 'MainColor',
        BorderColor3 = 'OutlineColor',
    }, true)
    local ColorFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        ZIndex = 102,
        Parent = KeybindInner,
    })
    Library:AddToRegistry(ColorFrame, { BackgroundColor3 = 'AccentColor' }, true)
    Library.KeybindInner = KeybindInner
    Library.KeybindColorFrame = ColorFrame
    Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 2),
        TextXAlignment = Enum.TextXAlignment.Center,
        Text = 'Keybinds',
        ZIndex = 104,
        Parent = KeybindInner,
    })
    local KeybindContainer = Library:Create('Frame', {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -20),
        Position = UDim2.new(0, 0, 0, 20),
        ZIndex = 1,
        Parent = KeybindInner,
    })
    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = KeybindContainer,
    })
    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        Parent = KeybindContainer,
    })
    Library.KeybindFrame = KeybindOuter
    Library.KeybindContainer = KeybindContainer
    Library:MakeDraggable(KeybindOuter)
end

function Library:SetKeybindMode(Mode)
    assert(Mode == 'All' or Mode == 'Active' or Mode == 'Toggled',
        "SetKeybindMode: Mode must be 'All', 'Active', or 'Toggled'")
    Library.KeybindMode = Mode
    Library:RefreshKeybinds()
end

function Library:RefreshKeybinds()
    for _, kp in ipairs(Library.KeyPickerList) do
        if not kp.NoUI then
            pcall(function() kp:Update() end)
        end
    end
end

function Library:SetWatermarkVisibility(Bool) Library.Watermark.Visible = Bool end

function Library:SetWatermark(Text)
    local X, Y = Library:GetTextBounds(Text, Library.Font, Library.FontSize)
    Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3)
    Library:SetWatermarkVisibility(true)
    Library.WatermarkText.Text = Text
end

function Library:Notify(Text, Time)
    if not Text or Text == "" then return end
    table.insert(Library.NotifyQueue, { Text = Text, Time = Time })
    Library:ProcessNotifyQueue()
end

function Library:ProcessNotifyQueue()
    local C = Library.NotifyConfig
    local ItemHeight = 22 + 4
    while #Library.NotifyQueue > 0 do
        if C.ClipDescendants and (Library.ActiveNotifyCount + 1) * ItemHeight > C.MaxHeight then break end
        local Item = table.remove(Library.NotifyQueue, 1)
        Library:SpawnNotify(Item.Text, Item.Time)
    end
end

function Library:SpawnNotify(Text, Time)
    local xw = (Library:GetTextBounds(Text, Library.CustomFontFace or Library.Font, 13) or 200)
    local H = 22
    local NotifyTransparency = (Library.NotifyConfig.Transparency or 0) / 100
    Library.NotifyCounter = Library.NotifyCounter + 1
    local notifyMain = Library.MainColor
    if Library.NotifyConfig.ForceColor and Library.NotifyConfig.ForceColorValue then
        notifyMain = Library.NotifyConfig.ForceColorValue
    end
    local Outer = Library:Create('Frame', {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(0, H),
        ClipsDescendants = true,
        LayoutOrder = Library.NotifyConfig.SortOrder == "Text Length" and #Text or Library.NotifyCounter,
        ZIndex = 100,
        Parent = Library.NotificationArea,
    })
    local Inner = Library:Create('Frame', {
        BackgroundColor3 = notifyMain,
        BackgroundTransparency = NotifyTransparency,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 101,
        Parent = Outer,
    })
    Library:AddToRegistry(Inner, { BackgroundColor3 = 'MainColor' })
    local InnerStroke = Library:Create('UIStroke', {
        Color = Library.OutlineColor,
        Transparency = NotifyTransparency,
        Thickness = 1,
        Parent = Inner,
    })
    Library:AddToRegistry(InnerStroke, { Color = 'OutlineColor' })
    local GradientFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BackgroundTransparency = NotifyTransparency,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 102,
        Parent = Inner,
    })
    Library:AddToRegistry(GradientFrame, { BackgroundColor3 = 'MainColor' })
    local G = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        }),
        Rotation = -90,
        Parent = GradientFrame,
    })
    Library:AddToRegistry(G, { Color = function()
        return ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        })
    end })
    Library:CreateLabel({
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -8, 1, 0),
        Text = Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 13,
        ZIndex = 103,
        Parent = GradientFrame,
    })
    local BarSide = Library.NotifyConfig.BarSide or "Bottom"
    local AccentBarPos, AccentBarSize
    if BarSide == "Top" then
        AccentBarPos = UDim2.new(0, -1, 0, -1)
        AccentBarSize = UDim2.new(1, 2, 0, 3)
    elseif BarSide == "Bottom" then
        AccentBarPos = UDim2.new(0, -1, 1, -2)
        AccentBarSize = UDim2.new(1, 2, 0, 3)
    elseif BarSide == "Left" then
        AccentBarPos = UDim2.new(0, -1, 0, -1)
        AccentBarSize = UDim2.new(0, 3, 1, 2)
    else
        AccentBarPos = UDim2.new(1, -2, 0, -1)
        AccentBarSize = UDim2.new(0, 3, 1, 2)
    end
    local AccentBar = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Position = AccentBarPos,
        Size = AccentBarSize,
        ZIndex = 104,
        Parent = Outer,
    })
    Library:AddToRegistry(AccentBar, { BackgroundColor3 = 'AccentColor' }, true)
    pcall(Outer.TweenSize, Outer, UDim2.fromOffset(xw + 16, H), 'Out', 'Quad', 0.35, true)
    Library.ActiveNotifyCount = Library.ActiveNotifyCount + 1
    task.spawn(function()
        task.wait(Time or 5)
        pcall(Outer.TweenSize, Outer, UDim2.fromOffset(0, H), 'Out', 'Quad', 0.35, true)
        task.wait(0.4)
        Outer:Destroy()
        Library.ActiveNotifyCount = Library.ActiveNotifyCount - 1
        Library:ProcessNotifyQueue()
    end)
end

function Library:CreateWindow(...)
    local Arguments = { ... }
    local Config = { AnchorPoint = Vector2.zero }
    if type(...) == 'table' then
        Config = ...
    else
        Config.Title = Arguments[1]
        Config.AutoShow = Arguments[2] or false
    end
    if type(Config.Title) ~= 'string' then Config.Title = 'No title' end
    if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 0 end
    if type(Config.MenuFadeTime) ~= 'number' then Config.MenuFadeTime = 0.2 end
    if type(Config.UseBlur) == 'boolean' then Library.UseBlur = Config.UseBlur end
    if type(Config.BlurSize) == 'number' then Library.BlurSize = Config.BlurSize end
    if type(Config.UseDarken) == 'boolean' then Library.UseDarken = Config.UseDarken end
    if type(Config.DarkenAmount) == 'number' then Library.DarkenAmount = Config.DarkenAmount end
    if typeof(Config.Size) ~= 'UDim2' then Config.Size = UDim2.fromOffset(550, 650) end
    if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end
    if InputService.TouchEnabled then
        local vp = Library.ScreenGui.AbsoluteSize
        local maxWidth = math.min(Config.Size.X.Offset, vp.X - 20)
        local maxHeight = math.min(Config.Size.Y.Offset, vp.Y - 60)
        Config.Size = UDim2.fromOffset(maxWidth, maxHeight)
    end
    if Config.Center then
        Config.AnchorPoint = Vector2.new(0.5, 0.5)
        Config.Position = UDim2.fromScale(0.5, 0.5)
    end
    local Window = { Tabs = {} }
    local Outer = Library:Create('Frame', {
        AnchorPoint = Config.AnchorPoint,
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Position = Config.Position,
        Size = Config.Size,
        Visible = false,
        ZIndex = 1,
        Parent = ScreenGui,
    })
    Library:MakeDraggable(Outer, 25, true)

    local OutlineShell = Library:Create('Frame', {
        Name = "OutlineShell",
        BackgroundColor3 = Library.OutlineColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 1,
        Parent = Outer,
    })
    Library:AddToRegistry(OutlineShell, { BackgroundColor3 = 'OutlineColor' })

    local Inner = Library:Create('Frame', {
        Name = "Inner",
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        BorderMode = Enum.BorderMode.Inset,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 1,
        Parent = OutlineShell,
    })
    Library:AddToRegistry(Inner, {
        BackgroundColor3 = 'MainColor',
        BorderColor3 = 'OutlineColor',
    })
    local InnerGloss = Library:Create('Frame', {
        Name = "Vercel_InnerGloss",
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.97,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0.35, 0),
        Position = UDim2.new(0, 0, 0, 0),
        ZIndex = 2,
        Parent = Inner,
    })
    Library:Create('UIGradient', {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Rotation = 90,
        Parent = InnerGloss,
    })
    local WindowLabel = Library:CreateLabel({
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 25),
        Text = Config.Title or '',
        RichText = true,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 1,
        Parent = Inner,
    })
    local MapNameLabel = Library:CreateLabel({
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -7, 0, 0),
        Size = UDim2.new(0, 0, 0, 25),
        Text = 'Loading...',
        TextColor3 = Library.AccentColor,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 1,
        Parent = Inner,
    })
    Library:AddToRegistry(MapNameLabel, { TextColor3 = 'AccentColor' })
    task.spawn(function()
        if type(Config.GameName) == "string" and Config.GameName ~= "" then
            MapNameLabel.Text = Config.GameName
        elseif type(Config.MapName) == "string" and Config.MapName ~= "" then
            MapNameLabel.Text = Config.MapName
        else
            local success, info = pcall(function()
                return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
            end)
            local n = (success and info and info.Name) or game.Name or "Unknown"
            if n == "Matchmaking" or n == "Lobby" or (typeof(game.PlaceId) == "number" and game.PlaceId == 17625359962) then
                n = "Rivals"
            end
            MapNameLabel.Text = n
        end
    end)

    local TabBarOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor,
        BorderColor3 = Library.OutlineColor,
        Position = UDim2.new(0, 8, 0, 25),
        Size = UDim2.new(1, -16, 0, 21),
        ZIndex = 1,
        Parent = Inner,
    })
    Library:AddToRegistry(TabBarOuter, {
        BackgroundColor3 = 'BackgroundColor',
        BorderColor3 = 'OutlineColor',
    })
    local TabBarInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor,
        BorderColor3 = Color3.new(0, 0, 0),
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 1,
        Parent = TabBarOuter,
    })
    Library:AddToRegistry(TabBarInner, { BackgroundColor3 = 'BackgroundColor' })
    local TabSep = Library:Create('Frame', {
        Name = 'TabSeparator',
        BackgroundColor3 = Library.OutlineColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 2,
        Parent = TabBarOuter,
    })
    Library:AddToRegistry(TabSep, { BackgroundColor3 = 'OutlineColor' })
    local TabArea = Library:Create('ScrollingFrame', {
        Name = 'TabArea',
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 2, 0, 0),
        Size = UDim2.new(1, -4, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollBarThickness = 0,
        ScrollBarImageTransparency = 1,
        ScrollingDirection = Enum.ScrollingDirection.X,
        ElasticBehavior = Enum.ElasticBehavior.Never,
        ClipsDescendants = true,
        Active = true,
        ZIndex = 2,
        Parent = TabBarInner,
    })
    pcall(function()
        TabArea.TopImage = ''
        TabArea.MidImage = ''
        TabArea.BottomImage = ''
        TabArea.ScrollingEnabled = false
    end)
    local TabListLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, 2),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = TabArea,
    })
    local function RefreshTabCanvas()
        pcall(function()
            local w = math.max(TabListLayout.AbsoluteContentSize.X + 6, 6)
            TabArea.CanvasSize = UDim2.fromOffset(w, 0)
            TabArea.BackgroundTransparency = 1
        end)
    end
    TabListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(RefreshTabCanvas)
    RefreshTabCanvas()

    do
        local dragging = false
        local dragStartX = 0
        local dragStartCanvas = 0
        local velX = 0
        local lastX = 0
        local lastT = 0
        local momentumConn

        local function getMaxScroll()
            local content = TabListLayout.AbsoluteContentSize.X
            local view = TabArea.AbsoluteSize.X
            return math.max(0, content - view + 10)
        end

        local function clampCanvas(x)
            return math.clamp(x, 0, getMaxScroll())
        end

        local function stopMomentum()
            if momentumConn then
                momentumConn:Disconnect()
                momentumConn = nil
            end
        end

        TabArea.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton3
                or input.UserInputType == Enum.UserInputType.Touch then
                stopMomentum()
                dragging = true
                dragStartX = input.Position.X
                dragStartCanvas = TabArea.CanvasPosition.X
                velX = 0
                lastX = input.Position.X
                lastT = os.clock()
            end
        end)

        TabArea.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseWheel then
                return
            end
            if dragging then
                if input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch then
                    local now = os.clock()
                    local dt = now - lastT
                    if dt > 0 then
                        velX = (lastX - input.Position.X) / dt
                    end
                    lastX = input.Position.X
                    lastT = now
                    local dx = dragStartX - input.Position.X
                    TabArea.CanvasPosition = Vector2.new(clampCanvas(dragStartCanvas + dx), 0)
                end
            end
        end)

        InputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton3
                or input.UserInputType == Enum.UserInputType.Touch then
                if dragging then
                    dragging = false
                    if math.abs(velX) > 50 then
                        local startCanvas = TabArea.CanvasPosition.X
                        local projected = clampCanvas(startCanvas + velX * 0.35)
                        TweenService:Create(TabArea, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                            CanvasPosition = Vector2.new(projected, 0),
                        }):Play()
                    end
                    velX = 0
                end
            end
        end)
    end
    Window._RefreshTabCanvas = RefreshTabCanvas

    do
        local draggingTabs = false
        local startX, startCanvas
        TabArea.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                draggingTabs = true
                startX = input.Position.X
                startCanvas = TabArea.CanvasPosition.X
            end
        end)
        InputService.InputChanged:Connect(function(input)
            if not draggingTabs then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                local dx = startX - input.Position.X
                TabArea.CanvasPosition = Vector2.new(math.max(0, startCanvas + dx), 0)
            end
        end)
        InputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                draggingTabs = false
            end
        end)
    end

    local MainSectionOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor,
        BorderColor3 = Library.OutlineColor,
        Position = UDim2.new(0, 6, 0, 48),
        Size = UDim2.new(1, -12, 1, -54),
        ZIndex = 1,
        Parent = Inner,
    })
    Library:AddToRegistry(MainSectionOuter, {
        BackgroundColor3 = 'BackgroundColor',
        BorderColor3 = 'OutlineColor',
    })
    local MainSectionInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor,
        BorderColor3 = Color3.new(0, 0, 0),
        BorderMode = Enum.BorderMode.Inset,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 1,
        Parent = MainSectionOuter,
    })
    Library:AddToRegistry(MainSectionInner, { BackgroundColor3 = 'BackgroundColor' })
    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Position = UDim2.new(0, 8, 0, 8),
        Size = UDim2.new(1, -16, 1, -16),
        ZIndex = 2,
        Parent = MainSectionInner,
    })
    Library:AddToRegistry(TabContainer, {
        BackgroundColor3 = 'MainColor',
        BorderColor3 = 'OutlineColor',
    })
    Outer.ClipsDescendants = true

    local CornerCircle = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Library.AccentColor,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Position = UDim2.new(1, 0, 1, 0),
        Size = UDim2.fromOffset(46, 46),
        ZIndex = 10,
        Parent = Inner,
    })
    Library:Create('UICorner', {
        CornerRadius = UDim.new(1, 0),
        Parent = CornerCircle,
    })
    Library:AddToRegistry(CornerCircle, { BackgroundColor3 = 'AccentColor' })
    CornerCircle.Active = true
    CornerCircle.Parent = Outer
    CornerCircle.ZIndex = 100
    CornerCircle.MouseEnter:Connect(function()
        CornerCircle.BackgroundTransparency = 0.15
    end)
    CornerCircle.MouseLeave:Connect(function()
        CornerCircle.BackgroundTransparency = 0.5
    end)

    do
        local MinW = 420
        local MinH = 340
        local Resizing = false
        local ResizeConn, EndConn
        local StartSize, DragStart, DragType
        local HasMoved = false
        local Wireframe
        local function StopResize()
            Resizing = false
            if ResizeConn then ResizeConn:Disconnect() ResizeConn = nil end
            if EndConn then EndConn:Disconnect() EndConn = nil end
        end
        local function StartResize(Position, FromType)
            if Resizing then return end
            StopResize()
            Resizing = true
            StartSize = Outer.Size
            DragStart = Position
            DragType = FromType
            HasMoved = false
            if Wireframe then Wireframe:Destroy() Wireframe = nil end
            ResizeConn = InputService.InputChanged:Connect(function(Change)
                local T = Change.UserInputType
                if T ~= Enum.UserInputType.MouseMovement and T ~= Enum.UserInputType.Touch then return end
                if DragType ~= Enum.UserInputType.Touch and T == Enum.UserInputType.Touch then return end
                local Delta = Change.Position - DragStart
                if not HasMoved and Delta.Magnitude <= 2 then return end
                local TopLeft = Outer.AbsolutePosition
                local VPSize = Library.ScreenGui.AbsoluteSize
                local NewW = math.clamp(StartSize.X.Offset + Delta.X, MinW, VPSize.X - TopLeft.X)
                local NewH = math.clamp(StartSize.Y.Offset + Delta.Y, MinH, VPSize.Y - TopLeft.Y)
                if Library.WireframeDrag then
                    if not HasMoved then
                        HasMoved = true
                        Wireframe = Library:Create('Frame', {
                            Size = UDim2.fromOffset(NewW, NewH),
                            Position = UDim2.fromOffset(TopLeft.X, TopLeft.Y),
                            BackgroundTransparency = 1,
                            Active = false,
                            ZIndex = 100000,
                            Parent = ScreenGui,
                        })
                        Library:Create('UIStroke', {
                            Color = Library.AccentColor,
                            Thickness = 1,
                            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                            Parent = Wireframe,
                        })
                    end
                    if HasMoved and Wireframe then
                        Wireframe.Position = UDim2.fromOffset(TopLeft.X, TopLeft.Y)
                        Wireframe.Size = UDim2.fromOffset(NewW, NewH)
                    end
                else
                    Outer.Size = UDim2.fromOffset(NewW, NewH)
                end
            end)
            EndConn = InputService.InputEnded:Connect(function(EndInput)
                if EndInput.UserInputType == DragType then
                    if Library.WireframeDrag and HasMoved and Wireframe then
                        Outer.Size = Wireframe.Size
                        Wireframe:Destroy()
                        Wireframe = nil
                    end
                    StopResize()
                end
            end)
        end
        local function OnHandlePressed(Position, InputType)
            StartResize(Position, InputType)
        end
        CornerCircle.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                OnHandlePressed(Input.Position, Input.UserInputType)
            end
        end)
        InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end
            if Resizing then return end
            local WindowPos = Outer.AbsolutePosition
            local WindowSize = Outer.AbsoluteSize
            local CenterX = WindowPos.X + WindowSize.X
            local CenterY = WindowPos.Y + WindowSize.Y
            local P = Input.Position
            local Rad = 26
            local DX = CenterX - P.X
            local DY = CenterY - P.Y
            if (DX * DX) + (DY * DY) <= (Rad * Rad) then
                OnHandlePressed(P, Input.UserInputType)
            end
        end)
    end

    function Window:SetWindowTitle(Title) WindowLabel.Text = Title end

    function Window:AddTab(Name)
        local Tab = { Groupboxes = {}, Tabboxes = {} }
        local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, Library.FontSize + 2)
        local TabButton = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, math.max(TabButtonWidth + 14, 42), 1, 0),
            ZIndex = 1,
            Parent = TabArea,
            Active = true,
        })
        Library:AddToRegistry(TabButton, { BackgroundColor3 = 'MainColor' })
        local TabLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, -1),
            Text = Name,
            TextSize = Library.FontSize,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 2,
            Parent = TabButton,
        })
        local TabIndicator = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -1),
            Size = UDim2.new(1, 0, 0, 1),
            Visible = false,
            ZIndex = 3,
            Parent = TabButton,
        })
        Library:AddToRegistry(TabIndicator, { BackgroundColor3 = 'AccentColor' })
        Library:AddToRegistry(TabIndicator, { BackgroundColor3 = 'AccentColor' })
        local TabFrame = Library:Create('Frame', {
            Name = 'TabFrame',
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
            ZIndex = 2,
            Parent = TabContainer,
        })
        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 8 - 1, 0, 8 - 1),
            Size = UDim2.new(0.5, -12 + 2, 1, -16),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            BottomImage = '',
            TopImage = '',
            ScrollBarThickness = 0,
            ZIndex = 2,
            Parent = TabFrame,
        })
        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1),
            Size = UDim2.new(0.5, -12 + 2, 1, -16),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            BottomImage = '',
            TopImage = '',
            ScrollBarThickness = 0,
            ZIndex = 2,
            Parent = TabFrame,
        })
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Parent = LeftSide,
        })
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Parent = RightSide,
        })
        for _, Side in next, { LeftSide, RightSide } do
            Side:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y)
            end)
        end
        Tab.Frame, Tab.Button, Tab.ButtonLabel, Tab.LeftSide, Tab.RightSide = TabFrame, TabButton, TabLabel, LeftSide, RightSide
        function Tab:ShowTab()
            for _, T in next, Window.Tabs do
                if T.HideTab then T:HideTab() end
            end
            TabButton.BackgroundColor3 = Library.BackgroundColor
            TabButton.BackgroundTransparency = 0
            if Library.RegistryMap[TabButton] then
                Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'BackgroundColor'
            end
            TabLabel.TextTransparency = 0
            TabFrame.Visible = true
            TabIndicator.Visible = true
            pcall(function()
                local abs = TabButton.AbsolutePosition.X
                local area = TabArea.AbsolutePosition.X
                local rel = abs - area + TabArea.CanvasPosition.X
                local view = TabArea.AbsoluteSize.X
                if rel < TabArea.CanvasPosition.X then
                    TabArea.CanvasPosition = Vector2.new(math.max(0, rel - 8), 0)
                elseif rel + TabButton.AbsoluteSize.X > TabArea.CanvasPosition.X + view then
                    TabArea.CanvasPosition = Vector2.new(rel + TabButton.AbsoluteSize.X - view + 8, 0)
                end
            end)
            Window.ActiveTab = Name
        end
        function Tab:HideTab()
            TabButton.BackgroundColor3 = Library.MainColor
            TabButton.BackgroundTransparency = 0
            if Library.RegistryMap[TabButton] then
                Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'MainColor'
            end
            TabLabel.TextTransparency = 0
            TabFrame.Visible = false
            TabIndicator.Visible = false
        end
        function Tab:SetLayoutOrder(Position)
            TabButton.LayoutOrder = Position
            TabListLayout:ApplyLayout()
        end
        function Tab:AddGroupbox(Info)
            local Groupbox = {}
            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 0, 507 + 2),
                ZIndex = 2,
                Parent = Info.Side == 1 and LeftSide or RightSide,
            })
            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor',
                BorderColor3 = 'OutlineColor',
            })
            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Color3.new(0, 0, 0),
                Size = UDim2.new(1, -2, 1, -2),
                Position = UDim2.new(0, 1, 0, 1),
                ZIndex = 4,
                Parent = BoxOuter,
            })
            Library:AddToRegistry(BoxInner, { BackgroundColor3 = 'BackgroundColor' })
            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 2),
                ZIndex = 5,
                Parent = BoxInner,
            })
            Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor' })
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 18),
                Position = UDim2.new(0, 0, 0, 2),
                TextSize = Library.FontSize,
                Text = Info.Name,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 5,
                Parent = BoxInner,
            })
            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 4, 0, 20),
                Size = UDim2.new(1, -4, 1, -20),
                ZIndex = 1,
                Parent = BoxInner,
            })
            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Container,
            })
            function Groupbox:Resize()
                local Size = 0
                for _, Element in next, Groupbox.Container:GetChildren() do
                    if not Element:IsA('UIListLayout') and Element.Visible then
                        Size = Size + Element.Size.Y.Offset
                    end
                end
                BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2)
            end
            Groupbox.Container = Container
            Groupbox.Frame = BoxOuter
            setmetatable(Groupbox, BaseGroupbox)
            Groupbox:AddBlank(3)
            Groupbox:Resize()
            Tab.Groupboxes[Info.Name] = Groupbox
            return Groupbox
        end
        function Tab:AddLeftGroupbox(Name) return Tab:AddGroupbox({ Side = 1, Name = Name }) end
        function Tab:AddRightGroupbox(Name) return Tab:AddGroupbox({ Side = 2, Name = Name }) end
        function Tab:AddTabbox(Info)
            local Tabbox = { Tabs = {} }
            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 0, 0),
                ZIndex = 2,
                Parent = Info.Side == 1 and LeftSide or RightSide,
            })
            Tabbox.Frame = BoxOuter
            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor',
                BorderColor3 = 'OutlineColor',
            })
            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Color3.new(0, 0, 0),
                Size = UDim2.new(1, -2, 1, -2),
                Position = UDim2.new(0, 1, 0, 1),
                ZIndex = 4,
                Parent = BoxOuter,
            })
            Library:AddToRegistry(BoxInner, { BackgroundColor3 = 'BackgroundColor' })
            local TabboxButtons = Library:Create('Frame', {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 1),
                Size = UDim2.new(1, 0, 0, 18),
                ZIndex = 5,
                Parent = BoxInner,
            })
            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = TabboxButtons,
            })
            function Tabbox:AddTab(Name)
                local Tab = {}
                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor,
                    BorderColor3 = Color3.new(0, 0, 0),
                    Size = UDim2.new(0.5, 0, 1, 0),
                    ZIndex = 6,
                    Parent = TabboxButtons,
                })
                Library:AddToRegistry(Button, { BackgroundColor3 = 'MainColor' })
                local TabHighlight = Library:Create('Frame', {
                    BackgroundColor3 = Library.AccentColor,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 2),
                    Visible = false,
                    ZIndex = 10,
                    Parent = Button,
                })
                Library:AddToRegistry(TabHighlight, { BackgroundColor3 = 'AccentColor' })
                Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0),
                    TextSize = Library.FontSize,
                    Text = Name,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 7,
                    Parent = Button,
                })
                local Block = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 1, 0),
                    Size = UDim2.new(1, 0, 0, 1),
                    Visible = false,
                    ZIndex = 9,
                    Parent = Button,
                })
                Library:AddToRegistry(Block, { BackgroundColor3 = 'BackgroundColor' })
                local Container = Library:Create('Frame', {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 4, 0, 20),
                    Size = UDim2.new(1, -4, 1, -20),
                    ZIndex = 1,
                    Visible = false,
                    Parent = BoxInner,
                })
                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = Container,
                })
                function Tab:Show()
                    for _, T in next, Tabbox.Tabs do T:Hide() end
                    Container.Visible = true
                    Block.Visible = true
                    TabHighlight.Visible = true
                    Button.BackgroundColor3 = Library.BackgroundColor
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor'
                    Tab:Resize()
                end
                function Tab:Hide()
                    Container.Visible = false
                    Block.Visible = false
                    TabHighlight.Visible = false
                    Button.BackgroundColor3 = Library.MainColor
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor'
                end
                function Tab:Resize()
                    local TabCount = 0
                    for _, T in next, Tabbox.Tabs do TabCount = TabCount + 1 end
                    for _, B in next, TabboxButtons:GetChildren() do
                        if not B:IsA('UIListLayout') then
                            B.Size = UDim2.new(1 / TabCount, 0, 1, 0)
                        end
                    end
                    if not Container.Visible then return end
                    local Size = 0
                    for _, Element in next, Tab.Container:GetChildren() do
                        if not Element:IsA('UIListLayout') and Element.Visible then
                            Size = Size + Element.Size.Y.Offset
                        end
                    end
                    BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2)
                end
                Button.InputBegan:Connect(function(Input)
                    if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                        Tab:Show()
                        Tab:Resize()
                    end
                end)
                Tab.Container = Container
                Tabbox.Tabs[Name] = Tab
                setmetatable(Tab, BaseGroupbox)
                Tab:AddBlank(3)
                Tab:Resize()
                if #TabboxButtons:GetChildren() == 2 then Tab:Show() end
                return Tab
            end
            Tab.Tabboxes[Info.Name or ''] = Tabbox
            return Tabbox
        end
        function Tab:AddLeftTabbox(Name) return Tab:AddTabbox({ Name = Name, Side = 1 }) end
        function Tab:AddRightTabbox(Name) return Tab:AddTabbox({ Name = Name, Side = 2 }) end
        TabButton.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Tab:ShowTab()
            end
        end)
        if #TabContainer:GetChildren() == 1 then Tab:ShowTab() end
        Window.Tabs[Name] = Tab
        pcall(function()
            if Window._RefreshTabCanvas then Window._RefreshTabCanvas() end
        end)
        return Tab
    end

    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 0),
        Visible = true,
        Text = '',
        Modal = false,
        Parent = ScreenGui,
    })

    Library._StoredSize = nil
    Library._StoredPos = nil

    function Library:Toggle()
        Library.Toggled = not Library.Toggled
        ModalElement.Modal = Library.Toggled

        if Library.Toggled then
            Outer.Visible = true
            pcall(function() if Library.UpdateLogoVisibility then Library:UpdateLogoVisibility() end end)
            pcall(function() if Library.ReapplyGlass then Library:ReapplyGlass() end end)
            local fullSize = Library._StoredSize or Outer.Size
            local fullPos = Library._StoredPos or Outer.Position
            Library._StoredSize = nil
            Library._StoredPos = nil
            if fullSize.X.Offset > 50 and fullSize.Y.Offset > 50 then
                Outer.Size = UDim2.fromOffset(
                    math.floor(fullSize.X.Offset * 0.92),
                    math.floor(fullSize.Y.Offset * 0.92)
                )
                TweenService:Create(Outer, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = fullSize,
                    Position = fullPos,
                }):Play()
            end
            task.spawn(function()
                local State = InputService.MouseIconEnabled
                local GuiService = game:GetService("GuiService")
                local Cursor = Instance.new("ImageLabel", ScreenGui)
                Cursor.Image = "http://www.roblox.com/asset/?id=4292970642"
                Cursor.BackgroundTransparency = 1
                Cursor.ZIndex = 100
                local CursorOutline = Instance.new("ImageLabel", ScreenGui)
                CursorOutline.Image = "http://www.roblox.com/asset/?id=4292970642"
                CursorOutline.ImageColor3 = Color3.new()
                CursorOutline.BackgroundTransparency = 1
                CursorOutline.ZIndex = 99
                Cursor.Size, CursorOutline.Size = UDim2.fromOffset(17, 17), UDim2.fromOffset(19, 19)
                Cursor.Rotation, CursorOutline.Rotation = -45, -45
                if Library.IsMobile == true then
                    while Library.Toggled and ScreenGui.Parent do
                        task.wait(0.5)
                    end
                else
                    while Library.Toggled and ScreenGui.Parent do
                        InputService.MouseIconEnabled = false
                        local mPos = InputService:GetMouseLocation()
                        local udim = UDim2.fromOffset(mPos.X, mPos.Y - GuiService:GetGuiInset().Y - 1)
                        Cursor.ImageColor3 = Library.AccentColor
                        Cursor.Position, CursorOutline.Position = udim, udim - UDim2.fromOffset(1, 1)
                        if Library.PerformanceMode then
                            task.wait()
                        else
                            RenderStepped:Wait()
                        end
                    end
                end
                InputService.MouseIconEnabled = State
                Cursor:Destroy()
                CursorOutline:Destroy()
            end)
        else
            Library._StoredSize = Outer.Size
            Library._StoredPos = Outer.Position
            local startSize = Outer.Size
            local targetSize = UDim2.fromOffset(
                math.max(50, math.floor(startSize.X.Offset * 0.92)),
                math.max(50, math.floor(startSize.Y.Offset * 0.92))
            )
            TweenService:Create(Outer, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Size = targetSize,
            }):Play()
            task.delay(0.22, function()
                if not Library.Toggled then
                    Outer.Visible = false
                    if Library._StoredSize then
                        Outer.Size = Library._StoredSize
                        Outer.Position = Library._StoredPos
                    end
                end
            end)
        end
        pcall(function() if Library.UpdateLogoVisibility then Library:UpdateLogoVisibility() end end)
        Library:UpdateBlur()
    end

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
        if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
                task.spawn(Library.Toggle)
            end
        elseif type(Library.ToggleKeybind) == 'string' then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind then
                task.spawn(Library.Toggle)
            end
        elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and (not Processed)) then
            task.spawn(Library.Toggle)
        end
    end))

    if Config.AutoShow then
        task.spawn(function()
            Library.Toggled = false
            Library:Toggle()
            pcall(function()
                Outer.Visible = true
                Library.Toggled = true
            end)
        end)
    end

    Window.Holder = Outer
    Window.Inner, Window.TabArea, Window.TabContainer, Window.TabListLayout = Inner, TabArea, TabContainer, TabListLayout
    Library.WindowOuter = Outer

    pcall(function() if Library.ApplyBlackWhiteTheme then Library:ApplyBlackWhiteTheme() end end)
    pcall(function() if Library.SetGlass then Library:SetGlass(false) end end)

    task.defer(function()
        pcall(function()
            if Config.StartHidden then return end
            Library.Toggled = true
            ModalElement.Modal = true
            Outer.Visible = true
            if Library.ScreenGui then Library.ScreenGui.Enabled = true end
            if Library.UpdateBlur then Library:UpdateBlur() end
            if Library.ReapplyGlass then Library:ReapplyGlass() end
            if Library.CreateLogo then
                -- logo removed
            end
            if Library.UpdateLogoVisibility then Library:UpdateLogoVisibility() end
        end)
    end)

    return Window
end

local function OnPlayerChange()
    local PlayerList = GetPlayersString()
    for _, Value in next, Options do
        if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
            Value:SetValues(PlayerList)
        end
    end
end

Players.PlayerAdded:Connect(OnPlayerChange)
Players.PlayerRemoving:Connect(OnPlayerChange)

if InputService.TouchEnabled then
    local MobileGui = Instance.new("ScreenGui")
    MobileGui.Name = "Vercel_MobileUI"
    MobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    MobileGui.DisplayOrder = 9999
    MobileGui.ResetOnSpawn = false
    ProtectGui(MobileGui)
    MobileGui.Parent = CoreGui

    local BTN_W, BTN_H = 100, 34
    local BTN_GAP = 42

    local function CreateMobileButton(name, text, startPos)
        local Outer = Library:Create('Frame', {
            Name = name .. "Outer",
            BackgroundColor3 = Library.OutlineColor,
            BorderSizePixel = 0,
            Position = startPos,
            Size = UDim2.new(0, BTN_W, 0, BTN_H),
            ZIndex = 300,
            Parent = MobileGui,
            Active = true,
        })
        Library:AddToRegistry(Outer, { BackgroundColor3 = 'OutlineColor' })

        local AccentFrame = Library:Create('Frame', {
            Name = name .. "Accent",
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            ZIndex = 301,
            Parent = Outer,
        })
        Library:AddToRegistry(AccentFrame, { BackgroundColor3 = 'AccentColor' })

        local Inner = Library:Create('Frame', {
            Name = name .. "Inner",
            BackgroundColor3 = Color3.fromRGB(8, 8, 12),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            ZIndex = 302,
            Parent = AccentFrame,
        })

        local GradientOverlay = Library:Create('Frame', {
            Name = name .. "Gradient",
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 303,
            Parent = Inner,
        })
        Library:Create('UIGradient', {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.90),
                NumberSequenceKeypoint.new(1, 1.0),
            }),
            Rotation = 90,
            Parent = GradientOverlay,
        })

        local Btn = Library:Create('TextButton', {
            Name = name .. "Btn",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -4, 1, 0),
            Position = UDim2.new(0, 4, 0, 0),
            Font = Enum.Font.Code,
            Text = text,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 304,
            Parent = Inner,
            Active = true,
            AutoButtonColor = false,
        })

        return Outer, Btn, AccentFrame
    end

    local ToggleOuter, ToggleBtn = CreateMobileButton("Toggle", "Toggle UI", UDim2.new(0, 10, 0, 10))
    local LockOuter, LockBtn = CreateMobileButton("Lock", "Unlock UI", UDim2.new(0, 10, 0, 10 + BTN_H + (BTN_GAP - BTN_H)))

    local IsUnlocked = false
    Library.UILocked = false

    local function BindMobile(Btn, Outer, onClick)
        local dragging = false
        local dragInput, dragStart, startPos
        local hasMoved = false
        local handled = false

        local function doClick()
            if handled then return end
            handled = true
            task.defer(function() handled = false end)
            pcall(onClick)
        end

        Btn.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            dragging = true
            hasMoved = false
            dragStart = input.Position
            startPos = Outer.Position
            dragInput = input

            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if conn then conn:Disconnect() end
                    if not hasMoved then
                        doClick()
                    end
                end
            end)
        end)

        InputService.InputChanged:Connect(function(input)
            if not dragging or input ~= dragInput then return end
            local delta = input.Position - dragStart
            if delta.Magnitude > 12 then
                hasMoved = true
            end
            if IsUnlocked and hasMoved then
                Outer.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    BindMobile(ToggleBtn, ToggleOuter, function()
        pcall(function()
            Library:Toggle()
        end)
    end)

    BindMobile(LockBtn, LockOuter, function()
        IsUnlocked = not IsUnlocked
        Library.UILocked = not IsUnlocked
        LockBtn.Text = IsUnlocked and "Lock UI" or "Unlock UI"
        LockBtn.TextColor3 = IsUnlocked and Library.AccentColor or Color3.fromRGB(255, 255, 255)
        pcall(function()
            if Library.Notify then
                Library:Notify(IsUnlocked and "Unlocked - drag buttons" or "Locked", 2)
            end
        end)
    end)

    Library.MobileGui = MobileGui
    Library.MobileToggleBtn = ToggleBtn
    Library.MobileLockBtn = LockBtn
    Library.IsMobile = true
end

function Library:ApplyBlackWhiteTheme()
    Library.FontColor = Color3.fromRGB(225, 225, 225)
    Library.MainColor = Color3.fromRGB(10, 10, 10)
    Library.BackgroundColor = Color3.fromRGB(0, 0, 0)
    Library.AccentColor = Color3.fromRGB(170, 170, 170)
    Library.OutlineColor = Color3.fromRGB(42, 42, 42)
    Library.RiskColor = Color3.fromRGB(220, 60, 60)
    Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
    pcall(function() Library:UpdateColorsUsingRegistry() end)
    pcall(function() if Library.SyncThemeColorPickers then Library:SyncThemeColorPickers() end end)
    pcall(function() if Library.ReapplyGlass then Library:ReapplyGlass() end end)
end

function Library:SetGlass(Enabled, Transparency)
    if Library._SettingGlass then return end
    Library._SettingGlass = true

    if type(Enabled) == "boolean" then Library.GlassEnabled = Enabled
    else Library.GlassEnabled = Enabled ~= false end
    if type(Transparency) == "number" then
        Library.GlassTransparency = math.clamp(Transparency, 0.45, 0.96)
    end
    Library.GlassTransparency = Library.GlassTransparency or 0.72

    local on = Library.GlassEnabled == true
    local t = Library.GlassTransparency

    local L_outer = on and math.clamp(0.86 + (t - 0.5) * 0.18, 0.82, 0.95) or 0
    local L_mid   = on and math.clamp(0.62 + (t - 0.5) * 0.4, 0.55, 0.88) or 0
    local L_inner = on and math.clamp(0.38 + (t - 0.5) * 0.35, 0.28, 0.68) or 0
    Library.OuterGlassTransparency = L_outer

    pcall(function()
        if on then
            Library.UseBlur = not (Library.IsMobile == true)
            Library.BlurSize = math.clamp(Library.BlurSize or 18, 14, 32)
            Library.UseDarken = true
            Library.DarkenAmount = math.clamp(Library.DarkenAmount or 10, 4, 18)
        end

        local outer = Library.WindowOuter
        if outer then
            outer.BackgroundColor3 = Library.BackgroundColor
            outer.BackgroundTransparency = L_outer
            outer.BorderSizePixel = 0

            local edge = outer:FindFirstChild("Vercel_GlassEdge")
            if on then
                if not edge then
                    edge = Instance.new("UIStroke")
                    edge.Name = "Vercel_GlassEdge"
                    edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    edge.LineJoinMode = Enum.LineJoinMode.Round
                    edge.Parent = outer
                end
                edge.Thickness = 1.5
                edge.Color = Color3.fromRGB(255, 255, 255)
                edge.Transparency = 0.55
            elseif edge then
                edge:Destroy()
            end

            local rim = outer:FindFirstChild("Vercel_GlassRim")
            if on then
                if not rim then
                    rim = Instance.new("UIStroke")
                    rim.Name = "Vercel_GlassRim"
                    rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    rim.LineJoinMode = Enum.LineJoinMode.Round
                    rim.Parent = outer
                end
                rim.Thickness = 0.5
                rim.Color = Color3.fromRGB(0, 0, 0)
                rim.Transparency = 0.7
            elseif rim then
                rim:Destroy()
            end

            local shadow = outer:FindFirstChild("Vercel_GlassShadow")
            if on then
                if not shadow then
                    shadow = Instance.new("Frame")
                    shadow.Name = "Vercel_GlassShadow"
                    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
                    shadow.BorderSizePixel = 0
                    shadow.ZIndex = math.max(0, (outer.ZIndex or 1) - 1)
                    shadow.Parent = outer.Parent or outer
                    local sc = Instance.new("UICorner")
                    sc.CornerRadius = UDim.new(0, 8)
                    sc.Parent = shadow
                end
                shadow.BackgroundTransparency = 0.72
                shadow.Size = outer.Size + UDim2.fromOffset(14, 16)
                shadow.Position = outer.Position + UDim2.fromOffset(-7, 6)
                shadow.AnchorPoint = outer.AnchorPoint
            elseif shadow then
                shadow:Destroy()
            end

            local shadow2 = outer:FindFirstChild("Vercel_GlassShadow2")
            if on then
                if not shadow2 then
                    shadow2 = Instance.new("Frame")
                    shadow2.Name = "Vercel_GlassShadow2"
                    shadow2.BackgroundColor3 = Color3.new(0, 0, 0)
                    shadow2.BorderSizePixel = 0
                    shadow2.ZIndex = math.max(0, (outer.ZIndex or 1) - 2)
                    shadow2.Parent = outer.Parent or outer
                    local sc = Instance.new("UICorner")
                    sc.CornerRadius = UDim.new(0, 10)
                    sc.Parent = shadow2
                end
                shadow2.BackgroundTransparency = 0.88
                shadow2.Size = outer.Size + UDim2.fromOffset(22, 24)
                shadow2.Position = outer.Position + UDim2.fromOffset(-11, 10)
                shadow2.AnchorPoint = outer.AnchorPoint
            elseif shadow2 then
                shadow2:Destroy()
            end

            local gloss = outer:FindFirstChild("Vercel_GlassGloss")
            if on then
                if not gloss then
                    gloss = Instance.new("Frame")
                    gloss.Name = "Vercel_GlassGloss"
                    gloss.BackgroundColor3 = Color3.new(1, 1, 1)
                    gloss.BorderSizePixel = 0
                    gloss.Size = UDim2.new(1, 0, 0.42, 0)
                    gloss.Position = UDim2.new(0, 0, 0, 0)
                    gloss.ZIndex = (outer.ZIndex or 1) + 2
                    gloss.Parent = outer
                    local g = Instance.new("UIGradient")
                    g.Name = "GlossGrad"
                    g.Rotation = 105
                    g.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.4),
                        NumberSequenceKeypoint.new(0.35, 0.85),
                        NumberSequenceKeypoint.new(0.7, 0.97),
                        NumberSequenceKeypoint.new(1, 1),
                    })
                    g.Parent = gloss
                end
                gloss.BackgroundTransparency = 0.82
            elseif gloss then
                gloss.BackgroundTransparency = 1
            end

            local refl = outer:FindFirstChild("Vercel_GlassRefl")
            if on then
                if not refl then
                    refl = Instance.new("Frame")
                    refl.Name = "Vercel_GlassRefl"
                    refl.BackgroundColor3 = Color3.new(1, 1, 1)
                    refl.BorderSizePixel = 0
                    refl.Size = UDim2.new(1, 0, 0.18, 0)
                    refl.Position = UDim2.new(0, 0, 0.82, 0)
                    refl.ZIndex = (outer.ZIndex or 1) + 2
                    refl.Parent = outer
                    local g = Instance.new("UIGradient")
                    g.Rotation = 90
                    g.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(0.5, 0.94),
                        NumberSequenceKeypoint.new(1, 1),
                    })
                    g.Parent = refl
                end
                refl.BackgroundTransparency = 0.93
            elseif refl then
                refl.BackgroundTransparency = 1
            end

            local leftLight = outer:FindFirstChild("Vercel_GlassLeft")
            if on then
                if not leftLight then
                    leftLight = Instance.new("Frame")
                    leftLight.Name = "Vercel_GlassLeft"
                    leftLight.BackgroundColor3 = Color3.new(1, 1, 1)
                    leftLight.BorderSizePixel = 0
                    leftLight.Size = UDim2.new(0, 3, 1, 0)
                    leftLight.Position = UDim2.new(0, 0, 0, 0)
                    leftLight.ZIndex = (outer.ZIndex or 1) + 3
                    leftLight.Parent = outer
                    local g = Instance.new("UIGradient")
                    g.Rotation = 0
                    g.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.7),
                        NumberSequenceKeypoint.new(1, 1),
                    })
                    g.Parent = leftLight
                end
                leftLight.BackgroundTransparency = 0.88
            elseif leftLight then
                leftLight.BackgroundTransparency = 1
            end
        end

        if Library.DarkOverlay then
            if on and Library.Toggled then
                Library.DarkOverlay.BackgroundTransparency = 1 - ((Library.DarkenAmount or 10) / 100)
            else
                Library.DarkOverlay.BackgroundTransparency = 1
            end
        end

        if not Library.ScreenGui then
            Library._SettingGlass = false
            return
        end

        local registryMap = Library.RegistryMap
        for _, d in ipairs(Library.ScreenGui:GetDescendants()) do
            if d:IsA("Frame") or d:IsA("ScrollingFrame") then
                local nm = d.Name
                local parent = d.Parent
                local pname = parent and parent.Name or ""

                if nm == "TabArea" or nm == "Vercel_LogoBehind" or nm == "LogoHolder"
                    or nm:find("Vercel_Glass") then
                    if not nm:find("Gloss") and not nm:find("Refl") and not nm:find("Left") then
                        d.BackgroundTransparency = 1
                    end
                elseif nm == "TabBarOuter" or nm == "TabBarInner" then
                    d.BackgroundColor3 = Library.BackgroundColor
                    d.BackgroundTransparency = on and math.clamp(L_mid * 0.55, 0.2, 0.5) or 0
                    local ts = d:FindFirstChild("Vercel_TabGlassEdge")
                    if on then
                        if not ts then
                            ts = Instance.new("UIStroke")
                            ts.Name = "Vercel_TabGlassEdge"
                            ts.Thickness = 1
                            ts.Color = Color3.fromRGB(255, 255, 255)
                            ts.Transparency = 0.75
                            ts.Parent = d
                        end
                    elseif ts then
                        ts:Destroy()
                    end
                elseif pname == "TabArea" then
                    d.BackgroundTransparency = 0
                elseif nm == "Outer" or d == Library.WindowOuter then
                    d.BackgroundColor3 = Library.BackgroundColor
                    d.BackgroundTransparency = L_outer
                else
                    local reg = registryMap and registryMap[d]
                    local bg = reg and reg.Properties and reg.Properties.BackgroundColor3
                    if bg == "BackgroundColor" then
                        d.BackgroundColor3 = Library.BackgroundColor
                        d.BackgroundTransparency = L_mid
                        local ps = d:FindFirstChild("Vercel_PanelGlassEdge")
                        if on and d.AbsoluteSize.Y > 36 then
                            if not ps then
                                ps = Instance.new("UIStroke")
                                ps.Name = "Vercel_PanelGlassEdge"
                                ps.Thickness = 1
                                ps.Color = Color3.fromRGB(255, 255, 255)
                                ps.Transparency = 0.78
                                ps.Parent = d
                            end
                        end
                    elseif bg == "MainColor" then
                        d.BackgroundColor3 = Library.MainColor
                        local sz = d.AbsoluteSize
                        if sz.X <= 22 and sz.Y <= 22 then
                            d.BackgroundTransparency = 0
                        else
                            d.BackgroundTransparency = L_inner
                        end
                    end
                end
            end
        end

        if Library.Toggled then
            pcall(function() Library:UpdateBlur() end)
        end
    end)

    Library._SettingGlass = false
end

function Library:ReapplyGlass()
    Library:SetGlass(Library.GlassEnabled ~= false, Library.GlassTransparency or 0.92)
end

function Library:CreateLogo(Info)
    Info = Info or {}
    pcall(function()
        if Library._LogoGui then Library._LogoGui:Destroy() end
        if Library._LogoSpinConn then Library._LogoSpinConn:Disconnect() end
        if Library._LogoHolder and Library._LogoHolder.Parent then Library._LogoHolder:Destroy() end
    end)

    local text = tostring(Info.Text or "V")
    local size = tonumber(Info.TextSize) or 52

    local outer = Library.WindowOuter
    if not outer or not outer.Parent then
        task.defer(function()
            task.wait(0.15)
            if Library.WindowOuter and not Library._LogoHolder then
                Library:CreateLogo(Info)
            end
        end)
        return
    end

    local holder = Instance.new("Frame")
    holder.Name = "Vercel_LogoBehind"
    holder.BackgroundTransparency = 1
    holder.AnchorPoint = Vector2.new(0.5, 0.5)
    holder.Position = UDim2.fromScale(0.5, 0.5)
    holder.Size = UDim2.fromScale(0.55, 0.4)
    holder.ZIndex = 1
    holder.ClipsDescendants = false
    holder.Parent = outer

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextSize = size
    label.TextColor3 = Library.AccentColor
    label.TextTransparency = 0.75
    label.TextScaled = true
    label.ZIndex = 1
    label.Parent = holder

    Library._LogoHolder = holder
    Library._LogoGui = holder

    local conn = RunService.Heartbeat:Connect(function(dt)
        if not holder.Parent then return end
        if Library.Toggled ~= true then
            holder.Visible = false
            return
        end
        holder.Visible = true
        holder.Rotation = 0
        label.TextColor3 = Library.AccentColor
    end)
    Library._LogoSpinConn = conn
    table.insert(Library.Signals, conn)
    Library._LogoSync = function()
        if holder and holder.Parent then
            holder.Visible = Library.Toggled == true
        end
    end
end

function Library:UpdateLogoVisibility()
    if Library._LogoSync then pcall(Library._LogoSync) end
    if Library.Toggled ~= true and Library._LogoGui then Library._LogoGui.Enabled = false end
end

function Library:SetNotifyConfig(Config)
    Config = Config or {}
    local C = Library.NotifyConfig
    if type(C) ~= "table" then
        Library.NotifyConfig = {}
        C = Library.NotifyConfig
    end
    if Config.Transparency ~= nil then C.Transparency = Config.Transparency end
    if Config.PosX ~= nil then C.PosX = Config.PosX end
    if Config.PosY ~= nil then C.PosY = Config.PosY end
    if Config.MaxHeight ~= nil then C.MaxHeight = Config.MaxHeight end
    if Config.Alignment ~= nil then C.Alignment = Config.Alignment end
    if Config.BarSide ~= nil then C.BarSide = Config.BarSide end
    if Config.SortOrder ~= nil then C.SortOrder = Config.SortOrder end
    if Config.ClipDescendants ~= nil then C.ClipDescendants = Config.ClipDescendants end
    if Config.Duration ~= nil then Library.NotifyDefaultTime = Config.Duration end
    if Config.MaxActive ~= nil then Library.NotifyMaxActive = Config.MaxActive end
end


function Library:SetTabPadding(px)
    Library.TabPadding = math.clamp(tonumber(px) or 2, 0, 20)
    pcall(function()
        for _, win in pairs(Library.Windows or {}) do
            if win._TabListLayout then
                win._TabListLayout.Padding = UDim.new(0, Library.TabPadding)
            end
        end
    end)
end

function Library:SetTabTextSize(size)
    size = math.clamp(tonumber(size) or Library.FontSize or 14, 10, 20)
    Library.TabTextSize = size
    pcall(function()
        for _, inst in pairs(Library.Registry or {}) do
        end
        if Library.ScreenGui then
            for _, d in ipairs(Library.ScreenGui:GetDescendants()) do
                if d:IsA("TextLabel") and d.Parent and d.Parent.Name and tostring(d.Parent.Name):find("Tab") then
                end
            end
        end
    end)
end

function Library:ApplyTabTweaks(opts)
    opts = opts or {}
    if opts.Padding ~= nil then Library:SetTabPadding(opts.Padding) end
    if opts.Compact then
        Library.TabCompact = true
    end
    if opts.TextSize then Library.TabTextSize = opts.TextSize end
end

function Library:AddTabTweaks(Groupbox, Window)
    Groupbox:AddSlider('TabPadding', {
        Text = 'Tab Padding',
        Default = Library.TabPadding or 2,
        Min = 0, Max = 16, Rounding = 0,
        Callback = function(V)
            Library:SetTabPadding(V)
        end,
    })
    Groupbox:AddToggle('TabCompact', {
        Text = 'Compact Tabs',
        Default = Library.TabCompact == true,
        Callback = function(V)
            Library.TabCompact = V
            Library:Notify("Compact tabs: " .. tostring(V) .. " (reopen UI to fully apply)")
        end,
    })
    Groupbox:AddSlider('TabAnimSpeed', {
        Text = 'Tab Switch Speed',
        Default = 12, Min = 1, Max = 30, Rounding = 0,
        Callback = function(V) Library.TabSwitchSpeed = V end,
    })
    if Window and Window.Tabs then
        for name, tab in pairs(Window.Tabs) do
            Groupbox:AddButton("Open " .. tostring(name), function()
                if tab.ShowTab then tab:ShowTab() end
            end)
        end
    end
    Groupbox:AddButton('Refresh Tabs', function()
        Library:Notify("Tabs refreshed")
    end)
end


function Library:AddNotifyOptions(Groupbox)
    Library.NotifyConfig = Library.NotifyConfig or {
        ClipDescendants = false,
        MaxHeight = 200,
        PosX = 50,
        PosY = 60,
        Transparency = 25,
        Alignment = "Center",
        BarSide = "Bottom",
        SortOrder = "Default",
        ForceColor = false,
        ClipPastDistance = 200,
    }
    local NC = Library.NotifyConfig
    local function Apply()
        pcall(function()
            if Library.ConfigureNotifications then
                Library:ConfigureNotifications(NC)
            end
        end)
    end
    Apply()

    Groupbox:AddToggle('NotifyClip', {
        Text = 'Clip Descendants',
        Default = NC.ClipDescendants == true,
        Callback = function(V) NC.ClipDescendants = V; Apply() end,
    })
    Groupbox:AddSlider('NotifyClipDist', {
        Text = 'Clip Past Distance',
        Default = NC.ClipPastDistance or 200,
        Min = 50, Max = 1000, Rounding = 0, Suffix = 'px',
        Callback = function(V) NC.ClipPastDistance = V; Apply() end,
    })
    Groupbox:AddToggle('NotifyForceColor', {
        Text = 'Force Color',
        Default = NC.ForceColor == true,
        Callback = function(V) NC.ForceColor = V; Apply() end,
    }):AddColorPicker('NotifyForceColorVal', {
        Default = NC.ForceColorValue or Library.AccentColor,
        Title = 'Notify Color',
        Callback = function(C) NC.ForceColorValue = C; Apply() end,
    })
    Groupbox:AddSlider('NotifyPosX', {
        Text = 'Position X',
        Default = NC.PosX or 50,
        Min = 0, Max = 100, Rounding = 0, Suffix = '%',
        Callback = function(V) NC.PosX = V; Apply() end,
    })
    Groupbox:AddSlider('NotifyPosY', {
        Text = 'Position Y',
        Default = NC.PosY or 60,
        Min = 0, Max = 100, Rounding = 0, Suffix = '%',
        Callback = function(V) NC.PosY = V; Apply() end,
    })
    Groupbox:AddSlider('NotifyTransparency', {
        Text = 'Transparency',
        Default = NC.Transparency or 25,
        Min = 0, Max = 100, Rounding = 0, Suffix = '%',
        Callback = function(V) NC.Transparency = V; Apply() end,
    })
    Groupbox:AddDropdown('NotifyAlign', {
        Text = 'Alignment',
        Values = { 'Center', 'Left', 'Right' },
        Default = 1,
        Callback = function(V) NC.Alignment = V; Apply() end,
    })
    Groupbox:AddDropdown('NotifyBarSide', {
        Text = 'Bar Side',
        Values = { 'Bottom', 'Top', 'Left', 'Right' },
        Default = 1,
        Callback = function(V) NC.BarSide = V; Apply() end,
    })
    Groupbox:AddDropdown('NotifySortOrder', {
        Text = 'Sort Order',
        Values = { 'Default', 'Time', 'Reverse' },
        Default = 1,
        Callback = function(V) NC.SortOrder = V; Apply() end,
    })
    Groupbox:AddSlider('NotifyDuration', {
        Text = 'Default Duration',
        Default = Library.NotifyDefaultTime or 5,
        Min = 1, Max = 15, Rounding = 0, Suffix = 's',
        Callback = function(V) Library.NotifyDefaultTime = V end,
    })
    Groupbox:AddButton('Send Notification', function()
        Library:Notify('Test notification', Library.NotifyDefaultTime or 5)
    end)
end

function Library:SetAutoLoad(opts)
    opts = opts or {}
    Library.AutoLoadEnabled = opts.Enabled ~= false
    Library.AutoLoadSilent = opts.Silent == true
end

function Library:RunAutoLoad(ThemeManager, SaveManager)
    if Library.AutoLoadEnabled == false then return end
    local silent = Library.AutoLoadSilent == true
    pcall(function()
        if ThemeManager and ThemeManager.TryAutoLoad then
            ThemeManager:TryAutoLoad()
        end
    end)
    pcall(function()
        if SaveManager then
            if SaveManager.LoadAutoloadConfig then
                SaveManager:LoadAutoloadConfig()
            elseif SaveManager.TryAutoLoad then
                SaveManager:TryAutoLoad()
            end
        end
    end)
    if not silent and Library.Notify then
        Library:Notify("Auto-load done", 3)
    end
end

function Library:SetAutoExecute(source)
    if type(source) ~= "string" or source == "" then return false end
    Library._AutoExecuteSource = source
    local ok = false
    pcall(function()
        local q = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
        if q then
            q(source)
            Library._AutoExecuteQueued = true
            ok = true
        end
    end)
    return ok
end

function Library:EnableAutoExecuteFromUrl(url)
    if type(url) ~= "string" or url == "" then return false end
    local src = string.format('loadstring(game:HttpGet(%q))()', url)
    return Library:SetAutoExecute(src)
end

function Library:NotifyScriptReady(name)
    name = name or "Script"
    pcall(function()
        Library:Notify(name .. " loaded", 4)
    end)
end

function Library:ForceShow()
    pcall(function()
        Library.Toggled = true
        if Library.WindowOuter then
            Library.WindowOuter.Visible = true
        end
        if Library.UpdateBlur then Library:UpdateBlur() end
    end)
end


Library.ThemePresets = Library.ThemePresets or {}
do
    local P = Library.ThemePresets
    local function T(font, main, bg, accent, outline)
        return {
            FontColor = font,
            MainColor = main,
            BackgroundColor = bg,
            AccentColor = accent,
            OutlineColor = outline,
        }
    end
    P["Default"] = T(Color3.fromRGB(255,255,255), Color3.fromRGB(28,28,28), Color3.fromRGB(20,20,20), Color3.fromRGB(0,155,255), Color3.fromRGB(50,50,50))
    P["BlackWhite"] = T(Color3.fromRGB(220,220,220), Color3.fromRGB(28,28,28), Color3.fromRGB(18,18,18), Color3.fromRGB(200,200,200), Color3.fromRGB(45,45,45))
    P["Darker"] = T(Color3.fromRGB(200,200,200), Color3.fromRGB(16,16,16), Color3.fromRGB(10,10,10), Color3.fromRGB(90,90,90), Color3.fromRGB(35,35,35))
    P["Aqua"] = T(Color3.fromRGB(210,245,255), Color3.fromRGB(20,28,32), Color3.fromRGB(12,16,20), Color3.fromRGB(0,200,220), Color3.fromRGB(40,55,60))
    P["Matrix"] = T(Color3.fromRGB(180,255,180), Color3.fromRGB(16,24,16), Color3.fromRGB(8,14,8), Color3.fromRGB(0,255,70), Color3.fromRGB(30,50,30))
    P["Blood"] = T(Color3.fromRGB(255,220,220), Color3.fromRGB(32,18,18), Color3.fromRGB(18,10,10), Color3.fromRGB(180,20,30), Color3.fromRGB(55,22,22))
    P["Nord"] = T(Color3.fromRGB(216,222,233), Color3.fromRGB(46,52,64), Color3.fromRGB(36,41,51), Color3.fromRGB(136,192,208), Color3.fromRGB(59,66,82))
    P["Purple"] = T(Color3.fromRGB(235,220,255), Color3.fromRGB(28,22,36), Color3.fromRGB(16,12,22), Color3.fromRGB(140,70,200), Color3.fromRGB(50,40,65))
    P["DarkBlue"] = T(Color3.fromRGB(220,230,255), Color3.fromRGB(22,26,36), Color3.fromRGB(14,16,24), Color3.fromRGB(71,119,182), Color3.fromRGB(40,48,64))
    P["TokyoNight"] = T(Color3.fromRGB(192,202,245), Color3.fromRGB(26,27,38), Color3.fromRGB(15,16,24), Color3.fromRGB(122,162,247), Color3.fromRGB(41,46,66))
    P["Dracula"] = T(Color3.fromRGB(248,248,242), Color3.fromRGB(40,42,54), Color3.fromRGB(30,31,41), Color3.fromRGB(189,147,249), Color3.fromRGB(68,71,90))
    P["Emerald"] = T(Color3.fromRGB(210,255,220), Color3.fromRGB(18,28,22), Color3.fromRGB(10,16,12), Color3.fromRGB(40,200,120), Color3.fromRGB(35,55,42))
    P["Crimson"] = T(Color3.fromRGB(255,230,230), Color3.fromRGB(30,18,20), Color3.fromRGB(16,10,12), Color3.fromRGB(220,50,70), Color3.fromRGB(55,28,32))
    P["Gold"] = T(Color3.fromRGB(255,245,210), Color3.fromRGB(32,28,18), Color3.fromRGB(18,16,10), Color3.fromRGB(220,180,40), Color3.fromRGB(60,50,25))
    P["Rose"] = T(Color3.fromRGB(255,230,240), Color3.fromRGB(32,20,26), Color3.fromRGB(18,12,16), Color3.fromRGB(240,100,150), Color3.fromRGB(55,30,40))
    P["Orange"] = T(Color3.fromRGB(255,240,220), Color3.fromRGB(32,24,16), Color3.fromRGB(18,14,10), Color3.fromRGB(255,140,40), Color3.fromRGB(55,40,25))
    P["Mint"] = T(Color3.fromRGB(220,255,240), Color3.fromRGB(18,30,26), Color3.fromRGB(10,18,16), Color3.fromRGB(80,220,180), Color3.fromRGB(35,55,48))
    P["Cyan"] = T(Color3.fromRGB(220,250,255), Color3.fromRGB(18,26,30), Color3.fromRGB(10,16,20), Color3.fromRGB(0,220,255), Color3.fromRGB(35,50,55))
    P["Lava"] = T(Color3.fromRGB(255,230,210), Color3.fromRGB(30,16,12), Color3.fromRGB(16,8,6), Color3.fromRGB(255,80,20), Color3.fromRGB(55,25,15))
    P["Ocean"] = T(Color3.fromRGB(210,230,255), Color3.fromRGB(18,24,34), Color3.fromRGB(10,14,22), Color3.fromRGB(40,120,200), Color3.fromRGB(30,40,55))
    P["Midnight"] = T(Color3.fromRGB(200,210,230), Color3.fromRGB(14,16,24), Color3.fromRGB(8,10,16), Color3.fromRGB(80,100,180), Color3.fromRGB(28,32,45))
    P["BBot"] = T(Color3.fromRGB(255,255,255), Color3.fromRGB(30,30,30), Color3.fromRGB(35,35,35), Color3.fromRGB(126,72,163), Color3.fromRGB(20,20,20))
    P["Fatality"] = T(Color3.fromRGB(255,255,255), Color3.fromRGB(30,30,30), Color3.fromRGB(20,20,20), Color3.fromRGB(255,40,40), Color3.fromRGB(40,40,40))
    P["Ubuntu"] = T(Color3.fromRGB(255,255,255), Color3.fromRGB(48,48,48), Color3.fromRGB(56,56,56), Color3.fromRGB(233,84,32), Color3.fromRGB(30,30,30))
    P["Quartz"] = T(Color3.fromRGB(255,255,255), Color3.fromRGB(25,25,25), Color3.fromRGB(19,19,19), Color3.fromRGB(145,145,145), Color3.fromRGB(40,40,40))
    P["Green"] = T(Color3.fromRGB(210,255,210), Color3.fromRGB(20,28,20), Color3.fromRGB(12,18,12), Color3.fromRGB(40,200,80), Color3.fromRGB(35,50,35))
    P["Red"] = T(Color3.fromRGB(255,220,220), Color3.fromRGB(28,18,18), Color3.fromRGB(16,10,10), Color3.fromRGB(220,40,40), Color3.fromRGB(50,25,25))
    P["Pink"] = T(Color3.fromRGB(255,230,245), Color3.fromRGB(30,20,28), Color3.fromRGB(18,12,16), Color3.fromRGB(255,105,180), Color3.fromRGB(50,30,40))
    P["Monokai"] = T(Color3.fromRGB(248,248,242), Color3.fromRGB(39,40,34), Color3.fromRGB(30,31,28), Color3.fromRGB(249,38,114), Color3.fromRGB(55,55,50))
    P["Solarized"] = T(Color3.fromRGB(238,232,213), Color3.fromRGB(7,54,66), Color3.fromRGB(0,43,54), Color3.fromRGB(38,139,210), Color3.fromRGB(20,60,70))
    P["Gruvbox"] = T(Color3.fromRGB(235,219,178), Color3.fromRGB(60,56,54), Color3.fromRGB(40,40,40), Color3.fromRGB(251,184,41), Color3.fromRGB(80,73,69))
    P["Catppuccin"] = T(Color3.fromRGB(205,214,244), Color3.fromRGB(30,30,46), Color3.fromRGB(24,24,37), Color3.fromRGB(203,166,247), Color3.fromRGB(49,50,68))
    P["OneDark"] = T(Color3.fromRGB(171,178,191), Color3.fromRGB(40,44,52), Color3.fromRGB(33,37,43), Color3.fromRGB(97,175,239), Color3.fromRGB(55,60,70))
    P["Synthwave"] = T(Color3.fromRGB(255,230,255), Color3.fromRGB(30,16,40), Color3.fromRGB(16,8,24), Color3.fromRGB(255,0,170), Color3.fromRGB(50,25,60))
    P["Forest"] = T(Color3.fromRGB(220,240,220), Color3.fromRGB(22,30,22), Color3.fromRGB(12,18,12), Color3.fromRGB(70,160,80), Color3.fromRGB(35,50,35))
    P["Ice"] = T(Color3.fromRGB(230,245,255), Color3.fromRGB(22,28,34), Color3.fromRGB(12,16,22), Color3.fromRGB(140,200,255), Color3.fromRGB(40,50,60))
    P["Royal"] = T(Color3.fromRGB(240,230,255), Color3.fromRGB(24,20,36), Color3.fromRGB(14,12,22), Color3.fromRGB(120,80,220), Color3.fromRGB(40,35,55))
    P["Sand"] = T(Color3.fromRGB(255,245,220), Color3.fromRGB(36,30,22), Color3.fromRGB(22,18,12), Color3.fromRGB(210,170,90), Color3.fromRGB(55,45,30))
    P["Steel"] = T(Color3.fromRGB(220,225,230), Color3.fromRGB(28,30,34), Color3.fromRGB(16,18,22), Color3.fromRGB(120,140,160), Color3.fromRGB(45,50,55))
    P["Neon"] = T(Color3.fromRGB(230,255,240), Color3.fromRGB(16,20,18), Color3.fromRGB(8,12,10), Color3.fromRGB(0,255,170), Color3.fromRGB(30,45,40))
    P["Violet"] = T(Color3.fromRGB(240,230,255), Color3.fromRGB(26,20,36), Color3.fromRGB(14,12,22), Color3.fromRGB(160,80,255), Color3.fromRGB(45,35,60))
    P["Amber"] = T(Color3.fromRGB(255,245,220), Color3.fromRGB(32,26,16), Color3.fromRGB(18,14,8), Color3.fromRGB(255,170,30), Color3.fromRGB(55,42,20))
    P["Slate"] = T(Color3.fromRGB(220,225,235), Color3.fromRGB(30,34,40), Color3.fromRGB(18,20,26), Color3.fromRGB(100,120,150), Color3.fromRGB(45,50,60))
    P["Coral"] = T(Color3.fromRGB(255,235,230), Color3.fromRGB(32,22,20), Color3.fromRGB(18,12,12), Color3.fromRGB(255,110,90), Color3.fromRGB(55,35,30))
    P["Indigo"] = T(Color3.fromRGB(230,235,255), Color3.fromRGB(22,22,36), Color3.fromRGB(12,12,22), Color3.fromRGB(90,100,220), Color3.fromRGB(35,35,55))
    P["Lime"] = T(Color3.fromRGB(240,255,220), Color3.fromRGB(22,28,16), Color3.fromRGB(12,16,8), Color3.fromRGB(160,230,40), Color3.fromRGB(40,50,30))
    P["Sky"] = T(Color3.fromRGB(230,245,255), Color3.fromRGB(20,26,34), Color3.fromRGB(12,16,22), Color3.fromRGB(80,180,255), Color3.fromRGB(35,45,55))
    P["Wine"] = T(Color3.fromRGB(255,230,235), Color3.fromRGB(30,16,20), Color3.fromRGB(16,8,12), Color3.fromRGB(160,30,60), Color3.fromRGB(50,25,30))
    P["Graphite"] = T(Color3.fromRGB(210,210,210), Color3.fromRGB(26,26,26), Color3.fromRGB(14,14,14), Color3.fromRGB(120,120,120), Color3.fromRGB(40,40,40))
    P["Azure"] = T(Color3.fromRGB(230,245,255), Color3.fromRGB(18,24,32), Color3.fromRGB(10,14,20), Color3.fromRGB(0,140,255), Color3.fromRGB(30,40,50))
    P["Magma"] = T(Color3.fromRGB(255,235,220), Color3.fromRGB(28,14,10), Color3.fromRGB(14,6,4), Color3.fromRGB(255,60,0), Color3.fromRGB(50,20,12))
    P["Frost"] = T(Color3.fromRGB(240,250,255), Color3.fromRGB(24,28,34), Color3.fromRGB(14,16,22), Color3.fromRGB(180,220,255), Color3.fromRGB(40,48,55))
    P["Shadow"] = T(Color3.fromRGB(180,180,190), Color3.fromRGB(14,14,18), Color3.fromRGB(6,6,10), Color3.fromRGB(70,70,90), Color3.fromRGB(25,25,30))
    P["Pearl"] = T(Color3.fromRGB(245,245,250), Color3.fromRGB(34,34,38), Color3.fromRGB(22,22,26), Color3.fromRGB(200,200,220), Color3.fromRGB(50,50,55))
    P["Jade"] = T(Color3.fromRGB(220,255,235), Color3.fromRGB(16,28,22), Color3.fromRGB(8,16,12), Color3.fromRGB(0,180,120), Color3.fromRGB(30,50,40))
    P["Cobalt"] = T(Color3.fromRGB(220,235,255), Color3.fromRGB(16,22,34), Color3.fromRGB(8,12,20), Color3.fromRGB(40,90,200), Color3.fromRGB(28,35,50))
    P["Cherry"] = T(Color3.fromRGB(255,230,235), Color3.fromRGB(30,16,18), Color3.fromRGB(16,8,10), Color3.fromRGB(220,40,80), Color3.fromRGB(50,25,28))
    P["Olive"] = T(Color3.fromRGB(235,240,210), Color3.fromRGB(28,30,20), Color3.fromRGB(16,18,10), Color3.fromRGB(140,160,40), Color3.fromRGB(45,50,30))
    P["Teal"] = T(Color3.fromRGB(220,250,250), Color3.fromRGB(18,28,28), Color3.fromRGB(10,16,16), Color3.fromRGB(0,180,180), Color3.fromRGB(30,50,50))
    P["Berry"] = T(Color3.fromRGB(250,230,255), Color3.fromRGB(28,18,32), Color3.fromRGB(16,10,18), Color3.fromRGB(180,60,180), Color3.fromRGB(50,30,55))
    P["Copper"] = T(Color3.fromRGB(255,235,220), Color3.fromRGB(32,24,18), Color3.fromRGB(18,14,10), Color3.fromRGB(200,110,50), Color3.fromRGB(55,40,25))
    P["Platinum"] = T(Color3.fromRGB(240,245,250), Color3.fromRGB(32,34,38), Color3.fromRGB(20,22,26), Color3.fromRGB(180,190,200), Color3.fromRGB(50,55,60))
    P["Rainbow"] = T(Color3.fromRGB(255,255,255), Color3.fromRGB(24,24,28), Color3.fromRGB(14,14,18), Color3.fromRGB(255,100,180), Color3.fromRGB(45,45,50))
end

function Library:GetThemePresetNames()
    local names = {}
    for k in pairs(Library.ThemePresets or {}) do
        table.insert(names, k)
    end
    table.sort(names)
    return names
end

function Library:ApplyThemePreset(name)
    local p = Library.ThemePresets and Library.ThemePresets[name]
    if not p then return false end
    if Library.ApplyThemeColors then
        Library:ApplyThemeColors(p)
    else
        for k, v in pairs(p) do Library[k] = v end
        Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
        Library:UpdateColorsUsingRegistry()
    end
    Library.ActiveThemePreset = name
    return true
end

Library.FontFaces = {}
pcall(function()
    local names = {
        "Code","Ubuntu","Gotham","GothamBold","SourceSans","SourceSansBold",
        "Legacy","Arcade","Cartoon","SciFi","Bodoni","Garamond","Highway",
        "FredokaOne","DenkOne","JosefinSans","Nunito","Oswald","Roboto",
        "RobotoCondensed","RobotoMono",
    }
    for _, n in ipairs(names) do
        pcall(function()
            local f = Enum.Font[n]
            if f then Library.FontFaces[n] = f end
        end)
    end
    if not Library.FontFaces.Code then Library.FontFaces.Code = Enum.Font.Code end
    if not Library.FontFaces.Body and Enum.Font.Bodoni then Library.FontFaces.Body = Enum.Font.Bodoni end
end)

function Library:SetFontFace(name)
    local f = Library.FontFaces[name] or Enum.Font.Code
    Library.Font = f
    pcall(function()
        for _, data in pairs(Library.Registry or {}) do
            local inst = data.Instance
            if inst and (inst:IsA("TextLabel") or inst:IsA("TextButton")) then
                pcall(function() inst.Font = f end)
            end
        end
    end)
end

Library.Sounds = Library.Sounds or {
    Enabled = false,
    Volume = 0.35,
    Click = "rbxassetid://6895079853",
    Toggle = "rbxassetid://6895079853",
    Hover = "rbxassetid://10066936758",
    Notify = "rbxassetid://4590657391",
    Open = "rbxassetid://6042053626",
    Close = "rbxassetid://6042053626",
}

function Library:PlayUISound(kind)
    if not (Library.Sounds and Library.Sounds.Enabled) then return end
    pcall(function()
        local id = Library.Sounds[kind] or Library.Sounds.Click
        local s = Instance.new("Sound")
        s.SoundId = id
        s.Volume = Library.Sounds.Volume or 0.3
        s.Parent = game:GetService("SoundService")
        s:Play()
        task.delay(2, function() pcall(function() s:Destroy() end) end)
    end)
end

function Library:SetSoundsEnabled(on)
    Library.Sounds = Library.Sounds or {}
    Library.Sounds.Enabled = on and true or false
end

Library.Anim = Library.Anim or {}
function Library.Anim:Tween(inst, props, time, style, dir)
    time = time or 0.18
    style = style or Enum.EasingStyle.Quart
    dir = dir or Enum.EasingDirection.Out
    local tw = game:GetService("TweenService"):Create(inst, TweenInfo.new(time, style, dir), props)
    tw:Play()
    return tw
end

function Library.Anim:FadeIn(inst, time)
    if not inst then return end
    inst.Visible = true
    pcall(function()
        if inst:IsA("Frame") or inst:IsA("TextLabel") or inst:IsA("ImageLabel") then
            local goal = {}
            if inst:IsA("Frame") then
                local t = inst.BackgroundTransparency
                inst.BackgroundTransparency = 1
                goal.BackgroundTransparency = t
            end
            Library.Anim:Tween(inst, goal, time or 0.2)
        end
    end)
end

function Library.Anim:Pulse(inst, scale, time)
    if not inst then return end
    pcall(function()
        local uis = inst:FindFirstChildOfClass("UIScale")
        if not uis then
            uis = Instance.new("UIScale")
            uis.Parent = inst
        end
        uis.Scale = 1
        local tw = Library.Anim:Tween(uis, { Scale = scale or 1.04 }, (time or 0.12) / 2)
        tw.Completed:Connect(function()
            Library.Anim:Tween(uis, { Scale = 1 }, (time or 0.12) / 2)
        end)
    end)
end

Library.Profiles = {
    Ultra = { PerformanceMode = false, UseBlur = true, BlurSize = 24, Glass = 0.88, WireframeDrag = true },
    High = { PerformanceMode = false, UseBlur = true, BlurSize = 18, Glass = 0.8, WireframeDrag = true },
    Balanced = { PerformanceMode = true, UseBlur = true, BlurSize = 12, Glass = 0.72, WireframeDrag = true },
    Performance = { PerformanceMode = true, UseBlur = false, BlurSize = 0, Glass = 0.55, WireframeDrag = false },
    Potato = { PerformanceMode = true, UseBlur = false, BlurSize = 0, Glass = 0, WireframeDrag = false },
}

function Library:ApplyProfile(name)
    local p = Library.Profiles[name]
    if not p then return end
    Library.PerformanceMode = p.PerformanceMode
    Library.UseBlur = p.UseBlur
    Library.BlurSize = p.BlurSize
    Library.WireframeDrag = p.WireframeDrag
    if p.Glass and p.Glass > 0 then
        pcall(function() Library:SetGlass(true, p.Glass) end)
    else
        pcall(function() Library:SetGlass(false) end)
    end
    pcall(function() if Library.UpdateBlur then Library:UpdateBlur() end end)
    Library.ActiveProfile = name
end

function Library:CreateWatermark(text)
    text = text or "vercel.cc"
    pcall(function()
        if Library._WatermarkGui then Library._WatermarkGui:Destroy() end
        local g = Instance.new("ScreenGui")
        g.Name = "Vercel_Watermark"
        g.DisplayOrder = 50
        g.ResetOnSpawn = false
        ProtectGui(g)
        g.Parent = CoreGui
        local f = Instance.new("Frame")
        f.BackgroundColor3 = Library.MainColor
        f.BackgroundTransparency = 0.25
        f.BorderSizePixel = 0
        f.Position = UDim2.new(0, 12, 0, 12)
        f.Size = UDim2.new(0, 180, 0, 22)
        f.Parent = g
        local s = Instance.new("UIStroke")
        s.Color = Library.OutlineColor
        s.Thickness = 1
        s.Parent = f
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Size = UDim2.new(1, -8, 1, 0)
        l.Position = UDim2.new(0, 6, 0, 0)
        l.Font = Library.Font or Enum.Font.Code
        l.TextSize = 13
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextColor3 = Library.FontColor
        l.Text = text
        l.Parent = f
        Library._WatermarkGui = g
        Library._WatermarkLabel = l
        local frames, last = 0, tick()
        local fps = 0
        task.spawn(function()
            while g.Parent do
                frames = frames + 1
                local now = tick()
                if now - last >= 0.5 then
                    fps = math.floor(frames / (now - last) + 0.5)
                    frames = 0
                    last = now
                    l.Text = string.format("%s | %d FPS", text, fps)
                end
                task.wait()
            end
        end)
    end)
end

function Library:DestroyWatermark()
    pcall(function()
        if Library._WatermarkGui then Library._WatermarkGui:Destroy() end
        Library._WatermarkGui = nil
    end)
end

function Library:CreateLiveStudUI(opts)
    opts = opts or {}
    local title = opts.Title or Library.ScriptName or "vercel.cc"
    local showFps = opts.ShowFPS ~= false

    pcall(function()
        if Library._StudConn then Library._StudConn:Disconnect() end
        if Library._StudGui then Library._StudGui:Destroy() end
    end)

    local g = Instance.new("ScreenGui")
    g.Name = "Vercel_LiveStud"
    g.DisplayOrder = 55
    g.ResetOnSpawn = false
    g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ProtectGui(g)
    g.Parent = CoreGui

    local f = Instance.new("Frame")
    f.Name = "StudFrame"
    f.BackgroundColor3 = Library.MainColor
    f.BackgroundTransparency = 0.18
    f.BorderSizePixel = 0
    f.Position = UDim2.new(0, 14, 0, 48)
    f.Size = UDim2.new(0, 148, 0, showFps and 86 or 72)
    f.ClipsDescendants = true
    f.Parent = g

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = f

    local stroke = Instance.new("UIStroke")
    stroke.Name = "StudStroke"
    stroke.Color = Library.OutlineColor
    stroke.Thickness = 1
    stroke.Transparency = 0.25
    stroke.Parent = f

    local grad = Instance.new("UIGradient")
    grad.Rotation = 90
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 190)),
    })
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(1, 0.35),
    })
    grad.Parent = f

    local topLine = Instance.new("Frame")
    topLine.Name = "TopLine"
    topLine.BorderSizePixel = 0
    topLine.BackgroundColor3 = Library.AccentColor
    topLine.Size = UDim2.new(1, 0, 0, 2)
    topLine.Position = UDim2.new(0, 0, 0, 0)
    topLine.ZIndex = 3
    topLine.Parent = f

    local accentBar = Instance.new("Frame")
    accentBar.Name = "StudAccent"
    accentBar.BackgroundColor3 = Library.AccentColor
    accentBar.BorderSizePixel = 0
    accentBar.Size = UDim2.new(0, 3, 1, 0)
    accentBar.ZIndex = 3
    accentBar.Parent = f

    local titleL = Instance.new("TextLabel")
    titleL.Name = "StudTitle"
    titleL.BackgroundTransparency = 1
    titleL.Size = UDim2.new(1, -16, 0, 16)
    titleL.Position = UDim2.new(0, 10, 0, 5)
    titleL.Font = Enum.Font.GothamBold
    titleL.TextSize = 12
    titleL.TextXAlignment = Enum.TextXAlignment.Left
    titleL.TextColor3 = Library.AccentColor
    titleL.Text = title
    titleL.ZIndex = 4
    titleL.Parent = f

    local div = Instance.new("Frame")
    div.Name = "Divider"
    div.BackgroundColor3 = Library.OutlineColor
    div.BackgroundTransparency = 0.55
    div.BorderSizePixel = 0
    div.Size = UDim2.new(1, -14, 0, 1)
    div.Position = UDim2.new(0, 10, 0, 22)
    div.ZIndex = 3
    div.Parent = f

    local function makeRow(name, y, labelColor)
        local row = Instance.new("Frame")
        row.Name = name .. "Row"
        row.BackgroundTransparency = 1
        row.Size = UDim2.new(1, -16, 0, 14)
        row.Position = UDim2.new(0, 10, 0, y)
        row.ZIndex = 4
        row.Parent = f

        local tag = Instance.new("TextLabel")
        tag.Name = "Tag"
        tag.BackgroundTransparency = 1
        tag.Size = UDim2.new(0, 18, 1, 0)
        tag.Font = Enum.Font.Code
        tag.TextSize = 12
        tag.TextXAlignment = Enum.TextXAlignment.Left
        tag.TextColor3 = labelColor
        tag.Text = name
        tag.ZIndex = 5
        tag.Parent = row

        local val = Instance.new("TextLabel")
        val.Name = "Val"
        val.BackgroundTransparency = 1
        val.Size = UDim2.new(1, -22, 1, 0)
        val.Position = UDim2.new(0, 20, 0, 0)
        val.Font = Enum.Font.Code
        val.TextSize = 12
        val.TextXAlignment = Enum.TextXAlignment.Left
        val.TextColor3 = Library.FontColor
        val.Text = "0.0"
        val.ZIndex = 5
        val.Parent = row
        return val
    end

    local xVal = makeRow("X", 26, Color3.fromRGB(255, 95, 95))
    local yVal = makeRow("Y", 40, Color3.fromRGB(95, 255, 130))
    local zVal = makeRow("Z", 54, Color3.fromRGB(95, 160, 255))

    local fpsL
    if showFps then
        fpsL = Instance.new("TextLabel")
        fpsL.Name = "StudFPS"
        fpsL.BackgroundTransparency = 1
        fpsL.Size = UDim2.new(1, -16, 0, 12)
        fpsL.Position = UDim2.new(0, 10, 0, 70)
        fpsL.Font = Enum.Font.Code
        fpsL.TextSize = 11
        fpsL.TextXAlignment = Enum.TextXAlignment.Left
        fpsL.TextColor3 = Color3.fromRGB(170, 170, 180)
        fpsL.Text = "FPS 0"
        fpsL.ZIndex = 4
        fpsL.Parent = f
    end

    Library._StudGui = g
    Library._StudFrame = f
    Library._StudStroke = stroke
    Library._StudAccent = accentBar
    Library._StudTopLine = topLine
    Library._StudTitle = titleL
    Library._StudX = xVal
    Library._StudY = yVal
    Library._StudZ = zVal
    Library._StudFPS = fpsL
    Library._StudDiv = div

    function Library:SyncStudTheme()
        pcall(function()
            if not Library._StudFrame then return end
            Library._StudFrame.BackgroundColor3 = Library.MainColor
            if Library._StudStroke then Library._StudStroke.Color = Library.OutlineColor end
            if Library._StudAccent then Library._StudAccent.BackgroundColor3 = Library.AccentColor end
            if Library._StudTopLine then Library._StudTopLine.BackgroundColor3 = Library.AccentColor end
            if Library._StudTitle then Library._StudTitle.TextColor3 = Library.AccentColor end
            if Library._StudDiv then Library._StudDiv.BackgroundColor3 = Library.OutlineColor end
            for _, lab in ipairs({ Library._StudX, Library._StudY, Library._StudZ }) do
                if lab then lab.TextColor3 = Library.FontColor end
            end
        end)
    end

    local frames, last = 0, tick()
    local fps = 0
    Library._StudConn = RunService.RenderStepped:Connect(function()
        pcall(function()
            local char = LocalPlayer and LocalPlayer.Character
            local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
            if root then
                local p = root.Position
                if Library._StudX then Library._StudX.Text = string.format("%.1f", p.X) end
                if Library._StudY then Library._StudY.Text = string.format("%.1f", p.Y) end
                if Library._StudZ then Library._StudZ.Text = string.format("%.1f", p.Z) end
            end
            if Library._StudFPS then
                frames = frames + 1
                local now = tick()
                if now - last >= 0.5 then
                    fps = math.floor(frames / (now - last) + 0.5)
                    frames = 0
                    last = now
                    Library._StudFPS.Text = "FPS " .. tostring(fps)
                end
            end
        end)
    end)

    f.BackgroundTransparency = 1
    stroke.Transparency = 1
    TweenService:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.18,
    }):Play()
    TweenService:Create(stroke, TweenInfo.new(0.35), { Transparency = 0.25 }):Play()

    return g
end

function Library:DestroyLiveStudUI()
    pcall(function()
        if Library._StudConn then Library._StudConn:Disconnect() end
        Library._StudConn = nil
        if Library._StudGui then Library._StudGui:Destroy() end
        Library._StudGui = nil
        Library._StudFrame = nil
    end)
end

function Library:ShowLiveStud(title)
    return Library:CreateLiveStudUI({ Title = title or Library.ScriptName or "vercel.cc" })
end

function Library:HideLiveStud()
    return Library:DestroyLiveStudUI()
end


function Library:GetActiveKeybinds()
    local list = {}
    for idx, opt in pairs(Options or {}) do
        if type(opt) == "table" and opt.Type == "KeyPicker" then
            table.insert(list, { Index = idx, Text = opt.Text or idx, Value = opt.Value, Mode = opt.Mode })
        end
    end
    return list
end

function Library:SafeUnload()
    pcall(function() Library:DestroyWatermark() end)
    pcall(function() Library:DestroyLiveStudUI() end)
    pcall(function()
        if Library.MobileGui then Library.MobileGui:Destroy() end
    end)
    pcall(function()
        if Library.Unload then Library:Unload() end
    end)
end

function Library:DeepCopy(t)
    if type(t) ~= "table" then return t end
    local n = {}
    for k, v in pairs(t) do
        n[Library:DeepCopy(k)] = Library:DeepCopy(v)
    end
    return n
end

function Library:ColorToHex(c)
    if typeof(c) ~= "Color3" then return "#ffffff" end
    return string.format("#%02x%02x%02x", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
end

function Library:HexToColor(hex)
    hex = tostring(hex or ""):gsub("#", "")
    if #hex < 6 then return Color3.new(1,1,1) end
    local r = tonumber(hex:sub(1,2), 16) or 255
    local g = tonumber(hex:sub(3,4), 16) or 255
    local b = tonumber(hex:sub(5,6), 16) or 255
    return Color3.fromRGB(r, g, b)
end

Library.GlassPresets = {
    Off = 0,
    Soft = 0.55,
    Medium = 0.7,
    Strong = 0.82,
    Max = 0.92,
}

function Library:ApplyGlassPreset(name)
    local v = Library.GlassPresets[name]
    if v == nil then return end
    if v <= 0 then
        pcall(function() Library:SetGlass(false) end)
    else
        pcall(function() Library:SetGlass(true, v) end)
    end
end

function Library:ShowTabByName(window, name)
    if not window or not window.Tabs then return end
    local t = window.Tabs[name]
    if t and t.ShowTab then t:ShowTab() end
end

function Library:NotifyMany(messages, delayBetween)
    delayBetween = delayBetween or 0.35
    task.spawn(function()
        for _, msg in ipairs(messages or {}) do
            Library:Notify(tostring(msg))
            task.wait(delayBetween)
        end
    end)
end

function Library:CreateDebugConsole()
    pcall(function()
        if Library._DebugGui then Library._DebugGui:Destroy() end
        local g = Instance.new("ScreenGui")
        g.Name = "Vercel_Debug"
        g.DisplayOrder = 200
        ProtectGui(g)
        g.Parent = CoreGui
        local f = Instance.new("ScrollingFrame")
        f.BackgroundColor3 = Color3.fromRGB(10,10,12)
        f.BackgroundTransparency = 0.2
        f.Size = UDim2.new(0, 360, 0, 160)
        f.Position = UDim2.new(1, -370, 1, -170)
        f.CanvasSize = UDim2.new(0, 0, 0, 0)
        f.ScrollBarThickness = 4
        f.Parent = g
        local lay = Instance.new("UIListLayout")
        lay.Parent = f
        Library._DebugGui = g
        Library._DebugFrame = f
        Library._DebugLayout = lay
        function Library:DebugLog(text)
            pcall(function()
                local l = Instance.new("TextLabel")
                l.BackgroundTransparency = 1
                l.Size = UDim2.new(1, -8, 0, 16)
                l.Font = Enum.Font.Code
                l.TextSize = 12
                l.TextXAlignment = Enum.TextXAlignment.Left
                l.TextColor3 = Color3.fromRGB(200, 220, 200)
                l.Text = os.date("[%H:%M:%S] ") .. tostring(text)
                l.Parent = f
                f.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 8)
                f.CanvasPosition = Vector2.new(0, lay.AbsoluteContentSize.Y)
            end)
        end
    end)
end

function Library:ResetAllToggles(defaultValue)
    defaultValue = defaultValue and true or false
    for _, t in pairs(Toggles or {}) do
        pcall(function()
            if t.SetValue then t:SetValue(defaultValue) end
        end)
    end
end

function Library:SetScriptIdentity(name, version)
    Library.ScriptName = name or "Script"
    Library.ScriptVersion = version or "1.0"
end

function Library:GetScriptIdentity()
    return string.format("%s v%s", Library.ScriptName or "vercel.cc", Library.ScriptVersion or "1")
end

Library.ToggleUI = Library.ToggleUI or function() Library:Toggle() end
Library.ShowUI = Library.ShowUI or function() pcall(function() Library:ForceShow() end) end

function Library:ForceRepaint()
    pcall(function() Library:UpdateColorsUsingRegistry() end)
    pcall(function() if Library.ReapplyGlass then Library:ReapplyGlass() end end)
    pcall(function() if Library.UpdateBlur then Library:UpdateBlur() end end)
end

Library.API = {
    CreateWindow = true,
    AddTab = true,
    AddLeftGroupbox = true,
    AddRightGroupbox = true,
    AddToggle = true,
    AddSlider = true,
    AddDropdown = true,
    AddButton = true,
    AddLabel = true,
    AddKeyPicker = true,
    AddColorPicker = true,
    AddDivider = true,
    AddInput = true,
    Notify = true,
    SetGlass = true,
    ApplyThemePreset = true,
    ApplyProfile = true,
    CreateWatermark = true,
    CreateLiveStudUI = true,
    SetAutoLoad = true,
    RunAutoLoad = true,
    SetAutoExecute = true,
    EnableAutoExecuteFromUrl = true,
    ForceShow = true,
    SafeUnload = true,
}

Library.ColorUtil = {}
function Library.ColorUtil.Lerp(a, b, t)
    return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end
function Library.ColorUtil.Darken(c, amt)
    amt = amt or 0.2
    return Color3.new(math.max(0, c.R * (1 - amt)), math.max(0, c.G * (1 - amt)), math.max(0, c.B * (1 - amt)))
end
function Library.ColorUtil.Lighten(c, amt)
    amt = amt or 0.2
    return Color3.new(c.R + (1 - c.R) * amt, c.G + (1 - c.G) * amt, c.B + (1 - c.B) * amt)
end
function Library.ColorUtil.Saturation(c, s)
    local h, sat, v = Color3.toHSV(c)
    return Color3.fromHSV(h, math.clamp(s, 0, 1), v)
end
function Library.ColorUtil.Value(c, v)
    local h, sat, val = Color3.toHSV(c)
    return Color3.fromHSV(h, sat, math.clamp(v, 0, 1))
end

Library.NotifyPresets = {
    Default = { Transparency = 25, PosX = 50, PosY = 60, BarSide = "Bottom" },
    TopCenter = { Transparency = 20, PosX = 50, PosY = 8, BarSide = "Top" },
    BottomRight = { Transparency = 30, PosX = 88, PosY = 90, BarSide = "Right" },
    BottomLeft = { Transparency = 30, PosX = 12, PosY = 90, BarSide = "Left" },
    Minimal = { Transparency = 50, PosX = 50, PosY = 85, BarSide = "Bottom" },
}
function Library:ApplyNotifyPreset(name)
    local p = Library.NotifyPresets[name]
    if not p then return end
    Library.NotifyConfig = Library.NotifyConfig or {}
    for k, v in pairs(p) do Library.NotifyConfig[k] = v end
end

Library.MobileLayouts = {
    TopLeft = { Toggle = UDim2.new(0, 10, 0, 10), Lock = UDim2.new(0, 10, 0, 42) },
    TopRight = { Toggle = UDim2.new(1, -82, 0, 10), Lock = UDim2.new(1, -82, 0, 42) },
    BottomLeft = { Toggle = UDim2.new(0, 10, 1, -70), Lock = UDim2.new(0, 10, 1, -40) },
}

function Library:Validate()
    local ok = true
    local missing = {}
    for name, _ in pairs(Library.API) do
        if Library[name] == nil and name ~= "AddTab" then
        end
    end
    return ok, missing
end

Library.ThemeMeta = {}
for name, colors in pairs(Library.ThemePresets) do
    Library.ThemeMeta[name] = {
        Name = name,
        AccentHex = Library:ColorToHex(colors.AccentColor),
        MainHex = Library:ColorToHex(colors.MainColor),
        BackgroundHex = Library:ColorToHex(colors.BackgroundColor),
        FontHex = Library:ColorToHex(colors.FontColor),
        OutlineHex = Library:ColorToHex(colors.OutlineColor),
        Tags = { "vercel", "preset", string.lower(name) },
    }
end

Library.GeneratedPalettes = {}

function Library:ApplyGeneratedPalette(id)
    local p = Library.GeneratedPalettes[id]
    if not p then return false end
    if Library.ApplyThemeColors then
        Library:ApplyThemeColors(p)
    else
        Library.FontColor = p.FontColor
        Library.MainColor = p.MainColor
        Library.BackgroundColor = p.BackgroundColor
        Library.AccentColor = p.AccentColor
        Library.OutlineColor = p.OutlineColor
        Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
        Library:UpdateColorsUsingRegistry()
    end
    return true
end


Library.ExtendedStrings = {}

function Library:GetTip(id)
    local t = Library.ExtendedStrings[id]
    return t and t.Tip or "vercel.cc"
end

function Library:RandomTip()
    local n = #Library.ExtendedStrings
    if n < 1 then return "vercel.cc" end
    return Library:GetTip(math.random(1, math.min(n, 119)))
end

Library.KeyCodes = {
    ["LeftControl"] = Enum.KeyCode.LeftControl,
    ["RightControl"] = Enum.KeyCode.RightControl,
    ["LeftShift"] = Enum.KeyCode.LeftShift,
    ["RightShift"] = Enum.KeyCode.RightShift,
    ["LeftAlt"] = Enum.KeyCode.LeftAlt,
    ["RightAlt"] = Enum.KeyCode.RightAlt,
    ["Space"] = Enum.KeyCode.Space,
    ["Tab"] = Enum.KeyCode.Tab,
    ["Escape"] = Enum.KeyCode.Escape,
    ["Return"] = Enum.KeyCode.Return,
    ["Backspace"] = Enum.KeyCode.Backspace,
}
Library.KeyCodes["0"] = Enum.KeyCode.Zero
Library.KeyCodes["1"] = Enum.KeyCode.One
Library.KeyCodes["2"] = Enum.KeyCode.Two
Library.KeyCodes["3"] = Enum.KeyCode.Three
Library.KeyCodes["4"] = Enum.KeyCode.Four
Library.KeyCodes["5"] = Enum.KeyCode.Five
Library.KeyCodes["6"] = Enum.KeyCode.Six
Library.KeyCodes["7"] = Enum.KeyCode.Seven
Library.KeyCodes["8"] = Enum.KeyCode.Eight
Library.KeyCodes["9"] = Enum.KeyCode.Nine
for c = string.byte("A"), string.byte("Z") do
    local ch = string.char(c)
    pcall(function()
        Library.KeyCodes[ch] = Enum.KeyCode[ch]
    end)
end

Library.GeneratedPalettes = Library.GeneratedPalettes or {}
Library.ExtendedStrings = Library.ExtendedStrings or {}

function Library:ApplyMaxPreset(opts)
    opts = opts or {}
    local skip = opts.Skip or {}
    local silent = opts.Silent == true
    local count = 0

    for idx, toggle in pairs(Toggles or {}) do
        if not skip[idx] then
            pcall(function()
                if toggle.SetValue then
                    toggle:SetValue(true)
                    count = count + 1
                end
            end)
        end
    end

    for idx, option in pairs(Options or {}) do
        if not skip[idx] then
            pcall(function()
                local ty = option.Type
                if ty == "Slider" and option.SetValue and option.Max ~= nil then
                    option:SetValue(option.Max)
                    count = count + 1
                elseif ty == "Dropdown" and option.SetValue and option.Values and #option.Values > 0 then
                    if opts.DropdownMode == "Last" then
                        option:SetValue(option.Values[#option.Values])
                    end
                    count = count + 1
                end
            end)
        end
    end

    if not silent and Library.Notify then
        Library:Notify(string.format("Max preset applied (%d options)", count), 4)
    end
    return count
end

function Library:ApplyMinPreset(opts)
    opts = opts or {}
    local skip = opts.Skip or {}
    local silent = opts.Silent == true
    local count = 0
    for idx, toggle in pairs(Toggles or {}) do
        if not skip[idx] then
            pcall(function()
                if toggle.SetValue then
                    toggle:SetValue(false)
                    count = count + 1
                end
            end)
        end
    end
    for idx, option in pairs(Options or {}) do
        if not skip[idx] then
            pcall(function()
                if option.Type == "Slider" and option.SetValue and option.Min ~= nil then
                    option:SetValue(option.Min)
                    count = count + 1
                end
            end)
        end
    end
    if not silent and Library.Notify then
        Library:Notify(string.format("Min preset applied (%d options)", count), 4)
    end
    return count
end

function Library:ApplyNamedPreset(name)
    local preset = Library.PresetConfigs and Library.PresetConfigs[name]
    if not preset then
        if name == "Max" or name == "max" then
            return Library:ApplyMaxPreset()
        elseif name == "Min" or name == "min" then
            return Library:ApplyMinPreset()
        end
        return false
    end
    for k, v in pairs(preset) do
        pcall(function()
            if k == "AccentColor" or k == "MainColor" or k == "BackgroundColor" or k == "OutlineColor" or k == "FontColor" then
                Library[k] = v
            elseif k == "GlassEnabled" or k == "GlassTransparency" then
                if k == "GlassTransparency" and preset.GlassEnabled ~= false then
                    Library:SetGlass(true, v)
                elseif k == "GlassEnabled" and v == false then
                    Library:SetGlass(false)
                end
            elseif k == "UseBlur" then
                Library.UseBlur = v
            elseif k == "BlurSize" then
                Library.BlurSize = v
            elseif k == "UseDarken" then
                Library.UseDarken = v
            elseif k == "DarkenAmount" then
                Library.DarkenAmount = v
            elseif k == "FontSize" and Library.SetFontSize then
                Library:SetFontSize(v)
            elseif Options[k] and Options[k].SetValue then
                Options[k]:SetValue(v)
            elseif Toggles[k] and Toggles[k].SetValue then
                Toggles[k]:SetValue(v)
            end
        end)
    end
    pcall(function()
        Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
        Library:UpdateColorsUsingRegistry()
        if Library.SyncStudTheme then Library:SyncStudTheme() end
    end)
    if Library.Notify then Library:Notify("Preset: " .. tostring(name), 3) end
    return true
end

Library.PresetConfigs = Library.PresetConfigs or {}
Library.PresetConfigs.Max = { _Mode = "Max", Description = "Every toggle on, every slider at Max" }
Library.PresetConfigs.Min = { _Mode = "Min", Description = "Every toggle off, every slider at Min" }

do
    local g = Vercel_getgenv()
    g.Vercel_Library = Library
    g.Vercel_Toggles = Toggles
    g.Vercel_Options = Options

    local foreign = type(g.Library) == "table" and g.Library.IsVercel ~= true
    if foreign then
        Library._IsolatedMode = true
        Library._ForeignLibrary = g.Library
    else
        Library._IsolatedMode = false
        Library._PrevLibrary = g.Library
        Library._PrevToggles = g.Toggles
        Library._PrevOptions = g.Options
        g.Library = Library
        g.Toggles = Toggles
        g.Options = Options
    end
    Library.Toggles = Toggles
    Library.Options = Options
end
return Library

]==========]

local Library = assert(loadstring(SOURCE, "=VercelUI"))()
local Toggles, Options = Library.Toggles, Library.Options
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local VirtualUser      = game:GetService("VirtualUser")
local HttpService      = game:GetService("HttpService")
local workspace        = game:GetService("Workspace")
local localplayer      = Players.LocalPlayer

getgenv().config = {
    nc = false, flyEnabled = false, flySpeed = 50, doubleJumpEnabled = false,
    fakePositionEnabled = false, desyncEnabled = false,
    evasionEnabled = false, evasionIntensity = 3.0,
    blinkEnabled = false, blinkRadius = 80, blinkRate = 60,
    ghostEnabled = false, ghostDistance = 150,
    glideEnabled = false, glideSpeed = 280, glideAccel = 18,
    VoidEnabled = false, voidX = 1e8, voidY = 1e8, voidZ = 1e8,
    voidSpamEnabled = false, voidSpamInterval = 0.016, voidSpamBurst = 5,
    voidSmooth = false, voidSmoothAlpha = 0.5, voidPattern = "random",
    voidAxisX = true, voidAxisY = true, voidAxisZ = true,
    voidXPos = 2500, voidXNeg = 2500, voidYPos = 1500, voidYNeg = 1500, voidZPos = 2500, voidZNeg = 2500,
    orbit = false, orbitSpeed = 90, orbitDistance = 8, orbitHeight = 0,
    wallbangEnabled = false, rapidFire = false, teleportEnemyEnabled = false,
    sling = false, daggerBypass = false, AntiEnemy = false,
    slingRage = false, antiProj = false, fastReload = false, antiClose = false,
    antiAimEnabled = false, pitchAngle = 0, yawAngle = 0, spinEnabled = false,
    underMapEnabled = false, underMapY = -500,
    riotAbuserEnabled = false, riotAbuserDistance = 300, riotAbuserX = 30,
    riotAbuserY = 8, riotAbuserZ = 30, riotAbuserSpin = 720,
    riotBypassEnabled = false, riotBypassDistance = 3, riotBypassHeight = 0, riotBypassUpdate = 0.02, riotBypassPosition = "Front",
    antiAfkEnabled = false, autocollectEnabled = false, autocollectRadius = 60,
    returnHomeEnabled = false, homeReturnDelay = 3.0,
    safeZoneEnabled = false, safeZoneY = -10,
    teleportLoopEnabled = false, teleportLoopDelay = 1.5,
}

local ROOT_FOLDER        = "vercelcc"
local PROFILES_FOLDER    = ROOT_FOLDER .. "/profiles"
local GLOBAL_CFG_FILE    = ROOT_FOLDER .. "/global_config.json"
local ACTIVE_PROFILE_FILE = ROOT_FOLDER .. "/active_profile.txt"

local function ensureFolders()
    local function mf(path) if not isfolder(path) then pcall(makefolder, path) end end
    mf(ROOT_FOLDER); mf(PROFILES_FOLDER)
end

local function safeWrite(path, content) return pcall(writefile, path, content) end
local function safeRead(path) local ok, d = pcall(readfile, path); return ok and d or nil end
local function safeDelete(path) pcall(delfile, path) end

local function jsonEncode(t)
    local ok, s = pcall(function() return HttpService:JSONEncode(t) end)
    return ok and s or nil
end
local function jsonDecode(s)
    local ok, t = pcall(function() return HttpService:JSONDecode(s) end)
    return ok and t or nil
end

local function getActiveProfileName() return safeRead(ACTIVE_PROFILE_FILE) end
local function setActiveProfileName(name)
    if name then safeWrite(ACTIVE_PROFILE_FILE, name) else safeDelete(ACTIVE_PROFILE_FILE) end
end

local function profilePath(name)
    local safe = name:gsub("[^%w%-%_ ]", ""):sub(1, 48)
    return PROFILES_FOLDER .. "/" .. safe .. ".json"
end

local function listProfiles()
    local names = {}
    local ok, files = pcall(listfiles, PROFILES_FOLDER)
    if not ok or not files then return names end
    for _, path in ipairs(files) do
        local name = path:match("([^/\\]+)%.json$")
        if name then table.insert(names, name) end
    end
    table.sort(names); return names
end

local function saveProfile(name)
    name = name:match("^%s*(.-)%s*$")
    if name == "" then return false, "Enter a profile name" end
    local t = {}
    for k, v in pairs(getgenv().config) do t[k] = v end
    local s = jsonEncode(t)
    if not s then return false, "JSON encode failed" end
    local ok, err = safeWrite(profilePath(name), s)
    if not ok then return false, tostring(err) end
    setActiveProfileName(name)
    return true, "Saved profile: " .. name
end

local function loadProfile(name)
    local raw = safeRead(profilePath(name))
    if not raw then return false, "Profile not found" end
    local data = jsonDecode(raw)
    if not data then return false, "Corrupted profile" end
    for k, v in pairs(data) do
        if getgenv().config[k] ~= nil then
            if type(getgenv().config[k]) == type(v) then getgenv().config[k] = v end
        end
    end
    setActiveProfileName(name)
    return true, "Loaded: " .. name
end

local function deleteProfile(name)
    safeDelete(profilePath(name))
    if getActiveProfileName() == name then setActiveProfileName(nil) end
    return true, "Deleted: " .. name
end

local function saveGlobalConfig()
    local t = {}
    for k, v in pairs(getgenv().config) do t[k] = v end
    local s = jsonEncode(t)
    if s then safeWrite(GLOBAL_CFG_FILE, s) end
end

local function loadGlobalConfig()
    local raw = safeRead(GLOBAL_CFG_FILE)
    if not raw then return end
    local data = jsonDecode(raw)
    if not data then return end
    for k, v in pairs(data) do
        if getgenv().config[k] ~= nil and type(getgenv().config[k]) == type(v) then
            getgenv().config[k] = v
        end
    end
end

pcall(ensureFolders)
pcall(loadGlobalConfig)

warn("[vercel.cc] library loaded")
local Window = Library:CreateWindow({
    Title = "vercel.cc  |  Free Version",
    Center = true,
    AutoShow = true,
    TabPadding = 6,
    MenuFadeTime = 0.12,
})
Library.ToggleKeybind = { Type = "KeyPicker", Value = "Insert" }

local function Notify(title, desc)
    pcall(function() Library:Notify(title .. ": " .. tostring(desc), 3) end)
end

getgenv().AllConnections   = {}
getgenv().loopWaypoints    = {}
getgenv().loopIndex        = 1
getgenv().homePosition     = nil
getgenv().safeZoneSavedPos = nil

local config = getgenv().config

local function getHrp()
    return localplayer.Character and localplayer.Character:FindFirstChild("HumanoidRootPart")
end

local function getClosest()
    local closest, minD = nil, math.huge
    local hrp = getHrp()
    if not hrp then return nil end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= localplayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if localplayer.Team == nil or p.Team == nil or localplayer.Team ~= p.Team then
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

local function safeTeleport(pos)
    local hrp = getHrp()
    if not hrp then return end
    local x, y, z = pos.X, pos.Y, pos.Z
    y = math.clamp(y, 2, hrp.Position.Y + 800)
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = { localplayer.Character }
    local hit = workspace:Raycast(Vector3.new(x, y + 60, z), Vector3.new(0, -220, 0), p)
    if hit then y = math.max(hit.Position.Y + 3, 2) end
    hrp.CFrame = CFrame.new(x, y, z)
end

pcall(function()
local oldFireServer
oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, newcclosure(function(self, ...)
    if not checkcaller() and config.daggerBypass then
        local parts = {} for i, v in ipairs({ ... }) do parts[i] = tostring(v) end
        local n, a = self.Name:lower(), table.concat(parts, " "):lower()
        if (n:find("dagger") or n:find("knife") or n:find("throw") or n:find("blade"))
        and not (a:find(localplayer.Name:lower()) or a:find("owner")) then return end
    end
    return oldFireServer(self, ...)
end))

end)
UserInputService.JumpRequest:Connect(function()
    if config.doubleJumpEnabled then
        local hum = localplayer.Character and localplayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum:GetState() ~= Enum.HumanoidStateType.Dead then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

local voidConn1, voidConn2, voidConn3, voidToggle = nil, nil, nil, false
getgenv().startVoid = function()
    if voidConn1 then voidConn1:Disconnect() end
    if voidConn2 then voidConn2:Disconnect() end
    if voidConn3 then voidConn3:Disconnect() end
    voidConn1 = RunService.Heartbeat:Connect(function()
        if not config.VoidEnabled or not getHrp() then return end
        voidToggle = not voidToggle
        local hrp = getHrp()
        local vx, vy, vz = config.voidX, config.voidY, config.voidZ
        if voidToggle then hrp.CFrame = CFrame.new(math.random(-vx, vx), vy, math.random(-vz, vz))
        else hrp.CFrame = CFrame.new(math.random(vx, vx * 2), -vy, math.random(vz, vz * 2)) end
        hrp.AssemblyLinearVelocity = Vector3.new(math.random(-1e5, 1e5), math.random(-1e5, 1e5), math.random(-1e5, 1e5))
        hrp.AssemblyAngularVelocity = Vector3.new(math.random(-1e5, 1e5), math.random(-1e5, 1e5), math.random(-1e5, 1e5))
    end)
    voidConn2 = RunService.RenderStepped:Connect(function()
        if not config.VoidEnabled or not getHrp() then return end
        getHrp().CFrame = getHrp().CFrame * CFrame.new(math.random(-50, 50), math.random(-50, 50), math.random(-50, 50))
    end)
    voidConn3 = RunService.Stepped:Connect(function()
        if not config.VoidEnabled or not getHrp() then return end
        if getHrp().Position.Magnitude > 1e7 then getHrp().CFrame = CFrame.new(0, config.voidY, 0) end
    end)
end
getgenv().stopVoid = function()
    if voidConn1 then voidConn1:Disconnect() voidConn1 = nil end
    if voidConn2 then voidConn2:Disconnect() voidConn2 = nil end
    if voidConn3 then voidConn3:Disconnect() voidConn3 = nil end
end
local voidSpamConn, voidSpamCharConn = nil, nil
local voidSpiralAngle = 0
local voidWaveTime    = 0
local voidBounceDir   = { X = 1, Y = 1, Z = 1 }
local voidChaosSeeds  = { math.random(), math.random(), math.random() }
local voidHelixT      = 0
local voidStrobePhase = false

local function getVoidSpamDelta(dt)
    local xp, xn = config.voidXPos, config.voidXNeg
    local yp, yn = config.voidYPos, config.voidYNeg
    local zp, zn = config.voidZPos, config.voidZNeg
    local ax, ay, az = config.voidAxisX, config.voidAxisY, config.voidAxisZ
    local p = config.voidPattern
    if p == "spiral" then
        voidSpiralAngle = voidSpiralAngle + 0.35
        return Vector3.new(ax and math.cos(voidSpiralAngle) * (xp + xn) / 2 or 0, ay and math.sin(voidSpiralAngle * 0.6) * (yp + yn) / 2 or 0, az and math.sin(voidSpiralAngle) * (zp + zn) / 2 or 0)
    elseif p == "wave" then
        voidWaveTime = voidWaveTime + dt * 8
        return Vector3.new(ax and math.sin(voidWaveTime) * (xp + xn) / 2 or 0, ay and math.sin(voidWaveTime * 1.7) * (yp + yn) / 2 or 0, az and math.cos(voidWaveTime * 0.9) * (zp + zn) / 2 or 0)
    elseif p == "bounce" then
        local step = Vector3.new(ax and voidBounceDir.X * (xp + xn) / 3 or 0, ay and voidBounceDir.Y * (yp + yn) / 3 or 0, az and voidBounceDir.Z * (zp + zn) / 3 or 0)
        if math.random() < 0.25 then voidBounceDir.X = -voidBounceDir.X end
        if math.random() < 0.25 then voidBounceDir.Y = -voidBounceDir.Y end
        if math.random() < 0.25 then voidBounceDir.Z = -voidBounceDir.Z end
        return step
    elseif p == "chaos" then
        voidChaosSeeds[1] = (voidChaosSeeds[1] * 1664525 + 1013904223) % 1
        voidChaosSeeds[2] = (voidChaosSeeds[2] * 22695477 + 1) % 1
        voidChaosSeeds[3] = (voidChaosSeeds[3] * 214013 + 2531011) % 1
        return Vector3.new(ax and (voidChaosSeeds[1] * (xp + xn) - xn) or 0, ay and (voidChaosSeeds[2] * (yp + yn) - yn) or 0, az and (voidChaosSeeds[3] * (zp + zn) - zn) or 0)
    elseif p == "cross" then
        local tog = (math.floor(tick() * 10)) % 2 == 0
        return Vector3.new(ax and (tog and (math.random() * (xp + xn) - xn) or 0) or 0, ay and (not tog and (math.random() * (yp + yn) - yn) or 0) or 0, az and (tog and (math.random() * (zp + zn) - zn) or 0) or 0)
    elseif p == "helix" then
        voidHelixT = voidHelixT + dt * 6
        return Vector3.new(ax and math.cos(voidHelixT * 2) * (xp + xn) / 2 or 0, ay and math.sin(voidHelixT) * (yp + yn) / 8 or 0, az and math.sin(voidHelixT * 2) * (zp + zn) / 2 or 0)
    elseif p == "strobe" then
        voidStrobePhase = not voidStrobePhase
        local s = voidStrobePhase and 1 or -1
        return Vector3.new(ax and s * xp or 0, ay and s * yp or 0, az and s * zp or 0)
    else
        return Vector3.new(ax and (math.random() * (xp + xn) - xn) or 0, ay and (math.random() * (yp + yn) - yn) or 0, az and (math.random() * (zp + zn) - zn) or 0)
    end
end

getgenv().startVoidSpam = function()
    if voidSpamConn then return end
    voidSpiralAngle = 0; voidWaveTime = 0; voidHelixT = 0; voidStrobePhase = false
    voidBounceDir = { X = 1, Y = 1, Z = 1 }; voidChaosSeeds = { math.random(), math.random(), math.random() }
    local root, humanoid
    local function refreshChar()
        local ch = localplayer.Character
        if not ch then root = nil; humanoid = nil; return end
        root = ch:FindFirstChild("HumanoidRootPart"); humanoid = ch:FindFirstChildOfClass("Humanoid")
    end
    refreshChar()
    voidSpamCharConn = localplayer.CharacterAdded:Connect(function(ch)
        root = ch:WaitForChild("HumanoidRootPart"); humanoid = ch:WaitForChild("Humanoid")
        task.wait(0.2)
        if config.voidSpamEnabled and humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Physics) end
    end)
    local acc, dtBuf = 0, 0
    voidSpamConn = RunService.Heartbeat:Connect(function(dt)
        if not config.voidSpamEnabled then getgenv().stopVoidSpam(); return end
        if not root or not root.Parent then refreshChar(); return end
        if humanoid and humanoid.Health <= 0 then return end
        dtBuf = dtBuf + dt; acc = acc + dt
        local interval = math.max(config.voidSpamInterval, 0.005)
        if acc < interval then return end
        acc = acc % interval
        local burst = math.clamp(config.voidSpamBurst, 1, 20)
        for _ = 1, burst do
            if not root or not root.Parent then break end
            local pos = root.Position; local look = root.CFrame.LookVector
            local delta = getVoidSpamDelta(dtBuf / burst)
            local newPos
            if config.voidSmooth then
                newPos = pos:Lerp(pos + delta, math.clamp(config.voidSmoothAlpha, 0.01, 1))
            else newPos = pos + delta end
            root.CFrame = CFrame.new(newPos, newPos + look)
        end
        dtBuf = 0
    end)
end
getgenv().stopVoidSpam = function()
    if voidSpamConn then voidSpamConn:Disconnect() voidSpamConn = nil end
    if voidSpamCharConn then voidSpamCharConn:Disconnect() voidSpamCharConn = nil end
    config.voidSpamEnabled = false
end

local orbConn, orbAngle = nil, 0
getgenv().startOrbit = function()
    if orbConn then orbConn:Disconnect() end
    local hum = localplayer.Character and localplayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Physics) end
    orbAngle = 0
    orbConn = RunService.Heartbeat:Connect(function(dt)
        if not config.orbit then return end
        local myHrp = getHrp()
        if not myHrp then return end
        local cl = getClosest()
        if cl and cl.Character then
            local hrp = cl.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local speedMod = (config.orbitSpeed or 90) / 500
                orbAngle = orbAngle + speedMod
                local radius = config.orbitDistance or 8
                local height = config.orbitHeight or 0
                local offset = Vector3.new(math.cos(orbAngle) * radius, height, math.sin(orbAngle) * radius)
                myHrp.CFrame = CFrame.new(hrp.Position + offset, hrp.Position)
                pcall(function()
                    myHrp.AssemblyLinearVelocity = Vector3.zero
                    myHrp.AssemblyAngularVelocity = Vector3.zero
                end)
            end
        end
    end)
end
getgenv().stopOrbit = function()
    if orbConn then orbConn:Disconnect() orbConn = nil end
    config.orbit = false
end
local tpConn
getgenv().startTp = function()
    if tpConn then tpConn:Disconnect() end
    tpConn = RunService.Heartbeat:Connect(function()
        if config.teleportEnemyEnabled then
            local t = getClosest()
            if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") and getHrp() then
                getHrp().CFrame = CFrame.new(t.Character.HumanoidRootPart.Position + Vector3.new(0, 3.5, 0))
            end
        end
    end)
end
getgenv().stopTp = function() if tpConn then tpConn:Disconnect() tpConn = nil end end

local fakePosConnection, renderPosConnection, realCF = nil, nil, nil
getgenv().startFakePosition = function()
    if fakePosConnection then fakePosConnection:Disconnect() end
    if renderPosConnection then renderPosConnection:Disconnect() end
    fakePosConnection = RunService.Heartbeat:Connect(function()
        local tHrp = getHrp()
        if config.fakePositionEnabled and tHrp then
            realCF = tHrp.CFrame
            tHrp.CFrame = realCF + Vector3.new(math.random(-150, 150), math.random(10, 100), math.random(-150, 150))
        end
    end)
    renderPosConnection = RunService.RenderStepped:Connect(function()
        local tHrp = getHrp()
        if config.fakePositionEnabled and tHrp and realCF then tHrp.CFrame = realCF end
    end)
end
getgenv().stopFakePosition = function()
    if fakePosConnection then fakePosConnection:Disconnect() fakePosConnection = nil end
    if renderPosConnection then renderPosConnection:Disconnect() renderPosConnection = nil end
end

local desyncHeartbeat, desyncRender, realVel = nil, nil, nil
getgenv().startDesync = function()
    if desyncHeartbeat then desyncHeartbeat:Disconnect() end
    if desyncRender then desyncRender:Disconnect() end
    desyncHeartbeat = RunService.Heartbeat:Connect(function()
        local tHrp = getHrp()
        if config.desyncEnabled and tHrp then
            realVel = tHrp.AssemblyLinearVelocity
            tHrp.AssemblyLinearVelocity = Vector3.new(math.random(-5000, 5000), math.random(-5000, 5000), math.random(-5000, 5000))
        end
    end)
    desyncRender = RunService.RenderStepped:Connect(function()
        local tHrp = getHrp()
        if config.desyncEnabled and tHrp and realVel then tHrp.AssemblyLinearVelocity = realVel end
    end)
end
getgenv().stopDesync = function()
    if desyncHeartbeat then desyncHeartbeat:Disconnect() desyncHeartbeat = nil end
    if desyncRender then desyncRender:Disconnect() desyncRender = nil end
end

local evasionConn, blinkConn, ghostConn = nil, nil, nil
getgenv().startEvasion = function()
    if evasionConn then evasionConn:Disconnect() end
    local t0, s1, s2, s3 = tick(), math.random(1e3, 9e3), math.random(1e3, 9e3), math.random(1e3, 9e3)
    evasionConn = RunService.Heartbeat:Connect(function()
        if not config.evasionEnabled or not getHrp() then return end
        local t, i = tick() - t0, config.evasionIntensity
        local r1, r2, r3 = 500 * 0.18 * i, 500 * 0.35 * i, 500 * 0.55 * i
        local oX = math.cos(t * 18.7) * r1 + math.cos(t * 7.3 + s1) * r2 + math.cos(t * 2.1 + s2) * r3
        local oZ = math.sin(t * 18.7) * r1 + math.sin(t * 7.3 + s1) * r2 + math.sin(t * 2.1 + s2) * r3
        local oY = math.sin(t * 11.3 + s3) * 500 * 0.12 * i + math.sin(t * 5.7) * 500 * 0.08 * i
        local jX = math.noise(t * 8, s1, 0) * 40 * i
        local jY = math.noise(0, t * 8, s2) * 20 * i
        local jZ = math.noise(0, 0, t * 8 + s3) * 40 * i
        safeTeleport(getHrp().Position + Vector3.new(oX + jX, oY + jY, oZ + jZ))
    end)
end
getgenv().stopEvasion = function() if evasionConn then evasionConn:Disconnect() evasionConn = nil end end

local blinkAnchor = nil
getgenv().startBlink = function()
    if blinkConn then blinkConn:Disconnect() end
    if getHrp() then blinkAnchor = getHrp().Position end
    local lastSnap, anchorT, seed = 0, 0, math.random(1e3, 9e3)
    blinkConn = RunService.Heartbeat:Connect(function(dt)
        if not config.blinkEnabled or not getHrp() then return end
        anchorT = anchorT + dt
        blinkAnchor = (blinkAnchor or getHrp().Position) + Vector3.new(math.sin(anchorT * 1.3 + seed) * 12, math.sin(anchorT * 2.1) * 3, math.cos(anchorT * 1.7 + seed) * 12) * dt
        local now = tick()
        if (now - lastSnap) >= (1 / config.blinkRate) then
            lastSnap = now
            local a, d = math.random() * math.pi * 2, math.random() * config.blinkRadius
            safeTeleport(Vector3.new(blinkAnchor.X + math.cos(a) * d, blinkAnchor.Y + (math.random() - 0.5) * config.blinkRadius * 0.3, blinkAnchor.Z + math.sin(a) * d))
        end
    end)
end
getgenv().stopBlink = function() if blinkConn then blinkConn:Disconnect() blinkConn = nil end end

getgenv().startGhost = function()
    if ghostConn then ghostConn:Disconnect() end
    local flip, t0, seed = false, tick(), math.random(1e3, 9e3)
    ghostConn = RunService.Heartbeat:Connect(function()
        if not config.ghostEnabled or not getHrp() then return end
        flip = not flip
        if flip then
            local a = (tick() - t0) * 4.3 + seed
            safeTeleport(Vector3.new(getHrp().Position.X + math.cos(a) * config.ghostDistance, getHrp().Position.Y, getHrp().Position.Z + math.sin(a) * config.ghostDistance))
        end
    end)
end
getgenv().stopGhost = function() if ghostConn then ghostConn:Disconnect() ghostConn = nil end end

local glideConn = nil
getgenv().startGlide = function()
    if glideConn then glideConn:Disconnect() end
    local hum = localplayer.Character and localplayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Physics) end
    local vel = Vector3.zero
    glideConn = RunService.Heartbeat:Connect(function(dt)
        if not config.glideEnabled then getgenv().stopGlide(); return end
        local hrp = getHrp(); if not hrp then return end
        local cam = workspace.CurrentCamera
        local cf  = cam and cam.CFrame or hrp.CFrame
        local f   = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z).Unit
        local r   = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z).Unit
        local humC = localplayer.Character and localplayer.Character:FindFirstChildOfClass("Humanoid")
        local md   = humC and humC.MoveDirection or Vector3.zero
        local wish = Vector3.zero
        if md.Magnitude > 0.001 then
            wish = f * md:Dot(f) + r * md:Dot(r)
            if wish.Magnitude > 0.001 then wish = wish.Unit end
        end
        local accel = math.clamp(config.glideAccel, 1, 100)
        vel = vel:Lerp(wish * config.glideSpeed, 1 - math.exp(-accel * dt))
        hrp.AssemblyLinearVelocity = Vector3.new(vel.X, hrp.AssemblyLinearVelocity.Y, vel.Z)
    end)
end
getgenv().stopGlide = function()
    if glideConn then glideConn:Disconnect() glideConn = nil end
    config.glideEnabled = false
end
local riotAbuserConn = nil
getgenv().startRiotAbuser = function()
    if riotAbuserConn then riotAbuserConn:Disconnect() end
    local t0, seed = tick(), math.random(1e3, 9e3)
    local hrp = getHrp()
    if hrp then getgenv().riotAbuserOriginal = hrp.CFrame end
    riotAbuserConn = RunService.Heartbeat:Connect(function(dt)
        if not config.riotAbuserEnabled or not getHrp() then return end
        local t = tick() - t0
        local hrp2 = getHrp()
        local yaw   = math.rad(config.riotAbuserSpin * dt)
        local pitch = math.rad(config.riotAbuserSpin * 0.37 * dt * math.sin(t * 3.1))
        local roll  = math.rad(config.riotAbuserSpin * 0.19 * dt * math.cos(t * 5.7 + seed))
        local spinCF = hrp2.CFrame * CFrame.Angles(pitch, yaw, roll)
        local spread = config.riotAbuserDistance / 300
        local jX = (math.random() - 0.5) * config.riotAbuserX * spread * 2 + math.noise(t * 9, seed, 0) * config.riotAbuserX * spread
        local jY = (math.random() - 0.5) * config.riotAbuserY * spread + math.noise(0, t * 9, seed) * config.riotAbuserY * spread * 0.3
        local jZ = (math.random() - 0.5) * config.riotAbuserZ * spread * 2 + math.noise(0, 0, t * 9 + seed) * config.riotAbuserZ * spread
        local newY = math.max(spinCF.Position.Y + jY, 2)
        hrp2.CFrame = spinCF + Vector3.new(jX, newY - spinCF.Position.Y, jZ)
    end)
end
getgenv().stopRiotAbuser = function()
    if riotAbuserConn then riotAbuserConn:Disconnect() riotAbuserConn = nil end
    if getHrp() and getgenv().riotAbuserOriginal then getHrp().CFrame = getgenv().riotAbuserOriginal end
end

local riotBypassConn, riotBypassTarget = nil, nil
local riotBypassLastSnap = 0
getgenv().startRiotBypass = function()
    if riotBypassConn then riotBypassConn:Disconnect() end
    riotBypassConn = RunService.Heartbeat:Connect(function()
        if not config.riotBypassEnabled or not getHrp() then return end
        if not riotBypassTarget or not riotBypassTarget.Character or not riotBypassTarget.Character:FindFirstChild("Humanoid") or riotBypassTarget.Character.Humanoid.Health <= 0 then
            riotBypassTarget = getClosest()
            return
        end
        local tr = riotBypassTarget.Character:FindFirstChild("HumanoidRootPart")
        if not tr then return end
        local now = tick()
        if (now - riotBypassLastSnap) < config.riotBypassUpdate then return end
        riotBypassLastSnap = now
        local hrp = getHrp()
        if not hrp then return end
        
        local targetPos = tr.Position
        local targetLook = tr.CFrame.LookVector
        local distance = config.riotBypassDistance or 3
        local heightOffset = config.riotBypassHeight or 0
        local calculatedCFrame = hrp.CFrame
        local mode = config.riotBypassPosition or "Front"
        
        if mode == "Front" then
            calculatedCFrame = CFrame.lookAt(targetPos + (targetLook * distance) + Vector3.new(0, heightOffset, 0), targetPos + Vector3.new(0, heightOffset, 0))
        elseif mode == "Back" then
            calculatedCFrame = CFrame.lookAt(targetPos - (targetLook * distance) + Vector3.new(0, heightOffset, 0), targetPos + Vector3.new(0, heightOffset, 0))
        elseif mode == "Above" then
            calculatedCFrame = CFrame.lookAt(targetPos + Vector3.new(0, distance + heightOffset, 0), targetPos + Vector3.new(0, heightOffset, 0))
        elseif mode == "Below" then
            calculatedCFrame = CFrame.lookAt(targetPos + Vector3.new(0, -distance + heightOffset, 0), targetPos + Vector3.new(0, heightOffset, 0))
        end
        
        hrp.CFrame = calculatedCFrame
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)
end
getgenv().stopRiotBypass = function()
    if riotBypassConn then riotBypassConn:Disconnect() riotBypassConn = nil end
    riotBypassTarget = nil
    riotBypassLastSnap = 0
end

local slingRageConn, slingProjA, slingProjB
local slingTarget = CFrame.new(9000, 9000, 9000)
local slingProjs  = {}
getgenv().startSlingRage = function()
    if slingRageConn then slingRageConn:Disconnect() end
    slingProjA = workspace.ChildAdded:Connect(function(o)
        if not o:IsA("BasePart") then return end
        if o.Name == "CoreProjectile" then slingProjs[o] = true
        elseif o.Name == "Part" then task.defer(function()
            if o and o.Parent and o.AssemblyLinearVelocity.Magnitude > 50 then slingProjs[o] = true end
        end) end
    end)
    slingProjB = workspace.ChildRemoved:Connect(function(o) slingProjs[o] = nil end)
    slingRageConn = RunService.Heartbeat:Connect(function()
        if not config.slingRage then return end
        pcall(function()
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= localplayer and p.Character then
                    local h = p.Character:FindFirstChild("HumanoidRootPart")
                    if h then h.CFrame = slingTarget; h.AssemblyLinearVelocity = Vector3.zero; h.AssemblyAngularVelocity = Vector3.zero end
                end
            end
            for _, o in pairs(workspace:GetChildren()) do
                if o.Name == "CoreProjectile" and o:IsA("BasePart") then
                    o.CFrame = slingTarget; o.AssemblyLinearVelocity = Vector3.zero
                end
            end
            for p in pairs(slingProjs) do
                if p and p.Parent then p.CFrame = slingTarget; p.AssemblyLinearVelocity = Vector3.zero
                else slingProjs[p] = nil end
            end
        end)
    end)
end
getgenv().stopSlingRage = function()
    if slingRageConn then slingRageConn:Disconnect() slingRageConn = nil end
    if slingProjA then slingProjA:Disconnect() slingProjA = nil end
    if slingProjB then slingProjB:Disconnect() slingProjB = nil end
    slingProjs = {}
end

local apConn, apProjA, apProjB
local apTarget = CFrame.new(999999, 999999, 999999)
local apProjs  = {}
getgenv().startAntiProj = function()
    if apConn then apConn:Disconnect() end
    apProjA = workspace.ChildAdded:Connect(function(o)
        if not o:IsA("BasePart") then return end
        if o.Name == "CoreProjectile" then apProjs[o] = true
        elseif o.Name == "Part" then task.defer(function()
            if o and o.Parent and o.AssemblyLinearVelocity.Magnitude > 50 then apProjs[o] = true end
        end) end
    end)
    apProjB = workspace.ChildRemoved:Connect(function(o) apProjs[o] = nil end)
    apConn = RunService.Heartbeat:Connect(function()
        if not config.antiProj then return end
        pcall(function()
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= localplayer and p.Character then
                    local h = p.Character:FindFirstChild("HumanoidRootPart")
                    if h then h.CFrame = apTarget; h.AssemblyLinearVelocity = Vector3.zero; h.AssemblyAngularVelocity = Vector3.zero end
                end
            end
            for _, o in pairs(workspace:GetChildren()) do
                if o.Name == "CoreProjectile" and o:IsA("BasePart") then
                    o.CFrame = apTarget; o.AssemblyLinearVelocity = Vector3.zero
                end
            end
            for p in pairs(apProjs) do
                if p and p.Parent then p.CFrame = apTarget; p.AssemblyLinearVelocity = Vector3.zero
                else apProjs[p] = nil end
            end
        end)
    end)
end
getgenv().stopAntiProj = function()
    if apConn then apConn:Disconnect() apConn = nil end
    if apProjA then apProjA:Disconnect() apProjA = nil end
    if apProjB then apProjB:Disconnect() apProjB = nil end
    apProjs = {}
end

local antiCloseConn = nil
getgenv().startAntiClose = function()
    if antiCloseConn then antiCloseConn:Disconnect() end
    antiCloseConn = RunService.Heartbeat:Connect(function()
        if not config.antiClose then return end
        local hrp = getHrp(); if not hrp then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= localplayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                if (hrp.Position - plr.Character.HumanoidRootPart.Position).Magnitude < 20 then
                    hrp.CFrame = hrp.CFrame + hrp.CFrame.LookVector * 60 + Vector3.new(0, 30, 0)
                    break
                end
            end
        end
    end)
end
getgenv().stopAntiClose = function() if antiCloseConn then antiCloseConn:Disconnect() antiCloseConn = nil end end

getgenv().startFastReload = function()
    local ok, ItemLibrary = pcall(function() return require(game:GetService("ReplicatedStorage").Modules.ItemLibrary) end)
    if not ok or not ItemLibrary then return end
    local Items = rawget(ItemLibrary, "Items"); if not Items then return end
    task.spawn(function()
        while config.fastReload do
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
    end)
end
getgenv().stopFastReload = function() config.fastReload = false end
local lastShootTime = 0
local function handleWallbang()
    if not config.wallbangEnabled then return end
    local cl = getClosest(); local hrp = getHrp(); local char = localplayer.Character
    if cl and cl.Character and cl.Character:FindFirstChild("Head") and hrp and char then
        local hd  = cl.Character.Head
        local cam = workspace.CurrentCamera
        cam.CFrame = CFrame.lookAt(cam.CFrame.Position, hd.Position)
        local t = char:FindFirstChildOfClass("Tool")
        if t then t:Activate() end
        if tick() - lastShootTime > 0.05 then
            lastShootTime = tick()
            pcall(function()
                if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
                    local center = cam.ViewportSize / 2
                    if firetouchtap then firetouchtap(center) elseif touchtap then touchtap(center) end
                else
                    if mouse1click then mouse1click() else VirtualUser:ClickButton1(Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)) end
                end
            end)
        end
    end
end
getgenv().startWallbang = function() RunService:BindToRenderStep("WbAimFix", Enum.RenderPriority.Camera.Value + 1, handleWallbang) end
getgenv().stopWallbang  = function() RunService:UnbindFromRenderStep("WbAimFix") end

local rapidFireConn = nil
getgenv().startRapidFire = function()
    if rapidFireConn then rapidFireConn:Disconnect() end
    rapidFireConn = RunService.Heartbeat:Connect(function()
        if config.rapidFire then
            local t = localplayer.Character and localplayer.Character:FindFirstChildOfClass("Tool")
            if t then t:Activate() end
        end
    end)
end
getgenv().stopRapidFire = function() if rapidFireConn then rapidFireConn:Disconnect() rapidFireConn = nil end end

local autocollectConn, homeConn, loopConn, safeZoneConn = nil, nil, nil, nil
getgenv().startAutocollect = function()
    if autocollectConn then autocollectConn:Disconnect() end
    autocollectConn = RunService.Heartbeat:Connect(function()
        if not config.autocollectEnabled or not getHrp() then return end
        local best, minD = nil, math.huge
        for _, o in ipairs(workspace:GetDescendants()) do
            local n = o.Name:lower()
            if n:find("heal") or n:find("health") or n:find("medkit") or n:find("bandage") then
                local p = o:IsA("Model") and (o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart")) or (o:IsA("BasePart") and o or nil)
                if p then
                    local d = (p.Position - getHrp().Position).Magnitude
                    if d < minD and d <= config.autocollectRadius then minD = d; best = p.Position end
                end
            end
        end
        if best then safeTeleport(best) end
    end)
end
getgenv().stopAutocollect = function() if autocollectConn then autocollectConn:Disconnect() autocollectConn = nil end end

getgenv().startReturnHome = function()
    if homeConn then homeConn:Disconnect() end
    if not getgenv().homePosition and getHrp() then getgenv().homePosition = getHrp().Position end
    local lastRet = 0
    homeConn = RunService.Heartbeat:Connect(function()
        if not config.returnHomeEnabled or not getHrp() or not getgenv().homePosition then return end
        if (getHrp().Position - getgenv().homePosition).Magnitude > 50 and (tick() - lastRet) >= config.homeReturnDelay then
            lastRet = tick(); safeTeleport(getgenv().homePosition)
        end
    end)
end
getgenv().stopReturnHome = function() if homeConn then homeConn:Disconnect() homeConn = nil end end

getgenv().startSafeZone = function()
    if safeZoneConn then safeZoneConn:Disconnect() end
    safeZoneConn = RunService.Heartbeat:Connect(function()
        if not getHrp() then return end
        if getHrp().Position.Y > config.safeZoneY then getgenv().safeZoneSavedPos = getHrp().Position
        elseif config.safeZoneEnabled and getgenv().safeZoneSavedPos then getHrp().CFrame = CFrame.new(getgenv().safeZoneSavedPos) end
    end)
end
getgenv().stopSafeZone = function() if safeZoneConn then safeZoneConn:Disconnect() safeZoneConn = nil end end

getgenv().startTeleportLoop = function()
    if loopConn then pcall(task.cancel, loopConn) end
    config.teleportLoopEnabled = true
    loopConn = task.spawn(function()
        while config.teleportLoopEnabled do
            if #getgenv().loopWaypoints > 0 and getHrp() then
                local t = getgenv().loopWaypoints[getgenv().loopIndex]
                if t then safeTeleport(t) end
                getgenv().loopIndex = (getgenv().loopIndex % #getgenv().loopWaypoints) + 1
            end
            task.wait(config.teleportLoopDelay)
        end
    end)
end
getgenv().stopTeleportLoop = function()
    config.teleportLoopEnabled = false
    if loopConn then pcall(task.cancel, loopConn) loopConn = nil end
end

local antiAfkConn = nil
getgenv().startAntiAfk = function()
    if antiAfkConn then antiAfkConn:Disconnect() end
    antiAfkConn = localplayer.Idled:Connect(function()
        if config.antiAfkEnabled then
            VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end
    end)
end
getgenv().stopAntiAfk = function() if antiAfkConn then antiAfkConn:Disconnect() antiAfkConn = nil end end

local flyConn = nil
getgenv().startFly = function()
    if flyConn then flyConn:Disconnect() end
    flyConn = RunService.Heartbeat:Connect(function(dt)
        local tHrp = getHrp()
        if not tHrp or not config.flyEnabled then return end
        local h = localplayer.Character and localplayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Physics) end
        local c  = workspace.CurrentCamera
        local md = Vector3.zero
        if h and h.MoveDirection.Magnitude > 0 then
            local fl = Vector3.new(c.CFrame.LookVector.X, 0, c.CFrame.LookVector.Z)
            md = fl.Magnitude > 0.001
                and Vector3.new(h.MoveDirection.X, c.CFrame.LookVector.Y * h.MoveDirection:Dot(fl.Unit), h.MoveDirection.Z)
                or  Vector3.new(h.MoveDirection.X, c.CFrame.LookVector.Y, h.MoveDirection.Z)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then md = md + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then md = md - Vector3.new(0, 1, 0) end
        tHrp.AssemblyLinearVelocity = Vector3.zero; tHrp.AssemblyAngularVelocity = Vector3.zero
        if md.Magnitude > 0 then tHrp.CFrame = tHrp.CFrame + (md.Unit * (config.flySpeed * dt)) end
    end)
end
getgenv().stopFly = function()
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if getHrp() then getHrp().AssemblyLinearVelocity = Vector3.zero; getHrp().AssemblyAngularVelocity = Vector3.zero end
    local h = localplayer.Character and localplayer.Character:FindFirstChildOfClass("Humanoid")
    if h then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
end

local underMapConn = nil
getgenv().startUnderMap = function()
    if underMapConn then underMapConn:Disconnect() end
    underMapConn = RunService.Heartbeat:Connect(function()
        if not config.underMapEnabled or not getHrp() then return end
        local hrp = getHrp()
        if localplayer.Character then
            for _, p in ipairs(localplayer.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
        hrp.CFrame = CFrame.new(hrp.Position.X, config.underMapY, hrp.Position.Z)
    end)
end
getgenv().stopUnderMap = function() if underMapConn then underMapConn:Disconnect() underMapConn = nil end end

table.insert(getgenv().AllConnections, RunService.Stepped:Connect(function()
    if config.nc and localplayer.Character then
        for _, p in ipairs(localplayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end))

table.insert(getgenv().AllConnections, RunService.Heartbeat:Connect(function()
    if config.antiAimEnabled and getHrp() then
        getHrp().CFrame = getHrp().CFrame * CFrame.Angles(math.rad(config.pitchAngle), math.rad(config.yawAngle), 0)
    end
    if config.spinEnabled and getHrp() then
        getHrp().CFrame = getHrp().CFrame * CFrame.Angles(0, math.rad(math.random(-180, 180)), 0)
        getHrp().AssemblyLinearVelocity = Vector3.new(math.random(-200, 200), 250, math.random(-200, 200)) * 45
    end
end))

local function Tgl(box, id, txt, desc, cb)
    box:AddToggle(id, { Text = txt, Default = false, Callback = function(v) if v then Notify(txt, desc) end cb(v) end })
end
local function Sld(box, id, txt, def, min, max, rnd, cb)
    box:AddSlider(id, { Text = txt, Default = def, Min = min, Max = max, Rounding = rnd or 0, Callback = cb })
end

warn("[vercel.cc] window created")

-- background character image (peeks out from behind the menu)
local BG_B64 = "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"
task.spawn(function()
    pcall(function()
        if not (writefile and getcustomasset) then return end
        local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local lut = {}
        for i = 1, #alphabet do lut[alphabet:byte(i)] = i - 1 end
        local out, n = {}, 0
        for i = 1, #BG_B64, 4 do
            local a, b, c, d = BG_B64:byte(i, i + 3)
            local v = (lut[a] or 0) * 262144 + (lut[b] or 0) * 4096 + ((c and lut[c]) or 0) * 64 + ((d and lut[d]) or 0)
            n = n + 1
            local b1, b2, b3 = math.floor(v / 65536) % 256, math.floor(v / 256) % 256, v % 256
            if not c or c == 61 then out[n] = string.char(b1)
            elseif not d or d == 61 then out[n] = string.char(b1, b2)
            else out[n] = string.char(b1, b2, b3) end
            if n % 4000 == 0 then task.wait() end
        end
        pcall(function() if not isfolder("vercelcc") then makefolder("vercelcc") end end)
        writefile("vercelcc/bg.png", table.concat(out))
        local holder = Window.Holder
        local img = Instance.new("ImageLabel")
        img.Name = "VercelBG"
        img.BackgroundTransparency = 1
        img.BorderSizePixel = 0
        img.Image = getcustomasset("vercelcc/bg.png")
        img.AnchorPoint = Vector2.new(0, 1)
        img.Position = UDim2.new(1, -70, 1, 0)
        img.Size = UDim2.new(0, 0, 1, 0)
        img.ZIndex = -5
        img.Parent = holder
        local ar = Instance.new("UIAspectRatioConstraint")
        ar.AspectRatio = 210 / 303
        ar.DominantAxis = Enum.DominantAxis.Height
        ar.Parent = img
    end)
end)

local MainTab     = Window:AddTab("Main")
local CombatTab   = Window:AddTab("Combat")
local MovementTab = Window:AddTab("Movement")
local MiscTab     = Window:AddTab("Utilities")
local SettingsTab = Window:AddTab("Settings")

-- MAIN
local MoveBox = MainTab:AddLeftGroupbox("Movement")
Tgl(MoveBox, "FlyMode",    "Fly",            "Camera-directed flight.",       function(v) config.flyEnabled = v if v then startFly() else stopFly() end end)
Sld(MoveBox, "FlySpeed", "Fly Speed", 50, 1, 2000, 0, function(v) config.flySpeed = v end)
Tgl(MoveBox, "Noclip",     "Noclip",         "Walk through walls.",           function(v) config.nc = v end)
Tgl(MoveBox, "DoubleJump", "Double Jump",    "Infinite mid-air jumps.",       function(v) config.doubleJumpEnabled = v end)
Tgl(MoveBox, "FakePos",    "Fake Position",  "Spoofs server-sided position.", function(v) config.fakePositionEnabled = v if v then startFakePosition() else stopFakePosition() end end)
Tgl(MoveBox, "Desync",     "Velocity Desync","Spoofs velocity vectors.",      function(v) config.desyncEnabled = v if v then startDesync() else stopDesync() end end)
Tgl(MoveBox, "GlideMode",  "Glide",          "Smooth ground-level glide.",    function(v) config.glideEnabled = v if v then startGlide() else stopGlide() end end)
Sld(MoveBox, "GlideSpd", "Glide Speed", 280, 10, 5000, 0, function(v) config.glideSpeed = v end)
Sld(MoveBox, "GlideAcc", "Glide Accel", 18, 1, 100, 0, function(v) config.glideAccel = v end)

local CombatBox2 = MainTab:AddRightGroupbox("Combat")
Tgl(CombatBox2, "Wallbang",    "Wallbang Aim",     "Camera lock and auto-shoot.",      function(v) config.wallbangEnabled = v if v then startWallbang() else stopWallbang() end end)
Tgl(CombatBox2, "RapidFire",   "Rapid Fire",       "Spams tool activation.",           function(v) config.rapidFire = v if v then startRapidFire() else stopRapidFire() end end)
Tgl(CombatBox2, "TpEnemy",     "Teleport to Enemy","Teleports on top of enemy.",       function(v) config.teleportEnemyEnabled = v if v then startTp() else stopTp() end end)
Tgl(CombatBox2, "FastReload",  "Fast Reload",      "Zero cooldown on all weapons.",    function(v) config.fastReload = v if v then startFastReload() else stopFastReload() end end)
Tgl(CombatBox2, "DaggerBypass","Dagger Bypass",    "Disables incoming dagger hits.",   function(v) config.daggerBypass = v end)
Tgl(CombatBox2, "AntiClose",   "Anti Close",       "Pushes away approaching enemies.", function(v) config.antiClose = v if v then startAntiClose() else stopAntiClose() end end)

-- COMBAT
local AntiBox = CombatTab:AddLeftGroupbox("Anti-Aim")
Tgl(AntiBox, "AntiAim",   "Anti Aim", "Alters orientation angles.", function(v) config.antiAimEnabled = v end)
Sld(AntiBox, "PitchShift", "Pitch Shift", 0, -180, 180, 0, function(v) config.pitchAngle = v end)
Sld(AntiBox, "YawShift",   "Yaw Shift",   0, -180, 180, 0, function(v) config.yawAngle = v end)
Tgl(AntiBox, "SpinBypass","Spin Bypass", "Spins physical coordinates rapidly.", function(v) config.spinEnabled = v end)
Tgl(AntiBox, "UnderMap",  "Underground (Anti-Aim)", "Pushes your character under the map.", function(v) config.underMapEnabled = v if v then startUnderMap() else stopUnderMap() end end)
Sld(AntiBox, "UnderMapY", "Underground Depth", -500, -5000, -50, 0, function(v) config.underMapY = v end)

local OrbitBox = CombatTab:AddLeftGroupbox("Orbit")
Tgl(OrbitBox, "OrbitMode", "Orbit Mode", "Orbit around closest enemy.", function(v) config.orbit = v if v then startOrbit() else stopOrbit() end end)
Sld(OrbitBox, "OrbSpeed",  "Orbit Speed (deg/s)", 90, 10, 720, 0, function(v) config.orbitSpeed = v end)
Sld(OrbitBox, "OrbDist",   "Orbit Radius", 8, 1, 5000, 0, function(v) config.orbitDistance = v end)
Sld(OrbitBox, "OrbHeight", "Orbit Height Offset", 0, -100, 100, 0, function(v) config.orbitHeight = v end)

local AntiHitBox = CombatTab:AddRightGroupbox("Anti-Hit")
Tgl(AntiHitBox, "SlingRage", "Slingshot Ragebot", "Bypasses slingshot parameters.", function(v) config.slingRage = v if v then startSlingRage() else stopSlingRage() end end)
Tgl(AntiHitBox, "AntiProj",  "Anti Projectile",   "Freezes and breaks projectiles.", function(v) config.antiProj = v if v then startAntiProj() else stopAntiProj() end end)

local RiotAbuserBox = CombatTab:AddRightGroupbox("Riot Abuser")
Tgl(RiotAbuserBox, "RiotAbuserE", "Riot Abuser", "Heavy distortion parameters.", function(v) config.riotAbuserEnabled = v if v then startRiotAbuser() else stopRiotAbuser() end end)
Sld(RiotAbuserBox, "RA_D",    "Spread Distance", 300, 10, 1000, 0, function(v) config.riotAbuserDistance = v end)
Sld(RiotAbuserBox, "RA_X",    "X Jitter", 30, 0, 200, 0, function(v) config.riotAbuserX = v end)
Sld(RiotAbuserBox, "RA_Y",    "Y Jitter", 8, 0, 100, 0, function(v) config.riotAbuserY = v end)
Sld(RiotAbuserBox, "RA_Z",    "Z Jitter", 30, 0, 200, 0, function(v) config.riotAbuserZ = v end)
Sld(RiotAbuserBox, "RA_Spin", "Spin Speed", 720, 0, 2000, 0, function(v) config.riotAbuserSpin = v end)

local RiotBypassBox = CombatTab:AddRightGroupbox("Riot Bypass")
Tgl(RiotBypassBox, "RiotBypassE", "Riot Bypass", "Snap to target, facing them.", function(v) config.riotBypassEnabled = v if v then startRiotBypass() else stopRiotBypass() end end)
Sld(RiotBypassBox, "RB_D",  "Distance", 3, 0, 20, 1, function(v) config.riotBypassDistance = v end)
Sld(RiotBypassBox, "RB_H",  "Height Offset", 0, -20, 20, 1, function(v) config.riotBypassHeight = v end)
Sld(RiotBypassBox, "RB_UR", "Update Rate (ms)", 20, 1, 500, 0, function(v) config.riotBypassUpdate = v / 1000 end)
RiotBypassBox:AddDropdown("RB_Pos", { Text = "Teleport Position", Values = { "Front", "Back", "Above", "Below" }, Default = 1, Callback = function(v) config.riotBypassPosition = v end })

-- AIM ASSIST / TRIGGERBOT (native)
local aimCfg = { assist = false, fov = 120, smooth = 0.25, part = "Head", team = true, trig = false, trigDelay = 0.1, showFov = false }
local fovCircle
pcall(function()
    if Drawing then
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 1; fovCircle.NumSides = 64; fovCircle.Filled = false
        fovCircle.Color = Color3.fromRGB(170, 170, 170); fovCircle.Visible = false
    end
end)
local function isEnemy(p)
    if p == localplayer then return false end
    if aimCfg.team and localplayer.Team ~= nil and p.Team == localplayer.Team then return false end
    local ch = p.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end
local lastTrig = 0
table.insert(getgenv().AllConnections, RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local mpos = UserInputService:GetMouseLocation()
    if fovCircle then
        fovCircle.Visible = aimCfg.showFov and aimCfg.assist
        fovCircle.Position = mpos; fovCircle.Radius = aimCfg.fov
    end
    if aimCfg.assist and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local best, bestD = nil, aimCfg.fov
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) then
                local part = p.Character:FindFirstChild(aimCfg.part) or p.Character:FindFirstChild("HumanoidRootPart")
                if part then
                    local sp, on = cam:WorldToViewportPoint(part.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - mpos).Magnitude
                        if d < bestD then bestD = d; best = part end
                    end
                end
            end
        end
        if best then
            local goal = CFrame.lookAt(cam.CFrame.Position, best.Position)
            cam.CFrame = cam.CFrame:Lerp(goal, math.clamp(aimCfg.smooth, 0.02, 1))
        end
    end
    if aimCfg.trig and (tick() - lastTrig) >= aimCfg.trigDelay then
        local ray = cam:ViewportPointToRay(mpos.X, mpos.Y)
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = { localplayer.Character }
        local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, rp)
        local m = hit and hit.Instance and hit.Instance:FindFirstAncestorOfClass("Model")
        local p = m and Players:GetPlayerFromCharacter(m)
        if p and isEnemy(p) then
            lastTrig = tick()
            pcall(function()
                if mouse1click then mouse1click() else VirtualUser:ClickButton1(mpos) end
            end)
        end
    end
end))

local AimBox = CombatTab:AddLeftGroupbox("Aim Assist")
Tgl(AimBox, "AimAssistE", "Aim Assist", "Hold right mouse to pull aim to the nearest enemy.", function(v) aimCfg.assist = v end)
Sld(AimBox, "AimFov", "FOV", 120, 20, 600, 0, function(v) aimCfg.fov = v end)
Sld(AimBox, "AimSmooth", "Smoothing (higher = snappier)", 0.25, 0.02, 1, 2, function(v) aimCfg.smooth = v end)
AimBox:AddDropdown("AimPart", { Text = "Target Part", Values = { "Head", "HumanoidRootPart" }, Default = 1, Callback = function(v) aimCfg.part = v end })
AimBox:AddToggle("AimTeam", { Text = "Team Check", Default = true, Callback = function(v) aimCfg.team = v end })
AimBox:AddToggle("AimShowFov", { Text = "Show FOV Circle", Default = false, Callback = function(v) aimCfg.showFov = v end })
local TrigBox = CombatTab:AddRightGroupbox("Triggerbot")
Tgl(TrigBox, "TrigE", "Triggerbot", "Clicks when your crosshair is on an enemy.", function(v) aimCfg.trig = v end)
Sld(TrigBox, "TrigDelay", "Delay (ms)", 100, 0, 1000, 0, function(v) aimCfg.trigDelay = v / 1000 end)

-- MOVEMENT
local VoidBox = MovementTab:AddLeftGroupbox("Void (Extreme)")
Tgl(VoidBox, "VoidEnable", "Void (Extreme)", "Teleports massively out of map.", function(v) config.VoidEnabled = v if v then startVoid() else stopVoid() end end)
Sld(VoidBox, "VoidX", "X Distance Bound", 1e8, 1000, 1e9, 0, function(v) config.voidX = v end)
Sld(VoidBox, "VoidY", "Y Height Bound",   1e8, 1000, 1e9, 0, function(v) config.voidY = v end)
Sld(VoidBox, "VoidZ", "Z Distance Bound", 1e8, 1000, 1e9, 0, function(v) config.voidZ = v end)

local VoidSpamBox = MovementTab:AddLeftGroupbox("Void Spam (Pattern)")
Tgl(VoidSpamBox, "VoidSpamE", "Void Spam", "Pattern-based void with 8 modes.", function(v) config.voidSpamEnabled = v if v then startVoidSpam() else stopVoidSpam() end end)
Sld(VoidSpamBox, "VSInterval", "Interval (lower=faster)", 16, 5, 500, 0, function(v) config.voidSpamInterval = v / 1000 end)
Sld(VoidSpamBox, "VSBurst", "Burst Count", 5, 1, 20, 0, function(v) config.voidSpamBurst = v end)
VoidSpamBox:AddDropdown("VSPattern", { Text = "Pattern", Values = { "random", "spiral", "wave", "bounce", "chaos", "cross", "helix", "strobe" }, Default = 1, Callback = function(v) config.voidPattern = v end })
VoidSpamBox:AddToggle("VSSmooth", { Text = "Smooth", Default = false, Callback = function(v) config.voidSmooth = v end })
Sld(VoidSpamBox, "VSSmoothA", "Smooth Alpha", 0.5, 0.01, 1, 2, function(v) config.voidSmoothAlpha = v end)

local VoidAxisBox = MovementTab:AddRightGroupbox("Void Spam Range")
VoidAxisBox:AddToggle("VSAxX", { Text = "Axis X", Default = true, Callback = function(v) config.voidAxisX = v end })
VoidAxisBox:AddToggle("VSAxY", { Text = "Axis Y", Default = true, Callback = function(v) config.voidAxisY = v end })
VoidAxisBox:AddToggle("VSAxZ", { Text = "Axis Z", Default = true, Callback = function(v) config.voidAxisZ = v end })
Sld(VoidAxisBox, "VSXp", "X +", 2500, 0, 20000, 0, function(v) config.voidXPos = v end)
Sld(VoidAxisBox, "VSXn", "X -", 2500, 0, 20000, 0, function(v) config.voidXNeg = v end)
Sld(VoidAxisBox, "VSYp", "Y +", 1500, 0, 20000, 0, function(v) config.voidYPos = v end)
Sld(VoidAxisBox, "VSYn", "Y -", 1500, 0, 20000, 0, function(v) config.voidYNeg = v end)
Sld(VoidAxisBox, "VSZp", "Z +", 2500, 0, 20000, 0, function(v) config.voidZPos = v end)
Sld(VoidAxisBox, "VSZn", "Z -", 2500, 0, 20000, 0, function(v) config.voidZNeg = v end)


local WsBox = MovementTab:AddRightGroupbox("WalkSpeed")
local wsBase, wsConn, wsLast = nil, nil, nil
Tgl(WsBox, "WsMult", "WalkSpeed Multiplier", "Multiplies your walk speed.", function(v)
    config.wsEnabled = v
    if wsConn then wsConn:Disconnect() wsConn = nil end
    local hum0 = localplayer.Character and localplayer.Character:FindFirstChildOfClass("Humanoid")
    if v then
        wsConn = RunService.Heartbeat:Connect(function()
            local hum = localplayer.Character and localplayer.Character:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            if not wsBase or hum.WalkSpeed ~= wsLast then wsBase = hum.WalkSpeed end
            wsLast = wsBase * (config.wsMult or 1)
            hum.WalkSpeed = wsLast
        end)
    else
        if hum0 and wsBase then hum0.WalkSpeed = wsBase end
        wsBase = nil
    end
end)
Sld(WsBox, "WsMultV", "Multiplier", 1.5, 0.5, 10, 1, function(v) config.wsMult = v end)
config.wsMult = 1.5

local EvadeBox = MovementTab:AddRightGroupbox("Evasion")
Tgl(EvadeBox, "EvasionE", "Evasion", "Erratic teleport dodging.", function(v) config.evasionEnabled = v if v then startEvasion() else stopEvasion() end end)
Sld(EvadeBox, "EvasionI", "Intensity", 3, 1, 10, 1, function(v) config.evasionIntensity = v end)
Tgl(EvadeBox, "BlinkE", "Blink", "Random snaps around an anchor.", function(v) config.blinkEnabled = v if v then startBlink() else stopBlink() end end)
Sld(EvadeBox, "BlinkR", "Blink Radius", 80, 5, 1000, 0, function(v) config.blinkRadius = v end)
Sld(EvadeBox, "BlinkRate", "Blink Rate (/s)", 60, 1, 240, 0, function(v) config.blinkRate = v end)
Tgl(EvadeBox, "GhostE", "Ghost", "Flickers around your position.", function(v) config.ghostEnabled = v if v then startGhost() else stopGhost() end end)
Sld(EvadeBox, "GhostD", "Ghost Distance", 150, 5, 1000, 0, function(v) config.ghostDistance = v end)

-- UTILITIES
local UtilBox = MiscTab:AddLeftGroupbox("Utilities")
Tgl(UtilBox, "AntiAfkE", "Anti AFK", "Prevents idle kick.", function(v) config.antiAfkEnabled = v if v then startAntiAfk() else stopAntiAfk() end end)
Tgl(UtilBox, "AutoCollectE", "Auto Collect", "Teleports to nearby heals.", function(v) config.autocollectEnabled = v if v then startAutocollect() else stopAutocollect() end end)
Sld(UtilBox, "AutoCollectR", "Collect Radius", 60, 5, 500, 0, function(v) config.autocollectRadius = v end)
Tgl(UtilBox, "ReturnHomeE", "Return Home", "Returns you to your saved home.", function(v) config.returnHomeEnabled = v if v then startReturnHome() else stopReturnHome() end end)
Sld(UtilBox, "HomeDelay", "Return Delay (s)", 3, 0.5, 30, 1, function(v) config.homeReturnDelay = v end)
UtilBox:AddButton({ Text = "Set Home Here", Func = function()
    if getHrp() then getgenv().homePosition = getHrp().Position Notify("Home", "Saved current position.") end
end })
Tgl(UtilBox, "SafeZoneE", "Safe Zone", "Snaps you back when falling.", function(v) config.safeZoneEnabled = v if v then startSafeZone() else stopSafeZone() end end)
Sld(UtilBox, "SafeZoneY", "Safe Zone Y", -10, -500, 100, 0, function(v) config.safeZoneY = v end)

local TpBox = MiscTab:AddRightGroupbox("Teleport Loop")
TpBox:AddButton({ Text = "Add Waypoint (here)", Func = function()
    if getHrp() then table.insert(getgenv().loopWaypoints, getHrp().Position) Notify("Waypoint", "Added #" .. #getgenv().loopWaypoints) end
end })
TpBox:AddButton({ Text = "Clear Waypoints", Func = function()
    getgenv().loopWaypoints = {}; getgenv().loopIndex = 1 Notify("Waypoints", "Cleared.")
end })
Sld(TpBox, "TpLoopDelay", "Loop Delay (s)", 1.5, 0.1, 10, 1, function(v) config.teleportLoopDelay = v end)
Tgl(TpBox, "TpLoopE", "Teleport Loop", "Cycles through waypoints.", function(v) if v then startTeleportLoop() else stopTeleportLoop() end end)

-- SETTINGS
local ProfBox = SettingsTab:AddLeftGroupbox("Profiles")
local profileName = ""
ProfBox:AddInput("ProfName", { Text = "Profile name", Default = "", Placeholder = "name", Callback = function(v) profileName = v or "" end })
ProfBox:AddDropdown("ProfList", { Text = "Saved profiles", Values = (#listProfiles() > 0 and listProfiles() or { "(none)" }), Default = 1 })
ProfBox:AddButton({ Text = "Save Profile", Func = function()
    local ok, msg = saveProfile(profileName ~= "" and profileName or (Options.ProfName and Options.ProfName.Value) or "")
    Notify("Profiles", msg)
    if ok and Options.ProfList then local l = listProfiles() Options.ProfList:SetValues(l) end
end })
ProfBox:AddButton({ Text = "Load Profile", Func = function()
    local sel = Options.ProfList and Options.ProfList.Value
    if not sel or sel == "(none)" then return Notify("Profiles", "Select a profile.") end
    local ok, msg = loadProfile(sel)
    Notify("Profiles", msg)
    if ok then
        for _, pair in ipairs({
            { "FlyMode", "flyEnabled" }, { "Noclip", "nc" }, { "DoubleJump", "doubleJumpEnabled" },
            { "AntiAim", "antiAimEnabled" }, { "SpinBypass", "spinEnabled" }, { "DaggerBypass", "daggerBypass" },
        }) do
            local t = Toggles[pair[1]]
            if t then pcall(function() t:SetValue(config[pair[2]]) end) end
        end
    end
end })
ProfBox:AddButton({ Text = "Delete Profile", Func = function()
    local sel = Options.ProfList and Options.ProfList.Value
    if not sel or sel == "(none)" then return end
    Notify("Profiles", select(2, deleteProfile(sel)))
    local l = listProfiles() Options.ProfList:SetValues(#l > 0 and l or { "(none)" })
end })

local MenuBox = SettingsTab:AddRightGroupbox("Menu")
MenuBox:AddButton({ Text = "Save Global Config", Func = function() saveGlobalConfig() Notify("Config", "Saved.") end })
MenuBox:AddButton({ Text = "Panic (stop everything)", Func = function() getgenv().vercelPanic() end })
MenuBox:AddButton({ Text = "Unload", Func = function() getgenv().vercelPanic() Library:Unload() end })

getgenv().vercelPanic = function()
    for _, n in ipairs({ "Fly","Void","VoidSpam","Orbit","Tp","FakePosition","Desync","Evasion","Blink","Ghost","Glide",
        "RiotAbuser","RiotBypass","SlingRage","AntiProj","AntiClose","Wallbang","RapidFire","Autocollect","ReturnHome",
        "SafeZone","TeleportLoop","AntiAfk","UnderMap" }) do
        local f = getgenv()["stop" .. n]
        if f then pcall(f) end
    end
    for k, v in pairs(config) do if type(v) == "boolean" then config[k] = false end end
    config.voidAxisX, config.voidAxisY, config.voidAxisZ = true, true, true
end
pcall(function() Library:OnUnload(function()
    pcall(getgenv().vercelPanic)
    for _, c in ipairs(getgenv().AllConnections) do pcall(function() c:Disconnect() end) end
    getgenv().vercel_loaded = nil
end) end)

getgenv().vercel_unload = function()
    pcall(getgenv().vercelPanic)
    pcall(function() Library:Unload() end)
end
MainTab:ShowTab()
Library:Notify("vercel.cc loaded", 3)
warn("[vercel.cc] ready")
end, function(e) return debug.traceback(tostring(e), 2) end)
if not __ok then
    getgenv().vercel_loaded = nil
    warn("[vercel.cc] FAILED: " .. tostring(__err))
end
