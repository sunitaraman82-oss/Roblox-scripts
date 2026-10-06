--[[ SETTINGS ]]--
getgenv().Settings = {
    SilentAim = true,
    ToggleKey = Enum.KeyCode.Q,
    TargetPart = "HumanoidRootPart",
    Prediction = 0.1,
    Offset = 0.0,
    Resolver = false,
    HealthThreshold = 1,
    TeamCheck = true,
    FOVRadius = 120,
    FOVThreshold = 0.5
}

--[[ SERVICES ]]--
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--[[ VARIABLES ]]--
local Victim, Velocity, OldPosition = nil, Vector3.zero, Vector3.zero

--[[ DRAW FOV CIRCLE ]]--
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = true
FOVCircle.Radius = Settings.FOVRadius
FOVCircle.Color = Color3.fromRGB(0, 255, 140)
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false
FOVCircle.Transparency = 0.6

RunService.RenderStacked:Connect(function()
    FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y)
    FOVCircle.Visible = Settings.SilentAim
end)

--[[ TOGGLE KEY ]]--
UIS.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Settings.ToggleKey then
        Settings.SilentAim = not Settings.SilentAim
        print("Silent Aim:", Settings.SilentAim)
    end
end)

--[[ HELPERS ]]--
local function IsVisible(part)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.IgnoreWater = true

    local result = workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit, rayParams)
    return result and result.Instance:IsDescendantOf(part.Parent)
end

local function IsInFOV(part)
    local direction = (part.Position - Camera.CFrame.Position).Unit
    return direction:Dot(Camera.CFrame.LookVector) > Settings.FOVThreshold
end

local function GetClosestTarget()
    local closest, shortest = nil, math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Settings.TargetPart) then
            if Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end

            local part = player.Character[Settings.TargetPart]
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

            if humanoid and humanoid.Health > Settings.HealthThreshold then
                if IsInFOV(part) and IsVisible(part) then
                    local success, screenPos = pcall(Camera.WorldToViewportPoint, Camera, part.Position)
                    if success and screenPos.Z > 0 then
                        local dist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                        if dist < shortest and dist <= Settings.FOVRadius then
                            closest, shortest = part, dist
                        end
                    end
                end
            end
        end
    end

    return closest
end

--[[ PREDICTION TRACKING ]]--
RunService.Heartbeat:Connect(function(dt)
    if Victim and Victim.Parent then
        local currentPos = Victim.Position
        local displacement = currentPos - OldPosition
        local estimated = displacement / dt

        Velocity = Velocity:Lerp(Vector3.new(
            estimated.X,
            estimated.Y * 0.94 * Settings.Offset,
            estimated.Z
        ), 0.4)

        OldPosition = currentPos
    end
end)

--[[ NAMECALL HOOKING ]]--
if not getgenv().__silent_hooked then
    local mt = getrawmetatable(game)
    setreadonly(mt, false)

    local oldNamecall = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local args, method = {...}, getnamecallmethod()

        if Settings.SilentAim and (tostring(self):lower():find("hit") or tostring(self):lower():find("target")) then
            Victim = GetClosestTarget()

            if Victim and Victim.Parent then
                local predicted = Settings.Resolver 
                    and Victim.Position + (Velocity * Settings.Prediction)
                    or Victim.Position + (Victim.Velocity * Settings.Prediction)

                if method == "FireServer" or method == "InvokeServer" then
                    if typeof(args[1]) == "Vector3" then
                        args[1] = predicted
                    elseif typeof(args[1]) == "CFrame" then
                        args[1] = CFrame.new(predicted)
                    end
                end
            end
        end

        return oldNamecall(self, unpack(args))
    end)

    setreadonly(mt, true)
    getgenv().__silent_hooked = true
end
