--// Training Target Lock
--// For your own Roblox Studio experience / private testing

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- SETTINGS
--==================================================

local Settings = {
	Enabled = false,
	TargetLock = true,
	WallCheck = true,

	HitPart = "Random", -- Head / Body / Random

	FOV = 100,
	MaxDistance = 500,

	DetectMovingOnly = true,
	MinimumVelocity = 0.05,

	Smoothness = 0.25
}

--==================================================
-- TARGET FOLDER
--==================================================

local TargetFolder = workspace:FindFirstChild("TrainingTargets")

if not TargetFolder then
	TargetFolder = Instance.new("Folder")
	TargetFolder.Name = "TrainingTargets"
	TargetFolder.Parent = workspace
end

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "TrainingAimUI"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = Player:WaitForChild("PlayerGui")

--==================================================
-- FOV CIRCLE
--==================================================

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.Size = UDim2.fromOffset(Settings.FOV * 2, Settings.FOV * 2)
FOVCircle.Position = UDim2.fromScale(0.5, 0.5)
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Visible = true
FOVCircle.Parent = Gui

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = FOVCircle

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Thickness = 2
CircleStroke.Transparency = 0.2
CircleStroke.Parent = FOVCircle

--==================================================
-- MAIN PANEL
--==================================================

local Panel = Instance.new("Frame")
Panel.Name = "MainPanel"
Panel.Size = UDim2.fromOffset(230, 300)
Panel.Position = UDim2.new(0, 20, 0.5, -150)
Panel.BackgroundTransparency = 0.12
Panel.Parent = Gui

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 14)
PanelCorner.Parent = Panel

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Thickness = 1
PanelStroke.Transparency = 0.4
PanelStroke.Parent = Panel

--==================================================
-- TITLE
--==================================================

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 40)
Title.Position = UDim2.fromOffset(10, 5)
Title.BackgroundTransparency = 1
Title.Text = "TARGET TRAINER"
Title.TextSize = 19
Title.Font = Enum.Font.GothamBold
Title.Parent = Panel

--==================================================
-- BUTTON CREATOR
--==================================================

local function CreateButton(text, y)
	local Button = Instance.new("TextButton")

	Button.Size = UDim2.new(1, -30, 0, 40)
	Button.Position = UDim2.fromOffset(15, y)

	Button.BackgroundTransparency = 0.15
	Button.Text = text
	Button.TextSize = 15
	Button.Font = Enum.Font.GothamBold

	Button.AutoButtonColor = true

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 10)
	Corner.Parent = Button

	Button.Parent = Panel

	return Button
end

--==================================================
-- BUTTONS
--==================================================

local LockButton = CreateButton("Target Lock: OFF", 50)
local DetectButton = CreateButton("Detection: ON", 95)
local WallButton = CreateButton("Wall Check: ON", 140)
local HitButton = CreateButton("Hit Part: Random", 185)
local TargetButton = CreateButton("TARGET", 230)

--==================================================
-- STATUS
--==================================================

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 25)
Status.Position = UDim2.fromOffset(10, 275)
Status.BackgroundTransparency = 1
Status.Text = "No target"
Status.TextSize = 13
Status.Font = Enum.Font.Gotham
Status.Parent = Panel

--==================================================
-- MINIMIZE BUTTON
--==================================================

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(45, 45)
Minimize.Position = UDim2.fromOffset(20, 20)
Minimize.Text = "≡"
Minimize.TextSize = 25
Minimize.Font = Enum.Font.GothamBold
Minimize.BackgroundTransparency = 0.15
Minimize.Parent = Gui

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = Minimize

local Open = true

Minimize.MouseButton1Click:Connect(function()
	Open = not Open
	Panel.Visible = Open
end)

--==================================================
-- SETTINGS
--==================================================

LockButton.MouseButton1Click:Connect(function()
	Settings.TargetLock = not Settings.TargetLock
	Settings.Enabled = Settings.TargetLock

	if Settings.TargetLock then
		LockButton.Text = "Target Lock: ON"
	else
		LockButton.Text = "Target Lock: OFF"
	end
end)

DetectButton.MouseButton1Click:Connect(function()
	Settings.DetectMovingOnly = not Settings.DetectMovingOnly

	if Settings.DetectMovingOnly then
		DetectButton.Text = "Detection: MOVING"
	else
		DetectButton.Text = "Detection: ALL"
	end
end)

WallButton.MouseButton1Click:Connect(function()
	Settings.WallCheck = not Settings.WallCheck

	if Settings.WallCheck then
		WallButton.Text = "Wall Check: ON"
	else
		WallButton.Text = "Wall Check: OFF"
	end
end)

HitButton.MouseButton1Click:Connect(function()

	if Settings.HitPart == "Random" then
		Settings.HitPart = "Head"

	elseif Settings.HitPart == "Head" then
		Settings.HitPart = "Body"

	else
		Settings.HitPart = "Random"
	end

	HitButton.Text = "Hit Part: " .. Settings.HitPart
end)

TargetButton.MouseButton1Click:Connect(function()
	Settings.Enabled = not Settings.Enabled

	if Settings.Enabled then
		LockButton.Text = "Target Lock: ON"
	else
		LockButton.Text = "Target Lock: OFF"
	end
end)

