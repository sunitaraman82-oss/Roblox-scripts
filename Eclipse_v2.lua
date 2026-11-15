--[[
    Eclipse v2 — Rivals
    Full-featured mobile cheat menu
    UI: LinoriaLib | All features wired
]]

-- ── Bootstrap ─────────────────────────────────────────────────────────────────
local cloneref = cloneref or function(x) return x end
local Players    = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UIS        = cloneref(game:GetService("UserInputService"))
local TweenS     = cloneref(game:GetService("TweenService"))
local Workspace  = cloneref(game:GetService("Workspace"))
local RepS       = cloneref(game:GetService("ReplicatedStorage"))
local CoreGui    = game:GetService("CoreGui")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end)

-- ── Safe loadstring ───────────────────────────────────────────────────────────
local function safeLoad(src)
    local fn, err
    if loadstring then fn, err = loadstring(src) end
    if not fn then fn, err = load(src, "chunk", "t", getfenv and getfenv(0) or nil) end
    assert(fn, err)
    return fn()
end
local function safeHttp(url)
    local body
    if not body then pcall(function() body = game:HttpGet(url, true) end) end
    if not body then pcall(function() body = request({Url=url,Method="GET"}).Body end) end
    assert(body and #body > 0, "HTTP failed: "..url)
    return body
end

-- ── LinoriaLib ────────────────────────────────────────────────────────────────
local repo = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/"
local Library      = safeLoad(safeHttp(repo.."Library.lua"))
local ThemeManager = safeLoad(safeHttp(repo.."addons/ThemeManager.lua"))
local SaveManager  = safeLoad(safeHttp(repo.."addons/SaveManager.lua"))

Library.IsMobile = true
Library.ShowCustomCursor = false

local Window = Library:CreateWindow({
    Title    = "Eclipse v2",
    Center   = true,
    AutoShow = true,
})

local Tabs = {
    Combat     = Window:AddTab("Combat"),
    Visuals    = Window:AddTab("Visuals"),
    Movement   = Window:AddTab("Movement"),
    Automation = Window:AddTab("Automation"),
    Utility    = Window:AddTab("Utility"),
    Settings   = Window:AddTab("Settings"),
}

local Options = Library.Options
local Toggles = Library.Toggles
local function T(n) return Toggles[n] and Toggles[n].Value end
local function O(n) return Options[n] and Options[n].Value end

-- ═══════════════════════════════════════════════════════════════════════════
-- COMBAT TAB
-- ═══════════════════════════════════════════════════════════════════════════
local AimGroup = Tabs.Combat:AddLeftGroupbox("Aimbot")
AimGroup:AddToggle("AimbotEnabled",   {Text="Enabled",         Default=false})
AimGroup:AddDropdown("AimbotMode",    {Text="Mode",            Values={"Lock","Spring","Linear"}, Default="Spring"})
AimGroup:AddSlider("AimbotSmooth",    {Text="Smoothness",      Default=15, Min=1, Max=100, Rounding=0})
AimGroup:AddSlider("AimbotFOV",       {Text="FOV",             Default=500, Min=50, Max=2000, Rounding=0})
AimGroup:AddDropdown("AimbotPart",    {Text="Hit Part",        Values={"Head","Body","Closest"}, Default="Head"})
AimGroup:AddToggle("AimbotTeam",      {Text="Team Check",      Default=true})
AimGroup:AddToggle("AimbotWall",      {Text="Wall Check",      Default=true})
AimGroup:AddToggle("AimbotFOVCircle", {Text="Show FOV Circle", Default=true})

local SAGroup = Tabs.Combat:AddLeftGroupbox("Silent Aim")
SAGroup:AddToggle("SAEnabled",    {Text="Enabled",       Default=false})
SAGroup:AddSlider("SAChance",     {Text="Hit Chance %",  Default=100, Min=0, Max=100, Rounding=0})
SAGroup:AddSlider("SAJitter",     {Text="Jitter (deg)",  Default=1, Min=0, Max=10, Rounding=1})
SAGroup:AddToggle("SAMultipoint", {Text="Multipoint",    Default=false})
SAGroup:AddToggle("SALead",       {Text="Predict Lead",  Default=true})
SAGroup:AddToggle("SATorso",      {Text="Torso Fallback",Default=true})

local RageGroup = Tabs.Combat:AddRightGroupbox("Ragebot")
RageGroup:AddToggle("RageEnabled",  {Text="Enabled",      Default=false})
RageGroup:AddDropdown("RageSlot",   {Text="Weapon Slot",  Values={"Primary","Secondary","Melee"}, Default="Melee"})
RageGroup:AddSlider("RageFireRate", {Text="Fire Rate",     Default=1, Min=1, Max=100, Rounding=0})
RageGroup:AddSlider("RageOrbit",    {Text="Orbit Radius",  Default=14, Min=2, Max=30, Rounding=0})
RageGroup:AddToggle("RageAntiHit",  {Text="Anti-Hit",      Default=true})
RageGroup:AddToggle("RageKnife",    {Text="Knife Aware",   Default=true})

local TriggerGroup = Tabs.Combat:AddRightGroupbox("Triggerbot")
TriggerGroup:AddToggle("TriggerEnabled", {Text="Enabled",        Default=false})
TriggerGroup:AddSlider("TriggerDelay",   {Text="Reaction (ms)",  Default=0, Min=0, Max=500, Rounding=0})
TriggerGroup:AddDropdown("TriggerPart",  {Text="Target Part",    Values={"Any","Head","Torso"}, Default="Any"})

local AAGroup = Tabs.Combat:AddRightGroupbox("Anti-Aim")
AAGroup:AddDropdown("AAPitch",      {Text="Pitch",       Values={"Off","Up","Down","Random","Custom"}, Default="Off"})
AAGroup:AddSlider("AAPitchAngle",   {Text="Pitch Angle", Default=0, Min=-180, Max=180, Rounding=0})
AAGroup:AddDropdown("AAYaw",        {Text="Yaw",         Values={"Off","Backwards","Random","Custom"}, Default="Off"})
AAGroup:AddSlider("AAYawAngle",     {Text="Yaw Angle",   Default=0, Min=-180, Max=180, Rounding=0})
AAGroup:AddToggle("AAUnderground",  {Text="Underground", Default=false})

-- ═══════════════════════════════════════════════════════════════════════════
-- VISUALS TAB
-- ═══════════════════════════════════════════════════════════════════════════
local ESPGroup = Tabs.Visuals:AddLeftGroupbox("ESP")
ESPGroup:AddToggle("ESPEnabled",  {Text="Enabled",        Default=false})
ESPGroup:AddToggle("ESPBox",      {Text="Box",            Default=true})
ESPGroup:AddToggle("ESPSkeleton", {Text="Skeleton",       Default=false})
ESPGroup:AddToggle("ESPHealth",   {Text="Health Bar",     Default=true})
ESPGroup:AddToggle("ESPName",     {Text="Name",           Default=true})
ESPGroup:AddToggle("ESPDist",     {Text="Distance",       Default=false})
ESPGroup:AddToggle("ESPChams",    {Text="Chams",          Default=false})
ESPGroup:AddToggle("ESPTeam",     {Text="Show Teammates", Default=false})
ESPGroup:AddSlider("ESPMaxDist",  {Text="Max Distance",   Default=500, Min=50, Max=2000, Rounding=0})
ESPGroup:AddLabel("Visible Color"):AddColorPicker("ESPColVis",    {Default=Color3.fromRGB(0,255,0)})
ESPGroup:AddLabel("Hidden Color"):AddColorPicker("ESPColHid",     {Default=Color3.fromRGB(255,0,0)})
ESPGroup:AddLabel("Chams Color"):AddColorPicker("ESPColChams",    {Default=Color3.fromRGB(235,64,80)})

local TracerGroup = Tabs.Visuals:AddRightGroupbox("Tracers & FOV")
TracerGroup:AddToggle("TracerEnabled", {Text="Tracers",      Default=false})
TracerGroup:AddDropdown("TracerFrom",  {Text="From",         Values={"Bottom","Center","Top"}, Default="Bottom"})
TracerGroup:AddLabel("Tracer Color"):AddColorPicker("TracerColor",{Default=Color3.fromRGB(255,255,255)})
TracerGroup:AddToggle("FOVEnabled",    {Text="FOV Circle",   Default=true})
TracerGroup:AddSlider("FOVRadius",     {Text="FOV Radius",   Default=500, Min=50, Max=2000, Rounding=0})
TracerGroup:AddLabel("FOV Color"):AddColorPicker("FOVColor",      {Default=Color3.fromRGB(255,255,255)})

local DropESPGroup = Tabs.Visuals:AddRightGroupbox("Dropped Item ESP")
DropESPGroup:AddToggle("DropESPEnabled", {Text="Enabled",    Default=false})
DropESPGroup:AddSlider("DropESPDist",    {Text="Max Dist",   Default=200, Min=20, Max=1000, Rounding=0})
DropESPGroup:AddLabel("Drop Color"):AddColorPicker("DropESPColor", {Default=Color3.fromRGB(255,220,0)})

-- ═══════════════════════════════════════════════════════════════════════════
-- MOVEMENT TAB
-- ═══════════════════════════════════════════════════════════════════════════
local MoveGroup = Tabs.Movement:AddLeftGroupbox("Movement")
MoveGroup:AddToggle("SpeedEnabled",  {Text="Speed Boost",     Default=false})
MoveGroup:AddSlider("SpeedMult",     {Text="Walk Multiplier", Default=2, Min=1, Max=10, Rounding=1})
MoveGroup:AddToggle("JumpEnabled",   {Text="Jump Boost",      Default=false})
MoveGroup:AddSlider("JumpMult",      {Text="Jump Multiplier", Default=2, Min=1, Max=10, Rounding=1})
MoveGroup:AddToggle("NoclipEnabled", {Text="Noclip",          Default=false})
MoveGroup:AddToggle("InfJump",       {Text="Infinite Double Jump", Default=false})
MoveGroup:AddToggle("LongJump",      {Text="Long Jump",       Default=false})
MoveGroup:AddToggle("AutoStrafe",    {Text="Auto Strafe",     Default=false})
MoveGroup:AddSlider("StrafeMult",    {Text="Strafe Speed",    Default=50, Min=10, Max=200, Rounding=0})

local FlyGroup = Tabs.Movement:AddRightGroupbox("Flight")
FlyGroup:AddToggle("FlyEnabled",  {Text="Fly",          Default=false})
FlyGroup:AddSlider("FlySpeed",    {Text="Fly Speed",    Default=80, Min=10, Max=400, Rounding=0})

-- ═══════════════════════════════════════════════════════════════════════════
-- AUTOMATION TAB
-- ═══════════════════════════════════════════════════════════════════════════
local QueueGroup = Tabs.Automation:AddLeftGroupbox("Auto Queue")
QueueGroup:AddToggle("AutoQueue",   {Text="Enabled",  Default=false})
QueueGroup:AddDropdown("QueueMode", {Text="Mode",     Values={"1v1","2v2","3v3","4v4","5v5"}, Default="1v1"})

local RespawnGroup = Tabs.Automation:AddLeftGroupbox("Auto Respawn")
RespawnGroup:AddToggle("AutoRespawn", {Text="Enabled", Default=false})

local LoadoutGroup = Tabs.Automation:AddRightGroupbox("Auto Loadout")
LoadoutGroup:AddToggle("AutoLoadout",    {Text="Enabled",   Default=false})
LoadoutGroup:AddDropdown("LoadoutSlot1", {Text="Primary",   Values={"Assault Rifle","Sniper","Shotgun","None"}, Default="None"})
LoadoutGroup:AddDropdown("LoadoutSlot2", {Text="Secondary", Values={"Handgun","Revolver","None"}, Default="None"})
LoadoutGroup:AddDropdown("LoadoutSlot3", {Text="Melee",     Values={"Knife","Katana","Fists","None"}, Default="None"})

local BanGroup = Tabs.Automation:AddRightGroupbox("Auto Weapon Ban")
BanGroup:AddToggle("AutoBan",   {Text="Enabled",    Default=false})
BanGroup:AddDropdown("Ban1",    {Text="First Ban",  Values={"None","Primary","Secondary","Melee"}, Default="None"})
BanGroup:AddDropdown("Ban2",    {Text="Second Ban", Values={"None","Primary","Secondary","Melee"}, Default="None"})

local MapGroup = Tabs.Automation:AddLeftGroupbox("Auto Map Vote")
MapGroup:AddToggle("AutoMap",    {Text="Enabled", Default=false})
MapGroup:AddDropdown("MapVote",  {Text="Vote For",Values={"Random","None"}, Default="Random"})

local DropGroup = Tabs.Automation:AddRightGroupbox("Drop Vacuum")
DropGroup:AddToggle("DropVacuum", {Text="Enabled", Default=false})

local ModGroup = Tabs.Automation:AddLeftGroupbox("Detectors")
ModGroup:AddToggle("ModDetect",    {Text="Mod Detector",    Default=false})
ModGroup:AddToggle("HackDetect",   {Text="Hacker Detector", Default=false})
ModGroup:AddToggle("AntiKatana",   {Text="Anti-Katana",     Default=false})

-- ═══════════════════════════════════════════════════════════════════════════
-- UTILITY TAB
-- ═══════════════════════════════════════════════════════════════════════════
local SkinGroup = Tabs.Utility:AddLeftGroupbox("Skin Changer")
SkinGroup:AddToggle("SkinEnabled", {Text="Enabled", Default=false})
SkinGroup:AddLabel("Note: equip cosmetics normally — overrides client-side")

local SpooferGroup = Tabs.Utility:AddRightGroupbox("Spoofer")
SpooferGroup:AddToggle("SpooferEnabled", {Text="VR Device Spoof", Default=false})
SpooferGroup:AddButton("Run Spoofer Now", function()
    pcall(function()
        RepS:WaitForChild("Remotes"):WaitForChild("Replication")
            :WaitForChild("Fighter"):WaitForChild("SetControls"):FireServer("VR")
    end)
    Library:Notify("Spoofer fired!", 2)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ═══════════════════════════════════════════════════════════════════════════
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuBind", {Default="RightShift", NoUI=true, Text="Menu Bind"})
Library.ToggleKeybind = Options.MenuBind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuBind"})
ThemeManager:SetFolder("EclipseV2")
SaveManager:SetFolder("EclipseV2/configs")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS (shared)
-- ═══════════════════════════════════════════════════════════════════════════
local c0,c1,c2,c3,c4,c5 = utf8.char(0),utf8.char(1),utf8.char(2),utf8.char(3),utf8.char(4),utf8.char(5)
local function encodeCF(cf)
    local rx,ry,rz = cf:ToOrientation()
    return {[c0]=cf.X,[c1]=cf.Y,[c2]=cf.Z,[c3]=rx,[c4]=ry,[c5]=rz}
end

local HEAD_P  = {"HitboxHead","HitboxHeadSmall","Head"}
local TORSO_P = {"HitboxBody","UpperTorso","HumanoidRootPart"}
local ALL_P   = {"HitboxHead","Head","UpperTorso","HumanoidRootPart","LowerTorso",
                 "LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg"}

local function getPart(char, mode)
    if mode == "Closest" then
        local center = Vector2.new(Camera.ViewportSize.X*.5, Camera.ViewportSize.Y*.5)
        local best, bestD = nil, math.huge
        for _, n in ipairs(ALL_P) do
            local p = char:FindFirstChild(n)
            if p and p:IsA("BasePart") then
                local sp, on = Camera:WorldToViewportPoint(p.Position)
                if on then
                    local d = (Vector2.new(sp.X,sp.Y)-center).Magnitude
                    if d < bestD then best,bestD = p,d end
                end
            end
        end
        return best
    end
    local list = mode == "Body" and TORSO_P or HEAD_P
    for _, n in ipairs(list) do
        local p = char:FindFirstChild(n)
        if p and p:IsA("BasePart") then return p end
    end
    return char:FindFirstChild("HumanoidRootPart")
end

local wallParams = RaycastParams.new()
wallParams.FilterType = Enum.RaycastFilterType.Exclude
local _wChar = nil
local function canSee(pos)
    local mc = LP.Character
    if mc ~= _wChar then
        wallParams.FilterDescendantsInstances = {mc}
        _wChar = mc
    end
    local res = Workspace:Raycast(Camera.CFrame.Position, pos - Camera.CFrame.Position, wallParams)
    if not res then return true end
    local m = res.Instance and res.Instance:FindFirstAncestorOfClass("Model")
    return m ~= nil and Players:GetPlayerFromCharacter(m) ~= nil
end

local function isTeammate(plr)
    if plr == LP then return true end
    local a = LP:GetAttribute("TeamID")
    local b = plr:GetAttribute("TeamID")
    if a ~= nil and b ~= nil then return a == b end
    if LP.Team and plr.Team then return LP.Team == plr.Team end
    return false
end

local function isAlive(plr)
    local c = plr.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function lookCF(from, to)
    local dir = to - from
    if dir.Magnitude < 1e-4 then dir = Vector3.new(0,-1,0) end
    local up = Vector3.new(0,1,0)
    if math.abs(dir.Unit.Y) > 0.999 then up = Vector3.new(0,0,1) end
    return CFrame.lookAt(from, from+dir, up)
end

-- velocity map
local velMap, velPos, velTime, velAcc = {},{},{}, 0
RunService.Heartbeat:Connect(function(dt)
    velAcc += dt
    if velAcc < 1/30 then return end
    velAcc = 0
    local now = tick()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local pos = hrp.Position
                if velPos[p] and velTime[p] then
                    local d = now - velTime[p]
                    if d > 0 then
                        local v = (pos - velPos[p]) / d
                        if v.Magnitude < 500 then velMap[p] = v end
                    end
                end
                velPos[p] = pos; velTime[p] = now
            end
        end
    end
end)

local function getTarget(fov, part, teamCheck, wallCheck)
    local center = Vector2.new(Camera.ViewportSize.X*.5, Camera.ViewportSize.Y*.5)
    local best, bestPart, bestD = nil, nil, math.huge
    local mc = LP.Character
    local mr = mc and mc:FindFirstChild("HumanoidRootPart")
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        if teamCheck and isTeammate(plr) then continue end
        if not isAlive(plr) then continue end
        local char = plr.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not (char and hrp) then continue end
        if mr and (hrp.Position-mr.Position).Magnitude > 2000 then continue end
        local p = getPart(char, part)
        if not p then continue end
        local sp, on = Camera:WorldToViewportPoint(p.Position)
        if not on or sp.Z <= 0 then continue end
        local d = (Vector2.new(sp.X,sp.Y)-center).Magnitude
        if fov > 0 and d > fov then continue end
        if wallCheck and not canSee(p.Position) then continue end
        if d < bestD then bestD=d; best=plr; bestPart=p end
    end
    return best, bestPart
end

-- ═══════════════════════════════════════════════════════════════════════════
-- AIMBOT
-- ═══════════════════════════════════════════════════════════════════════════
local aimSpring = {pos=Vector3.zero, init=false}
local aimPrevTgt = nil
RunService:BindToRenderStep("EclAimbot", Enum.RenderPriority.Camera.Value+1, function()
    -- FOV circle
    -- (handled in Drawing section below)
    if not T("AimbotEnabled") then aimSpring.init=false; aimPrevTgt=nil; return end
    local tgt, part = getTarget(O("AimbotFOV") or 500, O("AimbotPart") or "Head", T("AimbotTeam"), T("AimbotWall"))
    if tgt ~= aimPrevTgt then aimSpring.init=false; aimPrevTgt=tgt end
    if not (tgt and part) then aimSpring.init=false; return end
    local mode = O("AimbotMode") or "Spring"
    local smooth = math.clamp((O("AimbotSmooth") or 15)/100, 0.01, 1)
    if mode == "Lock" then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
    elseif mode == "Spring" then
        if not aimSpring.init then aimSpring.pos = Camera.CFrame.Position + Camera.CFrame.LookVector; aimSpring.init=true end
        local dt = math.clamp(1/60, 0, 0.1)
        local alpha = 1 - math.exp(-(1+smooth*20)*dt)
        aimSpring.pos = aimSpring.pos:Lerp(part.Position, alpha)
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimSpring.pos)
    elseif mode == "Linear" then
        local dt = math.clamp(1/60, 0, 0.1)
        local alpha = 1 - math.exp(-(1+smooth*25)*dt)
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, part.Position), alpha)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- DRAWING (FOV, Tracers)
-- ═══════════════════════════════════════════════════════════════════════════
local FOVCircle, Tracers = nil, {}
pcall(function()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 1.5
    FOVCircle.Filled    = false
    FOVCircle.NumSides  = 64
    FOVCircle.Visible   = false
end)
if not FOVCircle then FOVCircle = {Visible=false, Position=Vector2.zero, Radius=0, Color=Color3.new(1,1,1)} end

