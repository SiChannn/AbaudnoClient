--[[
    AbaudnoClient — Air Jump Module
    Movement: прыжок в воздухе.
]]

local lib = _G.AbaudnoClient or loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/modules/lib/shared.lua"))()

local Settings = lib.Settings
local UserInputService = lib.UserInputService

local M = {}

function M.toggle()
    Settings.AirJumpActive = not Settings.AirJumpActive
    return Settings.AirJumpActive
end

function M.onJumpRequest()
    if not Settings.AirJumpActive then return end

    local char, root, hum = lib.GetCharParts()
    if root and hum and hum.FloorMaterial == Enum.Material.Air then
        if Settings.AirJumpMode == "Default" then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        elseif Settings.AirJumpMode == "Velocity" then
            root.Velocity = Vector3.new(root.Velocity.X, Settings.AirJumpPower, root.Velocity.Z)
        end
    end
end

return M
