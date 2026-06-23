--[[
    AbaudnoClient — ESP Core System Module
    Visuals: подсветка игроков через стены.
]]

local lib = _G.AbaudnoClient or loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/modules/lib/shared.lua"))()

local Settings = lib.Settings
local Players = lib.Players
local Theme = lib.Theme

local M = {}

function M.toggle()
    Settings.EspActive = not Settings.EspActive
    if not Settings.EspActive then
        local plist = Players:GetPlayers()
        for i = 1, #plist do
            local p = plist[i]
            if p.Character and p.Character:FindFirstChild("RbNeonHighlight") then
                p.Character.RbNeonHighlight:Destroy()
            end
        end
    end
    return Settings.EspActive
end

function M.renderStepped()
    if not Settings.EspActive and not Settings.NoPlayerCollision then return end

    local playersList = Players:GetPlayers()
    local tickTime = os.clock()
    local factor = (math.sin(tickTime * 4) + 1) / 2
    local mixColor = Theme.Accent:Lerp(Theme.AccentSecondary, factor)

    for i = 1, #playersList do
        local p = playersList[i]
        if p ~= lib.LocalPlayer and p.Character then
            if Settings.EspActive
                and p.Character:FindFirstChild("Humanoid")
                and p.Character.Humanoid.Health > 0
            then
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

return M
