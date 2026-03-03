local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
   Name = "Ultra Light Movement",
   LoadingTitle = "Loading...",
   LoadingSubtitle = "Color Custom Edition",
   ConfigurationSaving = { Enabled = false }
})

local MovementTab = Window:CreateTab("Movement", 4483362458)
local CombatTab = Window:CreateTab("Combat", 4483362458)
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
-- 共通変数とサービス
--------------------------------------------------

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

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
-- Movement機能
--------------------------------------------------

-- 🚀 WalkSpeed
MovementTab:CreateSlider({
   Name = "WalkSpeed",
   Range = {16, 200},
   Increment = 1,
   CurrentValue = 16,
   Callback = function(Value)
      Humanoid.WalkSpeed = Value
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
    end
end)

-- 🛸 フライ
local flying = false
local bodyVelocity
local flySpeed = 60

MovementTab:CreateToggle({
   Name = "Fly",
   CurrentValue = false,
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
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

MovementTab:CreateToggle({
   Name = "Infinite Jump",
   CurrentValue = false,
   Callback = function(Value)
       infiniteJump = Value
   end,
})

-- 🌀 ノークリップ
local noclip = false
local noclipConnection

MovementTab:CreateToggle({
   Name = "Noclip",
   CurrentValue = false,
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
       else
           if noclipConnection then
               noclipConnection:Disconnect()
               noclipConnection = nil
           end
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

CombatTab:CreateToggle({
    Name = "ESP (Players)",
    CurrentValue = false,
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
        else
            for _, conn in pairs(espConnections) do
                conn:Disconnect()
            end
            espConnections = {}
            clearESP()
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

CombatTab:CreateToggle({
    Name = "Auto Assistant (Aimbot)",
    CurrentValue = false,
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
        else
            if aimConnection then
                aimConnection:Disconnect()
                aimConnection = nil
            end
            if fovCircle then
                fovCircle:Destroy()
                fovCircle = nil
            end
        end
    end,
})

CombatTab:CreateSlider({
    Name = "Aimbot FOV",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = fovRadius,
    Callback = function(Value)
        fovRadius = Value
        if fovCircle then
            fovCircle.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
            fovCircle.Position = UDim2.new(0.5, -fovRadius, 0.5, -fovRadius)
        end
    end,
})

-- Fling / Kick Player
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

local playerDropdown = CombatTab:CreateDropdown({
    Name = "Select Player Target",
    Options = playerNames,
    CurrentOption = selectedPlayerName,
    Callback = function(Option)
        selectedPlayerName = Option
    end,
})

CombatTab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        updatePlayerList()
        playerDropdown:SetOptions(playerNames) -- ドロップダウンのオプションを更新
        Rayfield:Notify("Player List", "Player list refreshed!", 5)
    end,
})

CombatTab:CreateButton({
    Name = "Fling Selected Player",
    Callback = function()
        if selectedPlayerName ~= "" then
            local targetPlayer = Players:FindFirstChild(selectedPlayerName)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local targetRoot = targetPlayer.Character.HumanoidRootPart
                local flingForce = Vector3.new(0, 500, 0) + (RootPart.CFrame.LookVector * 200) -- 上方向と前方への力
                
                -- ターゲットを無重力状態にして、より遠くに飛ばす
                targetRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
                targetRoot.AssemblyAngularVelocity = Vector3.new(0,0,0)
                targetRoot:ApplyImpulse(flingForce * targetRoot:GetMass() * 2) -- 質量に応じて力を調整

                Rayfield:Notify("Fling", "Flinged " .. selectedPlayerName .. "!", 5)
            else
                Rayfield:Notify("Fling Error", "Selected player not found or character not loaded.", 5)
            end
        else
            Rayfield:Notify("Fling Error", "No player selected.", 5)
        end
    end,
})

-- Loop Kill
local loopKillEnabled = false
local loopKillConnection

local function killPlayer(targetPlayer)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid") then
        targetPlayer.Character:FindFirstChildOfClass("Humanoid").Health = 0
        Rayfield:Notify("Loop Kill", "Killed " .. targetPlayer.Name .. "!", 2)
    end
end

CombatTab:CreateToggle({
    Name = "Loop Kill Selected Player",
    CurrentValue = false,
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
                else
                    Rayfield:Notify("Loop Kill Error", "Selected player not found.", 5)
                    loopKillEnabled = false -- 無効にする
                    return
                end
            else
                Rayfield:Notify("Loop Kill Error", "No player selected for loop kill.", 5)
                loopKillEnabled = false -- 無効にする
                return
            end
        else
            if loopKillConnection then
                loopKillConnection:Disconnect()
                loopKillConnection = nil
            end
        end
    end,
})
