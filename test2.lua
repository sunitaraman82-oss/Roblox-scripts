-- RIVALS Ragebot - UI-free extracted version
-- Screenshot-matched ragebot defaults (no UI)
-- Ragebot: enabled
-- Prioritize Hackers: ON
-- Stability: 1.5
-- Shoot Frames: 1
-- Use Primary / Secondary / Melee: ON
-- On Empty: SwapOrReload
-- Evasion Mode: Random
-- Character Origin: OFF
-- Base Radius: 100000000
-- Random Range: 1

-- Extracted from HD8TBv.lua.txt.
-- Enabled automatically. No GUI/toggle logic is included.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local _cloneref = cloneref
if type(_cloneref) ~= "function" then _cloneref = function(x) return x end end
local _clonefunction = clonefunction
if type(_clonefunction) ~= "function" then _clonefunction = function(x) return x end end
cloneref = _cloneref
clonefunction = _clonefunction

local Char, Root
local function refreshCharacter()
    Char = LocalPlayer.Character
    Root = Char and Char:FindFirstChild("HumanoidRootPart") or nil
    return Char
end
refreshCharacter()
LocalPlayer.CharacterAdded:Connect(function(character)
    Char = character
    Root = character:WaitForChild("HumanoidRootPart", 10)
end)

local Bridge = {}
function Bridge.IsReadyToFight() return true end
local Options = {}
local Toggles = {}
local FighterDataCache = { LocalDuel = { Seeded = false, IsInShootingRange = false } }
local Genv = (type(getgenv) == "function" and getgenv()) or _G
Genv.KiciaHookCaps = Genv.KiciaHookCaps or {}
Genv.KiciaHookCaps.gate = Genv.KiciaHookCaps.gate or function()
    return type(getgc) == "function" and type(sethiddenproperty) == "function"
end
local function GetChar()
    if not Char or not Char.Parent then refreshCharacter() end
    return Char
end
local function GetRoot()
    local character = GetChar()
    Root = character and character:FindFirstChild("HumanoidRootPart") or Root
    return Root
end

