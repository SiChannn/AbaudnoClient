-- ====================================================================
-- RdHelper (Ultimate Suite) — INTEGRATED COMBAT & MOVEMENT FRAMEWORK
-- ====================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

-- [0. ОКРУЖЕНИЕ И ЗАЩИТА (SOLARA BYPASS & ISOLATION)]
pcall(function()
    if _G then _G.RdHelper = nil; _G.RdHelperActive = nil end
    if shared then shared.RdHelper = nil; shared.RdHelperActive = nil end

    if hookmetamethod and checkcaller and newcclosure then
        local gameMeta = getrawmetatable(game)
        if setreadonly then setreadonly(gameMeta, false) end
        
        local oldIndex; oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
            if not checkcaller() then
                local kStr = tostring(key):lower()
                if kStr:find("helper") or kStr:find("roblox_") or kStr:find("terrainchunk_") then
                    return nil
                end
            end
            return oldIndex(self, key)
        end))

        if setreadonly then setreadonly(gameMeta, true) end
    end
end)

-- [1. СЕРВИСЫ ROBLOX]
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

-- [2. МЕНЕДЖЕР НАСТРОЕК И ПЕРЕМЕННЫЕ]
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do task.wait(0.1) LocalPlayer = Players.LocalPlayer end
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")

local RandomGuiName = "Roblox_" .. string.gsub(HttpService:GenerateGUID(false), "-", ""):sub(1, 10)
local RandomFolderName = "TerrainChunk_" .. string.gsub(HttpService:GenerateGUID(false), "-", ""):sub(1, 6)

local SafeParent = nil
if gethui then SafeParent = gethui() else SafeParent = CoreGui or LocalPlayer:WaitForChild("PlayerGui", 5) end

local Settings = {
    GUIBind = Enum.KeyCode.RightControl,
    
    -- Combat
    SilentAimActive = false, SilentAimBind = Enum.KeyCode.Unknown, AimMode = "Hold", AimType = "Bypass", AimFov = 140, TargetIndicator = true, TargetLock = true, WallCheck = true, HitPart = "Head",
    FollowActive = false, FollowBind = Enum.KeyCode.Unknown, FollowMode = "Run", FollowDistance = 5, FollowSpeed = 20,
    
    -- Movement
    SpeedActive = false, SpeedBind = Enum.KeyCode.Unknown, BoostSpeed = 50,
    JumpActive = false, JumpBind = Enum.KeyCode.Unknown, BoostJump = 100,
    BhopActive = false, BhopBind = Enum.KeyCode.Unknown, BhopSpeed = 35,
    FlightActive = false, FlightBind = Enum.KeyCode.Unknown, FlightSpeed = 50,
    VflyActive = false, VflyBind = Enum.KeyCode.Unknown, VflySpeed = 60,
    BlinkBind = Enum.KeyCode.Unknown, BlinkDistance = 25, BlinkMode = "Normal",
    AirJumpActive = false, AirJumpBind = Enum.KeyCode.Unknown, AirJumpPower = 50, AirJumpMode = "Default",
    SpiderActive = false, SpiderBind = Enum.KeyCode.Unknown, SpiderSpeed = 25,
    AntiVoid = false, AntiVoidHeight = -200,
    
    -- Visuals
    EspActive = false, EspBind = Enum.KeyCode.Unknown, EspFillTransparency = 0.65, EspBoxes = false, EspTracers = false, EspNames = false,
    ShadersActive = false, ShadersBind = Enum.KeyCode.Unknown,
    FullbrightActive = false, FullbrightBind = Enum.KeyCode.Unknown, FullbrightPower = 5,
    NoFog = false, XrayActive = false, FovCircleVisible = true,
    
    -- Misc
    NoPlayerCollision = false, NoclipActive = false, NoclipBind = Enum.KeyCode.Unknown,
    ClickTpActive = false, ClickTpBind = Enum.KeyCode.Unknown, ClickTpKey = Enum.KeyCode.LeftControl, ClickTpMode = "Click Required",
    FastTpBind = Enum.KeyCode.Unknown,
    TpManagerActive = false, TpManagerBind = Enum.KeyCode.Unknown, TpManagerInterval = 3,
    ChatSpam = false,
    SpinnerActive = false, SpinnerBind = Enum.KeyCode.Unknown, SpinnerSpeed = 30, SpinnerMoveSync = true
}

local FrameKeys = {
    SilentAimActive = "SilentAim", FollowActive = "Follow", SpeedActive = "SpeedBoost",
    JumpActive = "JumpBoost", BhopActive = "Bhop", FlightActive = "Flight", VflyActive = "Vfly",
    AirJumpActive = "AirJump", SpiderActive = "Spider", EspActive = "Esp", FullbrightActive = "Fullbright",
    NoPlayerCollision = "NoPlayerCollision", NoclipActive = "Noclip", ClickTpActive = "ClickTP", TpManagerActive = "TpManager",
    ShadersActive = "ShadersModule", SpinnerActive = "SpinnerFrame"
}

local Theme = {
    Background = Color3.fromRGB(18, 18, 22), Sidebar = Color3.fromRGB(12, 12, 16), TitleBar = Color3.fromRGB(25, 25, 35), ModuleBg = Color3.fromRGB(22, 22, 28), ModuleActiveBg = Color3.fromRGB(29, 25, 38), 
    ElementBg = Color3.fromRGB(38, 38, 48), Accent = Color3.fromRGB(160, 32, 240), AccentSecondary = Color3.fromRGB(255, 20, 147), Text = Color3.fromRGB(240, 240, 240), AimCircleColor = Color3.fromRGB(160, 32, 240)
}

local OrigLighting = { Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, GlobalShadows = Lighting.GlobalShadows, FogEnd = Lighting.FogEnd }
local OriginalGravity = Workspace.Gravity
local CustomVisuals = { SunRays = nil, ColorCorr = nil }
local FastTpPos, FastTpVisual = nil, nil
local TpPoints, TpVisuals = {}, {}
local CurrentTpIndex = 1
local LastTpTime = 0
local LockedTarget = nil
local ClickDebounce = false
local MaxVisualDistance = 2000
local SpinnerAngle = 0

local DrawingFovCircle = nil
if Drawing then
    pcall(function()
        DrawingFovCircle = Drawing.new("Circle")
        DrawingFovCircle.Thickness = 1.5
        DrawingFovCircle.NumSides = 64
        DrawingFovCircle.Radius = Settings.AimFov
        DrawingFovCircle.Filled = false
        DrawingFovCircle.Visible = false
        DrawingFovCircle.Color = Theme.AimCircleColor
    end)
end

local function GetScreenCenter() return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2) end

local function GetVehiclePart()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart then return hum.SeatPart end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        local parts = Workspace:GetPartBoundsInRadius(root.Position, 6)
        for i = 1, #parts do
            local part = parts[i]
            if part.Name:lower():find("seat") or part:IsA("VehicleSeat") or part:IsA("Seat") then return part end
        end
    end
    return nil
