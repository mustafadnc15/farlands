# Content — Level: The Island

**Owners:** `world` (layout, markers, gameplay volumes) + `art-environment` (terrain mesh, props, water, sky) · **Output:** `res://levels/`, `res://assets/environment/` · **Milestone:** grey-box M0, dressed M6

## Brief

A small, friendly, **nearly flat** island, about 400 × 400 m of land. Flat enough that players can build almost anywhere;
gentle bumps for charm only. One dirt road crosses it. The merchant's stall sits beside the road. The sea surrounds everything.

## Layout (north is −Z)

```
                 N
     ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
   ~   . rocky rise (rocks, ore) .   ~
  ~  forest (dense)        meadow     ~
 ~   T T T T        .  .  berries  .   ~
[W pier]====road=====(M stall)=====road====[E pier]
 ~   meadow  (SPAWN)        pond o      ~
  ~   fibre grass     light woods T T  ~
   ~    sandy beach . . shallows .    ~
     ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
                 S
```

| Zone | Size (approx.) | Contents | Purpose |
|------|----------------|----------|---------|
| Spawn meadow | 80 × 60 m, south of road, west of centre | open flat grass, loose sticks/stones, a few bushes | First camp; safe, lots of build space |
| Road | 4 m wide, slight S-curve west→east | dirt road, pier at each end, a few fence bits and a signpost | Landmark, orientation; where hires "arrive" |
| Merchant stall | 8 × 8 m pad on the north side of the road, near centre | stall, cart, lantern | Trading and hiring |
| Forest | NW quarter | dense small/large trees, deer | Wood, hunting |
| Light woods | SE | scattered trees, rabbits | Easy wood near water |
| Rocky rise | N/NE, the only real hill (max +8 m) | rocks, ore rocks, boar | Stone, iron ore, a viewpoint |
| Pond | E of centre, 25 m across, max 1.5 m deep | fishing spot ×2, reeds | Fishing near base |
| Beach & shallows | S and E coasts | sand, shallow water < 0.6 m, fishing spot ×3 | Spear fishing, rod fishing |
| Meadows | everywhere else | grass, fibre grass, berry bushes | Farming and building land |

## Rules

- Terrain height range −2 m (sea floor at shore) to +8 m; 85 % of land within ±1 m of base level. Slopes > 30° only on the rocky rise and shore lip.
- Sea level Y = 0; land base level Y = 1. The water plane extends to the horizon; an invisible wall 40 m offshore plus the "pushed back to shore" rule keeps players in.
- **No-build strips:** the road (4 m + 1 m margin each side), the stall pad, the two piers. Marked with `Area3D` volumes in group `no_build` (owned by `world`, read by `building`).
- Target counts: ~500 trees, ~150 rocks (25 ore), ~120 bushes, ~300 fibre/loose pickups, 5 fishing spots. All are **markers** (`Marker3D` with a `def_id` export, scattered by a tool script with a fixed seed) that `NodeManager` turns into records on first world creation.
- Wildlife zones are `Area3D` volumes with `animal_id` and `target_population`.
- Navigation: terrain is covered by 50 × 50 m `NavigationRegion3D` chunks (handed to `npc`).
- Spawn point marker `SpawnPoint` in the spawn meadow, 30 m from the road, with a clear view of the merchant stall so new players see where to go.

## Scene structure

```
levels/island.tscn
├─ Terrain            (MeshInstance3D + StaticBody3D trimesh, layer terrain)
├─ Water              (plane + shader; Area3D volumes on layer water)
├─ Road               (mesh strip/decal + no_build volume)
├─ MerchantStall      (static props + MerchantSpawn marker + no_build volume)
├─ Piers
├─ NodeMarkers        (generated; do not hand-edit individual markers)
├─ FishingSpots
├─ WildlifeZones
├─ NavRegions
├─ SpawnPoint
└─ Environment        (WorldEnvironment, DirectionalLight3D — driven by WorldClock)
```

## Process

1. **Grey-box (M0):** flat-ish mesh from a heightmap, coloured zones, primitive markers. Good enough to play M1–M5 on.
2. **Dress (M6):** final terrain mesh with palette-coloured ground blending (vertex colours), props, water shader, sky, decoration that has no collision (flowers, pebbles) via MultiMesh.

Decoration must never block building: anything without gameplay purpose has no collision and disappears when a piece is placed on it.

## Acceptance

- [ ] A player can walk the whole island without getting stuck; no holes; cannot leave the play area.
- [ ] From spawn, the road and merchant are visible without moving the camera far.
- [ ] Every resource type is reachable within 2 minutes of spawn on foot.
- [ ] At least 70 % of land is valid building ground.
- [ ] Runs within budget with all markers populated.
