class_name World
extends Node3D
## Session world root. Holds the manager registry; see docs/03-contracts.md section 7.

const VALID_KEYS: Array[StringName] = [&"node", &"build", &"farm", &"npc", &"drop", &"economy"]

var _managers: Dictionary = {}

func _ready() -> void:
	add_to_group(&"world")

func get_manager(manager_name: StringName) -> Node:
	var m: Node = _managers.get(manager_name) as Node
	if m == null or not is_instance_valid(m):
		push_error("World: no manager registered under '%s'" % manager_name)
		return null
	return m

func register_manager(manager_name: StringName, node: Node) -> void:
	if not VALID_KEYS.has(manager_name):
		push_error("World: invalid manager key '%s'" % manager_name)
		return
	_managers[manager_name] = node
