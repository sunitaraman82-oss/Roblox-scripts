-- CombatClient
-- Aim assist + target lock + ESP + GUI
-- Designed for Roblox Studio games you control.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Remote = ReplicatedStorage:WaitForChild("CombatRemote")

----------------------------------------------------------------
-- SETTINGS
----------------------------------------------------------------

local Settings = {
	AimAssist = false,
	TargetLock = false,
	ESP = false,

	-- 0.05 = very smooth
	-- 0.5 = faster
	Smoothness = 0.18,

	HitPart = "Head",

	-- Maximum distance for target selection
	MaxDistance = 300,

	-- Maximum angle from screen center
	FOV = 250
}

local CurrentTarget = nil

----------------------------------------------------------------
-- GUI
----------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "CombatGUI"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(250, 350)
main.Position = UDim2.new(0, 20, 0.5, -175)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundTransparency = 1
title.Text = "Combat System"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.Parent = main

local function createButton(text, y)
	local button = Instance.new("TextButton")

	button.Size = UDim2.new(1, -30, 0, 42)
	button.Position = UDim2.new(0, 15, 0, y)

	button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	button.TextColor3 = Color3.new(1, 1, 1)

	button.Text = text
	button.TextSize = 15
	button.Font = Enum.Font.Gotham

	button.AutoButtonColor = true
	button.Parent = main

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 7)
	c.Parent = button

	return button
end

local aimButton = createButton("Aim Assist: OFF", 55)
local lockButton = createButton("Target Lock: OFF", 105)
local espButton = createButton("ESP: OFF", 155)
local partButton = createButton("Hit Part: HEAD", 205)

local smoothLabel = Instance.new("TextLabel")
smoothLabel.Size = UDim2.new(1, -30, 0, 35)
smoothLabel.Position = UDim2.new(0, 15, 0, 260)
smoothLabel.BackgroundTransparency = 1
smoothLabel.TextColor3 = Color3.new(1, 1, 1)
smoothLabel.Text = "Smoothness: 18%"
smoothLabel.TextSize = 14
smoothLabel.Font = Enum.Font.Gotham
smoothLabel.Parent = main

local smoothMinus = createButton("-", 300)
smoothMinus.Size = UDim2.fromOffset(90, 35)

local smoothPlus = createButton("+", 300)
smoothPlus.Size = UDim2.fromOffset(90, 35)
smoothPlus.Position = UDim2.new(1, -105, 0, 300)

----------------------------------------------------------------
-- GUI UPDATES
----------------------------------------------------------------

local function updateButtons()
	aimButton.Text = "Aim Assist: " ..
		(Settings.AimAssist and "ON" or "OFF")

	lockButton.Text = "Target Lock: " ..
		(Settings.TargetLock and "ON" or "OFF")

	espButton.Text = "ESP: " ..
		(Settings.ESP and "ON" or "OFF")

	partButton.Text = "Hit Part: " ..
		string.upper(Settings.HitPart)

	smoothLabel.Text = string.format(
		"Smoothness: %d%%",
		math.floor(Settings.Smoothness * 100)
	)
end

aimButton.MouseButton1Click:Connect(function()
	Settings.AimAssist = not Settings.AimAssist
	updateButtons()
end)

lockButton.MouseButton1Click:Connect(function()
	Settings.TargetLock = not Settings.TargetLock

	if not Settings.TargetLock then
		CurrentTarget = nil
	end

	updateButtons()
end)

espButton.MouseButton1Click:Connect(function()
	Settings.ESP = not Settings.ESP
	updateButtons()
end)

partButton.MouseButton1Click:Connect(function()
	if Settings.HitPart == "Head" then
		Settings.HitPart = "Body"

	elseif Settings.HitPart == "Body" then
		Settings.HitPart = "Random"

	else
		Settings.HitPart = "Head"
	end

	updateButtons()
end)

smoothMinus.MouseButton1Click:Connect(function()
	Settings.Smoothness = math.clamp(
		Settings.Smoothness - 0.05,
		0.05,
		0.5
	)

	updateButtons()
end)

smoothPlus.MouseButton1Click:Connect(function()
	Settings.Smoothness = math.clamp(
		Settings.Smoothness + 0.05,
		0.05,
		0.5
	)

	updateButtons()
end)

updateButtons()

----------------------------------------------------------------
-- CHARACTER DETECTION
----------------------------------------------------------------

local function getCharacterParts(player)
	if player == LocalPlayer then
		return nil
	end

	local character = player.Character

	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid or humanoid.Health <= 0 then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")

	if not root then
		return nil
	end

	return character, humanoid, root
end

----------------------------------------------------------------
-- HIT PART SELECTION
----------------------------------------------------------------

