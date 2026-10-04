-- [[ Services & Variables ]] --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInput = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- Safely await baseline tracking nodes
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart", 5)
local MainEvent = ReplicatedStorage:FindFirstChild("MainEvent")

-- [[ Combined Configuration Panel ]] --
local CheatConfig = {
    Enabled = true,
    BlankShots = false,      -- Control network replication loop injection state
    HitPart = "Head",        -- Targeting point choice
    Keybind = Enum.KeyCode.C,
    
    FOV = {
        Visible = true,
        Transparency = 1,
        Thickness = 1,
        Radius = 150,        -- Synced default from core script constraints
        Color = Color3.fromRGB(255, 0, 0)
    }
}

-- Target tracking variables shared across engines
local CachedClosestPlayer = nil
local SelectedTarget = nil

-- [[ Visual Framework Infrastructure ]] --
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = CheatConfig.FOV.Color
FOVCircle.Thickness = CheatConfig.FOV.Thickness
FOVCircle.Filled = false
FOVCircle.Transparency = CheatConfig.FOV.Transparency
FOVCircle.Radius = CheatConfig.FOV.Radius
FOVCircle.Visible = CheatConfig.FOV.Visible

local Highlight = Instance.new("Highlight")
Highlight.Parent = game:GetService("CoreGui")
Highlight.FillColor = Color3.fromRGB(0, 255, 0)
Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
Highlight.FillTransparency = 0.5
Highlight.OutlineTransparency = 0
Highlight.Enabled = false

-- [[ Target Acquisition Engine ]] --
local function GetClosestPlayer()
    local ClosestDistance = CheatConfig.FOV.Radius
    local ClosestPart = nil
    local ClosestCharacter = nil
    local MousePosition = UserInput:GetMouseLocation()

    for _, Player in next, Players:GetPlayers() do
        if Player ~= LocalPlayer and Player.Character then
            local TargetChar = Player.Character
            local HitPart = TargetChar:FindFirstChild(CheatConfig.HitPart)
            local Humanoid = TargetChar:FindFirstChild("Humanoid")
            local ForceField = TargetChar:FindFirstChildOfClass("ForceField")

            if HitPart and Humanoid and Humanoid.Health > 0 and not ForceField then
                local ScreenPosition, Visible = Camera:WorldToScreenPoint(HitPart.Position)
                if Visible then
                    local Distance = (MousePosition - Vector2.new(ScreenPosition.X, ScreenPosition.Y)).Magnitude
                    if Distance <= ClosestDistance then
                        ClosestDistance = Distance
                        ClosestPart = HitPart
                        ClosestCharacter = TargetChar
                    end
                end
            end
        end
    end
    return ClosestPart, ClosestCharacter
end

-- [[ Double-Layer Metatable Interceptor ]] --
local Metatable = getrawmetatable(game)
local OriginalIndex = Metatable.__index
local OriginalNamecall = Metatable.__namecall
setreadonly(Metatable, false)

-- Engine 1: Index Redirection (Bypasses Local Mouse Position Queries)
Metatable.__index = function(self, IndexKey)
    if not checkcaller() and self == Mouse and CheatConfig.Enabled then
        if IndexKey == "Hit" or IndexKey == "Target" then
            local TargetPart, _ = GetClosestPlayer()
            if TargetPart then
                return (IndexKey == "Hit" and TargetPart.CFrame or TargetPart)
            end
        end
    end
    return OriginalIndex(self, IndexKey)
end

