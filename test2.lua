--// AimAssist - Expanded test2.lua
--// For your own Roblox game / private testing

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--==================================================
-- SETTINGS
--==================================================

local AimEnabled = false
local TargetLock = true
local WallCheck = true
local TeamCheck = true

local FOV = 250
local Smoothness = 100
local Prediction = 0.08

local HitParts = {
	"Head",
	"Torso",
	"HumanoidRootPart"
}

local HitPartIndex = 1
local CurrentTarget = nil

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "AimAssist"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

--==================================================
-- FOV CIRCLE
--==================================================

local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.fromScale(0.5, 0.5)
fovCircle.Size = UDim2.fromOffset(FOV * 2, FOV * 2)
fovCircle.BackgroundTransparency = 1
fovCircle.Parent = gui

local circleCorner = Instance.new("UICorner")
circleCorner.CornerRadius = UDim.new(1, 0)
circleCorner.Parent = fovCircle

local circleStroke = Instance.new("UIStroke")
circleStroke.Thickness = 2
circleStroke.Color = Color3.new(1, 1, 1)
circleStroke.Transparency = 0
circleStroke.Parent = fovCircle

--==================================================
-- MAIN WINDOW
--==================================================

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(300, 430)
main.Position = UDim2.new(0, 20, 0.5, -215)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
main.BorderSizePixel = 0
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(65, 65, 70)
stroke.Thickness = 1
stroke.Parent = main

--==================================================
-- TITLE
--==================================================

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -55, 0, 45)
title.Position = UDim2.fromOffset(15, 5)
title.BackgroundTransparency = 1
title.Text = "AimAssist"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(35, 35)
closeButton.Position = UDim2.new(1, -43, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
closeButton.Text = "×"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextSize = 24
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = main

Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 8)

--==================================================
-- OPEN BUTTON
--==================================================

local openButton = Instance.new("TextButton")
openButton.Size = UDim2.fromOffset(50, 50)
openButton.Position = UDim2.fromOffset(20, 20)
openButton.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
openButton.Text = "☰"
openButton.TextColor3 = Color3.new(1, 1, 1)
openButton.TextSize = 22
openButton.Font = Enum.Font.GothamBold
openButton.Visible = false
openButton.Parent = gui

Instance.new("UICorner", openButton).CornerRadius = UDim.new(0, 10)

closeButton.Activated:Connect(function()
	main.Visible = false
	openButton.Visible = true
end)

openButton.Activated:Connect(function()
	main.Visible = true
	openButton.Visible = false
end)

--==================================================
-- UI HELPER
--==================================================

local y = 55

local function makeButton(text)
	local button = Instance.new("TextButton")

	button.Size = UDim2.new(1, -30, 0, 42)
	button.Position = UDim2.fromOffset(15, y)

	button.BackgroundColor3 = Color3.fromRGB(38, 38, 42)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.Text = text

	button.AutoButtonColor = true
	button.Parent = main

	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

	y += 48

	return button
end

local function makeLabel(text)
	local label = Instance.new("TextLabel")

	label.Size = UDim2.new(1, -30, 0, 25)
	label.Position = UDim2.fromOffset(15, y)

	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(220, 220, 220)
	label.Text = text
	label.TextSize = 13
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left

	label.Parent = main

	y += 28

	return label
end

--==================================================
-- AIM TOGGLE
--==================================================

local aimButton = makeButton("Aim Assist: OFF")

aimButton.Activated:Connect(function()
	AimEnabled = not AimEnabled

	if AimEnabled then
		aimButton.Text = "Aim Assist: ON"
		aimButton.BackgroundColor3 = Color3.fromRGB(40, 150, 75)
	else
		aimButton.Text = "Aim Assist: OFF"
		aimButton.BackgroundColor3 = Color3.fromRGB(38, 38, 42)
		CurrentTarget = nil
	end
end)

--==================================================
-- TARGET LOCK
--==================================================

local lockButton = makeButton("Target Lock: ON")

lockButton.Activated:Connect(function()
	TargetLock = not TargetLock

	if TargetLock then
		lockButton.Text = "Target Lock: ON"
		lockButton.BackgroundColor3 = Color3.fromRGB(40, 150, 75)
	else
		lockButton.Text = "Target Lock: OFF"
		lockButton.BackgroundColor3 = Color3.fromRGB(38, 38, 42)
		CurrentTarget = nil
	end
end)

