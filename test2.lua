-- Roblox Combat Assist
-- Put this LocalScript in:
-- StarterPlayer > StarterPlayerScripts
--
-- Features:
-- Aim Assist
-- Target Lock
-- ESP
-- Smoothness
-- Hit-part selection: Head / Body / Random
-- Mobile-friendly GUI
-- No Silent Aim / forced-hit

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = {
	AimAssist = false,
	TargetLock = false,
	ESP = false,
	Smoothness = 0.15,
	HitPart = "Head",
	Range = 300
}

local Target

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "CombatAssist"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(220, 270)
frame.Position = UDim2.fromOffset(20, 100)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.Parent = gui

local function button(text, y)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,-20,0,40)
	b.Position = UDim2.fromOffset(10,y)
	b.Text = text
	b.TextSize = 16
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = Color3.fromRGB(50,50,50)
	b.Parent = frame
	return b
end

local aim = button("Aim Assist: OFF",10)
local lock = button("Target Lock: OFF",55)
local esp = button("ESP: OFF",100)
local part = button("Hit Part: HEAD",145)
local smooth = button("Smoothness +",190)
local minus = button("Smoothness -",235)

-- Target detection
local function getTarget()
	local best
	local bestDistance = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			local root = player.Character:FindFirstChild("HumanoidRootPart")

			if humanoid and root and humanoid.Health > 0 then
				local myRoot = LocalPlayer.Character
					and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

				if myRoot then
					local distance = (myRoot.Position-root.Position).Magnitude

					if distance < Settings.Range and distance < bestDistance then
						best = player
						bestDistance = distance
					end
				end
			end
		end
	end

	return best
end

local function getPart(character)
	if Settings.HitPart == "Head" then
		return character:FindFirstChild("Head")
	elseif Settings.HitPart == "Body" then
		return character:FindFirstChild("UpperTorso")
			or character:FindFirstChild("Torso")
			or character:FindFirstChild("HumanoidRootPart")
	else
		local parts = {}

		for _, name in ipairs({
			"Head",
			"UpperTorso",
			"Torso",
			"LeftUpperArm",
			"RightUpperArm",
			"LeftUpperLeg",
			"RightUpperLeg"
		}) do
			local p = character:FindFirstChild(name)
			if p then
				table.insert(parts,p)
			end
		end

		return parts[math.random(1,#parts)]
	end
end

-- ESP
local function updateESP()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then

			local old = player.Character:FindFirstChild("CombatESP")

			if Settings.ESP and not old then
				local h = Instance.new("Highlight")
				h.Name = "CombatESP"
				h.FillTransparency = 0.6
				h.OutlineTransparency = 0
				h.Parent = player.Character

			elseif not Settings.ESP and old then
				old:Destroy()
			end
		end
	end
end

-- Aim
RunService.RenderStepped:Connect(function()

	updateESP()

	if not Settings.AimAssist then
		return
	end

	if not Target or not Target.Character then
		Target = getTarget()
	end

	if not Settings.TargetLock then
		Target = getTarget()
	end

	if Target and Target.Character then
		local targetPart = getPart(Target.Character)

		if targetPart then
			local desired = CFrame.lookAt(
				Camera.CFrame.Position,
				targetPart.Position
			)

			Camera.CFrame = Camera.CFrame:Lerp(
				desired,
				Settings.Smoothness
			)
		end
	end
end)

-- Buttons
aim.MouseButton1Click:Connect(function()
	Settings.AimAssist = not Settings.AimAssist
	aim.Text = "Aim Assist: "..(Settings.AimAssist and "ON" or "OFF")

	if not Settings.AimAssist then
		Target = nil
	end
end)

lock.MouseButton1Click:Connect(function()
	Settings.TargetLock = not Settings.TargetLock
	lock.Text = "Target Lock: "..(Settings.TargetLock and "ON" or "OFF")

	if Settings.TargetLock then
		Target = getTarget()
	else
		Target = nil
	end
end)

esp.MouseButton1Click:Connect(function()
	Settings.ESP = not Settings.ESP
	esp.Text = "ESP: "..(Settings.ESP and "ON" or "OFF")
	updateESP()
end)

part.MouseButton1Click:Connect(function()
	if Settings.HitPart == "Head" then
		Settings.HitPart = "Body"
	elseif Settings.HitPart == "Body" then
		Settings.HitPart = "Random"
	else
		Settings.HitPart = "Head"
	end

	part.Text = "Hit Part: "..string.upper(Settings.HitPart)
end)

smooth.MouseButton1Click:Connect(function()
	Settings.Smoothness = math.clamp(
		Settings.Smoothness + 0.05,
		0.05,
		0.5
	)
end)

minus.MouseButton1Click:Connect(function()
	Settings.Smoothness = math.clamp(
		Settings.Smoothness - 0.05,
		0.05,
		0.5
	)
end)

-- Mobile/keyboard target reset
UIS.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.Q then
		Settings.AimAssist = not Settings.AimAssist
		aim.Text = "Aim Assist: "..(Settings.AimAssist and "ON" or "OFF")
	end

	if input.KeyCode == Enum.KeyCode.E then
		Settings.TargetLock = not Settings.TargetLock
		lock.Text = "Target Lock: "..(Settings.TargetLock and "ON" or "OFF")

		if Settings.TargetLock then
			Target = getTarget()
		else
			Target = nil
		end
	end
end)

print("Combat Assist loaded successfully")