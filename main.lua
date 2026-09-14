-- ❄️ Winter Hub v34 - No Start Sound + Welcome Fix
-- Klick-Sound bleibt, Welcome funktioniert, Auto Shoot schießt bis tot

local isXeno = false
local isDelta = false
pcall(function()
    local exec = identifyexecutor and identifyexecutor() or "Unknown"
    isXeno = exec:lower():find("xeno") and true or false
    isDelta = exec:lower():find("delta") and true or false
end)

if _G.WinterCleanup then pcall(_G.WinterCleanup) end
pcall(function()
    if gethui then
        local hui = gethui()
        if hui:FindFirstChild("WinterHub") then hui.WinterHub:Destroy() end
    end
    if game:GetService("CoreGui"):FindFirstChild("WinterHub") then
        game:GetService("CoreGui").WinterHub:Destroy()
    end
    local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if pg and pg:FindFirstChild("WinterHub") then pg.WinterHub:Destroy() end
end)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ⚠️ START SOUND ENTFERNT (kein 5-Sek-Ping mehr)

-- ==================== SOUND FEEDBACK (Klick bleibt!) ====================
local function playToggleSound(on)
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = on and "rbxasset://sounds/switch3.wav" or "rbxasset://sounds/switch.wav"
        s.Volume = 1.5
        s.Parent = SoundService
        s:Play()
        Debris:AddItem(s, 2)
    end)
end

-- ==================== CONFIG ====================
local SETTINGS_FILE = "WinterHub_Settings.json"

local defaultSettings = {
    Speed = 16, Jump = 50,
    AimbotFOV = 150, AimbotSmooth = 15,
    AimbotMode = "Camera", AimbotPart = "Head",
    HitboxSize = 15, TriggerDelay = 10,
    AutoShootDelay = 5, ESPTransparency = 50,
    FlySpeed = 60, CurrentTab = "Move",
}

local Settings = {}
for k, v in pairs(defaultSettings) do Settings[k] = v end

local Toggles = {
    InfiniteJump = false, Noclip = false, Invisible = false,
    ESP = false, TeamESP = false,
    Aimbot = false, WallCheck = false,
    Hitbox = false, Triggerbot = false, AutoShoot = false,
    AntiAFK = false, AutoRespawn = false, Fullbright = false,
    Fly = false,
}

local function saveSettings()
    pcall(function()
        if writefile then writefile(SETTINGS_FILE, HttpService:JSONEncode(Settings)) end
    end)
end

local function loadSettings()
    local ok, data = pcall(function()
        if isfile and isfile(SETTINGS_FILE) then
            return HttpService:JSONDecode(readfile(SETTINGS_FILE))
        end
    end)
    if ok and data then
        for k, v in pairs(data) do
            if Settings[k] ~= nil then Settings[k] = v end
        end
        return true
    end
    return false
end

local hasConfig = loadSettings()

local Connections = {}
local ESPObjects = {}
local OriginalSizes = {}
local OriginalTransparency = {}
local OriginalLighting = {}
local Tween1 = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local Checkpoints = {}
local checkpointFolder = nil
local nextCheckpointNumber = 1

local function addConn(c) table.insert(Connections, c) return c end

-- ==================== FARBEN ====================
local C = {
    BG = Color3.fromRGB(16, 17, 22),
    BG2 = Color3.fromRGB(22, 24, 30),
    Card = Color3.fromRGB(27, 29, 37),
    Card2 = Color3.fromRGB(33, 36, 45),
    CardHover = Color3.fromRGB(40, 44, 55),
    Line = Color3.fromRGB(45, 48, 60),
    LineHi = Color3.fromRGB(60, 65, 80),
    Accent = Color3.fromRGB(95, 165, 255),
    Accent2 = Color3.fromRGB(120, 200, 255),
    Text = Color3.fromRGB(240, 244, 252),
    TextDim = Color3.fromRGB(130, 140, 160),
    TextMid = Color3.fromRGB(175, 185, 205),
    Green = Color3.fromRGB(95, 220, 155),
    Red = Color3.fromRGB(240, 100, 115),
    Checkpoint = Color3.fromRGB(255, 70, 90),
}

-- ==================== GUI PARENT ====================
local parentGui
pcall(function() if gethui then parentGui = gethui() end end)
if not parentGui then pcall(function() parentGui = game:GetService("CoreGui") end) end
if not parentGui then pcall(function() parentGui = LocalPlayer:WaitForChild("PlayerGui", 5) end) end
if not parentGui then error("Kein GUI Parent!") end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WinterHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = parentGui

-- ==================== WELCOME SCREEN (FIXED) ====================
local WelcomeFrame = Instance.new("Frame")
WelcomeFrame.Size = UDim2.new(1, 0, 1, 0)
WelcomeFrame.BackgroundTransparency = 1
WelcomeFrame.BorderSizePixel = 0
WelcomeFrame.ZIndex = 100
WelcomeFrame.Active = false
WelcomeFrame.Parent = ScreenGui

local WelcomeGlow = Instance.new("Frame")
WelcomeGlow.Size = UDim2.new(0, 320, 0, 160)
WelcomeGlow.Position = UDim2.new(0.5, -160, 0.5, -80)
WelcomeGlow.BackgroundColor3 = C.Accent
WelcomeGlow.BackgroundTransparency = 1
WelcomeGlow.BorderSizePixel = 0
WelcomeGlow.ZIndex = 100
WelcomeGlow.Parent = WelcomeFrame

local WelcomeGlowGrad = Instance.new("UIGradient")
WelcomeGlowGrad.Color = ColorSequence.new(C.Accent, C.Accent2)
WelcomeGlowGrad.Transparency = NumberSequence.new(1)
WelcomeGlowGrad.Rotation = 45
WelcomeGlowGrad.Parent = WelcomeGlow

local WelcomeBG = Instance.new("Frame")
WelcomeBG.Size = UDim2.new(0, 340, 0, 180)
WelcomeBG.Position = UDim2.new(0.5, -170, 0.5, -90)
WelcomeBG.BackgroundColor3 = C.BG
WelcomeBG.BackgroundTransparency = 1
WelcomeBG.BorderSizePixel = 0
WelcomeBG.ZIndex = 101
WelcomeBG.Parent = WelcomeFrame

local WelcomeBGCorner = Instance.new("UICorner")
WelcomeBGCorner.CornerRadius = UDim.new(0, 14)
WelcomeBGCorner.Parent = WelcomeBG

local WelcomeBGStroke = Instance.new("UIStroke")
WelcomeBGStroke.Color = C.Accent
WelcomeBGStroke.Thickness = 2
WelcomeBGStroke.Transparency = 1
WelcomeBGStroke.Parent = WelcomeBG

local WelcomeIcon = Instance.new("TextLabel")
WelcomeIcon.Size = UDim2.new(1, 0, 0, 50)
WelcomeIcon.Position = UDim2.new(0, 0, 0, 15)
WelcomeIcon.BackgroundTransparency = 1
WelcomeIcon.Text = "❄"
WelcomeIcon.TextColor3 = C.Accent2
WelcomeIcon.Font = Enum.Font.GothamBold
WelcomeIcon.TextSize = 50
WelcomeIcon.TextTransparency = 1
WelcomeIcon.ZIndex = 102
WelcomeIcon.Parent = WelcomeBG

local WelcomeTitle = Instance.new("TextLabel")
WelcomeTitle.Size = UDim2.new(1, 0, 0, 34)
WelcomeTitle.Position = UDim2.new(0, 0, 0, 70)
WelcomeTitle.BackgroundTransparency = 1
WelcomeTitle.Text = "WELCOME TO WINTER HUB"
WelcomeTitle.TextColor3 = C.Text
WelcomeTitle.Font = Enum.Font.GothamBlack
WelcomeTitle.TextSize = 20
WelcomeTitle.TextTransparency = 1
WelcomeTitle.ZIndex = 102
WelcomeTitle.Parent = WelcomeBG

local WelcomeUser = Instance.new("TextLabel")
WelcomeUser.Size = UDim2.new(1, 0, 0, 22)
WelcomeUser.Position = UDim2.new(0, 0, 0, 108)
WelcomeUser.BackgroundTransparency = 1
WelcomeUser.Text = "👤  " .. LocalPlayer.Name
WelcomeUser.TextColor3 = C.Accent
WelcomeUser.Font = Enum.Font.GothamBold
WelcomeUser.TextSize = 14
WelcomeUser.TextTransparency = 1
WelcomeUser.ZIndex = 102
WelcomeUser.Parent = WelcomeBG

local WelcomeSub = Instance.new("TextLabel")
WelcomeSub.Size = UDim2.new(1, 0, 0, 18)
WelcomeSub.Position = UDim2.new(0, 0, 0, 138)
WelcomeSub.BackgroundTransparency = 1
WelcomeSub.Text = "v34"
WelcomeSub.TextColor3 = C.TextDim
WelcomeSub.Font = Enum.Font.GothamMedium
WelcomeSub.TextSize = 10
WelcomeSub.TextTransparency = 1
WelcomeSub.ZIndex = 102
WelcomeSub.Parent = WelcomeBG