--==================================================
-- WALL CHECK
--==================================================

local wallButton = makeButton("Wall Check: ON")

wallButton.Activated:Connect(function()
	WallCheck = not WallCheck

	if WallCheck then
		wallButton.Text = "Wall Check: ON"
		wallButton.BackgroundColor3 = Color3.fromRGB(40, 150, 75)
	else
		wallButton.Text = "Wall Check: OFF"
		wallButton.BackgroundColor3 = Color3.fromRGB(38, 38, 42)
	end
end)

--==================================================
-- TEAM CHECK
--==================================================

local teamButton = makeButton("Team Check: ON")

teamButton.Activated:Connect(function()
	TeamCheck = not TeamCheck

	if TeamCheck then
		teamButton.Text = "Team Check: ON"
		teamButton.BackgroundColor3 = Color3.fromRGB(40, 150, 75)
	else
		teamButton.Text = "Team Check: OFF"
		teamButton.BackgroundColor3 = Color3.fromRGB(38, 38, 42)
	end
end)

--==================================================
-- HIT PART
--==================================================

local hitButton = makeButton("Hit Part: Head")

local function getHitPart(character)
	local selected = HitParts[HitPartIndex]

	if selected == "Head" then
		return character:FindFirstChild("Head")
	end

	if selected == "Torso" then
		return character:FindFirstChild("UpperTorso")
			or character:FindFirstChild("Torso")
			or character:FindFirstChild("LowerTorso")
	end

	if selected == "HumanoidRootPart" then
		return character:FindFirstChild("HumanoidRootPart")
	end
end

hitButton.Activated:Connect(function()
	HitPartIndex += 1

	if HitPartIndex > #HitParts then
		HitPartIndex = 1
	end

	hitButton.Text = "Hit Part: " .. HitParts[HitPartIndex]
end)

--==================================================
-- FOV
--==================================================

local fovLabel = makeLabel("FOV: 250")

local fovBack = Instance.new("Frame")
fovBack.Size = UDim2.new(1, -30, 0, 8)
fovBack.Position = UDim2.fromOffset(15, y)
fovBack.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
fovBack.Parent = main

Instance.new("UICorner", fovBack).CornerRadius = UDim.new(1, 0)

local fovFill = Instance.new("Frame")
fovFill.Size = UDim2.new(FOV / 500, 0, 1, 0)
fovFill.BackgroundColor3 = Color3.fromRGB(70, 150, 255)
fovFill.Parent = fovBack

Instance.new("UICorner", fovFill).CornerRadius = UDim.new(1, 0)

y += 22

--==================================================
-- SMOOTHNESS
--==================================================

local smoothLabel = makeLabel("Smoothness: 100")

local smoothBack = Instance.new("Frame")
smoothBack.Size = UDim2.new(1, -30, 0, 8)
smoothBack.Position = UDim2.fromOffset(15, y)
smoothBack.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
smoothBack.Parent = main

Instance.new("UICorner", smoothBack).CornerRadius = UDim.new(1, 0)

local smoothFill = Instance.new("Frame")
smoothFill.Size = UDim2.new(Smoothness / 100, 0, 1, 0)
smoothFill.BackgroundColor3 = Color3.fromRGB(70, 150, 255)
smoothFill.Parent = smoothBack

Instance.new("UICorner", smoothFill).CornerRadius = UDim.new(1, 0)

y += 30

--==================================================
-- SLIDER FUNCTION
--==================================================

local function setupSlider(back, fill, label, minValue, maxValue, setter)
	local dragging = false

	local function update(input)
		local percent =
			math.clamp(
				(input.Position.X - back.AbsolutePosition.X)
				/ back.AbsoluteSize.X,
				0,
				1
			)

		local value =
			math.floor(
				minValue + (maxValue - minValue) * percent
			)

		fill.Size = UDim2.new(percent, 0, 1, 0)
		setter(value)
	end

	back.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragging = true
			update(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging then
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then

				update(input)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragging = false
		end
	end)
end

setupSlider(
	fovBack,
	fovFill,
	fovLabel,
	50,
	500,
	function(value)
		FOV = value
		fovLabel.Text = "FOV: " .. value
	end
)

setupSlider(
	smoothBack,
	smoothFill,
	smoothLabel,
	10,
	100,
	function(value)
		Smoothness = value
		smoothLabel.Text = "Smoothness: " .. value
	end
)

