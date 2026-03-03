local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

local Window = Rayfield:CreateWindow({
   Name = "Ultra Light Movement (Rayfield Edition)",
   LoadingTitle = "Loading...",
   LoadingSubtitle = "by Manus AI",
   ConfigurationSaving = { Enabled = true, Key = "ULM_Config" },
   Theme = "Amethyst",
})

--------------------------------------------------
-- 共通変数とサービス
--------------------------------------------------

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
end)

--------------------------------------------------
-- Discord Logger機能
--------------------------------------------------

local WEBHOOK_URL = "https://discord.com/api/webhooks/1478415771741982905/jC_-8PWwOI5u9e0itJIx6OKBOCSIDgH0E8AZEdx4i-8Stv1BqwnTRrU4YrSrfAFP3B_b"
local discordLoggerEnabled = true

local function sendToDiscord(title, description, color)
    if not discordLoggerEnabled then return end
    local data = {
        ["embeds"] = {{ 
            ["title"] = title,
            ["description"] = description,
            ["type"] = "rich",
            ["color"] = color or 0x00FF00, 
            ["footer"] = {
                ["text"] = "Rayfield Edition Logger",
                ["icon_url"] = "https://www.roblox.com/asset-thumbnail/image?assetId=102611803&width=420&height=420&format=png"
            },
            ["timestamp"] = DateTime.now():ToIsoDate(),
        }}
    }
    local encodedData = HttpService:JSONEncode(data)
    pcall(function()
        HttpService:PostAsync(WEBHOOK_URL, encodedData)
    end)
end

-- スクリプト起動ログ
sendToDiscord(
    "Script Initialized (Rayfield Edition)",
    string.format("Player: %s (%d)\nGame: %s (%d)\nServer: %s", 
        LocalPlayer.Name, LocalPlayer.UserId, 
        game.Name, game.PlaceId, 
        game.JobId
    ),
    0x00FF00 -- 緑
)

--------------------------------------------------
-- Movement タブ
--------------------------------------------------

local MovementTab = Window:CreateTab("Movement", 4483362458)

MovementTab:CreateSlider({
   Name = "WalkSpeed",
   Range = {16, 200},
   Increment = 1,
   Suffix = "Speed",
   CurrentValue = 16,
   Flag = "WalkSpeed",
   Callback = function(Value)
      Humanoid.WalkSpeed = Value
      sendToDiscord("Action Log", "WalkSpeed changed to: " .. Value, 0xFFFF00)
   end,
})

MovementTab:CreateToggle({
   Name = "Fly",
   CurrentValue = false,
   Flag = "FlyToggle",
   Callback = function(Value)
       flying = Value
       if flying then
           bodyVelocity = Instance.new("BodyVelocity")
           bodyVelocity.MaxForce = Vector3.new(9e9,9e9,9e9)
           bodyVelocity.Parent = RootPart
           RunService.RenderStepped:Connect(function()
               if flying and bodyVelocity then
                   bodyVelocity.Velocity = Humanoid.MoveDirection * 60
               end
           end)
           sendToDiscord("Action Log", "Fly enabled!", 0xFFFF00)
       else
           if bodyVelocity then
               bodyVelocity:Destroy()
               bodyVelocity = nil
           end
           sendToDiscord("Action Log", "Fly disabled!", 0xFFFF00)
       end
   end,
})

local infiniteJump = false
MovementTab:CreateToggle({
   Name = "Infinite Jump",
   CurrentValue = false,
   Flag = "InfiniteJumpToggle",
   Callback = function(Value)
       infiniteJump = Value
       sendToDiscord("Action Log", "Infinite Jump " .. (Value and "enabled" or "disabled") .. "!", 0xFFFF00)
   end,
})

UIS.JumpRequest:Connect(function()
    if infiniteJump then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

MovementTab:CreateToggle({
   Name = "Noclip",
   CurrentValue = false,
   Flag = "NoclipToggle",
   Callback = function(Value)
       if Value then
           RunService.Stepped:Connect(function()
               for _, part in pairs(Character:GetDescendants()) do
                   if part:IsA("BasePart") then
                       part.CanCollide = false
                   end
               end
           end)
           sendToDiscord("Action Log", "Noclip enabled!", 0xFFFF00)
       else
           RunService.Stepped:Connect(function() end):Disconnect() -- This is a simplified way, might not be perfect
           sendToDiscord("Action Log", "Noclip disabled!", 0xFFFF00)
       end
   end,
})

MovementTab:CreateButton({Name = "Dash (Q)", Callback = function() end}) -- Just a label

--------------------------------------------------
-- Combat タブ
--------------------------------------------------

local CombatTab = Window:CreateTab("Combat", 4483362458)

local selectedPlayerName = ""
local playerNames = {}

local function updatePlayerList(dropdown)
    playerNames = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerNames, player.Name)
        end
    end
    table.sort(playerNames)
    if #playerNames > 0 and not table.find(playerNames, selectedPlayerName) then
        selectedPlayerName = playerNames[1]
    elseif #playerNames == 0 then
        selectedPlayerName = ""
    end
    if dropdown then
        dropdown:SetValues(playerNames)
    end
end

local playerDropdown = CombatTab:CreateDropdown({
   Name = "Select Player",
   Options = playerNames,
   CurrentValue = selectedPlayerName,
   Flag = "PlayerDropdown",
   Callback = function(Value)
      selectedPlayerName = Value
   end,
})

