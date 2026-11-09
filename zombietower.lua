local _acRS = game:GetService("ReplicatedStorage")
local original_debug_info = (debug and debug.info) or function() return nil end

local exec_funcs = {
    "getgenv", "hookfunction", "getrawmetatable", "hookmetamethod", "setreadonly",
    "islclosure", "checkcaller", "getnamecallmethod", "setnamecallmethod",
    "newcclosure", "getconnections", "getloadedmodules", "getsenv", "getreg",
    "getgc", "debug_getupvalues", "identifyexecutor", "getexecutorname",
    "request", "syn", "fluxus", "clonereference", "getcallingscript",
    "replicatesignal", "getscriptbytecode", "firesignal", "getupvalue",
    "getconstants", "getproto", "getstack"
}

local saved = {}
local genv = getfenv()
if not genv.getgenv then
    local ok, g = pcall(getgenv)
    if ok then genv = g end
end

for _, name in ipairs(exec_funcs) do
    if genv[name] then
        saved[name] = genv[name]
    end
end

local newcclosure = saved.newcclosure or function(f) return f end
local setreadonly = saved.setreadonly or function() end
local getnamecallmethod = saved.getnamecallmethod or function() return "" end
local old_getfenv = genv.getfenv or getfenv
local old_getgc = saved.getgc or getgc
local old_getrawmetatable = saved.getrawmetatable or getmetatable

local blocked_sources = {
    "LocalScript3", "MiscellaneousController", "ClientFighter", "Root",
    "CameraController", "ReplicatedController", "Camera", "out.lua"
}

local function is_anticheat(max_level)
    max_level = max_level or 5
    for i = 2, max_level do
        local info = original_debug_info(i, "s")
        if not info then break end
        for _, src in ipairs(blocked_sources) do
            if string.find(info, src, 1, true) then return true end
        end
    end
    return false
end

pcall(function()
    local function hooked_getfenv(level)
        if is_anticheat(5) then
            local real = old_getfenv(level)
            if type(real) == "table" then
                return setmetatable({}, {
                    __index = function(_, k)
                        if saved[k] then return nil end
                        return real[k]
                    end,
                    __newindex = function(_, k, v) real[k] = v end,
                    __metatable = "Locked"
                })
            end
        end
        return old_getfenv(level)
    end
    rawset(genv, "getfenv", newcclosure(hooked_getfenv))
end)

local function trap(obj)
    local ok, mt = pcall(old_getrawmetatable, obj)
    if not ok or not mt then return false end
    return mt.__tostring ~= nil
        or mt.__index ~= nil
        or mt.__newindex ~= nil
        or mt.__call ~= nil
        or mt.__len ~= nil
end

pcall(function()
    local function hooked_getgc(includeTables)
        local res = old_getgc(includeTables)
        local out = {}
        for _, v in ipairs(res) do
            if not trap(v) then
                table.insert(out, v)
            end
        end
        return out
    end
    rawset(genv, "getgc", newcclosure(hooked_getgc))
end)

pcall(function()
    if saved.debug_getupvalues or (debug and debug.getupvalue) then
        local noop = newcclosure(function() end)
        rawset(genv, "debug.getupvalue", noop)
        if debug then
            rawset(debug, "getupvalue", noop)
            rawset(debug, "getconstants", noop)
            rawset(debug, "getproto", noop)
            rawset(debug, "getstack", noop)
        end
    end
end)

local killed_r = false
local function neutralize_shared_r_table(t)
    local ok, mt = pcall(old_getrawmetatable, t)
    if ok and mt then
        pcall(setreadonly, mt, false)
        pcall(function()
            mt.__index = function() return function() end end
            mt.__newindex = function() end
            mt.__call = function() end
        end)
        pcall(setreadonly, mt, true)
        return true
    end
    return false
end

local function kill_r()
    if not (shared and shared.r) then return false end
    if neutralize_shared_r_table(shared.r) then
        killed_r = true
        return true
    end
    return false
end

if not kill_r() then
    local ok_mt, shared_mt = pcall(old_getrawmetatable, shared)
    if ok_mt and shared_mt then
        pcall(setreadonly, shared_mt, false)
        local old_newindex = shared_mt.__newindex
        shared_mt.__newindex = function(t, k, v)
            if k == "r" and type(v) == "table" then
                if neutralize_shared_r_table(v) then
                    killed_r = true
                end
            end
            return old_newindex(t, k, v)
        end
        pcall(setreadonly, shared_mt, true)
    else
        task.spawn(function()
            while not killed_r do
                pcall(kill_r)
                task.wait(0.1)
            end
        end)
    end
