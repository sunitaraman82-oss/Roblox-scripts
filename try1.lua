
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "FeatureToggleUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(230, 230)
main.Position = UDim2.new(0.5, -115, 0.5, -115)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundTransparency = 1
title.Text = "Feature Panel"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.Parent = main

local function createToggle(name, y)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -30, 0, 45)
    button.Position = UDim2.new(0, 15, 0, y)
    button.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
    button.Text = name .. ": OFF"
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 16
    button.Font = Enum.Font.GothamSemibold
    button.BorderSizePixel = 0
    button.Parent = main

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = button

    local enabled = false

    button.Activated:Connect(function()
        enabled = not enabled

        if enabled then
            button.Text = name .. ": ON"
            button.BackgroundColor3 = Color3.fromRGB(45, 140, 75)
        else
            button.Text = name .. ": OFF"
            button.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
        end

        -- Put your own Studio feature logic here.
        print(name, enabled and "enabled" or "disabled")
    end)

    return button
end

createToggle("Silent Aim", 55)
createToggle("Triggerbot", 110)
createToggle("ESP", 165)

local openButton = Instance.new("TextButton")
openButton.Size = UDim2.fromOffset(55, 55)
openButton.Position = UDim2.new(0, 15, 0.5, -27)
openButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
openButton.Text = "☰"
openButton.TextColor3 = Color3.new(1, 1, 1)
openButton.TextSize = 25
openButton.Font = Enum.Font.GothamBold
openButton.BorderSizePixel = 0
openButton.Parent = gui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(1, 0)
openCorner.Parent = openButton

openButton.Activated:Connect(function()
    main.Visible = not main.Visible
end)
---
getgenv().Config = {
    HitPart = "Head",
    FOVRadius = 300,
    ShowFOV = true
}

local phem1_plrs = game:GetService("Players")
local phem2_cs = game:GetService("CollectionService")
local phem5 = game:GetService("ReplicatedStorage")
local phem6 = phem1_plrs.LocalPlayer
local phem7 = require(phem5.Modules.Utility)
local phem8 = phem7.Raycast

local phem4 = Drawing.new("Circle")
phem4.Visible = getgenv().Config.ShowFOV
phem4.Radius = getgenv().Config.FOVRadius
phem4.Color = Color3.fromRGB(255, 255, 255)
phem4.Thickness = 1
phem4.Filled = false

game:GetService("RunService").RenderStepped:Connect(function()
    phem4.Position = workspace.CurrentCamera.ViewportSize / 2
    phem4.Radius = getgenv().Config.FOVRadius
    phem4.Visible = getgenv().Config.ShowFOV
end)

local function phem9()
    local phem10 = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
    local phem11 = nil
    local phem12 = getgenv().Config.FOVRadius
    for phem13, phem14 in phem2_cs:GetTagged("Entity") do
        if phem14 == phem6.Character then 
            continue 
        end
        local phem15 = phem14:FindFirstChild(getgenv().Config.HitPart, true)
        if not phem15 or not phem15:IsA("BasePart") then 
            continue 
        end
        local phem16, phem17 = workspace.CurrentCamera:WorldToViewportPoint(phem15.Position)
        if not phem17 then 
            continue 
        end
        local phem18 = (phem10 - Vector2.new(phem16.X, phem16.Y)).Magnitude
        if phem18 < phem12 then
            phem12 = phem18
            phem11 = phem15
        end
    end
    return phem11
end

phem7.Raycast = function(self, phem19, phem20, phem21, phem22, phem23, phem24)
    if type(phem21) ~= "number" or phem21 < 100 then
        return phem8(self, phem19, phem20, phem21, phem22, phem23, phem24)
    end
    local phem25 = phem9()
    if not phem25 then
        return phem8(self, phem19, phem20, phem21, phem22, phem23, phem24)
    end
    local phem26 = phem25.Position
    local phem27 = (phem26 - phem19).Unit
    local phem28 = (phem26 - phem19).Magnitude
    if phem28 > phem21 then
        phem28 = phem21
        phem26 = phem19 + (phem27 * phem21)
    end
    return {
        Position = phem26,
        Distance = phem28,
        Instance = phem25,
        Material = phem25.Material,
        Normal = -phem27
    }
