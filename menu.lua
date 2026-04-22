-- [[ СЕРВИСЫ И НАСТРОЙКИ ]]
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

pcall(function()
    local PlayerModule = require(Player.PlayerScripts:WaitForChild("PlayerModule"))
    local Controls = PlayerModule:GetControls()
    if Controls and Controls.activeController and Controls.activeController.isShiftLockEnabled then
        Controls.activeController.isShiftLockEnabled = false
    end
end)
pcall(function() Player.DevEnableMouseLock = false end)

local get_hidden_gui = gethui and gethui or function() return CoreGui end
local uiName = "SketchPastelHub"
if get_hidden_gui():FindFirstChild(uiName) then get_hidden_gui()[uiName]:Destroy() end

local Theme = {
    PastelPink = Color3.fromRGB(255, 175, 200),
    CursorGray = Color3.fromRGB(150, 150, 160),
    White = Color3.fromRGB(255, 255, 255),
    NotchBG = Color3.fromRGB(15, 15, 15),
    DarkFade = Color3.fromRGB(5, 5, 5),
    FadeTransparency = 0.65
}

local Library = { Tabs = {}, ActiveTab = nil, IsOpen = false, Connections = {} }
getgenv().Library = Library

-- Экспортируем Theme и ApplyTextStroke в Library для использования в других файлах (bhop.lua)
Library.Theme = Theme
local function ApplyTextStroke(textInstance)
    local s = Instance.new("UIStroke")
    s.Color = Color3.new(0,0,0)
    s.Thickness = 1.5
    s.Transparency = 0
    s.Parent = textInstance
    return s
end
Library.ApplyTextStroke = ApplyTextStroke

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = uiName
ScreenGui.Parent = get_hidden_gui()
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Enabled = false

local BlockClickFrame = Instance.new("TextButton")
BlockClickFrame.Size = UDim2.new(1,0,1,0)
BlockClickFrame.BackgroundTransparency = 1
BlockClickFrame.Text = ""
BlockClickFrame.Visible = false
BlockClickFrame.Active = true
BlockClickFrame.Parent = ScreenGui

local DarkBackground = Instance.new("Frame")
DarkBackground.Size = UDim2.new(1,0,1,0)
DarkBackground.BackgroundColor3 = Theme.DarkFade
DarkBackground.BackgroundTransparency = 1
DarkBackground.BorderSizePixel = 0
DarkBackground.Parent = ScreenGui

local MainMover = Instance.new("Frame")
MainMover.Size = UDim2.new(1,0,1,0)
MainMover.BackgroundTransparency = 1
MainMover.Parent = ScreenGui

local TopNotch = Instance.new("Frame")
TopNotch.BackgroundColor3 = Theme.NotchBG
TopNotch.Position = UDim2.new(0.5,0,0,-100)
TopNotch.AnchorPoint = Vector2.new(0.5,0)
TopNotch.AutomaticSize = Enum.AutomaticSize.X
TopNotch.Size = UDim2.new(0,0,0,50)
TopNotch.Parent = MainMover
do
    Instance.new("UICorner", TopNotch).CornerRadius = UDim.new(0,16)
    local l = Instance.new("UIListLayout", TopNotch)
    l.FillDirection = Enum.FillDirection.Horizontal
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    l.VerticalAlignment = Enum.VerticalAlignment.Center
    l.Padding = UDim.new(0,15)
    local p = Instance.new("UIPadding", TopNotch)
    p.PaddingLeft = UDim.new(0,20)
    p.PaddingRight = UDim.new(0,20)
    p.PaddingTop = UDim.new(0,10)
end

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(0,420,1,-100)
ContentContainer.Position = UDim2.new(0,50,0,100)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainMover

local CursorBlob = Instance.new("Frame")
CursorBlob.BackgroundColor3 = Color3.new(1,1,1)
CursorBlob.AnchorPoint = Vector2.new(0.5,0.5)
CursorBlob.ZIndex = 2000
CursorBlob.Visible = false
CursorBlob.BorderSizePixel = 0
CursorBlob.Parent = ScreenGui
Instance.new("UICorner", CursorBlob).CornerRadius = UDim.new(1,0)

local CursorStroke = Instance.new("UIStroke")
CursorStroke.Color = Theme.CursorGray
CursorStroke.Thickness = 1.5
CursorStroke.Transparency = 1
CursorStroke.Parent = CursorBlob

local CursorGradient = Instance.new("UIGradient", CursorBlob)

local TooltipBlob = Instance.new("Frame")
TooltipBlob.BackgroundColor3 = Color3.new(1,1,1)
TooltipBlob.AnchorPoint = Vector2.new(0.5,0.5)
TooltipBlob.ZIndex = 1500
TooltipBlob.Visible = false
TooltipBlob.ClipsDescendants = true
TooltipBlob.Parent = ScreenGui

