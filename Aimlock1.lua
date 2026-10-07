--// Mobile Aim Assist
--// Roblox Studio / Own Experience
--// Supports R6 + R15

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local Settings = {
	Enabled = false,

	TargetLock = true,
	TeamCheck = true,
	WallCheck = true,

	FOV = 220,
	Smoothness = 65,
	Prediction = 0.05,

	HitPart = "Head"
}

local Target = nil

--==================================================
-- CHARACTER / HIT PART
--==================================================

local function GetHitPart(character)
	if not character then
		return nil
	end

	-- Exact requested part first
	local part = character:FindFirstChild(Settings.HitPart)

	if part and part:IsA("BasePart") then
		return part
	end

	-- R6/R15 compatibility
	if Settings.HitPart == "Torso" then
		part = character:FindFirstChild("Torso")
			or character:FindFirstChild("UpperTorso")

	elseif Settings.HitPart == "UpperTorso" then
		part = character:FindFirstChild("UpperTorso")
			or character:FindFirstChild("Torso")
	end

	if part and part:IsA("BasePart") then
		return part
	end

	-- Universal fallback
	return character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChild("Head")
end

--==================================================
-- VALID PLAYER
--==================================================

local function IsValidTarget(player)
	if not player or player == LocalPlayer then
		return false
	end

	local character = player.Character

	if not character then
		return false
	end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	-- Team check
	if Settings.TeamCheck then
		if LocalPlayer.Team ~= nil
			and player.Team ~= nil
			and LocalPlayer.Team == player.Team then

			return false
		end
	end

	return GetHitPart(character) ~= nil
end

--==================================================
-- WALL CHECK
--==================================================

local function IsVisible(character, part)
	if not Settings.WallCheck then
		return true
	end

	local camera = workspace.CurrentCamera

	if not camera then
		return false
	end

	local origin = camera.CFrame.Position
	local direction = part.Position - origin

	local params = RaycastParams.new()

	params.FilterType = Enum.RaycastFilterType.Exclude

	params.FilterDescendantsInstances = {
		LocalPlayer.Character,
		camera
	}

	local result = workspace:Raycast(
		origin,
		direction,
		params
	)

	if not result then
		return true
	end

	return result.Instance:IsDescendantOf(character)
end

--==================================================
-- FIND CLOSEST TARGET
--==================================================

local function FindTarget()
	local camera = workspace.CurrentCamera

	if not camera then
		return nil
	end

	local viewport = camera.ViewportSize

	local center = Vector2.new(
		viewport.X / 2,
		viewport.Y / 2
	)

	local closestPlayer = nil
	local closestDistance = Settings.FOV

	for _, player in ipairs(Players:GetPlayers()) do

		if IsValidTarget(player) then

			local character = player.Character
			local part = GetHitPart(character)

			if part then

				local screenPoint, onScreen =
					camera:WorldToViewportPoint(
						part.Position
					)

				if onScreen and screenPoint.Z > 0 then

					local screenPosition =
						Vector2.new(
							screenPoint.X,
							screenPoint.Y
						)

					local distance =
						(screenPosition - center).Magnitude

					if distance <= closestDistance then

						if IsVisible(character, part) then
							closestDistance = distance
							closestPlayer = player
						end
					end
				end
			end
		end
	end

	return closestPlayer
end

--==================================================
-- TARGET STILL VALID
--==================================================

local function TargetStillValid(player)
	if not IsValidTarget(player) then
		return false
	end

	local character = player.Character
	local part = GetHitPart(character)

	if not part then
		return false
	end

	local camera = workspace.CurrentCamera

	if not camera then
		return false
	end

	-- Keep locked target inside FOV
	local screenPoint, onScreen =
		camera:WorldToViewportPoint(
			part.Position
		)

	if not onScreen or screenPoint.Z <= 0 then
		return false
	end

	local center = Vector2.new(
		camera.ViewportSize.X / 2,
		camera.ViewportSize.Y / 2
	)

	local distance =
		(
			Vector2.new(
				screenPoint.X,
				screenPoint.Y
			) - center
		).Magnitude

	if distance > Settings.FOV then
		return false
	end

	if not IsVisible(character, part) then
		return false
	end

	return true
end

--==================================================
-- AIM
--==================================================

