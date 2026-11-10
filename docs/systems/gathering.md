# System — Gathering (resource nodes, fishing, hunting targets)

**Owner:** `world` · **Code:** `res://world/`, data in `res://content/nodes/`, `res://content/animals/` · **Depends on:** items, world-time · **Milestone:** M2 (nodes), M5 (fishing, wildlife)

## Purpose

The island's renewable resources: things you hit (trees, rocks, bushes), places you fish, and the stats of animals you hunt.
Animal *behaviour* (AI, movement) is implemented by `npc`; this system owns their defs and spawn rules.

## Resource nodes

`NodeManager` holds records `{entity_id, def_id, pos, rot, scale, hp, depleted_until_day}`. Initial records come from marker
nodes placed in the level (see [content/level-island.md](../content/level-island.md)); after first load the save is the truth.

| Node | Tool | HP | Drops | Respawn |
|------|------|----|-------|---------|
| `tree_small` | axe | 30 | log ×2, stick ×2 | 3 days |
| `tree_large` | axe | 60 | log ×4, stick ×3 | 5 days |
| `rock` | pickaxe | 50 | stone ×4 | 4 days |
| `ore_rock` | pickaxe (iron) | 80 | iron_ore ×2, stone ×2 | 6 days |
| `berry_bush` | none (interact) | — | berries ×3 | 2 days |
| `fibre_grass` | none (interact) | — | fibre ×2 | 1 day |
| `loose_stick`, `loose_stone` | none (interact) | — | stick ×1 / stone ×1 | 1 day |

- Damage per hit = `ToolStats.power` (stone axe 10, iron axe 20).
- Depleted nodes show a stump/rubble model and block nothing important; on respawn day they regrow **unless a build piece overlaps the spot**, in which case the node is removed for good. This lets players clear land permanently.
- Drops spawn around the node via `DropManager.spawn_drop`.

## Fishing

- Fishing spots are marker areas in water (pond, shore). With the rod equipped and targeting water inside a spot: `use_tool` casts.
- Host rolls a bite after 4–12 s; client sees the bobber dip and must press `use_tool` within 1.5 s → `request_reel`. Success gives one fish from the spot's table (`fish_small` 70 %, `fish_large` 30 %).
- Spear in shallow water (< 0.6 m) on a visible fish shadow: instant catch on hit (skill alternative, no rod needed).
- Each spot has a daily catch cap (default 12) reset on `day_started`, so workers and players share it.

## Wildlife

| Animal | Health | Behaviour | Drops (as bulky `carcass_*`, butchered at campfire/workbench) |
|--------|--------|-----------|------|
| `rabbit` | 10 | flees | raw_meat ×1, hide ×1 |
| `deer` | 40 | flees fast | raw_meat ×3, hide ×2 |
| `boar` | 60 | charges when hit or approached < 4 m (15 damage) | raw_meat ×4, hide ×2 |

Spawn rule (host): keep each zone at its target population, spawn out of sight (> 40 m from any player) at dawn, cap 20 alive.
Spear: melee thrust (`use_tool`) or throw (`alt_use`, hold to aim; the spear becomes a drop where it lands).

## Networking

Node state via record deltas (`sync_node_hp`, `sync_node_depleted`, `sync_node_respawned`). Fishing is request/response with the host. Animals replicate as NPC entities.

## Save

Node records, per-spot remaining catches, alive animals (def, pos, health).

## Acceptance

- [ ] Correct tool damages; wrong tool does nothing; hit feedback on all peers.
- [ ] Depletion, drops, and respawn after the right number of days; building over a stump prevents regrowth.
- [ ] Fishing loop works for host and client; daily cap enforced across players and workers.
- [ ] Animals spawn within budget, never in view; hunting yields a carcass that must be carried.
- [ ] 1,500 nodes load and render within budget (instanced rendering for unhit nodes).

## Out of scope

Mining underground, tree physics/felling direction, animal breeding/taming, bait types.
