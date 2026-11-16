--[[
    adyans personal ragebot — Obsidian UI
    Base: Ragebot OPEN-SOURCE (Rivals UseItem / EncodeCFrame)
    + Anti-knife (Elisium-style height stick)
    + Void spam (Elisium-style hide/attack phases)
    + Shotgun ammo gate (pause fire until ~7 shells)
    + Touch-friendly menu toggle
    + Snowfall visual effect
    + Rage modes: Default + Knife (backstab stick + RMB spam)\n    + Jarvis Chaos + Alternative Chaos
    + Always face target when ragebot is enabled
]]

local cloneref = cloneref or function(x) return x end

local Players           = cloneref(game:GetService("Players"))
local RunService        = cloneref(game:GetService("RunService"))
local UserInputService  = cloneref(game:GetService("UserInputService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Workspace         = cloneref(game:GetService("Workspace"))
local TweenService      = cloneref(game:GetService("TweenService"))
local GuiService        = cloneref(game:GetService("GuiService"))

local lp  = Players.LocalPlayer
local cam = Workspace.CurrentCamera

-- ── UI ───────────────────────────────────────────────────────────────────────
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/visnoukkk/ObsidianLib/refs/heads/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
    Title            = "adyans personal ragebot",
    Footer           = "adyans personal ragebot + jarvis + snowfall",
    NotifySide       = "Right",
    ShowCustomCursor = false,
})

local Tabs = {
    Rage     = Window:AddTab("Rage", "crosshair"),
    Settings = Window:AddTab("Settings", "settings"),
}

-- ── Config ───────────────────────────────────────────────────────────────────
getgenv().Config = getgenv().Config or {}
local Config = getgenv().Config

Config.Enabled          = Config.Enabled == true
Config.RageMode         = Config.RageMode or "Default"  -- "Default" | "Knife"
Config.FireRate         = tonumber(Config.FireRate) or 0.0005
Config.WeaponSlot       = Config.WeaponSlot or "Melee" -- Primary / Secondary / Melee
Config.KnifeBackDist    = tonumber(Config.KnifeBackDist) or 1.15  -- stick tightly behind
Config.KnifeClickRate   = tonumber(Config.KnifeClickRate) or 0.04
Config.KnifeHeight      = tonumber(Config.KnifeHeight) or 0
Config.MaxDistance      = tonumber(Config.MaxDistance) or 500
Config.TeamCheck        = Config.TeamCheck ~= false
Config.AntiKnife        = Config.AntiKnife ~= false
Config.AntiKnifeHeight  = tonumber(Config.AntiKnifeHeight) or 6
Config.StickHeight      = tonumber(Config.StickHeight) or 1
Config.StickDepth       = tonumber(Config.StickDepth) or 2
Config.VoidSpam         = Config.VoidSpam == true
Config.VoidHideSec      = tonumber(Config.VoidHideSec) or 0.35
Config.VoidAttackSec    = tonumber(Config.VoidAttackSec) or 0.45
Config.VoidY            = tonumber(Config.VoidY) or -120
Config.ShotgunGate      = Config.ShotgunGate ~= false
Config.ShotgunResumeAt  = tonumber(Config.ShotgunResumeAt) or 7
Config.AutoEquip        = Config.AutoEquip ~= false
Config.DeflectSkip      = Config.DeflectSkip ~= false
Config.Jarvis           = Config.Jarvis == true
Config.JarvisVoidY      = tonumber(Config.JarvisVoidY) or -400
Config.JarvisExtremeY   = tonumber(Config.JarvisExtremeY) or 800
Config.JarvisIdleSec    = tonumber(Config.JarvisIdleSec) or 0.55
Config.JarvisAboveH     = tonumber(Config.JarvisAboveH) or 12
Config.FaceTarget       = Config.FaceTarget ~= false  -- always face target when rage on

local slots = { Primary = 1, Secondary = 2, Melee = 3 }

local function getSlotNumber()
    return slots[Config.WeaponSlot] or 3
end

-- ── Rivals modules ───────────────────────────────────────────────────────────
local util, enum, FighterController, SpectateController

local function tryModules()
    pcall(function()
        util = require(ReplicatedStorage.Modules.Utility)
        enum = require(ReplicatedStorage.Modules.EnumLibrary)
        FighterController = require(lp.PlayerScripts.Controllers.FighterController)
        SpectateController = require(lp.PlayerScripts.Controllers:WaitForChild("SpectateController"))
    end)
end

tryModules()
task.spawn(function()
    for _ = 1, 30 do
        if util and enum and FighterController then break end
        task.wait(0.5)
        tryModules()
    end
end)

-- ── Auto equip ───────────────────────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(1)
        if not Config.AutoEquip or not Config.Enabled then continue end
        local lf = FighterController and FighterController.LocalFighter
        if lf then
            local slot = (Config.RageMode == "Knife") and 3 or getSlotNumber()
            pcall(function() lf:EquipItem(slot) end)
        end
    end
end)

-- ── Deflection tracking (katana) ─────────────────────────────────────────────
local deflecting = {}
Players.PlayerRemoving:Connect(function(player)
    deflecting[player] = nil
end)

local function updateDeflection()
    if not FighterController or not FighterController.Objects then return end
    for _, fighterObj in pairs(FighterController.Objects) do
        local player = fighterObj.Player
        if not player then continue end
        if not fighterObj.Entity or not fighterObj.Entity:IsAlive() or fighterObj:Get("IsSpectating") then
            deflecting[player] = false
            continue
        end
        local equipped = fighterObj.EquippedItem
        local isKatana = equipped and equipped.ViewModel and equipped.ViewModel.Name == "Katana"
        local isDeflecting = false
        if isKatana then
            isDeflecting = (equipped._attack_cooldown and equipped._attack_cooldown > tick()) or false
        end
        deflecting[player] = isDeflecting
    end
end

-- ── Target helpers ───────────────────────────────────────────────────────────
local function isEnemy(player)
    if player == lp then return false end
    if not Config.TeamCheck then return true end

    local ok, result = pcall(function()
        if SpectateController and SpectateController.CurrentDuelSubject then
            local duel = SpectateController.CurrentDuelSubject
            local localDueler = duel and duel:GetDueler(lp)
            local localTeam = localDueler and localDueler:Get("TeamID") or nil
            if localTeam and duel.Duelers then
                for _, dueler in pairs(duel.Duelers) do
                    if dueler.Player == player then
                        return dueler:Get("TeamID") ~= localTeam
                    end
                end
            end
        end
        local pTeam = player:GetAttribute("TeamID")
        local lTeam = lp:GetAttribute("TeamID")
        if pTeam and lTeam then
            return pTeam ~= lTeam
        end
        if lp.Team and player.Team then
            return lp.Team ~= player.Team
        end
        return true
    end)
    if ok then return result end
    return true
end

local function getClosestTarget()
    local char = lp.Character
    if not char then return nil, nil, nil end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil, nil, nil end

    local closestPlayer, closestRoot, closestHead
    local closestDist = tonumber(Config.MaxDistance) or 500

    for _, player in ipairs(Players:GetPlayers()) do
        if not isEnemy(player) then continue end
        local pChar = player.Character
        if not pChar then continue end
        local pRoot = pChar:FindFirstChild("HumanoidRootPart")
        local pHead = pChar:FindFirstChild("Head")
        local pHum  = pChar:FindFirstChildWhichIsA("Humanoid")
        if not (pRoot and pHead and pHum and pHum.Health > 0) then continue end
        local dist = (myRoot.Position - pRoot.Position).Magnitude
        if dist < closestDist then
            closestDist = dist
            closestPlayer, closestRoot, closestHead = player, pRoot, pHead
        end
    end
    return closestPlayer, closestRoot, closestHead
end

local function hasKnifeViewModel(targetPlayer)
    if not targetPlayer then return false end
    local viewModels = Workspace:FindFirstChild("ViewModels")
    if not viewModels then return false end
    local targetName = targetPlayer.Name
    for _, model in ipairs(viewModels:GetChildren()) do
        if model:IsA("Model")
            and string.find(model.Name, targetName, 1, true)
            and string.find(model.Name, "Knife", 1, true) then
            return true
        end
    end
    -- also check equipped tool name
    local ch = targetPlayer.Character
    if ch then
        local tool = ch:FindFirstChildOfClass("Tool")
        if tool then
            local n = string.lower(tool.Name)
            if n:find("knife", 1, true) or n:find("melee", 1, true) or n:find("katana", 1, true) then
                return true
            end
        end
    end
    return false
end


-- ── Jarvis mode state ────────────────────────────────────────────────────────
local jarvisState = {
    mode = "idle",          -- "idle" | "chaos" | "altchaos" | "antiknife" | "antibait"
    hiding = false,
    hideUntil = 0,
    lastTarget = nil,
    waitForIdle = false,
    waitForUnknife = false,
    -- hit-and-run attack window (chaos stays void-immune; only fires in short bursts)
    attackUntil = 0,
    attackShotsLeft = 0,
    nextAttackAfter = 0,
    -- Alternative Chaos
    altPhase = "wait_first",  -- "wait_first" | "attack" | "safety"
    altDeaths = 0,            -- deaths while normal chaos vs this fight
    altDamageHits = 0,        -- damage ticks while in chaos/altchaos
    altLastHp = nil,
    altSeenFirstShot = false,
    altSafetyNotified = false,
    altTargetName = nil,
    altLastDeath = 0,
}

