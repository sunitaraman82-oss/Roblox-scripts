--// AimAssist + ESP
--// For your own Roblox experience / Studio testing

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- SETTINGS
--==================================================

local Settings = {
	Enabled = false,

	-- More natural aim
	HoldToAim = true,
	AimKey = Enum.UserInputType.MouseButton2,

	TargetLock = true,
	WallCheck = true,
	TeamCheck = true,

	FOV = 180,
	Smoothness = 92,
	Prediction = 0.03,

	HitPart = "Head",

	-- ESP
	ESPEnabled = false,
	ESPTeamColor = true
}

local Target = nil
local AimHeld = false
local ESPObjects = {}

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "AimAssistUI"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- FOV CIRCLE
--==================================================

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOV"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.fromScale(0.5, 0.5)
FOVCircle.Size = UDim2.fromOffset(
	Settings.FOV * 2,
	Settings.FOV * 2
)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Parent = Gui

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = FOVCircle

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Thickness = 2
CircleStroke.Color = Color3.fromRGB(255, 255, 255)
CircleStroke.Parent = FOVCircle

--==================================================
-- MAIN PANEL
--==================================================

local Panel = Instance.new("Frame")
Panel.Name = "Panel"
Panel.Size = UDim2.fromOffset(285, 430)
Panel.Position = UDim2.new(0, 25, 0.5, -215)
Panel.BackgroundColor3 = Color3.fromRGB(22, 20, 27)
Panel.BackgroundTransparency = 0.08
Panel.BorderSizePixel = 0
Panel.Parent = Gui

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 14)
PanelCorner.Parent = Panel

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Color = Color3.fromRGB(80, 75, 90)
PanelStroke.Transparency = 0.25
PanelStroke.Parent = Panel

--==================================================
-- TITLE
--==================================================

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -55, 0, 45)
Title.Position = UDim2.fromOffset(15, 5)
Title.BackgroundTransparency = 1
Title.Text = "AimAssist + ESP"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Panel

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(34, 34)
Close.Position = UDim2.new(1, -44, 0, 10)
Close.BackgroundColor3 = Color3.fromRGB(45, 42, 52)
Close.Text = "×"
Close.TextColor3 = Color3.new(1, 1, 1)
Close.TextSize = 22
Close.Font = Enum.Font.GothamBold
Close.Parent = Panel

Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 8)

--==================================================
-- OPEN BUTTON
--==================================================

local Open = Instance.new("TextButton")
Open.Size = UDim2.fromOffset(48, 48)
Open.Position = UDim2.fromOffset(20, 20)
Open.BackgroundColor3 = Color3.fromRGB(25, 23, 30)
Open.Text = "☰"
Open.TextColor3 = Color3.new(1, 1, 1)
Open.TextSize = 21
Open.Font = Enum.Font.GothamBold
Open.Visible = false
Open.Parent = Gui

Instance.new("UICorner", Open).CornerRadius = UDim.new(0, 12)

Close.Activated:Connect(function()
	Panel.Visible = false
	Open.Visible = true
end)

Open.Activated:Connect(function()
	Panel.Visible = true
	Open.Visible = false
end)

--==================================================
-- UI HELPERS
--==================================================

local Y = 58

local function Button(text)
	local b = Instance.new("TextButton")

	b.Size = UDim2.new(1, -30, 0, 38)
	b.Position = UDim2.fromOffset(15, Y)
	b.BackgroundColor3 = Color3.fromRGB(40, 37, 47)
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextSize = 13
	b.Font = Enum.Font.GothamSemibold
	b.Parent = Panel

	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)

	Y += 44

	return b
end

local function Label(text)
	local l = Instance.new("TextLabel")

	l.Size = UDim2.new(1, -30, 0, 22)
	l.Position = UDim2.fromOffset(15, Y)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = Color3.fromRGB(205, 202, 215)
	l.TextSize = 12
	l.Font = Enum.Font.Gotham
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = Panel

	Y += 25

	return l
end

--==================================================
-- AIM TOGGLE
--==================================================

local AimButton = Button("Aim Assist : OFF")

local function UpdateAimButton()
	if Settings.Enabled then
		AimButton.Text = "Aim Assist : ON"
		AimButton.BackgroundColor3 =
			Color3.fromRGB(45, 135, 75)
	else
		AimButton.Text = "Aim Assist : OFF"
		AimButton.BackgroundColor3 =
			Color3.fromRGB(40, 37, 47)
	end
