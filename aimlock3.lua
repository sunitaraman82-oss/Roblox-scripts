
local Players = game:GetService("Players")
local player = Players.LocalPlayer

print("TEST 1: LocalScript started")

local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "SimpleTestGui"
gui.Parent = playerGui

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 200, 0, 50)
button.Position = UDim2.new(0, 20, 0, 100)
button.Text = "LOCK: OFF"
button.Visible = true
button.Parent = gui

print("TEST 2: Button created")

button.Activated:Connect(function()
    if button.Text == "LOCK: OFF" then
        button.Text = "LOCK: ON"
    else
        button.Text = "LOCK: OFF"
    end
end)
