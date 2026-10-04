--========================================================
--              AIM ASSIST - FINAL VERSION
--              Roblox Studio / Own Experience
--========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--========================================================
-- SETTINGS
--========================================================

local AimEnabled = false
local TargetLock = false
local WallCheck = true
local TeamCheck = true

local FOV = 250
local Smoothness = 50

local HitParts = {
	"Head",
	"Torso",
	"HumanoidRootPart"
}

local HitPartIndex = 1
local Target = nil

--========================================================
-- GUI
--========================================================

local GUI = Instance.new("ScreenGui")
GUI.Name = "AimAssistUI"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")

--========================================================
-- MAIN WINDOW
--========================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(285, 390)
Main.Position = UDim2.new(0, 20, 0.5, -195)

Main.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
Main.BackgroundTransparency = 0.05
Main.BorderSizePixel = 0

Main.Active = true
Main.Parent = GUI

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(65, 65, 70)
MainStroke.Thickness = 1
MainStroke.Parent = Main

--========================================================
-- RESPONSIVE SCALE
--========================================================

local Scale = Instance.new("UIScale")
Scale.Parent = Main

local function UpdateScale()

	local Size = Camera.ViewportSize

	if Size.X < 500 then
		Scale.Scale = 0.72
	elseif Size.X < 800 then
		Scale.Scale = 0.88
	else
		Scale.Scale = 1
	end
end

UpdateScale()

Camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)

--========================================================
-- DRAGGING - PC + MOBILE
--========================================================

local Dragging = false
local DragStart
local StartPosition

local function UpdateDrag(Input)

	local Delta = Input.Position - DragStart

	Main.Position = UDim2.new(
		StartPosition.X.Scale,
		StartPosition.X.Offset + Delta.X,
		StartPosition.Y.Scale,
		StartPosition.Y.Offset + Delta.Y
	)
end

Main.InputBegan:Connect(function(Input)

	if Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.UserInputType == Enum.UserInputType.Touch then

		Dragging = true
		DragStart = Input.Position
		StartPosition = Main.Position
	end
end)