end

local function IsVisibleBehindWalls(targetPart)
    if not Settings.WallCheck then return true end
    local char = LocalPlayer.Character
    if not char then return false end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {char, targetPart.Parent}
    raycastParams.IgnoreWater = true
    local result = Workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position, raycastParams)
    return result == nil
end

local function IsValid(player)
    return player and player ~= LocalPlayer and player.Character and 
           player.Character:FindFirstChild("Head") and 
           player.Character:FindFirstChild("HumanoidRootPart") and
           player.Character:FindFirstChildOfClass("Humanoid") and 
           player.Character.Humanoid.Health > 0
end

local function GetClosestPlayerInFov()
    local closestPlayer = nil; local shortestDistance = math.huge; local center = GetScreenCenter()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local playersList = Players:GetPlayers()
    for i = 1, #playersList do
        local player = playersList[i]
        if IsValid(player) then
            local targetPart = player.Character:FindFirstChild(Settings.HitPart) or player.Character.Head
            local targetRoot = player.Character.HumanoidRootPart
            local distanceToPlayer = (root.Position - targetRoot.Position).Magnitude
            
            if distanceToPlayer <= MaxVisualDistance then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local distFromMouse = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if distFromMouse <= Settings.AimFov and distFromMouse < shortestDistance then
                        if not Settings.WallCheck or IsVisibleBehindWalls(targetPart) then
                            closestPlayer = player; shortestDistance = distFromMouse
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function GetClosestPlayerForFollow()
    local closestPlayer = nil; local shortestDistance = math.huge
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local playersList = Players:GetPlayers()
    for i = 1, #playersList do
        local player = playersList[i]
        if IsValid(player) then
            local targetRoot = player.Character.HumanoidRootPart
            local dist = (root.Position - targetRoot.Position).Magnitude
            if dist <= MaxVisualDistance and dist < shortestDistance then closestPlayer = player; shortestDistance = dist end
        end
    end
    return closestPlayer
end

-- [3. СОЗДАНИЕ ИНТЕРФЕЙСА]
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = RandomGuiName; ScreenGui.ResetOnSpawn = false; ScreenGui.Parent = SafeParent
local VisualFolder = Instance.new("Folder"); VisualFolder.Name = RandomFolderName; VisualFolder.Parent = Workspace

local FovCircleFrame = Instance.new("Frame", ScreenGui); FovCircleFrame.AnchorPoint = Vector2.new(0.5, 0.5); FovCircleFrame.BackgroundTransparency = 1; FovCircleFrame.Visible = false
local FovStroke = Instance.new("UIStroke", FovCircleFrame); FovStroke.Color = Theme.AimCircleColor; FovStroke.Thickness = 1.2
Instance.new("UICorner", FovCircleFrame).CornerRadius = UDim.new(1, 0)

local function UpdateFovCircle()
    local center = GetScreenCenter()
    if DrawingFovCircle then
        if Settings.SilentAimActive and Settings.AimFov > 0 and Settings.FovCircleVisible then
            DrawingFovCircle.Position = center
            DrawingFovCircle.Radius = Settings.AimFov
            DrawingFovCircle.Visible = true
        else
            DrawingFovCircle.Visible = false
        end
        FovCircleFrame.Visible = false
    else
        if Settings.SilentAimActive and Settings.AimFov > 0 and Settings.FovCircleVisible then
            FovCircleFrame.Position = UDim2.new(0, center.X, 0, center.Y); FovCircleFrame.Size = UDim2.new(0, Settings.AimFov * 2, 0, Settings.AimFov * 2); FovCircleFrame.Visible = true
        else
            FovCircleFrame.Visible = false
        end
    end
end

local AimTargetGui = Instance.new("BillboardGui", ScreenGui); AimTargetGui.Size = UDim2.new(0, 6, 0, 6); AimTargetGui.AlwaysOnTop = true; AimTargetGui.Enabled = false
local AimCircleFrame = Instance.new("Frame", AimTargetGui); AimCircleFrame.Size = UDim2.new(1, 0, 1, 0); AimCircleFrame.BackgroundColor3 = Theme.Accent
Instance.new("UICorner", AimCircleFrame).CornerRadius = UDim.new(1, 0)

local MainFrame = Instance.new("Frame", ScreenGui); MainFrame.Position = UDim2.new(0.5, -225, 0.5, -175); MainFrame.Size = UDim2.new(0, 470, 0, 360); MainFrame.BackgroundColor3 = Theme.Background
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 6)
local MainStroke = Instance.new("UIStroke", MainFrame); MainStroke.Color = Theme.Accent; MainStroke.Thickness = 1.5

local TitleBar = Instance.new("Frame", MainFrame); TitleBar.Size = UDim2.new(1, 0, 0, 35); TitleBar.BackgroundColor3 = Theme.TitleBar
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 6)
local Title = Instance.new("TextLabel", TitleBar); Title.Size = UDim2.new(1, -20, 1, 0); Title.Position = UDim2.new(0, 15, 0, 0); Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBold; Title.Text = "RdHelper v11.1"; Title.TextSize = 13; Title.TextColor3 = Theme.Accent; Title.TextXAlignment = Enum.TextXAlignment.Left

local dragToggle, dragStart, startPos
TitleBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragToggle = true; dragStart = input.Position; startPos = MainFrame.Position end end)
UserInputService.InputChanged:Connect(function(input) if dragToggle and input.UserInputType == Enum.UserInputType.MouseMovement then local delta = input.Position - dragStart; MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragToggle = false end end)

local Sidebar = Instance.new("Frame", MainFrame); Sidebar.Position = UDim2.new(0, 0, 0, 35); Sidebar.Size = UDim2.new(0, 120, 1, -35); Sidebar.BackgroundColor3 = Theme.Sidebar
local function CreateTab(text, y)
    local b = Instance.new("TextButton", Sidebar); b.Position = UDim2.new(0, 5, 0, y); b.Size = UDim2.new(1, -10, 0, 28); b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.Text = text; b.BackgroundColor3 = Theme.Sidebar; b.TextColor3 = Theme.Text; b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    return b
end

local TabCombat = CreateTab("Combat", 10); local TabMovement = CreateTab("Movement", 44); local TabVisuals = CreateTab("Visuals", 78); local TabMisc = CreateTab("Misc", 112); local TabSettings = CreateTab("Settings", 146)

local function CreateScroll()
    local s = Instance.new("ScrollingFrame", MainFrame); s.Position = UDim2.new(0, 130, 0, 45); s.Size = UDim2.new(1, -140, 1, -55); s.BackgroundTransparency = 1; s.BorderSizePixel = 0; s.ScrollBarThickness = 4; s.ScrollBarImageColor3 = Theme.Accent; s.Visible = false
    local l = Instance.new("UIListLayout", s); l.SortOrder = Enum.SortOrder.LayoutOrder; l.Padding = UDim.new(0, 6)
    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() s.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 15) end)
    return s
end

