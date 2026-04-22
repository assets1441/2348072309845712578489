local Library = getgenv().Library
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

local BhopSettings = {
    Enabled = false,
    Chance = 100, 
    DelayMs = 0, -- 0 = perfect
    Binds = {} 
}

local function SimulateSpacebar()
    if keypress and keyrelease then
        keypress(0x20) 
        task.wait(0.01)
        keyrelease(0x20)
    else
        VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.01)
        VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end
end

local connection
local function SetupBhop(character)
    if connection then connection:Disconnect() end
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    connection = humanoid.StateChanged:Connect(function(oldState, newState)
        if not BhopSettings.Enabled then return end
        if newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running then
            if math.random(1, 100) <= BhopSettings.Chance then
                task.spawn(function()
                    if BhopSettings.DelayMs > 0 then
                        task.wait(BhopSettings.DelayMs / 1000)
                    end
                    SimulateSpacebar()
                end)
            end
        end
    end)
end

if LocalPlayer.Character then SetupBhop(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(SetupBhop)

local BhopToggle = Library:AddToggle("Main", "Perfect Bhop", "RMB - Settings | MMB - Keybinds", false, function(v)
    BhopSettings.Enabled = v
end)

-- НАСТРОЙКИ (ПКМ)
BhopToggle.OnRightClick = function()
    local modal = Library:OpenModal("Bhop Settings")
    
    Library:AddModalSlider(modal, "Hit Chance", 0, 100, BhopSettings.Chance, function(v)
        return v == 100 and "Perfect" or v.."%"
    end, function(val)
        BhopSettings.Chance = val
    end)

    Library:AddModalSlider(modal, "Timing Delay", 0, 10, 10 - BhopSettings.DelayMs, function(v)
        local actualDelay = 10 - v
        return actualDelay == 0 and "Perfect" or actualDelay.." ms"
    end, function(val)
        BhopSettings.DelayMs = 10 - val
    end)
end

-- МЕНЕДЖЕР БИНДОВ (СКМ)
BhopToggle.OnMiddleClick = function()
    local modal = Library:OpenModal("Bhop Keybinds")
    
    local function RefreshBindsList()
        for _, c in pairs(modal:GetChildren()) do
            if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
        end
        
        -- Яркая и заметная кнопка добавления бинда
        local AddBtn = Instance.new("TextButton")
        AddBtn.Size = UDim2.new(1, -20, 0, 40) 
        AddBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        AddBtn.Text = "+ CLICK TO ADD BIND"
        AddBtn.TextColor3 = Color3.fromRGB(255, 175, 200)
        AddBtn.Font = Enum.Font.GothamBold
        AddBtn.TextSize = 14
        AddBtn.Parent = modal
        Instance.new("UICorner", AddBtn).CornerRadius = UDim.new(0, 6)
        
        -- Легкая обводка чтобы кнопка не сливалась с фоном
        local s1 = Instance.new("UIStroke", AddBtn)
        s1.Color = Color3.fromRGB(50, 50, 50); s1.Thickness = 1
        
        local listening = false
        AddBtn.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            AddBtn.Text = "... PRESS ANY KEY ..."
            AddBtn.TextColor3 = Color3.new(1, 1, 1)
            s1.Color = Color3.fromRGB(255, 175, 200) -- Подсветка во время бинда
            
            local c; c = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    BhopSettings.Binds[input.KeyCode] = "Toggle"
                    c:Disconnect()
                    RefreshBindsList()
                end
            end)
        end)
        
        for key, mode in pairs(BhopSettings.Binds) do
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, -20, 0, 35)
            Row.BackgroundTransparency = 1
            Row.Parent = modal
            
            local KeyLabel = Instance.new("TextLabel")
            KeyLabel.Size = UDim2.new(0.4, 0, 1, 0)
            KeyLabel.BackgroundTransparency = 1
            KeyLabel.Text = key.Name
            KeyLabel.TextColor3 = Color3.new(1, 1, 1)
            KeyLabel.Font = Enum.Font.GothamBold
            KeyLabel.TextSize = 14
            KeyLabel.TextXAlignment = Enum.TextXAlignment.Left
            KeyLabel.Parent = Row
            
            local ModeBtn = Instance.new("TextButton")
            ModeBtn.Size = UDim2.new(0.4, -5, 1, 0)
            ModeBtn.Position = UDim2.new(0.4, 0, 0, 0)
            ModeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            ModeBtn.Text = mode
            ModeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
            ModeBtn.Font = Enum.Font.GothamMedium
            ModeBtn.TextSize = 13
            ModeBtn.Parent = Row
            Instance.new("UICorner", ModeBtn).CornerRadius = UDim.new(0, 6)
            local s2 = Instance.new("UIStroke", ModeBtn); s2.Color = Color3.fromRGB(50, 50, 50)
            
            ModeBtn.MouseButton1Click:Connect(function()
                BhopSettings.Binds[key] = (BhopSettings.Binds[key] == "Toggle" and "Hold" or "Toggle")
                ModeBtn.Text = BhopSettings.Binds[key]
            end)
            
            local DelBtn = Instance.new("TextButton")
            DelBtn.Size = UDim2.new(0.2, 0, 1, 0)
            DelBtn.Position = UDim2.new(0.8, 0, 0, 0)
            DelBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            DelBtn.Text = "X"
            DelBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
            DelBtn.Font = Enum.Font.GothamBold
            DelBtn.Parent = Row
            Instance.new("UICorner", DelBtn).CornerRadius = UDim.new(0, 6)
            local s3 = Instance.new("UIStroke", DelBtn); s3.Color = Color3.fromRGB(255, 100, 100); s3.Transparency = 0.5
            
            DelBtn.MouseButton1Click:Connect(function()
                BhopSettings.Binds[key] = nil
                RefreshBindsList()
            end)
        end
    end
    RefreshBindsList()
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and BhopSettings.Binds[input.KeyCode] then
        local mode = BhopSettings.Binds[input.KeyCode]
        if mode == "Toggle" then
            BhopToggle:SetValue(not BhopToggle.State)
        elseif mode == "Hold" then
            BhopToggle:SetValue(true)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and BhopSettings.Binds[input.KeyCode] then
        if BhopSettings.Binds[input.KeyCode] == "Hold" then
            BhopToggle:SetValue(false)
        end
    end
end)

Library:AddButton("Main", "Destroy Map", {Text = "Dangerous!", Warning = true}, function()
    print("Map Destroyed")
end)
