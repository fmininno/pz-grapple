# PZ-Grapple — Grappling Hook Resource

Standalone FiveM resource that adds a grappling hook mechanic. Built on **ESX Legacy**, **ox_lib**, and **PZFX** conventions.

---

## Features

- **Raycast targeting** — aim with a weapon, press `E` to fire the hook at the hit point
- **Rope physics** — visual rope connects player to target; player is pulled along it
- **Animation** — superhero-style flying animation while grappling
- **Synced visuals** — other nearby players see the rope and animation
- **Permission system** — optional Discord role gate via `DiscordAPI` resource
- **Configurable** — keybind, distance, delay, animation, UI text

---

## Dependencies

| Resource | Purpose |
|----------|---------|
| `es_extended` | ESX Legacy (shared object, locale) |
| `ox_lib` | Keybinds, callbacks, notifications, TextUI |
| `DiscordAPI` (optional) | Role-based permission check (`Config.DiscordAPI = true`) |

> **Note:** `pzfx` is **not** required. This is a standalone script.

---

## Installation

1. Place the folder in your resources directory:
   ```
   resources/[standalone]/pz-grapple/
   ```
2. Ensure dependencies are started **before** `pz-grapple` in `server.cfg`:
   ```cfg
   ensure es_extended
   ensure ox_lib
   ensure DiscordAPI      # only if Config.DiscordAPI = true
   ensure pz-grapple
   ```
3. No SQL migrations required.

---

## Configuration (`cfg_grapple.lua`)

```lua
Config = {}

Config.Debug       = true           -- prints to server/client console
Config.DiscordAPI  = false          -- enable Discord role check
Config.DiscordRole = "Tester"       -- role name in DiscordAPI
Config.Key         = "Z"            -- default keybind (see Config.Keys table)
Config.EventOnly   = false          -- if true, no keybind; use exports/events only
Config.Delay       = 200            -- ms before pull starts (rope wind-up)
Config.MaxDistance = 9999           -- max raycast distance

Config.TextOpt = {
    position = "top-center",
    icon = 'circle-info',
    style = {
        borderRadius = 5,
        backgroundColor = '#000000',
        color = 'white'
    },
}

Config.Anim = {
    dict = 'kp_wmtg_superhero_fly_fwd',
    name = 'kp_wmtg_superhero_fly_fwd_clip',
    duration = -1
}
```

### Keybind Values
`Config.Key` must match a key in `Config.Keys` (GTA control hashes). Common defaults:

| Key | Hash |
|-----|------|
| `Z` | 20 |
| `E` | 38 |
| `G` | 47 |
| `X` | 73 |
| `LEFTALT` | 19 |

---

## Usage

### Default (Keybind)
1. Hold a weapon and aim (`RIGHT CLICK` / `LEFT ALT`).
2. Press the configured key (default `Z`).
3. A crosshair + TextUI `[E] to grappling` appears.
4. Aim at a surface/entity and press `E` to fire.
5. Player is pulled to the hit point with rope visual.

### Cancel
- Press `X` (control 73) or `BACKSPACE` (177) while aiming to cancel.

### Event-Only Mode (`Config.EventOnly = true`)
Disables the keybind. Trigger from another script:

```lua
-- Client-side
TriggerEvent('pz-grapple:client:start')  -- starts the aiming phase

-- Or export (if you add one)
exports['pz-grapple']:StartGrapple()
```

---

## Events

### Client → Server
| Event | Payload | Description |
|-------|---------|-------------|
| `pz-grapple:start:sync` | `{ coords = vector3 }` | Sent when player fires hook; broadcasts to nearby players |

### Server → Client
| Event | Payload | Description |
|-------|---------|-------------|
| `pz-grapple:start:syncC` | `targetSrc (serverId), params` | Received by clients within 100 units; spawns rope + anim on target player |

### Callbacks
| Callback | Server → Client | Description |
|----------|-----------------|-------------|
| `pz-grapple:perm` | `source` | Returns `true` if player has `Config.DiscordRole` (requires `DiscordAPI`) |

---

## Sync & Visuals

- **Rope**: Created client-side on each observer via `AddRope` + `AttachEntitiesToRope`.
- **Target object**: Invisible `prop_cs_dildo_01` placed at hit coords as rope anchor.
- **Animation**: `Config.Anim.dict/name` played on the grappling player.
- **Range**: Only players within **100 units** of the grappler receive the sync event (see `server/grapple.lua:9`).

> **Performance**: Rope cleanup runs on arrival (`DeleteRope`, `DeleteObject`, `StopAnimTask`).

---

## Discord Permission Setup (Optional)

1. Install [RickyBhatti/DiscordAPI](https://github.com/RickyBhatti/DiscordAPI).
2. Configure `DiscordAPI` with your bot token & guild ID.
3. Set in `cfg_grapple.lua`:
   ```lua
   Config.DiscordAPI  = true
   Config.DiscordRole = "YourRoleName"
   ```
4. Players without the role cannot activate the grapple (keybind does nothing).

---

## Customization

### Change Animation
Replace `Config.Anim` with any valid anim dict/name:
```lua
Config.Anim = {
    dict = 'move_jump',
    name = 'jump_fall',
    duration = -1
}
```
Use `LoadAnimDict` in `client/grapple.lua:309` — ensure dict exists.

### Adjust Pull Speed
In `client/grapple.lua:256–282`, the loop moves player `1.0` unit per `20ms` (`direction * 1`). Change the multiplier or `Wait(20)` for speed.

### Rope Appearance
`AddRope` parameters (line 213–221):
```lua
AddRope(
    pedPos.x, pedPos.y, pedPos.z + 0.5,  -- start coords
    0.0, 0.0, 0.0,                       -- rotation
    length,                              -- max length
    5, 5.0, 5.0, 0.0,                    -- rope type, min length, max length, ...
    false, false, true,                  -- collision flags
    5.0,                                 -- break strength
    false, nil                           -- ...
)
```
See FiveM `AddRope` native docs for flags.

---

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Keybind doesn't work | `Config.Key` not in `Config.Keys` | Use a valid key name from the table |
| "You have to aim with the weapon!" | Player not aiming (`IsPlayerFreeAiming` false) | Hold right-click / left-alt before pressing `E` |
| Rope not visible to others | Sync range too small | Increase `distance < 100` in `server/grapple.lua:9` |
| Permission always false | `DiscordAPI` not started or role name mismatch | Check `DiscordAPI` resource logs; verify role name exactly |
| Player stuck in air | Ground check failed | `nextCoords` fallback handles this; ensure map collision loaded |

---

## File Structure

```
pz-grapple/
├── fxmanifest.lua
├── cfg_grapple.lua
├── config.lua              -- (referenced in manifest, create if needed)
├── client/
│   └── grapple.lua         -- main client logic
└── server/
    ├── grapple.lua         -- sync broadcast
    └── perm.lua            -- Discord permission callback
```

---

## License / Credits

- Author: **PZ-DEV**
- Framework: **PZFX** conventions (standalone)
- Rope mechanics: Native `AddRope` / `AttachEntitiesToRope`
- Animation: `kp_wmtg_superhero_fly_fwd` (requires `kp_wmtg` DLC or custom pack)

---

## Support

For issues, check:
1. `Config.Debug = true` → read client/server console
2. `ox_lib` version ≥ latest
3. `es_extended` Legacy branch
4. No conflicting keybinds on same control