-- =========================================================
-- LINORIA UI SETUP
-- =========================================================
local repo = 'https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Options = Library.Options
local Toggles = Library.Toggles

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera
local lp = Players.LocalPlayer

local Window = Library:CreateWindow({
    Title = "mspaint",
    Footer = "version: example",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

-- Tabs
local Tabs = {
    Main = Window:AddTab("Main", "user"),
    Rage = Window:AddTab("Rage", "crosshair"),
    ESP = Window:AddTab("ESP", "eye"),
    Configs = Window:AddTab("Configs", "settings"),
}

-- =========================================================
-- CONFIG & STATE
-- =========================================================
local Config = {
    -- Silent Aim
    SilentAim = false, SilentAimVisCheck = false, SilentAimJitter = true,
    SilentAimTargetPart = "Head", SilentAimFOV = 250, AvoidDeflect = true,
    SilentAimStickiness = 0.05, TeamCheck = true, MaxDistance = 1200, 
    PredictiveLead = true, LeadCap = 15, ServerProcessingMs = 30, 
    ProjectileLead = false, ProjectileSpeed = 300, SilentAimHitChance = 85,
    SilentAimJitterDeg = 1.5,
    
    -- Aimbot
    Aimbot = false, AimbotVisCheck = true, AimbotKey = "MB2",
    AimbotSmoothness = 0, AimbotSmoothnessX = 0, AimbotSmoothnessY = 0,
    AimbotLinkAxes = true, AimbotJumpDamping = 40, AimbotCancelSprings = true,
    AimbotCurvedFlick = false, AimbotCurvedIntensity = 0.35, AimbotTrackAssist = 100,
    AimbotFOVDeg = 20, AimbotMaxSpeed = 0, AimbotDeadzoneDeg = 0,
    AimbotSwitchDeg = 2, AimbotStickiness = 0.15, AimbotForgetTime = 0.2,
    AimbotTargetPart = "Best", AimbotPriority = "Crosshair",
    AimbotSkipImmune = true, AimbotPrediction = false, AimbotShotOverride = false,
    AimbotShowFOV = false, AimbotShowLock = false, AimbotDebug = false,
    AimbotReactionMs = 0, AimbotNoiseDeg = 0, AimbotOvershoot = 0,
    AimbotDirectCamera = false, TargetLockEnabled = false, TargetLockMode = "ToggleLock",

    -- Triggerbot
    Trigger = false, TriggerKey = "Always", TriggerHeadOnly = false,
    TriggerScopeCheck = false, TriggerDelayMs = 0, TriggerRefireMs = 0, TriggerMaxDist = 400,

    -- Fake Underground
    FakeUnderground = false, FUDepth = 5.8, FUWalk = true, FUCamera = false,
    FUNoclip = true, FUHide = true, FUAnim = true, FUPanic = false,
    FUPanicMin = -5, FUPanicMax = 5, FUPanicZ = false,
    FURage = false, FURageOrbit = false, FURageRadius = 14, FURageSpeed = 4,
    FURageRate = 0.1, FURageDist = 400, FURageSlot = "Primary", FURageTeam = true,

    -- ESP
    ESP = false, ESPTeamCheck = true, ESPMaxDistance = 1200, ESPMaxPlayers = 0,
    ESPFont = "Code", ESPTextSize = 14, ESPInfoTextSize = 12, ESPHealthTextSize = 11,
    ESPTextScale = 1, ESPTextCasing = 1, ESPDistanceScaling = true, ESPDistanceScalingRef = 50,
    ESPCasingThickness = 1, ESPBoxScale = 1, ESPBox = true, ESPBoxStyle = "Full Box", 
    ESPBoxBrackets = false, ESPCornerLength = 0.28, ESPBoxFill = false, ESPBoxThickness = 1,
    ESPName = true, ESPDistance = true, ESPWeapon = false, ESPHealth = true, 
    ESPHealthNumberMode = "OnDamage", ESPSkeleton = false, ESPSkeletonThickness = 1,
    ESPChams = false, ESPTracers = false, ESPTracerThickness = 1, ESPTracerOrigin = "Bottom",
    ESPArrows = false, ESPFlagStaring = false, ESPFlagDeflect = true, ESPFlagShield = true, 
    ESPFlagInvincible = true, ESPFlagLowHP = true, ESPHeadDot = false, ESPHeadDotSize = 4,
    ESPBoxColorMode = "Solid", ESPBoxColor = Color3.fromRGB(255, 255, 255),
    ESPBoxGradA = Color3.fromRGB(255, 59, 78), ESPBoxGradB = Color3.fromRGB(255, 194, 75),
    ESPBoxFillColor = Color3.fromRGB(255, 59, 78), ESPHealthColorMode = "Ramp", 
    ESPHealthColor = Color3.fromRGB(61, 224, 122), ESPHealthGradA = Color3.fromRGB(255, 68, 54), 
    ESPHealthGradB = Color3.fromRGB(61, 224, 122), ESPNameColorMode = "Solid", 
    ESPNameColor = Color3.fromRGB(255, 255, 255), ESPNameGradA = Color3.fromRGB(255, 255, 255), 
    ESPNameGradB = Color3.fromRGB(255, 194, 75), ESPInfoColorMode = "Solid", 
    ESPInfoColor = Color3.fromRGB(255, 255, 255), ESPInfoGradA = Color3.fromRGB(255, 255, 255), 
    ESPInfoGradB = Color3.fromRGB(255, 158, 75), ESPFlagColorMode = "PerFlag", 
    ESPFlagColor = Color3.fromRGB(255, 194, 75), ESPFlagGradA = Color3.fromRGB(255, 194, 75), 
    ESPFlagGradB = Color3.fromRGB(255, 70, 85), ESPSkeletonColorMode = "Solid", 
    ESPSkeletonColor = Color3.fromRGB(255, 255, 255), ESPSkeletonGradA = Color3.fromRGB(255, 255, 255), 
    ESPSkeletonGradB = Color3.fromRGB(120, 180, 255), ESPTracerColorMode = "Solid", 
    ESPTracerColor = Color3.fromRGB(255, 255, 255), ESPTracerGradA = Color3.fromRGB(255, 255, 255), 
    ESPTracerGradB = Color3.fromRGB(255, 59, 78), ESPMarkColorMode = "Solid", 
    ESPMarkColor = Color3.fromRGB(255, 255, 255), ESPMarkGradA = Color3.fromRGB(255, 255, 255), 
    ESPMarkGradB = Color3.fromRGB(255, 194, 75), ESPGradientSpeed = 0, ESPGradientRotBox = 0, 
    ESPGradientRotText = 90, ESPHeadDotColor = Color3.fromRGB(255, 255, 255),
    ESPChamsFillColor = Color3.fromRGB(255, 59, 78), ESPChamsOutlineColor = Color3.fromRGB(255, 255, 255),
    ColorEnemy = Color3.fromRGB(255, 59, 78), ColorTeam = Color3.fromRGB(53, 215, 199),
    ColorEnemyOcc = Color3.fromRGB(168, 85, 96), ColorTeamOcc = Color3.fromRGB(92, 153, 147),
    ColorVisible = Color3.fromRGB(41, 224, 255), ESPDistNearColor = Color3.fromRGB(80, 255, 140), 
    ESPDistFarColor = Color3.fromRGB(255, 70, 90), ESPBoxTransparency = 0, 
    ESPBoxFillTransparency = 0.75, ESPNameTransparency = 0, ESPHealthTransparency = 0.1, 
    ESPSkeletonTransparency = 0.2, ESPTracerTransparency = 0.35, ESPHeadDotTransparency = 0, 
    ESPChamsFillTransparency = 0.6, ESPChamsOutlineTransparency = 0,
    ESPChamsStyle = "Shade", ESPNameMode = "Display", ESPFadeIn = true, 
    ESPLookLine = false, ESPLookLineLength = 8, ESPHealthSmooth = true, 
    ESPHealthGhost = true, ESPDeclutter = true, ESPChamsVisSplit = true,
    ESPAmmoBar = false, ESPHealthNumber = true,
}

local State = { ESPObjects = {}, PrimaryTarget = nil, SilentLastTarget = nil, 
    AimbotTarget = nil, AimbotPart = nil, AimbotLastTarget = nil, AimbotLastTargetTime = 0,
    AimbotKeyHeld = false, AimbotFlickActive = false, AimbotSpringOffset = Vector2.zero,
    TargetLockTarget = nil, TargetLockTap = false
}

-- Safe API check
local DrawingAPI = Drawing or (syn and syn.drawing) or (getgenv and getgenv().Drawing)
local function screenDraw(kind)
    if not DrawingAPI or not DrawingAPI.new then return nil end
    local ok, obj = pcall(DrawingAPI.new, kind)
    if ok then return obj end
    return nil
end
local _mouseMove = mousemoverel or (syn and syn.mousemoverel) or (getgenv and getgenv().mousemoverel)

-- =========================================================
-- HELPER FUNCTIONS
-- =========================================================
local function getSafePlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do table.insert(list, p) end
    return list
end

local function isAlive(player)
    local c = player.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return h ~= nil and h.Health > 0
end

local function getHealth(player)
    if not player.Character then return 0, 100 end
    local h = player.Character:FindFirstChildOfClass("Humanoid")
    if not h then return 0, 100 end
    return h.Health, h.MaxHealth
end

local function isTeammate(player)
    if player == lp then return true end
    if lp.Team ~= nil and player.Team ~= nil then return lp.Team == player.Team end
    local a = lp:GetAttribute("TeamID")
    local b = player:GetAttribute("TeamID")
    if a ~= nil and b ~= nil then return a == b end
    return false
end

local function getWeaponName(player)
    if not player or not player.Character then return "?" end
    for _, c in ipairs(player.Character:GetChildren()) do
        if c:IsA("Tool") then return c.Name end
        if c:IsA("Model") and not c:FindFirstChildOfClass("Humanoid") then
            if c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart") then return c.Name end
        end
    end
    return "?"
end

local function isVisible(worldPos)
    local origin = Camera.CFrame.Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { lp.Character }
    local result = workspace:Raycast(origin, worldPos - origin, params)
    if not result then return true end
    local hitModel = result.Instance and result.Instance:FindFirstAncestorOfClass("Model")
    if hitModel and Players:GetPlayerFromCharacter(hitModel) then return true end
    return (result.Position - worldPos).Magnitude < 3
end

local HEAD_PARTS = { "HitboxHead", "HitboxHeadSmall", "Head" }
local TORSO_PARTS = { "HitboxBody", "UpperTorso", "HumanoidRootPart", "LowerTorso" }
local CLOSEST_PARTS = {
    "HitboxHead","Head","UpperTorso","LowerTorso","HumanoidRootPart",
    "LeftHand","RightHand","LeftFoot","RightFoot","LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg",
}

local function pickPart(char, mode)
    if not char then return nil end
    if mode == "Closest" then
        local best, bestDist = nil, math.huge
        local vp = Camera.ViewportSize
        local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
        for _, name in ipairs(CLOSEST_PARTS) do
            local p = char:FindFirstChild(name)
            if p and p:IsA("BasePart") then
                local sp, on = Camera:WorldToViewportPoint(p.Position)
                if on and sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < bestDist then best, bestDist = p, d end
                end
            end
        end
        if best then return best end
    end
    local list = mode == "Torso" and TORSO_PARTS or HEAD_PARTS
    for _, name in ipairs(list) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then return p end
    end
    return char:FindFirstChild("HumanoidRootPart")
end

local function isInputActive(key)
    if key == "MB1" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
    if key == "MB2" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
    if key == "Always" then return true end
    local kc = Enum.KeyCode[key]
    if kc then return UserInputService:IsKeyDown(kc) end
    return false
end

local function isValidTarget(player, checkVis)
    if not player or player == lp then return false end
    if Config.TeamCheck and isTeammate(player) then return false end
    if not isAlive(player) then return false end
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local myChar = lp.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if myRoot and (hrp.Position - myRoot.Position).Magnitude > Config.MaxDistance then return false end
    if checkVis and not isVisible(hrp.Position) then return false end
    return true
end

local function selectTarget(opts)
    opts = opts or {}
    local fov = opts.fov or 90
    local checkVis = opts.checkVis or false
    local mode = opts.partMode or "Head"
    local sticky = opts.stickyTarget
    local stickyBonus = opts.stickyBonus or 0
    local camPos0 = Camera.CFrame.Position
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    local best, bestPart, bestScore = nil, nil, math.huge
    
    for _, player in ipairs(getSafePlayers()) do
        if isValidTarget(player, false) then
            local char = player.Character
            local part = pickPart(char, mode)
            if part and (not checkVis or isVisible(part.Position)) then
                local sp, on = Camera:WorldToViewportPoint(part.Position)
                if on and sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d <= fov then
                        local score = d
                        if player == sticky then score = score * (1 - stickyBonus) end
                        if score < bestScore then bestScore, best, bestPart = score, player, part end
                    end
                end
            end
        end
    end
    return best, bestPart
end

-- =========================================================
-- SILENT AIM HOOK
-- =========================================================
task.spawn(function()
    task.wait(3)
    pcall(function()
        local RivalsUtil = require(ReplicatedStorage.Modules.Utility)
        local RivalsEnums = require(ReplicatedStorage.Modules.EnumLibrary)
        local GunModule = require(lp.PlayerScripts.Modules.ItemTypes.Gun)
        
        if shared._LH_GunOrig then pcall(function() GunModule.StartShooting = shared._LH_GunOrig end) end
        shared._LH_GunOrig = GunModule.StartShooting
        
        GunModule.StartShooting = function(self, ...)
            local results = { shared._LH_GunOrig(self, ...) }
            
            pcall(function()
                if not self.ClientFighter or not self.ClientFighter.IsLocalPlayer then return end
                local camData = results[3]
                if not camData or typeof(camData) ~= "table" then return end
                
                if Config.SilentAim then
                    local camPos = Camera.CFrame.Position
                    local tgt, part = selectTarget({
                        fov = Config.SilentAimFOV,
                        checkVis = Config.SilentAimVisCheck,
                        partMode = Config.SilentAimTargetPart,
                        stickyTarget = State.SilentLastTarget,
                        stickyBonus = Config.SilentAimStickiness or 0.05,
                    })
                    
                    if tgt and part then
                        State.SilentLastTarget = tgt
                        local lead = Vector3.zero
                        if Config.PredictiveLead then
                            local hrp = tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local lat = (lp:GetNetworkPing() or 0.05) + ((Config.ServerProcessingMs or 30) / 1000)
                                lead = hrp.AssemblyLinearVelocity * lat
                                if lead.Magnitude > (Config.LeadCap or 15) then lead = lead.Unit * (Config.LeadCap or 15) end
                            end
                        end
                        
                        local leadedPos = part.Position + lead
                        local eyeCF = CFrame.lookAt(camPos, leadedPos)
                        local muzzleCF = CFrame.lookAt(camPos - Vector3.new(0, 0.07, 0), leadedPos)
                        local objSpace = part.CFrame:PointToObjectSpace(leadedPos)
                        local hs = part.Size * 0.45
                        objSpace = Vector3.new(math.clamp(objSpace.X, -hs.X, hs.X), math.clamp(objSpace.Y, -hs.Y, hs.Y), math.clamp(objSpace.Z, -hs.Z, hs.Z))
                        
                        camData[utf8.char(0)] = RivalsUtil:EncodeCFrame(eyeCF)
                        camData[utf8.char(1)] = RivalsUtil:EncodeCFrame(muzzleCF)
                        camData[utf8.char(2)] = part
                        camData[utf8.char(3)] = RivalsUtil:EncodeCFrame(part.CFrame:ToObjectSpace(CFrame.new(part.CFrame:PointToWorldSpace(objSpace))))
                        
                        results[4] = true
                    end
                end
            end)
            return unpack(results)
        end
    end)
end)

-- =========================================================
-- AIMBOT MODULE
-- =========================================================
local Aimbot = {}
;(function()
    local TAU = math.pi * 2
    local D2R = math.pi / 180
    local R2D = 180 / math.pi
    local MAX_TAU     = 0.30
    local RETAIN_MUL  = 1.6
    local STICKY_MEM  = 2.0
    local FF_TAU      = 0.05
    local FF_MAX      = 12
    local UNIT_MAX    = 2000
    local RAMP_TIME   = 0.15
    local PITCH_LIMIT = 1.5690509975429023
    local CAL_MIN     = 1.5
    local CAL_FAST_N  = 8
    local BAND_LO     = 0.05
    local BAND_HI     = 6.0
    local OSC_ERR     = 0.02
    local RUNAWAY_ERR = 1.0
    local SEED_MX     = -0.008726646259971648
    local SEED_MY     = -0.006719517620178168
    local SEED_DX     = 1.0
    local SEED_DY     = 1.0
    local _bound       = false
    local _fovC, _lockC, _dbgT = nil, nil, nil
    local _tgt, _part  = nil, nil
    local _prevTgt     = nil
    local _notified    = nil
    local _acquireAt   = 0
    local _lastSeenAt  = 0
    local _ramp        = 0
    local _gx, _gy     = SEED_MX, SEED_MY
    local _sdx, _sdy   = SEED_MX, SEED_MY
    local _nx, _ny     = 0, 0
    local _sx, _sy     = 0, 0
    local _fx, _fy     = 0, 0
    local _lyaw, _lpit = 0, 0
    local _haveCam     = false
    local _ffy, _ffp   = 0, 0
    local _lty, _ltp   = 0, 0
    local _haveTgt     = false
    local _lastPartRef = nil
    local _flickActive   = false
    local _flickT        = 0
    local _flickDur      = 0.15
    local _flickCtrl1Y   = 0
    local _flickCtrl1P   = 0
    local _flickCtrl2Y   = 0
    local _flickCtrl2P   = 0
    local _auth        = 1.0
    local _flips       = 0
    local _errEma      = 0
    local _lastSign    = nil
    local _drive       = 0
    local _trips       = 0
    local _calOff      = false
    local _lastFOV     = 0
    local _errDeg      = 0
    local _path        = "none"
    local _ctl, _ctlTried = nil, false
    
    local function wrapPi(a) return (a + math.pi) % TAU - math.pi end
    local function yawOf(v) return math.atan2(-v.X, -v.Z) end
    local function pitchOf(v) return math.asin(math.clamp(v.Y, -1, 1)) end
    local function angTo(cf, pos)
        local d = pos - cf.Position
        local m = d.Magnitude
        if m < 1e-4 then return 0 end
        return math.acos(math.clamp(cf.LookVector:Dot(d) / m, -1, 1))
    end
    local function fovPixels(deg)
        local vp = Camera.ViewportSize
        local lim = math.max(vp.X, vp.Y)
        if deg >= 89 then return lim end
        local half = math.tan(math.rad(Camera.FieldOfView) * 0.5)
        if half <= 0 then return lim end
        return math.clamp(math.tan(deg * D2R) / half * (vp.Y * 0.5), 4, lim)
    end
    local function minJerk(s)
        s = math.clamp(s, 0, 1)
        return s * s * s * (10 + s * (-15 + 6 * s))
    end
    local function bezier(p0, p1, p2, p3, t)
        local it = 1 - t
        return it * it * it * p0 + 3 * it * it * t * p1 + 3 * it * t * t * p2 + t * t * t * p3
    end
    local function validFor(pl)
        if not isValidTarget(pl, false) then return false end
        return true
    end
    local function firstVisible(char, list, skip)
        for _, n in ipairs(list) do
            local p = char:FindFirstChild(n)
            if p and p ~= skip and p:IsA("BasePart") and isVisible(p.Position) then return p end
        end
        return nil
    end
    local function resolveBest(char, primary)
        if not char then return primary end
        if primary and isVisible(primary.Position) then return primary end
        return firstVisible(char, HEAD_PARTS, primary) or firstVisible(char, TORSO_PARTS, primary) or primary
    end
    local function acquire(cf, fovR, retainR, cur)
        local mode = Config.AimbotTargetPart or "Best"
        local pick = (mode == "Best") and "Head" or mode
        local prio = Config.AimbotPriority or "Crosshair"
        local vis  = Config.AimbotVisCheck
        local myRoot = nil
        if prio == "Distance" then
            local mc = lp.Character
            myRoot = mc and mc:FindFirstChild("HumanoidRootPart")
        end
        local bP, bPart, bAng, bScore = nil, nil, math.huge, math.huge
        local cPart, cAng, cOK = nil, math.huge, false
        for _, pl in ipairs(getSafePlayers()) do
            if pl ~= lp and validFor(pl) then
                local char = pl.Character
                local part = pickPart(char, pick)
                if part then
                    local ang    = angTo(cf, part.Position)
                    local isCur  = (pl == cur)
                    if ang <= (isCur and retainR or fovR) then
                        local hasVis = (not vis) or isVisible(part.Position)
                        if hasVis then
                            local score = ang
                            if prio == "Health" then
                                local hp = getHealth(pl)
                                score = hp * 100 + ang
                            elseif prio == "Distance" and myRoot then
                                score = (part.Position - myRoot.Position).Magnitude * 100 + ang
                            end
                            if isCur then
                                cPart, cAng, cOK = part, ang, true
                                score = score * (1 - (Config.AimbotStickiness or 0))
                            end
                            if score < bScore then bScore, bP, bPart, bAng = score, pl, part, ang end
                        end
                    end
                end
            end
        end
        if prio == "Crosshair" and cOK and bP and bP ~= cur then
            if bAng > cAng - (Config.AimbotSwitchDeg or 0) * D2R then
                return cur, cPart, cAng
            end
        end
        return bP, bPart, bAng
    end
    local function ensureDraw()
        pcall(function()
            if not _fovC then
                local c = screenDraw("Circle")
                if c then c.Thickness = 1; c.NumSides = 64; c.Color = Color3.fromRGB(180, 180, 180); c.Transparency = 0.6; c.Filled = false; c.Visible = false; _fovC = c end
            end
            if not _lockC then
                local c = screenDraw("Circle")
                if c then c.Thickness = 2; c.NumSides = 32; c.Color = Color3.fromRGB(255, 80, 100); c.Transparency = 0.9; c.Filled = false; c.Radius = 6; c.Visible = false; _lockC = c end
            end
            if not _dbgT then
                local t = screenDraw("Text")
                if t then t.Font = 3; t.Size = 13; t.Outline = true; t.Color = Color3.fromRGB(0, 230, 160); t.Position = Vector2.new(14, 330); t.Visible = false; _dbgT = t end
            end
        end)
    end
    local function diagText()
        return string.format("AIMBOT [MATH V2]  path=%s%s\ngain  x=%.6f (n%d)   y=%.6f (n%d)\nerr %.2f deg   sent %d,%d   auth %.2f   trips %d\ntarget %s", _path, _calOff and "  [gain PINNED]" or "", _gx, _nx, _gy, _ny, _errDeg, _sx, _sy, _auth, _trips, _tgt and _tgt.Name or "-")
    end
    local function updateDraw()
        local wantFov  = Config.Aimbot and Config.AimbotShowFOV
        local wantLock = Config.Aimbot and Config.AimbotShowLock and _part
        local wantDbg  = Config.Aimbot and Config.AimbotDebug
        if not (wantFov or wantLock or wantDbg) then
            if _fovC  and _fovC.Visible  then _fovC.Visible  = false end
            if _lockC and _lockC.Visible then _lockC.Visible = false end
            if _dbgT  and _dbgT.Visible  then _dbgT.Visible  = false end
            return
        end
        ensureDraw()
        if _fovC then
            if wantFov then
                local vp = Camera.ViewportSize
                _fovC.Position = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
                _fovC.Radius   = fovPixels(Config.AimbotFOVDeg or 20)
                _fovC.Visible  = true
            else _fovC.Visible = false end
        end
        if _lockC then
            local on = false
            if wantLock then
                local sp, vis = Camera:WorldToViewportPoint(_part.Position)
                if vis and sp.Z > 0 then _lockC.Position = Vector2.new(sp.X, sp.Y); on = true end
            end
            _lockC.Visible = on
        end
        if _dbgT then
            if wantDbg then _dbgT.Text = diagText(); _dbgT.Visible = true else _dbgT.Visible = false end
        end
    end
    local function resolvePath()
        local uis = UserInputService
        local touchOnly = uis.TouchEnabled and not uis.MouseEnabled
        if _mouseMove and not touchOnly then return "mouse" end
        if Config.AimbotDirectCamera or touchOnly then
            if not _ctlTried then
                _ctlTried = true
                task.spawn(function()
                    pcall(function()
                        local ps = lp:FindFirstChild("PlayerScripts")
                        local ctrls = ps and ps:FindFirstChild("Controllers")
                        local cMod = ctrls and ctrls:FindFirstChild("CameraController")
                        if cMod then
                            local m = require(cMod)
                            if type(m) == "table" and typeof(m.Rotation) == "Vector2" and type(m.ApplyRotationDelta) == "function" then
                                _ctl = m; _gx, _gy = SEED_DX, SEED_DY; _sdx, _sdy = SEED_DX, SEED_DY; _nx, _ny = 0, 0
                            end
                        end
                    end)
                end)
            end
            if _ctl then return "direct" end
        end
        return "none"
    end
    local function getSpringOffset()
        if not Config.AimbotCancelSprings then return 0, 0 end
        if _ctl then
            local s = rawget(_ctl, "_aim_spring") or rawget(_ctl, "_camera_rotation_spring")
            if s and typeof(s.Position) == "Vector2" then return s.Position.Y, s.Position.X
            elseif s and typeof(s.Position) == "Vector3" then return s.Position.X, s.Position.Y end
        end
        return 0, 0
    end
    local function quant(v, frac)
        local w = v + frac
        local n = (w >= 0) and math.floor(w + 0.5) or math.ceil(w - 0.5)
        return n, w - n
    end
    local function emit(ux, uy)
        if _path == "mouse" then pcall(_mouseMove, ux, uy)
        elseif _path == "direct" and _ctl then pcall(function() _ctl:ApplyRotationDelta(Vector2.new(uy, ux)) end) end
    end
    local function calibrate(obs, sent, gain, n, seed)
        if math.abs(sent) < CAL_MIN then return gain, n end
        local s = obs / sent
        if (s * seed) <= 0 then return gain, n end
        local a  = math.abs(s)
        local lo = math.abs(seed) * BAND_LO
        local hi = math.abs(seed) * BAND_HI
        if a < lo or a > hi then return gain, n end
        if n < CAL_FAST_N then return s, n + 1 end
        local r = math.abs(s / gain)
        if r < 0.34 or r > 3.0 then return gain, n end
        return gain + (s - gain) * 0.05, n + 1
    end
    local function clearTarget()
        _tgt, _part  = nil, nil
        _prevTgt     = nil
        _notified    = nil
        _haveTgt     = false
        _lastPartRef = nil
        _ffy, _ffp   = 0, 0
        _errDeg      = 0
        _flips, _errEma, _lastSign, _drive = 0, 0, nil, 0
        _flickActive = false
        State.AimbotTarget      = nil
        State.AimbotPart        = nil
        State.AimbotFlickActive = false
    end
    local function step(dt)
        dt = math.clamp(dt or (1 / 60), 1 / 1000, 0.1)
        local cf     = Camera.CFrame
        local look   = cf.LookVector
        local curYaw, curPit = yawOf(look), pitchOf(look)
        if _haveCam and not _calOff then
            _gx, _nx = calibrate(wrapPi(curYaw - _lyaw), _sx, _gx, _nx, _sdx)
            _gy, _ny = calibrate(curPit - _lpit, _sy, _gy, _ny, _sdy)
        end
        _lyaw, _lpit, _haveCam = curYaw, curPit, true
        local fov = Camera.FieldOfView
        if math.abs(fov - _lastFOV) > 0.5 then _lastFOV = fov; _nx, _ny = 0, 0 end
        _sx, _sy = 0, 0
        updateDraw()
        if not Config.Aimbot then
            State.AimbotKeyHeld = false
            clearTarget()
            return
        end
        local keyDown = isInputActive(Config.AimbotKey)
        State.AimbotKeyHeld = keyDown
        if not keyDown then
            clearTarget()
            return
        end
        _path = resolvePath()
        if _path == "none" then clearTarget(); return end
        
        local fovR    = math.clamp(Config.AimbotFOVDeg or 20, 0.1, 180) * D2R
        local retainR = math.min(fovR * RETAIN_MUL, math.pi)
        local sticky  = _tgt
        if not sticky then
            local last = State.AimbotLastTarget
            if last and (tick() - (State.AimbotLastTargetTime or 0)) <= STICKY_MEM then sticky = last end
        end
        local tgt, part = acquire(cf, fovR, retainR, sticky)
        
        if Config.TargetLockEnabled then
            local tlMode = Config.TargetLockMode or 'ToggleLock'
            if State.TargetLockTap then
                State.TargetLockTap = false
                if State.TargetLockTarget then State.TargetLockTarget = nil
                else State.TargetLockTarget = tgt end
            end
            local locked = State.TargetLockTarget
            if locked and not validFor(locked) then locked = nil; State.TargetLockTarget = nil end
            if locked then
                local pk = Config.AimbotTargetPart or "Best"
                if pk == "Best" then pk = "Head" end
                local lpart = pickPart(locked.Character, pk)
                if lpart then tgt, part = locked, lpart else State.TargetLockTarget = nil; locked = nil end
            end
            if not locked then
                if tlMode == 'ManualOnly' then tgt, part = nil, nil
                elseif tlMode == 'AutoLock' and tgt then State.TargetLockTarget = tgt end
            end
        else
            State.TargetLockTarget = nil
            State.TargetLockTap = false
        end

        local now = tick()
        if tgt and part then _lastSeenAt = now
        else
            local forget = Config.AimbotForgetTime or 0.2
            if _tgt and (now - _lastSeenAt) <= forget then tgt, part = _tgt, _part
            else clearTarget(); return end
        end
        
        if (Config.AimbotTargetPart or "Best") == "Best" then part = resolveBest(tgt.Character, part) or part end
        if tgt ~= _prevTgt then _acquireAt = now; _ramp = 0; _haveTgt = false; _ffy, _ffp = 0, 0; _prevTgt = tgt; _flickActive = false end
        
        _tgt, _part = tgt, part
        State.AimbotTarget         = tgt
        State.AimbotPart           = part
        State.AimbotLastTarget     = tgt
        State.AimbotLastTargetTime = now
        
        local targetPos = part.Position
        local targetChar = tgt.Character
        local targetRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        local targetVel = targetRP and targetRP.AssemblyLinearVelocity or Vector3.zero
        local myChar = lp.Character
        local myRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myVel = myRP and myRP.AssemblyLinearVelocity or Vector3.zero
        local vRel = targetVel - myVel
        if Config.AimbotPrediction then
            local lead = calculateLead(targetChar, cf.Position, true)
            targetPos = targetPos + lead
        end
        local d = targetPos - cf.Position
        local dDist = d.Magnitude
        if dDist < 1e-3 then return end
        local u = d / dDist
        local tYaw = yawOf(u)
        local tPit = math.clamp(pitchOf(u), -PITCH_LIMIT, PITCH_LIMIT)
        local errYaw = wrapPi(tYaw - curYaw)
        local errPit = tPit - curPit
        _errDeg = math.sqrt(errYaw * errYaw + errPit * errPit) * R2D
        
        local dH2 = d.X * d.X + d.Z * d.Z
        if _haveTgt and part == _lastPartRef and dH2 > 1e-4 then
            local vDotU = vRel:Dot(u)
            local dH = math.sqrt(dH2)
            local rawFFY = (d.Z * vRel.X - d.X * vRel.Z) / dH2
            local rawFFP = (vRel.Y - vDotU * u.Y) / dH
            local k = math.clamp(dt / FF_TAU, 0, 1)
            _ffy = _ffy + (math.clamp(rawFFY, -FF_MAX, FF_MAX) - _ffy) * k
            _ffp = _ffp + (math.clamp(rawFFP, -FF_MAX, FF_MAX) - _ffp) * k
        else _ffy, _ffp = 0, 0 end
        _lty, _ltp, _haveTgt, _lastPartRef = tYaw, tPit, true, part
        
        if (Config.AimbotReactionMs or 0) > 0 and (now - _acquireAt) * 1000 < Config.AimbotReactionMs then return end
        if (Config.AimbotDeadzoneDeg or 0) > 0 then
            local m = math.sqrt(errYaw * errYaw + errPit * errPit)
            if m < Config.AimbotDeadzoneDeg * D2R then return end
        end
        
        local smoothX = Config.AimbotLinkAxes and (Config.AimbotSmoothness or 0) or (Config.AimbotSmoothnessX or 0)
        local smoothY = Config.AimbotLinkAxes and (Config.AimbotSmoothness or 0) or (Config.AimbotSmoothnessY or 0)
        smoothX = math.clamp(smoothX, 0, 100); smoothY = math.clamp(smoothY, 0, 100)
        
        local isHardLock = (smoothX == 0 and smoothY == 0)
        local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
        local isAirborne = (targetHum and targetHum.FloorMaterial == Enum.Material.Air) or math.abs(targetVel.Y) > 5
        if isAirborne and (Config.AimbotJumpDamping or 0) > 0 and smoothY > 0 then
            local jDamp = (Config.AimbotJumpDamping / 100)
            local vyFrac = math.clamp(math.abs(targetVel.Y) / 60, 0, 1)
            smoothY = math.clamp(smoothY + (100 - smoothY) * vyFrac * jDamp, 0, 100)
        end
        local aErr = math.sqrt(errYaw * errYaw + errPit * errPit)
        _errEma = _errEma + (aErr - _errEma) * math.clamp(dt / 0.15, 0, 1)
        _drive  = _drive + dt
        local sPos = (errYaw >= 0)
        if _lastSign ~= nil and sPos ~= _lastSign then _flips = _flips + 1 end
        _lastSign = sPos
        _flips = _flips * math.exp(-dt / 0.25)
        if _flips >= 4 and _errEma > OSC_ERR and not isHardLock then
            _auth  = math.max(0.15, _auth * 0.5); _flips = 0
        else _auth = math.min(1, _auth + dt * 0.3) end
        
        local avgSmooth = (smoothX + smoothY) * 0.5
        if _errEma > RUNAWAY_ERR and _drive > (0.15 + (avgSmooth / 100) * MAX_TAU * 3) and not isHardLock then
            _auth    = math.max(0.08, _auth * 0.5); _gx, _gy = _sdx, _sdy; _nx, _ny = 0, 0; _drive   = 0; _trips   = _trips + 1
            if _trips >= 2 then _calOff = true end
        end
        
        local alphaX = 1
        if smoothX > 0 then alphaX = (1 - math.exp(-dt / ((smoothX / 100) * MAX_TAU))) * _auth end
        local alphaY = 1
        if smoothY > 0 then alphaY = (1 - math.exp(-dt / ((smoothY / 100) * MAX_TAU))) * _auth end
        
        local cy = errYaw * alphaX
        local cp = errPit * alphaY
        
        if Config.AimbotCurvedFlick and _errDeg > 3.0 and not isHardLock then
            if not _flickActive then
                _flickActive = true; _flickT = 0
                _flickDur = math.clamp((_errDeg / 90) * 0.22 + 0.08, 0.08, 0.35)
                local intensity = (Config.AimbotCurvedIntensity or 0.35) * (_errDeg * D2R)
                local normY, normP = -errPit / (aErr + 1e-4), errYaw / (aErr + 1e-4)
                local curveSign = ((math.floor(now * 10) % 2 == 0) and 1 or -1)
                _flickCtrl1Y = normY * intensity * curveSign; _flickCtrl1P = normP * intensity * curveSign
                _flickCtrl2Y = normY * (intensity * 0.7) * curveSign; _flickCtrl2P = normP * (intensity * 0.7) * curveSign
            end
            _flickT = math.min(_flickDur, _flickT + dt)
            local prog = _flickT / _flickDur
            local sJerk = minJerk(prog)
            local p1Y = errYaw * 0.33 + _flickCtrl1Y
            local p1P = errPit * 0.33 + _flickCtrl1P
            local p2Y = errYaw * 0.66 + _flickCtrl2Y
            local p2P = errPit * 0.66 + _flickCtrl2P
            cy = bezier(0, p1Y, p2Y, errYaw, sJerk) * alphaX
            cp = bezier(0, p1P, p2P, errPit, sJerk) * alphaY
            if prog >= 1.0 or _errDeg < 1.0 then _flickActive = false end
        else _flickActive = false end
        State.AimbotFlickActive = _flickActive
        
        if not isHardLock then
            local spPit, spYaw = getSpringOffset()
            cy = cy - (spYaw * alphaX)
            cp = cp - (spPit * alphaY)
        end
        local os = Config.AimbotOvershoot or 0
        if os > 0 and not isHardLock then
            _ramp = math.min(1, _ramp + dt / RAMP_TIME)
            local k = 1 + math.sin(_ramp * math.pi) * os
            cy, cp = cy * k, cp * k
        end
        local ff = (Config.AimbotTrackAssist or 100) / 100
        if ff > 0 and not isHardLock then cy = cy + _ffy * dt * ff; cp = cp + _ffp * dt * ff end
        
        local nz = Config.AimbotNoiseDeg or 0
        if nz > 0 then
            local n = nz * D2R * dt
            cy = cy + (math.random() - 0.5) * 2 * n
            cp = cp + (math.random() - 0.5) * 2 * n
        end
        local cap = Config.AimbotMaxSpeed or 0
        if cap > 0 then
            local m = math.sqrt(cy * cy + cp * cp)
            local lim = cap * D2R * dt
            if m > lim then local k = lim / m; cy, cp = cy * k, cp * k end
        end
        cp = math.clamp(curPit + cp, -PITCH_LIMIT, PITCH_LIMIT) - curPit
        if _gx == 0 or _gy == 0 then return end
        local ux, uy = cy / _gx, cp / _gy
        local um = math.max(math.abs(ux), math.abs(uy))
        if um > UNIT_MAX then local k = UNIT_MAX / um; ux, uy = ux * k, uy * k end
        if _path == "mouse" then ux, _fx = quant(ux, _fx); uy, _fy = quant(uy, _fy)
        else _fx, _fy = 0, 0 end
        if ux == 0 and uy == 0 then return end
        emit(ux, uy)
        _sx, _sy = ux, uy
    end

    function Aimbot.enable()
        Config.Aimbot = true
        if _bound then return end
        RunService:BindToRenderStep("LuaHook_Aimbot", Enum.RenderPriority.Camera.Value + 1, function(dt)
            pcall(step, dt)
        end)
        _bound = true
    end
    function Aimbot.disable()
        Config.Aimbot = false
        State.AimbotKeyHeld = false
        clearTarget()
        _sx, _sy, _fx, _fy = 0, 0, 0, 0
        _haveCam, _ramp, _notified = false, 0, nil
        _auth = 1.0
        if _bound then
            pcall(function() RunService:UnbindFromRenderStep("LuaHook_Aimbot") end)
            _bound = false
        end
        if _fovC  then _fovC.Visible  = false end
        if _lockC then _lockC.Visible = false end
        if _dbgT  then _dbgT.Visible  = false end
    end
    function Aimbot.init()
        if Config.Aimbot then Aimbot.enable() end
    end
end)()

-- =========================================================
-- TRIGGERBOT MODULE (Extracted from File 2)
-- =========================================================
local Trigger = {}
do
    local _bound    = false
    local _lastFire = 0
    local _onTgtAt  = 0
    local _lastChar = nil
    local trigParams = RaycastParams.new()
    trigParams.FilterType = Enum.RaycastFilterType.Exclude
    local _filterChar = nil
    
    local function isHeadHit(part)
        if not part then return false end
        local n = part.Name
        for _, h in ipairs(HEAD_PARTS) do
            if n == h then return true end
        end
        return false
    end
    local function fullyScoped()
        local lf = lp.PlayerScripts:FindFirstChild("Controllers"):FindFirstChild("FighterController")
        local it = lf and require(lf).LocalFighter and require(lf).LocalFighter.EquippedItem
        if not it then return true end
        local cur, pct = nil, nil
        pcall(function() cur = it.ViewModel.CurrentAimValue end)
        pcall(function() pct = it.Info.AimScopePercent end)
        if type(cur) == "number" then
            if type(pct) == "number" then return cur >= pct end
            return cur >= 1
        end
        local aiming
        pcall(function() aiming = it:Get("IsAiming") end)
        if aiming == nil then return true end
        return aiming == true
    end
    local function askToShoot()
        local lf = lp.PlayerScripts:FindFirstChild("Controllers"):FindFirstChild("FighterController")
        if not lf then return end
        task.spawn(function()
            if pcall(function() require(lf).LocalFighter:Input("StartShooting") end) then return end
            local g = getthreadidentity or get_thread_identity
            local s = setthreadidentity or set_thread_identity or setidentity
            if type(s) ~= "function" then return end
            local prev
            if type(g) == "function" then local okP, p = pcall(g); if okP then prev = p end end
            pcall(s, 2)
            pcall(function() require(lf).LocalFighter:Input("StartShooting") end)
            pcall(s, prev or 2)
        end)
    end
    local function underCrosshair()
        local c = lp.Character
        if c ~= _filterChar then
            trigParams.FilterDescendantsInstances = { c }
            _filterChar = c
        end
        local cf   = Camera.CFrame
        local dist = math.clamp(Config.TriggerMaxDist or 400, 1, 400)
        local res  = Workspace:Raycast(cf.Position, cf.LookVector * dist, trigParams)
        if not res or not res.Instance then return nil end
        local model = res.Instance:FindFirstAncestorOfClass("Model")
        if not model then return nil end
        local pl = Players:GetPlayerFromCharacter(model)
        if not pl or pl == lp then return nil end
        return pl, res.Instance
    end
    local function step()
        if not Config.Trigger then return end
        if not isInputActive(Config.TriggerKey) then
            _lastChar = nil
            return
        end
        local pl, hit = underCrosshair()
        if not pl then
            _lastChar = nil
            return
        end
        if not isValidTarget(pl, false) then
            _lastChar = nil
            return
        end
        if Config.TriggerHeadOnly and not isHeadHit(hit) then
            _lastChar = nil
            return
        end
        if Config.TriggerScopeCheck and not fullyScoped() then
            _lastChar = nil
            return
        end
        local now = tick()
        if pl.Character ~= _lastChar then
            _lastChar = pl.Character
            _onTgtAt  = now
        end
        if (now - _onTgtAt) * 1000 < (Config.TriggerDelayMs or 0) then return end
        if (now - _lastFire) * 1000 < (Config.TriggerRefireMs or 0) then return end
        _lastFire = now
        askToShoot()
    end
    function Trigger.enable()
        Config.Trigger = true
        if _bound then return end
        RunService:BindToRenderStep("LuaHook_Trigger", Enum.RenderPriority.Camera.Value + 2, function()
            pcall(step)
        end)
        _bound = true
    end
    function Trigger.disable()
        Config.Trigger = false
        _lastChar = nil
        _lastFire = 0
        _onTgtAt  = 0
        if not _bound then return end
        pcall(function() RunService:UnbindFromRenderStep("LuaHook_Trigger") end)
        _bound = false
    end
    function Trigger.init()
        if Config.Trigger then Trigger.enable() end
    end
end

-- =========================================================
-- FAKE UNDERGROUND MODULE (Extracted from File 2)
-- =========================================================
local FU = { on = false, depth = 5.8, walk = true, hide = true, camera = false, orbit = false, noclip = true,
             panic = false, pMin = -5, pMax = 5, pZ = false, anim = true, zeroVel = true,
             virtualCF = nil, saved = nil, track = nil, hb = nil, alive = true,
             rage = false, radius = 14, speed = 4, rate = 0.1, slot = 'Primary', maxDist = 400, team = true,
             ang = 0, target = nil, nextPick = 0, lastShot = 0, localCF = nil, status = nil }

local function hideChar()
    local char = lp.Character
    if not char then return end
    FU.saved = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA('BasePart') or part:IsA('Decal') then
            FU.saved[#FU.saved + 1] = { part = part, t = part.Transparency }
            pcall(function() part.Transparency = 1 end)
        end
    end
end
local function showChar()
    if not FU.saved then return end
    for _, d in ipairs(FU.saved) do
        if d.part and d.part.Parent then pcall(function() d.part.Transparency = d.t end) end
    end
    FU.saved = nil
end
local function startAnim()
    local hum = lp.Character and lp.Character:FindFirstChildOfClass('Humanoid')
    if not hum or FU.track then return end
    pcall(function()
        local a = Instance.new('Animation')
        a.AnimationId = 'rbxassetid://10714003221'
        local t = hum:LoadAnimation(a)
        t:Play(0, 1, 0)
        t.TimePosition = 1.48
        FU.track = t
    end)
end
local function stopAnim()
    if FU.track then
        pcall(function() FU.track:Stop(); FU.track:Destroy() end)
        FU.track = nil
    end
end

local RS_ = game:GetService('ReplicatedStorage')
local mods, modErr = nil, nil
local function getMods()
    if mods then return mods end
    local ok, res = pcall(function()
        return {
            util = require(RS_.Modules.Utility),
            enumLib = require(RS_.Modules.EnumLibrary),
            FC = require(lp.PlayerScripts.Controllers.FighterController),
        }
    end)
    if ok then mods = res; modErr = nil else modErr = tostring(res) end
    return mods
end
local SLOT_IDX = { Primary = 1, Secondary = 2, Melee = 3 }
local function validTarget(plr, myPos)
    if plr == lp then return nil end
    if FU.team and plr.Team ~= nil and plr.Team == lp.Team then return nil end
    local ch = plr.Character
    local root = ch and ch:FindFirstChild('HumanoidRootPart')
    local head = ch and ch:FindFirstChild('Head')
    local hum = ch and ch:FindFirstChildOfClass('Humanoid')
    if not (root and head and hum) or hum.Health <= 0 then return nil end
    if root.Position.Y < -500 or root.Position.Y > 2000 then return nil end
    local d = (root.Position - myPos).Magnitude
    if d > FU.maxDist then return nil end
    return root, head, d
end
local function pickTarget(myPos)
    local cur = FU.target
    if cur and cur.plr and cur.plr.Parent then
        local root, head = validTarget(cur.plr, myPos)
        if root then cur.root, cur.head = root, head; return cur end
    end
    local best, bestD = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        local root, head, d = validTarget(plr, myPos)
        if root and d < bestD then bestD = d; best = { plr = plr, root = root, head = head } end
    end
    FU.target = best
    return best
end
local function shootAt(head, fromPos)
    local m = getMods()
    if not m then return false end
    local lf = m.FC.LocalFighter
    if not lf then return false end
    if lf.EquippedItem == nil then
        pcall(function() lf:EquipItem(SLOT_IDX[FU.slot] or 1) end)
        return false
    end
    local hp = head.Position
    local aimCF = CFrame.lookAt(fromPos + Vector3.new(0, 1.5, 0), hp)
    local objSpace = head.CFrame:ToObjectSpace(CFrame.new(hp))
    local data = {}
    data[utf8.char(1)] = {
        [utf8.char(0)] = m.util:EncodeCFrame(aimCF),
        [utf8.char(1)] = m.util:EncodeCFrame(head.CFrame),
        [utf8.char(2)] = head,
        [utf8.char(3)] = m.util:EncodeCFrame(objSpace),
    }
    return pcall(function()
        RS_.Remotes.Replication.Fighter.UseItem:FireServer(
            lf.EquippedItem:Get('ObjectID'), m.enumLib:ToEnum('StartShooting'), data, nil)
    end)
end

local function turnOff()
    FU.on = false
    FU.localCF = nil; FU.target = nil
    pcall(function() RunService:UnbindFromRenderStep('FU_OrbitUndo') end)
    if FU.hb then FU.hb:Disconnect(); FU.hb = nil end
    pcall(function() RunService:UnbindFromRenderStep('FU_SurfaceCamera') end)
    showChar(); stopAnim()
    local hrp = lp.Character and lp.Character:FindFirstChild('HumanoidRootPart')
    if hrp and FU.virtualCF then
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = FU.virtualCF
        end)
    end
    FU.virtualCF = nil
end

local function turnOn()
    FU.on = true
    local hrp = lp.Character and lp.Character:FindFirstChild('HumanoidRootPart')
    if hrp then FU.virtualCF = hrp.CFrame end
    if FU.hide then hideChar() end
    if FU.anim then startAnim() end
    pcall(function() RunService:UnbindFromRenderStep('FU_SurfaceCamera') end)
    RunService:BindToRenderStep('FU_SurfaceCamera', 201, function()
        if FU.on and FU.camera then
            local cam = workspace.CurrentCamera
            if cam and FU.depth > 0 then cam.CFrame = cam.CFrame + Vector3.new(0, FU.depth, 0) end
        end
    end)
    pcall(function() RunService:UnbindFromRenderStep('FU_OrbitUndo') end)
    RunService:BindToRenderStep('FU_OrbitUndo', Enum.RenderPriority.Camera.Value - 1, function()
        if FU.on and FU.localCF then
            local h = lp.Character and lp.Character:FindFirstChild('HumanoidRootPart')
            if h then h.CFrame = FU.localCF end
        end
    end)
    FU.hb = RunService.Heartbeat:Connect(function(dt)
        if not FU.on then return end
        local char = lp.Character
        local hrp2 = char and char:FindFirstChild('HumanoidRootPart')
        local hum = char and char:FindFirstChildOfClass('Humanoid')
        if not hrp2 or not hum then return end
        local cam = workspace.CurrentCamera
        local look = cam and cam.CFrame.LookVector or Vector3.new(0, 0, -1)
        local rot = CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0)
        if not FU.virtualCF then FU.virtualCF = CFrame.new(hrp2.Position) * rot end
        local pos = FU.virtualCF.Position
        if FU.walk and hum.MoveDirection.Magnitude > 0 then
            pos = pos + hum.MoveDirection * (hum.WalkSpeed * dt)
        end
        FU.virtualCF = CFrame.new(pos) * rot
        local under = pos - Vector3.new(0, FU.depth, 0)
        if FU.panic then
            local lo, hi = math.min(FU.pMin, FU.pMax), math.max(FU.pMin, FU.pMax)
            under = under + Vector3.new(lo + math.random() * (hi - lo), 0, FU.pZ and (math.random() - 0.5) * (hi - lo) or 0)
        end
        if FU.noclip then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA('BasePart') and p.CanCollide then p.CanCollide = false end
            end
        end
        if FU.zeroVel then
            hrp2.AssemblyLinearVelocity = Vector3.zero
            hrp2.AssemblyAngularVelocity = Vector3.zero
        end
        local localCF = CFrame.new(under) * rot
        FU.localCF = nil
        if FU.rage then
            local tgt = pickTarget(pos)
            if tgt and not FU.orbit then
                FU.localCF = nil
                hrp2.CFrame = localCF
                FU.status = 'shooting from under ' .. tostring(tgt.plr.Name)
                if tick() - FU.lastShot >= FU.rate then
                    FU.lastShot = tick()
                    shootAt(tgt.head, localCF.Position)
                end
            elseif tgt then
                FU.ang = (FU.ang + FU.speed * dt) % (math.pi * 2)
                local tp = tgt.root.Position
                local orbit = Vector3.new(tp.X + math.cos(FU.ang) * FU.radius, tp.Y - FU.depth, tp.Z + math.sin(FU.ang) * FU.radius)
                local yaw = CFrame.new(orbit) * CFrame.Angles(0, math.atan2(-(tp.X - orbit.X), -(tp.Z - orbit.Z)), 0)
                FU.localCF = localCF
                hrp2.CFrame = yaw
                FU.status = 'orbiting ' .. tostring(tgt.plr.Name)
                if tick() - FU.lastShot >= FU.rate then
                    FU.lastShot = tick()
                    shootAt(tgt.head, orbit)
                end
            else
                FU.status = 'no target'
                hrp2.CFrame = localCF
            end
        else
            hrp2.CFrame = localCF
        end
        if FU.hide and FU.saved then
            for _, d in ipairs(FU.saved) do
                if d.part and d.part.Parent and d.part.Transparency ~= 1 then
                    pcall(function() d.part.Transparency = 1 end)
                end
            end
        end
    end)
end
lp.CharacterAdded:Connect(function()
    if FU.on then
        task.wait(1)
        turnOff(); turnOn()
    end
end)
pcall(function() Library:OnUnload(function() FU.alive = false; if FU.on then turnOff() end end) end)


-- =========================================================
-- ESP CORE MODULE
-- =========================================================
local function hpRamp(frac)
    local stops = {
        { 0.00, Color3.fromRGB(255, 68, 54) }, { 0.20, Color3.fromRGB(255, 122, 61) },
        { 0.40, Color3.fromRGB(255, 194, 75) }, { 0.60, Color3.fromRGB(196, 226, 78) },
        { 1.00, Color3.fromRGB(61, 224, 122) },
    }
    frac = math.clamp(frac or 0, 0, 1)
    for i = 1, #stops - 1 do
        local a, b = stops[i], stops[i + 1]
        if frac <= b[1] then
            local t = (frac - a[1]) / (b[1] - a[1])
            return a[2]:Lerp(b[2], math.clamp(t, 0, 1))
        end
    end
    return stops[#stops][2]
end

local ESP = {}
;(function()
    local hasDrawing = DrawingAPI ~= nil
    local _renderConn, _espFrame, _lastRenderT = nil, 0, 0
    local _bboxCache, _bboxFrameN, _ctx, _renderArr = {}, {}, {}, {}
    local BLACK, WHITE = Color3.new(0,0,0), Color3.new(1,1,1)
    local INK, HPBG = Color3.fromRGB(4,6,10), Color3.fromRGB(11,15,22)
    local HP_W, HP_GAP, PAD, FLAG_GAP = 3, 5, 5, 6
    local BASE_H, MIN_W, MIN_H = 1080, 8, 13
    local BOX_W_STUDS, BOX_H_STUDS = 4 * 1000 / 1080, 6.5 * 1000 / 1080
    local TEXT_FLOOR, DIST_MIN_MUL = 8, 0.5
    local cam = Camera
    
    local FACES = {}
    for _, n in ipairs({"Code", "RobotoMono", "Gotham", "GothamBold", "Arial", "SourceSans"}) do
        pcall(function() FACES[n] = Enum.Font[n] end)
    end
    if not FACES.Code then FACES.Code = Enum.Font.SourceSans end
    local _customFaces = {}
    local function faceFor(name) return _customFaces[name] or FACES[name] or FACES.Code end
    local function typePx(base, scale) return math.max(math.floor(base * scale + 0.5), TEXT_FLOOR) end
    local function distMul(dist) 
        if not Config.ESPDistanceScaling then return 1 end 
        return math.clamp((Config.ESPDistanceScalingRef or 50) / math.max(dist or 1, 1), DIST_MIN_MUL, 1)
    end
    local function sizeFor(base, mul) return math.max(math.floor(base * (mul or 1) + 0.5), TEXT_FLOOR) end
    
    local function styleLabel(t, face, size, casing)
        if typeof(face) == "EnumItem" then t.Font = face else t.FontFace = face end
        t.TextSize = size
        local st = t:FindFirstChildOfClass("UIStroke")
        if st then st.Thickness = casing or 2; st.Enabled = (casing or 2) > 0 end
    end
    
    local _seqCache = {}
    local function gradSeq(key, a, b)
        if not a or not b then return nil end
        local s = _seqCache[key]
        if s and s.a == a and s.b == b then return s.seq end
        local seq = ColorSequence.new({ ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(0.5, b), ColorSequenceKeypoint.new(1, a) })
        _seqCache[key] = { a = a, b = b, seq = seq }
        return seq
    end
    
    local function paint(inst, prop, key, mode, solid, ga, gb, rot, spin, now)
        if not inst then return end
        if mode == "Gradient" then
            local seq = gradSeq(key, ga, gb)
            if seq then
                if inst[prop] ~= WHITE then inst[prop] = WHITE end
                local ug = inst:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient", inst)
                ug.Color = seq
                local r = rot or 0
                if spin and spin > 0 then r = (r + (now or 0) * spin * 360) % 360 end
                ug.Rotation = r
                ug.Enabled = true
                return
            end
        end
        local ug = inst:FindFirstChildOfClass("UIGradient")
        if ug and ug.Enabled then ug.Enabled = false end
        if inst[prop] ~= (solid or WHITE) then inst[prop] = solid or WHITE end
    end
    
    local function healthColor(frac)
        local mode = Config.ESPHealthColorMode or "Ramp"
        if mode == "Solid" then return Config.ESPHealthColor end
        if mode == "Gradient" then return WHITE end
        return hpRamp(frac)
    end

    local FLAG_COLORS = {
        STARING = Color3.fromRGB(255, 70, 85), DEFLECT = Color3.fromRGB(53, 215, 199),
        SHIELD = Color3.fromRGB(255, 194, 75), INVINCIBLE = Color3.fromRGB(255, 215, 0),
        LOW = Color3.fromRGB(255, 90, 100),
    }

    local _gui, _absLayer = nil, nil
    local function mkFrame(parent, z)
        local f = Instance.new("Frame")
        f.BackgroundTransparency = 1; f.BorderSizePixel = 0; f.ZIndex = z or 1; f.Parent = parent
        return f
    end
    local function mkLabel(parent, z, align)
        local t = Instance.new("TextLabel")
        t.BackgroundTransparency = 1; t.BorderSizePixel = 0; t.RichText = true
        t.TextXAlignment = align or Enum.TextXAlignment.Center
        t.AutomaticSize = Enum.AutomaticSize.XY; t.Size = UDim2.fromOffset(0, 0)
        t.ZIndex = z or 3; t.TextColor3 = WHITE
        local st = Instance.new("UIStroke")
        st.Color = BLACK; st.Thickness = 1; st.Transparency = 0; st.LineJoinMode = Enum.LineJoinMode.Round; st.Parent = t
        t.Parent = parent
        return t
    end
    local function mkList(parent, z, pad, hAlign, vAlign)
        local f = mkFrame(parent, z)
        f.AutomaticSize = Enum.AutomaticSize.XY; f.Size = UDim2.fromOffset(0, 0)
        local l = Instance.new("UIListLayout")
        l.FillDirection = Enum.FillDirection.Vertical; l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Padding = UDim.new(0, pad or 2)
        l.HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Center
        l.VerticalAlignment = vAlign or Enum.VerticalAlignment.Top
        l.Parent = f
        return f
    end
    local function mkRing(parent, z, colour, thick)
        local f = mkFrame(parent, z)
        f.AnchorPoint = Vector2.new(0.5, 0.5); f.Position = UDim2.fromScale(0.5, 0.5); f.Size = UDim2.fromScale(1, 1)
        local s = Instance.new("UIStroke")
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.LineJoinMode = Enum.LineJoinMode.Miter
        s.Color = colour; s.Thickness = thick; s.Transparency = 0; s.Parent = f
        return f, s
    end
    local function mkCasedRect(parent, z)
        local box = mkFrame(parent, z); box.Size = UDim2.fromScale(1, 1)
        local rIn, sIn = mkRing(box, z+1, INK, 1)
        local rMid, sMid = mkRing(box, z+2, WHITE, 1)
        local rOut, sOut = mkRing(box, z+1, INK, 1)
        return box, sMid, sOut, sIn, rMid, rOut, rIn
    end
    local function espGui()
        if _gui and _gui.Parent then return _gui end
        local g = Instance.new("ScreenGui")
        g.Name = "\0" .. tostring(math.random(1e5, 1e6))
        g.IgnoreGuiInset = true; g.ResetOnSpawn = false; g.DisplayOrder = 99990; g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        local parent = gethui and gethui() or game:GetService("CoreGui") or lp:FindFirstChildOfClass("PlayerGui")
        g.Parent = parent
        _gui = g
        _absLayer = mkFrame(g, 1); _absLayer.Size = UDim2.fromScale(1,1)
        return _gui
    end
    
    local function buildTree(o)
        local u = {}
        local root = mkFrame(espGui(), 2); root.Visible = false; root.Size = UDim2.fromOffset(MIN_W, MIN_H)
        u.root = root
        u.fill = mkFrame(root, 2); u.fill.Size = UDim2.fromScale(1, 1); u.fill.Visible = false
        u.box, u.boxStroke, u.caseOut, u.caseIn, u.ringMid, u.ringOut, u.ringIn = mkCasedRect(root, 3); u.box.Visible = false
        u.corners = {}
        for i = 1, 8 do
            local c = mkFrame(root, 6); c.BackgroundTransparency = 0; c.BackgroundColor3 = WHITE; c.Visible = false
            local cs = Instance.new("UIStroke"); cs.Color = INK; cs.Thickness = 1; cs.Parent = c
            u.corners[i] = c
        end
        local hp = mkFrame(root, 4); hp.AnchorPoint = Vector2.new(1, 0); hp.Position = UDim2.new(0, -HP_GAP, 0, 0); hp.Size = UDim2.new(0, HP_W, 1, 0); hp.BackgroundColor3 = HPBG; hp.Visible = false
        local hs = Instance.new("UIStroke"); hs.Color = INK; hs.Thickness = 1; hs.Parent = hp
        u.hp = hp
        u.hpGhost = mkFrame(hp, 5); u.hpGhost.BackgroundTransparency = 0; u.hpGhost.BackgroundColor3 = WHITE; u.hpGhost.AnchorPoint = Vector2.new(0, 1); u.hpGhost.Position = UDim2.fromScale(0, 1); u.hpGhost.Visible = false
        u.hpFill = mkFrame(hp, 6); u.hpFill.BackgroundTransparency = 0; u.hpFill.BackgroundColor3 = WHITE; u.hpFill.AnchorPoint = Vector2.new(0, 1); u.hpFill.Position = UDim2.fromScale(0, 1); u.hpFill.Size = UDim2.fromScale(1, 1)
        u.hpNum = mkLabel(root, 7, Enum.TextXAlignment.Right); u.hpNum.AnchorPoint = Vector2.new(1, 0); u.hpNum.Position = UDim2.new(0, -HP_GAP - HP_W - 3, 0, 0); u.hpNum.Visible = false
        u.head = mkList(root, 7, 2, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Bottom); u.head.AnchorPoint = Vector2.new(0.5, 1); u.head.Position = UDim2.new(0.5, 0, 0, -PAD); u.head.Visible = false
        u.name = mkLabel(u.head, 8); u.name.LayoutOrder = 1
        u.under = mkFrame(u.head, 8); u.under.LayoutOrder = 2; u.under.BackgroundTransparency = 0; u.under.BackgroundColor3 = WHITE; u.under.Size = UDim2.fromOffset(0, 2); u.under.Visible = false
        u.foot = mkList(root, 7, 2, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top); u.foot.AnchorPoint = Vector2.new(0.5, 0); u.foot.Position = UDim2.new(0.5, 0, 1, PAD); u.foot.Visible = false
        u.info = mkLabel(u.foot, 8); u.info.LayoutOrder = 1; u.info.Visible = false
        u.ammo = mkFrame(u.foot, 8); u.ammo.LayoutOrder = 2; u.ammo.BackgroundColor3 = HPBG; u.ammo.Size = UDim2.fromOffset(28, 3); u.ammo.Visible = false
        local as = Instance.new("UIStroke"); as.Color = INK; as.Thickness = 1; as.Parent = u.ammo
        u.ammoFill = mkFrame(u.ammo, 9); u.ammoFill.BackgroundColor3 = WHITE; u.ammoFill.Size = UDim2.fromScale(1, 1)
        u.flags = mkList(root, 7, 3, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top); u.flags.AnchorPoint = Vector2.new(0, 0); u.flags.Position = UDim2.new(1, FLAG_GAP, 0, 0); u.flags.Visible = false
        u.chips = {}
        for i = 1, 5 do u.chips[i] = mkLabel(u.flags, 8, Enum.TextXAlignment.Left); u.chips[i].LayoutOrder = i; u.chips[i].Visible = false end
        u.chev = mkLabel(root, 9); u.chev.AnchorPoint = Vector2.new(0.5, 1); u.chev.Text = "▼"; u.chev.Visible = false
        u.pulse = mkFrame(root, 1); u.pulse.AnchorPoint = Vector2.new(0.5, 0.5); u.pulse.Position = UDim2.fromScale(0.5, 0.5); u.pulse.Visible = false
        local ps = Instance.new("UIStroke"); ps.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ps.Thickness = 2; ps.Color = WHITE; ps.Parent = u.pulse
        u.pulseStroke = ps
        
        u.skel = {}
        u.tracer = mkFrame(_absLayer, 2); u.tracer.AnchorPoint = Vector2.new(0.5, 0.5); u.tracer.BackgroundColor3 = WHITE; u.tracer.Visible = false
        u.look = mkFrame(_absLayer, 2); u.look.AnchorPoint = Vector2.new(0.5, 0.5); u.look.BackgroundColor3 = WHITE; u.look.Visible = false
        u.dot = mkFrame(_absLayer, 3); u.dot.AnchorPoint = Vector2.new(0.5, 0.5); u.dot.BackgroundColor3 = WHITE; u.dot.Visible = false
        local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = u.dot
        local ds = Instance.new("UIStroke"); ds.Color = INK; ds.Thickness = 1; ds.Parent = u.dot
        return u
    end
    
    local function destroyTree(o)
        local u = o.ui; if not u then return end
        pcall(function() u.root:Destroy() end); pcall(function() u.tracer:Destroy() end); pcall(function() u.look:Destroy() end); pcall(function() u.dot:Destroy() end)
        if u.skel then for i = 1, #u.skel do pcall(function() u.skel[i]:Destroy() end) end end
        o.ui = nil
    end
    
    local function ensureCham(o, char)
        local hl = o.cham
        if hl == nil then
            hl = Instance.new("Highlight"); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Enabled = false; hl.Parent = char; o.cham = hl
        elseif hl and hl.Parent ~= char then
            pcall(function() hl.Parent = char end)
        end
        return o.cham
    end
    
    local function cleanESP(p)
        local o = State.ESPObjects[p]; if not o then return end
        destroyTree(o)
        if o.cham and o.cham.Parent then pcall(function() o.cham:Destroy() end) end
        _bboxCache[p], _bboxFrameN[p], State.ESPObjects[p] = nil, nil, nil
    end
    
    local function buildESP(player)
        if player == lp then return end
        cleanESP(player)
        local char = player.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local isR6 = (hum and hum.RigType == Enum.HumanoidRigType.R6) or (char:FindFirstChild("Torso") ~= nil)
        local rig = isR6 and {
            {"Head","Torso"}, {"Torso","Left Arm"}, {"Torso","Right Arm"}, {"Torso","Left Leg"}, {"Torso","Right Leg"},
        } or {
            {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
            {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
            {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
            {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
        }
        local bones = {}
        for i, pair in ipairs(rig) do bones[i] = { a = char:FindFirstChild(pair[1]), b = char:FindFirstChild(pair[2]) } end
        local o = { drawings = {}, root = root, rig = rig, bones = bones, _fadeT = tick() }
        o.ui = buildTree(o)
        State.ESPObjects[player] = o
    end
    
    local function bbox(char, player)
        local frame = _bboxFrameN[player] or -999
        if (_espFrame - frame) < 1 then
            local c = _bboxCache[player]; if c then return c[1], c[2], c[3], c[4] end; return nil
        end
        _bboxFrameN[player] = _espFrame; _bboxCache[player] = nil
        local ok, pivot = pcall(function() return char:GetPivot().Position end)
        if not ok or pivot == nil then return nil end
        local sp = cam:WorldToViewportPoint(pivot)
        local depth = sp.Z; if depth <= 0.5 then return nil end
        local vpY = _ctx.vp and _ctx.vp.Y or 1080
        local tanHalf = math.tan(math.rad(cam.FieldOfView) * 0.5)
        if tanHalf <= 0 then return nil end
        local scale = vpY / (2 * depth * tanHalf)
        local bs = Config.ESPBoxScale or 1
        local rawW, rawH = BOX_W_STUDS * scale * bs, BOX_H_STUDS * scale * bs
        if rawH > 4000 or rawW > 3000 then return nil end
        local x, y = math.floor(sp.X - rawW * 0.5), math.floor(sp.Y - rawH * 0.5)
        local bw, bh = math.floor(math.max(MIN_W, rawW)), math.floor(math.max(MIN_H, rawH))
        _bboxCache[player] = { x, y, x + bw, y + bh }
        return x, y, x + bw, y + bh
    end
    
    local function hideTree(o)
        local u = o.ui; if not u then return end
        u.root.Visible = false; u.tracer.Visible = false; u.look.Visible = false; u.dot.Visible = false
        if u.skel then for i = 1, #u.skel do u.skel[i].Visible = false end end
    end
    local function hideDrawings(o) for _, d in ipairs(o.drawings or {}) do d.Visible = false end end
    local function hideAll(o, force) if o._allHidden and not force then return end; o._allHidden = true; hideTree(o); hideDrawings(o); if o.cham then o.cham.Enabled = false end end
    
    function ESP.rebuildAll()
        for p in pairs(State.ESPObjects) do cleanESP(p) end
        if not Config.ESP then return end
        for _, p in ipairs(getSafePlayers()) do if p ~= lp and p.Character then buildESP(p) end end
    end
    
    local function paintBox(u, ctx)
        local mode = Config.ESPBoxColorMode or "Solid"
        paint(u.boxStroke, "Color", "box", mode, Config.ESPBoxColor, Config.ESPBoxGradA, Config.ESPBoxGradB, Config.ESPGradientRotBox, Config.ESPGradientSpeed, ctx.now)
        local ct = math.floor(math.clamp(Config.ESPCasingThickness or 1, 1, 3))
        local bt = math.floor(math.clamp(Config.ESPBoxThickness or 1, 1, 4))
        u.caseOut.Thickness, u.caseIn.Thickness, u.boxStroke.Thickness = ct, ct, bt
        local sOut, sMid, sIn = UDim2.fromScale(1, 1), UDim2.new(1, -2*bt, 1, -2*bt), UDim2.new(1, -2*bt - 2*ct, 1, -2*bt - 2*ct)
        u.ringOut.Size, u.ringMid.Size, u.ringIn.Size = sOut, sMid, sIn
        local tr = math.clamp((Config.ESPBoxTransparency or 0) + (1 - (ctx.fade or 1)), 0, 1)
        u.boxStroke.Transparency, u.caseOut.Transparency, u.caseIn.Transparency = tr, tr, tr
    end
    
    local function drawCorners(u, w, h, ctx)
        local len = math.floor(math.clamp(w * (Config.ESPCornerLength or 0.28), 4, math.max(w * 0.48, 6)))
        local th = math.max(math.floor(Config.ESPBoxThickness or 1), 1)
        local spec = {
            { 0, 0, len, th }, { 0, 0, th, len }, { w - len, 0, len, th }, { w - th, 0, th, len },
            { 0, h - th, len, th }, { 0, h - len, th, len }, { w - len, h - th, len, th }, { w - th, h - len, th, len },
        }
        for i = 1, 8 do
            local c, s = u.corners[i], spec[i]
            c.Position, c.Size = UDim2.fromOffset(s[1], s[2]), UDim2.fromOffset(s[3], s[4])
            paint(c, "BackgroundColor3", "box", Config.ESPBoxColorMode or "Solid", Config.ESPBoxColor, Config.ESPBoxGradA, Config.ESPBoxGradB, Config.ESPGradientRotBox, Config.ESPGradientSpeed, ctx.now)
            c.Visible = true
        end
    end
    
    local function drawHealth(u, o, ctx, frac, hp)
        if not Config.ESPHealth then u.hp.Visible = false; u.hpNum.Visible = false; return end
        local fill = frac
        if Config.ESPHealthSmooth then
            local s = o._sHP or frac
            s = s + (frac - s) * math.clamp((ctx.dt or 0) * 16, 0, 1)
            o._sHP = s; fill = s
        end
        u.hp.Visible = true; u.hpFill.Size = UDim2.new(1, 0, math.clamp(fill, 0, 1), 0)
        paint(u.hpFill, "BackgroundColor3", "hp", Config.ESPHealthColorMode or "Ramp", healthColor(fill), Config.ESPHealthGradA, Config.ESPHealthGradB, 90, Config.ESPGradientSpeed, ctx.now)
        u.hpFill.BackgroundTransparency = Config.ESPHealthTransparency or 0
        
        if Config.ESPHealthGhost and o._ghostT and o._ghostFrac and o._ghostFrac > fill and (ctx.now - o._ghostT) < 0.35 then
            u.hpGhost.Visible = true; u.hpGhost.Size = UDim2.new(1, 0, math.clamp(o._ghostFrac, 0, 1), 0)
            u.hpGhost.BackgroundTransparency = 0.35 + 0.65 * math.clamp((ctx.now - o._ghostT) / 0.35, 0, 1)
        else u.hpGhost.Visible = false end
        
        local show = (Config.ESPHealthNumberMode == "Always") or (Config.ESPHealthNumberMode == "OnDamage" and frac < 0.999)
        if show then
            u.hpNum.Visible = true; u.hpNum.Text = tostring(math.floor(hp or 0))
            styleLabel(u.hpNum, ctx.face, sizeFor(ctx.tsHp, ctx.dmul), ctx.casing)
            u.hpNum.TextColor3 = healthColor(fill); u.hpNum.TextTransparency = 1 - (ctx.fade or 1)
            u.hpNum.Position = UDim2.new(0, -HP_GAP - HP_W - 3, math.clamp(1 - fill, 0, 1), 0)
        else u.hpNum.Visible = false end
    end
    
    local function drawText(u, o, player, ctx, dist, frac)
        local declut = Config.ESPDeclutter and o._declutter
        if Config.ESPName and not declut then
            u.head.Visible = true; u.name.Visible = true
            styleLabel(u.name, ctx.face, sizeFor(ctx.tsName, ctx.dmul), ctx.casing)
            u.name.Text = (Config.ESPNameMode == "Username") and player.Name or player.DisplayName
            paint(u.name, "TextColor3", "name", Config.ESPNameColorMode or "Solid", Config.ESPNameColor, Config.ESPNameGradA, Config.ESPNameGradB, Config.ESPGradientRotText, Config.ESPGradientSpeed, ctx.now)
            u.name.TextTransparency = math.clamp((Config.ESPNameTransparency or 0) + (1 - (ctx.fade or 1)), 0, 1)
            if Config.ESPNameHealthUnderline and frac then
                u.under.Visible = true; u.under.Size = UDim2.fromOffset(math.max(math.floor((u.name.TextBounds.X or 0) * frac), 1), 2); u.under.BackgroundColor3 = healthColor(frac)
            else u.under.Visible = false end
        else u.head.Visible = false end
        
        local showInfo = (Config.ESPDistance or Config.ESPWeapon) and not declut
        local showAmmo = Config.ESPAmmoBar and not declut
        u.foot.Visible = showInfo or showAmmo
        if showInfo then
            local txt
            if Config.ESPWeapon then txt = getWeaponName(player) end
            if Config.ESPDistance then txt = txt and (txt .. " · " .. ("%dm"):format(dist)) or ("%dm"):format(dist) end
            u.info.Visible = true; styleLabel(u.info, ctx.face, sizeFor(ctx.tsInfo, ctx.dmul), ctx.casing); u.info.Text = txt or ""
            paint(u.info, "TextColor3", "info", Config.ESPInfoColorMode or "Solid", Config.ESPInfoColor, Config.ESPInfoGradA, Config.ESPInfoGradB, Config.ESPGradientRotText, Config.ESPGradientSpeed, ctx.now)
            u.info.TextTransparency = 1 - (ctx.fade or 1)
        else u.info.Visible = false end
        
        if showAmmo then
            u.ammo.Visible = true; u.ammo.Size = UDim2.fromOffset(math.max(math.floor(ctx.boxW * 0.9), 12), 3)
            u.ammoFill.Size = UDim2.new(math.random(), 0, 1, 0)
            paint(u.ammoFill, "BackgroundColor3", "mark", Config.ESPMarkColorMode or "Solid", Config.ESPMarkColor, Config.ESPMarkGradA, Config.ESPMarkGradB, 0, Config.ESPGradientSpeed, ctx.now)
        else u.ammo.Visible = false end
    end
    
    local function drawFlags(u, o, player, ctx, char, frac)
        local n = 0
        local function add(key, label)
            if n >= 5 then return end
            n = n + 1; local c = u.chips[n]; c.Visible = true; styleLabel(c, ctx.face, sizeFor(ctx.tsChip, ctx.dmul), ctx.casing); c.Text = label
            paint(c, "TextColor3", "flag", Config.ESPFlagColorMode or "PerFlag", (Config.ESPFlagColorMode == "PerFlag") and (FLAG_COLORS[key] or WHITE) or Config.ESPFlagColor, Config.ESPFlagGradA, Config.ESPFlagGradB, Config.ESPGradientRotText, Config.ESPGradientSpeed, ctx.now)
            c.TextTransparency = 1 - (ctx.fade or 1)
        end
        if Config.ESPFlagShield and getWeaponName(player):find("Shield") then add("SHIELD", "[SHIELD]") end
        if Config.ESPFlagLowHP and frac and frac <= 0.25 then add("LOW", "[LOW]") end
        u.flags.Visible = n > 0
        for i = n + 1, 5 do u.chips[i].Visible = false end
    end
    
    local function segment(f, ax, ay, bx, by, thick, transp)
        local dx, dy = bx - ax, by - ay
        local len = math.sqrt(dx * dx + dy * dy)
        if len < 1 then f.Visible = false; return end
        f.Position = UDim2.fromOffset(math.floor((ax + bx) * 0.5), math.floor((ay + by) * 0.5)); f.Size = UDim2.fromOffset(math.floor(len + 0.5), thick)
        f.Rotation = math.deg(math.atan2(dy, dx)); f.BackgroundTransparency = transp or 0; f.Visible = true
    end
    
    local function drawSkeleton(u, o, ctx)
        if not Config.ESPSkeleton then if u.skel then for i = 1, #u.skel do u.skel[i].Visible = false end end return end
        for i = #u.skel + 1, #o.bones do
            local f = mkFrame(_absLayer, 2); f.AnchorPoint = Vector2.new(0.5, 0.5); f.BackgroundColor3 = WHITE; f.Visible = false
            local s = Instance.new("UIStroke"); s.Color = INK; s.Thickness = 1; s.Parent = f; u.skel[i] = f
        end
        if (not o._skelPts) or (_espFrame - (o._skelFrame or -9)) >= 2 then
            o._skelFrame = _espFrame; local pts = o._skelPts or {}; o._skelPts = pts
            for i, pair in ipairs(o.bones) do
                local e = pts[i] or {}; pts[i] = e
                if pair.a and pair.b and pair.a.Parent and pair.b.Parent then
                    local s1, v1 = cam:WorldToViewportPoint(pair.a.Position); local s2, v2 = cam:WorldToViewportPoint(pair.b.Position)
                    if v1 and v2 and s1.Z > 0 and s2.Z > 0 then e.ok, e.ax, e.ay, e.bx, e.by = true, s1.X, s1.Y, s2.X, s2.Y else e.ok = false end
                else e.ok = false end
            end
        end
        for i = 1, #o.bones do
            local f, e = u.skel[i], o._skelPts and o._skelPts[i]
            if f then
                if e and e.ok then segment(f, e.ax, e.ay, e.bx, e.by, Config.ESPSkeletonThickness or 1, Config.ESPSkeletonTransparency or 0); paint(f, "BackgroundColor3", "skel", Config.ESPSkeletonColorMode or "Solid", Config.ESPSkeletonColor, Config.ESPSkeletonGradA, Config.ESPSkeletonGradB, 0, Config.ESPGradientSpeed, ctx.now)
                else f.Visible = false end
            end
        end
    end
    
    local function drawAbsExtras(u, o, ctx, char, minX, minY, maxX, maxY)
        if Config.ESPTracers then
            local ox, oy = ctx.vp.X * 0.5, ctx.vp.Y
            if Config.ESPTracerOrigin == "Top" then oy = 0 elseif Config.ESPTracerOrigin == "Middle" then oy = ctx.vp.Y * 0.5 end
            segment(u.tracer, ox, oy, (minX + maxX) * 0.5, maxY, Config.ESPTracerThickness or 1, Config.ESPTracerTransparency or 0)
            paint(u.tracer, "BackgroundColor3", "tracer", Config.ESPTracerColorMode or "Solid", Config.ESPTracerColor, Config.ESPTracerGradA, Config.ESPTracerGradB, 0, Config.ESPGradientSpeed, ctx.now)
        else u.tracer.Visible = false end
        
        if Config.ESPHeadDot then
            local head = char:FindFirstChild("Head"); local ok = false
            if head then
                local hsp, inv = cam:WorldToViewportPoint(head.Position)
                if inv and hsp.Z > 0 then
                    local r = math.clamp(Config.ESPHeadDotSize or 4, 2, 16)
                    u.dot.Position = UDim2.fromOffset(math.floor(hsp.X), math.floor(hsp.Y)); u.dot.Size = UDim2.fromOffset(r * 2, r * 2)
                    paint(u.dot, "BackgroundColor3", "mark", Config.ESPMarkColorMode or "Solid", Config.ESPMarkColor, Config.ESPMarkGradA, Config.ESPMarkGradB, 0, Config.ESPGradientSpeed, ctx.now)
                    u.dot.Visible, ok = true, true
                end
            end
            if not ok then u.dot.Visible = false end
        else u.dot.Visible = false end
    end
    
    local function renderPlayer(player, o)
        local ctx = _ctx; local char = player.Character
        if not char or not o.root or not o.root.Parent then cleanESP(player); return end
        if not o.ui then o.ui = buildTree(o); if not o.ui then return end end
        local u = o.ui; local rootPos = o.root.Position
        local myRoot = ctx.myRoot; local dist = o._dist or (myRoot and (myRoot.Position - rootPos).Magnitude) or 0
        if (Config.ESPTeamCheck and isTeammate(player)) or (not isAlive(player)) or dist > Config.ESPMaxDistance then
            hideAll(o); return
        end
        if o._allHidden and Config.ESPFadeIn then o._fadeT = ctx.now end; o._allHidden = false
        
        ctx.fade = Config.ESPFadeIn and math.clamp((ctx.now - (o._fadeT or 0)) / 0.12, 0, 1) or 1
        ctx.dmul = distMul(dist)
        local minX, minY, maxX, maxY = bbox(char, player)
        if minX then
            local w, h = maxX - minX, maxY - minY; ctx.boxW = w
            u.root.Position = UDim2.fromOffset(minX, minY); u.root.Size = UDim2.fromOffset(w, h); u.root.Visible = true
            local hp, mh = getHealth(player); local frac = math.clamp((mh or 0) > 0 and hp / mh or 0, 0, 1)
            
            if Config.ESPHealthGhost and o._lastHP and frac < o._lastHP - 0.005 then
                if not o._ghostT or (ctx.now - o._ghostT) >= 0.35 then o._ghostFrac = o._lastHP
                else o._ghostFrac = math.max(o._ghostFrac or o._lastHP, o._lastHP) end
                o._ghostT = ctx.now
            end
            
            if Config.ESPBox then
                if Config.ESPBoxStyle == "Corner Brackets" then u.box.Visible = false; drawCorners(u, w, h, ctx)
                else u.box.Visible = true; paintBox(u, ctx); for i=1,8 do u.corners[i].Visible = false end end
            else u.box.Visible = false; for i=1,8 do u.corners[i].Visible = false end end
            
            if Config.ESPBoxFill then
                u.fill.Visible = true; u.fill.BackgroundTransparency = Config.ESPBoxFillTransparency or 0.75
                paint(u.fill, "BackgroundColor3", "fill", "Solid", Config.ESPBoxFillColor, Config.ESPBoxGradA, Config.ESPBoxGradB, Config.ESPGradientRotBox, Config.ESPGradientSpeed, ctx.now)
            else u.fill.Visible = false end
            
            drawHealth(u, o, ctx, frac, hp)
            drawText(u, o, player, ctx, dist, frac)
            drawFlags(u, o, player, ctx, char, frac)
            o._lastHP = frac
        else hideTree(o) end
        
        drawSkeleton(u, o, ctx)
        if minX then drawAbsExtras(u, o, ctx, char, minX, minY, maxX, maxY)
        else u.tracer.Visible = false; u.dot.Visible = false end
        
        if Config.ESPChams then
            local hl = ensureCham(o, char)
            if hl then
                hl.FillColor = Config.ESPChamsFillColor; hl.OutlineColor = Config.ESPChamsOutlineColor
                hl.FillTransparency = Config.ESPChamsFillTransparency; hl.OutlineTransparency = Config.ESPChamsOutlineTransparency
                hl.Enabled = true
            end
        elseif o.cham then o.cham.Enabled = false end
    end
    
    local function render()
        local now = tick()
        if now - _lastRenderT < 0.0083 then return end
        _lastRenderT = now; _espFrame = _espFrame + 1; _createBudget = 32
        if not Config.ESP then
            for _, o in pairs(State.ESPObjects) do hideAll(o, true) end; return
        end
        local ctx = _ctx
        ctx.vp = Camera.ViewportSize; ctx.myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        ctx.dt = math.clamp(now - (_lastRenderT or now), 0, 0.1); ctx.now = now
        ctx.face = faceFor(Config.ESPFont or "Code")
        local ts = (ctx.vp.Y / 1080) * (Config.ESPTextScale or 1)
        ctx.tsName = typePx(Config.ESPTextSize or 14, ts); ctx.tsInfo = typePx(Config.ESPInfoTextSize or 12, ts)
        ctx.tsHp = typePx(Config.ESPHealthTextSize or 11, ts); ctx.tsChip = typePx(10, ts)
        ctx.casing = math.floor(math.clamp(Config.ESPTextCasing or 1, 0, 4))
        
        local cap = Config.ESPMaxPlayers or 0
        if cap > 0 then
            local arr, n = _renderArr, 0
            for p, o in pairs(State.ESPObjects) do
                n = n + 1; arr[n] = arr[n] or {}; arr[n].p = p; arr[n].o = o
                local rp = o.root and o.root.Parent and o.root.Position
                arr[n].d = (ctx.myRoot and rp) and (ctx.myRoot.Position - rp).Magnitude or math.huge
            end
            for i = #arr, n + 1, -1 do arr[i] = nil end
            table.sort(arr, function(a,b) return a.d < b.d end)
            for i = 1, n do
                if i <= cap then arr[i].o._dist = arr[i].d; renderPlayer(arr[i].p, arr[i].o) else hideAll(arr[i].o) end
            end
        else
            for p, o in pairs(State.ESPObjects) do o._dist = nil; renderPlayer(p, o) end
        end
    end
    
    function ESP.init()
        for _, p in ipairs(getSafePlayers()) do
            if p ~= lp then p.CharacterAdded:Connect(function() task.wait(0.5); if Config.ESP then buildESP(p) end end) end
        end
        Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() task.wait(0.5); if Config.ESP then buildESP(p) end end) end)
        Players.PlayerRemoving:Connect(function(p) cleanESP(p) end)
        if Config.ESP and not _renderConn then _renderConn = RunService.RenderStepped:Connect(render); ESP.rebuildAll() end
    end
    function ESP.enable() Config.ESP = true; ESP.rebuildAll(); if not _renderConn then _renderConn = RunService.RenderStepped:Connect(render) end end
    function ESP.disable() Config.ESP = false; ESP.rebuildAll(); if _renderConn then _renderConn:Disconnect(); _renderConn = nil end end
end)()

-- =========================================================
-- UI: MAIN TAB (Silent Aim & Aimbot & Triggerbot)
-- =========================================================
local MainLeft = Tabs.Main:AddLeftGroupbox("Silent Aim")
MainLeft:AddToggle('SilentAim', { Text='Silent Aim', Default=Config.SilentAim, Callback=function(v) Config.SilentAim = v end })
    :AddKeyPicker('SilentAimKey', { Default='None', Mode='Toggle', SyncToggleState=true, Text='Silent Aim' })
MainLeft:AddToggle('SilentAimVisCheck', { Text='Visibility check', Default=Config.SilentAimVisCheck, Callback=function(v) Config.SilentAimVisCheck = v end })
MainLeft:AddSlider('SilentAimFOV', { Text='FOV radius', Default=Config.SilentAimFOV, Min=20, Max=2000, Rounding=0, Callback=function(v) Config.SilentAimFOV = v end })
MainLeft:AddDropdown('SilentAimTargetPart', { Values={'Head','Torso','Closest'}, Default=Config.SilentAimTargetPart, Text='Target bone', Callback=function(v) Config.SilentAimTargetPart = v end })
MainLeft:AddSlider('SilentAimStickiness', { Text='Stickiness', Default=Config.SilentAimStickiness, Min=0, Max=0.5, Rounding=2, Callback=function(v) Config.SilentAimStickiness = v end })
MainLeft:AddSlider('SilentAimHitChance', { Text='Hit chance %', Default=Config.SilentAimHitChance, Min=25, Max=100, Rounding=0, Callback=function(v) Config.SilentAimHitChance = math.floor(v) end })
MainLeft:AddSlider('SilentAimJitterDeg', { Text='Jitter cone (deg)', Default=Config.SilentAimJitterDeg, Min=0, Max=10, Rounding=1, Callback=function(v) Config.SilentAimJitterDeg = v end })

local MainRight = Tabs.Main:AddRightGroupbox("Aimbot")
MainRight:AddToggle('Aimbot', { Text='Aimbot', Default=Config.Aimbot, Callback=function(v) if v then Aimbot.enable() else Aimbot.disable() end end })
MainRight:AddDropdown('AimbotKey', { Values={'Always','MB2','MB1','C','E','F','Q','V','X','LeftShift','LeftAlt','LeftControl'}, Default=Config.AimbotKey, Text='Activation', Callback=function(v) Config.AimbotKey = v end })
MainRight:AddDivider('Target Lock')
MainRight:AddToggle('TargetLockEnabled', { Text='Enable Target Lock', Default=(Config.TargetLockEnabled or false), Callback=function(v) Config.TargetLockEnabled = v; if not v then State.TargetLockTarget = nil end end })
    :AddKeyPicker('TargetLockKey', { Default='Y', Mode='Toggle', SyncToggleState=false, Text='Target Lock', Callback=function() if Config.TargetLockEnabled then State.TargetLockTap = true end end })
MainRight:AddDropdown('TargetLockMode', { Values={'ToggleLock','AutoLock','ManualOnly'}, Default=(Config.TargetLockMode or 'ToggleLock'), Text='Lock mode', Callback=function(v) Config.TargetLockMode = v; State.TargetLockTarget = nil end })
MainRight:AddDivider('Smoothing')
MainRight:AddSlider('AimbotSmoothness', { Text='Smoothness (0 = hard lock)', Default=Config.AimbotSmoothness, Min=0, Max=100, Rounding=0, Callback=function(v) Config.AimbotSmoothness = v end })
MainRight:AddToggle('AimbotLinkAxes', { Text='Link X / Y smoothing', Default=(Config.AimbotLinkAxes ~= false), Callback=function(v) Config.AimbotLinkAxes = v end })
local axisDep = MainRight:AddDependencyBox()
axisDep:AddSlider('AimbotSmoothnessX', { Text='Yaw (X) smoothness', Default=(Config.AimbotSmoothnessX or 0), Min=0, Max=100, Rounding=0, Callback=function(v) Config.AimbotSmoothnessX = v end })
axisDep:AddSlider('AimbotSmoothnessY', { Text='Pitch (Y) smoothness', Default=(Config.AimbotSmoothnessY or 0), Min=0, Max=100, Rounding=0, Callback=function(v) Config.AimbotSmoothnessY = v end })
axisDep:SetupDependencies({ { Toggles.AimbotLinkAxes, false } })
MainRight:AddSlider('AimbotJumpDamping', { Text='Jump & airborne damping (%)', Default=(Config.AimbotJumpDamping or 40), Min=0, Max=100, Rounding=0, Callback=function(v) Config.AimbotJumpDamping = v end })
MainRight:AddToggle('AimbotCancelSprings', { Text='Pre-cancel weapon sway springs', Default=(Config.AimbotCancelSprings ~= false), Callback=function(v) Config.AimbotCancelSprings = v end })
MainRight:AddToggle('AimbotCurvedFlick', { Text='Humanized curved flicks (Bezier)', Default=(Config.AimbotCurvedFlick or false), Callback=function(v) Config.AimbotCurvedFlick = v end })
local curveDep = MainRight:AddDependencyBox()
curveDep:AddSlider('AimbotCurvedIntensity', { Text='Curve amplitude', Default=(Config.AimbotCurvedIntensity or 0.35), Min=0.05, Max=1.0, Rounding=2, Callback=function(v) Config.AimbotCurvedIntensity = v end })
curveDep:SetupDependencies({ { Toggles.AimbotCurvedFlick, true } })
MainRight:AddSlider('AimbotTrackAssist', { Text='Track assist (0-lag feedforward)', Default=(Config.AimbotTrackAssist or 100), Min=0, Max=100, Rounding=0, Callback=function(v) Config.AimbotTrackAssist = v end })
MainRight:AddSlider('AimbotMaxSpeed', { Text='Max turn speed (deg/s, 0 = off)', Default=(Config.AimbotMaxSpeed or 0), Min=0, Max=3600, Rounding=0, Callback=function(v) Config.AimbotMaxSpeed = v end })
MainRight:AddSlider('AimbotDeadzoneDeg', { Text='Deadzone (deg)', Default=(Config.AimbotDeadzoneDeg or 0), Min=0, Max=10, Rounding=2, Callback=function(v) Config.AimbotDeadzoneDeg = v end })
MainRight:AddSlider('AimbotFOVDeg', { Text='FOV (deg)', Default=(Config.AimbotFOVDeg or 20), Min=1, Max=180, Rounding=1, Callback=function(v) Config.AimbotFOVDeg = v end })
MainRight:AddSlider('AimbotSwitchDeg', { Text='Switch threshold (deg)', Default=(Config.AimbotSwitchDeg or 2), Min=0, Max=45, Rounding=1, Callback=function(v) Config.AimbotSwitchDeg = v end })
MainRight:AddSlider('AimbotStickiness', { Text='Stickiness', Default=(Config.AimbotStickiness or 0.15), Min=0, Max=0.5, Rounding=2, Callback=function(v) Config.AimbotStickiness = v end })
MainRight:AddSlider('AimbotForgetTime', { Text='Occlusion forget time (s)', Default=(Config.AimbotForgetTime or 0.2), Min=0, Max=1.0, Rounding=2, Callback=function(v) Config.AimbotForgetTime = v end })
MainRight:AddDropdown('AimbotTargetPart', { Values={'Best','Head','Torso','Closest'}, Default=(Config.AimbotTargetPart or 'Best'), Text='Target bone', Callback=function(v) Config.AimbotTargetPart = v end })
MainRight:AddDropdown('AimbotPriority', { Values={'Crosshair','Health','Distance'}, Default=(Config.AimbotPriority or 'Crosshair'), Text='Priority', Callback=function(v) Config.AimbotPriority = v end })
MainRight:AddToggle('AimbotVisCheck', { Text='Visibility check', Default=(Config.AimbotVisCheck ~= false), Callback=function(v) Config.AimbotVisCheck = v end })
MainRight:AddToggle('AimbotSkipImmune', { Text='Skip immune targets', Default=(Config.AimbotSkipImmune ~= false), Callback=function(v) Config.AimbotSkipImmune = v end })
MainRight:AddToggle('AimbotPrediction', { Text='Prediction (lead + gravity)', Default=(Config.AimbotPrediction or false), Callback=function(v) Config.AimbotPrediction = v end })
MainRight:AddToggle('AimbotShotOverride', { Text='Shot override', Default=(Config.AimbotShotOverride or false), Callback=function(v) Config.AimbotShotOverride = v end })
MainRight:AddSlider('AimbotReactionMs', { Text='Reaction delay (ms)', Default=(Config.AimbotReactionMs or 0), Min=0, Max=300, Rounding=0, Callback=function(v) Config.AimbotReactionMs = v end })
MainRight:AddSlider('AimbotNoiseDeg', { Text='Aim noise (deg/s)', Default=(Config.AimbotNoiseDeg or 0), Min=0, Max=20, Rounding=1, Callback=function(v) Config.AimbotNoiseDeg = v end })
MainRight:AddSlider('AimbotOvershoot', { Text='Overshoot', Default=(Config.AimbotOvershoot or 0), Min=0, Max=1, Rounding=2, Callback=function(v) Config.AimbotOvershoot = v end })
MainRight:AddToggle('AimbotShowLock', { Text='Show lock indicator', Default=(Config.AimbotShowLock or false), Callback=function(v) Config.AimbotShowLock = v end })
MainRight:AddToggle('AimbotShowFOV', { Text='Debug FOV circle', Default=(Config.AimbotShowFOV or false), Callback=function(v) Config.AimbotShowFOV = v end })
MainRight:AddToggle('AimbotDebug', { Text='Debug readout', Default=(Config.AimbotDebug or false), Callback=function(v) Config.AimbotDebug = v end })
MainRight:AddToggle('AimbotDirectCamera', { Text='Direct camera fallback', Default=(Config.AimbotDirectCamera or false), Callback=function(v) Config.AimbotDirectCamera = v end })

local TriggerGroup = Tabs.Main:AddLeftGroupbox("Triggerbot")
TriggerGroup:AddToggle('Trigger', { Text='Trigger bot', Default=Config.Trigger, Callback=function(v) if v then Trigger.enable() else Trigger.disable() end end })
TriggerGroup:AddDropdown('TriggerKey', { Values={'Always','MB2','MB1','C','E','F','Q','V','X','LeftShift','LeftAlt','LeftControl'}, Default=Config.TriggerKey, Text='Activation', Callback=function(v) Config.TriggerKey = v end })
TriggerGroup:AddToggle('TriggerHeadOnly', { Text='Head only', Default=Config.TriggerHeadOnly, Callback=function(v) Config.TriggerHeadOnly = v end })
TriggerGroup:AddToggle('TriggerScopeCheck', { Text='Scope check', Default=Config.TriggerScopeCheck, Callback=function(v) Config.TriggerScopeCheck = v end })
TriggerGroup:AddSlider('TriggerDelayMs', { Text='Reaction delay (ms)', Default=Config.TriggerDelayMs, Min=0, Max=300, Rounding=0, Callback=function(v) Config.TriggerDelayMs = v end })
TriggerGroup:AddSlider('TriggerRefireMs', { Text='Refire delay (ms)', Default=Config.TriggerRefireMs, Min=0, Max=500, Rounding=0, Callback=function(v) Config.TriggerRefireMs = v end })
TriggerGroup:AddSlider('TriggerMaxDist', { Text='Max distance', Default=Config.TriggerMaxDist, Min=50, Max=400, Rounding=0, Callback=function(v) Config.TriggerMaxDist = v end })


-- =========================================================
-- UI: RAGE TAB (Graviton & Fake Underground)
-- =========================================================
local B = Tabs.Rage:AddRightGroupbox('Graviton ragebot')
B:AddToggle('GravRage', { Text = 'Graviton ragebot', Default = false,
    Tooltip = 'Ported from Graviton-9v2. Desyncs next to the closest enemy, fires from there, and restores your position before the camera updates. Do not run it with the other ragebots.',
    Callback = function(v)
        GR.on = v
        if v then start() else stop() end
    end })
    :AddKeyPicker('GravRageKey', { Default = 'None', Mode = 'Toggle', SyncToggleState = true, Text = 'Graviton ragebot' })
B:AddToggle('GravDesync', { Text = 'Desync origin', Default = true, Callback = function(v) GR.desync = v end })
B:AddToggle('GravVoid', { Text = 'Void park (shotgun)', Default = true, Callback = function(v) GR.void = v end })
B:AddToggle('GravHead', { Text = 'Aim head', Default = true, Callback = function(v) GR.head = v end })
B:AddToggle('GravExtra', { Text = 'Extrapolation', Default = true, Callback = function(v) GR.extra = v end })
B:AddToggle('GravKnife', { Text = 'Knife deflect check', Default = true, Callback = function(v) GR.knife = v end })
B:AddToggle('GravEquip', { Text = 'Auto equip slot', Default = true,
    Callback = function(v) GR.equip = v; if v and GR.on then startEquip() end end })
B:AddSlider('GravRate', { Text = 'Fire rate (ms)', Default = 1, Min = 1, Max = 500, Rounding = 0, Suffix = ' ms',
    Callback = function(v) GR.rate = v / 1000 end })
B:AddSlider('GravFov', { Text = 'FOV', Default = 9999, Min = 0, Max = 9999, Rounding = 0, Suffix = ' px',
    Callback = function(v) GR.fov = v end })
B:AddDropdown('GravSlot', { Text = 'Weapon', Values = { 'Primary', 'Secondary', 'Melee' }, Default = 1, Multi = false,
    Callback = function(v) GR.slot = ({ Primary = 1, Secondary = 2, Melee = 3 })[v] or 1 end })


local FUG = Tabs.Rage:AddLeftGroupbox('Fake Underground')
FUG:AddToggle('FakeUnderground', { Text = 'Fake Underground', Default = false,
    Tooltip = 'Holds your character underground while your view and walking stay on the surface. Do not run it with the ragebots.',
    Callback = function(v) if v then turnOn() else turnOff() end end })
    :AddKeyPicker('FakeUndergroundKey', { Default = 'None', Mode = 'Toggle', SyncToggleState = true, Text = 'Fake Underground' })
FUG:AddSlider('FUDepth', { Text = 'Depth', Default = 5.8, Min = 0, Max = 150, Rounding = 1, Suffix = ' studs',
    Callback = function(v) FU.depth = v end })
FUG:AddToggle('FUWalk', { Text = 'Walk mode', Default = true, Tooltip = 'Lets you move around while underground.',
    Callback = function(v) FU.walk = v end })
FUG:AddToggle('FUCamera', { Text = 'Surface camera', Default = false, Tooltip = 'OFF: your view stays underground (you see the map from below). ON: the camera stays on the surface.',
    Callback = function(v) FU.camera = v end })
FUG:AddToggle('FUNoclip', { Text = 'Auto noclip', Default = true, Callback = function(v) FU.noclip = v end })
FUG:AddToggle('FUHide', { Text = 'Hide my character', Default = true,
    Callback = function(v)
        FU.hide = v
        if FU.on then if v then hideChar() else showChar() end end
    end })
FUG:AddToggle('FUAnim', { Text = 'Animation desync', Default = true,
    Callback = function(v) FU.anim = v; if FU.on then if v then startAnim() else stopAnim() end end end })
FUG:AddToggle('FUPanic', { Text = 'Panic jitter', Default = false, Callback = function(v) FU.panic = v end })
FUG:AddSlider('FUPanicMin', { Text = 'Jitter min X', Default = -5, Min = -50, Max = 0, Rounding = 0, Callback = function(v) FU.pMin = v end })
FUG:AddSlider('FUPanicMax', { Text = 'Jitter max X', Default = 5, Min = 0, Max = 50, Rounding = 0, Callback = function(v) FU.pMax = v end })
FUG:AddToggle('FUPanicZ', { Text = 'Jitter Z too', Default = false, Callback = function(v) FU.pZ = v end })
FUG:AddDivider('Underground ragebot')
FUG:AddToggle('FURage', { Text = 'Underground ragebot', Default = false,
    Tooltip = 'Orbits around the closest enemy while underground and shoots them. Needs Fake Underground; turning this on switches it on. Do not run the other ragebots with it.',
    Callback = function(v)
        FU.rage = v
        FU.target = nil
        if v then
            if not getMods() then
                pcall(function() Library:Notify('Underground ragebot: could not load the game modules (' .. tostring(modErr) .. ')', 6) end)
            end
            if not FU.on then pcall(function() Toggles.FakeUnderground:SetValue(true) end) end
        end
    end })
FUG:AddToggle('FURageOrbit', { Text = 'Orbit the target', Default = false,
    Tooltip = 'OFF: you stay under your own spot and shoot up at the closest enemy. ON: you orbit the enemy underground and shoot.',
    Callback = function(v) FU.orbit = v end })
FUG:AddSlider('FURageRadius', { Text = 'Orbit radius', Default = 14, Min = 3, Max = 60, Rounding = 0, Suffix = ' studs', Callback = function(v) FU.radius = v end })
FUG:AddSlider('FURageSpeed', { Text = 'Orbit speed', Default = 4, Min = 0.5, Max = 20, Rounding = 1, Suffix = ' rad/s', Callback = function(v) FU.speed = v end })
FUG:AddSlider('FURageRate', { Text = 'Shoot delay', Default = 0.1, Min = 0.01, Max = 1, Rounding = 2, Suffix = 's', Callback = function(v) FU.rate = v end })
FUG:AddSlider('FURageDist', { Text = 'Max target distance', Default = 400, Min = 50, Max = 2000, Rounding = 0, Suffix = ' studs', Callback = function(v) FU.maxDist = v end })
FUG:AddDropdown('FURageSlot', { Text = 'Weapon', Values = { 'Primary', 'Secondary' }, Default = 1, Multi = false, Callback = function(v) FU.slot = v end })
FUG:AddToggle('FURageTeam', { Text = 'Skip teammates', Default = true, Callback = function(v) FU.team = v end })


-- =========================================================
-- UI: ESP TAB
-- =========================================================
local GRAD_MODES = {'Solid','Gradient'}
local W = Color3.fromRGB(255, 255, 255)

local function colourRow(box, label, key, modes, solidDefault, aDefault, bDefault)
    local modeKey = 'ESP' .. key .. 'ColorMode'
    local colKey  = 'ESP' .. key .. 'Color'
    local aKey    = 'ESP' .. key .. 'GradA'
    local bKey    = 'ESP' .. key .. 'GradB'
    
    box:AddDropdown(modeKey, { Values=modes, Default=(Config[modeKey] or modes[1]),
        Text=label .. ' colour', Callback=function(v) Config[modeKey] = v end })
        
    local solidDep = box:AddDependencyBox()
    solidDep:AddLabel(label):AddColorPicker(colKey, { Default=(Config[colKey] or solidDefault),
        Callback=function(v) Config[colKey] = v end })
    solidDep:SetupDependencies({ { Options[modeKey], 'Solid' } })
    
    local gradDep = box:AddDependencyBox()
    gradDep:AddLabel(label .. ' A'):AddColorPicker(aKey, { Default=(Config[aKey] or aDefault),
        Callback=function(v) Config[aKey] = v end })
    gradDep:AddLabel(label .. ' B'):AddColorPicker(bKey, { Default=(Config[bKey] or bDefault),
        Callback=function(v) Config[bKey] = v end })
    gradDep:SetupDependencies({ { Options[modeKey], 'Gradient' } })
end

local L = Tabs.ESP:AddLeftGroupbox('ESP & Boxes')
L:AddToggle('ESP', { Text='Enable ESP', Default=Config.ESP,
    Callback=function(v) if v then ESP.enable() else ESP.disable() end end })
    :AddKeyPicker('ESPToggleKey', { Default='None', Mode='Toggle', SyncToggleState=true, Text='ESP' })

local espDep = L:AddDependencyBox()
espDep:AddToggle('ESPTeamCheck', { Text='Team check (hide teammates)', Default=(Config.ESPTeamCheck ~= false),
    Callback=function(v) Config.ESPTeamCheck = v end })
espDep:AddToggle('ESPBox', { Text='Box', Default=(Config.ESPBox ~= false),
    Callback=function(v) Config.ESPBox = v end })
espDep:AddToggle('ESPBoxFill', { Text='Fill ESP', Default=(Config.ESPBoxFill or false),
    Tooltip='Translucent fill behind each player.',
    Callback=function(v) Config.ESPBoxFill = v end })
    :AddColorPicker('ESPBoxFillColor', { Default=(Config.ESPBoxFillColor or Color3.fromRGB(255, 59, 78)),
        Title='Fill color', Callback=function(v) Config.ESPBoxFillColor = v end })

local fillDep = espDep:AddDependencyBox()
fillDep:AddSlider('ESPBoxFillTransparency', { Text='Fill transparency', Default=(Config.ESPBoxFillTransparency or 0.75),
    Min=0, Max=1, Rounding=2, Callback=function(v) Config.ESPBoxFillTransparency = v end })
fillDep:SetupDependencies({ { Toggles.ESPBoxFill, true } })

local boxDep = espDep:AddDependencyBox()
boxDep:AddDropdown('ESPBoxStyle', { Values={'Full Box','Corner Brackets'}, Default=(Config.ESPBoxStyle or 'Full Box'),
    Text='Box style', Callback=function(v) Config.ESPBoxStyle = v end })
boxDep:AddSlider('ESPCornerLength', { Text='Corner length %', Default=(Config.ESPCornerLength or 0.28),
    Min=0.05, Max=0.5, Rounding=2, Callback=function(v) Config.ESPCornerLength = v end })
boxDep:AddSlider('ESPBoxThickness', { Text='Box thickness', Default=(Config.ESPBoxThickness or 1),
    Min=1, Max=4, Rounding=0, Callback=function(v) Config.ESPBoxThickness = math.floor(v) end })
boxDep:AddSlider('ESPBoxScale', { Text='Box size', Default=(Config.ESPBoxScale or 1),
    Min=0.6, Max=1.6, Rounding=2, Callback=function(v) Config.ESPBoxScale = v end })
colourRow(boxDep, 'Box', 'Box', GRAD_MODES, W, Color3.fromRGB(255,59,78), Color3.fromRGB(255,194,75))
boxDep:SetupDependencies({ { Toggles.ESPBox, true } })
espDep:SetupDependencies({ { Toggles.ESP, true } })


local L2 = Tabs.ESP:AddLeftGroupbox('Health & Ammo')
L2:AddToggle('ESPHealth', { Text='Health bar', Default=(Config.ESPHealth ~= false),
    Callback=function(v) Config.ESPHealth = v end })
local hpDep = L2:AddDependencyBox()
hpDep:AddDropdown('ESPHealthNumberMode', { Values={'Off','OnDamage','Always'},
    Default=(Config.ESPHealthNumberMode or 'OnDamage'), Text='Number readout',
    Callback=function(v) Config.ESPHealthNumberMode = v end })
hpDep:AddToggle('ESPHealthSmooth', { Text='Damage lerp animation', Default=(Config.ESPHealthSmooth ~= false),
    Callback=function(v) Config.ESPHealthSmooth = v end })
hpDep:AddToggle('ESPHealthGhost', { Text='Damage ghost bar', Default=(Config.ESPHealthGhost ~= false),
    Callback=function(v) Config.ESPHealthGhost = v end })
colourRow(hpDep, 'Health', 'Health', {'Ramp','Solid','Gradient'},
          Color3.fromRGB(61,224,122), Color3.fromRGB(255,68,54), Color3.fromRGB(61,224,122))
hpDep:SetupDependencies({ { Toggles.ESPHealth, true } })
L2:AddToggle('ESPAmmoBar', { Text='Ammo bar (magazine)', Default=(Config.ESPAmmoBar or false),
    Callback=function(v) Config.ESPAmmoBar = v end })


local L3 = Tabs.ESP:AddLeftGroupbox('Skeleton, Tracers & Markers')
L3:AddToggle('ESPSkeleton', { Text='Skeleton', Default=(Config.ESPSkeleton or false),
    Callback=function(v) Config.ESPSkeleton = v end })
local skelDep = L3:AddDependencyBox()
skelDep:AddSlider('ESPSkeletonThickness', { Text='Thickness', Default=(Config.ESPSkeletonThickness or 1),
    Min=1, Max=5, Rounding=0, Callback=function(v) Config.ESPSkeletonThickness = math.floor(v) end })
colourRow(skelDep, 'Skeleton', 'Skeleton', GRAD_MODES, W, W, Color3.fromRGB(120,180,255))
skelDep:SetupDependencies({ { Toggles.ESPSkeleton, true } })

L3:AddToggle('ESPTracers', { Text='Tracer snaplines', Default=(Config.ESPTracers or false),
    Callback=function(v) Config.ESPTracers = v end })
local trDep = L3:AddDependencyBox()
trDep:AddDropdown('ESPTracerOrigin', { Values={'Bottom','Middle','Top'}, Default=(Config.ESPTracerOrigin or 'Bottom'), Text='Origin',
    Callback=function(v) Config.ESPTracerOrigin = v end })
trDep:AddSlider('ESPTracerThickness', { Text='Thickness', Default=(Config.ESPTracerThickness or 1),
    Min=1, Max=4, Rounding=0, Callback=function(v) Config.ESPTracerThickness = math.floor(v) end })
colourRow(trDep, 'Tracer', 'Tracer', GRAD_MODES, W, W, Color3.fromRGB(255,59,78))
trDep:SetupDependencies({ { Toggles.ESPTracers, true } })

L3:AddToggle('ESPHeadDot', { Text='Head dot', Default=(Config.ESPHeadDot or false),
    Callback=function(v) Config.ESPHeadDot = v end })
local hmDep = L3:AddDependencyBox()
hmDep:AddSlider('ESPHeadDotSize', { Text='Radius', Default=(Config.ESPHeadDotSize or 4),
    Min=2, Max=16, Rounding=0, Callback=function(v) Config.ESPHeadDotSize = math.floor(v) end })
hmDep:SetupDependencies({ { Toggles.ESPHeadDot, true } })

colourRow(L3, 'Markers', 'Mark', GRAD_MODES, W, W, Color3.fromRGB(255,194,75))


local R = Tabs.ESP:AddRightGroupbox('Text & Flags')
R:AddToggle('ESPName', { Text='Player name', Default=(Config.ESPName ~= false),
    Callback=function(v) Config.ESPName = v end })
R:AddDropdown('ESPNameMode', { Values={'Display','Username'}, Default=(Config.ESPNameMode or 'Display'),
    Text='Name source', Callback=function(v) Config.ESPNameMode = v end })
R:AddToggle('ESPNameHealthUnderline', { Text='Health underline', Default=(Config.ESPNameHealthUnderline or false),
    Callback=function(v) Config.ESPNameHealthUnderline = v end })
colourRow(R, 'Name', 'Name', GRAD_MODES, W, W, Color3.fromRGB(255,194,75))

R:AddDivider()
R:AddToggle('ESPDistance', { Text='Distance', Default=(Config.ESPDistance ~= false),
    Callback=function(v) Config.ESPDistance = v end })
R:AddToggle('ESPWeapon', { Text='Equipped weapon', Default=(Config.ESPWeapon or false),
    Callback=function(v) Config.ESPWeapon = v end })
colourRow(R, 'Info', 'Info', GRAD_MODES, W, W, Color3.fromRGB(255,158,75))

R:AddDivider()
R:AddDropdown('ESPFont', { Values={'Code','RobotoMono','Gotham','GothamBold','Arial','SourceSans'},
    Default=(Config.ESPFont or 'Code'), Text='Font',
    Callback=function(v) Config.ESPFont = v end })
R:AddSlider('ESPTextSize', { Text='Name size', Default=(Config.ESPTextSize or 14),
    Min=9, Max=24, Rounding=0, Callback=function(v) Config.ESPTextSize = math.floor(v) end })
R:AddSlider('ESPInfoTextSize', { Text='Info size', Default=(Config.ESPInfoTextSize or 12),
    Min=9, Max=22, Rounding=0, Callback=function(v) Config.ESPInfoTextSize = math.floor(v) end })
R:AddSlider('ESPTextScale', { Text='Text scale', Default=(Config.ESPTextScale or 1),
    Min=0.6, Max=1.6, Rounding=2, Callback=function(v) Config.ESPTextScale = v end })
R:AddToggle('ESPDeclutter', { Text='Declutter overlapping tags', Default=(Config.ESPDeclutter ~= false),
    Callback=function(v) Config.ESPDeclutter = v end })

R:AddDivider()
R:AddToggle('ESPFlagShield', { Text='SHIELD', Default=(Config.ESPFlagShield ~= false),
    Callback=function(v) Config.ESPFlagShield = v end })
R:AddToggle('ESPFlagLowHP', { Text='LOW', Default=(Config.ESPFlagLowHP ~= false),
    Callback=function(v) Config.ESPFlagLowHP = v end })
colourRow(R, 'Flags', 'Flag', {'PerFlag','Solid','Gradient'},
          Color3.fromRGB(255,194,75), Color3.fromRGB(255,194,75), Color3.fromRGB(255,70,85))


local RG = Tabs.ESP:AddRightGroupbox('Gradient & Chams')
RG:AddSlider('ESPGradientRotBox', { Text='Angle (box & bars)', Default=(Config.ESPGradientRotBox or 0),
    Min=0, Max=360, Rounding=0, Callback=function(v) Config.ESPGradientRotBox = math.floor(v) end })
RG:AddSlider('ESPGradientRotText', { Text='Angle (text)', Default=(Config.ESPGradientRotText or 90),
    Min=0, Max=360, Rounding=0, Callback=function(v) Config.ESPGradientRotText = math.floor(v) end })
RG:AddSlider('ESPGradientSpeed', { Text='Flow (0 = static)', Default=(Config.ESPGradientSpeed or 0),
    Min=0, Max=0.5, Rounding=2, Callback=function(v) Config.ESPGradientSpeed = v end })

RG:AddToggle('ESPChams', { Text='Player chams', Default=(Config.ESPChams or false),
    Callback=function(v) Config.ESPChams = v end })
local chDep = RG:AddDependencyBox()
chDep:AddToggle('ESPChamsVisSplit', { Text='Visible vs Occluded two-tone', Default=(Config.ESPChamsVisSplit or true),
    Callback=function(v) Config.ESPChamsVisSplit = v end })
chDep:AddSlider('ESPChamsFillTransparency', { Text='Fill transp.', Default=(Config.ESPChamsFillTransparency or 0.7),
    Min=0, Max=1, Rounding=2, Callback=function(v) Config.ESPChamsFillTransparency = v end })
chDep:AddSlider('ESPChamsOutlineTransparency', { Text='Outline transp.', Default=(Config.ESPChamsOutlineTransparency or 0.1),
    Min=0, Max=1, Rounding=2, Callback=function(v) Config.ESPChamsOutlineTransparency = v end })
chDep:SetupDependencies({ { Toggles.ESPChams, true } })

RG:AddDivider()
RG:AddSlider('ESPMaxDistance', { Text='Max distance', Default=(Config.ESPMaxDistance or 1200),
    Min=50, Max=3000, Rounding=0, Callback=function(v) Config.ESPMaxDistance = math.floor(v) end })
RG:AddSlider('ESPMaxPlayers', { Text='Max targets (0 = all)', Default=(Config.ESPMaxPlayers or 0),
    Min=0, Max=24, Rounding=0, Callback=function(v) Config.ESPMaxPlayers = math.floor(v) end })
RG:AddButton({ Text='Rebuild ESP Objects', Func=function() pcall(ESP.rebuildAll) end })

-- =========================================================
-- UI: CONFIGS TAB & FINAL INIT
-- =========================================================
local ConfigGroup = Tabs.Configs:AddLeftGroupbox("Menu")
ConfigGroup:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("MyScriptHub/specific-game")

-- Build the Config UI inside the Configs Tab
SaveManager:BuildConfigSection(Tabs.Configs)
ThemeManager:ApplyToTab(Tabs.Configs)

-- Initialize Modules
ESP.init()
Aimbot.init()
Trigger.init()

SaveManager:LoadAutoloadConfig()