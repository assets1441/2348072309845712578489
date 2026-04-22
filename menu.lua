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

local function ApplyTextStroke(textInstance) 
	local s = Instance.new("UIStroke") 
	s.Color = Color3.new(0,0,0); s.Thickness = 1.5; s.Transparency = 0 
	s.Parent = textInstance 
	return s 
end 

local ScreenGui = Instance.new("ScreenGui") 
ScreenGui.Name = uiName; ScreenGui.Parent = get_hidden_gui() 
ScreenGui.IgnoreGuiInset = true; ScreenGui.ResetOnSpawn = false 
ScreenGui.Enabled = false 

local BlockClickFrame = Instance.new("TextButton") 
BlockClickFrame.Size = UDim2.new(1,0,1,0); BlockClickFrame.BackgroundTransparency = 1 
BlockClickFrame.Text = ""; BlockClickFrame.Visible = false; BlockClickFrame.Active = true 
BlockClickFrame.Parent = ScreenGui 

local DarkBackground = Instance.new("Frame") 
DarkBackground.Size = UDim2.new(1,0,1,0); DarkBackground.BackgroundColor3 = Theme.DarkFade 
DarkBackground.BackgroundTransparency = 1; DarkBackground.BorderSizePixel = 0 
DarkBackground.Parent = ScreenGui 

local MainMover = Instance.new("Frame") 
MainMover.Size = UDim2.new(1,0,1,0); MainMover.BackgroundTransparency = 1 
MainMover.Parent = ScreenGui 

local TopNotch = Instance.new("Frame") 
TopNotch.BackgroundColor3 = Theme.NotchBG 
TopNotch.Position = UDim2.new(0.5,0,0,-100); TopNotch.AnchorPoint = Vector2.new(0.5,0) 
TopNotch.AutomaticSize = Enum.AutomaticSize.X; TopNotch.Size = UDim2.new(0,0,0,50) 
TopNotch.Parent = MainMover 
do 
	Instance.new("UICorner", TopNotch).CornerRadius = UDim.new(0,16) 
	local l = Instance.new("UIListLayout", TopNotch) 
	l.FillDirection = Enum.FillDirection.Horizontal 
	l.HorizontalAlignment = Enum.HorizontalAlignment.Center 
	l.VerticalAlignment = Enum.VerticalAlignment.Center 
	l.Padding = UDim.new(0,15) 
	local p = Instance.new("UIPadding", TopNotch) 
	p.PaddingLeft = UDim.new(0,20); p.PaddingRight = UDim.new(0,20); p.PaddingTop = UDim.new(0,10) 
end 

local ContentContainer = Instance.new("Frame") 
ContentContainer.Size = UDim2.new(0,420,1,-100); ContentContainer.Position = UDim2.new(0,50,0,100) 
ContentContainer.BackgroundTransparency = 1; ContentContainer.Parent = MainMover 

-- МОДАЛЬНЫЕ ОКНА (НАСТРОЙКИ И БИНДЫ)
local ModalOverlay = Instance.new("TextButton") -- Сделано кнопкой, чтобы клик по фону закрывал меню
ModalOverlay.Size = UDim2.new(1,0,1,0); ModalOverlay.BackgroundColor3 = Color3.new(0,0,0); ModalOverlay.BackgroundTransparency = 1
ModalOverlay.Text = ""; ModalOverlay.AutoButtonColor = false
ModalOverlay.Visible = false; ModalOverlay.ZIndex = 3000; ModalOverlay.Parent = ScreenGui

local ModalWindow = Instance.new("Frame")
ModalWindow.Size = UDim2.new(0,350,0,400); ModalWindow.Position = UDim2.new(0.5,0,0.5,10); ModalWindow.AnchorPoint = Vector2.new(0.5,0.5)
ModalWindow.BackgroundColor3 = Theme.NotchBG; ModalWindow.ZIndex = 3001; ModalWindow.Active = true; ModalWindow.Parent = ModalOverlay
Instance.new("UICorner", ModalWindow).CornerRadius = UDim.new(0,12)
ApplyTextStroke(ModalWindow)

local ModalTitle = Instance.new("TextLabel")
ModalTitle.Size = UDim2.new(1,0,0,40); ModalTitle.BackgroundTransparency = 1; ModalTitle.Text = "Settings"
ModalTitle.TextColor3 = Theme.PastelPink; ModalTitle.Font = Enum.Font.GothamBold; ModalTitle.TextSize = 18; ModalTitle.ZIndex = 3002; ModalTitle.Parent = ModalWindow

