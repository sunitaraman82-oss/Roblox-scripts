
local Players = game:GetService("Players")
local player = Players.LocalPlayer

print("[TargetLock] Script started")

local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then
    warn("[TargetLock] PlayerGui was not found")
    return
end

local gui = Instance.new("ScreenGui")
gui.Name = "TargetLockDiagnostic"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local button = Instance.new("TextButton")
button.Name = "TestToggle"
button.Size = UDim2.fromOffset(220, 50)
button.Position = UDim2.new(0, 20, 0, 100)
button.BackgroundColor3 = Color3.fromRGB(30, 145, 85)
button.TextColor3 = Color3.new(1, 1, 1)
button.TextSize = 18
button.Text = "Target Lock: OFF"
button.Visible = true
button.Parent = gui

button.Activated:Connect(function()
    local isOn = button.Text:find("OFF") ~= nil
    button.Text = isOn and "Target Lock: ON" or "Target Lock: OFF"
    print("[TargetLock] Toggle:", isOn and "ON" or "OFF")
end)

print("[TargetLock] Diagnostic GUI created")