end

pcall(function()
    local mtInstance = old_getrawmetatable(game)
    local oldNamecall = mtInstance.__namecall
    local oldNewindex = mtInstance.__newindex
    local protected_services = {
        [game:GetService("Players")] = true,
        [workspace] = true,
        [_acRS] = true,
        [game:GetService("ReplicatedFirst")] = true
    }
    pcall(setreadonly, mtInstance, false)
    mtInstance.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "Kick" then
            error("Kick is disabled")
            return
        end
        if method == "PreloadAsync" and is_anticheat(5) then
            return
        end
        return oldNamecall(self, ...)
    end)
    mtInstance.__newindex = newcclosure(function(self, k, v)
        if type(k) ~= "string" then
            error("Invalid key type")
        end
        if k == "Name" and protected_services[self] then
            return
        end
        return oldNewindex(self, k, v)
    end)
    pcall(setreadonly, mtInstance, true)
end)

pcall(function()
    if not rawget(genv, "LPH_CRASH") then
        rawset(genv, "LPH_CRASH", function() end)
    end
end)

warn("[AC Bypass] Loaded - waiting 4 seconds before main script...")
task.wait(4)

local cloneref = cloneref or clonereference or function(x) return x end

local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local Workspace = cloneref(game:GetService("Workspace"))
local lplr = Players.LocalPlayer
local util = require(ReplicatedStorage.Modules.Utility)
local enum = require(ReplicatedStorage.Modules.EnumLibrary)
local FighterController = require(lplr.PlayerScripts.Controllers.FighterController)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

getgenv().Config = {
    Enabled = true,
    FireRate = 0.02,
    MaxDistance = 500,
    LockEnabled = false,
    LockTolerance = 0.1,
    JitterEnabled = false,
    JitterRadius = 4.0,
    JitterInterval = 0.15,
    NoclipEnabled = false,
    AutoCollectEnabled = true,
    CollectHP = true,
    CollectAmmo = true,
    CollectInterval = 0.10,
    HideEnabled = false,
    HitTime = 1.0,
    HideTime = 0.25,
    HideDistance = 100,
    SmartUnderEnabled = false,
    UnderSafeReturn = true,
    InfiniteJumpsEnabled = true,

    AboveX = 5.0,
    AboveY = 14.5,
    AboveZ = -5.0,

    UnderX = -5.0,
    UnderY = -15.0,
    UnderZ = 5.0,
}

local function round1(v) return math.round(v * 10) / 10 end
local function round2(v) return math.round(v * 100) / 100 end

local originalJumps = {}

local function ApplyInfiniteDoubleJumps()
    local playerScripts = lplr:FindFirstChild("PlayerScripts")
    if not playerScripts then return end
    local controllers = playerScripts:FindFirstChild("Controllers")
    if not controllers then return end
    local module = controllers:FindFirstChild("FighterController")
    if not module then return end

    local ok, controller = pcall(require, module)
    if not ok then return end

    local fighter = controller.LocalFighter
    if not fighter then return end

    local enabled = getgenv().Config.InfiniteJumpsEnabled

    local items = fighter.Items
    if type(items) == "table" then
        for _, item in pairs(items) do
            local info = item.Info
            if type(info) == "table" then
                if originalJumps[item] == nil then
                    originalJumps[item] = info.MaxDoubleJumps
                end
                if enabled then
                    info.MaxDoubleJumps = 676767
                else
                    info.MaxDoubleJumps = originalJumps[item]
                end
            end
        end
    end

    if fighter.ItemAdded then
        fighter.ItemAdded:Connect(function(item)
            local info = item.Info
            if type(info) == "table" then
                if originalJumps[item] == nil then
                    originalJumps[item] = info.MaxDoubleJumps
                end
                if getgenv().Config.InfiniteJumpsEnabled then
                    info.MaxDoubleJumps = 676767
                else
                    info.MaxDoubleJumps = originalJumps[item]
                end
            end
        end)
    end
end

task.spawn(function()
    game:IsLoaded()
    ApplyInfiniteDoubleJumps()
end)

local lastFire = 0
local lastJitter = 0
local lastCollect = 0
local lockedTargetRoot = nil
local currentJitterOffset = Vector3.zero