local ModalScroll = Instance.new("ScrollingFrame")
ModalScroll.Size = UDim2.new(1,0,1,-50); ModalScroll.Position = UDim2.new(0,0,0,40); ModalScroll.BackgroundTransparency = 1
ModalScroll.BorderSizePixel = 0; ModalScroll.ScrollBarThickness = 2; ModalScroll.ZIndex = 3002; ModalScroll.Parent = ModalWindow
local ModalLayout = Instance.new("UIListLayout", ModalScroll)
ModalLayout.Padding = UDim.new(0, 10); ModalLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ModalLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() ModalScroll.CanvasSize = UDim2.new(0,0,0,ModalLayout.AbsoluteContentSize.Y + 20) end)
Instance.new("UIPadding", ModalScroll).PaddingTop = UDim.new(0,5)

-- Клик вне окна закрывает его
ModalOverlay.MouseButton1Click:Connect(function() Library:CloseModal() end)

function Library:OpenModal(title)
    for _, child in pairs(ModalScroll:GetChildren()) do if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end end
    ModalTitle.Text = title:upper()
    ModalOverlay.Visible = true
    TweenService:Create(ModalOverlay, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {BackgroundTransparency = 0.4}):Play()
    TweenService:Create(ModalWindow, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0.5,0,0.5,0)}):Play()
    return ModalScroll
end

function Library:CloseModal()
    TweenService:Create(ModalOverlay, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {BackgroundTransparency = 1}):Play()
    TweenService:Create(ModalWindow, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Position = UDim2.new(0.5,0,0.5,10)}):Play()
    task.delay(0.2, function() ModalOverlay.Visible = false end)
end

function Library:AddModalSlider(parent, text, min, max, default, formatFunc, callback)
    local val = default
    local Frame = Instance.new("Frame"); Frame.Size = UDim2.new(0.9,0,0,45); Frame.BackgroundTransparency = 1; Frame.ZIndex = 3003; Frame.Parent = parent
    local Label = Instance.new("TextLabel"); Label.Size = UDim2.new(1,0,0,20); Label.BackgroundTransparency = 1
    Label.Text = text..": "..(formatFunc and formatFunc(val) or val); Label.TextColor3 = Theme.White; Label.Font = Enum.Font.GothamMedium; Label.TextSize = 14; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.ZIndex = 3003; Label.Parent = Frame
    local BG = Instance.new("Frame"); BG.Size = UDim2.new(1,0,0,6); BG.Position = UDim2.new(0,0,0,28); BG.BackgroundColor3 = Color3.new(0.2,0.2,0.2); BG.ZIndex = 3003; BG.Parent = Frame; Instance.new("UICorner", BG).CornerRadius = UDim.new(1,0)
    local Fill = Instance.new("Frame"); Fill.Size = UDim2.new((val-min)/(max-min),0,1,0); Fill.BackgroundColor3 = Theme.PastelPink; Fill.ZIndex = 3004; Fill.Parent = BG; Instance.new("UICorner", Fill).CornerRadius = UDim.new(1,0)
    local Btn = Instance.new("TextButton"); Btn.Size = UDim2.new(1,0,1,0); Btn.BackgroundTransparency = 1; Btn.Text = ""; Btn.ZIndex = 3005; Btn.Parent = Frame
    
    local dragging = false
    local function update(input)
        local rawPos = math.clamp((input.Position.X - BG.AbsolutePosition.X) / BG.AbsoluteSize.X, 0, 1)
        val = math.round(min + (max-min)*rawPos) -- Делаем слайдер точечным (целые числа)
        local snapPos = (val - min) / (max - min)
        
        Label.Text = text..": "..(formatFunc and formatFunc(val) or val)
        Fill.Size = UDim2.new(snapPos,0,1,0)
        callback(val)
    end
    Btn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update(i) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i) end end)
end