local TooltipCorner = Instance.new("UICorner", TooltipBlob)
local TooltipGradient = Instance.new("UIGradient", TooltipBlob)

local TooltipText = Instance.new("TextLabel")
TooltipText.BackgroundTransparency = 1
TooltipText.TextColor3 = Theme.NotchBG
TooltipText.Font = Enum.Font.GothamBold
TooltipText.TextSize = 13
TooltipText.AnchorPoint = Vector2.new(0.5, 0.5)
TooltipText.Position = UDim2.new(0.5, 0, 0.5, 0)
TooltipText.ZIndex = 1501
TooltipText.Parent = TooltipBlob

local cursorPos, cursorSize = Vector2.new(0,0), Vector2.new(14,14)
local tipPos, tipAnchor, tipSize = Vector2.new(0,0), Vector2.new(0,0), Vector2.new(0,0)
local tipCorner, tipTxtAlpha, smoothPinkWeight = 14, 1, 1
local warningLerp, shellLerp = 0, 0
local hoveredButton, hoveredData, hoverStartTime = nil, nil, 0
local activeTipData, activeTipText, activeTipWarn = nil, "", false
local activeTipSize, tipTargetPos, tipState = Vector2.new(0,0), Vector2.new(0,0), "HIDDEN"
local lingerStart, prevTipState = 0, "HIDDEN"
local pendingTipText, textTransitionAlpha, textTransitionTarget = "", 1, 0

local TOOLTIP_DELAY, TOOLTIP_HEIGHT, SCREEN_PAD, TIP_OFFSET_Y, TIP_OFFSET_X, DEADZONE = 0.6, 28, 12, 32, 10, 4
local clickPulse, gradAngle, currentBreathAmp = 0, 0, 0
local trailFolder = Instance.new("Folder", ScreenGui)

local function QueueTooltip(button, data)
    if hoveredButton ~= button then
        hoveredButton = button
        hoveredData = data
        hoverStartTime = tick()
        tipState = (tipState == "HIDDEN" or tipState == "WAITING" or tipState == "RETURNING") and "WAITING" or "FLYING"
    end
end

local function UnqueueTooltip(button)
    if hoveredButton == button then
        hoveredButton = nil
        hoveredData = nil
        if tipState == "SHOWING" or tipState == "FLYING" then
            tipState = "LINGER"
            lingerStart = tick()
        elseif tipState == "WAITING" then
            tipState = "RETURNING"
        end
    end
end

local function GetTipPos(mouse, tw, vp)
    local th = TOOLTIP_HEIGHT
    return Vector2.new(
        math.clamp(mouse.X + TIP_OFFSET_X, SCREEN_PAD+tw/2, vp.X-SCREEN_PAD-tw/2),
        math.clamp(mouse.Y - TIP_OFFSET_Y - th/2, SCREEN_PAD+th/2, vp.Y-SCREEN_PAD-th/2)
    )
end

local lastTrailPos = Vector2.new(0,0)
local function SpawnTrail(pos, size, isShell, pinkWeight)
    local tr = Instance.new("Frame")
    tr.Size = UDim2.new(0,size,0,size)
    tr.Position = UDim2.new(0,pos.X,0,pos.Y)
    tr.AnchorPoint = Vector2.new(0.5,0.5)
    tr.ZIndex = 99
    tr.Parent = trailFolder
    Instance.new("UICorner", tr).CornerRadius = UDim.new(1,0)
    if isShell > 0.5 then
        tr.BackgroundTransparency = 1
        local str = Instance.new("UIStroke", tr)
        str.Color = Theme.CursorGray
        str.Thickness = 1.5
        TweenService:Create(str, TweenInfo.new(0.25), {Transparency = 1}):Play()
    else
        tr.BackgroundColor3 = (math.random() < pinkWeight) and Theme.PastelPink or Theme.CursorGray
        TweenService:Create(tr, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
    end
    TweenService:Create(tr, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0,2,0,2)}):Play()
    Debris:AddItem(tr, 0.3)
end

table.insert(Library.Connections, UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and Library.IsOpen then
        clickPulse = 1
    end
end))

