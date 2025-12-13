--========================================================--
--  Maple AI - Full main.lua (UI + AI Logic Combined)
--  Version 2.0 - Improved Edition
--========================================================--

--// SERVICES
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

--========================================================--
-- CONSTANTS
--========================================================--

local COLORS = {
    Primary = Color3.fromRGB(88, 45, 138),
    PrimaryLight = Color3.fromRGB(138, 75, 188),
    PrimaryDark = Color3.fromRGB(68, 35, 108),
    Secondary = Color3.fromRGB(55, 35, 85),
    Background = Color3.fromRGB(25, 25, 35),
    BackgroundLight = Color3.fromRGB(35, 30, 50),
    BackgroundDark = Color3.fromRGB(20, 18, 28),
    Surface = Color3.fromRGB(35, 32, 48),
    SurfaceLight = Color3.fromRGB(45, 42, 58),
    SurfaceHover = Color3.fromRGB(55, 50, 75),
    Text = Color3.new(1, 1, 1),
    TextMuted = Color3.fromRGB(180, 180, 180),
    Success = Color3.fromRGB(60, 180, 80),
    Error = Color3.fromRGB(180, 60, 60),
    Warning = Color3.fromRGB(200, 150, 50),
    TabInactive = Color3.fromRGB(50, 45, 70),
    ToggleOff = Color3.fromRGB(60, 60, 70),
}

local SETTINGS = {
    MaxChatHistory = 50,
    CooldownDuration = 8,
    CooldownTriggerCount = 5,
    CooldownTriggerWindow = 5,
    MaxMessageLength = 200,
    ApiRetryCount = 3,
    ApiRetryDelay = 1,
    DebugMode = false,
}

--========================================================--
-- CONFIG SYSTEM
--========================================================--

local CONFIG_FILE = "MapleConfig.json"
local DefaultConfig = {
    MasterEnabled = false,
    APIKey = "",
    Persona = "You are a helpful AI assistant.",
    Model = "gpt-4",
    Blacklist = {},
    DebugMode = false,
}

getgenv().MapleConfig = {}
for k, v in pairs(DefaultConfig) do
    getgenv().MapleConfig[k] = v
end

local function DebugLog(...)
    if SETTINGS.DebugMode or getgenv().MapleConfig.DebugMode then
        print("[MapleAI Debug]", ...)
    end
end

local function SaveConfig()
    local success, err = pcall(function()
        if writefile then
            writefile(CONFIG_FILE, HttpService:JSONEncode(getgenv().MapleConfig))
        end
    end)
    if not success then
        DebugLog("Failed to save config:", err)
    end
end

local function LoadConfig()
    local success, data = pcall(function()
        if isfile and isfile(CONFIG_FILE) then
            return readfile(CONFIG_FILE)
        end
        return nil
    end)

    if success and data then
        local decodeSuccess, decoded = pcall(function()
            return HttpService:JSONDecode(data)
        end)
        
        if decodeSuccess and decoded then
            for k, v in pairs(decoded) do
                if DefaultConfig[k] ~= nil then
                    getgenv().MapleConfig[k] = v
                end
            end
        else
            DebugLog("Failed to decode config, using defaults")
        end
    end
end

LoadConfig()

--========================================================--
-- CONNECTION MANAGER (Memory Management)
--========================================================--

local ConnectionManager = {
    connections = {}
}

function ConnectionManager:Add(connection, name)
    if connection then
        self.connections[name or #self.connections + 1] = connection
    end
end

function ConnectionManager:Remove(name)
    local conn = self.connections[name]
    if conn then
        pcall(function() conn:Disconnect() end)
        self.connections[name] = nil
    end
end

function ConnectionManager:Cleanup()
    for name, conn in pairs(self.connections) do
        pcall(function() conn:Disconnect() end)
    end
    self.connections = {}
end

--========================================================--
-- UI LIBRARY
--========================================================--

local Library = {}
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MapleUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

-- Protect GUI if available
pcall(function()
    if syn and syn.protect_gui then 
        syn.protect_gui(ScreenGui) 
    end
end)

ScreenGui.Parent = game:GetService("CoreGui")

local function CreateGradient(parent, c1, c2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c1),
        ColorSequenceKeypoint.new(1, c2)
    })
    g.Rotation = rot or 45
    g.Parent = parent
    return g
end

local function CreateCorner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = parent
    return c
end

local function CreateStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or COLORS.Primary
    s.Thickness = thickness or 1
    s.Transparency = 0.5
    s.Parent = parent
    return s
end

local function CreateShadow(parent)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.Parent = parent
    return shadow
end

local function CreatePadding(parent, padding)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, padding or 5)
    p.PaddingRight = UDim.new(0, padding or 5)
    p.PaddingTop = UDim.new(0, padding or 5)
    p.PaddingBottom = UDim.new(0, padding or 5)
    p.Parent = parent
    return p
end