-- КУРСОР И ПОДСКАЗКИ
local CursorBlob = Instance.new("Frame") 
CursorBlob.BackgroundColor3 = Color3.new(1,1,1); CursorBlob.AnchorPoint = Vector2.new(0.5,0.5); CursorBlob.ZIndex = 4000; CursorBlob.Visible = false; CursorBlob.BorderSizePixel = 0; CursorBlob.Parent = ScreenGui 
Instance.new("UICorner", CursorBlob).CornerRadius = UDim.new(1,0) 
local CursorStroke = Instance.new("UIStroke", CursorBlob); CursorStroke.Color = Theme.CursorGray; CursorStroke.Thickness = 1.5; CursorStroke.Transparency = 1 
local CursorGradient = Instance.new("UIGradient", CursorBlob) 
local TooltipBlob = Instance.new("Frame"); TooltipBlob.BackgroundColor3 = Color3.new(1,1,1); TooltipBlob.AnchorPoint = Vector2.new(0.5,0.5); TooltipBlob.ZIndex = 3500; TooltipBlob.Visible = false; TooltipBlob.ClipsDescendants = true; TooltipBlob.Parent = ScreenGui 
local TooltipCorner = Instance.new("UICorner", TooltipBlob); local TooltipGradient = Instance.new("UIGradient", TooltipBlob) 
local TooltipText = Instance.new("TextLabel"); TooltipText.BackgroundTransparency = 1; TooltipText.TextColor3 = Theme.NotchBG; TooltipText.Font = Enum.Font.GothamBold; TooltipText.TextSize = 13; TooltipText.AnchorPoint = Vector2.new(0.5, 0.5); TooltipText.Position = UDim2.new(0.5, 0, 0.5, 0); TooltipText.ZIndex = 3501; TooltipText.Parent = TooltipBlob 

local cursorPos, cursorSize, tipPos, tipAnchor, tipSize = Vector2.new(0,0), Vector2.new(14,14), Vector2.new(0,0), Vector2.new(0,0), Vector2.new(0,0)
local tipCorner, tipTxtAlpha, smoothPinkWeight, warningLerp, shellLerp = 14, 1, 1, 0, 0 
local hoveredButton, hoveredData, hoverStartTime = nil, nil, 0 
local activeTipData, activeTipText, activeTipWarn = nil, "", false 
local activeTipSize, tipTargetPos, tipState = Vector2.new(0,0), Vector2.new(0,0), "HIDDEN" 
local lingerStart, prevTipState, pendingTipText, textTransitionAlpha, textTransitionTarget = 0, "HIDDEN", "", 1, 0 
local TOOLTIP_DELAY, TOOLTIP_HEIGHT, SCREEN_PAD, TIP_OFFSET_Y, TIP_OFFSET_X, DEADZONE = 0.6, 28, 12, 32, 10, 4 
local clickPulse, gradAngle, currentBreathAmp = 0, 0, 0 
local trailFolder = Instance.new("Folder", ScreenGui) 

local function QueueTooltip(button, data) if hoveredButton ~= button then hoveredButton = button; hoveredData = data; hoverStartTime = tick(); tipState = (tipState == "HIDDEN" or tipState == "WAITING" or tipState == "RETURNING") and "WAITING" or "FLYING" end end 
local function UnqueueTooltip(button) if hoveredButton == button then hoveredButton = nil; hoveredData = nil; if tipState == "SHOWING" or tipState == "FLYING" then tipState = "LINGER"; lingerStart = tick() elseif tipState == "WAITING" then tipState = "RETURNING" end end end 
local function GetTipPos(mouse, tw, vp) local th = TOOLTIP_HEIGHT return Vector2.new(math.clamp(mouse.X + TIP_OFFSET_X, SCREEN_PAD+tw/2, vp.X-SCREEN_PAD-tw/2), math.clamp(mouse.Y - TIP_OFFSET_Y - th/2, SCREEN_PAD+th/2, vp.Y-SCREEN_PAD-th/2)) end 

local lastTrailPos = Vector2.new(0,0) 
local function SpawnTrail(pos, size, isShell, pinkWeight) 
	local tr = Instance.new("Frame"); tr.Size = UDim2.new(0,size,0,size); tr.Position = UDim2.new(0,pos.X,0,pos.Y); tr.AnchorPoint = Vector2.new(0.5,0.5); tr.ZIndex = 99; tr.Parent = trailFolder 
	Instance.new("UICorner", tr).CornerRadius = UDim.new(1,0) 
	if isShell > 0.5 then tr.BackgroundTransparency = 1; local str = Instance.new("UIStroke", tr); str.Color = Theme.CursorGray; str.Thickness = 1.5; TweenService:Create(str, TweenInfo.new(0.25), {Transparency = 1}):Play() else tr.BackgroundColor3 = (math.random() < pinkWeight) and Theme.PastelPink or Theme.CursorGray; TweenService:Create(tr, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play() end 
	TweenService:Create(tr, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0,2,0,2)}):Play(); Debris:AddItem(tr, 0.3) 