local underLockActive = false
local underSafeCF = nil

local hidePhase = "hit"
local phaseStart = tick()
local savedReturnCF = nil
local hiddenToCF = nil

local function isAirborne(targetModel)
    if not targetModel then return false end
    local hum = targetModel:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    return hum.FloorMaterial == Enum.Material.Air
end

local function getClosestTarget()
    local char = lplr.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil, nil, nil end

    local highestGrounded = nil
    local highestGroundedY = -math.huge
    local highestGroundedRoot, highestGroundedHead = nil, nil

    local lowestAirborne = nil
    local lowestAirborneY = math.huge
    local lowestAirborneRoot, lowestAirborneHead = nil, nil

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= char then
            local pRoot = obj:FindFirstChild("HumanoidRootPart")
            local pHead = obj:FindFirstChild("Head")
            local pHum = obj:FindFirstChildWhichIsA("Humanoid")

            if pRoot and pHead and pHum and pHum.Health > 0 then
                if not Players:GetPlayerFromCharacter(obj) then
                    local dist = (myRoot.Position - pRoot.Position).Magnitude
                    if dist < getgenv().Config.MaxDistance then
                        local airborne = pHum.FloorMaterial == Enum.Material.Air
                        if airborne then
                            if pRoot.Position.Y < lowestAirborneY then
                                lowestAirborneY = pRoot.Position.Y
                                lowestAirborne = obj
                                lowestAirborneRoot = pRoot
                                lowestAirborneHead = pHead
                            end
                        else
                            if pRoot.Position.Y > highestGroundedY then
                                highestGroundedY = pRoot.Position.Y
                                highestGrounded = obj
                                highestGroundedRoot = pRoot
                                highestGroundedHead = pHead
                            end
                        end
                    end
                end
            end
        end
    end

    if highestGrounded then
        return highestGrounded, highestGroundedRoot, highestGroundedHead
    end
    if lowestAirborne then
        return lowestAirborne, lowestAirborneRoot, lowestAirborneHead
    end
    return nil, nil, nil
end

local function applyNoclip(state)
    local char = lplr.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if state then
                part.CanCollide = false
            else
                if part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
        end
    end
end

lplr.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart", 5)
    task.wait(0.1)
    if getgenv().Config.NoclipEnabled then
        applyNoclip(true)
    end
    hidePhase = "hit"
    phaseStart = tick()
    savedReturnCF = nil
    hiddenToCF = nil
    underLockActive = false
    underSafeCF = nil
    originalJumps = {}
    ApplyInfiniteDoubleJumps()
end)

local function escapeUnderLock()
    if not underLockActive then return end
    local char = lplr.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if myRoot and underSafeCF and getgenv().Config.UnderSafeReturn then
        myRoot.CFrame = underSafeCF
    end
    underLockActive = false
    underSafeCF = nil
end

local function lockAbove(targetRoot)
    local char = lplr.Character
    if not char then return end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    if not targetRoot or not targetRoot.Parent then return end

    local offset = Vector3.new(
        getgenv().Config.AboveX,
        getgenv().Config.AboveY,
        getgenv().Config.AboveZ
    )

    local idealPos = targetRoot.Position + offset

    if getgenv().Config.JitterEnabled then
        idealPos = idealPos + currentJitterOffset
    end

    local targetChanged = (lockedTargetRoot ~= targetRoot)
    lockedTargetRoot = targetRoot

    local tolerance = getgenv().Config.LockTolerance or 2
    local drift = (myRoot.Position - idealPos).Magnitude
    if not targetChanged and drift < tolerance then
        return
    end

    myRoot.CFrame = CFrame.new(idealPos) * (myRoot.CFrame - myRoot.CFrame.Position)
end

local function lockBelow(targetRoot)
    local char = lplr.Character
    if not char then return end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    if not targetRoot or not targetRoot.Parent then return end

    local offset = Vector3.new(
        getgenv().Config.UnderX,
        getgenv().Config.UnderY,
        getgenv().Config.UnderZ
    )

    local idealPos = targetRoot.Position + offset

    if getgenv().Config.JitterEnabled then
        idealPos = idealPos + currentJitterOffset
    end

    if not underLockActive then
        underLockActive = true
        underSafeCF = myRoot.CFrame
    end

    local targetChanged = (lockedTargetRoot ~= targetRoot)
    lockedTargetRoot = targetRoot

    local tolerance = getgenv().Config.LockTolerance or 2
    local drift = (myRoot.Position - idealPos).Magnitude
    if not targetChanged and drift < tolerance then
        return
    end

    myRoot.CFrame = CFrame.new(idealPos) * (myRoot.CFrame - myRoot.CFrame.Position)
