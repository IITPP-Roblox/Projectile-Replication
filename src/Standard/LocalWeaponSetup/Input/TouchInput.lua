--[[
TheNexusAvenger

Handles inputs for touch displays.
TODO: Not a great design, but does allow for holding down.
--]]
--!strict

local UserInputService = game:GetService("UserInputService")

local BaseInput = require(script.Parent:WaitForChild("BaseInput"))

local TouchInput = {}
TouchInput.__index = BaseInput
setmetatable(TouchInput, BaseInput)

export type TouchInput = {
    new: () -> (TouchInput)
} & BaseInput.BaseInput



--[[
Creates a touch input.
--]]
function TouchInput.new(): TouchInput
    local self = (BaseInput.new() :: any) :: TouchInput
    setmetatable(self, TouchInput)

    --Connect firing events.
    UserInputService.InputBegan:Connect(function(Input, Processed)
        if Processed then return end
        if Input.UserInputType ~= Enum.UserInputType.Touch then return end
        self.StartFire:Fire()
    end)
    UserInputService.InputEnded:Connect(function(Input)
        if Input.UserInputType ~= Enum.UserInputType.Touch then return end
        self.EndFire:Fire()
    end)
    return self
end



return (TouchInput :: any) :: TouchInput