local renderConnection = RunService.RenderStepped:Connect(function(dt)
    if not Library.IsOpen then
        UserInputService.MouseIconEnabled = true
        CursorBlob.Visible = false
        TooltipBlob.Visible = false
        return
    end

    UserInputService.MouseIconEnabled = false
    local mouse = UserInputService:GetMouseLocation()
    local vp = Camera.ViewportSize

    gradAngle = (gradAngle + dt * 100) % 360
    CursorGradient.Rotation = gradAngle

    local isTooltipOut = (tipState == "FLYING" or tipState == "SHOWING" or tipState == "LINGER")
    smoothPinkWeight = smoothPinkWeight + ((isTooltipOut and 0.05 or 0.8) - smoothPinkWeight) * (dt * 8)
    CursorGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.CursorGray),
        ColorSequenceKeypoint.new(math.clamp(1 - smoothPinkWeight, 0.01, 0.99), Theme.CursorGray),
        ColorSequenceKeypoint.new(1, Theme.PastelPink),
    })

    warningLerp = warningLerp + (((isTooltipOut and activeTipWarn) and 1 or 0) - warningLerp) * (dt * 12)
    shellLerp = shellLerp + (((isTooltipOut and activeTipWarn) and 1 or 0) - shellLerp) * (dt * 12)
    CursorBlob.BackgroundTransparency = shellLerp
    CursorStroke.Transparency = 1 - shellLerp

    if warningLerp > 0.05 then
        TooltipGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.CursorGray),
            ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 235, 245)),
            ColorSequenceKeypoint.new(1, Theme.CursorGray)
        })
        TooltipGradient.Offset = Vector2.new(((tick() * 1.6) % 2) - 1, 0)
    else
        TooltipGradient.Color = ColorSequence.new(Theme.PastelPink)
        TooltipGradient.Offset = Vector2.new(0,0)
    end

    currentBreathAmp = currentBreathAmp + ((isTooltipOut and 1.5 or 0) - currentBreathAmp) * (dt * 12)
    clickPulse = clickPulse + (0 - clickPulse) * (dt * 14)
    cursorPos = cursorPos:Lerp(mouse, dt * 26)
    cursorSize = cursorSize:Lerp(Vector2.new(14 + (math.sin(tick() * 5) * currentBreathAmp) + (clickPulse * 6), 14 + (math.sin(tick() * 5) * currentBreathAmp) + (clickPulse * 6)), dt * 18)

    if (cursorPos - lastTrailPos).Magnitude > 8 then
        SpawnTrail(cursorPos, cursorSize.X * 0.4, shellLerp, smoothPinkWeight)
        lastTrailPos = cursorPos
    end

    CursorBlob.Visible = true
    CursorBlob.Position = UDim2.new(0, cursorPos.X, 0, cursorPos.Y)
    CursorBlob.Size = UDim2.new(0, cursorSize.X, 0, cursorSize.Y)

    local function UpdateTooltipData(newData)
        activeTipData = newData
        local newText = type(newData) == "table" and newData.Text or newData
        activeTipWarn = type(newData) == "table" and newData.Warning or false
        local bounds = TextService:GetTextSize(newText, 13, Enum.Font.GothamBold, Vector2.new(1000,24))
        activeTipSize = Vector2.new(bounds.X + 26, TOOLTIP_HEIGHT)
        if newText ~= activeTipText then
            pendingTipText = newText
            textTransitionAlpha = 1
            textTransitionTarget = 0
        end
    end

    if tipState == "HIDDEN" then
        tipPos = cursorPos
        tipSize = tipSize:Lerp(Vector2.new(0,0), dt * 15)
        if hoveredButton then tipState = "WAITING" end
    elseif tipState == "WAITING" then
        tipPos = cursorPos
        tipSize = tipSize:Lerp(Vector2.new(0,0), dt * 15)
        if not hoveredButton then
            tipState = "RETURNING"
        elseif tick() - hoverStartTime >= TOOLTIP_DELAY then
            UpdateTooltipData(hoveredData)
            tipTargetPos = GetTipPos(mouse, activeTipSize.X, vp)
            tipState = "FLYING"
        end
    elseif tipState == "FLYING" then
        tipTargetPos = GetTipPos(mouse, activeTipSize.X, vp)
        tipPos = tipPos:Lerp(tipTargetPos, dt * 12)
        tipSize = tipSize:Lerp(activeTipSize, dt * 10)
        tipCorner = tipCorner + (6 - tipCorner) * (dt * 12)
        if (tipPos - tipTargetPos).Magnitude < 5 then
            tipAnchor = tipTargetPos
            tipState = "SHOWING"
        end
        if not hoveredButton then tipState = "RETURNING" end
    elseif tipState == "SHOWING" then
        local nt = GetTipPos(mouse, activeTipSize.X, vp)
        if (nt - tipAnchor).Magnitude > DEADZONE then
            tipAnchor = tipAnchor:Lerp(nt, dt * 6)
        end
        tipPos = tipPos:Lerp(tipAnchor, dt * 12)
        tipSize = tipSize:Lerp(activeTipSize, dt * 14)
        if not hoveredButton then
            tipState = "LINGER"
            lingerStart = tick()
        elseif hoveredData ~= activeTipData then
            tipState = "FLYING"
            UpdateTooltipData(hoveredData)
        end
    elseif tipState == "LINGER" then
        if tick() - lingerStart >= 0.15 then
            tipState = hoveredButton and "WAITING" or "RETURNING"
        end
    elseif tipState == "RETURNING" then
        tipPos = tipPos:Lerp(cursorPos, dt * 14)
        tipSize = tipSize:Lerp(Vector2.new(0,0), dt * 12)
        if (tipPos - cursorPos).Magnitude < 8 or tipSize.X < 2 then
            tipState = "HIDDEN"
        end
    end

    prevTipState = tipState

    textTransitionAlpha = textTransitionAlpha + (textTransitionTarget - textTransitionAlpha) * (dt * 22)
    if textTransitionAlpha >= 0.95 and pendingTipText ~= activeTipText then
        activeTipText = pendingTipText
        TooltipText.Text = activeTipText
        textTransitionTarget = 0
    end

    TooltipBlob.Visible = (tipSize.X > 1)
    if TooltipBlob.Visible then
        TooltipBlob.Position = UDim2.new(0, tipPos.X, 0, tipPos.Y)
        TooltipBlob.Size = UDim2.new(0, tipSize.X, 0, tipSize.Y)
        TooltipCorner.CornerRadius = UDim.new(0, tipCorner)
        TooltipText.TextTransparency = math.max(0, textTransitionAlpha)
    end
