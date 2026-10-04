local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local enabled = false
local target = nil

local FOV = 250
local SMOOTHNESS = 0.2

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "AimAssist"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(150, 42)
button.Position = UDim2.new(0, 20, 0.5, -21)
button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
button.TextColor3 = Color3.new(1, 1, 1)
button.Text = "Aimbot: OFF"
button.TextSize = 16
button.Font = Enum.Font.GothamBold
button.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 9)
corner.Parent = button

local function validTarget(plr)
	if plr == player then return false end

	local char = plr.Character
	if not char then return false end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local head = char:FindFirstChild("Head")

	return humanoid
		and humanoid.Health > 0
		and head ~= nil
end

local function getTarget()
	local best = nil
	local bestDistance = FOV

	local center = Vector2.new(
		camera.ViewportSize.X / 2,
		camera.ViewportSize.Y / 2
	)

	for _, plr in ipairs(Players:GetPlayers()) do
		if validTarget(plr) then
			local head = plr.Character.Head

			local position, visible =
				camera:WorldToViewportPoint(head.Position)

			if visible and position.Z > 0 then
				local screenPosition =
					Vector2.new(position.X, position.Y)

				local distance =
					(screenPosition - center).Magnitude

				if distance < bestDistance then
					bestDistance = distance
					best = plr
				end
			end
		end
	end

	return best
end

button.Activated:Connect(function()
	enabled = not enabled

	if enabled then
		button.Text = "Aimbot: ON"
		button.BackgroundColor3 = Color3.fromRGB(40, 150, 75)
	else
		button.Text = "Aimbot: OFF"
		button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		target = nil
	end
end)

RunService:BindToRenderStep(
	"AimAssist",
	Enum.RenderPriority.Camera.Value + 1,
	function()
		if not enabled then return end

		if not target or not validTarget(target) then
			target = getTarget()
		end

		if target and validTarget(target) then
			local head = target.Character.Head

			local desired =
				CFrame.lookAt(
					camera.CFrame.Position,
					head.Position
				)

			camera.CFrame =
				camera.CFrame:Lerp(
					desired,
					SMOOTHNESS
				)
		end
	end
)