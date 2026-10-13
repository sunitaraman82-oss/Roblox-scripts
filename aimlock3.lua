-- Aimlock LocalScript: locks camera onto a target player's aim point with UI + keybind toggle.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Configuration
local TOGGLE_KEY = Enum.KeyCode.RightShift -- keybind to toggle aimlock
local SMOOTHNESS = 1 -- 1 = instant snap, lower = smoother lerp

local aimlockEnabled = false
local currentTarget = nil

-- Build the ScreenGui with a frame and toggle button
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimlockUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 160, 0, 60)
frame.Position = UDim2.new(0, 20, 0.5, -30)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -16, 1, -16)
button.Position = UDim2.new(0, 8, 0, 8)
button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 16
button.Text = "Aimlock: OFF"
button.BorderSizePixel = 0
button.Parent = frame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = button

-- Check whether a character is a valid aim target
local function isValidTarget(character)
	if not character or not character.Parent then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	-- Skip headless characters (no Head part)
	if not character:FindFirstChild("Head") then return false end
	return true
end

-- Pick the target closest to the camera's crosshair (screen center)
local function pickTarget()
	local closest, closestDist = nil, math.huge
	local screenCenter = camera.ViewportSize * 0.5
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and isValidTarget(player.Character) then
			local head = player.Character:FindFirstChild("Head")
			if head then
				local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
				if onScreen then
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
					if dist < closestDist then
						closestDist = dist
						closest = player.Character
					end
				end
			end
		end
	end
	return closest
end

-- Resolve the aim point via RootPart (R15) with Head/Torso fallback (R6)
local function getAimPoint(character)
	if not character then return nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end
	local root = humanoid.RootPart
	if root then
		return root.Position + Vector3.new(0, 1, 0)
	end
	local head = character:FindFirstChild("Head")
	if head then return head.Position end
	local torso = character:FindFirstChild("Torso")
	if torso then return torso.Position end
	return nil
end

-- Toggle the aimlock state and update button text
local function setAimlock(state)
	aimlockEnabled = state
	button.Text = aimlockEnabled and "Aimlock: ON" or "Aimlock: OFF"
	button.BackgroundColor3 = aimlockEnabled and Color3.fromRGB(40, 130, 60) or Color3.fromRGB(60, 60, 60)
	if not aimlockEnabled then
		currentTarget = nil
	end
end

-- Button click handler
button.MouseButton1Click:Connect(function()
	setAimlock(not aimlockEnabled)
end)

-- Keybind handler
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == TOGGLE_KEY then
		setAimlock(not aimlockEnabled)
	end
end)

-- Main aim update loop
RunService.RenderStepped:Connect(function()
	if not aimlockEnabled then return end
	if not camera then return end

	-- Re-pick target if current is invalid (handles despawn/death/respawn)
	if not isValidTarget(currentTarget) then
		currentTarget = pickTarget()
	end
	if not isValidTarget(currentTarget) then return end

	local aimPoint = getAimPoint(currentTarget)
	if not aimPoint then return end

	-- Aim camera from its position to the target's aim point
	local camPos = camera.CFrame.Position
	local desired = CFrame.lookAt(camPos, aimPoint)
	if SMOOTHNESS >= 1 then
		camera.CFrame = desired
	else
		camera.CFrame = camera.CFrame:Lerp(desired, SMOOTHNESS)
	end
end)