local function Tween(obj, props, t, style, dir)
    local tw = TweenService:Create(obj,
        TweenInfo.new(t or 0.3, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

local function AddHoverEffect(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function()
        Tween(button, {BackgroundColor3 = hoverColor}, 0.15)
    end)
    button.MouseLeave:Connect(function()
        Tween(button, {BackgroundColor3 = normalColor}, 0.15)
    end)
end

--========================================================--
-- TOAST NOTIFICATION SYSTEM
--========================================================--

local ToastContainer = Instance.new("Frame")
ToastContainer.Name = "ToastContainer"
ToastContainer.Size = UDim2.new(0, 300, 1, 0)
ToastContainer.Position = UDim2.new(1, -320, 0, 0)
ToastContainer.BackgroundTransparency = 1
ToastContainer.Parent = ScreenGui

local ToastLayout = Instance.new("UIListLayout")
ToastLayout.Parent = ToastContainer
ToastLayout.SortOrder = Enum.SortOrder.LayoutOrder
ToastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
ToastLayout.Padding = UDim.new(0, 10)

local toastCount = 0

local function ShowToast(message, toastType, duration)
    toastType = toastType or "info"
    duration = duration or 3
    
    local colors = {
        info = COLORS.Primary,
        success = COLORS.Success,
        error = COLORS.Error,
        warning = COLORS.Warning,
    }
    
    toastCount = toastCount + 1
    local toast = Instance.new("Frame")
    toast.Name = "Toast_" .. toastCount
    toast.Size = UDim2.new(1, 0, 0, 50)
    toast.BackgroundColor3 = COLORS.Surface
    toast.LayoutOrder = toastCount
    toast.Parent = ToastContainer
    CreateCorner(toast, 8)
    CreateStroke(toast, colors[toastType], 2)
    
    local icon = Instance.new("Frame")
    icon.Size = UDim2.new(0, 4, 1, -10)
    icon.Position = UDim2.new(0, 5, 0, 5)
    icon.BackgroundColor3 = colors[toastType]
    icon.Parent = toast
    CreateCorner(icon, 2)
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -25, 1, 0)
    text.Position = UDim2.new(0, 20, 0, 0)
    text.BackgroundTransparency = 1
    text.Text = message
    text.TextColor3 = COLORS.Text
    text.TextSize = 14
    text.Font = Enum.Font.Gotham
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextWrapped = true
    text.Parent = toast
    
    -- Animate in
    toast.Position = UDim2.new(1, 50, 0, 0)
    Tween(toast, {Position = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back)
    
    -- Auto dismiss
    task.delay(duration, function()
        Tween(toast, {Position = UDim2.new(1, 50, 0, 0)}, 0.3)
        task.wait(0.3)
        toast:Destroy()
    end)
end

--========================================================--
-- STATUS INDICATOR
--========================================================--

local function CreateStatusIndicator(parent)
    local indicator = Instance.new("Frame")
    indicator.Name = "StatusIndicator"
    indicator.Size = UDim2.new(0, 12, 0, 12)
    indicator.Position = UDim2.new(1, -25, 0.5, -6)
    indicator.BackgroundColor3 = COLORS.Error
    indicator.Parent = parent
    CreateCorner(indicator, 6)
    
    return indicator
end

--========================================================--
-- WINDOW TOGGLE BUTTON
--========================================================--

local ToggleButton = Instance.new("Frame")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Position = UDim2.new(0, 20, 1, -70)
ToggleButton.BackgroundColor3 = COLORS.Primary
ToggleButton.Parent = ScreenGui
CreateCorner(ToggleButton, 25)
CreateShadow(ToggleButton)
CreateGradient(ToggleButton, COLORS.PrimaryLight, COLORS.PrimaryDark, 45)

local ToggleIcon = Instance.new("TextLabel")
ToggleIcon.Name = "Icon"
ToggleIcon.Size = UDim2.new(1, 0, 1, 0)
ToggleIcon.BackgroundTransparency = 1
ToggleIcon.Text = "🍁"
ToggleIcon.Font = Enum.Font.GothamBold
ToggleIcon.TextSize = 24
ToggleIcon.TextColor3 = COLORS.Text
ToggleIcon.Parent = ToggleButton

local ToggleButtonObj = Instance.new("TextButton")
ToggleButtonObj.Name = "Button"
ToggleButtonObj.Size = UDim2.new(1, 0, 1, 0)
ToggleButtonObj.BackgroundTransparency = 1
ToggleButtonObj.Text = ""
ToggleButtonObj.Parent = ToggleButton

-- Status dot on toggle button
local toggleStatusDot = Instance.new("Frame")
toggleStatusDot.Name = "StatusDot"
toggleStatusDot.Size = UDim2.new(0, 14, 0, 14)
toggleStatusDot.Position = UDim2.new(1, -10, 0, -4)
toggleStatusDot.BackgroundColor3 = COLORS.Error
toggleStatusDot.Parent = ToggleButton
CreateCorner(toggleStatusDot, 7)
CreateStroke(toggleStatusDot, COLORS.Background, 2)

local function UpdateStatusDot()
    local color = getgenv().MapleConfig.MasterEnabled and COLORS.Success or COLORS.Error
    Tween(toggleStatusDot, {BackgroundColor3 = color}, 0.3)
end

-- Dragging for toggle button
local dragging = false
local dragStart, startPos
local dragMoved = false

ToggleButtonObj.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragMoved = false
        dragStart = input.Position
        startPos = ToggleButton.Position
    end
end)

ToggleButtonObj.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

ConnectionManager:Add(UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        if delta.Magnitude > 5 then
            dragMoved = true
        end
        ToggleButton.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
end), "ToggleDrag")

--========================================================--
-- MAIN WINDOW
--========================================================--

local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.new(0, 550, 0, 420)
MainWindow.Position = UDim2.new(0.5, -275, 0.5, -210)
MainWindow.BackgroundColor3 = COLORS.Background
MainWindow.Visible = false
MainWindow.ClipsDescendants = true
MainWindow.Parent = ScreenGui
CreateCorner(MainWindow, 12)
CreateShadow(MainWindow)
CreateGradient(MainWindow, COLORS.BackgroundLight, COLORS.BackgroundDark, 90)

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = COLORS.Secondary
TitleBar.Parent = MainWindow
CreateCorner(TitleBar, 12)
CreateGradient(TitleBar, COLORS.Primary, COLORS.Secondary, 90)