-- Track opponent movement + shoot timing for chaos
local oppTrack = {} -- [player] = tracking table

local function trackOpponent(player, root, now)
    if not player or not root then return end
    local t = oppTrack[player]
    local pos = root.Position
    if not t then
        oppTrack[player] = {
            lastPos = pos,
            lastTime = now,
            jumpCount = 0,
            closeFrames = 0,
            lowVelFrames = 0,
            shootFrames = 0,
            lastShootTime = 0,
            prevCooldown = 0,
            prevAmmo = nil,
            prevShootingFlag = false,
            shotTimes = {},       -- ring of recent shot timestamps
            avgInterval = 0.28,   -- learned fire interval (seconds)
            samples = {},
        }
        return
    end
    local dt = now - (t.lastTime or now)
    if dt < 0.03 then return end

    local delta = (pos - t.lastPos).Magnitude
    local yDelta = math.abs(pos.Y - t.lastPos.Y)

    if delta > 25 or yDelta > 40 then
        t.jumpCount = (t.jumpCount or 0) + 1
    else
        t.jumpCount = math.max(0, (t.jumpCount or 0) - 0.2)
    end

    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if myRoot then
        local dist = (myRoot.Position - pos).Magnitude
        if dist < 8 then
            t.closeFrames = (t.closeFrames or 0) + 1
        else
            t.closeFrames = math.max(0, (t.closeFrames or 0) - 1)
        end
    end

    local vel = root.AssemblyLinearVelocity
    local speed = vel and vel.Magnitude or 0
    if speed < 1.5 then
        t.lowVelFrames = (t.lowVelFrames or 0) + 1
    else
        t.lowVelFrames = 0
    end

    t.lastPos = pos
    t.lastTime = now
    oppTrack[player] = t
end

local function recordShot(t, now)
    if not t then return end
    -- multi-pellet / burst debounce (shotguns register many hits at once)
    local debounce = t.isShotgun and 0.14 or 0.05
    if t.lastShootTime and (now - t.lastShootTime) < debounce then
        t.lastShootTime = now
        return
    end
    local prev = t.lastShootTime or 0
    t.lastShootTime = now
    t.shotTimes = t.shotTimes or {}
    table.insert(t.shotTimes, now)
    -- keep last 8 shots
    while #t.shotTimes > 8 do
        table.remove(t.shotTimes, 1)
    end
    -- learn interval from consecutive shots
    if prev > 0 and (now - prev) > 0.05 and (now - prev) < 1.5 then
        local interval = now - prev
        local times = t.shotTimes
        if #times >= 2 then
            local gaps = {}
            for i = 2, #times do
                local g = times[i] - times[i - 1]
                if g > 0.05 and g < 1.5 then
                    table.insert(gaps, g)
                end
            end
            if #gaps > 0 then
                table.sort(gaps)
                local mid = gaps[math.ceil(#gaps / 2)]
                -- smooth toward measured interval
                t.avgInterval = (t.avgInterval or mid) * 0.55 + mid * 0.45
            else
                t.avgInterval = (t.avgInterval or interval) * 0.6 + interval * 0.4
            end
        else
            t.avgInterval = (t.avgInterval or interval) * 0.6 + interval * 0.4
        end
        -- clamp learned interval to sane gun ranges
        if t.isShotgun then
            t.avgInterval = math.clamp(t.avgInterval, 0.40, 1.2)
        else
            t.avgInterval = math.clamp(t.avgInterval, 0.08, 0.9)
        end
    end
end

-- Adaptive void hold based on their fire rate (+ shotgun bias)
local function getAdaptiveHold(t)
    local interval = (t and t.avgInterval) or 0.28
    local shotgun = t and t.isShotgun
    if shotgun then
        -- shotguns: long gap between pumps/blasts — hold almost the full interval
        if interval < 0.45 then interval = 0.55 end  -- floor for SG if not learned yet
        local hold = interval * 1.05
        if hold < 0.50 then hold = 0.50 end
        if hold > 1.10 then hold = 1.10 end
        return hold
    end
    -- other guns: hide most of the gap, small attack window
    local hold = interval * 0.92
    if hold < 0.14 then hold = 0.14 end
    if hold > 0.85 then hold = 0.85 end
    return hold
end

local function isOpponentWeaponShotgun(player)
    local found = false
    pcall(function()
        if FighterController and FighterController.Objects then
            for _, fighterObj in pairs(FighterController.Objects) do
                if fighterObj.Player ~= player then continue end
                local equipped = fighterObj.EquippedItem
                if not equipped then continue end
                local name = ""
                pcall(function()
                    name = tostring(equipped.Name or equipped:Get("Name") or "")
                    if equipped.ViewModel then name = name .. " " .. tostring(equipped.ViewModel.Name) end
                end)
                name = string.lower(name)
                if name:find("shotgun", 1, true) or name:find("shot gun", 1, true)
                    or name:find("db", 1, true) or name:find("double", 1, true)
                    or name:find("pump", 1, true) or name:find("sawed", 1, true) then
                    found = true
                    break
                end
            end
        end
        if not found then
            local ch = player and player.Character
            local tool = ch and ch:FindFirstChildOfClass("Tool")
            if tool then
                local n = string.lower(tool.Name)
                if n:find("shotgun", 1, true) or n:find("shot gun", 1, true)
                    or n:find("db", 1, true) or n:find("double", 1, true)
                    or n:find("pump", 1, true) then
                    found = true
                end
            end
        end
    end)
    return found
end

local function isOpponentVoidingOrSticking(player, root)
    local t = oppTrack[player]
    if not t then return false end
    if (t.jumpCount or 0) >= 3 then return true end
    if (t.closeFrames or 0) >= 18 then return true end
    return false
end

local function isOpponentIdle(player, root)
    local t = oppTrack[player]
    if not t then return false end
    local vel = root.AssemblyLinearVelocity
    local speed = vel and vel.Magnitude or 99
    return speed < 2.5 and (t.jumpCount or 0) < 1.2 and (t.lowVelFrames or 0) >= 8
end

-- Detect opponent reloading (ammo was low/zero and climbing, reload flags, anim)
local function isOpponentReloading(player)
    if not player then return false end
    local t = oppTrack[player]
    local now = tick()
    local reloading = false

    pcall(function()
        if not FighterController or not FighterController.Objects then return end
        for _, fighterObj in pairs(FighterController.Objects) do
            if fighterObj.Player ~= player then continue end
            local equipped = fighterObj.EquippedItem
            if not equipped then continue end

            -- explicit reload flags
            local flag = false
            pcall(function()
                flag = equipped:Get("IsReloading") or equipped.IsReloading
                    or equipped._reloading or equipped.Reloading
                    or equipped:Get("Reloading")
            end)
            if flag then
                reloading = true
            end

            -- reload cooldown timestamp
            local rcd = nil
            pcall(function()
                rcd = equipped._reload_cooldown or equipped.ReloadCooldown
                    or equipped:Get("ReloadCooldown")
            end)
            if type(rcd) == "number" and rcd > now then
                reloading = true
            end

            local ammo = nil
            pcall(function()
                ammo = tonumber(equipped:Get("Ammo") or equipped.Ammo or equipped._ammo or equipped.Bullets)
            end)
            if ammo ~= nil and t then
                -- empty mag → treat as reload window until ammo recovers
                if ammo <= 0 then
                    reloading = true
                    t.reloadUntil = now + 1.2
                    t.wasEmpty = true
                elseif t.wasEmpty and ammo > 0 then
                    -- mag filled — short post-reload lag still dangerous to peek early
                    t.wasEmpty = false
                    t.reloadUntil = now + 0.25
                elseif t.prevAmmo ~= nil and ammo > t.prevAmmo then
                    -- ammo increased mid-fight = reload tick
                    reloading = true
                    t.reloadUntil = now + 0.45
                end
                t.prevAmmoReload = ammo
            end
        end
    end)

    -- sticky reload window
    if t and t.reloadUntil and now < t.reloadUntil then
        reloading = true
    end
    if reloading and t then
        t.lastReloadTime = now
        t.reloadFrames = (t.reloadFrames or 0) + 2
    elseif t then
        t.reloadFrames = math.max(0, (t.reloadFrames or 0) - 1)
        if (t.reloadFrames or 0) > 0 then
            reloading = true
        end
    end
    return reloading
end

-- Vulnerable = good moment to attack (idle, reloading is NOT vulnerable for us —
-- we void during reload; vulnerable means exposed movement / no pressure)
local function isOpponentVulnerable(player, root)
    if not player or not root then return false end
    if isOpponentReloading(player) then
        return false  -- we choose to void during reload, not peek
    end
    if isOpponentShooting(player, root) then
        return false
    end
    if isOpponentVoidingOrSticking(player, root) then
        return false
    end
    -- idle = vulnerable
    if isOpponentIdle(player, root) then
        return true
    end
    -- not aiming at us + not shooting recently
    local t = oppTrack[player]
    local now = tick()
    if t and t.lastShootTime and (now - t.lastShootTime) < 0.35 then
        return false
    end
    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if myRoot and root then
        local look = root.CFrame.LookVector
        local toMe = (myRoot.Position - root.Position)
        if toMe.Magnitude > 1 then
            local dot = look:Dot(toMe.Unit)
            -- looking away and not in shoot hold
            if dot < 0.15 and not isOpponentShooting(player, root) then
                return true
            end
        end
    end
    return false
end

-- Fast multi-signal shoot detection + adaptive post-shot hold
local function isOpponentShooting(player, root)
    if not player or not root then return false end
    local t = oppTrack[player]
    if not t then
        trackOpponent(player, root, tick())
        t = oppTrack[player]
    end
    local now = tick()
    local shotThisFrame = false

    -- mark shotgun early so hold/debounce adapt
    t.isShotgun = isOpponentWeaponShotgun(player)
    if t.isShotgun and (not t.avgInterval or t.avgInterval < 0.4) then
        t.avgInterval = t.avgInterval and math.max(t.avgInterval, 0.55) or 0.55
    end

    -- 1) FighterController: cooldown rising edge, IsShooting, ammo drop
    pcall(function()
        if not FighterController or not FighterController.Objects then return end
        for _, fighterObj in pairs(FighterController.Objects) do
            if fighterObj.Player ~= player then continue end
            local equipped = fighterObj.EquippedItem
            if not equipped then continue end

            local name = ""
            pcall(function()
                name = tostring(equipped.Name or equipped:Get("Name") or "")
                if equipped.ViewModel then name = name .. " " .. tostring(equipped.ViewModel.Name) end
            end)
            name = string.lower(name)
            local isMelee = name:find("knife", 1, true) or name:find("katana", 1, true)
                or name:find("melee", 1, true) or name:find("fist", 1, true)
            if isMelee then continue end

            -- cooldown value
            local cd = 0
            pcall(function()
                cd = tonumber(equipped._attack_cooldown or equipped._shoot_cooldown
                    or equipped.AttackCooldown or equipped:Get("AttackCooldown")) or 0
            end)
            -- rising / active cooldown = shot
            if cd > now then
                if (t.prevCooldown or 0) <= now then
                    shotThisFrame = true
                else
                    shotThisFrame = true -- still in active fire window
                end
            end
            t.prevCooldown = cd

            -- explicit shooting flag (edge + level)
            local flag = false
            pcall(function()
                flag = equipped:Get("IsShooting") or equipped.IsShooting or equipped._shooting or false
            end)
            if flag then
                shotThisFrame = true
            elseif t.prevShootingFlag and not flag then
                -- just stopped a burst — still count recent
                shotThisFrame = true
            end
            t.prevShootingFlag = flag and true or false

            -- ammo drop = definitive shot
            local ammo = nil
            pcall(function()
                ammo = tonumber(equipped:Get("Ammo") or equipped.Ammo or equipped._ammo or equipped.Bullets)
            end)
            if ammo ~= nil and t.prevAmmo ~= nil and ammo < t.prevAmmo then
                shotThisFrame = true
            end
            if ammo ~= nil then t.prevAmmo = ammo end
        end
    end)

    -- 2) Tool in character + muzzle / facing pressure (faster threshold)
    pcall(function()
        local ch = player.Character
        if not ch then return end
        local tool = ch:FindFirstChildOfClass("Tool")
        local n = tool and string.lower(tool.Name) or ""
        local isGun = tool and not (n:find("knife", 1, true) or n:find("katana", 1, true)
            or n:find("melee", 1, true) or n:find("fist", 1, true))
        if not isGun then return end

        local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        local theirHead = ch:FindFirstChild("Head")
        if not myRoot then return end

        local look = root.CFrame.LookVector
        if theirHead then look = theirHead.CFrame.LookVector end
        local toMe = myRoot.Position - root.Position
        local dist = toMe.Magnitude
        if dist < 0.5 then return end
        local dot = look:Dot(toMe.Unit)

        -- tighter + faster: if gun aimed near us, treat as pressure
        if dot > 0.42 and dist < 220 then
            -- micro-jitter on look or root often accompanies fire
            local lookDelta = 0
            if t.lastLook then
                lookDelta = (look - t.lastLook).Magnitude
            end
            t.lastLook = look
            if lookDelta > 0.04 or dot > 0.72 then
                shotThisFrame = true
            end
        else
            t.lastLook = look
        end
    end)

    -- 3) Our health just dropped → they landed a shot (force long hold on SG)
    pcall(function()
        local myHum = lp.Character and lp.Character:FindFirstChildWhichIsA("Humanoid")
        if not myHum then return end
        local hp = myHum.Health
        if t.prevMyHp and hp < t.prevMyHp - 0.5 then
            shotThisFrame = true
            recordShot(t, now)
            if t.isShotgun then
                -- got tagged by SG: extend hold past next expected blast
                t.lastShootTime = now
                t.avgInterval = math.max(t.avgInterval or 0.55, 0.65)
            end
        end
        t.prevMyHp = hp
    end)

    if shotThisFrame then
        recordShot(t, now)
        t.shootFrames = (t.shootFrames or 0) + 2
    else
        t.shootFrames = math.max(0, (t.shootFrames or 0) - 1)
    end

    -- Adaptive hold: hidden until their interval window passes
    local hold = getAdaptiveHold(t)
    if t.lastShootTime and (now - t.lastShootTime) < hold then
        return true
    end
    -- still actively shooting this frame
    if shotThisFrame or (t.shootFrames or 0) > 0 then
        return true
    end
    return false