end

AimButton.Activated:Connect(function()
	Settings.Enabled = not Settings.Enabled

	if not Settings.Enabled then
		Target = nil
	end

	UpdateAimButton()
end)

--==================================================
-- TARGET LOCK
--==================================================

local LockButton = Button("Target Lock : ON")

LockButton.Activated:Connect(function()
	Settings.TargetLock = not Settings.TargetLock

	LockButton.Text =
		"Target Lock : " ..
		(Settings.TargetLock and "ON" or "OFF")
end)

--==================================================
-- WALL CHECK
--==================================================

local WallButton = Button("Wall Check : ON")

WallButton.Activated:Connect(function()
	Settings.WallCheck = not Settings.WallCheck

	WallButton.Text =
		"Wall Check : " ..
		(Settings.WallCheck and "ON" or "OFF")
end)

--==================================================
-- TEAM CHECK
--==================================================

local TeamButton = Button("Team Check : ON")

TeamButton.Activated:Connect(function()
	Settings.TeamCheck = not Settings.TeamCheck

	TeamButton.Text =
		"Team Check : " ..
		(Settings.TeamCheck and "ON" or "OFF")
end)

--==================================================
-- ESP
--==================================================

local ESPButton = Button("ESP : OFF")

local function RemoveESP(plr)
	local data = ESPObjects[plr]

	if data then
		if data.Highlight then
			data.Highlight:Destroy()
		end

		ESPObjects[plr] = nil
	end
end

local function CreateESP(plr)
	if plr == LocalPlayer then
		return
	end

	local character = plr.Character

	if not character then
		return
	end

	local old = ESPObjects[plr]

	if old
		and old.Highlight
		and old.Highlight.Parent == character then
		return
	end

	RemoveESP(plr)

	local highlight = Instance.new("Highlight")

	highlight.Name = "AimAssistESP"
	highlight.Adornee = character

	-- Does NOT show through walls
	highlight.DepthMode =
		Enum.HighlightDepthMode.Occluded

	highlight.FillTransparency = 0.88
	highlight.OutlineTransparency = 0.15

	local color = Color3.fromRGB(255, 80, 80)

	if Settings.ESPTeamColor and plr.Team then
		color = plr.Team.TeamColor.Color
	end

	highlight.FillColor = color
	highlight.OutlineColor = color

	highlight.Parent = character

	ESPObjects[plr] = {
		Highlight = highlight
	}
end

local function UpdateESP()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			if Settings.ESPEnabled then
				CreateESP(plr)
			else
				RemoveESP(plr)
			end
		end
	end
end

local function UpdateESPButton()
	if Settings.ESPEnabled then
		ESPButton.Text = "ESP : ON"
		ESPButton.BackgroundColor3 =
			Color3.fromRGB(45, 135, 75)
	else
		ESPButton.Text = "ESP : OFF"
		ESPButton.BackgroundColor3 =
			Color3.fromRGB(40, 37, 47)
	end
end

ESPButton.Activated:Connect(function()
	Settings.ESPEnabled = not Settings.ESPEnabled

	UpdateESP()
	UpdateESPButton()
end)

Players.PlayerRemoving:Connect(function(plr)
	RemoveESP(plr)
end)

--==================================================
-- HIT PART
--==================================================

local HitButton = Button("Hit Part : Head")

local HitParts = {
	"Head",
	"Torso",
	"HumanoidRootPart"
}

local HitIndex = 1

HitButton.Activated:Connect(function()
	HitIndex += 1

	if HitIndex > #HitParts then
		HitIndex = 1
	end

	Settings.HitPart = HitParts[HitIndex]

	HitButton.Text =
		"Hit Part : " .. Settings.HitPart
end)

--==================================================
-- FOV
--==================================================

local FOVLabel = Label("FOV : 180")

local FOVBar = Instance.new("Frame")
FOVBar.Size = UDim2.new(1, -30, 0, 8)
FOVBar.Position = UDim2.fromOffset(15, Y)
FOVBar.BackgroundColor3 = Color3.fromRGB(55, 52, 63)
FOVBar.BorderSizePixel = 0
FOVBar.Parent = Panel

Instance.new("UICorner", FOVBar).CornerRadius = UDim.new(1, 0)