end)
table.insert(Library.Connections, renderConnection)

-- [[ МЕТОДЫ БИБЛИОТЕКИ ]]
function Library:CreateTab(name)
    local TabBtn = Instance.new("TextButton")
    TabBtn.BackgroundTransparency = 1
    TabBtn.Size = UDim2.new(0,80,1,0)
    TabBtn.Text = name:lower()
    TabBtn.TextColor3 = Theme.White
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.TextSize = 15
    TabBtn.Parent = TopNotch
    ApplyTextStroke(TabBtn)

    local PageGroup = Instance.new("CanvasGroup")
    PageGroup.Size = UDim2.new(1,0,1,0)
    PageGroup.BackgroundTransparency = 1
    PageGroup.GroupTransparency = 1
    PageGroup.Visible = false
    PageGroup.Parent = ContentContainer

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1,0,1,0)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.ScrollBarThickness = 0
    Scroll.Parent = PageGroup
    Instance.new("UIPadding", Scroll).PaddingLeft = UDim.new(0,10)
    Instance.new("UIPadding", Scroll).PaddingTop = UDim.new(0,10)
    local ScrollLayout = Instance.new("UIListLayout", Scroll)
    ScrollLayout.Padding = UDim.new(0,14)
    ScrollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    ScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0,0,0, ScrollLayout.AbsoluteContentSize.Y + 20)
    end)

    TabBtn.MouseButton1Click:Connect(function()
        if Library.ActiveTab == PageGroup then return end
        for _, t in pairs(Library.Tabs) do
            TweenService:Create(t.Btn, TweenInfo.new(0.2), {TextColor3 = Theme.White}):Play()
            if t.PageGroup.Visible then
                TweenService:Create(t.PageGroup, TweenInfo.new(0.15), {GroupTransparency = 1}):Play()
                task.delay(0.15, function() t.PageGroup.Visible = false end)
            end
        end
        Library.ActiveTab = PageGroup
        PageGroup.Visible = true
        TweenService:Create(PageGroup, TweenInfo.new(0.25), {GroupTransparency = 0}):Play()
        TweenService:Create(TabBtn, TweenInfo.new(0.3), {TextColor3 = Theme.PastelPink}):Play()
    end)

    Library.Tabs[name] = {Btn = TabBtn, PageGroup = PageGroup, Scroll = Scroll}
    if not Library.ActiveTab then
        Library.ActiveTab = PageGroup
        PageGroup.Visible = true
        PageGroup.GroupTransparency = 0
        TabBtn.TextColor3 = Theme.PastelPink
    end
end

function Library:AddButton(tabName, text, tooltipData, callback)
    local page = Library.Tabs[tabName].Scroll
    local Btn = Instance.new("TextButton")
    Btn.BackgroundTransparency = 1
    Btn.Size = UDim2.new(1,0,0,32)
    Btn.Text = text:lower()
    Btn.TextColor3 = Theme.White
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextSize = 16
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.Parent = page
    ApplyTextStroke(Btn)
    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {TextColor3 = Theme.PastelPink}):Play()
        if tooltipData then QueueTooltip(Btn, tooltipData) end
    end)
    Btn.MouseLeave:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {TextColor3 = Theme.White}):Play()
        if tooltipData then UnqueueTooltip(Btn) end
    end)
    Btn.MouseButton1Click:Connect(callback)
end

