--Update loop for all current projectiles.
--!strict

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Types = require(script.Parent:WaitForChild("Types"))

local ProjectileUpdateLoop = {
    ActiveProjectiles = {} :: {ProjectileState},
}

export type ProjectileUpdateLoop = typeof(ProjectileUpdateLoop)
export type InputProjectileState = {
    Projectile: Types.Projectile,
    Speed: number,
    StartCFrame: CFrame,
    MaxLifetime: number,
    ExtraProjectileLength: number,
    ProjectileDiameter: number,
    IgnoreList: {Instance}?,
}
type ProjectileState = {
    Projectile: Types.Projectile,
    Speed: number,
    StartCFrame: CFrame,
    StartTime: number,
    EndTime: number,
    LastUpdateTime: number,
    ExtraProjectileLength: number,
    LastProjectileLength: number,
    ProjectileDiameter: number,
    WasHit: boolean,
    IgnoreList: {Instance}?,
}



--[[
Updates all the stored projectiles.
--]]
function ProjectileUpdateLoop.Update(self: ProjectileUpdateLoop): ()
    --Update the projectiles.
    debug.profilebegin("ProjectileReplicationUpdate")
    local NewTime = tick()
    local IsClient = RunService:IsClient()
    local BulkMoveParts, BulkMoveCFrames = table.create(#self.ActiveProjectiles), table.create(#self.ActiveProjectiles)
    for i = #self.ActiveProjectiles, 1, -1 do
        --Determine the end position and hit.
        local ActiveProjectile = self.ActiveProjectiles[i]
        local Projectile = ActiveProjectile.Projectile
        local Speed = ActiveProjectile.Speed
        local StartCFrame = ActiveProjectile.StartCFrame
        local StartTime = ActiveProjectile.StartTime
        if not ActiveProjectile.WasHit then
            local PreviousEndPosition = (StartCFrame * CFrame.new(0, 0, -Speed * (ActiveProjectile.LastUpdateTime - StartTime))).Position
            local NewEndPosition = (StartCFrame * CFrame.new(0, 0, -Speed * (NewTime - StartTime))).Position
            local HitPart, HitEndPosition = Projectile.RayCast(PreviousEndPosition, NewEndPosition, ActiveProjectile.IgnoreList)
            if HitPart then
                ActiveProjectile.WasHit = true
                ActiveProjectile.EndTime = StartTime + ((HitEndPosition - StartCFrame.Position).Magnitude / Speed)
                Projectile.OnHitEvent:Fire(HitPart, HitEndPosition, Projectile)
            end
        end

        --Update the part.
        local ProjectilePart = Projectile.ProjectilePart
        if ProjectilePart then
            --Calculate the projectile physical properties.
            local ExtraProjectileLength = ActiveProjectile.ExtraProjectileLength
            local ProjectileDiameter = ActiveProjectile.ProjectileDiameter
            local ProjectileStartPosition = (StartCFrame * CFrame.new(0, 0, -Speed * math.max(0, NewTime - StartTime - ExtraProjectileLength))).Position
            local ProjectileEndPosition = (StartCFrame * CFrame.new(0, 0, -Speed * math.min(ActiveProjectile.EndTime - StartTime, NewTime - StartTime))).Position
            local ProjectileLength = (ProjectileEndPosition - ProjectileStartPosition).Magnitude
            
            --Store the CFrame to set in bulk.
            if IsClient then
                table.insert(BulkMoveParts, ProjectilePart)
                table.insert(BulkMoveCFrames, CFrame.new(ProjectileStartPosition, ProjectileEndPosition) * CFrame.new(0, 0, -ProjectileLength / 2) * CFrame.Angles(0, math.pi / 2, 0))
            end

            --Set the size if it has changed.
            if math.abs(ActiveProjectile.LastProjectileLength - ProjectileLength) > 0.001 then
                ProjectilePart.Size = Vector3.new(ProjectileLength, ProjectileDiameter, ProjectileDiameter)
            end
            ActiveProjectile.LastProjectileLength = ProjectileLength
        end

        --Store the last update time.
        ActiveProjectile.LastUpdateTime = NewTime

        --Remove the projectile if it is past the end time.
        if NewTime >= ActiveProjectile.EndTime + ActiveProjectile.ExtraProjectileLength then
            Projectile:Destroy()
            table.remove(self.ActiveProjectiles, i)
        end
    end
    debug.profileend()

    --Move the projectile parts.
    if IsClient and #BulkMoveParts > 0 then
        debug.profilebegin("ProjectileReplicationBulkMoveTo")
        Workspace:BulkMoveTo(BulkMoveParts, BulkMoveCFrames)
        debug.profileend()
    end
end

--[[
Adds a projectile to update.
--]]
function ProjectileUpdateLoop.AddProjectile(self: ProjectileUpdateLoop, ProjectileData: InputProjectileState): ()
    local StartTime = tick()
    table.insert(self.ActiveProjectiles, {
        Projectile = ProjectileData.Projectile,
        Speed = ProjectileData.Speed,
        StartCFrame = ProjectileData.StartCFrame,
        StartTime = StartTime,
        EndTime = StartTime + ProjectileData.MaxLifetime,
        LastUpdateTime = StartTime,
        ExtraProjectileLength = ProjectileData.ExtraProjectileLength,
        ProjectileDiameter = ProjectileData.ProjectileDiameter,
        WasHit = false,
        IgnoreList = ProjectileData.IgnoreList,
        LastProjectileLength = 0,
    })
end



--Start the update loop.
RunService.Stepped:Connect(function()
    ProjectileUpdateLoop:Update()
end)



return ProjectileUpdateLoop