end

local function isRagdolled(targetModel)
    if not targetModel then return false end
    local hum = targetModel:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    if hum.Health <= 0 then return true end
    if hum.PlatformStand then return true end
    if hum:GetState() == Enum.HumanoidStateType.Physics then return true end
    return false
end

local function isMoving(targetModel, threshold)
    if not targetModel then return false end
    local root = targetModel:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local v = root.AssemblyLinearVelocity
    return Vector3.new(v.X, 0, v.Z).Magnitude > (threshold or 1)
end

local function isInsideGround(targetModel)
    if not targetModel then return false end
    local root = targetModel:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {targetModel, lplr.Character}

    local origin = root.Position + Vector3.new(0, 2, 0)
    local result = Workspace:Raycast(origin, Vector3.new(0, -10, 0), rayParams)

    if result and result.Position.Y > root.Position.Y then
        return true
    end
    return false
end

local function canUseUnder(targetModel)
    if not targetModel then return false end
    if not targetModel:FindFirstChildOfClass("Humanoid") then return false end
    if isRagdolled(targetModel) then return false end
    if isAirborne(targetModel) then return false end
    if isMoving(targetModel, 15) then return false end
    if isInsideGround(targetModel) then return false end
    return true
end

local function releaseLock()
    escapeUnderLock()
    lockedTargetRoot = nil
    currentJitterOffset = Vector3.zero
end

local function updateJitter(targetRoot)
    if not getgenv().Config.JitterEnabled then
        currentJitterOffset = Vector3.zero
        return
    end
    local now = tick()
    if now - lastJitter < (getgenv().Config.JitterInterval or 0.15) then return end
    lastJitter = now

    local r = getgenv().Config.JitterRadius or 4
    local amount = (math.random() * 2 - 1) * r
    if targetRoot then
        currentJitterOffset = targetRoot.CFrame.RightVector * amount
    else
        currentJitterOffset = Vector3.new(amount, 0, 0)
    end
end

local function doCollect()
    if not getgenv().Config.AutoCollectEnabled then return end
    local now = tick()
    if now - lastCollect < (getgenv().Config.CollectInterval or 0.10) then return end
    lastCollect = now

    local char = lplr.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    local wantHP   = getgenv().Config.CollectHP and hum.Health < hum.MaxHealth
    local wantAmmo = getgenv().Config.CollectAmmo
    if not wantHP and not wantAmmo then return end

    local firetouch = firetouchinterest
    if not firetouch then return end

    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name == "_drop" and obj:IsA("BasePart") then
            local isHP   = obj:FindFirstChild("Health") ~= nil
            local isAmmo = obj:FindFirstChild("Ammo") ~= nil
                        or obj:FindFirstChild("AmmoBalanced") ~= nil
            if (wantHP and isHP) or (wantAmmo and isAmmo) then
                pcall(function()
                    firetouch(hrp, obj, 0)
                    firetouch(hrp, obj, 1)
                end)
            end
        end
    end
end

local function pickHideCFrame(fromCF)
    local sign = (math.random() < 0.5) and -1 or 1
    local dir = Vector3.new(sign, 0, 0)
    local dest = fromCF.Position + dir * (getgenv().Config.HideDistance or 100)
    return CFrame.new(dest) * (fromCF - fromCF.Position)
end