function Library:AddToggle(tabName, text, tooltipData, default, callback)
    local page = Library.Tabs[tabName].Scroll
    local state = default or false
    local Btn = Instance.new("TextButton")
    Btn.BackgroundTransparency = 1
    Btn.Size = UDim2.new(1,0,0,32)
    Btn.Text = (state and "> " or "") .. text:lower()
    Btn.TextColor3 = state and Theme.PastelPink or Theme.White
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextSize = 16
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.Parent = page
    ApplyTextStroke(Btn)
    Btn.MouseEnter:Connect(function()
        if not state then
            TweenService:Create(Btn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(200,200,200)}):Play()
        end
        if tooltipData then QueueTooltip(Btn, tooltipData) end
    end)
    Btn.MouseLeave:Connect(function()
        if not state then
            TweenService:Create(Btn, TweenInfo.new(0.2), {TextColor3 = Theme.White}):Play()
        end
        if tooltipData then UnqueueTooltip(Btn) end
    end)
    Btn.MouseButton1Click:Connect(function()
        state = not state
        Btn.Text = (state and "> " or "") .. text:lower()
        TweenService:Create(Btn, TweenInfo.new(0.2), {TextColor3 = state and Theme.PastelPink or Theme.White}):Play()
        callback(state)
    end)
end

function Library:AddSlider(tabName, text, min, max, default, callback)
    local page = Library.Tabs[tabName].Scroll
    local value = math.clamp(default, min, max)
    local SliderFrame = Instance.new("Frame")
    SliderFrame.BackgroundTransparency = 1
    SliderFrame.Size = UDim2.new(1,0,0,45)
    SliderFrame.Parent = page
    local SliderText = Instance.new("TextLabel")
    SliderText.BackgroundTransparency = 1
    SliderText.Size = UDim2.new(1,0,0,20)
    SliderText.Text = text:lower()..": "..tostring(value)
    SliderText.TextColor3 = Theme.White
    SliderText.Font = Enum.Font.GothamMedium
    SliderText.TextSize = 14
    SliderText.TextXAlignment = Enum.TextXAlignment.Left
    SliderText.Parent = SliderFrame
    ApplyTextStroke(SliderText)
    local BG = Instance.new("Frame")
    BG.BackgroundColor3 = Theme.NotchBG
    BG.Size = UDim2.new(1,-20,0,6)
    BG.Position = UDim2.new(0,0,0,28)
    BG.Parent = SliderFrame
    Instance.new("UICorner", BG).CornerRadius = UDim.new(1,0)
    local Fill = Instance.new("Frame")
    Fill.BackgroundColor3 = Theme.PastelPink
    Fill.Size = UDim2.new((value-min)/(max-min),0,1,0)
    Fill.Parent = BG
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1,0)
    local Hitbox = Instance.new("TextButton")
    Hitbox.Size = UDim2.new(1,0,1,0)
    Hitbox.BackgroundTransparency = 1
    Hitbox.Text = ""
    Hitbox.Parent = SliderFrame
    local isDragging = false
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - BG.AbsolutePosition.X) / BG.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max-min)*pos)
        SliderText.Text = text:lower()..": "..tostring(value)
        TweenService:Create(Fill, TweenInfo.new(0.1), {Size = UDim2.new(pos,0,1,0)}):Play()
        callback(value)
    end
    Hitbox.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            updateSlider(i)
        end
    end)
    table.insert(Library.Connections, UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = false end
    end))
    table.insert(Library.Connections, UserInputService.InputChanged:Connect(function(i)
        if isDragging and i.UserInputType == Enum.UserInputType.MouseMovement then updateSlider(i) end
    end))
end

function Library:ToggleUI()
    Library.IsOpen = not Library.IsOpen
    local twInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quart)
    if Library.IsOpen then
        ScreenGui.Enabled = true
        BlockClickFrame.Visible = true
        pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
        TweenService:Create(DarkBackground, twInfo, {BackgroundTransparency = Theme.FadeTransparency}):Play()
        TweenService:Create(TopNotch, twInfo, {Position = UDim2.new(0.5, 0, 0, -10)}):Play()
        if Library.ActiveTab then TweenService:Create(Library.ActiveTab, twInfo, {GroupTransparency = 0}):Play() end
        cursorPos = UserInputService:GetMouseLocation()
    else
        BlockClickFrame.Visible = false
        pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
        TweenService:Create(DarkBackground, twInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(TopNotch, twInfo, {Position = UDim2.new(0.5, 0, 0, -100)}):Play()
        if Library.ActiveTab then TweenService:Create(Library.ActiveTab, twInfo, {GroupTransparency = 1}):Play() end
        task.delay(0.35, function() if not Library.IsOpen then ScreenGui.Enabled = false end end)
    end
end

table.insert(Library.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        Library:ToggleUI()
    end
end))

-- ==================== НОВЫЕ МЕТОДЫ ДЛЯ Bhop ====================

