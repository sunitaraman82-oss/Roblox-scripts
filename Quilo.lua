-- deoffed by mani

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

game:GetService("HttpService")

local CoreGui = game:GetService("CoreGui")

game:GetService("TweenService")

local CurrentCamera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

LocalPlayer:GetMouse()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local mousemoverel_ = mousemoverel
local settings_ = settings
local t1 = {
	["Visuals"] = {
		["SkeletonESP"] = false,
		["BoxESP"] = false,
		["LineESP"] = false,
		["NameESP"] = false,
		["HealthESP"] = false,
		["HealthBar"] = false,
		["TeamCheck"] = false,
		["LevelESP"] = false,
		["WallCheck"] = false,
		["DistanceESP"] = false,
		["ESPRange"] = 1000,
	},
	["Aim"] = {
		["Enabled"] = false,
		["Smoothing"] = 0.3,
		["Target"] = "Neck",
		["AntiRecoil"] = false,
		["MagicBullet"] = false,
		["SilentBullet"] = false,
		["NearestAim"] = false,
		["LockOn"] = false,
		["ShowFOV"] = false,
		["FOVSize"] = 180,
		["SpinBot"] = false,
		["ShootOnContact"] = false,
	},
	["Misc"] = {
		["TPToNearest"] = false,
		["TPHotkey"] = Enum.KeyCode.T,
		["Speed"] = 16,
		["NoClip"] = false,
		["Sky"] = "Default",
		["GodMode"] = false,
		["AutoPlay"] = false,
		["Flying"] = false,
		["InfiniteJump"] = false,
		["Xray"] = false,
		["Optimize"] = false,
	},
}
local v15 = LocalPlayer
local v16 = t1

local function v17()
	local ok, result = pcall(function()
		return game:GetService("DataStoreService"):GetDataStore("PultoHubConfig"):GetAsync(v15.UserId)
	end)

	if not (ok and result) then
		return
	end

	local v20

	ok, result, v20 = pairs(result)

	while true do
		local v21

		v20, v21 = ok(result, v20)

		if v20 == nil then
			break
		end

		if v16[v20] then
			local v22, v23

			v21, v22, v23 = pairs(v21)

			local v24 = v20

			while true do
				local v25

				v23, v25 = v21(v22, v23)

				if v23 == nil then
					break
				end

				v16[v24][v23] = v25
			end
		end
	end
end

local legit = {
	["Visuals"] = {
		["SkeletonESP"] = true,
		["BoxESP"] = false,
		["LineESP"] = false,
		["NameESP"] = false,
		["HealthESP"] = false,
		["HealthBar"] = true,
		["TeamCheck"] = false,
		["LevelESP"] = false,
		["WallCheck"] = true,
		["DistanceESP"] = false,
		["ESPRange"] = 500,
	},
	["Aim"] = {
		["Enabled"] = true,
		["Smoothing"] = 0.15,
		["Target"] = "Neck",
		["AntiRecoil"] = false,
		["MagicBullet"] = false,
		["SilentBullet"] = false,
		["NearestAim"] = false,
		["LockOn"] = false,
		["ShowFOV"] = true,
		["FOVSize"] = 80,
		["SpinBot"] = false,
		["ShootOnContact"] = false,
	},
	["Misc"] = {
		["TPToNearest"] = false,
		["TPHotkey"] = Enum.KeyCode.T,
		["Speed"] = 16,
		["NoClip"] = false,
		["Sky"] = "Default",
		["GodMode"] = false,
		["AutoPlay"] = false,
		["Flying"] = false,
		["InfiniteJump"] = false,
		["Xray"] = false,
		["Optimize"] = false,
	},
}
local t2 = {
	Legit = legit,
}

legit = {
	["Visuals"] = {
		["SkeletonESP"] = true,
		["BoxESP"] = false,
		["LineESP"] = true,
		["NameESP"] = true,
		["HealthESP"] = true,
		["HealthBar"] = true,
		["TeamCheck"] = false,
		["LevelESP"] = true,
		["WallCheck"] = true,
		["DistanceESP"] = true,
		["ESPRange"] = 2000,
	},
	["Aim"] = {
		["Enabled"] = true,
		["Smoothing"] = 0.9,
		["Target"] = "Head",
		["AntiRecoil"] = true,
		["MagicBullet"] = true,
		["SilentBullet"] = true,
		["NearestAim"] = true,
		["LockOn"] = true,
		["ShowFOV"] = true,
		["FOVSize"] = 150,
		["SpinBot"] = true,
		["ShootOnContact"] = true,
	},
	["Misc"] = {
		["TPToNearest"] = true,
		["TPHotkey"] = Enum.KeyCode.P,
		["Speed"] = 32,
		["NoClip"] = true,
		["Sky"] = "Galaxy",
		["GodMode"] = true,
		["AutoPlay"] = false,
		["Flying"] = false,
		["InfiniteJump"] = true,
		["Xray"] = false,
		["Optimize"] = false,
	},
}
t2.Rage = legit
legit = {
	["Visuals"] = {
		["SkeletonESP"] = true,
		["BoxESP"] = false,
		["LineESP"] = true,
		["NameESP"] = true,
		["HealthESP"] = true,
		["HealthBar"] = true,
		["TeamCheck"] = false,
		["LevelESP"] = true,
		["WallCheck"] = true,
		["DistanceESP"] = true,
		["ESPRange"] = 1000,
	},
	["Aim"] = {
		["Enabled"] = true,
		["Smoothing"] = 0.3,
		["Target"] = "Head",
		["AntiRecoil"] = true,
		["MagicBullet"] = true,
		["SilentBullet"] = true,
		["NearestAim"] = false,
		["LockOn"] = false,
		["ShowFOV"] = true,
		["FOVSize"] = 120,
		["SpinBot"] = false,
		["ShootOnContact"] = false,
	},
	["Misc"] = {
		["TPToNearest"] = true,
		["TPHotkey"] = Enum.KeyCode.P,
		["Speed"] = 16,
		["NoClip"] = false,
		["Sky"] = "Pink",
		["GodMode"] = false,
		["AutoPlay"] = false,
		["Flying"] = false,
		["InfiniteJump"] = false,
		["Xray"] = false,
		["Optimize"] = true,
	},
}
t2.Pulto = legit
legit = {
	["Visuals"] = {
		["SkeletonESP"] = false,
		["BoxESP"] = false,
		["LineESP"] = false,
		["NameESP"] = false,
		["HealthESP"] = false,
		["HealthBar"] = false,
		["TeamCheck"] = false,
		["LevelESP"] = false,
		["WallCheck"] = false,
		["DistanceESP"] = false,
		["ESPRange"] = 1000,
	},
	["Aim"] = {
		["Enabled"] = false,
		["Smoothing"] = 0.3,
		["Target"] = "Neck",
		["AntiRecoil"] = false,
		["MagicBullet"] = false,
		["SilentBullet"] = false,
		["NearestAim"] = false,
		["LockOn"] = false,
		["ShowFOV"] = false,
		["FOVSize"] = 180,
		["SpinBot"] = false,
		["ShootOnContact"] = false,
	},
	["Misc"] = {
		["TPToNearest"] = false,
		["TPHotkey"] = Enum.KeyCode.T,
		["Speed"] = 16,
		["NoClip"] = false,
		["Sky"] = "Galaxy",
		["GodMode"] = false,
		["AutoPlay"] = false,
		["Flying"] = true,
		["InfiniteJump"] = true,
		["Xray"] = false,
		["Optimize"] = true,
	},
}
t2.Sky = legit

local v28 = t2
local v29 = t1

t2 = function(p1)
	local v30 = v28[p1]

	if v30 then
		local v31, v32

		v30, v31, v32 = pairs(v30)

		while true do
			local v33

			v32, v33 = v30(v31, v32)

			if v32 == nil then
				break
			end

			if v29[v32] then
				local v34, v35

				v33, v34, v35 = pairs(v33)

				local v36 = v32

				while true do
					local v37

					v35, v37 = v33(v34, v35)

					if v35 == nil then
						break
					end

					v29[v36][v35] = v37
				end
			end
		end

		return
	else
		return
	end
end
local ScreenGui = nil
local u41 = false
local u42 = false
local Position = nil
local Position2 = nil
local ScreenGui2 = nil

legit = {}

local MouseBehavior = nil
local u47 = nil
local u48 = nil
local n1
local Circle = nil
local u51 = false
local u52 = nil
local u53 = nil
local u54 = nil
local u55 = nil
local u56 = nil
local u57 = nil
local Text = nil
local n2 = 0
local n3 = 0
local n4 = 0
local u62 = nil
local u63 = nil
local v64 = nil
local v65 = nil
local v66 = nil
local v67 = LocalPlayer
local v68 = t1
local v69 = Workspace

local function v70(p2)
	local Character = v67.Character
	local Character2 = p2.Character

	if Character and Character2 then
		local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
		local HumanoidRootPart2 = Character2:FindFirstChild("HumanoidRootPart")

		if HumanoidRootPart and HumanoidRootPart2 then
			if v68.Visuals.WallCheck then
				HumanoidRootPart = HumanoidRootPart.Position

				local Unit = (HumanoidRootPart2.Position - HumanoidRootPart).Unit

				HumanoidRootPart2 = (HumanoidRootPart2.Position - HumanoidRootPart).Magnitude

				local raycastParams = RaycastParams.new()

				raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
				raycastParams.FilterDescendantsInstances = { Character, Character2 }

				return v69:Raycast(HumanoidRootPart, Unit * HumanoidRootPart2, raycastParams) == nil
			else
				return true
			end

			return
		else
			return false
		end

		return
	else
		return false
	end
end
local v79 = CoreGui

local function v80()
	ScreenGui2 = Instance.new("ScreenGui")
	ScreenGui2.Name = "PultoHubLoading"
	ScreenGui2.IgnoreGuiInset = true
	ScreenGui2.DisplayOrder = 9999
	ScreenGui2.Parent = v79

	local Frame = Instance.new("Frame")

	Frame.Size = UDim2.new(1, 0, 1, 0)
	Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Frame.BackgroundTransparency = 0.3
	Frame.BorderSizePixel = 0
	Frame.Parent = ScreenGui2

	local Frame2 = Instance.new("Frame")

	Frame2.Size = UDim2.new(0, 400, 0, 120)
	Frame2.Position = UDim2.new(0.5, -200, 0.1, 0)
	Frame2.BackgroundTransparency = 1
	Frame2.Parent = Frame
	Frame = Instance.new("TextLabel")
	Frame.Size = UDim2.new(1, 0, 0.4, 0)
	Frame.Position = UDim2.new(0, 0, 0.1, 0)
	Frame.BackgroundTransparency = 1
	Frame.Text = "Pulto Hub V1.6"
	Frame.TextColor3 = Color3.fromRGB(0, 150, 255)
	Frame.TextSize = 36
	Frame.Font = Enum.Font.GothamBold
	Frame.TextStrokeTransparency = 0.5
	Frame.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	Frame.TextXAlignment = Enum.TextXAlignment.Center
	Frame.Parent = Frame2

	local Frame3 = Instance.new("Frame")

	Frame3.Size = UDim2.new(0.8, 0, 0, 6)
	Frame3.Position = UDim2.new(0.1, 0, 0.7, 0)
	Frame3.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	Frame3.BorderSizePixel = 0
	Frame3.Parent = Frame2
	Frame2 = Instance.new("Frame")
	Frame2.Size = UDim2.new(0, 0, 1, 0)
	Frame2.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	Frame2.BorderSizePixel = 0
	Frame2.Parent = Frame3

	return Frame2, Frame
