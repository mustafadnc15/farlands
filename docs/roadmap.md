# Roadmap

Each milestone is a **playable vertical slice** verified with two clients. Nothing from a later milestone starts
before its dependencies' contracts exist in `res://core/` — but agents inside a milestone work in parallel.
Art and audio run alongside from M1 using placeholders; M6 is the integration pass, not the start of art.

## M0 — Foundation (lead, then qa, world)

Sequential, small, done before any parallel work.

- Git repo, `.gitignore`, folder layout, `CLAUDE.md`.
- `project.godot`: autoloads, input map, physics layer names (contracts §3–4).
- `res://core/`: def classes, components, `Events`, `Registry`, `Entities`, placeholders (capsule character, box item, box piece).
- `main.tscn` / `game.tscn` skeleton with `World` and empty manager slots.
- Test harness + headless run script ([qa-testing.md](qa-testing.md)).
- Grey-box island with markers and spawn point.

**Gate:** project opens with no errors; `Registry` loads a sample item; test runner passes; a capsule can stand on the island.

## M1 — Walk together

Parallel: `net`, `player`, `ui` (menu, pause, chat). Art: `art-characters` starts the settler rig.

**Gate:** host creates a world, a second instance joins by IP, both walk/jump/see each other, chat works, late join and leave are clean.

## M2 — Survive & gather

Parallel: `items`, `survival`, `world` (nodes + clock), `ui` (HUD, inventory). Art: tools, materials, trees, rocks.

**Gate:** chop trees, mine rocks, pick up and carry logs, craft stone tools, get hungry, eat berries, die and respawn, day turns to night — all synced.

## M3 — Build

Parallel: `building`, `save`, `ui` (build menu, storage). Art: build pieces (route B, exact dimensions).

**Gate:** two players build a small house together from blueprints, store items in a chest, set a bed; host saves, quits, reloads, client rejoins — everything is still there.

## M4 — Farm & trade

Parallel: `farming`, `economy`, `ui` (trade), `npc` (merchant body only). Art: crops, stall, merchant.

**Gate:** till, plant, water, harvest over several days; sell the harvest; buy seeds and an iron tool; stock resets daily.

## M5 — Colony

Parallel: `npc` (workers, wildlife AI, navigation), `world` (fishing, wildlife spawning), `ui` (worker radial). Art: animals, worker variants.

**Gate:** hire three workers; one fishes, one hunts, one hauls logs to blueprints; they deliver to storage, get paid daily, strike when unpaid; new buildings do not trap them.

## M6 — Look & feel

Parallel: all art agents (swap every placeholder), `audio`, `world` + `art-environment` (island dressing), `ui` (theme polish), `qa` (soak tests, performance).

**Gate:** no placeholder visible; all sounds in; 4 players + 8 workers + 3,000 pieces at 60 fps on the target PC; one-hour 4-player session with no errors.

## Parallelism map

```
M0  lead ─────────► (everything)
M1  net ║ player ║ ui                      art-characters ─────────────────────────►
M2  items ║ survival ║ world ║ ui          art-props ──────────────────────────────►
M3  building ║ save ║ ui                   art-props (pieces) ─────────────────────►
M4  farming ║ economy ║ ui ║ npc(merchant) art-environment ────────────────────────►
M5  npc ║ world ║ ui
M6  art-* ║ audio ║ ui ║ qa
```

`qa` joins at every gate. `lead` merges, resolves change requests, and updates the status board in [INDEX.md](INDEX.md).

## After v1 (parked — see decisions.md)

Internet relay/Steam lobbies, controller support, NPC farmers and woodcutters, more crops and pieces, weather, a second island, light story.
