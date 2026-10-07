local Settings = {
    FOV = 200,
    AimPart = "Head",
}

local function wwguard(old, new)
    return function(...)
        local consts = debug.getconstants(2)
        if table.find(consts, "StackSize") then
            return old(...)
        end
        return new(...)
    end
end

local   Players = game:GetService("Players")
local   RunService = game:GetService("RunService")
local   Workspace = game:GetService("Workspace")
local   ReplicatedStorage = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local cam = Workspace.CurrentCamera

local SharedModules = require(ReplicatedStorage.SharedModules.Global ::
ModuleScript)

local Aiming_Library =
loadstring(game:HttpGet("https://pastebin.com/raw/KiRm0mvK"))()
assert(Aiming_Library, "Failed to load Aiming Library.")

Aiming_Library.FOV = Settings.FOV

local ESP = getfenv().ESP or {
    HighlightEnabled = false,
    Highlighted = nil,
    GetTeam = function(p_esp) return p_esp and p_esp.Team and p_esp.Team.Name or
"Neutral" end,
    RegisterHighlight = function(func) print("ESP:RegisterHighlight (stub)") end,
}

local SilentAimSettings = {
    SilentAim = false,
    AimDistance = 500,
    HeadshotChance = 100,
    FOVRange = 200,
    VisCheck = true,
    Whitelist = {},
    FriendlyCheck = false,
    FactionCheck = false,

    SilentTargetPlayers = true,
    SilentTargetAnimals = false,
    SilentTargetNPCs = false,
    TargetPriority = "Players",

    BackTrack = true,
    WallBang = false,

    BoneNames = {
        Torso = 'UpperTorso',
        Head = 'Head',
    },
    Aimbot_AimPart = Options.AimPart or "Head",
}

local Aimbot = {}
Aimbot.VisCheck = SilentAimSettings.VisCheck
Aimbot.AimPart = SilentAimSettings.Aimbot_AimPart
Aimbot.Prediction = true
Aimbot.BulletSpeed = 200
Aimbot.Gravity = -64.348

function Aimbot:_solveTime(origin, speed, targetPos, gY_abs) -- don't have the
original so this probably isn't 100% accurate
    local toTarget = targetPos - origin
    local toTargetXY = Vector3.new(toTarget.X, 0, toTarget.Z)
    local distXY = toTargetXY.Magnitude

    if speed <= 0.01 then return nil, nil end

    local time_est = distXY / speed
    if distXY < 0.1 then time_est = toTarget.Magnitude / speed end

    local launch_dir = toTarget.Unit
    for i = 1, 3 do
        local t = distXY / (speed *
Vector3.new(launch_dir.X,0,launch_dir.Z).Magnitude)
        if t == math.huge or t ~= t then t = toTarget.Magnitude / speed end

        local estimated_target_pos_with_gravity_compensation = targetPos +
Vector3.new(0, 0.5 * gY_abs * (distXY/speed)^2, 0)
        launch_dir = (estimated_target_pos_with_gravity_compensation - origin).Unit
        time_est = distXY / (speed *
Vector3.new(launch_dir.X,0,launch_dir.Z).Magnitude)
        if time_est == math.huge or time_est ~= time_est then time_est =
toTarget.Magnitude / speed end
    end
    return launch_dir, time_est
end

function Aimbot:Register(getTargetsFn, settings)
    self.getTargetsFn = getTargetsFn
    self.settingsRef = settings
end

function Aimbot:SetValidator(validatorFn)
    self.validatorFn = validatorFn
    if self.validatorFn then self.validatorFn() end
end

local animalsCache = {}
local npcsCache = {}

