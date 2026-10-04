local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- SETTINGS
--==================================================

local Enabled = false
local TargetLock = false

local FOV = 250
local Smoothness = 50 -- 10-100

local Target = nil

--==================================================
-- UI
--==================================================

local GUI = Instance.new("ScreenGui")
GUI.Name = "AimAssistUI"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(260, 245)
Main.Position = UDim2.new(0, 20, 0.5, -122)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = GUI

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Main

-- Automatically scales the UI for different screens
local Scale = Instance.new("UIScale")
Scale.Parent = Main

local function updateScale()
	local camera = workspace.CurrentCamera
	if not camera then return end

	local width = camera.ViewportSize.X

	if width < 500 then
		Scale.Scale = 0.78
	elseif width < 800 then
		Scale.Scale = 0.9
	else
		Scale.Scale = 1
	end
end

updateScale()

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize")
	:Connect(updateScale)

--==================================================
-- TITLE
--==================================================

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 38)
Title.Position = UDim2.new(0, 10, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "AIM ASSIST"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 19
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

--==================================================
-- BUTTON CREATOR
--==================================================

local function CreateButton(text, y)

	local Button = Instance.new("TextButton")

	Button.Size = UDim2.new(1, -24, 0, 38)
	Button.Position = UDim2.new(0, 12, 0, y)

	Button.BackgroundColor3 = Color3.fromRGB(48, 48, 48)
	Button.TextColor3 = Color3.new(1, 1, 1)

	Button.Text = text
	Button.TextSize = 14
	Button.Font = Enum.Font.GothamMedium

	Button.AutoButtonColor = true
	Button.BorderSizePixel = 0

	Button.Parent = Main

	local C = Instance.new("UICorner")
	C.CornerRadius = UDim.new(0, 8)
	C.Parent = Button

	return Button
end

local AimButton =
	CreateButton("Aim Assist: OFF", 48)

local LockButton =
	CreateButton("Target Lock: OFF", 92)

--==================================================
-- SLIDER CREATOR
--==================================================

local function CreateSlider(title, y, minValue, maxValue, defaultValue)

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -24, 0, 20)
	Label.Position = UDim2.new(0, 12, 0, y)

	Label.BackgroundTransparency = 1
	Label.TextColor3 = Color3.new(1, 1, 1)
	Label.TextSize = 13
	Label.Font = Enum.Font.Gotham

	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Main

	local Bar = Instance.new("Frame")
	Bar.Size = UDim2.new(1, -24, 0, 8)
	Bar.Position = UDim2.new(0, 12, 0, y + 25)

	Bar.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
	Bar.BorderSizePixel = 0
	Bar.Active = true
	Bar.Parent = Main

	local BarCorner = Instance.new("UICorner")
	BarCorner.CornerRadius = UDim.new(1, 0)
	BarCorner.Parent = Bar

	local Fill = Instance.new("Frame")
	Fill.Size = UDim2.new(
		(defaultValue - minValue) /
		(maxValue - minValue),
		0, 1, 0
	)

	Fill.BackgroundColor3 = Color3.fromRGB(70, 150, 255)
	Fill.BorderSizePixel = 0
	Fill.Parent = Bar

	local FillCorner = Instance.new("UICorner")
	FillCorner.CornerRadius = UDim.new(1, 0)
	FillCorner.Parent = Fill

	local Knob = Instance.new("Frame")
	Knob.Size = UDim2.fromOffset(14, 14)
	Knob.AnchorPoint = Vector2.new(0.5, 0.5)
	Knob.Position = UDim2.new(
		(defaultValue - minValue) /
		(maxValue - minValue),
		0, 0.5, 0
	)

	Knob.BackgroundColor3 = Color3.new(1, 1, 1)
	Knob.BorderSizePixel = 0
	Knob.Parent = Bar

	local KnobCorner = Instance.new("UICorner")
	KnobCorner.CornerRadius = UDim.new(1, 0)
	KnobCorner.Parent = Knob

	local Value = defaultValue

	local function SetValue(number)

		Value = math.clamp(
			math.round(number),
			minValue,
			maxValue
		)

		local Percent =
			(Value - minValue) /
			(maxValue - minValue)

		Fill.Size =
			UDim2.new(Percent, 0, 1, 0)

		Knob.Position =
			UDim2.new(Percent, 0, 0.5, 0)

		Label.Text =
			title .. ": " .. Value
	end

	local function SetFromInput(input)

		local X = input.Position.X
		local BarX = Bar.AbsolutePosition.X
		local BarWidth = Bar.AbsoluteSize.X

		local Percent =
			math.clamp(
				(X - BarX) / BarWidth,
				0,
				1
			)

		SetValue(
			minValue +
			((maxValue - minValue) * Percent)
		)
	end

	local Dragging = false

	Bar.InputBegan:Connect(function(input)

		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			Dragging = true
			SetFromInput(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)

		if not Dragging then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then

			SetFromInput(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)

		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			Dragging = false
		end
	end)

	SetValue(defaultValue)

	return function()
		return Value
	end
