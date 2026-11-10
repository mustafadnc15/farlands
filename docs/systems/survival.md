# System — Survival

**Owner:** `survival` · **Code:** `res://survival/` · **Depends on:** player, items · **Milestone:** M2

## Purpose

Health and hunger, eating, damage sources, death and respawn. Gentle pressure that gives food a purpose.

## Behaviour (starting values, all tunable via exports)

| Stat | Max | Rule |
|------|-----|------|
| Health | 100 | Regenerates 1/s when hunger > 50 and no damage for 10 s |
| Hunger | 100 | Drains 100 → 0 over 2 in-game days (faster ×1.5 while sprinting or swinging tools) |

- Hunger 0: lose 1 health every 3 s until fed. Hunger ≤ 20: HUD warning.
- **Eating:** `use_tool` with a food item equipped, or from the inventory UI → `request_eat(slot)`. Host removes one item, adds `food_hunger` / `food_health` from its `ItemDef`.
- **Damage sources:** starvation, fall (> 6 m: 10 damage per extra metre), boar attack, drowning is not modelled.
- **Death:** player drops the whole inventory and carry slot as one "bag" drop at the death spot, then respawns after 5 s at their bed (if claimed) or the island spawn point with 50 health / 50 hunger.
- **Sleeping:** interacting with a bed claims it as respawn point. If all online players are in beds at night, the clock skips to morning.

`HungerComponent` (owned by this system, added to the player scene by change request):

```gdscript
class_name HungerComponent extends Node
  var max_hunger: float ; var hunger: float
  func feed(amount: float) -> void     # host only
  signal changed(hunger: float, max_hunger: float)
```

## Networking

Host simulates drain, regen and damage. `health` and `hunger` replicate to the owning client; `health` also to others (for name-plate bars).

## Save

Per player: health, hunger, bed entity_id. Stored in the player block (see [save-load.md](save-load.md)).

## Acceptance

- [ ] Hunger drains at the documented rate; eating restores per item data.
- [ ] Starvation damages, never below-zero values, death triggers once.
- [ ] Death drops a bag another player can loot; respawn at bed or spawn.
- [ ] All players sleeping skips the night; one awake player prevents it.
- [ ] A client cannot heal or feed itself by sending forged requests (no item → rejected).

## Out of scope

Stamina, thirst, temperature, illness, buffs, armour.
