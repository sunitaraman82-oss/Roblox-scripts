-- Aimlock client script: toggles camera lock onto nearest valid player, R15/R6 compatible.

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Local player and camera
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Config
local TOGGLE_KEY = Enum.KeyCode.RightShift -- Default keybind for toggling aimlock
local AIM_LERP = 1 -- 1 = snap instantly; lower values smooth the aim
local aimlockEnabled = false
local currentTarget = nil -- Cached target character

-- UI: build ScreenGui with a frame and toggle button
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimlockGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 160, 0, 60)
frame.Position = UDim2.new(0, 20, 0.5, -30)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -16, 1, -16)
button.Position = UDim2.new(0, 8, 0, 8)
button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.Text = "Aimlock: OFF"
button.Parent = frame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = button

-- Helper: is a character alive and valid (skip dead / headless)
local function isCharacterValid(character)
	if not character or not character.Parent then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	if not character:FindFirstChild("Head") then return false end
	return true
end

-- Helper: resolve aim point for R15 or R6 with safe fallbacks
local function getAimPoint(character)
	if not character then return nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	-- Prefer Humanoid.RootPart (works on both rigs, present when alive)
	if humanoid and humanoid.RootPart then
		return humanoid.RootPart.Position
	end
	-- R15 fallback: UpperTorso / LowerTorso / Torso
	local r15 = character:FindFirstChild("UpperTorso") or character:FindFirstChild("LowerTorso")
	if r15 then return r15.Position end
	-- R6 fallback: Torso, then Head
	local torso = character:FindFirstChild("Torso")
	if torso then return torso.Position end
	local head = character:FindFirstChild("Head")
	if head then return head.Position end
	return nil
end

-- Targeting: pick the player nearest to the local player's HumanoidRootPart
local function pickTarget()
	local myChar = localPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end
	local myPos = myRoot.Position

	local best, bestDist = nil, math.huge
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= localPlayer then
			local char = other.Character
			if isCharacterValid(char) then
				local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
				if root then
					local dist = (root.Position - myPos).Magnitude
					if dist < bestDist then
						bestDist = dist
						best = char
					end
				end
			end
		end
	end
	return best
end

-- Toggle state and refresh button text
local function setEnabled(state)
	aimlockEnabled = state
	button.Text = state and "Aimlock: ON" or "Aimlock: OFF"
	button.BackgroundColor3 = state and Color3.fromRGB(60, 130, 60) or Color3.fromRGB(45, 45, 45)
	if not state then currentTarget = nil end
end

-- UI + keybind toggles
button.Activated:Connect(function() setEnabled(not aimlockEnabled) end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == TOGGLE_KEY then
		setEnabled(not aimlockEnabled)
	end
end)

-- Re-pick target periodically to handle spawns/despawns smoothly
task.spawn(function()
	while true do
		task.wait(0.25)
		if aimlockEnabled then
			currentTarget = pickTarget()
		end
	end
end)

-- Per-frame aim update using CFrame.lookAt from camera to target aim point
RunService.RenderStepped:Connect(function()
	if not aimlockEnabled then return end
	if not currentTarget or not isCharacterValid(currentTarget) then
		currentTarget = pickTarget()
		if not currentTarget then return end
	end
	local aimPos = getAimPoint(currentTarget)
	if not aimPos then return end
	local camPos = camera.CFrame.Position
	local look = CFrame.lookAt(camPos, aimPos)
	camera.CFrame = AIM_LERP >= 1 and look or camera.CFrame:Lerp(look, AIM_LERP)
end)