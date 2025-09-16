# Projectile-Replication
Projectile Replication is the system used and developed by
[Innovation Inc Thermal Power Plant on Roblox](https://www.roblox.com/games/2337178805/Innovation-Inc-Thermal-Power-Plant)
to manage disinfectors.

# Setup
## Project
This project uses [Rojo](https://github.com/rojo-rbx/rojo) for the project
structure. Four project files in included in the repository.
* `default.project.json` - Structure for just the module within Wally projects.
* `default-standalone.project.json` - Structure for just the module to
  be published as a standalone module outside of Wally.
* `demo.project.json` - Full Roblox place that can be synced into Roblox
  studio and ran with demo models.
* `demo-standalone.project.json` - Full Roblox place that can be synced
  into Roblox studio and ran with demo models, but with the standalone
  module setup.

To set up the project dependencies with types:
```bash
wally install
rojo sourcemap demo.project.json --output sourcemap.json
wally-package-types --sourcemap sourcemap.json Packages/
```

## Game
Compared to [LocalAudio](https://github.com/IITPP-Roblox/LocalAudio) and
[LocalTween](https://github.com/IITPP-Roblox/LocalTween), this system is a
lot more involved to set up.

### Audio (Optional)
Projectile sounds use LocalAudio for playing sounds. See the
[setup for LocalAudio](https://github.com/IITPP-Roblox/LocalTween#readme)
for how to add sounds.

### Projectile Presets
The projectiles in the game are stored as data that define the properties and
behavior of the projectiles. At the moment, they are hard-coded to be
`MdouleScript`s under `ReplicatedStorage.Data.ProjectilePresets`. The
schema of the data for each preset is the following:
* `number Speed` - Speed that the projectile moves at.
* `number LifetimeSeconds` - The maximum lifetime of the projectile in seconds.
* `string? DefaultFireSound` - Optional sound id to play in `LocalAudio`
  when the projectile is fired from a source.
* `string? DefaultReloadSound` - Optional sound id to play in `LocalAudio`
  when a weapon is reloaded.
* `ProjectileAppearance Appearance` - Appearance of the projectile, which
  is a table containing the following data:
  * `number? LengthStuds` - The length of the projectile in studs.
  * `number? Diameter` - Diameter of the projectile.
  * `{[string]: any}? Properties` - Additional properties to set. `Size`,
    `CFrame`, and `Parent` will be overwritten if set.

For an example, [see the demo projectile](./demo/ReplicatedStorage/Data/ProjectilePresets/DemoProjectile.lua).

### Server / Client Setup
In order to set up the replication on both the client and server,
`ProjectileReplication:SetUp()` needs to be invoked on both the
client and server.

### Standard Weapons (Optional)
For the Thermal Power Plant, a standard set of scripts are used for all
disinfectors. They are loaded using the helper [`Standard` module's](./src/Standard/init.lua)
`CreateStandardWeapon` method. In order to use it, the `Tool` must have
a `Handle`. The `Handle` must have an `Attachment` named `"StartAttachment"`
and optional `Attachment` for the left arm named `"LeftHandHold"`.
There also must be a `Configuration` like [the demo configuration](demo/ServerScriptService/DemoConfiguration.lua).

### Nexus VR Character Model (Optional)
The standard weapons support [Nexus VR Character Model](https://github.com/TheNexusAvenger/Nexus-VR-Character-Model).
Adding [the loader](https://www.roblox.com/library/1547146240/Nexus-VR-Character-Model)
to the game will make Nexus VR Character Model load when the game starts.

# Firing Projectiles Directly
In the case a projectile needs to be fired without using a standard
weapon, such as the turrets in the Innovation Inc Thermal Power Plant, use
`ProjectileReplication:Fire(StartCFrame: CFrame, FirePart: BasePart, PresetName: string): ()`.
The `StartCFrame` is the starting `CFrame` of the projectile with `FirePart`
being the source part. If `FirePart` has an `Attachment` named `StartAttachment`,
the attachment will be used for playing sounds. `PresetName` is the name of
the module storing the projectile data to use.

# Future Enhancements
Pull requests are open for future enhancements that could be made to the system.
They have been requested either internally or by members of the Innovation Inc
Thermal Plant Discord server.
* Generalized Animations - Animations are currently limited to the hold animation.
  Reload animations, aiming down scopes, and holding the weapon down for posing
  are not supported.
* Acceleration - Projectiles follow a straight path instead of accelerating due
  to gravity or other forces.

# License
This project is available under the terms of the MIT License. See [LICENSE](LICENSE)
for details.