RunService.Heartbeat:Connect(function()
    if not getgenv().Config.Enabled then return end

    if getgenv().Config.NoclipEnabled then
        applyNoclip(true)
    end

    doCollect()

    local char = lplr.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not myRoot or not hum or hum.Health <= 0 then
        if lockedTargetRoot then releaseLock() end
        hidePhase = "hit"
        savedReturnCF = nil
        hiddenToCF = nil
        return
    end

    if getgenv().Config.HideEnabled and hidePhase == "hide" then
        local now = tick()
        if hiddenToCF and (myRoot.Position - hiddenToCF.Position).Magnitude > 1 then
            myRoot.CFrame = hiddenToCF
        end
        if now - phaseStart >= (getgenv().Config.HideTime or 0.5) then
            if savedReturnCF then
                myRoot.CFrame = savedReturnCF
            end
            savedReturnCF = nil
            hiddenToCF = nil
            hidePhase = "hit"
            phaseStart = now
        end
        return
    end

    local targetModel, targetRoot, targetHead = getClosestTarget()

    if underLockActive and (not targetModel or not targetRoot or not targetModel.Parent) then
        escapeUnderLock()
        lockedTargetRoot = nil
    end

    if getgenv().Config.HideEnabled then
        if not targetModel or not targetRoot then
            hidePhase = "hit"
            phaseStart = tick()
            if lockedTargetRoot then releaseLock() end
            return
        end

        local now = tick()
        if hidePhase == "hit" then
            if now - phaseStart >= (getgenv().Config.HitTime or 1.0) then
                savedReturnCF = myRoot.CFrame
                hiddenToCF = pickHideCFrame(savedReturnCF)
                myRoot.CFrame = hiddenToCF
                hidePhase = "hide"
                phaseStart = now
                return
            end
        end
    else
        if hidePhase == "hide" then
            if savedReturnCF then
                myRoot.CFrame = savedReturnCF
            end
            savedReturnCF = nil
            hiddenToCF = nil
            hidePhase = "hit"
            phaseStart = tick()
        end
    end

    if not targetModel or not targetHead or not targetRoot then
        if lockedTargetRoot then releaseLock() end
        return
    end

    local localFighter = FighterController.LocalFighter
    if not localFighter or not localFighter.EquippedItem then return end

    if getgenv().Config.LockEnabled and getgenv().Config.JitterEnabled then
        updateJitter(targetRoot)
    end

    if getgenv().Config.LockEnabled then
        if getgenv().Config.SmartUnderEnabled and canUseUnder(targetModel) then
            pcall(lockBelow, targetRoot)
        else
            if underLockActive then escapeUnderLock() end
            pcall(lockAbove, targetRoot)
        end
    elseif lockedTargetRoot then
        releaseLock()
    else
        if underLockActive then escapeUnderLock() end
    end

    if tick() - lastFire < getgenv().Config.FireRate then return end
    lastFire = tick()

    local originPos = targetHead.Position + Vector3.new(0, 1, 0)
    local targetPos = targetHead.Position
    local aimCF = CFrame.lookAt(originPos, targetPos)
    local targetCF = targetHead.CFrame

    local randomOffset = Vector3.new(
        (math.random() - 0.5) * 0.02,
        (math.random() - 0.5) * 0.02,
        (math.random() - 0.5) * 0.02
    )
    local aimedPos = targetPos + randomOffset
    local objSpaceHeadOffset = targetHead.CFrame:ToObjectSpace(CFrame.new(aimedPos))

    local cameradata = {}
    cameradata[utf8.char(1)] = {
        [utf8.char(0)] = util:EncodeCFrame(aimCF),
        [utf8.char(1)] = util:EncodeCFrame(targetCF),
        [utf8.char(2)] = targetHead,
        [utf8.char(3)] = util:EncodeCFrame(objSpaceHeadOffset)
    }

    pcall(function()
        ReplicatedStorage.Remotes.Replication.Fighter.UseItem:FireServer(
            localFighter.EquippedItem:Get("ObjectID"),
            enum:ToEnum("StartShooting"),
            cameradata,
            nil
        )
    end)
end)

local Window = Rayfield:CreateWindow({
    Name = "Tower Ragebot | by ɹǝɯɐǝɹᗡ @hiyigoo67 on discord",
    LoadingTitle = "Tower Ragebot",
    LoadingSubtitle = "by ɹǝɯɐǝɹᗡ (@hiyigoo67) on discord",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "boneclawlegend",
        FileName = "config"
    },
    Discord = { Enabled = false },
    KeySystem = false,
})

local CombatTab = Window:CreateTab("Combat", 4483362458)

CombatTab:CreateToggle({
    Name = "Enable Auto-Shoot",
    CurrentValue = getgenv().Config.Enabled,
    Flag = "EnabledToggle",
    Callback = function(Value) getgenv().Config.Enabled = Value end,
})

CombatTab:CreateToggle({
    Name = "Lock Above Target",
    CurrentValue = getgenv().Config.LockEnabled,
    Flag = "LockToggle",
    Callback = function(Value)
        getgenv().Config.LockEnabled = Value
        if not Value then releaseLock() end
    end,
})