local function AimAt(player, deltaTime)
	local camera = workspace.CurrentCamera

	if not camera then
		return
	end

	local character = player.Character

	if not character then
		return
	end

	local part = GetHitPart(character)

	if not part then
		return
	end

	local predictedPosition =
		part.Position +
		(part.AssemblyLinearVelocity * Settings.Prediction)

	local desiredCFrame =
		CFrame.lookAt(
			camera.CFrame.Position,
			predictedPosition
		)

	-- Smoothness:
	-- 1 = fast
	-- 100 = very smooth
	local responsiveness =
		1 - (Settings.Smoothness / 100)

	responsiveness =
		math.clamp(
			responsiveness,
			0.03,
			0.8
		)

	-- Framerate-independent smoothing
	local alpha =
		1 - math.pow(
			1 - responsiveness,
			deltaTime * 60
		)

	camera.CFrame =
		camera.CFrame:Lerp(
			desiredCFrame,
			alpha
		)
end

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")

Gui.Name = "MobileAimAssist"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = PlayerGui

--==================================================
-- FOV
--==================================================

local FOVCircle = Instance.new("Frame")

FOVCircle.Name = "FOV"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.fromScale(0.5, 0.5)
FOVCircle.Size =
	UDim2.fromOffset(
		Settings.FOV * 2,
		Settings.FOV * 2
	)

FOVCircle.BackgroundTransparency = 1
FOVCircle.Parent = Gui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

local FOVStroke = Instance.new("UIStroke")

FOVStroke.Thickness = 2
FOVStroke.Transparency = 0.15
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Parent = FOVCircle

--==================================================
-- OPEN BUTTON
--==================================================

local OpenButton = Instance.new("TextButton")

OpenButton.Size = UDim2.fromOffset(55, 55)
OpenButton.Position = UDim2.fromOffset(18, 90)
OpenButton.BackgroundColor3 =
	Color3.fromRGB(25, 25, 32)

OpenButton.Text = "☰"
OpenButton.TextColor3 = Color3.new(1, 1, 1)
OpenButton.TextSize = 24
OpenButton.Font = Enum.Font.GothamBold
OpenButton.Visible = false
OpenButton.Parent = Gui

Instance.new("UICorner", OpenButton).CornerRadius =
	UDim.new(0, 14)

--==================================================
-- PANEL
--==================================================

local Panel = Instance.new("Frame")

Panel.Size = UDim2.fromOffset(290, 365)
Panel.Position = UDim2.new(0, 18, 0.5, -182)
Panel.BackgroundColor3 =
	Color3.fromRGB(22, 22, 28)

Panel.BorderSizePixel = 0
Panel.Parent = Gui

Instance.new("UICorner", Panel).CornerRadius =
	UDim.new(0, 15)

local PanelStroke = Instance.new("UIStroke")

PanelStroke.Color =
	Color3.fromRGB(75, 75, 90)

PanelStroke.Transparency = 0.3
PanelStroke.Parent = Panel

--==================================================
-- TITLE
--==================================================

local Title = Instance.new("TextLabel")

Title.Size = UDim2.new(1, -60, 0, 45)
Title.Position = UDim2.fromOffset(15, 5)

Title.BackgroundTransparency = 1
Title.Text = "Mobile Aim Assist"

Title.TextColor3 =
	Color3.new(1, 1, 1)

Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment =
	Enum.TextXAlignment.Left

Title.Parent = Panel

--==================================================
-- CLOSE
--==================================================

local CloseButton = Instance.new("TextButton")

CloseButton.Size = UDim2.fromOffset(38, 38)
CloseButton.Position =
	UDim2.new(1, -48, 0, 9)

CloseButton.BackgroundColor3 =
	Color3.fromRGB(45, 45, 55)

CloseButton.Text = "×"
CloseButton.TextColor3 =
	Color3.new(1, 1, 1)

CloseButton.TextSize = 24
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = Panel

Instance.new("UICorner", CloseButton).CornerRadius =
	UDim.new(0, 10)

--==================================================
-- BUTTON CREATOR
--==================================================

local Y = 58