local ScrollCombat = CreateScroll(); ScrollCombat.Visible = true
local ScrollMovement = CreateScroll(); local ScrollVisuals = CreateScroll(); local ScrollMisc = CreateScroll(); local ScrollSettings = CreateScroll()

local function switch(activeBtn)
    local btns = {TabCombat, TabMovement, TabVisuals, TabMisc, TabSettings}; local scrals = {ScrollCombat, ScrollMovement, ScrollVisuals, ScrollMisc, ScrollSettings}
    for i, v in ipairs(btns) do
        local act = (v == activeBtn); v.BackgroundColor3 = act and Theme.TitleBar or Theme.Sidebar; v.TextColor3 = act and Theme.Accent or Theme.Text; scrals[i].Visible = act
    end
end
TabCombat.MouseButton1Click:Connect(function() switch(TabCombat) end); TabMovement.MouseButton1Click:Connect(function() switch(TabMovement) end); TabVisuals.MouseButton1Click:Connect(function() switch(TabVisuals) end); TabMisc.MouseButton1Click:Connect(function() switch(TabMisc) end); TabSettings.MouseButton1Click:Connect(function() switch(TabSettings) end)

local isBindingProcess = false; local ModuleFrames = {}

local function SetModuleGlow(key, active)
    if not key then return end
    local frameName = FrameKeys[key] or key; local m = ModuleFrames[frameName]
    if not m then return end
    local g = m:FindFirstChild("GlowIndicator")
    if g then g.BackgroundTransparency = active and 0 or 1 end
    m.BackgroundColor3 = active and Theme.ModuleActiveBg or Theme.ModuleBg
    UpdateFovCircle()
end

local function AddModule(key, name, parent, onClick, hValue)
    local m = Instance.new("Frame", parent); m.Size = UDim2.new(1, 0, 0, 32); m.BackgroundColor3 = Theme.ModuleBg; m.ClipsDescendants = true; m.Name = key
    Instance.new("UICorner", m).CornerRadius = UDim.new(0, 4)
    local glow = Instance.new("Frame", m); glow.Name = "GlowIndicator"; glow.Size = UDim2.new(0, 4, 1, 0); glow.BackgroundTransparency = 1; glow.BackgroundColor3 = Theme.Accent
    local trigger = Instance.new("TextButton", m); trigger.Size = UDim2.new(1, -80, 0, 32); trigger.BackgroundTransparency = 1; trigger.Font = Enum.Font.GothamBold; trigger.Text = "  " .. name; trigger.TextColor3 = Theme.Text; trigger.TextSize = 12; trigger.TextXAlignment = Enum.TextXAlignment.Left
    local bBtn = Instance.new("TextButton", m); bBtn.Name = "BindButton"; bBtn.Position = UDim2.new(1, -72, 0, 5); bBtn.Size = UDim2.new(0, 65, 0, 22); bBtn.BackgroundColor3 = Theme.ElementBg; bBtn.Font = Enum.Font.GothamBold; bBtn.Text = "Bind"; bBtn.TextColor3 = Theme.Accent; bBtn.TextSize = 11; Instance.new("UICorner", bBtn).CornerRadius = UDim.new(0, 4)

    trigger.MouseEnter:Connect(function() if m.BackgroundColor3 ~= Theme.ModuleActiveBg then TweenService:Create(m, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(26, 26, 34)}):Play() end end)
    trigger.MouseLeave:Connect(function() if m.BackgroundColor3 ~= Theme.ModuleActiveBg then TweenService:Create(m, TweenInfo.new(0.1), {BackgroundColor3 = Theme.ModuleBg}):Play() end end)

    trigger.MouseButton1Click:Connect(function() if not isBindingProcess and onClick then onClick() end end)
    trigger.MouseButton2Click:Connect(function()
        if isBindingProcess then return end
        local open = (m.Size.Y.Offset == 32)
        TweenService:Create(m, TweenInfo.new(0.15), {Size = open and UDim2.new(1, 0, 0, hValue or 140) or UDim2.new(1, 0, 0, 32)}):Play()
    end)
    ModuleFrames[key] = m
    return m, trigger, bBtn
end

local function addLabel(txt, p, y)
    local l = Instance.new("TextLabel", p); l.Position = UDim2.new(0, 12, 0, y); l.Size = UDim2.new(0, 130, 0, 18); l.BackgroundTransparency = 1; l.Font = Enum.Font.GothamBold; l.Text = txt; l.TextColor3 = Theme.Text; l.TextSize = 11; l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

-- Текстовое поле ввода вместо ползунков
local function addTextBox(p, y, def, cb)
    local box = Instance.new("TextBox", p); box.Position = UDim2.new(1, -72, 0, y); box.Size = UDim2.new(0, 65, 0, 20); box.BackgroundColor3 = Theme.ElementBg; box.Font = Enum.Font.GothamBold; box.Text = tostring(def); box.TextColor3 = Theme.AccentSecondary; box.TextSize = 11; box.ClearTextOnFocus = false
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val then cb(val) else box.Text = tostring(def) end
    end)
end

local function addToggle(p, y, def, cb)
    local b = Instance.new("TextButton", p); b.Position = UDim2.new(1, -72, 0, y); b.Size = UDim2.new(0, 65, 0, 20); b.BackgroundColor3 = Theme.ElementBg; b.Font = Enum.Font.GothamBold; b.Text = def and "ON" or "OFF"; b.TextColor3 = def and Theme.Accent or Theme.Text; b.TextSize = 11; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    b.MouseButton1Click:Connect(function() local s = (b.Text == "OFF") b.Text = s and "ON" or "OFF" b.TextColor3 = s and Theme.Accent or Theme.Text cb(s) end)
end

