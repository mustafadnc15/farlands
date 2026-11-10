extends GutTest

var inv: Inventory

func before_all() -> void:
	Registry.load_from("res://tests/core/fixtures/inv")

func after_all() -> void:
	Registry.load_from("res://content")

func before_each() -> void:
	inv = Inventory.new()
	add_child_autofree(inv)

func _slot_counts() -> Array[int]:
	var out: Array[int] = []
	for i: int in inv.slot_count:
		out.append(int(inv.get_slot(i).get("count", 0)))
	return out

func test_add_stacks_then_spills() -> void:
	inv.slot_count = 2
	assert_eq(inv.add(&"stick", 25), 0)
	assert_eq(inv.get_slot(0).count, 20)
	assert_eq(inv.get_slot(1).count, 5)

func test_add_returns_leftover() -> void:
	inv.slot_count = 1
	assert_eq(inv.add(&"stick", 25), 5)

func test_add_zero_or_negative_noop() -> void:
	watch_signals(inv)
	assert_eq(inv.add(&"stick", 0), 0)
	assert_eq(inv.add(&"stick", -3), 0)
	assert_eq(inv.count_of(&"stick"), 0)
	assert_signal_not_emitted(inv, "changed")

func test_add_unknown_id_rejected() -> void:
	assert_eq(inv.add(&"nope", 2), 2)
	assert_push_error("unknown item")
	assert_eq(inv.count_of(&"nope"), 0)
	assert_eq(inv.get_slot(0), {})

func test_backpack_rejects_bulky() -> void:
	assert_eq(inv.add(&"log", 1), 1)

func test_carry_accepts_only_bulky() -> void:
	inv.bulky_only = true
	inv.slot_count = 1
	assert_eq(inv.add(&"log", 4), 1)
	assert_eq(inv.add(&"stick", 1), 1)

func test_storage_accepts_both() -> void:
	inv.allow_bulky = true
	assert_eq(inv.add(&"log", 1), 0)
	assert_eq(inv.add(&"stick", 1), 0)

func test_tool_gets_full_durability() -> void:
	inv.add(&"stone_axe", 1)
	assert_eq(inv.get_slot(0).durability, 60)

func test_tool_keeps_given_durability() -> void:
	inv.add(&"stone_axe", 1, 12)
	assert_eq(inv.get_slot(0).durability, 12)

func test_remove_all_or_nothing() -> void:
	inv.add(&"stick", 5)
	assert_false(inv.remove(&"stick", 6))
	assert_eq(inv.count_of(&"stick"), 5)
	assert_true(inv.remove(&"stick", 5))
	assert_eq(inv.count_of(&"stick"), 0)

func test_remove_takes_from_last_slot_first() -> void:
	inv.add(&"stick", 25)
	assert_true(inv.remove(&"stick", 3))
	assert_eq(_slot_counts().slice(0, 2), [20, 2] as Array[int])

func test_has_all() -> void:
	inv.add(&"stick", 2)
	inv.add(&"stone_axe", 1)
	assert_true(inv.has_all({&"stick": 2, &"stone_axe": 1}))
	assert_false(inv.has_all({&"stick": 3}))
	assert_false(inv.has_all({&"stick": 2, &"stone_axe": 2}))
	assert_true(inv.has_all({}))

func test_get_slot_out_of_range() -> void:
	assert_eq(inv.get_slot(-1), {})
	assert_eq(inv.get_slot(999), {})

func test_get_slot_is_copy() -> void:
	inv.add(&"stick", 4)
	var s: Dictionary = inv.get_slot(0)
	s["count"] = 99
	assert_eq(inv.count_of(&"stick"), 4)

func test_free_space_for() -> void:
	inv.slot_count = 2
	inv.add(&"stick", 5)
	assert_eq(inv.free_space_for(&"stick"), 35)
	assert_eq(inv.free_space_for(&"log"), 0)

func test_zero_max_stack_treated_as_one() -> void:
	assert_eq(inv.slot_count, 24)
	assert_eq(inv.add(&"bad_stack", 3), 0)
	assert_eq(inv.count_of(&"bad_stack"), 3)
	var used := 0
	for i: int in inv.slot_count:
		if inv.get_slot(i).get("id") == &"bad_stack":
			used += 1
	assert_eq(used, 3)

