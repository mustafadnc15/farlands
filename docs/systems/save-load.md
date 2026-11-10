# System — Save & Load

**Owner:** `save` · **Code:** `res://save/` (autoload `SaveGame`) · **Depends on:** save contract (contracts §11) · **Milestone:** M3

## Purpose

The world never ends, so it must persist. Only the **host** saves and loads; clients receive state through join snapshots.

## Format

`user://saves/<world_name>/world.json` (+ rotating backups `world.bak1.json` … `bak3`).

```json
{
  "format_version": 1,
  "game_version": "0.1.0",
  "saved_at": "2026-11-10T12:00:00Z",
  "world": { "<save_key>": { ... }, "clock": { ... }, "build": { ... } },
  "players": { "<player_id>": { "name": "...", "pos": [x,y,z], "inventory": {...}, "carry": {...},
                                "health": 100, "hunger": 80, "bed": 123 } },
  "next_entity_id": 4567
}
```

- JSON for debuggability. If the build block gets large, `save` may move it to a compressed sidecar file without changing the contract.
- Each manager owns the inside of its block; `save` never interprets it.

## Behaviour

- **Save triggers:** autosave every 5 real minutes, on host quit, on manual save from the pause menu, on `day_started`.
- **Save procedure:** collect `save_state()` from every node in group `saveable` → write to `world.tmp` → rotate backups → rename. Never leave a half-written `world.json`.
- **Load order:** clock → items/drops → nodes → build → farm → economy → npc → players. (Fixed list in `save_game.gd`; order matters because storages must exist before workers reference them.)
- `Entities` id counter is restored before anything loads; loaded records keep their saved `entity_id`.
- **Players:** stored by `player_id`. On join, a known player resumes where they left; unknown gets the starter kit. Offline players' data is kept.
- **Migrations:** `format_version` bump comes with a function `migrate_vN_to_vN+1(data)`. Managers must tolerate missing keys.
- **Failure:** unreadable save → try backups newest first → if all fail, show an error and do not overwrite anything.

## Acceptance

- [ ] Build, farm, hire, trade → save → quit → load: world is identical (automated round-trip test compares `save_state()` before and after).
- [ ] Killing the process during a save never corrupts the latest good save.
- [ ] A save from the previous milestone still loads.
- [ ] Autosave causes no visible hitch above 50 ms with 5,000 pieces (serialise across frames or on a thread).
- [ ] Rejoining client gets its old inventory and position.

## Out of scope

Cloud saves, save transfer between players, multiple save slots per world, replay.