end
local v87 = CurrentCamera

local function v88()
	Text = Drawing.new("Text")
	Text.Visible = true
	Text.Size = 18
	Text.Color = Color3.fromRGB(0, 170, 255)
	Text.Center = false
	Text.Outline = true
	Text.OutlineColor = Color3.fromRGB(0, 0, 0)
	Text.Position = Vector2.new(20, v87.ViewportSize.Y / 2 - 100)
	Text.Text = "\240\159\140\140 | FPS: 0"
end

local function v90(p3)
	local ok, result = pcall(function()
		return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Replication"):WaitForChild("Fighter"):WaitForChild("SetControls")
	end)

	if not (ok and result) then
		return
	end

	result:FireServer("MouseKeyboard")
	task.wait(0.3)
	result:FireServer(p3)
end
local function createTextButton(p4, p5, p6, p7)
	local TextButton = Instance.new("TextButton")

	TextButton.Name = p4 .. "Btn"
	TextButton.Parent = p6
	TextButton.Size = UDim2.new(0.9, 0, 0, 35)
	TextButton.Position = UDim2.new(0.05, 0, 0, p7)
	TextButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	TextButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
	TextButton.BorderSizePixel = 2
	TextButton.Text = p4
	TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextButton.Font = Enum.Font.Gotham
	TextButton.TextSize = 14

	local UICorner = Instance.new("UICorner")

	UICorner.CornerRadius = UDim.new(0, 4)
	UICorner.Parent = TextButton
	UICorner = TextButton.MouseButton1Click

	local v96 = p5
	local v97 = TextButton

	UICorner:Connect(function()
		v90(v96)
		v97.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
		v97.BorderColor3 = Color3.fromRGB(0, 255, 0)
		task.wait(0.15)
		v97.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		v97.BorderColor3 = Color3.fromRGB(255, 255, 255)
	end)

	return TextButton
end

local v98 = CoreGui
local v99 = UserInputService
local v100 = LocalPlayer

local function v101()
	local t3 = {
		{
			["name"] = "Synapse X",
			["check"] = function()
				local syn_

				if type(syn) ~= "table" then
					syn_ = false
				else
					syn_ = syn.protect_gui ~= nil
				end

				return syn_
			end,
		},
		{
			["name"] = "ScriptWare",
			["check"] = function()
				return getgenv().SCRIPTWARE ~= nil
			end,
		},
		{
			["name"] = "Krnl",
			["check"] = function()
				return getgenv().KRNL ~= nil
			end,
		},
		{
			["name"] = "Comet",
			["check"] = function()
				return getgenv().COMET ~= nil
			end,
		},
		{
			["name"] = "SirHurt",
			["check"] = function()
				return type(is_sirhurt_closure) == "function"
			end,
		},
		{
			["name"] = "Calamari",
			["check"] = function()
				return getgenv().CALAMARI ~= nil
			end,
		},
		{
			["name"] = "Valyse",
			["check"] = function()
				return getgenv().VALYSE ~= nil
			end,
		},
		{
			["name"] = "Electron",
			["check"] = function()
				return getgenv().ELECTRON ~= nil
			end,
		},
		{
			["name"] = "Fluxus",
			["check"] = function()
				return getgenv().FLUXUS ~= nil
			end,
		},
		{
			["name"] = "Oxygen U",
			["check"] = function()
				return getgenv().OXYGENU ~= nil
			end,
		},
		{
			["name"] = "Delta",
			["check"] = function()
				return getgenv().DELTA ~= nil
			end,
		},
		{
			["name"] = "Solara",
			["check"] = function()
				return getgenv().SOLARA_LOADED ~= nil
			end,
		},
		{
			["name"] = "ProtoSmasher",
			["check"] = function()
				return getgenv().PROTOSMASHER_LOADED ~= nil
			end,
		},
		{
			["name"] = "Sentinel",
			["check"] = function()
				return getgenv().SENTINEL_LOADED ~= nil
			end,
		},
	}
	local result, v106

	t3, result, v106 = ipairs(t3)

	local t4 = {}
	local name, ok, result2

	while true do
		v106, name = t3(result, v106)

		if v106 == nil then
			break
		end

		ok, result2 = pcall(name.check)

		if ok and result2 then
			name = name.name
			table.insert(t4, name)
		end
	end

	t3 = {
		{
			["name"] = "Synapse X",
			["check"] = function()
				local syn_

				if type(syn) ~= "table" then
					syn_ = false
				else
					syn_ = syn.request ~= nil
				end

				return syn_
			end,
		},
		{
			["name"] = "Krnl",
			["check"] = function()
				return type(krnl) == "table"
			end,
		},
		{
			["name"] = "ScriptWare",
			["check"] = function()
				return type(identifyexecutor) == "function"
			end,
		},
		{
			["name"] = "Comet",
			["check"] = function()
				return type(getcomet) == "function"
			end,
		},
		{
			["name"] = "Calamari",
			["check"] = function()
				return type(calamari) == "table"
			end,
		},
		{
			["name"] = "Fluxus",
			["check"] = function()
				return type(fluxus) == "table"
			end,
		},
	}
	t3, result, v106 = ipairs(t3)

	while true do
		v106, name = t3(result, v106)

		if v106 == nil then
			break
		end

		ok, result2 = pcall(name.check)

		if ok and result2 then
			name = name.name
			table.insert(t4, name)
		end
	end

	t3 = identifyexecutor

	if type(identifyexecutor) == "function" then
		t3, result = pcall(identifyexecutor)

		if t3 and (result and type(result) == "string") then
			table.insert(t4, result)
		end
	end

	t3 = getexecutorname

	if type(getexecutorname) == "function" then
		t3, result = pcall(getexecutorname)

		if t3 and (result and type(result) == "string") then
			table.insert(t4, result)
		end
	end

	t3 = {
		{
			["name"] = "Roblox Script Environment",
			["check"] = function()
				local get_hidden_gui = _G.get_hidden_gui

				return type(get_hidden_gui) == "function"
			end,
		},
		{
			["name"] = "Studio",
			["check"] = function()
				return game:GetService("RunService"):IsStudio()
			end,
		},
		{
			["name"] = "Roblox Console",
			["check"] = function()
				return type(rconsoleprint) == "function"
			end,
		},
	}
	t3, result, v106 = ipairs(t3)

	while true do
		v106, name = t3(result, v106)

		if v106 == nil then
			break
		end

		ok, result2 = pcall(name.check)

		if ok and result2 then
			name = name.name
			table.insert(t4, name)
		end
	end

	t3 = pcall

	local v119 = t4

	pcall(function()
		if debug and debug.getinfo and debug.getinfo(1).source:find("@@") then
			v118 = v119
			table.insert(v119, "Protected Executor")
		end

		if type(writefile) ~= "function" then
			return
		end

		if type(readfile) ~= "function" or table.find(v119, "Unknown Executor") then
			return
		end
		table.insert(v119, "File Access Available")
	end)

	if #t4 <= 0 then
		return "Standard Lua Environment"
	else
		t3, result, v106 = ipairs(t4)
		t4 = {}

		while true do
			v106, name = t3(result, v106)

			if v106 == nil then
				break
			end

			if not table.find(t4, name) then
				table.insert(t4, name)
			end
		end

		if #t4 <= 1 then
			return t4[1]
		else
			return table.concat(t4, " + ")
		end

		return
	end
end

local v121 = t1
local v122 = t2

