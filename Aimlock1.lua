-- ==========================================================
-- RIVALS CENTER-FOV SILENT AIM (Mobile Delta)
-- ==========================================================

repeat task.wait() until game:IsLoaded()
repeat task.wait() until Players and Players.LocalPlayer
repeat task.wait() until Players.LocalPlayer:FindFirstChild("PlayerScripts")

local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer   = Players.LocalPlayer
local CurrentCamera = Workspace.CurrentCamera

-- // MOBILE DETECTION \\ --
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- // CONFIGURATION \\ --
local Configuration = {
	Enabled    = false,
	FOV        = 80,   -- Small center FOV (in pixels)
	MaxAngle   = 45,
	TeamCheck  = true,
	WallCheck  = true,
	HitParts   = { "Head", "UpperTorso", "HumanoidRootPart" },
	Prediction = 0.06,
	ShowFOV    = true,
	CacheRate  = 1,
}

-- // REMOTE SETUP \\ --
local Char0, Char1, Char2, Char3 = utf8.char(0), utf8.char(1), utf8.char(2), utf8.char(3)
local Char4, Char5               = utf8.char(4), utf8.char(5)

local FighterFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
if not FighterFolder then warn("Remotes not found") return end
FighterFolder = FighterFolder:WaitForChild("Replication", 10)
if not FighterFolder then return end
FighterFolder = FighterFolder:WaitForChild("Fighter", 10)
if not FighterFolder then return end

local UpdateState          = FighterFolder:WaitForChild("UpdateState", 10)
local UpdateCameraRotation = FighterFolder:WaitForChild("UpdateCameraRotation", 10)

if not UpdateState or not UpdateCameraRotation then return end

local Utility = nil
pcall(function()
	Utility = require(ReplicatedStorage.Modules.Utility)
end)

-- // CENTER FOV CIRCLE \\ --
local FOVCircle = nil
pcall(function()
	FOVCircle           = Drawing.new("Circle")
	FOVCircle.Color     = Color3.fromRGB(255, 255, 255)
	FOVCircle.Thickness = 2
	FOVCircle.NumSides  = 60
	FOVCircle.Filled    = false
	FOVCircle.Transparency = 1
end)

-- // TARGETING LOGIC \\ --
local Cached    = {}
local LastCache = 0

local function IsSameTeam(character)
	if not Configuration.TeamCheck then return false end
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		local mine   = LocalPlayer:GetAttribute("TeamID")
		local theirs = player:GetAttribute("TeamID")
		if mine ~= nil and theirs ~= nil and mine == theirs then return true end
		if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then return true end
	end
	return false
end

local function RefreshCache()
	if tick() - LastCache < Configuration.CacheRate then return end
	LastCache = tick()
	table.clear(Cached)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			if not IsSameTeam(plr.Character) then
				table.insert(Cached, plr.Character)
			end
		end
	end
	for _, model in ipairs(CollectionService:GetTagged("Entity")) do
		if model:IsA("Model") and model ~= LocalPlayer.Character and not IsSameTeam(model) then
			table.insert(Cached, model)
		end
	end
	local range = Workspace:FindFirstChild("ShootingRangeEntities")
	if range then
		for _, model in ipairs(range:GetChildren()) do
			if model:IsA("Model") then table.insert(Cached, model) end
		end
	end
end

local RayParams       = RaycastParams.new()
RayParams.FilterType  = Enum.RaycastFilterType.Exclude
RayParams.IgnoreWater = true

local function IsVisible(from, to, char)
	if not Configuration.WallCheck then return true end
	local ignoreList = { LocalPlayer.Character, CurrentCamera }
	for _, obj in ipairs(char:GetChildren()) do
		if obj:IsA("Accessory") or obj:IsA("Tool") or obj:IsA("Hat") then
			table.insert(ignoreList, obj)
		end
	end
	RayParams.FilterDescendantsInstances = ignoreList
	local hit = Workspace:Raycast(from, to - from, RayParams)
	if not hit then return true end
	return hit.Instance:IsDescendantOf(char)
end

local LastTarget, LastPart = nil, nil