-- [[ МОДАЛЬНЫЕ ОКНА ]]
local activeModal = nil
local modalOverlay = Instance.new("Frame")
modalOverlay.Size = UDim2.new(1,0,1,0)
modalOverlay.BackgroundColor3 = Color3.new(0,0,0)
modalOverlay.BackgroundTransparency = 1
modalOverlay.BorderSizePixel = 0
modalOverlay.ZIndex = 100
modalOverlay.Visible = false
modalOverlay.Parent = ScreenGui

Instance.new("UICorner", modalOverlay).CornerRadius = UDim.new(0,16)
local modalButton = Instance.new("TextButton")
modalButton.Size = UDim2.new(1,0,1,0)
modalButton.BackgroundTransparency = 1
modalButton.Text = ""
modalButton.ZIndex = 101
modalButton.Parent = modalOverlay

local modalContent = Instance.new("Frame")
modalContent.Size = UDim2.new(0,300,0,0)
modalContent.AnchorPoint = Vector2.new(0.5,0.5)
modalContent.Position = UDim2.new(0.5,0,0.5,0)
modalContent.BackgroundColor3 = Theme.NotchBG
modalContent.BorderSizePixel = 0
modalContent.ZIndex = 102
modalContent.Visible = false
modalContent.Parent = modalOverlay
Instance.new("UICorner", modalContent).CornerRadius = UDim.new(0,12)

local modalTitle = Instance.new("TextLabel")
modalTitle.Size = UDim2.new(1,-20,0,30)
modalTitle.Position = UDim2.new(0,10,0,10)
modalTitle.BackgroundTransparency = 1
modalTitle.Text = "Settings"
modalTitle.TextColor3 = Theme.White
modalTitle.Font = Enum.Font.GothamBold
modalTitle.TextSize = 16
modalTitle.TextXAlignment = Enum.TextXAlignment.Left
modalTitle.ZIndex = 103
modalTitle.Parent = modalContent
ApplyTextStroke(modalTitle)

local modalClose = Instance.new("TextButton")
modalClose.Size = UDim2.new(0,30,0,30)
modalClose.Position = UDim2.new(1,-35,0,10)
modalClose.BackgroundTransparency = 1
modalClose.Text = "✕"
modalClose.TextColor3 = Theme.White
modalClose.Font = Enum.Font.GothamBold
modalClose.TextSize = 18
modalClose.ZIndex = 103
modalClose.Parent = modalContent
ApplyTextStroke(modalClose)

local modalContainer = Instance.new("ScrollingFrame")
modalContainer.Size = UDim2.new(1,-20,0,200)
modalContainer.Position = UDim2.new(0,10,0,50)
modalContainer.BackgroundTransparency = 1
modalContainer.BorderSizePixel = 0
modalContainer.ScrollBarThickness = 2
modalContainer.ScrollBarImageColor3 = Theme.PastelPink
modalContainer.CanvasSize = UDim2.new(0,0,0,0)
modalContainer.ZIndex = 103
modalContainer.Parent = modalContent

local modalList = Instance.new("UIListLayout", modalContainer)
modalList.Padding = UDim.new(0,10)
modalList.HorizontalAlignment = Enum.HorizontalAlignment.Center
modalList.SortOrder = Enum.SortOrder.LayoutOrder

modalList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    modalContainer.CanvasSize = UDim2.new(0,0,0,modalList.AbsoluteContentSize.Y + 20)
end)