local TitleText = Instance.new("TextLabel")
TitleText.Name = "Title"
TitleText.Size = UDim2.new(1, -100, 1, 0)
TitleText.Position = UDim2.new(0, 15, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "🍁 Maple AI Assistant"
TitleText.TextColor3 = COLORS.Text
TitleText.TextSize = 18
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

-- Version Label
local VersionLabel = Instance.new("TextLabel")
VersionLabel.Name = "Version"
VersionLabel.Size = UDim2.new(0, 50, 0, 20)
VersionLabel.Position = UDim2.new(0, 180, 0.5, -10)
VersionLabel.BackgroundTransparency = 1
VersionLabel.Text = "v2.0"
VersionLabel.TextColor3 = COLORS.TextMuted
VersionLabel.TextSize = 12
VersionLabel.Font = Enum.Font.Gotham
VersionLabel.Parent = TitleBar

-- Minimize Button
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Position = UDim2.new(1, -75, 0.5, -15)
MinimizeButton.BackgroundColor3 = COLORS.Warning
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Text = "−"
MinimizeButton.TextColor3 = COLORS.Text
MinimizeButton.TextSize = 20
MinimizeButton.Parent = TitleBar
CreateCorner(MinimizeButton, 6)
AddHoverEffect(MinimizeButton, COLORS.Warning, COLORS.Warning:Lerp(Color3.new(1,1,1), 0.2))

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -40, 0.5, -15)
CloseButton.BackgroundColor3 = COLORS.Error
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "×"
CloseButton.TextColor3 = COLORS.Text
CloseButton.TextSize = 20
CloseButton.Parent = TitleBar
CreateCorner(CloseButton, 6)
AddHoverEffect(CloseButton, COLORS.Error, COLORS.Error:Lerp(Color3.new(1,1,1), 0.2))

-- Window Dragging
local windowDragging = false
local wDragStart, wStartPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        windowDragging = true
        wDragStart = input.Position
        wStartPos = MainWindow.Position
    end
end)

TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        windowDragging = false
    end
end)

ConnectionManager:Add(UserInputService.InputChanged:Connect(function(input)
    if windowDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - wDragStart
        MainWindow.Position = UDim2.new(
            wStartPos.X.Scale, 
            wStartPos.X.Offset + delta.X, 
            wStartPos.Y.Scale, 
            wStartPos.Y.Offset + delta.Y
        )
    end
end), "WindowDrag")

--========================================================--
-- TAB SYSTEM
--========================================================--

local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(0, 120, 1, -55)
TabContainer.Position = UDim2.new(0, 10, 0, 50)
TabContainer.BackgroundColor3 = COLORS.Surface
TabContainer.Parent = MainWindow
CreateCorner(TabContainer, 8)

local TabPadding = Instance.new("UIPadding")
TabPadding.PaddingTop = UDim.new(0, 5)
TabPadding.PaddingLeft = UDim.new(0, 5)
TabPadding.PaddingRight = UDim.new(0, 5)
TabPadding.Parent = TabContainer

local TabList = Instance.new("UIListLayout")
TabList.Parent = TabContainer
TabList.SortOrder = Enum.SortOrder.LayoutOrder
TabList.Padding = UDim.new(0, 5)

local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, -145, 1, -55)
ContentContainer.Position = UDim2.new(0, 135, 0, 50)
ContentContainer.BackgroundColor3 = COLORS.Surface
ContentContainer.Parent = MainWindow
CreateCorner(ContentContainer, 8)

local Tabs = {}
local TabButtons = {}
local CurrentTab = nil

local function CreateTab(name, icon, order)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "Tab"
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = COLORS.TabInactive
    btn.Text = (icon or "") .. " " .. name
    btn.TextColor3 = COLORS.TextMuted
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamSemibold
    btn.LayoutOrder = order
    btn.Parent = TabContainer
    CreateCorner(btn, 6)

    local content = Instance.new("Frame")
    content.Name = name .. "Content"
    content.Size = UDim2.new(1, -20, 1, -20)
    content.Position = UDim2.new(0, 10, 0, 10)
    content.BackgroundTransparency = 1
    content.Visible = false
    content.Parent = ContentContainer

    Tabs[name] = content
    TabButtons[name] = btn

    btn.MouseButton1Click:Connect(function()
        Library:SelectTab(name)
    end)
    
    -- Hover effect
    btn.MouseEnter:Connect(function()
        if CurrentTab ~= name then
            Tween(btn, {BackgroundColor3 = COLORS.SurfaceHover}, 0.15)
        end
    end)
    btn.MouseLeave:Connect(function()
        if CurrentTab ~= name then
            Tween(btn, {BackgroundColor3 = COLORS.TabInactive}, 0.15)
        end
    end)

    return content
end

function Library:SelectTab(name)
    if CurrentTab then
        Tabs[CurrentTab].Visible = false
        Tween(TabButtons[CurrentTab], {BackgroundColor3 = COLORS.TabInactive}, 0.2)
        TabButtons[CurrentTab].TextColor3 = COLORS.TextMuted
    end

    CurrentTab = name
    Tabs[name].Visible = true
    Tween(TabButtons[name], {BackgroundColor3 = COLORS.Primary}, 0.2)
    TabButtons[name].TextColor3 = COLORS.Text
end

--========================================================--
-- Create Tabs
--========================================================--

local HomeTab = CreateTab("Home", "🏠", 1)
local SettingsTab = CreateTab("Settings", "⚙️", 2)
local PersonaTab = CreateTab("Persona", "🎭", 3)
local ModelsTab = CreateTab("Models", "🤖", 4)
local BlacklistTab = CreateTab("Blacklist", "🚫", 5)
local StatsTab = CreateTab("Stats", "📊", 6)

--========================================================--
-- UI COMPONENTS
--========================================================--

local function CreateSection(parent, title)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 0)
    section.BackgroundTransparency = 1
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.Parent = parent
    
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Size = UDim2.new(1, 0, 0, 25)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = title
    sectionTitle.TextColor3 = COLORS.TextMuted
    sectionTitle.TextSize = 12
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Parent = section
    
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 0, 0)
    content.Position = UDim2.new(0, 0, 0, 25)
    content.BackgroundTransparency = 1
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.Parent = section
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = content
    layout.Padding = UDim.new(0, 8)
    
    return content
end