CombatTab:CreateToggle({
    Name = "Smart Under Target",
    CurrentValue = getgenv().Config.SmartUnderEnabled,
    Flag = "SmartUnderToggle",
    Callback = function(Value)
        getgenv().Config.SmartUnderEnabled = Value
        if not Value then releaseLock() end
    end,
})

CombatTab:CreateToggle({
    Name = "Safe Return From Under",
    CurrentValue = getgenv().Config.UnderSafeReturn,
    Flag = "UnderSafeReturnToggle",
    Callback = function(Value)
        getgenv().Config.UnderSafeReturn = Value
        if not Value then underSafeCF = nil end
    end,
})

CombatTab:CreateSlider({
    Name = "Lock Tolerance (studs)",
    Range = {0.1, 10}, Increment = 0.1, Suffix = "studs",
    CurrentValue = getgenv().Config.LockTolerance, Flag = "LockToleranceSlider",
    Callback = function(Value) getgenv().Config.LockTolerance = round1(Value) end,
})

CombatTab:CreateToggle({
    Name = "Random Jitter Teleport (Strafe)",
    CurrentValue = getgenv().Config.JitterEnabled,
    Flag = "JitterToggle",
    Callback = function(Value)
        getgenv().Config.JitterEnabled = Value
        if not Value then currentJitterOffset = Vector3.zero end
    end,
})

CombatTab:CreateSlider({
    Name = "Jitter Radius (studs)",
    Range = {0.1, 15}, Increment = 0.1, Suffix = "studs",
    CurrentValue = getgenv().Config.JitterRadius, Flag = "JitterRadiusSlider",
    Callback = function(Value) getgenv().Config.JitterRadius = round1(Value) end,
})

CombatTab:CreateSlider({
    Name = "Jitter Interval (seconds)",
    Range = {0.05, 1}, Increment = 0.01, Suffix = "s",
    CurrentValue = getgenv().Config.JitterInterval, Flag = "JitterIntervalSlider",
    Callback = function(Value) getgenv().Config.JitterInterval = round2(Value) end,
})

CombatTab:CreateSlider({
    Name = "Fire Rate (seconds)",
    Range = {0.01, 0.5}, Increment = 0.01, Suffix = "s",
    CurrentValue = getgenv().Config.FireRate, Flag = "FireRateSlider",
    Callback = function(Value) getgenv().Config.FireRate = round2(Value) end,
})

CombatTab:CreateSlider({
    Name = "Max Distance",
    Range = {50, 2000}, Increment = 1, Suffix = "studs",
    CurrentValue = getgenv().Config.MaxDistance, Flag = "MaxDistSlider",
    Callback = function(Value) getgenv().Config.MaxDistance = math.round(Value) end,
})

local OffsetTab = Window:CreateTab("Lock Offset", 4483362458)

OffsetTab:CreateSection("Lock Above (target.Position + offset)")

OffsetTab:CreateSlider({
    Name = "Above X (-20 to 20)",
    Range = {-20, 20}, Increment = 0.1, Suffix = "studs",
    CurrentValue = getgenv().Config.AboveX, Flag = "AboveXSlider",
    Callback = function(Value) getgenv().Config.AboveX = round1(Value) end,
})

OffsetTab:CreateSlider({
    Name = "Above Y (5 to 20)",
    Range = {5, 20}, Increment = 0.1, Suffix = "studs",
    CurrentValue = getgenv().Config.AboveY, Flag = "AboveYSlider",
    Callback = function(Value) getgenv().Config.AboveY = round1(Value) end,
})

OffsetTab:CreateSlider({
    Name = "Above Z (-20 to 20)",
    Range = {-20, 20}, Increment = 0.1, Suffix = "studs",
    CurrentValue = getgenv().Config.AboveZ, Flag = "AboveZSlider",
    Callback = function(Value) getgenv().Config.AboveZ = round1(Value) end,
})

OffsetTab:CreateSection("Smart Under (target.Position + offset)")

OffsetTab:CreateSlider({
    Name = "Under X (-20 to 20)",
    Range = {-20, 20}, Increment = 0.1, Suffix = "studs",
    CurrentValue = getgenv().Config.UnderX, Flag = "UnderXSlider",
    Callback = function(Value) getgenv().Config.UnderX = round1(Value) end,
})