end
---
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Triggerbot = {}
Triggerbot.__index = Triggerbot

local HITBOX_NAMES = { "HitboxBody", "HitboxHead", "HitboxHands" }

function Triggerbot.new(clientFighter, clientItem, input)
    local self = setmetatable({}, Triggerbot)
    self.clientFighter = clientFighter
    self.clientItem = clientItem
    self.input = input

    self.rayParams = RaycastParams.new()
    self.rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local function buildFilter()
        local filter = {}
        local characters = workspace:FindFirstChild("characters")
        if characters then
            table.insert(filter, characters)
        end
        local localChar = LocalPlayer.Character
        if localChar then
            table.insert(filter, localChar)
        end
        self.rayParams.FilterDescendantsInstances = filter
    end

    local function isScopedWeapon(item)
        if not item then return false end
        local weaponName = item.Name
        local scoped = Options.triggerbot_scoped.Value or {}
        for weapon, enabled in pairs(scoped) do
            if enabled and weaponName == weapon then
                return true
            end
        end
        return false
    end

    local function rayToTarget()
        local cam = workspace.CurrentCamera
        if not cam then return nil end

        buildFilter()

        local origin = cam.CFrame.Position
        local direction = cam.CFrame.LookVector
        local maxDistance = Options.triggerbot_max_distance.Value

        local result = workspace:Raycast(origin, direction * maxDistance, self.rayParams)
        if not result then return nil end

        local instance = result.Instance
        if not instance then return nil end

        local blacklist = Options.triggerbot_part_blacklist.Value or {}
        if blacklist[instance.Name] then
            return nil
        end

        local character = instance:FindFirstAncestorOfClass("Model")
        if not character then return nil end

        local hum = character:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then return nil end

        local ally = character:FindFirstChild("_is_ally")
        if ally and ally.Value then return nil end

        for _, name in ipairs(HITBOX_NAMES) do
            if instance.Name == name then
                return instance
            end
        end
        return nil
    end

    local function tryShoot()
        if not Toggles.triggerbot_enabled.Value then return end
        if not self:keyHeld() then return end

        local target = rayToTarget()
        if not target then return end

        local reaction = Options.triggerbot_reaction_time.Value
        local offset = Options.triggerbot_reaction_time_offset.Value
        local delay = Options.triggerbot_shoot_delay.Value

        task.delay((reaction + offset) / 1000, function()
            task.wait(delay / 1000)
            if not Toggles.triggerbot_enabled.Value then return end
            if self.clientItem then
                pcall(function()
                    self.clientItem:Input(nil)
                end)
            elseif self.input then
                pcall(function()
                    self.input(nil)
                end)
            end
        end)
    end

    function self:keyHeld()
        local mode = Toggles.triggerbot_keybind.Mode
        local key = Toggles.triggerbot_keybind.Value
        if mode == "Always" then
            return true
        end
        if mode == "Hold" then
            return UserInputService:IsKeyDown(key)
        end
        if mode == "Toggle" then
            return Toggles.triggerbot_keybind.KeyDown
        end
        return true
    end

    local function onHeartbeat()
        tryShoot()
    end

    RunService.Heartbeat:Connect(onHeartbeat)
    RunService.RenderStepped:Connect(function()
        if LocalPlayer.Character then
            buildFilter()
        end
    end)

    return self
end

return Triggerbot
---
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local ESP = {}
ESP.__index = ESP

local SKELETON_PARTS = {
    "RightHand", "LeftLowerArm", "RightLowerArm", "LeftUpperArm", "RightUpperArm",
    "LowerTorso", "LeftLowerLeg", "LeftUpperLeg", "LeftFoot", "RightFoot",
    "RightLowerLeg", "RightUpperLeg", "UpperTorso", "LeftHand", "Head",
}

local SKELETON_LINES = {
    { "LeftUpperArm", "UpperTorso" },
    { "LeftLowerArm", "LeftUpperArm" },
    { "LeftLowerArm", "LeftHand" },
    { "RightUpperArm", "UpperTorso" },
    { "RightLowerArm", "RightUpperArm" },
    { "RightHand", "RightLowerArm" },
    { "LeftUpperLeg", "LowerTorso" },
    { "LeftLowerLeg", "LeftUpperLeg" },
    { "LeftFoot", "LeftLowerLeg" },
    { "RightUpperLeg", "LowerTorso" },
    { "RightLowerLeg", "RightUpperLeg" },
    { "RightFoot", "RightLowerLeg" },
    { "LowerTorso", "UpperTorso" },
}

