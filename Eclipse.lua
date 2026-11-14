--[[
    Eclipse
    Mobile-Only | Rivals
    Combat · Visuals · Movement · Automation · Settings
    UI: LinoriaLib | Features: Aimbot · Silent Aim · Ragebot · Anti-Aim · ESP · SkinChanger · Spoofer
]]

-- ── Spoofer (VR device, fires immediately) ───────────────────────────────────
pcall(function()
    game:GetService("ReplicatedStorage")
        :WaitForChild("Remotes")
        :WaitForChild("Replication")
        :WaitForChild("Fighter")
        :WaitForChild("SetControls")
        :FireServer("VR")
end)

-- ── Unload previous copy ─────────────────────────────────────────────────────
if getgenv then
    for _, key in ipairs({"__Eclipse", "__Graviton9v2", "__Graviton9v1"}) do
        if getgenv()[key] then pcall(getgenv()[key].Destroy) getgenv()[key] = nil end
    end
end

-- ── Core services ─────────────────────────────────────────────────────────────
local cloneref     = cloneref or function(o) return o end
local Players      = cloneref(game:GetService("Players"))
local RunService   = cloneref(game:GetService("RunService"))
local UIS          = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local Lighting     = cloneref(game:GetService("Lighting"))
local RepS         = cloneref(game:GetService("ReplicatedStorage"))
local Workspace    = cloneref(game:GetService("Workspace"))
local CoreGui      = game:GetService("CoreGui")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if Workspace.CurrentCamera then Camera = Workspace.CurrentCamera end
end)

-- ── LinoriaLib UI ─────────────────────────────────────────────────────────────
local repo          = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/"
local Library       = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager  = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager   = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.IsMobile                = true
Library.ShowCustomCursor        = false
Library.ShowToggleFrameInKeybinds = true

Library.MainColor       = Color3.fromRGB(18, 18, 20)
Library.BackgroundColor = Color3.fromRGB(10, 10, 12)
Library.AccentColor     = Color3.fromRGB(235, 64, 80)
Library.OutlineColor    = Color3.fromRGB(35, 35, 40)
Library.FontColor       = Color3.fromRGB(255, 255, 255)

local Window = Library:CreateWindow({
    Title           = "Eclipse",
    Center          = true,
    AutoShow        = true,
    TabPadding      = 8,
    MenuFadeTime    = 0.2,
    NotifySide      = "Right",
    Resizable       = true,
    UnlockMouseWhileOpen = true,
})

local Tabs = {
    Combat     = Window:AddTab("Combat"),
    Visuals    = Window:AddTab("Visuals"),
    Movement   = Window:AddTab("Movement"),
    Automation = Window:AddTab("Automation"),
    Settings   = Window:AddTab("Settings"),
}

local function T(n) local t = Toggles[n]; return t and t.Value or false end
local function O(n) local o = Options[n]; return o and o.Value end

-- ── COMBAT TAB UI ──────────────────────────────────────────────────────────────
local AimAssist = Tabs.Combat:AddLeftGroupbox("Aim Assist")
AimAssist:AddToggle("Aimbot",        { Text = "Aimbot",             Default = false })
    :AddKeyPicker("AimbotKey",       { Default = "None", Mode = "Toggle", SyncToggleState = true, Text = "Aimbot" })
AimAssist:AddToggle("SilentAim",     { Text = "Silent Aim",         Default = false })
    :AddKeyPicker("SilentAimKey",    { Default = "None", Mode = "Toggle", SyncToggleState = true, Text = "Silent Aim" })
AimAssist:AddSlider("Smoothness",    { Text = "Smoothness",         Default = 35,   Min = 0,   Max = 100,  Rounding = 0 })
AimAssist:AddSlider("SilentAimHitChance", { Text = "Silent Aim Hit Chance", Default = 100, Min = 0, Max = 100, Rounding = 0 })
AimAssist:AddSlider("FOVSize",       { Text = "FOV Size",           Default = 500,  Min = 20,  Max = 2000, Rounding = 0 })
AimAssist:AddDropdown("HitPart",     { Values = {"Random","Head","Torso"}, Default = "Random", Text = "Hit Part" })
AimAssist:AddToggle("ShowFOVCircle", { Text = "Show FOV Circle",    Default = false })
AimAssist:AddToggle("OnlyWhileScoped",{ Text = "Only while Scoped", Default = false })
AimAssist:AddToggle("TeamCheck",     { Text = "Team Check",         Default = true })
AimAssist:AddToggle("WallCheck",     { Text = "Wall Check",         Default = true })
AimAssist:AddDropdown("AimbotMode",  { Values = {"Lock","Linear","Spring"}, Default = "Lock", Text = "Aim Mode" })
AimAssist:AddToggle("AimbotShowFOV", { Text = "Show Aimbot FOV",    Default = false })
AimAssist:AddSlider("SilentAimJitterDeg",  { Text = "Silent Aim Jitter (deg)", Default = 1.5, Min = 0, Max = 10, Rounding = 1 })
AimAssist:AddSlider("SilentAimBodyMix",    { Text = "Body Mix %",   Default = 25,  Min = 0, Max = 100, Rounding = 0 })
AimAssist:AddSlider("SilentAimStickiness", { Text = "Stickiness",   Default = 0.05,Min = 0, Max = 1,   Rounding = 2 })
AimAssist:AddSlider("MaxDistance",   { Text = "Max Distance",       Default = 1200,Min = 100, Max = 3000, Rounding = 0 })
AimAssist:AddToggle("PredictiveLead",{ Text = "Predictive Lead",    Default = true })
AimAssist:AddSlider("LeadCap",       { Text = "Lead Cap",           Default = 15,  Min = 0, Max = 50,   Rounding = 0 })
AimAssist:AddToggle("SilentAimMultipoint",     { Text = "Multipoint",       Default = false })
AimAssist:AddSlider("SilentAimMultipointCount",{ Text = "Multipoint Count", Default = 5, Min = 1, Max = 12, Rounding = 0 })
AimAssist:AddToggle("SilentAimTorsoFallback",  { Text = "Torso Fallback",   Default = false })

local Ragebot = Tabs.Combat:AddRightGroupbox("Ragebot")
Ragebot:AddToggle("RagebotEnabled", { Text = "Enabled", Default = false })
    :AddKeyPicker("RagebotKey", { Default = "None", Mode = "Toggle", SyncToggleState = true, Text = "Ragebot" })
Ragebot:AddDropdown("RagebotWeapon",   { Values = {"Auto","Primary","Secondary","Melee"}, Default = "Auto", Text = "Weapon" })
Ragebot:AddSlider("RageFireRate",      { Text = "Fire Rate",        Default = 0.05, Min = 0.01, Max = 0.3, Rounding = 2 })
Ragebot:AddToggle("RageTeleportMode",  { Text = "Teleport Mode",    Default = false })
Ragebot:AddSlider("RageOrbitRadius",   { Text = "Orbit Distance",   Default = 5,   Min = 2,  Max = 25, Rounding = 0 })
Ragebot:AddSlider("RageOrbitSpeed",    { Text = "Orbit Speed",      Default = 15,  Min = 5,  Max = 50, Rounding = 0 })
Ragebot:AddToggle("RageAutoFire",      { Text = "Auto Fire",        Default = true })
Ragebot:AddToggle("RageAntiHit",       { Text = "Anti-Hit",         Default = true })
Ragebot:AddToggle("RageClampY",        { Text = "Clamp to Floor",   Default = true })
Ragebot:AddToggle("RageRoundCheck",    { Text = "Round State Check",Default = true })
Ragebot:AddToggle("RageWallbang",      { Text = "Wallbang",         Default = true })

local Triggerbot = Tabs.Combat:AddRightGroupbox("Triggerbot")
Triggerbot:AddToggle("TriggerbotEnabled", { Text = "Enabled", Default = false })
    :AddKeyPicker("TriggerbotKey", { Default = "None", Mode = "Toggle", SyncToggleState = true, Text = "Triggerbot" })
Triggerbot:AddSlider("TriggerReaction", { Text = "Reaction Delay (s)", Default = 0, Min = 0, Max = 1, Rounding = 2 })
Triggerbot:AddSlider("TriggerRelease",  { Text = "Release Delay (s)",  Default = 0, Min = 0, Max = 1, Rounding = 2 })
Triggerbot:AddDropdown("TriggerTarget", { Values = {"Any","Head","Torso"}, Default = "Any", Text = "Target" })
Triggerbot:AddToggle("TriggerScoped",   { Text = "Only When Scoped",  Default = false })

local WeaponMods = Tabs.Combat:AddRightGroupbox("Weapon Mods")
WeaponMods:AddToggle("NoBulletSpread",    { Text = "No Bullet Spread",    Default = false })
WeaponMods:AddToggle("RapidFire",         { Text = "Rapid Fire",          Default = false })
WeaponMods:AddToggle("NoScytheCooldown",  { Text = "No Scythe Cooldown",  Default = false })

-- Anti-Aim (in Combat, right side — added to Ragebot groupbox section area)
local AntiAimGroup = Tabs.Combat:AddRightGroupbox("Anti-Aim")
AntiAimGroup:AddDropdown("AntiAimPitch", { Values = {"disabled","offset","random","look up","look down","custom","extended custom","extended random"}, Default = "disabled", Text = "Pitch" })
AntiAimGroup:AddSlider("AntiAimPitchAngle", { Text = "Pitch Angle",  Default = 0,   Min = -180, Max = 180, Rounding = 0 })
AntiAimGroup:AddDropdown("AntiAimYaw",   { Values = {"disabled","offset","backwards","random","custom"}, Default = "disabled", Text = "Yaw" })
AntiAimGroup:AddSlider("AntiAimYawAngle",{ Text = "Yaw Angle",    Default = 0,   Min = -180, Max = 180, Rounding = 0 })
AntiAimGroup:AddToggle("AntiAimUnderground", { Text = "Underground", Default = false })

-- ── VISUALS TAB UI ─────────────────────────────────────────────────────────────
local ESPGroup = Tabs.Visuals:AddLeftGroupbox("ESP")
ESPGroup:AddToggle("EnableESP",  { Text = "Enable ESP",   Default = false })
    :AddKeyPicker("ESPKey", { Default = "None", Mode = "Toggle", SyncToggleState = true, Text = "ESP" })
