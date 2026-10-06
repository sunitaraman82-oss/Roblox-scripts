--// MOBILE-FRIENDLY SETTINGS GUI
--// Roblox Studio LocalScript
--// Put inside StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

local Settings = {
	SilentAim = true,
	Prediction = 0.1,
	Offset = 0,
	Resolver = false,
	TeamCheck = true,
	FOVRadius = 120,
	FOVThreshold = 0.5,
	TargetPart = "HumanoidRootPart"
}

local Gui = Instance.new("ScreenGui")
Gui.Name = "MobileSettingsGUI"
Gui.ResetOnSpawn = false
Gui.Parent = Player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(280, 390)
Main.Position = UDim2.new(0.5, -140, 0.5, -195)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Main.BorderSizePixel = 0
Main.Parent = Gui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 0, 45)
Title.Position = UDim2.fromOffset(15, 0)
Title.BackgroundTransparency = 1
Title.Text = "Settings"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(35, 35)
Minimize.Position = UDim2.new(1, -42, 0, 5)
Minimize.Text = "-"
Minimize.TextSize = 22
Minimize.TextColor3 = Color3.new(1, 1, 1)
Minimize.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
Minimize.Parent = Main

Instance.new("UICorner", Minimize).CornerRadius = UDim.new(0, 8)

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -20, 1, -55)
Content.Position = UDim2.fromOffset(10, 50)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 4
Content.CanvasSize = UDim2.new()
Content.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 8)
Layout.Parent = Content

local function updateCanvas()
	Content.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 10)
end

Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

local function CreateToggle(name, setting)
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, -5, 0, 45)
	Button.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
	Button.TextColor3 = Color3.new(1, 1, 1)
	Button.TextSize = 15
	Button.Font = Enum.Font.Gotham
	Button.AutoButtonColor = false
	Button.Parent = Content

	Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)

	local function refresh()
		Button.Text = name .. ": " .. (Settings[setting] and "ON" or "OFF")
	end

	Button.Activated:Connect(function()
		Settings[setting] = not Settings[setting]
		refresh()
	end)

	refresh()
end

local function CreateSlider(name, setting, min, max, step)
	local Holder = Instance.new("Frame")
	Holder.Size = UDim2.new(1, -5, 0, 65)
	Holder.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
	Holder.Parent = Content

	Instance.new("UICorner", Holder).CornerRadius = UDim.new(0, 8)

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -20, 0, 25)
	Label.Position = UDim2.fromOffset(10, 5)
	Label.BackgroundTransparency = 1
	Label.TextColor3 = Color3.new(1, 1, 1)
	Label.TextSize = 14
	Label.Font = Enum.Font.Gotham
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Holder

	local Bar = Instance.new("Frame")
	Bar.Size = UDim2.new(1, -20, 0, 8)
	Bar.Position = UDim2.fromOffset(10, 43)
	Bar.BackgroundColor3 = Color3.fromRGB(70, 70, 78)
	Bar.BorderSizePixel = 0
	Bar.Parent = Holder

	Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)

	local Fill = Instance.new("Frame")
	Fill.BackgroundColor3 = Color3.fromRGB(0, 200, 140)
	Fill.BorderSizePixel = 0
	Fill.Parent = Bar

	Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

	local function setFromX(x)
		local percent = math.clamp(
			(x - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X,
			0,
			1
		)

		local value = min + (max - min) * percent

		if step then
			value = math.floor(value / step + 0.5) * step
		end

		Settings[setting] = value

		local normalized = (value - min) / (max - min)
		Fill.Size = UDim2.new(normalized, 0, 1, 0)

		Label.Text = name .. ": " .. tostring(value)
	end

	Bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			setFromX(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then

			if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
				or input.UserInputType == Enum.UserInputType.Touch then
				-- Touch position is handled when interacting with the bar.
			end
		end
	end)

	setFromX(
		Bar.AbsolutePosition.X +
		((Settings[setting] - min) / (max - min)) * Bar.AbsoluteSize.X
	)
end

CreateToggle("Silent Aim", "SilentAim")
CreateToggle("Resolver", "Resolver")
CreateToggle("Team Check", "TeamCheck")

CreateSlider("Prediction", "Prediction", 0, 1, 0.01)
CreateSlider("Offset", "Offset", 0, 2, 0.05)
CreateSlider("FOV Radius", "FOVRadius", 20, 300, 1)
CreateSlider("FOV Threshold", "FOVThreshold", 0, 1, 0.01)

local minimized = false

Minimize.Activated:Connect(function()
	minimized = not minimized

	Content.Visible = not minimized

	if minimized then
		Main.Size = UDim2.fromOffset(280, 50)
		Minimize.Text = "+"
	else
		Main.Size = UDim2.fromOffset(280, 390)
		Minimize.Text = "-"
	end
end)

--// Mobile-friendly dragging
local dragging = false
local dragStart
local startPosition

Main.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then

		dragging = true
		dragStart = input.Position
		startPosition = Main.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then
		return
	end

	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseMovement then

		local delta = input.Position - dragStart

		Main.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)