local SMALL_FONTS = {
    ["smallest pixel"] = 8,
    ["proggy tiny"] = 10,
    ["pixel arial"] = 11,
}

function ESP.new()
    local self = setmetatable({}, ESP)
    self.players = {}
    self.events = {
        esp_color_changed = Instance.new("BindableEvent"),
        esp_fill_changed = Instance.new("BindableEvent"),
        esp_effects_changed = Instance.new("BindableEvent"),
        esp_effects_color_changed = Instance.new("BindableEvent"),
    }

    local function makeDrawing(kind, props)
        local drawing = Drawing.new(kind)
        for key, value in pairs(props) do
            drawing[key] = value
        end
        return drawing
    end

    local function makeText()
        local text = makeDrawing("Text", {
            Outline = true,
            Visible = false,
            Color = Color3.new(1, 1, 1),
            Center = true,
            Middle = true,
            Size = 12,
        })
        return text
    end

    local function makeSquare()
        return makeDrawing("Square", { Visible = false, Outline = true })
    end

    local function makeLine()
        return makeDrawing("Line", { Visible = false })
    end

    local function makeImage()
        return makeDrawing("Image", { Visible = false, Outline = true })
    end

    local function gradientOptions(prefix)
        local options = {}
        local index = 1
        while true do
            local option = Options[prefix .. index]
            if not option then break end
            table.insert(options, option)
            index = index + 1
        end
        return options
    end

    local function colorSequenceFromOptions(prefix, transparency)
        local options = gradientOptions(prefix)
        if #options == 0 then
            return ColorSequence.new(Color3.new(1, 1, 1))
        end
        local keypoints = {}
        for i, option in ipairs(options) do
            local t = (#options > 1) and ((i - 1) / (#options - 1)) or 0
            local value = transparency and option.Transparency or option.Color
            table.insert(keypoints, ColorSequenceKeypoint.new(t, value))
        end
        return ColorSequence.new(keypoints)
    end

    local function updatePlayerState(player, character)
        local state = self.players[player]
        if not state then
            state = self:createState(player, character)
            self.players[player] = state
        end
        state.character = character
        state.humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
        state.humanoid = character:WaitForChild("Humanoid", 10)
        state.parts = {}

        local connections = state.connections
        table.insert(connections, state.humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            state.health = state.humanoid.Health
        end))
        table.insert(connections, state.humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
            state.maxHealth = state.humanoid.MaxHealth
        end))
        state.health = state.humanoid.Health
        state.maxHealth = state.humanoid.MaxHealth

        for _, partName in ipairs(SKELETON_PARTS) do
            local part = character:WaitForChild(partName, 10)
            if not part then continue end
            state.parts[partName] = part
            state.corners[partName] = self:computeCorners(part)
        end

        task.wait()
    end

    return self
end

function ESP:computeCorners(part)
    local size = part.Size / 2
    local corners = {}
    local x, y, z = size.X, size.Y, size.Z
    table.insert(corners, Vector3.new(-x, -y, -z))
    table.insert(corners, Vector3.new(-x, -y, z))
    table.insert(corners, Vector3.new(-x, y, -z))
    table.insert(corners, Vector3.new(-x, y, z))
    table.insert(corners, Vector3.new(x, -y, -z))
    table.insert(corners, Vector3.new(x, -y, z))
    table.insert(corners, Vector3.new(x, y, -z))
    table.insert(corners, Vector3.new(x, y, z))
    return corners
end

local IMAGES = {
    default = { image = "", size = 1 },
    circle = { image = "rbxassetid://133898707", size = 1 },
    diamond = { image = "rbxassetid://146699083", size = 1 },
    heart = { image = "rbxassetid://134603269", size = 1 },
}

