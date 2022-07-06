--[[
TheNexusAvenger

Solves joins for the arms. Taken from the railguns.
TODO: Doesn't work that well with default character: https://github.com/TheNexusAvenger/Nexus-VR-Character-Model/issues/9
--]]

--[[
Attempts to solve a joint.
--]]
local function SolveJoint(OriginCFrame,TargetPosition,Length1,Length2)
    local LocalizedPosition = OriginCFrame:pointToObjectSpace(TargetPosition)
    local LocalizedUnit = LocalizedPosition.unit
    local Hypotenuse = LocalizedPosition.magnitude

    --Get the axis and correct it if it is 0.
    local Axis = Vector3.new(0,0,-1):Cross(LocalizedUnit)
    if Axis == Vector3.new(0,0,0) then
        if LocalizedPosition.Z < 0 then
            Axis = Vector3.new(0,0,0.001)
        else
            Axis = Vector3.new(0,0,-0.001)
        end
    end

    --Calculate and return the angles.
    local PlaneRotation = math.acos(-LocalizedUnit.Z)
    local PlaneCFrame = OriginCFrame * CFrame.fromAxisAngle(Axis,PlaneRotation)
    if Hypotenuse < math.max(Length2,Length1) - math.min(Length2,Length1) then
        local ShoulderAngle,ElbowAngle = -math.pi/2,math.pi
        return PlaneCFrame * CFrame.new(0,0,math.max(Length2,Length1) - math.min(Length2,Length1) - Hypotenuse),ShoulderAngle,ElbowAngle
    elseif Hypotenuse > Length1 + Length2 then
        local ShoulderAngle,ElbowAngle = math.pi/2, 0
        return PlaneCFrame * CFrame.new(0,0,Length1 + Length2 - Hypotenuse),ShoulderAngle,ElbowAngle
    else
        local Angle1 = -math.acos((-(Length2 * Length2) + (Length1 * Length1) + (Hypotenuse * Hypotenuse)) / (2 * Length1 * Hypotenuse))
        local Angle2 = math.acos(((Length2 * Length2) - (Length1 * Length1) + (Hypotenuse * Hypotenuse)) / (2 * Length2 * Hypotenuse))
        return PlaneCFrame,Angle1 + math.pi/2,Angle2 - Angle1
    end
end

--[[
Returns the rotation offset relative to the Y axis
to an end CFrame.
--]]
local function RotationTo(StartCFrame,EndCFrame)
    local Offset = (StartCFrame:Inverse() * EndCFrame).Position
    return CFrame.Angles(math.atan2(Offset.Z,Offset.Y),0,-math.atan2(Offset.X,Offset.Y))
end

--[[
Attempts to solve a limb.
From: https://github.com/TheNexusAvenger/Nexus-VR-Character-Model/blob/master/src/Character/Appendage.lua
--]]
return function(StartCFrame,HoldCFrame,UpperLimbStartAttachment,UpperLimbJointAttachment,LowerLimbJointAttachment,LowerLimbEndAttachment,LimbEndAttachment,LimbHoldAttachment)
    --Get the attachment CFrames.
    local UpperLimbStartCFrame = UpperLimbStartAttachment.CFrame
    local UpperLimbJointCFrame = UpperLimbJointAttachment.CFrame
    local LowerLimbJointCFrame = LowerLimbJointAttachment.CFrame
    local LowerLimbEndCFrame = LowerLimbEndAttachment.CFrame
    local LimbEndCFrame = LimbEndAttachment.CFrame
    local LimbHoldCFrame = LimbHoldAttachment.CFrame

    --Calculate the appendage lengths.
    local UpperLimbLength = (UpperLimbStartCFrame.Position - UpperLimbJointCFrame.Position).magnitude
    local LowerLimbLength = (LowerLimbJointCFrame.Position - LowerLimbEndCFrame.Position).magnitude

    --Calculate the end point of the limb.
    local AppendageEndJointCFrame = HoldCFrame * LimbHoldCFrame:Inverse() * LimbEndCFrame

    --Solve the join.
    local PlaneCFrame,UpperAngle,CenterAngle = SolveJoint(StartCFrame,AppendageEndJointCFrame.Position,UpperLimbLength,LowerLimbLength)

    --Calculate the CFrame of the limb join before and after the center angle.
    local JointUpperCFrame = PlaneCFrame * CFrame.Angles(UpperAngle,0,0) * CFrame.new(0,-UpperLimbLength,0)
    local JointLowerCFrame = JointUpperCFrame * CFrame.Angles(CenterAngle,0,0)

    --Calculate the part CFrames.
    --The appendage end is not calculated with hold CFrame directly since it can ignore PreventDisconnection = true.
    local UpperLimbCFrame = JointUpperCFrame * RotationTo(UpperLimbJointCFrame,UpperLimbStartCFrame):Inverse() * UpperLimbJointCFrame:Inverse()
    local LowerLimbCFrame = JointLowerCFrame * RotationTo(LowerLimbEndCFrame,LowerLimbJointCFrame):Inverse() * LowerLimbJointCFrame:Inverse()
    local AppendageEndCFrame = CFrame.new((LowerLimbCFrame * LowerLimbEndCFrame).Position) * (CFrame.new(-AppendageEndJointCFrame.Position) * AppendageEndJointCFrame) * LimbEndCFrame:Inverse()

    --Return the part CFrames.
    return UpperLimbCFrame,LowerLimbCFrame,AppendageEndCFrame
end