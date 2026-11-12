-- =========================================================
-- LINORIA UI SETUP
-- =========================================================
local repo = 'https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/'
local Library, ThemeManager, SaveManager
do
    local files, pending = {}, 3
    local urls = { 'Library.lua', 'addons/ThemeManager.lua', 'addons/SaveManager.lua' }
    for i = 1, 3 do
        task.spawn(function()
            local got, body = pcall(function() return game:HttpGet(repo .. urls[i]) end)
            if got and type(body) == 'string' and #body > 0 then files[i] = body end
            pending = pending - 1
        end)
    end
    local deadline = tick() + 20
    while pending > 0 and tick() < deadline do task.wait() end
    for i = 1, 3 do
        if files[i] == nil then warn("[Engine] failed to fetch " .. urls[i]); return end
    end
    local src = files[1]
    local patched, n = src:gsub('if not FetchIcons then', 'if not Icons then')
    if n > 0 then src = patched end
    Library      = loadstring(src)()
    ThemeManager = loadstring(files[2])()
    SaveManager  = loadstring(files[3])()
end
if not Library then return end

local cloneref = clonereference or cloneref or function(x) return x end
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local VirtualInputMgr   = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Lighting          = game:GetService("Lighting")
local Workspace         = workspace
local Camera            = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end)
local lp                = Players.LocalPlayer
local isMobile          = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local Options = Library.Options or {}
local Toggles = Library.Toggles or {}
Library.Options = Options
Library.Toggles = Toggles

