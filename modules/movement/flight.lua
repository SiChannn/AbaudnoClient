--[[
    AbaudnoClient — Character Flight Module
    Movement: свободный полёт персонажа.
]]

local lib = _G.AbaudnoClient or loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/modules/lib/shared.lua"))()

local Settings = lib.Settings
local UserInputService = lib.UserInputService
local Workspace = lib.Workspace
local Camera = lib.Camera

local M = {}

function M.toggle()
    Settings.FlightActive = not Settings.FlightActive
    return Settings.FlightActive
end

function M.renderStepped(root, hum)
    if not root or not hum then return end

    if Settings.FlightActive then
        if not lib.LastFlightState then
            lib.LastFlightState = true
            lib.OriginalGravity = Workspace.Gravity
        end
        Workspace.Gravity = 0
        hum:ChangeState(Enum.HumanoidStateType.Physics)

        Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
        lib.Camera = Camera
        local camLook = Camera.CFrame.LookVector
        root.CFrame = CFrame.new(root.Position, root.Position + Vector3.new(camLook.X, camLook.Y, camLook.Z))

        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

        root.AssemblyAngularVelocity = Vector3.zero
        if moveDir.Magnitude > 0 then
            root.AssemblyLinearVelocity = moveDir.Unit * Settings.FlightSpeed
        else
            root.AssemblyLinearVelocity = Vector3.zero
        end
    else
        if lib.LastFlightState then
            lib.LastFlightState = false
            Workspace.Gravity = lib.OriginalGravity
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            task.wait(0.05)
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
end

return M
