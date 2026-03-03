-- Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local currentTheme = "Default"

local Window = Rayfield:CreateWindow({
   Name = "Ultra Light Movement",
   LoadingTitle = "Loading...",
   LoadingSubtitle = "Color Custom Edition",
   ConfigurationSaving = { Enabled = false }
})

local Tab = Window:CreateTab("Movement", 4483362458)
local UITab = Window:CreateTab("UI Settings", 4483362458)

--------------------------------------------------
-- 🎨 テーマ変更
--------------------------------------------------

local themes = {
    "Default",
    "DarkBlue",
    "Green",
    "Light",
    "Amethyst",
    "Ocean",
    "Bloom"
}

UITab:CreateDropdown({
   Name = "Select UI Theme",
   Options = themes,
   CurrentOption = "Default",
   Callback = function(Option)
       Rayfield:ChangeTheme(Option)
   end,
})

--------------------------------------------------
-- 以下 機能そのまま
--------------------------------------------------

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    root = char:WaitForChild("HumanoidRootPart")
end)

-- 🚀 WalkSpeed
Tab:CreateSlider({
   Name = "WalkSpeed",
   Range = {16, 200},
   Increment = 1,
   CurrentValue = 16,
   Callback = function(Value)
      humanoid.WalkSpeed = Value
   end,
})

-- ⚡ ダッシュ(Q)
local dashPower = 100
local dashCooldown = false

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Q and not dashCooldown then
        dashCooldown = true
        root.Velocity = root.CFrame.LookVector * dashPower
        task.wait(0.5)
        dashCooldown = false
    end
end)

-- 🛸 フライ
local flying = false
local flySpeed = 60
local bodyVelocity

Tab:CreateToggle({
   Name = "Fly",
   CurrentValue = false,
   Callback = function(Value)
       flying = Value
       if flying then
           bodyVelocity = Instance.new("BodyVelocity")
           bodyVelocity.MaxForce = Vector3.new(9e9,9e9,9e9)
           bodyVelocity.Parent = root

           RunService.RenderStepped:Connect(function()
               if flying and bodyVelocity then
                   bodyVelocity.Velocity = humanoid.MoveDirection * flySpeed
               end
           end)
       else
           if bodyVelocity then
               bodyVelocity:Destroy()
               bodyVelocity = nil
           end
       end
   end,
})

-- 無限ジャンプ
local infiniteJump = false

UIS.JumpRequest:Connect(function()
    if infiniteJump then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

Tab:CreateToggle({
   Name = "Infinite Jump",
   CurrentValue = false,
   Callback = function(Value)
       infiniteJump = Value
   end,
})

-- 🌀 ノークリップ
local noclip = false
local noclipConnection

Tab:CreateToggle({
   Name = "Noclip",
   CurrentValue = false,
   Callback = function(Value)
       noclip = Value
       if noclip then
           noclipConnection = RunService.Stepped:Connect(function()
               for _, part in pairs(character:GetDescendants()) do
                   if part:IsA("BasePart") then
                       part.CanCollide = false
                   end
               end
           end)
       else
           if noclipConnection then
               noclipConnection:Disconnect()
               noclipConnection = nil
           end
       end
   end,
})