local function addModeBtn(p, y, currentMode, modesTable, cb)
    local b = Instance.new("TextButton", p); b.Position = UDim2.new(1, -72, 0, y); b.Size = UDim2.new(0, 65, 0, 20); b.BackgroundColor3 = Theme.ElementBg; b.Font = Enum.Font.GothamBold; b.Text = currentMode; b.TextColor3 = Theme.AccentSecondary; b.TextSize = 11; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    b.MouseButton1Click:Connect(function() local idx = table.find(modesTable, b.Text) or 1 idx = (idx % #modesTable) + 1 b.Text = modesTable[idx] cb(modesTable[idx]) end)
end

local function addButton(txt, p, y, cb)
    local b = Instance.new("TextButton", p); b.Position = UDim2.new(0, 12, 0, y); b.Size = UDim2.new(1, -24, 0, 22); b.BackgroundColor3 = Theme.ElementBg; b.Font = Enum.Font.GothamBold; b.Text = txt; b.TextColor3 = Theme.Text; b.TextSize = 11; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    b.MouseButton1Click:Connect(cb)
end

local function setupCustomKeybind(btn, settingKey)
    if not btn then return end
    btn.MouseButton1Click:Connect(function()
        if isBindingProcess then return end
        isBindingProcess = true; btn.Text = "..."
        local conn; conn = UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.Escape or input.UserInputType == Enum.UserInputType.MouseButton2 then
                conn:Disconnect(); Settings[settingKey] = Enum.KeyCode.Unknown; btn.Text = "Bind"; task.wait(0.1); isBindingProcess = false; return
            end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                conn:Disconnect(); Settings[settingKey] = input.KeyCode; btn.Text = tostring(input.KeyCode.Name); isBindingProcess = false
            end
        end)
    end)
end

-- ====================================================================
-- COMBAT TAB MODULES
-- ====================================================================
local fCombat, _, bCombat = AddModule("SilentAim", "Silent Aim", ScrollCombat, function() Settings.SilentAimActive = not Settings.SilentAimActive; LockedTarget = nil; SetModuleGlow("SilentAimActive", Settings.SilentAimActive) end, 190)
addLabel("Aim Target:", fCombat, 35); addModeBtn(fCombat, 35, Settings.AimType, {"Bypass", "Classic"}, function(m) Settings.AimType = m UpdateFovCircle() end)
addLabel("Activation:", fCombat, 60); addModeBtn(fCombat, 60, Settings.AimMode, {"Hold", "Toggle"}, function(m) Settings.AimMode = m LockedTarget = nil end)
addLabel("FOV Size:", fCombat, 85); addTextBox(fCombat, 85, Settings.AimFov, function(v) Settings.AimFov = v UpdateFovCircle() end)
addLabel("HitPart:", fCombat, 110); addModeBtn(fCombat, 110, Settings.HitPart, {"Head", "HumanoidRootPart"}, function(m) Settings.HitPart = m end)
addLabel("Lock Target:", fCombat, 135); addToggle(fCombat, 135, Settings.TargetLock, function(v) Settings.TargetLock = v end)
addLabel("Wall Check:", fCombat, 160); addToggle(fCombat, 160, Settings.WallCheck, function(v) Settings.WallCheck = v end)
setupCustomKeybind(bCombat, "SilentAimBind")

local fFollow, _, bFollow = AddModule("Follow", "Follow Player", ScrollCombat, function() Settings.FollowActive = not Settings.FollowActive; SetModuleGlow("FollowActive", Settings.FollowActive) end, 115)
addLabel("Movement:", fFollow, 35); addModeBtn(fFollow, 35, Settings.FollowMode, {"Run", "Fly"}, function(m) Settings.FollowMode = m end)
addLabel("Distance:", fFollow, 60); addTextBox(fFollow, 60, Settings.FollowDistance, function(v) Settings.FollowDistance = v end)
addLabel("Follow Speed:", fFollow, 85); addTextBox(fFollow, 85, Settings.FollowSpeed, function(v) Settings.FollowSpeed = v end)
setupCustomKeybind(bFollow, "FollowBind")

-- ====================================================================
-- MOVEMENT TAB MODULES
-- ====================================================================
local fSpeed, _, bSpeed = AddModule("SpeedBoost", "Walk Speed Boost", ScrollMovement, function() Settings.SpeedActive = not Settings.SpeedActive; SetModuleGlow("SpeedActive", Settings.SpeedActive) end, 65)
addLabel("Speed Value:", fSpeed, 35); addTextBox(fSpeed, 35, Settings.BoostSpeed, function(v) Settings.BoostSpeed = v end); setupCustomKeybind(bSpeed, "SpeedBind")

local fJump, _, bJump = AddModule("JumpBoost", "Jump Power Boost", ScrollMovement, function() Settings.JumpActive = not Settings.JumpActive; SetModuleGlow("JumpActive", Settings.JumpActive) end, 65)
addLabel("Jump Power:", fJump, 35); addTextBox(fJump, 35, Settings.BoostJump, function(v) Settings.BoostJump = v end); setupCustomKeybind(bJump, "JumpBind")

local fBhop, _, bBhop = AddModule("Bhop", "Bhop", ScrollMovement, function() Settings.BhopActive = not Settings.BhopActive; SetModuleGlow("BhopActive", Settings.BhopActive) end, 65)
addLabel("Forward Force:", fBhop, 35); addTextBox(fBhop, 35, Settings.BhopSpeed, function(v) Settings.BhopSpeed = v end); setupCustomKeybind(bBhop, "BhopBind")

local fFly, _, bFly = AddModule("Flight", "Character Flight", ScrollMovement, function() Settings.FlightActive = not Settings.FlightActive; SetModuleGlow("FlightActive", Settings.FlightActive) end, 65)
addLabel("Flight Speed:", fFly, 35); addTextBox(fFly, 35, Settings.FlightSpeed, function(v) Settings.FlightSpeed = v end); setupCustomKeybind(bFly, "FlightBind")

local fVfly, _, bVfly = AddModule("Vfly", "Vehicle Flight", ScrollMovement, function() Settings.VflyActive = not Settings.VflyActive; SetModuleGlow("VflyActive", Settings.VflyActive) end, 65)
addLabel("Vfly Speed:", fVfly, 35); addTextBox(fVfly, 35, Settings.VflySpeed, function(v) Settings.VflySpeed = v end); setupCustomKeybind(bVfly, "VflyBind")

local fBlink = Instance.new("Frame", ScrollMovement); fBlink.Size = UDim2.new(1,0,0,32); fBlink.BackgroundColor3 = Theme.ModuleBg; fBlink.ClipsDescendants = true; fBlink.Name = "SpeedBlink"; Instance.new("UICorner", fBlink).CornerRadius = UDim.new(0,4)
local blTrigger = Instance.new("TextButton", fBlink); blTrigger.Size = UDim2.new(1, -80, 0, 32); blTrigger.BackgroundTransparency = 1; blTrigger.Font = Enum.Font.GothamBold; blTrigger.Text = "  Speed Blink"; blTrigger.TextColor3 = Theme.Text; blTrigger.TextSize = 12; blTrigger.TextXAlignment = Enum.TextXAlignment.Left
local blBindBtn = Instance.new("TextButton", fBlink); blBindBtn.Position = UDim2.new(1, -72, 0, 5); blBindBtn.Size = UDim2.new(0, 65, 0, 22); blBindBtn.BackgroundColor3 = Theme.ElementBg; blBindBtn.Font = Enum.Font.GothamBold; blBindBtn.Text = "Bind"; blBindBtn.TextColor3 = Theme.Accent; blBindBtn.TextSize = 11; Instance.new("UICorner", blBindBtn).CornerRadius = UDim.new(0,4)
setupCustomKeybind(blBindBtn, "BlinkBind")
addLabel("Blink Mode:", fBlink, 35); addModeBtn(fBlink, 35, Settings.BlinkMode, {"Normal", "Strict"}, function(m) Settings.BlinkMode = m end)
addLabel("Teleport studs:", fBlink, 60); addTextBox(fBlink, 60, Settings.BlinkDistance, function(v) Settings.BlinkDistance = v end)
blTrigger.MouseButton2Click:Connect(function() local open = (fBlink.Size.Y.Offset == 32) TweenService:Create(fBlink, TweenInfo.new(0.15), {Size = open and UDim2.new(1,0,0,90) or UDim2.new(1,0,0,32)}):Play() end)

local fAirJ, _, bAirJ = AddModule("AirJump", "Air Jump", ScrollMovement, function() Settings.AirJumpActive = not Settings.AirJumpActive; SetModuleGlow("AirJumpActive", Settings.AirJumpActive) end, 90)
addLabel("Mode:", fAirJ, 35); addModeBtn(fAirJ, 35, Settings.AirJumpMode, {"Default", "Velocity"}, function(m) Settings.AirJumpMode = m end)
addLabel("Force Studs:", fAirJ, 60); addTextBox(fAirJ, 60, Settings.AirJumpPower, function(v) Settings.AirJumpPower = v end); setupCustomKeybind(bAirJ, "AirJumpBind")

local fSpider, _, bSpider = AddModule("Spider", "Spider", ScrollMovement, function() Settings.SpiderActive = not Settings.SpiderActive; SetModuleGlow("SpiderActive", Settings.SpiderActive) end, 65)
addLabel("Climb Speed:", fSpider, 35); addTextBox(fSpider, 35, Settings.SpiderSpeed, function(v) Settings.SpiderSpeed = v end); setupCustomKeybind(bSpider, "SpiderBind")

-- Полезный Анти-Воид теперь вынесен отдельным независимым модулем в Movement
local fVoid, _, bVoid = AddModule("AntiVoid", "Anti-Void Security", ScrollMovement, function() Settings.AntiVoid = not Settings.AntiVoid; SetModuleGlow("AntiVoid", Settings.AntiVoid) end, 65)
addLabel("Void Height Y:", fVoid, 35); addTextBox(fVoid, 35, Settings.AntiVoidHeight, function(v) Settings.AntiVoidHeight = v end); setupCustomKeybind(bVoid, "AntiVoidBind")

-- ====================================================================
-- VISUALS TAB MODULES
-- ====================================================================
local fEsp, _, bEsp = AddModule("Esp", "Esp Core System", ScrollVisuals, function() 
    Settings.EspActive = not Settings.EspActive; SetModuleGlow("EspActive", Settings.EspActive)
    if not Settings.EspActive then
        local plist = Players:GetPlayers()
        for i = 1, #plist do 
            local p = plist[i]
            if p.Character and p.Character:FindFirstChild("RbNeonHighlight") then p.Character.RbNeonHighlight:Destroy() end 
        end
    end
end, 165)
addLabel("Fill Alpha (0-100):", fEsp, 35); addTextBox(fEsp, 35, Settings.EspFillTransparency * 100, function(v) Settings.EspFillTransparency = v / 100 end)
addLabel("Show FOV Ring:", fEsp, 60); addToggle(fEsp, 60, Settings.FovCircleVisible, function(v) Settings.FovCircleVisible = v UpdateFovCircle() end)
addLabel("Box Outlines:", fEsp, 85); addToggle(fEsp, 85, Settings.EspBoxes, function(v) Settings.EspBoxes = v end)
addLabel("Tracers Link:", fEsp, 110); addToggle(fEsp, 110, Settings.EspTracers, function(v) Settings.EspTracers = v end)
addLabel("Name Tags:", fEsp, 135); addToggle(fEsp, 135, Settings.EspNames, function(v) Settings.EspNames = v end)
setupCustomKeybind(bEsp, "EspBind")

local fShaders, _, bShaders = AddModule("ShadersModule", "Shaders Engine", ScrollVisuals, function()
    Settings.ShadersActive = not Settings.ShadersActive; SetModuleGlow("ShadersActive", Settings.ShadersActive)
    if Settings.ShadersActive then
        if not Lighting:FindFirstChild("RbShaders_SunRays") then
            local sun = Instance.new("SunRaysEffect", Lighting); sun.Name = "RbShaders_SunRays"; sun.Intensity = 0.35; CustomVisuals.SunRays = sun
            local colorCorr = Instance.new("ColorCorrectionEffect", Lighting); colorCorr.Name = "RbShaders_Color"; colorCorr.TintColor = Color3.fromRGB(225, 190, 255); CustomVisuals.ColorCorr = colorCorr
        end
    else
        if CustomVisuals.SunRays then CustomVisuals.SunRays:Destroy() end
        if CustomVisuals.ColorCorr then CustomVisuals.ColorCorr:Destroy() end
    end
end, 35)
setupCustomKeybind(bShaders, "ShadersBind")

local XrayCache = {}
local function ApplyXrayToPart(part)
    if part:IsA("BasePart") and not part:IsDescendantOf(LocalPlayer.Character or Workspace) and not part:IsA("Terrain") then
        if not part:GetAttribute("OldTrans") then part:SetAttribute("OldTrans", part.Transparency) end
        part.Transparency = Settings.XrayActive and 0.65 or part:GetAttribute("OldTrans")
        if not Settings.XrayActive then part:SetAttribute("OldTrans", nil) end
    end
end

local fBright, _, bBright = AddModule("Fullbright", "Fullbright Render", ScrollVisuals, function() 
    Settings.FullbrightActive = not Settings.FullbrightActive; SetModuleGlow("FullbrightActive", Settings.FullbrightActive)
    if not Settings.FullbrightActive then Lighting.Ambient = OrigLighting.Ambient; Lighting.OutdoorAmbient = OrigLighting.OutdoorAmbient; Lighting.ClockTime = OrigLighting.ClockTime; Lighting.Brightness = OrigLighting.Brightness; Lighting.FogEnd = OrigLighting.FogEnd end
end, 115)
addLabel("Ambient Power:", fBright, 35); addTextBox(fBright, 35, Settings.FullbrightPower, function(v) Settings.FullbrightPower = v end)
addLabel("Remove Fog:", fBright, 60); addToggle(fBright, 60, Settings.NoFog, function(v) Settings.NoFog = v end)
addLabel("Xray Vision:", fBright, 85); addToggle(fBright, 85, Settings.XrayActive, function(v) 
    Settings.XrayActive = v 
    for part, _ in pairs(XrayCache) do ApplyXrayToPart(part) end
end)
setupCustomKeybind(bBright, "FullbrightBind")

task.spawn(function()
    for _, obj in ipairs(Workspace:GetDescendants()) do if obj:IsA("BasePart") then XrayCache[obj] = true end end
    Workspace.DescendantAdded:Connect(function(obj) if obj:IsA("BasePart") then XrayCache[obj] = true if Settings.XrayActive then ApplyXrayToPart(obj) end end end)
    Workspace.DescendantRemoving:Connect(function(obj) XrayCache[obj] = nil end)
end)

-- ====================================================================
-- MISC TAB MODULES
-- ====================================================================
local fNoCol, _, bNoCol = AddModule("NoPlayerCollision", "No Player Collision", ScrollMisc, function() Settings.NoPlayerCollision = not Settings.NoPlayerCollision; SetModuleGlow("NoPlayerCollision", Settings.NoPlayerCollision) end, 35)
local fNoc, _, bNoc = AddModule("Noclip", "Character Noclip", ScrollMisc, function() Settings.NoclipActive = not Settings.NoclipActive; SetModuleGlow("NoclipActive", Settings.NoclipActive) end, 35); setupCustomKeybind(bNoc, "NoclipBind")

local fClickTp, _, bClickTp = AddModule("ClickTP", "Mouse Click Teleport", ScrollMisc, function() Settings.ClickTpActive = not Settings.ClickTpActive; SetModuleGlow("ClickTP", Settings.ClickTpActive) end, 90)
addLabel("Teleport Mode:", fClickTp, 35); addModeBtn(fClickTp, 35, Settings.ClickTpMode, {"Click Req", "Instant"}, function(m) Settings.ClickTpMode = m end)
addLabel("Hold Key:", fClickTp, 60)
local bCKey = Instance.new("TextButton", fClickTp); bCKey.Position = UDim2.new(1, -72, 0, 60); bCKey.Size = UDim2.new(0, 65, 0, 20); bCKey.BackgroundColor3 = Theme.ElementBg; bCKey.Font = Enum.Font.GothamBold; bCKey.Text = "LControl"; bCKey.TextColor3 = Theme.Accent; bCKey.TextSize = 11; Instance.new("UICorner", bCKey).CornerRadius = UDim.new(0, 4)
bCKey.MouseButton1Click:Connect(function()
    isBindingProcess = true; bCKey.Text = "..."
    local conn; conn = UserInputService.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Keyboard then Settings.ClickTpKey = i.KeyCode; bCKey.Text = i.KeyCode.Name; conn:Disconnect(); isBindingProcess = false end
    end)
end)
setupCustomKeybind(bClickTp, "ClickTpBind")

