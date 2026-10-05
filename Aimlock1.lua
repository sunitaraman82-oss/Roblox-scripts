--==========================================================================
--  Kicia Rebuild  -  Rivals
--  Kiciahook v3, rebuilt from a decompiled build.
--==========================================================================
if getgenv().KiciaRebuild and getgenv().KiciaRebuild.Unload then
    pcall(getgenv().KiciaRebuild.Unload)
end
if not game:IsLoaded() then game.Loaded:Wait() end

local K = { connections = {}, cleanups = {}, destroyed = false }
getgenv().KiciaRebuild = K

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

local rawget, rawset = rawget, rawset

function K.fn(name)
    local v
    pcall(function() v = getfenv(0)[name] end)
    if type(v) ~= "function" then pcall(function() v = getfenv()[name] end) end
    return type(v) == "function" and v or nil
end

local getthreadidentity_ = K.fn("getthreadidentity") or K.fn("getidentity")
local setthreadidentity_ = K.fn("setthreadidentity") or K.fn("setidentity")
local sethiddenproperty_ = K.fn("sethiddenproperty")
local gethui_ = K.fn("gethui")
local function identity(n)
    if not setthreadidentity_ then return function() end end
    local old = getthreadidentity_ and getthreadidentity_() or nil
    pcall(setthreadidentity_, n)
    return function() if old then pcall(setthreadidentity_, old) end end
end
K.identity = identity
local function hudParent()
    local ok, h = pcall(function() return gethui_ and gethui_() end)
    if ok and h then return h end
    return game:GetService("CoreGui")
end
K.hudParent = hudParent

