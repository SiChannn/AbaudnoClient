--[[
    AbaudnoClient — Walk Speed Boost Module
    Movement: увеличение скорости ходьбы.
]]

local lib = _G.AbaudnoClient or loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/modules/lib/shared.lua"))()

local Settings = lib.Settings

local M = {}

function M.toggle()
    Settings.SpeedActive = not Settings.SpeedActive
    return Settings.SpeedActive
end

function M.renderStepped(hum)
    if not hum then return end
    if Settings.SpeedActive and not Settings.FlightActive and not Settings.VflyActive then
        hum.WalkSpeed = Settings.BoostSpeed
    elseif not Settings.FollowActive and not Settings.FlightActive and not Settings.VflyActive then
        hum.WalkSpeed = 16
    end
end

return M