-- // CENTER FOV TARGETING FUNCTION \\ --
local function GetTarget()
	if not Configuration.Enabled then
		getgenv().__SA_Lock = false
		if FOVCircle then FOVCircle.Visible = false end
		return nil, nil
	end

	RefreshCache()

	-- Always use the CENTER of the screen
	local cx = CurrentCamera.ViewportSize.X / 2
	local cy = CurrentCamera.ViewportSize.Y / 2

	local camPos  = CurrentCamera.CFrame.Position
	local camLook = CurrentCamera.CFrame.LookVector

	local bestPos, bestPart, bestDist = nil, nil, Configuration.FOV

	for _, model in ipairs(Cached) do
		local hum = model:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			for _, name in ipairs(Configuration.HitParts) do
				local part = model:FindFirstChild(name)
				if part and part:IsA("BasePart") then
					local vel = part.AssemblyLinearVelocity
					local aim = vel.Magnitude > 2 and part.Position + vel * Configuration.Prediction or part.Position
					local s, onScreen = CurrentCamera:WorldToViewportPoint(aim)

					if onScreen then
						local dx, dy = s.X - cx, s.Y - cy
						local d = math.sqrt(dx * dx + dy * dy)

						-- Only lock if the enemy is INSIDE the center FOV circle
						if d < bestDist then
							local dir = (aim - camPos).Unit
							if camLook:Dot(dir) > math.cos(math.rad(Configuration.MaxAngle)) then
								if IsVisible(camPos, aim, model) then
									bestDist = d
									bestPos  = aim
									bestPart = part
								end
							end
						end
					end
					break
				end
			end
		end
	end

	LastTarget, LastPart = bestPos, bestPart

	if bestPos then
		getgenv().__SA_Shot = { Pos = bestPos, T = tick() }
		getgenv().__SA_Lock = true
	else
		getgenv().__SA_Lock = false
	end

	-- Update the center FOV Circle
	if FOVCircle then
		FOVCircle.Position = Vector2.new(cx, cy)
		FOVCircle.Radius   = Configuration.FOV
		FOVCircle.Visible  = Configuration.ShowFOV and Configuration.Enabled
		FOVCircle.Color    = getgenv().__SA_Lock and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)
	end

	return bestPos, bestPart
end

RunService.RenderStepped:Connect(function() GetTarget() end)

-- // REMOTE HOOKING \\ --
local function Encode(cf)
	local rx, ry, rz = cf:ToOrientation()
	return { [Char0] = cf.X, [Char1] = cf.Y, [Char2] = cf.Z, [Char3] = rx, [Char4] = ry, [Char5] = rz }
end

local function EncodeRot(target)
	local rx, ry = CFrame.new(CurrentCamera.CFrame.Position, target):ToOrientation()
	local ok, enc = pcall(function() return Utility:EncodeCameraRotation(Vector2.new(rx, ry)) end)
	if ok and enc then return enc end
	local function b(v) return utf8.char(math.clamp(math.floor(v % 6.2831853 / 6.2831853 * 256 + 0.5), 0, 255)) end
	return b(rx) .. b(ry)
end

local function HookRemote(remote, fn)
	if oth and oth.hook and oth.get_root_callback then
		oth.hook(remote.FireServer, function(self, ...)
			return fn(oth.get_root_callback(), self, ...)
		end)
	else
		local old
		old = hookfunction(remote.FireServer, newcclosure(function(self, ...)
			return fn(old, self, ...)
		end))
	end
end

HookRemote(UpdateState, function(call, self, enumId, a1, a2, ...)
	if not Configuration.Enabled then return call(self, enumId, a1, a2, ...) end
	if type(a2) == "table" then
		local pos, part = LastTarget, LastPart
		if pos and part then
			local ok, pcf = pcall(function() return part.CFrame end)
			if ok then
				local noff   = Encode(pcf:Inverse() * CFrame.new(pos))
				local cloned = table.clone(a2)
				for k, e in pairs(cloned) do
					if type(e) == "table" and e[Char2] ~= nil then
						local n   = table.clone(e)
						n[Char2]  = part
						n[Char3]  = noff
						cloned[k] = n
					end
				end
				return call(self, enumId, a1, cloned, ...)
			end
		end
	end
	return call(self, enumId, a1, a2, ...)
end)

HookRemote(UpdateCameraRotation, function(call, self, rot, ...)
	if not Configuration.Enabled then return call(self, rot, ...) end
	local s = getgenv().__SA_Shot
	if s and tick() - s.T < 0.5 and rot ~= nil then
		rot = EncodeRot(s.Pos)
	end
	return call(self, rot, ...)
end)

-- // UI CREATION \\ --
local Gui = Instance.new("ScreenGui")
Gui.Name = "RivalsCenterAim"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Panel = Instance.new("Frame")
Panel.Size = UDim2.fromOffset(320, 340)
Panel.Position = UDim2.new(0, 15, 0.5, -170)
Panel.BackgroundColor3 = Color3.fromRGB(22, 20, 27)
Panel.BackgroundTransparency = 0.08
Panel.BorderSizePixel = 0
Panel.Parent = Gui
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 14)

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Color = Color3.fromRGB(80, 75, 90)
PanelStroke.Transparency = 0.25
PanelStroke.Parent = Panel

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -85, 0, 45)
Title.Position = UDim2.fromOffset(15, 5)
Title.BackgroundTransparency = 1
Title.Text = "Center Aim Assist"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 19
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

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(34, 34)
Minimize.Position = UDim2.new(1, -82, 0, 10)
Minimize.BackgroundColor3 = Color3.fromRGB(45, 42, 52)
Minimize.Text = "-"
Minimize.TextColor3 = Color3.new(1, 1, 1)
Minimize.TextSize = 22
Minimize.Font = Enum.Font.GothamBold
Minimize.Parent = Panel
Instance.new("UICorner", Minimize).CornerRadius = UDim.new(0, 8)

