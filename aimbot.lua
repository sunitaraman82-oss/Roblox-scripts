--!strict
-- Validates target requests and gates hitbox visibility per player.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage:WaitForChild("TrainingTargetingShared"))

local CONFIG = {
    TrainingEnabled    = true,
    AuthorizedUserIds  = {},
    MaxDistance        = 250,
    RequireLineOfSight = true,
    AllowTeamTargeting = false,
    ValidateCooldown   = 0.05,
}

local function ensureRemote(name, className)
    local inst = ReplicatedStorage:FindFirstChild(name)
    if not inst then
        inst = Instance.new(className)
        inst.Name = name
        inst.Parent = ReplicatedStorage
    end
    return inst
end

local ValidateTarget      = ensureRemote("TT_ValidateTarget", "RemoteFunction")
local SetHitboxVisibility = ensureRemote("TT_SetHitboxVisibility", "RemoteEvent")

local function isAuthorized(player)
    if not CONFIG.TrainingEnabled then return false end
    if #CONFIG.AuthorizedUserIds == 0 then return true end
    return table.find(CONFIG.AuthorizedUserIds, player.UserId) ~= nil
end

local lastValidateAt = {}

ValidateTarget.OnServerInvoke = function(player, candidate)
    if not isAuthorized(player) then
        return nil, "NotAuthorized"
    end

    local now = os.clock()
    if lastValidateAt[player] and (now - lastValidateAt[player]) < CONFIG.ValidateCooldown then
        return nil, "Cooldown"
    end
    lastValidateAt[player] = now

    if typeof(candidate) ~= "Instance" or not candidate:IsA("Model") then
        return nil, "InvalidTarget"
    end
    if candidate == player.Character then
        return nil, "SelfTarget"
    end
    if not Shared.IsAlive(candidate) then
        return nil, "TargetDead"
    end

    local targetPlayer = Players:GetPlayerFromCharacter(candidate)
    if not targetPlayer then
        return nil, "NotPlayerCharacter"
    end

    local myRoot    = Shared.GetRootPart(player.Character)
    local theirRoot = Shared.GetRootPart(candidate)
    if not myRoot or not theirRoot then
        return nil, "MissingRoot"
    end

    local dist = (myRoot.Position - theirRoot.Position).Magnitude
    if dist > CONFIG.MaxDistance then
        return nil, "OutOfRange"
    end

    if not CONFIG.AllowTeamTargeting then
        if player.Team and targetPlayer.Team and player.Team == targetPlayer.Team then
            return nil, "SameTeam"
        end
    end

    local aimPart = Shared.GetAimPart(candidate, true)
    if not aimPart then
        return nil, "NoAimPart"
    end

    if CONFIG.RequireLineOfSight and not Shared.HasLineOfSight(myRoot, aimPart) then
        return nil, "NoLineOfSight"
    end

    return {
        Character   = candidate,
        AimPartName = aimPart.Name,
        Distance    = dist,
        ValidatedAt = now,
    }
end

SetHitboxVisibility.OnServerEvent:Connect(function(player, enabled)
    if not isAuthorized(player) then return end
    player:SetAttribute("TT_HitboxesEnabled", enabled == true)
end)

Players.PlayerRemoving:Connect(function(player)
    lastValidateAt[player] = nil
end)
--!strict
-- UI, target acquisition, smooth camera assist, and local hitbox visuals.

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")

local Shared = require(ReplicatedStorage:WaitForChild("TrainingTargetingShared"))

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local ValidateTarget      = ReplicatedStorage:WaitForChild("TT_ValidateTarget")
local SetHitboxVisibility = ReplicatedStorage:WaitForChild("TT_SetHitboxVisibility")

local CONFIG = {
    MaxDistance        = 250,
    DeadzoneRadians    = math.rad(2),
    MaxAngularSpeed    = math.rad(540),
    RevalidateInterval = 0.15,
}

local State = {
    TargetLock    = false,
    ShowHitboxes  = false,
    Smoothness    = 25,
    FOVPixels     = 200,
    CurrentTarget = nil,
}

