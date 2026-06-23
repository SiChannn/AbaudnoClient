--[[
    AbaudnoClient — Click Teleport Module
    Misc: телепортация по клику.
]]

local lib = _G.AbaudnoClient or loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/modules/lib/shared.lua"))()

local Settings = lib.Settings
local UserInputService = lib.UserInputService
local Workspace = lib.Workspace

local M = {}

function M.toggle()
    Settings.ClickTpActive = not Settings.ClickTpActive
    return Settings.ClickTpActive
end

function M.inputBegan(input, gameProcessed)
    if gameProcessed then return end
    if not Settings.ClickTpActive then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if input.KeyCode ~= Settings.ClickTpKey then return end

    local char, root, hum = lib.GetCharParts()
    if not root then return end

    local ray = Ray.new(
        Workspace.CurrentCamera.CFrame.Position,
        Workspace.CurrentCamera.CFrame.LookVector * 1000
    )
    local result = Workspace:FindPartOnRay(ray, char)

    if result then
        root.CFrame = CFrame.new(result.Position) + Vector3.new(0, 5, 0)
    end
end

return M