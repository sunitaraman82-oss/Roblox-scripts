--// Studio Mobile Aim Assist
--// Place this LocalScript in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = {
	Enabled = false,
	TargetLock = true,
	TeamCheck = true,
	WallCheck = true,

	FOV = 50,
	Smoothness = 100,
	Prediction = 0.08,

	HitPart = "Head"
}

local Target = nil
local UIVisible = true

--------------------------------------------------
-- CHARACTER / HIT PART
--------------------------------------------------

local function GetHitPart(character)
	if not character then
		return nil
	end

	local requested = character:FindFirstChild(Settings.HitPart)

	if requested and requested:IsA("BasePart") then
		return requested
	end

	-- R6 / R15 torso compatibility
	if Settings.HitPart == "Torso" then
		local torso = character:FindFirstChild("Torso")
			or character:FindFirstChild("UpperTorso")

		if torso then
			return torso
		end
	end

	if Settings.HitPart == "UpperTorso" then
		local torso = character:FindFirstChild("UpperTorso")
			or character:FindFirstChild("Torso")

		if torso then
			return torso
		end
	end

	return character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChild("Head")
end

--------------------------------------------------
-- TARGET VALIDATION
--------------------------------------------------

local function IsValidTarget(player)
	if not player or player == LocalPlayer then
		return false
	end

	local character = player.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	if Settings.TeamCheck and LocalPlayer.Team ~= nil then
		if player.Team == LocalPlayer.Team then
			return false
		end
	end

	return GetHitPart(character) ~= nil
end

--------------------------------------------------
-- WALL CHECK
--------------------------------------------------

local function IsVisible(character, part)
	if not Settings.WallCheck then
		return true
	end

	if not character or not part then
		return false
	end

	local origin = Camera.CFrame.Position
	local direction = part.Position - origin

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {
		LocalPlayer.Character,
		Camera
	}
	params.IgnoreWater = true

	local result = workspace:Raycast(origin, direction, params)

	if not result then
		return true
	end

	return result.Instance:IsDescendantOf(character)
end

--------------------------------------------------
-- TARGET FINDING
--------------------------------------------------

local function FindTarget()
	local bestTarget = nil
	local bestDistance = Settings.FOV

	local viewport = Camera.ViewportSize
	local screenCenter = Vector2.new(
		viewport.X / 2,
		viewport.Y / 2
	)

	for _, player in ipairs(Players:GetPlayers()) do
		if IsValidTarget(player) then
			local character = player.Character
			local part = GetHitPart(character)

			if part then
				local screenPosition, onScreen =
					Camera:WorldToViewportPoint(part.Position)

				if onScreen and screenPosition.Z > 0 then
					local screenPos = Vector2.new(
						screenPosition.X,
						screenPosition.Y
					)

					local distance =
						(screenPos - screenCenter).Magnitude

					if distance <= bestDistance then
						if IsVisible(character, part) then
							bestDistance = distance
							bestTarget = player
						end
					end
				end
			end
		end
	end

	return bestTarget
end

--------------------------------------------------
-- TARGET LOCK VALIDATION
--------------------------------------------------

local function TargetStillValid(player)
	if not IsValidTarget(player) then
		return false
	end

	local character = player.Character
	local part = GetHitPart(character)

	if not part then
		return false
	end

	local viewport = Camera.ViewportSize
	local center = Vector2.new(
		viewport.X / 2,
		viewport.Y / 2
	)

	local position, onScreen =
		Camera:WorldToViewportPoint(part.Position)

	if not onScreen or position.Z <= 0 then
		return false
	end

	local distance =
		(Vector2.new(position.X, position.Y) - center).Magnitude

	if distance > Settings.FOV then
		return false
	end

	return IsVisible(character, part)
end

--------------------------------------------------
-- AIM
--------------------------------------------------

local function AimAt(player, deltaTime)
	if not player or not player.Character then
		return
	end

	local part = GetHitPart(player.Character)

	if not part then
		return
	end

	local predictedPosition =
		part.Position + (part.AssemblyLinearVelocity * Settings.Prediction)

	local direction =
		predictedPosition - Camera.CFrame.Position

	if direction.Magnitude <= 0 then
		return
	end

	local targetCFrame =
		CFrame.lookAt(Camera.CFrame.Position, predictedPosition)

	-- Higher Smoothness = stronger/faster aim
	local strength =
		math.clamp(Settings.Smoothness / 100, 0, 1)

	local frameStrength =
		1 - math.pow(1 - strength, deltaTime * 60)

	Camera.CFrame =
		Camera.CFrame:Lerp(targetCFrame, frameStrength)
end

--------------------------------------------------
-- UI
--------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StudioAimAssistUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--------------------------------------------------
-- FOV CIRCLE
--------------------------------------------------

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Parent = ScreenGui

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = FOVCircle

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Thickness = 2
CircleStroke.Transparency = 0.15
CircleStroke.Parent = FOVCircle

--------------------------------------------------
-- OPEN BUTTON
--------------------------------------------------