-- =========================================================
-- WAIT FOR GAME + MODULE LOADING
-- =========================================================
local _safePlayersCache = nil
local function getSafePlayers()
    if _safePlayersCache then return _safePlayersCache end
    local list = {}
    for _, p in ipairs(Players:GetChildren()) do
        if p:IsA("Player") then list[#list+1] = p end
    end
    _safePlayersCache = list
    return list
end
Players.PlayerAdded:Connect(function() _safePlayersCache = nil end)
Players.PlayerRemoving:Connect(function() _safePlayersCache = nil end)

local function waitForGameReady()
    repeat task.wait() until game:IsLoaded()
    if not lp then repeat task.wait() until Players.LocalPlayer; end
    if not lp:FindFirstChild("PlayerScripts") then
        repeat task.wait() until lp:FindFirstChild("PlayerScripts")
    end
    local deadline = tick() + 5
    while lp.Character == nil and tick() < deadline do task.wait() end
    return true
end
waitForGameReady()

local function safeRequire(path, timeout)
    if not path then return nil end
    timeout = timeout or 5
    local start = tick()
    while tick() - start < timeout do
        local ok, result = pcall(require, path)
        if ok then return result end
        task.wait(0.2)
    end
    return nil
end
local function waitModule(root, names, timeout)
    timeout = timeout or 10
    local obj = root
    for _, n in ipairs(names) do
        if not obj then return nil end
        local ok, child = pcall(function() return obj:WaitForChild(n, timeout) end)
        obj = ok and child or nil
    end
    return obj
end
local function awaitGameLoaded(moduleInst, timeout)
    if not moduleInst or type(getloadedmodules) ~= "function" then return end
    local deadline = tick() + (timeout or 15)
    repeat
        local ok, loaded = pcall(getloadedmodules)
        if ok and type(loaded) == "table" then
            for _, m in ipairs(loaded) do
                if m == moduleInst then return end
            end
        end
        task.wait(0.1)
    until tick() >= deadline
end
local function loadGameModule(root, names)
    local inst = waitModule(root, names)
    awaitGameLoaded(inst, 15)
    return safeRequire(inst)
end

local Rivals = { Ready = false }
local function resolveAll(jobs, timeout)
    local pending = #jobs
    for _, job in ipairs(jobs) do
        task.spawn(function() pcall(job); pending = pending - 1 end)
    end
    local deadline = tick() + (timeout or 25)
    while pending > 0 and tick() < deadline do task.wait() end
    return pending == 0
end
resolveAll({
    function() Rivals.Util      = loadGameModule(ReplicatedStorage, {"Modules","Utility"}) end,
    function() Rivals.Fighter   = loadGameModule(lp.PlayerScripts,  {"Controllers","FighterController"}) end,
    function() Rivals.Enums     = loadGameModule(ReplicatedStorage, {"Modules","EnumLibrary"}) end,
    function() Rivals.Cosmetics = loadGameModule(ReplicatedStorage, {"Modules","CosmeticLibrary"}) end,
    function() Rivals.ItemLib   = loadGameModule(ReplicatedStorage, {"Modules","ItemLibrary"}) end,
})
Rivals.Ready = (Rivals.Util ~= nil and Rivals.Fighter ~= nil)

local _weaponResolving = false
local hookGunModule
local function resolveWeaponModules()
    if _weaponResolving then return end
    if Rivals.Gun ~= nil and Rivals.Melee ~= nil and Rivals.Knife ~= nil then return end
    _weaponResolving = true
    task.spawn(function()
        resolveAll({
            function() if Rivals.Gun   == nil then Rivals.Gun   = loadGameModule(lp.PlayerScripts, {"Modules","ItemTypes","Gun"})   end end,
            function() if Rivals.Melee == nil then Rivals.Melee = loadGameModule(lp.PlayerScripts, {"Modules","ItemTypes","Melee"}) end end,
            function() if Rivals.Knife == nil then Rivals.Knife = loadGameModule(lp.PlayerScripts, {"Modules","Items","Knife"})     end end,
        })
        _weaponResolving = false
        if Rivals.Gun ~= nil and hookGunModule ~= nil then pcall(hookGunModule) end
    end)
end
resolveWeaponModules()
lp.CharacterAdded:Connect(function()
    task.wait(0.5)
    resolveWeaponModules()
    if Rivals.Ready and hookGunModule then hookGunModule() end
end)

-- =========================================================
-- CONFIG
-- =========================================================
local Config = {
    -- Silent Aim
    SilentAim = false, SilentAimVisCheck = false, SilentAimJitter = true,
    SilentAimTargetPart = "Head", SilentAimFOV = 250, AvoidDeflect = true,
    SilentAimStickiness = 0.05, SilentAimMultipoint = false,
    SilentAimMultipointCount = 5, SilentAimTorsoFallback = false,
    SilentAimHitChance = 85, SilentAimBodyMix = 25, SilentAimJitterDeg = 1.5,
    -- Aimbot
    Aimbot = false, AimbotVisCheck = true, AimbotKey = "MB2",
    AimbotSmoothness = 0, AimbotSmoothnessX = 0, AimbotSmoothnessY = 0,
    AimbotLinkAxes = true, AimbotJumpDamping = 40, AimbotCancelSprings = true,
    AimbotCurvedFlick = false, AimbotCurvedIntensity = 0.35, AimbotTrackAssist = 100,
    AimbotFOVDeg = 20, AimbotMaxSpeed = 0, AimbotDeadzoneDeg = 0, AimbotSwitchDeg = 2,
    AimbotStickiness = 0.15, AimbotForgetTime = 0.2, AimbotTargetPart = "Best",
    AimbotPriority = "Crosshair", AimbotSkipImmune = true, AimbotPrediction = false,
    AimbotShotOverride = false, AimbotShowFOV = false, AimbotShowLock = false,
    AimbotDebug = false, AimbotReactionMs = 0, AimbotNoiseDeg = 0, AimbotOvershoot = 0,
    AimbotDirectCamera = false,
    -- Triggerbot
    Trigger = false, TriggerKey = "Always", TriggerHeadOnly = false,
    TriggerScopeCheck = false, TriggerDelayMs = 0, TriggerRefireMs = 0, TriggerMaxDist = 400,
    -- Shared targeting
    MaxDistance = 1200, TeamCheck = true, PredictiveLead = true, LeadCap = 15,
    ServerProcessingMs = 30, ProjectileLead = false, ProjectileSpeed = 300,
    -- RAGE
    Rage = false, RageFireRateOverride = 0, RageRestoreWhileFiring = false,
    RageVoidMove = true, RageVoidMinStep = 25000, RageVoidJitterLocal = false,
    RageVoidJitterStuds = 2000, RageEyeMuzzleSep = 0.07, RageVoidDepth = "deep",
    RageGatePoison = true, RagePredictPrefire = true, RageSkipImmune = true,
    RagePredictResurface = true, RageAttackContinuity = true, RageKnifeBot = true,
    RageMeleeAsk = true, RageMeleeLog = false, RageKnifeCamForge = true,
    RageParkLift = false, RagePolarParity = true, RagePhysicsFlags = true,
    RageRestoreMode = "auto", RageCameraAnchor = true, RagePartGlue = false,
    RageGumMode = "on", RageGumVoidFire = true, RageAttackTranslocate = false,
    RageTapsPerFrame = 1, RagePrioritizeHackers = true, RageHideJitter = true,
    RageHPPriority = true, RageFastTargetSwitch = true, RageVisCheck = false,
    RageShieldBackstab = true, RageKnifeBackstab = true, RageKillPlaneBuffer = 200,
    RageLab = false, RageVoidPhase = true, RageMode = "Polar", RageDirectFire = true,
    RageRateLimit = false, RageTaps = 6, RageCombatOrbitRadius = 60,
    RageOrbitDwell = 0.30, RageCombatOrbitHeight = 8, RageCombatOrbitJitter = true,
    RagePBEyeUp = 3, RageOnEmpty = "Swap", RagePreferredSlot = "Primary",
    RageSwitchMelee = false, RageSwitchRateLimit = 0.06,
    RageWeaponPick = "Primary", RageGlueMode = "off",
    -- ESP
    ESP = false, ESPTeamCheck = true, ESPMaxDistance = 1200, ESPMaxPlayers = 0,
    ESPFont = "Code", ESPTextSize = 14, ESPInfoTextSize = 12, ESPHealthTextSize = 11,
    ESPTextScale = 1, ESPTextCasing = 1, ESPDistanceScaling = true,
    ESPDistanceScalingRef = 50, ESPCasingThickness = 1, ESPBoxScale = 1,
    ESPBox = true, ESPBoxStyle = "Full Box", ESPBoxBrackets = false,
    ESPCornerLength = 0.28, ESPBoxFill = false, ESPBoxThickness = 1,
    ESPName = true, ESPDistance = true, ESPWeapon = false, ESPHealth = true,
    ESPHealthNumberMode = "OnDamage", ESPSkeleton = false, ESPSkeletonThickness = 1,
    ESPChams = false, ESPTracers = false, ESPTracerThickness = 1, ESPTracerOrigin = "Bottom",
    ESPArrows = false, ESPFlagStaring = false, ESPFlagDeflect = true,
    ESPFlagShield = true, ESPFlagInvincible = true, ESPFlagLowHP = true,
    ESPHeadDot = false, ESPHeadDotSize = 4,
    ESPBoxColorMode = "Solid", ESPBoxColor = Color3.fromRGB(255, 255, 255),
    ESPBoxGradA = Color3.fromRGB(255, 59, 78), ESPBoxGradB = Color3.fromRGB(255, 194, 75),
    ESPBoxFillColor = Color3.fromRGB(255, 59, 78),
    ESPHealthColorMode = "Ramp", ESPHealthColor = Color3.fromRGB(61, 224, 122),
    ESPHealthGradA = Color3.fromRGB(255, 68, 54), ESPHealthGradB = Color3.fromRGB(61, 224, 122),
    ESPNameColorMode = "Solid", ESPNameColor = Color3.fromRGB(255, 255, 255),
    ESPNameGradA = Color3.fromRGB(255, 255, 255), ESPNameGradB = Color3.fromRGB(255, 194, 75),
    ESPInfoColorMode = "Solid", ESPInfoColor = Color3.fromRGB(255, 255, 255),
    ESPInfoGradA = Color3.fromRGB(255, 255, 255), ESPInfoGradB = Color3.fromRGB(255, 158, 75),
    ESPFlagColorMode = "PerFlag", ESPFlagColor = Color3.fromRGB(255, 194, 75),
    ESPFlagGradA = Color3.fromRGB(255, 194, 75), ESPFlagGradB = Color3.fromRGB(255, 70, 85),
    ESPSkeletonColorMode = "Solid", ESPSkeletonColor = Color3.fromRGB(255, 255, 255),
    ESPSkeletonGradA = Color3.fromRGB(255, 255, 255), ESPSkeletonGradB = Color3.fromRGB(120, 180, 255),
    ESPTracerColorMode = "Solid", ESPTracerColor = Color3.fromRGB(255, 255, 255),
    ESPTracerGradA = Color3.fromRGB(255, 255, 255), ESPTracerGradB = Color3.fromRGB(255, 59, 78),
    ESPMarkColorMode = "Solid", ESPMarkColor = Color3.fromRGB(255, 255, 255),
    ESPMarkGradA = Color3.fromRGB(255, 255, 255), ESPMarkGradB = Color3.fromRGB(255, 194, 75),
    ESPGradientSpeed = 0, ESPGradientRotBox = 0, ESPGradientRotText = 90,
    ESPHeadDotColor = Color3.fromRGB(255, 255, 255),
    ESPChamsFillColor = Color3.fromRGB(255, 59, 78),
    ESPChamsOutlineColor = Color3.fromRGB(255, 255, 255),
    ColorEnemy = Color3.fromRGB(255, 59, 78), ColorTeam = Color3.fromRGB(53, 215, 199),
    ColorEnemyOcc = Color3.fromRGB(168, 85, 96), ColorTeamOcc = Color3.fromRGB(92, 153, 147),
    ColorVisible = Color3.fromRGB(41, 224, 255),
    ESPDistNearColor = Color3.fromRGB(80, 255, 140), ESPDistFarColor = Color3.fromRGB(255, 70, 90),
    ESPBoxTransparency = 0, ESPBoxFillTransparency = 0.75, ESPNameTransparency = 0,
    ESPHealthTransparency = 0.1, ESPSkeletonTransparency = 0.2,
    ESPTracerTransparency = 0.35, ESPHeadDotTransparency = 0,
    ESPChamsFillTransparency = 0.6, ESPChamsOutlineTransparency = 0,
    ESPChamsStyle = "Shade", ESPNameMode = "Display", ESPFadeIn = true,
    ESPLookLine = false, ESPLookLineLength = 8, ESPHealthSmooth = true,
    ESPHealthGhost = true, ESPDeclutter = true, ESPChamsVisSplit = true,
    ESPAmmoBar = false, ESPHealthNumber = true,
    -- GameVisuals (Cosmetics)
    GameVisuals = false, GVUnlockAll = true, GVUnlockWeapons = false, GVWrapInverted = false,
    GVEveryone = false, GVBirthHook = true, GVFinisherClone = true, GVRemember = true,
    GVRankCharmOn = false, GVRankCharmRank = "", GVRankCharmLb = 0, GVEmotes = false,
    -- Spoofer
    SpooferNameEnabled = false, SpooferName = "ProPlayer", SpooferDisplayName = "ProPlayer",
    SpooferLevelEnabled = false, SpooferLevel = 100,
    SpooferCasualWinsEnabled = false, SpooferCasualWins = 500,
    SpooferRankedWinsEnabled = false, SpooferRankedWins = 250,
    SpooferRankedEloEnabled = false, SpooferRankedElo = 2400,
    SpooferWinPercentEnabled = false, SpooferWinPercent = 75,
    SpooferWinStreakEnabled = false, SpooferWinStreak = 25,
    SpooferFavoriteMapEnabled = false, SpooferFavoriteMap = "Arena",
}
if isMobile then Config.AimbotKey = "Always" end

-- =========================================================
-- STATE
-- =========================================================
local State = {
    ESPObjects = {}, PrimaryTarget = nil, SilentLastTarget = nil,
    AimbotTarget = nil, AimbotPart = nil, AimbotLastTarget = nil, AimbotLastTargetTime = 0,
    AimbotKeyHeld = false, AimbotFlickActive = false, AimbotSpringOffset = Vector2.zero,
    TargetLockTarget = nil, TargetLockTap = false,
    CamPos = Vector3.zero, Shots = 0, Hits = 0, Target = nil,
    RageRealCF = nil, RageRealChar = nil, RageTarget = nil,
    RageVoidCF = nil, RageVoidNext = 0, RageVoidBase = nil, RageVoidSteps = 0,
    RageLastFireTime = 0, RageReloadLast = 0, RageSwitchLast = 0,
    OrbitAngle = 0, OrbitVantage = nil, OrbitVantageUntil = 0,
    RageForging = false, RageLeakCanary = 0, RageTracerCanary = 0, RageBlankCanary = 0,
    RageOOBParkCanary = 0, RageHitsOn = 0, RageHitsOff = 0,
    RageOffFromSelf = 0, RageOffFromTarget = 0, ViewAngleForged = false,
    RageKnifeSwings = 0, RageKnifeStatus = "idle", RageRawSet = false,
    RagePhysRate = "off", RageParkDirty = false, RageLastParkPos = nil,
    RageParkLatchCanary = 0, RageLatchStuds = 0, RageOrderCanary = 0,
    RagePostPark = false, RageBelowPlaneFrames = 0, RageBelowPlaneLast = 0,
    RageBelowPlaneDeaths = 0, RageParkDriftFrames = 0, RageParkDrift = 0,
    RageParkDriftY = 0, RageEyeClampFrames = 0, RageParkClampFrames = 0,
    RageTranslocateBaits = 0, RageVoidFires = 0, RagePoisonBlips = 0,
    RagePreFires = 0, RagePredTarget = nil,
    RagePredHide = 0, RagePredHideN = 0, RagePredAtk = 0, RagePredAtkN = 0,
    RagePredPhase = "?", RagePredFor = 0, RagePredDue = 0, RagePredWindow = false,
    RagePredMag = 0, RageGumMode = "off", RageKnifeHintLast = 0,
    RageInMatch = false, RageStatus = "Idle",
    RageFireFromPos = nil, RageFireAimPos = nil, RageFireHitPart = nil,
    RageFireStamp = 0, RageDealtTotal = 0, RageFiring = false,
    RageVoidActive = false, RageTranslocating = false,
    RageTrueVelocityMap = {}, RageSuspectedProtection = {}, RageBacktrackBuf = {},
    RageCharTokens = {},
    RageGlueBound = false, RageGlueVerified = nil, RageImmuneOverride = 0,
    RageAutoTransport = "kicia", RageTransportSwitches = 0, RageLastLossAt = 0,
    AutoWeaponFails = 0,
    LastAttackWeapon = nil, LastAttackWeaponAt = 0,
}

-- =========================================================
-- HELPERS
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

local HEAD_PARTS    = { "HitboxHead", "HitboxHeadSmall", "Head" }
local TORSO_PARTS   = { "HitboxBody", "UpperTorso", "HumanoidRootPart", "LowerTorso" }
local CLOSEST_PARTS = {
    "HitboxHead","Head","UpperTorso","LowerTorso","HumanoidRootPart",
    "LeftHand","RightHand","LeftFoot","RightFoot",
    "LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg",
}

local function envIdOf(player)
    local id = nil
    pcall(function()
        local fc = Rivals.Fighter
        if fc == nil then return end
        local f = (player == lp) and fc.LocalFighter or (fc._player_to_fighter and fc._player_to_fighter[player])
        if f == nil then return end
        id = f:Get("EnvironmentID")
        if id == nil and f.Entity ~= nil then id = f.Entity:Get("EnvironmentID") end
    end)
    return id
end
local function isTeammate(player)
    if player == lp then return true end
    local myEnv, theirEnv = envIdOf(lp), envIdOf(player)
    if myEnv ~= nil and theirEnv ~= nil and myEnv ~= theirEnv then return true end
    local a = lp:GetAttribute("TeamID")
    local b = player:GetAttribute("TeamID")
    if a == nil or b == nil then
        if lp.Team ~= nil and player.Team ~= nil then return lp.Team == player.Team end
        return false
    end
    return a == b
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
local function getWeaponName(player)
    if not player or not player.Character then return "?" end
    local ok, res = pcall(function()
        if Rivals.Ready and Rivals.Fighter and Rivals.Fighter._player_to_fighter then
            local f = Rivals.Fighter._player_to_fighter[player]
            if f and f.EquippedItem and f.EquippedItem.Info then
                return f.EquippedItem.Info.Name
            end
        end
        return nil
    end)
    if ok and type(res) == "string" and res ~= "" then return res end
    local ok2, fallback = pcall(function()
        for _, c in ipairs(player.Character:GetChildren()) do
            if c:IsA("Model") and not c:FindFirstChildOfClass("Humanoid") then
                if c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart") then return c.Name end
            end
            if c:IsA("Tool") then return c.Name end
        end
        return "?"
    end)
    return (ok2 and type(fallback) == "string") and fallback or "?"
end
local function pickPart(char, mode)
    if not char then return nil end
    if mode == "Closest" then
        local best, bestDist = nil, math.huge
        local vp     = Camera.ViewportSize
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
local visParams = RaycastParams.new()
visParams.FilterType = Enum.RaycastFilterType.Exclude
local _visFilterChar = nil
local function isVisible(worldPos)
    local origin = Camera.CFrame.Position
    local _vc = lp.Character
    if _vc ~= _visFilterChar then
        visParams.FilterDescendantsInstances = { _vc }
        _visFilterChar = _vc
    end
    local result = Workspace:Raycast(origin, worldPos - origin, visParams)
    if not result then return true end
    local hitModel = result.Instance and result.Instance:FindFirstAncestorOfClass("Model")
    if hitModel and Players:GetPlayerFromCharacter(hitModel) then return true end
    return (result.Position - worldPos).Magnitude < 3
end

-- Deflect tracking
local DEFLECT_ANIM_IDS = {
    ["14761240825"] = true, ["14761220206"] = true,
    ["14761234917"] = true, ["14761221711"] = true, ["14761223422"] = true, ["14761225204"] = true, ["14761232380"] = true,
    ["90436105114997"] = true, ["90797895557136"] = true, ["77995180947430"] = true, ["111943779640553"] = true,
    ["131072510521727"] = true, ["132022220827223"] = true, ["116315405171252"] = true, ["110358509711635"] = true, ["98242486936084"] = true, ["81132288854196"] = true,
    ["123293403148826"] = true, ["136354716301184"] = true, ["120567011479119"] = true, ["92502373956550"] = true, ["83541611040586"] = true, ["92773106977434"] = true,
    ["75844592081515"] = true, ["75381142568185"] = true,
}
local function isDeflectingAnim(player)
    if not player or not player.Character then return false end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then return false end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        if track.Name:lower():find("deflect") then return true end
        local anim = track.Animation
        local id = anim and anim.AnimationId
        if id then
            local num = id:match("(%d+)")
            if num and DEFLECT_ANIM_IDS[num] then return true end
        end
    end
    return false
end
local _deflecting = {}
local _deflGen    = {}
local _deflHookLive = false
local DEFLECT_CLEAR_PAD = 0.05
local function isDeflecting(player)
    if not player then return false end
    if _deflecting[player.UserId] then return true end
    if _deflHookLive then return false end
    return isDeflectingAnim(player)
end
;(function()
    local function recordDeflect(self)
        local fighter = self and self.ClientFighter
        local plr = fighter and fighter.Player
        if not plr then return end
        local uid = plr.UserId
        local dur = self.Info and self.Info.DeflectDuration
        if type(dur) ~= "number" then dur = 0.1 end
        _deflecting[uid] = true
        local gen = (_deflGen[uid] or 0) + 1
        _deflGen[uid] = gen
        task.delay(dur + DEFLECT_CLEAR_PAD, function()
            if _deflGen[uid] == gen then _deflecting[uid] = nil end
        end)
    end
    task.spawn(function()
        local ok, katana = pcall(loadGameModule, lp.PlayerScripts, {"Modules", "Items", "Katana"})
        if not ok or type(katana) ~= "table" or type(katana._StartDeflecting) ~= "function" then return end
        local orig = shared._JH_KatanaDeflOrig
        if not orig then orig = clonefunction(katana._StartDeflecting) end
        shared._JH_KatanaMod      = katana
        shared._JH_KatanaDeflOrig = orig
        if setreadonly then pcall(setreadonly, katana, false) end
        katana._StartDeflecting = function(self, ...)
            pcall(recordDeflect, self)
            return orig(self, ...)
        end
        _deflHookLive = true
    end)
end)()

-- Spawn protection
local _invincible = {}
local _invincEnt  = {}
local function isSpawnProtected(player)
    if not player then return false end
    if not (Rivals.Ready and Rivals.Fighter) then return false end
    local map = Rivals.Fighter._player_to_fighter
    if not map then return false end
    local f = map[player]
    if not f then return false end
    local e = f.Entity
    if not e then return false end
    local uid = player.UserId
    if _invincEnt[uid] ~= e then
        _invincible[uid] = nil
        local ok = pcall(function()
            local live = e:Get("IsInvincible") == true
            e:GetDataChangedSignal("IsInvincible"):Connect(function()
                _invincible[uid] = e:Get("IsInvincible") == true
            end)
            _invincible[uid] = live
        end)
        if ok then _invincEnt[uid] = e end
    end
    return _invincible[uid] == true
end

-- Weapon class helpers
local KATANA_NAMES = { "katana", "saber", "lightning bolt", "evil trident", "tridant", "devil's trident", "linked sword", "keytana", "cutlass", "swordfish", "riptide" }
local function isKatana(player)
    local w = getWeaponName(player):lower()
    for _, n in ipairs(KATANA_NAMES) do
        if w:find(n, 1, true) then return true end
    end
    return isDeflecting(player)
end
local KNIFE_NAMES = { "knife", "karambit", "balisong", "chancla", "machete", "candy cane", "armature", "daggers", "axe" }
local function isEnemyKnife(player)
    if not player then return false end
    local w = getWeaponName(player):lower()
    for _, n in ipairs(KNIFE_NAMES) do
        if w:find(n, 1, true) then return true end
    end
    return false
end
local function isLocalKnife()
    local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
    if lf and lf.EquippedItem then
        local name = lf.EquippedItem.Name:lower()
        for _, n in ipairs(KNIFE_NAMES) do
            if name:find(n, 1, true) then return true end
        end
    end
    return false
end
local function isRiotShield(player)
    local w = getWeaponName(player):lower()
    return w:find("riot shield") or w:find("energy shield") or w:find("tombstone shield")
        or w:find("broken surfboard", 1, true) or w == "door" or w == "sled" or w == "masterpiece"
end
local function ownsRiotShield(player)
    if not player then return false end
    local ok, res = pcall(function()
        if not (Rivals.Ready and Rivals.Fighter and Rivals.Fighter._player_to_fighter) then return false end
        local f = Rivals.Fighter._player_to_fighter[player]
        local items = f and f.Items
        if type(items) ~= "table" then return false end
        for _, it in items do
            local n = nil
            if type(it) == "table" then
                n = it.Name
                if n == nil and it.Info then n = it.Info.Name end
            end
            if type(n) == "string" then
                local low = n:lower()
                if low:find("riot shield") or low:find("energy shield") or low:find("tombstone shield") then
                    return true
                end
            end
        end
        return false
    end)
    return ok and res == true
end

local function inMatch()
    local envOk = false
    pcall(function()
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        if lf ~= nil and lf:Get("EnvironmentID") ~= nil and lf:IsAlive() then envOk = true end
    end)
    if envOk then return true end
    if lp:GetAttribute("TeamID") ~= nil then return true end
    if lp.Team ~= nil then return true end
    local lf = Rivals.Ready and Rivals.Fighter and Rivals.Fighter.LocalFighter
    if lf then
        local ok, objId = pcall(function() return lf.EquippedItem and lf.EquippedItem:Get("ObjectID") end)
        if ok and objId then return true end
    end
    return false
end

local function isSanePos(p)
    return p == p
        and math.abs(p.X) < 100000
        and math.abs(p.Y) < 100000
        and math.abs(p.Z) < 100000
end
local function posInPart(pos, part)
    if not part or not part.Parent then return false end
    local lpv = part.CFrame:PointToObjectSpace(pos)
    local s = part.Size * 0.5
    return math.abs(lpv.X) <= s.X and math.abs(lpv.Y) <= s.Y and math.abs(lpv.Z) <= s.Z
end
local function posIsOOB(pos)
    local ok, result = pcall(function()
        for _, p in ipairs(CollectionService:GetTagged("OutOfBoundsSafePart")) do
            if posInPart(pos, p) then return false end
        end
        for _, p in ipairs(CollectionService:GetTagged("OutOfBoundsPart")) do
            if posInPart(pos, p) then return true end
        end
        return false
    end)
    return ok and result == true
end

-- Velocity map
local _sharedVelMap = {}
;(function()
    local _svPos, _svTime = {}, {}
    local _svAccum = 0
    local SV_INTERVAL = 1 / 30
    local function velTrackerStep(dt)
        if not (Config.Aimbot or Config.SilentAim or Config.Rage) then return end
        _svAccum = _svAccum + (dt or 0)
        if _svAccum < SV_INTERVAL then return end
        _svAccum = 0
        local now = tick()
        for _, p in ipairs(getSafePlayers() or {}) do
            if p ~= lp and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local pos = hrp.Position
                    local lt  = _svTime[p]
                    if _svPos[p] and lt then
                        local d = now - lt
                        if d > 0 then
                            local v = (pos - _svPos[p]) / d
                            if v.Magnitude < 500 then _sharedVelMap[p] = v end
                        end
                    end
                    _svPos[p]  = pos
                    _svTime[p] = now
                end
            end
        end
    end
    if shared._JH_velConn then pcall(function() shared._JH_velConn:Disconnect() end) end
    shared._JH_velConn = RunService.Heartbeat:Connect(velTrackerStep)
end)()

local function calculateLead(targetChar, fromPos, wantLead)
    if wantLead == nil then wantLead = Config.PredictiveLead end
    if not targetChar then return Vector3.new() end
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return Vector3.new() end
    local lat = (lp:GetNetworkPing() or 0.05) + ((Config.ServerProcessingMs or 30) / 1000)
    if Config.ProjectileLead and (Config.ProjectileSpeed or 0) > 0 then
        lat = lat + (hrp.Position - fromPos).Magnitude / Config.ProjectileSpeed
    end
    local lead = Vector3.new()
    if wantLead then
        local ply     = Players:GetPlayerFromCharacter(targetChar)
        local trueVel = hrp.AssemblyLinearVelocity
        local calcVel = ply and (_sharedVelMap[ply] or State.RageTrueVelocityMap[ply])
        if calcVel then
            if (trueVel - calcVel).Magnitude > 25 then trueVel = calcVel end
        else
            if trueVel.Magnitude > 100 then trueVel = Vector3.new() end
        end
        if trueVel.Magnitude > 120 then trueVel = Vector3.new() end
        local md = hum.MoveDirection
        if md.Magnitude > 0.1 then
            lead = lead + Vector3.new(trueVel.X, 0, trueVel.Z) * lat
        end
        lead = lead + Vector3.new(0, trueVel.Y * lat, 0)
    end
    local cap = Config.LeadCap or 15
    if lead.Magnitude > cap then lead = lead.Unit * cap end
    return lead
end

local function isValidTarget(player, checkVis, keepDeflect, rageScope)
    if not player or player == lp then return false end
    if Config.TeamCheck and isTeammate(player) then return false end
    if not isAlive(player) then return false end
    if Config.AvoidDeflect and not keepDeflect and isDeflecting(player) then return false end
    if Config.RageSkipImmune and not rageScope and isSpawnProtected(player) then return false end
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local sane = isSanePos(hrp.Position)
    if not rageScope then
        if not sane then return false end
        local myChar = lp.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myRoot and (hrp.Position - myRoot.Position).Magnitude > Config.MaxDistance then return false end
    end
    if checkVis and sane and not isVisible(hrp.Position) then return false end
    return true
end

local function selectTarget(opts)
    opts = opts or {}
    local fov         = opts.fov or 90
    local checkVis    = opts.checkVis or false
    local mode        = opts.partMode or "Head"
    local sticky      = opts.stickyTarget
    local stickyBonus = opts.stickyBonus or 0
    local vp     = Camera.ViewportSize
    local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    local best, bestPart, bestScore = nil, nil, math.huge
    for _, player in ipairs(getSafePlayers()) do
        if player ~= lp and isValidTarget(player, false) then
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

local function isMouseButtonDown()
    if isMobile then return true end
    return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
end
local function isInputActive(key)
    if key == "MB1" then return isMouseButtonDown() end
    if key == "MB2" then
        if isMobile then return true end
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    end
    if key == "Always" then return true end
    local kc = Enum.KeyCode[key]
    if kc and not isMobile then return UserInputService:IsKeyDown(kc) end
    return false
end

local function silentPartVisible(part)
    if not part or not part:IsA("BasePart") then return false end
    if not Config.SilentAimMultipoint then return isVisible(part.Position) end
    if isVisible(part.Position) then return true end
    local n = math.max(1, math.floor(Config.SilentAimMultipointCount or 5))
    local r = math.min(part.Size.X, part.Size.Y, part.Size.Z) * 0.4
    for i = 1, n do
        local a   = (i / n) * math.pi * 2
        local off = Vector3.new(math.cos(a) * r, ((i % 2 == 0) and 0.5 or -0.5) * r, math.sin(a) * r)
        if isVisible(part.Position + off) then return true end
    end
    return false
end
local function pickSilentPart(char, primary)
    if not char then return primary end
    if silentPartVisible(primary) then return primary end
    for _, name in ipairs(HEAD_PARTS) do
        local p = char:FindFirstChild(name)
        if p and p ~= primary and silentPartVisible(p) then return p end
    end
    if Config.SilentAimTorsoFallback then
        for _, name in ipairs(TORSO_PARTS) do
            local p = char:FindFirstChild(name)
            if p and silentPartVisible(p) then return p end
        end
    end
    return primary
end

-- =========================================================
-- VISUALS (Stub + Spoofer)
-- =========================================================
local Visuals = {}
Visuals.notifyTarget = function() end
Visuals.worldSpark = function() end
Visuals.FX = { onHit = function() end, onIncoming = function() end }
Visuals.refreshViewModel = function() end

;(function()
    local _spooferActive = false
    local _spooferConns = {}
    local _isSpoofing = {}
    local _origText = {}
    local function anySpoofOn()
        return Config.SpooferNameEnabled or Config.SpooferLevelEnabled or Config.SpooferCasualWinsEnabled
            or Config.SpooferRankedWinsEnabled or Config.SpooferRankedEloEnabled
            or Config.SpooferWinPercentEnabled or Config.SpooferWinStreakEnabled
            or Config.SpooferFavoriteMapEnabled
    end
    local function escPat(s) return (s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")) end
    local function escRep(s) return (s:gsub("%%", "%%%%")) end
    local function belongsToLp(obj)
        local node, depth = obj, 0
        while node ~= nil and node ~= game and depth < 12 do
            if node:IsA("BillboardGui") then
                local anchor = node.Adornee or node.Parent
                while anchor ~= nil and not anchor:IsA("Model") do anchor = anchor.Parent end
                if anchor ~= nil then
                    local plr = Players:GetPlayerFromCharacter(anchor)
                    if plr ~= nil then return plr == lp end
                end
            elseif node:IsA("Model") then
                local plr = Players:GetPlayerFromCharacter(node)
                if plr ~= nil then return plr == lp end
            end
            local asId = tonumber(node.Name)
            if asId ~= nil and Players:GetPlayerByUserId(asId) ~= nil then return asId == lp.UserId end
            node = node.Parent; depth = depth + 1
        end
        return true
    end
    local ALLOWED_TEXT_NAMES = {
        DisplayName = true, Username = true, Name = true, Handle = true, Nametag = true,
        Title = true, TitleText = true, Value = true, Text = true, Label = true,
        Wins = true, WinRate = true, Streak = true, WinStreak = true, ELO = true, Level = true,
    }
    local function applyTextSpoof(obj)
        if not (obj and obj.Parent) then return end
        if _isSpoofing[obj] then return end
        local text = obj.Text
        if not text or #text == 0 then return end
        local newText = text
        local changed = false
        if Config.SpooferNameEnabled then
            local fakeName = Config.SpooferName or "ProPlayer"
            local fakeDisp = Config.SpooferDisplayName or fakeName
            local realName = lp.Name
            local realDisp = lp.DisplayName
            if realDisp and #realDisp > 0 and newText:find(realDisp, 1, true) then
                newText = newText:gsub(escPat(realDisp), escRep(fakeDisp))
                changed = true
            end
            if realName and #realName > 0 and newText:find(realName, 1, true) then
                newText = newText:gsub(escPat(realName), escRep(fakeName))
                changed = true
            end
        end
        local pn = obj.Parent and obj.Parent.Name or ""
        local on = obj.Name
        local isVal = (on == "Value" or on == "Text")
        local is_level = (pn == "Level" or pn == "LevelContainer") and (isVal or on == "Level")
        local is_wins = (on == "Wins" or pn == "Wins" or pn == "WinsContainer") and (isVal or on == "Wins")
        local is_elo = (pn == "ELO" or pn == "RankedElo" or pn == "Rating" or pn == "Rank") and (isVal or on == "ELO")
        local is_winrate = (on == "WinRate" or on == "win rate" or pn == "WinRate") and (isVal or on == "WinRate")
        local is_streak = (pn == "Streak" or pn == "WinStreak" or pn == "StreakContainer" or on == "Streak" or on == "WinStreak")
            and (isVal or on == "Streak" or on == "WinStreak")
        if (is_level or is_wins or is_elo or is_winrate or is_streak) and belongsToLp(obj) then
            local sVal = nil
            if Config.SpooferLevelEnabled and is_level then sVal = tostring(Config.SpooferLevel or 100)
            elseif Config.SpooferCasualWinsEnabled and is_wins then sVal = tostring(Config.SpooferCasualWins or 500)
            elseif Config.SpooferRankedEloEnabled and is_elo then sVal = tostring(Config.SpooferRankedElo or 2400)
            elseif Config.SpooferWinPercentEnabled and is_winrate then sVal = tostring(Config.SpooferWinPercent or 75) .. "%"
            elseif Config.SpooferWinStreakEnabled and is_streak then sVal = tostring(Config.SpooferWinStreak or 25)
            end
            if sVal ~= nil and newText ~= sVal then newText = sVal; changed = true end
        end
        if changed and newText ~= text then
            if _origText[obj] == nil then _origText[obj] = text end
            _isSpoofing[obj] = true
            pcall(function() obj.Text = newText end)
            _isSpoofing[obj] = nil
        end
    end
    local function registerTextObj(obj)
        if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then return end
        if _spooferConns[obj] ~= nil then return end
        local txt = nil
        pcall(function() txt = obj.Text end)
        local mine = type(txt) == "string" and #txt > 0
            and ((#lp.Name > 0 and txt:find(lp.Name, 1, true) ~= nil)
              or (#lp.DisplayName > 0 and txt:find(lp.DisplayName, 1, true) ~= nil))
        if not ALLOWED_TEXT_NAMES[obj.Name] and not mine then return end
        applyTextSpoof(obj)
        _spooferConns[obj] = obj:GetPropertyChangedSignal("Text"):Connect(function() applyTextSpoof(obj) end)
        obj.Destroying:Once(function()
            local c = _spooferConns[obj]
            if c ~= nil then pcall(function() c:Disconnect() end) end
            _spooferConns[obj] = nil; _origText[obj] = nil; _isSpoofing[obj] = nil
        end)
    end
    local function stopGuiNameSpoofer()
        for k, c in pairs(_spooferConns) do
            pcall(function() c:Disconnect() end)
            _spooferConns[k] = nil
        end
        for obj, t in pairs(_origText) do
            pcall(function()
                if obj.Parent ~= nil then
                    _isSpoofing[obj] = true; obj.Text = t; _isSpoofing[obj] = nil
                end
            end)
            _origText[obj] = nil
        end
        _isSpoofing = {}
        _spooferActive = false
    end
    local function startGuiNameSpoofer()
        if _spooferActive or not anySpoofOn() then return end
        _spooferActive = true
        local pGui = lp:FindFirstChildOfClass("PlayerGui")
        if pGui then
            for _, inst in ipairs(pGui:GetDescendants()) do registerTextObj(inst) end
            _spooferConns["pGuiDesc"] = pGui.DescendantAdded:Connect(registerTextObj)
        end
        pcall(function()
            local cGui = cloneref(game:GetService("CoreGui"))
            if cGui then
                for _, inst in ipairs(cGui:GetDescendants()) do registerTextObj(inst) end
                _spooferConns["cGuiDesc"] = cGui.DescendantAdded:Connect(registerTextObj)
            end
        end)
        if Config.SpooferNameEnabled then
            _spooferConns["wsDesc"] = Workspace.DescendantAdded:Connect(function(inst)
                if inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
                    for _, child in ipairs(inst:GetDescendants()) do registerTextObj(child) end
                    if _spooferConns[inst] == nil then
                        _spooferConns[inst] = inst.DescendantAdded:Connect(registerTextObj)
                    end
                end
            end)
        end
    end
    local function refreshGuiNameSpoofer()
        if not anySpoofOn() then stopGuiNameSpoofer(); return end
        if not _spooferActive then startGuiNameSpoofer(); return end
        for obj in pairs(_spooferConns) do
            if typeof(obj) == "Instance" then pcall(applyTextSpoof, obj) end
        end
    end
    local _pinnedAttrs = {}
    local _pinConns = {}
    local function pinAttr(attrName, val)
        _pinnedAttrs[attrName] = val
        if not _pinConns[attrName] then
            _pinConns[attrName] = lp:GetAttributeChangedSignal(attrName):Connect(function()
                local targetVal = _pinnedAttrs[attrName]
                if targetVal ~= nil and lp:GetAttribute(attrName) ~= targetVal then
                    pcall(function() lp:SetAttribute(attrName, targetVal) end)
                end
            end)
        end
        pcall(function() lp:SetAttribute(attrName, val) end)
    end
    local function unpinAttr(attrName)
        _pinnedAttrs[attrName] = nil
        if _pinConns[attrName] then
            _pinConns[attrName]:Disconnect()
            _pinConns[attrName] = nil
        end
    end
    local function unpinAll()
        local names = {}
        for k in pairs(_pinConns) do names[#names + 1] = k end
        for _, k in ipairs(names) do unpinAttr(k) end
    end
    local function updatePlayerSpoofer()
        if not anySpoofOn() then unpinAll(); return end
        pcall(function()
            local PDC = Rivals and Rivals.PlayerDataController
            if not PDC then
                pcall(function()
                    local scr = lp:FindFirstChild("PlayerScripts")
                    local ctrls = scr and scr:FindFirstChild("Controllers")
                    local pdcMod = ctrls and ctrls:FindFirstChild("PlayerDataController")
                    if pdcMod then PDC = require(pdcMod) end
                end)
            end
            local cData = PDC and PDC.CurrentData and PDC.CurrentData.Data
            local sLev = tonumber(Config.SpooferLevel) or 100
            local sElo = tonumber(Config.SpooferRankedElo) or 2400
            local sCWins = tonumber(Config.SpooferCasualWins) or 500
            local sRWins = tonumber(Config.SpooferRankedWins) or 250
            local sWP = (tonumber(Config.SpooferWinPercent) or 75) / 100
            local sStreak = tonumber(Config.SpooferWinStreak) or 25
            local sMap = tostring(Config.SpooferFavoriteMap or "Arena")
            if Config.SpooferLevelEnabled then
                pinAttr("Level", sLev)
                if cData then cData.Level = sLev end
            else unpinAttr("Level") end
            if Config.SpooferRankedEloEnabled then
                pinAttr("DisplayELO", sElo); pinAttr("RankedCurrentELO", sElo)
                if cData then
                    cData.RankedCurrentELO = sElo
                    if cData.Seasons then
                        for _, season in pairs(cData.Seasons) do
                            if season.RankedPerformances then
                                for _, perf in pairs(season.RankedPerformances) do
                                    perf.CurrentELO = sElo
                                end
                            end
                        end
                    end
                end
            else
                unpinAttr("DisplayELO"); unpinAttr("RankedCurrentELO")
            end
            if Config.SpooferCasualWinsEnabled then
                pinAttr("CasualWins", sCWins); pinAttr("StatisticDuelsWins", sCWins)
                if cData then cData.CasualWins = sCWins end
            else
                unpinAttr("CasualWins"); unpinAttr("StatisticDuelsWins")
            end
            if Config.SpooferRankedWinsEnabled then
                pinAttr("RankedWins", sRWins)
                if cData then cData.RankedWins = sRWins end
            else unpinAttr("RankedWins") end
            if Config.SpooferWinPercentEnabled then
                pinAttr("CasualWinPercent", sWP); pinAttr("RankedWinPercent", sWP)
                pinAttr("StatisticDuelsWinRate", sWP * 100); pinAttr("WinRate", sWP * 100)
                if cData then cData.CasualWinPercent = sWP; cData.RankedWinPercent = sWP end
            else
                unpinAttr("CasualWinPercent"); unpinAttr("RankedWinPercent")
                unpinAttr("StatisticDuelsWinRate"); unpinAttr("WinRate")
            end
            if Config.SpooferWinStreakEnabled then
                pinAttr("StatisticDuelsWinStreak", sStreak); pinAttr("WinStreak", sStreak)
                pinAttr("CurrentWinStreak", sStreak)
                if cData then
                    cData.StatisticDuelsWinStreak = sStreak
                    cData.WinStreak = sStreak
                    cData.CurrentWinStreak = sStreak
                end
            else
                unpinAttr("StatisticDuelsWinStreak"); unpinAttr("WinStreak"); unpinAttr("CurrentWinStreak")
            end
            if Config.SpooferFavoriteMapEnabled then
                pinAttr("FavoriteMap", sMap)
                if cData then cData.FavoriteMap = sMap end
            else unpinAttr("FavoriteMap") end
        end)
    end
    Visuals.applyGuiNameSpoof = refreshGuiNameSpoofer
    Visuals.updatePlayerSpoofer = updatePlayerSpoofer
    function Visuals.initSpoofer()
        updatePlayerSpoofer()
        refreshGuiNameSpoofer()
    end
end)()

-- =========================================================
-- GAMEVISUALS (Cosmetics)
-- =========================================================
local GameVisuals = {}
GameVisuals.uiAlive = true
;(function()
    local NONE_COSMETIC   = "NONE_COSMETIC"
    local RANDOM_COSMETIC = "RANDOM_COSMETIC"
    local POLL_S = 0.35
    local REBUILD_COOLDOWN = 1.5
    local captureInstall, captureRestore
    local saveSoon, saveDrain
    local _log, _lastNote = {}, nil
    local function note(msg)
        State.GVStatus = msg
        if msg == _lastNote then return end
        _lastNote = msg
        table.insert(_log, os.date("%H:%M:%S") .. "  " .. msg)
        if #_log > 60 then table.remove(_log, 1) end
    end
    function GameVisuals.history(n)
        local out, want = {}, n or 12
        for i = #_log, math.max(1, #_log - want + 1), -1 do table.insert(out, _log[i]) end
        if #out == 0 then table.insert(out, "nothing yet") end
        return out
    end
    local ENUM = {}
    local function enumOf(key)
        if ENUM[key] ~= nil then return ENUM[key] end
        local e = nil
        pcall(function() e = Rivals.Enums:ToEnum(key) end)
        ENUM[key] = e
        return e
    end
    local M = { cvm=nil, ci=nil, pdc=nil, fctrl=nil, ilib=nil, cent=nil,
                cslot=nil, copts=nil, shop=nil }
    local function moduleAt(path)
        local m = nil
        pcall(function() m = loadGameModule(lp.PlayerScripts, path) end)
        return m
    end
    local function repModuleAt(path)
        local m = nil
        pcall(function() m = loadGameModule(ReplicatedStorage, path) end)
        return m
    end
    local _resolving, _resolveAt, _optTries = false, 0, 0
    local function resolveModules()
        if M.cvm ~= nil and M.ci ~= nil and M.pdc ~= nil and _optTries >= 3 then return end
        if _resolving then return end
        local now = tick()
        if now < _resolveAt then return end
        _resolveAt = now + 5
        _resolving = true
        if M.cvm == nil then
            M.cvm = moduleAt({"Modules","ClientReplicatedClasses","ClientFighter","ClientItem","ClientViewModel"})
        end
        if M.ci   == nil then M.ci   = moduleAt({"Modules","ClientReplicatedClasses","ClientFighter","ClientItem"}) end
        if M.cent == nil then M.cent = moduleAt({"Modules","ClientReplicatedClasses","ClientEntity"}) end
        if M.pdc  == nil then M.pdc  = moduleAt({"Controllers","PlayerDataController"}) end
        if _optTries < 3 then
            _optTries = _optTries + 1
            if M.cslot == nil then M.cslot = moduleAt({"Modules","CosmeticSlot"}) end
            if M.copts == nil then
                M.copts = moduleAt({"Modules","UserInterface","Equipment","Interface","Customize","Options"})
            end
            if M.shop  == nil then M.shop  = repModuleAt({"Modules","ShopLibrary"}) end
            if M.seasonLib == nil then M.seasonLib = repModuleAt({"Modules","SeasonLibrary"}) end
            if M.emoteCtl == nil then M.emoteCtl = moduleAt({"Controllers","EmoteController"}) end
        end
        if M.fctrl == nil then M.fctrl = Rivals.Fighter end
        if M.ilib  == nil then M.ilib  = Rivals.ItemLib end
        _resolving = false
    end
    GameVisuals.Choices = {}
    local function selectionFor(itemName) return GameVisuals.Choices[itemName] end
    local _maskTarget, _maskInner, _maskConn = nil, nil, nil
    local _spoof = {}
    local _favOverride = {}
    local _rsPatch, _captured, _captureBound = {}, 0, 0
    local DECOY, _lastFn = nil, nil
    local _saveAt, _fsWarned = nil, false
    local function maskActive()
        if _maskTarget == nil then return false end
        local cur = nil
        pcall(function() cur = M.pdc.CurrentData end)
        return cur == _maskTarget
    end
    local function maskRemove()
        if _maskTarget == nil then return end
        local target, inner = _maskTarget, _maskInner
        _maskTarget, _maskInner = nil, nil
        pcall(function() rawset(target, "Data", inner) end)
    end
    local function maskInstall()
        resolveModules()
        if M.pdc == nil then return false, "PlayerDataController did not resolve" end
        local cur = nil
        pcall(function() cur = M.pdc.CurrentData end)
        if cur == nil then return false, "no CurrentData yet (still loading)" end
        if cur == _maskTarget then return true, nil end
        maskRemove()
        local inner = rawget(cur, "Data")
        if type(inner) ~= "table" then return false, "CurrentData.Data is not a table" end
        local proxy = setmetatable({}, {
            __index = function(_, k)
                local p = _spoof[k]
                if p ~= nil then return p(inner[k]) end
                return inner[k]
            end,
            __newindex = function(_, k, v) inner[k] = v end,
            __iter = function() return next, inner end,
            __len  = function() return #inner end,
        })
        rawset(cur, "Data", proxy)
        _maskTarget, _maskInner = cur, inner
        return true, nil
    end
    local function refresh(key)
        pcall(function()
            local cur = M.pdc.CurrentData
            if cur ~= nil then cur:Replicate(key) end
        end)
    end
    local function refreshAll()
        refresh("CosmeticInventory"); refresh("FavoritedCosmetics")
        refresh("WeaponInventory"); refresh("EquippedEmotes")
    end
    local function everyCosmetic(real)
        local out = {}
        if type(real) == "table" then for k, v in pairs(real) do out[k] = v end end
        pcall(function()
            local cos = Rivals.Cosmetics.Cosmetics
            if type(cos) ~= "table" then return end
            for name in pairs(cos) do if out[name] == nil then out[name] = true end end
        end)
        return out
    end
    local function everyFavorite(real)
        local out = {}
        if type(real) == "table" then for k, v in pairs(real) do out[k] = v end end
        for weapon, marks in pairs(_favOverride) do
            local merged = {}
            if type(out[weapon]) == "table" then for k, v in pairs(out[weapon]) do merged[k] = v end end
            for k, v in pairs(marks) do merged[k] = v end
            out[weapon] = merged
        end
        return out
    end
    local function mergeChoices(entry, weapon)
        local slot = GameVisuals.Choices[weapon]
        if slot == nil then return entry end
        for _, kind in pairs({ "Skin", "Charm", "Wrap", "Finisher" }) do
            local sel = slot[kind]
            if sel ~= nil then entry[kind] = sel end
        end
        return entry
    end
    local function ownableWeapons()
        local out = {}
        pcall(function()
            if M.shop == nil or type(M.shop.GetReleasedOwnableWeapons) ~= "function" then return end
            local list = M.shop:GetReleasedOwnableWeapons()
            if type(list) ~= "table" then return end
            for _, name in pairs(list) do
                if type(name) == "string" then table.insert(out, name) end
            end
        end)
        return out
    end
    local function weaponInventory(real)
        local out, seen = {}, {}
        if type(real) == "table" then
            for i, entry in pairs(real) do
                if type(entry) == "table" then
                    local copy = {}
                    for k, v in pairs(entry) do copy[k] = v end
                    if type(copy.Name) == "string" then
                        seen[copy.Name] = true
                        mergeChoices(copy, copy.Name)
                    end
                    out[i] = copy
                else out[i] = entry end
            end
        end
        if Config.GVUnlockWeapons == true then
            for _, wname in pairs(ownableWeapons()) do
                if not seen[wname] then
                    seen[wname] = true
                    table.insert(out, mergeChoices({ Name = wname, Level = 1, XP = 0, IsFavorited = false }, wname))
                end
            end
        end
        return out
    end
    local function applyMaskFields()
        if Config.GVUnlockAll == true then _spoof.CosmeticInventory = everyCosmetic
        else _spoof.CosmeticInventory = nil end
        if Config.GVUnlockAll == true or next(_favOverride) ~= nil then
            _spoof.FavoritedCosmetics = everyFavorite
        else _spoof.FavoritedCosmetics = nil end
        if next(GameVisuals.Choices) ~= nil or Config.GVUnlockWeapons == true then
            _spoof.WeaponInventory = weaponInventory
        else _spoof.WeaponInventory = nil end
    end
    local function maskNeeded()
        return Config.GVUnlockAll == true or Config.GVUnlockWeapons == true
            or next(GameVisuals.Choices) ~= nil or next(_favOverride) ~= nil
    end
    local function watchPlayerData()
        if _maskConn ~= nil then return end
        pcall(function()
            local sig = M.pdc.PlayerDataAdded
            if sig == nil then return end
            _maskConn = sig:Connect(function()
                if not maskNeeded() then return end
                task.defer(function()
                    if maskInstall() then applyMaskFields(); refreshAll() end
                end)
            end)
        end)
    end
    local function syncMask()
        applyMaskFields()
        if not maskNeeded() then maskRemove(); refreshAll(); return true, nil end
        local ok, why = maskInstall()
        if not ok then return false, why end
        watchPlayerData(); refreshAll(); return true, nil
    end
    function GameVisuals.setUnlockAll(on)
        Config.GVUnlockAll = (on == true)
        local ok, why = syncMask()
        if ok then note("unlock all " .. tostring(Config.GVUnlockAll))
        else note("unlock all: " .. tostring(why)) end
    end
    function GameVisuals.setUnlockWeapons(on)
        Config.GVUnlockWeapons = (on == true)
        local ok, why = syncMask()
        if ok then note("unlock weapons " .. tostring(Config.GVUnlockWeapons))
        else note("unlock weapons: " .. tostring(why)) end
    end
    local function charmMetadata(charmName)
        if type(charmName) ~= "string" or string.match(charmName, "^Season %d+$") == nil then return nil end
        return GameVisuals.resolveRankStamp()
    end
    local function cloneCosmetic(name, ctype, inverted)
        local base = nil
        pcall(function() base = Rivals.Cosmetics.Cosmetics[name] end)
        if type(base) ~= "table" then return nil end
        local data = {}
        for k, v in pairs(base) do data[k] = v end
        data.Name = name
        if data.Type == nil then data.Type = ctype end
        data.Seed = math.random(1, 1000000)
        local id = enumOf(name)
        if id ~= nil then data.Enum = id; data.ObjectID = id end
        if inverted == true then data.Inverted = true end
        if ctype == "Charm" then
            local md = charmMetadata(name)
            if md ~= nil then data.Metadata = md end
        end
        return data
    end
    local function rankOverrideRecord(liveCharm)
        if Config.GVRankCharmOn ~= true then return nil end
        local nm = nil
        if type(liveCharm) == "table" then nm = liveCharm.Name end
        local want = charmMetadata(nm)
        if want == nil then return nil end
        local have = (type(liveCharm) == "table") and liveCharm.Metadata or nil
        if have ~= nil and have.SeasonELO == want.SeasonELO
            and have.SeasonLeaderboardRank == want.SeasonLeaderboardRank then return nil end
        return cloneCosmetic(nm, "Charm")
    end
    local function randomCosmetic(ctype, weapon, inverted)
        local pool = {}
        pcall(function()
            local cos = Rivals.Cosmetics.Cosmetics
            local inv = M.pdc and M.pdc:Get("CosmeticInventory")
            if type(cos) ~= "table" then return end
            for name, entry in pairs(cos) do
                if type(entry) == "table" and entry.Type == ctype and entry.Hidden ~= true then
                    local owned = true
                    pcall(function() owned = Rivals.Cosmetics:OwnsCosmetic(inv, name, weapon) and true or false end)
                    if owned and (ctype ~= "Skin" or entry.ItemName == weapon) then
                        table.insert(pool, name)
                    end
                end
            end
        end)
        if #pool == 0 then return nil end
        return cloneCosmetic(pool[math.random(#pool)], ctype, inverted)
    end
    local function resolveSel(weapon, ctype)
        local slot = GameVisuals.Choices[weapon]
        local sel = slot and slot[ctype]
        if sel == nil then return nil end
        if sel.Name == NONE_COSMETIC then return nil end
        if sel.Name == RANDOM_COSMETIC then
            if sel.Resolved == nil then
                sel.Resolved = randomCosmetic(ctype, weapon, sel.Inverted)
            end
            return sel.Resolved
        end
        return sel
    end
    local function hasIntent(weapon, ctype)
        local slot = GameVisuals.Choices[weapon]
        return slot ~= nil and slot[ctype] ~= nil
    end
    local function buildPayload(weapon, dst, key)
        if hasIntent(weapon, "Skin") then
            local s = resolveSel(weapon, "Skin")
            dst[key("Name")] = (s ~= nil) and s.Name or weapon
        end
        if hasIntent(weapon, "Wrap") then dst[key("Wrap")] = resolveSel(weapon, "Wrap") end
        if hasIntent(weapon, "Charm") then dst[key("Charm")] = resolveSel(weapon, "Charm") end
        return dst
    end
    local function identityKey(k) return k end
    local HOOKS = {}
    local function hookField(tbl, key, make)
        if tbl == nil then return false end
        local orig = nil
        pcall(function() orig = tbl[key] end)
        if type(orig) ~= "function" then return false end
        for _, h in pairs(HOOKS) do if h.tbl == tbl and h.key == key then return true end end
        local inherited = false
        pcall(function() inherited = (rawget(tbl, key) == nil) end)
        local ok = false
        pcall(function() tbl[key] = make(orig); ok = true end)
        if not ok then return false end
        table.insert(HOOKS, { tbl = tbl, key = key, orig = orig, inherited = inherited })
        return true
    end
    local function hooksRestore()
        for i = #HOOKS, 1, -1 do
            local h = HOOKS[i]
            pcall(function()
                if h.inherited then h.tbl[h.key] = nil
                else h.tbl[h.key] = h.orig end
            end)
            HOOKS[i] = nil
        end
    end
    local function origOf(tbl, key)
        if tbl == nil then return nil end
        for _, h in pairs(HOOKS) do
            if h.tbl == tbl and h.key == key then return h.orig end
        end
        local fn = nil
        pcall(function() fn = tbl[key] end)
        return fn
    end
    local function ownedByUs(item)
        local owner = nil
        pcall(function() owner = item.ClientFighter.Player end)
        if owner == lp then return true end
        if Config.GVEveryone == true and owner ~= nil then return true end
        return false
    end
    local function enumKey(k)
        local e = enumOf(k)
        if e ~= nil then return e end
        return k
    end
    local function styleSerial(serial, weapon)
        if type(serial) ~= "table" or type(weapon) ~= "string" then return false end
        if selectionFor(weapon) == nil then return false end
        local touched = false
        pcall(function()
            local dk = enumOf("Data")
            local slot = nil
            if dk ~= nil and type(serial[dk]) == "table" then slot = serial[dk]
            elseif type(serial.Data) == "table" then slot = serial.Data end
            if slot == nil then return end
            buildPayload(weapon, slot, enumKey)
            touched = true
        end)
        return touched
    end
    local _building = nil
    local _oidWeapon, _oidAt = {}, 0
    local function atIdentity2(fn)
        local prev = 8
        if getthreadidentity ~= nil then pcall(function() prev = getthreadidentity() end) end
        local setter = setthreadidentity
        if setter == nil then setter = setidentity end
        if setter ~= nil then pcall(setter, 2) end
        local ok, err = pcall(fn)
        if setter ~= nil then pcall(setter, prev) end
        return ok, err
    end
    local FINISHER_FOLDER = nil
    local function finisherFolder()
        if FINISHER_FOLDER == nil then
            pcall(function() FINISHER_FOLDER = ReplicatedStorage.Modules.Finishers end)
        end
        return FINISHER_FOLDER
    end
    local function cloneCharacter(model)
        local copy = nil
        pcall(function()
            local was = model.Archivable
            model.Archivable = true
            copy = model:Clone()
            model.Archivable = was
        end)
        return copy
    end
    local function hideCorpse(model)
        pcall(function()
            for _, d in pairs(model:GetDescendants()) do
                if d:IsA("BasePart") then d.Transparency = 1
                elseif d:IsA("Decal") then d:Destroy()
                elseif d:IsA("BillboardGui") then d.Enabled = false end
            end
        end)
    end
    local _finisherCopies = setmetatable({}, { __mode = "k" })
    local function playFinisherOnClone(ent, model, mod, isFinal, killer, serial)
        local copy = cloneCharacter(model)
        if copy == nil then return false end
        local hum, root = nil, nil
        pcall(function()
            hum  = copy:FindFirstChildOfClass("Humanoid")
            root = copy:FindFirstChild("HumanoidRootPart")
        end)
        if hum == nil or root == nil then pcall(function() copy:Destroy() end); return false end
        hideCorpse(model)
        pcall(function()
            for _, d in pairs(copy:GetDescendants()) do
                if d:IsA("BillboardGui") or d:IsA("SurfaceGui") or d:IsA("Highlight") then d:Destroy() end
            end
        end)
        local ok = false
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            hum.Health = 0
            local parts = {}
            for _, c in pairs(copy:GetChildren()) do
                if c:IsA("BasePart") then
                    pcall(function() c.CollisionGroup = "Players" end)
                    table.insert(parts, c)
                end
            end
            for i = 1, #parts do
                for j = i + 1, #parts do
                    local nc = Instance.new("NoCollisionConstraint")
                    nc.Part0 = parts[i]; nc.Part1 = parts[j]; nc.Parent = parts[i]
                end
            end
            copy:PivotTo(model:GetPivot())
            copy.Parent = model.Parent
            ok = true
        end)
        if not ok then pcall(function() copy:Destroy() end); return false end
        pcall(function()
            model.Destroying:Once(function()
                if copy.Parent ~= nil then copy:Destroy() end
            end)
        end)
        local prevCopy = rawget(_finisherCopies, ent)
        if prevCopy ~= nil and prevCopy ~= copy and prevCopy.Parent ~= nil then
            pcall(function() prevCopy:Destroy() end)
        end
        rawset(_finisherCopies, ent, copy)
        local fin = nil
        atIdentity2(function()
            local prev = rawget(ent, "_current_finisher")
            if prev ~= nil then pcall(prev.Destroy, prev) end
            fin = mod.new(hum, isFinal, killer)
            rawset(ent, "_current_finisher", fin)
            fin:SetSerial(serial)
            task.spawn(function() pcall(fin.PlayServer, fin) end)
            task.spawn(function() pcall(fin.PlayClient, fin) end)
        end)
        if fin == nil then pcall(function() copy:Destroy() end); return false end
        return true
    end
    local function hooksInstall()
        resolveModules()
        if Config.GVBirthHook == false then return false, "birth hook disabled in config" end
        local n = 0
        if hookField(M.ci, "_CreateViewModel", function(orig)
            return function(item, serial)
                local weapon = nil
                pcall(function() weapon = item.Name end)
                local mine = ownedByUs(item)
                _building = mine and weapon or nil
                if mine and weapon ~= nil then pcall(styleSerial, serial, weapon) end
                local ok, res = pcall(orig, item, serial)
                _building = nil
                if not ok then error(res, 0) end
                return res
            end
        end) then n = n + 1 end
        if hookField(M.cvm, "new", function(orig)
            return function(serial, item)
                local weapon = _building
                if weapon == nil and item ~= nil then
                    pcall(function() if ownedByUs(item) then weapon = item.Name end end)
                end
                if weapon ~= nil then pcall(styleSerial, serial, weapon) end
                local vm = orig(serial, item)
                if vm ~= nil and weapon ~= nil and resolveSel(weapon, "Wrap") ~= nil then
                    local upd = nil
                    pcall(function() upd = M.cvm._UpdateWrap end)
                    if type(upd) == "function" then
                        task.spawn(function()
                            pcall(upd, vm)
                            task.wait(0.1)
                            if rawget(vm, "_destroyed") ~= true then pcall(upd, vm) end
                        end)
                    end
                end
                return vm
            end
        end) then n = n + 1 end
        if hookField(M.cvm, "GetWrap", function(orig)
            return function(vm)
                local weapon, mine = nil, false
                pcall(function()
                    local item = vm.ClientItem
                    weapon = item.Name
                    mine = ownedByUs(item)
                end)
                if mine and weapon ~= nil and hasIntent(weapon, "Wrap") then
                    return resolveSel(weapon, "Wrap")
                end
                return orig(vm)
            end
        end) then n = n + 1 end
        if hookField(M.fctrl, "GetWrap", function(orig)
            return function(ctrl, oid)
                local res = orig(ctrl, oid)
                if res ~= nil then return res end
                local weapon = _oidWeapon and _oidWeapon[tostring(oid)] or nil
                if weapon == nil then return nil end
                return resolveSel(weapon, "Wrap")
            end
        end) then n = n + 1 end
        if hookField(M.ilib, "GetViewModelImageFromWeaponData", function(orig)
            return function(lib, wdata, hires)
                if type(wdata) == "table" and type(wdata.Name) == "string" then
                    local skin = resolveSel(wdata.Name, "Skin")
                    if skin ~= nil then
                        local img = nil
                        pcall(function()
                            local info = lib.ViewModels[skin.Name]
                            if info ~= nil then
                                img = hires and info.ImageHighResolution or info.Image
                                if img == nil then img = info.Image end
                            end
                        end)
                        if img ~= nil then return img end
                    end
                end
                return orig(lib, wdata, hires)
            end
        end) then n = n + 1 end
        if hookField(M.cent, "ReplicateFromServer", function(orig)
            return function(ent, action, ...)
                if action ~= "FinisherEffect" then return orig(ent, action, ...) end
                local args = { ... }
                local killer = args[3]
                local isUs = false
                pcall(function()
                    if typeof(killer) == "Instance" then isUs = (killer == lp)
                    elseif type(killer) == "number" then isUs = (killer == lp.UserId)
                    elseif type(killer) == "string" then isUs = (killer:lower() == lp.Name:lower()) end
                end)
                if not isUs then return orig(ent, action, ...) end
                local held = nil
                pcall(function()
                    local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
                    local it = lf and lf.EquippedItem
                    if it ~= nil then held = it.Name end
                end)
                local fin, weapon = nil, nil
                local atkW = State.LastAttackWeapon
                if type(atkW) ~= "string" or tick() - (State.LastAttackWeaponAt or 0) > 30 then atkW = nil end
                for _, w in pairs({ atkW, held, GameVisuals.lastWeapon }) do
                    if fin == nil and type(w) == "string" then
                        fin = resolveSel(w, "Finisher")
                        if fin ~= nil then weapon = w end
                    end
                end
                if fin == nil then
                    for w in pairs(GameVisuals.Choices) do
                        if fin == nil then
                            fin = resolveSel(w, "Finisher")
                            if fin ~= nil then weapon = w end
                        end
                    end
                end
                if fin == nil then return orig(ent, action, ...) end
                local rendered = false
                pcall(function() rendered = ent:IsRendered() end)
                if not rendered then return orig(ent, action, ...) end
                local mod, model = nil, nil
                pcall(function()
                    local folder = finisherFolder()
                    local node = folder and folder:FindFirstChild(tostring(fin.Name)) or nil
                    if node ~= nil then atIdentity2(function() mod = require(node) end) end
                    model = rawget(ent, "Model")
                end)
                if type(mod) ~= "table" or type(mod.new) ~= "function" or model == nil then
                    return orig(ent, action, ...)
                end
                if Config.GVFinisherClone == false then return orig(ent, action, ...) end
                if playFinisherOnClone(ent, model, mod, args[2], args[3], args[4]) then return end
                return orig(ent, action, ...)
            end
        end) then n = n + 1 end
        if n == 0 then return false, "no hook target resolved (modules not loaded yet?)" end
        return true, n
    end
    local function rebuildOidMap()
        local now = tick()
        if now < _oidAt then return end
        _oidAt = now + 5
        pcall(function()
            local f = Rivals.Fighter:GetFighter(lp)
            if f == nil or type(f.Items) ~= "table" then return end
            for _, item in pairs(f.Items) do
                local oid = nil
                pcall(function() oid = item:Get("ObjectID") end)
                if oid ~= nil then _oidWeapon[tostring(oid)] = item.Name end
            end
        end)
    end
    local _rebuildAt = setmetatable({}, { __mode = "k" })
    local _forceRebuild = false
    local _lastRefusal = {}
    local _rebuildFails = setmetatable({}, { __mode = "k" })
    local _rebuildSeen  = setmetatable({}, { __mode = "k" })
    local function liveTriple(vm)
        local name, charm, wrap = nil, nil, nil
        pcall(function()
            local src = rawget(vm, "Data")
            if type(src) ~= "table" then return end
            name = src.Name; charm = src.Charm; wrap = src.Wrap
        end)
        return name, charm, wrap
    end
    local function sameSub(a, b)
        if a == nil and b == nil then return true end
        if a == nil or b == nil then return false end
        return a.Name == b.Name
    end
    local INTENT_OF = { Name = "Skin", Charm = "Charm", Wrap = "Wrap" }
    local function wants(base, dataKey) return hasIntent(base, INTENT_OF[dataKey]) end
    local function rebuildPayload(base, vm)
        local liveName, liveCharm, liveWrap = liveTriple(vm)
        local raw = {}
        if hasIntent(base, "Skin") then
            local s = resolveSel(base, "Skin")
            raw[enumKey("Name")] = (s ~= nil) and s.Name or base
        else raw[enumKey("Name")] = liveName or base end
        if hasIntent(base, "Charm") then
            raw[enumKey("Charm")] = resolveSel(base, "Charm")
        else
            local forced = rankOverrideRecord(liveCharm)
            raw[enumKey("Charm")] = forced or liveCharm
        end
        if hasIntent(base, "Wrap") then
            raw[enumKey("Wrap")] = resolveSel(base, "Wrap")
        else raw[enumKey("Wrap")] = liveWrap end
        return raw
    end
    local function payloadKeysAreEnums(raw)
        for _, k in pairs({ "Name", "Charm", "Wrap" }) do
            if rawget(raw, k) ~= nil and enumOf(k) ~= k then return false, k end
        end
        return true, nil
    end
    local function adoptViewModel(item, fresh, arms)
        pcall(function() rawset(item, "ViewModel", fresh) end)
        if arms ~= nil then
            atIdentity2(function() M.cvm.SetArmsData(fresh, table.unpack(arms, 1, arms.n)) end)
        end
        atIdentity2(function() M.cvm.Equip(fresh, true) end)
    end
    local function usableReplacement(fresh, vm)
        if fresh == nil or fresh == vm then return false end
        local ok = false
        pcall(function()
            ok = (rawget(fresh, "_destroyed") ~= true) and (rawget(fresh, "Model") ~= nil)
        end)
        return ok
    end
    local function tryBuild(create, item, serial, vm)
        local fresh = nil
        atIdentity2(function() fresh = create(item, serial) end)
        if fresh == nil then pcall(function() fresh = rawget(item, "ViewModel") end) end
        if usableReplacement(fresh, vm) then return fresh end
        return nil
    end
    local function dropViewModel(drop, vm)
        pcall(function()
            if rawget(vm, "_destroyed") ~= true then atIdentity2(function() drop(vm) end) end
        end)
    end
    local function armsDataOf(item)
        local packed = nil
        pcall(function()
            local f = item.ClientFighter
            if f == nil then return end
            local get = f.GetArmsData
            if type(get) ~= "function" then return end
            packed = table.pack(get(f))
        end)
        return packed
    end
    local function rebuildViewModel(item, base, vm)
        if Config.GVBirthHook == false then return false, "style at construction is off", false end
        if State.RageFiring == true then return false, nil, true end
        local now = tick()
        if not _forceRebuild and now < (_rebuildAt[item] or 0) then return false, nil, true end
        local fails = _rebuildFails[item]
        if not _forceRebuild and fails ~= nil and fails >= 3 and _rebuildSeen[item] == vm then
            return false, "constructor keeps refusing — lands on next spawn", false
        end
        local create = origOf(M.ci, "_CreateViewModel")
        if type(create) ~= "function" then return false, "_CreateViewModel missing — needs a respawn", false end
        local drop = nil
        pcall(function() drop = M.cvm.Destroy end)
        if type(drop) ~= "function" then return false, "Destroy missing — needs a respawn", false end
        local equip = nil
        pcall(function() equip = M.cvm.Equip end)
        if type(equip) ~= "function" then return false, "Equip missing — needs a respawn", false end
        local raw = rebuildPayload(base, vm)
        local keysOk, badKey = payloadKeysAreEnums(raw)
        if not keysOk then return false, "no enum for '" .. tostring(badKey) .. "' — lands on next spawn", false end
        _rebuildAt[item] = now + REBUILD_COOLDOWN
        local arms = armsDataOf(item)
        local serial = { Data = raw }
        local prevField = nil
        pcall(function() prevField = rawget(item, "ViewModel") end)
        pcall(function() rawset(item, "ViewModel", nil) end)
        local fresh = tryBuild(create, item, serial, vm)
        if fresh ~= nil then
            adoptViewModel(item, fresh, arms)
            dropViewModel(drop, vm)
            _rebuildFails[item] = nil; _rebuildSeen[item] = nil
            return true, nil, false
        end
        pcall(function() rawset(item, "ViewModel", prevField) end)
        _rebuildFails[item] = (fails or 0) + 1
        _rebuildSeen[item] = vm
        return false, "constructor refused — lands on next spawn", false
    end
    local function writeData(obj, raw, base)
        if obj == nil then return false end
        local wrote = false
        for _, key in pairs({ "Name", "Charm", "Wrap" }) do
            if wants(base, key) then
                local ok = false
                pcall(function() obj:SetReplicate(key, raw[key]); ok = true end)
                if not ok then
                    pcall(function()
                        local d = rawget(obj, "Data")
                        if type(d) == "table" then d[key] = raw[key]; ok = true end
                    end)
                end
                if ok then wrote = true end
            end
        end
        return wrote
    end
    local function applyWrapLive(vm, wrap)
        local data = nil
        pcall(function() data = rawget(vm, "Data") end)
        if type(data) ~= "table" then return false end
        local upd = nil
        pcall(function() upd = M.cvm._UpdateWrap end)
        if type(upd) ~= "function" then return false end
        rawset(data, "Wrap", wrap)
        atIdentity2(function() upd(vm) end)
        return true
    end
    local function applyToItem(item, base)
        local vm = nil
        pcall(function() vm = item.ViewModel end)
        if vm == nil then return false end
        local sel = selectionFor(base)
        if sel == nil then return true end
        local curName, curCharm, curWrap = liveTriple(vm)
        if curName == nil then return false end
        local raw = buildPayload(base, { Name = base }, identityKey)
        if raw == nil then raw = { Name = base } end
        if wants(base, "Wrap") and not sameSub(curWrap, raw.Wrap) then
            applyWrapLive(vm, raw.Wrap)
        end
        local needName  = wants(base, "Name")  and curName ~= raw.Name
        local needCharm = wants(base, "Charm") and not sameSub(curCharm, raw.Charm)
        if not needName and not needCharm then return true end
        local rok, rwhy, transient = rebuildViewModel(item, base, vm)
        writeData(item, raw, base)
        if transient ~= true then
            local nowVm = nil
            pcall(function() nowVm = item.ViewModel end)
            writeData(nowVm or vm, raw, base)
        end
        if transient ~= true then _lastRefusal[base] = nil end
        if rwhy ~= nil and not rok then _lastRefusal[base] = rwhy end
        return true
    end
    local function itemsOf(player)
        local items = nil
        pcall(function()
            local f = Rivals.Fighter:GetFighter(player)
            if f ~= nil and type(f.Items) == "table" then items = f.Items end
        end)
        if items == nil then
            pcall(function()
                local map = Rivals.Fighter._player_to_fighter
                local f = map and map[player]
                if f ~= nil and type(f.Items) == "table" then items = f.Items end
            end)
        end
        return items
    end
    local function applyToPlayer(player)
        local items = itemsOf(player)
        if items == nil then return 0 end
        local n = 0
        for _, item in pairs(items) do
            if type(item) == "table" then
                local base = nil
                pcall(function() base = item.Name end)
                if type(base) == "string" and selectionFor(base) ~= nil then
                    if applyToItem(item, base) then n = n + 1 end
                end
            end
        end
        return n
    end
    function GameVisuals.apply()
        if Config.GameVisuals ~= true then return 0 end
        resolveModules(); rebuildOidMap()
        local n = applyToPlayer(lp)
        if Config.GVEveryone == true then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= lp then n = n + applyToPlayer(p) end
            end
        end
        State.GVApplied = n
        return n
    end
    local function noneSlot()
        return { Skin = { Name = NONE_COSMETIC }, Charm = { Name = NONE_COSMETIC },
                 Wrap = { Name = NONE_COSMETIC }, Finisher = { Name = NONE_COSMETIC } }
    end
    function GameVisuals.restore()
        for weapon in pairs(GameVisuals.Choices) do GameVisuals.Choices[weapon] = noneSlot() end
        _forceRebuild = true
        pcall(GameVisuals.apply)
        _forceRebuild = false
        GameVisuals.Choices = {}
        pcall(syncMask)
        note("reset")
        saveSoon()
    end
    local _conn, _last, _loaded = nil, 0, false
    function GameVisuals.enable()
        Config.GameVisuals = true
        resolveModules()
        local hok, hwhy = hooksInstall()
        if hok then note("hooks bound (" .. tostring(hwhy) .. ")")
        else note("hooks: " .. tostring(hwhy)) end
        local cok, cwhy = captureInstall()
        if not cok then note("menu capture unavailable (" .. tostring(cwhy) .. ")") end
        local mok, mwhy = syncMask()
        if not mok then note("mask: " .. tostring(mwhy)) end
        if Config.GVRemember ~= false and not _loaded then
            _loaded = true
            local lok, lwhy = GameVisuals.loadConfig()
            if not lok and lwhy ~= "no saved cosmetics" then note("load: " .. tostring(lwhy)) end
        end
        if _conn ~= nil then return end
        _conn = RunService.Heartbeat:Connect(function()
            if Config.GameVisuals ~= true then return end
            local now = tick()
            if now - _last < POLL_S then return end
            _last = now
            if #HOOKS == 0 and Config.GVBirthHook ~= false then pcall(hooksInstall) end
            if _captureBound < 2 and Config.GVBirthHook ~= false then pcall(captureInstall) end
            if maskNeeded() and not maskActive() then pcall(syncMask) end
            pcall(GameVisuals.apply)
            saveDrain()
        end)
    end
    function GameVisuals.disable()
        Config.GameVisuals = false
        if _saveAt ~= nil then _saveAt = nil; pcall(GameVisuals.saveConfig) end
        _loaded = false
        if _conn ~= nil then _conn:Disconnect(); _conn = nil end
        if _maskConn ~= nil then pcall(function() _maskConn:Disconnect() end); _maskConn = nil end
        captureRestore()
        for weapon in pairs(GameVisuals.Choices) do GameVisuals.Choices[weapon] = noneSlot() end
        _forceRebuild = true
        pcall(applyToPlayer, lp)
        _forceRebuild = false
        GameVisuals.Choices = {}
        hooksRestore()
        _favOverride = {}
        _spoof.CosmeticInventory  = nil
        _spoof.FavoritedCosmetics = nil
        _spoof.WeaponInventory    = nil
        maskRemove()
        note("off")
    end
    local CAT = nil
    local function sortTail(t)
        local head = table.remove(t, 1)
        table.sort(t)
        table.insert(t, 1, head)
        table.insert(t, 2, "Random")
    end
    local function buildCatalog()
        if CAT ~= nil then return end
        CAT = { Skin = { "None" }, Charm = { "None" }, Wrap = { "None" }, Finisher = { "None" },
                weapons = { "None" }, byWeapon = {}, owner = {} }
        pcall(function()
            local cos = Rivals.Cosmetics.Cosmetics
            if type(cos) ~= "table" then return end
            for name, entry in pairs(cos) do
                if type(entry) == "table" and entry.Hidden ~= true then
                    local t = entry.Type
                    if t == "Skin" and type(entry.ItemName) == "string" then
                        local item = entry.ItemName
                        CAT.owner[name] = item
                        CAT.owner[item .. " | " .. name] = item
                        table.insert(CAT.Skin, item .. " | " .. name)
                        if CAT.byWeapon[item] == nil then
                            CAT.byWeapon[item] = { "None" }
                            table.insert(CAT.weapons, item)
                        end
                        table.insert(CAT.byWeapon[item], name)
                    elseif CAT[t] ~= nil then
                        table.insert(CAT[t], name)
                    end
                end
            end
        end)
        sortTail(CAT.Skin); sortTail(CAT.Charm); sortTail(CAT.Wrap); sortTail(CAT.Finisher)
        local head = table.remove(CAT.weapons, 1)
        table.sort(CAT.weapons)
        table.insert(CAT.weapons, 1, head)
        for _, list in pairs(CAT.byWeapon) do sortTail(list) end
    end
    function GameVisuals.listOf(kind) buildCatalog(); return CAT[kind] or { "None" } end
    function GameVisuals.skinList()  return GameVisuals.listOf("Skin")  end
    function GameVisuals.charmList() return GameVisuals.listOf("Charm") end
    function GameVisuals.wrapList()  return GameVisuals.listOf("Wrap")  end
    function GameVisuals.finisherList() return GameVisuals.listOf("Finisher") end
    function GameVisuals.weaponList() buildCatalog(); return CAT.weapons end
    function GameVisuals.skinsFor(item)
        buildCatalog()
        local list = CAT.byWeapon[item]
        if list == nil then return { "None" } end
        return list
    end
    local _weapon = nil
    GameVisuals.lastWeapon = nil
    function GameVisuals.setWeapon(name)
        if name == nil or name == "None" then _weapon = nil else _weapon = name end
        GameVisuals.lastWeapon = _weapon
    end
    local function heldItemName()
        local base = nil
        pcall(function()
            local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
            local it = lf and lf.EquippedItem
            if it ~= nil then base = it.Name end
        end)
        if type(base) == "string" then return base end
        return _weapon
    end
    function GameVisuals.setFor(weapon, kind, name, inverted)
        if type(weapon) ~= "string" or type(kind) ~= "string" then return end
        buildCatalog()
        local slot = GameVisuals.Choices[weapon]
        if slot == nil then slot = {}; GameVisuals.Choices[weapon] = slot end
        if name == nil or name == "None" or name == NONE_COSMETIC then
            slot[kind] = { Name = NONE_COSMETIC }
        elseif name == "Random" or name == RANDOM_COSMETIC then
            slot[kind] = { Name = RANDOM_COSMETIC, Type = kind, Inverted = inverted == true }
        else
            local rec = cloneCosmetic(name, kind, inverted)
            if rec == nil then note("unknown " .. kind .. ": " .. tostring(name)); return end
            slot[kind] = rec
        end
        GameVisuals.lastWeapon = weapon
        note(weapon .. " " .. kind .. " = " .. tostring(name))
        pcall(syncMask)
        pcall(GameVisuals.apply)
        saveSoon()
    end
    function GameVisuals.setSkin(label)
        buildCatalog()
        if label == nil or label == "None" then
            if _weapon ~= nil then GameVisuals.setFor(_weapon, "Skin", nil) end
            return
        end
        if label == "Random" then
            local w = _weapon or heldItemName()
            if w == nil then return end
            GameVisuals.setFor(w, "Skin", "Random")
            return
        end
        local item = CAT.owner[label]
        if item == nil then return end
        local skin = label
        local bar = string.find(label, " | ", 1, true)
        if bar ~= nil then skin = string.sub(label, bar + 3) end
        GameVisuals.setFor(item, "Skin", skin)
    end
    function GameVisuals.setOn(kind, name)
        local base = _weapon or heldItemName()
        if base == nil then return end
        local inv = nil
        if kind == "Wrap" then inv = Config.GVWrapInverted == true end
        GameVisuals.setFor(base, kind, name, inv)
    end
    function GameVisuals.setCharm(name)    GameVisuals.setOn("Charm", name)    end
    function GameVisuals.setWrap(name)     GameVisuals.setOn("Wrap", name)     end
    function GameVisuals.setFinisher(name) GameVisuals.setOn("Finisher", name) end
    function GameVisuals.setWrapInverted(on)
        Config.GVWrapInverted = (on == true)
        for _, slot in pairs(GameVisuals.Choices) do
            local w = slot.Wrap
            if type(w) == "table" and w.Name ~= NONE_COSMETIC then
                w.Inverted = Config.GVWrapInverted
                if type(w.Resolved) == "table" then w.Resolved.Inverted = Config.GVWrapInverted end
            end
        end
        pcall(GameVisuals.apply)
        saveSoon()
    end
    local RANK_FALLBACK = { "Bronze 1","Bronze 2","Bronze 3","Silver 1","Silver 2","Silver 3",
        "Gold 1","Gold 2","Gold 3","Platinum 1","Platinum 2","Platinum 3",
        "Diamond 1","Diamond 2","Diamond 3","Onyx 1","Onyx 2","Onyx 3","Nemesis","Archnemesis" }
    local RANK_ELO_FALLBACK = { ["Bronze 1"]=0,["Bronze 2"]=200,["Bronze 3"]=400,
        ["Silver 1"]=600,["Silver 2"]=800,["Silver 3"]=1000,["Gold 1"]=1200,["Gold 2"]=1400,
        ["Gold 3"]=1600,["Platinum 1"]=1800,["Platinum 2"]=2000,["Platinum 3"]=2200,
        ["Diamond 1"]=2400,["Diamond 2"]=2600,["Diamond 3"]=2800,["Onyx 1"]=3000,
        ["Onyx 2"]=3200,["Onyx 3"]=3400,["Nemesis"]=3600,["Archnemesis"]=3600 }
    function GameVisuals.rankNames()
        local sl = M.seasonLib
        if sl ~= nil and type(sl.RankProfiles) == "table" then
            local prof = sl.RankProfiles.ranks_version1
            if type(prof) == "table" and type(prof.RanksOrder) == "table" then
                local out = {}
                for _, name in ipairs(prof.RanksOrder) do
                    if name ~= "Unranked" then out[#out + 1] = name end
                end
                if #out > 0 then return out end
            end
        end
        local out = {}
        for _, name in ipairs(RANK_FALLBACK) do out[#out + 1] = name end
        return out
    end
    function GameVisuals.rankEloFor(rankName)
        if type(rankName) ~= "string" or rankName == "" then return nil end
        local sl = M.seasonLib
        if sl ~= nil and type(sl.RankProfiles) == "table" then
            local prof = sl.RankProfiles.ranks_version1
            local r = (type(prof) == "table" and type(prof.Ranks) == "table") and prof.Ranks[rankName] or nil
            if type(r) == "table" and type(r.RequiredELO) == "number" then return r.RequiredELO end
        end
        return RANK_ELO_FALLBACK[rankName]
    end
    function GameVisuals.rankNeedsLb(rankName)
        if rankName == "Archnemesis" then return true end
        local sl = M.seasonLib
        if sl ~= nil and type(sl.RankProfiles) == "table" then
            local prof = sl.RankProfiles.ranks_version1
            local r = (type(prof) == "table" and type(prof.Ranks) == "table") and prof.Ranks[rankName] or nil
            if type(r) == "table" and r.RequiredELOLeaderboardRanking ~= nil then return true end
        end
        return false
    end
    function GameVisuals.resolveRankStamp()
        if Config.GVRankCharmOn ~= true then return nil end
        local elo = GameVisuals.rankEloFor(Config.GVRankCharmRank)
        if type(elo) ~= "number" then return nil end
        local lb = tonumber(Config.GVRankCharmLb) or 0
        if lb <= 0 and GameVisuals.rankNeedsLb(Config.GVRankCharmRank) then lb = 1 end
        return { SeasonELO = elo, SeasonLeaderboardRank = (lb > 0 and lb or nil) }
    end
    function GameVisuals.rankedCharmsFor()
        local out = { "Held weapon" }
        for _, w in ipairs(GameVisuals.weaponList()) do
            if w ~= "None" then out[#out + 1] = w end
        end
        return out
    end
    function GameVisuals.applyRankedCharm(rankName, weaponLabel)
        if Config.GVRankCharmOn ~= true then return end
        if type(rankName) ~= "string" or rankName == "" or rankName == "None" then return end
        if type(GameVisuals.rankEloFor(rankName)) ~= "number" then return end
        local base = nil
        if type(weaponLabel) == "string" and weaponLabel ~= "" and weaponLabel ~= "None"
            and weaponLabel ~= "Held weapon" then base = weaponLabel
        else base = heldItemName() end
        if base == nil then return end
        local bestN, bestSeason = -1, nil
        for _, name in ipairs(GameVisuals.charmList()) do
            local n = string.match(name, "^Season (%d+)$")
            n = n and tonumber(n)
            if n ~= nil and n > bestN then bestN, bestSeason = n, name end
        end
        if bestSeason == nil then return end
        Config.GVRankCharmRank = rankName
        local slotChoices = GameVisuals.Choices[base]
        if slotChoices == nil then slotChoices = {}; GameVisuals.Choices[base] = slotChoices end
        slotChoices.Charm = cloneCosmetic(bestSeason, "Charm")
        pcall(GameVisuals.apply)
        saveSoon()
    end
    function GameVisuals.refreshRankCharmMeta()
        for _, slot in pairs(GameVisuals.Choices) do
            local c = slot.Charm
            if c ~= nil and c.Name ~= NONE_COSMETIC and string.match(c.Name, "^Season %d+$") ~= nil then
                slot.Charm = cloneCosmetic(c.Name, "Charm", c.Inverted)
            end
        end
        pcall(GameVisuals.apply)
        saveSoon()
    end
    function GameVisuals.clearWeapon()
        local base = _weapon or heldItemName()
        if base == nil then return end
        GameVisuals.Choices[base] = noneSlot()
        _forceRebuild = true
        pcall(GameVisuals.apply)
        _forceRebuild = false
        GameVisuals.Choices[base] = nil
        note("cleared " .. base)
        pcall(syncMask)
        saveSoon()
    end
    function GameVisuals.summary()
        local out = {}
        for weapon, slot in pairs(GameVisuals.Choices) do
            local bits = {}
            for _, kind in pairs({ "Skin", "Wrap", "Charm", "Finisher" }) do
                local v = slot[kind]
                if v ~= nil and v.Name ~= NONE_COSMETIC then
                    local shown = tostring(v.Name)
                    if v.Name == RANDOM_COSMETIC then
                        shown = "Random"
                        if type(v.Resolved) == "table" and v.Resolved.Name ~= nil then
                            shown = "Random (" .. tostring(v.Resolved.Name) .. ")"
                        end
                    end
                    table.insert(bits, string.lower(kind) .. " " .. shown)
                end
            end
            if #bits > 0 then
                local line = weapon .. " — " .. table.concat(bits, " · ")
                local why = _lastRefusal[weapon]
                if why ~= nil then line = line .. "  (" .. tostring(why) .. ")" end
                table.insert(out, line)
            end
        end
        table.sort(out)
        return out
    end
    function GameVisuals.ready() return #HOOKS > 0 end
    local CFG_DIR, CFG_FILE = "JewHook", "JewHook/cosmetics.json"
    local function fsReady()
        if type(writefile) ~= "function" or type(readfile) ~= "function" or type(isfile) ~= "function" then
            if not _fsWarned then _fsWarned = true; note("no filesystem API") end
            return false
        end
        pcall(function()
            if type(isfolder) ~= "function" or type(makefolder) ~= "function" then return end
            if not isfolder(CFG_DIR) then makefolder(CFG_DIR) end
        end)
        return true
    end
    function GameVisuals.saveConfig()
        if Config.GVRemember == false then return false, "remember picks is off" end
        if not fsReady() then return false, "no filesystem API" end
        local doc = { v = 1, choices = {} }
        for weapon, slot in pairs(GameVisuals.Choices) do
            local entry = nil
            for _, kind in pairs({ "Skin", "Charm", "Wrap", "Finisher" }) do
                local sel = slot[kind]
                if type(sel) == "table" and type(sel.Name) == "string" then
                    if entry == nil then entry = {} end
                    entry[kind] = { Name = sel.Name, Inverted = sel.Inverted == true }
                end
            end
            if entry ~= nil then doc.choices[weapon] = entry end
        end
        local ok, err = pcall(function()
            writefile(CFG_FILE, game:GetService("HttpService"):JSONEncode(doc))
        end)
        if not ok then return false, tostring(err) end
        return true, nil
    end
    saveSoon = function()
        if Config.GVRemember == false then return end
        _saveAt = tick() + 1
    end
    saveDrain = function()
        if _saveAt == nil or tick() < _saveAt then return end
        _saveAt = nil
        GameVisuals.saveConfig()
    end
    function GameVisuals.loadConfig()
        if not fsReady() then return false, "no filesystem API" end
        local raw = nil
        pcall(function() if isfile(CFG_FILE) then raw = readfile(CFG_FILE) end end)
        if type(raw) ~= "string" or #raw == 0 then return false, "no saved cosmetics" end
        local doc = nil
        pcall(function() doc = game:GetService("HttpService"):JSONDecode(raw) end)
        if type(doc) ~= "table" then return false, "cosmetics.json did not decode" end
        buildCatalog()
        local n = 0
        if type(doc.choices) == "table" then
            for weapon, entry in pairs(doc.choices) do
                if type(weapon) == "string" and type(entry) == "table" then
                    local slot = GameVisuals.Choices[weapon]
                    if slot == nil then slot = {}; GameVisuals.Choices[weapon] = slot end
                    for _, kind in pairs({ "Skin", "Charm", "Wrap", "Finisher" }) do
                        local sel = entry[kind]
                        if type(sel) == "table" and type(sel.Name) == "string" then
                            local inverted = sel.Inverted == true
                            if sel.Name == NONE_COSMETIC then slot[kind] = { Name = NONE_COSMETIC }; n = n + 1
                            elseif sel.Name == RANDOM_COSMETIC then
                                slot[kind] = { Name = RANDOM_COSMETIC, Type = kind, Inverted = inverted }
                                n = n + 1
                            else
                                local rec = cloneCosmetic(sel.Name, kind, inverted)
                                if rec ~= nil then slot[kind] = rec; n = n + 1 end
                            end
                        end
                    end
                end
            end
        end
        pcall(syncMask); pcall(GameVisuals.apply)
        note("loaded " .. n .. " saved picks")
        return true, n
    end
    local function isReplicatedStorage(v)
        local ok = false
        pcall(function() ok = (typeof(v) == "Instance" and v.ClassName == "ReplicatedStorage") end)
        return ok
    end
    local function cosmeticsCaller()
        for lvl = 2, 8 do
            local src, fn = nil, nil
            local ok = pcall(function() src, fn = debug.info(lvl, "sf") end)
            if not ok then return nil end
            if type(src) == "string" and type(fn) == "function"
                and string.match(src, "Cosmetics$") ~= nil then
                return fn
            end
        end
        return nil
    end
    local function onEquipPicked(weapon, ctype, cname, opts)
        _captured = _captured + 1
        if type(weapon) ~= "string" or type(ctype) ~= "string" then return end
        local inverted = nil
        if type(opts) == "table" then inverted = opts.IsInverted == true end
        if ctype == "Wrap" and inverted ~= nil then Config.GVWrapInverted = inverted end
        GameVisuals.setFor(weapon, ctype, cname, inverted)
    end
    local function onFavouritePicked(weapon, cname, state, ctype)
        if type(weapon) ~= "string" or type(cname) ~= "string" then return end
        local key = cname
        if cname == NONE_COSMETIC and type(ctype) == "string" then key = cname .. "_" .. ctype end
        local slot = _favOverride[weapon]
        if slot == nil then slot = {}; _favOverride[weapon] = slot end
        slot[key] = (state == true) or nil
        refresh("FavoritedCosmetics")
    end
    local function makeDecoy()
        local equip, fav = {}, {}
        equip.FireServer = function(_, weapon, ctype, cname, opts) pcall(onEquipPicked, weapon, ctype, cname, opts) end
        fav.FireServer = function(_, weapon, cname, state, ctype) pcall(onFavouritePicked, weapon, cname, state, ctype) end
        return { Remotes = { Data = { EquipCosmetic = equip, FavoriteCosmetic = fav } } }
    end
    local function patchRemoteUpvalue(fn)
        if type(fn) ~= "function" then return false end
        if fn == _lastFn then return true end
        if debug.setupvalue == nil then return false end
        if DECOY == nil then DECOY = makeDecoy() end
        local ups = nil
        pcall(function() ups = debug.getupvalues(fn) end)
        if ups == nil then
            ups = {}
            for i = 1, 64 do
                local ok, v = pcall(debug.getupvalue, fn, i)
                if not ok then break end
                ups[i] = v
            end
        end
        for i, v in pairs(ups) do
            if v == DECOY then return true end
            if isReplicatedStorage(v) then
                local ok = false
                pcall(function() debug.setupvalue(fn, i, DECOY); ok = true end)
                if ok then
                    _lastFn = fn
                    table.insert(_rsPatch, { fn = fn, idx = i, orig = v })
                    return true
                end
                return false
            end
        end
        return false
    end
    captureRestore = function()
        for i = #_rsPatch, 1, -1 do
            local p = _rsPatch[i]
            pcall(function() debug.setupvalue(p.fn, p.idx, p.orig) end)
            _rsPatch[i] = nil
        end
        _captureBound = 0
        _lastFn = nil
    end
    captureInstall = function()
        resolveModules()
        if Config.GVBirthHook == false then return false, "menu capture disabled" end
        if debug.setupvalue == nil then return false, "executor lacks debug.setupvalue" end
        local bound = 0
        if hookField(M.cslot, "new", function(orig)
            return function(...)
                if debug.info ~= nil then
                    local fn = cosmeticsCaller()
                    if fn ~= nil then pcall(patchRemoteUpvalue, fn) end
                end
                return orig(...)
            end
        end) then bound = bound + 1 end
        if M.copts ~= nil then
            local initFn = nil
            pcall(function() initFn = M.copts._Init end)
            if patchRemoteUpvalue(initFn) then bound = bound + 1 end
        end
        _captureBound = bound
        if bound == 0 then return false, "no capture target resolved yet" end
        return true, bound
    end
end)()

-- =========================================================
-- ViewAngle
-- =========================================================
local ViewAngle = {}
;(function()
    local _remote     = nil
    local _forged     = nil
    local _loopFn, _utilIdx, _utilOrig = nil, nil, nil
    local _suppressed = false
    local _joints, _jointsOrig = nil, nil
    local function remote()
        if _remote == nil then
            pcall(function() _remote = ReplicatedStorage.Remotes.Replication.Fighter.UpdateCameraRotation end)
        end
        return _remote
    end
    local function resolveLoop()
        if _loopFn ~= nil then return true end
        if type(debug) ~= "table" or type(debug.getupvalues) ~= "function"
           or type(debug.setupvalue) ~= "function" then return false end
        pcall(function()
            local F = Rivals.Fighter
            if F == nil then return end
            local fn = rawget(F, "_CameraReplicationLoop")
            if type(fn) ~= "function" then
                local mt = getmetatable(F)
                local proto = mt and rawget(mt, "__index")
                if type(proto) == "table" then fn = rawget(proto, "_CameraReplicationLoop") end
            end
            if type(fn) ~= "function" then return end
            for i, v in debug.getupvalues(fn) do
                if type(v) == "table" then
                    local vmt = getmetatable(v)
                    local vidx = vmt and rawget(vmt, "__index")
                    if type(vidx) == "table" and rawget(vidx, "EncodeCameraRotation") ~= nil then
                        _loopFn, _utilIdx, _utilOrig = fn, i, v
                        return
                    end
                end
            end
        end)
        return _loopFn ~= nil
    end
    local function makeShim()
        local shim = {}
        shim.EncodeCameraRotation = function(_, rot)
            local last = nil
            pcall(function()
                local F = Rivals.Fighter
                if F ~= nil then
                    F._replication_stopped = false
                    last = F._last_encoded_camera_rotation
                end
            end)
            if last ~= nil then return last end
            return _utilOrig:EncodeCameraRotation(rot)
        end
        return setmetatable(shim, { __index = _utilOrig })
    end
    local function suppress(on)
        if on == _suppressed then return end
        if on then
            if not resolveLoop() then return end
            if pcall(debug.setupvalue, _loopFn, _utilIdx, makeShim()) then
                _suppressed = true
                State.ViewAngleForged = true
            end
            return
        end
        if _loopFn ~= nil and _utilOrig ~= nil then
            pcall(debug.setupvalue, _loopFn, _utilIdx, _utilOrig)
        end
        _suppressed = false
        State.ViewAngleForged = false
    end
    local function patchJoints(on)
        if on then
            if _jointsOrig ~= nil then return end
            pcall(function()
                _joints = loadGameModule(lp.PlayerScripts,
                    {"Modules", "ClientReplicatedClasses", "ClientFighter", "ClientFighterCharacter", "Joints"})
                if type(_joints) ~= "table" then _joints = nil return end
                local orig = rawget(_joints, "Update")
                if type(orig) ~= "function" then _joints = nil return end
                _jointsOrig = orig
                if setreadonly then pcall(setreadonly, _joints, false) end
                _joints.Update = function(selfJoints, dt, data)
                    if _forged ~= nil and type(data) == "table" then
                        pcall(function()
                            local cfc = selfJoints.ClientFighterCharacter
                            local cf = cfc and cfc.ClientFighter
                            if cf and cf.IsLocalPlayer == true then
                                data.CameraRotationRaw = _forged
                            end
                        end)
                    end
                    return orig(selfJoints, dt, data)
                end
            end)
            return
        end
        if _joints ~= nil and _jointsOrig ~= nil then
            pcall(function()
                if setreadonly then pcall(setreadonly, _joints, false) end
                _joints.Update = _jointsOrig
            end)
        end
        _jointsOrig = nil
    end
    function ViewAngle.forge(pitch, yaw)
        local r = remote()
        if r == nil or not Rivals.Util then return false end
        local ok = pcall(function()
            local enc = Rivals.Util:EncodeCameraRotation(Vector2.new(pitch, yaw))
            _forged = Rivals.Util:DecodeCameraRotation(enc)
            r:FireServer(enc, nil)
        end)
        if not ok then return false end
        suppress(true); patchJoints(true); return true
    end
    function ViewAngle.restore() _forged = nil; suppress(false); patchJoints(false) end
    ViewAngle.isForging = function() return _forged ~= nil end
end)()

-- =========================================================
-- RAGE
-- =========================================================
local Rage = {}
;(function()
    local _tgtConn = nil
    local function bump(p) State.RageCharTokens[p] = (State.RageCharTokens[p] or 0) + 1 end
    local function killFloor() return workspace.FallenPartsDestroyHeight + Config.RageKillPlaneBuffer end
    local function hasLOS(fromPos, toPos, ignore)
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = ignore
        local res = workspace:Raycast(fromPos, toPos - fromPos, rp)
        if not res then return true end
        return (res.Position - toPos).Magnitude < 3
    end
    local function lookCF(fromPos, toPos)
        local dir = toPos - fromPos
        if dir.Magnitude < 1e-4 then dir = Vector3.new(0, -1, 0) end
        local up = Vector3.new(0, 1, 0)
        if math.abs(dir.Unit.Y) > 0.999 then up = Vector3.new(0, 0, 1) end
        return CFrame.lookAt(fromPos, fromPos + dir, up)
    end
    Rage._lookCF = lookCF
    local function buildShotFields(camData, eyeCF, muzzleCF, hitPart, aimWorldPos, jitter, clampFrac, jitterFrac)
        local objSpace = hitPart.CFrame:PointToObjectSpace(aimWorldPos)
        local hs = hitPart.Size * (clampFrac or 0.45)
        objSpace = Vector3.new(math.clamp(objSpace.X, -hs.X, hs.X),
            math.clamp(objSpace.Y, -hs.Y, hs.Y), math.clamp(objSpace.Z, -hs.Z, hs.Z))
        if jitter then
            local jf = jitterFrac or 1.0
            objSpace = Vector3.new(
                math.clamp(objSpace.X + (math.random() - 0.5) * hs.X * jf, -hs.X, hs.X),
                math.clamp(objSpace.Y + (math.random() - 0.5) * hs.Y * jf, -hs.Y, hs.Y),
                math.clamp(objSpace.Z + (math.random() - 0.5) * hs.Z * jf, -hs.Z, hs.Z))
        end
        local hitWorld = hitPart.CFrame:PointToWorldSpace(objSpace)
        local objSpaceCF = hitPart.CFrame:ToObjectSpace(CFrame.new(hitWorld))
        camData[utf8.char(0)] = Rivals.Util:EncodeCFrame(eyeCF)
        camData[utf8.char(1)] = Rivals.Util:EncodeCFrame(muzzleCF)
        camData[utf8.char(2)] = hitPart
        camData[utf8.char(3)] = Rivals.Util:EncodeCFrame(objSpaceCF)
    end
    Rage._buildShotFields = buildShotFields
    local RAGE_CLAMP_FRAC, RAGE_JITTER_FRAC = 0.30, 1.0
    local function encodeShot(camData, hitPart, targetChar, fromCamPos, claimOffset)
        if not hitPart or not camData or not Rivals.Util then return false end
        local lead = calculateLead(targetChar, fromCamPos)
        local off  = (typeof(claimOffset) == "Vector3") and claimOffset or Vector3.zero
        local leadedPos = hitPart.Position + lead + off
        local eyeCF = lookCF(fromCamPos, leadedPos)
        local muzzlePos = fromCamPos + (eyeCF.RightVector * 0.2) + Vector3.new(0, -Config.RageEyeMuzzleSep, 0)
        local muzzleCF = lookCF(muzzlePos, leadedPos)
        buildShotFields(camData, eyeCF, muzzleCF, hitPart, leadedPos, Config.SilentAimJitter, 0.45, 1.0)
        return true
    end
    Rage._encodeShot = encodeShot
    local PICK_SLOT = { Primary = 1, Secondary = 2, Melee = 3 }
    ;(function()
        local function fighterItems() local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter; return lf and lf.Items or nil end
        local function itemIsMelee(item)
            if not item then return false end
            local viaInfo = false
            pcall(function()
                local info = item.Info
                if info == nil then return end
                if info.Type == "Melee" or info.Class == "Melee" then viaInfo = true return end
                if type(info.AttackReach) == "number" and info.MaxAmmo == nil then viaInfo = true end
            end)
            if viaInfo then return true end
            local okN, nm = pcall(function() return item:Get("Name") or item.Name end)
            if okN and type(nm) == "string" and nm:lower():find("melee", 1, true) then return true end
            return false
        end
        Rage._itemIsMelee = itemIsMelee
        local function itemAmmo(item)
            if not item then return nil end
            local ok, a = pcall(function() return item:Get("Ammo") or item:Get("CurrentAmmo") end)
            if ok and type(a) == "number" then return a end
            return nil
        end
        local function slotItemByIndex(idx)
            local items = fighterItems(); if not items then return nil end
            if items[idx] then return items[idx] end
            if items[tostring(idx)] then return items[tostring(idx)] end
            return nil
        end
        local function whichSlotNow()
            local cur = getEquippedItem(); if not cur then return nil end
            local okId, oid = pcall(function() return cur:Get("ObjectID") end)
            if okId and oid then
                for idx = 1, 3 do
                    local it = slotItemByIndex(idx)
                    if it then
                        local okI, iid = pcall(function() return it:Get("ObjectID") end)
                        if okI and iid == oid then return idx end
                    end
                end
            end
            if itemIsMelee(cur) then return 3 end
            return nil
        end
        local function slotUsable(idx)
            local it = slotItemByIndex(idx); if not it then return false end
            if itemIsMelee(it) then return Config.RageSwitchMelee == true end
            local a = itemAmmo(it)
            return a == nil or a > 0
        end
        local function slotOrder()
            local pref = PICK_SLOT[Config.RageWeaponPick] or 1
            local order = { pref }
            for _, s in ipairs({ 1, 2, 3 }) do if s ~= pref then order[#order + 1] = s end end
            if not Config.RageSwitchMelee then
                local filtered = {}
                for _, s in ipairs(order) do if s ~= 3 then filtered[#filtered + 1] = s end end
                order = filtered
            end
            return order
        end
        local function nextUsableSlot(excludeIdx)
            for _, s in ipairs(slotOrder()) do if s ~= excludeIdx and slotUsable(s) then return s end end
            return nil
        end
        local function equipSlot(idx)
            if not idx then return false end
            if whichSlotNow() == idx then return true end
            local now = tick()
            if now - (State.RageSwitchLast or 0) < (Config.RageSwitchRateLimit or 0.06) then return false end
            State.RageSwitchLast = now
            local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
            local equipped = false
            if lf and lf.EquipItem then equipped = pcall(function() lf:EquipItem(idx) end) end
            if not equipped then
                pcall(function()
                    local kc = ({ Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three })[idx]
                    if kc then
                        VirtualInputMgr:SendKeyEvent(true, kc, false, game)
                        VirtualInputMgr:SendKeyEvent(false, kc, false, game)
                    end
                end)
            end
            return true
        end
        Rage._equipSlot = equipSlot
        Rage._nextUsableSlot = nextUsableSlot
        Rage._whichSlotNow = whichSlotNow
    end)()
    local function encodeRageShot(camData)
        if tick() - (State.RageFireStamp or 0) > 0.03 then return false end
        local hitPart, eyePos, aimPos = State.RageFireHitPart, State.RageFireFromPos, State.RageFireAimPos
        if not (hitPart and hitPart.Parent and eyePos and aimPos) then return false end
        if not isSanePos(eyePos) or not isSanePos(hitPart.Position) then return false end
        if (hitPart.Position - eyePos).Magnitude > (400 - 5) then return false end
        local ignore = { lp.Character }
        local t = State.RageTarget or State.Target
        if t and t.Character then ignore[2] = t.Character end
        if not hasLOS(eyePos, hitPart.Position, ignore) then return false end
        local item = getEquippedItem(); if not item then return false end
        local okE, equipping = pcall(function() return item:IsEquipping() end)
        if okE and equipping then return false end
        if not (Rage._itemIsMelee and Rage._itemIsMelee(item)) then
            local okR, reloading = pcall(function() return (item._reload_cooldown or 0) > tick() end)
            if okR and reloading then return false end
            local okA, ammo = pcall(function() return item:Get("Ammo") end)
            if not okA or type(ammo) ~= "number" or ammo <= 0 then return false end
        end
        local interval = 0
        if Rage._fireInterval then interval = Rage._fireInterval() end
        if tick() - (State.RageLastFireTime or 0) < interval then return false end
        State.RageLastFireTime = tick()
        local eyeCF = lookCF(eyePos, aimPos)
        local muzzleCF = eyeCF - Vector3.new(0, Config.RageEyeMuzzleSep, 0)
        buildShotFields(camData, eyeCF, muzzleCF, hitPart, aimPos, true, RAGE_CLAMP_FRAC, RAGE_JITTER_FRAC)
        State.Shots = State.Shots + 1
        return true
    end
    Rage._encodeRageShot = encodeRageShot
    local function findTarget()
        local myChar = lp.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local cands  = {}
        for _, p in ipairs(getSafePlayers()) do
            if isValidTarget(p, Config.RageVisCheck, true, true) then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local d = 9999
                local sane = myRoot ~= nil and hrp ~= nil and isSanePos(hrp.Position)
                if sane then d = (hrp.Position - myRoot.Position).Magnitude end
                if (not sane) or d <= (Config.MaxDistance or 1200) then
                    table.insert(cands, { p = p, hp = hum.Health, d = d })
                end
            end
        end
        if #cands == 0 then return nil end
        if Config.RageHPPriority then
            table.sort(cands, function(a, b)
                if math.abs(a.hp - b.hp) > 10 then return a.hp < b.hp end
                return a.d < b.d
            end)
        else table.sort(cands, function(a, b) return a.d < b.d end) end
        return cands[1].p
    end
    Rage._findTarget = findTarget
    local function startTargetLoop()
        if _tgtConn then _tgtConn:Disconnect() end
        local lastPosMap, lastTimeMap = {}, {}
        _tgtConn = RunService.Heartbeat:Connect(function()
            if not Config.Rage then return end
            local nowTime = tick()
            for _, p in ipairs(getSafePlayers() or {}) do
                if p ~= lp and p.Character then
                    local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                    if pRoot then
                        local currentPos = pRoot.Position
                        if lastPosMap[p] and lastTimeMap[p] then
                            local dt = nowTime - lastTimeMap[p]
                            if dt > 0 then State.RageTrueVelocityMap[p] = (currentPos - lastPosMap[p]) / dt end
                        end
                        lastPosMap[p] = currentPos; lastTimeMap[p] = nowTime
                    end
                end
            end
            if Config.RageFastTargetSwitch and State.Target and not isValidTarget(State.Target, false, true, true) then
                State.Target = nil
            end
            State.Target = findTarget()
        end)
    end
    Rage._startTargetLoop = startTargetLoop
    function Rage.init()
        for _, p in ipairs(getSafePlayers()) do bump(p) end
        Players.PlayerAdded:Connect(function(p) bump(p); p.CharacterAdded:Connect(function() bump(p) end) end)
        for _, p in ipairs(getSafePlayers()) do p.CharacterAdded:Connect(function() bump(p) end) end
        Players.PlayerRemoving:Connect(function(p) State.RageCharTokens[p] = nil end)
        lp.CharacterAdded:Connect(function()
            bump(lp); State.RageRealCF = nil; State.RageRealChar = nil
            State.RageParkDirty = false; State.RageTarget = nil
        end)
        bump(lp)
    end
    local _rageConn, _rageCharConn = nil, nil
    local _rageStepConn, _rageDiedConn, _rageCooldownConn = nil, nil, nil
    local _rageRestoreName = "__jh_rage_restore"
    local function fireInterval() return Config.RageFireRateOverride or 0 end
    Rage._fireInterval = fireInterval
    local _preParkCF = nil
    local _identGet, _identSet, _identTried = nil, nil, false
    local function rawSetCFrame(hrp, cf)
        if not _identTried then
            _identTried = true
            pcall(function()
                local g = getthreadidentity or get_thread_identity
                local s = setthreadidentity or set_thread_identity or setidentity or setthreadcontext
                if type(g) == "function" and type(s) == "function" then _identGet, _identSet = g, s end
            end)
        end
        if _identSet ~= nil then
            local okPrev, prev = pcall(_identGet)
            if okPrev then
                pcall(_identSet, 8)
                local wrote = pcall(function() hrp.CFrame = cf end)
                pcall(_identSet, prev)
                if wrote then return true end
            end
        end
        return pcall(function() hrp.CFrame = cf end)
    end
    local function displace(hrp, cf)
        if _preParkCF == nil then _preParkCF = hrp.CFrame end
        return rawSetCFrame(hrp, cf)
    end
    Rage._displace = displace
    local ORBIT_PRIME_S, ORBIT_JITTER_MAX, ORBIT_JUMP = 0.07, 0.25, 5
    local _orbHiding, _orbPrimeUntil = true, 0
    local ORB_IMMUNE_MAX_HOLD = 6.0
    local _orbImmuneSince, _orbImmuneTgt = 0, nil
    local _orbLastDisp = nil
    local function voidAxis() local v = math.random(110000, 140000); if math.random(0, 1) == 0 then return -v end; return v end
    local function rollVoid() return CFrame.new(voidAxis(), math.random(110000, 140000), voidAxis()) end
    local function stepClears(cf, prev, minStep)
        if not prev then return true end
        return (cf.Position - prev.Position).Magnitude >= minStep
    end
    local function voidCFrame()
        local now = tick()
        if not Config.RageVoidMove then
            if (not State.RageVoidCF) or now >= (State.RageVoidNext or 0) then
                State.RageVoidCF = rollVoid(); State.RageVoidNext = now + 4 + math.random() * 4
            end
            return State.RageVoidCF
        end
        local prev = State.RageVoidCF
        local cf
        if Config.RageVoidJitterLocal then
            if (not State.RageVoidBase) or now >= (State.RageVoidNext or 0) then
                State.RageVoidBase = rollVoid(); State.RageVoidNext = now + 4 + math.random() * 4
            end
            local base = State.RageVoidBase.Position
            local span = Config.RageVoidJitterStuds or 2000
            local function offset() local v = 500 + math.random() * (span - 500); if math.random(0, 1) == 0 then return -v end; return v end
            local tries = 0
            repeat cf = CFrame.new(base.X + offset(), math.max(base.Y + offset(), 110000), base.Z + offset()); tries = tries + 1
            until tries >= 8 or stepClears(cf, prev, 600)
        else
            local minStep = Config.RageVoidMinStep or 25000
            local tries = 0
            repeat cf = rollVoid(); tries = tries + 1 until tries >= 8 or stepClears(cf, prev, minStep)
        end
        State.RageVoidCF = cf
        State.RageVoidSteps = (State.RageVoidSteps or 0) + 1
        return cf
    end
    local function weaponReady(it)
        if not it then return false end
        local okE, equipping = pcall(function() return it:IsEquipping() end)
        if okE and equipping then return false end
        if (it._reload_cooldown or 0) > tick() then return false end
        if Rage._itemIsMelee and Rage._itemIsMelee(it) then return true end
        local okA, ammo = pcall(function() return it:Get("Ammo") end)
        return okA and type(ammo) == "number" and ammo > 0
    end
    Rage._ensureReload = function(it)
        if it == nil then return "no item" end
        local okR, reloading = pcall(function() return (it._reload_cooldown or 0) > tick() end)
        if okR and reloading then return "waiting" end
        local okA, ammo = pcall(function() return it:Get("Ammo") end)
        if okA and type(ammo) == "number" and ammo > 0 then return "loaded" end
        local okRes, reserve = pcall(function() return it:Get("AmmoReserve") end)
        if okRes and type(reserve) == "number" and reserve <= 0 then
            local okInf, inf = pcall(function() return it.ClientFighter ~= nil and it.ClientFighter:Get("InfiniteAmmoReserve") == true end)
            if not okInf or inf ~= true then return "dry" end
        end
        if tick() - (State.RageReloadLast or 0) < 0.5 then return "throttled" end
        State.RageReloadLast = tick()
        pcall(function()
            local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
            if lf ~= nil then
                task.spawn(function()
                    if setthreadidentity then setthreadidentity(2) elseif setidentity then setidentity(2) end
                    pcall(function() lf:Input("StartReloading") end)
                    if setthreadidentity then setthreadidentity(8) elseif setidentity then setidentity(8) end
                end)
            end
        end)
        pcall(function() it:StartReloading() end)
        return "requested"
    end
    local _SLOT_INDEX = { Primary = 1, Secondary = 2 }
    Rage._weaponRecovery = function(it)
        local mode = Config.RageOnEmpty or "Reload"
        local okA, ammo = pcall(function() return it and it:Get("Ammo") end)
        local empty = not (okA and type(ammo) == "number" and ammo > 0)
        if mode ~= "Swap" or not empty then return Rage._ensureReload(it) end
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        local items = lf and lf.Items
        if type(items) ~= "table" then return Rage._ensureReload(it) end
        if tick() - (State.RageSwitchLast or 0) < 0.5 then return "swap-wait" end
        local pref = _SLOT_INDEX[Config.RagePreferredSlot or "Primary"] or 1
        local other = pref == 1 and 2 or 1
        for _, slot in ipairs({ pref, other }) do
            local w = items[slot]
            if w and w ~= it then
                local okW, wammo = pcall(function() return w:Get("Ammo") end)
                if okW and type(wammo) == "number" and wammo > 0 then
                    local busy = false
                    pcall(function() if w:IsEquipping() then busy = true end end)
                    pcall(function() if (w._reload_cooldown or 0) > tick() then busy = true end end)
                    if not busy then
                        State.RageSwitchLast = tick()
                        local okE = pcall(function() lf.EquipItem(lf, slot) end)
                        if okE then State.AutoWeaponFails = 0 return "swap" end
                        State.AutoWeaponFails = (State.AutoWeaponFails or 0) + 1
                    end
                end
            end
        end
        return Rage._ensureReload(it)
    end
    local function flankPoint(tgt, hh)
        if not tgt or not tgt.Character or not hh or not isSanePos(hh.Position) then return nil end
        local katana = Config.AvoidDeflect and isKatana(tgt)
        local shield = Config.RageShieldBackstab and isRiotShield(tgt)
        local stowed = Config.RageShieldBackstab and ownsRiotShield(tgt)
        if not (katana or shield or stowed) then return nil end
        local thrp = tgt.Character:FindFirstChild("HumanoidRootPart")
        if not thrp then return nil end
        local look = thrp.CFrame.LookVector
        look = Vector3.new(look.X, 0, look.Z)
        if look.Magnitude < 1e-3 then return nil end
        local inv = -look.Unit
        if not katana and not shield and stowed then inv = look.Unit end
        local anchor, kf = hh.Position, killFloor()
        local dist = shield and 2.5 or 3.0
        local ignore = { tgt.Character, lp.Character }
        local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = ignore
        local flank = anchor + inv * dist
        local wr = workspace:Raycast(anchor, inv * dist, rp)
        if wr then flank = wr.Position - inv * 0.5 end
        flank = Vector3.new(flank.X, math.max(flank.Y, kf + 3), flank.Z)
        if not hasLOS(flank, hh.Position, ignore) then return nil end
        return flank
    end
    local _shootEnum
    local function polarFire(eyePos, aimPos, hh)
        local reach = 1e9
        if hh and hh.Parent then reach = (hh.Position - eyePos).Magnitude end
        if not (reach <= 395) then State.RageBlankCanary = State.RageBlankCanary + 1 return end
        local it = getEquippedItem(); if not it then return end
        if Config.RageDirectFire then
            if Config.RageRateLimit then
                if tick() - (State.RageLastFireTime or 0) < fireInterval() then return end
                State.RageLastFireTime = tick()
            end
            pcall(function() it._shoot_cooldown = 0; it._shoot_cooldown_no_ammo = 0; it._last_shot = tick() - 1 end)
            if not (Rivals.Ready and Rivals.Enums and Rivals.Util) then return end
            if _shootEnum == nil then pcall(function() _shootEnum = Rivals.Enums:ToEnum("StartShooting") end) end
            if _shootEnum == nil then return end
            local okId, objId = pcall(function() return it:Get("ObjectID") end)
            if not okId or not objId then return end
            local eyeCF = Rage._lookCF(eyePos, aimPos)
            local muzzleCF = eyeCF - Vector3.new(0, Config.RageEyeMuzzleSep, 0)
            local taps = Config.RageTapsPerFrame
            if type(taps) ~= "number" then taps = 1 end
            taps = math.max(1, math.min(math.floor(taps), math.floor(Config.RageTaps or 6)))
            local sent, rayCast = 0, false
            pcall(function() rayCast = it.Info.IsRaycast == true end)
            State.RageForging = true
            pcall(function()
                local remote = ReplicatedStorage.Remotes.Replication.Fighter.UseItem
                for _ = 1, taps do
                    if not (hh and hh.Parent) then break end
                    local inner = {}
                    Rage._buildShotFields(inner, eyeCF, muzzleCF, hh, aimPos, true, 0.30, 1.0)
                    local env = { [utf8.char(1)] = inner }
                    if rayCast then env[utf8.char(2)] = true end
                    remote:FireServer(objId, _shootEnum, env, nil)
                    sent = sent + 1
                end
            end)
            State.RageForging = false
            State.Shots = State.Shots + sent
            return
        end
        if not weaponReady(it) then return end
        if not hh or not hh.Parent or not isSanePos(hh.Position) then return end
        local hpos = hh.Position
        if (hpos - eyePos).Magnitude > (400 - 5) then return end
        local ignore = { lp.Character }
        local tgt = State.RageTarget or State.Target
        if tgt and tgt.Character then ignore[2] = tgt.Character end
        if not hasLOS(eyePos, hpos, ignore) then return end
        if tick() - (State.RageLastFireTime or 0) < fireInterval() then return end
        State.RageFireFromPos = eyePos
        State.RageFireAimPos  = aimPos
        State.RageFireHitPart = hh
        State.RageFireStamp   = tick()
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        if not lf then return end
        task.spawn(function()
            if setthreadidentity then setthreadidentity(2) elseif setidentity then setidentity(2) end
            pcall(function() lf:Input("StartShooting") end)
            if setthreadidentity then setthreadidentity(8) elseif setidentity then setidentity(8) end
        end)
    end
    local function clearFireSolution()
        State.RageFireFromPos = nil; State.RageFireAimPos = nil
        State.RageFireHitPart = nil; State.RageFireStamp = 0
    end
    ;(function()
        local function orbitVantage(aimPos, ignore, kf, knife)
            State.OrbitAngle = ((State.OrbitAngle or 0) + 2.39996) % (math.pi * 2)
            local base = Config.RageCombatOrbitRadius or 60
            local radii = knife and { math.max(base, 75), 95 } or { base, base * 0.6, math.min(base * 1.5, 380) }
            for _, r in ipairs(radii) do
                for i = 0, 5 do
                    local ang = State.OrbitAngle + i * (math.pi / 3)
                    local jitter = 0
                    if Config.RageCombatOrbitJitter then jitter = (math.random() - 0.5) * 14 end
                    local h = (Config.RageCombatOrbitHeight or 8) + jitter
                    local pos = Vector3.new(aimPos.X + math.cos(ang) * r,
                        math.max(aimPos.Y + h, kf + 6), aimPos.Z + math.sin(ang) * r)
                    if isSanePos(pos) and not posIsOOB(pos) and hasLOS(pos, aimPos, ignore) then return pos end
                end
            end
            return nil
        end
        local function orbitVoid(hrp, status)
            State.RageStatus = status
            State.OrbitVantage = nil; State.OrbitVantageUntil = 0
            State.RageFiring = false; State.RageVoidActive = true
            clearFireSolution()
            _orbHiding = true; _orbPrimeUntil = 0; _orbLastDisp = nil
            Rage._displace(hrp, voidCFrame())
        end
        local _orbDeflectSince = 0
        local function orbitTick(ch, hrp, tgt)
            local kf = killFloor()
            if not tgt or not tgt.Character then return orbitVoid(hrp, "No target") end
            local tc, thrp = tgt.Character, tgt.Character:FindFirstChild("HumanoidRootPart")
            local hh = tc:FindFirstChild("HitboxHead") or tc:FindFirstChild("Head")
            if not hh or not isSanePos(hh.Position) then return orbitVoid(hrp, "Hiding") end
            if Config.AvoidDeflect and isDeflecting(tgt) then
                if _orbDeflectSince == 0 then _orbDeflectSince = tick() end
                if tick() - _orbDeflectSince < 1.5 then return orbitVoid(hrp, "Deflecting") end
            else _orbDeflectSince = 0 end
            if not weaponReady(getEquippedItem()) then
                local act = Rage._weaponRecovery(getEquippedItem())
                if act == "dry" then return orbitVoid(hrp, "Dry") end
                if act == "swap" or act == "swap-wait" then return orbitVoid(hrp, "Swapping") end
                return orbitVoid(hrp, "Reloading")
            end
            local aimPos = hh.Position
            if posIsOOB(aimPos) or aimPos.Y < kf + 1 then return orbitVoid(hrp, "Hiding") end
            local ignore = { tc, lp.Character }
            local vantage, status = nil, nil
            local flank = flankPoint(tgt, hh)
            if not flank and thrp and Config.RageKnifeBackstab and isLocalKnife() then
                local inv = -thrp.CFrame.LookVector
                local rp = RaycastParams.new()
                rp.FilterType = Enum.RaycastFilterType.Exclude
                rp.FilterDescendantsInstances = ignore
                local f = thrp.Position + inv * 3.0
                local wr = workspace:Raycast(thrp.Position, inv * 3.0, rp)
                if wr then f = wr.Position - inv * 0.5 end
                local cand = Vector3.new(f.X, math.max(f.Y, kf + 3), f.Z)
                if isSanePos(cand) and not posIsOOB(cand) and hasLOS(cand, hh.Position, ignore) then
                    flank = cand
                end
            end
            if flank then
                vantage = flank; State.OrbitVantage = nil
                if isRiotShield(tgt) then status = "Anti-riot"
                elseif isKatana(tgt) then status = "Katana flank"
                else status = "Backstab" end
            else
                local knife = isEnemyKnife(tgt)
                local held = State.OrbitVantage
                if (not held) or tick() >= (State.OrbitVantageUntil or 0) or not hasLOS(held, aimPos, ignore) then
                    local v = orbitVantage(aimPos, ignore, kf, knife)
                    if v then
                        State.OrbitVantage = v
                        State.OrbitVantageUntil = tick() + (Config.RageOrbitDwell or 0.09)
                        held = v
                    elseif held and hasLOS(held, aimPos, ignore) then
                        State.OrbitVantageUntil = tick() + (Config.RageOrbitDwell or 0.09)
                    else held = nil end
                end
                if held then
                    vantage = held
                    if knife then status = "Orbit (kept dist)" else status = "Orbit" end
                end
            end
            if not vantage or not isSanePos(vantage) or posIsOOB(vantage) then return orbitVoid(hrp, "Orbit (hiding)") end
            State.RageStatus = status or "Orbit"
            State.RageVoidActive = false
            local jumped = _orbLastDisp == nil or (vantage - _orbLastDisp).Magnitude > ORBIT_JUMP
            _orbLastDisp = vantage
            if _orbHiding or jumped then
                _orbHiding = false
                local extra = 0
                if Config.RageHideJitter ~= false then extra = math.random() * ORBIT_JITTER_MAX end
                _orbPrimeUntil = tick() + ORBIT_PRIME_S + extra
            end
            Rage._displace(hrp, CFrame.new(vantage))
            local holdFire = false
            if Config.RageSkipImmune ~= false then holdFire = isSpawnProtected(tgt) end
            if not holdFire then _orbImmuneSince, _orbImmuneTgt = 0, nil
            else
                local nowI = tick()
                if _orbImmuneTgt ~= tgt then _orbImmuneSince, _orbImmuneTgt = nowI, tgt end
                if nowI - _orbImmuneSince > ORB_IMMUNE_MAX_HOLD then
                    holdFire = false
                    State.RageImmuneOverride = (State.RageImmuneOverride or 0) + 1
                end
            end
            if holdFire then
                State.RageFiring = false
                State.RageStatus = "Protected — vantage held, holding fire"
            elseif tick() < _orbPrimeUntil then
                State.RageFiring = false
                State.RageStatus = "Priming"
            else
                State.RageFiring = true
                local eye = vantage + Vector3.new(0, Config.RagePBEyeUp or 3, 0)
                polarFire(eye, aimPos, hh)
            end
            pcall(Visuals.notifyTarget, tgt)
        end
        local function rageTick(ch, hrp, tgt)
            if (Config.RageMode or "Polar") ~= "Orbit" then
                State.RageStatus = "Mode error"; return
            end
            orbitTick(ch, hrp, tgt)
        end
        Rage._rageTick = rageTick
    end)()
    local function restoreHome(pin)
        if State.RagePostPark then State.RageOrderCanary = State.RageOrderCanary + 1 end
        local ch = lp.Character; if not ch then return end
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        local back = _preParkCF; _preParkCF = nil
        if back == nil then
            local real = State.RageRealCF
            if real and State.RageRealChar == ch then back = CFrame.new(real.Position) * hrp.CFrame.Rotation end
        end
        pcall(function()
            if back then hrp.CFrame = back end
            State.RageParkDirty = false
            if pin then
                local hu = ch:FindFirstChildOfClass("Humanoid")
                if hu and hu:GetState() == Enum.HumanoidStateType.Freefall and hu.FloorMaterial ~= Enum.Material.Air then
                    hu:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end)
    end
    local function startRage()
        if _rageConn then return end
        local function hookDied(char)
            if _rageDiedConn then _rageDiedConn:Disconnect(); _rageDiedConn = nil end
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then _rageDiedConn = hum.Died:Connect(function() end) end
        end
        hookDied(lp.Character)
        if not _rageCharConn then
            _rageCharConn = lp.CharacterAdded:Connect(function()
                State.RageRealCF = nil; State.RageRealChar = nil
                State.RageVoidCF = nil; State.RageVoidBase = nil
                State.RageParkDirty = false; State.RageLastParkPos = nil
                hookDied(lp.Character)
            end)
        end
        local function rageRestoreActive()
            if not Config.Rage then return false end
            if not State.RageInMatch then return false end
            if State.RageRealChar ~= lp.Character then return false end
            return true
        end
        pcall(function() RunService:UnbindFromRenderStep(_rageRestoreName) end)
        RunService:BindToRenderStep(_rageRestoreName, Enum.RenderPriority.First.Value - 1000, function()
            State.RagePostPark = false
            if rageRestoreActive() then restoreHome(true) end
        end)
        if not _rageStepConn then
            _rageStepConn = RunService.Stepped:Connect(function()
                State.RagePostPark = false
                if rageRestoreActive() then restoreHome(true) end
            end)
        end
        if not _rageCooldownConn then
            _rageCooldownConn = RunService.Heartbeat:Connect(function()
                if not Config.Rage then return end
                local it = getEquippedItem(); if not it then return end
                it._shoot_cooldown = 0
                it._shoot_cooldown_no_ammo = 0
                if (it._last_shot or 0) > tick() + 1 then it._last_shot = tick() - 1 end
                if it._shot_but_ammo_hasnt_updated then it._shot_but_ammo_hasnt_updated = false end
            end)
        end
        _rageConn = RunService.Heartbeat:Connect(function()
            if not Config.Rage or (Config.RageMode or "Polar") ~= "Orbit" then
                restoreHome(false)
                pcall(function() RunService:UnbindFromRenderStep(_rageRestoreName) end)
                if _rageConn then _rageConn:Disconnect(); _rageConn = nil end
                if _rageStepConn then _rageStepConn:Disconnect(); _rageStepConn = nil end
                if _rageCooldownConn then _rageCooldownConn:Disconnect(); _rageCooldownConn = nil end
                if _rageCharConn then _rageCharConn:Disconnect(); _rageCharConn = nil end
                if _rageDiedConn then _rageDiedConn:Disconnect(); _rageDiedConn = nil end
                State.RageRealCF = nil; State.RageRealChar = nil
                State.RageTarget = nil; State.RageVoidCF = nil; State.RageVoidBase = nil
                State.RageParkDirty = false; State.RageLastParkPos = nil
                State.RageInMatch = false
                State.OrbitVantage = nil; State.OrbitVantageUntil = 0
                clearFireSolution()
                return
            end
            local ch = lp.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if not hrp or not hrp.Parent then clearFireSolution() return end
            if State.RageParkDirty and State.RageRealChar == ch then
                State.RageParkLatchCanary = State.RageParkLatchCanary + 1
                if State.RageLastParkPos then
                    State.RageLatchStuds = (hrp.Position - State.RageLastParkPos).Magnitude
                end
            elseif isSanePos(hrp.Position) then
                State.RageRealCF = hrp.CFrame
                State.RageRealChar = ch
            end
            State.RageInMatch = inMatch()
            if not State.RageInMatch then
                if not isSanePos(hrp.Position) then restoreHome(false) end
                State.RageTarget = nil
                State.RageStatus = "Lobby"
                State.RageFiring = false
                clearFireSolution()
                return
            end
            if not State.RageRealCF or State.RageRealChar ~= ch then
                State.RageStatus = "Waiting"; State.RageFiring = false
                clearFireSolution(); return
            end
            local hum0 = ch:FindFirstChildOfClass("Humanoid")
            if hum0 and hum0.Health <= 0 then
                if not isSanePos(hrp.Position) then restoreHome(false) end
                State.RageFiring = false; State.RageVoidActive = false; State.RageStatus = "Dead"
                clearFireSolution(); return
            end
            local tgt = State.RageTarget
            if tgt and (not tgt.Parent or not tgt.Character or not isAlive(tgt)
                or (Config.TeamCheck and isTeammate(tgt))) then tgt = nil end
            if not tgt then tgt = Rage._findTarget() end
            State.RageTarget = tgt
            State.RagePostPark = true
            Rage._rageTick(ch, hrp, tgt)
            local anchor = State.RageRealCF
            local displaced = false
            if anchor then displaced = (hrp.Position - anchor.Position).Magnitude > 0.001 end
            State.RageParkDirty = displaced
            if displaced then State.RageLastParkPos = hrp.Position end
        end)
    end
    function Rage.enable()
        Config.Rage = true
        if Rage._startTargetLoop then Rage._startTargetLoop() end
        if (Config.RageMode or "Polar") ~= "Orbit" then
            if Rage._polarCoreStart then Rage._polarCoreStart() end
            return
        end
        startRage()
    end
    function Rage.disable()
        Config.Rage = false
        if Rage._polarCoreStop then Rage._polarCoreStop() end
        State.RagePostPark = false
        pcall(function() RunService:UnbindFromRenderStep(_rageRestoreName) end)
        if _rageConn then _rageConn:Disconnect(); _rageConn = nil end
        if _rageStepConn then _rageStepConn:Disconnect(); _rageStepConn = nil end
        if _rageCooldownConn then _rageCooldownConn:Disconnect(); _rageCooldownConn = nil end
        if _rageCharConn then _rageCharConn:Disconnect(); _rageCharConn = nil end
        if _rageDiedConn then _rageDiedConn:Disconnect(); _rageDiedConn = nil end
        restoreHome(false)
        State.RageRealCF = nil; State.RageRealChar = nil
        State.RageTarget = nil; State.RageVoidCF = nil; State.RageVoidBase = nil
        State.RageParkDirty = false; State.RageLastParkPos = nil
        State.RageInMatch = false
        State.OrbitVantage = nil; State.OrbitVantageUntil = 0
        State.RageFiring = false; State.RageVoidActive = false; State.RageStatus = "Idle"
        clearFireSolution()
    end
    function Rage.unload()
        Rage.disable()
        if _tgtConn then pcall(function() _tgtConn:Disconnect() end); _tgtConn = nil end
    end
end)()

-- =========================================================
-- POLAR CORE
-- =========================================================
;(function()
    local PolarCore = {}
    local _realCF, _realChar = nil, nil
    local _voidCF, _target, _inMatch = nil, nil, false
    local _firing, _deflectSince, _shots, _voidSteps = false, 0, 0, 0
    local _shootEnum, _useItem, _notified = nil, nil, nil
    local _conn, _stepConn, _charConn = nil, nil, nil
    local RENDER_NAME = "JewHook_PolarCore_Restore"
    local CAMERA_NAME = "JewHook_PolarCore_CamAnchor"
    local POLAR_TAPS_SANE, EYE_UP_SANE, KILL_PLANE_BUF = 6, 2.5, 200
    local VOID_MIN_STEP, VOID_R_MIN, VOID_R_MAX = 25000, 110000, 140000
    local DEFLECT_MAX_HOLD, IMMUNE_MAX_HOLD = 1.5, 6.0
    local _immuneSince, _immuneTgt = 0, nil
    local EYE_MUZZLE_SEP, RAGE_CLAMP_FRAC = 0.07, 0.30
    local function parity() return Config.RagePolarParity ~= false end
    local _preParkCF = nil
    local _prevPark, _prevParkTgt, _lastPark = nil, nil, nil
    local PRIME_S, HIDE_JITTER_MAX = 0.07, 0.25
    local _hiding, _primeUntil = false, 0
    local _identGet, _identSet, _identTried = nil, nil, false
    local function identEnsure()
        if _identTried then return _identSet ~= nil end
        _identTried = true
        pcall(function()
            local g = getthreadidentity or get_thread_identity
            local s = setthreadidentity or set_thread_identity or setidentity or setthreadcontext
            if type(g) == "function" and type(s) == "function" then _identGet, _identSet = g, s end
        end)
        State.RageRawSet = _identSet ~= nil
        return _identSet ~= nil
    end
    local function rawSetCFrame(hrp, cf)
        identEnsure()
        if _identSet ~= nil then
            local okPrev, prev = pcall(_identGet)
            if okPrev then
                pcall(_identSet, 8)
                local wrote = pcall(function() hrp.CFrame = cf end)
                pcall(_identSet, prev)
                if wrote then return true end
            end
        end
        return pcall(function() hrp.CFrame = cf end)
    end
    local function killFloor()
        local ok, val = pcall(function() return Workspace.FallenPartsDestroyHeight end)
        if ok and type(val) == "number" and val == val then return val + KILL_PLANE_BUF end
        return -400
    end
    local function isProtected(player)
        if not player or not player.Character then return false end
        if player.Character:FindFirstChildOfClass("ForceField") then return true end
        if not Config.RageSkipImmune then return false end
        return isSpawnProtected(player)
    end
    local function inMatchLocal()
        local envOk = false
        pcall(function()
            local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
            if lf ~= nil and lf:Get("EnvironmentID") ~= nil and lf:IsAlive() then envOk = true end
        end)
        if envOk then return true end
        if lp:GetAttribute("TeamID") ~= nil then return true end
        if lp.Team ~= nil then return true end
        return false
    end
    local function getEquippedItem()
        local ok, result = pcall(function()
            local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
            if lf and lf.EquippedItem then return lf.EquippedItem end
            return nil
        end)
        if ok then return result end
        return nil
    end
    local function weaponReady(it)
        if not it then return false end
        local okE, equipping = pcall(function() return it:IsEquipping() end)
        if okE and equipping then return false end
        if (it._reload_cooldown or 0) > tick() then return false end
        local magazine = true
        pcall(function() magazine = it.Info.MaxAmmo ~= nil end)
        if not magazine then return true end
        local okA, ammo = pcall(function() return it:Get("Ammo") end)
        return okA and type(ammo) == "number" and ammo > 0
    end
    local function findTarget()
        local myChar = lp.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local cands, unreachable = {}, {}
        for _, p in Players:GetPlayers() do
            if p ~= lp and not isTeammate(p) and isAlive(p) then
                local c = p.Character
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = 9999
                    if myRoot then d = (hrp.Position - myRoot.Position).Magnitude end
                    local hum = c:FindFirstChildOfClass("Humanoid")
                    local health = hum and hum.Health or 9999
                    local entry = { p = p, hp = health, d = d, prot = isProtected(p) }
                    if isSanePos(hrp.Position) and d <= Config.MaxDistance then
                        table.insert(cands, entry)
                    else table.insert(unreachable, entry) end
                end
            end
        end
        if #cands == 0 then cands = unreachable end
        if #cands == 0 then return nil end
        table.sort(cands, function(a, b)
            if a.prot ~= b.prot then return b.prot end
            if math.abs(a.hp - b.hp) > 10 then return a.hp < b.hp end
            return a.d < b.d
        end)
        return cands[1].p
    end
    local function voidAxis() local v = math.random(VOID_R_MIN, VOID_R_MAX); if math.random(0, 1) == 0 then return -v end; return v end
    local function rollVoid() return CFrame.new(voidAxis(), math.random(VOID_R_MIN, VOID_R_MAX), voidAxis()) end
    local function voidCFrame()
        local prev = _voidCF
        local cf = rollVoid()
        if prev then
            local tries = 0
            while tries < 8 and (cf.Position - prev.Position).Magnitude < VOID_MIN_STEP do
                cf = rollVoid(); tries = tries + 1
            end
        end
        _voidCF = cf; _voidSteps = _voidSteps + 1
        return cf
    end
    local function parkHasLOS(from, to, ourChar, tgtChar)
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = { ourChar, tgtChar }
        local res = Workspace:Raycast(from, to - from, rp)
        if not res then return true end
        return (res.Position - to).Magnitude < 3
    end
    local function eyeRise(fromPos, tgtChar)
        local rise = EYE_UP_SANE
        pcall(function()
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            rp.FilterDescendantsInstances = { lp.Character, tgtChar }
            local res = Workspace:Raycast(fromPos, Vector3.new(0, EYE_UP_SANE, 0), rp)
            if res ~= nil then
                local room = (res.Position.Y - fromPos.Y) - 0.25
                if room < rise then rise = math.max(room, 0.15) end
            end
        end)
        return rise
    end
    local _meleeDwellStart = nil
    local MELEE_DWELL_S = 0.07
    local function pointBlank(hp) return Vector3.new(hp.X, math.max(hp.Y, killFloor() + 3), hp.Z) end
    local function meleeProfile(it)
        local prof = nil
        pcall(function()
            local info = it.Info
            if info == nil then return end
            if info.MaxAmmo ~= nil then return end
            local heavy = info.CriticalDamage ~= nil and type(info.HeavyAttackCooldown) == "number"
            prof = { heavy = heavy }
        end)
        return prof
    end
    local function meleeStrike(firePark, hpos, hh, tgt)
        local it = getEquippedItem()
        if it == nil then State.RageKnifeStatus = "no item" return false end
        local prof = meleeProfile(it)
        if prof == nil then State.RageKnifeStatus = "not a melee item" return false end
        local now = tick()
        if _meleeDwellStart == nil then _meleeDwellStart = now end
        if now - _meleeDwellStart < MELEE_DWELL_S then State.RageKnifeStatus = "dwell" return false end
        local actionName = prof.heavy and "StartAiming" or "StartShooting"
        local actionEnum = nil
        pcall(function() actionEnum = Rivals.Enums:ToEnum(actionName) end)
        local tc = tgt.Character
        local trp = tc and tc:FindFirstChild("HumanoidRootPart")
        if trp == nil then State.RageKnifeStatus = "target has no root" return false end
        local vp, vy = trp.CFrame:ToOrientation()
        if prof.heavy and Config.RageKnifeCamForge ~= false then ViewAngle.forge(vp, vy) end
        local eyePos = firePark + Vector3.new(0, eyeRise(firePark, tgt.Character), 0)
        local eyeCF = Rage._lookCF(eyePos, hpos)
        local muzzleCF = eyeCF - Vector3.new(0, EYE_MUZZLE_SEP, 0)
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        if lf == nil then return false end
        local restoreId = nil
        local g = getthreadidentity or get_thread_identity
        local s = setthreadidentity or set_thread_identity or setidentity
        if g and s then
            local prev = nil; pcall(function() prev = g() end)
            if prev and prev ~= 2 then
                pcall(s, 2)
                restoreId = function() pcall(s, prev) end
            end
        end
        local ok = pcall(function() lf:Input(actionName) end)
        if restoreId then restoreId() end
        if ok then
            _shots = _shots + 1
            State.Shots = State.Shots + 1
            State.RageKnifeSwings = (State.RageKnifeSwings or 0) + 1
            State.RageKnifeStatus = "swinging " .. actionName
            return true
        end
        State.RageKnifeStatus = "send failed"
        return false
    end
    local function polarFire(eyePos, aimPos, hh, taps)
        local it = getEquippedItem(); if not it then return 0 end
        pcall(function() it._shoot_cooldown = 0; it._shoot_cooldown_no_ammo = 0; it._last_shot = tick() - 1 end)
        if _shootEnum == nil then pcall(function() _shootEnum = Rivals.Enums:ToEnum("StartShooting") end) end
        if _shootEnum == nil then return 0 end
        if _useItem == nil then pcall(function() _useItem = ReplicatedStorage.Remotes.Replication.Fighter.UseItem end) end
        if _useItem == nil then return 0 end
        local okId, objId = pcall(function() return it:Get("ObjectID") end)
        if not okId or not objId then return 0 end
        local fireEyePos = eyePos
        local base = eyePos - Vector3.new(0, EYE_UP_SANE, 0)
        local ftgt = State.RageTarget or State.Target
        local rise = eyeRise(base, ftgt and ftgt.Character or nil)
        if rise < EYE_UP_SANE then fireEyePos = base + Vector3.new(0, rise, 0) end
        local eyeCF = Rage._lookCF(fireEyePos, aimPos)
        local muzzleCF = eyeCF - Vector3.new(0, EYE_MUZZLE_SEP, 0)
        local sent, rayCast = 0, false
        pcall(function() rayCast = it.Info.IsRaycast == true end)
        State.RageForging = true
        pcall(function()
            for _ = 1, taps do
                local inner = {}
                Rage._buildShotFields(inner, eyeCF, muzzleCF, hh, aimPos, true, RAGE_CLAMP_FRAC, 1.0)
                local env = { [utf8.char(1)] = inner }
                if rayCast and not parity() then env[utf8.char(2)] = true end
                _useItem:FireServer(objId, _shootEnum, env, nil)
                sent = sent + 1
            end
        end)
        State.RageForging = false
        _shots = _shots + sent
        State.Shots = State.Shots + sent
        return sent
    end
    local function tapsPerFrame()
        local n = Config.RageTapsPerFrame
        if type(n) ~= "number" then return 1 end
        if n < 1 then return 1 end
        if n > POLAR_TAPS_SANE then return POLAR_TAPS_SANE end
        return math.floor(n)
    end
    local ATTACK_GAP_HOLD = 0.30
    local _attackGapTgt, _attackGapUntil, _attackReadyTgt = nil, 0, nil
    local function clearAttackGap() _attackGapTgt = nil; _attackGapUntil = 0 end
    local function resetAttackContinuity() clearAttackGap(); _attackReadyTgt = nil end
    local function holdAttackGap(hrp, tgt, status)
        if Config.RageAttackContinuity == false then return false end
        local now = os.clock()
        if _attackGapTgt ~= tgt then
            if _attackReadyTgt ~= tgt or _prevPark == nil or _prevParkTgt ~= tgt then return false end
            _attackGapTgt = tgt; _attackGapUntil = now + ATTACK_GAP_HOLD
        elseif now > _attackGapUntil then clearAttackGap(); return false end
        _firing = false; State.RageFiring = false; State.RageStatus = status
        State.RageVoidActive = true; _lastPark = nil; _meleeDwellStart = nil
        rawSetCFrame(hrp, voidCFrame())
        return true
    end
    local function hide(hrp, status)
        resetAttackContinuity()
        _firing = false; State.RageFiring = false; State.RageStatus = status
        State.RageVoidActive = true
        _prevPark, _prevParkTgt, _lastPark = nil, nil, nil
        _hiding = true; _primeUntil = 0; _meleeDwellStart = nil
        rawSetCFrame(hrp, voidCFrame())
    end
    local function polarTick(ch, hrp)
        local tgt = _target
        if tgt and (not tgt.Parent or not tgt.Character or not isAlive(tgt) or isTeammate(tgt) or isProtected(tgt)) then tgt = nil end
        if not tgt then tgt = findTarget() end
        _target = tgt; State.RageTarget = tgt
        if not tgt or not tgt.Character then return hide(hrp, "No target") end
        local holdFire = isProtected(tgt)
        if not holdFire then _immuneSince, _immuneTgt = 0, nil
        else
            local now = tick()
            if _immuneTgt ~= tgt then _immuneSince, _immuneTgt = now, tgt end
            if now - _immuneSince > IMMUNE_MAX_HOLD then
                holdFire = false
                State.RageImmuneOverride = (State.RageImmuneOverride or 0) + 1
            end
        end
        if Config.AvoidDeflect and isDeflecting(tgt) then
            local now = tick()
            if _deflectSince == 0 then _deflectSince = now end
            if now - _deflectSince < DEFLECT_MAX_HOLD then return hide(hrp, "Deflecting") end
        else _deflectSince = 0 end
        local it = getEquippedItem()
        if not weaponReady(it) then
            local act = Rage._weaponRecovery(it)
            if act == "dry" then return hide(hrp, "Dry") end
            if act == "swap" or act == "swap-wait" then return hide(hrp, "Swapping") end
            return hide(hrp, "Reloading")
        end
        local hh = tgt.Character:FindFirstChild("HitboxHead") or tgt.Character:FindFirstChild("Head")
        if not hh then return hide(hrp, "Hiding") end
        if _hiding then
            _hiding = false
            local extra = 0
            if Config.RageHideJitter ~= false then extra = math.random() * HIDE_JITTER_MAX end
            _primeUntil = tick() + PRIME_S + extra
        end
        local hpos = hh.Position
        if not isSanePos(hpos) then
            if holdAttackGap(hrp, tgt, "Holding target swap") then return nil end
            return hide(hrp, "Head voided")
        end
        _firing = true
        State.RageFiring = not holdFire; State.RageVoidActive = false
        local melee = meleeProfile(it) ~= nil
        local park
        if melee then
            local trp = tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart")
            if trp and (it.name == "Knife" or (meleeProfile(it) and meleeProfile(it).heavy)) then
                park = trp.Position - (trp.CFrame.LookVector * 1.2) + Vector3.new(0, 0.6, 0)
            else park = hpos + (trp and (trp.CFrame.LookVector * -0.8) or Vector3.new(0, -0.5, 0)) end
        else park = pointBlank(hpos) end
        if posIsOOB(hpos) or posIsOOB(park) or not isSanePos(park) then
            if holdAttackGap(hrp, tgt, "Holding target swap") then return nil end
            return hide(hrp, "Hiding")
        end
        clearAttackGap()
        if Config.RageParkLift ~= false and not melee then
            local lifted = park + Vector3.new(0, 12, 0)
            if isSanePos(lifted) and not posIsOOB(lifted) and parkHasLOS(lifted, hpos, ch, tgt.Character) then
                park = lifted
            end
        end
        local parked = rawSetCFrame(hrp, CFrame.new(park))
        if parked then _prevPark, _prevParkTgt = park, tgt; _lastPark = CFrame.new(park)
        else _prevPark, _prevParkTgt, _lastPark = nil, nil, nil end
        local firePark = nil
        if _prevPark ~= nil and _prevParkTgt == tgt then firePark = _prevPark end
        if holdFire then State.RageStatus = "Protected — parked, holding fire"
        elseif firePark == nil then State.RageFiring = false; State.RageStatus = "Priming"; _meleeDwellStart = nil
        elseif (not parity()) and (tick() < _primeUntil) then State.RageFiring = false; State.RageStatus = "Priming"; _meleeDwellStart = nil
        elseif melee and Config.RageKnifeBot ~= false then
            if meleeStrike(firePark, hpos, hh, tgt) then _attackReadyTgt = tgt; State.RageStatus = "Melee"
            else State.RageFiring = false; State.RageStatus = "Melee (cooldown)" end
        else
            local sent = polarFire(firePark + Vector3.new(0, EYE_UP_SANE, 0), hpos, hh, tapsPerFrame())
            if sent > 0 then _attackReadyTgt = tgt end
            State.RageStatus = "Attacking"
        end
        if _notified ~= tgt then _notified = tgt; pcall(Visuals.notifyTarget, tgt) end
    end
    local function restoreHome(pin)
        local ch = lp.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        local back = _preParkCF; _preParkCF = nil
        pcall(function()
            if back then hrp.CFrame = back end
            if pin then
                local hu = ch:FindFirstChildOfClass("Humanoid")
                if hu and hu:GetState() == Enum.HumanoidStateType.Freefall and hu.FloorMaterial ~= Enum.Material.Air then
                    hu:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end)
    end
    local function cameraAnchor()
        if Config.RageCameraAnchor == false then return end
        local back = _preParkCF; if back == nil then return end
        local ch = lp.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        local delta = back.Position - hrp.Position
        if not isSanePos(delta) then return end
        Camera.CFrame = Camera.CFrame + delta
    end
    local function reparkAfterRender()
        local cf = _lastPark; if cf == nil then return end
        local ch = lp.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        rawSetCFrame(hrp, cf)
    end
    local function restoreMode()
        local m = Config.RageRestoreMode
        if m == "kicia" or m == "render" or m == "none" then return m end
        return "none"
    end
    function PolarCore.start()
        if _conn then return end
        _firing = false
        resetAttackContinuity()
        _notified = nil
        pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
        pcall(function() RunService:UnbindFromRenderStep(CAMERA_NAME) end)
        RunService:BindToRenderStep(CAMERA_NAME, Enum.RenderPriority.Camera.Value + 5, function() pcall(cameraAnchor) end)
        RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.First.Value - 1000, function()
            if _firing and restoreMode() == "none" then return end
            restoreHome(false)
        end)
        _stepConn = RunService.Stepped:Connect(function()
            if _firing then
                local pol = restoreMode()
                if pol == "render" then return reparkAfterRender() end
                if pol ~= "kicia" then return end
            end
            restoreHome(true)
        end)
        _charConn = lp.CharacterAdded:Connect(function()
            _realCF, _realChar = nil, nil
            _voidCF, _target, _notified = nil, nil, nil
            _firing = false
            resetAttackContinuity()
            _preParkCF = nil
            _prevPark, _prevParkTgt, _lastPark = nil, nil, nil
            _hiding, _primeUntil = true, 0
        end)
        _conn = RunService.Heartbeat:Connect(function()
            if not Config.Rage or (Config.RageMode or "Polar") ~= "Polar" then
                PolarCore.stop(); return
            end
            local ch = lp.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if not hrp or not hrp.Parent then return end
            if _preParkCF == nil and isSanePos(hrp.Position) then
                _realCF = hrp.CFrame; _realChar = ch
            end
            _inMatch = inMatchLocal()
            State.RageInMatch = _inMatch
            if not _inMatch then
                _target = nil; _firing = false; resetAttackContinuity()
                State.RageFiring = false; State.RageTarget = nil; State.RageStatus = "Lobby"
                if not isSanePos(hrp.Position) then restoreHome(false) end
                return
            end
            if not _realCF or _realChar ~= ch then
                _firing = false; resetAttackContinuity()
                State.RageFiring = false; State.RageStatus = "Waiting"; return
            end
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then
                _firing = false; resetAttackContinuity()
                State.RageFiring = false; State.RageVoidActive = false; State.RageStatus = "Dead"
                if not isSanePos(hrp.Position) then restoreHome(false) end
                return
            end
            polarTick(ch, hrp)
        end)
    end
    function PolarCore.stop()
        pcall(ViewAngle.restore)
        if _conn then _conn:Disconnect(); _conn = nil end
        if _stepConn then _stepConn:Disconnect(); _stepConn = nil end
        if _charConn then _charConn:Disconnect(); _charConn = nil end
        pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
        pcall(function() RunService:UnbindFromRenderStep(CAMERA_NAME) end)
        _firing = false; resetAttackContinuity()
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Parent then
            if _realCF and _realChar == lp.Character then
                pcall(function() hrp.CFrame = CFrame.new(_realCF.Position) * hrp.CFrame.Rotation end)
            elseif not isSanePos(hrp.Position) then
                pcall(function() hrp.CFrame = CFrame.new(0, 100, 0) end)
            end
        end
        _realCF, _realChar, _target, _voidCF, _notified = nil, nil, nil, nil, nil
        State.RageFiring = false; State.RageVoidActive = false; State.RageTranslocating = false
        State.RageTarget = nil; State.RageInMatch = false; State.RageStatus = "Idle"
    end
    PolarCore.shots = function() return _shots end
    PolarCore.voidSteps = function() return _voidSteps end
    Rage._polarCoreStart = PolarCore.start
    Rage._polarCoreStop  = PolarCore.stop
end)()

-- =========================================================
-- HOOK: Gun / Melee / Knife
-- =========================================================
local function getEquippedItem()
    if not Rivals.Ready then return nil end
    local f = Rivals.Fighter and Rivals.Fighter.LocalFighter
    return f and f.EquippedItem or nil
end

function hookGunModule()
    if not Rivals.Ready or not Rivals.Gun then return end
    if shared._JH_GunOrig then pcall(function() Rivals.Gun.StartShooting = shared._JH_GunOrig end) end
    if shared._JH_MeleeOrig and Rivals.Melee then pcall(function() Rivals.Melee.StartShooting = shared._JH_MeleeOrig end) end
    if shared._JH_KnifeOrig and Rivals.Knife then pcall(function() Rivals.Knife.StartAiming = shared._JH_KnifeOrig end) end
    local oldStart = Rivals.Gun.StartShooting
    shared._JH_GunOrig = oldStart
    local hookWrapper = function(self, ...)
        local suppress = (Config.Rage == true and Config.RageDirectFire == true)
        if suppress then
            pcall(function()
                local cf = self.ClientFighter
                if cf and cf.IsLocalPlayer == false then suppress = false end
            end)
        end
        if suppress then return false end
        local results = { oldStart(self, ...) }
        pcall(function()
            if not self.ClientFighter or not self.ClientFighter.IsLocalPlayer then return end
            pcall(function()
                local wname = nil
                pcall(function() wname = self.Name end)
                if type(wname) ~= "string" then
                    local ci = self.ClientItem
                    pcall(function() wname = ci and ci.Name or nil end)
                end
                if type(wname) == "string" then
                    State.LastAttackWeapon = wname
                    State.LastAttackWeaponAt = tick()
                end
            end)
            local camData = results[3]
            if not camData or typeof(camData) ~= "table" then return end
            local camPos = Camera.CFrame.Position
            State.CamPos = camPos
            if Config.Rage then
                if Rage._encodeRageShot(camData) then results[4] = true end
                return
            end
            if Config.SilentAim then
                local tgt, part = selectTarget({
                    fov = Config.SilentAimFOV, checkVis = Config.SilentAimVisCheck,
                    partMode = Config.SilentAimTargetPart,
                    stickyTarget = State.SilentLastTarget,
                    stickyBonus = Config.SilentAimStickiness or 0.05,
                })
                if tgt and part then
                    State.SilentLastTarget = tgt
                    if math.random(1, 100) <= (Config.SilentAimHitChance or 100) then
                        local hitPart = pickSilentPart(tgt.Character, part)
                        if math.random(1, 100) <= (Config.SilentAimBodyMix or 0) then
                            local body = tgt.Character:FindFirstChild("HitboxBody")
                            if body and silentPartVisible(body.Position) then hitPart = body end
                        end
                        local jit = Vector3.zero
                        local jd = Config.SilentAimJitterDeg or 0
                        if jd > 0 then
                            local okD, unit = pcall(function()
                                return Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5)
                            end)
                            local dir = (okD and unit.Magnitude > 1e-4) and unit.Unit or Vector3.zero
                            local dist = 0
                            pcall(function() dist = (hitPart.Position - camPos).Magnitude end)
                            local off = math.min(math.tan(math.rad(jd)) * dist, 3) * (math.random() * 0.5)
                            jit = dir * off
                        end
                        if Rage._encodeShot(camData, hitPart, tgt.Character, camPos, jit) then
                            results[4] = true
                            State.Shots = State.Shots + 1
                            State.Hits  = State.Hits  + 1
                        end
                    end
                    return
                end
            end
            if Config.Aimbot and Config.AimbotShotOverride
                and State.AimbotTarget and State.AimbotPart and State.AimbotKeyHeld then
                local tgt = State.AimbotTarget
                if tgt and tgt.Character and isValidTarget(tgt, false) then
                    if Rage._encodeShot(camData, State.AimbotPart, tgt.Character, camPos) then
                        results[4] = true
                        State.Shots = State.Shots + 1
                        State.Hits  = State.Hits  + 1
                    end
                end
            end
        end)
        return unpack(results)
    end
    if setfenv then pcall(setfenv, hookWrapper, getfenv(oldStart)) end
    if setreadonly then pcall(setreadonly, Rivals.Gun, false) end
    Rivals.Gun.StartShooting = hookWrapper
    local function wrapMeleeAttack(cls, method, saveKey)
        if type(cls) ~= "table" then return end
        local orig = rawget(cls, method)
        if type(orig) ~= "function" then return end
        shared[saveKey] = shared[saveKey] or orig
        if setreadonly then pcall(setreadonly, cls, false) end
        cls[method] = function(selfItem, ...)
            local results = { orig(selfItem, ...) }
            pcall(function()
                if not selfItem.ClientFighter or not selfItem.ClientFighter.IsLocalPlayer then return end
                if not Config.Rage then return end
                local camData = results[3]
                if typeof(camData) ~= "table" then return end
                Rage._encodeRageShot(camData)
            end)
            return unpack(results)
        end
    end
    wrapMeleeAttack(Rivals.Melee, "StartShooting", "_JH_MeleeOrig")
    wrapMeleeAttack(Rivals.Knife, "StartAiming",  "_JH_KnifeOrig")
end
hookGunModule()

-- =========================================================
-- AIMBOT (FULL FEATURE SET)
-- =========================================================
local Aimbot = {}
;(function()
    local TAU = math.pi * 2
    local D2R = math.pi / 180
    local R2D = 180 / math.pi
    local MAX_TAU = 0.30
    local RETAIN_MUL = 1.6
    local STICKY_MEM = 2.0
    local FF_TAU = 0.05
    local FF_MAX = 12
    local UNIT_MAX = 2000
    local RAMP_TIME = 0.15
    local PITCH_LIMIT = 1.5690509975429023
    local CAL_MIN = 1.5
    local CAL_FAST_N = 8
    local BAND_LO, BAND_HI = 0.05, 6.0
    local OSC_ERR, RUNAWAY_ERR = 0.02, 1.0
    local SEED_MX = -0.008726646259971648
    local SEED_MY = -0.006719517620178168
    local SEED_DX, SEED_DY = 1.0, 1.0
    local _bound = false
    local _mouseMove = mousemoverel
    local _fovC, _lockC, _dbgT = nil, nil, nil
    local _tgt, _part, _prevTgt, _notified = nil, nil, nil, nil
    local _acquireAt, _lastSeenAt = 0, 0
    local _ramp = 0
    local _gx, _gy, _sdx, _sdy = SEED_MX, SEED_MY, SEED_MX, SEED_MY
    local _nx, _ny, _sx, _sy, _fx, _fy = 0, 0, 0, 0, 0, 0
    local _lyaw, _lpit, _haveCam = 0, 0, false
    local _ffy, _ffp = 0, 0
    local _lty, _ltp, _haveTgt, _lastPartRef = 0, 0, false, nil
    local _flickActive, _flickT, _flickDur = false, 0, 0.15
    local _flickCtrl1Y, _flickCtrl1P, _flickCtrl2Y, _flickCtrl2P = 0, 0, 0, 0
    local _auth = 1.0
    local _flips, _errEma, _lastSign, _drive, _trips = 0, 0, nil, 0, 0
    local _calOff = false
    local _lastFOV, _errDeg = 0, 0
    local _path = "none"
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
    local function minJerk(s) s = math.clamp(s, 0, 1); return s * s * s * (10 + s * (-15 + 6 * s)) end
    local function bezier(p0, p1, p2, p3, t)
        local it = 1 - t
        return it*it*it*p0 + 3*it*it*t*p1 + 3*it*t*t*p2 + t*t*t*p3
    end
    local function validFor(pl)
        if not isValidTarget(pl, false) then return false end
        if Config.AimbotSkipImmune and isSpawnProtected(pl) then return false end
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
        local vis = Config.AimbotVisCheck
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
                    local ang = angTo(cf, part.Position)
                    local isCur = (pl == cur)
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
                if c then
                    c.Thickness = 1; c.NumSides = 64
                    c.Color = Color3.fromRGB(180, 180, 180)
                    c.Transparency = 0.6; c.Filled = false; c.Visible = false
                    _fovC = c
                end
            end
            if not _lockC then
                local c = screenDraw("Circle")
                if c then
                    c.Thickness = 2; c.NumSides = 32
                    c.Color = Color3.fromRGB(255, 80, 100)
                    c.Transparency = 0.9; c.Filled = false; c.Radius = 6; c.Visible = false
                    _lockC = c
                end
            end
            if not _dbgT then
                local t = screenDraw("Text")
                if t then
                    t.Font = 3; t.Size = 13; t.Outline = true
                    t.Color = Color3.fromRGB(0, 230, 160)
                    t.Position = Vector2.new(14, 330); t.Visible = false
                    _dbgT = t
                end
            end
        end)
    end
    local function diagText()
        return string.format(
            "AIMBOT [MATH V2]  path=%s%s\ngain  x=%.6f (n%d)   y=%.6f (n%d)\nerr %.2f deg   sent %d,%d   auth %.2f   trips %d\ntarget %s",
            _path, _calOff and "  [gain PINNED]" or "",
            _gx, _nx, _gy, _ny, _errDeg, _sx, _sy, _auth, _trips,
            _tgt and _tgt.Name or "-")
    end
    local function updateDraw()
        local wantFov = Config.Aimbot and Config.AimbotShowFOV
        local wantLock = Config.Aimbot and Config.AimbotShowLock and _part
        local wantDbg = Config.Aimbot and Config.AimbotDebug
        if not (wantFov or wantLock or wantDbg) then
            if _fovC and _fovC.Visible then _fovC.Visible = false end
            if _lockC and _lockC.Visible then _lockC.Visible = false end
            if _dbgT and _dbgT.Visible then _dbgT.Visible = false end
            return
        end
        ensureDraw()
        if _fovC then
            if wantFov then
                local vp = Camera.ViewportSize
                _fovC.Position = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
                _fovC.Radius = fovPixels(Config.AimbotFOVDeg or 20)
                _fovC.Visible = true
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
            if wantDbg then _dbgT.Text = diagText(); _dbgT.Visible = true
            else _dbgT.Visible = false end
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
                    local ok, m = pcall(loadGameModule, lp.PlayerScripts, { "Controllers", "CameraController" })
                    if ok and type(m) == "table" and typeof(m.Rotation) == "Vector2"
                       and type(m.ApplyRotationDelta) == "function" then
                        _ctl = m
                        _gx, _gy, _sdx, _sdy, _nx, _ny = SEED_DX, SEED_DY, SEED_DX, SEED_DY, 0, 0
                    end
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
        elseif _path == "direct" and _ctl then
            pcall(function() _ctl:ApplyRotationDelta(Vector2.new(uy, ux)) end)
        end
    end
    local function calibrate(obs, sent, gain, n, seed)
        if math.abs(sent) < CAL_MIN then return gain, n end
        local s = obs / sent
        if (s * seed) <= 0 then return gain, n end
        local a = math.abs(s)
        local lo = math.abs(seed) * BAND_LO
        local hi = math.abs(seed) * BAND_HI
        if a < lo or a > hi then return gain, n end
        if n < CAL_FAST_N then return s, n + 1 end
        local r = math.abs(s / gain)
        if r < 0.34 or r > 3.0 then return gain, n end
        return gain + (s - gain) * 0.05, n + 1
    end
    local function clearTarget()
        _tgt, _part, _prevTgt, _notified = nil, nil, nil, nil
        _haveTgt, _lastPartRef = false, nil
        _ffy, _ffp, _errDeg = 0, 0, 0
        _flips, _errEma, _lastSign, _drive = 0, 0, nil, 0
        _flickActive = false
        State.AimbotTarget, State.AimbotPart, State.AimbotFlickActive = nil, nil, false
    end
    local function step(dt)
        dt = math.clamp(dt or (1 / 60), 1 / 1000, 0.1)
        local cf = Camera.CFrame
        local look = cf.LookVector
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
            clearTarget(); return
        end
        if State.RageFiring then clearTarget(); return end
        if not inMatch() then
            State.AimbotKeyHeld = false
            clearTarget(); return
        end
        local keyDown = isInputActive(Config.AimbotKey)
        State.AimbotKeyHeld = keyDown
        if not keyDown then clearTarget(); return end
        _path = resolvePath()
        if _path == "none" then clearTarget(); return end
        local fovR = math.clamp(Config.AimbotFOVDeg or 20, 0.1, 180) * D2R
        local retainR = math.min(fovR * RETAIN_MUL, math.pi)
        local sticky = _tgt
        if not sticky then
            local last = State.AimbotLastTarget
            if last and (tick() - (State.AimbotLastTargetTime or 0)) <= STICKY_MEM then sticky = last end
        end
        local tgt, part = acquire(cf, fovR, retainR, sticky)
        local now = tick()
        if tgt and part then
            _lastSeenAt = now
        else
            local forget = Config.AimbotForgetTime or 0.2
            if _tgt and (now - _lastSeenAt) <= forget then tgt, part = _tgt, _part
            else clearTarget(); return end
        end
        if (Config.AimbotTargetPart or "Best") == "Best" then
            part = resolveBest(tgt.Character, part) or part
        end
        if tgt ~= _prevTgt then
            _acquireAt, _ramp, _haveTgt, _ffy, _ffp, _prevTgt, _flickActive = now, 0, false, 0, 0, tgt, false
        end
        _tgt, _part = tgt, part
        State.AimbotTarget = tgt; State.AimbotPart = part
        State.AimbotLastTarget = tgt; State.AimbotLastTargetTime = now
        if _notified ~= tgt then _notified = tgt; pcall(Visuals.notifyTarget, tgt) end
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
            local hum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
            if hum and hum.FloorMaterial == Enum.Material.Air then
                local dist = (targetPos - cf.Position).Magnitude
                local leadTime = math.clamp(dist / 1000, 0, 0.5)
                targetPos = targetPos + Vector3.new(0, 0.5 * -196.2 * leadTime * leadTime, 0)
            end
        end
        local d = targetPos - cf.Position
        local dDist = d.Magnitude
        if dDist < 1e-3 then return end
        local u = d / dDist
        local tYaw = yawOf(u)
        local tPit = math.clamp(pitchOf(u), -PITCH_LIMIT, PITCH_LIMIT)
        local errYaw = wrapPi(tYaw - curYaw)
        local errPit = tPit - curPit
        _errDeg = math.sqrt(errYaw*errYaw + errPit*errPit) * R2D
        -- FEEDFORWARD (Track Assist)
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
        if (Config.AimbotReactionMs or 0) > 0
           and (now - _acquireAt) * 1000 < Config.AimbotReactionMs then return end
        if (Config.AimbotDeadzoneDeg or 0) > 0 then
            local m = math.sqrt(errYaw*errYaw + errPit*errPit)
            if m < Config.AimbotDeadzoneDeg * D2R then return end
        end
        local smoothX = Config.AimbotLinkAxes and (Config.AimbotSmoothness or 0) or (Config.AimbotSmoothnessX or Config.AimbotSmoothness or 0)
        local smoothY = Config.AimbotLinkAxes and (Config.AimbotSmoothness or 0) or (Config.AimbotSmoothnessY or Config.AimbotSmoothness or 0)
        smoothX = math.clamp(smoothX, 0, 100); smoothY = math.clamp(smoothY, 0, 100)
        local isHardLock = (smoothX == 0 and smoothY == 0)
        -- JUMP DAMPING
        local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
        local isAirborne = (targetHum and targetHum.FloorMaterial == Enum.Material.Air) or math.abs(targetVel.Y) > 5
        if isAirborne and (Config.AimbotJumpDamping or 0) > 0 and smoothY > 0 then
            local jDamp = (Config.AimbotJumpDamping / 100)
            local vyFrac = math.clamp(math.abs(targetVel.Y) / 60, 0, 1)
            smoothY = math.clamp(smoothY + (100 - smoothY) * vyFrac * jDamp, 0, 100)
        end
        local aErr = math.sqrt(errYaw*errYaw + errPit*errPit)
        _errEma = _errEma + (aErr - _errEma) * math.clamp(dt / 0.15, 0, 1)
        _drive = _drive + dt
        local sPos = (errYaw >= 0)
        if _lastSign ~= nil and sPos ~= _lastSign then _flips = _flips + 1 end
        _lastSign = sPos
        _flips = _flips * math.exp(-dt / 0.25)
        if _flips >= 4 and _errEma > OSC_ERR and not isHardLock then
            _auth = math.max(0.15, _auth * 0.5); _flips = 0
        else _auth = math.min(1, _auth + dt * 0.3) end
        local avgSmooth = (smoothX + smoothY) * 0.5
        if _errEma > RUNAWAY_ERR and _drive > (0.15 + (avgSmooth / 100) * MAX_TAU * 3) and not isHardLock then
            _auth = math.max(0.08, _auth * 0.5)
            _gx, _gy = _sdx, _sdy; _nx, _ny = 0, 0
            _drive = 0; _trips = _trips + 1
            if _trips >= 2 then _calOff = true end
        end
        local alphaX = 1
        if smoothX > 0 then alphaX = (1 - math.exp(-dt / ((smoothX / 100) * MAX_TAU))) * _auth end
        local alphaY = 1
        if smoothY > 0 then alphaY = (1 - math.exp(-dt / ((smoothY / 100) * MAX_TAU))) * _auth end
        local cy = errYaw * alphaX
        local cp = errPit * alphaY
        -- CURVED FLICK (Bezier)
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
        -- CANCEL SPRINGS
        if not isHardLock then
            local spPit, spYaw = getSpringOffset()
            cy = cy - (spYaw * alphaX)
            cp = cp - (spPit * alphaY)
        end
        -- OVERSHOOT
        local os = Config.AimbotOvershoot or 0
        if os > 0 and not isHardLock then
            _ramp = math.min(1, _ramp + dt / RAMP_TIME)
            local k = 1 + math.sin(_ramp * math.pi) * os
            cy, cp = cy * k, cp * k
        end
        -- TRACK ASSIST feedforward
        local ff = (Config.AimbotTrackAssist or 100) / 100
        if ff > 0 and not isHardLock then
            cy = cy + _ffy * dt * ff
            cp = cp + _ffp * dt * ff
        end
        -- NOISE
        local nz = Config.AimbotNoiseDeg or 0
        if nz > 0 then
            local n = nz * D2R * dt
            cy = cy + (math.random() - 0.5) * 2 * n
            cp = cp + (math.random() - 0.5) * 2 * n
        end
        -- MAX SPEED
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
        if _path == "mouse" then
            ux, _fx = quant(ux, _fx); uy, _fy = quant(uy, _fy)
        else _fx, _fy = 0, 0 end
        if ux == 0 and uy == 0 then return end
        emit(ux, uy)
        _sx, _sy = ux, uy
    end
    function Aimbot.enable()
        Config.Aimbot = true
        if _bound then return end
        RunService:BindToRenderStep("JewHook_Aimbot", Enum.RenderPriority.Camera.Value + 1, function(dt)
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
            pcall(function() RunService:UnbindFromRenderStep("JewHook_Aimbot") end)
            _bound = false
        end
        if _fovC then _fovC.Visible = false end
        if _lockC then _lockC.Visible = false end
        if _dbgT then _dbgT.Visible = false end
    end
    function Aimbot.init() if Config.Aimbot then Aimbot.enable() end end
    function Aimbot.unload()
        Aimbot.disable()
        if shared._JH_velConn then pcall(function() shared._JH_velConn:Disconnect() end); shared._JH_velConn = nil end
        if _fovC then pcall(function() _fovC:Remove() end); _fovC = nil end
        if _lockC then pcall(function() _lockC:Remove() end); _lockC = nil end
        if _dbgT then pcall(function() _dbgT:Remove() end); _dbgT = nil end
    end
end)()

-- =========================================================
-- TRIGGER
-- =========================================================
local Trigger = {}
do
    local _bound, _lastFire, _onTgtAt, _lastChar = false, 0, 0, nil
    local trigParams = RaycastParams.new()
    trigParams.FilterType = Enum.RaycastFilterType.Exclude
    local _filterChar = nil
    local function isHeadHit(part)
        if not part then return false end
        for _, h in ipairs(HEAD_PARTS) do
            if part.Name == h then return true end
        end
        return false
    end
    local function fullyScoped()
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        local it = lf and lf.EquippedItem
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
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        if not lf then return end
        task.spawn(function()
            if setthreadidentity then setthreadidentity(2) elseif setidentity then setidentity(2) end
            pcall(function() lf:Input("StartShooting") end)
            if setthreadidentity then setthreadidentity(8) elseif setidentity then setidentity(8) end
        end)
    end
    local function underCrosshair()
        local c = lp.Character
        if c ~= _filterChar then
            trigParams.FilterDescendantsInstances = { c }
            _filterChar = c
        end
        local cf = Camera.CFrame
        local dist = math.clamp(Config.TriggerMaxDist or 400, 1, 400)
        local res = Workspace:Raycast(cf.Position, cf.LookVector * dist, trigParams)
        if not res or not res.Instance then return nil end
        local model = res.Instance:FindFirstAncestorOfClass("Model")
        if not model then return nil end
        local pl = Players:GetPlayerFromCharacter(model)
        if not pl or pl == lp then return nil end
        return pl, res.Instance
    end
    local function step()
        if not Config.Trigger then return end
        if Config.Rage then _lastChar = nil; return end
        if not isInputActive(Config.TriggerKey) then _lastChar = nil; return end
        local pl, hit = underCrosshair()
        if not pl or not isValidTarget(pl, false) then _lastChar = nil; return end
        if Config.TriggerHeadOnly and not isHeadHit(hit) then _lastChar = nil; return end
        if Config.TriggerScopeCheck and not fullyScoped() then _lastChar = nil; return end
        local now = tick()
        if pl.Character ~= _lastChar then _lastChar = pl.Character; _onTgtAt = now end
        if (now - _onTgtAt) * 1000 < (Config.TriggerDelayMs or 0) then return end
        if (now - _lastFire) * 1000 < (Config.TriggerRefireMs or 0) then return end
        _lastFire = now
        askToShoot()
    end
    function Trigger.enable()
        Config.Trigger = true
        if _bound then return end
        RunService:BindToRenderStep("JewHook_Trigger", Enum.RenderPriority.Camera.Value + 2, function() pcall(step) end)
        _bound = true
    end
    function Trigger.disable()
        Config.Trigger = false
        _lastChar, _lastFire, _onTgtAt = nil, 0, 0
        if not _bound then return end
        pcall(function() RunService:UnbindFromRenderStep("JewHook_Trigger") end)
        _bound = false
    end
    function Trigger.init() if Config.Trigger then Trigger.enable() end end
    function Trigger.unload() Trigger.disable() end
end

-- =========================================================
-- screenDraw
-- =========================================================
local screenDraw
do
    local CoreGui = game:GetService("CoreGui")
    local _layers = {}
    local LAYER_ORDER = { base = 100000, fx = 100100 }
    local LAYER_NAME  = { base = "JH_Overlay", fx = "JH_Overlay_FX" }
    local FONT_MAP = { [0]=Enum.Font.Gotham,[1]=Enum.Font.SourceSans,[2]=Enum.Font.GothamMedium,
        [3]=Enum.Font.Code,[4]=Enum.Font.GothamBold,[5]=Enum.Font.SourceSansBold }
    local BLACK = Color3.new(0, 0, 0)
    local function op(t) return 1 - (t or 1) end
    local function gui(layer)
        local Lr = _layers[layer]
        if not Lr then Lr = { gui=nil, z=0, pools={} }; _layers[layer] = Lr end
        if Lr.gui and Lr.gui.Parent then return Lr.gui end
        local g = Instance.new("ScreenGui")
        g.Name = LAYER_NAME[layer] or "JH_Overlay"
        g.IgnoreGuiInset = true; g.ResetOnSpawn = false
        g.DisplayOrder = LAYER_ORDER[layer] or 100000
        g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        local ok = pcall(function() g.Parent = (gethui and gethui()) or CoreGui end)
        if not ok or not g.Parent then pcall(function() g.Parent = lp:FindFirstChildOfClass("PlayerGui") end) end
        Lr.gui = g; return g
    end
    local function build(kind)
        if kind == "Square" then
            local f = Instance.new("Frame")
            f.BorderSizePixel = 0; f.BackgroundTransparency = 1; f.Visible = false
            local st = Instance.new("UIStroke")
            st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            st.LineJoinMode = Enum.LineJoinMode.Miter
            st.Enabled = false; st.Parent = f
            local function apply(s, k)
                if k == "Position" then if s.Position then f.Position = UDim2.fromOffset(s.Position.X, s.Position.Y) end
                elseif k == "Size" then if s.Size then f.Size = UDim2.fromOffset(s.Size.X, s.Size.Y) end
                elseif k == "Color" then if s.Color then f.BackgroundColor3 = s.Color; st.Color = s.Color end
                elseif k == "Thickness" then st.Thickness = math.max(s.Thickness or 1, 0.1)
                elseif k == "Transparency" or k == "Filled" then
                    local o = op(s.Transparency)
                    if s.Filled == false then f.BackgroundTransparency = 1; st.Enabled = true; st.Transparency = o
                    else f.BackgroundTransparency = o; st.Enabled = false end
                elseif k == "Visible" then f.Visible = s.Visible and true or false end
            end
            return f, apply
        elseif kind == "Line" then
            local f = Instance.new("Frame")
            f.BorderSizePixel = 0; f.AnchorPoint = Vector2.new(0.5, 0.5); f.Visible = false
            local _len = nil
            local function geom(s)
                if not (s.From and s.To) then return end
                local dx, dy = s.To.X - s.From.X, s.To.Y - s.From.Y
                _len = math.sqrt(dx*dx + dy*dy)
                f.Position = UDim2.fromOffset((s.From.X + s.To.X) * 0.5, (s.From.Y + s.To.Y) * 0.5)
                f.Size = UDim2.fromOffset(_len, math.max(s.Thickness or 1, 0.1))
                f.Rotation = math.deg(math.atan2(dy, dx))
            end
            local function apply(s, k)
                if k == "To" then geom(s)
                elseif k == "Thickness" then if _len then f.Size = UDim2.fromOffset(_len, math.max(s.Thickness or 1, 0.1)) end
                elseif k == "Color" then if s.Color then f.BackgroundColor3 = s.Color end
                elseif k == "Transparency" then f.BackgroundTransparency = op(s.Transparency)
                elseif k == "Visible" then f.Visible = s.Visible and true or false end
            end
            return f, apply
        elseif kind == "Text" then
            local t = Instance.new("TextLabel")
            t.BackgroundTransparency = 1; t.BorderSizePixel = 0; t.Visible = false
            t.AutomaticSize = Enum.AutomaticSize.XY; t.RichText = false
            t.TextYAlignment = Enum.TextYAlignment.Top
            t.AnchorPoint = Vector2.new(0, 0); t.TextXAlignment = Enum.TextXAlignment.Left
            local st = Instance.new("UIStroke")
            st.Thickness = 1; st.Color = BLACK
            st.LineJoinMode = Enum.LineJoinMode.Miter
            st.Enabled = false; st.Parent = t
            local function apply(s, k)
                if k == "Text" then t.Text = tostring(s.Text or "")
                elseif k == "Size" then t.TextSize = math.max(s.Size or 12, 1)
                elseif k == "Font" then t.Font = FONT_MAP[s.Font or 2] or Enum.Font.GothamMedium
                elseif k == "Color" then if s.Color then t.TextColor3 = s.Color end
                elseif k == "Center" or k == "RightAlign" then
                    if s.Center then t.AnchorPoint = Vector2.new(0.5, 0); t.TextXAlignment = Enum.TextXAlignment.Center
                    elseif s.RightAlign then t.AnchorPoint = Vector2.new(1, 0); t.TextXAlignment = Enum.TextXAlignment.Right
                    else t.AnchorPoint = Vector2.new(0, 0); t.TextXAlignment = Enum.TextXAlignment.Left end
                    if s.Position then t.Position = UDim2.fromOffset(s.Position.X, s.Position.Y) end
                elseif k == "Position" then if s.Position then t.Position = UDim2.fromOffset(s.Position.X, s.Position.Y) end
                elseif k == "Outline" then st.Enabled = s.Outline and true or false
                elseif k == "OutlineColor" then if s.OutlineColor then st.Color = s.OutlineColor end
                elseif k == "Transparency" then local o = op(s.Transparency); t.TextTransparency = o; st.Transparency = o
                elseif k == "Visible" then t.Visible = s.Visible and true or false end
            end
            return t, apply
        elseif kind == "Circle" then
            local f = Instance.new("Frame")
            f.BorderSizePixel = 0; f.AnchorPoint = Vector2.new(0.5, 0.5)
            f.BackgroundTransparency = 1; f.Visible = false
            local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(1, 0); uc.Parent = f
            local st = Instance.new("UIStroke"); st.Enabled = false; st.Parent = f
            local function apply(s, k)
                if k == "Radius" then local d = 2 * (s.Radius or 0); f.Size = UDim2.fromOffset(d, d)
                elseif k == "Position" then if s.Position then f.Position = UDim2.fromOffset(s.Position.X, s.Position.Y) end
                elseif k == "Color" then if s.Color then f.BackgroundColor3 = s.Color; st.Color = s.Color end
                elseif k == "Thickness" then st.Thickness = math.max(s.Thickness or 1, 0.1)
                elseif k == "Transparency" or k == "Filled" then
                    local o = op(s.Transparency)
                    if s.Filled == false then f.BackgroundTransparency = 1; st.Enabled = true; st.Transparency = o
                    else f.BackgroundTransparency = o; st.Enabled = false end
                elseif k == "Visible" then f.Visible = s.Visible and true or false end
            end
            return f, apply
        end
        return nil
    end
    screenDraw = function(kind, layer)
        layer = layer or "base"
        local Lr = _layers[layer]
        if not Lr then Lr = { gui=nil, z=0, pools={} }; _layers[layer] = Lr end
        local pool = Lr.pools[kind]; if not pool then pool = {}; Lr.pools[kind] = pool end
        local inst, applyFn
        local reused = table.remove(pool)
        if reused then inst, applyFn = reused.inst, reused.apply
        else
            inst, applyFn = build(kind)
            if not inst then return nil end
            inst.Parent = gui(layer)
        end
        Lr.z = Lr.z + 1; inst.ZIndex = Lr.z
        inst.Visible = false
        local state = {}
        return setmetatable({}, {
            __index = function(_, k)
                if k == "Remove" then return function() inst.Visible = false; pool[#pool+1] = { inst=inst, apply=applyFn } end
                elseif k == "TextBounds" then return inst.TextBounds end
                return state[k]
            end,
            __newindex = function(_, k, v)
                if state[k] == v then return end
                state[k] = v; applyFn(state, k)
            end,
        })
    end
end

-- =========================================================
-- ESP
-- =========================================================
local ESP = {}
;(function()
    local _renderConn, _espFrame, _lastRenderT = nil, 0, 0
    local _bboxCache, _bboxFrameN, _ctx, _renderArr = {}, {}, {}, {}
    local BLACK, WHITE = Color3.new(0,0,0), Color3.new(1,1,1)
    local INK, HPBG = Color3.fromRGB(4,6,10), Color3.fromRGB(11,15,22)
    local HP_W, HP_GAP, PAD, FLAG_GAP = 3, 5, 5, 6
    local BASE_H, MIN_W, MIN_H = 1080, 8, 13
    local BOX_W_STUDS, BOX_H_STUDS = 4*1000/1080, 6.5*1000/1080
    local TEXT_FLOOR, DIST_MIN_MUL = 8, 0.5
    local cam = Camera
    local FACES = {}
    for _, n in ipairs({"Code","RobotoMono","Gotham","GothamBold","Arial","SourceSans"}) do
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
                ug.Rotation = r; ug.Enabled = true
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
        st.Color = BLACK; st.Thickness = 1; st.Transparency = 0
        st.LineJoinMode = Enum.LineJoinMode.Round; st.Parent = t
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
        local hp = mkFrame(root, 4); hp.AnchorPoint = Vector2.new(1, 0); hp.Position = UDim2.new(0, -HP_GAP, 0, 0)
        hp.Size = UDim2.new(0, HP_W, 1, 0); hp.BackgroundColor3 = HPBG; hp.Visible = false
        local hs = Instance.new("UIStroke"); hs.Color = INK; hs.Thickness = 1; hs.Parent = hp
        u.hp = hp
        u.hpGhost = mkFrame(hp, 5); u.hpGhost.BackgroundTransparency = 0; u.hpGhost.BackgroundColor3 = WHITE
        u.hpGhost.AnchorPoint = Vector2.new(0, 1); u.hpGhost.Position = UDim2.fromScale(0, 1); u.hpGhost.Visible = false
        u.hpFill = mkFrame(hp, 6); u.hpFill.BackgroundTransparency = 0; u.hpFill.BackgroundColor3 = WHITE
        u.hpFill.AnchorPoint = Vector2.new(0, 1); u.hpFill.Position = UDim2.fromScale(0, 1); u.hpFill.Size = UDim2.fromScale(1, 1)
        u.hpNum = mkLabel(root, 7, Enum.TextXAlignment.Right); u.hpNum.AnchorPoint = Vector2.new(1, 0)
        u.hpNum.Position = UDim2.new(0, -HP_GAP - HP_W - 3, 0, 0); u.hpNum.Visible = false
        u.head = mkList(root, 7, 2, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Bottom)
        u.head.AnchorPoint = Vector2.new(0.5, 1); u.head.Position = UDim2.new(0.5, 0, 0, -PAD); u.head.Visible = false
        u.name = mkLabel(u.head, 8); u.name.LayoutOrder = 1
        u.under = mkFrame(u.head, 8); u.under.LayoutOrder = 2; u.under.BackgroundTransparency = 0; u.under.BackgroundColor3 = WHITE; u.under.Size = UDim2.fromOffset(0, 2); u.under.Visible = false
        u.foot = mkList(root, 7, 2, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top)
        u.foot.AnchorPoint = Vector2.new(0.5, 0); u.foot.Position = UDim2.new(0.5, 0, 1, PAD); u.foot.Visible = false
        u.info = mkLabel(u.foot, 8); u.info.LayoutOrder = 1; u.info.Visible = false
        u.ammo = mkFrame(u.foot, 8); u.ammo.LayoutOrder = 2; u.ammo.BackgroundColor3 = HPBG; u.ammo.Size = UDim2.fromOffset(28, 3); u.ammo.Visible = false
        local as = Instance.new("UIStroke"); as.Color = INK; as.Thickness = 1; as.Parent = u.ammo
        u.ammoFill = mkFrame(u.ammo, 9); u.ammoFill.BackgroundColor3 = WHITE; u.ammoFill.Size = UDim2.fromScale(1, 1)
        u.flags = mkList(root, 7, 3, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)
        u.flags.AnchorPoint = Vector2.new(0, 0); u.flags.Position = UDim2.new(1, FLAG_GAP, 0, 0); u.flags.Visible = false
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
        pcall(function() u.root:Destroy() end) ; pcall(function() u.tracer:Destroy() end)
        pcall(function() u.look:Destroy() end) ; pcall(function() u.dot:Destroy() end)
        if u.skel then for i = 1, #u.skel do pcall(function() u.skel[i]:Destroy() end) end end
        o.ui = nil
    end
    local function ensureCham(o, char)
        local hl = o.cham
        if hl == nil then
            hl = Instance.new("Highlight"); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Enabled = false; hl.Parent = char; o.cham = hl
        elseif hl and hl.Parent ~= char then pcall(function() hl.Parent = char end) end
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
            local c = _bboxCache[player]; if c then return c[1], c[2], c[3], c[4] end ; return nil
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
        u.foot.Visible = showInfo
        if showInfo then
            local txt
            if Config.ESPWeapon then txt = getWeaponName(player) end
            if Config.ESPDistance then txt = txt and (txt .. " · " .. ("%dm"):format(dist)) or ("%dm"):format(dist) end
            u.info.Visible = true; styleLabel(u.info, ctx.face, sizeFor(ctx.tsInfo, ctx.dmul), ctx.casing); u.info.Text = txt or ""
            paint(u.info, "TextColor3", "info", Config.ESPInfoColorMode or "Solid", Config.ESPInfoColor, Config.ESPInfoGradA, Config.ESPInfoGradB, Config.ESPGradientRotText, Config.ESPGradientSpeed, ctx.now)
            u.info.TextTransparency = 1 - (ctx.fade or 1)
        else u.info.Visible = false end
    end
    local function drawFlags(u, o, player, ctx, char, frac)
        local n = 0
        local function add(key, label)
            if n >= 5 then return end
            n = n + 1; local c = u.chips[n]; c.Visible = true
            styleLabel(c, ctx.face, sizeFor(ctx.tsChip, ctx.dmul), ctx.casing); c.Text = label
            paint(c, "TextColor3", "flag", Config.ESPFlagColorMode or "PerFlag", (Config.ESPFlagColorMode == "PerFlag") and (FLAG_COLORS[key] or WHITE) or Config.ESPFlagColor, Config.ESPFlagGradA, Config.ESPFlagGradB, Config.ESPGradientRotText, Config.ESPGradientSpeed, ctx.now)
            c.TextTransparency = 1 - (ctx.fade or 1)
        end
        if Config.ESPFlagShield and getWeaponName(player):find("Shield") then add("SHIELD", "[SHIELD]") end
        if Config.ESPFlagLowHP and frac and frac <= 0.25 then add("LOW", "[LOW]") end
        if Config.ESPFlagDeflect and isDeflecting and isDeflecting(player) then add("DEFLECT", "[DEFLECT]") end
        if Config.ESPFlagInvincible and isSpawnProtected and isSpawnProtected(player) then add("INVINCIBLE", "[INVULN]") end
        u.flags.Visible = n > 0
        for i = n + 1, 5 do u.chips[i].Visible = false end
    end
    local function segment(f, ax, ay, bx, by, thick, transp)
        local dx, dy = bx - ax, by - ay
        local len = math.sqrt(dx * dx + dy * dy)
        if len < 1 then f.Visible = false; return end
        f.Position = UDim2.fromOffset(math.floor((ax + bx) * 0.5), math.floor((ay + by) * 0.5))
        f.Size = UDim2.fromOffset(math.floor(len + 0.5), thick)
        f.Rotation = math.deg(math.atan2(dy, dx))
        f.BackgroundTransparency = transp or 0
        f.Visible = true
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
                if e and e.ok then
                    segment(f, e.ax, e.ay, e.bx, e.by, Config.ESPSkeletonThickness or 1, Config.ESPSkeletonTransparency or 0)
                    paint(f, "BackgroundColor3", "skel", Config.ESPSkeletonColorMode or "Solid", Config.ESPSkeletonColor, Config.ESPSkeletonGradA, Config.ESPSkeletonGradB, 0, Config.ESPGradientSpeed, ctx.now)
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
        if (Config.ESPTeamCheck and isTeammate(player)) or (not isAlive(player)) or dist > Config.ESPMaxDistance then hideAll(o); return end
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
        _lastRenderT = now; _espFrame = _espFrame + 1
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
-- FAKE UNDERGROUND
-- =========================================================
local FU = { on = false, depth = 5.8, walk = true, hide = true, camera = false, orbit = false, noclip = true,
             panic = false, pMin = -5, pMax = 5, pZ = false, anim = true, zeroVel = true,
             virtualCF = nil, saved = nil, track = nil, hb = nil, alive = true,
             rage = false, radius = 14, speed = 4, rate = 0.1, slot = 'Primary', maxDist = 400, team = true,
             ang = 0, target = nil, nextPick = 0, lastShot = 0, localCF = nil, status = nil }
local function hideChar()
    local char = lp.Character; if not char then return end
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
        t:Play(0, 1, 0); t.TimePosition = 1.48
        FU.track = t
    end)
end
local function stopAnim()
    if FU.track then pcall(function() FU.track:Stop(); FU.track:Destroy() end); FU.track = nil end
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
local function validTargetFU(plr, myPos)
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
local function pickTargetFU(myPos)
    local cur = FU.target
    if cur and cur.plr and cur.plr.Parent then
        local root, head = validTargetFU(cur.plr, myPos)
        if root then cur.root, cur.head = root, head; return cur end
    end
    local best, bestD = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        local root, head, d = validTargetFU(plr, myPos)
        if root and d < bestD then bestD = d; best = { plr = plr, root = root, head = head } end
    end
    FU.target = best
    return best
end
local function shootAt(head, fromPos)
    local m = getMods(); if not m then return false end
    local lf = m.FC.LocalFighter; if not lf then return false end
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
local function turnOffFU()
    FU.on = false; FU.localCF = nil; FU.target = nil
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
local function turnOnFU()
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
            local tgt = pickTargetFU(pos)
            if tgt and not FU.orbit then
                FU.localCF = nil; hrp2.CFrame = localCF
                FU.status = 'shooting from under ' .. tostring(tgt.plr.Name)
                if tick() - FU.lastShot >= FU.rate then FU.lastShot = tick(); shootAt(tgt.head, localCF.Position) end
            elseif tgt then
                FU.ang = (FU.ang + FU.speed * dt) % (math.pi * 2)
                local tp = tgt.root.Position
                local orbit = Vector3.new(tp.X + math.cos(FU.ang) * FU.radius, tp.Y - FU.depth, tp.Z + math.sin(FU.ang) * FU.radius)
                local yaw = CFrame.new(orbit) * CFrame.Angles(0, math.atan2(-(tp.X - orbit.X), -(tp.Z - orbit.Z)), 0)
                FU.localCF = localCF; hrp2.CFrame = yaw
                FU.status = 'orbiting ' .. tostring(tgt.plr.Name)
                if tick() - FU.lastShot >= FU.rate then FU.lastShot = tick(); shootAt(tgt.head, orbit) end
            else
                FU.status = 'no target'; hrp2.CFrame = localCF
            end
        else hrp2.CFrame = localCF end
        if FU.hide and FU.saved then
            for _, d in ipairs(FU.saved) do
                if d.part and d.part.Parent and d.part.Transparency ~= 1 then pcall(function() d.part.Transparency = 1 end) end
            end
        end
    end)
end
lp.CharacterAdded:Connect(function()
    if FU.on then task.wait(1); turnOffFU(); turnOnFU() end
end)

-- =========================================================
-- UI SETUP
-- =========================================================
Library.IsMobile = isMobile
Library.ShowCustomCursor = false
pcall(function()
    Library.MainColor       = Color3.fromRGB(26, 27, 31)
    Library.BackgroundColor = Color3.fromRGB(17, 18, 21)
    Library.AccentColor     = Color3.fromRGB(96, 165, 250)
    Library.OutlineColor    = Color3.fromRGB(43, 45, 52)
    Library.FontColor       = Color3.fromRGB(239, 241, 245)
end)
local okWin, Window = pcall(function()
    return Library:CreateWindow({ Title='JewHook', Center=true, AutoShow=false, TabPadding=8,
        MenuFadeTime=0.2, NotifySide='Right', Resizable=true, UnlockMouseWhileOpen=true })
end)
if not okWin or not Window then warn("[JewHook] GUI window failed to build:", Window); return end
local Tabs = {
    Main     = Window:AddTab('Main'),
    Rage     = Window:AddTab('Rage'),
    ESP      = Window:AddTab('ESP'),
    Visuals  = Window:AddTab('Visuals'),
    Settings = Window:AddTab('Settings'),
}

-- =========================================================
-- UI: MAIN
-- =========================================================
do
    local L = Tabs.Main:AddLeftGroupbox('Silent Aim')
    L:AddToggle('SilentAim', { Text='Silent Aim', Default=Config.SilentAim, Callback=function(v) Config.SilentAim = v end })
        :AddKeyPicker('SilentAimKey', { Default='None', Mode='Toggle', SyncToggleState=true, Text='Silent Aim' })
    L:AddToggle('SilentAimVisCheck', { Text='Visibility check', Default=Config.SilentAimVisCheck, Callback=function(v) Config.SilentAimVisCheck = v end })
    L:AddToggle('SilentAimJitter', { Text='Hit randomization', Default=Config.SilentAimJitter, Callback=function(v) Config.SilentAimJitter = v end })
    L:AddSlider('SilentAimFOV', { Text='FOV radius', Default=Config.SilentAimFOV, Min=20, Max=2000, Rounding=0, Callback=function(v) Config.SilentAimFOV = v end })
    L:AddDropdown('SilentAimTargetPart', { Values={'Head','Torso','Closest'}, Default=Config.SilentAimTargetPart, Text='Target bone', Callback=function(v) Config.SilentAimTargetPart = v end })
    L:AddSlider('SilentAimStickiness', { Text='Stickiness', Default=Config.SilentAimStickiness, Min=0, Max=0.5, Rounding=2, Callback=function(v) Config.SilentAimStickiness = v end })
    L:AddToggle('SilentAimMultipoint', { Text='Multipoint', Default=Config.SilentAimMultipoint, Callback=function(v) Config.SilentAimMultipoint = v end })
    local mp = L:AddDependencyBox()
    mp:AddSlider('SilentAimMultipointCount', { Text='Samples', Default=Config.SilentAimMultipointCount, Min=1, Max=12, Rounding=0, Callback=function(v) Config.SilentAimMultipointCount = math.floor(v) end })
    mp:SetupDependencies({ { Toggles.SilentAimMultipoint, true } })
    L:AddToggle('SilentAimTorsoFallback', { Text='Torso fallback', Default=Config.SilentAimTorsoFallback, Callback=function(v) Config.SilentAimTorsoFallback = v end })
    L:AddDivider('De-blend')
    L:AddSlider('SilentAimHitChance', { Text='Hit chance %', Default=Config.SilentAimHitChance, Min=25, Max=100, Rounding=0, Callback=function(v) Config.SilentAimHitChance = math.floor(v) end })
    L:AddSlider('SilentAimBodyMix', { Text='Body mix %', Default=Config.SilentAimBodyMix, Min=0, Max=100, Rounding=0, Callback=function(v) Config.SilentAimBodyMix = math.floor(v) end })
    L:AddSlider('SilentAimJitterDeg', { Text='Jitter cone (deg)', Default=Config.SilentAimJitterDeg, Min=0, Max=10, Rounding=1, Callback=function(v) Config.SilentAimJitterDeg = v end })

    local R = Tabs.Main:AddRightGroupbox('Aimbot')
    R:AddToggle('Aimbot', { Text='Aimbot', Default=Config.Aimbot, Callback=function(v) if v then Aimbot.enable() else Aimbot.disable() end end })
    R:AddDropdown('AimbotKey', { Values={'Always','MB2','MB1','C','E','F','Q','V','X','LeftShift','LeftAlt','LeftControl'}, Default=Config.AimbotKey, Text='Activation', Callback=function(v) Config.AimbotKey = v end })
    R:AddDivider('Target Lock')
    R:AddSlider('AimbotSmoothness', { Text='Smoothness (0 = hard lock)', Default=Config.AimbotSmoothness, Min=0, Max=100, Rounding=0, Callback=function(v) Config.AimbotSmoothness = v end })
    R:AddToggle('AimbotLinkAxes', { Text='Link X / Y smoothing', Default=(Config.AimbotLinkAxes ~= false), Callback=function(v) Config.AimbotLinkAxes = v end })
    local ax = R:AddDependencyBox()
    ax:AddSlider('AimbotSmoothnessX', { Text='Yaw (X) smoothness', Default=Config.AimbotSmoothnessX, Min=0, Max=100, Rounding=0, Callback=function(v) Config.AimbotSmoothnessX = v end })
    ax:AddSlider('AimbotSmoothnessY', { Text='Pitch (Y) smoothness', Default=Config.AimbotSmoothnessY, Min=0, Max=100, Rounding=0, Callback=function(v) Config.AimbotSmoothnessY = v end })
    ax:SetupDependencies({ { Toggles.AimbotLinkAxes, false } })
    R:AddSlider('AimbotJumpDamping', { Text='Jump & airborne damping (%)', Default=Config.AimbotJumpDamping, Min=0, Max=100, Rounding=0, Callback=function(v) Config.AimbotJumpDamping = v end })
    R:AddToggle('AimbotCancelSprings', { Text='Pre-cancel weapon sway springs', Default=(Config.AimbotCancelSprings ~= false), Callback=function(v) Config.AimbotCancelSprings = v end })
    R:AddToggle('AimbotCurvedFlick', { Text='Humanized curved flicks (Bezier)', Default=Config.AimbotCurvedFlick, Callback=function(v) Config.AimbotCurvedFlick = v end })
    local curveDep = R:AddDependencyBox()
    curveDep:AddSlider('AimbotCurvedIntensity', { Text='Curve amplitude', Default=Config.AimbotCurvedIntensity, Min=0.05, Max=1.0, Rounding=2, Callback=function(v) Config.AimbotCurvedIntensity = v end })
    curveDep:SetupDependencies({ { Toggles.AimbotCurvedFlick, true } })
    R:AddSlider('AimbotTrackAssist', { Text='Track assist (0-lag feedforward)', Default=Config.AimbotTrackAssist, Min=0, Max=100, Rounding=0, Callback=function(v) Config.AimbotTrackAssist = v end })
    R:AddSlider('AimbotMaxSpeed', { Text='Max turn speed (deg/s, 0 = off)', Default=Config.AimbotMaxSpeed, Min=0, Max=3600, Rounding=0, Callback=function(v) Config.AimbotMaxSpeed = v end })
    R:AddSlider('AimbotDeadzoneDeg', { Text='Deadzone (deg)', Default=Config.AimbotDeadzoneDeg, Min=0, Max=10, Rounding=2, Callback=function(v) Config.AimbotDeadzoneDeg = v end })
    R:AddSlider('AimbotFOVDeg', { Text='FOV (deg)', Default=Config.AimbotFOVDeg, Min=1, Max=180, Rounding=1, Callback=function(v) Config.AimbotFOVDeg = v end })
    R:AddSlider('AimbotSwitchDeg', { Text='Switch threshold (deg)', Default=Config.AimbotSwitchDeg, Min=0, Max=45, Rounding=1, Callback=function(v) Config.AimbotSwitchDeg = v end })
    R:AddSlider('AimbotStickiness', { Text='Stickiness', Default=Config.AimbotStickiness, Min=0, Max=0.5, Rounding=2, Callback=function(v) Config.AimbotStickiness = v end })
    R:AddSlider('AimbotForgetTime', { Text='Occlusion forget time (s)', Default=Config.AimbotForgetTime, Min=0, Max=1.0, Rounding=2, Callback=function(v) Config.AimbotForgetTime = v end })
    R:AddDropdown('AimbotTargetPart', { Values={'Best','Head','Torso','Closest'}, Default=Config.AimbotTargetPart, Text='Target bone', Callback=function(v) Config.AimbotTargetPart = v end })
    R:AddDropdown('AimbotPriority', { Values={'Crosshair','Health','Distance'}, Default=Config.AimbotPriority, Text='Priority', Callback=function(v) Config.AimbotPriority = v end })
    R:AddToggle('AimbotVisCheck', { Text='Visibility check', Default=Config.AimbotVisCheck, Callback=function(v) Config.AimbotVisCheck = v end })
    R:AddToggle('AimbotSkipImmune', { Text='Skip immune targets', Default=Config.AimbotSkipImmune, Callback=function(v) Config.AimbotSkipImmune = v end })
    R:AddToggle('AimbotPrediction', { Text='Prediction (lead + gravity)', Default=Config.AimbotPrediction, Callback=function(v) Config.AimbotPrediction = v end })
    R:AddToggle('AimbotShotOverride', { Text='Shot override', Default=Config.AimbotShotOverride, Callback=function(v) Config.AimbotShotOverride = v end })
    R:AddSlider('AimbotReactionMs', { Text='Reaction delay (ms)', Default=Config.AimbotReactionMs, Min=0, Max=300, Rounding=0, Callback=function(v) Config.AimbotReactionMs = v end })
    R:AddSlider('AimbotNoiseDeg', { Text='Aim noise (deg/s)', Default=Config.AimbotNoiseDeg, Min=0, Max=20, Rounding=1, Callback=function(v) Config.AimbotNoiseDeg = v end })
    R:AddSlider('AimbotOvershoot', { Text='Overshoot', Default=Config.AimbotOvershoot, Min=0, Max=1, Rounding=2, Callback=function(v) Config.AimbotOvershoot = v end })
    R:AddToggle('AimbotShowLock', { Text='Show lock indicator', Default=Config.AimbotShowLock, Callback=function(v) Config.AimbotShowLock = v end })
    R:AddToggle('AimbotShowFOV', { Text='Debug FOV circle', Default=Config.AimbotShowFOV, Callback=function(v) Config.AimbotShowFOV = v end })
    R:AddToggle('AimbotDebug', { Text='Debug readout', Default=Config.AimbotDebug, Callback=function(v) Config.AimbotDebug = v end })
    R:AddToggle('AimbotDirectCamera', { Text='Direct camera fallback', Default=Config.AimbotDirectCamera, Callback=function(v) Config.AimbotDirectCamera = v end })

    local L2 = Tabs.Main:AddLeftGroupbox('Triggerbot')
    L2:AddToggle('Trigger', { Text='Trigger bot', Default=Config.Trigger, Callback=function(v) if v then Trigger.enable() else Trigger.disable() end end })
    L2:AddDropdown('TriggerKey', { Values={'Always','MB2','MB1','C','E','F','Q','V','X','LeftShift','LeftAlt','LeftControl'}, Default=Config.TriggerKey, Text='Activation', Callback=function(v) Config.TriggerKey = v end })
    L2:AddToggle('TriggerHeadOnly', { Text='Head only', Default=Config.TriggerHeadOnly, Callback=function(v) Config.TriggerHeadOnly = v end })
    L2:AddToggle('TriggerScopeCheck', { Text='Scope check', Default=Config.TriggerScopeCheck, Callback=function(v) Config.TriggerScopeCheck = v end })
    L2:AddSlider('TriggerDelayMs', { Text='Reaction (ms)', Default=Config.TriggerDelayMs, Min=0, Max=300, Rounding=0, Callback=function(v) Config.TriggerDelayMs = v end })
    L2:AddSlider('TriggerRefireMs', { Text='Refire (ms)', Default=Config.TriggerRefireMs, Min=0, Max=500, Rounding=0, Callback=function(v) Config.TriggerRefireMs = v end })
    L2:AddSlider('TriggerMaxDist', { Text='Max distance', Default=Config.TriggerMaxDist, Min=50, Max=400, Rounding=0, Callback=function(v) Config.TriggerMaxDist = v end })

    local L3 = Tabs.Main:AddLeftGroupbox('Targeting')
    L3:AddToggle('TeamCheck', { Text='Team check', Default=Config.TeamCheck, Callback=function(v) Config.TeamCheck = v end })
    L3:AddToggle('AvoidDeflect', { Text='Avoid katana deflect', Default=Config.AvoidDeflect, Callback=function(v) Config.AvoidDeflect = v end })
    L3:AddToggle('PredictiveLead', { Text='Predictive lead', Default=Config.PredictiveLead, Callback=function(v) Config.PredictiveLead = v end })
    L3:AddSlider('MaxDistance', { Text='Max distance', Default=Config.MaxDistance, Min=200, Max=3000, Rounding=0, Callback=function(v) Config.MaxDistance = v end })
    L3:AddSlider('LeadCap', { Text='Lead cap', Default=Config.LeadCap, Min=1, Max=50, Rounding=0, Callback=function(v) Config.LeadCap = v end })
    L3:AddToggle('ProjectileLead', { Text='Projectile lead', Default=Config.ProjectileLead, Callback=function(v) Config.ProjectileLead = v end })
    local proj = L3:AddDependencyBox()
    proj:AddSlider('ProjectileSpeed', { Text='Projectile speed', Default=Config.ProjectileSpeed, Min=50, Max=2000, Rounding=0, Callback=function(v) Config.ProjectileSpeed = v end })
    proj:SetupDependencies({ { Toggles.ProjectileLead, true } })
    L3:AddSlider('ServerProcessingMs', { Text='Server processing (ms)', Default=Config.ServerProcessingMs, Min=0, Max=200, Rounding=0, Callback=function(v) Config.ServerProcessingMs = v end })
end

-- =========================================================
-- UI: RAGE
-- =========================================================
do (function()
    local LTB = Tabs.Rage:AddLeftTabbox('Combat')
    local CORE = LTB:AddTab('Core')
    local DEF  = LTB:AddTab('Defense')

    CORE:AddToggle('Rage', { Text='Enable Rage', Default=Config.Rage,
        Callback=function(v) if v then Rage.enable() else Rage.disable() end end })
        :AddKeyPicker('RageToggleKey', { Default='None', Mode='Toggle', SyncToggleState=true, Text='Rage' })
    CORE:AddDropdown('RageMode', { Values={'Polar','Orbit'},
        Default=Config.RageMode, Text='Rage mode',
        Callback=function(v) Config.RageMode = v ; if Config.Rage then Rage.enable() end end })
    CORE:AddDivider('Engine')
    CORE:AddDropdown('RageGumMode', { Values={'off','lite','on'},
        Default=Config.RageGumMode, Text='Gum',
        Callback=function(v) Config.RageGumMode = v end })
    CORE:AddDropdown('RageVoidDepth', { Values={'shallow','deep'},
        Default=Config.RageVoidDepth, Text='Hide depth',
        Callback=function(v) Config.RageVoidDepth = v end })
    CORE:AddToggle('RageGatePoison', { Text='Gate poison', Default=Config.RageGatePoison,
        Callback=function(v) Config.RageGatePoison = v end })
    CORE:AddToggle('RagePredictPrefire', { Text='Prefire resurface', Default=Config.RagePredictPrefire,
        Callback=function(v) Config.RagePredictPrefire = v end })
    CORE:AddDivider('Engagement')
    CORE:AddToggle('RageSkipImmune', { Text='Hold fire on immune', Default=Config.RageSkipImmune,
        Callback=function(v) Config.RageSkipImmune = v end })
    CORE:AddToggle('RagePrioritizeHackers', { Text='Target cheaters first', Default=Config.RagePrioritizeHackers,
        Callback=function(v) Config.RagePrioritizeHackers = v end })
    local orb = CORE:AddDependencyBox()
    orb:AddSlider('RageCombatOrbitRadius', { Text='Orbit radius', Default=Config.RageCombatOrbitRadius, Min=20, Max=380, Rounding=0,
        Callback=function(v) Config.RageCombatOrbitRadius = v end })
    orb:AddSlider('RageOrbitDwell', { Text='Vantage time', Default=Config.RageOrbitDwell, Min=0.10, Max=0.60, Rounding=2,
        Callback=function(v) Config.RageOrbitDwell = v end })
    orb:AddSlider('RageCombatOrbitHeight', { Text='Orbit height', Default=Config.RageCombatOrbitHeight, Min=0, Max=40, Rounding=0,
        Callback=function(v) Config.RageCombatOrbitHeight = v end })
    orb:AddToggle('RageCombatOrbitJitter', { Text='Vertical jitter', Default=Config.RageCombatOrbitJitter,
        Callback=function(v) Config.RageCombatOrbitJitter = v end })
    orb:AddSlider('RagePBEyeUp', { Text='Eye height', Default=Config.RagePBEyeUp, Min=1, Max=12, Rounding=0,
        Callback=function(v) Config.RagePBEyeUp = v end })
    orb:SetupDependencies({ { Options.RageMode, 'Orbit' } })

    DEF:AddDivider('Bait pulse')
    DEF:AddToggle('RageAttackTranslocate', { Text='Bait Pulse', Default=Config.RageAttackTranslocate,
        Callback=function(v) Config.RageAttackTranslocate = v end })
    DEF:AddDivider('Park transport')
    DEF:AddDropdown('RageRestoreMode', { Values={'auto','none','render','kerp'},
        Default=Config.RageRestoreMode, Text='Park transport',
        Callback=function(v) Config.RageRestoreMode = v end })
    DEF:AddLabel('auto: kerp <-> render on round losses to your target')

    local WEP = Tabs.Rage:AddRightGroupbox('Weapon')
    WEP:AddDivider('On empty magazine')
    WEP:AddDropdown('RageOnEmpty', { Values={'Swap','Reload'},
        Default=Config.RageOnEmpty, Text='Action',
        Callback=function(v) Config.RageOnEmpty = v end })
    WEP:AddDropdown('RagePreferredSlot', { Values={'Primary','Secondary','Melee'},
        Default=Config.RagePreferredSlot, Text='Prefer slot',
        Callback=function(v) Config.RagePreferredSlot = v end })

    local B = Tabs.Rage:AddRightGroupbox('Melee')
    B:AddToggle('AvoidDeflect', { Text='Avoid katana deflect', Default=Config.AvoidDeflect,
        Callback=function(v) Config.AvoidDeflect = v end })
    B:AddToggle('RageShieldBackstab', { Text='Riot shield bypass', Default=Config.RageShieldBackstab,
        Callback=function(v) Config.RageShieldBackstab = v end })
    B:AddToggle('RageKnifeBackstab', { Text='Force knife backstabs', Default=Config.RageKnifeBackstab,
        Callback=function(v) Config.RageKnifeBackstab = v end })

    -- Graviton
    local _Players = game:GetService('Players')
    local _RunService = game:GetService('RunService')
    local _UIS = game:GetService('UserInputService')
    local _RS = game:GetService('ReplicatedStorage')
    local LP = _Players.LocalPlayer
    local GR = { on = false, rate = 0.001, slot = 1, desync = true, void = true, head = true, extra = true,
                 knife = true, equip = true, fov = 9999 }
    local _FC, _SC, _util, _enum, _remote = false, false, false, false, false
    local alive = true

    task.spawn(function()
        for _ = 1, 60 do
            if not alive then return end
            pcall(function()
                if not _util then _util = require(_RS.Modules.Utility) or false end
                if not _enum then _enum = require(_RS.Modules.EnumLibrary) or false end
                if not _FC then _FC = require(LP.PlayerScripts.Controllers.FighterController) or false end
                if not _SC then _SC = require(LP.PlayerScripts.Controllers:WaitForChild('SpectateController', 3)) or false end
                if not _remote then _remote = _RS.Remotes.Replication.Fighter.UseItem end
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
    _Players.PlayerRemoving:Connect(function(p) deflecting[p] = nil end)
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
                    for _, d in duel.Duelers do
                        if d.Player == pl then return d:Get('TeamID') ~= lt end
                    end
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
        return (Vector2.new(p3.X, p3.Y) - _UIS:GetMouseLocation()).Magnitude <= GR.fov
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
        if now - pingAt >= 1 then
            pingAt = now
            pcall(function() ping = math.clamp(LP:GetNetworkPing(), 0, 0.5) end)
        end
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
        pcall(function()
            local n = item.Info and item.Info.ShootPellets
            if type(n) == 'number' then pelCount = math.max(1, math.floor(n)) end
        end)
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
        if dsBound then
            dsBound = false
            pcall(function() _RunService:UnbindFromRenderStep('GR_DsRestore') end)
        end
        local root, cf = dsRoot, dsCF
        dsRoot, dsCF, dsShown = nil, nil, nil
        if root and root.Parent and cf then
            pcall(function()
                root.CFrame = cf
                root.AssemblyLinearVelocity = dsVel
                root.AssemblyAngularVelocity = dsRot
            end)
        end
    end
    pcall(function()
        local pre = _RunService.PreSimulation
        if typeof(pre) == 'RBXScriptSignal' then
            pre:Connect(function() if dsBound or dsCF then flush() end end)
        end
    end)
    local function apply(cf)
        local ch = LP.Character
        local root = ch and ch:FindFirstChild('HumanoidRootPart')
        if not root or not root:IsA('BasePart') then return false end
        local keep = dsCF ~= nil and (dsBound or (dsShown and (root.Position - dsShown.Position).Magnitude < 0.2))
        if not keep or dsRoot ~= root then
            dsRoot, dsCF, dsVel, dsRot = root, root.CFrame, root.AssemblyLinearVelocity, root.AssemblyAngularVelocity
        end
        root.CFrame = cf
        dsShown = cf
        if not dsBound then
            dsBound = true
            _RunService:BindToRenderStep('GR_DsRestore', Enum.RenderPriority.Camera.Value - 1, flush)
        end
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
        for _, pl in ipairs(_Players:GetPlayers()) do
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
        local objectId
        pcall(function() objectId = item:Get('ObjectID') end)
        if not objectId then return end
        local ch = hrp and hrp.Parent
        if not (ch and head) then return end
        local hum = ch:FindFirstChildOfClass('Humanoid')
        if not hum or hum.Health <= 0 then return end
        if GR.knife and deflecting[pl] then return end
        local part = hitbox(ch, head, not GR.head)
        local aimPos = leadPos(hrp)
        local hitPoint = part.Position
        local dcf
        if hasKnifeVM(pl) then
            dcf = CFrame.lookAt(hrp.Position + Vector3.new(0, -5, 0), aimPos)
        else
            local f = hrp.CFrame.LookVector
            local flat = Vector3.new(f.X, 0, f.Z)
            if flat.Magnitude < 0.05 then flat = Vector3.new(0, 0, -1) end
            dcf = CFrame.lookAt(hrp.Position + flat.Unit + Vector3.new(0, 1, 0), aimPos)
        end
        if GR.desync then apply(dcf) end
        local eye = dcf.Position + EYE
        if (eye - aimPos).Magnitude < 0.1 then eye = aimPos + Vector3.new(0, 0.2, 0) end
        local aimCF = CFrame.lookAt(eye, aimPos)
        local offset = part.CFrame:ToObjectSpace(CFrame.new(hitPoint))
        local eAim, eOff
        if not pcall(function()
            eAim = _util:EncodeCFrame(aimCF)
            eOff = _util:EncodeCFrame(offset)
        end) or not eAim then return end
        local data = { [K1] = { [K0] = eAim, [K1] = eAim, [K2] = part, [K3] = eOff } }
        if pellets(item) > 1 then data[K2] = true end
        local en
        pcall(function() en = _enum:ToEnum('StartShooting') end)
        if not en then return end
        pcall(function() _remote:FireServer(objectId, en, data, nil) end)
    end

    local lastFire = 0
    local function start()
        if hb then hb:Disconnect(); hb = nil end
        if GR.equip then startEquip() end
        hb = _RunService.Heartbeat:Connect(function()
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
            lastFire = tick()
            task.spawn(fire, pl, hrp, head)
        end)
    end
    local function stop()
        GR.on = false
        if hb then hb:Disconnect(); hb = nil end
        flush()
    end

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
    B:AddDropdown('GravSlot', { Text = 'Weapon', Values = { 'Primary', 'Secondary', 'Melee' }, Default = 'Primary', Multi = false,
        Callback = function(v) GR.slot = ({ Primary = 1, Secondary = 2, Melee = 3 })[v] or 1 end })
    pcall(function() Library:OnUnload(function() alive = false; stop() end) end)

    local FUG = Tabs.Rage:AddLeftGroupbox('Fake Underground')
    FUG:AddToggle('FakeUnderground', { Text='Fake Underground', Default=false,
        Tooltip='Holds your character underground while your view stays on the surface.',
        Callback=function(v) if v then turnOnFU() else turnOffFU() end end })
        :AddKeyPicker('FakeUndergroundKey', { Default='None', Mode='Toggle', SyncToggleState=true, Text='Fake Underground' })
    FUG:AddSlider('FUDepth', { Text='Depth', Default=FU.depth, Min=0, Max=150, Rounding=1, Suffix=' studs',
        Callback=function(v) FU.depth = v end })
    FUG:AddToggle('FUWalk', { Text='Walk mode', Default=FU.walk, Callback=function(v) FU.walk = v end })
    FUG:AddToggle('FUCamera', { Text='Surface camera', Default=FU.camera, Callback=function(v) FU.camera = v end })
    FUG:AddToggle('FUNoclip', { Text='Auto noclip', Default=FU.noclip, Callback=function(v) FU.noclip = v end })
    FUG:AddToggle('FUHide', { Text='Hide my character', Default=FU.hide,
        Callback=function(v) FU.hide = v ; if FU.on then if v then hideChar() else showChar() end end end })
    FUG:AddToggle('FUAnim', { Text='Animation desync', Default=FU.anim,
        Callback=function(v) FU.anim = v ; if FU.on then if v then startAnim() else stopAnim() end end end })
    FUG:AddToggle('FUPanic', { Text='Panic jitter', Default=FU.panic, Callback=function(v) FU.panic = v end })
    FUG:AddSlider('FUPanicMin', { Text='Jitter min X', Default=FU.pMin, Min=-50, Max=0, Rounding=0, Callback=function(v) FU.pMin = v end })
    FUG:AddSlider('FUPanicMax', { Text='Jitter max X', Default=FU.pMax, Min=0, Max=50, Rounding=0, Callback=function(v) FU.pMax = v end })
    FUG:AddToggle('FUPanicZ', { Text='Jitter Z too', Default=FU.pZ, Callback=function(v) FU.pZ = v end })
end)() end

-- =========================================================
-- UI: ESP
-- =========================================================
do
    local GRAD_MODES = {'Solid','Gradient'}
    local W = Color3.fromRGB(255, 255, 255)
    local function colourRow(box, label, key, modes, solidDefault, aDefault, bDefault)
        local modeKey = 'ESP' .. key .. 'ColorMode'
        local colKey  = 'ESP' .. key .. 'Color'
        local aKey    = 'ESP' .. key .. 'GradA'
        local bKey    = 'ESP' .. key .. 'GradB'
        box:AddDropdown(modeKey, { Values=modes, Default=(Config[modeKey] or modes[1]), Text=label .. ' colour', Callback=function(v) Config[modeKey] = v end })
        local sd = box:AddDependencyBox()
        sd:AddLabel(label):AddColorPicker(colKey, { Default=(Config[colKey] or solidDefault), Callback=function(v) Config[colKey] = v end })
        sd:SetupDependencies({ { Options[modeKey], 'Solid' } })
        local gd = box:AddDependencyBox()
        gd:AddLabel(label .. ' A'):AddColorPicker(aKey, { Default=(Config[aKey] or aDefault), Callback=function(v) Config[aKey] = v end })
        gd:AddLabel(label .. ' B'):AddColorPicker(bKey, { Default=(Config[bKey] or bDefault), Callback=function(v) Config[bKey] = v end })
        gd:SetupDependencies({ { Options[modeKey], 'Gradient' } })
    end
    local L = Tabs.ESP:AddLeftGroupbox('ESP & Boxes')
    L:AddToggle('ESP', { Text='Enable ESP', Default=Config.ESP, Callback=function(v) if v then ESP.enable() else ESP.disable() end end })
        :AddKeyPicker('ESPToggleKey', { Default='None', Mode='Toggle', SyncToggleState=true, Text='ESP' })
    local espDep = L:AddDependencyBox()
    espDep:AddToggle('ESPTeamCheck', { Text='Team check', Default=Config.ESPTeamCheck, Callback=function(v) Config.ESPTeamCheck = v end })
    espDep:AddToggle('ESPBox', { Text='Box', Default=Config.ESPBox, Callback=function(v) Config.ESPBox = v end })
    local boxDep = espDep:AddDependencyBox()
    boxDep:AddDropdown('ESPBoxStyle', { Values={'Full Box','Corner Brackets'}, Default=Config.ESPBoxStyle, Text='Box style', Callback=function(v) Config.ESPBoxStyle = v end })
    boxDep:AddSlider('ESPBoxThickness', { Text='Box thickness', Default=Config.ESPBoxThickness, Min=1, Max=4, Rounding=0, Callback=function(v) Config.ESPBoxThickness = math.floor(v) end })
    boxDep:AddSlider('ESPBoxScale', { Text='Box size', Default=Config.ESPBoxScale, Min=0.6, Max=1.6, Rounding=2, Callback=function(v) Config.ESPBoxScale = v end })
    boxDep:AddToggle('ESPBoxFill', { Text='Fill', Default=Config.ESPBoxFill, Callback=function(v) Config.ESPBoxFill = v end })
    colourRow(boxDep, 'Box', 'Box', GRAD_MODES, W, Color3.fromRGB(255,59,78), Color3.fromRGB(255,194,75))
    boxDep:SetupDependencies({ { Toggles.ESPBox, true } })
    espDep:SetupDependencies({ { Toggles.ESP, true } })
    local L2 = Tabs.ESP:AddLeftGroupbox('Health & Info')
    L2:AddToggle('ESPHealth', { Text='Health bar', Default=Config.ESPHealth, Callback=function(v) Config.ESPHealth = v end })
    L2:AddDropdown('ESPHealthNumberMode', { Values={'Off','OnDamage','Always'}, Default=Config.ESPHealthNumberMode, Text='Number readout', Callback=function(v) Config.ESPHealthNumberMode = v end })
    L2:AddToggle('ESPName', { Text='Name', Default=Config.ESPName, Callback=function(v) Config.ESPName = v end })
    L2:AddToggle('ESPDistance', { Text='Distance', Default=Config.ESPDistance, Callback=function(v) Config.ESPDistance = v end })
    L2:AddToggle('ESPWeapon', { Text='Weapon', Default=Config.ESPWeapon, Callback=function(v) Config.ESPWeapon = v end })
    local L3 = Tabs.ESP:AddLeftGroupbox('Skeleton, Tracers & Markers')
    L3:AddToggle('ESPSkeleton', { Text='Skeleton', Default=Config.ESPSkeleton, Callback=function(v) Config.ESPSkeleton = v end })
    L3:AddToggle('ESPTracers', { Text='Tracers', Default=Config.ESPTracers, Callback=function(v) Config.ESPTracers = v end })
    L3:AddToggle('ESPHeadDot', { Text='Head dot', Default=Config.ESPHeadDot, Callback=function(v) Config.ESPHeadDot = v end })
    L3:AddToggle('ESPChams', { Text='Chams', Default=Config.ESPChams, Callback=function(v) Config.ESPChams = v end })
    L3:AddToggle('ESPFlagDeflect', { Text='DEFLECT flag', Default=Config.ESPFlagDeflect, Callback=function(v) Config.ESPFlagDeflect = v end })
    L3:AddToggle('ESPFlagShield', { Text='SHIELD flag', Default=Config.ESPFlagShield, Callback=function(v) Config.ESPFlagShield = v end })
    L3:AddToggle('ESPFlagInvincible', { Text='INVULN flag', Default=Config.ESPFlagInvincible, Callback=function(v) Config.ESPFlagInvincible = v end })
    L3:AddToggle('ESPFlagLowHP', { Text='LOW flag', Default=Config.ESPFlagLowHP, Callback=function(v) Config.ESPFlagLowHP = v end })
    L3:AddToggle('ESPDeclutter', { Text='Declutter overlapping', Default=Config.ESPDeclutter, Callback=function(v) Config.ESPDeclutter = v end })

    local R = Tabs.ESP:AddRightGroupbox('Text & Fonts')
    R:AddDropdown('ESPFont', { Values={'Code','RobotoMono','Gotham','GothamBold','Arial','SourceSans'}, Default=Config.ESPFont, Text='Font', Callback=function(v) Config.ESPFont = v end })
    R:AddSlider('ESPTextSize', { Text='Name size', Default=Config.ESPTextSize, Min=9, Max=24, Rounding=0, Callback=function(v) Config.ESPTextSize = math.floor(v) end })
    R:AddSlider('ESPInfoTextSize', { Text='Info size', Default=Config.ESPInfoTextSize, Min=9, Max=22, Rounding=0, Callback=function(v) Config.ESPInfoTextSize = math.floor(v) end })
    R:AddSlider('ESPTextScale', { Text='Text scale', Default=Config.ESPTextScale, Min=0.6, Max=1.6, Rounding=2, Callback=function(v) Config.ESPTextScale = v end })

    local R3 = Tabs.ESP:AddRightGroupbox('Range')
    R3:AddSlider('ESPMaxDistance', { Text='Max distance', Default=Config.ESPMaxDistance, Min=50, Max=3000, Rounding=0, Callback=function(v) Config.ESPMaxDistance = math.floor(v) end })
    R3:AddSlider('ESPMaxPlayers', { Text='Max targets (0 = all)', Default=Config.ESPMaxPlayers, Min=0, Max=24, Rounding=0, Callback=function(v) Config.ESPMaxPlayers = math.floor(v) end })
    R3:AddButton({ Text='Rebuild ESP Objects', Func=function() pcall(ESP.rebuildAll) end })
end

-- =========================================================
-- UI: VISUALS (Cosmetics + Spoofer)
-- =========================================================
do (function()
    local RTB = Tabs.Visuals:AddRightTabbox('Game & Profile')
    local GL = RTB:AddTab('Cosmetics')
    local SP = RTB:AddTab('Spoofer')

    GL:AddToggle('GameVisuals', { Text='Enable Cosmetics', Default=(Config.GameVisuals or false),
        Callback=function(v) if v then GameVisuals.enable() else GameVisuals.disable() end end })
    local gvDep = GL:AddDependencyBox()
    gvDep:AddToggle('GVUnlockAll', { Text='Unlock all cosmetics', Default=(Config.GVUnlockAll or true),
        Callback=function(v) pcall(GameVisuals.setUnlockAll, v) end })
    gvDep:AddToggle('GVUnlockWeapons', { Text='Unlock all weapons', Default=(Config.GVUnlockWeapons or false),
        Callback=function(v) pcall(GameVisuals.setUnlockWeapons, v) end })
    gvDep:AddToggle('GVEveryone', { Text='Apply to everyone (not just you)', Default=(Config.GVEveryone or false),
        Callback=function(v) Config.GVEveryone = v end })
    gvDep:AddToggle('GVFinisherClone', { Text='Finisher clone', Default=(Config.GVFinisherClone ~= false),
        Callback=function(v) Config.GVFinisherClone = v end })
    gvDep:AddToggle('GVRemember', { Text='Remember picks', Default=(Config.GVRemember or true),
        Callback=function(v) Config.GVRemember = v; if v then pcall(GameVisuals.saveConfig) end end })
    gvDep:AddButton({ Text='Reset all cosmetics', Func=function() pcall(GameVisuals.restore) end })
    gvDep:AddDivider('Manual picker')
    gvDep:AddDropdown('GVWeapon', { Values={'None'}, Default='None', Text='Weapon',
        Callback=function(v) pcall(GameVisuals.setWeapon, v) end })
    gvDep:AddDropdown('GVSkin', { Values={'None'}, Default='None', Text='Skin',
        Callback=function(v) pcall(GameVisuals.setSkin, v) end })
    gvDep:AddDropdown('GVCharm', { Values={'None'}, Default='None', Text='Charm',
        Callback=function(v) pcall(GameVisuals.setCharm, v) end })
    gvDep:AddDropdown('GVWrap', { Values={'None'}, Default='None', Text='Wrap',
        Callback=function(v) pcall(GameVisuals.setWrap, v) end })
    gvDep:AddDropdown('GVFinisher', { Values={'None'}, Default='None', Text='Finisher',
        Callback=function(v) pcall(GameVisuals.setFinisher, v) end })
    gvDep:AddToggle('GVWrapInverted', { Text='Invert wrap', Default=(Config.GVWrapInverted or false),
        Callback=function(v) pcall(GameVisuals.setWrapInverted, v) end })
    gvDep:AddDivider('Ranked charm')
    gvDep:AddToggle('GVRankCharmOn', { Text='Spoof ranked charm rank', Default=(Config.GVRankCharmOn or false),
        Callback=function(v) Config.GVRankCharmOn = v; if v then pcall(GameVisuals.refreshRankCharmMeta) end end })
    gvDep:AddDropdown('GVRankWep', { Values={'Held weapon'}, Default='Held weapon', Text='Ranked charm on',
        Callback=function(v) end })
    gvDep:AddDropdown('GVRankLook', { Values={}, Default='None', Text='Make it look like',
        Callback=function(v)
            if v == nil or v == 'None' then return end
            local wv = 'Held weapon'
            pcall(function() wv = Options.GVRankWep.Value or wv end)
            pcall(GameVisuals.applyRankedCharm, v, wv)
        end })
    gvDep:SetupDependencies({ { Toggles.GameVisuals, true } })

    -- Poll to update dropdowns once modules resolve
    task.spawn(function()
        local sig = nil
        while true do
            task.wait(3)
            local ok, lists = pcall(function()
                return { GameVisuals.weaponList(), GameVisuals.skinList(), GameVisuals.charmList(),
                         GameVisuals.wrapList(), GameVisuals.finisherList(), GameVisuals.rankNames(),
                         GameVisuals.rankedCharmsFor() }
            end)
            if ok and type(lists) == 'table' then
                local lens = {}
                for i = 1, 7 do lens[i] = lists[i] and #lists[i] or 0 end
                local now = table.concat(lens, '/')
                if now ~= sig then
                    sig = now
                    pcall(function() Options.GVWeapon:SetValues(lists[1]) end)
                    pcall(function() Options.GVSkin:SetValues(lists[2]) end)
                    pcall(function() Options.GVCharm:SetValues(lists[3]) end)
                    pcall(function() Options.GVWrap:SetValues(lists[4]) end)
                    pcall(function() Options.GVFinisher:SetValues(lists[5]) end)
                    pcall(function() Options.GVRankLook:SetValues(lists[6]) end)
                    pcall(function() Options.GVRankWep:SetValues(lists[7]) end)
                end
            end
        end
    end)

    GL:AddDivider('Live Loaded')
    local loaded = {}
    for i = 1, 6 do loaded[i] = GL:AddLabel(' ', true) end
    task.spawn(function()
        local shown = nil
        while GameVisuals.uiAlive do
            task.wait(0.35)
            local lines = GameVisuals.summary()
            if #lines == 0 and Config.GameVisuals == true and GameVisuals.ready() ~= true then
                lines = { 'not active yet' }
            end
            local joined = table.concat(lines, '\n')
            if joined ~= shown then
                shown = joined
                for i = 1, 6 do
                    pcall(function() loaded[i]:SetText(lines[i] or ' ') end)
                end
            end
        end
    end)

    -- ============ SPOOFER ============
    SP:AddDivider('Identity')
    SP:AddToggle('SpooferNameEnabled', { Text='Spoof name', Default=(Config.SpooferNameEnabled or false),
        Callback=function(v) Config.SpooferNameEnabled = v; Visuals.applyGuiNameSpoof() end })
    local spNDep = SP:AddDependencyBox()
    spNDep:AddInput('SpooferName', { Default=(Config.SpooferName or 'ProPlayer'), Text='Username',
        Placeholder='Username', Finished=false,
        Callback=function(v) Config.SpooferName = v; Visuals.applyGuiNameSpoof() end })
    spNDep:AddInput('SpooferDisplayName', { Default=(Config.SpooferDisplayName or 'ProPlayer'), Text='Display name',
        Placeholder='Display name', Finished=false,
        Callback=function(v) Config.SpooferDisplayName = v; Visuals.applyGuiNameSpoof() end })
    spNDep:SetupDependencies({ { Toggles.SpooferNameEnabled, true } })

    SP:AddDivider('Ranked & Stats')
    SP:AddToggle('SpooferLevelEnabled', { Text='Spoof level', Default=(Config.SpooferLevelEnabled or false),
        Callback=function(v) Config.SpooferLevelEnabled = v; Visuals.updatePlayerSpoofer() end })
    local spLDep = SP:AddDependencyBox()
    spLDep:AddInput('SpooferLevel', { Default=tostring(Config.SpooferLevel or 100), Text='Level',
        Placeholder='100', Finished=false, Numeric=true,
        Callback=function(v) Config.SpooferLevel = tonumber(v) or 100; Visuals.updatePlayerSpoofer() end })
    spLDep:SetupDependencies({ { Toggles.SpooferLevelEnabled, true } })

    SP:AddToggle('SpooferRankedEloEnabled', { Text='Spoof ELO', Default=(Config.SpooferRankedEloEnabled or false),
        Callback=function(v) Config.SpooferRankedEloEnabled = v; Visuals.updatePlayerSpoofer() end })
    local spEDep = SP:AddDependencyBox()
    spEDep:AddInput('SpooferRankedElo', { Default=tostring(Config.SpooferRankedElo or 2400), Text='ELO rating',
        Placeholder='2400', Finished=false, Numeric=true,
        Callback=function(v) Config.SpooferRankedElo = tonumber(v) or 2400; Visuals.updatePlayerSpoofer() end })
    spEDep:SetupDependencies({ { Toggles.SpooferRankedEloEnabled, true } })

    SP:AddToggle('SpooferCasualWinsEnabled', { Text='Spoof casual wins', Default=(Config.SpooferCasualWinsEnabled or false),
        Callback=function(v) Config.SpooferCasualWinsEnabled = v; Visuals.updatePlayerSpoofer() end })
    local spWDep = SP:AddDependencyBox()
    spWDep:AddInput('SpooferCasualWins', { Default=tostring(Config.SpooferCasualWins or 500), Text='Casual wins',
        Placeholder='500', Finished=false, Numeric=true,
        Callback=function(v) Config.SpooferCasualWins = tonumber(v) or 500; Visuals.updatePlayerSpoofer() end })
    spWDep:SetupDependencies({ { Toggles.SpooferCasualWinsEnabled, true } })

    SP:AddToggle('SpooferRankedWinsEnabled', { Text='Spoof ranked wins', Default=(Config.SpooferRankedWinsEnabled or false),
        Callback=function(v) Config.SpooferRankedWinsEnabled = v; Visuals.updatePlayerSpoofer() end })
    local spRWDep = SP:AddDependencyBox()
    spRWDep:AddInput('SpooferRankedWins', { Default=tostring(Config.SpooferRankedWins or 250), Text='Ranked wins',
        Placeholder='250', Finished=false, Numeric=true,
        Callback=function(v) Config.SpooferRankedWins = tonumber(v) or 250; Visuals.updatePlayerSpoofer() end })
    spRWDep:SetupDependencies({ { Toggles.SpooferRankedWinsEnabled, true } })

    SP:AddToggle('SpooferWinPercentEnabled', { Text='Spoof winrate', Default=(Config.SpooferWinPercentEnabled or false),
        Callback=function(v) Config.SpooferWinPercentEnabled = v; Visuals.updatePlayerSpoofer() end })
    local spPDep = SP:AddDependencyBox()
    spPDep:AddInput('SpooferWinPercent', { Default=tostring(Config.SpooferWinPercent or 75), Text='Winrate %',
        Placeholder='75', Finished=false, Numeric=true,
        Callback=function(v) Config.SpooferWinPercent = tonumber(v) or 75; Visuals.updatePlayerSpoofer() end })
    spPDep:SetupDependencies({ { Toggles.SpooferWinPercentEnabled, true } })

    SP:AddToggle('SpooferWinStreakEnabled', { Text='Spoof win streak', Default=(Config.SpooferWinStreakEnabled or false),
        Callback=function(v) Config.SpooferWinStreakEnabled = v; Visuals.updatePlayerSpoofer() end })
    local spSDep = SP:AddDependencyBox()
    spSDep:AddInput('SpooferWinStreak', { Default=tostring(Config.SpooferWinStreak or 25), Text='Win streak',
        Placeholder='25', Finished=false, Numeric=true,
        Callback=function(v) Config.SpooferWinStreak = tonumber(v) or 25; Visuals.updatePlayerSpoofer() end })
    spSDep:SetupDependencies({ { Toggles.SpooferWinStreakEnabled, true } })

    SP:AddToggle('SpooferFavoriteMapEnabled', { Text='Spoof favorite map', Default=(Config.SpooferFavoriteMapEnabled or false),
        Callback=function(v) Config.SpooferFavoriteMapEnabled = v; Visuals.updatePlayerSpoofer() end })
    local spMDep = SP:AddDependencyBox()
    spMDep:AddInput('SpooferFavoriteMap', { Default=tostring(Config.SpooferFavoriteMap or 'Arena'), Text='Map name',
        Placeholder='Arena', Finished=false,
        Callback=function(v) Config.SpooferFavoriteMap = v; Visuals.updatePlayerSpoofer() end })
    spMDep:SetupDependencies({ { Toggles.SpooferFavoriteMapEnabled, true } })
end)() end

-- =========================================================
-- UI: SETTINGS
-- =========================================================
do
    local L = Tabs.Settings:AddLeftGroupbox('Menu')
    L:AddToggle('ShowWatermark', { Text='Show watermark', Default=false, Callback=function(v)
        pcall(function() Library:SetWatermarkVisibility(v) end)
    end })
    L:AddDivider()
    L:AddButton({ Text='UNLOAD JewHook', DoubleClick=true, Func=function()
        pcall(function() ESP.disable() end)
        pcall(function() Aimbot.unload() end)
        pcall(function() Trigger.unload() end)
        pcall(function() Rage.unload() end)
        pcall(function() GameVisuals.disable() end)
        pcall(function() turnOffFU() end)
        Library:Unload()
        _G["\74\72"] = nil
    end })
end

-- =========================================================
-- CONFIGS + FINAL INIT
-- =========================================================
do
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ 'MenuKeybind', 'GVWeapon', 'GVSkin', 'GVCharm', 'GVWrap',
        'GVFinisher', 'GVRankWep', 'GVRankLook' })
    ThemeManager:SetFolder('JewHook')
    SaveManager:SetFolder('JewHook/configs')
    SaveManager:BuildConfigSection(Tabs.Settings)
    ThemeManager:ApplyToTab(Tabs.Settings)
    pcall(function() SaveManager:LoadAutoloadConfig() end)
end

pcall(Rage.init)
pcall(Aimbot.init)
pcall(Trigger.init)
pcall(ESP.init)
pcall(Visuals.initSpoofer)

local _origUnload = Library.Unload
Library.Unload = function(self, ...)
    pcall(function()
        if shared._JH_GunOrig and Rivals.Gun then
            if setreadonly then pcall(setreadonly, Rivals.Gun, false) end
            Rivals.Gun.StartShooting = shared._JH_GunOrig
        end
        shared._JH_GunOrig = nil
        if shared._JH_KatanaMod and shared._JH_KatanaDeflOrig then
            if setreadonly then pcall(setreadonly, shared._JH_KatanaMod, false) end
            shared._JH_KatanaMod._StartDeflecting = shared._JH_KatanaDeflOrig
        end
        shared._JH_KatanaMod, shared._JH_KatanaDeflOrig = nil, nil
    end)
    pcall(ViewAngle.restore)
    GameVisuals.uiAlive = false
    pcall(GameVisuals.disable)
    return _origUnload(self, ...)
end

_G["\74\72"] = Library
pcall(function() Library:SetWatermark('JewHook v1 beta') end)
pcall(function() Library:SetWatermarkVisibility(false) end)
Library:Notify('JewHook v1 beta loaded (rage + graviton + visuals)', 4)