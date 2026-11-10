## Network-stable entity id service (contracts §7).
## No class_name: this script is the `Entities` autoload singleton.
extends Node

var _next_id: int = 1
var _nodes: Dictionary[int, Node] = {}


## Allocates a fresh id. Host only: returns -1 (and logs an error) on a client.
func next_id() -> int:
	if not Net.is_host():
		push_error("[entities] next_id() called on a non-host peer")
		return -1
	var id := _next_id
	_next_id += 1
	return id


func register(entity_id: int, node: Node) -> void:
	if _nodes.has(entity_id) and is_instance_valid(_nodes.get(entity_id)):
		push_error("[entities] duplicate entity id %d" % entity_id)
		return
	_nodes[entity_id] = node


func unregister(entity_id: int) -> void:
	_nodes.erase(entity_id)


## Returns the registered node, or null if unknown or freed (stale entries are dropped).
func find(entity_id: int) -> Node:
	if not _nodes.has(entity_id):
		return null
	# Read untyped: assigning a freed instance to a typed Node variable errors.
	var entry: Variant = _nodes[entity_id]
	if not is_instance_valid(entry):
		_nodes.erase(entity_id)
		return null
	return entry as Node


## Next id that `next_id()` will hand out (for saving).
func get_next_id() -> int:
	return _next_id


func set_next_id(value: int) -> void:
	_next_id = value


func clear() -> void:
	_nodes.clear()
	_next_id = 1