local function buildUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "TrainingTargetingUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = player:WaitForChild("PlayerGui")

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 260, 0, 280)
    panel.Position = UDim2.new(0, 20, 0.5, -140)
    panel.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
    panel.BackgroundTransparency = 0.15
    panel.BorderSizePixel = 0
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 32)
    title.BackgroundTransparency = 1
    title.Text = "Training Targeting"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Parent = panel

    local lockBtn = Instance.new("TextButton")
    lockBtn.Size = UDim2.new(1, -20, 0, 32)
    lockBtn.Position = UDim2.new(0, 10, 0, 38)
    lockBtn.BackgroundColor3 = Color3.fromRGB(170, 60, 60)
    lockBtn.TextColor3 = Color3.new(1, 1, 1)
    lockBtn.Font = Enum.Font.Gotham
    lockBtn.TextSize = 14
    lockBtn.Text = "Target Lock: OFF"
    lockBtn.BorderSizePixel = 0
    lockBtn.Parent = panel
    Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 6)

    local hbBtn = Instance.new("TextButton")
    hbBtn.Size = UDim2.new(1, -20, 0, 32)
    hbBtn.Position = UDim2.new(0, 10, 0, 76)
    hbBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 66)
    hbBtn.TextColor3 = Color3.new(1, 1, 1)
    hbBtn.Font = Enum.Font.Gotham
    hbBtn.TextSize = 14
    hbBtn.Text = "Show Hitboxes: OFF"
    hbBtn.BorderSizePixel = 0
    hbBtn.Parent = panel
    Instance.new("UICorner", hbBtn).CornerRadius = UDim.new(0, 6)

    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(1, -20, 0, 32)
    resetBtn.Position = UDim2.new(0, 10, 0, 114)
    resetBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 66)
    resetBtn.TextColor3 = Color3.new(1, 1, 1)
    resetBtn.Font = Enum.Font.Gotham
    resetBtn.TextSize = 14
    resetBtn.Text = "Reset"
    resetBtn.BorderSizePixel = 0
    resetBtn.Parent = panel
    Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 6)

    local function makeSlider(labelY, trackY, labelText, minV, maxV, initV, onChange)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 20)
        lbl.Position = UDim2.new(0, 10, 0, labelY)
        lbl.BackgroundTransparency = 1
        lbl.Text = string.format("%s: %d", labelText, initV)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.TextColor3 = Color3.new(1, 1, 1)
        lbl.Parent = panel

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -20, 0, 10)
        track.Position = UDim2.new(0, 10, 0, trackY)
        track.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
        track.BorderSizePixel = 0
        track.Active = true
        track.Parent = panel
        Instance.new("UICorner", track).CornerRadius = UDim.new(0, 4)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((initV - minV) / (maxV - minV), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(90, 160, 255)
        fill.BorderSizePixel = 0
        fill.Parent = track
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

        local dragging = false
        local function apply(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            local v = minV + (maxV - minV) * rel
            lbl.Text = string.format("%s: %d", labelText, math.floor(v + 0.5))
            onChange(v)
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                apply(input.Position.X)
            end
        end)
        track.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
                apply(input.Position.X)
            end
        end)
    end

    makeSlider(154, 176, "Smoothness", 0, 100, State.Smoothness,
        function(v) State.Smoothness = v end)
    makeSlider(198, 220, "FOV", 50, 500, State.FOVPixels,
        function(v) State.FOVPixels = v end)

    lockBtn.MouseButton1Click:Connect(function()
        State.TargetLock = not State.TargetLock
        lockBtn.Text = "Target Lock: " .. (State.TargetLock and "ON" or "OFF")
        lockBtn.BackgroundColor3 = State.TargetLock
            and Color3.fromRGB(70, 170, 70)
            or Color3.fromRGB(170, 60, 60)
        if not State.TargetLock then
            State.CurrentTarget = nil
        end
    end)

    hbBtn.MouseButton1Click:Connect(function()
        SetHitboxVisibility:FireServer(not State.ShowHitboxes)
    end)

    resetBtn.MouseButton1Click:Connect(function()
        State.TargetLock = false
        State.CurrentTarget = nil
        lockBtn.Text = "Target Lock: OFF"
        lockBtn.BackgroundColor3 = Color3.fromRGB(170, 60, 60)
        SetHitboxVisibility:FireServer(false)
    end)

    local function syncHbButton()
        local on = player:GetAttribute("TT_HitboxesEnabled") == true
        State.ShowHitboxes = on
        hbBtn.Text = "Show Hitboxes: " .. (on and "ON" or "OFF")
        hbBtn.BackgroundColor3 = on
            and Color3.fromRGB(70, 170, 70)
            or Color3.fromRGB(60, 60, 66)
    end
    player:GetAttributeChangedSignal("TT_HitboxesEnabled"):Connect(syncHbButton)
    syncHbButton()

    return gui
end

buildUI()

local hitboxHighlights = {}

local function clearHitboxes()
    for _, hl in pairs(hitboxHighlights) do
        if hl and hl.Parent then hl:Destroy() end
    end
    hitboxHighlights = {}
end

local function rebuildHitboxes()
    clearHitboxes()
    if player:GetAttribute("TT_HitboxesEnabled") ~= true then return end
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player and Shared.IsAlive(other.Character) then
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(255, 90, 90)
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency = 0.78
            hl.OutlineTransparency = 0.15
            hl.DepthMode = Enum.HighlightDepthMode.Occluded
            hl.Adornee = other.Character
            hl.Parent = Workspace
            hitboxHighlights[other.Character] = hl
        end
    end
end

player:GetAttributeChangedSignal("TT_HitboxesEnabled"):Connect(rebuildHitboxes)
Players.PlayerAdded:Connect(function() task.defer(rebuildHitboxes) end)
Players.PlayerRemoving:Connect(function() task.defer(rebuildHitboxes) end)
player.CharacterAdded:Connect(function() task.defer(rebuildHitboxes) end)

