--Demo projectile preset.
--!strict

return {
    Speed = 500,
    LifetimeSeconds = 5,
    Appearance = {
        LengthStuds = 50,
        Diameter = 0.1,
        Properties = {
            BrickColor = BrickColor.new("Bright blue"),
            Material = Enum.Material.Neon,
        },
    },
    DefaultFireSound = "Demo.Fire",
    DefaultReloadSound = "Demo.Reload",
    OnHitClient = function(Part: BasePart, Position: Vector3, Projectile: any)
        print(`Projectile hit {Part} at position {Position} using projectile {Projectile} on the client`)
    end,
    OnHitServer = function(Part: BasePart, Position: Vector3, Projectile: any)
        print(`Projectile hit {Part} at position {Position} using projectile {Projectile} on the server`)
    end,
}