local FOVFill = Instance.new("Frame")
FOVFill.Size = UDim2.new(
	Settings.FOV / 500,
	0,
	1,
	0
)
FOVFill.BackgroundColor3 =
	Color3.fromRGB(100, 150, 255)
FOVFill.BorderSizePixel = 0
FOVFill.Parent = FOVBar

Instance.new("UICorner", FOVFill).CornerRadius = UDim.new(1, 0)

Y += 25

--==================================================
-- SMOOTHNESS
--==================================================

local SmoothLabel = Label("Smoothness : 92")

local SmoothBar = Instance.new("Frame")
SmoothBar.Size = UDim2.new(1, -30, 0, 8)
SmoothBar.Position = UDim2.fromOffset(15, Y)
SmoothBar.BackgroundColor3 =
	Color3.fromRGB(55, 52, 63)
SmoothBar.BorderSizePixel = 0
SmoothBar.Parent = Panel

Instance.new("UICorner", SmoothBar).CornerRadius = UDim.new(1, 0)

local SmoothFill = Instance.new("Frame")
SmoothFill.Size = UDim2.new(
	Settings.Smoothness / 100,
	0,
	1,
	0
)
SmoothFill.BackgroundColor3 =
	Color3.fromRGB(100, 150, 255)
SmoothFill.BorderSizePixel = 0
SmoothFill.Parent = SmoothBar

Instance.new("UICorner", SmoothFill).CornerRadius = UDim.new(1, 0)

--==================================================
-- SLIDER SYSTEM
--==================================================

local function Slider(bar, fill, min, max, callback)
	local dragging = false

	local function update(x)
		local percent = math.clamp(
			(x - bar.AbsolutePosition.X)
			/ bar.AbsoluteSize.X,
			0,
			1
		)

		local value = math.floor(
			min + ((max - min) * percent)
		)

		fill.Size = UDim2.new(
			percent,
			0,
			1,
			0
		)

		callback(value)
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			dragging = true
			update(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging then
			if input.UserInputType ==
				Enum.UserInputType.MouseMovement
				or input.UserInputType ==
				Enum.UserInputType.Touch then

				update(input.Position.X)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			dragging = false
		end
	end)
end

Slider(
	FOVBar,
	FOVFill,
	50,
	500,
	function(value)
		Settings.FOV = value
		FOVLabel.Text = "FOV : " .. value
	end
)

Slider(
	SmoothBar,
	SmoothFill,
	10,
	100,
	function(value)
		Settings.Smoothness = value
		SmoothLabel.Text =
			"Smoothness : " .. value
	end
)

--==================================================
-- TARGET PART
--==================================================

local function GetPart(character)
	if Settings.HitPart == "Head" then
		return character:FindFirstChild("Head")
	end

	if Settings.HitPart == "Torso" then
		return character:FindFirstChild("UpperTorso")
			or character:FindFirstChild("Torso")
			or character:FindFirstChild("LowerTorso")
	end

	return character:FindFirstChild("HumanoidRootPart")
end

--==================================================
-- VALID TARGET
--==================================================

local function ValidPlayer(plr)
	if plr == LocalPlayer then
		return false
	end

	if Settings.TeamCheck
		and LocalPlayer.Team ~= nil
		and plr.Team == LocalPlayer.Team then

		return false
	end

	local character = plr.Character

	if not character then
		return false
	end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	if not humanoid
		or humanoid.Health <= 0 then

		return false
	end

	return GetPart(character) ~= nil
end

--==================================================
-- VISIBILITY
--==================================================

