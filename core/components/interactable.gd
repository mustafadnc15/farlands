## Area on the interact physics layer (5). Subclasses override `can_interact`; the host calls `try_interact`.
class_name Interactable
extends Area3D

signal interacted(peer_id: int)

@export var prompt: String = ""

var entity_id: int = 0


func _init() -> void:
	collision_layer = 1 << 4
	collision_mask = 0
	monitoring = false


func _ready() -> void:
	add_to_group(&"interactable")


func can_interact(_peer_id: int) -> bool:
	return true


## Host only. Emits `interacted` and returns true when the interaction is allowed.
func try_interact(peer_id: int) -> bool:
	if not Net.is_host():
		push_warning("[interactable] try_interact ignored: not host")
		return false
	if not can_interact(peer_id):
		return false
	interacted.emit(peer_id)
	return true
