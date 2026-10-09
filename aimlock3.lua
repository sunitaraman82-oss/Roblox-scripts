if not game then
  print("This script requires the Roblox environment; the standard Lua sandbox does not provide 'game'.")
  return
end

local players = game:GetService("Players")

local function helper()
  local currentCamera = workspace.CurrentCamera

  if not currentCamera then

    currentCamera = (workspace:FindFirstChildOfClass("Camera")) or workspace.CurrentCamera
  end

  return currentCamera
end

local runService = game:GetService("RunService")

local userInputService = game:GetService("UserInputService")
local localPlayer = players.LocalPlayer
local color = Color3.fromRGB(255, 0, 0)
local color2 = Color3.fromRGB(0, 0, 0)
local val = 200
local q = Enum.KeyCode.Q

local function safeCall(val2)
  if not val2 then
    return nil, nil
  else
    local success = { pcall(function() return val2:GetBoundingBox() end) }

    if success[1] then
      return success[2], success[3]
    else
      return nil, nil
    end
  end
end

local e = Enum.KeyCode.E
local val3 = false
local val4 = false
local val5 = true
local val6 = "Head"
local val7 = false
local val8 = {}

local function helper2(val9)
  return val8[val9] == true
end

local function helper3(val10)

  return val10 and val10.Character or nil
end

local val11 = {}
local val12 = {}
local val13 = 0

local function helper4(val14)
  local object = helper3(val14)

  return object and object:FindFirstChildOfClass("Humanoid") or nil
end

local function helper5(val15)
  local object2 = helper3(val15)

  if not object2 then
    return nil
  else
    local findFirstChild = object2:FindFirstChild(val6)
    local humanoidRootPart = findFirstChild

    if not findFirstChild then
      local head = object2:FindFirstChild("Head")

      humanoidRootPart = head or object2:FindFirstChild("HumanoidRootPart")
    end

    return humanoidRootPart
  end
end

local function helper6(val16)
  local element = helper4(val16)

  return element and element.Health > 0
end

local function createBoxHandleAdornment()
  local parent = helper()

  local espHitboxInner = Instance.new("BoxHandleAdornment")
  espHitboxInner.AlwaysOnTop = true
  espHitboxInner.ZIndex = 10
  espHitboxInner.Transparency = 0.35
  espHitboxInner.Color3 = color
  espHitboxInner.Name = "ESP_HitboxInner"
  espHitboxInner.Parent = parent

  local espHitboxOutline = Instance.new("BoxHandleAdornment")
  espHitboxOutline.AlwaysOnTop = true
  espHitboxOutline.ZIndex = 9
  espHitboxOutline.Transparency = 0.75
  espHitboxOutline.Color3 = color2
  espHitboxOutline.Name = "ESP_HitboxOutline"
  espHitboxOutline.Parent = parent

  return { inner = espHitboxInner, outline = espHitboxOutline }
end

local function helper7(val17)
  local element2 = val11[val17]

  if not element2 then
    return
  else
    element2.inner.Adornee = nil
    element2.outline.Adornee = nil

    table.insert(val12, element2)
    val11[val17] = nil
    return
  end
end

local function helper8(val18)
  if val11[val18] then
    return val11[val18]
  else
    local val19 = table.remove(val12)

    local val20 = val19 or createBoxHandleAdornment()
    val11[val18] = val20
    return val20
  end
end

local function helper9(val21)
  if val21 == localPlayer then
    return
  end

  if helper2(val21) then
    helper7(val21)
    return
  end

  local team = val21.Team
  if team and localPlayer.Team and team == localPlayer.Team then
    helper7(val21)
    return
  end

  local character = val21.Character
  if not character or not character.Parent or not helper6(val21) then
    helper7(val21)
    return
  end

  local localCharacter = localPlayer.Character
  local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
  if localRoot then
    local targetRoot = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
    if targetRoot and (localRoot.Position - targetRoot.Position).Magnitude > 500 then
      helper7(val21)
      return
    end
  end

  local boxCFrame, boxSize = safeCall(character)
  if not boxCFrame or not boxSize then
    helper7(val21)
    return
  end

  local adornments = helper8(val21)
  local inner = adornments.inner
  local outline = adornments.outline

  inner.Adornee = character
  inner.Size = boxSize
  inner.CFrame = boxCFrame:ToObjectSpace(character:GetPivot())

  outline.Adornee = character
  outline.Size = boxSize * 1.05
  outline.CFrame = boxCFrame:ToObjectSpace(character:GetPivot())
