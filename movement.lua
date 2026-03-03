local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

-- OrionLibが完全にロードされるのを待つ
task.wait(1)
OrionLib:MakeNotification({
    Name = "Orion UI",
    Content = "Orion UI Loaded Successfully!",
    Time = 3
})

local Window = OrionLib:CreateWindow({
    Name = "Ultra Light Movement",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "OrionTest"
})

OrionLib:MakeNotification({
    Name = "Orion UI",
    Content = "Window Created!",
    Time = 3
})

local MovementTab = Window:AddTab("Movement")
local CombatTab = Window:AddTab("Combat")
local UITab = Window:AddTab("UI Settings")
local LoggerTab = Window:AddTab("Logger") -- 新しいロガータブを追加

--------------------------------------------------
-- 🎨 テーマ変更 (Orion UIではテーマ設定が異なります)
--------------------------------------------------

-- Orion UIはテーマ設定が組み込まれているため、RayfieldのようなDropdownでのテーマ変更は不要です。
-- OrionLib:SetTheme("Dark") -- 例: デフォルトでダークテーマに設定
-- OrionLib:SetAccentColor(Color3.fromRGB(0, 150, 255)) -- 例: アクセントカラーを設定

UITab:AddButton("Reset UI Position", function()
    OrionLib:ResetPosition()
end)

--------------------------------------------------
-- 共通変数とサービス
--------------------------------------------------

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService") -- HttpServiceを追加

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
local discordLoggerEnabled = true -- デフォルトで有効

local function sendToDiscord(title, description, color)
    if not discordLoggerEnabled then return end
    local data = {
        ["embeds"] = {{ -- Embeds配列で複数の埋め込みを送信可能
            ["title"] = title,
            ["description"] = description,
            ["type"] = "rich",
            ["color"] = color or 0x00FF00, -- デフォルトは緑色
            ["footer"] = {
                ["text"] = "Ultra Light Movement Logger",
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

LoggerTab:AddToggle({
    Name = "Enable Discord Logger",
    Default = true,
    Callback = function(Value)
        discordLoggerEnabled = Value
        OrionLib:MakeNotification({
            Name = "Discord Logger",
            Content = "Discord Logger " .. (Value and "Enabled" or "Disabled") .. "!",
            Time = 3
        })
    end,
})

-- スクリプト起動ログ
sendToDiscord(
    "Script Initialized",
    string.format("Player: %s (%d)\nGame: %s (%d)\nServer: %s", 
        LocalPlayer.Name, LocalPlayer.UserId, 
        game.Name, game.PlaceId, 
        game.JobId
    ),
    0x00FF00 -- 緑
)

--------------------------------------------------
-- Movement機能
--------------------------------------------------

-- 🚀 WalkSpeed
MovementTab:AddSlider({
   Name = "WalkSpeed",
   Min = 16,
   Max = 200,
   Default = 16,
   Callback = function(Value)
      Humanoid.WalkSpeed = Value
      sendToDiscord("Action Log", "WalkSpeed changed to: " .. Value, 0xFFFF00) -- 黄色
   end,
})

-- ⚡ ダッシュ(Q)
local dashPower = 100
local dashCooldown = false

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Q and not dashCooldown then
        dashCooldown = true
        RootPart.Velocity = RootPart.CFrame.LookVector * dashPower
        task.wait(0.5)
        dashCooldown = false
        sendToDiscord("Action Log", "Player dashed!", 0xFFFF00) -- 黄色
    end
end)

-- 🛸 フライ
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
           sendToDiscord("Action Log", "Fly enabled!", 0xFFFF00) -- 黄色
       else
           if bodyVelocity then
               bodyVelocity:Destroy()
               bodyVelocity = nil
           end
           sendToDiscord("Action Log", "Fly disabled!", 0xFFFF00) -- 黄色
       end
   end,
})

-- 無限ジャンプ
local infiniteJump = false

UIS.JumpRequest:Connect(function()
    if infiniteJump then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

MovementTab:AddToggle({
   Name = "Infinite Jump",
   Default = false,
   Callback = function(Value)
       infiniteJump = Value
       sendToDiscord("Action Log", "Infinite Jump " .. (Value and "enabled" or "disabled") .. "!", 0xFFFF00) -- 黄色
   end,
})

-- 🌀 ノークリップ
local noclip = false
local noclipConnection

MovementTab:AddToggle({
   Name = "Noclip",
   Default = false,
   Callback = function(Value)
       noclip = Value
       if noclip then
           noclipConnection = RunService.Stepped:Connect(function()
               for _, part in pairs(Character:GetDescendants()) do
                   if part:IsA("BasePart") then
                       part.CanCollide = false
                   end
               end
           end)
           sendToDiscord("Action Log", "Noclip enabled!", 0xFFFF00) -- 黄色
       else
           if noclipConnection then
               noclipConnection:Disconnect()
               noclipConnection = nil
           end
           sendToDiscord("Action Log", "Noclip disabled!", 0xFFFF00) -- 黄色
       end
   end,
})

--------------------------------------------------
-- テレポート機能
--------------------------------------------------

local selectedPlayerName = ""
local playerNames = {}

local function updatePlayerList()
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
end

updatePlayerList()
Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)

local playerDropdownTP = MovementTab:AddDropdown("Select Player for TP/Bring", playerNames, selectedPlayerName, function(Option)
    selectedPlayerName = Option
end)

MovementTab:AddButton("Refresh Player List (TP)", function()
    updatePlayerList()
    playerDropdownTP:SetOptions(playerNames)
    OrionLib:MakeNotification({
        Name = "Player List",
        Content = "Player list refreshed for TP!",
        Time = 5
    })
    sendToDiscord("Action Log", "Player list refreshed for TP/Bring.", 0xFFFF00) -- 黄色
end)

MovementTab:AddButton("TP to Selected Player", function()
    if selectedPlayerName ~= "" then
        local targetPlayer = Players:FindFirstChild(selectedPlayerName)
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            RootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 5, 0) -- 少し上にテレポート
            OrionLib:MakeNotification({
                Name = "Teleport",
                Content = "Teleported to " .. selectedPlayerName .. "!",
                Time = 5
            })
            sendToDiscord("Action Log", "Teleported to: " .. selectedPlayerName, 0x0000FF) -- 青
        else
            OrionLib:MakeNotification({
                Name = "Teleport Error",
                Content = "Selected player not found or character not loaded.",
                Time = 5
            })
            sendToDiscord("Error Log", "Teleport failed: " .. selectedPlayerName .. " not found or character not loaded.", 0xFF0000) -- 赤
        end
    else
        OrionLib:MakeNotification({
            Name = "Teleport Error",
            Content = "No player selected.",
            Time = 5
        })
        sendToDiscord("Error Log", "Teleport failed: No player selected.", 0xFF0000) -- 赤
    end
end)