task.spawn(function()
    if not Workspace:FindFirstChild("WORKSPACE_Entities") then
        warn("SilentAim: WORKSPACE_Entities not found, animal/NPC targeting may be
limited.")
        return
    end
    local entitiesRoot = Workspace:WaitForChild("WORKSPACE_Entities")
    local animalsRoot = entitiesRoot:FindFirstChild("Animals")
    local npcsRoot = entitiesRoot:FindFirstChild("NPCs")

    local function setupCacheItem(itemInstance, cacheTable, typeName)
        local map = { instance = itemInstance, connections = {}, type = typeName }
        local function clean()
            for _, con in ipairs(map.connections) do con:Disconnect() end
            table.clear(map.connections)
            local index = table.find(cacheTable, map)
            if index then table.remove(cacheTable, index) end
        end

        map.body   =   itemInstance:FindFirstChildWhichIsA('Model') or itemInstance
        map.root   =   map.body:FindFirstChild('HumanoidRootPart')
        map.head   =   map.body:FindFirstChild('Head')
        map.name   =   itemInstance.Name

        if not map.root or not map.head then return end

        if typeName == "Animal" then
            local healthObj = itemInstance:FindFirstChild('Health')
            if not healthObj then return end
            map.health = healthObj.Value
            table.insert(map.connections,
healthObj:GetPropertyChangedSignal('Value'):Connect(function()
                map.health = healthObj.Value
                if map.health <= 0 then task.defer(clean) end
            end))
        elseif typeName == "NPC" then
            map.health = itemInstance:GetAttribute('Health') or
(map.body:FindFirstChildWhichIsA("Humanoid") and
map.body:FindFirstChildWhichIsA("Humanoid").Health) or 0
            local humanoid = map.body:FindFirstChildWhichIsA("Humanoid")
            if itemInstance:GetAttributeChangedSignal('Health') then
                  table.insert(map.connections,
itemInstance:GetAttributeChangedSignal('Health'):Connect(function()
                     map.health = itemInstance:GetAttribute('Health') or 0
                     if map.health <= 0 then task.defer(clean) end
                end))
            elseif humanoid then
                  table.insert(map.connections, humanoid.Died:Connect(function()
map.health = 0; task.defer(clean) end))
                  if humanoid.Health == 0 then map.health = 0 end
            end
        end

        if map.health > 0 then
            table.insert(cacheTable, map)
        end
        table.insert(map.connections,
itemInstance.AncestryChanged:Connect(function(_, parent) if not parent then
task.defer(clean) end end))
    end

    if animalsRoot then
        animalsRoot.ChildAdded:Connect(function(child) setupCacheItem(child,
animalsCache, "Animal") end)
         for _, child in ipairs(animalsRoot:GetChildren()) do
task.spawn(setupCacheItem, child, animalsCache, "Animal") end
     end
     if npcsRoot then
         npcsRoot.ChildAdded:Connect(function(child) setupCacheItem(child,
npcsCache, "NPC") end)
         for _, child in ipairs(npcsRoot:GetChildren()) do
task.spawn(setupCacheItem, child, npcsCache, "NPC") end
     end
end)

local function GetPlayerState(targetPlr) return
SharedModules.ReplicatedState:GetPlayerState(targetPlr) end
local function IsPlayerAlive(targetPlr)
    local state = GetPlayerState(targetPlr)
    return state and state.State and (state.State.Health or 0) > 0 and not
state.State.Dead
end
local function IsPlayerProtected(targetPlr)
    local state = GetPlayerState(targetPlr)
    return state and state.State and (state.State.ProtectionStatus == 'Protected'
or state.State.ProtectionStatus == 'OutlawProtected')
end

function GetTarget()
    return Aiming_Library.CurrentTarget and Aiming_Library.CurrentTarget["Head"],
Aiming_Library.CurrentTarget
end

local markedBulletsForBacktrack = {}
local function markBulletForBacktrack(bulletId) markedBulletsForBacktrack[bulletId]
= true end

local function isPartVisibleByRay(part)
    if not part or not part.Parent then return false end
    local camPos = cam.CFrame.Position
    local targetPos = part.Position
    local ray = Ray.new(camPos, (targetPos - camPos).Unit * (targetPos-
camPos).Magnitude)
    local ignoreList = {plr.Character, part.Parent,
Workspace:FindFirstChild("Ignore")}
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
    return not hit or hit:IsDescendantOf(part.Parent)
end

local function forceHitTargetWithBacktrack(info)
    task.wait(info.travelTime)
    if not info.targetPart or not info.targetPart.Parent then
         markedBulletsForBacktrack[info.bulletId] = nil
         return
    end
    local targetRef
    if info.targetModel:FindFirstChildWhichIsA("Humanoid") and
Players:GetPlayerFromCharacter(info.targetModel) then
         targetRef =
SharedModules.Network:GetReference(Players:GetPlayerFromCharacter(info.targetModel)
, 'CharacterPart')
    else
         targetRef = SharedModules.Network:GetReference(info.targetModel,
'Character')
    end
    if not targetRef then
        markedBulletsForBacktrack[info.bulletId] = nil
        return
    end
    local objSpaceHitPos =
info.targetPart.CFrame:PointToObjectSpace(info.hitPosWorld)
    local objSpaceNormal = info.targetPart.CFrame:VectorToObjectSpace(-
info.originalProjectileData.direction.Unit)
    local objSpaceIncoming =
info.targetPart.CFrame:VectorToObjectSpace(info.originalProjectileData.direction.Un
it)

    SharedModules.Network:FireServer(
         'ProjectileEvent', info.bulletId, SharedModules.SyncedTime:GetTime(),
'Final',
         targetRef, objSpaceHitPos, objSpaceNormal, objSpaceIncoming,
         info.hitPosWorld, -info.originalProjectileData.direction.Unit,
info.targetPart.Material.Name
    )
    task.defer(SharedModules.Network.FireServer, SharedModules.Network,
'RemoveProjectile', info.bulletId)
    markedBulletsForBacktrack[info.bulletId] = nil
end

local function getSpreadVector(seed, fireDirectionUnit, accuracyRadians)
    local Rnd = Random.new(seed)
    local spreadCone = CFrame.Angles(0, 0, Rnd:NextNumber(0, 2 * math.pi)) *

CFrame.Angles(math.acos(Rnd:NextNumber(math.cos(accuracyRadians), 1)), 0, 0)
    return (CFrame.new(Vector3.new(), fireDirectionUnit) * spreadCone).LookVector
end

local oldOriginalFireServer = SharedModules.Network.FireServer
SharedModules.Network.FireServer = wwguard(oldOriginalFireServer,
function(self_net, action, ...)
    local args = table.pack(...)

    if action == 'InitProjectiles' and SilentAimSettings.SilentAim then
        print('hookrun', ...)

        if Aiming_Library.ShouldMiss and Aiming_Library.ShouldMiss() then
            return oldOriginalFireServer(self_net, action, unpack(args, 1, args.n))
        end

        local gun = SharedModules.PlayerCharacter:GetEquippedItem()
        local projectileData = args[2]

        if gun and gun.SharedData and projectileData and type(projectileData) ==
"table" then
             local targetPart, targetModel = GetTarget()

            print(targetPart, targetModel)

            if targetPart and targetModel then
                local gunShared = gun.SharedData
                local projSpeed = gunShared.ProjectilePower
                local gravY_abs = math.abs(((gunShared.Gravity and
gunShared.Gravity.Y) or -64.348) * (gunShared.GravityMultiplier or 1))

                if type(projectileData.power) == 'number' and
type(projectileData.drawStart) == 'number' then
                    local powerPerc = math.min(projectileData.power, 1)
                    local minP, maxP = gunShared.MinPower or 50, gunShared.MaxPower
or 150
                    if projectileData.arrowType == 'ExplosiveArrow' then
                        minP, maxP = gunShared.MinPowerExplosive or 70,
gunShared.MaxPowerExplosive or 220
                    end
                    projSpeed = minP + (maxP - minP) * powerPerc
                end

                Aimbot.BulletSpeed = projSpeed
                Aimbot.Gravity = -gravY_abs

                local calculatedDirectionUnit, timeToTarget =
Aimbot:_solveTime(projectileData.origin, projSpeed, targetPart.Position, gravY_abs)

                if calculatedDirectionUnit and timeToTarget then
                    local weaponAccuracy = gunShared.ProjectileAccuracy or 1
                    if projectileData.ammoType == 'ShotgunRound' then
weaponAccuracy = weaponAccuracy * (gunShared.ShotgunRoundAccuracy or 1) end

                    local spreadAngleRad = ((gunShared.NumProjectiles or 1) > 1 and
math.rad(10)) or math.rad(12.5)
                    local finalSpreadRad = spreadAngleRad * math.clamp(1 -
weaponAccuracy, 0, 1)

                    local isTomahawk = gun.Name and
gun.Name:lower():find("tomahawk")
                    if isTomahawk then
                         projectileData.direction = calculatedDirectionUnit
                    else
                         projectileData.direction =
getSpreadVector(projectileData.seed, calculatedDirectionUnit, finalSpreadRad)
                         projectileData.accuracy = 1
                    end

                    if type(projectileData.power) == 'number' and
type(projectileData.drawStart) ~= 'number' then
                        projectileData.power = 1
                    end

                    if SilentAimSettings.BackTrack then
                        local canBacktrackHit = true
                        if not SilentAimSettings.WallBang then canBacktrackHit =
isPartVisibleByRay(targetPart) end
                        if canBacktrackHit then
                            local bulletIds = args[3]
                            oldOriginalFireServer(self_net, action, unpack(args, 1,
args.n))
                            for _, bulletId in ipairs(bulletIds) do
                                markBulletForBacktrack(bulletId)
                                task.spawn(forceHitTargetWithBacktrack, {
                                    targetPart = targetPart, targetModel =
targetModel,
                                    hitPosWorld = targetPart.Position,
                                             originalProjectileData = projectileData,
                                             bulletId = bulletId, travelTime = timeToTarget
                                        })
                                    end
                                    return
                              end
                        end
                  end
            end
         end
     elseif (action == 'ProjectileEvent' or action == 'RemoveProjectile') and
SilentAimSettings.BackTrack then
         local bulletId = args[1]
         if markedBulletsForBacktrack[bulletId] then
             return
         end
     end
     return oldOriginalFireServer(self_net, action, unpack(args, 1, args.n))
end)

Aimbot:Register(GetTarget, SilentAimSettings)
Aimbot:SetValidator(function()
     local gun = SharedModules.PlayerCharacter:GetEquippedItem()
     if not gun or not gun.SharedData or not gun.SharedData.ProjectilePower then
         return false
     end
     Aimbot.BulletSpeed = gun.SharedData.ProjectilePower
     local gravY = ((gun.SharedData.Gravity and gun.SharedData.Gravity.Y) or -
64.348) * (gun.SharedData.GravityMultiplier or 1)
     Aimbot.Gravity = gravY
     return true
end)

if ESP and ESP.RegisterHighlight then
    ESP:RegisterHighlight(function()
         if SilentAimSettings.SilentAim and Aiming_Library.Enabled and
Aiming_Library.CurrentTarget then
             return Aiming_Library.CurrentTarget
         end
         return nil
    end)
end

RunService.Heartbeat:Connect(function()
     Aiming_Library.Enabled = SilentAimSettings.SilentAim
     Aiming_Library.Players = SilentAimSettings.SilentTargetPlayers
     Aiming_Library.NPCs = SilentAimSettings.SilentTargetNPCs
     Aimbot.AimPart = SilentAimSettings.Aimbot_AimPart
     Aimbot.VisCheck = SilentAimSettings.VisCheck
     if ESP then
         ESP.HighlightEnabled = SilentAimSettings.SilentAim
         if not SilentAimSettings.SilentAim then ESP.Highlighted = nil end
     end
end)

SilentAimSettings.SilentAim = true
