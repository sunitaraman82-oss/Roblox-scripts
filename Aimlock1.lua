-- ==========================================================
-- Extracted Aimbot & Silent Aim from Kicia Rebuild (Rivals)
-- Requires Delta Executor / getrawmetatable
-- ==========================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- [[ CONFIGURATION ]] --
local Config = {
    AimbotEnabled = true,
    SilentAimEnabled = true,
    FOV = 150,
    Smoothness = 0.15, -- For regular Aimbot
    Prediction = 0.15, -- Base prediction multiplier
    HitPart = "Head",  -- "Head", "Torso", "Closest"
    MaxAngle = 45,     -- Max angle to lock (degrees)
}

-- [[ TARGET CACHE ]] --
local CachedTargets = {}
local LastCacheTime = 0
local CacheRate = 1 -- Seconds

-- [[ HELPER: Check if target is visible (Wall Check) ]] --
local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude
RayParams.IgnoreWater = true

local function IsVisible(from, to, character)
    local ignoreList = { LocalPlayer.Character, Camera }
    for _, obj in ipairs(character:GetChildren()) do
        if obj:IsA("Accessory") or obj:IsA("Tool") or obj:IsA("Hat") then
            table.insert(ignoreList, obj)
        end
    end
    RayParams.FilterDescendantsInstances = ignoreList
    
    local hit = Workspace:Raycast(from, to - from, RayParams)
    if not hit then return true end
    return hit.Instance:IsDescendantOf(character)
end

-- [[ HELPER: Get Target Part ]] --
local function GetPart(character)
    if Config.HitPart == "Head" then
        return character:FindFirstChild("Head")
    elseif Config.HitPart == "Torso" then
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("LowerTorso")
    elseif Config.HitPart == "Closest" then
        local closestPart = nil
        local shortestDist = math.huge
        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                local dist = (part.Position - Camera.CFrame.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closestPart = part
                end
            end
        end
        return closestPart or character:FindFirstChild("HumanoidRootPart")
    end
    return character:FindFirstChild("Head")
end

-- [[ HELPER: Prediction (From Kicia Source) ]] --
local function GetPredictedPosition(part)
    local ping = LocalPlayer:GetNetworkPing() * 2
    local velocity = part.AssemblyLinearVelocity
    -- Using their prediction formula
    return part.Position + (velocity * (Config.Prediction + ping))
end

-- [[ TARGET SCANNER (Based on Kicia's RefreshCache) ]] --
local function RefreshTargets()
    if tick() - LastCacheTime < CacheRate then return end
    LastCacheTime = tick()
    table.clear(CachedTargets)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(CachedTargets, plr.Character)
            end
        end
    end
end

-- [[ MAIN TARGETING LOGIC (Based on Kicia's GetTarget) ]] --
local LastTarget, LastPart = nil, nil
local function FindTarget()
    RefreshTargets()
    
    local mouse = UserInputService:GetMouseLocation()
    local cx, cy = mouse.X, mouse.Y
    -- Use camera center for mobile/aimbot center
    if UserInputService.TouchEnabled then
        cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
    end

    local camPos = Camera.CFrame.Position
    local camLook = Camera.CFrame.LookVector
    local bestPos, bestPart, bestDist = nil, nil, Config.FOV

    for _, model in ipairs(CachedTargets) do
        local hum = model:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            for _, name in ipairs({Config.HitPart}) do
                local part = GetPart(model)
                if part and part:IsA("BasePart") then
                    local aim = GetPredictedPosition(part)
                    local s, onScreen = Camera:WorldToViewportPoint(aim)

                    if onScreen then
                        local dx, dy = s.X - cx, s.Y - cy
                        local d = math.sqrt(dx * dx + dy * dy)
                        if d < bestDist then
                            local dir = (aim - camPos).Unit
                            if camLook:Dot(dir) > math.cos(math.rad(Config.MaxAngle)) then
                                if IsVisible(camPos, aim, model) then
                                    bestDist = d
                                    bestPos = aim
                                    bestPart = part
                                end
                            end
                        end
                    end
                    break
                end
            end
        end
    end
    LastTarget, LastPart = bestPos, bestPart
    return bestPos, bestPart
end

-- [[ SILENT AIM HOOK (Extracted from Kicia's UpdateState Hook) ]] --
local silentAimActive = false
local originalIndex

local function EnableSilentAim()
    if silentAimActive then return end
    silentAimActive = true
    
    local mt = getrawmetatable(game)
    local oldIndex = mt.__index
    originalIndex = oldIndex

    mt.__index = newcclosure(function(self, key)
        -- Hook the Camera's CFrame to return the target's position
        if self == Camera and key == "CFrame" and Config.SilentAimEnabled and LastTarget then
            return CFrame.lookAt(Camera.CFrame.Position, LastTarget)
        end
        return oldIndex(self, key)
    end)
end

local function DisableSilentAim()
    if not silentAimActive then return end
    silentAimActive = false
    local mt = getrawmetatable(game)
    mt.__index = originalIndex
end

-- [[ AIMBOT CAMERA MOVE ]] --
local function AimAt(targetPos)
    local desired = CFrame.lookAt(Camera.CFrame.Position, targetPos)
    local alpha = 1 - (Config.Smoothness * 0.9) 
    if alpha < 0.01 then alpha = 0.01 end
    Camera.CFrame = Camera.CFrame:Lerp(desired, alpha)
end

-- [[ MAIN LOOP ]] --
RunService.RenderStepped:Connect(function()
    if not Config.AimbotEnabled and not Config.SilentAimEnabled then 
        if silentAimActive then DisableSilentAim() end
        return 
    end

    local targetPos, targetPart = FindTarget()

    if Config.SilentAimEnabled then
        if not silentAimActive then EnableSilentAim() end
    else
        if silentAimActive then DisableSilentAim() end
    end

    if targetPos and Config.AimbotEnabled and not Config.SilentAimEnabled then
        AimAt(targetPos)
    end
end)

-- Initialize
EnableSilentAim()