--[[
TheNexusAvenger

Combines multiple input sources into a single input handler.
--]]
--!strict

local BaseInput = require(script.Parent:WaitForChild("BaseInput"))

local CombinedInput = {}
CombinedInput.__index = CombinedInput
setmetatable(CombinedInput, BaseInput)

export type CombinedInput = {
    CurrentInput: BaseInput.BaseInput,
    Inputs: {BaseInput.BaseInput},
    new: (...BaseInput.BaseInput) -> (CombinedInput),
    Destroy: (CombinedInput) -> (),
} & BaseInput.BaseInput



--[[
Creates a combined input.
--]]
function CombinedInput.new(...: BaseInput.BaseInput): CombinedInput
    local self = (BaseInput.new() :: any) :: CombinedInput
    setmetatable(self, CombinedInput)

    --Connect firing events.
    local Inputs = {...}
    self.Inputs = Inputs
    self.CurrentInput = Inputs[1]
    for _, Input in Inputs do
        table.insert(self.Events, Input.StartFire:Connect(function()
            self.CurrentInput = Input
            self.StartFire:Fire()
        end))
        table.insert(self.Events, Input.EndFire:Connect(function()
            --Only the latest input is allowed to control when firing is stopped.
            if self.CurrentInput ~= Input then return end
            self.EndFire:Fire()
        end))
        table.insert(self.Events, Input.Reload:Connect(function()
            self.Reload:Fire()
        end))
    end
    return self
end

--[[
Returns the aiming location for the input in screen space.
--]]
function CombinedInput:GetTargetScreenSpace(): Vector2
    return self.CurrentInput:GetTargetScreenSpace()
end

--[[
Returns the aiming location for the input in world space.
--]]
function CombinedInput:GetTargetWorldSpace(): Vector3
    return self.CurrentInput:GetTargetWorldSpace()
end

--[[
Destroys the input.
--]]
function CombinedInput:Destroy(): ()
    BaseInput.Destroy(self)
    for _, Input in (self :: CombinedInput).Inputs do
        Input:Destroy()
    end
end


return (CombinedInput :: any) :: CombinedInput