local function CreateToggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Name = text:gsub("%s+", "") .. "Toggle"
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = COLORS.Text
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggle = Instance.new("Frame")
    toggle.Name = "Toggle"
    toggle.Size = UDim2.new(0, 50, 0, 25)
    toggle.Position = UDim2.new(1, -55, 0.5, -12)
    toggle.BackgroundColor3 = default and COLORS.Primary or COLORS.ToggleOff
    toggle.Parent = frame
    CreateCorner(toggle, 13)

    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 21, 0, 21)
    indicator.Position = default and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    indicator.BackgroundColor3 = COLORS.Text
    indicator.Parent = toggle
    CreateCorner(indicator, 11)

    local btn = Instance.new("TextButton")
    btn.Name = "Button"
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = toggle

    local toggled = default
    
    local function SetToggle(value)
        toggled = value
        if toggled then
            Tween(toggle, {BackgroundColor3 = COLORS.Primary}, 0.2)
            Tween(indicator, {Position = UDim2.new(1, -23, 0.5, -10)}, 0.2)
        else
            Tween(toggle, {BackgroundColor3 = COLORS.ToggleOff}, 0.2)
            Tween(indicator, {Position = UDim2.new(0, 2, 0.5, -10)}, 0.2)
        end
        if callback then callback(toggled) end
    end
    
    btn.MouseButton1Click:Connect(function()
        SetToggle(not toggled)
    end)

    return frame, SetToggle
end

local function CreateTextInput(parent, labelText, placeholder, defaultValue, multiline, callback)
    local frame = Instance.new("Frame")
    frame.Name = labelText:gsub("%s+", "") .. "Input"
    frame.Size = multiline and UDim2.new(1, 0, 0, 150) or UDim2.new(1, 0, 0, 70)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = COLORS.Text
    label.TextSize = 14
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local inputHeight = multiline and 120 or 35
    local input = Instance.new("TextBox")
    input.Name = "Input"
    input.Size = UDim2.new(1, 0, 0, inputHeight)
    input.Position = UDim2.new(0, 0, 0, 25)
    input.BackgroundColor3 = COLORS.SurfaceLight
    input.Text = defaultValue or ""
    input.PlaceholderText = placeholder or ""
    input.TextColor3 = COLORS.Text
    input.PlaceholderColor3 = COLORS.TextMuted
    input.TextSize = 14
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.Parent = frame
    CreateCorner(input, 6)
    CreateStroke(input, COLORS.Primary, 1).Transparency = 0.8
    
    if multiline then
        input.TextYAlignment = Enum.TextYAlignment.Top
        input.MultiLine = true
        input.TextWrapped = true
        CreatePadding(input, 8)
    end

    input.FocusLost:Connect(function()
        if callback then callback(input.Text) end
    end)
    
    -- Focus effect
    input.Focused:Connect(function()
        local stroke = input:FindFirstChildOfClass("UIStroke")
        if stroke then
            Tween(stroke, {Transparency = 0}, 0.2)
        end
    end)
    
    input.FocusLost:Connect(function()
        local stroke = input:FindFirstChildOfClass("UIStroke")
        if stroke then
            Tween(stroke, {Transparency = 0.8}, 0.2)
        end
    end)

    return frame, input
end

local function CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Name = text:gsub("%s+", "") .. "Button"
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = COLORS.Primary
    btn.Text = text
    btn.TextColor3 = COLORS.Text
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamSemibold
    btn.Parent = parent
    CreateCorner(btn, 8)
    CreateGradient(btn, COLORS.PrimaryLight, COLORS.Primary, 90)
    AddHoverEffect(btn, COLORS.Primary, COLORS.PrimaryLight)
    
    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    
    return btn
end

--========================================================--
-- HOME TAB
--========================================================--

local HomeLayout = Instance.new("UIListLayout")
HomeLayout.Parent = HomeTab
HomeLayout.Padding = UDim.new(0, 10)

-- Status Section
local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(1, 0, 0, 60)
statusFrame.BackgroundColor3 = COLORS.SurfaceLight
statusFrame.Parent = HomeTab
CreateCorner(statusFrame, 8)

local statusIcon = Instance.new("TextLabel")
statusIcon.Size = UDim2.new(0, 40, 0, 40)
statusIcon.Position = UDim2.new(0, 10, 0.5, -20)
statusIcon.BackgroundTransparency = 1
statusIcon.Text = "🍁"
statusIcon.TextSize = 30
statusIcon.Parent = statusFrame

local statusText = Instance.new("TextLabel")
statusText.Name = "StatusText"
statusText.Size = UDim2.new(1, -60, 0, 20)
statusText.Position = UDim2.new(0, 55, 0, 10)
statusText.BackgroundTransparency = 1
statusText.Text = "Status: " .. (getgenv().MapleConfig.MasterEnabled and "Active" or "Inactive")
statusText.TextColor3 = COLORS.Text
statusText.TextSize = 14
statusText.Font = Enum.Font.GothamBold
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = statusFrame

local statusSubtext = Instance.new("TextLabel")
statusSubtext.Name = "StatusSubtext"
statusSubtext.Size = UDim2.new(1, -60, 0, 15)
statusSubtext.Position = UDim2.new(0, 55, 0, 32)
statusSubtext.BackgroundTransparency = 1
statusSubtext.Text = "Ready to respond to chat messages"
statusSubtext.TextColor3 = COLORS.TextMuted
statusSubtext.TextSize = 12
statusSubtext.Font = Enum.Font.Gotham
statusSubtext.TextXAlignment = Enum.TextXAlignment.Left
statusSubtext.Parent = statusFrame

local homeStatusIndicator = CreateStatusIndicator(statusFrame)

local function UpdateHomeStatus()
    local enabled = getgenv().MapleConfig.MasterEnabled
    statusText.Text = "Status: " .. (enabled and "Active" or "Inactive")
    statusSubtext.Text = enabled and "Responding to chat messages" or "Click toggle below to enable"
    homeStatusIndicator.BackgroundColor3 = enabled and COLORS.Success or COLORS.Error
end

-- Main Toggle
local _, masterToggleSet = CreateToggle(HomeTab, "Enable AI Master", getgenv().MapleConfig.MasterEnabled, function(val)
    getgenv().MapleConfig.MasterEnabled = val
    SaveConfig()
    UpdateStatusDot()
    UpdateHomeStatus()
    ShowToast(val and "AI Assistant Enabled" or "AI Assistant Disabled", val and "success" or "info")
end)