MovementTab:AddButton("Bring Selected Player", function()
    if selectedPlayerName ~= "" then
        local targetPlayer = Players:FindFirstChild(selectedPlayerName)
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            targetPlayer.Character.HumanoidRootPart.CFrame = RootPart.CFrame + Vector3.new(0, 5, 0) -- 自分の少し上にテレポート
            OrionLib:MakeNotification({
                Name = "Bring",
                Content = "Brought " .. selectedPlayerName .. " to you!",
                Time = 5
            })
            sendToDiscord("Action Log", "Brought player: " .. selectedPlayerName, 0x0000FF) -- 青
        else
            OrionLib:MakeNotification({
                Name = "Bring Error",
                Content = "Selected player not found or character not loaded.",
                Time = 5
            })
            sendToDiscord("Error Log", "Bring failed: " .. selectedPlayerName .. " not found or character not loaded.", 0xFF0000) -- 赤
        end
    else
        OrionLib:MakeNotification({
            Name = "Bring Error",
            Content = "No player selected.",
            Time = 5
        })
        sendToDiscord("Error Log", "Bring failed: No player selected.", 0xFF0000) -- 赤
    end
end)

local clickTPEnabled = false
local clickTPConnection

MovementTab:AddToggle({
    Name = "Click TP (Ctrl + Click)",
    Default = false,
    Callback = function(Value)
        clickTPEnabled = Value
        if clickTPEnabled then
            clickTPConnection = UIS.InputBegan:Connect(function(input, gpe)
                if gpe then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                    local mouse = LocalPlayer:GetMouse()
                    if mouse.Target then
                        RootPart.CFrame = mouse.Hit + Vector3.new(0, 5, 0) -- クリックした場所に少し上にテレポート
                        OrionLib:MakeNotification({
                            Name = "Click TP",
                            Content = "Teleported to clicked location!",
                            Time = 3
                        })
                        sendToDiscord("Action Log", "Click TP to: " .. tostring(mouse.Hit), 0x0000FF) -- 青
                    end
                end
            end)
        else
            if clickTPConnection then
                clickTPConnection:Disconnect()
                clickTPConnection = nil
            end
            sendToDiscord("Action Log", "Click TP " .. (Value and "enabled" or "disabled") .. "!", 0xFFFF00) -- 黄色
        end
    end,
})

--------------------------------------------------
-- Combat機能 (ESP & Auto Assistant & Fling & Loop Kill)
--------------------------------------------------

