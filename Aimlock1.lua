local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- SETTINGS STATE
local settings = {
    aimlockEnabled = true,
    espEnabled = true,
    targetPart = "Head", -- Options: "Head", "Torso", "Random"
    smoothness = 0.15,
    maxDistance = 400
}

-- CREATE CLEAN MOBILE UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TrainerHub"
ScreenGui.Parent = (RunService:IsStudio() and player.PlayerGui or CoreGui)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 260)
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "🎯 AIM & ESP CONFIG"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

-- Helper function to make toggle buttons
local function createToggle(text, position, configKey)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 190, 0, 35)
    button.Position = position
    button.Font = Enum.Font.SourceSansSemibold
    button.TextSize = 14
    button.Parent = MainFrame
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
    
    local function updateVisual()
        if settings[configKey] == true then
            button.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            button.Text = text .. ": ON"
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
        elseif settings[configKey] == false then
            button.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            button.Text = text .. ": OFF"
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            button.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
            button.Text = text .. ": " .. tostring(settings[configKey])
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
    
    button.MouseButton1Click:Connect(function()
        if type(settings[configKey]) == "boolean" then
            settings[configKey] = not settings[configKey]
        elseif configKey == "targetPart" then
            if settings.targetPart == "Head" then settings.targetPart = "Torso"
            elseif settings.targetPart == "Torso" then settings.targetPart = "Random"
            else settings.targetPart = "Head" end
        end
        updateVisual()
    end)
    updateVisual()
end

createToggle("Aimlock Tracker", UDim2.new(0, 15, 0, 55), "aimlockEnabled")
createToggle("Target Target Part", UDim2.new(0, 15, 0, 100), "targetPart")
createToggle("Visual ESP Boxes", UDim2.new(0, 15, 0, 145), "espEnabled")

-- TARGET CALCULATOR WITH FILTERS
local function getBestTarget()
    local closestTarget = nil
    local shortestDistance = math.huge
    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    for _, obj in ipairs(Workspace:GetDescendants()) do
        local isValid = false
        local targetPos = nil
        
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj ~= player.Character then
            -- Standard Player tracking logic
            local partName = settings.targetPart
            if partName == "Random" then
                partName = (math.random(1, 2) == 1) and "Head" or "HumanoidRootPart"
            elseif partName == "Torso" then
                partName = obj:FindFirstChild("UpperTorso") and "UpperTorso" or "Torso"
            end
            
            local chosenPart = obj:FindFirstChild(partName)
            if chosenPart and obj.Humanoid.Health > 0 then
                isValid = true
                targetPos = chosenPart.Position
            end
        elseif obj:IsA("BasePart") and not obj:IsDescendantOf(player.Character) and obj.Name ~= "Baseplate" and obj.Name ~= "Terrain" then
            -- Standing map target fallback
            if obj.Size.X < 15 and obj.Size.Y < 15 then
                isValid = true
                targetPos = obj.Position
            end
        end

        if isValid and targetPos then
            local distanceToPlayer = (targetPos - camera.CFrame.Position).Magnitude
            if distanceToPlayer <= settings.maxDistance then
                local screenPos, onScreen = camera:WorldToViewportPoint(targetPos)
                if onScreen and screenPos.Z > 0 then
                    local distanceToCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if distanceToCenter < shortestDistance then
                        shortestDistance = distanceToCenter
                        closestTarget = targetPos
                    end
                end
            end
        end
    end
    return closestTarget
end

-- ESP SYSTEM RENDERING LAYER
local espFolder = Instance.new("Folder", Workspace)
espFolder.Name = "EspCacheSystem"

RunService.RenderStepped:Connect(function()
    espFolder:ClearAllChildren()
    local targetPos = getBestTarget()
    
    -- Execute Aim Lock Frame adjustments safely
    if settings.aimlockEnabled and targetPos then
        local targetRotation = CFrame.lookAt(camera.CFrame.Position, targetPos)
        camera.CFrame = camera.CFrame:Lerp(targetRotation, settings.smoothness)
    end
    
    -- Draw Active ESP box markers if turned on
    if settings.espEnabled then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name == "Head" and not obj:IsDescendantOf(player.Character) then
                local box = Instance.new("BoxHandleAdornment")
                box.Size = Vector3.new(2, 2, 2)
                box.Color3 = Color3.fromRGB(231, 76, 60)
                box.AlwaysOnTop = true
                box.ZIndex = 5
                box.Adornee = obj
                box.Parent = espFolder
            end
        end
    end
end)
