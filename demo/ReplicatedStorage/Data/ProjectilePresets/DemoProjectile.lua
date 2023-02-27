--[[
TheNexusAvenger

Demo projectile preset.
--]]
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
        print("Projectile hit "..tostring(Part).." at position "..tostring(Position).." using projectile "..tostring(Projectile).." on the client")
    end,
    OnHitServer = function(Part: BasePart, Position: Vector3, Projectile: any)
        print("Projectile hit "..tostring(Part).." at position "..tostring(Position).." using projectile "..tostring(Projectile).." on the server")
    end,
}