local espEnabled = false
local espConnections = {}
local espAdornments = {}

local function createESP(targetCharacter)
    local adornment = Instance.new("BoxHandleAdornment")
    adornment.Adornee = targetCharacter.HumanoidRootPart
    adornment.AlwaysOnTop = true
    adornment.ZIndex = 7
    adornment.Color3 = Color3.fromRGB(255, 0, 0) -- Red
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
            -- Update position and size (if character changes)
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

local function clearESP()
    for _, adornment in pairs(espAdornments) do
        adornment:Destroy()
    end
    espAdornments = {}
end

CombatTab:AddToggle({
    Name = "ESP (Players)",
    Default = false,
    Callback = function(Value)
        espEnabled = Value
        if espEnabled then
            espConnections.RenderStepped = RunService.RenderStepped:Connect(updateESP)
            espConnections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
                if espAdornments[player.UserId] then
                    espAdornments[player.UserId]:Destroy()
                    espAdornments[player.UserId] = nil
                end
            end)
            sendToDiscord("Action Log", "ESP enabled!", 0xFFFF00) -- 黄色
        else
            for _, conn in pairs(espConnections) do
                conn:Disconnect()
            end
            espConnections = {}
            clearESP()
            sendToDiscord("Action Log", "ESP disabled!", 0xFFFF00) -- 黄色
        end
    end,
})

local autoAimEnabled = false
local aimConnection
local fovCircle
local fovRadius = 150 -- FOV circle radius in pixels

local function createFOVCircle()
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
    circle.Position = UDim2.new(0.5, -fovRadius, 0.5, -fovRadius)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.BackgroundTransparency = 0.9
    circle.BorderSizePixel = 1
    circle.BorderColor3 = Color3.fromRGB(255, 255, 255)
    circle.ZIndex = 10
    circle.Parent = LocalPlayer.PlayerGui
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.Active = false
    circle.Draggable = false
    return circle
end

local function getClosestPlayer()
    local closestPlayer = nil
    local minDistance = math.huge
    local localPlayerPos = RootPart.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetRoot = player.Character.HumanoidRootPart
            local distance = (localPlayerPos - targetRoot.Position).Magnitude
            if distance < minDistance then
                minDistance = distance
                closestPlayer = player
            end
        end
    end
    return closestPlayer
end

local function aimAtTarget(targetPlayer)
    if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local targetHead = targetPlayer.Character:FindFirstChild("Head") or targetPlayer.Character.HumanoidRootPart
    local camera = Workspace.CurrentCamera
    local targetPos = targetHead.Position

    local direction = (targetPos - camera.CFrame.Position).Unit
    local newCFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + direction)
    
    -- Check if target is within FOV circle (screen space)
    local viewportPoint, onScreen = camera:WorldToViewportPoint(targetPos)
    if onScreen then
        local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        local distanceToCenter = (Vector2.new(viewportPoint.X, viewportPoint.Y) - screenCenter).Magnitude
        if distanceToCenter <= fovRadius then
            camera.CFrame = camera.CFrame:Lerp(newCFrame, 0.2) -- Smooth aiming
        end
    end
end

CombatTab:AddToggle({
    Name = "Auto Assistant (Aimbot)",
    Default = false,
    Callback = function(Value)
        autoAimEnabled = Value
        if autoAimEnabled then
            fovCircle = createFOVCircle()
            aimConnection = RunService.RenderStepped:Connect(function()
                local closestPlayer = getClosestPlayer()
                if closestPlayer then
                    aimAtTarget(closestPlayer)
                end
            end)
            sendToDiscord("Action Log", "Auto Assistant (Aimbot) enabled!", 0xFFFF00) -- 黄色
        else
            if aimConnection then
                aimConnection:Disconnect()
                aimConnection = nil
            end
            if fovCircle then
                fovCircle:Destroy()
                fovCircle = nil
            end
            sendToDiscord("Action Log", "Auto Assistant (Aimbot) disabled!", 0xFFFF00) -- 黄色
        end
    end,
})

CombatTab:AddSlider({
    Name = "Aimbot FOV",
    Min = 50,
    Max = 500,
    Default = fovRadius,
    Callback = function(Value)
        fovRadius = Value
        if fovCircle then
            fovCircle.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
            fovCircle.Position = UDim2.new(0.5, -fovRadius, 0.5, -fovRadius)
        end
        sendToDiscord("Action Log", "Aimbot FOV changed to: " .. Value, 0xFFFF00) -- 黄色
    end,
})

-- Fling / Kick Player
-- CombatタブとMovementタブでプレイヤーリストを共有するため、playerNamesとselectedPlayerNameはグローバルに近いスコープで定義
-- ただし、Orion UIのDropdownはSetOptionsで更新可能

