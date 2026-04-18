-- Файл: walkspeed.lua

return {
    Tab = "Players",            -- В какой вкладке будет функция (имя из Config.Tabs)
    Name = "Super Speed",       -- Название, которое увидит пользователь
    Type = "Toggle",            -- Тип элемента: "Toggle" (переключатель) или "Button" (кнопка)
    
    -- Сама логика функции.
    -- Для Toggle, в 'state' приходит true (включено) или false (выключено).
    -- Для Button, аргументов нет.
    Callback = function(state)
        local Player = game:GetService("Players").LocalPlayer
        local Character = Player.Character or Player.CharacterAdded:Wait()
        local Humanoid = Character:WaitForChild("Humanoid")

        if Humanoid then
            Humanoid.WalkSpeed = state and 100 or 16
        end
    end
}