task.spawn(function()
    task.wait(0.1)
    TweenService:Create(WelcomeGlow, TweenInfo.new(0.8), {BackgroundTransparency = 0.85}):Play()
    TweenService:Create(WelcomeGlowGrad, TweenInfo.new(0.8), {Transparency = NumberSequence.new(0.5)}):Play()
    TweenService:Create(WelcomeBG, TweenInfo.new(0.6), {BackgroundTransparency = 0}):Play()
    TweenService:Create(WelcomeBGStroke, TweenInfo.new(0.6), {Transparency = 0}):Play()
    task.wait(0.15)
    TweenService:Create(WelcomeIcon, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    task.wait(0.15)
    TweenService:Create(WelcomeTitle, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    task.wait(0.15)
    TweenService:Create(WelcomeUser, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    task.wait(0.1)
    TweenService:Create(WelcomeSub, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    task.wait(3)
    TweenService:Create(WelcomeBG, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
    TweenService:Create(WelcomeBGStroke, TweenInfo.new(0.4), {Transparency = 1}):Play()
    TweenService:Create(WelcomeGlow, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
    TweenService:Create(WelcomeGlowGrad, TweenInfo.new(0.4), {Transparency = NumberSequence.new(1)}):Play()
    TweenService:Create(WelcomeIcon, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
    TweenService:Create(WelcomeTitle, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
    TweenService:Create(WelcomeUser, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
    TweenService:Create(WelcomeSub, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
    task.wait(0.5)
    WelcomeFrame:Destroy()
end)

-- ==================== MAIN WINDOW ====================
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 420, 0, 380)
Main.Position = UDim2.new(0.5, -210, 0.5, -190)
Main.BackgroundColor3 = C.BG
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.ClipsDescendants = true
Main.ZIndex = 10
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local MainGrad = Instance.new("UIGradient")
MainGrad.Color = ColorSequence.new(C.BG, C.BG2)
MainGrad.Rotation = 135
MainGrad.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = C.Accent
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.3
MainStroke.Parent = Main

task.spawn(function()
    while MainStroke.Parent do
        TweenService:Create(MainStroke, TweenInfo.new(2), {Transparency = 0.7}):Play()
        task.wait(2)
        TweenService:Create(MainStroke, TweenInfo.new(2), {Transparency = 0.3}):Play()
        task.wait(2)
    end
end)

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundColor3 = C.BG2
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleBarCorner = Instance.new("UICorner")
TitleBarCorner.CornerRadius = UDim.new(0, 12)
TitleBarCorner.Parent = TitleBar

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 16)
TitleFix.Position = UDim2.new(0, 0, 1, -16)
TitleFix.BackgroundColor3 = C.BG2
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local IconBox = Instance.new("Frame")
IconBox.Size = UDim2.new(0, 26, 0, 26)
IconBox.Position = UDim2.new(0, 12, 0, 8)
IconBox.BackgroundColor3 = C.Accent
IconBox.BorderSizePixel = 0
IconBox.Parent = TitleBar
local IconBoxCorner = Instance.new("UICorner") IconBoxCorner.CornerRadius = UDim.new(0, 7) IconBoxCorner.Parent = IconBox
local IconBoxGrad = Instance.new("UIGradient") IconBoxGrad.Color = ColorSequence.new(C.Accent, C.Accent2) IconBoxGrad.Rotation = 45 IconBoxGrad.Parent = IconBox

local IconLbl = Instance.new("TextLabel")
IconLbl.Size = UDim2.new(1, 0, 1, 0)
IconLbl.BackgroundTransparency = 1
IconLbl.Text = "❄"
IconLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
IconLbl.Font = Enum.Font.GothamBold
IconLbl.TextSize = 15
IconLbl.Parent = IconBox

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1, -180, 1, 0)
TitleLbl.Position = UDim2.new(0, 46, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "Winter Hub"
TitleLbl.TextColor3 = C.Text
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 14
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Parent = TitleBar

local VerBadge = Instance.new("Frame")
VerBadge.Size = UDim2.new(0, 32, 0, 16)
VerBadge.Position = UDim2.new(0, 128, 0.5, -8)
VerBadge.BackgroundColor3 = C.Card
VerBadge.BorderSizePixel = 0
VerBadge.Parent = TitleBar
local VerBadgeCorner = Instance.new("UICorner") VerBadgeCorner.CornerRadius = UDim.new(0, 5) VerBadgeCorner.Parent = VerBadge
local VerBadgeStroke = Instance.new("UIStroke") VerBadgeStroke.Color = C.LineHi VerBadgeStroke.Thickness = 1 VerBadgeStroke.Parent = VerBadge

local VerLbl = Instance.new("TextLabel")
VerLbl.Size = UDim2.new(1, 0, 1, 0)
VerLbl.BackgroundTransparency = 1
VerLbl.Text = "v34"
VerLbl.TextColor3 = C.TextMid
VerLbl.Font = Enum.Font.GothamBold
VerLbl.TextSize = 9
VerLbl.Parent = VerBadge

local Dot = Instance.new("Frame")
Dot.Size = UDim2.new(0, 6, 0, 6)
Dot.Position = UDim2.new(0, 168, 0.5, -3)
Dot.BackgroundColor3 = C.Green
Dot.BorderSizePixel = 0
Dot.Parent = TitleBar
local DotCorner = Instance.new("UICorner") DotCorner.CornerRadius = UDim.new(1, 0) DotCorner.Parent = Dot

task.spawn(function()
    while Dot.Parent do
        TweenService:Create(Dot, TweenInfo.new(1.3), {BackgroundTransparency = 0.7}):Play()
        task.wait(1.3)
        TweenService:Create(Dot, TweenInfo.new(1.3), {BackgroundTransparency = 0}):Play()
        task.wait(1.3)
    end
end)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 26, 0, 26)
MinBtn.Position = UDim2.new(1, -60, 0, 8)
MinBtn.BackgroundColor3 = C.Card
MinBtn.Text = "–"
MinBtn.TextColor3 = C.TextMid
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 14
MinBtn.BorderSizePixel = 0
MinBtn.AutoButtonColor = false
MinBtn.Parent = TitleBar
local MinBtnCorner = Instance.new("UICorner") MinBtnCorner.CornerRadius = UDim.new(0, 7) MinBtnCorner.Parent = MinBtn
local MinStroke = Instance.new("UIStroke") MinStroke.Color = C.LineHi MinStroke.Thickness = 1 MinStroke.Transparency = 0.5 MinStroke.Parent = MinBtn

local XBtn = Instance.new("TextButton")
XBtn.Size = UDim2.new(0, 26, 0, 26)
XBtn.Position = UDim2.new(1, -32, 0, 8)
XBtn.BackgroundColor3 = C.Card
XBtn.Text = "✕"
XBtn.TextColor3 = C.TextMid
XBtn.Font = Enum.Font.GothamBold
XBtn.TextSize = 11
XBtn.BorderSizePixel = 0
XBtn.AutoButtonColor = false
XBtn.Parent = TitleBar
local XBtnCorner = Instance.new("UICorner") XBtnCorner.CornerRadius = UDim.new(0, 7) XBtnCorner.Parent = XBtn
local XStroke = Instance.new("UIStroke") XStroke.Color = C.LineHi XStroke.Thickness = 1 XStroke.Transparency = 0.5 XStroke.Parent = XBtn

MinBtn.MouseEnter:Connect(function()
    TweenService:Create(MinBtn, Tween1, {BackgroundColor3 = C.CardHover}):Play()
    TweenService:Create(MinStroke, Tween1, {Color = C.Accent}):Play()
end)
MinBtn.MouseLeave:Connect(function()
    TweenService:Create(MinBtn, Tween1, {BackgroundColor3 = C.Card}):Play()
    TweenService:Create(MinStroke, Tween1, {Color = C.LineHi}):Play()
end)
XBtn.MouseEnter:Connect(function()
    TweenService:Create(XBtn, Tween1, {BackgroundColor3 = C.Red}):Play()
    TweenService:Create(XStroke, Tween1, {Color = C.Red}):Play()
    XBtn.TextColor3 = C.Text
end)
XBtn.MouseLeave:Connect(function()
    TweenService:Create(XBtn, Tween1, {BackgroundColor3 = C.Card}):Play()
    TweenService:Create(XStroke, Tween1, {Color = C.LineHi}):Play()
    XBtn.TextColor3 = C.TextMid
end)

local MiniIcon = Instance.new("TextButton")
MiniIcon.Name = "MiniIcon"
MiniIcon.Size = UDim2.new(0, 50, 0, 50)
MiniIcon.Position = UDim2.new(0, 15, 0.5, -25)
MiniIcon.BackgroundColor3 = C.Accent
MiniIcon.Text = "❄"
MiniIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniIcon.Font = Enum.Font.GothamBold
MiniIcon.TextSize = 24
MiniIcon.BorderSizePixel = 0
MiniIcon.AutoButtonColor = false
MiniIcon.Visible = false
MiniIcon.Active = true
MiniIcon.Draggable = true
MiniIcon.ZIndex = 10
MiniIcon.Parent = ScreenGui
local MiniIconCorner = Instance.new("UICorner") MiniIconCorner.CornerRadius = UDim.new(0, 12) MiniIconCorner.Parent = MiniIcon
local MiniIconGrad = Instance.new("UIGradient") MiniIconGrad.Color = ColorSequence.new(C.Accent, C.Accent2) MiniIconGrad.Rotation = 45 MiniIconGrad.Parent = MiniIcon

MinBtn.MouseButton1Click:Connect(function() Main.Visible = false MiniIcon.Visible = true end)
MiniIcon.MouseButton1Click:Connect(function() Main.Visible = true MiniIcon.Visible = false end)
XBtn.MouseButton1Click:Connect(function() Main.Visible = false MiniIcon.Visible = false end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 84, 1, -52)
Sidebar.Position = UDim2.new(0, 8, 0, 44)
Sidebar.BackgroundColor3 = C.Card
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main
local SidebarCorner = Instance.new("UICorner") SidebarCorner.CornerRadius = UDim.new(0, 10) SidebarCorner.Parent = Sidebar
local SidebarStroke = Instance.new("UIStroke") SidebarStroke.Color = C.Line SidebarStroke.Thickness = 1 SidebarStroke.Transparency = 0.5 SidebarStroke.Parent = Sidebar

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 4)
SidebarLayout.Parent = Sidebar

local SidebarPad = Instance.new("UIPadding")
SidebarPad.PaddingLeft = UDim.new(0, 5)
SidebarPad.PaddingRight = UDim.new(0, 5)
SidebarPad.PaddingTop = UDim.new(0, 8)
SidebarPad.PaddingBottom = UDim.new(0, 8)
SidebarPad.Parent = Sidebar

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -104, 1, -88)
Content.Position = UDim2.new(0, 96, 0, 44)
Content.BackgroundTransparency = 1
Content.Parent = Main

local StatusBar = Instance.new("Frame")
StatusBar.Size = UDim2.new(1, -16, 0, 32)
StatusBar.Position = UDim2.new(0, 8, 1, -40)
StatusBar.BackgroundColor3 = C.Card
StatusBar.BorderSizePixel = 0
StatusBar.Parent = Main
local StatusBarCorner = Instance.new("UICorner") StatusBarCorner.CornerRadius = UDim.new(0, 8) StatusBarCorner.Parent = StatusBar
local StatusStroke = Instance.new("UIStroke") StatusStroke.Color = C.Line StatusStroke.Thickness = 1 StatusStroke.Transparency = 0.5 StatusStroke.Parent = StatusBar

local StatusIconBox = Instance.new("Frame")
StatusIconBox.Size = UDim2.new(0, 20, 0, 20)
StatusIconBox.Position = UDim2.new(0, 8, 0.5, -10)
StatusIconBox.BackgroundColor3 = C.Accent
StatusIconBox.BorderSizePixel = 0
StatusIconBox.Parent = StatusBar
local StatusIconCorner = Instance.new("UICorner") StatusIconCorner.CornerRadius = UDim.new(0, 6) StatusIconCorner.Parent = StatusIconBox

local StatusIcon = Instance.new("TextLabel")
StatusIcon.Size = UDim2.new(1, 0, 1, 0)
StatusIcon.BackgroundTransparency = 1
StatusIcon.Text = "❄"
StatusIcon.TextColor3 = C.Text
StatusIcon.Font = Enum.Font.GothamBold
StatusIcon.TextSize = 11
StatusIcon.Parent = StatusIconBox

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(1, -150, 1, 0)
StatusLbl.Position = UDim2.new(0, 34, 0, 0)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text = hasConfig and "Settings loaded ✓" or "Ready"
StatusLbl.TextColor3 = C.TextMid
StatusLbl.Font = Enum.Font.GothamMedium
StatusLbl.TextSize = 11
StatusLbl.TextXAlignment = Enum.TextXAlignment.Left
StatusLbl.Parent = StatusBar

local ActiveLbl = Instance.new("TextLabel")
ActiveLbl.Size = UDim2.new(0, 120, 1, 0)
ActiveLbl.Position = UDim2.new(1, -130, 0, 0)
ActiveLbl.BackgroundTransparency = 1
ActiveLbl.Text = ""
ActiveLbl.TextColor3 = C.Accent
ActiveLbl.Font = Enum.Font.GothamMedium
ActiveLbl.TextSize = 10
ActiveLbl.TextXAlignment = Enum.TextXAlignment.Right
ActiveLbl.Parent = StatusBar

local function setStatus(txt, ok)
    StatusLbl.Text = txt
    StatusLbl.TextColor3 = ok and C.Green or C.Red
    task.delay(2.5, function()
        if StatusLbl.Text == txt then
            StatusLbl.Text = "Ready"
            StatusLbl.TextColor3 = C.TextMid
        end
    end)
end

-- ==================== HELPERS ====================
local function makeScroll(parent)
    local s = Instance.new("ScrollingFrame")
    s.Size = UDim2.new(1, 0, 1, 0)
    s.BackgroundTransparency = 1
    s.BorderSizePixel = 0
    s.ScrollBarThickness = 3
    s.ScrollBarImageColor3 = C.Accent
    s.ScrollBarImageTransparency = 0.4
    s.CanvasSize = UDim2.new(0, 0, 0, 0)
    s.AutomaticCanvasSize = Enum.AutomaticSize.Y
    s.Parent = parent
    return s
end

local function makeSection(parent, text, y)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -6, 0, 22)
    f.Position = UDim2.new(0, 3, 0, y)
    f.BackgroundTransparency = 1
    f.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -6, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text:upper()
    lbl.TextColor3 = C.Accent
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f

    local line = Instance.new("Frame")
    line.Size = UDim2.new(0.7, -10, 0, 1)
    line.Position = UDim2.new(0.3, 10, 0.5, 1)
    line.BackgroundColor3 = C.Line
    line.BackgroundTransparency = 0.4
    line.BorderSizePixel = 0
    line.Parent = f
end

local function makeInput(parent, y, placeholder, x, w, default, callback)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(w or 0.5, -6, 0, 30)
    box.Position = UDim2.new(x, (x == 0.5) and 3 or 3, 0, y)
    box.BackgroundColor3 = C.Card
    box.TextColor3 = C.Text
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = C.TextDim
    box.Text = default or ""
    box.Font = Enum.Font.GothamBold
    box.TextSize = 12
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    box.Parent = parent

    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = box
    local s = Instance.new("UIStroke") s.Color = C.Line s.Thickness = 1 s.Transparency = 0.5 s.Parent = box

    box.Focused:Connect(function()
        TweenService:Create(s, Tween1, {Color = C.Accent, Transparency = 0}):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(s, Tween1, {Color = C.Line, Transparency = 0.5}):Play()
        if callback then callback(box.Text) end
    end)
    return box
end

local function makeButton(parent, text, x, y, w, h, baseColor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(w or 0.5, -6, 0, h or 28)
    btn.Position = UDim2.new(x, (x == 0.5) and 3 or 3, 0, y)
    btn.BackgroundColor3 = baseColor or C.Accent
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = parent

    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = btn
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new(baseColor or C.Accent, (baseColor or C.Accent):Lerp(C.Accent2, 0.4))
    grad.Rotation = 45
    grad.Parent = btn
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1
    stroke.Transparency = 0.75
    stroke.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(stroke, Tween1, {Transparency = 0.4}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(stroke, Tween1, {Transparency = 0.75}):Play()
    end)
    return btn
end

local function makeToggle(parent, text, x, y, w, initialState, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(w or 0.5, -6, 0, 34)
    row.Position = UDim2.new(x, (x == 0.5) and 3 or 3, 0, y)
    row.BackgroundColor3 = C.Card
    row.BorderSizePixel = 0
    row.Parent = parent

    local rC = Instance.new("UICorner") rC.CornerRadius = UDim.new(0, 8) rC.Parent = row
    local rS = Instance.new("UIStroke") rS.Color = C.Line rS.Thickness = 1 rS.Transparency = 0.5 rS.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -48, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = initialState and C.Text or C.TextDim
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 34, 0, 18)
    pill.Position = UDim2.new(1, -44, 0.5, -9)
    pill.BackgroundColor3 = initialState and C.Accent or C.Card2
    pill.BorderSizePixel = 0
    pill.Parent = row
    local pillCorner = Instance.new("UICorner") pillCorner.CornerRadius = UDim.new(1, 0) pillCorner.Parent = pill

    local pillStroke = Instance.new("UIStroke")
    pillStroke.Color = initialState and C.Accent2 or C.LineHi
    pillStroke.Thickness = 1
    pillStroke.Transparency = initialState and 0 or 0.5
    pillStroke.Parent = pill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = initialState and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
    knob.BackgroundColor3 = initialState and C.Text or C.TextDim
    knob.BorderSizePixel = 0
    knob.Parent = pill
    local knobCorner = Instance.new("UICorner") knobCorner.CornerRadius = UDim.new(1, 0) knobCorner.Parent = knob

    local click = Instance.new("TextButton")
    click.Size = UDim2.new(1, 0, 1, 0)
    click.BackgroundTransparency = 1
    click.Text = ""
    click.ZIndex = 5
    click.Parent = row

    local on = initialState

    local function updateVisual(state)
        on = state
        if state then
            TweenService:Create(pill, Tween1, {BackgroundColor3 = C.Accent}):Play()
            TweenService:Create(pillStroke, Tween1, {Color = C.Accent2, Transparency = 0}):Play()
            TweenService:Create(knob, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -15, 0.5, -6),
                BackgroundColor3 = C.Text
            }):Play()
            TweenService:Create(label, Tween1, {TextColor3 = C.Text}):Play()
            TweenService:Create(rS, Tween1, {Color = C.Accent, Transparency = 0.3}):Play()
        else
            TweenService:Create(pill, Tween1, {BackgroundColor3 = C.Card2}):Play()
            TweenService:Create(pillStroke, Tween1, {Color = C.LineHi, Transparency = 0.5}):Play()
            TweenService:Create(knob, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 3, 0.5, -6),
                BackgroundColor3 = C.TextDim
            }):Play()
            TweenService:Create(label, Tween1, {TextColor3 = C.TextDim}):Play()
            TweenService:Create(rS, Tween1, {Color = C.Line, Transparency = 0.5}):Play()
        end
    end

    click.MouseButton1Click:Connect(function()
        on = not on
        updateVisual(on)
        playToggleSound(on)
        if callback then callback(on) end
    end)

    row.MouseEnter:Connect(function()
        if not on then TweenService:Create(row, Tween1, {BackgroundColor3 = C.CardHover}):Play() end
    end)
    row.MouseLeave:Connect(function()
        if not on then TweenService:Create(row, Tween1, {BackgroundColor3 = C.Card}):Play() end
    end)

    return row, function(state) updateVisual(state) end
end

local function makeSlider(parent, text, y, min, max, default, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 42)
    row.Position = UDim2.new(0, 3, 0, y)
    row.BackgroundColor3 = C.Card
    row.BorderSizePixel = 0
    row.Parent = parent
    local rC = Instance.new("UICorner") rC.CornerRadius = UDim.new(0, 8) rC.Parent = row
    local rS = Instance.new("UIStroke") rS.Color = C.Line rS.Thickness = 1 rS.Transparency = 0.5 rS.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 0, 16)
    lbl.Position = UDim2.new(0, 12, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C.TextMid
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local valBox = Instance.new("Frame")
    valBox.Size = UDim2.new(0, 44, 0, 18)
    valBox.Position = UDim2.new(1, -56, 0, 5)
    valBox.BackgroundColor3 = C.Card2
    valBox.BorderSizePixel = 0
    valBox.Parent = row
    local valBoxCorner = Instance.new("UICorner") valBoxCorner.CornerRadius = UDim.new(0, 5) valBoxCorner.Parent = valBox

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(1, 0, 1, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default)
    valLbl.TextColor3 = C.Accent2
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 10
    valLbl.Parent = valBox

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, 6)
    track.Position = UDim2.new(0, 12, 0, 30)
    track.BackgroundColor3 = C.Card2
    track.BorderSizePixel = 0
    track.Parent = row
    local trackCorner = Instance.new("UICorner") trackCorner.CornerRadius = UDim.new(1, 0) trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = C.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    local fillCorner = Instance.new("UICorner") fillCorner.CornerRadius = UDim.new(1, 0) fillCorner.Parent = fill
    local fillGrad = Instance.new("UIGradient") fillGrad.Color = ColorSequence.new(C.Accent, C.Accent2) fillGrad.Parent = fill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
    knob.BackgroundColor3 = C.Text
    knob.BorderSizePixel = 0
    knob.Parent = track
    local knobCorner = Instance.new("UICorner") knobCorner.CornerRadius = UDim.new(1, 0) knobCorner.Parent = knob
    local knobStroke = Instance.new("UIStroke") knobStroke.Color = C.Accent knobStroke.Thickness = 1.5 knobStroke.Parent = knob

    local dragging = false
    local value = default

    local function update(input)
        local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, -7, 0.5, -7)
        valLbl.Text = tostring(value)
        if callback then callback(value) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)
    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            saveSettings()
        end
    end)
    addConn(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end))

    return row, function() return value end
