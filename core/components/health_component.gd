## Hit points with host-authoritative damage/heal. Emits `changed` on every real change, `died` once per death.
class_name HealthComponent
extends Node

signal changed(health: float, max_health: float)
signal died(source: StringName)

@export var max_health: float = 100.0

## Setter clamps to 0..max_health and emits `changed` only on a real change, so a MultiplayerSynchronizer
## writing it on a client updates listeners. `died` is host-side only (emitted by `damage`).
var health: float = 0.0:
	set(value):
		var v := clampf(value, 0.0, max_health)
		if v == health:
			return
		health = v
		changed.emit(health, max_health)


func _ready() -> void:
	health = max_health


func is_dead() -> bool:
	return health <= 0.0


func damage(amount: float, source: StringName) -> void:
	if not _is_host("damage") or amount <= 0.0 or is_dead():
		return
	health -= amount
	if is_dead():
		died.emit(source)


func heal(amount: float) -> void:
	if not _is_host("heal") or amount <= 0.0 or is_dead():
		return
	health += amount


## Brings a dead (or living) entity back at `to_health` (clamped to 1..max_health). Used for respawn.
func revive(to_health: float) -> void:
	if not _is_host("revive"):
		return
	health = clampf(to_health, 1.0, max_health)


func _is_host(action: String) -> bool:
	if Net.is_host():
		return true
	push_warning("[health] %s ignored: not host" % action)
	return false
