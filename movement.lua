local Kavo = loadstring(game:HttpGet("https://raw.githubusercontent.com/kavo-ui/kavo-ui/main/src/Kavo.lua"))()

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

-- Kavo UIの初期化
local Window = Kavo.Create({
    Name = "Ultra Light Movement (Kavo Edition)",
    Size = UDim2.new(0, 300, 0, 400),
    Position = UDim2.new(0.5, -150, 0.5, -200),
    Theme = "Dark", -- Dark, Light, Blue, Green, Red, Purple
    AlwaysOnTop = true,
    Draggable = true,
    Resizable = false,
    Visible = true,
})

-- 起動通知
Kavo.Notify({
    Title = "SCRIPT LOADED!",
    Content = "yaju&u is playing. Enjoy!",
    Duration = 5,
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
                ["text"] = "yaju&u Kavo Edition Logger",
                ["icon_url"] = "https://www.roblox.com/asset-thumbnail/image?assetId=102611803&width=420&height=420&format=png"
            },
            ["timestamp"] = DateTime.now():ToIsoDate(),
        }}
    }
    local encodedData = HttpService:JSONEncode(data)
    local success, err = pcall(function()
        HttpService:PostAsync(WEBHOOK_URL, encodedData)
    end)
    if not success then
        warn("Discord Webhook Send Error: " .. err)
        Kavo.Notify({
            Title = "Discord Logger Error",
            Content = "Failed to send log to Discord: " .. err,
            Duration = 5,
        })
    end
end

