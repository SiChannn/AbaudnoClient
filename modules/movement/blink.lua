--[[
    AbaudnoClient — Speed Blink Module
    Movement: мгновенный телепорт вперёд по направлению движения.
]]

local lib = _G.AbaudnoClient or loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/modules/lib/shared.lua"))()

local Settings = lib.Settings

local M = {}

function M.onKeyPress(keyCode)
    if Settings.BlinkBind == Enum.KeyCode.Unknown or keyCode ~= Settings.BlinkBind then return end

    local char, root, hum = lib.GetCharParts()
    if root and hum and hum.MoveDirection.Magnitude > 0 then
        local dist = Settings.BlinkDistance
        if Settings.BlinkMode == "Strict" then dist = math.min(dist, 15) end
        root.CFrame = root.CFrame + (hum.MoveDirection * dist)
    end
end

return M
