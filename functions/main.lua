local Library = getgenv().Library

-- Создаем вкладку
Library:CreateTab("Main")

-- Добавляем обычную кнопку
Library:AddButton("Main", "Force Update", "Force update the current target", function() 
    print("Цель обновлена!") 
end)

-- Добавляем переключатель
Library:AddToggle("Main", "Aim", "Automatically aim at enemies", false, function(state) 
    print("AimBot статус:", state)
end)

-- Добавляем слайдер
Library:AddSlider("Main", "FOV Size", 10, 300, 90, function(value) 
    print("FOV теперь:", value)
end)