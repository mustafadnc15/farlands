# 03 — Contracts (frozen shared interfaces)

Only `lead` edits this file and the matching code in `res://core/`. Everyone else codes against it.
Signatures here are normative. If the code differs, that is a bug in one of them.

## 1. Identifiers

- **Def ids**: `StringName`, `snake_case`, globally unique per def type, never renamed once merged (saves depend on them). Examples: `&"log"`, `&"stone_axe"`, `&"wall_plank"`.
- **entity_id**: `int`, assigned only by the host via `Entities.next_id()`. Identifies any networked world object (piece, node, drop, crop, NPC). Never send `NodePath`s over the network for these.
- **player_id**: `String` UUID stored in the client's `user://profile.json`. Stable across sessions; used in saves.
- **peer_id**: `int` from Godot multiplayer. Valid only for the current session. Host is `1`.

## 2. Units and axes

1 unit = 1 metre. Y up. Characters face −Z. Player capsule: height 1.7, radius 0.35. Time in seconds unless named `_days`.

## 3. Physics layers

| Layer | Name | Used by |
|-------|------|---------|
| 1 | `terrain` | island ground, static level geometry |
| 2 | `player` | player bodies |
| 3 | `npc` | workers and wildlife bodies |
| 4 | `piece` | completed build pieces |
| 5 | `interact` | `Interactable` areas (ray-queried only) |
| 6 | `node` | trees, rocks, bushes |
| 7 | `drop` | dropped items |
| 8 | `ghost` | blueprints (placement queries only, no body collision) |
| 9 | `water` | water volumes |

> **Provisional — owners `building`/`world`/`npc` may request a change.** As built in the grey-box island (`tools/build_greybox_island.gd`), level volumes sit on these layers (none of them monitor; `collision_mask` is 0 unless stated):
> - `no_build` areas (group `no_build`): layer 8 `ghost`, `monitoring = false`. Placement code queries them with a ghost-layer area/shape query.
> - `FishingSpot` areas: layer 9 `water`.
> - `WildlifeZone` areas: collision layer 0, collision mask 3 (`npc`), so they can detect animal bodies.

## 4. Input actions

`move_forward`, `move_back`, `move_left`, `move_right`, `jump`, `sprint`, `interact` (E), `use_tool` (LMB),
`alt_use` (RMB), `hotbar_1`..`hotbar_6`, `hotbar_next`, `hotbar_prev`, `inventory` (Tab), `build_menu` (B),
`rotate_piece_left` (Q), `rotate_piece_right` (R), `toggle_snap` (X), `cancel` (Esc), `drop_item` (G), `chat` (Enter), `pause` (Esc when nothing to cancel).

## 5. Groups

`world` (the `World` node), `players`, `npcs`, `wildlife`, `interactable`, `storage`, `saveable`, `no_build` (level volumes where placement is refused).

## 6. Def resources (`res://core/defs/`)

All extend `Resource` with `@export var id: StringName` and `display_name: String`.

```gdscript
class_name ItemDef      # id, display_name, icon: Texture2D, world_scene: PackedScene,
                        # max_stack: int, bulky: bool, category: StringName (&"material"|&"tool"|&"food"|&"seed"|&"misc"),
                        # base_value: int (coins), food_hunger: float, food_health: float,
                        # tool: ToolStats (null if not a tool)
class_name ToolStats    # tool_type: StringName (&"axe"|&"pickaxe"|&"hammer"|&"spear"|&"hoe"|&"rod"|&"can"),
                        # power: float, max_durability: int, swing_time: float, reach: float
class_name RecipeDef    # id, output: StringName, output_count: int, inputs: Dictionary[StringName,int],
                        # station: StringName (&"" hand | &"workbench" | &"campfire"), craft_time: float
class_name PieceDef     # id, display_name, icon, scene: PackedScene, cost: Dictionary[StringName,int],
                        # category: StringName, snap_points: Array[SnapPoint], needs_support: bool, function: StringName
class_name SnapPoint    # (Resource) position: Vector3, basis_forward: Vector3 (default Vector3.FORWARD), type: StringName
class_name CropDef      # id, seed_item, harvest_item, harvest_count_min/max, grow_days: float, stage_scenes: Array[PackedScene], regrows: bool
class_name NodeDef      # id, scene, required_tool: StringName, hit_points: float, drops: Dictionary[StringName,int], respawn_days: float
class_name AnimalDef    # id, scene, health: float, speed: float, flees: bool, attack_damage: float, drops: Dictionary[StringName,int]
class_name JobDef       # id, display_name, required_tool: StringName, behaviour_script: Script
class_name TradeDef     # id, item: StringName, buy_price: int, sell_price: int, daily_stock: int (−1 = unlimited)
```