end

--==================================================
-- FOV + SMOOTHNESS
--==================================================

local GetFOV = CreateSlider(
	"FOV",
	138,
	50,
	500,
	FOV
)

local GetSmoothness = CreateSlider(
	"Smoothness",
	190,
	10,
	100,
	Smoothness
)

--==================================================
-- BUTTONS
--==================================================

AimButton.Activated:Connect(function()

	Enabled = not Enabled

	if Enabled then
		AimButton.Text = "Aim Assist: ON"
		AimButton.BackgroundColor3 =
			Color3.fromRGB(40, 140, 75)
	else
		AimButton.Text = "Aim Assist: OFF"
		AimButton.BackgroundColor3 =
			Color3.fromRGB(48, 48, 48)

		Target = nil
	end
end)

LockButton.Activated:Connect(function()

	TargetLock = not TargetLock

	if TargetLock then
		LockButton.Text = "Target Lock: ON"
		LockButton.BackgroundColor3 =
			Color3.fromRGB(40, 140, 75)
	else
		LockButton.Text = "Target Lock: OFF"
		LockButton.BackgroundColor3 =
			Color3.fromRGB(48, 48, 48)

		Target = nil
	end
end)

--==================================================
-- TARGET CHECK
--==================================================

local function IsValidTarget(Player)

	if Player == LocalPlayer then
		return false
	end

	local Character = Player.Character

	if not Character then
		return false
	end

	local Humanoid =
		Character:FindFirstChildOfClass("Humanoid")

	local Head =
		Character:FindFirstChild("Head")

	if not Humanoid or Humanoid.Health <= 0 then
		return false
	end

	if not Head then
		return false
	end

	return true
end

--==================================================
-- FIND BEST TARGET
--==================================================

local function GetTarget()

	local BestTarget = nil
	local BestDistance = GetFOV()

	local Center = Vector2.new(
		Camera.ViewportSize.X / 2,
		Camera.ViewportSize.Y / 2
	)

	for _, Player in ipairs(Players:GetPlayers()) do

		if IsValidTarget(Player) then

			local Head =
				Player.Character:FindFirstChild("Head")

			local Position, Visible =
				Camera:WorldToViewportPoint(
					Head.Position
				)

			if Visible and Position.Z > 0 then

				local ScreenPosition =
					Vector2.new(
						Position.X,
						Position.Y
					)

				local Distance =
					(ScreenPosition - Center).Magnitude

				if Distance < BestDistance then
					BestDistance = Distance
					BestTarget = Player
				end
			end
		end
	end

	return BestTarget
end

--==================================================
-- AIM LOOP
--==================================================

RunService:BindToRenderStep(
	"AimAssist",
	Enum.RenderPriority.Camera.Value + 1,
	function()

		if not Enabled then
			return
		end

		if not Target or not IsValidTarget(Target) then
			Target = GetTarget()
		end

		if not Target then
			return
		end

		local Character = Target.Character
		local Head = Character and Character:FindFirstChild("Head")

		if not Head then
			Target = nil
			return
		end

		local Smooth = GetSmoothness()

		-- 10 = slower/smoother
		-- 100 = faster/stronger
		local Alpha = Smooth / 100

		local Desired =
			CFrame.lookAt(
				Camera.CFrame.Position,
				Head.Position
			)

		Camera.CFrame =
			Camera.CFrame:Lerp(
				Desired,
				Alpha
			)

		if not TargetLock then
			Target = GetTarget()
		end
	end
)

--==================================================
-- CLEANUP
--==================================================

Players.PlayerRemoving:Connect(function(Player)

	if Target == Player then
		Target = nil
	end
end)