local function init(ctx)

        local RivalsRuntimeBridge = ctx.RivalsRuntimeBridge
        local Options = ctx.Options
        local Toggles = ctx.Toggles
        local FighterDataCache = ctx.FighterDataCache
        local GetChar = ctx.GetChar
        local GetRoot = ctx.GetRoot
        local __kicia_hook_genv = ctx.Genv
        -- __KICIA_RAGEBOT_BEGIN__
            local KiciaRagebot = {}
            RivalsRuntimeBridge.KiciaRagebot = KiciaRagebot

            local RunService = game:GetService('RunService')
            local HttpServiceRB = cloneref(game:GetService('HttpService'))
            local CollectionServiceRB = cloneref(game:GetService('CollectionService'))
            local PlayersRB = cloneref(game:GetService('Players'))
            local ReplicatedStorageRB = cloneref(game:GetService('ReplicatedStorage'))
            local WorkspaceRB = workspace
            local LPRB = PlayersRB.LocalPlayer
            local rbRandom = Random.new()

            -- Executor capability shims (all feature-detected live on build 17625359962).
            local rbSetHidden = sethiddenproperty
            local rbSetFFlag = (type(setfflag) == 'function') and setfflag or sfflag
            local rbSetThreadIdentity = setthreadidentity
            local rbGetThreadIdentity = getthreadidentity

            -- Clean FireServer stolen off a throwaway RemoteEvent (matches the script's No Spread
            -- calling convention: positional call, never :FireServer()).
            local rbCleanFireEvent = Instance.new('RemoteEvent')
            local rbFireServerNative = clonefunction(rbCleanFireEvent.FireServer)

            local function rbRawWrite(obj, key, value)
                if typeof(obj) == 'Instance' then
                    if not pcall(rbSetHidden, obj, key, value) then
                        pcall(function() obj[key] = value end)
                    end
                else
                    pcall(rawset, obj, key, value)
                end
            end

            -- ---- settings (read live from the Obsidian controls; Kicia defaults as fallback) ----
            local function optValue(id, default)
                local o = Options and Options[id]
                if o and o.Value ~= nil then
                    return o.Value
                end
                return default
            end
            local function togValue(id, default)
                local t = Toggles and Toggles[id]
                if t and t.Value ~= nil then
                    return t.Value == true
                end
                return default
            end
            local Setting = {
                Stability = function() return optValue('P8S4S1', 1.5) end,
                ShootFrames = function() return optValue('P8S4S2', 1) end,
                PrioritizeHackers = function() return togValue('P8S4T4', true) end,
                WeaponPrimary = function() return togValue('P8S4T5', true) end,
                WeaponSecondary = function() return togValue('P8S4T6', true) end,
                WeaponMelee = function() return togValue('P8S4T7', true) end,
                OnEmpty = function() return optValue('P8S4D1', 'SwapOrReload') end,
                EvasionMode = function() return optValue('P8S4D2', 'Random') end,
                TranslocateOffset = function() return optValue('P8S4S3', -5) end,
                RandomBaseRadius = function() return optValue('P8S4S4', 100000000) end,
                RandomRadiusFactor = function() return optValue('P8S4S5', 1) end,
                RandomAnchorFromCharacter = function() return togValue('P8S4T8', false) end,
                -- ProjectileBreaker has no Kicia UI; RepositionInterval keeps Kicia's default.
                RepositionInterval = function() return 0.3 end,
            }
            -- Kicia's ProjectileBreaker depth constants (config present in Kicia; no UI slider).
            local PB_DEPTH_FORWARD = { Min = 0, Max = 4 }
            local PB_DEPTH_FORWARD_FREQ = 5
            local PB_DEPTH_UP = { Min = 0, Max = 5.5 }
            local PB_DEPTH_UP_FREQ = 5
            local PB_FALLBACK_BASE_RADIUS = 100
            local PB_FALLBACK_RADIUS_FACTOR = 0.5
            local PB_FALLBACK_ANCHOR_FROM_CHARACTER = false

            -- ---- self-contained game-handle resolution -----------------------------------
            local function findChild(root, ...)
                local node = root
                for _, name in ipairs({ ... }) do
                    if not node then
                        return nil
                    end
                    node = node:FindFirstChild(name)
                end
                return node
            end

            local cachedEnumLibrary = nil
            local function resolveEnumLibrary()
                if cachedEnumLibrary then
                    return cachedEnumLibrary
                end
                local mod = findChild(ReplicatedStorageRB, 'Modules', 'EnumLibrary')
                if not mod then
                    return nil
                end
                local ok, lib = pcall(require, mod)
                if ok and type(lib) == 'table' then
                    cachedEnumLibrary = lib
                    return lib
                end
                return nil
            end
            local function enc(name)
                local lib = resolveEnumLibrary()
                if not lib then
                    return nil
                end
                local ok, token = pcall(lib.ToEnum, lib, name)
                if ok then
                    return token
                end
                return nil
            end

            local cachedUseItemRemote = nil
            local function resolveUseItemRemote()
                if cachedUseItemRemote and cachedUseItemRemote.Parent then
                    return cachedUseItemRemote
                end
                local remote = findChild(ReplicatedStorageRB, 'Remotes', 'Replication', 'Fighter', 'UseItem')
                if remote and remote:IsA('RemoteEvent') then
                    cachedUseItemRemote = cloneref(remote)
                    return cachedUseItemRemote
                end
                return nil
            end
            local cachedUpdateStateRemote = nil
            local function resolveUpdateStateRemote()
                if cachedUpdateStateRemote and cachedUpdateStateRemote.Parent then
                    return cachedUpdateStateRemote
                end
                local remote = findChild(ReplicatedStorageRB, 'Remotes', 'Replication', 'Fighter', 'UpdateState')
                if remote and remote:IsA('RemoteEvent') then
                    cachedUpdateStateRemote = cloneref(remote)
                    return cachedUpdateStateRemote
                end
                return nil
            end
            local cachedCameraRotationRemote = nil
            local function resolveCameraRotationRemote()
                if cachedCameraRotationRemote and cachedCameraRotationRemote.Parent then
                    return cachedCameraRotationRemote
                end
                local remote = findChild(ReplicatedStorageRB, 'Remotes', 'Replication', 'Fighter', 'UpdateCameraRotation')
                if remote and remote:IsA('RemoteEvent') then
                    cachedCameraRotationRemote = cloneref(remote)
                    return cachedCameraRotationRemote
                end
                return nil
            end
            local function requireModuleRB(name)
                local mod = findChild(ReplicatedStorageRB, 'Modules', name)
                if not mod then
                    return nil
                end
                local ok, result = pcall(require, mod)
                if ok then
                    return result
                end
                return nil
            end

            -- FighterController singleton (carries LocalFighter + Objects) + its prototype
            -- (carries _CameraReplicationLoop).  Cached with cheap revalidation.
            local cachedFighterController = nil
            local function resolveFighterController()
                local cc = cachedFighterController
                if type(cc) == 'table' and rawget(cc, 'LocalFighter') ~= nil then
                    return cc
                end
                for _, m in ipairs(getgc(true)) do
                    if type(m) == 'table' and rawget(m, 'LocalFighter') ~= nil and rawget(m, 'Objects') ~= nil then
                        cachedFighterController = m
                        return m
                    end
                end
                return nil
            end
            local function resolveLocalFighter()
                local controller = resolveFighterController()
                return controller and rawget(controller, 'LocalFighter') or nil
            end
            local cachedFCPrototype = nil
            local function resolveFighterControllerPrototype()
                if type(cachedFCPrototype) == 'table' and rawget(cachedFCPrototype, '_CameraReplicationLoop') ~= nil then
                    return cachedFCPrototype
                end
                local controller = resolveFighterController()
                if controller then
                    local mt = getmetatable(controller)
                    local proto = mt and rawget(mt, '__index') or nil
                    if type(proto) == 'table' and rawget(proto, '_CameraReplicationLoop') ~= nil then
                        cachedFCPrototype = proto
                        return proto
                    end
                end
                for _, m in ipairs(getgc(true)) do
                    if type(m) == 'table' then
                        local idx = rawget(m, '__index')
                        if type(idx) == 'table' and rawget(idx, '_CameraReplicationLoop') ~= nil then
                            cachedFCPrototype = idx
                            return idx
                        end
                    end
                end
                return nil
            end

            -- ---- firing transport (Kicia t157/t16, lines 73511 / 88523 / 88535) ----------
            local function fireGun(objectId, isRaycast, aim1, aim2, hitboxHead, extra)
                local remote = resolveUseItemRemote()
                local token = enc('StartShooting')
                if not remote or not token or not objectId then
                    return
                end
                local inner = { ['\0'] = aim1, ['\1'] = aim2, ['\2'] = hitboxHead, ['\3'] = extra }
                local payload
                if isRaycast then
                    payload = { ['\1'] = inner, ['\2'] = true }
                else
                    payload = { ['\1'] = inner }
                end
                rbFireServerNative(remote, objectId, token, payload, nil)
            end
            local function fireMeleeAttack(objectId, a, b, c, d)
                local remote = resolveUseItemRemote()
                local token = enc('StartShooting')
                local anim = enc('AttackAnimation1')
                if not remote or not token or not anim or not objectId then
                    return
                end
                rbFireServerNative(remote, objectId, token, { ['\1'] = { ['\0'] = a, ['\1'] = b, ['\2'] = c, ['\3'] = d }, ['\2'] = anim }, nil)
            end
            local function fireMeleeHeavy(objectId, a, b, c, d)
                local remote = resolveUseItemRemote()
                local token = enc('StartAiming') -- Kicia HeavyAttackEncoded uses StartAiming
                local anim = enc('HeavyAttackAnimation1')
                if not remote or not token or not anim or not objectId then
                    return
                end
                rbFireServerNative(remote, objectId, token, { ['\1'] = { ['\0'] = a, ['\1'] = b, ['\2'] = c, ['\3'] = d }, ['\2'] = anim }, nil)
            end
            local function fireReload(objectId)
                local remote = resolveUseItemRemote()
                local start = enc('StartReloading')
                local reload = enc('Reload')
                if not remote or not start or not reload or not objectId then
                    return
                end
                rbFireServerNative(remote, objectId, start, { ['\1'] = reload, ['\2'] = reload }, nil)
            end

            -- ---- raw ClientItem helpers --------------------------------------------------
            local function itemObjectId(item)
                local data = rawget(item, 'Data')
                return data and rawget(data, 'ObjectID') or nil
            end
            local function itemInfo(item)
                return rawget(item, 'Info')
            end
            local function itemType(item)
                local info = itemInfo(item)
                return info and rawget(info, 'Type') or nil
            end
            local function itemIsRaycast(item)
                local info = itemInfo(item)
                return info and rawget(info, 'IsRaycast') == true
            end
            local function itemName(item)
                return rawget(item, 'Name') or rawget(item, 'ItemName')
            end
            local function itemAmmo(item)
                local data = rawget(item, 'Data')
                local ammo = data and rawget(data, 'Ammo')
                return type(ammo) == 'number' and ammo or 0
            end
            local function itemAmmoReserve(item)
                local data = rawget(item, 'Data')
                local reserve = data and rawget(data, 'AmmoReserve')
                if type(reserve) ~= 'number' then
                    return math.huge
                end
                return reserve
            end
            -- Kicia t157:IsReloading (lines 73560-73573): _reload_cooldown OR _shoot_cooldown_no_ammo.
            local function itemIsReloading(item)
                local now = tick()
                local cooldown = rawget(item, '_reload_cooldown')
                if type(cooldown) == 'number' and now < cooldown then
                    return true
                end
                local noAmmoCooldown = rawget(item, '_shoot_cooldown_no_ammo')
                return type(noAmmoCooldown) == 'number' and now < noAmmoCooldown
            end
            -- Kicia t157:IsMagFull (line 73575): Info.MaxAmmo <= current ammo.
            local function itemIsMagFull(item)
                local info = itemInfo(item)
                local maxAmmo = info and rawget(info, 'MaxAmmo')
                return type(maxAmmo) == 'number' and maxAmmo <= itemAmmo(item)
            end
            -- Kicia t157:IsEquipped (line 73501): the item's own IsEquipped field - the same
            -- read the game's Items modules (Minigun, Riot Shield) use. The fighter-side
            -- Data.EquippedItemID compare it replaced never matched Kicia and is gone.
            local function itemIsEquipped(item)
                return rawget(item, 'IsEquipped')
            end
            -- Kicia t157:Equip (lines 73493-73499): no-op when equipped, then
            -- item.ClientFighter:EquipItem(index). ClientFighter lives on the ITEM (the
            -- LocalFighter IS a ClientFighter and has no such field; live-verified),
            -- and index is the fighter's Items-table key - the exact value the game's
            -- QuickAttackSystem passes (EquipItem(table.find(ClientFighter.Items, item))).
            local function equipItem(item, index)
                if itemIsEquipped(item) then
                    return
                end
                local clientFighter = rawget(item, 'ClientFighter')
                if clientFighter and index and type(clientFighter.EquipItem) == 'function' then
                    pcall(function() clientFighter:EquipItem(index) end)
                end
            end
            -- Kicia t157:Reload guard (lines 73539-73546).
            local function reloadItem(item)
                if itemIsReloading(item) or itemAmmoReserve(item) <= 0 or itemIsMagFull(item) then
                    return
                end
                fireReload(itemObjectId(item))
            end

            -- ---- spoofed aim payload tables (hitscan strategy, lines 40519-40551) ---------
            local NEG_HUGE = -9e37
            local function buildAim(base, pitch, oy, oz)
                return {
                    ['\0'] = base['\0'], ['\1'] = base['\1'], ['\2'] = base['\2'],
                    ['\3'] = pitch, ['\4'] = oy, ['\5'] = oz,
                }
            end
            local AIM_ABOVE_ORIGIN = { ['\0'] = NEG_HUGE, ['\1'] = 0, ['\2'] = 0 }         -- t91
            local AIM_ABOVE_END = { ['\0'] = 0, ['\1'] = -90000000, ['\2'] = 0 }           -- t92
            local AIM_BELOW_ORIGIN = { ['\0'] = NEG_HUGE, ['\1'] = 0, ['\2'] = 0 }         -- t93
            local AIM_BELOW_END = { ['\0'] = 0, ['\1'] = 90000000, ['\2'] = 0 }            -- t94
            local AIM_EXTRA = { ['\0'] = 0, ['\1'] = 1, ['\2'] = 0, ['\3'] = 0, ['\4'] = 0, ['\5'] = 0 } -- t95
            local OFFSET_ABOVE = Vector3.new(0, -0.7, 0.05)                                -- v230/v138
            local OFFSET_BELOW = Vector3.new(0, -3.85, 0.05)                               -- v231/v139
            local PITCH_ABOVE = -math.pi / 2                                               -- v140
            local PITCH_BELOW = math.pi / 2                                                -- v141

            -- Riot-Shield-aware above/below classifier (Kicia ia(), lines 151550-151570).
            -- "None" for shield-less targets (common case) folds to Above.  Enemy
            -- itemObserver/camera are best-effort on this build; shield-less path is exact.
            local function classifyAboveBelow(target)
                local obs = target and target.itemObserver
                if obs then
                    local ok, result = pcall(function()
                        local equipped = obs:GetEquippedItem()
                        if equipped ~= nil and equipped.name == 'Riot Shield' th