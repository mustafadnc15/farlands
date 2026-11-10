# System — Building

**Owner:** `building` · **Code:** `res://building/`, data in `res://content/pieces/` · **Depends on:** items, net · **Milestone:** M3

## Purpose

The headline feature: build anything anywhere. Free placement with optional snapping, ghost blueprints that are
completed by hauling materials to them, as in *The Forest*.

## Player flow

1. `build_menu` opens the piece catalogue (categories below). Picking a piece enters **build mode** with a translucent ghost at the camera target.
2. Ghost follows the aim point on terrain or on other pieces. `rotate_piece_left/right` turns it in 15° steps (hold for smooth); scroll nudges height ±0.1 m within limits.
3. **Snapping** (toggle with `toggle_snap`, on by default): if a snap point of the ghost is within 0.4 m of a compatible snap point on an existing piece, the ghost jumps into alignment. With snap off, placement is fully free, at any angle.
4. Ghost is green when valid, red when not. `use_tool` confirms → a **blueprint** appears for everyone. Placing a blueprint is free.
5. Anyone (players or hired carriers) delivers materials: `interact` on the blueprint with the needed item in the carry slot or backpack deposits it. The blueprint shows what is still missing.
6. When the cost is met the piece **completes**: becomes solid, gains its function.
7. **Hammer**: `use_tool` on a blueprint cancels it (refunds delivered materials as drops); `alt_use` held 1.5 s on a completed piece dismantles it (refunds 50 %, rounded down; storage contents drop).

## Placement rules (host re-checks all of them)

- Within 6 m of the placing player.
- Not intersecting players, NPCs, the merchant stall, or the road's no-build strip. Overlap between pieces is **allowed** up to light interpenetration (ghost shape shrunk by 10 %) so free-angle builds fit together.
- `needs_support` pieces must touch terrain or another piece/blueprint (shape query with 0.1 m margin). No stability simulation: a supported piece stays even if its support is later removed.
- Max terrain slope under foundations: 30°. Nothing below sea level.
- World piece cap 5,000 (toast when reached).

## Snap points

`SnapPoint` resource: `{position: Vector3, basis_forward: Vector3, type: StringName}` in piece-local space.
Compatibility table lives in `building/snap_rules.gd` (e.g. `wall_bottom`↔`floor_edge`, `floor_edge`↔`floor_edge`, `roof_low`↔`wall_top`, `post_top`↔`beam_end`).
Modular pieces use a 2 m module (floor 2 × 2, wall 2 × 2.4) so snapped builds line up; free pieces (log, plank, fence post) ignore modules.

## Starting catalogue (data; costs tunable)

| Category | Pieces |
|----------|--------|
| Structure | `foundation_log`, `floor_plank`, `wall_log`, `wall_plank`, `wall_window`, `doorway` + `door`, `pillar_log`, `beam_log`, `stairs_plank`, `roof_thatch_slope`, `roof_thatch_ridge` |
| Free-form | `log_single`, `plank_single`, `stone_block`, `fence_post`, `fence_rail`, `gate`, `ladder`, `platform_small` |
| Function | `campfire` (cook, light), `workbench` (crafting station), `storage_chest` (30 slots, group `storage`), `bed` (respawn, sleep), `torch_post` (light), `sign` (editable text), `drying_rack` (later) |
| Decor | `bench`, `table`, `planter` |

Functional pieces declare `PieceDef.function`; the system owning that function attaches behaviour through the piece scene's
`Interactable` (e.g. `survival` listens for beds). Building never imports other systems' code.

## Data & records

`BuildManager` records: `{entity_id, piece_id, xform (12 floats), state: &"blueprint"|&"complete", delivered: {item_id: count}, placed_by: player_id, extra: {}}`.
`extra` holds function state (storage inventory dict, sign text, door open).

Rendering: each peer builds visuals from records. Blueprints and functional pieces are scene instances; plain structural
pieces switch to per-piece-type `MultiMesh` batches + shared static collision once the count passes ~1,000.

## Networking

Requests: `request_place(piece_id, xform)`, `request_deliver(entity_id, from_carry: bool)`, `request_cancel(entity_id)`, `request_dismantle(entity_id)`, `request_piece_action(entity_id, action, args)` (door toggle, sign text).
Deltas: `sync_piece_added`, `sync_piece_progress`, `sync_piece_completed`, `sync_piece_removed`, `sync_piece_extra`.
Ghost preview is purely local. Snapshot on join is chunked (see [04-networking.md](../04-networking.md)).

## Navigation hook

After a piece completes or is removed, emit the `Events` signal; `npc` rebakes navigation for the affected area. Building does not know about navigation.

## Save

All records. Version field per record set so piece scenes can change shape later without breaking old saves.

## Acceptance

- [ ] Any piece can be placed at any yaw on terrain and on other pieces; snap toggle works and feels predictable.
- [ ] Host rejects every invalid placement a modified client could send.
- [ ] Blueprint completes exactly when cost is met, with deliveries from two players at once.
- [ ] Cancel and dismantle refund correctly; storage contents are never lost.
- [ ] Late joiner sees a 2,000-piece base correctly within 5 s on LAN.
- [ ] 5,000 pieces hold 60 fps on the target PC.
- [ ] New piece = `PieceDef` + scene, no code (unless it adds a new function).

## Out of scope

Structural integrity/collapse, terrain digging/raising, piece health and repair, upgrades between material tiers, blueprints copy/paste, NPC building.
