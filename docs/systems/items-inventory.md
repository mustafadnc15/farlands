# System — Items, Inventory, Crafting, Tools

**Owner:** `items` · **Code:** `res://items/`, data in `res://content/items/`, `res://content/recipes/` · **Depends on:** net, contracts · **Milestone:** M2

## Purpose

Everything about items as data and as things you hold: defs, stacks, the inventory component's replication, ground drops,
crafting, tool durability. The list of actual items is in [content/item-catalog.md](../content/item-catalog.md).

## Inventory model

- Slot = `{id: StringName, count: int, durability: int}` or empty. Stack limit from `ItemDef.max_stack`; tools never stack.
- Player: 24 slots (first 6 = hotbar) + 1 **carry** slot.
- **Bulky items** (`ItemDef.bulky`: log, stone block, plank bundle, carcass) cannot enter the backpack. They go to the carry slot
  (stack limit e.g. 3 logs) and are shown on the character's shoulder. This is what makes hauling — and hired carriers — matter.
- Storage chest: 30 slots, accepts bulky items too (it is a stockpile).
- Moves between slots/inventories are requests: `request_move(from_inv_entity, from_slot, to_inv_entity, to_slot, count)`.
  Host validates that the peer may access both inventories (own, or an opened storage within 4 m).

## Drops

`DropManager` holds drop records `{entity_id, item_id, count, durability, pos}`. Drops are picked up with `interact`
(bulky → carry slot, else backpack; rejected with a toast if full). Drops despawn after 2 in-game days, except death bags.
`drop_item` drops the equipped stack 1 m in front of the player.

## Crafting

- Recipes are `RecipeDef`s. Station `&""` = craft anywhere from the inventory screen; `&"workbench"` / `&"campfire"` require standing within 3 m of that completed piece.
- `request_craft(recipe_id)`: host checks station + inputs, removes inputs, waits `craft_time`, adds output (drops it if full).
- No recipe unlocking in v1: all recipes are visible; unavailable ones are greyed out.

## Tools

- A tool is an `ItemDef` with `ToolStats`. `power` scales damage to nodes/animals; `reach` and `swing_time` feed the player controller.
- Durability decreases by 1 per successful hit; at 0 the tool breaks (removed, toast, sound). No repair in v1 — craft or buy a new one.
- Wrong tool on a node does nothing (and costs no durability); the HUD shows the required tool icon.

## Networking

`Inventory` contents replicate from host to the owning client always, and to any client that currently has that storage open.
Drops replicate as record deltas (see [04-networking.md](../04-networking.md)).

## Save

Player inventories (in player block), drop records, storage contents (saved by `building` as part of the piece record, using `Inventory.to_dict()`).

## Acceptance

- [ ] Add/remove/move respect stack limits and are all-or-nothing where the contract says so.
- [ ] Bulky items only ever sit in carry slots or storage; carried stack is visible to others.
- [ ] Two players grabbing the same drop: exactly one gets it.
- [ ] Crafting consumes inputs exactly once even under spammed requests.
- [ ] Adding a new item + recipe is done with two `.tres` files and no code.
- [ ] Unit tests cover `Inventory` add/remove/has_all edge cases.

## Out of scope

Item quality/rarity, weight limits, repair, enchantments, recipe discovery.