end

local aimbotUIV2 = Instance.new("ScreenGui")

aimbotUIV2.Name = "AimbotUI_v2"
aimbotUIV2.ResetOnSpawn = false

pcall(function()

  aimbotUIV2.Parent = game:GetService("CoreGui")
  return
end)

if not aimbotUIV2.Parent then
  aimbotUIV2.Parent = localPlayer:WaitForChild("PlayerGui")
end

local instance = Instance.new("Frame", aimbotUIV2)
instance.Size = UDim2.new(0, 300, 0, 170)
instance.Position = UDim2.new(0.6, 0, 0.32, 0)
instance.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
instance.BorderSizePixel = 0
instance.Active = true
instance.Draggable = true

Instance.new("UICorner", instance).CornerRadius = UDim.new(0, 8)

local instance2 = Instance.new("TextLabel", instance)
instance2.Size = UDim2.new(1, -20, 0, 24)
instance2.Position = UDim2.new(0, 10, 0, 8)
instance2.BackgroundTransparency = 1
instance2.Text = "Aimbot (improved)"
instance2.Font = Enum.Font.GothamBold
instance2.TextSize = 15
instance2.TextColor3 = Color3.fromRGB(230, 230, 230)
instance2.TextXAlignment = Enum.TextXAlignment.Left

local instance3 = Instance.new("TextButton", instance)
instance3.Size = UDim2.new(0.48, -10, 0, 36)
instance3.Position = UDim2.new(0, 10, 0, 36)
instance3.Text = "Aimbot: OFF (Q)"
instance3.Font = Enum.Font.GothamBold
instance3.TextSize = 13
instance3.BackgroundColor3 = Color3.fromRGB(180, 60, 60)

Instance.new("UICorner", instance3).CornerRadius = UDim.new(0, 6)

local instance4 = Instance.new("TextButton", instance)
instance4.Size = UDim2.new(0.48, -10, 0, 36)
instance4.Position = UDim2.new(0.52, 0, 0, 36)
instance4.Text = "Strong Lock: OFF"
instance4.Font = Enum.Font.Gotham
instance4.TextSize = 13
instance4.BackgroundColor3 = Color3.fromRGB(180, 60, 60)

Instance.new("UICorner", instance4).CornerRadius = UDim.new(0, 6)

local instance5 = Instance.new("TextButton", instance)
instance5.Size = UDim2.new(0.48, -10, 0, 26)
instance5.Position = UDim2.new(0, 10, 0, 84)
instance5.Text = "Wallcheck: ON"
instance5.Font = Enum.Font.Gotham
instance5.TextSize = 12
instance5.BackgroundColor3 = Color3.fromRGB(60, 160, 80)

Instance.new("UICorner", instance5).CornerRadius = UDim.new(0, 6)

local instance6 = Instance.new("TextButton", instance)
instance6.Size = UDim2.new(0.48, -10, 0, 26)
instance6.Position = UDim2.new(0.52, 0, 0, 84)
instance6.Text = "Aim: Head"
instance6.Font = Enum.Font.Gotham
instance6.TextSize = 12
instance6.BackgroundColor3 = Color3.fromRGB(80, 80, 80)

Instance.new("UICorner", instance6).CornerRadius = UDim.new(0, 6)