end

-- Tabs
local Tabs = {}
local TabButtons = {}

local function createTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = C.Card
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = Sidebar

    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = btn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = C.Line
    btnStroke.Thickness = 1
    btnStroke.Transparency = 0.6
    btnStroke.Parent = btn

    local iconLbl = Instance.new("TextLabel")
    iconLbl.Size = UDim2.new(1, 0, 0, 20)
    iconLbl.Position = UDim2.new(0, 0, 0, 4)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text = icon
    iconLbl.TextColor3 = C.TextDim
    iconLbl.Font = Enum.Font.GothamBold
    iconLbl.TextSize = 16
    iconLbl.Parent = btn

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, 0, 0, 12)
    nameLbl.Position = UDim2.new(0, 0, 0, 24)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = name
    nameLbl.TextColor3 = C.TextDim
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 9
    nameLbl.Parent = btn

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Visible = false
    container.Parent = Content

    local scroll = makeScroll(container)
    Tabs[name] = {
        Button = btn, Container = container, Scroll = scroll,
        IconLbl = iconLbl, NameLbl = nameLbl, Stroke = btnStroke
    }
    table.insert(TabButtons, {name = name, btn = btn})

    btn.MouseEnter:Connect(function()
        if not container.Visible then TweenService:Create(btn, Tween1, {BackgroundColor3 = C.CardHover}):Play() end
    end)
    btn.MouseLeave:Connect(function()
        if not container.Visible then TweenService:Create(btn, Tween1, {BackgroundColor3 = C.Card}):Play() end
    end)

    return scroll
