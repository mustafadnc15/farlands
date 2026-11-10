# System — Farming

**Owner:** `farming` · **Code:** `res://farming/`, data in `res://content/crops/` · **Depends on:** items, world-time · **Milestone:** M4

## Purpose

Till soil anywhere, plant seeds, water, harvest. Free placement like building — no farm grid, no plots to unlock.

## Behaviour

- **Till:** hoe + `use_tool` on grass terrain creates a **soil patch**: a 1 × 1 m decal-like mesh aligned to the ground at the hit point.
  Patches may not overlap each other, pieces, nodes, the road, or slopes > 20°. Hold `use_tool` and walk to till a row (patches auto-space edge to edge).
- **Plant:** with a seed equipped, `use_tool` on an empty patch consumes one seed and creates a crop.
- **Water:** watering can (10 charges, refill by `use_tool` on water) wets a patch for the current day. Wet soil is visibly darker.
- **Growth:** on each `day_started`, a crop advances by 1 growth day if its patch was watered the previous day, else by 0.5. Stage model = `floor(progress / grow_days × (stages − 1))`.
- **Harvest:** `interact` on a mature crop gives `harvest_item` × random(min..max) and, with 30 % chance, 1 seed. Crops with `regrows` return to the stage before last instead of clearing.
- **Remove:** hoe on an empty patch removes it; hammer-dismantle is not used here.
- Animals do not eat crops in v1.

Starting crops (data, tunable):

| Crop | Grow days | Yield | Regrows |
|------|-----------|-------|---------|
| `wheat` | 3 | 2–3 wheat | no |
| `carrot` | 2 | 1–2 carrot | no |
| `potato` | 4 | 2–4 potato | no |
| `tomato` | 5 | 2–3 tomato | yes |

## Data & records

`FarmManager` records: `{entity_id, pos, normal, crop_id (or &""), progress_days, watered_day}`.

## Networking

Requests: `request_till(pos)`, `request_plant(entity_id, slot)`, `request_water(entity_id)`, `request_harvest(entity_id)`, `request_untill(entity_id)`.
Host validates reach (≤ 3 m), tool/seed in hand, placement rules. Deltas: `sync_patch_added/removed`, `sync_crop_state`.

## Save

All patch records. Growth uses stored `progress_days`, so loading on any day is consistent.

## Acceptance

- [ ] Tilling respects all placement rules; row-tilling produces tidy, non-overlapping patches.
- [ ] Growth matches the watered/unwatered rule across several days and across save/load.
- [ ] Two players harvesting the same crop: one yield only.
- [ ] 500 patches with crops stay within frame budget (shared materials, instancing by stage).
- [ ] New crop = one `CropDef` + stage scenes + seed/harvest `ItemDef`s, no code.

## Out of scope

Fertiliser, seasons, crop disease, sprinklers, livestock, NPC farmers (candidate for a later job, see [decisions.md](../decisions.md)).