end 

table.insert(Library.Connections, UserInputService.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 and Library.IsOpen then clickPulse = 1 end end)) 

local renderConnection = RunService.RenderStepped:Connect(function(dt) 
	if not Library.IsOpen then UserInputService.MouseIconEnabled = true; CursorBlob.Visible = false; TooltipBlob.Visible = false; return end 
	UserInputService.MouseIconEnabled = false; local mouse = UserInputService:GetMouseLocation(); local vp = Camera.ViewportSize 
	gradAngle = (gradAngle + dt * 100) % 360; CursorGradient.Rotation = gradAngle 
	local isTooltipOut = (tipState == "FLYING" or tipState == "SHOWING" or tipState == "LINGER") 
	smoothPinkWeight = smoothPinkWeight + ((isTooltipOut and 0.05 or 0.8) - smoothPinkWeight) * (dt * 8) 
	CursorGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Theme.CursorGray), ColorSequenceKeypoint.new(math.clamp(1 - smoothPinkWeight, 0.01, 0.99), Theme.CursorGray), ColorSequenceKeypoint.new(1, Theme.PastelPink)}) 
	warningLerp = warningLerp + (((isTooltipOut and activeTipWarn) and 1 or 0) - warningLerp) * (dt * 12) 
	shellLerp = shellLerp + (((isTooltipOut and activeTipWarn) and 1 or 0) - shellLerp) * (dt * 12) 
	CursorBlob.BackgroundTransparency = shellLerp; CursorStroke.Transparency = 1 - shellLerp 

	if warningLerp > 0.05 then TooltipGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Theme.CursorGray), ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 235, 245)), ColorSequenceKeypoint.new(1, Theme.CursorGray)}); TooltipGradient.Offset = Vector2.new(((tick() * 1.6) % 2) - 1, 0) else TooltipGradient.Color = ColorSequence.new(Theme.PastelPink); TooltipGradient.Offset = Vector2.new(0,0) end 
	currentBreathAmp = currentBreathAmp + ((isTooltipOut and 1.5 or 0) - currentBreathAmp) * (dt * 12) 
	clickPulse = clickPulse + (0 - clickPulse) * (dt * 14) 
	cursorPos = cursorPos:Lerp(mouse, dt * 26) 
	cursorSize = cursorSize:Lerp(Vector2.new(14 + (math.sin(tick() * 5) * currentBreathAmp) + (clickPulse * 6), 14 + (math.sin(tick() * 5) * currentBreathAmp) + (clickPulse * 6)), dt * 18) 

	if (cursorPos - lastTrailPos).Magnitude > 8 then SpawnTrail(cursorPos, cursorSize.X * 0.4, shellLerp, smoothPinkWeight); lastTrailPos = cursorPos end 
	CursorBlob.Visible = true; CursorBlob.Position = UDim2.new(0, cursorPos.X, 0, cursorPos.Y); CursorBlob.Size = UDim2.new(0, cursorSize.X, 0, cursorSize.Y) 

	local function UpdateTooltipData(newData) 
		activeTipData = newData; local newText = type(newData) == "table" and newData.Text or newData; activeTipWarn = type(newData) == "table" and newData.Warning or false 
		local bounds = TextService:GetTextSize(newText, 13, Enum.Font.GothamBold, Vector2.new(1000,24)); activeTipSize = Vector2.new(bounds.X + 26, TOOLTIP_HEIGHT) 
		if newText ~= activeTipText then pendingTipText = newText; textTransitionAlpha = 1; textTransitionTarget = 0 end 
	end 

	if tipState == "HIDDEN" then tipPos = cursorPos; tipSize = tipSize:Lerp(Vector2.new(0,0), dt * 15); if hoveredButton then tipState = "WAITING" end 
	elseif tipState == "WAITING" then tipPos = cursorPos; tipSize = tipSize:Lerp(Vector2.new(0,0), dt * 15); if not hoveredButton then tipState = "RETURNING" elseif tick() - hoverStartTime >= TOOLTIP_DELAY then UpdateTooltipData(hoveredData); tipTargetPos = GetTipPos(mouse, activeTipSize.X, vp); tipState = "FLYING" end 
	elseif tipState == "FLYING" then tipTargetPos = GetTipPos(mouse, activeTipSize.X, vp); tipPos = tipPos:Lerp(tipTargetPos, dt * 12); tipSize = tipSize:Lerp(activeTipSize, dt * 10); tipCorner = tipCorner + (6 - tipCorner) * (dt * 12); if (tipPos - tipTargetPos).Magnitude < 5 then tipAnchor = tipTargetPos; tipState = "SHOWING" end; if not hoveredButton then tipState = "RETURNING" end 
	elseif tipState == "SHOWING" then local nt = GetTipPos(mouse, activeTipSize.X, vp); if (nt - tipAnchor).Magnitude > DEADZONE then tipAnchor = tipAnchor:Lerp(nt, dt * 6) end; tipPos, tipSize = tipPos:Lerp(tipAnchor, dt * 12), tipSize:Lerp(activeTipSize, dt * 14); if not hoveredButton then tipState = "LINGER"; lingerStart = tick() elseif hoveredData ~= activeTipData then tipState = "FLYING"; UpdateTooltipData(hoveredData) end 
	elseif tipState == "LINGER" then if tick() - lingerStart >= 0.15 then tipState = hoveredButton and "WAITING" or "RETURNING" end 
	elseif tipState == "RETURNING" then tipPos = tipPos:Lerp(cursorPos, dt * 14); tipSize = tipSize:Lerp(Vector2.new(0,0), dt * 12); if (tipPos - cursorPos).Magnitude < 8 or tipSize.X < 2 then tipState = "HIDDEN" end end 

	prevTipState = tipState; textTransitionAlpha = textTransitionAlpha + (textTransitionTarget - textTransitionAlpha) * (dt * 22) 
	if textTransitionAlpha >= 0.95 and pendingTipText ~= activeTipText then activeTipText = pendingTipText; TooltipText.Text = activeTipText; textTransitionTarget = 0 end 
	TooltipBlob.Visible = (tipSize.X > 1); if TooltipBlob.Visible then TooltipBlob.Position = UDim2.new(0, tipPos.X, 0, tipPos.Y); TooltipBlob.Size = UDim2.new(0, tipSize.X, 0, tipSize.Y); TooltipCorner.CornerRadius = UDim.new(0, tipCorner); TooltipText.TextTransparency = math.max(0, textTransitionAlpha) end 