local fFastTp = Instance.new("Frame", ScrollMisc); fFastTp.Size = UDim2.new(1,0,0,32); fFastTp.BackgroundColor3 = Theme.ModuleBg; fFastTp.ClipsDescendants = true; Instance.new("UICorner", fFastTp).CornerRadius = UDim.new(0,4); fFastTp.Name = "FastPosTP"
local ftTrigger = Instance.new("TextButton", fFastTp); ftTrigger.Size = UDim2.new(1, -80, 0, 32); ftTrigger.BackgroundTransparency = 1; ftTrigger.Font = Enum.Font.GothamBold; ftTrigger.Text = "  Fast Position TP"; ftTrigger.TextColor3 = Theme.Text; ftTrigger.TextSize = 12; ftTrigger.TextXAlignment = Enum.TextXAlignment.Left
local ftBindBtn = Instance.new("TextButton", fFastTp); ftBindBtn.Position = UDim2.new(1, -72, 0, 5); ftBindBtn.Size = UDim2.new(0, 65, 0, 22); ftBindBtn.BackgroundColor3 = Theme.ElementBg; ftBindBtn.Font = Enum.Font.GothamBold; ftBindBtn.Text = "Bind"; ftBindBtn.TextColor3 = Theme.Accent; ftBindBtn.TextSize = 11; Instance.new("UICorner", ftBindBtn).CornerRadius = UDim.new(0,4)
setupCustomKeybind(ftBindBtn, "FastTpBind")
addButton("Save Position", fFastTp, 35, function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        FastTpPos = root.Position
        if FastTpVisual then FastTpVisual:Destroy() end
        FastTpVisual = Instance.new("Part", VisualFolder); FastTpVisual.Size = Vector3.new(0.6, 0.6, 0.6); FastTpVisual.Position = FastTpPos; FastTpVisual.Anchored = true; FastTpVisual.CanCollide = false; FastTpVisual.Color = Theme.Accent; FastTpVisual.Material = Enum.Material.Neon; Instance.new("SpecialMesh", FastTpVisual).MeshType = Enum.MeshType.Sphere
    end
end)
ftTrigger.MouseButton2Click:Connect(function() local open = (fFastTp.Size.Y.Offset == 32) TweenService:Create(fFastTp, TweenInfo.new(0.15), {Size = open and UDim2.new(1,0,0,65) or UDim2.new(1,0,0,32)}):Play() end)