end

local function switchTab(name)
    for tabName, tabData in pairs(Tabs) do
        if tabName == name then
            tabData.Container.Visible = true
            TweenService:Create(tabData.Button, Tween1, {BackgroundColor3 = C.Accent}):Play()
            TweenService:Create(tabData.IconLbl, Tween1, {TextColor3 = C.Text}):Play()
            TweenService:Create(tabData.NameLbl, Tween1, {TextColor3 = C.Text}):Play()
            TweenService:Create(tabData.Stroke, Tween1, {Color = C.Accent2, Transparency = 0}):Play()
        else
            tabData.Container.Visible = false
            TweenService:Create(tabData.Button, Tween1, {BackgroundColor3 = C.Card}):Play()
            TweenService:Create(tabData.IconLbl, Tween1, {TextColor3 = C.TextDim}):Play()
            TweenService:Create(tabData.NameLbl, Tween1, {TextColor3 = C.TextDim}):Play()
            TweenService:Create(tabData.Stroke, Tween1, {Color = C.Line, Transparency = 0.6}):Play()
        end
    end
    Settings.CurrentTab = name
    saveSettings()
end

-- ==================== FUNKTIONEN ====================
local speedConn, jumpConn = nil, nil

local function applySpeed(speed)
    Settings.Speed = speed
    local char = LocalPlayer.Character
    if char then
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = speed end
    end
    if speedConn then speedConn:Disconnect() end
    speedConn = RunService.RenderStepped:Connect(function()
        local c = LocalPlayer.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h and h.WalkSpeed ~= Settings.Speed then h.WalkSpeed = Settings.Speed end
        end
    end)
    saveSettings()
end

local function applyJump(jump)
    Settings.Jump = jump
    local char = LocalPlayer.Character
    if char then
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then pcall(function() h.UseJumpPower = true; h.JumpPower = jump end) end
    end
    if jumpConn then jumpConn:Disconnect() end
    jumpConn = RunService.RenderStepped:Connect(function()
        local c = LocalPlayer.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then
                if not h.UseJumpPower then h.UseJumpPower = true end
                if h.JumpPower ~= Settings.Jump then h.JumpPower = Settings.Jump end
            end
        end
    end)
    saveSettings()
end

local function createCheckpointMarker(position, number)
    if not checkpointFolder or not checkpointFolder.Parent then
        checkpointFolder = Instance.new("Folder")
        checkpointFolder.Name = "WinterHub_Checkpoints"
        checkpointFolder.Parent = workspace
    end

    local marker = Instance.new("Part")
    marker.Name = "Checkpoint_" .. number
    marker.Size = Vector3.new(3, 0.5, 3)
    marker.Position = position
    marker.Anchored = true
    marker.CanCollide = false
    marker.Material = Enum.Material.Neon
    marker.Color = C.Checkpoint
    marker.Transparency = 0.2
    marker.Shape = Enum.PartType.Cylinder
    marker.Orientation = Vector3.new(0, 0, 90)
    marker.Parent = checkpointFolder

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 60, 0, 30)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = marker

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "CP " .. number
    lbl.TextColor3 = C.Checkpoint
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 16
    lbl.Parent = bb

    task.spawn(function()
        while marker.Parent do
            marker.CFrame = marker.CFrame * CFrame.Angles(0, math.rad(2), 0)
            task.wait(0.05)
        end
    end)

    task.spawn(function()
        while marker.Parent do
            TweenService:Create(marker, TweenInfo.new(1), {Transparency = 0.6}):Play()
            task.wait(1)
            TweenService:Create(marker, TweenInfo.new(1), {Transparency = 0.2}):Play()
            task.wait(1)
        end
    end)

    return marker
end

local infJumpConn1, infJumpConn2 = nil, nil
local lastJumpTime = 0
local function toggleInfiniteJump(on)
    Toggles.InfiniteJump = on
    if on then
        infJumpConn1 = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local h = char:FindFirstChildOfClass("Humanoid")
                if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
            end
        end)
        addConn(infJumpConn1)
        infJumpConn2 = RunService.Heartbeat:Connect(function()
            if not Toggles.InfiniteJump then return end
            local now = tick()
            if now - lastJumpTime < 0.1 then return end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                local char = LocalPlayer.Character
                if char then
                    local h = char:FindFirstChildOfClass("Humanoid")
                    if h then
                        local state = h:GetState()
                        if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.RunningNoPhysics or state == Enum.HumanoidStateType.Landed then
                            pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
                            lastJumpTime = now
                        end
                    end
                end
            end
        end)
        addConn(infJumpConn2)
    else
        if infJumpConn1 then infJumpConn1:Disconnect() infJumpConn1 = nil end
        if infJumpConn2 then infJumpConn2:Disconnect() infJumpConn2 = nil end
    end
end

local noclipConn = nil
local function setCollide(char, state)
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = state
            pcall(function() part.CanQuery = state end)
            pcall(function() part.CanTouch = state end)
        end
    end
end