--==================================================
-- TARGET VALIDATION
--==================================================

local function validTarget(plr)
	if not plr or plr == player then
		return false
	end

	if TeamCheck and player.Team ~= nil and plr.Team == player.Team then
		return false
	end

	local character = plr.Character

	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	local part = getHitPart(character)

	if not part then
		return false
	end

	return true
end

--==================================================
-- WALL CHECK
--==================================================

local function visibleTarget(part, character)
	if not WallCheck then
		return true
	end

	local origin = camera.CFrame.Position
	local direction = part.Position - origin

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {
		player.Character,
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
-- TARGET SEARCH
--==================================================

local function getTarget()
	local bestTarget = nil
	local bestDistance = FOV

	local viewport = camera.ViewportSize

	local center = Vector2.new(
		viewport.X / 2,
		viewport.Y / 2
	)

	for _, plr in ipairs(Players:GetPlayers()) do

		if validTarget(plr) then

			local character = plr.Character
			local part = getHitPart(character)

			if part then

				local screenPosition, visible =
					camera:WorldToViewportPoint(part.Position)

				if visible and screenPosition.Z > 0 then

					local screenPos = Vector2.new(
						screenPosition.X,
						screenPosition.Y
					)

					local distance =
						(screenPos - center).Magnitude

					if distance <= bestDistance then

						if visibleTarget(part, character) then
							bestDistance = distance
							bestTarget = plr
						end

					end
				end
			end
		end
	end

	return bestTarget
end

--==================================================
-- PREDICTION
--==================================================

local function getAimPosition(part)
	local velocity = Vector3.zero

	if part:IsA("BasePart") then
		velocity = part.AssemblyLinearVelocity
	end

	return part.Position + (velocity * Prediction)
end

--==================================================
-- AIM STRENGTH
--==================================================

local function getAimAlpha()
	-- 10 = slower
	-- 100 = extremely strong

	local strength = Smoothness / 100

	return math.clamp(
		0.08 + (strength * 0.92),
		0.08,
		1
	)
end

--==================================================
-- MAIN AIM LOOP
--==================================================

RunService:BindToRenderStep(
	"AimAssist",
	Enum.RenderPriority.Camera.Value + 1,
	function()

		-- Keep FOV circle visible even when UI is closed
		fovCircle.Size = UDim2.fromOffset(
			FOV * 2,
			FOV * 2
		)

		if not AimEnabled then
			circleStroke.Color = Color3.new(1, 1, 1)
			CurrentTarget = nil
			return
		end

		-- Target lock keeps the current target
		if TargetLock then

			if not CurrentTarget
				or not validTarget(CurrentTarget) then

				CurrentTarget = getTarget()
			end

		else
			CurrentTarget = getTarget()
		end

		-- Change circle color when target is inside FOV
		if CurrentTarget and validTarget(CurrentTarget) then
			circleStroke.Color = Color3.fromRGB(
				50,
				255,
				100
			)
		else
			circleStroke.Color = Color3.new(
				1,
				1,
				1
			)

			CurrentTarget = nil
			return
		end

		local character = CurrentTarget.Character

		local part = getHitPart(character)

		if not part then
			CurrentTarget = nil
			return
		end

		if WallCheck and not visibleTarget(part, character) then
			CurrentTarget = nil
			return
		end

		-- Strong prediction / tracking
		local aimPosition = getAimPosition(part)

		local desiredCFrame = CFrame.lookAt(
			camera.CFrame.Position,
			aimPosition
		)

		-- Strong camera tracking
		camera.CFrame =
			camera.CFrame:Lerp(
				desiredCFrame,
				getAimAlpha()
			)
	end
)

--==================================================
-- MOBILE / PC OPEN BUTTON
--==================================================

openButton.Activated:Connect(function()
	main.Visible = true
	openButton.Visible = false
end)

--==================================================
-- DRAGGABLE MAIN UI
--==================================================

local dragging = false
local dragStart
local startPosition

title.InputBegan:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		startPosition = main.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)

	if not dragging then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then

		local delta = input.Position - dragStart

		main.Position =
			UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
	end
end)

UserInputService.InputEnded:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		dragging = false
	end
end)

--==================================================
-- START
--==================================================

main.Visible = true
openButton.Visible = false

print("AimAssist loaded successfully")