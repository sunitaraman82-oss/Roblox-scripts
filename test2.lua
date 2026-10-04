local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local aiming = false
local target = nil

-- SETTINGS
local FOV = 180
local SMOOTHNESS = 0.15
local PREDICTION = 0.03

-- Button
local gui = Instance.new("ScreenGui")
gui.Name = "MobileAim"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(130, 60)
button.Position = UDim2.new(1, -150, 1, -100)
button.Text = "AIM: OFF"
button.TextSize = 18
button.Font = Enum.Font.GothamBold
button.TextColor3 = Color3.new(1, 1, 1)
button.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
button.Parent = gui

Instance.new("UICorner", button).CornerRadius =
	UDim.new(0, 12)

-- Find nearest player to screen center
local function findTarget()

	local closest = nil
	local closestDistance = FOV

	local center = Vector2.new(
		camera.ViewportSize.X / 2,
		camera.ViewportSize.Y / 2
	)

	for _, other in ipairs(Players:GetPlayers()) do

		if other ~= player and other.Character then

			local humanoid =
				other.Character:FindFirstChildOfClass("Humanoid")

			local head =
				other.Character:FindFirstChild("Head")

			if humanoid and humanoid.Health > 0 and head then

				local screenPosition, visible =
					camera:WorldToViewportPoint(head.Position)

				if visible and screenPosition.Z > 0 then

					local distance =
						(
							Vector2.new(
								screenPosition.X,
								screenPosition.Y
							) - center
						).Magnitude

					if distance < closestDistance then
						closestDistance = distance
						closest = other
					end
				end
			end
		end
	end

	return closest
end

-- Toggle button
button.Activated:Connect(function()

	aiming = not aiming

	if aiming then
		button.Text = "AIM: ON"
		button.BackgroundColor3 =
			Color3.fromRGB(45, 140, 75)

		target = findTarget()

	else
		button.Text = "AIM: OFF"
		button.BackgroundColor3 =
			Color3.fromRGB(45, 45, 50)

		target = nil
	end
end)

-- Aim loop
RunService.RenderStepped:Connect(function()

	if not aiming then
		return
	end

	if not target
		or not target.Character then

		target = findTarget()
		return
	end

	local head =
		target.Character:FindFirstChild("Head")

	if not head then
		target = findTarget()
		return
	end

	local velocity =
		head.AssemblyLinearVelocity

	local predictedPosition =
		head.Position +
		velocity * PREDICTION

	local desired =
		CFrame.lookAt(
			camera.CFrame.Position,
			predictedPosition
		)

	camera.CFrame =
		camera.CFrame:Lerp(
			desired,
			SMOOTHNESS
		)
end)