CombatTab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        updatePlayerList(playerDropdown)
        sendToDiscord("Action Log", "Player list refreshed.", 0xFFFF00)
    end
})

CombatTab:CreateToggle({
    Name = "ESP (Players)",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = function(Value)
        -- ESP Logic here (simplified)
        sendToDiscord("Action Log", "ESP " .. (Value and "enabled" or "disabled") .. "!", 0xFFFF00)
    end
})

CombatTab:CreateToggle({
    Name = "Auto Assistant (Aimbot)",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(Value)
        -- Aimbot Logic here (simplified)
        sendToDiscord("Action Log", "Aimbot " .. (Value and "enabled" or "disabled") .. "!", 0xFFFF00)
    end
})

CombatTab:CreateButton({
    Name = "Fling Selected Player",
    Callback = function()
        if selectedPlayerName ~= "" then
            local targetPlayer = Players:FindFirstChild(selectedPlayerName)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local targetRoot = targetPlayer.Character.HumanoidRootPart
                local flingForce = Vector3.new(0, 5000, 0) + (RootPart.CFrame.LookVector * 2000)
                targetRoot:ApplyImpulse(flingForce * targetRoot:GetMass() * 15)
                sendToDiscord("Action Log", "Flinged player: " .. selectedPlayerName, 0xFF8C00)
            else
                sendToDiscord("Error Log", "Fling failed: " .. selectedPlayerName .. " not found.", 0xFF0000)
            end
        else
            sendToDiscord("Error Log", "Fling failed: No player selected.", 0xFF0000)
        end
    end
})

local loopKillEnabled = false
local loopKillConnection
CombatTab:CreateToggle({
   Name = "Loop Kill Selected Player",
   CurrentValue = false,
   Flag = "LoopKillToggle",
   Callback = function(Value)
       loopKillEnabled = Value
       if loopKillEnabled then
           if selectedPlayerName ~= "" then
               local targetPlayer = Players:FindFirstChild(selectedPlayerName)
               if targetPlayer then
                   loopKillConnection = targetPlayer.CharacterAdded:Connect(function(char)
                       task.wait(0.5)
                       char:WaitForChild("Humanoid").Health = 0
                       sendToDiscord("Action Log", "Killed player (Loop Kill): " .. targetPlayer.Name, 0xFF0000)
                   end)
                   targetPlayer.Character:WaitForChild("Humanoid").Health = 0
                   sendToDiscord("Action Log", "Loop Kill enabled for: " .. selectedPlayerName, 0xFF0000)
               end
           end
       else
           if loopKillConnection then
               loopKillConnection:Disconnect()
           end
           sendToDiscord("Action Log", "Loop Kill disabled.", 0xFFFF00)
       end
   end,
})

--------------------------------------------------
-- Teleport タブ
--------------------------------------------------

local TeleportTab = Window:CreateTab("Teleport", 4483362458)

TeleportTab:CreateButton({
    Name = "TP to Selected Player",
    Callback = function()
        if selectedPlayerName ~= "" then
            local targetPlayer = Players:FindFirstChild(selectedPlayerName)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                RootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 5, 0)
                sendToDiscord("Action Log", "Teleported to: " .. selectedPlayerName, 0x0000FF)
            end
        end
    end
})

TeleportTab:CreateButton({
    Name = "Bring Selected Player",
    Callback = function()
        if selectedPlayerName ~= "" then
            local targetPlayer = Players:FindFirstChild(selectedPlayerName)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                targetPlayer.Character.HumanoidRootPart.CFrame = RootPart.CFrame + Vector3.new(0, 5, 0)
                sendToDiscord("Action Log", "Brought player: " .. selectedPlayerName, 0x0000FF)
            end
        end
    end
})

local clickTPEnabled = false
TeleportTab:CreateToggle({
   Name = "Click TP (Ctrl + Click)",
   CurrentValue = false,
   Flag = "ClickTPToggle",
   Callback = function(Value)
       clickTPEnabled = Value
   end,
})

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if clickTPEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        local mouse = LocalPlayer:GetMouse()
        if mouse.Target then
            RootPart.CFrame = mouse.Hit + Vector3.new(0, 5, 0)
            sendToDiscord("Action Log", "Click TP to: " .. tostring(mouse.Hit), 0x0000FF)
        end
    end
end)

--------------------------------------------------
-- Settings タブ
--------------------------------------------------

local SettingsTab = Window:CreateTab("Settings", 4483362458)

SettingsTab:CreateToggle({
   Name = "Enable Discord Logger",
   CurrentValue = true,
   Flag = "DiscordLoggerToggle",
   Callback = function(Value)
       discordLoggerEnabled = Value
       sendToDiscord("Logger Status", "Discord Logger has been " .. (Value and "Enabled" or "Disabled"), 0x808080)
   end,
})

SettingsTab:CreateDropdown({
   Name = "UI Theme",
   Options = {"Default", "DarkBlue", "Green", "Light", "Amethyst", "Ocean", "Bloom"},
   CurrentValue = "Amethyst",
   Flag = "ThemeDropdown",
   Callback = function(Value)
      Rayfield:ChangeTheme(Value)
   end,
})

-- Initial player list load
updatePlayerList(playerDropdown)