local function toggleNoclip(on)
    Toggles.Noclip = on
    if on then
        setCollide(LocalPlayer.Character, false)
        noclipConn = RunService.Stepped:Connect(function()
            if not Toggles.Noclip then return end
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
        addConn(noclipConn)
    else
        if noclipConn then noclipConn:Disconnect() noclipConn = nil end
        setCollide(LocalPlayer.Character, true)
    end
end

-- ==================== INVISIBLE (Tools) ====================
local invisibleConn = nil
local invisibleToolConn = nil
local savedTransparency = {}

local function collectParts(char)
    local parts = {}
    if not char then return parts end
    for _, obj in pairs(char:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Decal") then
            table.insert(parts, obj)
        end
    end
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            for _, obj in pairs(tool:GetDescendants()) do
                if obj:IsA("BasePart") or obj:IsA("Decal") then
                    table.insert(parts, obj)
                end
            end
        end
    end
    return parts
end

local function applyInvisible()
    local char = LocalPlayer.Character
    if not char then return end
    local parts = collectParts(char)
    for _, part in ipairs(parts) do
        if part.Transparency ~= 1 then
            if savedTransparency[part] == nil then
                savedTransparency[part] = part.Transparency
            end
            part.Transparency = 1
        end
    end
end

local function restoreInvisible()
    for obj, trans in pairs(savedTransparency) do
        pcall(function()
            if obj and obj.Parent then
                obj.Transparency = trans or 0
            end
        end)
    end
    savedTransparency = {}
end

local function toggleInvisible(on)
    Toggles.Invisible = on
    if on then
        applyInvisible()

        invisibleConn = RunService.Stepped:Connect(function()
            if not Toggles.Invisible then return end
            applyInvisible()
        end)
        addConn(invisibleConn)

        invisibleToolConn = LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            if Toggles.Invisible then
                savedTransparency = {}
                applyInvisible()
            end
        end)
        addConn(invisibleToolConn)

        local char = LocalPlayer.Character
        if char then
            addConn(char.ChildAdded:Connect(function(child)
                if Toggles.Invisible and child:IsA("Tool") then
                    task.wait(0.1)
                    for _, obj in pairs(child:GetDescendants()) do
                        if obj:IsA("BasePart") or obj:IsA("Decal") then
                            if savedTransparency[obj] == nil then
                                savedTransparency[obj] = obj.Transparency
                            end
                            obj.Transparency = 1
                        end
                    end
                end
            end))
        end
    else
        if invisibleConn then invisibleConn:Disconnect() invisibleConn = nil end
        if invisibleToolConn then invisibleToolConn:Disconnect() invisibleToolConn = nil end
        restoreInvisible()
    end
end

-- ==================== ANTI-AFK ====================
local antiAFKConn = nil
local function toggleAntiAFK(on)
    Toggles.AntiAFK = on
    if on then
        antiAFKConn = addConn(LocalPlayer.Idled:Connect(function()
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end))
    else
        if antiAFKConn then antiAFKConn:Disconnect() antiAFKConn = nil end
    end
end

-- ==================== AUTO RESPAWN ====================
local autoRespawnConn = nil
local function toggleAutoRespawn(on)
    Toggles.AutoRespawn = on
    if on then
        autoRespawnConn = addConn(RunService.Heartbeat:Connect(function()
            if not Toggles.AutoRespawn then return end
            local char = LocalPlayer.Character
            if char then
                local h = char:FindFirstChildOfClass("Humanoid")
                if h and h.Health <= 0 then
                    task.wait(1)
                    pcall(function() LocalPlayer:LoadCharacter() end)
                end
            end
        end))
    else
        if autoRespawnConn then autoRespawnConn:Disconnect() autoRespawnConn = nil end
    end
end

-- ==================== FULLBRIGHT ====================
local function toggleFullbright(on)
    Toggles.Fullbright = on
    if on then
        OriginalLighting.Ambient = Lighting.Ambient
        OriginalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
        OriginalLighting.Brightness = Lighting.Brightness
        OriginalLighting.ClockTime = Lighting.ClockTime
        OriginalLighting.FogEnd = Lighting.FogEnd
        OriginalLighting.FogStart = Lighting.FogStart

        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.Brightness = 3
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
    else
        if OriginalLighting.Ambient then
            Lighting.Ambient = OriginalLighting.Ambient
            Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
            Lighting.Brightness = OriginalLighting.Brightness
            Lighting.ClockTime = OriginalLighting.ClockTime
            Lighting.FogEnd = OriginalLighting.FogEnd
            Lighting.FogStart = OriginalLighting.FogStart
            OriginalLighting = {}
        end
    end
end

-- ==================== FLY (FIXED) ====================
local flyConn = nil
local flyBV = nil
local flyBG = nil

local function toggleFly(on)
    Toggles.Fly = on
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if on and hrp then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = true
        end

        flyBV = Instance.new("BodyVelocity")
        flyBV.Name = "WinterFly"
        flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = hrp

        flyBG = Instance.new("BodyGyro")
        flyBG.Name = "WinterFlyGyro"
        flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        flyBG.P = 10000
        flyBG.D = 100
        flyBG.Parent = hrp

        flyConn = addConn(RunService.RenderStepped:Connect(function()
            if not Toggles.Fly then return end
            local c = LocalPlayer.Character
            if not c then return end
            local h = c:FindFirstChildOfClass("Humanoid")
            local root = c:FindFirstChild("HumanoidRootPart")
            if not h or not root then return end

            if not flyBV or not flyBV.Parent then
                flyBV = Instance.new("BodyVelocity")
                flyBV.Name = "WinterFly"
                flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                flyBV.Parent = root
            end
            if not flyBG or not flyBG.Parent then
                flyBG = Instance.new("BodyGyro")
                flyBG.Name = "WinterFlyGyro"
                flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                flyBG.P = 10000
                flyBG.D = 100
                flyBG.Parent = root
            end

            local cam = Camera.CFrame
            local speed = Settings.FlySpeed

            local moveVec = Vector3.zero

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveVec = moveVec + cam.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveVec = moveVec - cam.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveVec = moveVec - cam.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveVec = moveVec + cam.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveVec = moveVec + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveVec = moveVec - Vector3.new(0, 1, 0)
            end

            if moveVec.Magnitude > 0 then
                flyBV.Velocity = moveVec.Unit * speed
            else
                flyBV.Velocity = Vector3.zero
            end

            if flyBG then
                flyBG.CFrame = cam
            end
        end))
    else
        if flyConn then flyConn:Disconnect() flyConn = nil end
        if flyBV then flyBV:Destroy() flyBV = nil end
        if flyBG then flyBG:Destroy() flyBG = nil end
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.PlatformStand = false
            end
        end
    end
end

-- ESP
local function createESP(player)
    if player == LocalPlayer or ESPObjects[player] then return end
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local h = Instance.new("Highlight")
    h.Name = "WinterESP"
    h.Adornee = char
    h.FillColor = C.Accent
    h.OutlineColor = C.Accent2
    h.FillTransparency = Settings.ESPTransparency / 100
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = char

    local bb = Instance.new("BillboardGui")
    bb.Name = "WinterESPName"
    bb.Size = UDim2.new(0, 200, 0, 40)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = char

    local n = Instance.new("TextLabel")
    n.Size = UDim2.new(1, 0, 0.5, 0)
    n.BackgroundTransparency = 1
    n.Text = player.Name
    n.TextColor3 = C.Text
    n.TextStrokeTransparency = 0
    n.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    n.Font = Enum.Font.GothamBold
    n.TextSize = 13
    n.Parent = bb

    local d = Instance.new("TextLabel")
    d.Size = UDim2.new(1, 0, 0.5, 0)
    d.Position = UDim2.new(0, 0, 0.5, 0)
    d.BackgroundTransparency = 1
    d.Text = "0m"
    d.TextColor3 = C.Accent2
    d.TextStrokeTransparency = 0
    d.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    d.Font = Enum.Font.GothamBold
    d.TextSize = 11
    d.Parent = bb

    ESPObjects[player] = {Highlight = h, Billboard = bb, DistLabel = d}
end

local function removeESP(player)
    local obj = ESPObjects[player]
    if obj then
        if obj.Highlight then obj.Highlight:Destroy() end
        if obj.Billboard then obj.Billboard:Destroy() end
        ESPObjects[player] = nil
    end
end

local function clearAllESP()
    for p, _ in pairs(ESPObjects) do removeESP(p) end
    ESPObjects = {}
end

local espConn = nil
local function toggleESP(on)
    Toggles.ESP = on
    if on then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then createESP(p) end
        end
        if espConn then espConn:Disconnect() end
        espConn = RunService.RenderStepped:Connect(function()
            if not Toggles.ESP then return end
            for player, obj in pairs(ESPObjects) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and obj.Billboard then
                    local hrp = player.Character.HumanoidRootPart
                    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if myHrp then
                        obj.DistLabel.Text = math.floor((hrp.Position - myHrp.Position).Magnitude) .. "m"
                    end
                end
            end
        end)
        addConn(espConn)
    else
        if espConn then espConn:Disconnect() espConn = nil end
        if not Toggles.TeamESP then clearAllESP() end
    end
end

local teamEspConn = nil
local function toggleTeamESP(on)
    Toggles.TeamESP = on
    if on then
        if not Toggles.ESP then toggleESP(true) end
        if teamEspConn then teamEspConn:Disconnect() end
        teamEspConn = RunService.Heartbeat:Connect(function()
            if not Toggles.TeamESP then return end
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and not ESPObjects[p] then createESP(p) end
            end
        end)
        addConn(teamEspConn)
    else
        if teamEspConn then teamEspConn:Disconnect() teamEspConn = nil end
        if not Toggles.ESP then clearAllESP() end
    end
end

local aimbotConn = nil

local function isVisible(part)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local r = workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position), params)
    if r then return r.Instance:FindFirstAncestorOfClass("Model") == part:FindFirstAncestorOfClass("Model") end
    return true
end

local function getTargetPart(player)
    local char = player.Character
    if not char then return nil end
    local names
    if Settings.AimbotPart == "Random" then
        names = {"Head", "UpperTorso", "HumanoidRootPart", "Torso"}
    else
        names = {Settings.AimbotPart}
        if Settings.AimbotPart == "UpperTorso" then table.insert(names, "Torso") end
    end
    for _, n in ipairs(names) do
        local p = char:FindFirstChild(n)
        if p then return p end
    end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getClosest()
    local best, bestPart
    local minD = Settings.AimbotFOV
    local mouse
    pcall(function() mouse = UserInputService:GetMouseLocation() end)
    if not mouse then
        mouse = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then
                local part = getTargetPart(p)
                if part then
                    local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        if not (Toggles.WallCheck and not isVisible(part)) then
                            local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                            if d < minD then
                                minD = d
                                best, bestPart = p, part
                            end
                        end
                    end
                end
            end
        end
    end
    return best, bestPart
end

