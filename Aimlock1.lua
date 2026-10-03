local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- FRAMEWORK CORE CONFIG
local UI_SETTINGS = {
    Aimbot = true,
    Esp = true,
    Target = "Head", -- "Head", "Torso", "Random"
    Smooth = 0.12,
    Radius = 150
}

-- FOV RENDERING BOUNDS
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = true
FOVCircle.Radius = UI_SETTINGS.Radius
FOVCircle.Color = Color3.fromRGB(0, 255, 0)
FOVCircle.Thickness = 1
FOVCircle.NumSides = 64
FOVCircle.Filled = false
FOVCircle.Transparency = 0.8

-- GRAPHICAL UI INTERFACE FRAMEWORK
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalHub"
ScreenGui.Parent = (RunService:IsStudio() and player.PlayerGui or CoreGui)

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 220, 0, 250)
Frame.Position = UDim2.new(0.05, 0, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "🎯 CUSTOM TRAINER HUD"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 14
Title.Parent = Frame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

local function makeBtn(txt, pos, key)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 190, 0, 35)
    btn.Position = pos
    btn.Font = Enum.Font.SourceSansSemibold
    btn.TextSize = 14
    btn.Parent = Frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local function redraw()
        if UI_SETTINGS[key] == true then
            btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            btn.Text = txt .. ": ON"
        elseif UI_SETTINGS[key] == false then
            btn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            btn.Text = txt .. ": OFF"
        else
            btn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
            btn.Text = txt .. ": " .. tostring(UI_SETTINGS[key])
        end
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    
    btn.MouseButton1Click:Connect(function()
        if type(UI_SETTINGS[key]) == "boolean" then
            UI_SETTINGS[key] = not UI_SETTINGS[key]
        elseif key == "Target" then
            if UI_SETTINGS.Target == "Head" then UI_SETTINGS.Target = "Torso"
            elseif UI_SETTINGS.Target == "Torso" then UI_SETTINGS.Target = "Random"
            else UI_SETTINGS.Target = "Head" end
        end
        redraw()
    end)
    redraw()
end

makeBtn("Aimlock Engine", UDim2.new(0, 15, 0, 55), "Aimbot")
makeBtn("Target Logic", UDim2.new(0, 15, 0, 100), "Target")
makeBtn("Active ESP", UDim2.new(0, 15, 0, 145), "Esp")

-- COMPACT TARGET FINDER
local function scanTargets()
    local bestPart = nil
    local shortestDist = math.huge
    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    FOVCircle.Position = screenCenter

    for _, v in ipairs(Workspace:GetDescendants()) do
        local targetPos = nil
        
        -- Player rig checking
        if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") and v ~= player.Character then
            if v.Humanoid.Health > 0 then
                local pName = UI_SETTINGS.Target
                if pName == "Random" then pName = (math.random(1,2) == 1) and "Head" or "HumanoidRootPart" end
                if pName == "Torso" then pName = v:FindFirstChild("UpperTorso") and "UpperTorso" or "Torso" end
                local p = v:FindFirstChild(pName)
                if p then targetPos = p.Position end
            end
        -- Object standalone check for map target shapes
        elseif v:IsA("BasePart") and not v:IsDescendantOf(player.Character) and v.Name ~= "Baseplate" and v.Name ~= "Terrain" then
            if v.Size.X < 12 and v.Size.Y < 12 and not v.Name:lower():find("floor") and not v.Name:lower():find("wall") then
                targetPos = v.Position
            end
        end

        if targetPos then
            local screenPos, visible = camera:WorldToViewportPoint(targetPos)
            if visible and screenPos.Z > 0 then
                local m = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                if m < UI_SETTINGS.Radius and m < shortestDist then
                    shortestDist = m
                    bestPart = targetPos
                end
            end
        end
    end
    return bestPart
end

local cache = Instance.new("Folder", Workspace)

RunService.RenderStepped:Connect(function()
    cache:ClearAllChildren()
    local target = scanTargets()
    
    if UI_SETTINGS.Aimbot and target then
        local goal = CFrame.lookAt(camera.CFrame.Position, target)
        camera.CFrame = camera.CFrame:Lerp(goal, UI_SETTINGS.Smooth)
    end
    
    if UI_SETTINGS.Esp then
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsDescendantOf(player.Character) and v.Name ~= "Baseplate" and v.Name ~= "Terrain" then
                if v.Size.X < 12 and v.Size.Y < 12 and not v.Name:lower():find("floor") and not v.Name:lower():find("wall") then
                    local box = Instance.new("BoxHandleAdornment")
                    box.Size = v.Size + Vector3.new(0.3, 0.3, 0.3)
                    box.Color3 = Color3.fromRGB(0, 255, 0)
                    box.AlwaysOnTop = true
                    box.ZIndex = 5
                    box.Adornee = v
                    box.Parent = cache
                end
            end
        end
    end
end)