local Open = Instance.new("TextButton")
Open.Size = UDim2.fromOffset(48, 48)
Open.Position = UDim2.fromOffset(20, 20)
Open.BackgroundColor3 = Color3.fromRGB(25, 23, 30)
Open.BackgroundTransparency = 0.05
Open.Text = "☰"
Open.TextColor3 = Color3.new(1, 1, 1)
Open.TextSize = 21
Open.Font = Enum.Font.GothamBold
Open.Visible = false
Open.Parent = Gui
Instance.new("UICorner", Open).CornerRadius = UDim.new(0, 12)

Close.Activated:Connect(function() Panel.Visible = false; Open.Visible = true end)
Minimize.Activated:Connect(function() Panel.Visible = false; Open.Visible = true end)
Open.Activated:Connect(function() Panel.Visible = true; Open.Visible = false end)

local Y = 55
local function Button(text)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -30, 0, 36)
	b.Position = UDim2.fromOffset(15, Y)
	b.BackgroundColor3 = Color3.fromRGB(40, 37, 47)
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextSize = 13
	b.Font = Enum.Font.GothamSemibold
	b.Parent = Panel
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
	Y += 42
	return b
end

local function Label(text)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -30, 0, 23)
	l.Position = UDim2.fromOffset(15, Y)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = Color3.fromRGB(205, 202, 215)
	l.TextSize = 12
	l.Font = Enum.Font.Gotham
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = Panel
	Y += 27
	return l
end

local AimButton = Button("Enabled : OFF")
local TeamButton = Button("Team Check : ON")
local WallButton = Button("Wall Check : ON")
local FOVLabel = Label("FOV : 80")

local FOVBar = Instance.new("Frame")
FOVBar.Size = UDim2.new(1, -30, 0, 8)
FOVBar.Position = UDim2.fromOffset(15, Y)
FOVBar.BackgroundColor3 = Color3.fromRGB(55, 52, 63)
FOVBar.BorderSizePixel = 0
FOVBar.Parent = Panel
Instance.new("UICorner", FOVBar).CornerRadius = UDim.new(1, 0)

local FOVFill = Instance.new("Frame")
FOVFill.Size = UDim2.new(Configuration.FOV / 300, 0, 1, 0)
FOVFill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
FOVFill.BorderSizePixel = 0
FOVFill.Parent = FOVBar
Instance.new("UICorner", FOVFill).CornerRadius = UDim.new(1, 0)

-- Slider Logic
local dragging = false
local function updateSlider(x)
	local percent = math.clamp((x - FOVBar.AbsolutePosition.X) / FOVBar.AbsoluteSize.X, 0, 1)
	local value = math.floor(20 + (280 * percent)) -- FOV range: 20 to 300
	Configuration.FOV = value
	FOVLabel.Text = "FOV : " .. value
	FOVFill.Size = UDim2.new(percent, 0, 1, 0)
end

FOVBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		updateSlider(input.Position.X)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		updateSlider(input.Position.X)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

local function UpdateAimButton()
	AimButton.Text = "Enabled : " .. (Configuration.Enabled and "ON" or "OFF")
	AimButton.BackgroundColor3 = Configuration.Enabled and Color3.fromRGB(45, 135, 75) or Color3.fromRGB(40, 37, 47)
end

AimButton.Activated:Connect(function()
	Configuration.Enabled = not Configuration.Enabled
	UpdateAimButton()
end)

TeamButton.Activated:Connect(function()
	Configuration.TeamCheck = not Configuration.TeamCheck
	TeamButton.Text = "Team Check : " .. (Configuration.TeamCheck and "ON" or "OFF")
end)

WallButton.Activated:Connect(function()
	Configuration.WallCheck = not Configuration.WallCheck
	WallButton.Text = "Wall Check : " .. (Configuration.WallCheck and "ON" or "OFF")
end)

-- // MOBILE TOGGLE BUTTON (Top Right) \\ --
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.fromOffset(50, 50)
ToggleBtn.Position = UDim2.new(1, -65, 0, 60)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 42, 52)
ToggleBtn.Text = "Aim"
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.TextSize = 14
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = Gui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 12)

ToggleBtn.Activated:Connect(function()
	Configuration.Enabled = not Configuration.Enabled
	UpdateAimButton()
end)

-- // DRAGGING LOGIC \\ --
local dragStart, startPos
local function setupDrag(guiObj)
	guiObj.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = guiObj.Position
		end
	end)
end

setupDrag(Title)
setupDrag(Open)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStart
		local target = (Title.Parent == Panel) and Panel or Open
		target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UpdateAimButton()
print("Rivals Center FOV Aim Loaded!")