end

-- Chaos should stay in void while opponent is dangerous (incl. reloading)
local function isChaosDangerous(player, root)
    if isOpponentVoidingOrSticking(player, root) then return true end
    if isOpponentShooting(player, root) then return true end
    if isOpponentReloading(player) then return true end  -- void spam during their reload
    return false
end

-- Only attack when idle or otherwise vulnerable — never during reload/shoot
local function isChaosSafeToAttack(player, root)
    if isOpponentReloading(player) then return false end
    if isOpponentShooting(player, root) then return false end
    if isOpponentVoidingOrSticking(player, root) then return false end
    if isOpponentIdle(player, root) then return true end
    if isOpponentVulnerable(player, root) then return true end
    return false
end

local function chaosStickOrigin(targetRoot, targetHead)
    local height = tonumber(Config.StickHeight) or 1
    local depth  = tonumber(Config.StickDepth) or 2
    local desyncPos = (targetRoot.CFrame * CFrame.new(0, height, depth)).Position
    return desyncPos, CFrame.lookAt(desyncPos, targetHead.Position)
end

-- How long / how many shots in one chaos attack burst
local function chaosBurstParams(player)
    local t = player and oppTrack[player]
    local shotgun = t and t.isShotgun
    if shotgun then
        -- one quick blast then immediately back to void
        return 0.07, 1, 0.35
    end
    local hold = getAdaptiveHold(t)
    -- short open window, then mandatory void cooldown before next burst
    local open = math.clamp(hold * 0.25, 0.05, 0.12)
    local gap  = math.clamp(hold * 0.55, 0.12, 0.40)
    return open, 3, gap
end

local function resetAltChaos(full)
    jarvisState.altPhase = "wait_first"
    jarvisState.altSeenFirstShot = false
    jarvisState.altSafetyNotified = false
    jarvisState.attackUntil = 0
    jarvisState.attackShotsLeft = 0
    if full then
        jarvisState.altDeaths = 0
        jarvisState.altDamageHits = 0
        jarvisState.altTargetName = nil
        jarvisState.altLastHp = nil
    end
end

local function promoteToAltChaos(reason)
    if jarvisState.mode == "altchaos" then return end
    jarvisState.mode = "altchaos"
    resetAltChaos(false)
    jarvisState.altPhase = "wait_first"
    jarvisState.altSeenFirstShot = false
    pcall(function()
        Library:Notify({
            Title = "Jarvis",
            Description = "Alternative Chaos: " .. (reason or "switching"),
            Time = 4,
        })
    end)
end

local function enterAltSafety()
    jarvisState.altPhase = "safety"
    jarvisState.hiding = true
    jarvisState.attackUntil = 0
    jarvisState.attackShotsLeft = 0
    if not jarvisState.altSafetyNotified then
        jarvisState.altSafetyNotified = true
        pcall(function()
            Library:Notify({
                Title = "Jarvis",
                Description = "opponent too strong going back to safety",
                Time = 5,
            })
        end)
    end
end

