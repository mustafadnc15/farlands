# System — NPCs (hired workers, wildlife AI, merchant body)

**Owner:** `npc` · **Code:** `res://npc/`, data in `res://content/jobs/` · **Depends on:** items, building, gathering, economy, world-time · **Milestone:** M5

## Purpose

Simulated characters: the workers players hire, the animals they hunt, and the merchant standing at his stall.
Workers **fish, hunt, and carry**. They never build, craft, farm, or fight.

## Workers

- Hired at the merchant's stall (see [economy-merchant.md](economy-merchant.md)). Cap: 8 per world. Each has a random name and one of the character variants.
- Belong to the colony, not to one player: any player can command any worker.
- Have: `HealthComponent` (boars can hurt hunters; at 0 they return to the stall, "injured", for 1 day), a `carry` inventory (1 bulky stack) and a 4-slot pack.
- **Home storage:** each worker is assigned a `storage_chest` (default: nearest to where they were hired/commanded). Output goes there; tools and wages are not drawn from it.

### Commands (`interact` on a worker opens a small radial menu)

| Command | What the worker does |
|---------|----------------------|
| **Follow** | Walks behind the commanding player. |
| **Stay** | Idles at the current spot. |
| **Carry this** | (aim at a bulky drop or stockpile) Picks up bulky items and follows the player; `interact` again → "Drop here" or deliver to the blueprint/chest the player aims at. |
| **Haul to blueprints** | Loops: take needed materials from home storage → deliver to the nearest blueprint that needs them (`BuildManager.blueprints_needing` / `deliver`). Idles when nothing is needed. |
| **Fish** | Needs a fishing rod given to them (drag from inventory in the menu). Walks to the nearest fishing spot (or the one the player aims at), fishes at ~60 % of player rate, brings fish to home storage when the pack is full or at dusk. |
| **Hunt** | Needs a spear. Roams the nearest wildlife zone, hunts rabbit/deer (avoids boar unless iron spear), carries the carcass to home storage. |
| **Set home storage** | Aim at a chest to reassign. |
| **Dismiss** | Worker leaves the island; no refund. |

- Tools given to workers lose durability like players' tools; when a tool breaks the worker goes idle and shows a "needs tool" icon.
- At night workers walk to the campfire nearest their home storage and sit until morning.
- **Wages:** on each `day_started` the host calls `Economy.spend(wage × workers)`. If the colony cannot pay a worker, that worker goes on strike (idle, coin icon) until paid; after 3 unpaid days they leave.

### Implementation shape

- `CharacterBody3D` + `NavigationAgent3D`, host-simulated only. Clients get position/anim through a synchronizer.
- Behaviour = small state machine per job (`JobDef.behaviour_script`), states like `go_to`, `work`, `deliver`, `idle`. No behaviour-tree library needed in v1.
- Jobs call only contract APIs (`NodeManager`, `BuildManager`, storage `Inventory`), never internals.
- Think rate: decisions at 2 Hz, movement every physics frame; workers far (> 60 m) from all players may run simplified (teleport-step) simulation.

## Navigation

- `NavigationRegion3D` chunks (50 × 50 m) covering the island, baked from terrain at build time.
- When pieces complete or are removed, mark touched chunks dirty and rebake them asynchronously, debounced 2 s. Rebake on the host only.
- If no path exists (player walled something in), the worker idles with a "can't reach" icon instead of pushing through walls. Doors are passable for NPCs.

## Wildlife AI

States: `graze`, `wander`, `alert`, `flee`, (`charge` for boar), `dead`. Senses: sight cone 15 m, hearing 8 m (sprinting players). Stats come from `AnimalDef`.

## Merchant

A stationary NPC at the stall with idle/talk animations and an `Interactable` that opens the trade UI (owned by `economy` + `ui`). Present during the day; the stall is closed at night.

## Networking

Host authoritative for all NPCs. Spawn via `MultiplayerSpawner` under `World/Npcs`. Commands: `request_command(worker_entity_id, command, args)`.

## Save

Workers: `{entity_id, name, variant, job_id, command state, home_storage, pos, health, pack, carry, unpaid_days}`. Wildlife saved by `world`.

## Acceptance

- [ ] Each command works when issued by host and by client.
- [ ] Haul loop completes a blueprint from storage without player help.
- [ ] Fisher and hunter deliver output to home storage over a full day; respect fishing caps and wildlife budget.
- [ ] Workers path around new buildings within a few seconds of completion; never get permanently stuck (fallback: teleport to home storage after 30 s stuck).
- [ ] Wages, strike, and leaving behave as documented.
- [ ] 8 workers + 20 animals stay within CPU budget on the host.

## Out of scope

NPC building/crafting/farming, needs or moods, combat, conversations, relationships, housing requirements.
