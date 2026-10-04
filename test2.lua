--========================================================
-- STRONG AIM ASSIST - OWN ROBLOX EXPERIENCE
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
local Smoothness = 100

-- Strong tracking
local AimStrength = 100

-- Small amount of movement prediction
local Prediction = 0.08

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
GUI.Name = "StrongAimAssist"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")

--========================================================
-- MAIN UI
--========================================================

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(285, 390)
Main.Position = UDim2.new(0, 20, 0.5, -195)
Main.BackgroundColor3 = Color3.fromRGB(24,24,28)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = GUI

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0,14)
Corner.Parent = Main

--========================================================
-- OPEN BUTTON
--========================================================

local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.fromOffset(50,50)
OpenButton.Position = UDim2.fromOffset(15,15)
OpenButton.BackgroundColor3 = Color3.fromRGB(25,25,30)
OpenButton.Text = "☰"
OpenButton.TextColor3 = Color3.new(1,1,1)
OpenButton.TextSize = 25
OpenButton.Font = Enum.Font.GothamBold
OpenButton.Visible = false
OpenButton.Parent = GUI

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(1,0)
OpenCorner.Parent = OpenButton

--========================================================
-- CLOSE BUTTON
--========================================================

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.fromOffset(32,32)
CloseButton.Position = UDim2.new(1,-40,0,8)
CloseButton.BackgroundColor3 = Color3.fromRGB(55,55,60)
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.new(1,1,1)
CloseButton.TextSize = 22
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = Main

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(1,0)
CloseCorner.Parent = CloseButton

CloseButton.Activated:Connect(function()
	Main.Visible = false
	OpenButton.Visible = true
end)

OpenButton.Activated:Connect(function()
	Main.Visible = true
	OpenButton.Visible = false
end)

--========================================================
-- TITLE
--========================================================

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,-55,0,42)
Title.Position = UDim2.fromOffset(10,4)
Title.BackgroundTransparency = 1
Title.Text = "AIM ASSIST"
Title.TextColor3 = Color3.new(1,1,1)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

--========================================================
-- BUTTON FUNCTION
--========================================================

local function Button(text,y)

	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,-24,0,38)
	b.Position = UDim2.fromOffset(12,y)
	b.BackgroundColor3 = Color3.fromRGB(48,48,53)
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.new(1,1,1)
	b.TextSize = 14
	b.Font = Enum.Font.GothamMedium
	b.Parent = Main

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0,8)
	c.Parent = b

	return b
end

local AimButton = Button("Aim Assist: OFF",48)
local LockButton = Button("Target Lock: OFF",92)
local WallButton = Button("Wall Check: ON",136)
local TeamButton = Button("Team Check: ON",180)
local HitButton = Button("Hit Part: Head",224)

--========================================================
-- SLIDER
--========================================================

local function Slider(name,y,min,max,default)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1,-24,0,20)
	label.Position = UDim2.fromOffset(12,y)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(230,230,230)
	label.TextSize = 13
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = Main

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1,-24,0,8)
	bar.Position = UDim2.fromOffset(12,y+25)
	bar.BackgroundColor3 = Color3.fromRGB(65,65,70)
	bar.BorderSizePixel = 0
	bar.Active = true
	bar.Parent = Main

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(1,0)
	bc.Parent = bar

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = Color3.fromRGB(70,150,255)
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(1,0)
	fc.Parent = fill

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(14,14)
	knob.AnchorPoint = Vector2.new(.5,.5)
	knob.BackgroundColor3 = Color3.new(1,1,1)
	knob.BorderSizePixel = 0
	knob.Parent = bar

	local kc = Instance.new("UICorner")
	kc.CornerRadius = UDim.new(1,0)
	kc.Parent = knob

	local value = default
	local dragging = false

	local function Set(v)

		value = math.clamp(math.round(v),min,max)

		local p = (value-min)/(max-min)

		fill.Size = UDim2.new(p,0,1,0)
		knob.Position = UDim2.new(p,0,.5,0)

		label.Text = name .. ": " .. value
	end

	local function InputToValue(input)

		local x = input.Position.X
		local start = bar.AbsolutePosition.X
		local width = bar.AbsoluteSize.X

		local p = math.clamp((x-start)/width,0,1)

		Set(min+(max-min)*p)
	end

	bar.InputBegan:Connect(function(input)

		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

			dragging = true
			InputToValue(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)

		if not dragging then return end

		if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then

			InputToValue(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)

		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

			dragging = false
		end
	end)

	Set(default)

	return function()
		return value
	end
end

local GetFOV = Slider("FOV",272,50,500,FOV)
local GetSmoothness = Slider("Smoothness",322,10,100,Smoothness)

--========================================================
-- PERMANENT FOV CIRCLE
--========================================================

local Circle = Instance.new("Frame")
Circle.AnchorPoint = Vector2.new(.5,.5)
Circle.Position = UDim2.fromScale(.5,.5)
Circle.Size = UDim2.fromOffset(FOV*2,FOV*2)
Circle.BackgroundTransparency = 1
Circle.BorderSizePixel = 0
Circle.Parent = GUI

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1,0)
CircleCorner.Parent = Circle

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Thickness = 2
CircleStroke.Transparency = .1
CircleStroke.Color = Color3.new(1,1,1)
CircleStroke.Parent = Circle

--========================================================
-- HIT PART
--========================================================

local function GetHitPart(character)

	local selected = HitParts[HitPartIndex]

	if selected == "Head" then
		return character:FindFirstChild("Head")

	elseif selected == "Torso" then

		return character:FindFirstChild("Torso")
			or character:FindFirstChild("UpperTorso")
			or character:FindFirstChild("LowerTorso")

	elseif selected == "HumanoidRootPart" then
		return character:FindFirstChild("HumanoidRootPart")
	end
