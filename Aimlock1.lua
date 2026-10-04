--============================================================
-- grassaim
-- Replication / Render Benchmark Dashboard
-- LocalScript - place in StarterPlayerScripts or StarterGui
--
-- MODULES:
--   1. Replication Validation Overlay
--   2. Viewport Predictor Visualisation
--   3. Pulse Detection Logger
--
-- IMPORTANT:
--   - No mouse/keyboard input simulation
--   - No combat automation
--   - No remote-event firing
--   - No target attacking
--   - Camera prediction is visual only
--============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

--============================================================
-- CONFIGURATION
--============================================================

local Config = {
	Enabled = true,

	OverlayEnabled = true,
	PredictorEnabled = true,
	PulseEnabled = true,

	Smoothing = 0.15,
	FOVRadius = 100,
	PulseTolerance = 12,

	TargetMode = "Closest",
	NamedTarget = "",

	ShowBoxes = true,
	ShowNames = true,
	ShowHealth = true,
	ShowDistance = true,

	Debug = true,
}

-- Session persistence only.
-- Roblox LocalScripts cannot write arbitrary files.
local SavedJSON = nil

local function DebugPrint(...)
	if Config.Debug then
		print("[grassaim]", ...)
	end
end

local function SafeCall(label, fn, ...)
	local ok, result = pcall(fn, ...)
	if not ok then
		warn("[grassaim][" .. label .. "]", result)
		return nil
	end
	return result
end

--============================================================
-- SETTINGS SERIALIZATION
--============================================================

local function SerializeSettings()
	local ok, encoded = pcall(function()
		return HttpService:JSONEncode({
			Enabled = Config.Enabled,
			OverlayEnabled = Config.OverlayEnabled,
			PredictorEnabled = Config.PredictorEnabled,
			PulseEnabled = Config.PulseEnabled,

			Smoothing = Config.Smoothing,
			FOVRadius = Config.FOVRadius,
			PulseTolerance = Config.PulseTolerance,

			TargetMode = Config.TargetMode,
			NamedTarget = Config.NamedTarget,

			ShowBoxes = Config.ShowBoxes,
			ShowNames = Config.ShowNames,
			ShowHealth = Config.ShowHealth,
			ShowDistance = Config.ShowDistance,
		})
	end)

	if ok then
		SavedJSON = encoded
		DebugPrint("Settings serialized")
	else
		warn("[grassaim] Settings serialization failed:", encoded)
	end

	return SavedJSON
end

local function LoadSettings()
	if not SavedJSON then
		return
	end

	local ok, data = pcall(function()
		return HttpService:JSONDecode(SavedJSON)
	end)

	if not ok or type(data) ~= "table" then
		warn("[grassaim] Could not decode saved settings")
		return
	end

	for key, value in pairs(data) do
		if Config[key] ~= nil then
			Config[key] = value
		end
	end

	DebugPrint("Settings restored")
end

LoadSettings()

--============================================================
-- CLEANUP OLD INSTANCE
--============================================================

local Existing = PlayerGui:FindFirstChild("grassaim")

if Existing then
	Existing:Destroy()
end

--============================================================
-- UI HELPERS
--============================================================

local function New(className, properties, parent)
	local object = Instance.new(className)

	for property, value in pairs(properties or {}) do
		local ok, err = pcall(function()
			object[property] = value
		end)

		if not ok then
			warn("[grassaim] UI property error:", property, err)
		end
	end

	object.Parent = parent
	return object
end

