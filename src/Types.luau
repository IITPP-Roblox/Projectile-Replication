--Types used by the system.
--!strict

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
    ProjectilePart: BasePart?,
    OnHit: RBXScriptSignal,
    OnHitEvent: BindableEvent,
    Source: Instance?,
    RayCast: (Vector3, Vector3, {Instance}?) -> (BasePart?, Vector3),
    Destroy: (Projectile) -> (),
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
    GamepadVibrationMotor: Enum.VibrationMotor?,
    GamepadVibrationMotorDuration: number?,
    GamepadVibrationMotorIntesity: number?,
}



return {}