local instance7 = Instance.new("TextLabel", instance)
instance7.Size = UDim2.new(1, -20, 0, 16)
instance7.Position = UDim2.new(0, 10, 0, 116)
instance7.BackgroundTransparency = 1
instance7.Text = "Aimed: None"
instance7.Font = Enum.Font.Gotham
instance7.TextSize = 12
instance7.TextColor3 = Color3.fromRGB(200, 200, 200)
instance7.TextXAlignment = Enum.TextXAlignment.Left

local instance8 = Instance.new("TextBox", instance)
instance8.Size = UDim2.new(0.48, -10, 0, 26)
instance8.Position = UDim2.new(0, 10, 0, 136)
instance8.PlaceholderText = "FOV Size (" .. val .. ")"
instance8.Text = tostring(val)
instance8.Font = Enum.Font.Gotham
instance8.TextSize = 12
instance8.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
instance8.TextColor3 = Color3.fromRGB(230, 230, 230)

Instance.new("UICorner", instance8).CornerRadius = UDim.new(0, 6)

instance8.FocusLost:Connect(function(p10)
  local numVal = tonumber(instance8.Text)
  local val29 = numVal

  if numVal then

    val29 = numVal > 0 and numVal < 2000
  end

  if val29 then
    val = numVal

    instance8.Text = tostring(val)
    instance8.PlaceholderText = "FOV Size (" .. val .. ")"

    if circle then
      circle.Radius = val
    end
  else
    instance8.Text = tostring(val)
  end

  return
end)

local function safeCall2(val30)
  local element5 = helper()

  if not element5 then
    return false, "no cam"
  else
    local val31 = {
      pcall(function()
        element5.CFrame = val30
        return
      end), }

    if not val31[1] then
      val7 = true
      return false, val31[2]
    else
      return true
    end
  end
end

local val32 = false
local val33

pcall(function()
  local element6 = Drawing.new("Circle")
  element6.Thickness = 2
  element6.NumSides = 64
  element6.Radius = val
  element6.Filled = false
  element6.Color = Color3.fromRGB(200, 200, 255)
  element6.Visible = false

  val33 = element6
  val32 = true
  return
end)

local function helper10()
  if not val33 then
    return
  else
    local element7 = helper()

    if not element7 then
      return
    else
      local viewportSize = element7.ViewportSize

      val33.Position = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
      val33.Radius = val

      return
    end
  end
end

local function helper11(val34, val35)

  if not val34 then
    return false
  else
    local element8 = helper()

    if not element8 then
      return false
    else
      local position = element8.CFrame.Position
      local val36 = val34.Position - position

      local raycastParams = RaycastParams.new()
      raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

      local val37 = {}

      if localPlayer.Character then
        table.insert(val37, localPlayer.Character)
      end

      if val35 then
        table.insert(val37, val35)
      end

      raycastParams.FilterDescendantsInstances = val37
      raycastParams.IgnoreWater = true

      return (workspace:Raycast(position, val36, raycastParams)) == nil
    end
  end
end

local function iterate()
  local element9 = helper()

  if not element9 then
    return nil
  else
    local viewportSize2 = element9.ViewportSize
    local vector = Vector2.new(viewportSize2.X / 2, viewportSize2.Y / 2)
    local huge = math.huge
    local val38 = nil

    for index, value in ipairs(players:GetPlayers()) do
      local val39 = value ~= localPlayer
      local val40 = val39

      if val39 then
        local val41 = helper6(value)

        val40 = val41 and not (helper2(value))
      end

      if val40 then
        local team3 = value.Team
        local team4 = team3

        if team3 then

          team4 = localPlayer.Team and value.Team == localPlayer.Team
        end

        if not team4 then
          local element10 = helper5(value)

          if element10 then
            local val42 = { element9:WorldToViewportPoint(element10.Position) }
            local element11 = val42[1]

            if val42[2] then
              local magnitude = ((Vector2.new(element11.X, element11.Y)) - vector).Magnitude

              if magnitude < val and magnitude < huge then

                if not val5 or helper11(element10, value.Character) then
                  huge = magnitude
                  val38 = value
                end
              end
            end
          end
        end
      end
    end

    return val38
  end
end

local val43