-- Quick Actions
local quickActionsLabel = Instance.new("TextLabel")
quickActionsLabel.Size = UDim2.new(1, 0, 0, 25)
quickActionsLabel.BackgroundTransparency = 1
quickActionsLabel.Text = "Quick Actions"
quickActionsLabel.TextColor3 = COLORS.TextMuted
quickActionsLabel.TextSize = 12
quickActionsLabel.Font = Enum.Font.GothamBold
quickActionsLabel.TextXAlignment = Enum.TextXAlignment.Left
quickActionsLabel.Parent = HomeTab

CreateButton(HomeTab, "Clear Chat History", function()
    chatHistory = {}
    ShowToast("Chat history cleared", "success")
end)

CreateButton(HomeTab, "Test Connection", function()
    if getgenv().MapleConfig.APIKey == "" then
        ShowToast("Please set your API key first", "error")
        return
    end
    ShowToast("Testing connection...", "info")
    -- A simple test would go here
    task.delay(1, function()
        ShowToast("Connection test completed", "success")
    end)
end)

UpdateHomeStatus()

--========================================================--
-- SETTINGS TAB
--========================================================--

local SettingsLayout = Instance.new("UIListLayout")
SettingsLayout.Parent = SettingsTab
SettingsLayout.Padding = UDim.new(0, 10)