local function viewportCenter()
    local vp = camera.ViewportSize
    return Vector2.new(vp.X * 0.5, vp.Y * 0.5)
end

local function screenDistance(part)
    local pos, onScreen = camera:WorldToScreenPoint(part.Position)
    if not onScreen then return math.huge end
    return (Vector2.new(pos.X, pos.Y) - viewportCenter()).Magnitude
end

local function findBestCandidate()
    local myChar = player.Character
    if not Shared.IsAlive(myChar) then return nil end
    local myRoot = Shared.GetRootPart(myChar)
    if not myRoot then return nil end

    local bestScore = math.huge
    local bestChar = nil

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player and Shared.IsAlive(other.Character) then
            local aimPart = Shared.GetAimPart(other.Character, true)
            if aimPart then
                local worldDist = (myRoot.Position - aimPart.Position).Magnitude
                if worldDist <= CONFIG.MaxDistance then
                    local screenDist = screenDistance(aimPart)
                    if screenDist <= State.FOVPixels then
                        local score = screenDist + worldDist * 0.05
                        if score < bestScore then
                            bestScore, bestChar = score, other.Character
                        end
                    end
                end
            end
        end
    end
    return bestChar
end

task.spawn(function()
    while true do
        task.wait(CONFIG.RevalidateInterval)
        if not State.TargetLock then
            State.CurrentTarget = nil
        else
            local cand = findBestCandidate()
            if cand then
                local ok, result = pcall(function()
                    return ValidateTarget:InvokeServer(cand)
                end)
                if ok and type(result) == "table" and result.Character then
                    State.CurrentTarget = result
                else
                    State.CurrentTarget = nil
                end
            else
                State.CurrentTarget = nil
            end
        end
    end
end)

RunService:BindToRenderStep(
    "TT_AimAssist",
    Enum.RenderPriority.Camera.Value + 1,
    function(dt)
        if not State.TargetLock then return end
        local target = State.CurrentTarget
        if not target or not target.Character then return end
        if not Shared.IsAlive(target.Character) then
            State.CurrentTarget = nil
            return
        end

        local aimPart = Shared.GetAimPart(target.Character, target.AimPartName == "Head")
        if not aimPart then
            State.CurrentTarget = nil
            return
        end

        local myRoot = Shared.GetRootPart(player.Character)
        if not myRoot then return end
        if (myRoot.Position - aimPart.Position).Magnitude > CONFIG.MaxDistance * 1.25 then
            State.CurrentTarget = nil
            return
        end

        local camPos = camera.CFrame.Position
        local look = camera.CFrame.LookVector
        local desired = aimPart.Position - camPos
        if desired.Magnitude < 0.05 then return end
        desired = desired.Unit

        local dot = math.clamp(look:Dot(desired), -1, 1)
        local angle = math.acos(dot)
        if angle <= CONFIG.DeadzoneRadians then return end

        local rate = math.max(0.01, State.Smoothness / 5)
        local alpha = 1 - math.exp(-rate * dt)
        local maxStep = CONFIG.MaxAngularSpeed * dt
        local stepAlpha = math.min(alpha, maxStep / math.max(angle, 1e-6))

        local newDir = look:Lerp(desired, stepAlpha)
        if newDir.Magnitude < 1e-4 then return end
        camera.CFrame = CFrame.lookAt(camPos, camPos + newDir.Unit)
    end
)
--!strict
-- Character helpers shared by server and client.

local Shared = {}

function Shared.GetAimPart(character, useHead)
    if not character then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil end
    if useHead == nil then useHead = true end

    if useHead then
        local head = character:FindFirstChild("Head")
        if head and head:IsA("BasePart") then return head end
    end

    local upper = character:FindFirstChild("UpperTorso")
    if upper and upper:IsA("BasePart") then return upper end

    local torso = character:FindFirstChild("Torso")
    if torso and torso:IsA("BasePart") then return torso end

    local head = character:FindFirstChild("Head")
    if head and head:IsA("BasePart") then return head end

    return nil
end

function Shared.IsAlive(character)
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return humanoid ~= nil and humanoid.Health > 0
end

function Shared.GetRootPart(character)
    if not character then return nil end
    local rp = character:FindFirstChild("HumanoidRootPart")
    if rp and rp:IsA("BasePart") then return rp end
    return Shared.GetAimPart(character, false)
end

function Shared.HasLineOfSight(fromPart, toPart)
    if not fromPart or not toPart then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = {}
    if fromPart.Parent then table.insert(exclude, fromPart.Parent) end
    if toPart.Parent then table.insert(exclude, toPart.Parent) end
    params.FilterDescendantsInstances = exclude

    local dir = toPart.Position - fromPart.Position
    if dir.Magnitude < 0.05 then return true end
    return workspace:Raycast(fromPart.Position, dir, params) == nil
end

return Shared