local fTpM, _, bTpM = AddModule("TpManager", "Route Manager", ScrollMisc, function() Settings.TpManagerActive = not Settings.TpManagerActive; SetModuleGlow("TpManagerActive", Settings.TpManagerActive) end, 115)
addLabel("TP Interval:", fTpM, 35); addTextBox(fTpM, 35, Settings.TpManagerInterval, function(v) Settings.TpManagerInterval = v end)
addButton("Add Route Point", fTpM, 60, function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        table.insert(TpPoints, root.Position)
        local p = Instance.new("Part", VisualFolder); p.Size = Vector3.new(0.5, 0.5, 0.5); p.Position = root.Position; p.Anchored = true; p.CanCollide = false; p.Color = Theme.AccentSecondary; p.Material = Enum.Material.Neon; table.insert(TpVisuals, p)
    end
end)
addButton("Clear Points", fTpM, 85, function() TpPoints = {}; for i = 1, #TpVisuals do TpVisuals[i]:Destroy() end; TpVisuals = {}; CurrentTpIndex = 1 end); setupCustomKeybind(bTpM, "TpManagerBind")

-- Чат Спамер (чистый, без лишних функций автоматизации)
local fSpam, _, bSpam = AddModule("ChatSpam", "Chat Spammer Check", ScrollMisc, function() Settings.ChatSpam = not Settings.ChatSpam; SetModuleGlow("ChatSpam", Settings.ChatSpam) end, 35)
setupCustomKeybind(bSpam, "ChatSpamBind")

-- Спиннер с исправленным вращением
local fSpinner, _, bSpinner = AddModule("SpinnerFrame", "Character Anti-Aim Spinner", ScrollMisc, function() Settings.SpinnerActive = not Settings.SpinnerActive; SetModuleGlow("SpinnerActive", Settings.SpinnerActive) end, 90)
addLabel("Rotation Speed:", fSpinner, 35); addTextBox(fSpinner, 35, Settings.SpinnerSpeed, function(v) Settings.SpinnerSpeed = v end)
addLabel("Walk Sync Protection:", fSpinner, 60); addToggle(fSpinner, 60, Settings.SpinnerMoveSync, function(v) Settings.SpinnerMoveSync = v end)
setupCustomKeybind(bSpinner, "SpinnerBind")

-- ====================================================================
-- SETTINGS TAB MODULES
-- ====================================================================
local fMenuBind = Instance.new("Frame", ScrollSettings); fMenuBind.Size = UDim2.new(1,0,0,32); fMenuBind.BackgroundColor3 = Theme.ModuleBg; Instance.new("UICorner", fMenuBind).CornerRadius = UDim.new(0,4); fMenuBind.Name = "MenuKeybindFrame"
addLabel("Menu Keybind", fMenuBind, 7)
local mBindBtn = Instance.new("TextButton", fMenuBind); mBindBtn.Position = UDim2.new(1, -85, 0, 5); mBindBtn.Size = UDim2.new(0, 78, 0, 22); mBindBtn.BackgroundColor3 = Theme.ElementBg; mBindBtn.Font = Enum.Font.GothamBold; mBindBtn.Text = "RightControl"; mBindBtn.TextColor3 = Theme.Accent; mBindBtn.TextSize = 11; Instance.new("UICorner", mBindBtn).CornerRadius = UDim.new(0,4)
mBindBtn.MouseButton1Click:Connect(function()
    if isBindingProcess then return end; isBindingProcess = true; mBindBtn.Text = "..."
    local conn; conn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then Settings.GUIBind = input.KeyCode; mBindBtn.Text = input.KeyCode.Name; conn:Disconnect(); isBindingProcess = false end
    end)
end)

