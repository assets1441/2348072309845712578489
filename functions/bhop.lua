local Library = getgenv().Library
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- Настройки Bhop
local Bhop = {
    Enabled = false,
    Chance = 100,       -- 0-100
    Timing = 0,         -- 0-10 ms (0 = perfect)
    Binds = {}          -- { {key = "Space", mode = "hold"} }
}

-- Флаги
local jumpRequested = false
local lastJumpTime = 0

-- Функция эмуляции прыжка с учётом тайминга
local function SimulateJump()
    local timing = Bhop.Timing / 1000  -- ms -> seconds
    if timing > 0 then
        task.wait(timing)
    end
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
    task.wait() -- небольшая задержка между нажатием и отпусканием
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
end

-- Основной цикл
local heartbeatConn
local function UpdateBhopLoop()
    if heartbeatConn then heartbeatConn:Disconnect() end
    if not Bhop.Enabled then return end

    heartbeatConn = RunService.Heartbeat:Connect(function()
        if not Bhop.Enabled then return end
        local char = Player.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        if not hum or hum:GetState() == Enum.HumanoidStateType.Dead then return end

        -- Проверка, нужно ли прыгать (касание земли)
        local onGround = hum.FloorMaterial ~= Enum.Material.Air
        if not onGround then return end

        -- Проверка шанса
        if math.random(1, 100) > Bhop.Chance then return end

        -- Проверка активных биндов (если включены)
        local anyActive = false
        for _, bind in ipairs(Bhop.Binds) do
            local key = Enum.KeyCode[bind.key]
            if key then
                if bind.mode == "hold" then
                    if UserInputService:IsKeyDown(key) then
                        anyActive = true
                        break
                    end
                elseif bind.mode == "toggle" then
                    -- Для toggle считаем всегда активным, если бинд есть (управление через UI)
                    anyActive = true
                    break
                end
            end
        end

        -- Если нет активных биндов, пропускаем
        if #Bhop.Binds > 0 and not anyActive then return end

        SimulateJump()
    end)
end

