--Combines multiple input sources into a single input handler.
--!strict

local BaseInput = require(script.Parent:WaitForChild("BaseInput"))

local CombinedInput = {}
CombinedInput.__index = CombinedInput
setmetatable(CombinedInput, BaseInput)

export type CombinedInput = {
    CurrentInput: BaseInput.BaseInput,
    Inputs: {BaseInput.BaseInput},
} & typeof(setmetatable({}, CombinedInput)) & BaseInput.BaseInput



--[[
Creates a combined input.
--]]
function CombinedInput.new(...: BaseInput.BaseInput): CombinedInput
    local self = setmetatable(BaseInput.new(), CombinedInput) :: CombinedInput

    --Get the initial input.
    local Inputs = {...}
    self.Inputs = Inputs
    self.CurrentInput = Inputs[1]
    for _, Input in Inputs do
        local CurrentInput = Input :: BaseInput.BaseInput
        if not CurrentInput:IsPriority() then continue end
        self.CurrentInput = CurrentInput
        break
    end

    --Connect firing events.
    for _, Input in Inputs do
        local CurrentInput = Input :: BaseInput.BaseInput
        table.insert(self.Events, CurrentInput.StartFire:Connect(function()
            self.CurrentInput = CurrentInput
            self.StartFire:Fire()
        end))
        table.insert(self.Events, CurrentInput.EndFire:Connect(function()
            --Only the latest input is allowed to control when firing is stopped.
            if self.CurrentInput ~= Input then return end
            self.EndFire:Fire()
        end))
        table.insert(self.Events, CurrentInput.Reload:Connect(function()
            self.Reload:Fire()
        end))
    end
    return self
end

--[[
Returns the aiming location for the input in screen space.
--]]
function CombinedInput.GetTargetScreenSpace(self: CombinedInput): Vector2
    return self.CurrentInput:GetTargetScreenSpace()
end

--[[
Returns the aiming location for the input in world space.
--]]
function CombinedInput.GetTargetWorldSpace(self: CombinedInput): Vector3
    return self.CurrentInput:GetTargetWorldSpace()
end

--[[
Destroys the input.
--]]
function CombinedInput.Destroy(self: CombinedInput): ()
    BaseInput.Destroy(self)
    for _, Input in self.Inputs do
        (Input :: BaseInput.BaseInput):Destroy()
    end
end



return CombinedInput