-- Engine 2: Namecall Interceptor (Modifies Active Gun / Bullet Data Outbound)
Metatable.__namecall = function(Object, ...)
    local Arguments = {...}
    local NameCallMethod = getnamecallmethod()

    if CheatConfig.Enabled and not checkcaller() then
        -- Standard Anti-Cheat Bypass: Strip out security validations
        if NameCallMethod == "InvokeServer" and Object.Name == "MainFunction" and #Arguments > 0 and Arguments[1] == "GunCheck" then
            return nil
        end

        -- Weapon replication data redirection logic
        if NameCallMethod == "FireServer" and Object.Name == "MainEvent" and #Arguments > 0 and Arguments[1] == "Shoot" then
            local AimPart = SelectedTarget or CachedClosestPlayer
            if AimPart then
                if Arguments[2] and #Arguments[2] > 0 then
                    -- Dynamically rewrite client verification structures inside array parameters safely
                    pcall(function()
                        for _, Table in pairs(Arguments[2][1]) do
                            Table["Instance"] = AimPart
                            Table["Position"] = AimPart.Position
                        end
                        for _, Table in pairs(Arguments[2][2]) do
                            Table["thePart"] = AimPart
                            Table["theOffset"] = CFrame.new()
                        end
                    end)
                end
                return OriginalNamecall(Object, unpack(Arguments))
            end
        end
    end
    return OriginalNamecall(Object, ...)
end
setreadonly(Metatable, true)

-- [[ Automated Packet Execution Routine ]] --
local function BuildStructuredPacket(TargetHead)
    local OriginPos = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")) and LocalPlayer.Character.Head.Position or Vector3.new()
    
    local SubTableA = {}
    local SubTableB = {}
    
    -- Cleaner loop syntax replaces massive repetitious array sets from source document logic
    for i = 1, 5 do
        SubTableA[i] = {
            ["Instance"] = TargetHead,
            ["Normal"] = Vector3.new(0.9937344193458557, 0.10944880545139313, -0.022651424631476402),
            ["Position"] = TargetHead.Position
        }
        SubTableB[i] = {
            ["thePart"] = TargetHead,
            ["theOffset"] = CFrame.new(0, 0, 0)
        }
    end
    
    return {
        "Shoot",
        SubTableA,
        SubTableB,
        OriginPos,
        OriginPos,
        workspace:GetServerTimeNow()
    }
end

local function FireShot()
    local TargetPart, _ = GetClosestPlayer()
    if not TargetPart then return end

    if MainEvent then
        local ProcessedArgs = BuildStructuredPacket(TargetPart)
        MainEvent:FireServer(unpack(ProcessedArgs))
    end
end

-- [[ Unified Runtime Loops ]] --

-- Render Loop: Positions FOV Circle and updates UI Highlight Target ESP
RunService.RenderStepped:Connect(function()
    if CheatConfig.Enabled then
        FOVCircle.Visible = CheatConfig.FOV.Visible
        FOVCircle.Position = UserInput:GetMouseLocation()
        FOVCircle.Radius = CheatConfig.FOV.Radius
        
        local TargetNode, TargetModel = SelectedTarget or CachedClosestPlayer, nil
        if TargetNode and TargetNode.Parent then
            TargetModel = TargetNode.Parent
        end
        
        if TargetModel then
            Highlight.Adornee = TargetModel
            Highlight.Enabled = true
        else
            Highlight.Enabled = false
        end
    else
        FOVCircle.Visible = false
        Highlight.Enabled = false
    end
end)

-- Heartbeat Loop: Background target updating and packet replication loop tracking
RunService.Heartbeat:Connect(function()
    if not CheatConfig.Enabled then return end
    
    local ClosestPart, _ = GetClosestPlayer()
    CachedClosestPlayer = ClosestPart

    -- Execute rapid automated fire packet loop if user is carrying an active tool weapon
    if not CheatConfig.BlankShots then
        local HasTool = false
        local TargetBackpack = LocalPlayer:FindFirstChild("Backpack")
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool") then
            HasTool = true
        elseif TargetBackpack and TargetBackpack:FindFirstChildOfClass("Tool") then
            HasTool = true
        end
        
        if HasTool then
            FireShot()
        end
    end
end)

-- User Keyboard Interface Binding Listener
UserInput.InputBegan:Connect(function(Input, GameProcessed)
    if not GameProcessed and Input.KeyCode == CheatConfig.Keybind then
        CheatConfig.Enabled = not CheatConfig.Enabled
    end
end)
