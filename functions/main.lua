local Library = getgenv().Library

Library:AddToggle("Main", "Silent Aim", "Automatically hits targets", false, function(v)
    print("Silent Aim:", v)
end)

Library:AddButton("Main", "Destroy Map", {Text = "Dangerous!", Warning = true}, function()
    print("Map Destroyed")
end)
