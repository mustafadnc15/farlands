# M0 Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the empty Godot project into the shared foundation every other agent codes against: project settings, `res://core/` contracts as real code, a test harness, a session scene skeleton, and a grey-box island.

**Architecture:** Contracts from `docs/03-contracts.md` become typed GDScript in `res://core/` (def resources, components, three autoloads). A minimal `Net` stub lets host-only guards work before real networking exists. Everything is covered by GUT tests run headless.

**Tech Stack:** Godot 4.7.2, GDScript (static typing), Jolt Physics, GUT (Godot Unit Test).

**Spec:** `docs/INDEX.md` → core docs. Normative for this plan: `docs/03-contracts.md`, `docs/02-architecture.md`, `docs/05-conventions.md`, `docs/content/level-island.md`, `docs/roadmap.md` (M0 gate).

## Global Constraints

- Agent id for all tasks: `lead`. Work on branch `agent/lead/m0-foundation`; one commit per task.
- Godot executable: set `GODOT` to the **console** build, e.g. `export GODOT="C:/Users/musto/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"` (that `.exe`-named path is a folder).
- Static typing everywhere; tabs; `class_name` on anything shared; ids are `StringName` literals (`&"log"`).
- 1 unit = 1 m, Y up, characters face −Z. Player capsule height 1.7, radius 0.35.
- Signatures in `docs/03-contracts.md` are copied exactly. If one cannot be implemented as written, stop and report — do not improvise a different interface.
- Verify any Godot API you are unsure of against the 4.7 docs before using it.
- After adding or renaming any `class_name` script, run `"$GODOT" --headless --path . --import` before running tests.
- Test command (all): `"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit`
  Single file: append `-gtest=res://tests/core/<file>.gd`. Pass = exit code 0 and "All tests passed".
- No gameplay features. Nothing outside the M0 list in `docs/roadmap.md`.

## Review Focus

1. **Inventory given a zero, negative, or over-capacity count** — `add` must never create negative stacks or lose items silently; leftover is returned. (Task 5)
2. **Inventory restored from an old or damaged save** (`from_dict` with unknown item ids, missing keys, too many slots) — must load what it can and not crash. (Task 5)
3. **Content folder with a duplicate id, a wrong-typed resource, or an empty id** — `Registry` keeps the first, reports the rest with `push_error`, boot continues. (Task 3)
4. **`Entities.find` for an id whose node has been freed** — returns `null`, never a dangling instance. (Task 4)
5. **Damage after death / negative damage / heal above max** — `died` fires exactly once; health stays within `0..max_health`. (Task 5)

---

## File Structure

```
project.godot                         autoloads, input map, layer names, main scene
tools/setup_project.gd                one-off headless script that writes input map + layer names
tools/run_tests.sh                    wrapper around the GUT command
tools/build_greybox_island.gd         headless generator for the grey-box level
addons/gut/                           test framework (vendored)
core/defs/*.gd                        ItemDef, ToolStats, RecipeDef, PieceDef, SnapPoint, CropDef, NodeDef, AnimalDef, JobDef, TradeDef
core/autoload/events.gd               Events
core/autoload/registry.gd             Registry
core/autoload/entities.gd             Entities
core/components/health_component.gd   HealthComponent
core/components/inventory.gd          Inventory
core/components/interactable.gd       Interactable
core/placeholders/                    capsule_character.tscn, box_item.tscn, box_piece.tscn
net/net.gd                            Net autoload STUB (replaced by `net` agent in M1)
main/main.tscn, main/main.gd          boot scene
main/game.tscn, main/world.gd         session skeleton: World, Managers, Players, Npcs, Dynamic
levels/island.tscn (+ generated mesh) grey-box island
content/items/log.tres                one sample def
content/<type>/.gitkeep               empty folders for each def type
tests/core/test_*.gd                  unit tests
tests/levels/test_island.gd           level smoke test
```

---

### Task 1: Project settings and test harness

**Files:**
- Create: `tools/setup_project.gd`, `tools/run_tests.sh`, `addons/gut/**`, `tests/core/test_project_settings.gd`, `.gutconfig.json`
- Create empty dirs with `.gitkeep`: `core/{autoload,components,defs,placeholders}`, `net player survival items world farming building npc economy ui save audio`, `content/{items,recipes,pieces,crops,nodes,animals,jobs,trades}`, `assets/{characters,environment,props,audio}`, `levels`, `main`, `tests`
- Modify: `project.godot` (only through the setup script and the editor plugin enable line)

**Interfaces:**
- Produces: input actions and 3D physics layer names exactly as in contracts §3–4; the test command in Global Constraints works.

