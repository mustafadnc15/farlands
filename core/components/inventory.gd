## Fixed-size slot inventory. A slot is `{}` (empty) or `{id: StringName, count: int, durability: int}`.
## Mutating calls are host only and emit `changed` once per call that changed something.
class_name Inventory
extends Node

signal changed()

@export var slot_count: int = 24:
	set(value):
		slot_count = maxi(value, 0)
		_resize()
## Carry slots: accept only bulky items.
@export var bulky_only: bool = false
## Storage: accept bulky and non-bulky items. With both flags false (backpack) bulky items are rejected.
@export var allow_bulky: bool = false

var _slots: Array[Dictionary] = []


func _init() -> void:
	_resize()


## Returns the leftover count that did not fit. Unknown ids, count <= 0 and rejected items return `count`
## (never below 0) and change nothing. `durability` -1 means full durability for tools.
func add(item_id: StringName, count: int, durability: int = -1) -> int:
	if not _is_host("add") or count <= 0:
		return maxi(count, 0)
	var def: ItemDef = Registry.item(item_id)
	if def == null or not _accepts(def):
		return count
	var left := _fill_existing(def, count)
	left = _fill_empty(def, left, _starting_durability(def, durability))
	if left != count:
		changed.emit()
	return left


## All-or-nothing. Takes from the last matching slot first.
func remove(item_id: StringName, count: int) -> bool:
	if not _is_host("remove") or count <= 0 or count_of(item_id) < count:
		return false
	var left := count
	for i in range(_slots.size() - 1, -1, -1):
		if left == 0:
			break
		if _slots[i].get("id") != item_id:
			continue
		var take := mini(left, int(_slots[i]["count"]))
		_slots[i]["count"] = int(_slots[i]["count"]) - take
		if _slots[i]["count"] == 0:
			_slots[i] = {}
		left -= take
	changed.emit()
	return true


func count_of(item_id: StringName) -> int:
	var total := 0
	for slot: Dictionary in _slots:
		if slot.get("id") == item_id:
			total += int(slot["count"])
	return total


## `cost` maps item id -> required count.
func has_all(cost: Dictionary) -> bool:
	for item_id: Variant in cost:
		if count_of(StringName(item_id)) < int(cost[item_id]):
			return false
	return true


## A copy of the slot, or `{}` when empty or out of range.
func get_slot(i: int) -> Dictionary:
	if i < 0 or i >= _slots.size():
		return {}
	return _slots[i].duplicate()


## Host only. Overwrites slot `i` (`{}` empties it); used by moves/swaps and sync.
func set_slot(i: int, slot: Dictionary) -> void:
	if not _is_host("set_slot") or i < 0 or i >= _slots.size():
		return
	var normalized := _normalize(slot, false)
	if normalized == _slots[i]:
		return
	_slots[i] = normalized
	changed.emit()


## How many more of `item_id` fit right now (0 for unknown or rejected items).
func free_space_for(item_id: StringName) -> int:
	var def: ItemDef = Registry.item(item_id)
	if def == null or not _accepts(def):
		return 0
	var space := 0
	for slot: Dictionary in _slots:
		if slot.is_empty():
			space += def.max_stack
		elif slot["id"] == item_id:
			space += def.max_stack - int(slot["count"])
	return maxi(space, 0)


func to_dict() -> Dictionary:
	var out: Array = []
	for slot: Dictionary in _slots:
		if slot.is_empty():
			out.append({})
		else:
			out.append({"id": String(slot["id"]), "count": int(slot["count"]), "durability": int(slot["durability"])})
	return {"slots": out}


## Tolerant restore: missing "slots" empties everything, extras are dropped, unknown ids leave the slot
## empty (one warning in total), counts are clamped to max_stack.
func from_dict(d: Dictionary) -> void:
	var raw: Variant = d.get("slots", [])
	var src: Array = raw if raw is Array else []
	var before: Array[Dictionary] = _slots.duplicate(true)
	var unknown: Array[String] = []
	for i in _slots.size():
		var entry: Variant = src[i] if i < src.size() else {}
		_slots[i] = _restore_slot(entry, unknown)
	if not unknown.is_empty():
		push_warning("[inventory] from_dict dropped unknown item ids: %s" % ", ".join(unknown))
	if before != _slots:
		changed.emit()


func _restore_slot(entry: Variant, unknown: Array[String]) -> Dictionary:
	if not entry is Dictionary or (entry as Dictionary).is_empty():
		return {}
	var e: Dictionary = entry
	var item_id := StringName(str(e.get("id", "")))
	if not _item_exists(item_id):
		if not unknown.has(String(item_id)):
			unknown.append(String(item_id))
		return {}
	return _normalize(e, true)


## Builds a clean slot from loose (possibly JSON) data. Returns {} for invalid data.
func _normalize(slot: Dictionary, clamp_to_stack: bool) -> Dictionary:
	var item_id := StringName(str(slot.get("id", "")))
	var count := int(slot.get("count", 0))
	if count <= 0 or not _item_exists(item_id):
		return {}
	var def: ItemDef = Registry.item(item_id)
	if clamp_to_stack:
		count = mini(count, def.max_stack)
	return {"id": item_id, "count": count, "durability": _starting_durability(def, int(slot.get("durability", -1)))}


# Registry.item() pushes an error for unknown ids; scan instead where unknown ids are expected.
func _item_exists(item_id: StringName) -> bool:
	for def: ItemDef in Registry.all_items():
		if def.id == item_id:
			return true
	return false


func _accepts(def: ItemDef) -> bool:
	if bulky_only:
		return def.bulky
	return allow_bulky or not def.bulky


func _starting_durability(def: ItemDef, durability: int) -> int:
	if def.max_stack != 1 or def.tool == null:
		return -1
	return durability if durability >= 0 else def.tool.max_durability


func _fill_existing(def: ItemDef, count: int) -> int:
	var left := count
	for slot: Dictionary in _slots:
		if left == 0:
			break
		if slot.is_empty() or slot["id"] != def.id:
			continue
		var moved := mini(left, def.max_stack - int(slot["count"]))
		if moved > 0:
			slot["count"] = int(slot["count"]) + moved
			left -= moved
	return left


func _fill_empty(def: ItemDef, count: int, durability: int) -> int:
	var left := count
	for i in _slots.size():
		if left == 0:
			break
		if not _slots[i].is_empty():
			continue
		var moved := mini(left, def.max_stack)
		_slots[i] = {"id": def.id, "count": moved, "durability": durability}
		left -= moved
	return left


func _resize() -> void:
	var old := _slots.size()
	_slots.resize(slot_count)
	for i in range(old, slot_count):
		_slots[i] = {}


func _is_host(action: String) -> bool:
	if Net.is_host():
		return true
	push_warning("[inventory] %s ignored: not host" % action)
	return false