end) 
table.insert(Library.Connections, renderConnection) 

-- [[ МЕТОДЫ БИБЛИОТЕКИ ]] 
function Library:CreateTab(name) 
	local TabBtn = Instance.new("TextButton") 
	TabBtn.BackgroundTransparency = 1; TabBtn.Size = UDim2.new(0,80,1,0); TabBtn.Text = name:lower() 
	TabBtn.TextColor3 = Theme.White; TabBtn.Font = Enum.Font.GothamBold; TabBtn.TextSize = 15; TabBtn.Parent = TopNotch 
	ApplyTextStroke(TabBtn) 

	local PageGroup = Instance.new("CanvasGroup") 
	PageGroup.Size = UDim2.new(1,0,1,0); PageGroup.Position = UDim2.new(0,0,0,15) -- Изначально смещено вниз для slide анимации
	PageGroup.BackgroundTransparency = 1; PageGroup.GroupTransparency = 1 
	PageGroup.Visible = false; PageGroup.Parent = ContentContainer 

	local Scroll = Instance.new("ScrollingFrame") 
	Scroll.Size = UDim2.new(1,0,1,0); Scroll.BackgroundTransparency = 1; Scroll.BorderSizePixel = 0; Scroll.ScrollBarThickness = 0; Scroll.Parent = PageGroup 
	Instance.new("UIPadding", Scroll).PaddingLeft, Instance.new("UIPadding", Scroll).PaddingTop = UDim.new(0,10), UDim.new(0,10) 
	local ScrollLayout = Instance.new("UIListLayout", Scroll) 
	ScrollLayout.Padding, ScrollLayout.HorizontalAlignment = UDim.new(0,14), Enum.HorizontalAlignment.Left 
	ScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Scroll.CanvasSize = UDim2.new(0,0,0, ScrollLayout.AbsoluteContentSize.Y + 20) end) 

	TabBtn.MouseButton1Click:Connect(function() 
		if Library.ActiveTab == PageGroup then return end 
		for _, t in pairs(Library.Tabs) do 
			TweenService:Create(t.Btn, TweenInfo.new(0.2), {TextColor3 = Theme.White}):Play() 
			if t.PageGroup.Visible then 
                -- Анимация исчезновения старого таба
                TweenService:Create(t.PageGroup, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {GroupTransparency = 1, Position = UDim2.new(0,0,0,15)}):Play()
                task.delay(0.2, function() t.PageGroup.Visible = false end) 
            end 
		end 
		Library.ActiveTab = PageGroup; PageGroup.Visible = true
        -- Анимация появления нового таба (Fade In + Slide Up)
        TweenService:Create(PageGroup, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {GroupTransparency = 0, Position = UDim2.new(0,0,0,0)}):Play() 
		TweenService:Create(TabBtn, TweenInfo.new(0.3), {TextColor3 = Theme.PastelPink}):Play() 
	end) 

	Library.Tabs[name] = {Btn = TabBtn, PageGroup = PageGroup, Scroll = Scroll} 
	if not Library.ActiveTab then Library.ActiveTab = PageGroup; PageGroup.Visible = true; PageGroup.GroupTransparency = 0; PageGroup.Position = UDim2.new(0,0,0,0); TabBtn.TextColor3 = Theme.PastelPink end 