runService:BindToRenderStep("Aimbot_v2", Enum.RenderPriority.Camera.Value + 1, function()
  if val33 then
    helper10()
    val33.Visible = val3 and val32
  end

  if not val3 then
    return
  end

  if val7 then
    instance7.Text = "Aimed: Camera writes blocked"
    return
  end

  if not val43 or not (val43.Character and val43.Character.Parent) or not helper6(val43) then
    val43 = iterate()
  end

  if not val43 or not val43.Character then
    instance7.Text = "Aimed: None"
    return
  end

  local targetPart = helper5(val43)
  if not targetPart then
    instance7.Text = "Aimed: None"
    return
  end

  if val5 and not helper11(targetPart, val43.Character) then
    val43 = nil
    instance7.Text = "Aimed: None"
    return
  end

  local currentCamera = helper()
  if not currentCamera then
    instance7.Text = "Aimed: None"
    return
  end

  local targetCFrame = CFrame.new(currentCamera.CFrame.Position, targetPart.Position)

  if val4 then
    local success = safeCall2(targetCFrame)
    if not success then
      instance7.Text = "Aimed: Camera blocked"
      val3 = false
      instance3.Text = "Aimbot: OFF (Q)"
      instance3.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
      return
    end
  else
    local success = pcall(function()
      currentCamera.CFrame = currentCamera.CFrame:Lerp(targetCFrame, 0.16)
    end)

    if not success then
      val7 = true
      instance7.Text = "Aimed: Camera writes blocked"
      val3 = false
      instance3.Text = "Aimbot: OFF (Q)"
      instance3.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
      return
    end
  end

  instance7.Text = "Aimed: " .. (val43.Name or "Unknown")
end)

local function helper12(val52)
  val3 = val52

  instance3.Text = "Aimbot: " .. (val52 and "ON (Q)" or "OFF (Q)")

  local color3 = val52
  color3 = val52 and Color3.fromRGB(60, 200, 120)

  instance3.BackgroundColor3 = color3 or Color3.fromRGB(180, 60, 60)

  if val52 then
    val43 = iterate()
  else
    val43 = nil
    instance7.Text = "Aimed: None"

    if val33 then
      val33.Visible = false
    end
  end

  return
end

instance3.MouseButton1Click:Connect(function()
  helper12(not val3)
  return
end)

instance4.MouseButton1Click:Connect(function()
  local val53 = not val4
  val4 = val53

  instance4.Text = "Strong Lock: " .. (val4 and "ON" or "OFF")
  local val54 = val4

  local color4 = val54
  color4 = val54 and Color3.fromRGB(60, 200, 120)

  instance4.BackgroundColor3 = color4 or Color3.fromRGB(180, 60, 60)

  if val4 then
    val43 = iterate()
  end

  return
end)

instance5.MouseButton1Click:Connect(function()
  local val55 = not val5
  val5 = val55

  instance5.Text = "Wallcheck: " .. (val5 and "ON" or "OFF")
  local val56 = val5

  local color5 = val56
  color5 = val56 and Color3.fromRGB(60, 200, 120)

  instance5.BackgroundColor3 = color5 or Color3.fromRGB(160, 160, 160)
  val43 = iterate()
  return
end)

instance6.MouseButton1Click:Connect(function()
  if val6 == "Head" then
    val6 = "HumanoidRootPart"
    instance6.Text = "Aim: HRP"
  else
    val6 = "Head"
    instance6.Text = "Aim: Head"
  end

  val43 = iterate()
  return
end)

userInputService.InputBegan:Connect(function(input, p15)
  if p15 then
    return
  else
    if input.KeyCode == q then
      helper12(not val3)
    else
      if input.KeyCode == e then
        instance6:CaptureFocus()
        instance6:ReleaseFocus()
        instance6:MouseButton1Click()
      end
    end

    return
  end
end)

localPlayer.CharacterAdded:Connect(function()
  val43 = nil
  val7 = false
  return
end)