ESPGroup:AddToggle("ESPBox",         { Text = "Box",          Default = true })
ESPGroup:AddToggle("ESPNames",       { Text = "Names",        Default = true })
ESPGroup:AddToggle("ESPHealth",      { Text = "Health Bar",   Default = true })
ESPGroup:AddToggle("ESPHealthText",  { Text = "Health Text",  Default = false })
ESPGroup:AddToggle("ESPDistance",    { Text = "Distance",     Default = false })
ESPGroup:AddToggle("ESPTeam",        { Text = "Show Teammates",Default = false })
ESPGroup:AddSlider("ESPMaxDist",     { Text = "Max Distance", Default = 500, Min = 50, Max = 2000, Rounding = 0 })
ESPGroup:AddToggle("ESPHighlight",   { Text = "Highlight",    Default = false })
ESPGroup:AddDropdown("ESPHighlightMethod", { Values = {"Highlight","Chams"}, Default = "Highlight", Text = "Highlight Method" })
ESPGroup:AddToggle("ESPSkeleton",    { Text = "Skeleton",     Default = false })
ESPGroup:AddToggle("ESPLookDir",     { Text = "Look Direction",Default = false })
ESPGroup:AddSlider("ESPTextSize",    { Text = "Text Size",    Default = 13, Min = 10, Max = 24, Rounding = 0 })

local ESPColors = Tabs.Visuals:AddLeftGroupbox("ESP Colors")
ESPColors:AddLabel("Visible Color"):AddColorPicker("ColorVisible", { Default = Color3.fromRGB(0, 255, 0) })
ESPColors:AddLabel("Hidden Color"):AddColorPicker("ColorHidden",   { Default = Color3.fromRGB(255, 0, 0) })
ESPColors:AddLabel("Teammate Color"):AddColorPicker("ColorTeam",   { Default = Color3.fromRGB(0, 150, 255) })

local Removals = Tabs.Visuals:AddRightGroupbox("Effect Removals")
Removals:AddToggle("NoFlashbang",   { Text = "No Flashbang Effect",  Default = false })
Removals:AddToggle("NoBurn",        { Text = "No Burn Effect",        Default = false })
Removals:AddToggle("NoScopeOverlay",{ Text = "No Scope Overlay",      Default = false })
Removals:AddToggle("NoScopeReticle",{ Text = "No Scope Reticle",      Default = false })
Removals:AddToggle("NoADS",         { Text = "No ADS Vignette",       Default = false })
Removals:AddToggle("NoMuzzle",      { Text = "No Muzzle Flash",       Default = false })
Removals:AddToggle("NoTracers",     { Text = "No Gun Tracers",         Default = false })
Removals:AddToggle("NoHitmarker",   { Text = "No Hitmarker",           Default = false })

local CameraFx = Tabs.Visuals:AddRightGroupbox("Camera Effects")
CameraFx:AddToggle("NoCameraShake", { Text = "No Camera Shake", Default = true })
CameraFx:AddToggle("CustomFOV",     { Text = "Custom Camera FOV", Default = false })
CameraFx:AddSlider("FOVValue",      { Text = "FOV Value",        Default = 130, Min = 50, Max = 130, Rounding = 0 })
CameraFx:AddToggle("ThirdPerson",   { Text = "Third Person",     Default = false })

local Viewmodel = Tabs.Visuals:AddRightGroupbox("Viewmodel Effects")
Viewmodel:AddToggle("NoViewModelMotion", { Text = "No Viewmodel Motion",   Default = false })
Viewmodel:AddToggle("NoShootAnim",       { Text = "No Shoot Animation",     Default = false })
Viewmodel:AddToggle("NoSprintAnim",      { Text = "No Sprint Animation",    Default = false })
Viewmodel:AddToggle("NoReloadAnim",      { Text = "No Reload Animation",    Default = false })
Viewmodel:AddToggle("NoEquipAnim",       { Text = "No Equip Animation",     Default = false })

local Stretched = Tabs.Visuals:AddRightGroupbox("Stretched Resolution")
Stretched:AddToggle("StretchedEnabled", { Text = "Stretched Resolution", Default = false })
Stretched:AddSlider("StretchedX", { Text = "X Ratio", Default = 100, Min = 10, Max = 100, Rounding = 0 })
Stretched:AddSlider("StretchedY", { Text = "Y Ratio", Default = 83,  Min = 10, Max = 100, Rounding = 0 })

-- ── MOVEMENT TAB UI ────────────────────────────────────────────────────────────
local MoveGroup = Tabs.Movement:AddLeftGroupbox("Movement")
MoveGroup:AddToggle("WalkSpeed",      { Text = "WalkSpeed",           Default = false })
MoveGroup:AddSlider("WalkSpeedMulti", { Text = "Walk Speed Multiplier",Default = 2.00, Min = 1, Max = 10, Rounding = 2 })
MoveGroup:AddToggle("SlidingSpeed",   { Text = "Sliding Speed",        Default = false })
MoveGroup:AddSlider("SlidingMulti",   { Text = "Sliding Multiplier",   Default = 10.00,Min = 1, Max = 20, Rounding = 2 })
MoveGroup:AddToggle("JumpPower",      { Text = "Jump Power",           Default = false })
MoveGroup:AddSlider("JumpPowerMulti", { Text = "Jump Power Multiplier",Default = 2.00, Min = 1, Max = 10, Rounding = 2 })
MoveGroup:AddToggle("Noclip",         { Text = "Noclip",               Default = false })

local FlightGroup = Tabs.Movement:AddRightGroupbox("Flight & Strafe")
FlightGroup:AddToggle("Flight",          { Text = "Flight",          Default = false })
FlightGroup:AddSlider("FlightSpeed",     { Text = "Flight Speed",    Default = 100, Min = 20, Max = 500, Rounding = 0 })
FlightGroup:AddToggle("AutoStrafe",      { Text = "Auto Strafe",     Default = false })
FlightGroup:AddSlider("AutoStrafeSpeed", { Text = "Auto Strafe Speed",Default = 50, Min = 10, Max = 150, Rounding = 0 })

local JumpGroup = Tabs.Movement:AddRightGroupbox("Jump")
JumpGroup:AddToggle("InfDoubleJumps", { Text = "Infinite Double Jumps", Default = false })
JumpGroup:AddToggle("LongJump",       { Text = "Long Jump",             Default = false })
JumpGroup:AddDropdown("LongJumpMode", { Values = {"Under Feet","Look Direction"}, Default = "Under Feet", Text = "Long Jump Mode" })

-- ── AUTOMATION TAB UI ─────────────────────────────────────────────────────────
local AutoQueue = Tabs.Automation:AddLeftGroupbox("Auto Queue")
AutoQueue:AddToggle("AutoQueueEnabled", { Text = "Enabled", Default = false })
AutoQueue:AddDropdown("QueueMode", { Values = {"1v1","2v2","3v3","4v4","5v5"}, Default = "1v1", Text = "Queue" })

local AutoBan = Tabs.Automation:AddRightGroupbox("Auto Weapon Ban")
AutoBan:AddToggle("AutoBanEnabled", { Text = "Enabled", Default = false })
AutoBan:AddDropdown("FirstBan",  { Values = {"None","Primary","Secondary","Melee"}, Default = "None", Text = "First Ban Choices" })
AutoBan:AddDropdown("SecondBan", { Values = {"None","Primary","Secondary","Melee"}, Default = "None", Text = "Second Ban Choices" })

local AutoMap = Tabs.Automation:AddLeftGroupbox("Auto Map Vote")
AutoMap:AddToggle("AutoMapEnabled", { Text = "Enabled", Default = false })
AutoMap:AddDropdown("MapsToVote", { Values = {"None","Random"}, Default = "None", Text = "Maps to Vote For" })

local AutoLoadout = Tabs.Automation:AddLeftGroupbox("Auto Loadout")
AutoLoadout:AddToggle("AutoLoadoutEnabled",    { Text = "Enabled",                    Default = false })
AutoLoadout:AddToggle("MapSpecificLoadout",    { Text = "Use Map-Specific Loadouts",  Default = false })
AutoLoadout:AddDropdown("LoadoutMap",          { Values = {"Default","Arena","Duel"}, Default = "Default", Text = "Map" })
AutoLoadout:AddDropdown("LoadoutPriority",     { Values = {"1","2","3"},              Default = "1",       Text = "Loadout Priority (1 highest)" })

local LoadoutSlots = Tabs.Automation:AddRightGroupbox("Loadout Slots")
LoadoutSlots:AddDropdown("PrimarySlot",   { Values = {"Assault Rifle","Sniper","Shotgun"},      Default = "Assault Rifle", Text = "Primary" })
LoadoutSlots:AddDropdown("SecondarySlot", { Values = {"Handgun","Dual Pistols"},                Default = "Handgun",       Text = "Secondary" })
LoadoutSlots:AddDropdown("MeleeSlot",     { Values = {"Fists","Sword","Knife"},                 Default = "Fists",         Text = "Melee" })
LoadoutSlots:AddDropdown("UtilitySlot",   { Values = {"Grenade","Flashbang","Smoke"},            Default = "Grenade",       Text = "Utility" })

local AutoPickup = Tabs.Automation:AddLeftGroupbox("Auto Pickup")
AutoPickup:AddToggle("AutoPickupEnabled", { Text = "Enabled", Default = false })
AutoPickup:AddDropdown("PickupTypes", { Values = {"Ammo","Health","Both"}, Default = "Both", Text = "Pickup Types" })

local Tripmines = Tabs.Automation:AddRightGroupbox("Subspace Tripmines")
Tripmines:AddToggle("TripmineAuto", { Text = "Auto Trigger",  Default = false })
Tripmines:AddToggle("TripmineTeam", { Text = "Team Trigger",  Default = false })

local AutoRespawn = Tabs.Automation:AddRightGroupbox("Auto Respawn")
AutoRespawn:AddToggle("AutoRespawnEnabled", { Text = "Enabled", Default = false })

local AntiKatana = Tabs.Automation:AddLeftGroupbox("Anti Katana")
AntiKatana:AddToggle("AntiKatanaEnabled", { Text = "Enabled", Default = false })

local ModDetector = Tabs.Automation:AddRightGroupbox("Moderator Detector")
ModDetector:AddToggle("ModDetectorEnabled", { Text = "Enabled", Default = false })
ModDetector:AddDropdown("ModResponses", { Values = {"Notify","Kick","Crash"}, Default = "Notify", Text = "Moderator Responses" })
ModDetector:AddDropdown("ModFriends",   { Values = {"None","Notify","Kick"},  Default = "None",   Text = "Mod Friends" })

local HackerDetector = Tabs.Automation:AddLeftGroupbox("Hacker Detector")
HackerDetector:AddToggle("HackerDetectorEnabled", { Text = "Enabled",  Default = false })
HackerDetector:AddToggle("HackerNotify",          { Text = "Notify",   Default = true })

