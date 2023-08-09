--[[
TheNexusAvenger

Wrapper for controlling vibration motors on gamepads.
--]]
--!strict

local HapticService = game:GetService("HapticService")

local VibrationMotor = {}
VibrationMotor.__index = VibrationMotor
local StaticVibrationMotorInstances = {}

export type VibrationMotor = {
    Motor: Enum.VibrationMotor,
    LastSetTime: number,
    IntensityMultiplier: number,

    GetMotor: (Motor: Enum.VibrationMotor) -> (VibrationMotor),
    new: (Motor: Enum.VibrationMotor) -> (VibrationMotor),
    SetIntensityMultiplier: (self: VibrationMotor, Multiplier: number) -> (),
    Activate: (self: VibrationMotor, Duration: number, Intensity: number) -> ()
}



--[[
Returns a static instance of a motor.
--]]
function VibrationMotor.GetMotor(Motor: Enum.VibrationMotor): VibrationMotor
    if not StaticVibrationMotorInstances[Motor] then
        StaticVibrationMotorInstances[Motor] = VibrationMotor.new(Motor)
    end
    return StaticVibrationMotorInstances[Motor]
end

--[[
Creates a vibration motor state.
--]]
function VibrationMotor.new(Motor: Enum.VibrationMotor): VibrationMotor
    return (setmetatable({
        Motor = Motor,
        LastSetTime = 0,
        IntensityMultiplier = 1,
    }, VibrationMotor) :: any) :: VibrationMotor
end

--[[
Sets the intensity multiplier of the motor.
--]]
function VibrationMotor:SetIntensityMultiplier(Multiplier: number): ()
    self.IntensityMultiplier = Multiplier
end

--[[
Sets the vibration motor as active for the given period of time.
--]]
function VibrationMotor:Activate(Duration: number, Intensity: number): ()
    if Intensity == 0 or self.IntensityMultiplier == 0 then return end
    local CurrentTime = tick()
    self.LastSetTime = CurrentTime
    HapticService:SetMotor(Enum.UserInputType.Gamepad1, self.Motor, Intensity * self.IntensityMultiplier)

    task.delay(Duration, function()
        if self.LastSetTime ~= CurrentTime then return end
        HapticService:SetMotor(Enum.UserInputType.Gamepad1, self.Motor, 0)
    end)
end





return (VibrationMotor :: any) :: VibrationMotor