local function CloseModal()
    if activeModal then
        activeModal = nil
        TweenService:Create(modalOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        TweenService:Create(modalContent, TweenInfo.new(0.2), {BackgroundTransparency = 1, Size = UDim2.new(0,0,0,0)}):Play()
        task.wait(0.2)
        modalOverlay.Visible = false
        modalContent.Visible = false
        -- Очистка контента
        for _, child in ipairs(modalContainer:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") then
                child:Destroy()
            end
        end
    end
end

modalButton.MouseButton1Click:Connect(CloseModal)
modalClose.MouseButton1Click:Connect(CloseModal)

function Library:ShowModal(title, elements)
    if activeModal then CloseModal() end
    activeModal = true
    modalTitle.Text = title
    -- Добавляем элементы в modalContainer
    for _, element in ipairs(elements) do
        element.Parent = modalContainer
    end
    modalOverlay.Visible = true
    modalContent.Visible = true
    TweenService:Create(modalOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()
    TweenService:Create(modalContent, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0, Size = UDim2.new(0,300,0,modalList.AbsoluteContentSize.Y + 80)}):Play()
end

-- [[ ОКНО БИНДОВ ]]
local bindModal = Instance.new("Frame")
bindModal.Size = UDim2.new(1,0,1,0)
bindModal.BackgroundColor3 = Color3.new(0,0,0)
bindModal.BackgroundTransparency = 1
bindModal.BorderSizePixel = 0
bindModal.ZIndex = 200
bindModal.Visible = false
bindModal.Parent = ScreenGui

Instance.new("UICorner", bindModal).CornerRadius = UDim.new(0,16)
local bindOverlayButton = Instance.new("TextButton")
bindOverlayButton.Size = UDim2.new(1,0,1,0)
bindOverlayButton.BackgroundTransparency = 1
bindOverlayButton.Text = ""
bindOverlayButton.ZIndex = 201
bindOverlayButton.Parent = bindModal

local bindContent = Instance.new("Frame")
bindContent.Size = UDim2.new(0,350,0,0)
bindContent.AnchorPoint = Vector2.new(0.5,0.5)
bindContent.Position = UDim2.new(0.5,0,0.5,0)
bindContent.BackgroundColor3 = Theme.NotchBG
bindContent.BorderSizePixel = 0
bindContent.ZIndex = 202
bindContent.Visible = false
bindContent.Parent = bindModal
Instance.new("UICorner", bindContent).CornerRadius = UDim.new(0,12)

local bindTitle = Instance.new("TextLabel")
bindTitle.Size = UDim2.new(1,-20,0,30)
bindTitle.Position = UDim2.new(0,10,0,10)
bindTitle.BackgroundTransparency = 1
bindTitle.Text = "Keybinds"
bindTitle.TextColor3 = Theme.White
bindTitle.Font = Enum.Font.GothamBold
bindTitle.TextSize = 16
bindTitle.TextXAlignment = Enum.TextXAlignment.Left
bindTitle.ZIndex = 203
bindTitle.Parent = bindContent
ApplyTextStroke(bindTitle)

local bindClose = Instance.new("TextButton")
bindClose.Size = UDim2.new(0,30,0,30)
bindClose.Position = UDim2.new(1,-35,0,10)
bindClose.BackgroundTransparency = 1
bindClose.Text = "✕"
bindClose.TextColor3 = Theme.White
bindClose.Font = Enum.Font.GothamBold
bindClose.TextSize = 18
bindClose.ZIndex = 203
bindClose.Parent = bindContent
ApplyTextStroke(bindClose)

local bindContainer = Instance.new("ScrollingFrame")
bindContainer.Size = UDim2.new(1,-20,0,250)
bindContainer.Position = UDim2.new(0,10,0,50)
bindContainer.BackgroundTransparency = 1
bindContainer.BorderSizePixel = 0
bindContainer.ScrollBarThickness = 2
bindContainer.ScrollBarImageColor3 = Theme.PastelPink
bindContainer.CanvasSize = UDim2.new(0,0,0,0)
bindContainer.ZIndex = 203
bindContainer.Parent = bindContent

local bindList = Instance.new("UIListLayout", bindContainer)
bindList.Padding = UDim.new(0,8)
bindList.HorizontalAlignment = Enum.HorizontalAlignment.Center
bindList.SortOrder = Enum.SortOrder.LayoutOrder

bindList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    bindContainer.CanvasSize = UDim2.new(0,0,0,bindList.AbsoluteContentSize.Y + 20)
end)

local addBindButton = Instance.new("TextButton")
addBindButton.Size = UDim2.new(1,-10,0,30)
addBindButton.Position = UDim2.new(0,5,0,bindContainer.Position.Y.Offset + bindContainer.Size.Y.Offset + 10)
addBindButton.BackgroundColor3 = Theme.PastelPink
addBindButton.Text = "+ Add Bind"
addBindButton.TextColor3 = Theme.NotchBG
addBindButton.Font = Enum.Font.GothamBold
addBindButton.TextSize = 14
addBindButton.ZIndex = 203
addBindButton.Parent = bindContent
Instance.new("UICorner", addBindButton).CornerRadius = UDim.new(0,6)
ApplyTextStroke(addBindButton)

local function CloseBindModal()
    if bindContent.Visible then
        TweenService:Create(bindModal, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        TweenService:Create(bindContent, TweenInfo.new(0.2), {BackgroundTransparency = 1, Size = UDim2.new(0,0,0,0)}):Play()
        task.wait(0.2)
        bindModal.Visible = false
        bindContent.Visible = false
        -- Очистка
        for _, child in ipairs(bindContainer:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
    end
end

bindOverlayButton.MouseButton1Click:Connect(CloseBindModal)
bindClose.MouseButton1Click:Connect(CloseBindModal)

function Library:ShowBindWindow(bindData)
    CloseBindModal()
    local function RefreshBindList()
        for _, child in ipairs(bindContainer:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        local binds = bindData.getBinds()
        for i, bind in ipairs(binds) do
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1,0,0,35)
            frame.BackgroundTransparency = 1
            frame.BorderSizePixel = 0
            frame.LayoutOrder = i
            frame.Parent = bindContainer

            local keyLabel = Instance.new("TextLabel")
            keyLabel.Size = UDim2.new(0,80,1,0)
            keyLabel.BackgroundColor3 = Theme.DarkFade
            keyLabel.Text = bind.key
            keyLabel.TextColor3 = Theme.White
            keyLabel.Font = Enum.Font.GothamBold
            keyLabel.TextSize = 14
            keyLabel.Parent = frame
            Instance.new("UICorner", keyLabel).CornerRadius = UDim.new(0,6)

            local modeButton = Instance.new("TextButton")
            modeButton.Size = UDim2.new(0,70,1,0)
            modeButton.Position = UDim2.new(0,85,0,0)
            modeButton.BackgroundColor3 = bind.mode == "toggle" and Theme.PastelPink or Theme.CursorGray
            modeButton.Text = bind.mode
            modeButton.TextColor3 = Theme.NotchBG
            modeButton.Font = Enum.Font.GothamBold
            modeButton.TextSize = 12
            modeButton.Parent = frame
            Instance.new("UICorner", modeButton).CornerRadius = UDim.new(0,6)

            modeButton.MouseButton1Click:Connect(function()
                local newMode = bind.mode == "toggle" and "hold" or "toggle"
                bind.mode = newMode
                modeButton.Text = newMode
                modeButton.BackgroundColor3 = newMode == "toggle" and Theme.PastelPink or Theme.CursorGray
                if bindData.onModeChange then
                    bindData.onModeChange(i, newMode)
                end
            end)

            local deleteButton = Instance.new("TextButton")
            deleteButton.Size = UDim2.new(0,30,1,0)
            deleteButton.Position = UDim2.new(1,-30,0,0)
            deleteButton.BackgroundColor3 = Color3.fromRGB(255,80,80)
            deleteButton.Text = "✕"
            deleteButton.TextColor3 = Theme.White
            deleteButton.Font = Enum.Font.GothamBold
            deleteButton.TextSize = 16
            deleteButton.Parent = frame
            Instance.new("UICorner", deleteButton).CornerRadius = UDim.new(0,6)

            deleteButton.MouseButton1Click:Connect(function()
                bindData.onRemove(i)
                RefreshBindList()
            end)
        end
    end

    RefreshBindList()
    addBindButton.MouseButton1Click:Connect(function()
        local waiting = Instance.new("TextLabel")
        waiting.Size = UDim2.new(1,0,1,0)
        waiting.BackgroundColor3 = Color3.new(0,0,0)
        waiting.BackgroundTransparency = 0.7
        waiting.Text = "Press any key..."
        waiting.TextColor3 = Theme.White
        waiting.Font = Enum.Font.GothamBold
        waiting.TextSize = 18
        waiting.ZIndex = 250
        waiting.Parent = bindModal
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                local keyName = input.KeyCode.Name
                bindData.onAdd(keyName, "toggle")
                RefreshBindList()
                conn:Disconnect()
                waiting:Destroy()
            end
        end)
        task.delay(5, function()
            if conn then conn:Disconnect() end
            if waiting then waiting:Destroy() end
        end)
    end)

    bindModal.Visible = true
    bindContent.Visible = true
    TweenService:Create(bindModal, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()
    TweenService:Create(bindContent, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0, Size = UDim2.new(0,350,0,350)}):Play()
end

-- [[ МЕТОД ДЛЯ ФУНКЦИЙ С НАСТРОЙКАМИ ]]
function Library:AddFeatureButton(tabName, text, tooltipData, options)
    local page = Library.Tabs[tabName].Scroll
    local Btn = Instance.new("TextButton")
    Btn.BackgroundTransparency = 1
    Btn.Size = UDim2.new(1,0,0,32)
    Btn.Text = text:lower()
    Btn.TextColor3 = Theme.White
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextSize = 16
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.Parent = page
    ApplyTextStroke(Btn)

    local hover = false
    Btn.MouseEnter:Connect(function()
        hover = true
        TweenService:Create(Btn, TweenInfo.new(0.2), {TextColor3 = Theme.PastelPink}):Play()
        if tooltipData then QueueTooltip(Btn, tooltipData) end
    end)
    Btn.MouseLeave:Connect(function()
        hover = false
        TweenService:Create(Btn, TweenInfo.new(0.2), {TextColor3 = Theme.White}):Play()
        if tooltipData then UnqueueTooltip(Btn) end
    end)

    -- Обработка кликов
    Btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if options.onClick then options.onClick() end
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            if options.onRightClick then options.onRightClick() end
        elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
            if options.onMiddleClick then options.onMiddleClick() end
        end
    end)

    return Btn
end

print("SketchPastelHub Loaded")
