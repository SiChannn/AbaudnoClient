--[[
    AbaudnoClient — Follow Player Module
    Combat: следование за ближайшим игроком.
]]

local lib = _G.AbaudnoClient or loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/modules/lib/shared.lua"))()

local Settings = lib.Settings

local M = {}

function M.toggle()
    Settings.FollowActive = not Settings.FollowActive
    return Settings.FollowActive
end

function M.renderStepped()
    if not Settings.FollowActive then return end

    local char, root, hum = lib.GetCharParts()
    if not root then return end

    local followTarget = lib.GetClosestPlayerForFollow()
    if followTarget and followTarget.Character and followTarget.Character:FindFirstChild("HumanoidRootPart") then
        local tRoot = followTarget.Character.HumanoidRootPart
        local targetOffset = tRoot.Position - (tRoot.CFrame.LookVector * Settings.FollowDistance)

        if Settings.FollowMode == "Fly" then
            root.CFrame = root.CFrame:Lerp(
                CFrame.new(
                    Vector3.new(targetOffset.X, tRoot.Position.Y + 2, targetOffset.Z),
                    tRoot.Position
                ),
                0.15
            )
        else
            root.CFrame = root.CFrame:Lerp(
                CFrame.new(
                    Vector3.new(targetOffset.X, tRoot.Position.Y, targetOffset.Z),
                    Vector3.new(tRoot.Position.X, root.Position.Y, root.Position.Z)
                ),
                0.2
            )
        end
    end
end

return M