-- ====================================================================
-- ХОТКЕЙ ФРЕЙМВОРК И ИГРОВЫЕ ЦИКЛЫ
-- ====================================================================
UserInputService.InputBegan:Connect(function(input, processed)
    if input.KeyCode == Settings.GUIBind then MainFrame.Visible = not MainFrame.Visible end
    if processed then return end

    local function checkToggle(bind, key)
        if bind ~= Enum.KeyCode.Unknown and input.KeyCode == bind then
            if key == "SilentAimActive" then Settings.SilentAimActive = not Settings.SilentAimActive; LockedTarget = nil; SetModuleGlow("SilentAimActive", Settings.SilentAimActive)
            else Settings[key] = not Settings[key]; SetModuleGlow(key, Settings[key]) end
        end
    end

    checkToggle(Settings.SilentAimBind, "SilentAimActive")
    checkToggle(Settings.FollowBind, "FollowActive")
    checkToggle(Settings.SpeedBind, "SpeedActive")
    checkToggle(Settings.JumpBind, "JumpActive")
    checkToggle(Settings.BhopBind, "BhopActive")
    checkToggle(Settings.FlightBind, "FlightActive")
    checkToggle(Settings.VflyBind, "VflyActive")
    checkToggle(Settings.AirJumpBind, "AirJumpActive")
    checkToggle(Settings.SpiderBind, "SpiderActive")
    checkToggle(Settings.ClickTpBind, "ClickTpActive")
    checkToggle(Settings.TpManagerBind, "TpManagerActive")
    checkToggle(Settings.NoclipBind, "NoclipActive")
    checkToggle(Settings.EspBind, "EspActive")
    checkToggle(Settings.FullbrightBind, "FullbrightActive")
    checkToggle(Settings.ShadersBind, "ShadersActive")
    checkToggle(Settings.SpinnerBind, "SpinnerActive")
    checkToggle(Settings.AntiVoidBind, "AntiVoid")
    checkToggle(Settings.ChatSpamBind, "ChatSpam")

    if Settings.ClickTpActive and Settings.ClickTpMode == "Instant" and input.KeyCode == Settings.ClickTpKey then
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root and Mouse.Hit then root.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0)) end
    end

    if Settings.BlinkBind ~= Enum.KeyCode.Unknown and input.KeyCode == Settings.BlinkBind then
        local char = LocalPlayer.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.MoveDirection.Magnitude > 0 then
            local dist = Settings.BlinkDistance; if Settings.BlinkMode == "Strict" then dist = math.min(dist, 15) end
            root.CFrame = root.CFrame + (hum.MoveDirection * dist)
        end
    end

    if Settings.FastTpBind ~= Enum.KeyCode.Unknown and input.KeyCode == Settings.FastTpBind and FastTpPos then
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = CFrame.new(FastTpPos + Vector3.new(0, 3, 0)) end
    end
end)

UserInputService.InputBegan:Connect(function(input)
    if Settings.ClickTpActive and Settings.ClickTpMode == "Click Req" and input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Settings.ClickTpKey) then
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root and Mouse.Hit then root.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0)) end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if not Settings.AirJumpActive then return end
    local char = LocalPlayer.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChildOfClass("Humanoid")
    if root and hum and hum.FloorMaterial == Enum.Material.Air then
        if Settings.AirJumpMode == "Default" then hum:ChangeState(Enum.HumanoidStateType.Jumping)
        elseif Settings.AirJumpMode == "Velocity" then root.Velocity = Vector3.new(root.Velocity.X, Settings.AirJumpPower, root.Velocity.Z) end
    end
end)

task.spawn(function()
    while task.wait(0.6) do
        if Settings.ChatSpam then
            local sayMsg = ReplicatedStorage:FindFirstChild("SayMessageRequest", true) or (ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") and ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest"))
            if sayMsg and sayMsg:IsA("RemoteEvent") then
                sayMsg:FireServer("RdHelper Execution Stability Confirmed", "All")
            end
        end
    end
end)

local LastFlightState = false 
local TargetCache = nil

