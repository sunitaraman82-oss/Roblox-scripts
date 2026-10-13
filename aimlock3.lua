local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local ASSIST_RADIUS = 220
local ASSIST_STRENGTH = 0.12
local TARGET_TAG = "AimAssistTarget"

local aiming = false

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobileAimAssist"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local aimButton = Instance.new("TextButton")
aimButton.Name = "AimAssistButton"
aimButton.AnchorPoint = Vector2.new(1, 1)
aimButton.Position = UDim2.new(1, -28, 1, -150)
aimButton.Size = UDim2.fromOffset(76, 76)
aimButton.BackgroundColor3 = Color3.fromRGB(45, 95, 170)
aimButton.BackgroundTransparency = 0.15
aimButton.Text = "AIM"
aimButton.TextColor3 = Color3.new(1, 1, 1)
aimButton.TextScaled = true
aimButton.Font = Enum.Font.GothamBold
aimButton.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = aimButton

local function setAiming(isAiming)
	 aiming = isAiming
	 aimButton.Text = aiming and "AIM: ON" or "AIM: OFF"
	 aimButton.BackgroundColor3 = aiming
		and Color3.fromRGB(70, 160, 100)
		or Color3.fromRGB(45, 95, 170)
end

setAiming(false)
aimButton.Activated:Connect(function()
	setAiming(not aiming)
end)

local function getAimPart(model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
  end
  
	return model:FindFirstChild("Head")
		or model:FindFirstChild("UpperTorso") -- R15
		or model:FindFirstChild("Torso") -- R6
		or model:FindFirstChild("HumanoidRootPart")
end

local function findTarget()
	local viewport = camera.ViewportSize
	local screenCenter = Vector2.new(viewport.X / 2, viewport.Y / 2)
	local bestPart = nil
	local bestDistance = ASSIST_RADIUS

	local ownCharacter = player.Character
	for _, model in ipairs(CollectionService:GetTagged(TARGET_TAG)) do
		if model:IsA("Model") and (not ownCharacter or not model:IsDescendantOf(ownCharacter)) then
			local part = getAimPart(model)
			if part then
				local point, onScreen = camera:WorldToViewportPoint(part.Position)
				if onScreen and point.Z > 0 then
					local distance = (Vector2.new(point.X, point.Y) - screenCenter).Magnitude
					if distance < bestDistance then
						bestDistance = distance
						bestPart = part
					end
				end
			end
		end
	end

	return bestPart
end

RunService:BindToRenderStep("MobileAimAssist", Enum.RenderPriority.Camera.Value + 1, function()
	if not aiming then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local targetPart = findTarget()
	if targetPart then
		local currentCFrame = camera.CFrame
		local targetCFrame = CFrame.lookAt(currentCFrame.Position, targetPart.Position)
		camera.CFrame = currentCFrame:Lerp(targetCFrame, ASSIST_STRENGTH)
	end
end)