function ESP:createState(player, character)
    local state = {
        player = player,
        character = character,
        humanoid = nil,
        humanoidRootPart = nil,
        health = 0,
        maxHealth = 150,
        parts = {},
        corners = {},
        connections = {},
        drawings = {},
        squares = {},
        images = {},
        lines = {},
        text = {},
    }

    for i = 1, 26 do
        local outline = i > 13
        local line = Drawing.new("Line")
        line.Visible = false
        line.Thickness = 1 + (outline and 2 or 0)
        line.Color = outline and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
        table.insert(state.drawings, line)
        table.insert(state.lines, line)
    end

    for i = 1, 4 do
        local text = Drawing.new("Text")
        text.Outline = true
        text.Visible = false
        text.Color = Color3.new(1, 1, 1)
        text.Center = true
        text.Middle = true
        text.Size = 12
        table.insert(state.drawings, text)
        table.insert(state.text, text)
    end

    for i = 1, 4 do
        local square = Drawing.new("Square")
        square.Visible = false
        square.Outline = true
        table.insert(state.drawings, square)
        table.insert(state.squares, square)
    end

    local image = Drawing.new("Image")
    image.Visible = false
    image.Outline = true
    image.Color = Color3.new(1, 1, 1)
    image.Filled = true
    table.insert(state.drawings, image)
    table.insert(state.images, image)

    state.squares[1].Thickness = 3
    state.squares[2].ZIndex = 2
    state.squares[2].Color = Color3.new(1, 1, 1)
    state.squares[3].ZIndex = 2
    state.squares[3].Color = Color3.new(1, 1, 1)
    state.squares[3].Filled = true
    state.squares[4].Filled = true
    state.squares[4].Color = Color3.new(0, 0, 0)

    state.text[1].Text = state.player.Name
    state.text[2].Text = "none"
    state.text[4].RichText = true
    state.text[4].Center = false

    local fillImage = Options.esp_fill_image.Value
    local fillConfig = IMAGES[fillImage] or IMAGES.default
    state.images[1].Image = fillConfig.image
    state.images[1].Center = true
    state.fillScale = fillConfig.size

    return state
end

function ESP:computeBounds(state)
    local cam = workspace.CurrentCamera
    local dynamic = Options.esp_bounds_type.Value == "dynamic"
    local widthScale = Options.esp_bounds_width_scale.Value / 100

    local function worldToScreen(position)
        local screen, onScreen = cam:WorldToViewportPoint(position)
        return Vector2.new(screen.X, screen.Y), onScreen
    end

    if dynamic then
        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        local valid = false
        for partName, part in pairs(state.parts) do
            local corners = state.corners[partName]
            if not corners then continue end
            for _, offset in ipairs(corners) do
                local screen, onScreen = worldToScreen((part.CFrame * offset).Position)
                if onScreen then
                    valid = true
                    minX = math.min(minX, screen.X)
                    maxX = math.max(maxX, screen.X)
                    minY = math.min(minY, screen.Y)
                    maxY = math.max(maxY, screen.Y)
                end
            end
        end
        if not valid then return nil end
        local width = math.max(10, maxX - minX)
        local height = math.max(10, maxY - minY)
        return width * widthScale, height * widthScale, Vector2.new(minX + (maxX - minX) / 2, minY)
    end

    local hrp = state.humanoidRootPart
    if not hrp then return nil end
    local top, topOn = worldToScreen((hrp.CFrame * CFrame.new(0, 2.5, 0)).Position)
    local bottom, bottomOn = worldToScreen((hrp.CFrame * CFrame.new(0, -3.5, 0)).Position)
    if not topOn or not bottomOn then return nil end
    local height = math.max(10, (top - bottom).Magnitude)
    return height * 0.55 * widthScale * 2, height * widthScale, bottom
end

function ESP:drawSkeleton(state)
    local visible = Toggles.esp_skeleton.Value
    for i, line in ipairs(state.lines) do
        line.Visible = false
    end
    if not visible then return end
    if not state.character then return end

    local cam = workspace.CurrentCamera
    local outline = Toggles.esp_skeleton_outline.Value

    for i, pair in ipairs(SKELETON_LINES) do
        local fromPart = state.parts[pair[1]]
        local toPart = state.parts[pair[2]]
        if not fromPart or not toPart then continue end

        local from, onFrom = cam:WorldToViewportPoint(fromPart.Position)
        local to, onTo = cam:WorldToViewportPoint(toPart.Position)
        if not onFrom or not onTo then continue end

        local line = state.lines[i]
        local outlineLine = state.lines[i + 13]

        line.From = Vector2.new(from.X, from.Y)
        line.To = Vector2.new(to.X, to.Y)
        line.Visible = true

        if outline then
            outlineLine.From = line.From
            outlineLine.To = line.To
            outlineLine.Visible = true
        end
    end