local function toggleAimbot(on)
    Toggles.Aimbot = on
    if on then
        if aimbotConn then aimbotConn:Disconnect() end
        aimbotConn = RunService.RenderStepped:Connect(function()
            if not Toggles.Aimbot then return end
            local _, part = getClosest()
            if part then
                local targetPos = part.Position
                if Settings.AimbotMode == "Camera" or Settings.AimbotMode == "Silent" then
                    local currentCF = Camera.CFrame
                    local newCF = CFrame.new(currentCF.Position, targetPos)
                    Camera.CFrame = currentCF:Lerp(newCF, Settings.AimbotSmooth / 100)
                elseif Settings.AimbotMode == "Mouse" then
                    local sp = Camera:WorldToViewportPoint(targetPos)
                    local cx = Camera.ViewportSize.X / 2
                    local cy = Camera.ViewportSize.Y / 2
                    local dx = (sp.X - cx) * (Settings.AimbotSmooth / 100)
                    local dy = (sp.Y - cy) * (Settings.AimbotSmooth / 100)
                    pcall(function() if mousemoverel then mousemoverel(dx, dy) end end)
                end
            end
        end)
        addConn(aimbotConn)
    else
        if aimbotConn then aimbotConn:Disconnect() aimbotConn = nil end
    end
end

local function applyHitbox(player, size)
    local char = player.Character
    if not char then return end
    for _, n in ipairs({"HumanoidRootPart", "Head", "UpperTorso", "Torso", "LowerTorso"}) do
        local p = char:FindFirstChild(n)
        if p then
            if size > 0 then
                if not OriginalSizes[player] then OriginalSizes[player] = {} end
                if not OriginalSizes[player][n] then
                    OriginalSizes[player][n] = {Size = p.Size, Transparency = p.Transparency, CanCollide = p.CanCollide, Massless = p.Massless}
                end
                p.Size = Vector3.new(size, size, size)
                p.Transparency = 0.5
                p.CanCollide = false
                p.Massless = true
            elseif OriginalSizes[player] and OriginalSizes[player][n] then
                p.Size = OriginalSizes[player][n].Size
                p.Transparency = OriginalSizes[player][n].Transparency
                p.CanCollide = OriginalSizes[player][n].CanCollide
                p.Massless = OriginalSizes[player][n].Massless
            end
        end
    end
end

local hitboxConn = nil
local function toggleHitbox(on)
    Toggles.Hitbox = on
    if on then
        hitboxConn = RunService.Heartbeat:Connect(function()
            if not Toggles.Hitbox then return end
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then applyHitbox(p, Settings.HitboxSize) end
            end
        end)
        addConn(hitboxConn)
    else
        if hitboxConn then hitboxConn:Disconnect() hitboxConn = nil end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then applyHitbox(p, 0) end
        end
        OriginalSizes = {}
    end
end

local trigConn = nil
local lastTrig = 0
local function toggleTriggerbot(on)
    Toggles.Triggerbot = on
    if on then
        trigConn = RunService.RenderStepped:Connect(function()
            if not Toggles.Triggerbot then return end
            if tick() - lastTrig < (Settings.TriggerDelay / 100) then return end
            local rp = RaycastParams.new()
            rp.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
            rp.FilterType = Enum.RaycastFilterType.Exclude
            local r = workspace:Raycast(Camera.CFrame.Position, Camera.CFrame.LookVector * 500, rp)
            if r then
                local hc = r.Instance:FindFirstAncestorOfClass("Model")
                if hc and Players:GetPlayerFromCharacter(hc) and Players:GetPlayerFromCharacter(hc) ~= LocalPlayer then
                    local char = LocalPlayer.Character
                    if char then
                        local tool = char:FindFirstChildOfClass("Tool")
                        if tool then
                            pcall(function() tool:Activate() end)
                            lastTrig = tick()
                        end
                    end
                end
            end
        end)
        addConn(trigConn)
    else
        if trigConn then trigConn:Disconnect() trigConn = nil end
    end
end

-- ==================== AUTO SHOOT (FIXED - Schießt bis tot) ====================
local shootConn = nil
local lastShoot = 0

local function toggleAutoShoot(on)
    Toggles.AutoShoot = on
    if on then
        shootConn = RunService.RenderStepped:Connect(function()
            if not Toggles.AutoShoot then return end
            if tick() - lastShoot < (Settings.AutoShootDelay / 100) then return end

            local target, part = getClosest()

            if not target or not part then
                return
            end

            local targetChar = target.Character
            if not targetChar then return end

            local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
            if not targetHumanoid or targetHumanoid.Health <= 0 then
                return
            end

            local char = LocalPlayer.Character
            if not char then return end
            local tool = char:FindFirstChildOfClass("Tool")
            if not tool then return end

            if part then
                local sp = Camera:WorldToViewportPoint(part.Position)
                if sp and sp.Z ~= nil and sp.Z > 0 then
                    Camera.CFrame = Camera.CFrame:Lerp(
                        CFrame.new(Camera.CFrame.Position, part.Position),
                        0.5
                    )
                end
            end

            local success = pcall(function() tool:Activate() end)
            if success then
                lastShoot = tick()
            end
        end)
        addConn(shootConn)
    else
        if shootConn then shootConn:Disconnect() shootConn = nil end
    end
end

-- ==================== FPS/PING COUNTER ====================
local frameCount = 0
local lastFPSUpdate = tick()
task.spawn(function()
    while ScreenGui.Parent do
        frameCount = frameCount + 1
        local now = tick()
        if now - lastFPSUpdate >= 1 then
            local fps = math.floor(frameCount / (now - lastFPSUpdate))
            local ping = 0
            pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
            if ActiveLbl then
                local count = 0
                for _, v in pairs(Toggles) do if v then count = count + 1 end end
                if count > 0 then
                    ActiveLbl.Text = "⚡" .. count .. " · FPS:" .. fps
                else
                    ActiveLbl.Text = "FPS:" .. fps .. " · " .. ping .. "ms"
                end
            end
            frameCount = 0
            lastFPSUpdate = now
        end
        task.wait()
    end
end)

-- ==================== MOVEMENT TAB ====================
local MoveTab = createTab("Move", "🚀")
makeSection(MoveTab, "Speed & Jump", 4)

local SpeedBox = makeInput(MoveTab, 28, "16", 0, 0.5, tostring(Settings.Speed), function(txt)
    local v = tonumber(txt)
    if v then Settings.Speed = v saveSettings() end
end)
local JumpBox = makeInput(MoveTab, 28, "50", 0.5, 0.5, tostring(Settings.Jump), function(txt)
    local v = tonumber(txt)
    if v then Settings.Jump = v saveSettings() end
end)
local ApplySpeedBtn = makeButton(MoveTab, "Apply Speed", 0, 62, 0.5, 26)
local ApplyJumpBtn = makeButton(MoveTab, "Apply Jump", 0.5, 62, 0.5, 26)

makeSection(MoveTab, "Movement Cheats", 96)
makeToggle(MoveTab, "Infinite Jump", 0, 120, 0.5, false, toggleInfiniteJump)
makeToggle(MoveTab, "Noclip", 0.5, 120, 0.5, false, toggleNoclip)
makeToggle(MoveTab, "Invisible + Tools", 0, 158, 1, false, toggleInvisible)

makeSection(MoveTab, "Flight", 200)
makeToggle(MoveTab, "Fly", 0, 224, 1, false, toggleFly)
makeSlider(MoveTab, "Fly Speed", 262, 10, 300, Settings.FlySpeed, function(v) Settings.FlySpeed = v end)

-- ==================== TP TAB ====================
local TpTab = createTab("Tp", "📍")
makeSection(TpTab, "Checkpoint System", 4)

local CpInfoLbl = Instance.new("TextLabel")
CpInfoLbl.Size = UDim2.new(1, -6, 0, 24)
CpInfoLbl.Position = UDim2.new(0, 3, 0, 28)
CpInfoLbl.BackgroundColor3 = C.Card
CpInfoLbl.BorderSizePixel = 0
CpInfoLbl.Text = "📍  0 Checkpoints gesetzt"
CpInfoLbl.TextColor3 = C.TextMid
CpInfoLbl.Font = Enum.Font.GothamMedium
CpInfoLbl.TextSize = 11
CpInfoLbl.Parent = TpTab
local CpInfoC = Instance.new("UICorner") CpInfoC.CornerRadius = UDim.new(0, 7) CpInfoC.Parent = CpInfoLbl
local CpInfoStroke = Instance.new("UIStroke") CpInfoStroke.Color = C.Line CpInfoStroke.Thickness = 1 CpInfoStroke.Transparency = 0.5 CpInfoStroke.Parent = CpInfoLbl

local SetCheckpointBtn = makeButton(TpTab, "📍  Set Checkpoint 1", 0, 58, 1, 30, C.Checkpoint)
local TpLastBtn = makeButton(TpTab, "🎯  Last CP", 0, 94, 0.6, 28, C.Accent)
local ClearAllBtn = makeButton(TpTab, "🗑️  Clear", 0.6, 94, 0.4, 28, C.Red)

local CpListHeader = Instance.new("TextLabel")
CpListHeader.Size = UDim2.new(1, -6, 0, 22)
CpListHeader.Position = UDim2.new(0, 3, 0, 130)
CpListHeader.BackgroundColor3 = C.Card2
CpListHeader.BorderSizePixel = 0
CpListHeader.Text = "  🎯  TELEPORT TO"
CpListHeader.TextColor3 = C.Accent
CpListHeader.Font = Enum.Font.GothamBold
CpListHeader.TextSize = 9
CpListHeader.TextXAlignment = Enum.TextXAlignment.Left
CpListHeader.Parent = TpTab
local CpListHeaderC = Instance.new("UICorner") CpListHeaderC.CornerRadius = UDim.new(0, 6) CpListHeaderC.Parent = CpListHeader