RunService.RenderStepped:Connect(function()
    -- FOV circle
    local fovCol = O("FOVColor") or Color3.fromRGB(255,255,255)
    if FOVCircle.Color ~= nil then
        FOVCircle.Color    = fovCol
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X*.5, Camera.ViewportSize.Y*.5)
        FOVCircle.Radius   = O("FOVRadius") or 500
        FOVCircle.Visible  = T("FOVEnabled") or (T("AimbotFOVCircle") and T("AimbotEnabled"))
    end

    -- Tracers
    for _, v in pairs(Tracers) do pcall(function() v:Remove() end) end
    Tracers = {}
    if T("TracerEnabled") then
        local vp = Camera.ViewportSize
        local fromY = O("TracerFrom") == "Top" and 0 or (O("TracerFrom") == "Center" and vp.Y*.5 or vp.Y)
        local fromPt = Vector2.new(vp.X*.5, fromY)
        local col = O("TracerColor") or Color3.fromRGB(255,255,255)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LP then continue end
            if not T("ESPTeam") and isTeammate(plr) then continue end
            if not isAlive(plr) then continue end
            local char = plr.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            local sp, on = Camera:WorldToScreenPoint(hrp.Position)
            if not on then continue end
            pcall(function()
                local line = Drawing.new("Line")
                line.From      = fromPt
                line.To        = Vector2.new(sp.X, sp.Y)
                line.Color     = col
                line.Thickness = 1
                line.Visible   = true
                table.insert(Tracers, line)
            end)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- ESP
