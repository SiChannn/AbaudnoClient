--[[
    AbaudnoClient — Shaders Engine Module
    Visuals: улучшение освещения и цветовой коррекции.
]]

local lib = _G.AbaudnoClient or loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/modules/lib/shared.lua"))()

local Settings = lib.Settings
local Lighting = lib.Lighting

local M = {}

function M.toggle()
    Settings.ShadersActive = not Settings.ShadersActive
    if Settings.ShadersActive then
        if not Lighting:FindFirstChild("RbShaders_SunRays") then
            local sun = Instance.new("SunRaysEffect", Lighting)
            sun.Name = "RbShaders_SunRays"
            sun.Intensity = 0.35
            lib.CustomVisuals.SunRays = sun

            local colorCorr = Instance.new("ColorCorrectionEffect", Lighting)
            colorCorr.Name = "RbShaders_Color"
            colorCorr.TintColor = Color3.fromRGB(225, 190, 255)
            lib.CustomVisuals.ColorCorr = colorCorr
        end
    else
        if lib.CustomVisuals.SunRays then lib.CustomVisuals.SunRays:Destroy() end
        if lib.CustomVisuals.ColorCorr then lib.CustomVisuals.ColorCorr:Destroy() end
    end
    return Settings.ShadersActive
end

return M