task.spawn(function()
    while task.wait(0.03) do 
        if Settings.SilentAimActive then TargetCache = GetClosestPlayerInFov() end
    end
end)

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    UpdateFovCircle()

    if Settings.FullbrightActive then
        local p = Settings.FullbrightPower; Lighting.Ambient = Color3.new(p, p, p); Lighting.OutdoorAmbient = Color3.new(p, p, p); Lighting.ClockTime = 14
        if Settings.NoFog then Lighting.FogEnd = 999999 end
    end

    if Settings.SilentAimActive then
        Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
        local isAimKeyPressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        local currentTarget = TargetCache
        
        if currentTarget and IsValid(currentTarget) and Settings.TargetIndicator then
            AimTargetGui.Adornee = currentTarget.Character:FindFirstChild(Settings.HitPart) or currentTarget.Character.Head; AimTargetGui.Enabled = true
        else
            AimTargetGui.Enabled = false
        end

        if Settings.AimMode == "Toggle" then
            if isAimKeyPressed then
                if not ClickDebounce then
                    ClickDebounce = true
                    if LockedTarget then LockedTarget = nil else LockedTarget = currentTarget end
                end
            else
                ClickDebounce = false
            end
        else
            if isAimKeyPressed then
                if not (Settings.TargetLock and LockedTarget and IsValid(LockedTarget)) then LockedTarget = currentTarget end
            else
                LockedTarget = nil
            end
        end

        local activeTarget = LockedTarget
        if Settings.AimMode == "Hold" and not activeTarget then activeTarget = currentTarget end

        if activeTarget and IsValid(activeTarget) then
            local targetPart = activeTarget.Character:FindFirstChild(Settings.HitPart) or activeTarget.Character.Head
            if Settings.AimMode == "Toggle" or isAimKeyPressed then
                if Settings.AimType == "Bypass" or Settings.AimType == "Classic" then Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position) end
                root.CFrame = CFrame.new(root.Position, Vector3.new(targetPart.Position.X, root.Position.Y, targetPart.Position.Z))
            end
        else
            if Settings.AimMode == "Toggle" then LockedTarget = nil end
        end
    else
        AimTargetGui.Enabled = false; LockedTarget = nil; ClickDebounce = false
    end

    -- Идеальный плавный спиннер на 360 градусов
    if Settings.SpinnerActive and not Settings.FlightActive and not Settings.VflyActive then
        if Settings.SpinnerMoveSync and hum.MoveDirection.Magnitude > 0 then
            hum.AutoRotate = true
        else
            hum.AutoRotate = false
            SpinnerAngle = (SpinnerAngle + math.rad(Settings.SpinnerSpeed)) % (math.pi * 2)
            root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, SpinnerAngle, 0)
        end
    else
        if not hum.AutoRotate and not Settings.FlightActive then hum.AutoRotate = true end
    end

    if Settings.FlightActive then
        if not LastFlightState then LastFlightState = true; OriginalGravity = Workspace.Gravity end
        Workspace.Gravity = 0; hum:ChangeState(Enum.HumanoidStateType.Physics)
        local camLook = Camera.CFrame.LookVector; root.CFrame = CFrame.new(root.Position, root.Position + Vector3.new(camLook.X, camLook.Y, camLook.Z))
        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
        root.AssemblyAngularVelocity = Vector3.zero
        if moveDir.Magnitude > 0 then root.AssemblyLinearVelocity = moveDir.Unit * Settings.FlightSpeed else root.AssemblyLinearVelocity = Vector3.zero end
    else
        if LastFlightState then
            LastFlightState = false; Workspace.Gravity = OriginalGravity; root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero
            hum:ChangeState(Enum.HumanoidStateType.GettingUp); task.wait(0.05); hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end

    -- Анти-Воид с точной высотой из текстового поля
    if Settings.AntiVoid and root.Position.Y < Settings.AntiVoidHeight then
        root.Velocity = Vector3.new(root.Velocity.X, 65, root.Velocity.Z)
    end

    if Settings.TpManagerActive and #TpPoints > 0 then
        local now = os.clock()
        if now - LastTpTime >= Settings.TpManagerInterval then
            LastTpTime = now; if CurrentTpIndex > #TpPoints then CurrentTpIndex = 1 end
            root.CFrame = CFrame.new(TpPoints[CurrentTpIndex] + Vector3.new(0, 3, 0)); CurrentTpIndex = CurrentTpIndex + 1
        end
    end

    if Settings.SpiderActive and hum.MoveDirection.Magnitude > 0 then
        local raycastParams = RaycastParams.new(); raycastParams.FilterType = Enum.RaycastFilterType.Exclude; raycastParams.FilterDescendantsInstances = {char}
        local wallRay = Workspace:Raycast(root.Position, hum.MoveDirection * 2.5, raycastParams)
        if wallRay and math.abs(wallRay.Normal.Y) < 0.1 then root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, Settings.SpiderSpeed, root.AssemblyLinearVelocity.Z) end
    end

    if Settings.VflyActive then
        local vehicle = GetVehiclePart()
        if vehicle then
            if not hum.Sit and vehicle:IsA("VehicleSeat") then pcall(function() vehicle:Sit(hum) end) end
            local model = vehicle:FindFirstAncestorOfClass("Model")
            if model then 
                local mDesc = model:GetChildren()
                for i = 1, #mDesc do local part = mDesc[i] if part:IsA("BasePart") and part ~= vehicle then part.CanCollide = false end end 
            end
            local cDesc = char:GetChildren()
            for i = 1, #cDesc do local part = cDesc[i] if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.CanCollide = false end end
            
            local moveDir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
            local camLook = Camera.CFrame.LookVector; local targetRotation = CFrame.new(vehicle.Position, vehicle.Position + Vector3.new(camLook.X, camLook.Y, camLook.Z))
            pcall(function()
                vehicle.AssemblyLinearVelocity = Vector3.new(0, 0.01, 0); vehicle.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                if moveDir.Magnitude > 0 then vehicle.CFrame = targetRotation:Lerp(targetRotation + (moveDir.Unit * (Settings.VflySpeed / 60)), 0.85) else vehicle.CFrame = vehicle.CFrame:Lerp(targetRotation, 0.2) end
            end)
        end
    end

    if Settings.FollowActive then
        local followTarget = GetClosestPlayerForFollow()
        if followTarget and followTarget.Character and followTarget.Character:FindFirstChild("HumanoidRootPart") then
            local tRoot = followTarget.Character.HumanoidRootPart; local targetOffset = tRoot.Position - (tRoot.CFrame.LookVector * Settings.FollowDistance)
            if Settings.FollowMode == "Fly" then root.CFrame = root.CFrame:Lerp(CFrame.new(Vector3.new(targetOffset.X, tRoot.Position.Y + 2, targetOffset.Z), tRoot.Position), 0.15)
            else root.CFrame = root.CFrame:Lerp(CFrame.new(Vector3.new(targetOffset.X, tRoot.Position.Y, targetOffset.Z), Vector3.new(tRoot.Position.X, root.Position.Y, tRoot.Position.Z)), 0.2) end
        end
    end

    if Settings.SpeedActive and not Settings.FlightActive and not Settings.VflyActive then 
        hum.WalkSpeed = Settings.BoostSpeed 
    elseif not Settings.FollowActive and not Settings.FlightActive and not Settings.VflyActive then 
        hum.WalkSpeed = 16 
    end
    
    if Settings.JumpActive then hum.JumpPower = Settings.BoostJump; hum.UseJumpPower = true else hum.JumpPower = 50 end
    if Settings.BhopActive and hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then root.Velocity = Vector3.new(hum.MoveDirection.X * Settings.BhopSpeed, 35, hum.MoveDirection.Z * Settings.BhopSpeed) end
    
    if Settings.NoclipActive then 
        local cDesc = char:GetChildren()
        for i = 1, #cDesc do local v = cDesc[i] if v:IsA("BasePart") then v.CanCollide = false end end 
    end

    if Settings.NoPlayerCollision or Settings.EspActive then
        local playersList = Players:GetPlayers()
        local tickTime = os.clock()
        local factor = (math.sin(tickTime * 4) + 1) / 2
        local mixColor = Theme.Accent:Lerp(Theme.AccentSecondary, factor)

        for i = 1, #playersList do
            local p = playersList[i]
            if p ~= LocalPlayer and p.Character then
                if Settings.NoPlayerCollision then
                    local pDesc = p.Character:GetChildren()
                    for j = 1, #pDesc do local part = pDesc[j] if part:IsA("BasePart") then part.CanCollide = false end end
                end
                if Settings.EspActive and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                    local high = p.Character:FindFirstChild("RbNeonHighlight")
                    if not high then 
                        high = Instance.new("Highlight")
                        high.Name = "RbNeonHighlight"
                        high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        high.Parent = p.Character 
                    end
                    high.FillTransparency = Settings.EspFillTransparency
                    high.OutlineColor = mixColor
                    high.FillColor = mixColor
                end
            end
        end
    end
end)