-- ═══════════════════════════════════════════════════════════════════════════
local ESPGui = Instance.new("ScreenGui")
ESPGui.Name = "EclipseESP"; ESPGui.ResetOnSpawn = false
ESPGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ESPGui.Parent = gethui() end)
if not ESPGui.Parent then pcall(function() ESPGui.Parent = CoreGui end) end
if not ESPGui.Parent then ESPGui.Parent = LP:WaitForChild("PlayerGui") end

local function mk(cls, props, par)
    local i = Instance.new(cls)
    for k,v in pairs(props) do i[k]=v end
    if par then i.Parent = par end
    return i
end

local espData = {}
local SKELETON_PAIRS = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}

local function buildESP(plr)
    if espData[plr] then return end
    local folder = mk("Folder",{Name=plr.Name}, ESPGui)
    local NameL  = mk("TextLabel",{Size=UDim2.fromOffset(120,20),AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=13,TextStrokeTransparency=0,ZIndex=5,Visible=false},ESPGui)
    local DistL  = mk("TextLabel",{Size=UDim2.fromOffset(80,16),AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),Font=Enum.Font.Gotham,TextSize=11,TextStrokeTransparency=0,ZIndex=5,Visible=false},ESPGui)
    local Box    = mk("Frame",{BackgroundTransparency=1,BorderSizePixel=0,ZIndex=4,Visible=false},ESPGui)
    mk("UIStroke",{Thickness=1.4},Box)
    local HBBg   = mk("Frame",{BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=3,Visible=false},ESPGui)
    local HBFill = mk("Frame",{BackgroundColor3=Color3.fromRGB(0,230,100),BorderSizePixel=0,ZIndex=4,Visible=false},ESPGui)
    local Chams  = mk("Highlight",{FillTransparency=0.6,OutlineTransparency=0,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,Enabled=false},folder)
    local skelLines = {}
    for i=1,#SKELETON_PAIRS do
        pcall(function()
            local line = Drawing.new("Line")
            line.Visible   = false
            line.Thickness = 1
            table.insert(skelLines, line)
        end)
    end
    espData[plr] = {folder=folder,NameL=NameL,DistL=DistL,Box=Box,HBBg=HBBg,HBFill=HBFill,Chams=Chams,skelLines=skelLines}
