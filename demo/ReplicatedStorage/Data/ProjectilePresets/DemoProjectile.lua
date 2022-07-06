--[[
TheNexusAvenger

Demo projectile preset.
--]]

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
    OnHitClient = function(Part, Position, Projectile)
        print("Projectile hit "..tostring(Part).." at position "..tostring(Position).." using projectile "..tostring(Projectile).." on the client")
    end,
    OnHitServer = function(Part, Position, Projectile)
        print("Projectile hit "..tostring(Part).." at position "..tostring(Position).." using projectile "..tostring(Projectile).." on the server")
    end,
}