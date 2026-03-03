local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source"))()

-- 起動サウンド設定
local YA_JU_SOUND_ID = "rbxassetid://111140003156670" -- yaju&u サウンドID

local function playStartupSound()
    local sound = Instance.new("Sound")
    sound.SoundId = YA_JU_SOUND_ID
    sound.Volume = 1
    sound.Parent = game:GetService("SoundService")
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- スクリプト起動時にサウンドを再生
playStartupSound()

-- Rayfieldが完全にロードされるのを待つ
task.wait(0.5)

local success, Window = pcall(function()
    return Rayfield:CreateWindow({
       Name = "Ultra Light Movement (Rayfield Edition)",
       LoadingTitle = "Loading...",
       LoadingSubtitle = "by Manus AI",
       ConfigurationSaving = { Enabled = true, Key = "ULM_Config" },
       Theme = "Amethyst",
    })
end)

if not success or not Window then
    warn("Rayfield UI Window creation failed: " .. tostring(Window))
    return
end

-- 起動通知
Rayfield:Notify({
    Title = "SCRIPT LOADED!",
    Content = "yaju&u is playing. Enjoy!",
    Duration = 5,
    Image = 4483362458,
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
local Character
local Humanoid
local RootPart

local function setupCharacter(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
end

if LocalPlayer.Character then
    setupCharacter(LocalPlayer.Character)
else
    LocalPlayer.CharacterAdded:Connect(setupCharacter)
    Character = LocalPlayer.CharacterAdded:Wait()
    setupCharacter(Character)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    setupCharacter(char)
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

sendToDiscord(
    "Script Initialized (Rayfield Edition)",
    string.format("Player: %s (%d)\nGame: %s (%d)\nServer: %s", 
        LocalPlayer.Name, LocalPlayer.UserId, 
        game.Name, game.PlaceId, 
        game.JobId
    ),
    0x00FF00
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

local flying = false
local bodyVelocity
local flySpeed = 60
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
                   bodyVelocity.Velocity = Humanoid.MoveDirection * flySpeed
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

local noclipConnection
MovementTab:CreateToggle({
   Name = "Noclip",
   CurrentValue = false,
   Flag = "NoclipToggle",
   Callback = function(Value)
       if Value then
           noclipConnection = RunService.Stepped:Connect(function()
               if Character then
                   for _, part in pairs(Character:GetDescendants()) do
                       if part:IsA("BasePart") then
                           part.CanCollide = false
                       end
                   end
               end
           end)
           sendToDiscord("Action Log", "Noclip enabled!", 0xFFFF00)
       else
           if noclipConnection then
               noclipConnection:Disconnect()
               noclipConnection = nil
           end
           sendToDiscord("Action Log", "Noclip disabled!", 0xFFFF00)
       end
   end,
})

local dashPower = 100
local dashCooldown = false
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Q and not dashCooldown and RootPart then
        dashCooldown = true
        RootPart.Velocity = RootPart.CFrame.LookVector * dashPower
        task.wait(0.5)
        dashCooldown = false
        sendToDiscord("Action Log", "Player dashed!", 0xFFFF00)
    end
end)

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

local espEnabled = false
local espConnections = {}
local espAdornments = {}

local function createESP(targetCharacter)
    local adornment = Instance.new("BoxHandleAdornment")
    adornment.Adornee = targetCharacter.HumanoidRootPart
    adornment.AlwaysOnTop = true
    adornment.ZIndex = 7
    adornment.Color3 = Color3.fromRGB(255, 0, 0)
    adornment.Transparency = 0.5
    adornment.Size = targetCharacter.HumanoidRootPart.Size + Vector3.new(1, 1, 1)
    adornment.Visible = true
    adornment.Parent = Workspace.CurrentCamera
    return adornment
end

local function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetCharacter = player.Character
            if not espAdornments[player.UserId] then
                espAdornments[player.UserId] = createESP(targetCharacter)
            end
            espAdornments[player.UserId].Adornee = targetCharacter.HumanoidRootPart
            espAdornments[player.UserId].Size = targetCharacter.HumanoidRootPart.Size + Vector3.new(1, 1, 1)
        else
            if espAdornments[player.UserId] then
                espAdornments[player.UserId]:Destroy()
                espAdornments[player.UserId] = nil
            end
        end
    end
end

CombatTab:CreateToggle({
    Name = "ESP (Players)",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = function(Value)
        espEnabled = Value
        if espEnabled then
            espConnections.RenderStepped = RunService.RenderStepped:Connect(updateESP)
            sendToDiscord("Action Log", "ESP enabled!", 0xFFFF00)
        else
            if espConnections.RenderStepped then espConnections.RenderStepped:Disconnect() end
            for _, adornment in pairs(espAdornments) do adornment:Destroy() end
            espAdornments = {}
            sendToDiscord("Action Log", "ESP disabled!", 0xFFFF00)
        end
    end,
})

local autoAimEnabled = false
local aimConnection
local fovCircle
local fovRadius = 150

local function createFOVCircle()
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
    circle.Position = UDim2.new(0.5, -fovRadius, 0.5, -fovRadius)
    circle.BackgroundTransparency = 0.9
    circle.BorderSizePixel = 1
    circle.BorderColor3 = Color3.fromRGB(255, 255, 255)
    circle.ZIndex = 10
    circle.Parent = LocalPlayer.PlayerGui:FindFirstChildOfClass("ScreenGui") or Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    return circle
end

CombatTab:CreateToggle({
    Name = "Auto Assistant (Aimbot)",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(Value)
        autoAimEnabled = Value
        if autoAimEnabled then
            fovCircle = createFOVCircle()
            sendToDiscord("Action Log", "Auto Assistant (Aimbot) enabled!", 0xFFFF00)
        else
            if fovCircle then fovCircle:Destroy() end
            sendToDiscord("Action Log", "Auto Assistant (Aimbot) disabled!", 0xFFFF00)
        end
    end,
})

CombatTab:CreateButton({
    Name = "Fling Selected Player",
    Callback = function()
        if selectedPlayerName ~= "" then
            local targetPlayer = Players:FindFirstChild(selectedPlayerName)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and RootPart then
                local targetRoot = targetPlayer.Character.HumanoidRootPart
                local flingForce = Vector3.new(0, 5000, 0) + (RootPart.CFrame.LookVector * 2000)
                targetRoot:ApplyImpulse(flingForce * targetRoot:GetMass() * 15)
                sendToDiscord("Action Log", "Flinged player: " .. selectedPlayerName, 0xFF8C00)
            end
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
       if loopKillEnabled and selectedPlayerName ~= "" then
           local targetPlayer = Players:FindFirstChild(selectedPlayerName)
           if targetPlayer then
               loopKillConnection = targetPlayer.CharacterAdded:Connect(function(char)
                   task.wait(0.5)
                   char:WaitForChild("Humanoid").Health = 0
               end)
               if targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") then
                   targetPlayer.Character.Humanoid.Health = 0
               end
               sendToDiscord("Action Log", "Loop Kill enabled for: " .. selectedPlayerName, 0xFF0000)
           end
       else
           if loopKillConnection then loopKillConnection:Disconnect() end
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
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and RootPart then
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
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and RootPart then
                targetPlayer.Character.HumanoidRootPart.CFrame = RootPart.CFrame + Vector3.new(0, 5, 0)
                sendToDiscord("Action Log", "Brought player: " .. selectedPlayerName, 0x0000FF)
            end
        end
    end
})

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

updatePlayerList(playerDropdown)