func test_set_slot() -> void:
	watch_signals(inv)
	assert_true(inv.set_slot(1, {"id": &"stick", "count": 3, "durability": -1}))
	assert_eq(inv.count_of(&"stick"), 3)
	assert_signal_emit_count(inv, "changed", 1)
	assert_true(inv.set_slot(1, {"id": &"stick", "count": 3, "durability": -1}), "same slot again succeeds")
	assert_signal_emit_count(inv, "changed", 1)
	assert_true(inv.set_slot(1, {}))
	assert_eq(inv.count_of(&"stick"), 0)
	assert_true(inv.set_slot(1, {}), "{} always succeeds")

func test_set_slot_rejects_unknown_id() -> void:
	inv.set_slot(0, {"id": &"stick", "count": 2, "durability": -1})
	watch_signals(inv)
	assert_false(inv.set_slot(0, {"id": &"nope", "count": 1, "durability": -1}))
	assert_push_warning("set_slot rejected")
	assert_eq(inv.get_slot(0), {"id": &"stick", "count": 2, "durability": -1})
	assert_signal_not_emitted(inv, "changed")

func test_set_slot_rejects_count_over_stack() -> void:
	inv.set_slot(0, {"id": &"stick", "count": 2, "durability": -1})
	assert_false(inv.set_slot(0, {"id": &"stick", "count": 21, "durability": -1}))
	assert_push_warning("set_slot rejected")
	assert_eq(inv.get_slot(0), {"id": &"stick", "count": 2, "durability": -1})
	assert_false(inv.set_slot(0, {"id": &"stick", "count": 0, "durability": -1}))
	assert_eq(inv.get_slot(0), {"id": &"stick", "count": 2, "durability": -1})

func test_set_slot_rejects_bulky_in_backpack() -> void:
	assert_false(inv.set_slot(0, {"id": &"log", "count": 1, "durability": -1}))
	assert_push_warning("set_slot rejected")
	assert_eq(inv.get_slot(0), {})

func test_set_slot_rejects_out_of_range() -> void:
	assert_false(inv.set_slot(24, {"id": &"stick", "count": 1, "durability": -1}))
	assert_false(inv.set_slot(-1, {}))
	assert_push_warning("set_slot rejected")
	assert_eq(inv.count_of(&"stick"), 0)

func test_round_trip() -> void:
	inv.allow_bulky = true
	inv.add(&"stick", 25)
	inv.add(&"log", 2)
	inv.add(&"stone_axe", 1, 12)
	var d: Dictionary = inv.to_dict()
	var other := Inventory.new()
	other.allow_bulky = true
	add_child_autofree(other)
	other.from_dict(d)
	for i: int in inv.slot_count:
		assert_eq(other.get_slot(i), inv.get_slot(i))
	assert_eq(other.to_dict(), d)
	var parsed: Variant = JSON.parse_string(JSON.stringify(d))
	other.from_dict(parsed as Dictionary)
	assert_eq(other.to_dict(), d)

func test_from_dict_tolerates_garbage() -> void:
	inv.add(&"stick", 3)
	inv.from_dict({})
	assert_eq(inv.count_of(&"stick"), 0)
	inv.from_dict({"slots": [{"id": "nope", "count": 2, "durability": -1}]})
	assert_push_warning("nope")
	assert_eq(inv.get_slot(0), {})
	var many: Array = []
	for i: int in 40:
		many.append({"id": "stick", "count": 1, "durability": -1})
	inv.from_dict({"slots": many})
	assert_eq(inv.to_dict()["slots"].size(), 24)
	assert_eq(inv.count_of(&"stick"), 24)
	inv.from_dict({"slots": [{"id": "stick", "count": 99, "durability": -1}]})
	assert_eq(inv.get_slot(0).count, 20)

func test_changed_emits_once_per_call() -> void:
	watch_signals(inv)
	inv.add(&"stick", 25)
	assert_signal_emit_count(inv, "changed", 1)