local function CreateButton(text)

	local button = Instance.new("TextButton")

	button.Size =
		UDim2.new(1, -30, 0, 42)

	button.Position =
		UDim2.fromOffset(15, Y)

	button.BackgroundColor3 =
		Color3.fromRGB(42, 42, 52)

	button.BorderSizePixel = 0

	button.Text = text
	button.TextColor3 =
		Color3.new(1, 1, 1)

	button.TextSize = 14
	button.Font = Enum.Font.GothamSemibold

	button.Parent = Panel

	Instance.new("UICorner", button).CornerRadius =
		UDim.new(0, 10)

	Y += 49

	return button
end

--==================================================
-- AIM BUTTON
--==================================================

local AimButton =
	CreateButton("Aim Assist : OFF")

local function UpdateAimButton()

	if Settings.Enabled then

		AimButton.Text =
			"Aim Assist : ON"

		AimButton.BackgroundColor3 =
			Color3.fromRGB(45, 135, 75)

	else

		AimButton.Text =
			"Aim Assist : OFF"

		AimButton.BackgroundColor3 =
			Color3.fromRGB(42, 42, 52)

		Target = nil
	end
end

AimButton.Activated:Connect(function()

	Settings.Enabled =
		not Settings.Enabled

	UpdateAimButton()
end)

--==================================================
-- TARGET LOCK
--==================================================

local LockButton =
	CreateButton("Target Lock : ON")

LockButton.Activated:Connect(function()

	Settings.TargetLock =
		not Settings.TargetLock

	LockButton.Text =
		"Target Lock : " ..
		(Settings.TargetLock and "ON" or "OFF")

	if not Settings.TargetLock then
		Target = nil
	end
end)

--==================================================
-- TEAM CHECK
--==================================================

local TeamButton =
	CreateButton("Team Check : ON")

TeamButton.Activated:Connect(function()

	Settings.TeamCheck =
		not Settings.TeamCheck

	TeamButton.Text =
		"Team Check : " ..
		(Settings.TeamCheck and "ON" or "OFF")

	Target = nil
end)

--==================================================
-- WALL CHECK
--==================================================

local WallButton =
	CreateButton("Wall Check : ON")

WallButton.Activated:Connect(function()

	Settings.WallCheck =
		not Settings.WallCheck

	WallButton.Text =
		"Wall Check : " ..
		(Settings.WallCheck and "ON" or "OFF")

	Target = nil
end)

--==================================================
-- HIT PART
--==================================================

local HitParts = {
	"Head",
	"Torso",
	"HumanoidRootPart"
}

local HitIndex = 1

local HitButton =
	CreateButton("Hit Part : Head")

HitButton.Activated:Connect(function()

	HitIndex += 1

	if HitIndex > #HitParts then
		HitIndex = 1
	end

	Settings.HitPart =
		HitParts[HitIndex]

	HitButton.Text =
		"Hit Part : " ..
		Settings.HitPart

	Target = nil
end)

--==================================================
-- OPEN / CLOSE
--==================================================

CloseButton.Activated:Connect(function()

	Panel.Visible = false
	OpenButton.Visible = true
end)

OpenButton.Activated:Connect(function()

	Panel.Visible = true
	OpenButton.Visible = false
end)

--==================================================
-- MAIN AIM LOOP
--==================================================

RunService:BindToRenderStep(
	"MobileAimAssist",
	Enum.RenderPriority.Camera.Value + 1,
	function(deltaTime)

		local camera =
			workspace.CurrentCamera

		if not camera then
			return
		end

		-- Update FOV
		FOVCircle.Position =
			UDim2.fromOffset(
				camera.ViewportSize.X / 2,
				camera.ViewportSize.Y / 2
			)

		FOVCircle.Size =
			UDim2.fromOffset(
				Settings.FOV * 2,
				Settings.FOV * 2
			)

		if not Settings.Enabled then

			Target = nil

			FOVStroke.Color =
				Color3.fromRGB(
					255,
					255,
					255
				)

			return
		end

		-- Acquire target
		if not Target then
			Target = FindTarget()
		end

		-- Check locked target
		if Target then

			if not TargetStillValid(Target) then

				Target = nil

			else

				FOVStroke.Color =
					Color3.fromRGB(
						50,
						255,
						100
					)

				AimAt(
					Target,
					deltaTime
				)

				-- If lock is disabled,
				-- choose again next frame.
				if not Settings.TargetLock then
					Target = nil
				end
			end
		end

		if not Target then

			FOVStroke.Color =
				Color3.fromRGB(
					255,
					255,
					255
				)
		end
	end
)

UpdateAimButton()