-- Track deaths / damage to decide when normal Chaos is failing
local function updateAltFailTracking(targetPlayer, now)
    local hum = lp.Character and lp.Character:FindFirstChildWhichIsA("Humanoid")
    if not hum then return end
    local hp = hum.Health
    local name = targetPlayer and targetPlayer.Name or nil

    if name and jarvisState.altTargetName and name ~= jarvisState.altTargetName then
        -- new opponent: soft reset fail counters
        jarvisState.altDeaths = 0
        jarvisState.altDamageHits = 0
        jarvisState.altSafetyNotified = false
        if jarvisState.mode == "altchaos" then
            resetAltChaos(false)
        end
    end
    if name then jarvisState.altTargetName = name end

    if jarvisState.altLastHp ~= nil and hp < jarvisState.altLastHp - 0.5 then
        if jarvisState.mode == "chaos" or jarvisState.mode == "altchaos" then
            jarvisState.altDamageHits = (jarvisState.altDamageHits or 0) + 1
        end
    end
    jarvisState.altLastHp = hp

    -- death edge
    if hp <= 0 and (now - (jarvisState.altLastDeath or 0)) > 1.5 then
        if jarvisState.mode == "chaos" or jarvisState.mode == "altchaos" then
            jarvisState.altLastDeath = now
            jarvisState.altDeaths = (jarvisState.altDeaths or 0) + 1
            if jarvisState.mode == "chaos" and jarvisState.altDeaths >= 1 then
                promoteToAltChaos("keep dying on normal Chaos")
            elseif jarvisState.mode == "chaos" and (jarvisState.altDamageHits or 0) >= 4 then
                promoteToAltChaos("taking too much damage")
            end
        end
    end

    -- promote on heavy damage without death (normal chaos failing)
    if jarvisState.mode == "chaos" and (jarvisState.altDamageHits or 0) >= 5 then
        promoteToAltChaos("taking too much damage")
    end
end

local function getOpponentAmmo(player)
    local ammo = nil
    pcall(function()
        if not FighterController or not FighterController.Objects then return end
        for _, fighterObj in pairs(FighterController.Objects) do
            if fighterObj.Player ~= player then continue end
            local equipped = fighterObj.EquippedItem
            if not equipped then continue end
            pcall(function()
                ammo = tonumber(equipped:Get("Ammo") or equipped.Ammo or equipped._ammo or equipped.Bullets)
            end)
            if ammo ~= nil then break end
        end
    end)
    return ammo
end

local function isOpponentRapidOrNoRecoilSG(player, root)
    local t = oppTrack[player]
    if not t then return false end
    -- shotgun that never idles + very short learned interval = rapid / no-recoil style
    if t.isShotgun and (t.avgInterval or 1) <= 0.35 then
        return true
    end
    if (t.avgInterval or 1) <= 0.12 and (t.shootFrames or 0) > 2 then
        return true
    end
    -- never idle while pressure
    if not isOpponentIdle(player, root) and (t.shootFrames or 0) > 0 and (t.avgInterval or 1) < 0.22 then
        return true
    end
    return false
end

local function runAltChaos(targetPlayer, targetRoot, targetHead, now)
    -- Always extreme void hide (meowwCL)
    jarvisState.hiding = true
    startChaosVoidPersist(targetRoot)
    local desyncCF = chaosVoidCF or makeJarvisVoidCF(targetRoot.Position)
    local shouldFire = false
    local fireOriginOverride = nil

    local shooting = isOpponentShooting(targetPlayer, targetRoot)
    local reloading = isOpponentReloading(targetPlayer)
    local ammo = getOpponentAmmo(targetPlayer)
    local rapid = isOpponentRapidOrNoRecoilSG(targetPlayer, targetRoot)
    local idle = isOpponentIdle(targetPlayer, targetRoot)
    local vulnerable = isOpponentVulnerable(targetPlayer, targetRoot)

    -- Escalate to safety if still getting wrecked in alt attack
    if jarvisState.altPhase == "attack" then
        if (jarvisState.altDamageHits or 0) >= 3 or rapid and (jarvisState.altDamageHits or 0) >= 2 then
            enterAltSafety()
        end
    end

    if jarvisState.altPhase == "safety" then
        -- remain in void until their bullets run out
        if ammo ~= nil and ammo <= 0 then
            jarvisState.altPhase = "attack"
            jarvisState.altSeenFirstShot = true
            jarvisState.altSafetyNotified = false
            pcall(function()
                Library:Notify({
                    Title = "Jarvis",
                    Description = "ammo empty — attacking",
                    Time = 3,
                })
            end)
        else
            shouldFire = false
            return desyncCF, shouldFire, fireOriginOverride
        end
    end

    if jarvisState.altPhase == "wait_first" then
        -- void hide until they fire the first shot
        if shooting or (jarvisState.altSeenFirstShot) then
            jarvisState.altSeenFirstShot = true
            jarvisState.altPhase = "attack"
            pcall(function()
                Library:Notify({
                    Title = "Jarvis",
                    Description = "first shot seen — attacking",
                    Time = 2,
                })
            end)
        else
            shouldFire = false
            return desyncCF, shouldFire, fireOriginOverride
        end
    end

    -- attack phase: void during reload/shoot; only burst when idle or vulnerable
    if jarvisState.altPhase == "attack" then
        local dangerous = shooting or reloading
        local inBurst = now < (jarvisState.attackUntil or 0)
        local canOpen = (idle or vulnerable) and not dangerous

        if dangerous and rapid then
            if (jarvisState.altDamageHits or 0) >= 1 then
                enterAltSafety()
                shouldFire = false
                return desyncCF, shouldFire, fireOriginOverride
            end
        end

        if reloading then
            -- void spam the whole reload — do not attack
            jarvisState.attackUntil = 0
            jarvisState.attackShotsLeft = 0
            jarvisState.nextAttackAfter = now + 0.05
            shouldFire = false
        elseif dangerous then
            jarvisState.attackUntil = 0
            jarvisState.attackShotsLeft = 0
            jarvisState.nextAttackAfter = now + 0.05
            shouldFire = false
        elseif inBurst and (jarvisState.attackShotsLeft or 0) > 0 and not reloading then
            local origin = select(1, chaosStickOrigin(targetRoot, targetHead))
            fireOriginOverride = origin
            shouldFire = true
        elseif canOpen and now >= (jarvisState.nextAttackAfter or 0) then
            local open, shots, gap = chaosBurstParams(targetPlayer)
            open = open + 0.03
            shots = shots + 1
            jarvisState.attackUntil = now + open
            jarvisState.attackShotsLeft = shots
            jarvisState.nextAttackAfter = now + open + gap
            fireOriginOverride = select(1, chaosStickOrigin(targetRoot, targetHead))
            shouldFire = true
        else
            shouldFire = false
        end
    end

    return desyncCF, shouldFire, fireOriginOverride
end


local function isOpponentUndergroundRooted(root)
    if not root then return false end
    local pos = root.Position
    local vel = root.AssemblyLinearVelocity
    local speed = vel and vel.Magnitude or 99
    -- roughly underground and not moving much
    return pos.Y < -15 and speed < 3
end

-- Extreme-coordinate void (meowwCL-style) used by Jarvis Chaos hide
local EXTREME_VOID_OFFSET = Vector3.new(249548593482502345, 32495872349574, 2394857239485792384)

local function makeJarvisVoidCF(awayFrom)
    -- Absolute extreme position (same idea as meowwCL community lua)
    -- Small jitter so the spot isn't 100% static every refresh
    local jx = (math.random() - 0.5) * 1e10
    local jy = (math.random() - 0.5) * 1e9
    local jz = (math.random() - 0.5) * 1e10
    local p = EXTREME_VOID_OFFSET + Vector3.new(jx, jy, jz)
    return CFrame.new(p)
end

-- Persistent chaos void: keep HRP at extreme coords while hiding (client visual restored)
local chaosVoidConn = nil
local chaosVoidCF = nil
local chaosRealCF = nil
local chaosVoidLastPush = 0