end 

function Library:AddButton(tabName, text, tooltipData, callback) 
	local page = Library.Tabs[tabName].Scroll 
	local Btn = Instance.new("TextButton") 
	Btn.BackgroundTransparency = 1; Btn.Size = UDim2.new(1,0,0,32); Btn.Text = text:lower() 
	Btn.TextColor3 = Theme.White; Btn.Font = Enum.Font.GothamMedium; Btn.TextSize = 16 
	Btn.TextXAlignment = Enum.TextXAlignment.Left; Btn.Parent = page 
	ApplyTextStroke(Btn) 
	Btn.MouseEnter:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {TextColor3 = Theme.PastelPink}):Play(); if tooltipData then QueueTooltip(Btn, tooltipData) end end) 
	Btn.MouseLeave:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {TextColor3 = Theme.White}):Play(); if tooltipData then UnqueueTooltip(Btn) end end) 
	Btn.MouseButton1Click:Connect(callback) 
end 

function Library:AddToggle(tabName, text, tooltipData, default, callback) 
	local page = Library.Tabs[tabName].Scroll; local state = default or false 

    -- Сначала создаем кнопку, чтобы потом к ней можно было обращаться
	local Btn = Instance.new("TextButton") 
	Btn.BackgroundTransparency = 1; Btn.Size = UDim2.new(1,0,0,32)
	Btn.Text = (state and "> " or "") .. text:lower() 
	Btn.TextColor3 = state and Theme.PastelPink or Theme.White; Btn.Font = Enum.Font.GothamMedium; Btn.TextSize = 16 
	Btn.TextXAlignment = Enum.TextXAlignment.Left; Btn.Parent = page 
	ApplyTextStroke(Btn) 

    -- Теперь создаем API, который изменяет уже существующую кнопку
    local ToggleAPI = {
        State = state,
        OnRightClick = nil,
        OnMiddleClick = nil,
        SetValue = function(self, val)
            self.State = val
            Btn.Text = (self.State and "> " or "") .. text:lower()
            TweenService:Create(Btn, TweenInfo.new(0.2), {TextColor3 = self.State and Theme.PastelPink or Theme.White}):Play()
            callback(self.State)
        end
    }

	Btn.MouseEnter:Connect(function() if not ToggleAPI.State then TweenService:Create(Btn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(200,200,200)}):Play() end; if tooltipData then QueueTooltip(Btn, tooltipData) end end) 
	Btn.MouseLeave:Connect(function() if not ToggleAPI.State then TweenService:Create(Btn, TweenInfo.new(0.2), {TextColor3 = Theme.White}):Play() end; if tooltipData then UnqueueTooltip(Btn) end end) 

    Btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            ToggleAPI:SetValue(not ToggleAPI.State)
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            if ToggleAPI.OnRightClick then ToggleAPI.OnRightClick() end
        elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
            if ToggleAPI.OnMiddleClick then ToggleAPI.OnMiddleClick() end
        end
    end)
    
    return ToggleAPI