-- Создание окна настроек
local function ShowSettings()
    local Theme = Library.Theme
    local elements = {}

    -- Chance Slider
    local chanceFrame = Instance.new("Frame")
    chanceFrame.Size = UDim2.new(1,0,0,60)
    chanceFrame.BackgroundTransparency = 1
    chanceFrame.BorderSizePixel = 0
    table.insert(elements, chanceFrame)

    local chanceLabel = Instance.new("TextLabel")
    chanceLabel.Size = UDim2.new(1,0,0,20)
    chanceLabel.BackgroundTransparency = 1
    chanceLabel.Text = "Chance: " .. Bhop.Chance .. (Bhop.Chance == 100 and " (Perfect)" or "")
    chanceLabel.TextColor3 = Theme.White
    chanceLabel.Font = Enum.Font.GothamMedium
    chanceLabel.TextSize = 14
    chanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    chanceLabel.Parent = chanceFrame
    Library.ApplyTextStroke(chanceLabel)

    local chanceBG = Instance.new("Frame")
    chanceBG.BackgroundColor3 = Theme.NotchBG
    chanceBG.Size = UDim2.new(1,0,0,6)
    chanceBG.Position = UDim2.new(0,0,0,28)
    chanceBG.Parent = chanceFrame
    Instance.new("UICorner", chanceBG).CornerRadius = UDim.new(1,0)

    local chanceFill = Instance.new("Frame")
    chanceFill.BackgroundColor3 = Theme.PastelPink
    chanceFill.Size = UDim2.new(Bhop.Chance/100,0,1,0)
    chanceFill.Parent = chanceBG
    Instance.new("UICorner", chanceFill).CornerRadius = UDim.new(1,0)

    local chanceHitbox = Instance.new("TextButton")
    chanceHitbox.Size = UDim2.new(1,0,1,0)
    chanceHitbox.BackgroundTransparency = 1
    chanceHitbox.Text = ""
    chanceHitbox.Parent = chanceFrame

    local isDraggingChance = false
    local function updateChance(input)
        local pos = math.clamp((input.Position.X - chanceBG.AbsolutePosition.X) / chanceBG.AbsoluteSize.X, 0, 1)
        Bhop.Chance = math.floor(pos * 100)
        chanceLabel.Text = "Chance: " .. Bhop.Chance .. (Bhop.Chance == 100 and " (Perfect)" or "")
        chanceFill.Size = UDim2.new(pos,0,1,0)
    end
    chanceHitbox.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            isDraggingChance = true
            updateChance(i)
        end
    end)
    table.insert(Library.Connections, UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then isDraggingChance = false end
    end))
    table.insert(Library.Connections, UserInputService.InputChanged:Connect(function(i)
        if isDraggingChance and i.UserInputType == Enum.UserInputType.MouseMovement then updateChance(i) end
    end))

    -- Timing Slider
    local timingFrame = Instance.new("Frame")
    timingFrame.Size = UDim2.new(1,0,0,60)
    timingFrame.BackgroundTransparency = 1
    timingFrame.BorderSizePixel = 0
    table.insert(elements, timingFrame)

    local timingLabel = Instance.new("TextLabel")
    timingLabel.Size = UDim2.new(1,0,0,20)
    timingLabel.BackgroundTransparency = 1
    timingLabel.Text = "Timing: " .. Bhop.Timing .. " ms" .. (Bhop.Timing == 0 and " (Perfect)" or "")
    timingLabel.TextColor3 = Theme.White
    timingLabel.Font = Enum.Font.GothamMedium
    timingLabel.TextSize = 14
    timingLabel.TextXAlignment = Enum.TextXAlignment.Left
    timingLabel.Parent = timingFrame
    Library.ApplyTextStroke(timingLabel)

    local timingBG = Instance.new("Frame")
    timingBG.BackgroundColor3 = Theme.NotchBG
    timingBG.Size = UDim2.new(1,0,0,6)
    timingBG.Position = UDim2.new(0,0,0,28)
    timingBG.Parent = timingFrame
    Instance.new("UICorner", timingBG).CornerRadius = UDim.new(1,0)

    local timingFill = Instance.new("Frame")
    timingFill.BackgroundColor3 = Theme.PastelPink
    timingFill.Size = UDim2.new(Bhop.Timing/10,0,1,0)
    timingFill.Parent = timingBG
    Instance.new("UICorner", timingFill).CornerRadius = UDim.new(1,0)

    local timingHitbox = Instance.new("TextButton")
    timingHitbox.Size = UDim2.new(1,0,1,0)
    timingHitbox.BackgroundTransparency = 1
    timingHitbox.Text = ""
    timingHitbox.Parent = timingFrame

    local isDraggingTiming = false
    local function updateTiming(input)
        local pos = math.clamp((input.Position.X - timingBG.AbsolutePosition.X) / timingBG.AbsoluteSize.X, 0, 1)
        Bhop.Timing = math.floor(pos * 10)
        timingLabel.Text = "Timing: " .. Bhop.Timing .. " ms" .. (Bhop.Timing == 0 and " (Perfect)" or "")
        timingFill.Size = UDim2.new(pos,0,1,0)
    end
    timingHitbox.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            isDraggingTiming = true
            updateTiming(i)
        end
    end)
    table.insert(Library.Connections, UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then isDraggingTiming = false end
    end))
    table.insert(Library.Connections, UserInputService.InputChanged:Connect(function(i)
        if isDraggingTiming and i.UserInputType == Enum.UserInputType.MouseMovement then updateTiming(i) end
    end))

    Library:ShowModal("Bhop Settings", elements)
end

-- Окно биндов
local function ShowBinds()
    local bindData = {
        getBinds = function() return Bhop.Binds end,
        onAdd = function(key, mode)
            table.insert(Bhop.Binds, {key = key, mode = mode})
        end,
        onRemove = function(index)
            table.remove(Bhop.Binds, index)
        end,
        onModeChange = function(index, newMode)
            Bhop.Binds[index].mode = newMode
        end
    }
    Library:ShowBindWindow(bindData)
end

-- Добавляем кнопку в таб Main
local btn = Library:AddFeatureButton("Main", "Bhop", nil, {   -- <-- tooltipData = nil, чтобы не было тултипа
    onClick = function()
        Bhop.Enabled = not Bhop.Enabled
        btn.TextColor3 = Bhop.Enabled and Library.Theme.PastelPink or Library.Theme.White
        UpdateBhopLoop()
    end,
    onRightClick = ShowSettings,
    onMiddleClick = ShowBinds
})

-- Сброс состояния при перезаходе персонажа
Player.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    if Bhop.Enabled then
        UpdateBhopLoop()
    end
end)

print("Bhop function loaded")