local function stopChaosVoidPersist()
    if chaosVoidConn then
        pcall(function() chaosVoidConn:Disconnect() end)
        chaosVoidConn = nil
    end
    pcall(function() RunService:UnbindFromRenderStep("__adyans_chaos_void") end)
    chaosVoidCF = nil
    -- restore real CF once when leaving void
    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if root and chaosRealCF then
        pcall(function()
            root.CFrame = chaosRealCF
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end
    chaosRealCF = nil
    chaosVoidLastPush = 0
end

local function startChaosVoidPersist(targetRoot)
    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    -- lock in the real world position before we leave for extreme void
    if not chaosRealCF then
        chaosRealCF = myRoot.CFrame
    end
    chaosVoidCF = makeJarvisVoidCF()

    -- push to extreme void immediately (meowwCL style)
    pcall(function()
        myRoot.CFrame = chaosVoidCF
        myRoot.AssemblyLinearVelocity = Vector3.zero
        myRoot.AssemblyAngularVelocity = Vector3.zero
    end)
    chaosVoidLastPush = tick()

    if chaosVoidConn then return end  -- already running

    -- keep re-applying extreme CFrame (~same cadence as the meowwCL loop)
    chaosVoidConn = RunService.Heartbeat:Connect(function()
        if not Config.Jarvis or not jarvisState.hiding then
            stopChaosVoidPersist()
            return
        end
        local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local now = tick()
        -- refresh every ~0.1s like the reference script
        if (now - (chaosVoidLastPush or 0)) >= 0.1 then
            chaosVoidCF = makeJarvisVoidCF()
            chaosVoidLastPush = now
        end
        if not chaosVoidCF then
            chaosVoidCF = makeJarvisVoidCF()
        end

        pcall(function()
            root.CFrame = chaosVoidCF
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end)

    -- client visual: stay at real position / face target so camera isn't at extreme coords
    pcall(function() RunService:UnbindFromRenderStep("__adyans_chaos_void") end)
    RunService:BindToRenderStep("__adyans_chaos_void", Enum.RenderPriority.Camera.Value + 2, function()
        local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not root or not jarvisState.hiding then return end
        local real = chaosRealCF
        if not real then return end
        local pos = real.Position
        pcall(function()
            local facePos = lastFacePos
            if Config.FaceTarget and facePos then
                local lookAt = Vector3.new(facePos.X, pos.Y, facePos.Z)
                root.CFrame = CFrame.lookAt(pos, lookAt)
            else
                root.CFrame = CFrame.new(pos) * (real - real.Position)
            end
        end)
    end)
end

local function makeJarvisExtremeCF()
    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    local base = root and root.Position or Vector3.new(0, 50, 0)
    local y = tonumber(Config.JarvisExtremeY) or 800
    return CFrame.new(base.X + math.random(-15, 15), y, base.Z + math.random(-15, 15))
end

local function makeJarvisAboveCF(targetRoot, targetHead)
    local height = tonumber(Config.JarvisAboveH) or 12
    local pos = (targetRoot.CFrame * CFrame.new(0, height, 0)).Position
    return CFrame.lookAt(pos, targetHead.Position)
end

local function isShotgunEquipped()
    local lf = FighterController and FighterController.LocalFighter
    local item = lf and lf.EquippedItem
    if not item then
        local tool = lp.Character and lp.Character:FindFirstChildOfClass("Tool")
        if tool then
            local n = string.lower(tool.Name)
            return n:find("shotgun", 1, true) or n:find("shot gun", 1, true) or n:find("db", 1, true)
        end
        return false
    end
    local name = ""
    pcall(function()
        name = tostring(item.Name or item:Get("Name") or "")
        if item.ViewModel then name = name .. " " .. tostring(item.ViewModel.Name) end
    end)
    name = string.lower(name)
    return name:find("shotgun", 1, true) or name:find("shot", 1, true) or name:find("db", 1, true)
end

local function getAmmoCount()
    local lf = FighterController and FighterController.LocalFighter
    local item = lf and lf.EquippedItem
    if not item then return nil end
    local ammo
    pcall(function()
        ammo = item:Get("Ammo") or item.Ammo or item._ammo or item.Bullets
    end)
    return tonumber(ammo)
end

-- ── Void spam state ──────────────────────────────────────────────────────────
local voidState = {
    phase = "attack", -- "hide" | "attack"
    phaseUntil = 0,
    voidCF = nil,
}

local lastFacePos = nil  -- last target position for client facing

local function makeVoidCF()
    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    local base = root and root.Position or Vector3.new(0, 50, 0)
    local y = tonumber(Config.VoidY) or -120
    return CFrame.new(base.X, y, base.Z)
end

local function tickVoidPhase(now)
    if not Config.VoidSpam then
        voidState.phase = "attack"
        return "attack"
    end
    if now >= (voidState.phaseUntil or 0) then
        if voidState.phase == "hide" then
            voidState.phase = "attack"
            voidState.phaseUntil = now + (tonumber(Config.VoidAttackSec) or 0.45)
        else
            voidState.phase = "hide"
            voidState.phaseUntil = now + (tonumber(Config.VoidHideSec) or 0.35)
            voidState.voidCF = makeVoidCF()
        end
    end
    return voidState.phase
end

-- ── Desync apply (client looks normal next frame) ────────────────────────────
local function applyDesync(desyncCF)
    if not desyncCF or not lp.Character then return end
    local myRoot = lp.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local oldCF = myRoot.CFrame
    local oldVel = myRoot.AssemblyLinearVelocity
    local oldRot = myRoot.AssemblyAngularVelocity

    pcall(function()
        myRoot.CFrame = desyncCF
    end)

    RunService:BindToRenderStep("__adyans_restore", Enum.RenderPriority.Camera.Value + 1, function()
        if myRoot and myRoot.Parent then
            pcall(function()
                -- restore position/velocity from before desync
                local pos = oldCF.Position
                local facePos = lastFacePos
                if Config.FaceTarget and facePos then
                    -- restore position but keep facing the target
                    local lookAt = Vector3.new(facePos.X, pos.Y, facePos.Z)
                    myRoot.CFrame = CFrame.lookAt(pos, lookAt)
                else
                    myRoot.CFrame = oldCF
                end
                myRoot.AssemblyLinearVelocity = oldVel
                myRoot.AssemblyAngularVelocity = oldRot
            end)
        end
        pcall(function()
            RunService:UnbindFromRenderStep("__adyans_restore")
        end)
    end)
end


-- ── Always face target (client character orientation) ────────────────────────
local function faceTarget(targetPos)
    if not Config.FaceTarget then return end
    if not targetPos or not lp.Character then return end
    local myRoot = lp.Character:FindFirstChild("HumanoidRootPart")
    local hum = lp.Character:FindFirstChildWhichIsA("Humanoid")
    if not myRoot then return end

    lastFacePos = targetPos

    -- flat look (yaw only) so character doesn't tilt
    local myPos = myRoot.Position
    local lookAt = Vector3.new(targetPos.X, myPos.Y, targetPos.Z)
    local flatCF = CFrame.lookAt(myPos, lookAt)

    pcall(function()
        if hum then
            hum.AutoRotate = false
        end
        -- keep current position + velocity, only change rotation
        local vel = myRoot.AssemblyLinearVelocity
        local rotVel = myRoot.AssemblyAngularVelocity
        myRoot.CFrame = CFrame.new(myPos) * (flatCF - flatCF.Position)
        myRoot.AssemblyLinearVelocity = vel
        myRoot.AssemblyAngularVelocity = rotVel
    end)
end

local function restoreAutoRotate()
    local char = lp.Character
    if not char then return end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if hum then
        pcall(function() hum.AutoRotate = true end)
    end
end
-- ── Knife / backstab mode ────────────────────────────────────────────────────
local lastKnifeClick = 0
local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

local function equipMeleeSlot()
    Config.WeaponSlot = "Melee"
    local lf = FighterController and FighterController.LocalFighter
    if lf then
        pcall(function() lf:EquipItem(3) end)
    end
end

-- Stick tightly behind opponent, face INTO their back (same dir they look)
local function makeKnifeBackstabCF(targetRoot)
    local dist = tonumber(Config.KnifeBackDist) or 1.15
    local height = tonumber(Config.KnifeHeight) or 0
    local look = targetRoot.CFrame.LookVector
    -- stand on their back side
    local backPos = targetRoot.Position - look * dist + Vector3.new(0, height, 0)
    -- face the same way they face → you look straight into their back
    -- (always_backstab style: align view with enemy orientation from behind)
    local flatLook = Vector3.new(look.X, 0, look.Z)
    if flatLook.Magnitude < 0.05 then
        flatLook = look
    else
        flatLook = flatLook.Unit
    end
    local faceTarget = backPos + flatLook
    return CFrame.lookAt(backPos, faceTarget)
end

local function spamKnifeRightClick(now)
    local rate = tonumber(Config.KnifeClickRate) or 0.04
    if now - (lastKnifeClick or 0) < rate then return end
    lastKnifeClick = now

    -- Prefer VirtualInputManager right button (button 1)
    if VirtualInputManager then
        pcall(function()
            local pos = UserInputService:GetMouseLocation()
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 1, true, game, 1)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 1, false, game, 1)
        end)
    end

    -- Also try tool activate + common exploit mouse2 helpers if present
    pcall(function()
        local ch = lp.Character
        local tool = ch and ch:FindFirstChildOfClass("Tool")
        if tool then
            tool:Activate()
        end
    end)
    pcall(function()
        if mouse2click then mouse2click() end
    end)
    pcall(function()
        if mouse2press then
            mouse2press()
            task.defer(function()
                pcall(function() if mouse2release then mouse2release() end end)
            end)
        end
    end)

    -- Melee UseItem path if the game uses it for knife swing
    pcall(function()
        if not util or not enum then return end
        if not FighterController or not FighterController.LocalFighter then return end
        local item = FighterController.LocalFighter.EquippedItem
        if not item then return end
        ReplicatedStorage.Remotes.Replication.Fighter.UseItem:FireServer(
            item:Get("ObjectID"),
            enum:ToEnum("StartShooting"),
            {},
            nil
        )
    end)
end

local knifeFaceConn = nil

local function stopKnifeFaceLock()
    if knifeFaceConn then
        pcall(function() knifeFaceConn:Disconnect() end)
        knifeFaceConn = nil
    end
    pcall(function() RunService:UnbindFromRenderStep("__adyans_knife_face") end)
end