end

function ESP:drawBox(state, size, position)
    local box = Toggles.esp_box.Value
    local fill = Toggles.esp_fill.Value
    local fillImage = Options.esp_fill_image.Value

    state.squares[1].Visible = false
    state.squares[2].Visible = false
    state.squares[3].Visible = false
    state.squares[4].Visible = false
    state.images[1].Visible = false

    if not box and not fill then return end

    local half = Vector2.new(size.X / 2, 0)

    if box then
        state.squares[1].Size = size
        state.squares[1].Position = position - half
        state.squares[1].Visible = true

        state.squares[2].Size = size
        state.squares[2].Position = position - half
        state.squares[2].Visible = true
    end

    if fill then
        if fillImage ~= "" then
            state.images[1].Size = size
            state.images[1].Position = position - half
            state.images[1].Visible = true
        else
            state.squares[3].Size = size
            state.squares[3].Position = position - half
            state.squares[3].Visible = true

            state.squares[4].Size = size
            state.squares[4].Position = position - half
            state.squares[4].Visible = true
        end
    end
end

function ESP:drawName(state, position)
    local name = state.text[1]
    name.Visible = false
    if not Toggles.esp_name.Value then return end

    name.Text = state.player.Name
    name.Position = position - Vector2.new(0, 2)
    name.Visible = true
end

function ESP:drawWeapon(state, position)
    local weapon = state.text[2]
    weapon.Visible = false
    if not Toggles.esp_weapon.Value then return end

    local character = state.character
    local item = character and character:FindFirstChild("EquippedItem")
    weapon.Text = item and item.Name or "none"
    weapon.Position = position + Vector2.new(0, weapon.TextBounds.Y + 1)
    weapon.Visible = true
end

function ESP:drawDistance(state, position)
    local distance = state.text[3]
    distance.Visible = false
    if not Toggles.esp_distance.Value then return end

    local cam = workspace.CurrentCamera
    local origin = cam and cam.CFrame.Position or Vector3.new()
    local dist = (state.humanoidRootPart.Position - origin).Magnitude
    distance.Text = "[" .. math.round(dist) .. "]"
    distance.Position = position + Vector2.new(0, state.text[2].Visible and (distance.TextBounds.Y + 8) or distance.TextBounds.Y + 2)
    distance.Visible = true
end

function ESP:drawHealthbar(state, size, position)
    state.squares[3].Visible = false
    state.squares[4].Visible = false
    if not Toggles.esp_healthbar.Value then return end
    if not state.humanoid then return end

    local health = state.humanoid.Health
    local maxHealth = state.humanoid.MaxHealth
    local ratio = math.clamp(health / maxHealth, 0, 1)

    local lerpSpeed = Options.esp_healthbar_health_lerp.Value
    state.lerpedHealth = state.lerpedHealth or ratio
    state.lerpedHealth = state.lerpedHealth + (ratio - state.lerpedHealth) * lerpSpeed

    local barSize = Vector2.new(4, size.Y - 2)
    if Toggles.esp_healthbar_resize.Value then
        barSize = Vector2.new(4, (size.Y - 2) * state.lerpedHealth)
    end

    local barPosition = position - Vector2.new(size.X / 2 + 6, -size.Y + 1) - Vector2.new(-1, 2)
    local bgPosition = barPosition - Vector2.new(1, -1)

    state.squares[4].Size = Vector2.new(4, size.Y)
    state.squares[4].Position = bgPosition
    state.squares[4].Visible = true

    state.squares[3].Size = barSize
    state.squares[3].Position = barPosition
    state.squares[3].Visible = true
end