--==================================================
-- TARGET HELPERS
--==================================================

local function GetRoot(target)

	if target:IsA("BasePart") then
		return target
	end

	if target:IsA("Model") then

		local root =
			target:FindFirstChild("HumanoidRootPart")
			or target.PrimaryPart
			or target:FindFirstChildWhichIsA("BasePart")

		return root
	end

	return nil
end

local function GetHumanoid(target)

	if target:IsA("Model") then
		return target:FindFirstChildOfClass("Humanoid")
	end

	return nil
end

--==================================================
-- HIT PART
--==================================================

local function GetHitPart(target)

	if target:IsA("BasePart") then
		return target
	end

	if not target:IsA("Model") then
		return nil
	end

	local Head = target:FindFirstChild("Head")
	local Root = target:FindFirstChild("HumanoidRootPart")

	local Body =
		target:FindFirstChild("UpperTorso")
		or target:FindFirstChild("Torso")
		or Root

	if Settings.HitPart == "Head" then
		return Head or Body
	end

	if Settings.HitPart == "Body" then
		return Body or Head
	end

	-- Random
	local Parts = {}

	if Head then
		table.insert(Parts, Head)
	end

	if Body then
		table.insert(Parts, Body)
	end

	if #Parts > 0 then
		return Parts[math.random(1, #Parts)]
	end

	return Root
end

--==================================================
-- WALL CHECK
--==================================================

local function IsVisible(part)

	if not Settings.WallCheck then
		return true
	end

	local Character = Player.Character

	if not Character then
		return false
	end

	local Origin = Camera.CFrame.Position
	local Direction = part.Position - Origin

	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = {
		Character
	}

	local Result = workspace:Raycast(
		Origin,
		Direction,
		Params
	)

	if not Result then
		return true
	end

	return Result.Instance:IsDescendantOf(part.Parent)
end

--==================================================
-- GET CLOSEST TARGET
--==================================================

local function GetClosestTarget()

	local BestTarget = nil
	local BestPart = nil
	local BestDistance = Settings.FOV

	local Center =
		Vector2.new(
			Camera.ViewportSize.X / 2,
			Camera.ViewportSize.Y / 2
		)

	for _, Target in ipairs(TargetFolder:GetChildren()) do

		local Root = GetRoot(Target)

		if Root then

			local Distance3D =
				(Camera.CFrame.Position - Root.Position).Magnitude

			if Distance3D <= Settings.MaxDistance then

				local Moving = true

				if Settings.DetectMovingOnly then

					if Root:IsA("BasePart") then
						Moving =
							Root.AssemblyLinearVelocity.Magnitude
							>= Settings.MinimumVelocity
					end

				end

				if Moving then

					local Part = GetHitPart(Target)

					if Part then

						local ScreenPosition, OnScreen =
							Camera:WorldToViewportPoint(Part.Position)

						if OnScreen then

							local ScreenDistance =
								(
									Vector2.new(
										ScreenPosition.X,
										ScreenPosition.Y
									)
									- Center
								).Magnitude

							if ScreenDistance <= BestDistance then

								if IsVisible(Part) then

									BestDistance = ScreenDistance
									BestTarget = Target
									BestPart = Part

								end

							end

						end
					end
				end
			end
		end
	end

	return BestTarget, BestPart
end

--==================================================
-- AIM
--==================================================

local CurrentTarget = nil
local CurrentPart = nil

local function AimAt(part)

	if not part then
		return
	end

	local CameraPosition = Camera.CFrame.Position

	local Desired =
		CFrame.lookAt(
			CameraPosition,
			part.Position
		)

	Camera.CFrame =
		Camera.CFrame:Lerp(
			Desired,
			Settings.Smoothness
		)
end

--==================================================
-- UPDATE FOV
--==================================================

local function UpdateFOV()

	FOVCircle.Size =
		UDim2.fromOffset(
			Settings.FOV * 2,
			Settings.FOV * 2
		)

	FOVCircle.Position =
		UDim2.fromScale(0.5, 0.5)

end

--==================================================
-- MAIN LOOP
--==================================================

RunService.RenderStepped:Connect(function()

	UpdateFOV()

	if not Settings.Enabled then

		CurrentTarget = nil
		CurrentPart = nil

		Status.Text = "Disabled"

		return
	end

	local Target, Part =
		GetClosestTarget()

	CurrentTarget = Target
	CurrentPart = Part

	if Target and Part then

		Status.Text =
			"Target: " .. Target.Name

		if Settings.TargetLock then
			AimAt(Part)
		end

	else

		Status.Text = "No target"

	end
end)

--==================================================
-- KEYBOARD SUPPORT
--==================================================

UserInputService.InputBegan:Connect(function(Input, Processed)

	if Processed then
		return
	end

	if Input.KeyCode == Enum.KeyCode.Q then

		Settings.Enabled =
			not Settings.Enabled

		if Settings.Enabled then
			LockButton.Text = "Target Lock: ON"
		else
			LockButton.Text = "Target Lock: OFF"
		end
	end

end)