local function runKnifeMode(targetPlayer, targetRoot, targetHead, now)
    equipMeleeSlot()
    stopChaosVoidPersist()

    local backCF = makeKnifeBackstabCF(targetRoot)

    -- Teleport / stick to their back and face into their back every frame
    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if myRoot then
        pcall(function()
            local hum = lp.Character:FindFirstChildWhichIsA("Humanoid")
            if hum then
                hum.AutoRotate = false
            end
            myRoot.CFrame = backCF
            myRoot.AssemblyLinearVelocity = Vector3.zero
            myRoot.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    -- Server desync to back CF (do NOT use FaceTarget restore — that turns you toward their head)
    do
        local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local oldVel = root.AssemblyLinearVelocity
            local oldRot = root.AssemblyAngularVelocity
            pcall(function()
                root.CFrame = backCF
            end)
            -- restore only velocity noise on render; keep knife facing/position
            pcall(function() RunService:UnbindFromRenderStep("__adyans_restore") end)
            RunService:BindToRenderStep("__adyans_restore", Enum.RenderPriority.Camera.Value + 1, function()
                local r = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if not r or not r.Parent then
                    pcall(function() RunService:UnbindFromRenderStep("__adyans_restore") end)
                    return
                end
                -- Re-apply backstab CF every render so nothing overwrites facing
                local tr = targetRoot
                if tr and tr.Parent then
                    local cf = makeKnifeBackstabCF(tr)
                    pcall(function()
                        r.CFrame = cf
                        r.AssemblyLinearVelocity = Vector3.zero
                        r.AssemblyAngularVelocity = Vector3.zero
                    end)
                end
                pcall(function() RunService:UnbindFromRenderStep("__adyans_restore") end)
            end)
        end
    end

    -- Continuous face-lock while in knife mode (survives between heartbeats)
    if not knifeFaceConn then
        knifeFaceConn = RunService.RenderStepped:Connect(function()
            if not Config.Enabled or Config.RageMode ~= "Knife" then
                stopKnifeFaceLock()
                restoreAutoRotate()
                return
            end
            local _, tr = getClosestTarget()
            local r = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if not (tr and r) then return end
            local cf = makeKnifeBackstabCF(tr)
            pcall(function()
                local hum = lp.Character:FindFirstChildWhichIsA("Humanoid")
                if hum then hum.AutoRotate = false end
                r.CFrame = cf
            end)
        end)
    end

    lastFacePos = nil  -- prevent FaceTarget from rotating toward head

    -- Spam right-click / knife attack until dead
    spamKnifeRightClick(now)
end

-- ── Fire ─────────────────────────────────────────────────────────────────────
local lastFire = 0
local shotgunPaused = false

local function fireAt(targetHead, originPos)
    if not util or not enum then return end
    if not FighterController or not FighterController.LocalFighter then return end
    local item = FighterController.LocalFighter.EquippedItem
    if not item then return end

    local targetPos = targetHead.Position
    local aimCF = CFrame.lookAt(originPos, targetPos)
    local targetCF = targetHead.CFrame
    local randomOffset = Vector3.new(
        (math.random() - 0.5) * 0.1,
        (math.random() - 0.5) * 0.1,
        (math.random() - 0.5) * 0.1
    )
    local aimedPos = targetPos + randomOffset
    local objSpaceHeadOffset = targetHead.CFrame:ToObjectSpace(CFrame.new(aimedPos))
    local cameradata = {}
    cameradata[utf8.char(1)] = {
        [utf8.char(0)] = util:EncodeCFrame(aimCF),
        [utf8.char(1)] = util:EncodeCFrame(targetCF),
        [utf8.char(2)] = targetHead,
        [utf8.char(3)] = util:EncodeCFrame(objSpaceHeadOffset),
    }
    pcall(function()
        ReplicatedStorage.Remotes.Replication.Fighter.UseItem:FireServer(
            item:Get("ObjectID"),
            enum:ToEnum("StartShooting"),
            cameradata,
            nil
        )
    end)
end

-- ── Main rage loop ───────────────────────────────────────────────────────────
local rageConn
local function stopRageLoop()
    if rageConn then
        rageConn:Disconnect()
        rageConn = nil
    end
    pcall(function() RunService:UnbindFromRenderStep("__adyans_restore") end)
    stopChaosVoidPersist()
    stopKnifeFaceLock()
    restoreAutoRotate()
end

local function startRageLoop()
    stopRageLoop()
    rageConn = RunService.Heartbeat:Connect(function()
        if not Config.Enabled then return end

        pcall(updateDeflection)

        local targetPlayer, targetRoot, targetHead = getClosestTarget()
        local now = tick()
        local phase = tickVoidPhase(now)

        -- Shotgun gate: when ammo hits 0, pause fire until resume count
        if Config.ShotgunGate and isShotgunEquipped() then
            local ammo = getAmmoCount()
            if ammo ~= nil then
                if ammo <= 0 then
                    shotgunPaused = true
                elseif ammo >= (tonumber(Config.ShotgunResumeAt) or 7) then
                    shotgunPaused = false
                end
            end
        else
            shotgunPaused = false
        end

        if not targetRoot or not targetHead then
            jarvisState.mode = "idle"
            jarvisState.hiding = false
            stopChaosVoidPersist()
            restoreAutoRotate()
            return
        end

        -- Knife mode: stick to back + spam right-click (always backstab style)
        if Config.RageMode == "Knife" then
            runKnifeMode(targetPlayer, targetRoot, targetHead, now)
            return
        end

        -- Track opponent for Jarvis
        trackOpponent(targetPlayer, targetRoot, now)
        if Config.Jarvis then
            updateAltFailTracking(targetPlayer, now)
        end

        local desyncCF
        local shouldFire = true
        local fireOriginOverride = nil  -- chaos: shoot from stick while body stays in void
        local jarvisActive = Config.Jarvis == true

        if jarvisActive then
            local holdingKnife = hasKnifeViewModel(targetPlayer)
            local voidingOrStick = isOpponentVoidingOrSticking(targetPlayer, targetRoot)
            local underground = isOpponentUndergroundRooted(targetRoot)
            local idle = isOpponentIdle(targetPlayer, targetRoot)

            -- Priority 1: Anti Knife
            if holdingKnife then
                jarvisState.mode = "antiknife"
                jarvisState.waitForUnknife = true
                jarvisState.hiding = true
                stopChaosVoidPersist()
                desyncCF = makeJarvisExtremeCF()
                shouldFire = false
            elseif jarvisState.waitForUnknife then
                -- still waiting for knife to be unequipped
                if not holdingKnife then
                    jarvisState.waitForUnknife = false
                    jarvisState.hiding = false
                    jarvisState.mode = "idle"
                    -- fall through to attack
                else
                    desyncCF = makeJarvisExtremeCF()
                    shouldFire = false
                end
            -- Priority 2a: Alternative Chaos (auto after normal Chaos keeps failing)
            elseif jarvisState.mode == "altchaos" then
                desyncCF, shouldFire, fireOriginOverride = runAltChaos(
                    targetPlayer, targetRoot, targetHead, now
                )
            -- Priority 2b: Chaos — stay void-immune; only micro hit-and-run bursts
            elseif voidingOrStick or isOpponentShooting(targetPlayer, targetRoot)
                or isOpponentReloading(targetPlayer) or jarvisState.waitForIdle
                or jarvisState.mode == "chaos" then
                jarvisState.mode = "chaos"
                jarvisState.waitForIdle = true

                local dangerous = isChaosDangerous(targetPlayer, targetRoot)
                local safe = isChaosSafeToAttack(targetPlayer, targetRoot)
                local inBurst = now < (jarvisState.attackUntil or 0)

                -- Always keep extreme void up during chaos (hitbox stays immune)
                jarvisState.hiding = true
                startChaosVoidPersist(targetRoot)
                desyncCF = chaosVoidCF or makeJarvisVoidCF(targetRoot.Position)

                if dangerous then
                    -- under fire / voiding: cancel any attack burst
                    jarvisState.attackUntil = 0
                    jarvisState.attackShotsLeft = 0
                    jarvisState.nextAttackAfter = now + 0.08
                    shouldFire = false
                    fireOriginOverride = nil
                elseif inBurst and (jarvisState.attackShotsLeft or 0) > 0 then
                    -- micro burst: fire from stick origin while body stays in extreme void
                    local origin, _ = chaosStickOrigin(targetRoot, targetHead)
                    fireOriginOverride = origin
                    shouldFire = true
                elseif safe and now >= (jarvisState.nextAttackAfter or 0) then
                    -- open a very short burst, then forced void gap
                    local open, shots, gap = chaosBurstParams(targetPlayer)
                    jarvisState.attackUntil = now + open
                    jarvisState.attackShotsLeft = shots
                    jarvisState.nextAttackAfter = now + open + gap
                    local origin, _ = chaosStickOrigin(targetRoot, targetHead)
                    fireOriginOverride = origin
                    shouldFire = true
                else
                    -- void gap between bursts
                    shouldFire = false
                    fireOriginOverride = nil
                end
            -- Priority 3: Anti Bait (rooted underground)
            elseif underground then
                jarvisState.mode = "antibait"
                jarvisState.hiding = false
                desyncCF = makeJarvisAboveCF(targetRoot, targetHead)
                shouldFire = true
            else
                jarvisState.mode = "idle"
                jarvisState.hiding = false
                -- normal stick pose
                local height = tonumber(Config.StickHeight) or 1
                local depth  = tonumber(Config.StickDepth) or 2
                local desyncPos = (targetRoot.CFrame * CFrame.new(0, height, depth)).Position
                desyncCF = CFrame.lookAt(desyncPos, targetHead.Position)
            end
        else
            -- Original non-Jarvis logic
            if Config.VoidSpam and phase == "hide" then
                desyncCF = voidState.voidCF or makeVoidCF()
            else
                local height = tonumber(Config.StickHeight) or 1
                local depth  = tonumber(Config.StickDepth) or 2
                if Config.AntiKnife and hasKnifeViewModel(targetPlayer) then
                    height = tonumber(Config.AntiKnifeHeight) or 6
                    depth = 0
                end
                local desyncPos = (targetRoot.CFrame * CFrame.new(0, height, depth)).Position
                desyncCF = CFrame.lookAt(desyncPos, targetHead.Position)
            end
        end

        -- While chaos void persist is active, skip one-shot desync (would break immunity)
        if desyncCF and not (Config.Jarvis and jarvisState.hiding and chaosVoidConn) then
            applyDesync(desyncCF)
        end

        -- Keep local character facing the target for clearer hits
        if not (Config.Jarvis and jarvisState.hiding and chaosVoidConn) then
            faceTarget(targetHead.Position)
        else
            lastFacePos = targetHead.Position
        end

        -- Fire rules
        if not shouldFire then return end
        if Config.DeflectSkip and deflecting[targetPlayer] then return end
        if not jarvisActive and Config.VoidSpam and phase == "hide" then return end
        if shotgunPaused then return end
        if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
        if not FighterController or not FighterController.LocalFighter then return end
        if not FighterController.LocalFighter.EquippedItem then return end
        if now - lastFire < (tonumber(Config.FireRate) or 0.0005) then return end
        lastFire = now

        local originPos = fireOriginOverride
            or (desyncCF and desyncCF.Position)
            or targetRoot.Position
        fireAt(targetHead, originPos)
        -- consume chaos burst shot quota
        if jarvisActive and jarvisState.mode == "chaos" and jarvisState.attackShotsLeft then
            jarvisState.attackShotsLeft = math.max(0, jarvisState.attackShotsLeft - 1)
            if jarvisState.attackShotsLeft <= 0 then
                jarvisState.attackUntil = 0
            end
        end
    end)
end

if Config.Enabled then
    startRageLoop()
end

-- ── Status HUD (small) ───────────────────────────────────────────────────────
local statusLabel
pcall(function()
    local sg = Instance.new("ScreenGui")
    sg.Name = "AdyansRageStatus"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 50
    pcall(function() sg.Parent = game:GetService("CoreGui") end)
    if not sg.Parent then sg.Parent = lp:WaitForChild("PlayerGui") end
    local f = Instance.new("TextLabel")
    f.Size = UDim2.new(0, 220, 0, 48)
    f.Position = UDim2.new(0, 12, 0, 120)
    f.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    f.BackgroundTransparency = 0.25
    f.TextColor3 = Color3.fromRGB(220, 220, 255)
    f.Font = Enum.Font.Code
    f.TextSize = 12
    f.TextXAlignment = Enum.TextXAlignment.Left
    f.TextYAlignment = Enum.TextYAlignment.Top
    f.Text = "Rage: off"
    f.Parent = sg
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    statusLabel = f
    RunService.Heartbeat:Connect(function()
        if not statusLabel then return end
        local parts = {
            Config.Enabled and ("ON:" .. (Config.RageMode or "Default")) or "OFF",
            Config.Jarvis and ("jarvis:" .. (jarvisState.mode or "idle") .. (jarvisState.mode == "altchaos" and (":" .. (jarvisState.altPhase or "")) or "")) or nil,
            (Config.Jarvis and jarvisState.hiding) and "void" or nil,
            (function()
                if not Config.Jarvis or jarvisState.mode ~= "chaos" then return nil end
                local tp = nil
                for p, _ in pairs(oppTrack) do tp = p break end
                local t = tp and oppTrack[tp]
                if t and t.avgInterval then
                    return string.format("hold:%.2f", getAdaptiveHold(t))
                end
                return nil
            end)(),
            Config.FaceTarget and "face" or nil,
            (not Config.Jarvis) and Config.VoidSpam and ("void:" .. voidState.phase) or nil,
            shotgunPaused and "sg:reload" or nil,
            (not Config.Jarvis) and Config.AntiKnife and "antiknife" or nil,
        }
        local t = {}
        for _, p in ipairs(parts) do if p then table.insert(t, p) end end
        statusLabel.Text = "Rage: " .. table.concat(t, " | ")
    end)
end)


-- ── Snowfall visual effect ───────────────────────────────────────────────────
pcall(function()
    local snowGui = Instance.new("ScreenGui")
    snowGui.Name = "AdyansSnowfall"
    snowGui.ResetOnSpawn = false
    snowGui.IgnoreGuiInset = true
    snowGui.DisplayOrder = 40
    snowGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() snowGui.Parent = game:GetService("CoreGui") end)
    if not snowGui.Parent then snowGui.Parent = lp:WaitForChild("PlayerGui") end

    local snowflakes = {}
    local flakeCount = 48
    local viewport = cam and cam.ViewportSize or Vector2.new(1920, 1080)

    local function makeFlake()
        local flake = Instance.new("TextLabel")
        flake.BackgroundTransparency = 1
        flake.Text = "❄"
        flake.TextColor3 = Color3.fromRGB(220, 235, 255)
        flake.TextTransparency = math.random(15, 45) / 100
        flake.TextSize = math.random(10, 18)
        flake.Font = Enum.Font.Gotham
        flake.Size = UDim2.fromOffset(20, 20)
        flake.ZIndex = 1
        flake.Parent = snowGui
        return flake
    end

    for i = 1, flakeCount do
        local flake = makeFlake()
        local x = math.random() 
        local y = math.random() * -0.2 - 0.05
        local speed = 0.08 + math.random() * 0.18
        local drift = (math.random() - 0.5) * 0.06
        local rotSpeed = (math.random() - 0.5) * 40
        flake.Position = UDim2.new(x, 0, y, 0)
        snowflakes[i] = {
            label = flake,
            x = x,
            y = y,
            speed = speed,
            drift = drift,
            rot = 0,
            rotSpeed = rotSpeed,
        }
    end

    local snowConn
    snowConn = RunService.RenderStepped:Connect(function(dt)
        if not snowGui or not snowGui.Parent then
            if snowConn then snowConn:Disconnect() end
            return
        end
        for _, s in ipairs(snowflakes) do
            s.y = s.y + s.speed * dt
            s.x = s.x + s.drift * dt
            s.rot = s.rot + s.rotSpeed * dt
            if s.y > 1.05 then
                s.y = -0.05 - math.random() * 0.1
                s.x = math.random()
                s.speed = 0.08 + math.random() * 0.18
                s.drift = (math.random() - 0.5) * 0.06
            end
            if s.x < -0.05 then s.x = 1.05 end
            if s.x > 1.05 then s.x = -0.05 end
            s.label.Position = UDim2.new(s.x, 0, s.y, 0)
            s.label.Rotation = s.rot
        end
    end)
end)

