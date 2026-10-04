--// TARGET TRAINER - STUDIO TESTING
--// Detects Parts/Models that move by CFrame, Tween, or physics

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

	FOV = 300,
	MaxDistance = 1000,

	WallCheck = false,

	HitPart = "Random",

	-- Position-change detection
	MovementThreshold = 0.01,

	Smoothness = 0.25
}

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "TargetTrainer"
Gui.ResetOnSpawn = false
Gui.Parent = Player:WaitForChild("PlayerGui")

--==================================================
-- FOV
--==================================================

local FOV = Instance.new("Frame")
FOV.Size = UDim2.fromOffset(Settings.FOV * 2, Settings.FOV * 2)
FOV.Position = UDim2.fromScale(0.5, 0.5)
FOV.AnchorPoint = Vector2.new(0.5, 0.5)
FOV.BackgroundTransparency = 1
FOV.Parent = Gui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOV

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 2
FOVStroke.Parent = FOV

--==================================================
-- MAIN PANEL
--==================================================

local Panel = Instance.new("Frame")
Panel.Size = UDim2.fromOffset(230, 300)
Panel.Position = UDim2.new(0, 20, 0.5, -150)
Panel.BackgroundTransparency = 0.1
Panel.Parent = Gui

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 14)
PanelCorner.Parent = Panel

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "TARGET TRAINER"
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.Parent = Panel

--==================================================
-- BUTTON FUNCTION
--==================================================

local function Button(text, y)

	local B = Instance.new("TextButton")

	B.Size = UDim2.new(1, -20, 0, 42)
	B.Position = UDim2.fromOffset(10, y)

	B.Text = text
	B.TextSize = 14
	B.Font = Enum.Font.GothamBold

	B.BackgroundTransparency = 0.15

	local C = Instance.new("UICorner")
	C.CornerRadius = UDim.new(0, 9)
	C.Parent = B

	B.Parent = Panel

	return B
end

local LockButton = Button("Target Lock: OFF", 45)
local HitButton = Button("Hit Part: Random", 92)
local DetectButton = Button("Detection: ALL MOVING", 139)
local TargetButton = Button("FIND TARGET", 186)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 45)
Status.Position = UDim2.fromOffset(10, 240)
Status.BackgroundTransparency = 1
Status.Text = "No target"
Status.TextSize = 13
Status.Font = Enum.Font.Gotham
Status.TextWrapped = true
Status.Parent = Panel

--==================================================
-- MINIMIZE
--==================================================

local Mini = Instance.new("TextButton")
Mini.Size = UDim2.fromOffset(50, 50)
Mini.Position = UDim2.fromOffset(20, 20)
Mini.Text = "≡"
Mini.TextSize = 25
Mini.Font = Enum.Font.GothamBold
Mini.Parent = Gui

local MiniCorner = Instance.new("UICorner")
MiniCorner.CornerRadius = UDim.new(1, 0)
MiniCorner.Parent = Mini

Mini.MouseButton1Click:Connect(function()
	Panel.Visible = not Panel.Visible
end)

--==================================================
-- GET ROOT PART
--==================================================

local function GetRoot(Object)

	if Object:IsA("BasePart") then
		return Object
	end

	if Object:IsA("Model") then

		return Object:FindFirstChild("HumanoidRootPart")
			or Object.PrimaryPart
			or Object:FindFirstChildWhichIsA("BasePart")
	end

	return nil
end

--==================================================
-- GET HIT PART
--==================================================