sendToDiscord(
    "yaju&u Script Initialized (Kavo Edition)",
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

local MovementTab = Window:AddTab("Movement")

MovementTab:AddSlider({
   Name = "WalkSpeed",
   Min = 16,
   Max = 200,
   Default = 16,
   Callback = function(Value)
      Humanoid.WalkSpeed = Value
      sendToDiscord("Action Log", "WalkSpeed changed to: " .. Value .. " [yaju&u]", 0xFFFF00)
   end,
})

local flying = false
local bodyVelocity
local flySpeed = 60
MovementTab:AddToggle({
   Name = "Fly",
   Default = false,
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
           sendToDiscord("Action Log", "Fly enabled! [yaju&u]", 0xFFFF00)
       else
           if bodyVelocity then
               bodyVelocity:Destroy()
               bodyVelocity = nil
           end
           sendToDiscord("Action Log", "Fly disabled! [yaju&u]", 0xFFFF00)
       end
   end,
})

local infiniteJump = false
MovementTab:AddToggle({
   Name = "Infinite Jump",
   Default = false,
   Callback = function(Value)
       infiniteJump = Value
       sendToDiscord("Action Log", "Infinite Jump " .. (Value and "enabled" or "disabled") .. "! [yaju&u]", 0xFFFF00)
   end,
})

UIS.JumpRequest:Connect(function()
    if infiniteJump then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

local noclipConnection
MovementTab:AddToggle({
   Name = "Noclip",
   Default = false,
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
           sendToDiscord("Action Log", "Noclip enabled! [yaju&u]", 0xFFFF00)
       else
           if noclipConnection then
               noclipConnection:Disconnect()
               noclipConnection = nil
           end
           sendToDiscord("Action Log", "Noclip disabled! [yaju&u]", 0xFFFF00)
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
        sendToDiscord("Action Log", "Player dashed! [yaju&u]", 0xFFFF00)
    end
end)

--------------------------------------------------
-- Combat タブ
--------------------------------------------------

local CombatTab = Window:AddTab("Combat")

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

local playerDropdown = CombatTab:AddDropdown({
   Name = "Select Player",
   Options = playerNames,
   Default = selectedPlayerName,
   Callback = function(Value)
      selectedPlayerName = Value
   end,
})

CombatTab:AddButton({
    Name = "Refresh Player List",
    Callback = function()
        updatePlayerList(playerDropdown)
        sendToDiscord("Action Log", "Player list refreshed. [yaju&u]", 0xFFFF00)
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

CombatTab:AddToggle({
    Name = "ESP (Players)",
    Default = false,
    Callback = function(Value)
        espEnabled = Value
        if espEnabled then
            espConnections.RenderStepped = RunService.RenderStepped:Connect(updateESP)
            sendToDiscord("Action Log", "ESP enabled! [yaju&u]", 0xFFFF00)
        else
            if espConnections.RenderStepped then espConnections.RenderStepped:Disconnect() end
            for _, adornment in pairs(espAdornments) do adornment:Destroy() end
            espAdornments = {}
            sendToDiscord("Action Log", "ESP disabled! [yaju&u]", 0xFFFF00)
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

CombatTab:AddToggle({
    Name = "Auto Assistant (Aimbot)",
    Default = false,
    Callback = function(Value)
        autoAimEnabled = Value
        if autoAimEnabled then
            fovCircle = createFOVCircle()
            sendToDiscord("Action Log", "Auto Assistant (Aimbot) enabled! [yaju&u]", 0xFFFF00)
        else
            if fovCircle then fovCircle:Destroy() end
            sendToDiscord("Action Log", "Auto Assistant (Aimbot) disabled! [yaju&u]", 0xFFFF00)
        end
    end,
})

CombatTab:AddButton({
    Name = "Fling Selected Player",
    Callback = function()
        if selectedPlayerName ~= "" then
            local targetPlayer = Players:FindFirstChild(selectedPlayerName)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and RootPart then
                local targetRoot = targetPlayer.Character.HumanoidRootPart
                local flingForce = Vector3.new(0, 5000, 0) + (RootPart.CFrame.LookVector * 2000)
                targetRoot:ApplyImpulse(flingForce * targetRoot:GetMass() * 15)
                sendToDiscord("Action Log", "Flinged player: " .. selectedPlayerName .. " [yaju&u]", 0xFF8C00)
            end
        end
    end
})

local loopKillEnabled = false
local loopKillConnection
CombatTab:AddToggle({
   Name = "Loop Kill Selected Player",
   Default = false,
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
               sendToDiscord("Action Log", "Loop Kill enabled for: " .. selectedPlayerName .. " [yaju&u]", 0xFF0000)
           end
       else
           if loopKillConnection then loopKillConnection:Disconnect() end
           sendToDiscord("Action Log", "Loop Kill disabled. [yaju&u]", 0xFFFF00)
       end
   end,
})

--------------------------------------------------
-- Teleport タブ
--------------------------------------------------

local TeleportTab = Window:AddTab("Teleport")

TeleportTab:AddButton({
    Name = "TP to Selected Player",
    Callback = function()
        if selectedPlayerName ~= "" then
            local targetPlayer = Players:FindFirstChild(selectedPlayerName)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and RootPart then
                RootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 5, 0)
                sendToDiscord("Action Log", "Teleported to: " .. selectedPlayerName .. " [yaju&u]", 0x0000FF)
            end
        end
    end
})

TeleportTab:AddButton({
    Name = "Bring Selected Player",
    Callback = function()
        if selectedPlayerName ~= "" then
            local targetPlayer = Players:FindFirstChild(selectedPlayerName)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and RootPart then
                targetPlayer.Character.HumanoidRootPart.CFrame = RootPart.CFrame + Vector3.new(0, 5, 0)
                sendToDiscord("Action Log", "Brought player: " .. selectedPlayerName .. " [yaju&u]", 0x0000FF)
            end
        end
    end
})

--------------------------------------------------
-- Settings タブ
--------------------------------------------------

local SettingsTab = Window:AddTab("Settings")

SettingsTab:AddToggle({
   Name = "Enable Discord Logger",
   Default = true,
   Callback = function(Value)
       discordLoggerEnabled = Value
   end,
})

SettingsTab:AddButton({
    Name = "Test Discord Webhook",
    Callback = function()
        sendToDiscord("yaju&u Webhook Test", "This is a test message from the yaju&u Kavo script!", 0x00FFFF)
    end
})

SettingsTab:AddDropdown({
   Name = "UI Theme",
   Options = {"Dark", "Light", "Blue", "Green", "Red", "Purple"},
   Default = "Dark",
   Callback = function(Value)
      -- Kavo UI does not have a direct theme change function like Rayfield
      -- This would require re-creating the UI or setting individual element colors
      Kavo.Notify({
          Title = "Theme Change",
          Content = "Kavo UI themes are set at initialization. Please re-execute the script to change theme.",
          Duration = 5,
      })
   end,
})

updatePlayerList(playerDropdown)

Window:SelectTab("Movement") -- デフォルトでMovementタブを選択
Window:Open() -- UIを表示
