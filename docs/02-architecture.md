# 02 — Architecture

## Principles

- **Composition over inheritance.** Behaviour lives in small component nodes (`HealthComponent`, `Inventory`, `Interactable`) added to entities.
- **Data-driven content.** Definitions are `Resource` files loaded by `Registry`. Code handles kinds of things; data lists the things.
- **Managers own collections.** Anything that exists in the hundreds (build pieces, resource nodes, crops) is owned by one manager that holds the authoritative records, replicates them, and saves them.
- **Server-authoritative.** The host runs the simulation. See [04-networking.md](04-networking.md).
- **Signals up, calls down.** Children emit signals; parents call methods. Cross-system notifications go through the `Events` bus.

## Folder layout

```
res://
  project.godot            (lead)
  main/                    (lead)   main.tscn, boot, menu flow
  core/                    (lead)   autoloads, components, def classes, placeholders
    autoload/              Events, Registry, Net facade hooks, Entities
    components/            HealthComponent, Inventory, Interactable, ...
    defs/                  ItemDef, RecipeDef, PieceDef, CropDef, NodeDef, AnimalDef, JobDef, TradeDef
    placeholders/          grey-box meshes/scenes
  net/                     (net)    session, transport, spawning, join snapshot
  player/  survival/  items/  world/  farming/  building/  npc/  economy/  ui/  save/  audio/
  content/                 data only (.tres), one subfolder per def type
    items/ recipes/ pieces/ crops/ nodes/ animals/ jobs/ trades/
  assets/                  art + audio source, no scripts
    characters/ environment/ props/ audio/
  levels/                  island.tscn and its sub-scenes
  tests/                   one subfolder per system
docs/
```

Each system folder is laid out the same way: `<system>_manager.gd` (if it has one), scenes, scripts, and a `README.md` only if something is non-obvious.

## Autoloads (complete list — adding one requires `lead`)

| Name | Owner | Role |
|------|-------|------|
| `Events` | lead | Global signal bus. Signals only, no state. |
| `Registry` | lead | Loads every def under `res://content/` at boot; lookup by id. |
| `Entities` | lead | Maps network-stable `entity_id: int` ↔ node. |
| `Net` | net | Session (host/join/leave), peer list, helpers like `Net.is_host()`, `Net.sender_id()`. |
| `WorldClock` | world | Day/night time, day counter. |
| `SaveGame` | save | Save/load orchestration. |
| `AudioDirector` | audio | Plays SFX/music in response to `Events`. |

Gameplay managers (`BuildManager`, `FarmManager`, `NodeManager`, `NpcManager`, `Economy`) are **not** autoloads.
They are nodes under `World/Managers` in the game scene, found through `World.get_manager(&"build")` (see contracts). This keeps them out of the menu and makes a session easy to tear down.

## Scene tree (in a running session)

```
Main (main.tscn)
├─ Menu (CanvasLayer)                     shown when no session
└─ Game (game.tscn, instanced on host/join)
   ├─ World (world.gd)                    get_manager(), references
   │  ├─ Level (levels/island.tscn)       terrain, road, merchant stall, static props
   │  ├─ Managers
   │  │  ├─ NodeManager   (world)         trees, rocks, bushes, fishing spots
   │  │  ├─ BuildManager  (building)
   │  │  ├─ FarmManager   (farming)
   │  │  ├─ NpcManager    (npc)           workers + wildlife
   │  │  ├─ DropManager   (items)         item drops on the ground
   │  │  └─ Economy       (economy)
   │  ├─ Players                          MultiplayerSpawner target
   │  ├─ Npcs                             MultiplayerSpawner target
   │  └─ Dynamic                          drops, effects
   └─ UI (CanvasLayer, ui)                HUD, inventory, build menu, trade, pause
```

## Data flow example — chopping a tree

1. Local player presses `use_tool`. `player` plays the swing locally and sends `request_use_tool(target_entity_id)` to the host.
2. Host validates (distance, tool equipped, cooldown) and calls `NodeManager.apply_hit(entity_id, tool_def, player_id)`.
3. `NodeManager` reduces the node's hit points; on zero it marks it depleted, asks `DropManager` to spawn `log × 3`, and replicates the state change to all peers.
4. All peers play the fall effect; `Events.node_depleted` fires; `AudioDirector` plays a sound.
5. `WorldClock` day ticks later trigger regrowth on the host.

No system referenced another system's internals: only `Registry` data, manager APIs, and `Events`.

## Performance budgets (targets on a mid-range PC, 60 fps)

| Thing | Budget |
|-------|--------|
| Players | 4 |
| Hired NPCs | 8 per world |
| Wildlife alive | 20 |
| Build pieces | 5,000 (render via instancing/MultiMesh above ~1,000) |
| Resource nodes | 1,500 |
| Network | ≤ 20 state updates/s per moving entity, ≤ 64 kbit/s per client in normal play |
| Triangles on screen | ≤ 500k |

## Error handling

- Invalid client request → host ignores it and logs once at `push_warning` level. Never crash, never trust.
- Missing def id → `Registry` returns `null` and logs an error; callers must handle `null`.
- Version mismatch on join → refuse connection with a clear message.