local CpListContainer = Instance.new("Frame")
CpListContainer.Size = UDim2.new(1, -6, 0, 48)
CpListContainer.Position = UDim2.new(0, 3, 0, 156)
CpListContainer.BackgroundColor3 = C.Card
CpListContainer.BorderSizePixel = 0
CpListContainer.Parent = TpTab
local CpListContainerC = Instance.new("UICorner") CpListContainerC.CornerRadius = UDim.new(0, 8) CpListContainerC.Parent = CpListContainer
local CpListStroke = Instance.new("UIStroke") CpListStroke.Color = C.Line CpListStroke.Thickness = 1 CpListStroke.Transparency = 0.5 CpListStroke.Parent = CpListContainer

local CpListLayout = Instance.new("UIListLayout")
CpListLayout.SortOrder = Enum.SortOrder.LayoutOrder
CpListLayout.Padding = UDim.new(0, 4)
CpListLayout.Parent = CpListContainer

local CpListPad = Instance.new("UIPadding")
CpListPad.PaddingLeft = UDim.new(0, 5)
CpListPad.PaddingRight = UDim.new(0, 5)
CpListPad.PaddingTop = UDim.new(0, 5)
CpListPad.PaddingBottom = UDim.new(0, 5)
CpListPad.Parent = CpListContainer

local CpEmptyLbl = Instance.new("TextLabel")
CpEmptyLbl.Size = UDim2.new(1, -10, 0, 40)
CpEmptyLbl.Position = UDim2.new(0, 5, 0, 5)
CpEmptyLbl.BackgroundTransparency = 1
CpEmptyLbl.Text = "Keine Checkpoints gesetzt"
CpEmptyLbl.TextColor3 = C.TextDim
CpEmptyLbl.Font = Enum.Font.GothamMedium
CpEmptyLbl.TextSize = 10
CpEmptyLbl.Parent = CpListContainer

local function refreshCheckpointList()
    for _, child in pairs(CpListContainer:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then
            if child.Name:find("CpItem") then child:Destroy() end
        end
    end
    CpEmptyLbl.Visible = (#Checkpoints == 0)
    CpInfoLbl.Text = "📍  " .. #Checkpoints .. " Checkpoints gesetzt"
    SetCheckpointBtn.Text = "📍  Set Checkpoint " .. nextCheckpointNumber

    for i, cp in ipairs(Checkpoints) do
        local item = Instance.new("Frame")
        item.Name = "CpItem_" .. i
        item.Size = UDim2.new(1, 0, 0, 30)
        item.BackgroundColor3 = C.Card2
        item.BorderSizePixel = 0
        item.Parent = CpListContainer
        local itemC = Instance.new("UICorner") itemC.CornerRadius = UDim.new(0, 6) itemC.Parent = item

        local tpBtn = Instance.new("TextButton")
        tpBtn.Name = "CpItemTp_" .. i
        tpBtn.Size = UDim2.new(1, -34, 1, 0)
        tpBtn.Position = UDim2.new(0, 0, 0, 0)
        tpBtn.BackgroundColor3 = C.Checkpoint
        tpBtn.Text = "🎯  CP " .. cp.Number
        tpBtn.TextColor3 = C.Text
        tpBtn.Font = Enum.Font.GothamBold
        tpBtn.TextSize = 11
        tpBtn.BorderSizePixel = 0
        tpBtn.AutoButtonColor = false
        tpBtn.Parent = item
        local tpBtnC = Instance.new("UICorner") tpBtnC.CornerRadius = UDim.new(0, 6) tpBtnC.Parent = tpBtn

        tpBtn.MouseEnter:Connect(function()
            TweenService:Create(tpBtn, Tween1, {BackgroundColor3 = C.Checkpoint:Lerp(Color3.new(1,1,1), 0.2)}):Play()
        end)
        tpBtn.MouseLeave:Connect(function()
            TweenService:Create(tpBtn, Tween1, {BackgroundColor3 = C.Checkpoint}):Play()
        end)
        tpBtn.MouseButton1Click:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            hrp.CFrame = CFrame.new(cp.Position + Vector3.new(0, 3, 0))
            setStatus("Teleported to CP " .. cp.Number, true)
        end)

        local delBtn = Instance.new("TextButton")
        delBtn.Name = "CpItemDel_" .. i
        delBtn.Size = UDim2.new(0, 30, 1, 0)
        delBtn.Position = UDim2.new(1, -32, 0, 0)
        delBtn.BackgroundColor3 = C.Red
        delBtn.Text = "✕"
        delBtn.TextColor3 = C.Text
        delBtn.Font = Enum.Font.GothamBold
        delBtn.TextSize = 12
        delBtn.BorderSizePixel = 0
        delBtn.AutoButtonColor = false
        delBtn.Parent = item
        local delBtnC = Instance.new("UICorner") delBtnC.CornerRadius = UDim.new(0, 6) delBtnC.Parent = delBtn

        delBtn.MouseButton1Click:Connect(function()
            pcall(function() cp.Marker:Destroy() end)
            table.remove(Checkpoints, i)
            refreshCheckpointList()
            setStatus("CP " .. cp.Number .. " deleted", true)
        end)
    end

    local totalHeight = (#Checkpoints * 34) + 10
    if #Checkpoints == 0 then totalHeight = 50 end
    CpListContainer.Size = UDim2.new(1, -6, 0, totalHeight)
end

local function setCheckpoint()
    local char = LocalPlayer.Character
    if not char then setStatus("No character", false) return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then setStatus("No HRP", false) return end
    local position = hrp.Position
    local marker = createCheckpointMarker(position, nextCheckpointNumber)
    table.insert(Checkpoints, {Position = position, Marker = marker, Number = nextCheckpointNumber})
    setStatus("CP " .. nextCheckpointNumber .. " created", true)
    nextCheckpointNumber = nextCheckpointNumber + 1
    refreshCheckpointList()
end

local function tpToLastCheckpoint()
    if #Checkpoints == 0 then setStatus("No checkpoints", false) return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local lastCP = Checkpoints[#Checkpoints]
    hrp.CFrame = CFrame.new(lastCP.Position + Vector3.new(0, 3, 0))
    setStatus("Teleported to CP " .. lastCP.Number, true)
end

SetCheckpointBtn.MouseButton1Click:Connect(setCheckpoint)
TpLastBtn.MouseButton1Click:Connect(tpToLastCheckpoint)

ClearAllBtn.MouseButton1Click:Connect(function()
    for _, cp in pairs(Checkpoints) do pcall(function() cp.Marker:Destroy() end) end
    Checkpoints = {}
    nextCheckpointNumber = 1
    refreshCheckpointList()
    setStatus("All CPs cleared", true)
end)

refreshCheckpointList()

-- ==================== AIM TAB ====================
local AimTab = createTab("Aim", "🎯")
makeSection(AimTab, "Aimbot", 4)
makeToggle(AimTab, "Aimbot", 0, 28, 0.5, false, toggleAimbot)
makeToggle(AimTab, "Wall Check", 0.5, 28, 0.5, false, function(on) Toggles.WallCheck = on end)

makeSection(AimTab, "Target Part", 66)
local TargetRow = Instance.new("Frame")
TargetRow.Size = UDim2.new(1, -6, 0, 26)
TargetRow.Position = UDim2.new(0, 3, 0, 90)
TargetRow.BackgroundTransparency = 1
TargetRow.Parent = AimTab

local TargetBtns = {}
for i, part in ipairs({"Head", "Torso", "Random"}) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.33, -2, 1, 0)
    b.Position = UDim2.new((i-1) * 0.33, (i-1), 0, 0)
    local sel = Settings.AimbotPart == part or (part == "Torso" and Settings.AimbotPart == "UpperTorso")
    b.BackgroundColor3 = sel and C.Accent or C.Card
    b.Text = part
    b.TextColor3 = sel and C.Text or C.TextDim
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Parent = TargetRow
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = b
    TargetBtns[part] = b
    b.MouseButton1Click:Connect(function()
        for p, btn in pairs(TargetBtns) do
            local s = p == part
            btn.BackgroundColor3 = s and C.Accent or C.Card
            btn.TextColor3 = s and C.Text or C.TextDim
        end
        Settings.AimbotPart = (part == "Torso") and "UpperTorso" or part
        saveSettings()
    end)
end

makeSection(AimTab, "Aim Mode", 122)
local ModeRow = Instance.new("Frame")
ModeRow.Size = UDim2.new(1, -6, 0, 26)
ModeRow.Position = UDim2.new(0, 3, 0, 146)
ModeRow.BackgroundTransparency = 1
ModeRow.Parent = AimTab

local ModeBtns = {}
for i, mode in ipairs({"Camera", "Mouse", "Silent"}) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.33, -2, 1, 0)
    b.Position = UDim2.new((i-1) * 0.33, (i-1), 0, 0)
    local sel = Settings.AimbotMode == mode
    b.BackgroundColor3 = sel and C.Accent or C.Card
    b.Text = mode
    b.TextColor3 = sel and C.Text or C.TextDim
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Parent = ModeRow
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = b
    ModeBtns[mode] = b
    b.MouseButton1Click:Connect(function()
        for m, btn in pairs(ModeBtns) do
            local s = m == mode
            btn.BackgroundColor3 = s and C.Accent or C.Card
            btn.TextColor3 = s and C.Text or C.TextDim
        end
        Settings.AimbotMode = mode
        saveSettings()
    end)
end

makeSlider(AimTab, "FOV", 178, 10, 800, Settings.AimbotFOV, function(v) Settings.AimbotFOV = v end)
makeSlider(AimTab, "Smooth", 224, 1, 100, Settings.AimbotSmooth, function(v) Settings.AimbotSmooth = v end)

