--[[
TheNexusAvenger

Base input class.
--]]
--!strict

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Projectile = require(script.Parent.Parent.Parent.Parent:WaitForChild("Projectile"))
local Event = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("Event"))

local BaseInput = {}
BaseInput.__index = BaseInput

export type BaseInput = {
    StartFire: Event.Event<>,
    EndFire: Event.Event<>,
    Reload: Event.Event<>,

    new: () -> (BaseInput),
    ConnectReloadButton: (self: BaseInput, Button: Enum.KeyCode) -> (),
    GetTargetScreenSpace: (self: BaseInput) -> (Vector2),
    GetTargetWorldSpace: (self: BaseInput) -> (Vector3),
}



--[[
Creates a base input.
--]]
function BaseInput.new(): BaseInput
    return (setmetatable({
        StartFire = Event.new(),
        EndFire = Event.new(),
        Reload = Event.new(),
    }, BaseInput) :: any) :: BaseInput
end

--[[
Connects a button press to invoke the reload event.
--]]
function BaseInput:ConnectReloadButton(Button: Enum.KeyCode): ()
    UserInputService.InputBegan:Connect(function(Input, Processed)
        if Processed then return end
        if Input.KeyCode ~= Button then return end
        self.Reload:Fire()
    end)
end

--[[
Returns the aiming location for the input in screen space.
--]]
function BaseInput:GetTargetScreenSpace(): Vector2
    return UserInputService:GetMouseLocation()
end

--[[
Returns the aiming location for the input in world space.
--]]
function BaseInput:GetTargetWorldSpace(): Vector3
    local Camera = Workspace.CurrentCamera
    local MousePosition = self:GetTargetScreenSpace()
    local CameraRay = Camera:ScreenPointToRay(MousePosition.X, MousePosition.Y, 10000)
    local _, EndPosition = Projectile.RayCast(Camera.CFrame.Position, CameraRay.Origin + CameraRay.Direction, {Players.LocalPlayer.Character, Camera})
    return EndPosition
end



return (BaseInput :: any) :: BaseInput