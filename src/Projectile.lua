--[[
TheNexusAvenger

Controls the logic for projectiles.
--]]
--!strict

local Workspace = game:GetService("Workspace")

local ProjectileUpdateLoop = require(script.Parent:WaitForChild("ProjectileUpdateLoop"))
local ProjctileTypes = require(script.Parent:WaitForChild("Types"))

local Projectile = {}
Projectile.__index = Projectile



--[[
Static helper for casting rays.
--]]
function Projectile.RayCast(StartPosition: Vector3, EndPosition: Vector3, IgnoreList: {Instance}?): (BasePart?, Vector3)
    --Clone the ignore list.
    local NewIgnoreList = {}
    if IgnoreList ~= nil then
        for _, Ins in IgnoreList do
            table.insert(NewIgnoreList, Ins)
        end
    end

    --Cast rays until a valid part is reached.
    local RaycastResult = nil
    local RaycastParameters = RaycastParams.new()
    RaycastParameters.FilterType = Enum.RaycastFilterType.Exclude
    RaycastParameters.FilterDescendantsInstances = NewIgnoreList
    RaycastParameters.IgnoreWater = true
    repeat
        --Perform the raycast.
        RaycastResult = Workspace:Raycast(StartPosition, EndPosition - StartPosition, RaycastParameters)
        if not RaycastResult then
            break
        end
        if not RaycastResult.Instance then
            break
        end

        --Return the part and position if the part is valid.
        local HitPart = RaycastResult.Instance
        if (HitPart.Transparency <= 0.95 and HitPart.CanCollide) or HitPart.Parent:FindFirstChildOfClass("Humanoid") then
            return HitPart, RaycastResult.Position
        end

        --Add the hit to the ignore list and allow it to retry.
        table.insert(NewIgnoreList, HitPart)
        RaycastParameters.FilterDescendantsInstances = NewIgnoreList
    until RaycastResult == nil

    --Return the end position and no part.
    return nil, EndPosition
end

--[[
Creates a projectile.
--]]
function Projectile.new(Appearance: ProjctileTypes.ProjectileAppearance?): ProjctileTypes.Projectile
    --Create the object.
    local ProjectileObject = {
        Appearance = Appearance,
        ObjectsToDestroy = {},
    }
    setmetatable(ProjectileObject, Projectile)

    --Create the event for the projectile.
    ProjectileObject.OnHitEvent = Instance.new("BindableEvent")
    ProjectileObject.OnHit = ProjectileObject.OnHitEvent.Event
    table.insert(ProjectileObject.ObjectsToDestroy, ProjectileObject.OnHitEvent)

    --Return the event.
    return (ProjectileObject :: any) :: ProjctileTypes.Projectile
end

--[[
Fires the projectile.
--]]
function Projectile:Fire(StartCFrame: CFrame, Speed: number, MaxLifetime: number, IgnoreList: {Instance}?): ()
    local NewIgnoreList = IgnoreList or {}
    table.insert(NewIgnoreList, Workspace.CurrentCamera)

    --Create the projectile part.
    local ProjectilePart = nil
    if self.Appearance then
        ProjectilePart = Instance.new("Part")
        ProjectilePart.CastShadow = false
        ProjectilePart.CanCollide = false
        ProjectilePart.Anchored = true
        ProjectilePart.Shape = Enum.PartType.Cylinder
        ProjectilePart.CFrame = CFrame.new(0, math.huge, 0)
        if self.Appearance.Properties then
            for Name, Value in self.Appearance.Properties do
                (ProjectilePart :: any)[Name] = Value
            end
        end
        ProjectilePart.Parent = Workspace.CurrentCamera
        self.ProjectilePart = ProjectilePart
        table.insert(self.ObjectsToDestroy, ProjectilePart)
        table.insert(NewIgnoreList, ProjectilePart)
    end

    --Add the projectile to the loop.
    ProjectileUpdateLoop:AddProjectile({
        Projectile = self,
        Speed = Speed,
        StartCFrame = StartCFrame,
        MaxLifetime = MaxLifetime,
        ExtraProjectileLength = ((self.Appearance and self.Appearance.LengthStuds) or 0) / Speed,
        ProjectileDiameter = (self.Appearance and self.Appearance.Diameter) or 0.2,
        IgnoreList = IgnoreList,
    })
end

--[[
Destroys the Projectile.
--]]
function Projectile:Destroy(): ()
    for _, Object in self.ObjectsToDestroy do
        Object:Destroy()
    end
    self.ObjectsToDestroy = {}
end



return Projectile