function CreateMainUI()
	ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "PultoHub"
	ScreenGui.Parent = v98

	local Frame = Instance.new("Frame")

	Frame.Size = UDim2.new(0, 480, 0, 480)
	Frame.Position = UDim2.new(0.5, -240, 0.5, -240)
	Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Frame.BackgroundTransparency = 0.05
	Frame.BorderSizePixel = 0
	Frame.ClipsDescendants = true
	Frame.Parent = ScreenGui

	local UICorner = Instance.new("UICorner")

	UICorner.CornerRadius = UDim.new(0, 8)
	UICorner.Parent = Frame
	UICorner = Instance.new("Frame")
	UICorner.Size = UDim2.new(1, 0, 0, 38)
	UICorner.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	UICorner.BackgroundTransparency = 0.05
	UICorner.BorderSizePixel = 0
	UICorner.Parent = Frame

	local UICorner2 = Instance.new("UICorner")

	UICorner2.CornerRadius = UDim.new(0, 8)
	UICorner2.Parent = UICorner
	UICorner2 = Instance.new("TextLabel")
	UICorner2.Size = UDim2.new(0, 180, 1, 0)
	UICorner2.Position = UDim2.new(0, 12, 0, 0)
	UICorner2.BackgroundTransparency = 1
	UICorner2.Text = "Pulto Hub V1.6"
	UICorner2.TextColor3 = Color3.fromRGB(0, 170, 255)
	UICorner2.TextSize = 18
	UICorner2.Font = Enum.Font.GothamBold
	UICorner2.TextXAlignment = Enum.TextXAlignment.Left
	UICorner2.Parent = UICorner
	UICorner2 = Instance.new("TextButton")
	UICorner2.Size = UDim2.new(0, 30, 0, 24)
	UICorner2.Position = UDim2.new(1, -36, 0.5, -12)
	UICorner2.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	UICorner2.BorderSizePixel = 0
	UICorner2.Text = "\226\156\149"
	UICorner2.TextColor3 = Color3.fromRGB(255, 255, 255)
	UICorner2.TextSize = 14
	UICorner2.Font = Enum.Font.GothamBold
	UICorner2.AutoButtonColor = false
	UICorner2.Parent = UICorner
	Instance.new("UICorner", UICorner2).CornerRadius = UDim.new(0, 5)

	local MouseEnter = UICorner2.MouseEnter
	local v127 = UICorner2

	MouseEnter:Connect(function()
		v127.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
	end)
	MouseEnter = UICorner2.MouseLeave

	local v128 = UICorner2

	MouseEnter:Connect(function()
		v128.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	end)
	MouseEnter = Instance.new("TextButton")
	MouseEnter.Size = UDim2.new(0, 30, 0, 24)
	MouseEnter.Position = UDim2.new(1, -72, 0.5, -12)
	MouseEnter.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	MouseEnter.BorderSizePixel = 0
	MouseEnter.Text = "\226\128\148"
	MouseEnter.TextColor3 = Color3.fromRGB(255, 255, 255)
	MouseEnter.TextSize = 14
	MouseEnter.Font = Enum.Font.GothamBold
	MouseEnter.AutoButtonColor = false
	MouseEnter.Parent = UICorner
	Instance.new("UICorner", MouseEnter).CornerRadius = UDim.new(0, 5)

	local MouseEnter2 = MouseEnter.MouseEnter
	local v130 = MouseEnter

	MouseEnter2:Connect(function()
		v130.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	end)
	MouseEnter2 = MouseEnter.MouseLeave

	local v131 = MouseEnter

	MouseEnter2:Connect(function()
		v131.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	end)
	MouseEnter2 = Instance.new("TextButton")
	MouseEnter2.Name = "PultoRestoreBtn"
	MouseEnter2.Size = UDim2.new(0, 90, 0, 36)
	MouseEnter2.Position = UDim2.new(1, -100, 0.5, -18)
	MouseEnter2.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
	MouseEnter2.BackgroundTransparency = 0.1
	MouseEnter2.BorderSizePixel = 2
	MouseEnter2.BorderColor3 = Color3.fromRGB(0, 170, 255)
	MouseEnter2.Text = "Pulto"
	MouseEnter2.TextColor3 = Color3.fromRGB(0, 170, 255)
	MouseEnter2.TextSize = 16
	MouseEnter2.Font = Enum.Font.GothamBold
	MouseEnter2.Visible = false
	MouseEnter2.ZIndex = 10
	MouseEnter2.Parent = ScreenGui
	Instance.new("UICorner", MouseEnter2).CornerRadius = UDim.new(0, 8)

	local InputBegan = UICorner.InputBegan
	local v133 = Frame

	InputBegan:Connect(function(p8)
		if p8.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		u42 = true
		Position = p8.Position
		Position2 = v133.Position
	end)
	UICorner.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		u42 = false
	end)
	UICorner = v99.InputChanged

	local v134 = Frame

	UICorner:Connect(function(p9)
		if not (u42 and p9.UserInputType == Enum.UserInputType.MouseMovement) then
			return
		end

		local v135 = p9.Position - Position

		v134.Position = UDim2.new(Position2.X.Scale, Position2.X.Offset + v135.X, Position2.Y.Scale, Position2.Y.Offset + v135.Y)
	end)
	UICorner = UICorner2.MouseButton1Click

	local v136 = MouseEnter2

	UICorner:Connect(function()
		u41 = false
		ScreenGui.Enabled = false
		v136.Visible = false

		if not MouseBehavior then
			return
		end

		v99.MouseBehavior = MouseBehavior
	end)
	UICorner = MouseEnter.MouseButton1Click

	local v137 = Frame
	local v138 = MouseEnter2

	UICorner:Connect(function()
		v137.Visible = false
		v138.Visible = true
	end)
	UICorner = MouseEnter2.MouseButton1Click

	local v139 = Frame
	local v140 = MouseEnter2

	UICorner:Connect(function()
		v139.Visible = true
		v140.Visible = false
	end)
	UICorner = Instance.new("Frame")
	UICorner.Size = UDim2.new(1, -20, 0, 80)
	UICorner.Position = UDim2.new(0, 10, 0, 45)
	UICorner.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	UICorner.BackgroundTransparency = 0.05
	UICorner.BorderColor3 = Color3.fromRGB(255, 255, 255)
	UICorner.BorderSizePixel = 1
	UICorner.Parent = Frame
	UICorner2 = Instance.new("UICorner")
	UICorner2.CornerRadius = UDim.new(0, 6)
	UICorner2.Parent = UICorner
	UICorner2 = Instance.new("ImageLabel")
	UICorner2.Size = UDim2.new(0, 55, 0, 55)
	UICorner2.Position = UDim2.new(0, 8, 0, 12)
	UICorner2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	UICorner2.BorderColor3 = Color3.fromRGB(255, 255, 255)
	UICorner2.BorderSizePixel = 1
	UICorner2.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. v100.UserId .. "&width=150&height=150&format=png"
	UICorner2.Parent = UICorner
	MouseEnter = Instance.new("UICorner")
	MouseEnter.CornerRadius = UDim.new(0, 6)
	MouseEnter.Parent = UICorner2
	UICorner2 = Instance.new("TextLabel")
	UICorner2.Size = UDim2.new(0, 220, 0, 20)
	UICorner2.Position = UDim2.new(0, 72, 0, 10)
	UICorner2.BackgroundTransparency = 1
	UICorner2.Text = v100.Name
	UICorner2.TextColor3 = Color3.fromRGB(0, 170, 255)
	UICorner2.TextSize = 18
	UICorner2.Font = Enum.Font.GothamBold
	UICorner2.TextXAlignment = Enum.TextXAlignment.Left
	UICorner2.Parent = UICorner
	UICorner2 = v101()
	MouseEnter = Instance.new("TextLabel")
	MouseEnter.Size = UDim2.new(0, 220, 0, 16)
	MouseEnter.Position = UDim2.new(0, 72, 0, 32)
	MouseEnter.BackgroundTransparency = 1
	MouseEnter.Text = "Executor: " .. UICorner2
	MouseEnter.TextColor3 = Color3.fromRGB(0, 200, 255)
	MouseEnter.TextSize = 12
	MouseEnter.Font = Enum.Font.GothamMedium
	MouseEnter.TextXAlignment = Enum.TextXAlignment.Left
	MouseEnter.Parent = UICorner
	UICorner2 = Instance.new("Frame")
	UICorner2.Size = UDim2.new(0, 220, 0, 20)
	UICorner2.Position = UDim2.new(0, 72, 0, 52)
	UICorner2.BackgroundTransparency = 1
	UICorner2.Parent = UICorner
	UICorner = Instance.new("Frame")
	UICorner.Size = UDim2.new(0, 10, 0, 10)
	UICorner.Position = UDim2.new(0, 0, 0.5, -5)
	UICorner.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	UICorner.BorderSizePixel = 0
	UICorner.Parent = UICorner2
	Instance.new("UICorner").CornerRadius = UDim.new(1, 0)
	Instance.new("UICorner").Parent = UICorner
	UICorner = Instance.new("TextLabel")
	UICorner.Size = UDim2.new(0, 210, 0, 20)
	UICorner.Position = UDim2.new(0, 15, 0, 0)
	UICorner.BackgroundTransparency = 1
	UICorner.Text = "Status: Online \226\128\162 Pulto Hub Active"
	UICorner.TextColor3 = Color3.fromRGB(0, 170, 255)
	UICorner.TextSize = 12
	UICorner.Font = Enum.Font.Gotham
	UICorner.TextXAlignment = Enum.TextXAlignment.Left
	UICorner.Parent = UICorner2
	UICorner = Instance.new("Frame")
	UICorner.Size = UDim2.new(1, -20, 0, 32)
	UICorner.Position = UDim2.new(0, 10, 0, 132)
	UICorner.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	UICorner.BackgroundTransparency = 0.05
	UICorner.BorderColor3 = Color3.fromRGB(255, 255, 255)
	UICorner.BorderSizePixel = 1
	UICorner.Parent = Frame
	UICorner2 = Instance.new("UICorner")
	UICorner2.CornerRadius = UDim.new(0, 6)
	UICorner2.Parent = UICorner
	UICorner2 = Instance.new("Frame")
	UICorner2.Size = UDim2.new(1, -20, 0, 300)
	UICorner2.Position = UDim2.new(0, 10, 0, 170)
	UICorner2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	UICorner2.BackgroundTransparency = 0.05
	UICorner2.BorderColor3 = Color3.fromRGB(255, 255, 255)
	UICorner2.BorderSizePixel = 1
	UICorner2.Parent = Frame
	Frame = Instance.new("UICorner")
	Frame.CornerRadius = UDim.new(0, 6)
	Frame.Parent = UICorner2
	Frame = {
		"Home",
		"Visuals",
		"Aim",
		"Misc",
		"Spoof",
	}
	MouseEnter = 1 / #Frame

	local v141

	MouseEnter2, InputBegan, v141 = ipairs(Frame)

	local t5 = {}

	while true do
		v141, v195 = MouseEnter2(InputBegan, v141)

		if v141 == nil then
			break
		end

		v196 = Instance.new("TextButton")
		v196.Size = UDim2.new(MouseEnter, -2, 1, -4)
		v196.Position = UDim2.new(MouseEnter * (v141 - 1), 1, 0, 2)
		v196.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		v196.BorderSizePixel = 0
		v196.Text = v195
		v196.TextColor3 = Color3.fromRGB(180, 180, 180)
		v196.TextSize = 13
		v196.Font = Enum.Font.GothamMedium
		v196.AutoButtonColor = false
		v196.Parent = UICorner
		v197 = Instance.new("UICorner")
		v197.CornerRadius = UDim.new(0, 4)
		v197.Parent = v196
		t5[v195] = v196
	end

	UICorner = function(p10, p11, p12, p13, p14)
		local Frame2 = Instance.new("Frame")

		Frame2.Size = UDim2.new(1, -16, 0, 28)
		Frame2.Position = UDim2.new(0, 8, 0, p11)
		Frame2.BackgroundTransparency = 1
		Frame2.Parent = p14

		local TextLabel = Instance.new("TextLabel")

		TextLabel.Size = UDim2.new(0, 200, 1, 0)
		TextLabel.BackgroundTransparency = 1
		TextLabel.Text = p10
		TextLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
		TextLabel.TextSize = 13
		TextLabel.Font = Enum.Font.Gotham
		TextLabel.TextXAlignment = Enum.TextXAlignment.Left
		TextLabel.Parent = Frame2
		TextLabel = Instance.new("TextButton")
		TextLabel.Size = UDim2.new(0, 44, 0, 18)
		TextLabel.Position = UDim2.new(1, -48, 0.5, -9)
		TextLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		TextLabel.BorderColor3 = v121[p12][p13] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100)
		TextLabel.BorderSizePixel = 2
		TextLabel.Text = ""
		TextLabel.AutoButtonColor = false
		TextLabel.Parent = Frame2
		Instance.new("UICorner").CornerRadius = UDim.new(1, 0)

		local UICorner3 = Instance.new("UICorner")

		UICorner3.CornerRadius = UDim.new(1, 0)
		UICorner3.Parent = TextLabel
		UICorner3 = Instance.new("Frame")
		UICorner3.Size = UDim2.new(0, 14, 0, 14)
		UICorner3.Position = v121[p12][p13] and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
		UICorner3.BackgroundColor3 = v121[p12][p13] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100)
		UICorner3.BorderSizePixel = 0
		UICorner3.Parent = TextLabel

		local UICorner4 = Instance.new("UICorner")

		UICorner4.CornerRadius = UDim.new(1, 0)
		UICorner4.Parent = UICorner3
		UICorner4 = TextLabel.MouseButton1Click

		local v147 = p12
		local v148 = p13

		UICorner4:Connect(function()
			v121[v147][v148] = not v121[v147][v148]

			if v121[v147][v148] then
				TextLabel.BorderColor3 = Color3.fromRGB(255, 255, 255)
				UICorner3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				UICorner3:TweenPosition(UDim2.new(1, -16, 0.5, -7), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
			else
				TextLabel.BorderColor3 = Color3.fromRGB(100, 100, 100)
				UICorner3.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				UICorner3:TweenPosition(UDim2.new(0, 2, 0.5, -7), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
			end

			pcall(function()
				game:GetService("DataStoreService"):GetDataStore("PultoHubConfig"):SetAsync(v100.UserId, v121)
			end)
		end)

		return Frame2
	end
	MouseEnter = function(p15, p16, p17, p18, p19, p20, p21)
		local Frame2 = Instance.new("Frame")

		Frame2.Size = UDim2.new(1, -16, 0, 40)
		Frame2.Position = UDim2.new(0, 8, 0, p16)
		Frame2.BackgroundTransparency = 1
		Frame2.Parent = p21

		local TextLabel = Instance.new("TextLabel")

		TextLabel.Size = UDim2.new(0, 200, 0, 18)
		TextLabel.BackgroundTransparency = 1
		TextLabel.Text = p15 .. ": " .. v121[p17][p18]
		TextLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
		TextLabel.TextSize = 13
		TextLabel.Font = Enum.Font.Gotham
		TextLabel.TextXAlignment = Enum.TextXAlignment.Left
		TextLabel.Parent = Frame2

		local Frame3 = Instance.new("Frame")

		Frame3.Size = UDim2.new(1, 0, 0, 5)
		Frame3.Position = UDim2.new(0, 0, 0, 26)
		Frame3.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		Frame3.BorderColor3 = Color3.fromRGB(255, 255, 255)
		Frame3.BorderSizePixel = 1
		Frame3.Parent = Frame2

		local UICorner3 = Instance.new("UICorner")

		UICorner3.CornerRadius = UDim.new(1, 0)
		UICorner3.Parent = Frame3

		local Frame4 = Instance.new("Frame")

		Frame4.Size = UDim2.new((v121[p17][p18] - p19) / (p20 - p19), 0, 1, 0)
		Frame4.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Frame4.BorderSizePixel = 0
		Frame4.Parent = Frame3
		UICorner3 = Instance.new("UICorner")
		UICorner3.CornerRadius = UDim.new(1, 0)
		UICorner3.Parent = Frame4

		local Frame5 = Instance.new("Frame")

		Frame5.Size = UDim2.new(0, 10, 0, 10)
		Frame5.Position = UDim2.new((v121[p17][p18] - p19) / (p20 - p19), -5, 0.5, -5)
		Frame5.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Frame5.BorderSizePixel = 0
		Frame5.Parent = Frame3
		UICorner3 = Instance.new("UICorner")
		UICorner3.CornerRadius = UDim.new(1, 0)
		UICorner3.Parent = Frame5

		local u155 = false

		Frame3.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end

			u155 = true
		end)
		Frame3.InputEnded:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end

			u155 = false
			pcall(function()
				game:GetService("DataStoreService"):GetDataStore("PultoHubConfig"):SetAsync(v100.UserId, v121)
			end)
		end)
		UICorner3 = v99.InputChanged

		local v156 = p17
		local v157 = p18
		local v158 = p15

		UICorner3:Connect(function(p22)
			if not (u155 and p22.UserInputType == Enum.UserInputType.MouseMovement) then
				return
			end

			local v159 = p19 + (p22.Position.X - Frame3.AbsolutePosition.X) / Frame3.AbsoluteSize.X * (p20 - p19)

			v159 = math.clamp(v159, p19, p20)
			v121[v156][v157] = v159
			Frame4.Size = UDim2.new((v159 - p19) / (p20 - p19), 0, 1, 0)
			Frame5.Position = UDim2.new((v159 - p19) / (p20 - p19), -5, 0.5, -5)
			TextLabel.Text = v158 .. ": " .. string.format("%.0f", v159)
		end)

		return Frame2
	end
	MouseEnter2 = function(p23, p24, p25, p26, p27, p28)
		local Frame2 = Instance.new("Frame")

		Frame2.Size = UDim2.new(1, -16, 0, 40)
		Frame2.Position = UDim2.new(0, 8, 0, p24)
		Frame2.BackgroundTransparency = 1
		Frame2.Parent = p28

		local TextLabel = Instance.new("TextLabel")

		TextLabel.Size = UDim2.new(0, 200, 0, 18)
		TextLabel.BackgroundTransparency = 1
		TextLabel.Text = p23 .. ": " .. v121[p25][p26]
		TextLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
		TextLabel.TextSize = 13
		TextLabel.Font = Enum.Font.Gotham
		TextLabel.TextXAlignment = Enum.TextXAlignment.Left
		TextLabel.Parent = Frame2

		local TextButton = Instance.new("TextButton")

		TextButton.Size = UDim2.new(0, 110, 0, 22)
		TextButton.Position = UDim2.new(0, 0, 0, 18)
		TextButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		TextButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
		TextButton.BorderSizePixel = 2
		TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		TextButton.TextSize = 13
		TextButton.Font = Enum.Font.Gotham
		TextButton.Text = v121[p25][p26]
		TextButton.Parent = Frame2

		local UICorner3 = Instance.new("UICorner")

		UICorner3.CornerRadius = UDim.new(0, 4)
		UICorner3.Parent = TextButton
		UICorner3 = TextButton.MouseButton1Click

		local v166 = p25
		local v167 = p26
		local v168 = p23

		UICorner3:Connect(function()
			local v169 = (table.find(p27, v121[v166][v167]) or 1) % #p27 + 1

			v121[v166][v167] = p27[v169]
			TextButton.Text = v121[v166][v167]
			TextLabel.Text = v168 .. ": " .. v121[v166][v167]
			pcall(function()
				game:GetService("DataStoreService"):GetDataStore("PultoHubConfig"):SetAsync(v100.UserId, v121)
			end)
		end)

		return Frame2
	end

	local v170 = UICorner2

	UICorner2 = function()
		local ScrollingFrame = Instance.new("ScrollingFrame")

		ScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
		ScrollingFrame.BackgroundTransparency = 1
		ScrollingFrame.ScrollBarThickness = 3
		ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 170, 255)
		ScrollingFrame.Visible = false
		ScrollingFrame.Parent = v170

		return ScrollingFrame
	end
	InputBegan = UICorner2()
	v141 = UICorner2()

	local v172 = UICorner2()
	local v173 = UICorner2()

	UICorner2 = UICorner2()
	InputBegan.Visible = true

	local n5 = 5
	local Frame2 = Instance.new("Frame")

	Frame2.Size = UDim2.new(1, -16, 0, 80)
	Frame2.Position = UDim2.new(0, 8, 0, 5)
	Frame2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Frame2.BackgroundTransparency = 0.05
	Frame2.BorderColor3 = Color3.fromRGB(255, 255, 255)
	Frame2.BorderSizePixel = 1
	Frame2.Parent = InputBegan

	local UICorner3 = Instance.new("UICorner")

	UICorner3.CornerRadius = UDim.new(0, 4)
	UICorner3.Parent = Frame2
	UICorner3 = Instance.new("TextLabel")
	UICorner3.Size = UDim2.new(1, 0, 0, 22)
	UICorner3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	UICorner3.Text = "Update Log"
	UICorner3.TextColor3 = Color3.fromRGB(0, 0, 0)
	UICorner3.TextSize = 14
	UICorner3.Font = Enum.Font.GothamBold
	UICorner3.Parent = Frame2

	local UICorner4 = Instance.new("UICorner")

	UICorner4.CornerRadius = UDim.new(0, 4)
	UICorner4.Parent = UICorner3
	UICorner3 = Instance.new("TextLabel")
	UICorner3.Size = UDim2.new(1, -8, 0, 55)
	UICorner3.Position = UDim2.new(0, 4, 0, 22)
	UICorner3.BackgroundTransparency = 1
	UICorner3.Text =
		"\226\128\162 Moved sidebar to top nav bar\n\226\128\162 Simplified Visuals tab\n\226\128\162 Added Health Bar ESP\n\226\128\162 Reduced GUI size"
	UICorner3.TextColor3 = Color3.fromRGB(0, 170, 255)
	UICorner3.TextSize = 11
	UICorner3.Font = Enum.Font.Gotham
	UICorner3.TextXAlignment = Enum.TextXAlignment.Left
	UICorner3.TextYAlignment = Enum.TextYAlignment.Top
	UICorner3.Parent = Frame2
	n5 = 90
	Frame2 = Instance.new("TextButton")
	Frame2.Size = UDim2.new(1, -16, 0, 30)
	Frame2.Position = UDim2.new(0, 8, 0, n5)
	Frame2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Frame2.BorderColor3 = Color3.fromRGB(255, 255, 255)
	Frame2.BorderSizePixel = 2
	Frame2.Text = "Save Current Config"
	Frame2.TextColor3 = Color3.fromRGB(255, 255, 255)
	Frame2.TextSize = 13
	Frame2.Font = Enum.Font.GothamBold
	Frame2.Parent = InputBegan
	UICorner3 = Instance.new("UICorner")
	UICorner3.CornerRadius = UDim.new(0, 4)
	UICorner3.Parent = Frame2
	UICorner3 = Frame2.MouseButton1Click

	local v178 = Frame2

	UICorner3:Connect(function()
		pcall(function()
			game:GetService("DataStoreService"):GetDataStore("PultoHubConfig"):SetAsync(v100.UserId, v121)
		end)
		v178.Text = "Config Saved!"
		task.wait(1)
		v178.Text = "Save Current Config"
	end)
	n5 = n5 + 38
	Frame2 = Instance.new("TextLabel")
	Frame2.Size = UDim2.new(1, -16, 0, 20)
	Frame2.Position = UDim2.new(0, 8, 0, n5)
	Frame2.BackgroundTransparency = 1
	Frame2.Text = "Config Preset"
	Frame2.TextColor3 = Color3.fromRGB(0, 170, 255)
	Frame2.TextSize = 13
	Frame2.Font = Enum.Font.Gotham
	Frame2.TextXAlignment = Enum.TextXAlignment.Left
	Frame2.Parent = InputBegan
	n5 = n5 + 22
	Frame2 = {
		"None",
		"Legit",
		"Rage",
		"Pulto",
		"Sky",
	}
	UICorner3 = Instance.new("TextButton")
	UICorner3.Size = UDim2.new(1, -16, 0, 30)
	UICorner3.Position = UDim2.new(0, 8, 0, n5)
	UICorner3.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	UICorner3.BorderColor3 = Color3.fromRGB(0, 170, 255)
	UICorner3.BorderSizePixel = 2
	UICorner3.Text = "\226\150\190  None"
	UICorner3.TextColor3 = Color3.fromRGB(0, 170, 255)
	UICorner3.TextSize = 13
	UICorner3.Font = Enum.Font.GothamMedium
	UICorner3.AutoButtonColor = false
	UICorner3.Parent = InputBegan
	Instance.new("UICorner", UICorner3).CornerRadius = UDim.new(0, 5)
	UICorner4 = Instance.new("Frame")
	UICorner4.Size = UDim2.new(1, -16, 0, #Frame2 * 28)
	UICorner4.Position = UDim2.new(0, 8, 0, n5 + 32)
	UICorner4.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	UICorner4.BorderColor3 = Color3.fromRGB(0, 170, 255)
	UICorner4.BorderSizePixel = 1
	UICorner4.Visible = false
	UICorner4.ZIndex = 5
	UICorner4.Parent = InputBegan
	Instance.new("UICorner", UICorner4).CornerRadius = UDim.new(0, 5)

	local v179, v180, v181 = ipairs(Frame2)
	local t6 = {}
	local s1
	local visible = false

	while true do
		local v185

		v181, v185 = v179(v180, v181)

		if v181 == nil then
			break
		end

		local TextButton = Instance.new("TextButton")

		TextButton.Size = UDim2.new(1, 0, 0, 28)
		TextButton.Position = UDim2.new(0, 0, 0, (v181 - 1) * 28)
		TextButton.BackgroundTransparency = 1
		TextButton.Text = v185
		TextButton.TextColor3 = Color3.fromRGB(200, 200, 200)
		TextButton.TextSize = 13
		TextButton.Font = Enum.Font.Gotham
		TextButton.AutoButtonColor = false
		TextButton.ZIndex = 6
		TextButton.Parent = UICorner4
		table.insert(t6, TextButton)

		local MouseEnter3 = TextButton.MouseEnter
		local v188 = TextButton

		MouseEnter3:Connect(function()
			v188.TextColor3 = Color3.fromRGB(0, 170, 255)
		end)
		MouseEnter3 = TextButton.MouseLeave

		local v189 = TextButton

		MouseEnter3:Connect(function()
			v189.TextColor3 = Color3.fromRGB(200, 200, 200)
		end)
		TextButton = TextButton.MouseButton1Click

		local v190 = v185
		local v191 = UICorner3
		local v192 = UICorner4

		TextButton:Connect(function()
			s1 = v190
			v191.Text = "\226\150\190  " .. v190
			v192.Visible = false
			visible = false

			if v190 == "None" then
				return
			end

			v122(v190)
		end)
	end

	UICorner3 = UICorner3.MouseButton1Click

	local v193 = UICorner4

	UICorner3:Connect(function()
		visible = not visible
		v193.Visible = visible
	end)
	n5 = n5 + 38 + #Frame2 * 28 + 8
	Frame2 = Instance.new("TextLabel")
	Frame2.Size = UDim2.new(1, -16, 0, 30)
	Frame2.Position = UDim2.new(0, 8, 0, n5)
	Frame2.BackgroundTransparency = 1
	Frame2.Text = "Made by Pulto"
	Frame2.TextColor3 = Color3.fromRGB(255, 255, 255)
	Frame2.TextSize = 16
	Frame2.Font = Enum.Font.GothamBold
	Frame2.TextXAlignment = Enum.TextXAlignment.Center
	Frame2.Parent = InputBegan
	InputBegan.CanvasSize = UDim2.new(0, 0, 0, n5 + 40)
	n5 = 5
	UICorner("Skeleton ESP", 5, "Visuals", "SkeletonESP", v141)
	n5 = 35
	UICorner("Box ESP", n5, "Visuals", "BoxESP", v141)
	n5 = n5 + 30
	UICorner("Line ESP", n5, "Visuals", "LineESP", v141)
	n5 = n5 + 30
	UICorner("Name ESP", n5, "Visuals", "NameESP", v141)
	n5 = n5 + 30
	UICorner("Health ESP", n5, "Visuals", "HealthESP", v141)
	n5 = n5 + 30
	UICorner("Health Bar", n5, "Visuals", "HealthBar", v141)
	n5 = n5 + 30
	UICorner("Wall Check", n5, "Visuals", "WallCheck", v141)
	n5 = n5 + 30
	UICorner("Level ESP", n5, "Visuals", "LevelESP", v141)
	n5 = n5 + 30
	UICorner("Distance ESP", n5, "Visuals", "DistanceESP", v141)
	n5 = n5 + 30
	MouseEnter("ESP Range", n5, "Visuals", "ESPRange", 100, 5000, v141)
	n5 = n5 + 42
	v141.CanvasSize = UDim2.new(0, 0, 0, n5 + 10)
	n5 = 5
	UICorner("Aimbot", 5, "Aim", "Enabled", v172)
	n5 = 35
	UICorner("Nearest Aim", n5, "Aim", "NearestAim", v172)
	n5 = n5 + 30
	UICorner("Lock On", n5, "Aim", "LockOn", v172)
	n5 = n5 + 30
	UICorner("Show FOV", n5, "Aim", "ShowFOV", v172)
	n5 = n5 + 30
	UICorner("Spin Bot", n5, "Aim", "SpinBot", v172)
	n5 = n5 + 30
	UICorner("Shoot on Contact", n5, "Aim", "ShootOnContact", v172)
	n5 = n5 + 30
	MouseEnter("FOV Size", n5, "Aim", "FOVSize", 20, 200, v172)
	n5 = n5 + 42
	MouseEnter("Aim Smoothing", n5, "Aim", "Smoothing", 0.1, 1, v172)
	n5 = n5 + 42
	MouseEnter2("Aim Target", n5, "Aim", "Target", { "Head", "Neck", "Chest" }, v172)
	n5 = n5 + 42
	UICorner("Anti Recoil", n5, "Aim", "AntiRecoil", v172)
	n5 = n5 + 30
	UICorner("Magic Bullet", n5, "Aim", "MagicBullet", v172)
	n5 = n5 + 30
	UICorner("Silent Bullet", n5, "Aim", "SilentBullet", v172)
	v172.CanvasSize = UDim2.new(0, 0, 0, n5 + 10)
	n5 = 5
	UICorner("TP to Nearest", 5, "Misc", "TPToNearest", v173)
	n5 = 35
	UICorner("Auto Play", n5, "Misc", "AutoPlay", v173)
	n5 = n5 + 30
	Frame2 = Instance.new("Frame")
	Frame2.Size = UDim2.new(1, -16, 0, 40)
	Frame2.Position = UDim2.new(0, 8, 0, n5)
	Frame2.BackgroundTransparency = 1
	Frame2.Parent = v173
	UICorner3 = Instance.new("TextLabel")
	UICorner3.Size = UDim2.new(0, 180, 0, 18)
	UICorner3.BackgroundTransparency = 1
	UICorner3.Text = "TP Hotkey: " .. v121.Misc.TPHotkey.Name
	UICorner3.TextColor3 = Color3.fromRGB(0, 170, 255)
	UICorner3.TextSize = 13
	UICorner3.Font = Enum.Font.Gotham
	UICorner3.TextXAlignment = Enum.TextXAlignment.Left
	UICorner3.Parent = Frame2
	UICorner4 = Instance.new("TextButton")
	UICorner4.Size = UDim2.new(0, 110, 0, 22)
	UICorner4.Position = UDim2.new(0, 0, 0, 18)
	UICorner4.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	UICorner4.BorderColor3 = Color3.fromRGB(255, 255, 255)
	UICorner4.BorderSizePixel = 2
	UICorner4.TextColor3 = Color3.fromRGB(255, 255, 255)
	UICorner4.Text = "Set Hotkey"
	UICorner4.TextSize = 13
	UICorner4.Font = Enum.Font.Gotham
	UICorner4.Parent = Frame2
	Frame2 = Instance.new("UICorner")
	Frame2.CornerRadius = UDim.new(0, 4)
	Frame2.Parent = UICorner4
	local u194

	Frame2 = UICorner4.MouseButton1Click

	local v198 = UICorner4

	Frame2:Connect(function()
		u194 = true
		v198.Text = "Press any key..."
		v198.BorderColor3 = Color3.fromRGB(0, 170, 255)
	end)
	n5 = n5 + 44
	MouseEnter("Change Speed", n5, "Misc", "Speed", 16, 100, v173)
	MouseEnter = n5 + 42
	UICorner("No Clip", MouseEnter, "Misc", "NoClip", v173)
	MouseEnter = MouseEnter + 30
	UICorner("Flying", MouseEnter, "Misc", "Flying", v173)
	MouseEnter = MouseEnter + 30
	UICorner("Infinite Jump", MouseEnter, "Misc", "InfiniteJump", v173)
	MouseEnter = MouseEnter + 30
	UICorner("Xray (75%)", MouseEnter, "Misc", "Xray", v173)
	MouseEnter = MouseEnter + 30
	MouseEnter2("Sky Changer", MouseEnter, "Misc", "Sky", {
		"Default",
		"Pink",
		"Sunset",
		"Starnight",
		"Galaxy",
	}, v173)
	MouseEnter = MouseEnter + 42
	UICorner("GodMode (Test)", MouseEnter, "Misc", "GodMode", v173)
	MouseEnter = MouseEnter + 30
	UICorner("Optimize", MouseEnter, "Misc", "Optimize", v173)
	v173.CanvasSize = UDim2.new(0, 0, 0, MouseEnter + 40)
	UICorner = Instance.new("TextLabel")
	UICorner.Size = UDim2.new(1, 0, 0, 34)
	UICorner.Position = UDim2.new(0, 0, 0, 5)
	UICorner.BackgroundTransparency = 1
	UICorner.Text = "Device Spoofing"
	UICorner.TextColor3 = Color3.fromRGB(0, 170, 255)
	UICorner.TextSize = 16
	UICorner.Font = Enum.Font.GothamBold
	UICorner.Parent = UICorner2
	createTextButton("Mouse & Keyboard", "MouseKeyboard", UICorner2, 42)
	createTextButton("Gamepad", "Gamepad", UICorner2, 82)
	createTextButton("Touch (Mobile)", "Touch", UICorner2, 122)
	createTextButton("VR", "VR", UICorner2, 162)
	UICorner = Instance.new("TextLabel")
	UICorner.Size = UDim2.new(1, -16, 0, 36)
	UICorner.Position = UDim2.new(0, 8, 0, 208)
	UICorner.BackgroundTransparency = 1
	UICorner.Text = "Changes your input device to trick the game"
	UICorner.TextColor3 = Color3.fromRGB(200, 200, 200)
	UICorner.TextSize = 11
	UICorner.Font = Enum.Font.Gotham
	UICorner.TextXAlignment = Enum.TextXAlignment.Center
	UICorner.Parent = UICorner2
	UICorner2.CanvasSize = UDim2.new(0, 0, 0, 260)

	local t7 = {
		["Home"] = InputBegan,
		["Visuals"] = v141,
		["Aim"] = v172,
		["Misc"] = v173,
		["Spoof"] = UICorner2,
	}
	local s2
	local v199 = Frame
	local v200 = t5

	UICorner = function(p29)
		local v201, v202, v203 = ipairs(v199)

		while true do
			local v204

			v203, v204 = v201(v202, v203)

			if v203 == nil then
				break
			end

			t7[v204].Visible = false
			v200[v204].TextColor3 = Color3.fromRGB(180, 180, 180)
			v200[v204].BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		end

		t7[p29].Visible = true
		v200[p29].TextColor3 = Color3.fromRGB(0, 170, 255)
		v200[p29].BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		s2 = p29
	end
	UICorner("Home")
	Frame, UICorner2, MouseEnter = ipairs(Frame)

	local v205 = false

	while true do
		MouseEnter, MouseEnter2 = Frame(UICorner2, MouseEnter)

		if MouseEnter == nil then
			break
		end

		InputBegan = t5[MouseEnter2].MouseButton1Click

		local v206 = UICorner
		local v207 = MouseEnter2

		InputBegan:Connect(function()
			v206(v207)
		end)
	end

	Frame = v99.InputBegan

	Frame:Connect(function(p30)
		if v205 then
			if p30.KeyCode == Enum.KeyCode.Unknown then
				return
			end

			return
		end

		if p30.KeyCode ~= v121.Misc.TPHotkey or not v121.Misc.TPToNearest then
			return
		end

		TeleportToNearestPlayer()
	end)
	u41 = true
	ScreenGui.Enabled = true
	MouseBehavior = v99.MouseBehavior
	v99.MouseBehavior = Enum.MouseBehavior.Default
end

local v210 = Lighting

function ChangeSky(p31)
	local Sky = v210
	local v211, v212

	Sky, v211, v212 = pairs(v210:GetChildren())

	while true do
		local v213

		v212, v213 = Sky(v211, v212)

		if v212 == nil then
			break
		end

		if v213:IsA("Sky") then
			v213:Destroy()
		end
	end

	if p31 == "Default" then
		return
	else
		Sky = Instance.new("Sky")

		if p31 == "Pink" then
			Sky.SkyboxBk = "http://www.roblox.com/asset/?id=271042516"
			Sky.SkyboxDn = "http://www.roblox.com/asset/?id=271077243"
			Sky.SkyboxFt = "http://www.roblox.com/asset/?id=271042556"
			Sky.SkyboxLf = "http://www.roblox.com/asset/?id=271042310"
			Sky.SkyboxRt = "http://www.roblox.com/asset/?id=271042467"
			Sky.SkyboxUp = "http://www.roblox.com/asset/?id=271077958"
		elseif p31 == "Sunset" then
			Sky.SkyboxBk = "http://www.roblox.com/asset/?id=626460377"
			Sky.SkyboxDn = "http://www.roblox.com/asset/?id=626460216"
			Sky.SkyboxFt = "http://www.roblox.com/asset/?id=626460513"
			Sky.SkyboxLf = "http://www.roblox.com/asset/?id=626460625"
			Sky.SkyboxRt = "http://www.roblox.com/asset/?id=626460750"
			Sky.SkyboxUp = "http://www.roblox.com/asset/?id=626460876"
		else
			if not (p31 == "Starnight" or p31 == "Galaxy") then
				Sky.Parent = v210

				return
			end

			Sky.SkyboxBk = "http://www.roblox.com/asset/?id=159454299"
			Sky.SkyboxDn = "http://www.roblox.com/asset/?id=159454296"
			Sky.SkyboxFt = "http://www.roblox.com/asset/?id=159454293"
			Sky.SkyboxLf = "http://www.roblox.com/asset/?id=159454286"
			Sky.SkyboxRt = "http://www.roblox.com/asset/?id=159454300"
			Sky.SkyboxUp = "http://www.roblox.com/asset/?id=159454288"
		end

		Sky.Parent = v210

		return
	end
end

local v214 = LocalPlayer
local v215 = Players
local v216 = t1

function TeleportToNearestPlayer()
	local Character = v214.Character

	if not Character then
		return
	end

	Character = Character:FindFirstChild("HumanoidRootPart")

	if not Character then
		return
	end

	local HumanoidRootPart = v215
	local v219, v220

	HumanoidRootPart, v219, v220 = pairs(v215:GetPlayers())

	local v221 = (1 / 0)
	local v222 = nil

	while true do
		local v223

		v220, v223 = HumanoidRootPart(v219, v220)

		if v220 == nil then
			break
		end

		if v223 ~= v214 then
			local v224

			if v216.Visuals.TeamCheck and (v223.Team and v214.Team) then
				v224 = v223.Team == v214.Team
			else
				v224 = false
			end

			if not v224 then
				v224 = v223.Character

				if v224 then
					v224 = v224:FindFirstChild("HumanoidRootPart")

					if v224 then
						v224 = (Character.Position - v224.Position).Magnitude

						if v224 < v221 then
							v222 = v223
							v221 = v224
						end
					end
				end
			end
		end
	end

	HumanoidRootPart = v222 and v222.Character and v222.Character:FindFirstChild("HumanoidRootPart")

	if not HumanoidRootPart then
		return
	end

	Character.CFrame = HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
end

local v225 = legit

function CreateESP(p32)
	if v225[p32] then
		return
	else
		local t8 = {
			["box"] = Drawing.new("Square"),
			["name"] = Drawing.new("Text"),
			["health"] = Drawing.new("Text"),
			["distance"] = Drawing.new("Text"),
			["line"] = Drawing.new("Line"),
			["healthBarBg"] = Drawing.new("Square"),
			["healthBarFill"] = Drawing.new("Square"),
			["skeleton"] = {
				["connections"] = {},
			},
		}

		t8.box.Visible = false
		t8.box.Thickness = 1
		t8.box.Filled = false
		t8.name.Visible = false
		t8.name.Size = 13
		t8.name.Center = true
		t8.name.Outline = true
		t8.health.Visible = false
		t8.health.Size = 13
		t8.health.Center = true
		t8.health.Outline = true
		t8.distance.Visible = false
		t8.distance.Size = 13
		t8.distance.Center = true
		t8.distance.Outline = true
		t8.line.Visible = false
		t8.line.Thickness = 1
		t8.healthBarBg.Visible = false
		t8.healthBarBg.Thickness = 1
		t8.healthBarBg.Filled = true
		t8.healthBarBg.Color = Color3.fromRGB(30, 30, 30)
		t8.healthBarFill.Visible = false
		t8.healthBarFill.Thickness = 1
		t8.healthBarFill.Filled = true
		t8.healthBarFill.Color = Color3.fromRGB(0, 255, 0)
		v225[p32] = t8

		return
	end
end
function UpdateSkeleton(p33, p34)
	local Character = p33.Character

	if Character then
		local v228, v229, v230 = pairs(p34.skeleton.connections)
		local t9 = {
			{ "Head", "UpperTorso" },
			{ "UpperTorso", "LowerTorso" },
			{ "UpperTorso", "LeftUpperArm" },
			{ "LeftUpperArm", "LeftLowerArm" },
			{ "LeftLowerArm", "LeftHand" },
			{ "UpperTorso", "RightUpperArm" },
			{ "RightUpperArm", "RightLowerArm" },
			{ "RightLowerArm", "RightHand" },
			{ "LowerTorso", "LeftUpperLeg" },
			{ "LeftUpperLeg", "LeftLowerLeg" },
			{ "LeftLowerLeg", "LeftFoot" },
			{ "LowerTorso", "RightUpperLeg" },
			{ "RightUpperLeg", "RightLowerLeg" },
			{ "RightLowerLeg", "RightFoot" },
		}
		local connections

		while true do
			v230, connections = v228(v229, v230)

			if v230 == nil then
				break
			end

			if connections then
				connections:Remove()
			end
		end

		p34.skeleton.connections = {}
		v228, v229, v230 = pairs(t9)

		while true do
			v230, t9 = v228(v229, v230)

			if v230 == nil then
				break
			end

			if Character:FindFirstChild(t9[1]) and Character:FindFirstChild(t9[2]) then
				t9 = Drawing.new("Line")
				t9.Thickness = 1
				t9.Color = Color3.fromRGB(255, 255, 255)
				t9.Visible = false
				connections = p34.skeleton.connections
				table.insert(connections, t9)
			end
		end

		return
	else
		return
	end
end

local v233 = legit
local v234 = t1
local v235 = LocalPlayer
local v236 = v70
local v237 = CurrentCamera

function UpdateESP()
	local v238, v239, v240 = pairs(v233)
	local visible = nil

	while true do
		local v242

		v240, v242 = v238(v239, v240)

		if v240 == nil then
			break
		end

		local Character = v240.Character
		local HumanoidRootPart, Humanoid

		if Character and (Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Humanoid")) then
			HumanoidRootPart = Character.HumanoidRootPart
			Humanoid = Character.Humanoid

			local color

			if v234.Visuals.TeamCheck and (v240.Team and v235.Team) then
				color = v240.Team == v235.Team
			else
				color = false
			end

			if color then
				v242.box.Visible = false
				v242.name.Visible = false
				v242.health.Visible = false
				v242.distance.Visible = false
				v242.line.Visible = false
				v242.healthBarBg.Visible = false
				v242.healthBarFill.Visible = false
				v242, Character, HumanoidRootPart = pairs(v242.skeleton.connections)

				while true do
					HumanoidRootPart, Humanoid = v242(Character, HumanoidRootPart)

					if HumanoidRootPart == nil then
						break
					end

					Humanoid.Visible = false
				end
			else
				color = v236(v240)

				if v234.Visuals.WallCheck then
					color = color and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
				else
					color = v240.Team and v240.Team.TeamColor.Color or Color3.fromRGB(255, 255, 255)
				end

				local v247, color3 = v237:WorldToViewportPoint(HumanoidRootPart.Position)

				HumanoidRootPart = (HumanoidRootPart.Position - v237.CFrame.Position).Magnitude

				if color3 and (Humanoid.Health > 0 and HumanoidRootPart <= v234.Visuals.ESPRange) then
					if v234.Visuals.BoxESP then
						v242.box.Visible = true
						v242.box.Color = color
						v242.box.Size = Vector2.new(80, 120)
						v242.box.Position = Vector2.new(v247.X - 40, v247.Y - 60)
					else
						v242.box.Visible = false
					end

					if v234.Visuals.NameESP then
						v242.name.Visible = true
						v242.name.Color = color
						v242.name.Text = v240.Name
						v242.name.Position = Vector2.new(v247.X, v247.Y - 70)
					else
						v242.name.Visible = false
					end

					local Health

					if v234.Visuals.HealthESP then
						v242.health.Visible = true
						color3 = Color3.fromRGB(0, 255, 0)

						if Humanoid.Health < Humanoid.MaxHealth * 0.5 then
							color3 = Color3.fromRGB(255, 255, 0)
						end

						if Humanoid.Health < Humanoid.MaxHealth * 0.25 then
							color3 = Color3.fromRGB(255, 0, 0)
						end

						v242.health.Color = color3
						color3 = v242.health
						Health = Humanoid.Health
						color3.Text = "HP: " .. math.floor(Health)
						v242.health.Position = Vector2.new(v247.X, v247.Y - 58)
					else
						v242.health.Visible = false
					end

					if v234.Visuals.HealthBar then
						Humanoid = Humanoid.Health / Humanoid.MaxHealth
						Humanoid = math.clamp(Humanoid, 0, 1)
						color3 = v247.X + 44
						Health = v247.Y - 30
						v242.healthBarBg.Visible = true
						v242.healthBarBg.Size = Vector2.new(4, 60)
						v242.healthBarBg.Position = Vector2.new(color3, Health)

						local v250 = 60 * Humanoid

						if Humanoid <= 0.5 then
							if Humanoid <= 0.25 then
								Humanoid = Color3.fromRGB(255, 0, 0)
							else
								Humanoid = Color3.fromRGB(255, 255, 0)
							end
						else
							Humanoid = Color3.fromRGB(0, 255, 0)
						end

						v242.healthBarFill.Visible = true
						v242.healthBarFill.Color = Humanoid
						v242.healthBarFill.Size = Vector2.new(4, v250)
						v242.healthBarFill.Position = Vector2.new(color3, Health + visible)
					else
						v242.healthBarBg.Visible = false
						v242.healthBarFill.Visible = false
					end

					if v234.Visuals.DistanceESP then
						v242.distance.Visible = true
						v242.distance.Color = color
						v242.distance.Text = math.floor(HumanoidRootPart) .. " studs"
						v242.distance.Position = Vector2.new(v247.X, v247.Y - 46)
					else
						v242.distance.Visible = false
					end

					if v234.Visuals.LineESP then
						v242.line.Visible = true
						v242.line.Color = color
						v242.line.From = Vector2.new(v237.ViewportSize.X / 2, v237.ViewportSize.Y)
						v242.line.To = Vector2.new(v247.X, v247.Y)
					else
						v242.line.Visible = false
					end

					if v234.Visuals.LevelESP then
						HumanoidRootPart = pcall

						local v251 = v240

						HumanoidRootPart, Humanoid = pcall(function()
							return v251.CustomLeaderstats.Level.Value
						end)

						if HumanoidRootPart and Humanoid ~= nil then
							HumanoidRootPart = tostring(Humanoid)
						else
							HumanoidRootPart = nil
						end

						if HumanoidRootPart then
							Humanoid = Vector2.new(v247.X, v247.Y - 84)

							if v242.rank then
								v242.rank.Text = "Lvl: " .. HumanoidRootPart
								v242.rank.Position = Humanoid
								v242.rank.Visible = true
							else
								HumanoidRootPart = Drawing.new("Text")
								HumanoidRootPart.Size = 11
								HumanoidRootPart.Center = true
								HumanoidRootPart.Outline = true
								HumanoidRootPart.Color = color
								HumanoidRootPart.Text = "Lvl: " .. HumanoidRootPart
								HumanoidRootPart.Position = Humanoid
								HumanoidRootPart.Visible = true
								v242.rank = HumanoidRootPart
							end
						end
					elseif v242.rank then
						v242.rank.Visible = false
					end

					if v234.Visuals.SkeletonESP then
						if #v242.skeleton.connections == 0 then
							UpdateSkeleton(v240, v242)
						end

						HumanoidRootPart = {}
						visible = { "LowerTorso", "LeftUpperLeg" }
						HumanoidRootPart[1] = { "Head", "UpperTorso" }
						HumanoidRootPart[2] = { "UpperTorso", "LowerTorso" }
						HumanoidRootPart[3] = { "UpperTorso", "LeftUpperArm" }
						HumanoidRootPart[4] = { "LeftUpperArm", "LeftLowerArm" }
						HumanoidRootPart[5] = { "LeftLowerArm", "LeftHand" }
						HumanoidRootPart[6] = { "UpperTorso", "RightUpperArm" }
						HumanoidRootPart[7] = { "RightUpperArm", "RightLowerArm" }
						HumanoidRootPart[8] = { "RightLowerArm", "RightHand" }
						HumanoidRootPart[9] = visible
						HumanoidRootPart[10] = { "LeftUpperLeg", "LeftLowerLeg" }
						HumanoidRootPart[11] = { "LeftLowerLeg", "LeftFoot" }
						HumanoidRootPart[12] = { "LowerTorso", "RightUpperLeg" }
						HumanoidRootPart[13] = { "RightUpperLeg", "RightLowerLeg" }
						HumanoidRootPart[14] = { "RightLowerLeg", "RightFoot" }
						HumanoidRootPart, Humanoid, v247 = pairs(HumanoidRootPart)

						while true do
							v247, color3 = HumanoidRootPart(Humanoid, v247)

							if v247 == nil then
								break
							end

							visible = Character:FindFirstChild(color3[1])
							color3 = Character:FindFirstChild(color3[2])

							if visible and (color3 and v242.skeleton.connections[v247]) then
								Health = v237:WorldToViewportPoint(visible.Position)
								visible = v237:WorldToViewportPoint(color3.Position)

								if Health.Z <= 0 or visible.Z <= 0 then
									v242.skeleton.connections[v247].Visible = false
								else
									v242.skeleton.connections[v247].Visible = true
									v242.skeleton.connections[v247].From = Vector2.new(Health.X, Health.Y)
									v242.skeleton.connections[v247].To = Vector2.new(visible.X, visible.Y)
									v242.skeleton.connections[v247].Color = color
								end
							else
								visible = v242.skeleton.connections

								if visible[v247] then
									visible = false
									v242.skeleton.connections[v247].Visible = false
								end
							end
						end
					else
						v242, Character, HumanoidRootPart = pairs(v242.skeleton.connections)

						while true do
							HumanoidRootPart, Humanoid = v242(Character, HumanoidRootPart)

							if HumanoidRootPart == nil then
								break
							end

							Humanoid.Visible = false
						end
					end
				else
					v242.box.Visible = false
					v242.name.Visible = false
					v242.health.Visible = false
					v242.distance.Visible = false
					v242.line.Visible = false
					v242.healthBarBg.Visible = false
					v242.healthBarFill.Visible = false

					if v242.rank then
						v242.rank.Visible = false
					end

					v242, Character, HumanoidRootPart = pairs(v242.skeleton.connections)

					while true do
						HumanoidRootPart, Humanoid = v242(Character, HumanoidRootPart)

						if HumanoidRootPart == nil then
							break
						end

						Humanoid.Visible = false
					end
				end
			end
		else
			v242.box.Visible = false
			v242.name.Visible = false
			v242.health.Visible = false
			v242.distance.Visible = false
			v242.line.Visible = false
			v242.healthBarBg.Visible = false
			v242.healthBarFill.Visible = false

			if v242.rank then
				v242.rank.Visible = false
			end

			v242, Character, HumanoidRootPart = pairs(v242.skeleton.connections)

			while true do
				HumanoidRootPart, Humanoid = v242(Character, HumanoidRootPart)

				if HumanoidRootPart == nil then
					break
				end

				Humanoid.Visible = false
			end
		end
	end
end

local v252 = legit

function RemoveESP(p35)
	if not v252[p35] then
		return
	end

	local v253 = v252[p35]

	v253.box:Remove()
	v253.name:Remove()
	v253.health:Remove()
	v253.distance:Remove()
	v253.line:Remove()
	v253.healthBarBg:Remove()
	v253.healthBarFill:Remove()

	if v253.rank then
		v253.rank:Remove()
	end

	local v254, v255

	v253, v254, v255 = pairs(v253.skeleton.connections)

	while true do
		local v256

		v255, v256 = v253(v254, v255)

		if v255 == nil then
			break
		end

		v256:Remove()
	end

	v252[p35] = nil
end

local v257 = t1
local v258 = CurrentCamera

function UpdateFOVCircle()
	if Circle or not v257.Aim.ShowFOV then
		if Circle and not v257.Aim.ShowFOV then
			Circle:Remove()
			Circle = nil

			return
		end
	else
		Circle = Drawing.new("Circle")
		Circle.Visible = true
		Circle.Thickness = 1
		Circle.Color = Color3.fromRGB(255, 0, 0)
		Circle.Filled = false
		Circle.NumSides = 64
	end

	if not Circle then
		return
	end

	Circle.Visible = v257.Aim.ShowFOV
	Circle.Radius = v257.Aim.FOVSize
	Circle.Position = Vector2.new(v258.ViewportSize.X / 2, v258.ViewportSize.Y / 2)
end

local v259 = t1

function ToggleSpinBot()
	if v259.Aim.SpinBot then
		if u57 then
			return
		end

		return
	end

	if not u57 then
		return
	end

	u57:Disconnect()
	u57 = nil
end

local v262 = t1

function ToggleShootOnContact()
	if v262.Aim.ShootOnContact then
		if u62 then
			return
		end

		return
	end

	if not u62 then
		return
	end

	u62:Disconnect()
	u62 = nil
end

local v266 = t1
local v267 = Lighting

function ToggleOptimize()
	if v266.Misc.Optimize then
		if u63 then
			return
		end

		return
	end

	if not u63 then
		v267.Brightness = v64 or 1
		v267.Ambient = v65 or Color3.fromRGB(0, 0, 0)
		v267.OutdoorAmbient = v66 or Color3.fromRGB(127, 127, 127)
		v267.GlobalShadows = true
		settings_().Rendering.QualityLevel = 3

		return
	end

	u63:Disconnect()
	u63 = nil
	v267.Brightness = v64 or 1
	v267.Ambient = v65 or Color3.fromRGB(0, 0, 0)
	v267.OutdoorAmbient = v66 or Color3.fromRGB(127, 127, 127)
	v267.GlobalShadows = true
	settings_().Rendering.QualityLevel = 3
end

local v269 = t1
local v270 = LocalPlayer
local v271 = Players
local v272 = CurrentCamera

function FindAimbotTarget()
	if not v269.Aim.Enabled then
		return nil
	end

	local Character = v270.Character

	if not Character then
		return nil
	end

	Character = Character:FindFirstChild("HumanoidRootPart")

	if not Character then
		return nil
	end

	if v269.Aim.LockOn and u53 then
		v304 = u53.Character

		if v304 and (v304:FindFirstChild("Humanoid") and v304.Humanoid.Health > 0) then
			v304 = u53

			if v269.Visuals.TeamCheck and (u53.Team and v270.Team) then
				v304 = u53.Team == v270.Team
			else
				v304 = false
			end

			if not v304 then
				return u53
			end

			u53 = nil
		else
			u53 = nil
		end
	end

	local v274 = v271
	local v275, v276

	v274, v275, v276 = pairs(v271:GetPlayers())

	local v277 = (1 / 0)
	local v278 = nil

	while true do
		local v279

		v276, v279 = v274(v275, v276)

		if v276 == nil then
			break
		end

		if v279 ~= v270 then
			local v280

			if v269.Visuals.TeamCheck and (v279.Team and v270.Team) then
				v280 = v279.Team == v270.Team
			else
				v280 = false
			end

			if not v280 then
				v280 = v279.Character

				if v280 and (v280:FindFirstChild("Humanoid") and v280.Humanoid.Health > 0) then
					local HumanoidRootPart = v280:FindFirstChild("HumanoidRootPart")

					v280 = v280:FindFirstChild(v269.Aim.Target) or (HumanoidRootPart or false)

					if v280 then
						HumanoidRootPart = (Character.Position - v280.Position).Magnitude

						if HumanoidRootPart <= v269.Visuals.ESPRange then
							local v282 = true

							if v269.Aim.ShowFOV then
								v280 = v272:WorldToViewportPoint(v280.Position)

								if
									(Vector2.new(v272.ViewportSize.X / 2, v272.ViewportSize.Y / 2) - Vector2.new(v280.X, v280.Y)).Magnitude > v269.Aim.FOVSize
								then
									v282 = false
								end
							end

							if v282 then
								if HumanoidRootPart < v277 then
									v278 = v279
									v277 = HumanoidRootPart
								end
							end
						end
					end
				end
			end
		end
	end

	if not (v269.Aim.LockOn and v278) then
		return v278
	end

	u53 = v278

	return v278
end

local v283 = t1
local v284 = LocalPlayer
local v285 = Workspace
local v286 = mousemoverel_

function ApplyAimbot()
	if not (v283.Aim.Enabled and u47) then
		return
	end

	if not v284.Character then
		return
	end

	local Character = u47.Character

	if not Character then
		return
	end

	local HumanoidRootPart = Character:FindFirstChild(v283.Aim.Target) or Character:FindFirstChild("HumanoidRootPart")

	if not HumanoidRootPart then
		return
	end

	local CurrentCamera2 = v285.CurrentCamera
	local mouse = v284:GetMouse()

	HumanoidRootPart = CurrentCamera2:WorldToScreenPoint(HumanoidRootPart.Position)
	mouse = Vector2.new(mouse.X, mouse.Y)
	HumanoidRootPart = mouse:Lerp(Vector2.new(HumanoidRootPart.X, HumanoidRootPart.Y), v283.Aim.Smoothing)

	if not v283.Aim.NearestAim then
		v286(HumanoidRootPart.X - mouse.X, HumanoidRootPart.Y - mouse.Y)

		return
	end

	local v291, v292, v293 = pairs({
		"Head",
		"Neck",
		"UpperTorso",
		"LowerTorso",
	})
	local v294 = (1 / 0)
	local v295 = nil

	while true do
		local v296

		v293, v296 = v291(v292, v293)

		if v293 == nil then
			break
		end

		HumanoidRootPart = Character:FindFirstChild(v296)

		if HumanoidRootPart then
			mouse = CurrentCamera2:WorldToScreenPoint(HumanoidRootPart.Position)
			mouse = (Vector2.new(mouse.X, mouse.Y) - mouse).Magnitude

			if mouse < v294 then
				v295 = HumanoidRootPart
				v294 = mouse
			end
		end
	end

	if not v295 then
		v286(HumanoidRootPart.X - mouse.X, HumanoidRootPart.Y - mouse.Y)

		return
	end

	Character = CurrentCamera2:WorldToScreenPoint(v295.Position)
	HumanoidRootPart = mouse:Lerp(Vector2.new(Character.X, Character.Y), v283.Aim.Smoothing)
	v286(HumanoidRootPart.X - mouse.X, HumanoidRootPart.Y - mouse.Y)
end

function StartAutoPlay()
	if u51 then
		return
	end
end
function StopAutoPlay()
	u51 = false

	if not u52 then
		return
	end

	u52:Disconnect()
	u52 = nil
end

local v306 = t1
local v307 = LocalPlayer

function ToggleFlying()
	if v306.Misc.Flying then
		if u54 then
			return
		else
			v340 = v307.Character

			if not v340 then
				return
			end

			return
		end

		return
	end

	if u54 then
		u54:Disconnect()
		u54 = nil
	end

	local Character = v307.Character

	Character = Character and Character:FindFirstChild("Humanoid")

	if not Character then
		return
	end

	Character.PlatformStand = false
end

local v311 = t1

function ToggleInfiniteJump()
	if v311.Misc.InfiniteJump then
		if u55 then
			return
		end

		return
	end

	if not u55 then
		return
	end

	u55:Disconnect()
	u55 = nil
end

local v314 = t1

function ToggleXray()
	if v314.Misc.Xray then
		if u56 then
			return
		end

		return
	end

	if not u56 then
		return
	end

	u56:Disconnect()
	u56 = nil
end

local v318 = LocalPlayer
local v319 = t1

function UpdateSpeed()
	local Character = v318.Character

	if not Character then
		return
	end

	Character = Character:FindFirstChild("Humanoid")

	if not (Character and Character.WalkSpeed ~= v319.Misc.Speed) then
		return
	end

	Character.WalkSpeed = v319.Misc.Speed
end

local v321 = t1

function ToggleNoClip()
	if v321.Misc.NoClip then
		if u48 then
			return
		end

		return
	end

	if not u48 then
		return
	end

	u48:Disconnect()
	u48 = nil
end

local v324 = t1
local v325 = LocalPlayer

function ApplyGodMode()
	if not v324.Misc.GodMode then
		return
	end

	local Character = v325.Character

	Character = Character and Character:FindFirstChild("Humanoid")

	if not Character then
		return
	end

	Character.MaxHealth = (1 / 0)
	Character.Health = (1 / 0)
end

Workspace = RunService.RenderStepped

local v327 = CurrentCamera
local v328 = t1
local v329 = legit
local v330 = UserInputService

Workspace:Connect(function()
	n3 = n3 + 1

	local now = tick()

	if now - n2 >= 1 then
		n4 = n3
		n3 = 0
		n2 = now
	end

	if Text then
		Text.Position = Vector2.new(20, v327.ViewportSize.Y / 2 - 100)
		Text.Text = "\240\159\140\140 | FPS: " .. n4
	end

	if
		v328.Visuals.SkeletonESP
		or (
			v328.Visuals.BoxESP
			or (
				v328.Visuals.NameESP
				or (v328.Visuals.HealthESP or (v328.Visuals.HealthBar or (v328.Visuals.DistanceESP or (v328.Visuals.LineESP or v328.Visuals.LevelESP))))
			)
		)
	then
		UpdateESP()
	else
		local v332, v333

		now, v332, v333 = pairs(v329)

		while true do
			local v334

			v333, v334 = now(v332, v333)

			if v333 == nil then
				break
			end

			v334.box.Visible = false
			v334.name.Visible = false
			v334.health.Visible = false
			v334.distance.Visible = false
			v334.line.Visible = false
			v334.healthBarBg.Visible = false
			v334.healthBarFill.Visible = false

			if v334.rank then
				v334.rank.Visible = false
			end

			local v335, v336

			v334, v335, v336 = pairs(v334.skeleton.connections)

			while true do
				local v337

				v336, v337 = v334(v335, v336)

				if v336 == nil then
					break
				end

				v337.Visible = false
			end
		end
	end

	UpdateFOVCircle()
	u47 = FindAimbotTarget()

	if v330:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or v328.Aim.NearestAim then
		ApplyAimbot()
	end

	if v328.Misc.AutoPlay and not u51 then
		StartAutoPlay()
	elseif not v328.Misc.AutoPlay and u51 then
		StopAutoPlay()
	end

	if v328.Misc.Sky and v328.Misc.Sky ~= "Default" then
		ChangeSky(v328.Misc.Sky)
	end

	UpdateSpeed()
	ToggleNoClip()

	if not v328.Misc.GodMode then
		ToggleFlying()
		ToggleInfiniteJump()
		ToggleXray()
		ToggleSpinBot()
		ToggleShootOnContact()
		ToggleOptimize()

		return
	end

	ApplyGodMode()
	ToggleFlying()
	ToggleInfiniteJump()
	ToggleXray()
	ToggleSpinBot()
	ToggleShootOnContact()
	ToggleOptimize()
end)
Players.PlayerAdded:Connect(function(player)
	task.wait(1)
	CreateESP(player)
end)
Players.PlayerRemoving:Connect(function(player)
	RemoveESP(player)

	if u53 ~= player then
		return
	end

	u53 = nil
end)
Players, Workspace, Lighting = pairs(Players:GetPlayers())

local v338 = MouseBehavior
local v339 = ScreenGui
local enabled = u41
local v341 = ScreenGui2

while true do
	Lighting, CoreGui = Players(Workspace, Lighting)

	if Lighting == nil then
		break
	end

	if CoreGui ~= LocalPlayer then
		CreateESP(CoreGui)
	end
end

LocalPlayer.CharacterAdded:Connect(function(character)
	task.wait(1)

	local Humanoid = character:FindFirstChild("Humanoid")

	if not Humanoid then
		return
	end

	n1 = Humanoid.WalkSpeed
end)
Players = UserInputService.InputBegan

local v343 = UserInputService

Players:Connect(function(p36)
	if p36.KeyCode ~= Enum.KeyCode.Insert then
		return
	end

	enabled = not enabled

	if v339 then
		v339.Enabled = enabled
	end

	if enabled then
		v343.MouseBehavior = Enum.MouseBehavior.Default

		return
	end

	v343.MouseBehavior = v338
end)
v88()
Players, UserInputService = v80()
Workspace = task.spawn

local v344 = Players
local v345 = UserInputService
local v346 = RunService
local v347 = v17

Workspace(function()
	local now = tick()

	while tick() - now < 2.5 do
		local v349 = (tick() - now) / 2.5

		v344.Size = UDim2.new(v349, 0, 1, 0)
		v349 = 0.6 + v349 * 0.1
		v345.TextColor3 = Color3.fromHSV(v349, 0.8, 1)
		v346.RenderStepped:Wait()
	end

	v347()
	v341:Destroy()
	CreateMainUI()
end)
print("Pulto Hub loaded Press Ins to Open/Close")