local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Size = UDim2.fromOffset(55, 55)
OpenButton.Position = UDim2.new(0, 15, 0.5, -25)
OpenButton.Text = "☰"
OpenButton.TextSize = 25
OpenButton.BackgroundTransparency = 0.15
OpenButton.Parent = ScreenGui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, 12)
OpenCorner.Parent = OpenButton

--------------------------------------------------
-- PANEL
--------------------------------------------------

local Panel = Instance.new("Frame")
Panel.Name = "Panel"
Panel.Size = UDim2.fromOffset(250, 430)
Panel.Position = UDim2.new(0, 80, 0.5, -215)
Panel.BackgroundTransparency = 0.1
Panel.Parent = ScreenGui

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 14)
PanelCorner.Parent = Panel

--------------------------------------------------
-- TITLE
--------------------------------------------------

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 0, 45)
Title.Position = UDim2.fromOffset(12, 5)
Title.BackgroundTransparency = 1
Title.Text = "Aim Assist"
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Panel

--------------------------------------------------
-- CLOSE
--------------------------------------------------

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.fromOffset(40, 40)
CloseButton.Position = UDim2.new(1, -45, 0, 5)
CloseButton.Text = "×"
CloseButton.TextSize = 25
CloseButton.BackgroundTransparency = 1
CloseButton.Parent = Panel

--------------------------------------------------
-- BUTTON CREATOR
--------------------------------------------------

local ButtonY = 55

local function CreateButton(text)
	local button = Instance.new("TextButton")

	button.Size = UDim2.new(1, -20, 0, 42)
	button.Position = UDim2.fromOffset(10, ButtonY)
	button.Text = text
	button.TextSize = 16
	button.BackgroundTransparency = 0.15
	button.Parent = Panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = button

	ButtonY += 48

	return button
end

--------------------------------------------------
-- CONTROLS
--------------------------------------------------

local AimButton =
	CreateButton("Aim Assist : OFF")

local LockButton =
	CreateButton("Target Lock : ON")

local TeamButton =
	CreateButton("Team Check : ON")

local WallButton =
	CreateButton("Wall Check : ON")

local HitPartButton =
	CreateButton("Hit Part : Head")

local FOVButton =
	CreateButton("FOV : 50")

--------------------------------------------------
-- BUTTON EVENTS
--------------------------------------------------

AimButton.Activated:Connect(function()
	Settings.Enabled = not Settings.Enabled

	if not Settings.Enabled then
		Target = nil
	end

	AimButton.Text =
		"Aim Assist : " ..
		(Settings.Enabled and "ON" or "OFF")
end)

LockButton.Activated:Connect(function()
	Settings.TargetLock = not Settings.TargetLock

	if not Settings.TargetLock then
		Target = nil
	end

	LockButton.Text =
		"Target Lock : " ..
		(Settings.TargetLock and "ON" or "OFF")
end)

TeamButton.Activated:Connect(function()
	Settings.TeamCheck = not Settings.TeamCheck

	Target = nil

	TeamButton.Text =
		"Team Check : " ..
		(Settings.TeamCheck and "ON" or "OFF")
end)

WallButton.Activated:Connect(function()
	Settings.WallCheck = not Settings.WallCheck

	Target = nil

	WallButton.Text =
		"Wall Check : " ..
		(Settings.WallCheck and "ON" or "OFF")
end)

HitPartButton.Activated:Connect(function()
	if Settings.HitPart == "Head" then
		Settings.HitPart = "Torso"
	elseif Settings.HitPart == "Torso" then
		Settings.HitPart = "HumanoidRootPart"
	else
		Settings.HitPart = "Head"
	end

	Target = nil

	HitPartButton.Text =
		"Hit Part : " .. Settings.HitPart
end)

-- 50 -> 60 -> 70 -> 80 -> 90 -> 100 -> 50
FOVButton.Activated:Connect(function()
	Settings.FOV += 10

	if Settings.FOV > 100 then
		Settings.FOV = 50
	end

	FOVButton.Text =
		"FOV : " .. Settings.FOV

	Target = nil
end)

--------------------------------------------------
-- OPEN / CLOSE
--------------------------------------------------

CloseButton.Activated:Connect(function()
	UIVisible = false
	Panel.Visible = false
end)

OpenButton.Activated:Connect(function()
	UIVisible = true
	Panel.Visible = true
end)

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------

RunService:BindToRenderStep(
	"StudioMobileAimAssist",
	Enum.RenderPriority.Camera.Value + 1,
	function(deltaTime)

		local viewport = Camera.ViewportSize

		FOVCircle.Size = UDim2.fromOffset(
			Settings.FOV * 2,
			Settings.FOV * 2
		)

		FOVCircle.Position =
			UDim2.fromOffset(
				viewport.X / 2,
				viewport.Y / 2
			)

		if not Settings.Enabled then
			Target = nil
			return
		end

		if Settings.TargetLock then
			if not Target or not TargetStillValid(Target) then
				Target = FindTarget()
			end
		else
			Target = FindTarget()
		end

		if Target then
			AimAt(Target, deltaTime)
		end
	end
)