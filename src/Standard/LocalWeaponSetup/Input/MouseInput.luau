--Handles inputs for a keyboard and mouse.
--!strict

local UserInputService = game:GetService("UserInputService")

local BaseInput = require(script.Parent:WaitForChild("BaseInput"))

local MouseInput = {}
MouseInput.__index = MouseInput
setmetatable(MouseInput, BaseInput)

export type MouseInput = typeof(setmetatable({}, MouseInput)) & BaseInput.BaseInput



--[[
Creates a mouse input.
--]]
function MouseInput.new(): MouseInput
    local self = setmetatable(BaseInput.new(), MouseInput) :: MouseInput
    
    --Connect reloading.
    self:ConnectReloadButton(Enum.KeyCode.R)

    --Connect firing events.
    table.insert(self.Events, UserInputService.InputBegan:Connect(function(Input, Processed)
        if Processed then return end
        if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        self.StartFire:Fire()
    end))
    table.insert(self.Events, UserInputService.InputEnded:Connect(function(Input)
        if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        self.EndFire:Fire()
    end))
    return self
end



return MouseInput