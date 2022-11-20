--[[
TheNexusAvenger

Types used by the system.
--]]

export type ProjectileAppearance = {
    LengthStuds: number?,
    Diameter: number?,
    Properties: {[string]: any}?,
}

export type ProjectilePreset = {
    Speed: number,
    LifetimeSeconds: number,
    DefaultFireSound: string?,
    DefaultReloadSound: string?,
    Appearance: ProjectileAppearance?,
    OnFireClient: (Projectile) -> ()?,
    OnFireServer: (Projectile) -> ()?,
    OnHitClient: (BasePart, Vector3, Projectile) -> ()?,
    OnHitServer: (BasePart, Vector3, Projectile) -> ()?,
}

export type Projectile = {
    OnHit: RBXScriptSignal,
    Source: Instance?,
    RayCast: (Vector3, Vector3, {Instance}?) -> (BasePart?, Vector3),
    new: (ProjectileAppearance) -> Projectile,
    Fire: (Projectile, CFrame, number, number, {Instance}?) -> (),
    Destroy: () -> (),
}

export type StandardConfiguration = {
    ProjectilePreset: string,
    ProjectileSpread: number,
    FireDelay: number,
    CooldownTime: number,
    ReloadTime: number,
    FullAutomatic: boolean,
    ProjectilesPerRound: number,
    TotalRounds: number,
    FireSound: string?,
    ReloadSound: string?,
    AimRotationOffset: CFrame?,
    AnimationJoints: {[string]: {[string]: CFrame}},
    ChargeUpTime: number?,
    ChargeDownTime: number?,
}



return {}