end 

function Library:AddSlider(tabName, text, min, max, default, callback) 
	local page = Library.Tabs[tabName].Scroll; local value = math.clamp(default, min, max) 
	local SliderFrame = Instance.new("Frame") 
	SliderFrame.BackgroundTransparency = 1; SliderFrame.Size = UDim2.new(1,0,0,45); SliderFrame.Parent = page 
	local SliderText = Instance.new("TextLabel") 
	SliderText.BackgroundTransparency = 1; SliderText.Size = UDim2.new(1,0,0,20); SliderText.Text = text:lower()..": "..tostring(value); SliderText.TextColor3 = Theme.White 
	SliderText.Font = Enum.Font.GothamMedium; SliderText.TextSize = 14; SliderText.TextXAlignment = Enum.TextXAlignment.Left; SliderText.Parent = SliderFrame 
	ApplyTextStroke(SliderText) 
	local BG = Instance.new("Frame"); BG.BackgroundColor3 = Theme.NotchBG; BG.Size = UDim2.new(1,-20,0,6); BG.Position = UDim2.new(0,0,0,28); BG.Parent = SliderFrame 
	Instance.new("UICorner", BG).CornerRadius = UDim.new(1,0) 
	local Fill = Instance.new("Frame"); Fill.BackgroundColor3 = Theme.PastelPink; Fill.Size = UDim2.new((value-min)/(max-min),0,1,0); Fill.Parent = BG 
	Instance.new("UICorner", Fill).CornerRadius = UDim.new(1,0) 
	local Hitbox = Instance.new("TextButton"); Hitbox.Size, Hitbox.BackgroundTransparency, Hitbox.Text = UDim2.new(1,0,1,0), 1, ""; Hitbox.Parent = SliderFrame 
	local isDragging = false 
	local function updateSlider(input) 
		local rawPos = math.clamp((input.Position.X - BG.AbsolutePosition.X) / BG.AbsoluteSize.X, 0, 1) 
		value = math.round(min + (max-min)*rawPos) -- Слайдер стал точечным
        local snapPos = (value - min) / (max - min)
		SliderText.Text = text:lower()..": "..tostring(value) 
		TweenService:Create(Fill, TweenInfo.new(0.1), {Size = UDim2.new(snapPos,0,1,0)}):Play(); callback(value) 
	end 
	Hitbox.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = true; updateSlider(i) end end) 
	table.insert(Library.Connections, UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = false end end)) 
	table.insert(Library.Connections, UserInputService.InputChanged:Connect(function(i) if isDragging and i.UserInputType == Enum.UserInputType.MouseMovement then updateSlider(i) end end)) 
end 

function Library:ToggleUI() 
	Library.IsOpen = not Library.IsOpen 
	local twInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out) 
	if Library.IsOpen then 
		ScreenGui.Enabled = true; BlockClickFrame.Visible = true; pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end) 
		TweenService:Create(DarkBackground, twInfo, {BackgroundTransparency = Theme.FadeTransparency}):Play() 
		TweenService:Create(TopNotch, twInfo, {Position = UDim2.new(0.5, 0, 0, -10)}):Play() 
		if Library.ActiveTab then 
            Library.ActiveTab.Position = UDim2.new(0,0,0,15)
            TweenService:Create(Library.ActiveTab, twInfo, {GroupTransparency = 0, Position = UDim2.new(0,0,0,0)}):Play() 
        end 
		cursorPos = UserInputService:GetMouseLocation() 
	else 
		BlockClickFrame.Visible = false; pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end) 
		TweenService:Create(DarkBackground, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {BackgroundTransparency = 1}):Play() 
		TweenService:Create(TopNotch, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Position = UDim2.new(0.5, 0, 0, -100)}):Play() 
		if Library.ActiveTab then TweenService:Create(Library.ActiveTab, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {GroupTransparency = 1, Position = UDim2.new(0,0,0,15)}):Play() end 
		task.delay(0.3, function() if not Library.IsOpen then ScreenGui.Enabled = false end end) 
	end 
end 

table.insert(Library.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed) 
	if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then Library:ToggleUI() end 
end)) 

print("SketchPastelHub Loaded")