-- ── RAGE TAB UI ──────────────────────────────────────────────────────────────
local RageMain = Tabs.Rage:AddLeftGroupbox("Ragebot")
local RageJarvis = Tabs.Rage:AddLeftGroupbox("Jarvis")
local RageVoid = Tabs.Rage:AddRightGroupbox("Void / Anti-Knife")
local RageGun  = Tabs.Rage:AddRightGroupbox("Weapon")

RageJarvis:AddToggle("LR_Jarvis", {
    Text = "Jarvis Mode",
    Default = Config.Jarvis,
    Callback = function(v)
        Config.Jarvis = v == true
        jarvisState.mode = "idle"
        jarvisState.hiding = false
        jarvisState.waitForIdle = false
        jarvisState.waitForUnknife = false
        resetAltChaos(true)
        if Config.Jarvis then
            Library:Notify({ Title = "Jarvis", Description = "Chaos + Alt Chaos + Anti Knife + Anti Bait", Time = 3 })
        end
    end,
})

RageJarvis:AddSlider("LR_JarvisVoidY", {
    Text = "Jarvis Void Y",
    Default = Config.JarvisVoidY,
    Min = -500,
    Max = -50,
    Rounding = 0,
    Callback = function(v) Config.JarvisVoidY = v end,
})

RageJarvis:AddSlider("LR_JarvisExtremeY", {
    Text = "Jarvis Extreme Y",
    Default = Config.JarvisExtremeY,
    Min = 100,
    Max = 1500,
    Rounding = 0,
    Callback = function(v) Config.JarvisExtremeY = v end,
})

RageJarvis:AddSlider("LR_JarvisAboveH", {
    Text = "Anti Bait Height",
    Default = Config.JarvisAboveH,
    Min = 4,
    Max = 30,
    Rounding = 1,
    Callback = function(v) Config.JarvisAboveH = v end,
})


RageMain:AddToggle("LR_Enabled", {
    Text = "Enable Ragebot",
    Default = Config.Enabled,
    Callback = function(v)
        Config.Enabled = v == true
        if Config.Enabled then
            startRageLoop()
        else
            stopRageLoop()
            restoreAutoRotate()
        end
    end,
})

RageMain:AddDropdown("LR_RageMode", {
    Text = "Rage Mode",
    Values = { "Default", "Knife" },
    Default = Config.RageMode,
    Callback = function(v)
        Config.RageMode = v
        if v == "Knife" then
            Config.WeaponSlot = "Melee"
            stopChaosVoidPersist()
            equipMeleeSlot()
            Library:Notify({
                Title = "Rage Mode",
                Description = "Knife: stick to back + face their back + RMB spam",
                Time = 3,
            })
        else
            stopKnifeFaceLock()
            restoreAutoRotate()
            Library:Notify({
                Title = "Rage Mode",
                Description = "Default ragebot",
                Time = 2,
            })
        end
    end,
})

