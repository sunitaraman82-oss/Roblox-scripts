-- Boot up the Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu'))()

-- Create the Main Window
local Window = Rayfield:CreateWindow({
   Name = "Private Test Environment Admin UI",
   LoadingTitle = "Loading UI...",
   LoadingSubtitle = "by AI Assistant",
   ConfigurationSaving = {
      Enabled = false
   },
   KeySystem = false
})

-- Configuration States (Variables to store user inputs)
local ScriptSettings = {
    ToggleActive = false,
    FOVValue = 70,
    SmoothnessValue = 1,
    TargetLockActive = false
}

-- Create a Main Tab
local MainTab = Window:CreateTab("Main Features", 4483362458) -- Code is a default icon ID

-- 1. Main Toggle Button
local MainToggle = MainTab:CreateToggle({
   Name = "Enable Main Script Function",
   CurrentValue = false,
   Flag = "MainToggleFlag",
   Callback = function(Value)
      ScriptSettings.ToggleActive = Value
      print("Main script active status: ", ScriptSettings.ToggleActive)
      -- Insert your primary custom script logic here
   end,
})

-- 2. FOV (Field of View) Slider
local FOVSlider = MainTab:CreateSlider({
   Name = "Field of View (FOV)",
   Min = 30,
   Max = 120,
   CurrentValue = 70,
   Flag = "FOVSliderFlag",
   Callback = function(Value)
      ScriptSettings.FOVValue = Value
      -- Dynamically changes the local player's camera FOV
      workspace.CurrentCamera.FieldOfView = Value
   end,
})

-- 3. Smoothness Slider for Aim
local SmoothnessSlider = MainTab:CreateSlider({
   Name = "Aim Smoothness",
   Min = 1,
   Max = 10,
   CurrentValue = 1,
   Flag = "SmoothnessSliderFlag",
   Callback = function(Value)
      ScriptSettings.SmoothnessValue = Value
      print("Aim Smoothness set to: ", ScriptSettings.SmoothnessValue)
      -- Use this variable inside your Lerp or Tween aim logic
   end,
})

-- 4. Target Lock Toggle
local TargetLockToggle = MainTab:CreateToggle({
   Name = "Target Lock",
   CurrentValue = false,
   Flag = "TargetLockFlag",
   Callback = function(Value)
      ScriptSettings.TargetLockActive = Value
      print("Target Lock status: ", ScriptSettings.TargetLockActive)
      -- Insert your target locking or camera tracking loop here
   end,
})

-- Send a clean notification when fully loaded
Rayfield:Notify({
   Title = "UI Loaded Successfully",
   Content = "Ready for private testing environment execution.",
   Duration = 5,
   Image = 4483362458,
})