- [ ] **Step 1: Vendor GUT.** Find the GUT release that supports Godot 4.7 (check the GUT repository's README/compat table; do not guess a version), copy its `addons/gut/` into the project, enable the plugin in `project.godot`, run `--import`. Write `.gutconfig.json` with `dirs: ["res://tests"]`, `include_subdirs: true`.

- [ ] **Step 2: Write the failing test** `tests/core/test_project_settings.gd`

```gdscript
extends GutTest

const ACTIONS: Array[StringName] = [&"move_forward", &"move_back", &"move_left", &"move_right", &"jump", &"sprint",
	&"interact", &"use_tool", &"alt_use", &"hotbar_1", &"hotbar_2", &"hotbar_3", &"hotbar_4", &"hotbar_5", &"hotbar_6",
	&"hotbar_next", &"hotbar_prev", &"inventory", &"build_menu", &"rotate_piece_left", &"rotate_piece_right",
	&"toggle_snap", &"cancel", &"drop_item", &"chat", &"pause"]
const LAYERS: Array[String] = ["terrain", "player", "npc", "piece", "interact", "node", "drop", "ghost", "water"]

func test_all_input_actions_exist() -> void:
	for a in ACTIONS:
		assert_true(InputMap.has_action(a), "missing action %s" % a)
		assert_gt(InputMap.action_get_events(a).size(), 0, "no binding for %s" % a)

func test_physics_layer_names() -> void:
	for i in LAYERS.size():
		assert_eq(ProjectSettings.get_setting("layer_names/3d_physics/layer_%d" % (i + 1)), LAYERS[i])
```

- [ ] **Step 3: Run it — expect FAIL** (actions missing).

- [ ] **Step 4: Implement `tools/setup_project.gd`** (`extends SceneTree`, runs in `_init`, then `quit()`). It sets `input/<action>` settings and `layer_names/3d_physics/layer_N`, then `ProjectSettings.save()`. Bindings: WASD move; Space jump; Shift sprint; E interact; LMB use_tool; RMB alt_use; 1–6 hotbar; wheel up/down hotbar_prev/next; Tab inventory; B build_menu; Q/R rotate left/right; X toggle_snap; Esc cancel **and** pause; G drop_item; Enter chat. Use physical keycodes. Idempotent (running twice changes nothing).
  Run: `"$GODOT" --headless --path . -s tools/setup_project.gd`

- [ ] **Step 5: Write `tools/run_tests.sh`** — fails with a clear message if `GODOT` is unset; runs `--import`, then the GUT command, passing extra args through; exits with GUT's exit code.

- [ ] **Step 6: Run `tools/run_tests.sh` — expect PASS.** Also confirm `"$GODOT" --headless --path . --quit` prints no errors.

- [ ] **Step 7: Commit** `chore: project settings, folder layout, GUT harness`

---

### Task 2: Def resource classes

**Files:**
- Create: `core/defs/item_def.gd`, `tool_stats.gd`, `recipe_def.gd`, `piece_def.gd`, `snap_point.gd`, `crop_def.gd`, `node_def.gd`, `animal_def.gd`, `job_def.gd`, `trade_def.gd`
- Create: `content/items/log.tres`
- Test: `tests/core/test_defs.gd`

**Interfaces:**
- Produces: the classes of contracts §6, every field an `@export` with the exact name and type given there. Typed dictionaries: `Dictionary[StringName, int]`. Defaults: `max_stack = 1`, `output_count = 1`, `daily_stock = -1`, `needs_support = true`, `harvest_count_min = 1`, `harvest_count_max = 1`, numeric others `0`, `StringName` others `&""`, object refs `null`.
  `SnapPoint`: `position: Vector3`, `basis_forward: Vector3 = Vector3.FORWARD`, `type: StringName`.
- `log.tres`: `ItemDef` with `id=&"log"`, `display_name="Log"`, `max_stack=3`, `bulky=true`, `category=&"material"`, `base_value=4`.

- [ ] **Step 1: Write the failing test**

```gdscript
extends GutTest

func test_item_def_defaults() -> void:
	var d := ItemDef.new()
	assert_eq(d.id, &"") ; assert_eq(d.max_stack, 1) ; assert_false(d.bulky) ; assert_null(d.tool)

func test_tool_stats_fields() -> void:
	var t := ToolStats.new()
	t.tool_type = &"axe" ; t.power = 10.0 ; t.max_durability = 60 ; t.swing_time = 0.5 ; t.reach = 2.5
	assert_eq(t.tool_type, &"axe")

func test_recipe_inputs_typed() -> void:
	var r := RecipeDef.new()
	r.inputs[&"stick"] = 2
	assert_eq(r.inputs[&"stick"], 2) ; assert_eq(r.output_count, 1) ; assert_eq(r.station, &"")

func test_trade_default_stock_unlimited() -> void:
	assert_eq(TradeDef.new().daily_stock, -1)

func test_all_defs_have_id_and_name() -> void:
	for d: Resource in [ItemDef.new(), RecipeDef.new(), PieceDef.new(), CropDef.new(), NodeDef.new(), AnimalDef.new(), JobDef.new(), TradeDef.new()]:
		assert_true("id" in d and "display_name" in d, d.get_script().resource_path)

func test_sample_log_loads() -> void:
	var log_def := load("res://content/items/log.tres") as ItemDef
	assert_not_null(log_def) ; assert_eq(log_def.id, &"log") ; assert_true(log_def.bulky) ; assert_eq(log_def.max_stack, 3)
```

- [ ] **Step 2: Run — expect FAIL** (classes undefined).
- [ ] **Step 3: Implement the ten classes and `log.tres`.** One class per file, `extends Resource`, `##` doc comment per class copied from its contracts line. No methods.
- [ ] **Step 4: `--import`, run — expect PASS.**
- [ ] **Step 5: Commit** `feat(core): def resource classes and sample item`

---

### Task 3: Registry autoload

**Files:**
- Create: `core/autoload/registry.gd`; Test: `tests/core/test_registry.gd`, fixtures under `tests/core/fixtures/registry/{items,recipes}/`
- Modify: `project.godot` (autoload `Registry`)

**Interfaces:**
- Consumes: def classes (Task 2).
- Produces (contracts §7): `item(id) -> ItemDef`, `recipe`, `piece`, `crop`, `node_def`, `animal`, `job`, `trade` (each returns `null` + `push_error` for unknown id); `all_items() -> Array[ItemDef]` and the matching `all_*()`.
  Plus for tests and tools: `func load_from(root: String) -> void` (clears, then scans `<root>/<type>/` recursively for `.tres`/`.res`); `_ready()` calls `load_from("res://content")`.

- [ ] **Step 1: Fixtures.** `items/log.tres` (`&"log"`), `items/log_copy.tres` (also `&"log"`, display_name "Dup"), `items/no_id.tres` (empty id), `items/wrong_type.tres` (a `RecipeDef` saved in the items folder), `recipes/plank.tres` (`&"plank"`).

- [ ] **Step 2: Write the failing test**

```gdscript
extends GutTest
const FIX := "res://tests/core/fixtures/registry"

func before_each() -> void:
	Registry.load_from(FIX)
func after_all() -> void:
	Registry.load_from("res://content")

func test_lookup_by_id() -> void:
	assert_eq(Registry.item(&"log").id, &"log")
	assert_eq(Registry.recipe(&"plank").id, &"plank")

func test_unknown_id_returns_null() -> void:
	assert_null(Registry.item(&"nope"))
	assert_push_error_count(1)          # use the GUT 4.7-compatible error assertion

func test_duplicate_keeps_first_and_reports() -> void:
	assert_eq(Registry.all_items().size(), 1)
	assert_ne(Registry.item(&"log").display_name, "Dup")

func test_wrong_type_and_empty_id_skipped() -> void:
	for d in Registry.all_items():
		assert_true(d is ItemDef) ; assert_ne(d.id, &"")

func test_real_content_loads() -> void:
	Registry.load_from("res://content")
	assert_not_null(Registry.item(&"log"))
	assert_eq(Registry.all_pieces().size(), 0)
```

Loading order for the duplicate rule: files sorted by path ascending, first wins. If GUT's error-assertion name differs in the vendored version, use its equivalent; the loading tests in `before_each` will also raise expected errors — mark them as expected the way that GUT version requires.

- [ ] **Step 3: Run — expect FAIL.**
- [ ] **Step 4: Implement `registry.gd`** — one `Dictionary[StringName, Resource]` per type keyed by folder name; skip + `push_error("[registry] ...")` on wrong type, empty id, duplicate. Must work in exported builds (handle `.remap` suffix when listing directories). Register the autoload.
- [ ] **Step 5: Run — expect PASS.**
- [ ] **Step 6: Commit** `feat(core): Registry autoload`

---

### Task 4: Events, Entities, and the Net stub

**Files:**
- Create: `core/autoload/events.gd`, `core/autoload/entities.gd`, `net/net.gd`; Test: `tests/core/test_entities.gd`, `tests/core/test_events.gd`
- Modify: `project.godot` (autoloads in this order: `Events`, `Registry`, `Entities`, `Net`)

**Interfaces:**
- Produces:
  - `Events`: exactly the signals of contracts §10, no state, no methods.
  - `Entities`: `next_id() -> int` (first call returns 1, host only: returns −1 + `push_error` when `not Net.is_host()`), `register(entity_id: int, node: Node) -> void`, `unregister(entity_id: int) -> void`, `find(entity_id: int) -> Node`, plus for save/load `get_next_id() -> int`, `set_next_id(value: int) -> void`, `clear() -> void`.
  - `Net` stub: `is_host() -> bool` (true when there is no multiplayer peer or `multiplayer.is_server()`), `sender_id() -> int` (remote sender id, or 1 when it is 0), `peer_to_player(peer_id: int) -> String` (returns `""`), `player_node(peer_id: int) -> Node3D` (returns `null`), signals `player_joined(peer_id: int, player_id: String)`, `player_left(peer_id: int, player_id: String)`. Top comment: `# STUB — replaced by the net agent in M1; keep these signatures.`

- [ ] **Step 1: Write the failing tests**

```gdscript
# test_entities.gd
extends GutTest
func before_each() -> void: Entities.clear()

func test_ids_start_at_one_and_increase() -> void:
	assert_eq(Entities.next_id(), 1) ; assert_eq(Entities.next_id(), 2)

func test_register_find_unregister() -> void:
	var n := Node.new() ; add_child_autofree(n)
	Entities.register(7, n)
	assert_eq(Entities.find(7), n)
	Entities.unregister(7)
	assert_null(Entities.find(7))

func test_find_unknown_is_null() -> void:
	assert_null(Entities.find(999))

func test_find_freed_node_is_null() -> void:
	var n := Node.new() ; add_child(n)
	Entities.register(3, n)
	n.free()
	assert_null(Entities.find(3))

func test_register_duplicate_id_keeps_first() -> void:
	var a := Node.new() ; var b := Node.new() ; add_child_autofree(a) ; add_child_autofree(b)
	Entities.register(5, a) ; Entities.register(5, b)      # second call push_errors
	assert_eq(Entities.find(5), a)

func test_counter_restore() -> void:
	Entities.set_next_id(4567)
	assert_eq(Entities.next_id(), 4567) ; assert_eq(Entities.get_next_id(), 4568)

func test_clear_resets() -> void:
	Entities.next_id() ; Entities.clear()
	assert_eq(Entities.next_id(), 1)
```

```gdscript
# test_events.gd
extends GutTest
const SIGNALS: Array[StringName] = [&"item_picked_up", &"item_crafted", &"tool_used", &"node_hit", &"node_depleted",
	&"piece_placed", &"piece_completed", &"piece_removed", &"crop_planted", &"crop_harvested", &"player_damaged",
	&"player_died", &"player_respawned", &"player_ate", &"trade_done", &"coins_changed", &"worker_hired",
	&"worker_job_changed", &"ui_toast"]
func test_all_contract_signals_exist() -> void:
	for s in SIGNALS: assert_true(Events.has_signal(s), "missing %s" % s)
func test_net_stub_is_host_offline() -> void:
	assert_true(Net.is_host()) ; assert_eq(Net.sender_id(), 1)
```

- [ ] **Step 2: Run — expect FAIL.**
- [ ] **Step 3: Implement the three scripts and register autoloads.** `Entities.find` uses `is_instance_valid` and drops stale entries.
- [ ] **Step 4: Run — expect PASS.**
- [ ] **Step 5: Commit** `feat(core): Events, Entities, Net stub`

---

### Task 5: Components

**Files:**
- Create: `core/components/health_component.gd`, `inventory.gd`, `interactable.gd`; Test: `tests/core/test_health_component.gd`, `test_inventory.gd`, `test_interactable.gd`, fixtures `tests/core/fixtures/inv/items/{log,stick,stone_axe}.tres`

**Interfaces:**
- Consumes: `Registry.item`, `Net.is_host` (host-only methods do nothing + `push_warning` when not host).
- Produces (contracts §8), with these pinned behaviours:
  - `HealthComponent`: `@export var max_health: float = 100.0`; `health` starts at `max_health` in `_ready`; `damage(amount, source)` ignores `amount <= 0` and calls after death; clamps at 0; emits `changed(health, max_health)` on every real change and `died(source)` once. `heal(amount)` ignores `<= 0`, clamps to max, does nothing when dead. Extra: `func is_dead() -> bool`, `func revive(to_health: float) -> void` (host only; for respawn).
  - `Inventory`: `@export var slot_count: int = 24`; `@export var bulky_only: bool = false` (carry slots) and `@export var allow_bulky: bool = false` (storage; backpack rejects bulky when both false).
    `add` fills existing stacks first, then empty slots in index order; respects `ItemDef.max_stack`; returns leftover; `count <= 0` or unknown id → returns `count` unchanged (max 0) with no change. Tools (`max_stack == 1`) carry `durability`; `-1` means "use `tool.max_durability`".
    `remove` is all-or-nothing, takes from the **last** matching slot first. `get_slot(i)` returns `{}` for empty/out-of-range, else `{id, count, durability}` (a copy).
    Also: `func set_slot(i: int, slot: Dictionary) -> void` (host only), `func free_space_for(item_id: StringName) -> int`.
    `to_dict()` → `{"slots": [ {} | {"id": String, "count": int, "durability": int}, ... ]}` (JSON-safe); `from_dict` tolerates missing `"slots"`, extra slots (dropped), unknown ids (slot left empty, one `push_warning`), counts above `max_stack` (clamped). `changed` emits once per mutating call that changed something.
  - `Interactable` (`extends Area3D`): `_init` sets `collision_layer` to layer 5 only, `collision_mask = 0`, `monitoring = false`; `_ready` adds to group `interactable`. `func try_interact(peer_id: int) -> bool` — host only; emits `interacted(peer_id)` and returns true when `can_interact(peer_id)`.

- [ ] **Step 1: Write the failing tests.** Fixture items: `log` (max_stack 3, bulky), `stick` (max_stack 20), `stone_axe` (max_stack 1, tool with `max_durability = 60`). Load fixtures with `Registry.load_from("res://tests/core/fixtures/inv")` in `before_all`, restore `res://content` in `after_all`.

```gdscript
# test_inventory.gd — required cases (one test function each)
# add_stacks_then_spills:      slot_count 2: add(&"stick", 25) == 0 -> slots 20 and 5
# add_returns_leftover:        slot_count 1: add(&"stick", 25) == 5
# add_zero_or_negative_noop:   add(&"stick", 0) == 0 ; add(&"stick", -3) == 0 ; count_of == 0 ; changed not emitted
# add_unknown_id_rejected:     add(&"nope", 2) == 2 ; nothing stored
# backpack_rejects_bulky:      add(&"log", 1) == 1
# carry_accepts_only_bulky:    bulky_only=true, slot_count 1: add(&"log", 4) == 1 ; add(&"stick", 1) == 1
# storage_accepts_both:        allow_bulky=true: add(&"log", 1) == 0 ; add(&"stick", 1) == 0
# tool_gets_full_durability:   add(&"stone_axe", 1) -> get_slot(0).durability == 60
# tool_keeps_given_durability: add(&"stone_axe", 1, 12) -> durability == 12
# remove_all_or_nothing:       5 sticks: remove(&"stick", 6) == false, count_of == 5 ; remove(&"stick", 5) == true, count_of == 0
# has_all:                     has_all({&"stick": 2, &"stone_axe": 1}) true/false cases ; has_all({}) == true
# get_slot_out_of_range:       get_slot(-1) == {} ; get_slot(999) == {}
# get_slot_is_copy:            mutating the returned dict does not change count_of
# round_trip:                  from_dict(to_dict()) preserves every slot ; JSON.stringify(to_dict()) parses back equal
# from_dict_tolerates_garbage: from_dict({}) empties ; unknown id slot -> empty ; 40 slots into 24 -> 24 ; count 99 of stick -> 20
# changed_emits_once_per_call: watch_signals ; add(&"stick", 25) -> assert_signal_emit_count(inv, "changed", 1)
```

```gdscript
# test_health_component.gd — required cases
# starts_full ; damage_reduces_and_emits_changed ; damage_clamps_at_zero
# died_emits_once:        damage(150, &"fall") ; damage(10, &"fall") -> died count 1, source &"fall"
# negative_or_zero_damage_ignored ; heal_clamps_to_max ; heal_ignored_when_dead
# revive_restores:        after death revive(50) -> health 50, is_dead() false, can die again (died count 2 total)
```

```gdscript
# test_interactable.gd — required cases
# layer_is_interact_only: collision_layer == 1 << 4 ; collision_mask == 0
# in_group_after_ready ;  try_interact_emits: returns true, interacted emitted with peer id 1
# can_interact_false_blocks: subclass overriding can_interact -> false => returns false, no signal
```

- [ ] **Step 2: Run — expect FAIL.**
- [ ] **Step 3: Implement the three components.**
- [ ] **Step 4: Run — expect PASS** (all tests in the project, not only these).
- [ ] **Step 5: Commit** `feat(core): HealthComponent, Inventory, Interactable`

---

### Task 6: Placeholders and session skeleton

**Files:**
- Create: `core/placeholders/capsule_character.tscn`, `box_item.tscn`, `box_piece.tscn`, `core/placeholders/placeholder_palette.tres` (one flat `StandardMaterial3D`, roughness 0.9)
- Create: `main/main.tscn`, `main/main.gd`, `main/game.tscn`, `main/world.gd`; Test: `tests/core/test_world.gd`, `tests/core/test_placeholders.gd`
- Modify: `project.godot` (`run/main_scene = res://main/main.tscn`)

**Interfaces:**
- Produces:
  - `capsule_character.tscn`: root `Node3D` named `Model`; capsule mesh 1.7 high, radius 0.35, base at origin, a small cone "nose" pointing −Z; `AnimationPlayer` containing **empty** clips for every settler animation name listed in `docs/content/characters.md`; `BoneAttachment`-stand-ins as plain `Node3D`s named `hand_r`, `hand_l`, `shoulder_r`, `back`, `head_top`.
  - `box_item.tscn` (root `Model`, 0.3 m cube), `box_piece.tscn` (root `Model`, 2 × 2.4 × 0.2 m slab, origin at bottom centre).
  - `World` (`main/world.gd`, `class_name World extends Node3D`, in group `world`): `func get_manager(name: StringName) -> Node` returning the child of `Managers` registered under that key, `null` + `push_error` if absent; `func register_manager(name: StringName, node: Node) -> void`. Valid keys: `&"node" &"build" &"farm" &"npc" &"drop" &"economy"`.
  - `game.tscn` tree exactly as `docs/02-architecture.md` "Scene tree": `Game/World/{Level, Managers, Players, Npcs, Dynamic}` and `Game/UI` (CanvasLayer). `Level` instances `levels/island.tscn` once Task 7 exists (leave an empty `Node3D` named `Level` until then). `Managers` is empty.
  - `main.tscn`: `Main` with `Menu` (CanvasLayer with one label "New Lands — M0" and a "Start test world" button). `main.gd`: `func start_game() -> void` instances `game.tscn` and hides the menu; `func end_game() -> void` frees it and shows the menu. Command-line user arg `--autostart` calls `start_game()` on ready.

- [ ] **Step 1: Write the failing tests**

```gdscript
# test_world.gd
extends GutTest
var game: Node
func before_each() -> void:
	game = load("res://main/game.tscn").instantiate() ; add_child_autofree(game)

func test_tree_shape() -> void:
	for p in ["World/Level", "World/Managers", "World/Players", "World/Npcs", "World/Dynamic", "UI"]:
		assert_not_null(game.get_node_or_null(p), p)

func test_world_in_group_and_typed() -> void:
	assert_true(get_tree().get_first_node_in_group("world") is World)

func test_manager_registration() -> void:
	var w := game.get_node("World") as World
	var m := Node.new() ; w.get_node("Managers").add_child(m)
	w.register_manager(&"build", m)
	assert_eq(w.get_manager(&"build"), m)
	assert_null(w.get_manager(&"farm"))       # push_error expected

func test_main_start_and_end() -> void:
	var main := load("res://main/main.tscn").instantiate() ; add_child_autofree(main)
	main.start_game() ; assert_not_null(main.get_node_or_null("Game"))
	main.end_game() ; await get_tree().process_frame
	assert_null(main.get_node_or_null("Game"))
```

```gdscript
# test_placeholders.gd
extends GutTest
const ANIMS := ["idle","walk","run","jump","fall","land","swing_axe","swing_pick","swing_hammer","swing_hoe","spear_thrust",
	"spear_aim","spear_throw","rod_cast","rod_idle","rod_reel","water","carry_idle","carry_walk","pickup","eat","sit","sleep",
	"hurt","die","wave","talk"]
func test_capsule_character_contract() -> void:
	var m: Node3D = load("res://core/placeholders/capsule_character.tscn").instantiate() ; add_child_autofree(m)
	assert_eq(m.name, &"Model")
	var ap := m.find_child("AnimationPlayer") as AnimationPlayer
	for a in ANIMS: assert_true(ap.has_animation(a), a)
	for n in ["hand_r","hand_l","shoulder_r","back","head_top"]: assert_not_null(m.find_child(n), n)
func test_item_and_piece_roots_named_model() -> void:
	for p in ["box_item", "box_piece"]:
		var n: Node = load("res://core/placeholders/%s.tscn" % p).instantiate() ; add_child_autofree(n)
		assert_eq(n.name, &"Model")
```

- [ ] **Step 2: Run — expect FAIL.**
- [ ] **Step 3: Build the scenes and scripts.** Scenes may be authored as `.tscn` text or generated by a throwaway headless script; either way commit only the resulting scenes.
- [ ] **Step 4: Run all tests — expect PASS.** Run `"$GODOT" --headless --path . --quit-after 60 -- --autostart` — expect no errors.
- [ ] **Step 5: Commit** `feat: placeholders and session scene skeleton`

---

### Task 7: Grey-box island

**Files:**
- Create: `tools/build_greybox_island.gd`, `levels/island.tscn`, `levels/generated/island_terrain.res` (mesh), `levels/node_marker.gd`, `levels/wildlife_zone.gd`, `levels/fishing_spot.gd`; Test: `tests/levels/test_island.gd`
- Modify: `main/game.tscn` (`Level` becomes an instance of `levels/island.tscn`)

**Interfaces:**
- Produces `levels/island.tscn` with the node structure in `docs/content/level-island.md` "Scene structure":
  - `Terrain`: `StaticBody3D` on layer 1 with trimesh collision + mesh. Generated by the tool: 480 × 480 m grid, 2 m cells, centred on origin. Height: land base Y = 1 inside an island outline of ~200 m radius (radius wobbles ±20 m with seeded noise), ±0.4 m gentle noise on land, smooth fall to −2 over the last 25 m to the coast and beyond; rocky rise: smooth bump to +8 centred at (60, −130) radius 55. Vertex colours by zone (grass, sand below Y 0.6, rock above Y 3, dirt on the road). `FastNoiseLite` seed `20261110`.
  - `Water`: plane at Y = 0, 2000 m wide; `Area3D` on layer 9.
  - `Road`: 4 m wide strip, gentle S-curve from (−200, 0) to (200, 0) following terrain +0.02 m; `Area3D` in group `no_build` covering road ± 1 m margin.
  - `MerchantStall`: 8 × 8 m box pad at (10, −10) on the north side of the road, `Marker3D` `MerchantSpawn`, `no_build` area.
  - `Piers`: two box piers at the road ends with `no_build` areas.
  - `SpawnPoint`: `Marker3D` at (−40, y, 30), y = terrain height + 0.1.
  - `NodeMarkers`: `Marker3D`s with script `node_marker.gd` (`class_name NodeMarker`, `@export var def_id: StringName`), scattered with `RandomNumberGenerator` seed `20261110` by zone per the doc: 500 trees (60 % `tree_small`, 40 % `tree_large`; dense NW, sparse SE), 125 `rock` + 25 `ore_rock` on/near the rise, 120 `berry_bush`, 150 `fibre_grass`, 75 `loose_stick`, 75 `loose_stone`. None on the road margin, stall pad, within 15 m of `SpawnPoint`, or below Y 0.8.
  - `FishingSpots`: 5 `Area3D` (`class_name FishingSpot`, `@export var daily_cap: int = 12`): 2 in the pond at (90, 40) (pond: 25 m wide depression to −0.5), 3 on the south/east shore.
  - `WildlifeZones`: 3 `Area3D` (`class_name WildlifeZone`, `@export var animal_id: StringName`, `@export var target_population: int`): deer 6 (forest), rabbit 8 (light woods), boar 4 (rocky rise).
  - `NavRegions`: empty `Node3D` (filled by `npc` in M5).
  - `Environment`: `WorldEnvironment` (procedural sky, light fog) + `DirectionalLight3D` named `Sun`.
  - Invisible boundary: four `StaticBody3D` walls 40 m outside the coast on layer 1.

- [ ] **Step 1: Write the failing test**

```gdscript
extends GutTest
var level: Node3D
func before_all() -> void:
	level = load("res://levels/island.tscn").instantiate() ; add_child(level)
	await wait_physics_frames(2)
func after_all() -> void: level.free()

func _ground_y(x: float, z: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, 50, z), Vector3(x, -50, z), 1)
	var hit := level.get_world_3d().direct_space_state.intersect_ray(q)
	return hit.position.y if hit else -INF

func test_required_nodes() -> void:
	for p in ["Terrain","Water","Road","MerchantStall/MerchantSpawn","Piers","NodeMarkers","FishingSpots","WildlifeZones","NavRegions","SpawnPoint","Environment/Sun"]:
		assert_not_null(level.get_node_or_null(p), p)

func test_marker_counts() -> void:
	var counts := {}
	for m: NodeMarker in level.get_node("NodeMarkers").get_children(): counts[m.def_id] = counts.get(m.def_id, 0) + 1
	assert_eq(counts[&"tree_small"] + counts[&"tree_large"], 500)
	assert_eq(counts[&"rock"], 125) ; assert_eq(counts[&"ore_rock"], 25) ; assert_eq(counts[&"berry_bush"], 120)
	assert_eq(level.get_node("FishingSpots").get_child_count(), 5)
	assert_eq(level.get_node("WildlifeZones").get_child_count(), 3)

func test_island_is_mostly_flat() -> void:      # spec: 85 % of land within ±1 m of base level (Y = 1)
	var land := 0 ; var flat := 0
	for x in range(-200, 201, 10):
		for z in range(-200, 201, 10):
			var y := _ground_y(x, z)
			if y > 0.0: land += 1 ; flat += int(absf(y - 1.0) <= 1.0)
	assert_gt(land, 800) ; assert_gt(float(flat) / land, 0.85)

func test_no_holes_inside_coast() -> void:
	for x in range(-150, 151, 10):
		for z in range(-150, 151, 10):
			assert_gt(_ground_y(x, z), -3.0, "hole at %d,%d" % [x, z])

func test_markers_respect_exclusions() -> void:
	var spawn: Vector3 = level.get_node("SpawnPoint").global_position
	for m: Node3D in level.get_node("NodeMarkers").get_children():
		assert_gt(m.global_position.distance_to(spawn), 15.0)
		assert_gt(m.global_position.y, 0.8)

func test_capsule_stands_at_spawn() -> void:     # M0 gate: "a capsule can stand on the island"
	var body := CharacterBody3D.new() ; body.collision_mask = 1
	var cs := CollisionShape3D.new() ; var cap := CapsuleShape3D.new() ; cap.height = 1.7 ; cap.radius = 0.35
	cs.shape = cap ; cs.position.y = 0.85 ; body.add_child(cs) ; level.add_child(body)
	body.global_position = level.get_node("SpawnPoint").global_position + Vector3.UP
	for i in 120:
		body.velocity.y -= 20.0 / 60.0 ; body.move_and_slide() ; await wait_physics_frames(1)
	assert_true(body.is_on_floor()) ; assert_between(body.global_position.y, 0.5, 2.5)
	body.free()

func test_no_build_volumes_exist() -> void:
	assert_gte(get_tree().get_nodes_in_group("no_build").size(), 4)   # road, stall, 2 piers
```

- [ ] **Step 2: Run — expect FAIL.**
- [ ] **Step 3: Implement `tools/build_greybox_island.gd`** (`extends SceneTree`) that builds everything above deterministically and saves `levels/island.tscn` + the mesh resource. Marker heights come from the same height function as the mesh (not from physics). Running it twice yields an identical scene. Run: `"$GODOT" --headless --path . -s tools/build_greybox_island.gd`
- [ ] **Step 4: Point `game.tscn`'s `Level` at the island; run all tests — expect PASS.**
- [ ] **Step 5: Visual check.** Run the game windowed with `-- --autostart`, add a temporary free camera only if needed to look, capture one screenshot to the scratchpad, confirm: island visible, road crosses it, stall pad north of the road, sea around. Remove any temporary camera before committing.
- [ ] **Step 6: Commit** `feat(levels): grey-box island with markers and volumes`

---

### Task 8: M0 gate

**Files:**
- Modify: `docs/INDEX.md` (status board), `docs/qa-testing.md` (replace the generic commands with `tools/run_tests.sh`; note the GUT version vendored), `CLAUDE.md` (add the test command)

- [ ] **Step 1: Full verification.** `tools/run_tests.sh` → all pass. `"$GODOT" --headless --path . --quit` → no errors or warnings. `"$GODOT" --headless --path . --quit-after 120 -- --autostart` → no errors.
- [ ] **Step 2: Contract diff.** Re-read `docs/03-contracts.md` §3–8, §10 against the code; list every mismatch. Fix the code, or — if the contract was wrong — fix the doc and add a row to `docs/decisions.md`.
- [ ] **Step 3: Update docs** as listed; set M0 to `done` in the status board with the commit hash.
- [ ] **Step 4: Commit** `docs: M0 gate passed`, merge the branch into `main`.

---

## Self-Review Notes

- Spec coverage: every M0 bullet in `docs/roadmap.md` maps to a task (repo/layout → 1; project settings → 1; core defs/components/autoloads/placeholders → 2–6; main/game skeleton → 6; harness → 1; grey-box island → 7; gate → 8). `WorldClock`, `SaveGame`, `AudioDirector` autoloads are intentionally **not** created here — their owners add them in M2/M3/M6 via `lead`.
- Added beyond contracts (to be folded into `docs/03-contracts.md` in Task 8): `Registry.load_from`, `Entities.get_next_id/set_next_id/clear`, `HealthComponent.is_dead/revive`, `Inventory.bulky_only/allow_bulky/set_slot/free_space_for`, `Interactable.try_interact`, `World.register_manager`.