local function GetHitPart(Object)

	if Object:IsA("BasePart") then
		return Object
	end

	if not Object:IsA("Model") then
		return nil
	end

	local Head = Object:FindFirstChild("Head")
	local Body =
		Object:FindFirstChild("UpperTorso")
		or Object:FindFirstChild("Torso")
		or Object:FindFirstChild("HumanoidRootPart")

	if Settings.HitPart == "Head" then
		return Head or Body
	end

	if Settings.HitPart == "Body" then
		return Body or Head
	end

	local Choices = {}

	if Head then
		table.insert(Choices, Head)
	end

	if Body then
		table.insert(Choices, Body)
	end

	if #Choices > 0 then
		return Choices[math.random(1, #Choices)]
	end

	return nil
end

--==================================================
-- MOVEMENT TRACKING
--==================================================

local PreviousPositions = {}

local function IsMoving(Object, Root)

	local LastPosition = PreviousPositions[Object]

	PreviousPositions[Object] = Root.Position

	if not LastPosition then
		return false
	end

	local Difference =
		(Root.Position - LastPosition).Magnitude

	return Difference >= Settings.MovementThreshold
end

--==================================================
-- GET ALL POSSIBLE TARGETS
--==================================================

local function GetObjects()

	local Objects = {}

	for _, Object in ipairs(workspace:GetChildren()) do

		if Object ~= Player.Character
			and not Object:IsA("Camera")
			and not Object:IsA("Terrain") then

			if Object:IsA("BasePart")
				or Object:IsA("Model") then

				table.insert(Objects, Object)
			end
		end
	end

	return Objects
end

--==================================================
-- WALL CHECK
--==================================================

local function Visible(Part)

	if not Settings.WallCheck then
		return true
	end

	local Character = Player.Character

	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = {
		Character
	}

	local Origin = Camera.CFrame.Position
	local Direction = Part.Position - Origin

	local Result = workspace:Raycast(
		Origin,
		Direction,
		Params
	)

	if not Result then
		return true
	end

	return Result.Instance:IsDescendantOf(
		Part.Parent
	)
end

--==================================================
-- FIND TARGET
--==================================================

local function FindTarget()

	local Center = Vector2.new(
		Camera.ViewportSize.X / 2,
		Camera.ViewportSize.Y / 2
	)

	local BestTarget = nil
	local BestPart = nil
	local BestScreenDistance = Settings.FOV

	for _, Object in ipairs(GetObjects()) do

		local Root = GetRoot(Object)

		if Root then

			local Distance =
				(Camera.CFrame.Position - Root.Position).Magnitude

			if Distance <= Settings.MaxDistance then

				local Moving =
					IsMoving(Object, Root)

				if Moving then

					local Part = GetHitPart(Object)

					if Part then

						local ScreenPos, OnScreen =
							Camera:WorldToViewportPoint(
								Part.Position
							)

						if OnScreen then

							local ScreenDistance =
								(
									Vector2.new(
										ScreenPos.X,
										ScreenPos.Y
									) - Center
								).Magnitude

							if ScreenDistance <= BestScreenDistance then

								if Visible(Part) then

									BestScreenDistance =
										ScreenDistance

									BestTarget =
										Object

									BestPart =
										Part
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

local function AimAt(Part)

	if not Part then
		return
	end

	local CameraPosition =
		Camera.CFrame.Position

	local Goal =
		CFrame.lookAt(
			CameraPosition,
			Part.Position
		)

	Camera.CFrame =
		Camera.CFrame:Lerp(
			Goal,
			Settings.Smoothness
		)
end

--==================================================
-- BUTTONS
--==================================================

LockButton.MouseButton1Click:Connect(function()

	Settings.Enabled =
		not Settings.Enabled

	if Settings.Enabled then
		LockButton.Text = "Target Lock: ON"
	else
		LockButton.Text = "Target Lock: OFF"
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

	HitButton.Text =
		"Hit Part: " .. Settings.HitPart
end)

TargetButton.MouseButton1Click:Connect(function()

	local Target, Part = FindTarget()

	if Target and Part then

		Status.Text =
			"FOUND: " .. Target.Name

		if Settings.TargetLock then
			AimAt(Part)
		end

	else

		Status.Text =
			"No moving target found"

	end
end)

--==================================================
-- MAIN LOOP
--==================================================

RunService.RenderStepped:Connect(function()

	if not Settings.Enabled then
		Status.Text = "Target Lock OFF"
		return
	end

	local Target, Part =
		FindTarget()

	if Target and Part then

		Status.Text =
			"LOCKED: " .. Target.Name

		if Settings.TargetLock then
			AimAt(Part)
		end

	else

		Status.Text =
			"Searching for moving target..."
	end
end)

--==================================================
-- KEYBOARD
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

print("TARGET TRAINER LOADED")