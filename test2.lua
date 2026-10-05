-- RIVALS-STYLE TRAINING PANEL
-- Roblox Studio / your own experience
-- Features: Mobile GUI, Fly, Aim Assist, FOV, ESP-style highlighting

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local flying = false
local aimAssist = false
local highlightsEnabled = false
local flySpeed = 60
local aimFOV = 150
local aimSmoothness = 0.18
local teamCheck = true

local character, humanoid, root

local function setupCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
end

if player.Character then
	setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "TrainingPanel"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(250, 330)
main.Position = UDim2.new(0, 20, 0.5, -165)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
main.BorderSizePixel = 0
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundTransparency = 1
title.Text = "TRAINING PANEL"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.Parent = main

local function makeButton(text, y)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -30, 0, 42)
	button.Position = UDim2.new(0, 15, 0, y)
	button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 15
	button.Font = Enum.Font.GothamSemibold
	button.Text = text
	button.AutoButtonColor = true
	button.Parent = main

	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

	return button
end

local flyButton = makeButton("Fly: OFF", 55)
local aimButton = makeButton("Aim Assist: OFF", 105)
local espButton = makeButton("Highlights: OFF", 155)
local teamButton = makeButton("Team Check: ON", 205)

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -30, 0, 30)
speedLabel.Position = UDim2.new(0, 15, 0, 260)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Fly Speed: 60"
speedLabel.TextColor3 = Color3.new(1, 1, 1)
speedLabel.TextSize = 14
speedLabel.Font = Enum.Font.Gotham
speedLabel.Parent = main

local speedDown = makeButton("-", 295)
speedDown.Size = UDim2.fromOffset(100, 30)

local speedUp = makeButton("+", 295)
speedUp.Size = UDim2.fromOffset(100, 30)
speedUp.Position = UDim2.new(1, -115, 0, 295)

-- FOV circle
local fov = Instance.new("Frame")
fov.Name = "FOV"
fov.AnchorPoint = Vector2.new(0.5, 0.5)
fov.Position = UDim2.fromScale(0.5, 0.5)
fov.Size = UDim2.fromOffset(aimFOV * 2, aimFOV * 2)
fov.BackgroundTransparency = 1
fov.Visible = false
fov.Parent = gui

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Parent = fov

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = fov

-- Fly
local flyConnection

local function stopFly()
	flying = false

	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end

	if humanoid then
		humanoid.PlatformStand = false
	end
end

local function startFly()
	if not root or not humanoid then return end

	flying = true
	humanoid.PlatformStand = true

	flyConnection = RunService.RenderStepped:Connect(function()
		if not flying or not root then return end

		local move = Vector3.zero

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			move += camera.CFrame.LookVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			move -= camera.CFrame.LookVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			move -= camera.CFrame.RightVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			move += camera.CFrame.RightVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			move += Vector3.yAxis
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			move -= Vector3.yAxis
		end

		-- Mobile thumbstick support
		local direction = humanoid.MoveDirection

		if direction.Magnitude > 0 then
			move += direction
		end

		if move.Magnitude > 0 then
			root.AssemblyLinearVelocity = move.Unit * flySpeed
		else
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end)
end

flyButton.Activated:Connect(function()
	if flying then
		stopFly()
		flyButton.Text = "Fly: OFF"
	else
		startFly()
		flyButton.Text = "Fly: ON"
	end
end)

-- Find closest target
local function getTarget()
	if not camera then return nil end

	local center = camera.ViewportSize / 2
	local bestTarget = nil
	local bestDistance = aimFOV

	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and other.Character then
			local hum = other.Character:FindFirstChildOfClass("Humanoid")
			local head = other.Character:FindFirstChild("Head")

			if hum and head and hum.Health > 0 then
				if teamCheck and other.Team == player.Team then
					continue
				end

				local screenPos, visible =
					camera:WorldToViewportPoint(head.Position)

				if visible and screenPos.Z > 0 then
					local distance = (
						Vector2.new(screenPos.X, screenPos.Y) - center
					).Magnitude

					if distance < bestDistance then
						bestDistance = distance
						bestTarget = head
					end
				end
			end
		end
	end

	return bestTarget
end

-- Aim assist
RunService.RenderStepped:Connect(function()
	if aimAssist then
		local target = getTarget()

		if target then
			local desired = CFrame.lookAt(
				camera.CFrame.Position,
				target.Position
			)

			camera.CFrame = camera.CFrame:Lerp(
				desired,
				aimSmoothness
			)
		end
	end
end)

aimButton.Activated:Connect(function()
	aimAssist = not aimAssist
	aimButton.Text = aimAssist and "Aim Assist: ON" or "Aim Assist: OFF"
	fov.Visible = aimAssist
end)

-- Highlights
local function updateHighlights()
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and other.Character then
			local existing = other.Character:FindFirstChild("TrainingHighlight")

			if highlightsEnabled then
				if not existing then
					local h = Instance.new("Highlight")
					h.Name = "TrainingHighlight"
					h.FillTransparency = 0.65
					h.OutlineTransparency = 0
					h.Parent = other.Character
				end
			elseif existing then
				existing:Destroy()
			end
		end
	end
end

espButton.Activated:Connect(function()
	highlightsEnabled = not highlightsEnabled
	espButton.Text = highlightsEnabled
		and "Highlights: ON"
		or "Highlights: OFF"

	updateHighlights()
end)

Players.PlayerAdded:Connect(function(other)
	other.CharacterAdded:Connect(function()
		task.wait(1)
		updateHighlights()
	end)
end)

teamButton.Activated:Connect(function()
	teamCheck = not teamCheck
	teamButton.Text = teamCheck
		and "Team Check: ON"
		or "Team Check: OFF"
end)

speedDown.Activated:Connect(function()
	flySpeed = math.max(10, flySpeed - 10)
	speedLabel.Text = "Fly Speed: " .. flySpeed
end)

speedUp.Activated:Connect(function()
	flySpeed = math.min(200, flySpeed + 10)
	speedLabel.Text = "Fly Speed: " .. flySpeed
end)

-- Keep FOV centered when screen size changes
RunService.RenderStepped:Connect(function()
	fov.Position = UDim2.fromScale(0.5, 0.5)
	fov.Size = UDim2.fromOffset(aimFOV * 2, aimFOV * 2)
end)

print("Training Panel loaded.")