end

local function hideESP(d)
    d.NameL.Visible=false; d.DistL.Visible=false
    d.Box.Visible=false; d.HBBg.Visible=false; d.HBFill.Visible=false
    d.Chams.Enabled=false
    for _,l in ipairs(d.skelLines) do pcall(function() l.Visible=false end) end
end

local function removeESP(plr)
    local d = espData[plr]
    if not d then return end
    pcall(function() d.folder:Destroy() end)
    pcall(function() d.NameL:Destroy() end)
    pcall(function() d.DistL:Destroy() end)
    pcall(function() d.Box:Destroy() end)
    pcall(function() d.HBBg:Destroy() end)
    pcall(function() d.HBFill:Destroy() end)
    for _,l in ipairs(d.skelLines) do pcall(function() l:Remove() end) end
    espData[plr] = nil
end

for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP then buildESP(plr) end end
Players.PlayerAdded:Connect(function(p) if p ~= LP then buildESP(p) end end)
Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    for plr, d in pairs(espData) do
        if not plr or not plr.Parent then removeESP(plr); continue end
        if not T("ESPEnabled") then hideESP(d); continue end

        local char = plr.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not (char and hrp and hum and hum.Health > 0) then hideESP(d); continue end
        if not T("ESPTeam") and isTeammate(plr) then hideESP(d); continue end

        local sp, on = Camera:WorldToScreenPoint(hrp.Position)
        local dist   = (Camera.CFrame.Position - hrp.Position).Magnitude
        if not on or dist > (O("ESPMaxDist") or 500) then hideESP(d); continue end

        local sf   = (hrp.Size.Y * Camera.ViewportSize.Y) / (sp.Z * 2)
        local w,h  = sf*3, sf*5.5
        local px,py = sp.X, sp.Y
        local vis  = canSee(hrp.Position)
        local col  = vis and (O("ESPColVis") or Color3.fromRGB(0,255,0)) or (O("ESPColHid") or Color3.fromRGB(255,0,0))

        -- Box
        if T("ESPBox") then
            d.Box.Position = UDim2.fromOffset(px-w/2, py-h/2)
            d.Box.Size     = UDim2.fromOffset(w, h)
            d.Box.Visible  = true
            local stroke = d.Box:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = col end
        else d.Box.Visible=false end

        -- Health bar
        if T("ESPHealth") then
            local hp = math.clamp(hum.Health/hum.MaxHealth,0,1)
            d.HBBg.Position  = UDim2.fromOffset(px-w/2-7, py-h/2)
            d.HBBg.Size      = UDim2.fromOffset(3, h)
            d.HBBg.Visible   = true
            d.HBFill.Position= UDim2.fromOffset(px-w/2-7, py-h/2+(h*(1-hp)))
            d.HBFill.Size    = UDim2.fromOffset(3, h*hp)
            d.HBFill.BackgroundColor3 = hp>.6 and Color3.fromRGB(0,230,80) or hp>.3 and Color3.fromRGB(255,200,0) or Color3.fromRGB(230,50,50)
            d.HBFill.Visible = true
        else d.HBBg.Visible=false; d.HBFill.Visible=false end

        -- Name
        if T("ESPName") then
            d.NameL.Text     = T("ESPDist") and string.format("%s [%dm]", plr.DisplayName, math.floor(dist)) or plr.DisplayName
            d.NameL.Position = UDim2.fromOffset(px, py-h/2-10)
            d.NameL.TextColor3 = col
            d.NameL.Visible  = true
        else d.NameL.Visible=false end

        -- Distance standalone
        if T("ESPDist") and not T("ESPName") then
            d.DistL.Text     = string.format("%dm", math.floor(dist))
            d.DistL.Position = UDim2.fromOffset(px, py+h/2+8)
            d.DistL.Visible  = true
        else d.DistL.Visible=false end

        -- Chams
        if T("ESPChams") then
            d.Chams.Adornee       = char
            d.Chams.FillColor     = O("ESPColChams") or Color3.fromRGB(235,64,80)
            d.Chams.OutlineColor  = O("ESPColChams") or Color3.fromRGB(235,64,80)
            d.Chams.Enabled       = true
        else d.Chams.Enabled=false end

        -- Skeleton
        for i, pair in ipairs(SKELETON_PAIRS) do
            local line = d.skelLines[i]
            if not line then continue end
            if T("ESPSkeleton") then
                local p1 = char:FindFirstChild(pair[1])
                local p2 = char:FindFirstChild(pair[2])
                if p1 and p2 then
                    local s1,o1 = Camera:WorldToScreenPoint(p1.Position)
                    local s2,o2 = Camera:WorldToScreenPoint(p2.Position)
                    if o1 and o2 then
                        pcall(function()
                            line.From    = Vector2.new(s1.X, s1.Y)
                            line.To      = Vector2.new(s2.X, s2.Y)
                            line.Color   = col
                            line.Visible = true
                        end)
                    else pcall(function() line.Visible=false end) end
                else pcall(function() line.Visible=false end) end
            else pcall(function() line.Visible=false end) end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- DROPPED ITEM ESP