local ScreenGui = New("ScreenGui", {
	Name = "grassaim",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

--============================================================
-- MAIN WINDOW
--============================================================

local Main = New("Frame", {
	Name = "Main",
	Size = UDim2.fromOffset(390, 520),
	Position = UDim2.new(0.5, -195, 0.5, -260),
	BackgroundColor3 = Color3.fromRGB(24, 24, 29),
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, ScreenGui)

New("UICorner", {
	CornerRadius = UDim.new(0, 10),
}, Main)

local Stroke = New("UIStroke", {
	Thickness = 1,
	Transparency = 0.35,
}, Main)

--============================================================
-- TITLE BAR
--============================================================

local TitleBar = New("Frame", {
	Name = "TitleBar",
	Size = UDim2.new(1, 0, 0, 42),
	BackgroundColor3 = Color3.fromRGB(31, 31, 38),
	BorderSizePixel = 0,
}, Main)

local Title = New("TextLabel", {
	Name = "Title",
	Size = UDim2.new(1, -90, 1, 0),
	Position = UDim2.fromOffset(14, 0),
	BackgroundTransparency = 1,
	Text = "grassaim",
	TextSize = 20,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(235, 235, 240),
}, TitleBar)

local Status = New("TextLabel", {
	Name = "Status",
	Size = UDim2.fromOffset(70, 42),
	Position = UDim2.new(1, -75, 0, 0),
	BackgroundTransparency = 1,
	Text = "ACTIVE",
	TextSize = 11,
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.fromRGB(100, 220, 130),
}, TitleBar)

--============================================================
-- DRAGGING
--============================================================

local dragging = false
local dragStart
local startPosition

TitleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		startPosition = Main.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseMovement
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local delta = input.Position - dragStart

	Main.Position = UDim2.new(
		startPosition.X.Scale,
		startPosition.X.Offset + delta.X,
		startPosition.Y.Scale,
		startPosition.Y.Offset + delta.Y
	)
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

--============================================================
-- SCROLLING AREA
--============================================================

local Scroll = New("ScrollingFrame", {
	Name = "Settings",
	Size = UDim2.new(1, -16, 1, -55),
	Position = UDim2.fromOffset(8, 48),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 5,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, Main)

local Layout = New("UIListLayout", {
	Padding = UDim.new(0, 7),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, Scroll)

New("UIPadding", {
	PaddingLeft = UDim.new(0, 5),
	PaddingRight = UDim.new(0, 5),
	PaddingTop = UDim.new(0, 5),
	PaddingBottom = UDim.new(0, 10),
}, Scroll)

--============================================================
-- UI FACTORIES
--============================================================

local function Section(text)
	local label = New("TextLabel", {
		Size = UDim2.new(1, -4, 0, 28),
		BackgroundTransparency = 1,
		Text = text,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.fromRGB(170, 170, 180),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, Scroll)

	return label
end

local function Button(text)
	local button = New("TextButton", {
		Size = UDim2.new(1, -4, 0, 34),
		BackgroundColor3 = Color3.fromRGB(39, 39, 47),
		BorderSizePixel = 0,
		Text = text,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(235, 235, 240),
		AutoButtonColor = true,
	}, Scroll)

	New("UICorner", {
		CornerRadius = UDim.new(0, 6),
	}, button)

	return button
end

local function Toggle(text, getter, setter)
	local button = Button("")

	local function Refresh()
		local enabled = getter()

		button.Text = text .. ": " .. (enabled and "ON" or "OFF")

		if enabled then
			button.TextColor3 = Color3.fromRGB(110, 230, 140)
		else
			button.TextColor3 = Color3.fromRGB(220, 120, 120)
		end
	end

	button.MouseButton1Click:Connect(function()
		setter(not getter())
		SerializeSettings()
		Refresh()
	end)

	Refresh()

	return button
end

-- Custom slider.
-- Roblox does NOT provide Instance.new("Slider"), so this is a
-- Frame-based slider named "Slider".
local function Slider(text, minimum, maximum, getter, setter)

	local Holder = New("Frame", {
		Name = "Slider",
		Size = UDim2.new(1, -4, 0, 55),
		BackgroundTransparency = 1,
	}, Scroll)

	local Label = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Text = "",
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(220, 220, 225),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, Holder)

	local Track = New("Frame", {
		Name = "Track",
		Size = UDim2.new(1, -65, 0, 7),
		Position = UDim2.new(0, 0, 0, 35),
		BackgroundColor3 = Color3.fromRGB(50, 50, 58),
		BorderSizePixel = 0,
	}, Holder)

	New("UICorner", {
		CornerRadius = UDim.new(1, 0),
	}, Track)

	local Fill = New("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0.5, 1),
		BackgroundColor3 = Color3.fromRGB(100, 170, 255),
		BorderSizePixel = 0,
	}, Track)

	New("UICorner", {
		CornerRadius = UDim.new(1, 0),
	}, Fill)

	local Value = New("TextLabel", {
		Size = UDim2.fromOffset(60, 22),
		Position = UDim2.new(1, -60, 0, 26),
		BackgroundTransparency = 1,
		Text = "",
		TextSize = 11,
		Font = Enum.Font.Gotham,
		TextColor3 = Color3.fromRGB(170, 170, 180),
		TextXAlignment = Enum.TextXAlignment.Right,
	}, Holder)

	local function Refresh()

		local current = math.clamp(
			tonumber(getter()) or minimum,
			minimum,
			maximum
		)

		local alpha = (current - minimum) / (maximum - minimum)

		Fill.Size = UDim2.fromScale(alpha, 1)
		Label.Text = text
		Value.Text = tostring(math.floor(current))

	end

	local function SetFromX(x)

		local relative = math.clamp(
			(x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X,
			0,
			1
		)

		local value = minimum + ((maximum - minimum) * relative)

		setter(value)
		SerializeSettings()
		Refresh()

	end

	Track.InputBegan:Connect(function(input)

		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			SetFromX(input.Position.X)

		end

	end)

	UserInputService.InputChanged:Connect(function(input)

		if input.UserInputType == Enum.UserInputType.MouseMovement then

			if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
				SetFromX(input.Position.X)
			end

		elseif input.UserInputType == Enum.UserInputType.Touch then

			if input.UserInputState == Enum.UserInputState.Change then
				SetFromX(input.Position.X)
			end

		end

	end)

	Refresh()

	return Holder
end

--============================================================
-- TARGET SYSTEM
--============================================================

local function IsValidCharacter(character)

	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")

	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	if not root or not head then
		return false
	end

	return true
end

local function GetCharacters()

	local characters = {}

	for _, player in ipairs(Players:GetPlayers()) do

		if player ~= LocalPlayer then

			local character = player.Character

			if IsValidCharacter(character) then
				table.insert(characters, character)
			end

		end

	end

	return characters

end

local function GetTarget()

	local characters = GetCharacters()

	if #characters == 0 then
		return nil
	end

	if Config.TargetMode == "Lowest Health" then

		local best
		local lowest = math.huge

		for _, character in ipairs(characters) do

			local humanoid = character:FindFirstChildOfClass("Humanoid")

			if humanoid and humanoid.Health < lowest then
				lowest = humanoid.Health
				best = character
			end

		end

		return best

	elseif Config.TargetMode == "Random" then

		return characters[math.random(1, #characters)]

	elseif Config.TargetMode == "Named" then

		for _, character in ipairs(characters) do

			if character.Name == Config.NamedTarget then
				return character
			end

		end

	end

	-- Default = closest
	local best
	local closest = math.huge

	local cameraPosition = Camera.CFrame.Position

	for _, character in ipairs(characters) do

		local root = character:FindFirstChild("HumanoidRootPart")

		if root then

			local distance = (root.Position - cameraPosition).Magnitude

			if distance < closest then
				closest = distance
				best = character
			end

		end

	end

	return best
end

--============================================================
-- TARGET SELECTION UI
--============================================================

Section("TARGET SELECTION")

local TargetButton = Button("")

local TargetModes = {
	"Closest",
	"Lowest Health",
	"Random",
	"Named",
}

local TargetIndex = 1

local function RefreshTargetButton()
	TargetButton.Text = "Target Mode: " .. Config.TargetMode
end

TargetButton.MouseButton1Click:Connect(function()

	TargetIndex += 1

	if TargetIndex > #TargetModes then
		TargetIndex = 1
	end

	Config.TargetMode = TargetModes[TargetIndex]

	SerializeSettings()
	RefreshTargetButton()

end)

RefreshTargetButton()

local NameBox = New("TextBox", {
	Name = "TargetName",
	Size = UDim2.new(1, -4, 0, 34),
	BackgroundColor3 = Color3.fromRGB(39, 39, 47),
	BorderSizePixel = 0,
	PlaceholderText = "Named target (TargetMode = Named)",
	Text = Config.NamedTarget,
	TextSize = 12,
	Font = Enum.Font.Gotham,
	TextColor3 = Color3.fromRGB(235, 235, 240),
	ClearTextOnFocus = false,
}, Scroll)

New("UICorner", {
	CornerRadius = UDim.new(0, 6),
}, NameBox)

NameBox.FocusLost:Connect(function()
	Config.NamedTarget = NameBox.Text
	SerializeSettings()
end)

--============================================================
-- GENERAL CONTROLS
--============================================================

Section("MODULES")

Toggle(
	"Master System",
	function()
		return Config.Enabled
	end,
	function(value)
		Config.Enabled = value
	end
)

Toggle(
	"Replication Overlay",
	function()
		return Config.OverlayEnabled
	end,
	function(value)
		Config.OverlayEnabled = value
	end
)

Toggle(
	"Viewport Predictor",
	function()
		return Config.PredictorEnabled
	end,
	function(value)
		Config.PredictorEnabled = value
	end
)

Toggle(
	"Pulse Detector",
	function()
		return Config.PulseEnabled
	end,
	function(value)
		Config.PulseEnabled = value
	end
)

--============================================================
-- OVERLAY CONTROLS
--============================================================

Section("OVERLAY")

Toggle(
	"Bounding Boxes",
	function()
		return Config.ShowBoxes
	end,
	function(value)
		Config.ShowBoxes = value
	end
)

Toggle(
	"Name Tags",
	function()
		return Config.ShowNames
	end,
	function(value)
		Config.ShowNames = value
	end
)

Toggle(
	"Health Values",
	function()
		return Config.ShowHealth
	end,
	function(value)
		Config.ShowHealth = value
	end
)

Toggle(
	"Distance Values",
	function()
		return Config.ShowDistance
	end,
	function(value)
		Config.ShowDistance = value
	end
)

--============================================================
-- BENCHMARK SETTINGS
--============================================================

Section("BENCHMARK")

Slider(
	"Smoothing",
	0.01,
	1,
	function()
		return Config.Smoothing * 100
	end,
	function(value)
		Config.Smoothing = math.clamp(value / 100, 0.01, 1)
	end
)

Slider(
	"FOV Radius",
	50,
	300,
	function()
		return Config.FOVRadius
	end,
	function(value)
		Config.FOVRadius = math.floor(value)
	end
)

Slider(
	"Pulse Tolerance",
	1,
	50,
	function()
		return Config.PulseTolerance
	end,
	function(value)
		Config.PulseTolerance = math.floor(value)
	end
)

--============================================================
-- RESIZE HANDLE
--============================================================

local Resize = New("Frame", {
	Name = "ResizeHandle",
	Size = UDim2.fromOffset(18, 18),
	Position = UDim2.new(1, -18, 1, -18),
	BackgroundTransparency = 1,
}, Main)

local resizeLine = New("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "◢",
	TextSize = 16,
	TextColor3 = Color3.fromRGB(130, 130, 140),
}, Resize)

local resizing = false
local resizeStart
local originalSize

Resize.InputBegan:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		resizing = true
		resizeStart = input.Position
		originalSize = Main.AbsoluteSize

	end

end)

UserInputService.InputChanged:Connect(function(input)

	if not resizing then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseMovement
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local delta = input.Position - resizeStart

	local width = math.max(300, originalSize.X + delta.X)
	local height = math.max(300, originalSize.Y + delta.Y)

	Main.Size = UDim2.fromOffset(width, height)

end)

UserInputService.InputEnded:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		resizing = false

	end

end)

--============================================================
-- FOV VISUALIZATION
--============================================================

local FOVGui = New("Frame", {
	Name = "FOVCircle",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(Config.FOVRadius * 2, Config.FOVRadius * 2),
	BackgroundTransparency = 1,
	Visible = true,
}, ScreenGui)

local FOVStroke = New("UIStroke", {
	Thickness = 1,
	Transparency = 0.35,
}, FOVGui)

New("UICorner", {
	CornerRadius = UDim.new(1, 0),
}, FOVGui)

--============================================================
-- REPLICATION VALIDATION OVERLAY
--============================================================

local OverlayFolder = New("Folder", {
	Name = "ReplicationOverlay",
}, ScreenGui)

local OverlayObjects = {}

local function CreateOverlay(character)

	if OverlayObjects[character] then
		return OverlayObjects[character]
	end

	local box = New("Frame", {
		Name = "BoundingBox",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 1,
		Visible = false,
	}, OverlayFolder)

	local boxStroke = New("UIStroke", {
		Thickness = 1,
		Transparency = 0.15,
	}, box)

	local label = New("TextLabel", {
		Name = "Info",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, -3),
		Size = UDim2.fromOffset(220, 45),
		BackgroundTransparency = 1,
		TextSize = 11,
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.fromRGB(235, 235, 235),
		TextStrokeTransparency = 0.5,
		Visible = false,
	}, box)

	OverlayObjects[character] = {
		Box = box,
		Stroke = boxStroke,
		Label = label,
	}

	return OverlayObjects[character]
end

local function RemoveOverlay(character)

	local data = OverlayObjects[character]

	if data then

		if data.Box then
			data.Box:Destroy()
		end

		OverlayObjects[character] = nil

	end

end

local function UpdateOverlay(character)

	if not IsValidCharacter(character) then

		RemoveOverlay(character)
		return

	end

	local data = CreateOverlay(character)

	local root = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not root or not head or not humanoid then
		return
	end

	local rootPos, rootVisible = Camera:WorldToViewportPoint(root.Position)
	local headPos, head