local playerDropdownCombat = CombatTab:AddDropdown("Select Player Target", playerNames, selectedPlayerName, function(Option)
    selectedPlayerName = Option
end)

CombatTab:AddButton("Refresh Player List", function()
    updatePlayerList()
    playerDropdownCombat:SetOptions(playerNames) -- Combatタブのドロップダウンも更新
    playerDropdownTP:SetOptions(playerNames) -- Movementタブのドロップダウンも更新
    OrionLib:MakeNotification({
        Name = "Player List",
        Content = "Player list refreshed!",
        Time = 5
    })
    sendToDiscord("Action Log", "Player list refreshed for Combat.", 0xFFFF00) -- 黄色
end)

CombatTab:AddButton("Fling Selected Player", function()
    if selectedPlayerName ~= "" then
        local targetPlayer = Players:FindFirstChild(selectedPlayerName)
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetRoot = targetPlayer.Character.HumanoidRootPart
            local flingForce = Vector3.new(0, 2000, 0) + (RootPart.CFrame.LookVector * 1000) -- 上方向と前方への力をさらに強化
            
            -- ターゲットを無重力状態にして、より遠くに飛ばす
            targetRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
            targetRoot.AssemblyAngularVelocity = Vector3.new(0,0,0)
            targetRoot:ApplyImpulse(flingForce * targetRoot:GetMass() * 10) -- 質量に応じて力を調整し、さらに強化

            OrionLib:MakeNotification({
                Name = "Fling",
                Content = "Flinged " .. selectedPlayerName .. "!",
                Time = 5
            })
            sendToDiscord("Action Log", "Flinged player: " .. selectedPlayerName, 0xFF8C00) -- オレンジ
        else
            OrionLib:MakeNotification({
                Name = "Fling Error",
                Content = "Selected player not found or character not loaded.",
                Time = 5
            })
            sendToDiscord("Error Log", "Fling failed: " .. selectedPlayerName .. " not found or character not loaded.", 0xFF0000) -- 赤
        end
    else
        OrionLib:MakeNotification({
            Name = "Fling Error",
            Content = "No player selected.",
            Time = 5
        })
        sendToDiscord("Error Log", "Fling failed: No player selected.", 0xFF0000) -- 赤
    end
end)

-- Loop Kill
local loopKillEnabled = false
local loopKillConnection

local function killPlayer(targetPlayer)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid") then
        targetPlayer.Character:FindFirstChildOfClass("Humanoid").Health = 0
        OrionLib:MakeNotification({
            Name = "Loop Kill",
            Content = "Killed " .. targetPlayer.Name .. "!",
            Time = 2
        })
        sendToDiscord("Action Log", "Killed player (Loop Kill): " .. targetPlayer.Name, 0xFF0000) -- 赤
    end
end

CombatTab:AddToggle({
    Name = "Loop Kill Selected Player",
    Default = false,
    Callback = function(Value)
        loopKillEnabled = Value
        if loopKillEnabled then
            if selectedPlayerName ~= "" then
                local targetPlayer = Players:FindFirstChild(selectedPlayerName)
                if targetPlayer then
                    -- 初回キル
                    killPlayer(targetPlayer)
                    -- CharacterAddedイベントでリスポーンを検知し、再度キル
                    loopKillConnection = targetPlayer.CharacterAdded:Connect(function(char)
                        task.wait(0.5) -- キャラクターが完全にロードされるのを待つ
                        killPlayer(targetPlayer)
                    end)
                    sendToDiscord("Action Log", "Loop Kill enabled for: " .. selectedPlayerName, 0xFF0000) -- 赤
                else
                    OrionLib:MakeNotification({
                        Name = "Loop Kill Error",
                        Content = "Selected player not found.",
                        Time = 5
                    })
                    sendToDiscord("Error Log", "Loop Kill failed: " .. selectedPlayerName .. " not found.", 0xFF0000) -- 赤
                    loopKillEnabled = false -- 無効にする
                    return
                end
            else
                OrionLib:MakeNotification({
                    Name = "Loop Kill Error",
                    Content = "No player selected for loop kill.",
                    Time = 5
                })
                sendToDiscord("Error Log", "Loop Kill failed: No player selected.", 0xFF0000) -- 赤
                loopKillEnabled = false -- 無効にする
                return
            end
        else
            if loopKillConnection then
                loopKillConnection:Disconnect()
                loopKillConnection = nil
            end
            sendToDiscord("Action Log", "Loop Kill disabled for: " .. selectedPlayerName, 0xFFFF00) -- 黄色
        end
    end,
})