Main.InputChanged:Connect(function(Input)

	if Input.UserInputType == Enum.UserInputType.MouseMovement
		or Input.UserInputType == Enum.UserInputType.Touch then

		Input.Changed:Connect(function()

			if Input.UserInputState == Enum.UserInputState.End then
				Dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(Input)

	if Dragging then

		if Input.UserInputType == Enum.UserInputType.MouseMovement
			or Input.UserInputType == Enum.UserInputType.Touch then

			UpdateDrag(Input)
		end
	end
end)

--========================================================
-- TITLE
--========================================================

local Title = Instance.new("TextLabel")

Title.Size = UDim2.new(1, -20, 0, 42)
Title.Position = UDim2.fromOffset(10, 4)

Title.BackgroundTransparency = 1
Title.Text = "AIM ASSIST"

Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold

Title.Parent = Main

--========================================================
-- BUTTON CREATOR
--========================================================

local function CreateButton(Text, Y)

	local Button = Instance.new("TextButton")

	Button.Size = UDim2.new(1, -24, 0, 38)
	Button.Position = UDim2.fromOffset(12, Y)

	Button.BackgroundColor3 =
		Color3.fromRGB(48, 48, 53)

	Button.BorderSizePixel = 0

	Button.Text = Text
	Button.TextColor3 =
		Color3.fromRGB(255, 255, 255)

	Button.TextSize = 14
	Button.Font = Enum.Font.GothamMedium

	Button.AutoButtonColor = true

	Button.Parent = Main

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = Button

	return Button
end

local AimButton =
	CreateButton("Aim Assist: OFF", 48)

local LockButton =
	CreateButton("Target Lock: OFF", 92)

local WallButton =
	CreateButton("Wall Check: ON", 136)

local TeamButton =
	CreateButton("Team Check: ON", 180)

local HitButton =
	CreateButton("Hit Part: Head", 224)

--========================================================
-- SLIDER CREATOR
--========================================================

local function CreateSlider(
	TitleText,
	Y,
	Minimum,
	Maximum,
	Default
)

	local Label = Instance.new("TextLabel")

	Label.Size = UDim2.new(1, -24, 0, 20)
	Label.Position = UDim2.fromOffset(12, Y)

	Label.BackgroundTransparency = 1

	Label.TextColor3 =
		Color3.fromRGB(230, 230, 230)

	Label.TextSize = 13
	Label.Font = Enum.Font.Gotham

	Label.TextXAlignment =
		Enum.TextXAlignment.Left

	Label.Parent = Main

	local Bar = Instance.new("Frame")

	Bar.Size = UDim2.new(1, -24, 0, 8)
	Bar.Position = UDim2.fromOffset(12, Y + 25)

	Bar.BackgroundColor3 =
		Color3.fromRGB(65, 65, 70)

	Bar.BorderSizePixel = 0
	Bar.Active = true

	Bar.Parent = Main

	local BarCorner = Instance.new("UICorner")
	BarCorner.CornerRadius = UDim.new(1, 0)
	BarCorner.Parent = Bar

	local Fill = Instance.new("Frame")

	Fill.BackgroundColor3 =
		Color3.fromRGB(70, 150, 255)

	Fill.BorderSizePixel = 0
	Fill.Parent = Bar

	local FillCorner = Instance.new("UICorner")
	FillCorner.CornerRadius = UDim.new(1, 0)
	FillCorner.Parent = Fill

	local Knob = Instance.new("Frame")

	Knob.Size = UDim2.fromOffset(14, 14)
	Knob.AnchorPoint =
		Vector2.new(0.5, 0.5)

	Knob.BackgroundColor3 =
		Color3.fromRGB(255, 255, 255)

	Knob.BorderSizePixel = 0
	Knob.Parent = Bar

	local KnobCorner = Instance.new("UICorner")
	KnobCorner.CornerRadius = UDim.new(1, 0)
	KnobCorner.Parent = Knob

	local Value = Default
	local DraggingSlider = false

	local function SetValue(Number)

		Value = math.clamp(
			math.round(Number),
			Minimum,
			Maximum
		)

		local Percent =
			(Value - Minimum) /
			(Maximum - Minimum)

		Fill.Size =
			UDim2.new(
				Percent,
				0,
				1,
				0
			)

		Knob.Position =
			UDim2.new(
				Percent,
				0,
				0.5,
				0
			)

		Label.Text =
			TitleText .. ": " .. Value
	end

	local function SetFromInput(Input)

		local X = Input.Position.X

		local Start =
			Bar.AbsolutePosition.X

		local Width =
			Bar.AbsoluteSize.X

		local Percent =
			math.clamp(
				(X - Start) / Width,
				0,
				1
			)

		SetValue(
			Minimum +
			((Maximum - Minimum) * Percent)
		)
	end

	Bar.InputBegan:Connect(function(Input)

		if Input.UserInputType ==
			Enum.UserInputType.MouseButton1

			or Input.UserInputType ==
			Enum.UserInputType.Touch then

			DraggingSlider = true
			SetFromInput(Input)
		end
	end)

	UserInputService.InputChanged:Connect(function(Input)

		if not DraggingSlider then
			return
		end

		if Input.UserInputType ==
			Enum.UserInputType.MouseMovement

			or Input.UserInputType ==
			Enum.UserInputType.Touch then

			SetFromInput(Input)
		end
	end)

	UserInputService.InputEnded:Connect(function(Input)

		if Input.UserInputType ==
			Enum.UserInputType.MouseButton1

			or Input.UserInputType ==
			Enum.UserInputType.Touch then

			DraggingSlider = false
		end
	end)

	SetValue(Default)

	return function()
		return Value
	end
end

--========================================================
-- SLIDERS
--========================================================

local GetFOV = CreateSlider(
	"FOV",
	272,
	50,
	500,
	FOV
)

local GetSmoothness = CreateSlider(
	"Smoothness",
	322,
	10,
	100,
	Smoothness
)

--========================================================
-- FOV CIRCLE
--========================================================

local Circle = Instance.new("Frame")

Circle.Name = "FOVCircle"

Circle.AnchorPoint =
	Vector2.new(0.5, 0.5)

Circle.Position =
	UDim2.fromScale(0.5, 0.5)

Circle.Size =
	UDim2.fromOffset(
		FOV * 2,
		FOV * 2
	)

Circle.BackgroundTransparency = 1
Circle.BorderSizePixel = 0

Circle.Parent = GUI

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = Circle

local CircleStroke = Instance.new("UIStroke")

CircleStroke.Thickness = 2
CircleStroke.Transparency = 0.15

CircleStroke.Color =
	Color3.fromRGB(255, 255, 255)

CircleStroke.Parent = Circle

--========================================================
-- HIT PART
--========================================================

local function GetHitPart(Character)

	local Selected =
		HitParts[HitPartIndex]

	if Selected == "Head" then

		return Character:FindFirstChild("Head")

	elseif Selected == "Torso" then

		-- R6
		local R6Torso =
			Character:FindFirstChild("Torso")

		if R6Torso then
			return R6Torso
		end

		-- R15
		return Character:FindFirstChild("UpperTorso")
			or Character:FindFirstChild("LowerTorso")

	elseif Selected == "HumanoidRootPart" then

		return Character:FindFirstChild(
			"HumanoidRootPart"
		)
	end

	return Character:FindFirstChild("Head")
end

--========================================================
-- TARGET VALIDATION
--========================================================

local function IsValidTarget(Player)

	if not Player then
		return false
	end

	if Player == LocalPlayer then
		return false
	end

	local Character = Player.Character

	if not Character then
		return false
	end

	local Humanoid =
		Character:FindFirstChildOfClass(
			"Humanoid"
		)

	if not Humanoid then
		return false
	end

	if Humanoid.Health <= 0 then
		return false
	end

	-- TEAM CHECK
	if TeamCheck then

		if LocalPlayer.Team ~= nil
			and Player.Team ~= nil
			and LocalPlayer.Team == Player.Team then

			return false
		end
	end

	local Part =
		GetHitPart(Character)

	if not Part then
		return false
	end

	-- WALL CHECK
	if WallCheck then

		local Origin =
			Camera.CFrame.Position

		local Direction =
			Part.Position - Origin

		local Params =
			RaycastParams.new()

		Params.FilterType =
			Enum.RaycastFilterType.Exclude

		Params.FilterDescendantsInstances = {
			LocalPlayer.Character
		}

		local Result =
			workspace:Raycast(
				Origin,
				Direction,
				Params
			)

		if Result then

			if not Result.Instance:IsDescendantOf(
				Character
			) then

				return false
			end
		end
	end

	return true
end

--========================================================
-- FIND BEST TARGET
--========================================================

local function GetTarget()

	local BestTarget = nil

	local BestDistance =
		GetFOV()

	local Center =
		Vector2.new(
			Camera.ViewportSize.X / 2,
			Camera.ViewportSize.Y / 2
		)

	for _, Player in
		ipairs(Players:GetPlayers()) do

		if IsValidTarget(Player) then

			local Character =
				Player.Character

			local Part =
				GetHitPart(Character)

			if Part then

				local Position, Visible =
					Camera:WorldToViewportPoint(
						Part.Position
					)

				if Visible and Position.Z > 0 then

					local ScreenPosition =
						Vector2.new(
							Position.X,
							Position.Y
						)

					local Distance =
						(
							ScreenPosition -
							Center
						).Magnitude

					if Distance <= BestDistance then

						BestDistance =
							Distance

						BestTarget =
							Player
					end
				end
			end
		end
	end

	return BestTarget
end

--========================================================
-- BUTTONS
--========================================================

AimButton.Activated:Connect(function()

	AimEnabled =
		not AimEnabled

	if AimEnabled then

		AimButton.Text =
			"Aim Assist: ON"

		AimButton.BackgroundColor3 =
			Color3.fromRGB(
				40,
				140,
				75
			)

	else

		AimButton.Text =
			"Aim Assist: OFF"

		AimButton.BackgroundColor3 =
			Color3.fromRGB(
				48,
				48,
				53
			)

		Target = nil
	end
end)

LockButton.Activated:Connect(function()

	TargetLock =
		not TargetLock

	if TargetLock then

		LockButton.Text =
			"Target Lock: ON"

		LockButton.BackgroundColor3 =
			Color3.fromRGB(
				40,
				140,
				75
			)

		Target =
			GetTarget()

	else

		LockButton.Text =
			"Target Lock: OFF"

		LockButton.BackgroundColor3 =
			Color3.fromRGB(
				48,
				48,
				53
			)

		Target = nil
	end
end)

WallButton.Activated:Connect(function()

	WallCheck =
		not WallCheck

	WallButton.Text =
		WallCheck
		and "Wall Check: ON"
		or "Wall Check: OFF"

	WallButton.BackgroundColor3 =
		WallCheck
		and Color3.fromRGB(
			40,
			140,
			75
		)
		or Color3.fromRGB(
			48,
			48,
			53
		)

	Target = nil
end)

TeamButton.Activated:Connect(function()

	TeamCheck =
		not TeamCheck

	TeamButton.Text =
		TeamCheck
		and "Team Check: ON"
		or "Team Check: OFF"

	TeamButton.BackgroundColor3 =
		TeamCheck
		and Color3.fromRGB(
			40,
			140,
			75
		)
		or Color3.fromRGB(
			48,
			48,
			53
		)

	Target = nil
end)

HitButton.Activated:Connect(function()

	HitPartIndex += 1

	if HitPartIndex >
		#HitParts then

		HitPartIndex = 1
	end

	HitButton.Text =
		"Hit Part: " ..
		HitParts[HitPartIndex]

	Target = nil
end)

--========================================================
-- MAIN AIM LOOP
--========================================================

RunService:BindToRenderStep(
	"AimAssist",
	Enum.RenderPriority.Camera.Value + 1,
	function()

		-- FOV is ALWAYS visible
		local CurrentFOV =
			GetFOV()

		Circle.Size =
			UDim2.fromOffset(
				CurrentFOV * 2,
				CurrentFOV * 2
			)

		-- Find candidate
		local Candidate =
			GetTarget()

		-- FOV COLOR
		if Candidate then

			CircleStroke.Color =
				Color3.fromRGB(
					50,
					255,
					100
				)

		else

			CircleStroke.Color =
				Color3.fromRGB(
					255,
					255,
					255
				)
		end

		-- AIM DISABLED
		if not AimEnabled then
			return
		end

		-- TARGET LOCK
		if TargetLock then

			if not Target
				or not IsValidTarget(Target) then

				Target =
					GetTarget()
			end

		else

			Target =
				Candidate
		end

		if not Target then
			return
		end

		-- SELECTED HIT PART
		local Character =
			Target.Character

		local Part =
			Character
			and GetHitPart(Character)

		if not Part then

			Target = nil
			return
		end

		-- SMOOTHNESS
		-- 10 = slow/smooth
		-- 100 = fast

		local Alpha =
			math.clamp(
				GetSmoothness() / 100,
				0.01,
				1
			)

		local Desired =
			CFrame.lookAt(
				Camera.CFrame.Position,
				Part.Position
			)

		Camera.CFrame =
			Camera.CFrame:Lerp(
				Desired,
				Alpha
			)
	end
)

--========================================================
-- CLEAN TARGET WHEN PLAYER LEAVES
--========================================================

Players.PlayerRemoving:Connect(function(Player)

	if Target == Player then
		Target = nil
	end
end)