function K.track(c) K.connections[#K.connections + 1] = c return c end
function K.onUnload(f) K.cleanups[#K.cleanups + 1] = f end

--==========================================================================
--  Signal / Trove (Kicia's own small versions)
--==========================================================================
local Signal = {}
Signal.__index = Signal
function Signal.new() return setmetatable({ _handlers = {} }, Signal) end
function Signal:Connect(fn)
    local h = { fn = fn, connected = true }
    table.insert(self._handlers, h)
    local sig = self
    return {
        Connected = true,
        Disconnect = function(c)
            if not h.connected then return end
            h.connected = false
            c.Connected = false
            local i = table.find(sig._handlers, h)
            if i then table.remove(sig._handlers, i) end
        end,
    }
end
function Signal:Once(fn)
    local c
    c = self:Connect(function(...) c:Disconnect() fn(...) end)
    return c
end
function Signal:Fire(...)
    local list = table.clone(self._handlers)
    for _, h in ipairs(list) do
        if h.connected then task.spawn(h.fn, ...) end
    end
end
function Signal:FireSync(...)
    for _, h in ipairs(table.clone(self._handlers)) do
        if h.connected then h.fn(...) end
    end
end
function Signal:Destroy() table.clear(self._handlers) end
K.Signal = Signal

local Trove = {}
Trove.__index = Trove
function Trove.new(name) return setmetatable({ _name = name, _items = {} }, Trove) end
local function cleanItem(o)
    local t = typeof(o)
    if t == "RBXScriptConnection" then o:Disconnect()
    elseif t == "Instance" then pcall(function() o:Destroy() end)
    elseif t == "thread" then pcall(task.cancel, o)
    elseif type(o) == "function" then pcall(o)
    elseif type(o) == "table" then
        --  some objects (Kicia's signal connections) error on unknown fields
        local function member(k)
            local ok, v = pcall(function() return o[k] end)
            return ok and type(v) == "function" and v or nil
        end
        local cancel, getStatus = member("cancel"), member("getStatus")
        if cancel and getStatus then pcall(cancel, o) return end
        local destroy = member("Destroy")
        if destroy then pcall(destroy, o) return end
        local disconnect = member("Disconnect")
        if disconnect then pcall(disconnect, o) end
    end
end
function Trove:Add(o) table.insert(self._items, o) return o end
function Trove:Connect(sig, fn) return self:Add(sig:Connect(fn)) end
function Trove:Extend() return self:Add(Trove.new(self._name)) end
function Trove:Remove(o, keep)
    local i = table.find(self._items, o)
    if i then
        table.remove(self._items, i)
        if not keep then cleanItem(o) end
    end
end
--  Promise held until it settles; cancelled if the trove is cleaned first.
function Trove:AddPromise(promise)
    if tostring(promise:getStatus()) == "Started" then
        self:Add(promise)
        promise:finally(function()
            if not self._cleaning then self:Remove(promise, true) end
        end)
    end
    return promise
end
--  Sub-trove that cleans itself up when `instance` is destroyed.
function Trove:AttachExtend(instance)
    local sub = self:Extend()
    sub:Connect(instance.Destroying, function() self:Remove(sub) end)
    return sub
end
function Trove:Clean()
    local items = self._items
    self._items = {}
    self._cleaning = true
    for i = #items, 1, -1 do cleanItem(items[i]) end
    self._cleaning = false
end
Trove.Destroy = Trove.Clean
K.Trove = Trove

--==========================================================================
--  Kicia's constant pool (v86[...]) as recovered from usage in the dump
--==========================================================================
local C = {
    [3] = "Toggle", [9] = 20, [12] = 12, [18] = "0", [26] = 4, [34] = true, [44] = "Enabled",
    [45] = 90, [48] = 2, [53] = 20, [55] = "Mode", [56] = 2, [62] = 0.1, [63] = 1, [68] = "table",
    [75] = "None", [83] = 64, [91] = 100, [95] = "number", [101] = 0.5, [108] = 255, [116] = "boolean",
    [118] = 16, [122] = 8, [126] = 0.15, [127] = "CFrame", [128] = "Frame", [133] = 10, [137] = 256,
    [147] = 0.1, [149] = 1, [153] = false, [155] = 3, [160] = 50, [162] = 8, [165] = "string",
    [170] = 9, [173] = 0.88, [175] = 5, [186] = 0, [192] = 30, [195] = 0.7,
}
K.C = C

--==========================================================================
--  Kicia's own UI, settings store and Combat menu (lifted from the dump)
--==========================================================================
local v86 = {
    [2] = "ReactiveStore",
    [3] = "Toggle",
    [4] = "UIListLayout",
    [5] = "BackgroundColor3",
    [6] = 0,
    [7] = 60,
    [8] = 60,
    [9] = 20,
    [12] = 12,
    [13] = 14,
    [14] = "Settings",
    [15] = 120,
    [16] = "min",
    [17] = 200,
    [18] = "0",
    [19] = 200,
    [20] = "Vector3",
    [21] = "Always",
    [22] = "",
    [23] = 1.4707963267948965,
    [24] = "Roboto",
    [25] = 24,
    [26] = 4,
    [27] = "Color",
    [28] = 0.2,
    [29] = "Size",
    [30] = 0.35,
    [31] = 29,
    [32] = 24,
    [33] = "Button",
    [34] = true,
    [35] = "ConfigManager",
    [36] = "ApplyMigrations",
    [37] = "TextBounds",
    [38] = "DeleteFile",
    [39] = "Slider",
    [40] = "...",
    [42] = "left",
    [43] = "Proggy Clean",
    [44] = "Enabled",
    [45] = 90,
    [46] = "UIGradient",
    [47] = "CanvasGroup",
    [48] = 0.3,
    [49] = 2,
    [50] = "Side",
    [51] = " ",
    [52] = "BottomRight",
    [53] = 92,
    [54] = 6,
    [55] = "Mode",
    [56] = 2,
    [57] = "TextColor",
    [58] = 80,
    [59] = "Font",
    [60] = 29,
    [61] = 20,
    [62] = 0.1,
    [63] = 1,
    [64] = "ScrollingFrame",
    [65] = 200,
    [66] = 0.5,
    [67] = 100,
    [68] = "table",
    [69] = "Catalog unavailable",
    [70] = "GradientDark",
    [71] = 10,
    [72] = 12,
    [73] = "Keybind",
    [74] = 0.9,
    [75] = "None",
    [76] = "LoadFromFile",
    [77] = "FireServer",
    [78] = 720,
    [79] = 255,
    [80] = "Text",
    [81] = 1,
    [82] = "Realize() can only be called on the root",
    [83] = 64,
    [84] = 0.5,
    [85] = "UIStroke",
    [87] = 0.8,
    [88] = "TabHighlight",
    [89] = "Loading",
    [90] = "Gradient",
    [91] = 100,
    [92] = "TextButton",
    [93] = "ColorSequence",
    [94] = "Options",
    [95] = "number",
    [96] = "Unselected",
    [97] = "Mode",
    [98] = "UICorner",
    [99] = "ExportToJson",
    [100] = 14,
    [101] = 0.5,
    [102] = 231,
    [103] = 52,
    [104] = "Fonts",
    [105] = 0.85,
    [106] = "Menu Keybind",
    [107] = 40,
    [108] = 255,
    [109] = 77,
    [110] = 70,
    [111] = "Fetching items...",
    [112] = "Invisible",
    [113] = "UIPadding",
    [114] = "primary",
    [115] = "Color3",
    [116] = "boolean",
    [118] = 16,
    [119] = 159,
    [120] = "Outline",
    [121] = "ImageButton",
    [122] = 8,
    [123] = 19,
    [124] = "X",
    [125] = "Proggy Tiny",
    [126] = 0.15,
    [127] = "CFrame",
    [128] = "Frame",
    [129] = "Show Watermark",
    [131] = "AbsoluteSize",
    [132] = "Breathing",
    [133] = 10,
    [134] = "GradientTop",
    [135] = "TextLabel",
    [136] = "Unselected Text",
    [137] = 256,
    [138] = 0.85,
    [139] = "Accent",
    [140] = "danger",
    [141] = "GradientDeep",
    [142] = "Silent Load",
    [143] = 32,
    [144] = 20,
    [145] = "Dialog has been destroyed",
    [146] = "ImageLabel",
    [147] = 0.1,
    [148] = "TextBox",
    [149] = 1,
    [150] = "stop",
    [151] = "family",
    [153] = false,
    [154] = "ScrollBarImageColor3",
    [155] = 3,
    [156] = "ImageColor3",
    [157] = 20,
    [158] = "secondary",
    [159] = 20,
    [160] = 50,
    [161] = 0.5,
    [162] = 8,
    [163] = 80,
    [164] = "hue",
    [165] = "string",
    [166] = "family",
    [167] = "TextColor3",
    [168] = "ElementBackground",
    [169] = "FromJson",
    [170] = 9,
    [172] = "none",
    [173] = 0.88,
    [174] = "Unselected",
    [175] = 5,
    [176] = "UISizeConstraint",
    [177] = "Try a different search.",
    [178] = "ElementBackground",
    [181] = 10,
    [182] = "HttpService",
    [183] = 72,
    [184] = "Color",
    [186] = 0,
    [187] = "GradientMid",
    [189] = "Position",
    [190] = "Search...",
    [191] = "TabShadow",
    [192] = 30,
    [193] = 0,
    [194] = "Hold",
    [195] = 0.7,
    [196] = "Viewport",
    [197] = "Y",
    [198] = 400,
    [199] = "Unload",
    [200] = 26,
}
--  Environment Kicia's modules expect: the module table and the aliases its
--  loader set up before them (v102 = rawget, v103 = rawset, v107 = pcall).
local tbl17 = { cache = {} }
local v102, v103, v107 = rawget, rawset, pcall
--  The obfuscator's integrity counters. Every check in the lifted code has one
--  branch that hangs and one that runs the real code; these values sit inside
--  the window where all of them take the real branch (n26 in [4790, 4809),
--  n25 in [3866, 3887]).
local n25, n26 = 3870, 4800
local flag2, flag3 = true, true
local function n29() return 0 end
local cloneref = K.fn("cloneref") or function(x) return x end
local gethui = K.fn("gethui") or function() return game:GetService("CoreGui") end
local getthreadidentity = K.fn("getthreadidentity") or K.fn("getidentity") or function() return 8 end
local setthreadidentity = K.fn("setthreadidentity") or K.fn("setidentity") or function() end
--  The rest of the loader's locals (clonefunction'd so hooks on them can't see us).
local function clonefn(f)
    local c = K.fn("clonefunction")
    if c and f then
        local ok, r = pcall(c, f)
        if ok and r then return r end
    end
    return f
end
local fireServer = clonefn(Instance.new("RemoteEvent").FireServer)
local fireServer2 = clonefn(Instance.new("UnreliableRemoteEvent").FireServer)
local v104 = clonefn(K.fn("sethiddenproperty"))
local v108 = clonefn(K.fn("setfflag")) or function() end
local v109 = clonefn(K.fn("isexecutorclosure")) or function() return false end
local v110 = clonefn(K.fn("setrawmetatable")) or setmetatable
local v111 = clonefn(K.fn("getrawmetatable")) or getmetatable
local v112 = clonefn(v111(game).__newindex)
local v113 = clonefn(v111(game).__index)
local v114 = clonefn(game.FindFirstChildOfClass)
local function n27() return 0 end
local firetouchinterest = K.fn("firetouchinterest") or function() end
local getconnections = K.fn("getconnections") or function() return {} end
local setclipboard = K.fn("setclipboard") or K.fn("toclipboard") or function() end
local InstanceHandle
pcall(function() InstanceHandle = getfenv(0).InstanceHandle end)
if InstanceHandle == nil then pcall(function() InstanceHandle = getgenv().InstanceHandle end) end
if InstanceHandle == nil then InstanceHandle = { new = function(x) return x end } end
--  The modules the decompiler lost (their bodies are `fn35(...) end` in
--  the dump), rebuilt from how the rest of Kicia's code calls them.

--  k: Trove
tbl17.k = function() return { new = function(name) return Trove.new(name) end } end

--  w: viewport / pointer / key / path helpers
do
    local UIS = UserInputService
    local GuiService = game:GetService("GuiService")
    local function camera() return workspace.CurrentCamera end
    local W = {}
    function W.appendPath(path, key)
        local p = table.clone(path)
        table.insert(p, key)
        return p
    end
    function W.currentViewportSize()
        local c = camera()
        return c and c.ViewportSize or Vector2.new(1920, 1080)
    end
    function W.connectCurrentCameraViewport(trove, cb)
        local inner = trove:Extend()
        local function bind()
            inner:Clean()
            local c = camera()
            if c == nil then return end
            inner:Connect(c:GetPropertyChangedSignal("ViewportSize"), function() cb(c.ViewportSize) end)
            cb(c.ViewportSize)
        end
        trove:Connect(workspace:GetPropertyChangedSignal("CurrentCamera"), bind)
        bind()
    end
    function W.absoluteToLayerOffset(layer, pos)
        return pos - layer.AbsolutePosition
    end
    function W.clampOffsetToViewport(x, y, size)
        local vp = W.currentViewportSize()
        return math.clamp(x, 0, math.max(0, vp.X - size.X)), math.clamp(y, 0, math.max(0, vp.Y - size.Y))
    end
    function W.clampGuiToViewport(gui)
        local vp = W.currentViewportSize()
        local ap, as = gui.AbsolutePosition, gui.AbsoluteSize
        local dx = math.clamp(ap.X, 0, math.max(0, vp.X - as.X)) - ap.X
        local dy = math.clamp(ap.Y, 0, math.max(0, vp.Y - as.Y)) - ap.Y
        if dx ~= 0 or dy ~= 0 then
            local p = gui.Position
            gui.Position = UDim2.new(p.X.Scale, p.X.Offset + dx, p.Y.Scale, p.Y.Offset + dy)
        end
    end
    function W.snapPosition(u)
        return UDim2.new(u.X.Scale, math.round(u.X.Offset), u.Y.Scale, math.round(u.Y.Offset))
    end
    function W.onScreenKeyboardTop()
        local ok, visible = pcall(function() return UIS.OnScreenKeyboardVisible end)
        if not ok or not visible then return nil end
        local ok2, pos = pcall(function() return UIS.OnScreenKeyboardPosition end)
        return ok2 and pos and pos.Y or nil
    end
    function W.connectOnScreenKeyboard(trove, cb)
        pcall(function() trove:Connect(UIS:GetPropertyChangedSignal("OnScreenKeyboardVisible"), cb) end)
        pcall(function() trove:Connect(UIS:GetPropertyChangedSignal("OnScreenKeyboardPosition"), cb) end)
    end
    function W.getPointerPosition()
        return UIS:GetMouseLocation()
    end
    function W.matchesPointerDrag(input, started, movement)
        if started ~= nil and started.UserInputType == Enum.UserInputType.Touch then return input == started end
        return input.UserInputType == movement
    end
    function W.round(v, step)
        if step == nil or step == 0 then return v end
        return math.round(v / step) * step
    end
    W.KeyNames = {
        [Enum.UserInputType.MouseButton1] = "MB1", [Enum.UserInputType.MouseButton2] = "MB2",
        [Enum.UserInputType.MouseButton3] = "MB3", [Enum.KeyCode.LeftShift] = "LShift",
        [Enum.KeyCode.RightShift] = "RShift", [Enum.KeyCode.LeftControl] = "LCtrl",
        [Enum.KeyCode.RightControl] = "RCtrl", [Enum.KeyCode.LeftAlt] = "LAlt", [Enum.KeyCode.RightAlt] = "RAlt",
    }
    function W.serializeKey(key)
        if typeof(key) ~= "EnumItem" then return nil end
        return tostring(key.EnumType) .. "." .. key.Name
    end
    function W.deserializeKey(s)
        if type(s) ~= "string" then return nil end
        local kind, name = s:match("^(%w+)%.(%w+)$")
        if kind == nil then return nil end
        local ok, v = pcall(function() return Enum[kind][name] end)
        return ok and v or nil
    end
    function W.findScrollingAncestor(inst)
        local p = inst and inst.Parent
        while p ~= nil do
            if p:IsA("ScrollingFrame") then return p end
            p = p.Parent
        end
        return nil
    end
    function W.isEffectivelyVisible(gui)
        local p = gui
        while p ~= nil and p ~= game do
            if p:IsA("GuiObject") and not p.Visible then return false end
            if p:IsA("LayerCollector") then return p.Enabled end
            p = p.Parent
        end
        return false
    end
    function W.ensureStorageDirectories(dir)
        local isf, mkf = K.fn("isfolder"), K.fn("makefolder")
        if not (isf and mkf) or type(dir) ~= "string" then return end
        local function make(path)
            local acc
            for part in path:gmatch("[^/]+") do
                acc = acc and (acc .. "/" .. part) or part
                pcall(function() if not isf(acc) then mkf(acc) end end)
            end
        end
        make(dir)
        make(dir .. "/configs")
    end
    tbl17.w = function() return W end
end

--  P: two-way link between a control and a settings path. Sliders ask for
--  Debounce so dragging writes once per short burst instead of every frame.
do
    local P = {}
    function P.bind(trove, config, control, path, opts)
        local debounce = opts ~= nil and opts.Debounce == true
        local writeBack = opts ~= nil and opts.WriteBack or nil
        control:Set(config:Get(path), true)
        trove:Connect(config:Changed(path), function(v) control:Set(v, true) end)
        local pending, scheduled = nil, false
        local function write(v)
            if writeBack then writeBack(v) else config:Set(path, v) end
        end
        trove:Connect(control.Changed, function(v)
            if not debounce then write(v) return end
            pending = v
            if scheduled then return end
            scheduled = true
            task.delay(0.05, function()
                scheduled = false
                write(pending)
            end)
        end)
    end
    tbl17.P = function() return P end
end

--  c5: the critically damped Spring (Position, Velocity, Target, Speed, Damper).
do
    local Spring = {}
    local function posVel(self, now)
        local p0, v0, p1, d, s = self._p0, self._v0, self._target, self._damper, self._speed
        local t = s * (now - self._t0)
        local d2 = d * d
        local h, si, co
        if d2 < 1 then
            h = math.sqrt(1 - d2)
            local ep = math.exp(-d * t) / h
            co, si = ep * math.cos(h * t), ep * math.sin(h * t)
        elseif d2 == 1 then
            h = 1
            local ep = math.exp(-d * t) / h
            c