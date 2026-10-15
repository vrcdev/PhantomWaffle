# PhantomWaffle

click-gui cheat for Phantom Forces.

## Execute

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/vrcdev/PhantomWaffle/main/loader.luau"))()
```

## Features

- silent aim (real client-authoritative hits via `networkClient.send` — bullets report their own hit, so wallbang is native)
- hit chance slider, bone select, fov, wall check, wallbang toggle
- camera aim with smoothing
- esp: boxes, names, distance, skeleton, tracers, offscreen arrows, team check
- Delete = toggle menu, End = unload
- config save/load: `pf_cfg.json`

## Files

- `loader.luau` — fetches + dispatches
- `pf_actor.luau` — runs in the shared.require actor; hooks `NetworkClient.send` (rewrites `newbullets` trajectories, forges `bullethit`) and mirrors replication entries to workspace attributes
- `click_phantom.luau` — main env payload: click gui, esp, target picking
