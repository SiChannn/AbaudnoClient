-- Модуль скорости для AbaudnoClient
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Инициализация глобальных переменных, если они не заданы из GUI
if _G.TargetSpeed == nil then _G.TargetSpeed = 16 end
if _G.SpeedModuleEnabled == nil then _G.SpeedModuleEnabled = true end

-- Подключение к циклу рендеринга для стабильного удержания скорости
local connection
connection = RunService.RenderStepped:Connect(function()
    -- Если функция отключена в GUI, возвращаем дефолтную скорость и отключаем цикл
    if not _G.SpeedModuleEnabled then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
        end
        connection:Disconnect()
        return
    end

    -- Применяем кастомную скорость
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid.WalkSpeed ~= _G.TargetSpeed then
            humanoid.WalkSpeed = _G.TargetSpeed
        end
    end
end)
