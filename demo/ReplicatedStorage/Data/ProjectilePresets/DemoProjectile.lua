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
    OnHitClient = function(Part, Position, Bullet)
        print("Bullet hit "..tostring(Part).." at position "..tostring(Position).." using bullet "..tostring(Bullet).." on the client")
    end,
    OnHitServer = function(Part, Position, Bullet)
        print("Bullet hit "..tostring(Part).." at position "..tostring(Position).." using bullet "..tostring(Bullet).." on the server")
    end,
}