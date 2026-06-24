-- Создание GUI
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local LeftPanel = Instance.new("Frame")
local TabButton = Instance.new("TextButton")
local ContentPanel = Instance.new("Frame")
local MovementTab = Instance.new("Frame")
local SpeedToggle = Instance.new("TextButton")
local SettingsPanel = Instance.new("Frame")
local SpeedInput = Instance.new("TextBox")

-- Настройки GUI
ScreenGui.Name = "AbaudnoGui"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 450, 0, 300)
MainFrame.Active = true
MainFrame.Draggable = true -- Простой перенос меню

LeftPanel.Name = "LeftPanel"
LeftPanel.Parent = MainFrame
LeftPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
LeftPanel.Size = UDim2.new(0, 120, 1, 0)

TabButton.Name = "TabButton"
TabButton.Parent = LeftPanel
TabButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
TabButton.Size = UDim2.new(1, 0, 0, 40)
TabButton.Font = Enum.Font.SourceSansBold
TabButton.Text = "Movement"
TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TabButton.TextSize = 16

ContentPanel.Name = "ContentPanel"
ContentPanel.Parent = MainFrame
ContentPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ContentPanel.Position = UDim2.new(0, 120, 0, 0)
ContentPanel.Size = UDim2.new(1, -120, 1, 0)

MovementTab.Name = "MovementTab"
MovementTab.Parent = ContentPanel
MovementTab.BackgroundTransparency = 1
MovementTab.Size = UDim2.new(1, 0, 1, 0)

-- Кнопка включения функции
SpeedToggle.Name = "SpeedToggle"
SpeedToggle.Parent = MovementTab
SpeedToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SpeedToggle.Position = UDim2.new(0, 20, 0, 20)
SpeedToggle.Size = UDim2.new(0, 150, 0, 35)
SpeedToggle.Font = Enum.Font.SourceSans
SpeedToggle.Text = "Speed: OFF"
SpeedToggle.TextColor3 = Color3.fromRGB(255, 0, 0)
SpeedToggle.TextSize = 16

-- Панель настроек (появляется по ПКМ)
SettingsPanel.Name = "SettingsPanel"
SettingsPanel.Parent = MovementTab
SettingsPanel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
SettingsPanel.Position = UDim2.new(0, 180, 0, 20)
SettingsPanel.Size = UDim2.new(0, 120, 0, 35)
SettingsPanel.Visible = false

SpeedInput.Name = "SpeedInput"
SpeedInput.Parent = SettingsPanel
SpeedInput.BackgroundTransparency = 1
SpeedInput.Size = UDim2.new(1, 0, 1, 0)
SpeedInput.Font = Enum.Font.SourceSans
SpeedInput.Text = "16" -- Дефолтная скорость Roblox
SpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedInput.TextSize = 14
SpeedInput.PlaceholderText = "Введи скорость"

-- Логика взаимодействия
local speedEnabled = false
_G.TargetSpeed = 16 -- Глобальная переменная для передачи значения во 2-й скрипт

-- Обработка кликов (ЛКМ и ПКМ) на кнопку Speed
SpeedToggle.MouseButton1Click:Connect(function()
    -- ЛКМ: Включение / Выключение
    speedEnabled = not speedEnabled
    _G.SpeedModuleEnabled = speedEnabled
    
    if speedEnabled then
        SpeedToggle.Text = "Speed: ON"
        SpeedToggle.TextColor3 = Color3.fromRGB(0, 255, 0)
        -- Загрузка внешнего модуля, как ты просил
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/SiChannn/AbaudnoClient/main/modules/movement/speed.lua"))()
        end)
        if not success then
            warn("Ошибка загрузки модуля: " .. tostring(err))
        end
    else
        SpeedToggle.Text = "Speed: OFF"
        SpeedToggle.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

SpeedToggle.MouseButton2Click:Connect(function()
    -- ПКМ: Показать/скрыть настройки скорости
    SettingsPanel.Visible = not SettingsPanel.Visible
end)

-- Обновление значения скорости при вводе текста
SpeedInput.FocusLost:Connect(function(enterPressed)
    local value = tonumber(SpeedInput.Text)
    if value then
        _G.TargetSpeed = value
    else
        SpeedInput.Text = tostring(_G.TargetSpeed) -- Возврат старого значения, если ввели не число
    end
end)