## 7. Autoload APIs

```gdscript
# Registry
func item(id: StringName) -> ItemDef          # likewise recipe(), piece(), crop(), node_def(), animal(), job(), trade()
func all_items() -> Array[ItemDef]            # likewise all_*()
func load_from(root: String) -> void          # clears all defs, then scans <root>/<type>/ recursively; called with "res://content" at startup, tests may pass a fixture root

# Entities
func next_id() -> int                         # host only (returns -1 and logs an error on a client)
func register(entity_id: int, node: Node) -> void
func unregister(entity_id: int) -> void
func find(entity_id: int) -> Node             # null if unknown or freed
func get_next_id() -> int                     # the id next_id() will hand out (for saving)
func set_next_id(value: int) -> void          # restore after load
func clear() -> void                          # drops all registrations and resets the counter to 1 (session end, tests)

# Net
func is_host() -> bool
func sender_id() -> int                       # remote sender, or 1 when the host called locally
func peer_to_player(peer_id: int) -> String   # player_id
func player_node(peer_id: int) -> Node3D
signal player_joined(peer_id: int, player_id: String)
signal player_left(peer_id: int, player_id: String)

# WorldClock
var day: int                                  # starts at 1
var time_of_day: float                        # 0.0–1.0, 0.25 = sunrise, 0.5 = noon
signal day_started(day: int)                  # host and clients
func is_night() -> bool

# World (node, not autoload):  get_tree().get_first_node_in_group("world")
func get_manager(manager_name: StringName) -> Node    # &"node" &"build" &"farm" &"npc" &"drop" &"economy"; null + error if unregistered
func register_manager(manager_name: StringName, node: Node) -> void   # called by each manager on ready; rejects keys outside the six above
```

## 8. Components (`res://core/components/`)

```gdscript
class_name HealthComponent extends Node
  @export var max_health: float = 100.0; var health: float   # health = max_health on _ready
  func is_dead() -> bool
  func damage(amount: float, source: StringName) -> void    # host only
  func heal(amount: float) -> void                          # host only
  func revive(to_health: float) -> void                     # host only; clamps to 1..max_health, clears the dead state (respawn)
  signal changed(health: float, max_health: float)
  signal died(source: StringName)

class_name Inventory extends Node
  @export var slot_count: int = 24           # setter resizes (min 0)
  @export var bulky_only: bool = false       # carry slots: accept only bulky items
  @export var allow_bulky: bool = false      # storage: accept bulky and non-bulky; with both flags false (backpack) bulky is rejected
  func add(item_id: StringName, count: int, durability: int = -1) -> int   # returns leftover; host only
  func remove(item_id: StringName, count: int) -> bool                     # all-or-nothing; host only
  func count_of(item_id: StringName) -> int
  func has_all(cost: Dictionary) -> bool
  func get_slot(i: int) -> Dictionary        # {} or {id, count, durability}; a copy
  func set_slot(i: int, slot: Dictionary) -> void      # host only; overwrites slot i ({} empties); for moves/swaps/sync
  func free_space_for(item_id: StringName) -> int      # how many more fit now (0 if unknown or rejected)
  func to_dict() -> Dictionary ; func from_dict(d: Dictionary) -> void
  signal changed()

class_name Interactable extends Area3D       # layer 5, group "interactable"
  @export var prompt: String                 # "Open", "Talk", "Pick up"
  var entity_id: int
  signal interacted(peer_id: int)            # emitted on host after validation
  func can_interact(peer_id: int) -> bool    # override; default true
  func try_interact(peer_id: int) -> bool    # host only: if can_interact, emits interacted and returns true
```