makeSection(AimTab, "Hitbox Expander", 270)
makeToggle(AimTab, "Hitbox", 0, 294, 1, false, toggleHitbox)
makeSlider(AimTab, "Size", 332, 1, 100, Settings.HitboxSize, function(v) Settings.HitboxSize = v end)

makeSection(AimTab, "Triggerbot", 378)
makeToggle(AimTab, "Triggerbot", 0, 402, 0.5, false, toggleTriggerbot)
makeToggle(AimTab, "Auto Shoot", 0.5, 402, 0.5, false, toggleAutoShoot)
makeSlider(AimTab, "Trigger Delay", 440, 1, 100, Settings.TriggerDelay, function(v) Settings.TriggerDelay = v end)
makeSlider(AimTab, "Shoot Delay", 486, 1, 100, Settings.AutoShootDelay, function(v) Settings.AutoShootDelay = v end)

-- ==================== VISUALS TAB ====================
local VisTab = createTab("Visuals", "👁")
makeSection(VisTab, "Player ESP", 4)
makeToggle(VisTab, "ESP", 0, 28, 0.5, false, toggleESP)
makeToggle(VisTab, "Team ESP", 0.5, 28, 0.5, false, toggleTeamESP)

makeSection(VisTab, "Settings", 66)
makeSlider(VisTab, "Transparency", 90, 0, 100, Settings.ESPTransparency, function(v)
    Settings.ESPTransparency = v
    for _, obj in pairs(ESPObjects) do
        if obj.Highlight then obj.Highlight.FillTransparency = v / 100 end
    end
end)

makeSection(VisTab, "World", 132)
makeToggle(VisTab, "Fullbright (Night Vision)", 0, 156, 1, false, toggleFullbright)

-- ==================== UTILITY TAB ====================
local UtilTab = createTab("Util", "🛠️")
makeSection(UtilTab, "Anti-Kick", 4)
makeToggle(UtilTab, "Anti-AFK", 0, 28, 0.5, false, toggleAntiAFK)
makeToggle(UtilTab, "Auto Respawn", 0.5, 28, 0.5, false, toggleAutoRespawn)

makeSection(UtilTab, "Character", 66)
local ResetCharBtn = makeButton(UtilTab, "🔄  Respawn Character", 0, 90, 1, 28)
local KillCharBtn = makeButton(UtilTab, "☠️  Kill Character", 0, 122, 1, 28, C.Red)

makeSection(UtilTab, "Server", 158)
local ServerHopBtn = makeButton(UtilTab, "🚀  Server Hop", 0, 182, 1, 28, C.Accent)

-- ==================== MISC TAB ====================
local MiscTab = createTab("Misc", "⚙")
makeSection(MiscTab, "Settings", 4)
local SaveBtn = makeButton(MiscTab, "💾  Save", 0, 28, 0.5, 28)
local LoadBtn = makeButton(MiscTab, "📂  Load", 0.5, 28, 0.5, 28)

makeSection(MiscTab, "Executor Info", 64)
local ExecInfo = Instance.new("TextLabel")
ExecInfo.Size = UDim2.new(1, -6, 0, 50)
ExecInfo.Position = UDim2.new(0, 3, 0, 88)
ExecInfo.BackgroundColor3 = C.Card
ExecInfo.BorderSizePixel = 0
ExecInfo.Text = "Executor: " .. (identifyexecutor and identifyexecutor() or "Unknown") .. "\nXeno: " .. (isXeno and "✓" or "✗") .. "  |  Delta: " .. (isDelta and "✓" or "✗") .. "\nGame ID: " .. game.PlaceId
ExecInfo.TextColor3 = C.TextMid
ExecInfo.Font = Enum.Font.GothamMedium
ExecInfo.TextSize = 10
ExecInfo.TextWrapped = true
ExecInfo.TextYAlignment = Enum.TextYAlignment.Center
ExecInfo.Parent = MiscTab
local ExecC = Instance.new("UICorner") ExecC.CornerRadius = UDim.new(0, 8) ExecC.Parent = ExecInfo
local ExecStroke = Instance.new("UIStroke") ExecStroke.Color = C.Line ExecStroke.Thickness = 1 ExecStroke.Transparency = 0.5 ExecStroke.Parent = ExecInfo

makeSection(MiscTab, "Danger Zone", 148)
local ResetBtn = makeButton(MiscTab, "🔄  Reset All Features", 0, 172, 1, 28, C.Red)

for _, tabData in pairs(TabButtons) do
    tabData.btn.MouseButton1Click:Connect(function()
        switchTab(tabData.name)
    end)
end

switchTab(Settings.CurrentTab or "Move")

-- ==================== BUTTON EVENTS ====================
ApplySpeedBtn.MouseButton1Click:Connect(function()
    local v = tonumber(SpeedBox.Text)
    if v and v >= 1 and v <= 100000 then
        applySpeed(v)
        setStatus("Speed: " .. v, true)
    else
        setStatus("Invalid", false)
    end
end)

ApplyJumpBtn.MouseButton1Click:Connect(function()
    local v = tonumber(JumpBox.Text)
    if v and v >= 1 and v <= 100000 then
        applyJump(v)
        setStatus("Jump: " .. v, true)
    else
        setStatus("Invalid", false)
    end
end)

ResetCharBtn.MouseButton1Click:Connect(function()
    pcall(function() LocalPlayer:LoadCharacter() end)
    setStatus("Character respawned ✓", true)
end)

KillCharBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then h.Health = 0 end
    end
    setStatus("Character killed", true)
end)

ServerHopBtn.MouseButton1Click:Connect(function()
    setStatus("Hopping servers...", true)
    task.spawn(function()
        local success, err = pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            local raw = game:HttpGet(url)
            local data = HttpService:JSONDecode(raw)
            local currentId = game.JobId

            if not data or not data.data then
                setStatus("No data from API", false)
                return
            end

            local servers = data.data
            for i = #servers, 2, -1 do
                local j = math.random(i)
                servers[i], servers[j] = servers[j], servers[i]
            end

            for _, server in ipairs(servers) do
                if server.playing and server.maxPlayers and server.id then
                    if server.playing < server.maxPlayers and server.id ~= currentId then
                        setStatus("Joining server...", true)
                        task.wait(0.3)
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                        return
                    end
                end
            end

            setStatus("No available servers", false)
        end)

        if not success then
            setStatus("Server hop failed", false)
        end
    end)
end)

SaveBtn.MouseButton1Click:Connect(function()
    saveSettings()
    setStatus("Settings saved ✓", true)
end)

LoadBtn.MouseButton1Click:Connect(function()
    loadSettings()
    SpeedBox.Text = tostring(Settings.Speed)
    JumpBox.Text = tostring(Settings.Jump)
    setStatus("Settings loaded ✓", true)
end)

ResetBtn.MouseButton1Click:Connect(function()
    toggleInfiniteJump(false)
    toggleNoclip(false)
    toggleInvisible(false)
    toggleESP(false)
    toggleTeamESP(false)
    toggleAimbot(false)
    toggleHitbox(false)
    toggleTriggerbot(false)
    toggleAutoShoot(false)
    toggleFly(false)
    toggleFullbright(false)
    toggleAntiAFK(false)
    toggleAutoRespawn(false)

    if speedConn then speedConn:Disconnect() speedConn = nil end
    if jumpConn then jumpConn:Disconnect() jumpConn = nil end

    Settings.Speed = 16
    Settings.Jump = 50
    local char = LocalPlayer.Character
    if char then
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = 16 h.UseJumpPower = true h.JumpPower = 50 end
    end
    clearAllESP()
    SpeedBox.Text = "16" JumpBox.Text = "50"
    setStatus("Reset complete ✓", true)
    saveSettings()
end)

SpeedBox.FocusLost:Connect(function(e) if e then ApplySpeedBtn:Fire("MouseButton1Click") end end)
JumpBox.FocusLost:Connect(function(e) if e then ApplyJumpBtn:Fire("MouseButton1Click") end end)

-- ==================== PLAYER EVENTS ====================
addConn(Players.PlayerAdded:Connect(function(p)
    if Toggles.ESP or Toggles.TeamESP then
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if Toggles.ESP or Toggles.TeamESP then createESP(p) end
        end)
    end
end))

addConn(Players.PlayerRemoving:Connect(function(p) removeESP(p) end))

addConn(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)

    if Settings.Speed ~= 16 then applySpeed(Settings.Speed) end
    if Settings.Jump ~= 50 then applyJump(Settings.Jump) end

    if Toggles.Fly then
        task.wait(0.5)
        toggleFly(true)
    end

    if Toggles.Invisible then
        savedTransparency = {}
        task.wait(0.5)
        applyInvisible()
    end

    if Toggles.AutoShoot then
        task.wait(0.3)
        toggleAutoShoot(true)
    end

    if Toggles.Noclip then
        task.wait(0.3)
        toggleNoclip(true)
    end

    if Toggles.InfiniteJump then
        task.wait(0.3)
        toggleInfiniteJump(true)
    end
end))

_G.WinterCleanup = function()
    saveSettings()
    for _, c in pairs(Connections) do pcall(function() c:Disconnect() end) end
    clearAllESP()
    for _, cp in pairs(Checkpoints) do
        pcall(function() cp.Marker:Destroy() end)
    end
    if checkpointFolder then
        pcall(function() checkpointFolder:Destroy() end)
    end
    Connections = {}
end

print("❄️ Winter Hub v34 - No Start Sound Edition geladen!")
print("🔇 Start-Sound entfernt ✓")
print("🔊 Klick-Sound bleibt ✓")
print("🎬 Welcome Screen funktioniert ✓")
print("🎯 Auto Shoot schießt bis tot ✓")
print("✈️ Fly Steuerung korrekt ✓")