runService.RenderStepped:Connect(function(delta)
  val13 = val13 + delta

  if val13 < 0.033333333333333 then
    return
  else
    val13 = 0

    for index2, value2 in ipairs(players:GetPlayers()) do
      helper9(value2)
    end

    return
  end
end)

local instance9 = Instance.new("TextButton", instance)
instance9.Size = UDim2.new(0.48, -10, 0, 26)
instance9.Position = UDim2.new(0.52, 0, 0, 136)
instance9.Text = "Exclude: 0"
instance9.Font = Enum.Font.Gotham
instance9.TextSize = 12
instance9.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

Instance.new("UICorner", instance9).CornerRadius = UDim.new(0, 6)

local instance10 = Instance.new("Frame", instance)
instance10.Size = UDim2.new(0, 280, 0, 140)
instance10.Position = UDim2.new(0, 10, 0, 170)
instance10.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
instance10.Visible = false

Instance.new("UICorner", instance10).CornerRadius = UDim.new(0, 8)

local instance11 = Instance.new("ScrollingFrame", instance10)
instance11.Size = UDim2.new(1, -12, 1, -12)
instance11.Position = UDim2.new(0, 6, 0, 6)
instance11.BackgroundTransparency = 1
instance11.CanvasSize = UDim2.new(0, 0, 0, 0)
instance11.ScrollBarThickness = 6

local instance12 = Instance.new("UIListLayout", instance11)
instance12.Padding = UDim.new(0, 6)
instance12.SortOrder = Enum.SortOrder.LayoutOrder

local function iterate2()
  local val57 = 0

  for index3, value3 in ipairs(instance11:GetChildren()) do
    if (value3:IsA("TextButton")) then
      val57 = val57 + value3.Size.Y.Offset + 6
    end
  end

  instance11.CanvasSize = UDim2.new(0, 0, 0, math.max(0, val57))
  return
end

local val58 = {}

local function iterate3()
  local count = 0

  for key, value4 in pairs(val8) do
    if value4 then
      count = count + 1
    end
  end

  instance9.Text = "Exclude: " .. (tostring(count))
  return
end

local function createTextButton(val59)

  if val59 == localPlayer then
    return
  else
    if val58[val59] then
      return
    else
      local strVal = tostring(val59.Name)

      local text = strVal .. " (" .. (tostring(val59.DisplayName or "")) .. ")"

      textButton = Instance.new("TextButton")
      textButton.Size = UDim2.new(1, 0, 0, 28)

      local val60 = helper2(val59)

      local color6 = val60
      color6 = val60 and Color3.fromRGB(180, 60, 60)

      textButton.BackgroundColor3 = color6 or Color3.fromRGB(40, 40, 40)
      textButton.TextColor3 = Color3.fromRGB(230, 230, 230)
      textButton.Font = Enum.Font.Gotham
      textButton.TextSize = 14
      textButton.Text = text
      textButton.Parent = instance11

      textButton.MouseButton1Click:Connect(function()
        if val8[val59] then
          val8[val59] = nil
          textButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        else
          val8[val59] = true
          textButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)

          if val43 == val59 then
            val43 = nil
          end
        end

        iterate3()
        return
      end)

      val58[val59] = textButton
      iterate2()
      iterate3()
      return textButton
    end
  end
end

for index4, value5 in ipairs(players:GetPlayers()) do
  createTextButton(value5)
end

players.PlayerAdded:Connect(function(player)
  createTextButton(player)
  return
end)

players.PlayerRemoving:Connect(function(player2)
  val8[player2] = nil
  local parent = val58[player2]

  if parent and parent.Parent then
    parent:Destroy()
  end

  val58[player2] = nil
  iterate2()
  iterate3()
  helper7(player2)

  if val43 == player2 then
    val43 = nil
  end

  return
end)

instance9.MouseButton1Click:Connect(function()
  instance10.Visible = not instance10.Visible
  return
end)

players.PlayerRemoving:Connect(function(player3)
  helper7(player3)
  return
end)

print("[AimbotUI_v2] Loaded")
