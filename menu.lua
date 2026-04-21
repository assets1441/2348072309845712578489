-- [[ ПОЛНОЕ ОБНОВЛЕННОЕ МЕНЮ ]]
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

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = uiName; ScreenGui.Parent = get_hidden_gui(); ScreenGui.IgnoreGuiInset = true; ScreenGui.ResetOnSpawn = false; ScreenGui.Enabled = false

local DarkBackground = Instance.new("Frame")
DarkBackground.Size = UDim2.new(1,0,1,0); DarkBackground.BackgroundColor3 = Theme.DarkFade; DarkBackground.BackgroundTransparency = 1; DarkBackground.BorderSizePixel = 0; DarkBackground.Parent = ScreenGui

local MainMover = Instance.new("Frame")
MainMover.Size = UDim2.new(1,0,1,0); MainMover.BackgroundTransparency = 1; MainMover.Parent = ScreenGui

local TopNotch = Instance.new("Frame")
TopNotch.BackgroundColor3 = Theme.NotchBG; TopNotch.Position = UDim2.new(0.5,0,0,-100); TopNotch.AnchorPoint = Vector2.new(0.5,0); TopNotch.AutomaticSize = Enum.AutomaticSize.X; TopNotch.Size = UDim2.new(0,0,0,50); TopNotch.Parent = MainMover
do
	Instance.new("UICorner", TopNotch).CornerRadius = UDim.new(0,16)
	local l = Instance.new("UIListLayout", TopNotch)
	l.FillDirection, l.HorizontalAlignment, l.VerticalAlignment, l.Padding = Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center, UDim.new(0,15)
	local p = Instance.new("UIPadding", TopNotch)
	p.PaddingLeft, p.PaddingRight = UDim.new(0,20), UDim.new(0,20)
end

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(0,420,1,-100); ContentContainer.Position = UDim2.new(0,50,0,100); ContentContainer.BackgroundTransparency = 1; ContentContainer.Parent = MainMover

-- Курсор и Тултипы (Дизайн сохранен)
local CursorBlob = Instance.new("Frame")
CursorBlob.BackgroundColor3 = Color3.new(1,1,1); CursorBlob.AnchorPoint = Vector2.new(0.5,0.5); CursorBlob.ZIndex = 1000; CursorBlob.Visible = false; CursorBlob.Parent = ScreenGui
Instance.new("UICorner", CursorBlob).CornerRadius = UDim.new(1,0)
local CursorGradient = Instance.new("UIGradient", CursorBlob)

local TooltipBlob = Instance.new("Frame")
TooltipBlob.BackgroundColor3 = Theme.PastelPink; TooltipBlob.AnchorPoint = Vector2.new(0.5,0.5); TooltipBlob.ZIndex = 900; TooltipBlob.Visible = false; TooltipBlob.Parent = ScreenGui
Instance.new("UICorner", TooltipBlob).CornerRadius = UDim.new(0,10)
local TooltipText = Instance.new("TextLabel")
TooltipText.BackgroundTransparency = 1; TooltipText.TextColor3 = Theme.NotchBG; TooltipText.Font = Enum.Font.GothamBold; TooltipText.TextSize = 13; TooltipText.ZIndex = 901; TooltipText.Parent = TooltipBlob

local cursorPos, cursorSize = Vector2.new(0,0), Vector2.new(14,14)
local tipPos, tipSize = Vector2.new(0,0), Vector2.new(0,0)
local hoveredButton, hoveredData = nil, nil

function Library:ApplyTextStroke(inst)
	local s = Instance.new("UIStroke", inst)
	s.Color = Color3.new(0,0,0); s.Thickness = 1.5; return s
end

local function QueueTooltip(b, d) hoveredButton = b; hoveredData = d end
local function UnqueueTooltip(b) if hoveredButton == b then hoveredButton = nil end end

-- Рендер (Твоя оригинальная плавность)
RunService.RenderStepped:Connect(function(dt)
	if not Library.IsOpen then UserInputService.MouseIconEnabled = true; CursorBlob.Visible = false; TooltipBlob.Visible = false; return end
	UserInputService.MouseIconEnabled = false
	local mouse = UserInputService:GetMouseLocation()
	
	cursorPos = cursorPos:Lerp(mouse, dt * 25)
	CursorBlob.Position = UDim2.new(0, cursorPos.X, 0, cursorPos.Y)
	CursorBlob.Size = UDim2.new(0, 14, 0, 14)
	CursorBlob.Visible = true
	
	CursorGradient.Rotation = (CursorGradient.Rotation + dt * 90) % 360
	CursorGradient.Color = ColorSequence.new(Theme.CursorGray, Theme.PastelPink)

	if hoveredButton then
		local txt = type(hoveredData) == "table" and hoveredData.Text or hoveredData
		local isWarn = type(hoveredData) == "table" and hoveredData.Warning or false
		TooltipText.Text = txt
		local b = TextService:GetTextSize(txt, 13, Enum.Font.GothamBold, Vector2.new(1000, 30))
		tipSize = tipSize:Lerp(Vector2.new(b.X + 26, 28), dt * 15)
		tipPos = tipPos:Lerp(mouse + Vector2.new(15, -20), dt * 15)
		TooltipBlob.Visible = true
		TooltipBlob.Size = UDim2.new(0, tipSize.X, 0, tipSize.Y)
		TooltipBlob.Position = UDim2.new(0, tipPos.X, 0, tipPos.Y)
		TooltipText.Size = UDim2.new(1,0,1,0)
		TooltipBlob.BackgroundColor3 = isWarn and Color3.fromRGB(255,100,100) or Theme.PastelPink
	else
		tipSize = tipSize:Lerp(Vector2.new(0,0), dt * 15)
		if tipSize.X < 2 then TooltipBlob.Visible = false end
	end
end)