local function getAimPart(character)
	if not character then
		return nil
	end

	if Settings.HitPart == "Head" then
		return character:FindFirstChild("Head")
	end

	if Settings.HitPart == "Body" then
		return character:FindFirstChild("UpperTorso")
			or character:FindFirstChild("Torso")
			or character:FindFirstChild("HumanoidRootPart")
	end

	-- Random
	local parts = {}

	for _, name in ipairs({
		"Head",
		"UpperTorso",
		"Torso",
		"HumanoidRootPart",
		"LeftUpperArm",
		"RightUpperArm",
		"LeftUpperLeg",
		"RightUpperLeg"
	}) do
		local part = character:FindFirstChild(name)

		if part and part:IsA("BasePart") then
			table.insert(parts, part)
		end
	end

	if #parts == 0 then
		return nil
	end

	return parts[math.random(1, #parts)]
end

----------------------------------------------------------------
-- TARGET DETECTION
----------------------------------------------------------------

local function getClosestTarget()
	local center = Vector2.new(
		Camera.ViewportSize.X / 2,
		Camera.ViewportSize.Y / 2
	)

	local closest = nil
	local closestDistance = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		local character, humanoid, root = getCharacterParts(player)

		if character and humanoid and root then
			local distance =
				(LocalPlayer.Character
				and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				and (
					LocalPlayer.Character.HumanoidRootPart.Position
					- root.Position
				).Magnitude)
				or math.huge

			if distance <= Settings.MaxDistance then

				local screenPosition, visible =
					Camera:WorldToViewportPoint(root.Position)

				if visible then
					local screenDistance =
						(Vector2.new(
							screenPosition.X,
							screenPosition.Y
						) - center).Magnitude

					if screenDistance <= Settings.FOV
						and screenDistance < closestDistance then

						closestDistance = screenDistance
						closest = player
					end
				end
			end
		end
	end

	return closest
end

----------------------------------------------------------------
-- AIM ASSIST
----------------------------------------------------------------

RunService.RenderStepped:Connect(function()

	if not Settings.AimAssist then
		return
	end

	if Settings.TargetLock then

		if not CurrentTarget
			or not getCharacterParts(CurrentTarget) then

			CurrentTarget = getClosestTarget()
		end

	else
		CurrentTarget = getClosestTarget()
	end

	if not CurrentTarget then
		return
	end

	local character = CurrentTarget.Character

	if not character then
		return
	end

	local aimPart = getAimPart(character)

	if not aimPart then
		return
	end

	local cameraPosition = Camera.CFrame.Position

	local desired =
		CFrame.lookAt(
			cameraPosition,
			aimPart.Position
		)

	-- Smooth camera movement
	Camera.CFrame = Camera.CFrame:Lerp(
		desired,
		Settings.Smoothness
	)
end)

----------------------------------------------------------------
-- ESP
----------------------------------------------------------------

local function updateESP(player)
	if player == LocalPlayer then
		return
	end

	local character = player.Character

	if not character then
		return
	end

	local existing = character:FindFirstChild("CombatESP")

	if Settings.ESP then

		if not existing then
			local highlight = Instance.new("Highlight")

			highlight.Name = "CombatESP"
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

			highlight.FillTransparency = 0.65
			highlight.OutlineTransparency = 0

			highlight.Parent = character
		end

	else

		if existing then
			existing:Destroy()
		end
	end
end

local function refreshESP()
	for _, player in ipairs(Players:GetPlayers()) do
		updateESP(player)
	end
end

Players.PlayerAdded:Connect(function(player)

	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		updateESP(player)
	end)

end)

Players.PlayerRemoving:Connect(function(player)

	if CurrentTarget == player then
		CurrentTarget = nil
	end

end)

RunService.Heartbeat:Connect(function()
	if Settings.ESP then
		refreshESP()
	end
end)

----------------------------------------------------------------
-- ATTACK
----------------------------------------------------------------

local function attack()
	local target = CurrentTarget

	if not target then
		target = getClosestTarget()
	end

	if not target then
		return
	end

	-- The client requests an attack.
	-- The SERVER decides whether the hit is valid.
	Remote:FireServer(
		"Attack",
		target,
		Settings.HitPart
	)
end

----------------------------------------------------------------
-- PC INPUT
----------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, processed)

	if processed then
		return
	end

	-- Q = toggle aim assist
	if input.KeyCode == Enum.KeyCode.Q then
		Settings.AimAssist = not Settings.AimAssist
		updateButtons()
	end

	-- E = toggle target lock
	if input.KeyCode == Enum.KeyCode.E then
		Settings.TargetLock = not Settings.TargetLock

		if not Settings.TargetLock then
			CurrentTarget = nil
		end

		updateButtons()
	end

	-- Left mouse button = attack
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		attack()
	end
end)

----------------------------------------------------------------
-- MOBILE ATTACK BUTTON
----------------------------------------------------------------

local attackButton = Instance.new("TextButton")

attackButton.Size = UDim2.fromOffset(100, 60)
attackButton.Position = UDim2.new(1, -120, 1, -100)

attackButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
attackButton.TextColor3 = Color3.new(1, 1, 1)

attackButton.Text = "ATTACK"
attackButton.TextSize = 16
attackButton.Font = Enum.Font.GothamBold

attackButton.Parent = gui

local attackCorner = Instance.new("UICorner")
attackCorner.CornerRadius = UDim.new(0, 12)
attackCorner.Parent = attackButton

attackButton.MouseButton1Click:Connect(attack)