function ESP:drawFlags(state, position)
    local flags = state.text[4]
    flags.Visible = false
    if not Toggles.esp_flag_health_text.Value and not Toggles.esp_flag_staring_text.Value then return end

    local text = ""
    local prefix = Options.esp_flag_prefix.Value or "minimal"
    local prefixMap = { ["bridge only"] = "", minimal = "HP", full = "HEALTH" }
    local prefixText = prefixMap[prefix] or ""

    if Toggles.esp_flag_health_text.Value and state.humanoid then
        text = text .. "[" .. prefixText .. " " .. math.round(state.humanoid.Health) .. "]"
    end

    if Toggles.esp_flag_staring_text.Value then
        local cam = workspace.CurrentCamera
        local origin = cam and cam.CFrame.Position or Vector3.new()
        local dist = (state.humanoidRootPart.Position - origin).Magnitude
        if dist < 25 then
            text = text .. "staring"
        end
    end

    flags.Text = text
    flags.Position = position + Vector2.new(sizeOf(state) / 2 + 2, 0)
    flags.Visible = text ~= ""
end

local function sizeOf(state)
    return state.text[1].TextBounds.Y
end

function ESP:drawEffects(state)
    if not state.character then return end
    local ally = state.character:FindFirstChild("_is_ally")
    if ally and ally.Value then return end

    if Toggles.esp_effects_aura.Value then
        local aura = state.character:FindFirstChild("ESP_Aura")
        if not aura then
            local newAura = Instance.new("SelectionBox")
            newAura.Name = "ESP_Aura"
            newAura.Adornee = state.character
            newAura.Color3 = Options.esp_effects_aura_color1.Value
            newAura.LineThickness = 1
            newAura.Transparency = 1
            newAura.SurfaceTransparency = 1
            newAura.Parent = state.character
        end
    else
        local aura = state.character:FindFirstChild("ESP_Aura")
        if aura then aura:Destroy() end
    end

    if Toggles.esp_effects_particle.Value then
        local particleFolder = state.character:FindFirstChild("ESP_Particles")
        if not particleFolder then
            particleFolder = Instance.new("Folder")
            particleFolder.Name = "ESP_Particles"
            particleFolder.Parent = state.character
        end
        if #particleFolder:GetChildren() == 0 then
            local emitter = Instance.new("ParticleEmitter")
            emitter.Color = ColorSequence.new(Options.esp_effects_particle_color1.Value)
            emitter.Size = NumberSequence.new(0.5)
            emitter.Lifetime = NumberRange.new(0.5)
            emitter.Rate = 10
            emitter.Parent = state.humanoidRootPart
        end
    else
        local particleFolder = state.character:FindFirstChild("ESP_Particles")
        if particleFolder then particleFolder:Destroy() end
    end
end

function ESP:drawWorldElements(state)
    local character = state.character
    if not character then return end
    local hrp = state.humanoidRootPart
    if not hrp then return end

    local whitelist = Options.esp_world_whitelist.Value or {}
    local showName = Toggles.esp_world_name.Value
    local showDistance = Toggles.esp_world_distance.Value
    local showImage = Toggles.esp_world_image.Value

    local existing = character:FindFirstChild("ESP_WorldName")
    if showName then
        if not existing then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ESP_WorldName"
            billboard.Size = UDim2.fromScale(1, 1)
            billboard.AlwaysOnTop = true
            billboard.Adornee = hrp
            billboard.MaxDistance = Options.esp_world_distance.Value * 10

            local label = Instance.new("TextLabel")
            label.Size = UDim2.fromScale(1, 1)
            label.BackgroundTransparency = 1
            label.Text = character.Name
            label.TextColor3 = Options.esp_world_name_color.Value
            label.TextStrokeTransparency = 0
            label.Parent = billboard

            billboard.Parent = character
        end
    elseif existing then
        existing:Destroy()
    end

    local distanceBillboard = character:FindFirstChild("ESP_WorldDistance")
    if showDistance then
        if not distanceBillboard then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ESP_WorldDistance"
            billboard.Size = UDim2.fromScale(1, 1)
            billboard.AlwaysOnTop = true
            billboard.Adornee = hrp
            billboard.MaxDistance = Options.esp_world_distance.Value * 10

            local label = Instance.new("TextLabel")
            label.Size = UDim2.fromScale(1, 1)
            label.BackgroundTransparency = 1
            label.Text = "0"
            label.TextColor3 = Options.esp_world_distance_color.Value
            label.TextStrokeTransparency = 0
            label.Parent = billboard

            billboard.Parent = character
        else
            local label = distanceBillboard:FindFirstChildOfClass("TextLabel")
            if label then
                local cam = workspace.CurrentCamera
                local dist = (hrp.Position - cam.CFrame.Position).Magnitude
                label.Text = "[" .. math.round(dist) .. "]"
            end
        end
    elseif distanceBillboard then
        distanceBillboard:Destroy()
    end

    local imageBillboard = character:FindFirstChild("ESP_WorldImage")
    if showImage then
        if not imageBillboard then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ESP_WorldImage"
            billboard.Size = UDim2.fromScale(1, 1)
            billboard.AlwaysOnTop = true
            billboard.Adornee = hrp
            billboard.MaxDistance = Options.esp_world_distance.Value * 10

            local image = Instance.new("ImageLabel")
            image.Size = UDim2.fromScale(1, 1)
            image.BackgroundTransparency = 1
            image.Image = Options.esp_world_image.Value
            image.Parent = billboard

            billboard.Parent = character
        end
    elseif imageBillboard then
        imageBillboard:Destroy()
    end