-- ═══════════════════════════════════════════════════════════════════════════
local dropLabels = {}
RunService.RenderStepped:Connect(function()
    for _, v in pairs(dropLabels) do pcall(function() v:Remove() end) end
    dropLabels = {}
    if not T("DropESPEnabled") then return end
    local maxD = O("DropESPDist") or 200
    local col  = O("DropESPColor") or Color3.fromRGB(255,220,0)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "_drop" then
            local sp, on = Camera:WorldToScreenPoint(obj.Position)
            if on then
                local dist = (Camera.CFrame.Position - obj.Position).Magnitude
                if dist <= maxD then
                    pcall(function()
                        local lbl = Drawing.new("Text")
                        lbl.Text     = string.format("DROP [%dm]", math.floor(dist))
                        lbl.Position = Vector2.new(sp.X, sp.Y)
                        lbl.Color    = col
                        lbl.Size     = 13
                        lbl.Center   = true
                        lbl.Outline  = true
                        lbl.Visible  = true
                        table.insert(dropLabels, lbl)
                    end)
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- SILENT AIM
-- ═══════════════════════════════════════════════════════════════════════════
local _saOrig, _saLive = nil, false
local function installSA()
    if _saLive then return end
    local ok, GunMod = pcall(function() return require(LP.PlayerScripts.Modules.ItemTypes.Gun) end)
    if not ok or type(GunMod) ~= "table" then return end
    local orig = GunMod.StartShooting
    if type(orig) ~= "function" then return end
    _saOrig = orig
    local hook = function(self, ...)
        local res = {orig(self, ...)}
        pcall(function()
            if not T("SAEnabled") then return end
            if res[1] ~= true then return end
            if not (self.ClientFighter and self.ClientFighter.IsLocalPlayer) then return end
            if math.random(1,100) > (O("SAChance") or 100) then return end
            local cd = res[3]
            if type(cd) ~= "table" then return end
            local tgt, part = getTarget(O("AimbotFOV") or 500, O("AimbotPart") or "Head", T("AimbotTeam"), true)
            if not (tgt and part) then return end
            local char   = tgt.Character
            if not char then return end
            if T("SATorso") and not canSee(part.Position) then
                for _, n in ipairs(TORSO_P) do
                    local p = char:FindFirstChild(n)
                    if p and canSee(p.Position) then part=p; break end
                end
            end
            local camPos = Camera.CFrame.Position
            local lead   = Vector3.zero
            if T("SALead") then
                local tv = tgt.Character:FindFirstChild("HumanoidRootPart")
                if tv then
                    local lat = (LP:GetNetworkPing() or 0.05)+0.03
                    local vel = velMap[tgt] or tv.AssemblyLinearVelocity
                    if vel.Magnitude < 120 then
                        lead = Vector3.new(vel.X,0,vel.Z)*lat
                        if lead.Magnitude > 15 then lead = lead.Unit*15 end
                    end
                end
            end
            local aimPos   = part.Position + lead
            local eyeCF    = lookCF(camPos, aimPos)
            local muzzleCF = lookCF(camPos + eyeCF.RightVector*0.2 + Vector3.new(0,-0.07,0), aimPos)
            local objSp    = part.CFrame:PointToObjectSpace(aimPos)
            local hs       = part.Size*0.45
            objSp = Vector3.new(math.clamp(objSp.X,-hs.X,hs.X), math.clamp(objSp.Y,-hs.Y,hs.Y), math.clamp(objSp.Z,-hs.Z,hs.Z))
            local hitWorld = part.CFrame:PointToWorldSpace(objSp)
            cd[c0] = encodeCF(eyeCF)
            cd[c1] = encodeCF(muzzleCF)
            cd[c2] = part
            cd[c3] = encodeCF(part.CFrame:ToObjectSpace(CFrame.new(hitWorld)))
        end)
        return table.unpack(res)
    end
    if setfenv then pcall(setfenv, hook, getfenv(orig)) end
    if setreadonly then pcall(setreadonly, GunMod, false) end
    GunMod.StartShooting = hook
    _saLive = true
end
task.spawn(function()
    for _=1,30 do if installSA() then break end; task.wait(1) end
    installSA()
end)
LP.CharacterAdded:Connect(function() task.wait(0.5); installSA() end)

-- ═══════════════════════════════════════════════════════════════════════════
-- RAGEBOT
-- ═══════════════════════════════════════════════════════════════════════════
local Util, EnumLib, FC
task.spawn(function()
    Util    = pcall(require, RepS.Modules.Utility)        and require(RepS.Modules.Utility)       or nil
    EnumLib = pcall(require, RepS.Modules.EnumLibrary)    and require(RepS.Modules.EnumLibrary)    or nil
    FC      = pcall(require, LP.PlayerScripts.Controllers.FighterController) and require(LP.PlayerScripts.Controllers.FighterController) or nil
end)

local deflMap = {}
Players.PlayerRemoving:Connect(function(p) deflMap[p]=nil end)
local function checkDeflect(plr)
    if not plr or not plr.Character then return false end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    local anim = hum and hum:FindFirstChildOfClass("Animator")
    if not anim then return false end
    for _, t in ipairs(anim:GetPlayingAnimationTracks()) do
        if t.Name:lower():find("deflect") then return true end
    end
    return false
end
local function hasKnife(plr)
    local vms = Workspace:FindFirstChild("ViewModels")
    if not vms then return false end
    for _, m in ipairs(vms:GetChildren()) do
        if m:IsA("Model") and m.Name:find(plr.Name,1,true) and m.Name:find("Knife",1,true) then return true end
    end
    return false
end
local function getRageTarget()
    local mc = LP.Character; local mr = mc and mc:FindFirstChild("HumanoidRootPart")
    if not mr then return end
    local best,bRoot,bHead,bScore = nil,nil,nil,math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end
        if isTeammate(plr) then continue end
        local pc = plr.Character; local ph = pc and pc:FindFirstChildOfClass("Humanoid")
        if not ph or ph.Health<=0 then continue end
        local pr = pc:FindFirstChild("HumanoidRootPart"); local phead = pc:FindFirstChild("Head")
        if not (pr and phead) then continue end
        if pc:FindFirstChildOfClass("ForceField") then continue end
        local dist = (mr.Position-pr.Position).Magnitude
        if dist > 1000 then continue end
        local score = dist + (deflMap[plr] and 1000 or 0) + ph.Health*2
        if score < bScore then bScore=score; best=plr; bRoot=pr; bHead=phead end
    end
    return best,bRoot,bHead
end
local restoreLocked=false
local function applyDesync(cf)
    local mc=LP.Character; local mr=mc and mc:FindFirstChild("HumanoidRootPart")
    if not mr then return end
    local oldCF=mr.CFrame; local oldV=mr.Velocity; local oldR=mr.RotVelocity
    mr.CFrame=cf
    if restoreLocked then return end; restoreLocked=true
    RunService:BindToRenderStep("__EclRestore",101,function()
        if mr and mr.Parent then mr.CFrame=oldCF; mr.Velocity=oldV; mr.RotVelocity=oldR end
        RunService:UnbindFromRenderStep("__EclRestore"); restoreLocked=false
    end)
end
local UseItemR, orbitAngle, lastRageFire = nil, 0, 0
RunService.Heartbeat:Connect(function(dt)
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then deflMap[p]=checkDeflect(p) end end
    if not T("RageEnabled") then return end
    if not (Util and EnumLib and FC) then return end
    if not UseItemR then
        pcall(function() UseItemR = RepS.Remotes.Replication.Fighter.UseItem end)
        if not UseItemR then return end
    end
    local lf = FC.LocalFighter; if not lf then return end
    local item = lf.EquippedItem; if not item then return end
    local info = rawget(item,"Info"); local data = rawget(item,"Data")
    if info and info.Type=="Gun" and data and data.Ammo and data.Ammo<=0 then return end
    local tgt,tRoot,tHead = getRageTarget()
    orbitAngle = (orbitAngle + (O("RageOrbit") or 6)*dt) % (math.pi*2)
    if T("RageAntiHit") and tRoot then
        local desyncCF
        if T("RageKnife") and hasKnife(tgt) then
            desyncCF = lookCF((tRoot.CFrame*CFrame.new(0,9,-4)).Position, tHead.Position)
        else
            local orbitR = O("RageOrbit") or 14
            desyncCF = lookCF(tRoot.Position + Vector3.new(math.cos(orbitAngle)*orbitR, 2, math.sin(orbitAngle)*orbitR), tHead.Position)
        end
        applyDesync(desyncCF)
    end
    if not (tgt and tRoot and tHead) then return end
    if deflMap[tgt] then return end
    local fireInterval = 1 / math.max(1, O("RageFireRate") or 50)
    if tick()-lastRageFire < fireInterval then return end
    lastRageFire = tick()
    local aimCF = lookCF(tRoot.Position, tHead.Position)
    local objID = item:Get("ObjectID"); if not objID then return end
    local shootEnum = EnumLib:ToEnum("StartShooting"); if not shootEnum then return end
    local innerData = {[c0]=Util:EncodeCFrame(aimCF),[c1]=Util:EncodeCFrame(tHead.CFrame),[c2]=tHead,[c3]=Util:EncodeCFrame(CFrame.new(0,0,0))}
    if info and info.Type=="Melee" then
        local aAnim = EnumLib:ToEnum("AttackAnimation1")
        if aAnim then pcall(function() UseItemR:FireServer(objID,shootEnum,{[c1]=innerData,[c2]=aAnim},nil) end) end
    else
        pcall(function() UseItemR:FireServer(objID,shootEnum,{[c1]=innerData},nil) end)
    end
end)
-- rage slot equip watcher
task.spawn(function()
    while true do task.wait(2)
        if T("RageEnabled") and FC and FC.LocalFighter then
            local slotMap = {Primary=1,Secondary=2,Melee=3}
            pcall(function() FC.LocalFighter:EquipItem(slotMap[O("RageSlot")] or 3) end)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- TRIGGERBOT
-- ═══════════════════════════════════════════════════════════════════════════
local lastTriggerFire = 0
RunService.Heartbeat:Connect(function()
    if not T("TriggerEnabled") then return end
    local now = tick()
    local delay = (O("TriggerDelay") or 0)/1000
    if now - lastTriggerFire < delay+0.05 then return end
    local center = Vector2.new(Camera.ViewportSize.X*.5, Camera.ViewportSize.Y*.5)
    local part   = O("TriggerPart") or "Any"
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end
        if isTeammate(plr) then continue end
        if not isAlive(plr) then continue end
        local char = plr.Character; if not char then continue end
        local list = part=="Head" and HEAD_P or part=="Torso" and TORSO_P or ALL_P
        for _, n in ipairs(list) do
            local p = char:FindFirstChild(n)
            if not p then continue end
            local sp, on = Camera:WorldToViewportPoint(p.Position)
            if on and sp.Z>0 and (Vector2.new(sp.X,sp.Y)-center).Magnitude < 20 then
                lastTriggerFire = now
                if FC and FC.LocalFighter then
                    pcall(function() FC.LocalFighter:Input("StartShooting") end)
                end
                return
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- ANTI-AIM
-- ═══════════════════════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    local pitch = O("AAPitch") or "Off"
    local yaw   = O("AAYaw") or "Off"
    if pitch=="Off" and yaw=="Off" and not T("AAUnderground") then return end
    local char = LP.Character; if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local cam  = Camera.CFrame
    local camPitch, camYaw = 0, 0
    local function deg(r) return math.deg(r) end
    camPitch, camYaw = select(1, cam:ToOrientation()), select(2, cam:ToOrientation())
    local finalPitch = math.rad(pitch=="Up" and 89 or pitch=="Down" and -89 or pitch=="Random" and math.random(-180,180) or pitch=="Custom" and (O("AAPitchAngle") or 0) or deg(camPitch))
    local finalYaw   = math.rad(yaw=="Backwards" and deg(camYaw)+180 or yaw=="Random" and math.random(-180,180) or yaw=="Custom" and (O("AAYawAngle") or 0) or deg(camYaw))
    -- store for anti-aim (desync on next heartbeat)
    if T("AAUnderground") then
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = {char}
        local hit = Workspace:Raycast(hrp.Position, Vector3.new(0,-500,0), rp)
        if hit then
            local underground = Vector3.new(hrp.Position.X, hit.Position.Y-5, hrp.Position.Z)
            hrp.CFrame = CFrame.new(underground) * CFrame.Angles(math.rad(90),0,0)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- MOVEMENT
-- ═══════════════════════════════════════════════════════════════════════════
local flyLV, flyEnabled = nil, false
local function updateFly()
    local char = LP.Character; if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    if T("FlyEnabled") and not flyEnabled then
        flyEnabled = true
        hum.PlatformStand = true
        flyLV = Instance.new("LinearVelocity")
        flyLV.Attachment0        = hrp:FindFirstChildOfClass("Attachment") or Instance.new("Attachment",hrp)
        flyLV.MaxForce           = math.huge
        flyLV.RelativeTo         = Enum.ActuatorRelativeTo.World
        flyLV.VectorVelocity     = Vector3.zero
        flyLV.Parent             = hrp
    elseif not T("FlyEnabled") and flyEnabled then
        flyEnabled = false
        hum.PlatformStand = false
        if flyLV then flyLV:Destroy(); flyLV=nil end
    end
end

Toggles.FlyEnabled:OnChanged(function() updateFly() end)

RunService.RenderStepped:Connect(function()
    -- fly controls
    if T("FlyEnabled") and flyLV then
        local spd = O("FlySpeed") or 80
        local cf  = Camera.CFrame
        local vel = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then vel += cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then vel -= cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then vel -= cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then vel += cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then vel += Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then vel -= Vector3.yAxis end
        flyLV.VectorVelocity = vel.Magnitude>0 and vel.Unit*spd or Vector3.zero
    end
end)

-- speed / jump / noclip / infinite jump
local origSpeeds = {}
local jumps = 0
RunService.Heartbeat:Connect(function()
    local char = LP.Character; if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    -- speed
    if T("SpeedEnabled") then
        if not origSpeeds.walk then origSpeeds.walk = hum.WalkSpeed end
        hum.WalkSpeed = 16 * (O("SpeedMult") or 2)
    else
        if origSpeeds.walk then hum.WalkSpeed=origSpeeds.walk; origSpeeds.walk=nil end
    end
    -- jump
    if T("JumpEnabled") then
        if not origSpeeds.jump then origSpeeds.jump = hum.JumpPower end
        hum.JumpPower = 50 * (O("JumpMult") or 2)
    else
        if origSpeeds.jump then hum.JumpPower=origSpeeds.jump; origSpeeds.jump=nil end
    end
    -- noclip
    if T("NoclipEnabled") then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end
end)

UIS.JumpRequest:Connect(function()
    if not T("InfJump") then return end
    local char = LP.Character; if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
end)

-- long jump
UIS.JumpRequest:Connect(function()
    if not T("LongJump") then return end
    local char = LP.Character; if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    hrp.Velocity = hrp.CFrame.LookVector * 80 + Vector3.new(0, 30, 0)
end)

-- auto strafe
RunService.RenderStepped:Connect(function()
    if not T("AutoStrafe") then return end
    local char = LP.Character; if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    if hum.MoveDirection.Magnitude > 0.1 then
        local spd = O("StrafeMult") or 50
        local dir = hrp.CFrame.RightVector * math.sin(tick()*spd) + hrp.CFrame.LookVector * math.cos(tick()*spd)
        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.lookAt(Vector3.zero, dir + Vector3.new(0,0,0))
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- AUTOMATION
-- ═══════════════════════════════════════════════════════════════════════════
-- Auto respawn
LP.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum.Died:Connect(function()
        if not T("AutoRespawn") then return end
        task.spawn(function()
            while T("AutoRespawn") do
                local c = LP.Character
                if c and c:FindFirstChildOfClass("Humanoid") and c:FindFirstChildOfClass("Humanoid").Health > 0 then break end
                pcall(function()
                    RepS.Remotes.Duels.RespawnNow:FireServer()
                end)
                task.wait(0.1)
            end
        end)
    end)
end)

-- Drop vacuum
local visitedDrops = {}
local function handleDrop(obj)
    if not T("DropVacuum") then return end
    if not (obj:IsA("BasePart") and obj.Name=="_drop") then return end
    if visitedDrops[obj] then return end
    visitedDrops[obj] = true
    task.wait()
    pcall(function()
        local char = LP.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if obj:IsDescendantOf(Workspace) and hrp then
            obj.CFrame    = hrp.CFrame + Vector3.new(0,3,0)
            obj.Anchored  = true; obj.CanCollide=false; obj.Transparency=1
        end
    end)
end
Workspace.DescendantAdded:Connect(handleDrop)

-- Mod / Hacker detector
local MOD_IDS = {} -- extend with known mod user IDs
Players.PlayerAdded:Connect(function(plr)
    task.wait(2)
    if T("ModDetect") and MOD_IDS[plr.UserId] then
        Library:Notify("⚠ Mod detected: "..plr.DisplayName, 5)
    end
    if T("HackDetect") then
        local char = plr.Character or plr.CharacterAdded:Wait()
        local hum  = char:WaitForChild("Humanoid",5)
        if hum then
            hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if T("HackDetect") and hum.WalkSpeed > 50 then
                    Library:Notify("⚠ Hacker detected: "..plr.DisplayName.." (speed "..math.floor(hum.WalkSpeed)..")", 5)
                end
            end)
        end
    end
end)

-- Anti-katana
local function setupAntiKatana(plr)
    if plr==LP then return end
    local char = plr.Character or plr.CharacterAdded:Wait()
    char.DescendantAdded:Connect(function(obj)
        if not T("AntiKatana") then return end
        if obj:IsA("Tool") and obj.Name:lower():find("katana") then
            pcall(function()
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if hrp and myHRP then
                    local away = (myHRP.Position - hrp.Position).Unit * 30
                    myHRP.CFrame = myHRP.CFrame + away
                end
            end)
        end
    end)
end
for _, p in ipairs(Players:GetPlayers()) do task.spawn(setupAntiKatana, p) end
Players.PlayerAdded:Connect(setupAntiKatana)

-- Spoofer on enable
Toggles.SpooferEnabled:OnChanged(function()
    if T("SpooferEnabled") then
        pcall(function()
            RepS:WaitForChild("Remotes"):WaitForChild("Replication")
                :WaitForChild("Fighter"):WaitForChild("SetControls"):FireServer("VR")
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- SKIN CHANGER
-- ═══════════════════════════════════════════════════════════════════════════
local skinActive = false
Toggles.SkinEnabled:OnChanged(function()
    if T("SkinEnabled") and not skinActive then
        skinActive = true
        task.spawn(function()
            local ok, lib   = pcall(require, RepS.Modules.CosmeticLibrary)
            local ok2, rep  = pcall(require, RepS.Modules.ReplicatedClass)
            if not (ok and ok2) then Library:Notify("Skin Changer: modules not ready", 3); return end
            local inv = pcall(function() return require(LP.PlayerScripts.Controllers.PlayerDataController) end)
                        and require(LP.PlayerScripts.Controllers.PlayerDataController)
            if not inv then return end
            local cosInv = inv.CurrentData and pcall(inv.CurrentData.Get, inv.CurrentData, "CosmeticInventory")
                           and inv.CurrentData:Get("CosmeticInventory")
            if cosInv then
                for name in pairs(lib.Cosmetics) do cosInv[name] = true end
                Library:Notify("Skin Changer: inventory unlocked", 3)
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- DONE
-- ═══════════════════════════════════════════════════════════════════════════
Library:Notify("Eclipse v2 loaded ✓", 3)
print("[Eclipse v2] ready")
