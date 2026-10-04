--// Head Lock / Aim Assist
--// For your own Roblox experience
--// PC + Mobile
--// Visible targets only

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- SETTINGS
--==================================================

local Enabled = false
local MaxDistance = 500
local Smoothness = 0.20

--==================================================
-- UI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "HeadLockUI"
Gui.ResetOnSpawn = false
Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Button = Instance.new("TextButton")
Button.Name = "Toggle"
Button.Size = UDim2.fromOffset(150, 55)
Button.Position = UDim2.new(1, -170, 1, -90)
Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Button.TextColor3 = Color3.new(1, 1, 1)
Button.TextSize = 18
Button.Font = Enum.Font.GothamBold
Button.Text = "HEAD LOCK: OFF"
Button.Parent = Gui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Button

--==================================================
-- TOGGLE
--==================================================

local function UpdateButton()
	if Enabled then
		Button.Text = "HEAD LOCK: ON"
		Button.BackgroundColor3 = Color3.fromRGB(40, 150, 70)
	else
		Button.Text = "HEAD LOCK: OFF"
		Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	end
end

local function Toggle()
	Enabled = not Enabled
	UpdateButton()
end

Button.Activated:Connect(Toggle)

-- PC keyboard toggle
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Q then
		Toggle()
	end
end)

--==================================================
-- CHECK IF TARGET IS VISIBLE
--==================================================

local function IsVisible(character, head)
	local origin = Camera.CFrame.Position
	local direction = head.Position - origin

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {
		LocalPlayer.Character
	}

	local result = workspace:Raycast(origin, direction, params)

	if not result then
		return true
	end

	return result.Instance:IsDescendantOf(character)
end

--==================================================
-- FIND CLOSEST VISIBLE HEAD
--==================================================

local function GetTarget()
	local closestHead = nil
	local closestDistance = math.huge

	local cameraPosition = Camera.CFrame.Position

	for _, player in ipairs(Players:GetPlayers()) do

		if player ~= LocalPlayer then

			local character = player.Character

			if character then

				local humanoid = character:FindFirstChildOfClass("Humanoid")
				local head = character:FindFirstChild("Head")

				if humanoid and head and humanoid.Health > 0 then

					local distance =
						(head.Position - cameraPosition).Magnitude

					if distance <= MaxDistance then

						-- Make sure the target is actually on screen
						local screenPosition, onScreen =
							Camera:WorldToViewportPoint(head.Position)

						if onScreen and screenPosition.Z > 0 then

							-- Don't lock through walls
							if IsVisible(character, head) then

								local center =
									Vector2.new(
										Camera.ViewportSize.X / 2,
										Camera.ViewportSize.Y / 2
									)

								local screenDistance =
									(Vector2.new(
										screenPosition.X,
										screenPosition.Y
									) - center).Magnitude

								if screenDistance < closestDistance then
									closestDistance = screenDistance
									closestHead = head
								end

							end
						end
					end
				end
			end
		end
	end

	return closestHead
end

--==================================================
-- AIM
--==================================================

RunService.RenderStepped:Connect(function()

	if not Enabled then
		return
	end

	local targetHead = GetTarget()

	if targetHead then

		local cameraPosition = Camera.CFrame.Position

		local desired =
			CFrame.lookAt(
				cameraPosition,
				targetHead.Position
			)

		Camera.CFrame =
			Camera.CFrame:Lerp(
				desired,
				Smoothness
			)
	end
end)

UpdateButton()