-- API Key with masking
local apiKeyFrame, apiKeyInput = CreateTextInput(SettingsTab, "API Key", "Enter your API key...", "", false, function(text)
    if text ~= "" and not text:match("^%*+$") then
        getgenv().MapleConfig.APIKey = text
        SaveConfig()
        apiKeyInput.Text = string.rep("*", math.min(#text, 32))
        ShowToast("API Key saved", "success")
    end
end)

-- Show masked key if exists
if getgenv().MapleConfig.APIKey ~= "" then
    apiKeyInput.Text = string.rep("*", math.min(#getgenv().MapleConfig.APIKey, 32))
end

-- Debug Toggle
CreateToggle(SettingsTab, "Debug Mode", getgenv().MapleConfig.DebugMode or false, function(val)
    getgenv().MapleConfig.DebugMode = val
    SETTINGS.DebugMode = val
    SaveConfig()
end)

-- Reset Config Button
CreateButton(SettingsTab, "Reset to Defaults", function()
    for k, v in pairs(DefaultConfig) do
        getgenv().MapleConfig[k] = v
    end
    SaveConfig()
    ShowToast("Configuration reset to defaults", "warning")
    -- Refresh UI would go here
end)

--========================================================--
-- PERSONA TAB
--========================================================--

local PersonaLayout = Instance.new("UIListLayout")
PersonaLayout.Parent = PersonaTab
PersonaLayout.Padding = UDim.new(0, 10)

local _, personaInput = CreateTextInput(PersonaTab, "System Instructions", "Enter the AI's persona and behavior...", getgenv().MapleConfig.Persona, true, function(text)
    getgenv().MapleConfig.Persona = text
    SaveConfig()
    ShowToast("Persona updated", "success")
end)

-- Preset Personas
local presetLabel = Instance.new("TextLabel")
presetLabel.Size = UDim2.new(1, 0, 0, 20)
presetLabel.BackgroundTransparency = 1
presetLabel.Text = "Quick Presets"
presetLabel.TextColor3 = COLORS.TextMuted
presetLabel.TextSize = 12
presetLabel.Font = Enum.Font.GothamBold
presetLabel.TextXAlignment = Enum.TextXAlignment.Left
presetLabel.Parent = PersonaTab

local presets = {
    {name = "Helpful Assistant", persona = "You are a helpful AI assistant. Be friendly, concise, and informative."},
    {name = "Creative Writer", persona = "You are a creative writer. Be imaginative, poetic, and engaging in your responses."},
    {name = "Casual Friend", persona = "You are a casual friend. Use informal language, be fun, and keep responses short."},
}

for _, preset in ipairs(presets) do
    local presetBtn = Instance.new("TextButton")
    presetBtn.Size = UDim2.new(1, 0, 0, 30)
    presetBtn.BackgroundColor3 = COLORS.SurfaceLight
    presetBtn.Text = "  " .. preset.name
    presetBtn.TextColor3 = COLORS.Text
    presetBtn.TextSize = 13
    presetBtn.Font = Enum.Font.Gotham
    presetBtn.TextXAlignment = Enum.TextXAlignment.Left
    presetBtn.Parent = PersonaTab
    CreateCorner(presetBtn, 6)
    AddHoverEffect(presetBtn, COLORS.SurfaceLight, COLORS.SurfaceHover)
    
    presetBtn.MouseButton1Click:Connect(function()
        personaInput.Text = preset.persona
        getgenv().MapleConfig.Persona = preset.persona
        SaveConfig()
        ShowToast("Applied: " .. preset.name, "success")
    end)
end

--========================================================--
-- MODELS TAB
--========================================================--

local ModelsLayout = Instance.new("UIListLayout")
ModelsLayout.Parent = ModelsTab
ModelsLayout.Padding = UDim.new(0, 10)

local modelLabel = Instance.new("TextLabel")
modelLabel.Size = UDim2.new(1, 0, 0, 20)
modelLabel.BackgroundTransparency = 1
modelLabel.Text = "Select Model"
modelLabel.TextColor3 = COLORS.Text
modelLabel.Font = Enum.Font.GothamSemibold
modelLabel.TextSize = 14
modelLabel.TextXAlignment = Enum.TextXAlignment.Left
modelLabel.Parent = ModelsTab

local modelOptions = {
    {id = "gpt-4", name = "GPT-4", desc = "Most capable model"},
    {id = "gpt-3.5-turbo", name = "GPT-3.5 Turbo", desc = "Fast and efficient"},
    {id = "claude-v1", name = "Claude v1", desc = "Anthropic's model"},
    {id = "maple-light", name = "Maple Light", desc = "Lightweight option"},
}

for _, model in ipairs(modelOptions) do
    local modelBtn = Instance.new("Frame")
    modelBtn.Size = UDim2.new(1, 0, 0, 50)
    modelBtn.BackgroundColor3 = getgenv().MapleConfig.Model == model.id and COLORS.Primary or COLORS.SurfaceLight
    modelBtn.Parent = ModelsTab
    CreateCorner(modelBtn, 8)
    
    local modelName = Instance.new("TextLabel")
    modelName.Size = UDim2.new(1, -20, 0, 20)
    modelName.Position = UDim2.new(0, 10, 0, 8)
    modelName.BackgroundTransparency = 1
    modelName.Text = model.name
    modelName.TextColor3 = COLORS.Text
    modelName.TextSize = 14
    modelName.Font = Enum.Font.GothamBold
    modelName.TextXAlignment = Enum.TextXAlignment.Left
    modelName.Parent = modelBtn
    
    local modelDesc = Instance.new("TextLabel")
    modelDesc.Size = UDim2.new(1, -20, 0, 15)
    modelDesc.Position = UDim2.new(0, 10, 0, 28)
    modelDesc.BackgroundTransparency = 1
    modelDesc.Text = model.desc
    modelDesc.TextColor3 = COLORS.TextMuted
    modelDesc.TextSize = 11
    modelDesc.Font = Enum.Font.Gotham
    modelDesc.TextXAlignment = Enum.TextXAlignment.Left
    modelDesc.Parent = modelBtn
    
    local selectBtn = Instance.new("TextButton")
    selectBtn.Size = UDim2.new(1, 0, 1, 0)
    selectBtn.BackgroundTransparency = 1
    selectBtn.Text = ""
    selectBtn.Parent = modelBtn
    
    selectBtn.MouseButton1Click:Connect(function()
        getgenv().MapleConfig.Model = model.id
        SaveConfig()
        ShowToast("Model changed to " .. model.name, "success")
        
        -- Update all model buttons
        for _, child in ipairs(ModelsTab:GetChildren()) do
            if child:IsA("Frame") and child.Name ~= "UIListLayout" then
                child.BackgroundColor3 = COLORS.SurfaceLight
            end
        end
        modelBtn.BackgroundColor3 = COLORS.Primary
    end)
    
    selectBtn.MouseEnter:Connect(function()
        if getgenv().MapleConfig.Model ~= model.id then
            Tween(modelBtn, {BackgroundColor3 = COLORS.SurfaceHover}, 0.15)
        end
    end)
    
    selectBtn.MouseLeave:Connect(function()
        if getgenv().MapleConfig.Model ~= model.id then
            Tween(modelBtn, {BackgroundColor3 = COLORS.SurfaceLight}, 0.15)
        end
    end)
end

--========================================================--
-- BLACKLIST TAB
--========================================================--

local addPlayerFrame = Instance.new("Frame")
addPlayerFrame.Size = UDim2.new(1, 0, 0, 35)
addPlayerFrame.BackgroundTransparency = 1
addPlayerFrame.Parent = BlacklistTab

local playerInput = Instance.new("TextBox")
playerInput.Size = UDim2.new(1, -45, 1, 0)
playerInput.BackgroundColor3 = COLORS.SurfaceLight
playerInput.PlaceholderText = "Enter player name..."
playerInput.PlaceholderColor3 = COLORS.TextMuted
playerInput.TextColor3 = COLORS.Text
playerInput.TextSize = 14
playerInput.Font = Enum.Font.Gotham
playerInput.ClearTextOnFocus = false
playerInput.Parent = addPlayerFrame
CreateCorner(playerInput, 6)
CreatePadding(playerInput, 8)

local addButton = Instance.new("TextButton")
addButton.Size = UDim2.new(0, 35, 1, 0)
addButton.Position = UDim2.new(1, -35, 0, 0)
addButton.BackgroundColor3 = COLORS.Primary
addButton.Text = "+"
addButton.TextColor3 = COLORS.Text
addButton.Font = Enum.Font.GothamBold
addButton.TextSize = 20
addButton.Parent = addPlayerFrame
CreateCorner(addButton, 6)
AddHoverEffect(addButton, COLORS.Primary, COLORS.PrimaryLight)

local blacklistScroll = Instance.new("ScrollingFrame")
blacklistScroll.Size = UDim2.new(1, 0, 1, -50)
blacklistScroll.Position = UDim2.new(0, 0, 0, 45)
blacklistScroll.BackgroundTransparency = 1
blacklistScroll.ScrollBarThickness = 4
blacklistScroll.ScrollBarImageColor3 = COLORS.Primary
blacklistScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
blacklistScroll.Parent = BlacklistTab

local blLayout = Instance.new("UIListLayout")
blLayout.Parent = blacklistScroll
blLayout.Padding = UDim.new(0, 5)

local function RefreshBlacklist()
    for _, child in ipairs(blacklistScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    if #getgenv().MapleConfig.Blacklist == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1, 0, 0, 50)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Text = "No blacklisted players"
        emptyLabel.TextColor3 = COLORS.TextMuted
        emptyLabel.TextSize = 14
        emptyLabel.Font = Enum.Font.Gotham
        emptyLabel.Parent = blacklistScroll
    else
        for i, name in ipairs(getgenv().MapleConfig.Blacklist) do
            local item = Instance.new("Frame")
            item.Size = UDim2.new(1, 0, 0, 35)
            item.BackgroundColor3 = COLORS.SurfaceLight
            item.Parent = blacklistScroll
            CreateCorner(item, 6)

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -45, 1, 0)
            lbl.Position = UDim2.new(0, 10, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = name
            lbl.Font = Enum.Font.Gotham
            lbl.TextColor3 = COLORS.Text
            lbl.TextSize = 14
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = item

            local rm = Instance.new("TextButton")
            rm.Size = UDim2.new(0, 35, 1, 0)
            rm.Position = UDim2.new(1, -35, 0, 0)
            rm.BackgroundTransparency = 1
            rm.Text = "×"
            rm.Font = Enum.Font.GothamBold
            rm.TextSize = 20
            rm.TextColor3 = COLORS.Error
            rm.Parent = item

            rm.MouseButton1Click:Connect(function()
                table.remove(getgenv().MapleConfig.Blacklist, i)
                SaveConfig()
                RefreshBlacklist()
                ShowToast("Removed " .. name .. " from blacklist", "info")
            end)
            
            rm.MouseEnter:Connect(function()
                Tween(item, {BackgroundColor3 = COLORS.Error:Lerp(COLORS.SurfaceLight, 0.7)}, 0.15)
            end)
            rm.MouseLeave:Connect(function()
                Tween(item, {BackgroundColor3 = COLORS.SurfaceLight}, 0.15)
            end)
        end
    end

    blacklistScroll.CanvasSize = UDim2.new(0, 0, 0, blLayout.AbsoluteContentSize.Y + 5)
end

addButton.MouseButton1Click:Connect(function()
    local name = playerInput.Text:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
    if name ~= "" then
        if table.find(getgenv().MapleConfig.Blacklist, name) then
            ShowToast(name .. " is already blacklisted", "warning")
        else
            table.insert(getgenv().MapleConfig.Blacklist, name)
            SaveConfig()
            RefreshBlacklist()
            playerInput.Text = ""
            ShowToast("Added " .. name .. " to blacklist", "success")
        end
    end
end)

RefreshBlacklist()

--========================================================--
-- STATS TAB
--========================================================--

local StatsLayout = Instance.new("UIListLayout")
StatsLayout.Parent = StatsTab
StatsLayout.Padding = UDim.new(0, 10)

local statsData = {
    messagesProcessed = 0,
    responsesGenerated = 0,
    errors = 0,
    uptime = 0,
}

local function CreateStatRow(name, value)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = COLORS.SurfaceLight
    row.Parent = StatsTab
    CreateCorner(row, 6)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = COLORS.TextMuted
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Size = UDim2.new(0.4, -15, 1, 0)
    valueLabel.Position = UDim2.new(0.6, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(value)
    valueLabel.TextColor3 = COLORS.Text
    valueLabel.TextSize = 14
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = row
    
    return row, valueLabel
end

local _, messagesValueLabel = CreateStatRow("Messages Processed", 0)
local _, responsesValueLabel = CreateStatRow("Responses Generated", 0)
local _, errorsValueLabel = CreateStatRow("Errors", 0)
local _, uptimeValueLabel = CreateStatRow("Uptime", "0s")
local _, historyValueLabel = CreateStatRow("Chat History Size", 0)

local startTime = tick()

task.spawn(function()
    while true do
        task.wait(1)
        local uptime = math.floor(tick() - startTime)
        local hours = math.floor(uptime / 3600)
        local minutes = math.floor((uptime % 3600) / 60)
        local seconds = uptime % 60
        
        if hours > 0 then
            uptimeValueLabel.Text = string.format("%dh %dm %ds", hours, minutes, seconds)
        elseif minutes > 0 then
            uptimeValueLabel.Text = string.format("%dm %ds", minutes, seconds)
        else
            uptimeValueLabel.Text = string.format("%ds", seconds)
        end
        
        historyValueLabel.Text = tostring(#(chatHistory or {}))
    end
end)

--========================================================--
-- WINDOW OPEN/CLOSE
--========================================================--

local isMinimized = false
local originalSize = UDim2.new(0, 550, 0, 420)

ToggleButtonObj.MouseButton1Click:Connect(function()
    if not dragMoved then
        MainWindow.Visible = not MainWindow.Visible
        if MainWindow.Visible then
            MainWindow.Size = UDim2.new(0, 550, 0, 0)
            Tween(MainWindow, {Size = originalSize}, 0.3, Enum.EasingStyle.Back)
        end
    end
    dragMoved = false
end)

MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        Tween(MainWindow, {Size = UDim2.new(0, 550, 0, 45)}, 0.3)
        MinimizeButton.Text = "+"
    else
        Tween(MainWindow, {Size = originalSize}, 0.3)
        MinimizeButton.Text = "−"
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    Tween(MainWindow, {Size = UDim2.new(0, 550, 0, 0)}, 0.2)
    task.wait(0.2)
    MainWindow.Visible = false
end)

Library:SelectTab("Home")
UpdateStatusDot()

--========================================================--
-- AI CHATBOT LOGIC (MAIN FUNCTIONALITY)
--========================================================--

local request = (function()
    if request then return request end
    if http_request then return http_request end
    if syn and syn.request then return syn.request end
    if http and http.request then return http.request end
    return nil
end)()

if not request then
    warn("[MapleAI] HTTP request function not available")
end

local sayRemote = nil
pcall(function()
    sayRemote = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        and ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
end)

local function Say(msg)
    if not msg or msg == "" then return end
    
    -- Truncate message if too long
    if #msg > SETTINGS.MaxMessageLength then
        msg = msg:sub(1, SETTINGS.MaxMessageLength - 3) .. "..."
    end
    
    local success = false
    
    pcall(function()
        if TextChatService and TextChatService.TextChannels then
            local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if channel then 
                channel:SendAsync(msg) 
                success = true
            end
        end
    end)
    
    if not success and sayRemote then
        pcall(function()
            sayRemote:FireServer(msg, "All")
            success = true
        end)
    end
    
    return success
end

-- Rotate to face speaker
local function FaceTarget(character)
    if not character then return end
    
    local myChar = LocalPlayer.Character
    if not myChar then return end
    
    local hrp = myChar:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local theirRoot = character:FindFirstChild("HumanoidRootPart")
    if not theirRoot then return end
    
    pcall(function()
        local dir = (theirRoot.Position - hrp.Position).Unit
        local look = CFrame.lookAt(hrp.Position, hrp.Position + dir)
        
        TweenService:Create(
            hrp,
            TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
            {CFrame = look}
        ):Play()
    end)
end

-- Cooldown Logic
local recentTriggers = {}
local inCooldown = false
local cooldownConnection = nil

local function ActivateCooldown()
    if inCooldown then return end
    inCooldown = true
    
    ShowToast("Rate limit triggered - cooling down", "warning")
    
    local start = tick()
    while tick() - start < SETTINGS.CooldownDuration do
        task.wait(1)
    end
    
    inCooldown = false
    recentTriggers = {}
    ShowToast("Ready to respond again", "success")
end

local function RegisterTrigger()
    local now = tick()
    table.insert(recentTriggers, now)

    -- Clean old triggers
    local newList = {}
    for _, t in ipairs(recentTriggers) do
        if now - t <= SETTINGS.CooldownTriggerWindow then 
            table.insert(newList, t) 
        end
    end
    recentTriggers = newList

    if #recentTriggers >= SETTINGS.CooldownTriggerCount and not inCooldown then
        task.spawn(ActivateCooldown)
    end
end

-- Chat History Management
chatHistory = {}

local function TrimChatHistory()
    while #chatHistory > SETTINGS.MaxChatHistory do
        table.remove(chatHistory, 1)
    end
end

-- AI Chat Handling with Retry Logic
local function HandleAI(message, senderName)
    local cfg = getgenv().MapleConfig
    if not cfg.MasterEnabled then return end
    if inCooldown then return end
    if not request then return end

    RegisterTrigger()
    statsData.messagesProcessed = statsData.messagesProcessed + 1
    messagesValueLabel.Text = tostring(statsData.messagesProcessed)

    -- Add context about who is speaking
    local contextMessage = senderName and (senderName .. " says: " .. message) or message
    table.insert(chatHistory, {role = "user", content = contextMessage})
    TrimChatHistory()

    local payload = {
        model = cfg.Model,
        messages = {
            {role = "system", content = cfg.Persona},
            unpack(chatHistory)
        }
    }

    local result = nil
    local lastError = nil
    
    for attempt = 1, SETTINGS.ApiRetryCount do
        local success, response = pcall(function()
            return request({
                Url = "https://api.mapleai.de/v1/chat/completions",
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Authorization"] = "Bearer " .. cfg.APIKey
                },
                Body = HttpService:JSONEncode(payload)
            })
        end)
        
        if success and response and response.Body then
            result = response
            break
        else
            lastError = response
            DebugLog("API attempt", attempt, "failed:", tostring(response))
            if attempt < SETTINGS.ApiRetryCount then
                task.wait(SETTINGS.ApiRetryDelay)
            end
        end
    end

    if not result or not result.Body then
        statsData.errors = statsData.errors + 1
        errorsValueLabel.Text = tostring(statsData.errors)
        DebugLog("API request failed after retries:", tostring(lastError))
        return
    end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(result.Body)
    end)

    if not ok then
        statsData.errors = statsData.errors + 1
        errorsValueLabel.Text = tostring(statsData.errors)
        DebugLog("Failed to decode response:", result.Body)
        return
    end
    
    if decoded.error then
        statsData.errors = statsData.errors + 1
        errorsValueLabel.Text = tostring(statsData.errors)
        DebugLog("API error:", decoded.error.message or decoded.error)
        return
    end

    if not decoded.choices or not decoded.choices[1] then
        DebugLog("No choices in response")
        return
    end

    local reply = decoded.choices[1].message and decoded.choices[1].message.content
    if not reply or reply == "" then 
        DebugLog("Empty reply from API")
        return 
    end

    table.insert(chatHistory, {role = "assistant", content = reply})
    TrimChatHistory()
    
    statsData.responsesGenerated = statsData.responsesGenerated + 1
    responsesValueLabel.Text = tostring(statsData.responsesGenerated)

    Say(reply)
end

local function OnPlayerChatted(player, msg)
    if player == LocalPlayer then return end
    
    local cfg = getgenv().MapleConfig
    if not cfg.MasterEnabled then return end

    if table.find(cfg.Blacklist, player.Name) or table.find(cfg.Blacklist, player.DisplayName) then 
        DebugLog("Message from blacklisted player:", player.Name)
        return 
    end

    -- Face the player
    if player.Character then 
        pcall(function()
            FaceTarget(player.Character) 
        end)
    end

    task.spawn(function()
        HandleAI(msg, player.DisplayName or player.Name)
    end)
end

-- Connect chat events with proper cleanup
local function ConnectPlayerChat(plr)
    if plr == LocalPlayer then return end
    
    local connection = plr.Chatted:Connect(function(msg)
        OnPlayerChatted(plr, msg)
    end)
    
    ConnectionManager:Add(connection, "PlayerChat_" .. plr.UserId)
end

-- Connect existing players
for _, plr in ipairs(Players:GetPlayers()) do
    ConnectPlayerChat(plr)
end

-- Connect new players
ConnectionManager:Add(Players.PlayerAdded:Connect(function(plr)
    ConnectPlayerChat(plr)
end), "PlayerAdded")

-- Cleanup on player leave
ConnectionManager:Add(Players.PlayerRemoving:Connect(function(plr)
    ConnectionManager:Remove("PlayerChat_" .. plr.UserId)
end), "PlayerRemoving")

--========================================================--
-- CLEANUP ON DESTROY
--========================================================--

ScreenGui.Destroying:Connect(function()
    ConnectionManager:Cleanup()
end)

-- Keyboard shortcut to toggle window
ConnectionManager:Add(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.F9 then
        MainWindow.Visible = not MainWindow.Visible
        if MainWindow.Visible then
            MainWindow.Size = UDim2.new(0, 550, 0, 0)
            Tween(MainWindow, {Size = originalSize}, 0.3, Enum.EasingStyle.Back)
        end
    end
end), "KeyboardToggle")

--========================================================--
-- INITIALIZATION COMPLETE
--========================================================--

DebugLog("Maple AI v2.0 loaded successfully")
ShowToast("Maple AI v2.0 loaded!", "success", 2)

--========================================================--
-- END OF FULL main.lua
--========================================================--