local function Visible(part, character)
	if not Settings.WallCheck then
		return true
	end

	local origin = Camera.CFrame.Position
	local direction = part.Position - origin

	local params = RaycastParams.new()

	params.FilterType =
		Enum.RaycastFilterType.Exclude

	params.FilterDescendantsInstances = {
		LocalPlayer.Character,
		Camera
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
-- FIND TARGET
--==================================================

local function FindTarget()
	local best = nil
	local bestDistance = Settings.FOV

	local center = Vector2.new(
		Camera.ViewportSize.X / 2,
		Camera.ViewportSize.Y / 2
	)

	for _, plr in ipairs(Players:GetPlayers()) do
		if ValidPlayer(plr) then

			local character = plr.Character
			local part = GetPart(character)

			if part then

				local point, onscreen =
					Camera:WorldToViewportPoint(
						part.Position
					)

				if onscreen and point.Z > 0 then

					local distance =
						(
							Vector2.new(
								point.X,
								point.Y
							) - center
						).Magnitude

					if distance <= bestDistance
						and Visible(
							part,
							character
						) then

						bestDistance = distance
						best = plr
					end
				end
			end
		end
	end

	return best
end

--==================================================
-- SMOOTH AIM
--==================================================

local function AimAt(part)
	if not part then
		return
	end

	local velocity =
		part.AssemblyLinearVelocity

	local predicted =
		part.Position +
		(velocity * Settings.Prediction)

	local desired =
		CFrame.lookAt(
			Camera.CFrame.Position,
			predicted
		)

	-- Lower alpha = smoother movement
	local alpha =
		(100 - Settings.Smoothness) / 100

	alpha = math.clamp(
		alpha,
		0.015,
		0.12
	)

	Camera.CFrame =
		Camera.CFrame:Lerp(
			desired,
			alpha
		)
end

--==================================================
-- AIM INPUT
--==================================================

UserInputService.InputBegan:Connect(function(
	input,
	processed
)
	if processed then
		return
	end

	if input.UserInputType ==
		Enum.UserInputType.MouseButton2 then

		AimHeld = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType ==
		Enum.UserInputType.MouseButton2 then

		AimHeld = false
		Target = nil
	end
end)

--==================================================
-- MAIN LOOP
--==================================================

RunService:BindToRenderStep(
	"AimAssistUpdate",
	Enum.RenderPriority.Camera.Value + 1,
	function()

		-- FOV always visible
		FOVCircle.Size =
			UDim2.fromOffset(
				Settings.FOV * 2,
				Settings.FOV * 2
			)

		-- Keep ESP updated
		if Settings.ESPEnabled then
			for _, plr in ipairs(
				Players:GetPlayers()
			) do
				if plr ~= LocalPlayer then
					CreateESP(plr)
				end
			end
		end

		if not Settings.Enabled then
			Target = nil

			CircleStroke.Color =
				Color3.fromRGB(
					255,
					255,
					255
				)

			return
		end

		-- Hold RMB to aim
		if Settings.HoldToAim
			and not AimHeld then

			Target = nil

			CircleStroke.Color =
				Color3.fromRGB(
					255,
					255,
					255
				)

			return
		end

		if not Settings.TargetLock
			or not Target
			or not ValidPlayer(Target) then

			Target = FindTarget()
		end

		if not Target then
			CircleStroke.Color =
				Color3.fromRGB(
					255,
					255,
					255
				)

			return
		end

		local character =
			Target.Character

		local part =
			GetPart(character)

		if not part then
			Target = nil
			return
		end

		if not Visible(
			part,
			character
		) then

			Target = nil
			return
		end

		CircleStroke.Color =
			Color3.fromRGB(
				50,
				255,
				100
			)

		AimAt(part)
	end
)

--==================================================
-- CHARACTER / ESP UPDATES
--==================================================

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		task.wait(0.5)

		if Settings.ESPEnabled then
			CreateESP(plr)
		end
	end)
end)

for _, plr in ipairs(Players:GetPlayers()) do
	if plr ~= LocalPlayer then
		plr.CharacterAdded:Connect(function()
			task.wait(0.5)

			if Settings.ESPEnabled then
				CreateESP(plr)
			end
		end)
	end
end

--==================================================
-- DRAG PANEL
--==================================================

local dragging = false
local dragStart
local panelStart

Title.InputBegan:Connect(function(input)
	if input.UserInputType ==
		Enum.UserInputType.MouseButton1
		or input.UserInputType ==
		Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		panelStart = Panel.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then
		return
	end

	if input.UserInputType ==
		Enum.UserInputType.MouseMovement
		or input.UserInputType ==
		Enum.UserInputType.Touch then

		local delta =
			input.Position - dragStart

		Panel.Position =
			UDim2.new(
				panelStart.X.Scale,
				panelStart.X.Offset + delta.X,
				panelStart.Y.Scale,
				panelStart.Y.Offset + delta.Y
			)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType ==
		Enum.UserInputType.MouseButton1
		or input.UserInputType ==
		Enum.UserInputType.Touch then

		dragging = false
	end
end)

--==================================================
-- INITIALIZE
--==================================================

UpdateAimButton()
UpdateESPButton()