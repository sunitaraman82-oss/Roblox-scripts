-- FOV-based target selection for your own Roblox experience

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

local FOV_RADIUS = 120 -- pixels
local MAX_DISTANCE = 500

local function getBestTarget()
    local bestTarget = nil
    local bestScreenDistance = FOV_RADIUS

    local center = Vector2.new(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y / 2
    )

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")

            if humanoid and humanoid.Health > 0 and root then
                local distance = (Camera.CFrame.Position - root.Position).Magnitude

                if distance <= MAX_DISTANCE then
                    local screenPosition, visible =
                        Camera:WorldToViewportPoint(root.Position)

                    if visible and screenPosition.Z > 0 then
                        local screenDistance = (
                            Vector2.new(screenPosition.X, screenPosition.Y)
                            - center
                        ).Magnitude

                        if screenDistance <= bestScreenDistance then
                            bestScreenDistance = screenDistance
                            bestTarget = player
                        end
                    end
                end
            end
        end
    end

    return bestTarget
end

-- Example:
local target = getBestTarget()

if target then
    print("Selected target:", target.Name)
end