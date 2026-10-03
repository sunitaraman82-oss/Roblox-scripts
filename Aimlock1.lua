local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- CONFIGURATION
local SMOOTHNESS = 0.2 -- Lower = smoother/slower, Higher = instant snap
local MAX_DISTANCE = 300 -- Maximum distance to detect targets
local enabled = true

-- Function to find the target object
local function getBestTarget()
    local closestTarget = nil
    local shortestDistance = math.huge
    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    -- Scan everything in the Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        -- Ensure it's a part, not part of your own character, and not the baseplate/floor
        if obj:IsA("BasePart") and not obj:IsDescendantOf(player.Character) and obj.Name ~= "Baseplate" and obj.Name ~= "Terrain" then
            
            -- Check distance from the player
            local distanceToPlayer = (obj.Position - camera.CFrame.Position).Magnitude
            if distanceToPlayer <= MAX_DISTANCE then
                
                -- Convert 3D world position to 2D screen space
                local screenPos, onScreen = camera:WorldToViewportPoint(obj.Position)
                
                if onScreen and screenPos.Z > 0 then
                    -- Calculate how close the target is to the crosshair
                    local targetCoord = Vector2.new(screenPos.X, screenPos.Y)
                    local distanceToCenter = (targetCoord - screenCenter).Magnitude
                    
                    if distanceToCenter < shortestDistance then
                        shortestDistance = distanceToCenter
                        closestTarget = obj
                    end
                end
            end
        end
    end
    return closestTarget
end

-- Main loop running every frame
RunService.RenderStepped:Connect(function()
    if not enabled then return end
    
    local target = getBestTarget()
    if target then
        -- CFrame.lookAt calculates the angle to face the target
        local targetRotation = CFrame.lookAt(camera.CFrame.Position, target.Position)
        
        -- Safe Linear Interpolation (Lerp) to prevent mobile camera crashing/jittering
        camera.CFrame = camera.CFrame:Lerp(targetRotation, SMOOTHNESS)
    end
end)