end

function ESP:hideAll(state)
    for _, drawing in ipairs(state.drawings) do
        drawing.Visible = false
    end
end

function ESP:update(player)
    local state = self.players[player]
    if not state then return end
    if not Toggles.esp_name.Value and not Toggles.esp_distance.Value
        and not Toggles.esp_weapon.Value and not Toggles.esp_box.Value
        and not Toggles.esp_fill.Value and not Toggles.esp_skeleton.Value
        and not Toggles.esp_healthbar.Value and not Toggles.esp_flag_health_text.Value
        and not Toggles.esp_flag_staring_text.Value then
        self:hideAll(state)
        return
    end

    local character = state.character
    if not character then
        self:hideAll(state)
        return
    end

    local ally = character:FindFirstChild("_is_ally")
    if not Toggles.esp_show_team.Value and ally and ally.Value then
        self:hideAll(state)
        return
    end

    if state.health <= 0 then
        self:hideAll(state)
        return
    end

    local bounds = self:computeBounds(state)
    if not bounds then
        self:hideAll(state)
        return
    end

    local size, height, position = bounds
    local sizeVec = Vector2.new(size, height)

    self:drawSkeleton(state)
    self:drawBox(state, sizeVec, position)
    self:drawName(state, position)
    self:drawWeapon(state, position)
    self:drawDistance(state, position)
    self:drawHealthbar(state, sizeVec, position)
    self:drawFlags(state, position)
end

function ESP:start()
    local self = self

    local function onPlayerAdded(player)
        local state = self:createState(player, nil)
        self.players[player] = state

        local function onCharacterAdded(character)
            self:updatePlayerState(player, character)
        end

        table.insert(state.connections, player.CharacterAdded:Connect(onCharacterAdded))
        table.insert(state.connections, player.CharacterRemoving:Connect(function()
            self:hideAll(state)
            state.character = nil
        end))

        if player.Character then
            task.spawn(function()
                onCharacterAdded(player.Character)
            end)
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
    Players.PlayerAdded:Connect(onPlayerAdded)

    RunService.RenderStepped:Connect(function()
        for player in pairs(self.players) do
            self:update(player)
        end
    end)

    self.events.esp_color_changed.Event:Connect(function()
        for _, state in pairs(self.players) do
            if state.character then
                self:drawEffects(state)
            end
        end
    end)

    self.events.esp_effects_changed.Event:Connect(function()
        for _, state in pairs(self.players) do
            if state.character then
                self:drawEffects(state)
            end
        end
    end)

    self.events.esp_effects_color_changed.Event:Connect(function()
        for _, state in pairs(self.players) do
            if state.character then
                self:drawEffects(state)
            end
        end
    end)

    return self
end

function ESP:destroy()
    for player, state in pairs(self.players) do
        for _, connection in ipairs(state.connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end
        for _, drawing in ipairs(state.drawings) do
            pcall(function()
                drawing:Remove()
            end)
        end
        self.players[player] = nil
    end
end

return ESP