RageMain:AddSlider("LR_KnifeBack", {
    Text = "Knife Back Distance",
    Default = Config.KnifeBackDist,
    Min = 0.4,
    Max = 4,
    Rounding = 2,
    Callback = function(v) Config.KnifeBackDist = v end,
})

RageMain:AddSlider("LR_KnifeClick", {
    Text = "Knife Click Rate",
    Default = Config.KnifeClickRate,
    Min = 0.01,
    Max = 0.2,
    Rounding = 3,
    Callback = function(v) Config.KnifeClickRate = v end,
})

RageMain:AddSlider("LR_FireRate", {
    Text = "Fire Rate",
    Default = Config.FireRate,
    Min = 0.0001,
    Max = 0.05,
    Rounding = 4,
    Callback = function(v) Config.FireRate = v end,
})

RageMain:AddSlider("LR_MaxDist", {
    Text = "Max Distance",
    Default = Config.MaxDistance,
    Min = 50,
    Max = 2000,
    Rounding = 0,
    Callback = function(v) Config.MaxDistance = v end,
})

RageMain:AddToggle("LR_Team", {
    Text = "Team Check",
    Default = Config.TeamCheck,
    Callback = function(v) Config.TeamCheck = v == true end,
})

RageMain:AddToggle("LR_Deflect", {
    Text = "Skip Katana Deflect",
    Default = Config.DeflectSkip,
    Callback = function(v) Config.DeflectSkip = v == true end,
})

RageMain:AddToggle("LR_FaceTarget", {
    Text = "Always Face Target",
    Default = Config.FaceTarget,
    Callback = function(v)
        Config.FaceTarget = v == true
        if not Config.FaceTarget then restoreAutoRotate() end
    end,
})

RageMain:AddSlider("LR_StickH", {
    Text = "Stick Height",
    Default = Config.StickHeight,
    Min = -2,
    Max = 8,
    Rounding = 1,
    Callback = function(v) Config.StickHeight = v end,
})

RageMain:AddSlider("LR_StickD", {
    Text = "Stick Depth",
    Default = Config.StickDepth,
    Min = -5,
    Max = 8,
    Rounding = 1,
    Callback = function(v) Config.StickDepth = v end,
})

RageVoid:AddToggle("LR_AntiKnife", {
    Text = "Anti Knife (Elisium)",
    Default = Config.AntiKnife,
    Callback = function(v) Config.AntiKnife = v == true end,
})

RageVoid:AddSlider("LR_AntiKnifeH", {
    Text = "Anti-Knife Height",
    Default = Config.AntiKnifeHeight,
    Min = 2,
    Max = 15,
    Rounding = 1,
    Callback = function(v) Config.AntiKnifeHeight = v end,
})

RageVoid:AddToggle("LR_VoidSpam", {
    Text = "Void Spam (Elisium)",
    Default = Config.VoidSpam,
    Callback = function(v)
        Config.VoidSpam = v == true
        voidState.phase = "attack"
        voidState.phaseUntil = 0
    end,
})

RageVoid:AddSlider("LR_VoidHide", {
    Text = "Void Hide (sec)",
    Default = Config.VoidHideSec,
    Min = 0.1,
    Max = 2,
    Rounding = 2,
    Callback = function(v) Config.VoidHideSec = v end,
})

RageVoid:AddSlider("LR_VoidAttack", {
    Text = "Void Attack (sec)",
    Default = Config.VoidAttackSec,
    Min = 0.1,
    Max = 2,
    Rounding = 2,
    Callback = function(v) Config.VoidAttackSec = v end,
})

RageVoid:AddSlider("LR_VoidY", {
    Text = "Void Y",
    Default = Config.VoidY,
    Min = -500,
    Max = -20,
    Rounding = 0,
    Callback = function(v) Config.VoidY = v end,
})

RageGun:AddDropdown("LR_Slot", {
    Text = "Weapon Slot",
    Values = { "Primary", "Secondary", "Melee" },
    Default = Config.WeaponSlot,
    Callback = function(v) Config.WeaponSlot = v end,
})

RageGun:AddToggle("LR_AutoEquip", {
    Text = "Auto Equip Slot",
    Default = Config.AutoEquip,
    Callback = function(v) Config.AutoEquip = v == true end,
})

RageGun:AddToggle("LR_Shotgun", {
    Text = "Shotgun Gate (wait 7)",
    Default = Config.ShotgunGate,
    Callback = function(v) Config.ShotgunGate = v == true end,
})

RageGun:AddSlider("LR_SGResume", {
    Text = "Resume Ammo",
    Default = Config.ShotgunResumeAt,
    Min = 1,
    Max = 12,
    Rounding = 0,
    Callback = function(v) Config.ShotgunResumeAt = v end,
})

RageGun:AddButton({
    Text = "Force Start Loop",
    Func = function()
        Config.Enabled = true
        startRageLoop()
        Library:Notify({ Title = "adyans personal ragebot", Description = "Loop started", Time = 2 })
    end,
})

-- ── SETTINGS ─────────────────────────────────────────────────────────────────
local uiGroup = Tabs.Settings:AddLeftGroupbox("Menu")

uiGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Toggle menu",
})

Library.ToggleKeybind = Options.MenuKeybind

uiGroup:AddButton({
    Text = "Unload",
    Func = function()
        Config.Enabled = false
        stopRageLoop()
        pcall(function()
            local sg = game:GetService("CoreGui"):FindFirstChild("AdyansRageStatus")
                or (lp:FindFirstChild("PlayerGui") and lp.PlayerGui:FindFirstChild("AdyansRageStatus"))
            if sg then sg:Destroy() end
        end)
        Library:Unload()
    end,
})

-- ── Mobile / touch-friendly toggle button ────────────────────────────────────
-- Larger hitbox, multi-input, debounced so toggle/untoggle always registers.
do
    local btnGui = Instance.new("ScreenGui")
    btnGui.Name = "AdyansRageMobileToggle"
    btnGui.ResetOnSpawn = false
    btnGui.IgnoreGuiInset = true
    btnGui.DisplayOrder = 100
    btnGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() btnGui.Parent = game:GetService("CoreGui") end)
    if not btnGui.Parent then btnGui.Parent = lp:WaitForChild("PlayerGui") end

    local isMobile = UserInputService.TouchEnabled
    local size = isMobile and 56 or 44

    local btn = Instance.new("TextButton")
    btn.Name = "Toggle"
    btn.Size = UDim2.fromOffset(size, size)
    btn.Position = UDim2.new(1, -size - 16, 0.5, -size / 2)
    btn.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
    btn.Text = "🌙"
    btn.TextSize = isMobile and 22 or 18
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(255, 200, 230)
    btn.AutoButtonColor = true
    btn.Parent = btnGui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 100, 180)
    stroke.Thickness = 1.5
    stroke.Parent = btn

    -- Invisible expanded hit area for touch
    local hit = Instance.new("TextButton")
    hit.Name = "HitExpand"
    hit.Size = UDim2.fromOffset(size + 24, size + 24)
    hit.Position = UDim2.new(0.5, -(size + 24) / 2, 0.5, -(size + 24) / 2)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.ZIndex = 0
    hit.Parent = btn

    local lastToggle = 0
    local function doToggle()
        local now = tick()
        -- short debounce so double-fires don't skip, but long enough to feel responsive
        if now - lastToggle < 0.12 then return end
        lastToggle = now
        pcall(function()
            if Library.Toggle then
                Library:Toggle()
            elseif Library.Toggled ~= nil then
                Library.Toggled = not Library.Toggled
            end
        end)
        -- visual feedback
        btn.BackgroundColor3 = Color3.fromRGB(60, 30, 70)
        task.delay(0.1, function()
            if btn then btn.BackgroundColor3 = Color3.fromRGB(30, 20, 40) end
        end)
    end

    -- Multiple input paths so touch always registers
    btn.MouseButton1Click:Connect(doToggle)
    hit.MouseButton1Click:Connect(doToggle)
    btn.TouchTap:Connect(doToggle)
    hit.TouchTap:Connect(doToggle)

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            doToggle()
        end
    end)
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            doToggle()
        end
    end)

    -- Draggable on mobile
    local dragging, dragStart, startPos
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = btn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            -- only move if dragged far enough (avoid blocking taps)
            if delta.Magnitude > 12 then
                btn.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
end

-- ── Save / theme ─────────────────────────────────────────────────────────────
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("AdyansRage")
SaveManager:SetFolder("AdyansRage/configs")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
pcall(function() SaveManager:LoadAutoloadConfig() end)

Library:Notify({
    Title = "adyans personal ragebot",
    Description = "adyans personal ragebot + jarvis extreme void + snowfall loaded",
    Time = 5,
})

-- Character respawn safety: keep loop alive
lp.CharacterAdded:Connect(function()
    task.delay(0.5, function()
        jarvisState.altLastHp = nil
        if jarvisState.mode == "altchaos" then
            -- stay on alt chaos after death, re-wait first shot
            jarvisState.altPhase = "wait_first"
            jarvisState.altSeenFirstShot = false
            jarvisState.attackUntil = 0
            jarvisState.attackShotsLeft = 0
        end
        if Config.Enabled and not rageConn then
            startRageLoop()
        end
    end)
end)