OffsetTab:CreateSlider({
    Name = "Under Y (-20 to -5)",
    Range = {-20, -5}, Increment = 0.1, Suffix = "studs",
    CurrentValue = getgenv().Config.UnderY, Flag = "UnderYSlider",
    Callback = function(Value) getgenv().Config.UnderY = round1(Value) end,
})

OffsetTab:CreateSlider({
    Name = "Under Z (-20 to 20)",
    Range = {-20, 20}, Increment = 0.1, Suffix = "studs",
    CurrentValue = getgenv().Config.UnderZ, Flag = "UnderZSlider",
    Callback = function(Value) getgenv().Config.UnderZ = round1(Value) end,
})

local HideTab = Window:CreateTab("Hide", 4483362458)

HideTab:CreateToggle({
    Name = "Enable Hide (Hit Time / Hide Time)",
    CurrentValue = getgenv().Config.HideEnabled,
    Flag = "HideToggle",
    Callback = function(Value)
        getgenv().Config.HideEnabled = Value
        if not Value then
            if hidePhase == "hide" then
                local char = lplr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and savedReturnCF then hrp.CFrame = savedReturnCF end
            end
            hidePhase = "hit"
            phaseStart = tick()
            savedReturnCF = nil
            hiddenToCF = nil
        end
    end,
})

HideTab:CreateSlider({
    Name = "Hit Time (seconds)",
    Range = {0.01, 2}, Increment = 0.01, Suffix = "s",
    CurrentValue = getgenv().Config.HitTime, Flag = "HitTimeSlider",
    Callback = function(Value) getgenv().Config.HitTime = round2(Value) end,
})

HideTab:CreateSlider({
    Name = "Hide Time (seconds)",
    Range = {0.01, 2}, Increment = 0.01, Suffix = "s",
    CurrentValue = getgenv().Config.HideTime, Flag = "HideTimeSlider",
    Callback = function(Value) getgenv().Config.HideTime = round2(Value) end,
})

HideTab:CreateSlider({
    Name = "Hide Distance (studs)",
    Range = {20, 500}, Increment = 1, Suffix = "studs",
    CurrentValue = getgenv().Config.HideDistance, Flag = "HideDistanceSlider",
    Callback = function(Value) getgenv().Config.HideDistance = math.round(Value) end,
})

local ItemsTab = Window:CreateTab("Items", 4483362458)

ItemsTab:CreateToggle({
    Name = "Enable Auto Collect",
    CurrentValue = getgenv().Config.AutoCollectEnabled,
    Flag = "AutoCollectToggle",
    Callback = function(Value) getgenv().Config.AutoCollectEnabled = Value end,
})

ItemsTab:CreateToggle({
    Name = "Collect Health Packs",
    CurrentValue = getgenv().Config.CollectHP,
    Flag = "CollectHPToggle",
    Callback = function(Value) getgenv().Config.CollectHP = Value end,
})

ItemsTab:CreateToggle({
    Name = "Collect Ammo Packs",
    CurrentValue = getgenv().Config.CollectAmmo,
    Flag = "CollectAmmoToggle",
    Callback = function(Value) getgenv().Config.CollectAmmo = Value end,
})

ItemsTab:CreateSlider({
    Name = "Collect Interval (seconds)",
    Range = {0.05, 1}, Increment = 0.01, Suffix = "s",
    CurrentValue = getgenv().Config.CollectInterval, Flag = "CollectIntervalSlider",
    Callback = function(Value) getgenv().Config.CollectInterval = round2(Value) end,
})

local MiscTab = Window:CreateTab("Misc", 4483362458)

MiscTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = getgenv().Config.NoclipEnabled,
    Flag = "NoclipToggle",
    Callback = function(Value)
        getgenv().Config.NoclipEnabled = Value
        applyNoclip(Value)
    end,
})

MiscTab:CreateToggle({
    Name = "Infinite Double Jumps",
    CurrentValue = getgenv().Config.InfiniteJumpsEnabled,
    Flag = "InfiniteJumpsToggle",
    Callback = function(Value)
        getgenv().Config.InfiniteJumpsEnabled = Value
        ApplyInfiniteDoubleJumps()
    end,
})

local SettingsTab = Window:CreateTab("Settings", 4483362458)
SettingsTab:CreateButton({
    Name = "Unload GUI",
    Callback = function() Rayfield:Destroy() end,
})

Rayfield:Notify({
    Title = "Fuck Towers",
    Content = "Script loaded successfully",
    Duration = 4,
    Image = 4483362458,
})