--Configuration for the gun.
--This should be the only script that is modified for an individual gun.
--!strict

return {
    --Name of the preset of the projectile.
    --The preset must exist in ReplicatedStorage.Data.ProjectilePresets.
    ProjectilePreset = "DemoProjectile",

    --Maximum random angle from the aim that the projectile will fire from.
    ProjectileSpread = math.rad(2),

    --Delay time between activating the gun and firing.
    --If nil, no delay will be used.
    FireDelay = nil,

    --Time between firing projectiles.
    CooldownTime = 0.075,

    --Time requires to reload the gun.
    ReloadTime = 2,

    --If true, the user is able to hold down their activation input instead of spamming it.
    FullAutomatic = true,

    --Projectiles to fire for each round.
    ProjectilesPerRound = 1,

    --Total rounds that can be fired between reloads.
    TotalRounds = 50,

    --Sound played when firing.
    --If nil, the default in the projectile preset will be used.
    FireSound = nil,

    --Sound played when reloading.
    --If nil, the default in the projectile preset will be used.
    ReloadSound = nil,

    --Additional rotation applied to aiming.
    --If nil, no additional rotation will be applied.
    AimRotationOffset = CFrame.Angles(0, math.rad(-50), 0),

    --Joints that are set when aiming.
    --If nil, no joints will be changed.
    AnimationJoints = {
        Head = {
            Neck = CFrame.Angles(0, math.rad(50), 0),
        },
        RightUpperArm = {
            RightShoulder = CFrame.Angles(0, math.rad(65), 0) * CFrame.Angles(math.rad(10), 0, 0),
        },
        RightLowerArm = {
            RightElbow = CFrame.Angles(math.rad(85), 0, 0),
        },
        RightHand = {
            RightWrist = CFrame.Angles(0, math.rad(10), 0) * CFrame.Angles(0, 0, math.rad(15)) * CFrame.Angles(math.rad(-10), 0, 0),
        },
    },

    --The time in seconds to charge down the gun.
    --If nil, charging up and down will not be done.
    ChargeUpTime = nil,

    --The time in seconds to charge down the gun.
    --If nil, charging up and down will not be done.
    ChargeDownTime = nil,

    --The time in seconds to charge down the gun.
    --If nil, no charge motor will be used.
    ChargeMaxMotorSpeed = nil,

    --Gamepad vibration motor activated when fired.
    GamepadVibrationMotor = Enum.VibrationMotor.Large,
    GamepadVibrationMotorDuration = 0.1,
    GamepadVibrationMotorIntesity = 0.5,
}