-- ── SETTINGS TAB UI ───────────────────────────────────────────────────────────
local SettingsGroup = Tabs.Settings:AddLeftGroupbox("Menu")
SettingsGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("Eclipse")
SaveManager:SetFolder("Eclipse/configs")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

-- ═══════════════════════════════════════════════════════════════════════════════
-- ── ESP (fixed: no cloneref crash, GUI-parented per-player, full feature set) ──
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local ESPHolder = Instance.new("ScreenGui")
    ESPHolder.Name = "EclipseESP"
    ESPHolder.ResetOnSpawn = false
    ESPHolder.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local ok = pcall(function() ESPHolder.Parent = (gethui and gethui()) or CoreGui end)
    if not ok then ESPHolder.Parent = LP:WaitForChild("PlayerGui") end

    local RotAngle = -45
    local RotTick  = tick()

    local function mk(cls, props, par)
        local i = Instance.new(cls)
        for k,v in pairs(props) do i[k] = v end
        if par then i.Parent = par end
        return i
    end

    local function getWeaponName(plr)
        if not plr or not plr.Character then return "" end
        local ok2, res = pcall(function()
            local fc = require(plr.PlayerScripts:FindFirstChild("FighterController", true))
            if fc and fc._player_to_fighter then
                local f = fc._player_to_fighter[plr]
                if f and f.EquippedItem and f.EquippedItem.Info then
                    return f.EquippedItem.Info.Name
                end
            end
            return ""
        end)
        return (ok2 and type(res) == "string") and res or ""
    end

    local function buildESP(plr)
        -- remove old if any
        local old = ESPHolder:FindFirstChild(plr.Name)
        if old then old:Destroy() end

        local container = mk("Folder", {Name = plr.Name}, ESPHolder)

        -- UI elements
        local Name       = mk("TextLabel",   {Size=UDim2.fromOffset(120,20), AnchorPoint=Vector2.new(0.5,0.5), BackgroundTransparency=1, TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextSize=13, TextStrokeTransparency=0, TextStrokeColor3=Color3.new(0,0,0), RichText=true, ZIndex=5, Visible=false}, ESPHolder)
        local Distance   = mk("TextLabel",   {Size=UDim2.fromOffset(120,20), AnchorPoint=Vector2.new(0.5,0.5), BackgroundTransparency=1, TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextSize=11, TextStrokeTransparency=0, TextStrokeColor3=Color3.new(0,0,0), ZIndex=5, Visible=false}, ESPHolder)
        local Box        = mk("Frame",        {BackgroundColor3=Color3.new(1,1,1), BackgroundTransparency=1, BorderSizePixel=0, ZIndex=4, Visible=false}, ESPHolder)
        mk("UIStroke", {Color=Color3.new(1,1,1), Thickness=1.4}, Box)
        local HBBack     = mk("Frame",        {BackgroundColor3=Color3.new(0,0,0), BackgroundTransparency=0, BorderSizePixel=0, ZIndex=3, Visible=false}, ESPHolder)
        local HBFill     = mk("Frame",        {BackgroundColor3=Color3.fromRGB(0,230,100), BorderSizePixel=0, ZIndex=4, Visible=false}, ESPHolder)
        local HBText     = mk("TextLabel",    {Size=UDim2.fromOffset(40,14), AnchorPoint=Vector2.new(0.5,0.5), BackgroundTransparency=1, TextColor3=Color3.new(1,1,1), Font=Enum.Font.Gotham, TextSize=10, TextStrokeTransparency=0.3, TextStrokeColor3=Color3.new(0,0,0), ZIndex=5, Visible=false}, ESPHolder)
        local Chams      = mk("Highlight",    {FillTransparency=0.6, OutlineTransparency=0, OutlineColor=Color3.fromRGB(235,64,80), DepthMode=Enum.HighlightDepthMode.AlwaysOnTop, Enabled=false}, container)
        -- corner box frames
        local corners = {}
        for i = 1, 8 do
            corners[i] = mk("Frame", {BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0, ZIndex=6, Visible=false}, ESPHolder)
        end

        local function hideAll()
            Name.Visible=false; Distance.Visible=false; Box.Visible=false
            HBBack.Visible=false; HBFill.Visible=false; HBText.Visible=false
            Chams.Enabled=false
            for _,c in ipairs(corners) do c.Visible=false end
        end

        local conn
        conn = RunService.RenderStepped:Connect(function()
            -- check player still exists
            if not plr or not plr.Parent then
                hideAll(); conn:Disconnect()
                pcall(function() container:Destroy() end)
                return
            end
            -- master toggle
            if not T("EnableESP") then hideAll(); return end

            local char = plr.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if not (char and hrp and hum and hum.Health > 0) then hideAll(); return end

            -- team check
            if not T("ESPTeam") then
                local sameTeam = false
                pcall(function()
                    local a = LP:GetAttribute("TeamID")
                    local b = plr:GetAttribute("TeamID")
                    if a and b then sameTeam = (a == b)
                    elseif LP.Team and plr.Team then sameTeam = (LP.Team == plr.Team) end
                end)
                if sameTeam then hideAll(); return end
            end

            local pos, onScreen = Camera:WorldToScreenPoint(hrp.Position)
            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
            local maxD = O("ESPMaxDist") or 500

            if not onScreen or dist > maxD then hideAll(); return end

            -- compute box dimensions from HRP
            local scaleFactor = (hrp.Size.Y * Camera.ViewportSize.Y) / (pos.Z * 2)
            local w, h = scaleFactor * 3, scaleFactor * 5.5
            local px, py = pos.X, pos.Y

            -- visible color vs hidden color
            local visColor   = O("ColorVisible") or Color3.fromRGB(0,255,0)
            local hiddenColor= O("ColorHidden")  or Color3.fromRGB(255,0,0)
            -- simple wall check via raycast
            local isVis = false
            pcall(function()
                local rp = RaycastParams.new()
                rp.FilterType = Enum.RaycastFilterType.Exclude
                rp.FilterDescendantsInstances = {char, LP.Character}
                local ray = Workspace:Raycast(Camera.CFrame.Position, hrp.Position - Camera.CFrame.Position, rp)
                isVis = not ray or (ray.Instance and char:IsAncestorOf(ray.Instance))
            end)
            local boxColor = isVis and visColor or hiddenColor
            local tsz = O("ESPTextSize") or 13

            -- Box
            if T("ESPBox") then
                Box.Position  = UDim2.fromOffset(px - w/2, py - h/2)
                Box.Size      = UDim2.fromOffset(w, h)
                Box.Visible   = true
                local stroke = Box:FindFirstChildOfClass("UIStroke")
                if stroke then stroke.Color = boxColor end
                -- corner boxes
                local cW, cH = w/5, 1
                local cSide = h/5
                -- LT horizontal
                corners[1].Position=UDim2.fromOffset(px-w/2,py-h/2); corners[1].Size=UDim2.fromOffset(cW,1); corners[1].BackgroundColor3=boxColor; corners[1].Visible=true
                -- LT vertical
                corners[2].Position=UDim2.fromOffset(px-w/2,py-h/2); corners[2].Size=UDim2.fromOffset(1,cSide); corners[2].BackgroundColor3=boxColor; corners[2].Visible=true
                -- RT horizontal
                corners[3].Position=UDim2.fromOffset(px+w/2-cW,py-h/2); corners[3].Size=UDim2.fromOffset(cW,1); corners[3].BackgroundColor3=boxColor; corners[3].Visible=true
                -- RT vertical
                corners[4].Position=UDim2.fromOffset(px+w/2-1,py-h/2); corners[4].Size=UDim2.fromOffset(1,cSide); corners[4].BackgroundColor3=boxColor; corners[4].Visible=true
                -- LB horizontal
                corners[5].Position=UDim2.fromOffset(px-w/2,py+h/2-1); corners[5].Size=UDim2.fromOffset(cW,1); corners[5].BackgroundColor3=boxColor; corners[5].Visible=true
                -- LB vertical
                corners[6].Position=UDim2.fromOffset(px-w/2,py+h/2-cSide); corners[6].Size=UDim2.fromOffset(1,cSide); corners[6].BackgroundColor3=boxColor; corners[6].Visible=true
                -- RB horizontal
                corners[7].Position=UDim2.fromOffset(px+w/2-cW,py+h/2-1); corners[7].Size=UDim2.fromOffset(cW,1); corners[7].BackgroundColor3=boxColor; corners[7].Visible=true
                -- RB vertical
                corners[8].Position=UDim2.fromOffset(px+w/2-1,py+h/2-cSide); corners[8].Size=UDim2.fromOffset(1,cSide); corners[8].BackgroundColor3=boxColor; corners[8].Visible=true
            else
                Box.Visible = false
                for _,c in ipairs(corners) do c.Visible=false end
            end

            -- Health bar
            if T("ESPHealth") then
                local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                local barH = h * hp
                HBBack.Position = UDim2.fromOffset(px - w/2 - 7, py - h/2)
                HBBack.Size     = UDim2.fromOffset(3, h)
                HBBack.Visible  = true
                HBFill.Position = UDim2.fromOffset(px - w/2 - 7, py - h/2 + (h - barH))
                HBFill.Size     = UDim2.fromOffset(3, barH)
                local hpColor = hp > 0.6 and Color3.fromRGB(0,230,80) or hp > 0.3 and Color3.fromRGB(255,200,0) or Color3.fromRGB(230,50,50)
                HBFill.BackgroundColor3 = hpColor
                HBFill.Visible  = true
                if T("ESPHealthText") then
                    HBText.Text     = tostring(math.floor(hum.Health))
                    HBText.Position = UDim2.fromOffset(px - w/2 - 7, py - h/2 + (h - barH) - 8)
                    HBText.TextSize = math.clamp(tsz - 2, 8, 18)
                    HBText.Visible  = true
                else HBText.Visible = false end
            else
                HBBack.Visible = false; HBFill.Visible = false; HBText.Visible = false
            end

            -- Name
            if T("ESPNames") then
                Name.Text     = plr.DisplayName
                Name.TextSize = tsz
                Name.TextColor3 = isVis and visColor or hiddenColor
                Name.Position = UDim2.fromOffset(px, py - h/2 - 10)
                Name.Visible  = true
                -- append distance inline if ESPDistance
                if T("ESPDistance") then
                    Name.Text = string.format("%s [%dm]", plr.DisplayName, math.floor(dist))
                end
            else Name.Visible = false end

            -- Distance standalone
            if T("ESPDistance") and not T("ESPNames") then
                Distance.Text     = string.format("%dm", math.floor(dist))
                Distance.TextSize = math.clamp(tsz - 1, 8, 18)
                Distance.Position = UDim2.fromOffset(px, py + h/2 + 8)
                Distance.Visible  = true
            else Distance.Visible = false end

            -- Highlight / Chams
            if T("ESPHighlight") then
                local method = O("ESPHighlightMethod") or "Highlight"
                Chams.Adornee = char
                if method == "Chams" then
                    Chams.FillColor       = boxColor
                    Chams.OutlineColor    = boxColor
                    Chams.FillTransparency    = 0.4
                    Chams.OutlineTransparency = 0
                    Chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                else
                    Chams.FillColor       = boxColor
                    Chams.OutlineColor    = boxColor
                    Chams.FillTransparency    = 0.75
                    Chams.OutlineTransparency = 0
                    Chams.DepthMode = Enum.HighlightDepthMode.Occluded
                end
                Chams.Enabled = true
            else Chams.Enabled = false end
        end)
    end

    -- spawn ESP for all current + future players (not self)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then task.spawn(buildESP, plr) end
    end
    Players.PlayerAdded:Connect(function(plr)
        if plr ~= LP then task.spawn(buildESP, plr) end
    end)
    Players.PlayerRemoving:Connect(function(plr)
        local c = ESPHolder:FindFirstChild(plr.Name)
        if c then c:Destroy() end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ── AIMBOT (Kicia-style: Spring / AI / Linear — exact from finalaimbot.txt) ───
-- ═══════════════════════════════════════════════════════════════════════════════
do
    -- FOV circle using Drawing (pcall-guarded for mobile executors)
    local FOVCircle
    pcall(function()
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Thickness  = 1.5
        FOVCircle.Color      = Color3.fromRGB(255, 255, 255)
        FOVCircle.Filled     = false
        FOVCircle.Visible    = false
    end)
    if not FOVCircle then
        FOVCircle = { Visible = false, Position = Vector2.zero, Radius = 0, Remove = function() end }
    end

    local AimbotSpring = { pos = Vector3.zero, vel = Vector3.zero, initialized = false }
    local AimbotAI     = { lastTarget = Vector3.zero, lead = Vector3.zero, acquireAt = 0 }

    local function resetAimStates()
        AimbotSpring.initialized = false
        AimbotSpring.pos = Vector3.zero
        AimbotSpring.vel = Vector3.zero
        AimbotAI.lastTarget = Vector3.zero
        AimbotAI.lead = Vector3.zero
        AimbotAI.acquireAt = 0
    end

    local function getAimbotTarget()
        local closestDist = O("FOVSize") or 500
        local best = nil
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = { LP.Character }
        local myChar = LP.Character
        local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LP then continue end
            local char = plr.Character
            if not char then continue end
            local partName = O("HitPart") or "Head"
            if partName == "Random" then partName = (math.random(2) == 1) and "Head" or "HumanoidRootPart" end
            local part = char:FindFirstChild(partName) or char:FindFirstChild("Head")
            local hum  = char:FindFirstChildOfClass("Humanoid")
            local hrp  = char:FindFirstChild("HumanoidRootPart")
            if not (part and hum and hrp and hum.Health > 0 and myHRP) then continue end

            local dist3D = (myHRP.Position - hrp.Position).Magnitude
            if dist3D > (O("MaxDistance") or 1200) then continue end

            -- team check
            if T("TeamCheck") then
                local sameTeam = false
                pcall(function()
                    local a = LP:GetAttribute("TeamID"); local b = plr:GetAttribute("TeamID")
                    if a and b then sameTeam = (a==b)
                    elseif LP.Team and plr.Team then sameTeam = (LP.Team == plr.Team) end
                end)
                if sameTeam then continue end
            end

            -- wall check
            if T("WallCheck") then
                local ray = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, rp)
                if ray and ray.Instance and not char:IsAncestorOf(ray.Instance) then continue end
            end

            local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
            if not onScreen then continue end
            local d2 = (Vector2.new(sp.X, sp.Y) - center).Magnitude
            if d2 < closestDist then closestDist = d2; best = plr end
        end
        return best
    end

    local function aimSpring(targetPos, dt)
        if not AimbotSpring.initialized then
            AimbotSpring.pos = Camera.CFrame.Position + Camera.CFrame.LookVector
            AimbotSpring.initialized = true
        end
        local s = math.clamp((O("Smoothness") or 35) / 100, 0.01, 1)
        local alpha = 1 - math.exp(-(1 + s * 15) * dt)
        AimbotSpring.pos = AimbotSpring.pos:Lerp(targetPos, alpha)
        return CFrame.new(Camera.CFrame.Position, AimbotSpring.pos)
    end

    local function aimLinear(targetPos, dt)
        local targetCF = CFrame.new(Camera.CFrame.Position, targetPos)
        local s = math.clamp((O("Smoothness") or 35) / 100, 0.01, 1)
        local alpha = 1 - math.exp(-(1 + s * 34) * dt)
        return Camera.CFrame:Lerp(targetCF, math.clamp(alpha, 0.001, 1))
    end

    local function aimAI(targetPos, hrp, dt)
        local vel = hrp and hrp.AssemblyLinearVelocity or Vector3.zero
        local dist = (targetPos - Camera.CFrame.Position).Magnitude
        AimbotAI.lead = vel * (dist / 500)
        local aimPos = targetPos + AimbotAI.lead
        local targetCF = CFrame.new(Camera.CFrame.Position, aimPos)
        local s = math.clamp((O("Smoothness") or 35) / 100, 0.01, 1)
        local alpha = 1 - math.exp(-(1 + s * 30) * dt)
        return Camera.CFrame:Lerp(targetCF, math.clamp(alpha, 0.001, 1))
    end

    local lastFrameAim = tick()
    local aimSwitchState = { lastTarget = nil, switchAt = 0 }

    RunService:BindToRenderStep("EclipseAimbot", Enum.RenderPriority.Camera.Value + 1, function()
        local now = tick()
        local dt  = math.clamp(now - lastFrameAim, 0, 0.1)
        lastFrameAim = now

        local fovSize = O("FOVSize") or 500
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius   = fovSize
        FOVCircle.Visible  = T("ShowFOVCircle") or T("AimbotShowFOV")

        if not T("Aimbot") then resetAimStates(); return end

        local target = getAimbotTarget()
        if not target or not target.Character then resetAimStates(); return end

        local partName = O("HitPart") or "Head"
        if partName == "Random" then partName = "Head" end
        local part = target.Character:FindFirstChild(partName) or target.Character:FindFirstChild("Head")
        local hrp  = target.Character:FindFirstChild("HumanoidRootPart")
        if not part then resetAimStates(); return end

        if aimSwitchState.lastTarget ~= target then
            aimSwitchState.switchAt   = now
            aimSwitchState.lastTarget = target
        end
        if now < aimSwitchState.switchAt then return end

        local mode = O("AimbotMode") or "Lock"
        if mode == "Spring" then
            Camera.CFrame = aimSpring(part.Position, dt)
        elseif mode == "Linear" then
            Camera.CFrame = aimLinear(part.Position, dt)
        else -- "Lock" / "AI"
            Camera.CFrame = aimAI(part.Position, hrp, dt)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ── SILENT AIM (exact from silent_aim.txt — zero crash version) ───────────────
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local SA = {}

    -- Module resolution helpers
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
    local function awaitLoaded(moduleInst, timeout)
        if not moduleInst or type(getloadedmodules) ~= "function" then return end
        local deadline = tick() + (timeout or 15)
        repeat
            local ok, loaded = pcall(getloadedmodules)
            if ok and type(loaded) == "table" then
                for _, m in ipairs(loaded) do if m == moduleInst then return end end
            end
            task.wait(0.1)
        until tick() >= deadline
    end
    local function loadGameModule(root, names)
        local inst = waitModule(root, names)
        awaitLoaded(inst, 15)
        return safeRequire(inst)
    end

    local Rivals = { Ready = false }
    local function resolveAll(jobs, timeout)
        local pending = #jobs
        for _, job in ipairs(jobs) do
            task.spawn(function() pcall(job); pending -= 1 end)
        end
        local deadline = tick() + (timeout or 25)
        while pending > 0 and tick() < deadline do task.wait() end
        return pending == 0
    end
    resolveAll({
        function() Rivals.Util    = loadGameModule(RepS, {"Modules","Utility"}) end,
        function() Rivals.Fighter = loadGameModule(LP.PlayerScripts, {"Controllers","FighterController"}) end,
        function() Rivals.Enums   = loadGameModule(RepS, {"Modules","EnumLibrary"}) end,
    })
    Rivals.Ready = (Rivals.Util ~= nil and Rivals.Fighter ~= nil)

    local function resolveWeaponModules()
        resolveAll({
            function() if Rivals.Gun   == nil then Rivals.Gun   = loadGameModule(LP.PlayerScripts, {"Modules","ItemTypes","Gun"})   end end,
            function() if Rivals.Melee == nil then Rivals.Melee = loadGameModule(LP.PlayerScripts, {"Modules","ItemTypes","Melee"}) end end,
            function() if Rivals.Knife == nil then Rivals.Knife = loadGameModule(LP.PlayerScripts, {"Modules","Items","Knife"})     end end,
        })
    end
    resolveWeaponModules()

    -- Player cache
    local _safePlyCache = nil
    local function getSafePlayers()
        if _safePlyCache then return _safePlyCache end
        local list = {}
        for _, p in ipairs(Players:GetChildren()) do
            if p:IsA("Player") then list[#list+1] = p end
        end
        _safePlyCache = list
        return list
    end
    Players.PlayerAdded:Connect(function()   _safePlyCache = nil end)
    Players.PlayerRemoving:Connect(function() _safePlyCache = nil end)

    local HEAD_PARTS  = { "HitboxHead","HitboxHeadSmall","Head" }
    local TORSO_PARTS = { "HitboxBody","UpperTorso","HumanoidRootPart","LowerTorso" }
    local CLOSE_PARTS = {
        "HitboxHead","Head","UpperTorso","LowerTorso","HumanoidRootPart",
        "LeftHand","RightHand","LeftFoot","RightFoot",
        "LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg",
    }

    local function envIdOf(plr)
        local id = nil
        pcall(function()
            local fc = Rivals.Fighter
            if not fc then return end
            local f = (plr == LP) and fc.LocalFighter or (fc._player_to_fighter and fc._player_to_fighter[plr])
            if not f then return end
            id = f:Get("EnvironmentID")
            if id == nil and f.Entity then id = f.Entity:Get("EnvironmentID") end
        end)
        return id
    end
    local function isTeammate(plr)
        if plr == LP then return true end
        local myEnv, theirEnv = envIdOf(LP), envIdOf(plr)
        if myEnv ~= nil and theirEnv ~= nil and myEnv ~= theirEnv then return true end
        local a = LP:GetAttribute("TeamID"); local b = plr:GetAttribute("TeamID")
        if a == nil or b == nil then
            if LP.Team and plr.Team then return LP.Team == plr.Team end
            return false
        end
        return a == b
    end
    local function isAlive(plr)
        local c = plr.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        return h ~= nil and h.Health > 0
    end
    local function pickPart(char, mode)
        if not char then return nil end
        if mode == "Closest" then
            local best, bestD = nil, math.huge
            local center = Vector2.new(Camera.ViewportSize.X*.5, Camera.ViewportSize.Y*.5)
            for _, name in ipairs(CLOSE_PARTS) do
                local p = char:FindFirstChild(name)
                if p and p:IsA("BasePart") then
                    local sp, on = Camera:WorldToViewportPoint(p.Position)
                    if on and sp.Z > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d < bestD then best, bestD = p, d end
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
        local vc = LP.Character
        if vc ~= _visFilterChar then
            visParams.FilterDescendantsInstances = { vc }
            _visFilterChar = vc
        end
        local result = Workspace:Raycast(origin, worldPos - origin, visParams)
        if not result then return true end
        local hitModel = result.Instance and result.Instance:FindFirstAncestorOfClass("Model")
        if hitModel and Players:GetPlayerFromCharacter(hitModel) then return true end
        return (result.Position - worldPos).Magnitude < 3
    end

    -- Deflect detection
    local DEFLECT_IDS = {
        ["14761240825"]=true,["14761220206"]=true,["14761234917"]=true,["14761221711"]=true,
        ["14761223422"]=true,["14761225204"]=true,["14761232380"]=true,["90436105114997"]=true,
        ["90797895557136"]=true,["77995180947430"]=true,["111943779640553"]=true,
        ["131072510521727"]=true,["132022220827223"]=true,["116315405171252"]=true,
    }
    local _deflecting, _deflGen, _deflHookLive = {}, {}, false
    local function isDeflectingAnim(plr)
        if not plr or not plr.Character then return false end
        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return false end
        local anim = hum:FindFirstChildOfClass("Animator")
        if not anim then return false end
        for _, track in ipairs(anim:GetPlayingAnimationTracks()) do
            if track.Name:lower():find("deflect") then return true end
            local an = track.Animation
            local id = an and an.AnimationId
            if id then
                local num = id:match("(%d+)")
                if num and DEFLECT_IDS[num] then return true end
            end
        end
        return false
    end
    local function isDeflecting(plr)
        if not plr then return false end
        if _deflecting[plr.UserId] then return true end
        if _deflHookLive then return false end
        return isDeflectingAnim(plr)
    end
    -- katana hook for deflect
    task.spawn(function()
        local ok, katana = pcall(loadGameModule, LP.PlayerScripts, {"Modules","Items","Katana"})
        if not ok or type(katana) ~= "table" or type(katana._StartDeflecting) ~= "function" then return end
        local orig = (clonefunction and clonefunction(katana._StartDeflecting)) or katana._StartDeflecting
        if setreadonly then pcall(setreadonly, katana, false) end
        katana._StartDeflecting = function(self, ...)
            pcall(function()
                local fighter = self and self.ClientFighter
                local plr = fighter and fighter.Player
                if not plr then return end
                local uid = plr.UserId
                local dur = self.Info and type(self.Info.DeflectDuration) == "number" and self.Info.DeflectDuration or 0.1
                _deflecting[uid] = true
                local gen = (_deflGen[uid] or 0) + 1
                _deflGen[uid] = gen
                task.delay(dur + 0.05, function()
                    if _deflGen[uid] == gen then _deflecting[uid] = nil end
                end)
            end)
            return orig(self, ...)
        end
        _deflHookLive = true
    end)

    -- Spawn protection
    local _invincible, _invincEnt = {}, {}
    local function isSpawnProtected(plr)
        if not plr or not (Rivals.Ready and Rivals.Fighter) then return false end
        local map = Rivals.Fighter._player_to_fighter
        if not map then return false end
        local f = map[plr]
        if not f then return false end
        local e = f.Entity
        if not e then return false end
        local uid = plr.UserId
        if _invincEnt[uid] ~= e then
            _invincible[uid] = nil
            pcall(function()
                local live = e:Get("IsInvincible") == true
                e:GetDataChangedSignal("IsInvincible"):Connect(function()
                    _invincible[uid] = e:Get("IsInvincible") == true
                end)
                _invincible[uid] = live
                _invincEnt[uid] = e
            end)
        end
        return _invincible[uid] == true
    end

    -- Velocity tracker
    local _sharedVelMap = {}
    do
        local _svPos, _svTime, _svAccum = {}, {}, 0
        local SV_INT = 1/30
        RunService.Heartbeat:Connect(function(dt)
            if not T("SilentAim") then return end
            _svAccum += dt
            if _svAccum < SV_INT then return end
            _svAccum = 0
            local now = tick()
            for _, p in ipairs(getSafePlayers()) do
                if p ~= LP and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local pos = hrp.Position
                        local lt = _svTime[p]
                        if _svPos[p] and lt then
                            local d = now - lt
                            if d > 0 then
                                local v = (pos - _svPos[p]) / d
                                if v.Magnitude < 500 then _sharedVelMap[p] = v end
                            end
                        end
                        _svPos[p] = pos; _svTime[p] = now
                    end
                end
            end
        end)
    end

    local function calculateLead(targetChar, fromPos)
        if not targetChar then return Vector3.zero end
        local hum = targetChar:FindFirstChildOfClass("Humanoid")
        local hrp = targetChar:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return Vector3.zero end
        local lat = (LP:GetNetworkPing() or 0.05) + 0.03
        local lead = Vector3.zero
        if T("PredictiveLead") then
            local ply = Players:GetPlayerFromCharacter(targetChar)
            local tv = hrp.AssemblyLinearVelocity
            local cv = ply and _sharedVelMap[ply]
            if cv then
                if (tv - cv).Magnitude > 25 then tv = cv end
            else
                if tv.Magnitude > 100 then tv = Vector3.zero end
            end
            if tv.Magnitude <= 120 then
                lead = Vector3.new(tv.X, 0, tv.Z) * lat + Vector3.new(0, tv.Y * lat, 0)
            end
        end
        local cap = O("LeadCap") or 15
        if lead.Magnitude > cap then lead = lead.Unit * cap end
        return lead
    end

    local function isValidTarget(plr)
        if not plr or plr == LP then return false end
        if T("TeamCheck") and isTeammate(plr) then return false end
        if not isAlive(plr) then return false end
        if isDeflecting(plr) then return false end
        if isSpawnProtected(plr) then return false end
        local char = plr.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        local myChar = LP.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myRoot and (hrp.Position - myRoot.Position).Magnitude > (O("MaxDistance") or 1200) then return false end
        return true
    end

    local _silentLastTarget = nil
    local function selectTarget()
        local fov     = O("FOVSize") or 500
        local partMode = O("HitPart") or "Head"
        if partMode == "Random" then partMode = "Head" end
        local center = Vector2.new(Camera.ViewportSize.X*.5, Camera.ViewportSize.Y*.5)
        local best, bestPart, bestScore = nil, nil, math.huge
        for _, plr in ipairs(getSafePlayers()) do
            if plr ~= LP and isValidTarget(plr) then
                local char = plr.Character
                local part = pickPart(char, partMode)
                if part then
                    local sp, on = Camera:WorldToViewportPoint(part.Position)
                    if on and sp.Z > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d <= fov then
                            local score = d
                            if plr == _silentLastTarget then score *= (1 - (O("SilentAimStickiness") or 0.05)) end
                            if score < bestScore then bestScore, best, bestPart = score, plr, part end
                        end
                    end
                end
            end
        end
        return best, bestPart
    end

    local function silentPartVisible(part)
        if not part or not part:IsA("BasePart") then return false end
        if not T("SilentAimMultipoint") then return isVisible(part.Position) end
        if isVisible(part.Position) then return true end
        local n = math.max(1, math.floor(O("SilentAimMultipointCount") or 5))
        local r = math.min(part.Size.X, part.Size.Y, part.Size.Z) * 0.4
        for i = 1, n do
            local a = (i / n) * math.pi * 2
            local off = Vector3.new(math.cos(a) * r, ((i%2==0) and 0.5 or -0.5)*r, math.sin(a)*r)
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
        if T("SilentAimTorsoFallback") then
            for _, name in ipairs(TORSO_PARTS) do
                local p = char:FindFirstChild(name)
                if p and silentPartVisible(p) then return p end
            end
        end
        return primary
    end

    local function lookCF(fromPos, toPos)
        local dir = toPos - fromPos
        if dir.Magnitude < 1e-4 then dir = Vector3.new(0,-1,0) end
        local up = Vector3.new(0,1,0)
        if math.abs(dir.Unit.Y) > 0.999 then up = Vector3.new(0,0,1) end
        return CFrame.lookAt(fromPos, fromPos + dir, up)
    end

    local function buildShotFields(camData, eyeCF, muzzleCF, hitPart, aimWorldPos, jitter, clampFrac, jitterFrac)
        local objSpace = hitPart.CFrame:PointToObjectSpace(aimWorldPos)
        local hs = hitPart.Size * (clampFrac or 0.45)
        objSpace = Vector3.new(
            math.clamp(objSpace.X, -hs.X, hs.X),
            math.clamp(objSpace.Y, -hs.Y, hs.Y),
            math.clamp(objSpace.Z, -hs.Z, hs.Z))
        if jitter then
            local jf = jitterFrac or 1.0
            objSpace = Vector3.new(
                math.clamp(objSpace.X + (math.random()-.5)*hs.X*jf, -hs.X, hs.X),
                math.clamp(objSpace.Y + (math.random()-.5)*hs.Y*jf, -hs.Y, hs.Y),
                math.clamp(objSpace.Z + (math.random()-.5)*hs.Z*jf, -hs.Z, hs.Z))
        end
        local hitWorld   = hitPart.CFrame:PointToWorldSpace(objSpace)
        local objSpaceCF = hitPart.CFrame:ToObjectSpace(CFrame.new(hitWorld))
        camData[utf8.char(0)] = Rivals.Util:EncodeCFrame(eyeCF)
        camData[utf8.char(1)] = Rivals.Util:EncodeCFrame(muzzleCF)
        camData[utf8.char(2)] = hitPart
        camData[utf8.char(3)] = Rivals.Util:EncodeCFrame(objSpaceCF)
    end

    local function encodeShot(camData, hitPart, targetChar, fromCamPos, claimOffset)
        if not hitPart or not camData or not Rivals.Util then return false end
        local lead     = calculateLead(targetChar, fromCamPos)
        local off      = (typeof(claimOffset) == "Vector3") and claimOffset or Vector3.zero
        local leadedPos = hitPart.Position + lead + off
        local eyeCF    = lookCF(fromCamPos, leadedPos)
        local muzzlePos = fromCamPos + (eyeCF.RightVector * 0.2) + Vector3.new(0, -0.07, 0)
        local muzzleCF = lookCF(muzzlePos, leadedPos)
        buildShotFields(camData, eyeCF, muzzleCF, hitPart, leadedPos, true, 0.45, 1.0)
        return true
    end

    local function hookGunModule()
        if not Rivals.Ready or not Rivals.Gun then return end
        if shared._EC_GunOrig then
            pcall(function() Rivals.Gun.StartShooting = shared._EC_GunOrig end)
        end
        local oldStart = Rivals.Gun.StartShooting
        shared._EC_GunOrig = oldStart
        local hookWrapper = function(self, ...)
            local results = { oldStart(self, ...) }
            pcall(function()
                if not self.ClientFighter or not self.ClientFighter.IsLocalPlayer then return end
                if not T("SilentAim") then return end
                local camData = results[3]
                if not camData or type(camData) ~= "table" then return end
                local camPos = Camera.CFrame.Position
                local tgt, part = selectTarget()
                if tgt and part then
                    _silentLastTarget = tgt
                    if math.random(1, 100) <= (O("SilentAimHitChance") or 100) then
                        local hitPart = pickSilentPart(tgt.Character, part)
                        if math.random(1, 100) <= (O("SilentAimBodyMix") or 25) then
                            local body = tgt.Character:FindFirstChild("HitboxBody")
                            if body and silentPartVisible(body) then hitPart = body end
                        end
                        local jit = Vector3.zero
                        local jd = O("SilentAimJitterDeg") or 0
                        if jd > 0 then
                            local ok2, unit = pcall(function()
                                return Vector3.new(math.random()-.5, math.random()-.5, math.random()-.5)
                            end)
                            local dir = (ok2 and unit.Magnitude > 1e-4) and unit.Unit or Vector3.zero
                            local dist = 0
                            pcall(function() dist = (hitPart.Position - camPos).Magnitude end)
                            local off = math.min(math.tan(math.rad(jd)) * dist, 3) * (math.random() * 0.5)
                            jit = dir * off
                        end
                        if encodeShot(camData, hitPart, tgt.Character, camPos, jit) then
                            results[4] = true
                        end
                    end
                end
            end)
            return table.unpack(results)
        end
        if setfenv then pcall(setfenv, hookWrapper, getfenv(oldStart)) end
        if setreadonly then pcall(setreadonly, Rivals.Gun, false) end
        Rivals.Gun.StartShooting = hookWrapper
    end

    -- Hook on spawn + initial
    LP.CharacterAdded:Connect(function()
        task.wait(0.5)
        resolveWeaponModules()
        if Rivals.Ready then hookGunModule() end
    end)
    task.spawn(function()
        for _ = 1, 30 do
            if Rivals.Gun then break end
            task.wait(1)
        end
        if Rivals.Ready and Rivals.Gun then hookGunModule() end
    end)

    _G["EclipseSilentAim"] = {
        unload = function()
            pcall(function()
                if shared._EC_GunOrig and Rivals.Gun then
                    if setreadonly then pcall(setreadonly, Rivals.Gun, false) end
                    Rivals.Gun.StartShooting = shared._EC_GunOrig
                end
                shared._EC_GunOrig = nil
            end)
            _G["EclipseSilentAim"] = nil
        end,
    }
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ── RAGEBOT (exact from fixedrage.lua, wired to LinoriaLib toggles) ───────────
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local clonerefR = cloneref or function(o) return o end
    local repSR  = clonerefR(game:GetService("ReplicatedStorage"))
    local plrsR  = clonerefR(game:GetService("Players"))
    local runSR  = clonerefR(game:GetService("RunService"))
    local wsR    = clonerefR(game:GetService("Workspace"))
    local lplrR  = plrsR.LocalPlayer

    local ok1, util     = pcall(require, repSR.Modules.Utility)
    local ok2, enumLib  = pcall(require, repSR.Modules.EnumLibrary)
    local ok3, FC       = pcall(require, lplrR.PlayerScripts.Controllers.FighterController)
    local ok4, SC       = pcall(require, lplrR.PlayerScripts.Controllers:WaitForChild("SpectateController"))
    if not (ok1 and ok2 and ok3 and ok4) then
        warn("[Eclipse Ragebot] Core modules failed to load")
        goto rageskip
    end

    local RageConfig = {
        FireRate       = 0.0005,
        WeaponSlot     = "Melee",
        DesyncMode     = "KnifeAware",
        JitterRange    = 3,
        OrbitSpeed     = 6.0,
        OrbitRadius    = 14,
        LowestHealth   = true,
        FFAMode        = false,
        FFAFireBoost   = true,
        KnifeHoverHeight  = 9,
        KnifeBehindOffset = -4,
        MaxDist        = 1000,
    }

    -- Sync LinoriaLib -> RageConfig every heartbeat
    RunService.Heartbeat:Connect(function()
        RageConfig.FireRate      = O("RageFireRate") or 0.05
        RageConfig.OrbitRadius   = O("RageOrbitRadius") or 5
        RageConfig.OrbitSpeed    = O("RageOrbitSpeed") or 15
        local wSlot = O("RagebotWeapon") or "Auto"
        if wSlot == "Auto" then RageConfig.WeaponSlot = "Melee"
        else RageConfig.WeaponSlot = wSlot end
    end)

    local slots = { Primary = 1, Secondary = 2, Melee = 3 }
    local function getSlotNumber() return slots[RageConfig.WeaponSlot] or 3 end

    task.spawn(function()
        while not FC.LocalFighter do task.wait(0.1) end
        pcall(function() FC.LocalFighter:EquipItem(getSlotNumber()) end)
        while true do
            task.wait(1)
            if T("RagebotEnabled") and FC.LocalFighter then
                pcall(function() FC.LocalFighter:EquipItem(getSlotNumber()) end)
            end
        end
    end)

    local lastFireR = 0
    local deflectingR = {}
    plrsR.PlayerRemoving:Connect(function(p) deflectingR[p] = nil end)

    local function updateDeflectionR()
        if not FC or not FC.Objects then return end
        for _, fo in FC.Objects do
            local player = fo.Player
            if not player then continue end
            if not fo.Entity or not fo.Entity:IsAlive() or fo:Get("IsSpectating") then
                deflectingR[player] = false; continue
            end
            local eq = fo.EquippedItem
            local isKatana = eq and eq.ViewModel and eq.ViewModel.Name == "Katana"
            local isDef = false
            if isKatana then
                isDef = (eq._attack_cooldown and eq._attack_cooldown > tick()) or false
            end
            deflectingR[player] = isDef
        end
    end

    local function isEnemyR(player)
        if player == lplrR then return false end
        local duel = SC.CurrentDuelSubject
        local ld = duel and duel:GetDueler(lplrR)
        local lt = ld and ld:Get("TeamID") or nil
        if lt and duel and duel.Duelers then
            for _, d in duel.Duelers do
                if d.Player == player then return d:Get("TeamID") ~= lt end
            end
        end
        local pT = player:GetAttribute("TeamID"); local lT = lplrR:GetAttribute("TeamID")
        if pT and lT then return pT ~= lT end
        return true
    end

    local function pickTargetR()
        local char = lplrR.Character
        if not char then return nil, nil, nil end
        local myRoot = char:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil, nil, nil end
        local bestPlayer, bestRoot, bestHead = nil, nil, nil
        local bestScore = math.huge
        for _, player in plrsR:GetPlayers() do
            if not isEnemyR(player) then continue end
            local pChar = player.Character
            if not pChar then continue end
            if pChar:FindFirstChildOfClass("ForceField") then continue end
            local pH = pChar:FindFirstChildWhichIsA("Humanoid")
            if not pH or pH.Health <= 0 then continue end
            local pRoot = pChar:FindFirstChild("HumanoidRootPart")
            local pHead = pChar:FindFirstChild("Head")
            if not (pRoot and pHead) then continue end
            local dist = (myRoot.Position - pRoot.Position).Magnitude
            if dist > RageConfig.MaxDist then continue end
            local score = dist
            if deflectingR[player] then score += 1000 end
            if RageConfig.LowestHealth then score += pH.Health * 2 end
            if score < bestScore then
                bestScore = score
                bestPlayer, bestRoot, bestHead = player, pRoot, pHead
            end
        end
        return bestPlayer, bestRoot, bestHead
    end

    local function hasKnifeVM(targetPlayer)
        if not targetPlayer then return false end
        local vms = wsR:FindFirstChild("ViewModels")
        if not vms then return false end
        for _, model in vms:GetChildren() do
            if model:IsA("Model") and model.Name:find(targetPlayer.Name, 1, true) and model.Name:find("Knife", 1, true) then
                return true
            end
        end
        return false
    end

    local restoreBoundR = false
    local function applyDesyncR(desyncCF)
        local myRoot = lplrR.Character and lplrR.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        local oldCF, oldVel, oldRV = myRoot.CFrame, myRoot.Velocity, myRoot.RotVelocity
        myRoot.CFrame = desyncCF
        if restoreBoundR then return end
        restoreBoundR = true
        runSR:BindToRenderStep("__eclipseRestore", 101, function()
            if myRoot then
                myRoot.CFrame = oldCF
                myRoot.Velocity = oldVel
                myRoot.RotVelocity = oldRV
            end
            runSR:UnbindFromRenderStep("__eclipseRestore")
            restoreBoundR = false
        end)
    end

    runSR.Heartbeat:Connect(function()
        updateDeflectionR()
        if not T("RagebotEnabled") then return end

        local targetPlayer, targetRoot, targetHead = pickTargetR()
        local desyncCF = nil

        local localFighter = FC.LocalFighter
        local item  = localFighter and localFighter.EquippedItem
        local info  = item and rawget(item, "Info")
        local data  = item and rawget(item, "Data")
        local reloading = (info and info.Type == "Gun" and data and data.Ammo <= 0)

        if reloading then
            local myRoot = lplrR.Character and lplrR.Character:FindFirstChild("HumanoidRootPart")
            if myRoot then
                myRoot.CFrame = CFrame.new(myRoot.Position) * (myRoot.CFrame - myRoot.CFrame.Position)
            end
            desyncCF = nil
        elseif targetRoot and targetHead then
            local dm = O("RagebotWeapon") == "Melee" and "KnifeAware" or "KnifeAware"
            if hasKnifeVM(targetPlayer) then
                desyncCF = CFrame.lookAt((targetRoot.CFrame * CFrame.new(0, RageConfig.KnifeHoverHeight, RageConfig.KnifeBehindOffset)).Position, targetHead.Position)
            else
                desyncCF = CFrame.lookAt((targetRoot.CFrame * CFrame.new(0, 3, -20)).Position, targetHead.Position)
            end
        end

        if desyncCF then applyDesyncR(desyncCF) end

        if not (targetPlayer and targetHead and targetRoot) then return end
        if deflectingR[targetPlayer] then return end
        if not lplrR.Character or not lplrR.Character:FindFirstChild("HumanoidRootPart") then return end
        if not FC.LocalFighter then return end
        if reloading then return end
        if not item then return end

        local rate = RageConfig.FireRate
        if tick() - lastFireR < rate then return end
        lastFireR = tick()

        local originPos = targetRoot.Position
        local aimCF = CFrame.lookAt(originPos, targetHead.Position)

        local cameradata = {}
        cameradata[utf8.char(1)] = {
            [utf8.char(0)] = util:EncodeCFrame(aimCF),
            [utf8.char(1)] = util:EncodeCFrame(targetHead.CFrame),
            [utf8.char(2)] = targetHead,
            [utf8.char(3)] = util:EncodeCFrame(CFrame.new(0,0,0))
        }

        if info and info.Type == "Melee" then
            local anim = enumLib:ToEnum("AttackAnimation1")
            if anim then
                repSR.Remotes.Replication.Fighter.UseItem:FireServer(
                    item:Get("ObjectID"),
                    enumLib:ToEnum("StartShooting"),
                    { [utf8.char(1)] = cameradata[utf8.char(1)], [utf8.char(2)] = anim },
                    nil
                )
                return
            end
        end

        repSR.Remotes.Replication.Fighter.UseItem:FireServer(
            item:Get("ObjectID"),
            enumLib:ToEnum("StartShooting"),
            cameradata,
            nil
        )
    end)

    -- FFA auto-respawn + drop vacuum
    local ffa = { AutoRespawn = true, DropVacuum = true }
    local visitedDrops = {}
    local function forceRespawn()
        pcall(function()
            local rf = repSR:FindFirstChild("Remotes")
            if not rf then return end
            local df = rf:FindFirstChild("Duels")
            if not df then return end
            local rr = df:FindFirstChild("RespawnNow")
            if rr and rr:IsA("RemoteEvent") then rr:FireServer() end
        end)
    end
    lplrR.CharacterAdded:Connect(function(newChar)
        local hum = newChar:WaitForChild("Humanoid")
        hum.Died:Connect(function()
            if not ffa.AutoRespawn then return end
            task.spawn(function()
                while ffa.AutoRespawn do
                    local c = lplrR.Character
                    if c and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0 then break end
                    forceRespawn()
                    task.wait(0.1)
                end
            end)
        end)
    end)
    local function handleDrop(obj)
        if not ffa.DropVacuum then return end
        if not (obj:IsA("BasePart") and obj.Name == "_drop") then return end
        if visitedDrops[obj] then return end
        visitedDrops[obj] = true
        task.wait()
        pcall(function()
            local char = lplrR.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if obj:IsDescendantOf(wsR) and hrp then
                obj.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
                obj.Anchored = true; obj.CanCollide = false; obj.Transparency = 1
                for _, child in obj:GetDescendants() do
                    if child:IsA("BasePart") or child:IsA("UnionOperation") or child:IsA("MeshPart") then
                        pcall(function() child.Transparency = 1; child.CanCollide = false end)
                    elseif child:IsA("BillboardGui") or child:IsA("SurfaceGui") or child:IsA("ParticleEmitter") then
                        pcall(function() child.Enabled = false end)
                    end
                end
            end
        end)
    end
    for _, obj in ipairs(wsR:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "_drop" then visitedDrops[obj] = true end
    end
    wsR.DescendantAdded:Connect(handleDrop)

    ::rageskip::
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ── ANTI-AIM (exact logic from Anti_aim.txt, no Rayfield, wired to LinoriaLib) ─
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local ok, err = pcall(function()
        local function protect(service)
            if type(cloneref) ~= "function" then return service end
            local ok2, clone = pcall(cloneref, service)
            return (ok2 and typeof(clone) == "Instance") and clone or service
        end
        local ServicesAA = setmetatable({}, {__index = function(_, name)
            return protect(game:GetService(name))
        end})

        local function find(root, names)
            local cur = root
            for _, name in ipairs(names) do
                local found = cur:FindFirstChild(name)
                assert(found, name .. " missing")
                cur = found
            end
            return cur
        end
        local function load(root, names)
            local mod = find(root, names)
            assert(mod:IsA("ModuleScript"), "not a module")
            return require(mod)
        end
        local function playerScripts()
            return find(LP, {"PlayerScripts"})
        end
        local function sharedMod(name) return load(RepS, {"Modules", name}) end
        local function controllerMod(name) return load(playerScripts(), {"Controllers", name}) end

        local function disguise(hook, original)
            pcall(setfenv, hook, getfenv(original))
            local ed = debug
            if type(ed.setinfo) == "function" and type(ed.getinfo) == "function" then
                ed.setinfo(hook, ed.getinfo(original))
            end
        end

        local executor = {
            hookfunction = hookfunction,
            getupvalues  = debug.getupvalues,
            setupvalue   = debug.setupvalue,
            getconstants = debug.getconstants,
            setconstant  = debug.setconstant,
            disguise     = disguise,
            cclosure     = (type(newcclosure) == "function") and newcclosure or function(f) return f end,
        }

        local function hook(access, target, make)
            local original
            local hooked = make(function(...) return original(...) end)
            access.disguise(hooked, target)
            original = access.hookfunction(target, hooked)
            return original
        end

        local function swapUpvalue(access, closure, current, replacement, what)
            local sls = {}
            for index, value in access.getupvalues(closure) do
                if value == current then table.insert(sls, index) end
            end
            assert(#sls > 0, "Code no longer holds " .. tostring(what))
            for _, index in sls do access.setupvalue(closure, index, replacement) end
        end

        local MAX_CODE_POINT = 0x10ffff
        local TAU = 2 * math.pi
        local function codePoint(value)
            local point = math.floor(value)
            if point >= 0xd800 and point < 0xe000 then point = 0xe000 end
            return utf8.char(math.clamp(point, 0, MAX_CODE_POINT))
        end
        local function turn(angle)
            return utf8.char(math.clamp(math.floor(angle % TAU / math.pi / 2 * 256 + 0.5), 0, 255))
        end

        local Pose = {}
        Pose.PITCHES = { "disabled","offset","random","look up","look down","custom","extended custom","extended random" }
        Pose.YAWS    = { "disabled","offset","backwards","random","custom" }

        function Pose.bend(settings, pitch, yaw, random)
            local mode = settings.pitch
            if mode == "extended custom" then
                return { kind = "encoded", data = codePoint((settings.customPitch + 180) / 360 * MAX_CODE_POINT) }
            elseif mode == "extended random" then
                return { kind = "encoded", data = codePoint(random(0, MAX_CODE_POINT)) }
            elseif mode == "offset"    then pitch = pitch + settings.customPitch
            elseif mode == "random"    then pitch = random(0, 360)
            elseif mode == "look up"   then pitch = 179
            elseif mode == "look down" then pitch = 180
            elseif mode == "custom"    then pitch = settings.customPitch end
            mode = settings.yaw
            if mode == "offset"    then yaw = yaw + settings.customYaw
            elseif mode == "backwards" then yaw = yaw + 180
            elseif mode == "random"    then yaw = random(0, 360)
            elseif mode == "custom"    then yaw = settings.customYaw end
            return { kind = "angles", pitch = pitch, yaw = yaw }
        end
        function Pose.encode(pitch, yaw) return turn(pitch) .. turn(yaw) end

        local ENCODER_STATE = nil
        local function resolveEncoder()
            local loop = controllerMod("FighterController")._CameraReplicationLoop
            assert(type(loop) == "function", "FighterController._CameraReplicationLoop unavailable")
            return { loop = loop, utility = sharedMod("Utility"), random = math.random, access = executor }
        end
        local function createEncoder()
            if ENCODER_STATE then return ENCODER_STATE end
            local deps    = resolveEncoder()
            local utility = deps.utility
            local encode  = utility.EncodeCameraRotation
            assert(type(encode) == "function", "Utility.EncodeCameraRotation unavailable")
            local state   = { bend = nil }
            local standIn = setmetatable({}, {__index = utility})
            standIn.EncodeCameraRotation = function(_, rotation, ...)
                local settings = state.bend
                if not settings then return encode(utility, rotation, ...) end
                local pose = Pose.bend(settings(), math.deg(rotation.X), math.deg(rotation.Y), deps.random)
                if pose.kind == "encoded" then return pose.data end
                return encode(utility, Vector2.new(math.rad(pose.pitch), math.rad(pose.yaw)), ...)
            end
            deps.access.disguise(standIn.EncodeCameraRotation, encode)
            swapUpvalue(deps.access, deps.loop, utility, standIn, "Utility in camera replication loop")
            ENCODER_STATE = state
            return state
        end
        local function EncoderUse(bend)
            local encoder = createEncoder()
            if bend then encoder.bend = bend end
        end

        -- Settings driven by LinoriaLib options
        local function getAASettings()
            return {
                pitch       = O("AntiAimPitch") or "disabled",
                customPitch = O("AntiAimPitchAngle") or 0,
                yaw         = O("AntiAimYaw") or "disabled",
                customYaw   = O("AntiAimYawAngle") or 0,
            }
        end

        -- guard decoding
        local function guardDecoding()
            local utility = sharedMod("Utility")
            local target = utility.DecodeCameraRotationBulk
            assert(type(target) == "function", "Utility.DecodeCameraRotationBulk unavailable")
            hook(executor, target, function(original)
                return function(...)
                    local results = table.pack(pcall(original, ...))
                    if results[1] then return table.unpack(results, 2, results.n) end
                    return {}
                end
            end)
        end

        -- Underground desync
        local DESYNC, desyncMembers = nil, {}
        local function resolveDesync()
            local index = assert(getrawmetatable(game), "Instance metatable unavailable").__index
            local members = {}
            local character, root, real = nil, nil, nil
            local function track(model)
                character, root, real = model, nil, nil
                local part = model:WaitForChild("HumanoidRootPart", 10)
                if character == model and part and part:IsA("BasePart") then root = part end
            end
            if LP.Character then task.spawn(track, LP.Character) end
            LP.CharacterAdded:Connect(track)
            LP.CharacterRemoving:Connect(function(model)
                if model == character then character, root, real = nil, nil, nil end
            end)
            ServicesAA.RunService:BindToRenderStep("AntiAim.DesyncRestore", Enum.RenderPriority.Camera.Value - 1, function()
                local part, cframe = root, real
                if part and cframe then part.CFrame = cframe end
            end)
            ServicesAA.RunService.Heartbeat:Connect(function(dt)
                local part = root
                if not part then real = nil; return end
                local cframe = index(part, "CFrame")
                real = cframe
                for _, member in members do
                    local ok2, server = pcall(member.propose, cframe, part, dt)
                    if not ok2 then
                        part.CFrame = cframe
                    elseif server then
                        part.CFrame = server
                        return
                    else
                        cframe = index(part, "CFrame")
                        real = cframe
                    end
                end
                real = nil
            end)
            return { members = members }
        end
        local function DesyncJoin(order, propose)
            if not DESYNC then DESYNC = resolveDesync(); desyncMembers = DESYNC.members end
            local member = { order = order, propose = propose }
            table.insert(desyncMembers, member)
            table.sort(desyncMembers, function(a, b) return a.order < b.order end)
        end

        local undergroundDeps, undergroundActive = nil, false
        local function resolveUnderground()
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            local down = Vector3.new(0, -500, 0)
            local function floor(from, character)
                params.FilterDescendantsInstances = character and {character} or {}
                local hit = ServicesAA.Workspace:Raycast(from, down, params)
                return hit and hit.Position.Y or nil
            end
            return { floor = floor }
        end
        local DEPTH = 5
        local function startUnderground()
            if undergroundDeps then return end
            undergroundDeps = resolveUnderground()
            local drop = Vector3.new(0, DEPTH, 0)
            local flat = CFrame.Angles(math.rad(90), 0, 0)
            DesyncJoin(2, function(real, rootPart)
                if not undergroundActive then return nil end
                local position = real.Position
                local f = undergroundDeps.floor(position, rootPart.Parent)
                local hidden = f and Vector3.new(position.X, f - DEPTH, position.Z) or (position - drop)
                return CFrame.new(hidden) * flat
            end)
        end

        -- Wire underground toggle
        Toggles.AntiAimUnderground:OnChanged(function()
            undergroundActive = T("AntiAimUnderground")
            if undergroundActive then startUnderground() end
        end)

        pcall(guardDecoding)
        EncoderUse(getAASettings)
    end)
    if not ok then warn("[Eclipse Anti-Aim] " .. tostring(err)) end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ── SKIN CHANGER (exact — untouched from skin_changer.txt) ────────────────────
-- ═══════════════════════════════════════════════════════════════════════════════
do
    if getgenv().RivalsCosmeticsCleanup then
        pcall(getgenv().RivalsCosmeticsCleanup)
    end

    local rs   = game:GetService("ReplicatedStorage")
    local http = game:GetService("HttpService")
    local plr  = game:GetService("Players").LocalPlayer

    local function waitFor(getter)
        local deadline = os.clock() + 90
        while os.clock() < deadline do
            local ok, value = pcall(getter)
            if ok and value then return value end
            task.wait(0.5)
        end
    end

    local scripts       = plr:WaitForChild("PlayerScripts")
    local lib           = waitFor(function() return require(rs.Modules.CosmeticLibrary) end)
    local replicated    = waitFor(function() return require(rs.Modules.ReplicatedClass) end)
    local vmClass       = waitFor(function() return require(scripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem.ClientViewModel) end)
    local pdc           = waitFor(function() return require(scripts.Controllers.PlayerDataController) end)
    local viewModels    = waitFor(function() return scripts.Assets.ViewModels end)
    local classes       = waitFor(function() return scripts.Modules.ViewModels end)
    local equipRemote   = waitFor(function() return rs.Remotes.Data.EquipCosmetic end)

    if not (lib and replicated and vmClass and pdc and viewModels and classes and equipRemote) then
        warn("Eclipse SkinChanger: game modules not ready")
        goto skinskip
    end

    local folder = "Eclipse"
    local file   = folder .. "/Rivals Cosmetics.json"
    local slots  = { Skin = true, Wrap = true, Charm = true, Finisher = true }
    local added, saved, alive = {}, {}, true
    local swaps, swapping = {}, nil
    local moduleCache, modelCache = {}, {}
    local oldGet   = replicated.Get
    local oldVmGet = rawget(vmClass, "Get")

    local function get(key)
        local ok, v = pcall(pdc.CurrentData.Get, pdc.CurrentData, key)
        return ok and v or nil
    end
    waitFor(function() return get("CosmeticInventory") and get("WeaponInventory") end)

    local function flush()
        pcall(function()
            if not isfolder(folder) then makefolder(folder) end
            writefile(file, http:JSONEncode(saved))
        end)
    end
    local function findWeapon(weapon)
        local list = get("WeaponInventory")
        if not list then return end
        for _, w in pairs(list) do if w.Name == weapon then return w end end
    end

    local inv = get("CosmeticInventory")
    for name in pairs(lib.Cosmetics) do
        if inv and inv[name] == nil then inv[name] = true; added[name] = true end
    end
    pcall(function()
        if isfile(file) then saved = http:JSONDecode(readfile(file)) end
    end)
    for weapon, picks in pairs(saved) do
        local w = findWeapon(weapon)
        if w then
            for slot, entry in pairs(picks) do
                if slots[slot] and lib.Cosmetics[entry.Name] then w[slot] = entry end
            end
        end
    end

    local function baseOf(name)
        local c = lib.Cosmetics[name]
        if c and c.Type == "Skin" and c.ItemName then return c.ItemName end
        return name
    end
    local function moduleOf(name)
        local cached = moduleCache[name]
        if cached == nil then
            local found = classes:FindFirstChild(name, true)
            cached = found and found:IsA("ModuleScript") and found or false
            moduleCache[name] = cached
        end
        return cached or nil
    end
    local function hasModel(name)
        local cached = modelCache[name]
        if cached == nil then cached = viewModels:FindFirstChild(name, true) ~= nil; modelCache[name] = cached end
        return cached
    end

    local function installSwap(weapon)
        if swaps[weapon] then return end
        local defaultModule = moduleOf(weapon)
        if not defaultModule then return end
        local ok, class = pcall(require, defaultModule)
        if not ok or type(class) ~= "table" or type(rawget(class, "new")) ~= "function" then return end
        local origNew = class.new
        swaps[weapon] = { class = class, origNew = origNew }
        class.new = function(...)
            local picks = alive and saved[weapon]
            local skin = picks and picks.Skin
            local skinModule = skin and moduleOf(skin.Name)
            if skinModule and not swapping and hasModel(skin.Name)
                and (skinModule.Parent == defaultModule.Parent or skinModule.Parent == defaultModule) then
                local loaded, skinClass = pcall(require, skinModule)
                if loaded and type(skinClass) == "table" and type(skinClass.new) == "function" then
                    swapping = { weapon = weapon, skin = skin.Name }
                    local built, object = pcall(skinClass.new, ...)
                    swapping = nil
                    if built then return object end
                end
            end
            return origNew(...)
        end
    end

    for weapon, picks in pairs(saved) do if picks.Skin then installSwap(weapon) end end

    replicated.Get = function(self, key)
        if alive and slots[key] then
            local data  = rawget(self, "Data")
            local picks = data and saved[baseOf(data.Name)]
            local entry = picks and picks[key]
            if entry ~= nil then return entry end
        end
        return oldGet(self, key)
    end
    vmClass.Get = function(self, key)
        if alive and key == "Name" then
            local data = rawget(self, "Data")
            if data then
                local weapon = baseOf(data.Name)
                if swapping and swapping.weapon == weapon then return swapping.skin end
                local picks = saved[weapon]
                local skin  = picks and picks.Skin
                if skin and not moduleOf(skin.Name) and hasModel(skin.Name)
                    and (data.Name == weapon or not moduleOf(data.Name)) then
                    return skin.Name
                end
            end
        end
        return (oldVmGet or replicated.Get)(self, key)
    end

    local function refreshHeld(weapon, slot)
        if slot ~= "Wrap" and slot ~= "Charm" then return end
        for _, obj in ipairs(getgc(true)) do
            if type(obj) == "table" and type(rawget(obj, "Data")) == "table"
                and rawget(obj, "ClientItem") and rawget(obj, "Model")
                and baseOf(obj.Data.Name) == weapon then
                local entry = saved[weapon] and saved[weapon][slot]
                obj.Data[slot] = entry
                local signal = obj._value_changed_events and obj._value_changed_events[slot]
                if signal then pcall(signal.Fire, signal, entry) end
                if slot == "Wrap" and obj._UpdateWrap then pcall(obj._UpdateWrap, obj) end
            end
        end
    end

    local function equip(weapon, slot, name, extra)
        local w = findWeapon(weapon)
        if not w then return false end
        local entry
        if name then entry = { Name = name, Inverted = slot == "Wrap" and extra and extra.IsInverted or nil } end
        w[slot] = entry
        saved[weapon] = saved[weapon] or {}
        saved[weapon][slot] = entry
        if slot == "Skin" and entry then installSwap(weapon) end
        flush()
        refreshHeld(weapon, slot)
        return true
    end

    getgenv().RivalsEquipHandler = function(self, ...)
        if not alive or self ~= equipRemote then return false end
        local weapon, slot, name, extra = ...
        return slots[slot] and (name == nil or lib.Cosmetics[name]) and equip(weapon, slot, name, extra) or false
    end

    if not getgenv().RivalsNamecallOriginal then
        getgenv().RivalsNamecallOriginal = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local handler = getgenv().RivalsEquipHandler
            if handler and not checkcaller() and getnamecallmethod() == "FireServer" and handler(self, ...) then return end
            return getgenv().RivalsNamecallOriginal(self, ...)
        end))
    end

    getgenv().RivalsCosmeticsCleanup = function()
        alive = false
        getgenv().RivalsEquipHandler = nil
        replicated.Get = oldGet
        vmClass.Get    = oldVmGet
        for _, swap in pairs(swaps) do swap.class.new = swap.origNew end
        local cur = get("CosmeticInventory")
        if cur then for name in pairs(added) do cur[name] = nil end end
        getgenv().RivalsCosmeticsCleanup = nil
    end

    ::skinskip::
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ── LOADED ────────────────────────────────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════════════════════
Library:Notify("Eclipse loaded · Mobile Edition", 3)
print("[Eclipse] Loaded — mobile only build")