function Library:CreateTab(name)
	local TabBtn = Instance.new("TextButton")
	TabBtn.BackgroundTransparency = 1; TabBtn.Size = UDim2.new(0,80,1,0); TabBtn.Text = name:lower(); TabBtn.TextColor3 = Theme.White; TabBtn.Font = Enum.Font.GothamBold; TabBtn.TextSize = 15; TabBtn.Parent = TopNotch
	Library:ApplyTextStroke(TabBtn)

	local Page = Instance.new("ScrollingFrame")
	Page.Size = UDim2.new(1,0,1,0); Page.BackgroundTransparency = 1; Page.Visible = false; Page.ScrollBarThickness = 0; Page.Parent = ContentContainer
	local l = Instance.new("UIListLayout", Page); l.Padding = UDim.new(0,12)
	l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Page.CanvasSize = UDim2.new(0,0,0, l.AbsoluteContentSize.Y + 20) end)

	TabBtn.MouseButton1Click:Connect(function()
		for _, t in pairs(Library.Tabs) do t.Btn.TextColor3 = Theme.White; t.Page.Visible = false end
		TabBtn.TextColor3 = Theme.PastelPink; Page.Visible = true
	end)

	Library.Tabs[name] = {Btn = TabBtn, Page = Page}
	if not Library.ActiveTab then Library.ActiveTab = name; Page.Visible = true; TabBtn.TextColor3 = Theme.PastelPink end
end

function Library:AddToggle(tab, text, tip, default, callback)
	local state = default
	local Btn = Instance.new("TextButton")
	Btn.BackgroundTransparency = 1; Btn.Size = UDim2.new(1,0,0,30); Btn.Text = (state and "> " or "") .. text:lower(); Btn.TextColor3 = state and Theme.PastelPink or Theme.White; Btn.Font = Enum.Font.GothamMedium; Btn.TextSize = 16; Btn.TextXAlignment = Enum.TextXAlignment.Left; Btn.Parent = Library.Tabs[tab].Page
	Library:ApplyTextStroke(Btn)
	Btn.MouseEnter:Connect(function() if tip then QueueTooltip(Btn, tip) end end)
	Btn.MouseLeave:Connect(function() UnqueueTooltip(Btn) end)
	Btn.MouseButton1Click:Connect(function()
		state = not state; callback(state)
		Btn.Text = (state and "> " or "") .. text:lower()
		TweenService:Create(Btn, TweenInfo.new(0.2), {TextColor3 = state and Theme.PastelPink or Theme.White}):Play()
	end)
end

function Library:AddButton(tab, text, tip, callback)
	local Btn = Instance.new("TextButton")
	Btn.BackgroundTransparency = 1; Btn.Size = UDim2.new(1,0,0,30); Btn.Text = text:lower(); Btn.TextColor3 = Theme.White; Btn.Font = Enum.Font.GothamMedium; Btn.TextSize = 16; Btn.TextXAlignment = Enum.TextXAlignment.Left; Btn.Parent = Library.Tabs[tab].Page
	Library:ApplyTextStroke(Btn)
	Btn.MouseEnter:Connect(function() if tip then QueueTooltip(Btn, tip) end end)
	Btn.MouseLeave:Connect(function() UnqueueTooltip(Btn) end)
	Btn.MouseButton1Click:Connect(callback)
end

function Library:ToggleUI()
	Library.IsOpen = not Library.IsOpen
	ScreenGui.Enabled = Library.IsOpen
	local info = TweenInfo.new(0.4, Enum.EasingStyle.Quart)
	TweenService:Create(DarkBackground, info, {BackgroundTransparency = Library.IsOpen and 0.65 or 1}):Play()
	TweenService:Create(TopNotch, info, {Position = UDim2.new(0.5, 0, 0, Library.IsOpen and 15 or -100)}):Play()
end

UserInputService.InputBegan:Connect(function(i, p) if not p and i.KeyCode == Enum.KeyCode.RightShift then Library:ToggleUI() end end)
print("SketchPastelHub Core Loaded")