end

--========================================================
-- VALID TARGET
--========================================================

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

	if TeamCheck
		and LocalPlayer.Team
		and player.Team
		and LocalPlayer.Team == player.Team then

		return false
	end

	local part = GetHitPart(character)

	if not part then
		return false
	end

	-- Wall check
	if WallCheck then

		local origin = Camera.CFrame.Position
		local direction = part.Position - origin

		local params = RaycastParams.new()

		params.FilterType =
			Enum.RaycastFilterType.Exclude

		params.FilterDescendantsInstances = {
			LocalPlayer.Character
		}

		local result =
			workspace:Raycast(
				origin,
				direction,
				params
			)

		if result
			and not result.Instance:IsDescendantOf(character) then

			return false
		end
	end

	return true
end

--========================================================
-- TARGET SEARCH
--========================================================

local function GetTarget()

	local best = nil
	local bestDistance = GetFOV()

	local center = Vector2.new(
		Camera.ViewportSize.X/2,
		Camera.ViewportSize.Y/2
	)

	for _,player in ipairs(Players:GetPlayers()) do

		if IsValidTarget(player) then

			local part =
				GetHitPart(player.Character)

			if part then

				local position,visible =
					Camera:WorldToViewportPoint(
						part.Position
					)

				if visible and position.Z > 0 then

					local screen =
						Vector2.new(
							position.X,
							position.Y
						)

					local distance =
						(screen-center).Magnitude

					if distance <= bestDistance then

						bestDistance = distance
						best = player
					end
				end
			end
		end
	end

	return best
end

--========================================================
-- BUTTONS
--========================================================

AimButton.Activated:Connect(function()

	AimEnabled = not AimEnabled

	if AimEnabled then

		AimButton.Text = "Aim Assist: ON"
		AimButton.BackgroundColor3 =
			Color3.fromRGB(40,140,75)

	else

		AimButton.Text = "Aim Assist: OFF"
		AimButton.BackgroundColor3 =
			Color3.fromRGB(48,48,53)

		Target = nil
	end
end)

LockButton.Activated:Connect(function()

	TargetLock = not TargetLock

	if TargetLock then

		LockButton.Text = "Target Lock: ON"
		LockButton.BackgroundColor3 =
			Color3.fromRGB(40,140,75)

		Target = GetTarget()

	else

		LockButton.Text = "Target Lock: OFF"
		LockButton.BackgroundColor3 =
			Color3.fromRGB(48,48,53)

		Target = nil
	end
end)

WallButton.Activated:Connect(function()

	WallCheck = not WallCheck

	WallButton.Text =
		WallCheck and
		"Wall Check: ON" or
		"Wall Check: OFF"

	WallButton.BackgroundColor3 =
		WallCheck and
		Color3.fromRGB(40,140,75) or
		Color3.fromRGB(48,48,53)

	Target = nil
end)

TeamButton.Activated:Connect(function()

	TeamCheck = not TeamCheck

	TeamButton.Text =
		TeamCheck and
		"Team Check: ON" or
		"Team Check: OFF"

	TeamButton.BackgroundColor3 =
		TeamCheck and
		Color3.fromRGB(40,140,75) or
		Color3.fromRGB(48,48,53)

	Target = nil
end)

HitButton.Activated:Connect(function()

	HitPartIndex += 1

	if HitPartIndex > #HitParts then
		HitPartIndex = 1
	end

	HitButton.Text =
		"Hit Part: " ..
		HitParts[HitPartIndex]

	Target = nil
end)

--========================================================
-- STRONG AIM LOOP
--========================================================

RunService:BindToRenderStep(
	"StrongAimAssist",
	Enum.RenderPriority.Camera.Value + 1,
	function()

		-- FOV NEVER DISAPPEARS
		local currentFOV = GetFOV()

		Circle.Size =
			UDim2.fromOffset(
				currentFOV*2,
				currentFOV*2
			)

		-- Find a candidate every frame
		local candidate = GetTarget()

		if candidate then

			CircleStroke.Color =
				Color3.fromRGB(
					50,255,100
				)

		else

			CircleStroke.Color =
				Color3.fromRGB(
					255,255,255
				)
		end

		if not AimEnabled then
			return
		end

		-- Sticky target lock
		if TargetLock then

			if not Target
				or not IsValidTarget(Target) then

				Target = candidate
			end

		else

			Target = candidate
		end

		if not Target then
			return
		end

		local character = Target.Character
		local part = character and GetHitPart(character)

		if not part then
			Target = nil
			return
		end

		--================================================
		-- TARGET PREDICTION
		--================================================

		local velocity =
			part.AssemblyLinearVelocity

		local predictedPosition =
			part.Position +
			(velocity * Prediction)

		--================================================
		-- VERY STRONG TRACKING
		--================================================

		local strength =
			math.clamp(
				AimStrength / 100,
				0.01,
				1
			)

		local smooth =
			math.clamp(
				GetSmoothness() / 100,
				0.01,
				1
			)

		local alpha =
			math.clamp(
				smooth * strength,
				0.01,
				1
			)

		local desired =
			CFrame.lookAt(
				Camera.CFrame.Position,
				predictedPosition
			)

		Camera.CFrame =
			Camera.CFrame:Lerp(
				desired,
				alpha
			)
	end
)

--========================================================
-- CLEANUP
--========================================================

Players.PlayerRemoving:Connect(function(player)

	if Target == player then
		Target = nil
	end
end)