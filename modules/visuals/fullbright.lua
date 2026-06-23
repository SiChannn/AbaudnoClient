--[[
    AbaudnoClient — Fullbright Render Module
    Visuals: полное освещение + Xray + NoFog.
]]

local lib = _G.AbaudnoClient or loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/modules/lib/shared.lua"))()

local Settings = lib.Settings
local Lighting = lib.Lighting
local Workspace = lib.Workspace

local M = {}

function M.toggle()
    Settings.FullbrightActive = not Settings.FullbrightActive
    if not Settings.FullbrightActive then
        Lighting.Ambient = lib.OrigLighting.Ambient
        Lighting.OutdoorAmbient = lib.OrigLighting.OutdoorAmbient
        Lighting.ClockTime = lib.OrigLighting.ClockTime
        Lighting.Brightness = lib.OrigLighting.Brightness
        Lighting.FogEnd = lib.OrigLighting.FogEnd
    end
    return Settings.FullbrightActive
end

function M.initXrayCache()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            lib.XrayCache[obj] = true
        end
    end
    Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("BasePart") then
            lib.XrayCache[obj] = true
            if Settings.XrayActive then lib.ApplyXrayToPart(obj) end
        end
    end)
    Workspace.DescendantRemoving:Connect(function(obj)
        lib.XrayCache[obj] = nil
    end)
end

function M.onXrayToggle()
    for part, _ in pairs(lib.XrayCache) do
        lib.ApplyXrayToPart(part)
    end
end

function M.renderStepped()
    if not Settings.FullbrightActive then return end

    local p = Settings.FullbrightPower
    Lighting.Ambient = Color3.new(p, p, p)
    Lighting.OutdoorAmbient = Color3.new(p, p, p)
    Lighting.ClockTime = 14
    if Settings.NoFog then
        Lighting.FogEnd = 999999
    end
end

return M