Player node exposes: `inventory: Inventory` (24 slots; first 6 are the hotbar), `carry: Inventory` (1 slot, bulky items only),
`health: HealthComponent`, `peer_id: int`, `player_id: String`, `get_equipped() -> ItemDef`.

### Level classes (`res://levels/`)

Scripts the level scene uses so managers can read placement data without scene-specific paths.

```gdscript
class_name NodeMarker extends Marker3D     # NodeManager turns each into a resource-node record on first world creation
  @export var def_id: StringName           # a NodeDef id
class_name FishingSpot extends Area3D      # fishing volume; catch per day is capped
  @export var daily_cap: int = 12
class_name WildlifeZone extends Area3D     # one animal species kept at a target population
  @export var animal_id: StringName        # an AnimalDef id
  @export var target_population: int
```

## 9. Manager APIs other systems may call (host side)

```gdscript
# DropManager (items)
func spawn_drop(item_id: StringName, count: int, pos: Vector3) -> int      # returns entity_id
# NodeManager (world)
func apply_hit(entity_id: int, tool: ToolStats, by_peer: int) -> void
func nearest_node(def_id: StringName, from: Vector3, max_dist: float) -> int   # −1 if none
# BuildManager (building)
func blueprints_needing(item_id: StringName) -> Array[int]                 # entity_ids
func deliver(entity_id: int, item_id: StringName, count: int) -> int       # returns accepted count
func storages() -> Array[Node]                                             # nodes in group "storage", each has .inventory
# Economy (economy)
func coins() -> int ; func add_coins(n: int) -> void ; func spend(n: int) -> bool   # shared colony wallet
# NpcManager (npc)
func worker_count() -> int ; func hire(job_id: StringName, by_peer: int) -> bool
```

## 10. Events bus (`Events` autoload) — fired on every peer unless marked

```gdscript
signal item_picked_up(peer_id: int, item_id: StringName, count: int)
signal item_crafted(peer_id: int, item_id: StringName)
signal tool_used(peer_id: int, tool_type: StringName, hit_entity: int)
signal node_hit(entity_id: int) ; signal node_depleted(entity_id: int)
signal piece_placed(entity_id: int, piece_id: StringName)
signal piece_completed(entity_id: int, piece_id: StringName)
signal piece_removed(entity_id: int)
signal crop_planted(entity_id: int) ; signal crop_harvested(entity_id: int)
signal player_damaged(peer_id: int, amount: float) ; signal player_died(peer_id: int) ; signal player_respawned(peer_id: int)
signal player_ate(peer_id: int, item_id: StringName)
signal trade_done(peer_id: int, item_id: StringName, count: int, bought: bool)
signal coins_changed(total: int)
signal worker_hired(entity_id: int, job_id: StringName)
signal worker_job_changed(entity_id: int, job_id: StringName)
signal ui_toast(text: String)                 # local only
```

## 11. Save contract

Every stateful manager is in group `saveable` and implements:

```gdscript
func save_key() -> StringName          # unique, e.g. &"build"
func save_state() -> Dictionary        # JSON-safe values only (no Vector3: use [x,y,z])
func load_state(d: Dictionary) -> void # must tolerate missing keys (older saves)
```

## 12. Changing a contract

File a change request ([01-agent-workflow.md](01-agent-workflow.md)). `lead` updates this doc and `res://core/` in one commit,
adds a line to [decisions.md](decisions.md), and notifies affected owners.
