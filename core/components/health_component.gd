## Hit points with host-authoritative damage/heal. Emits `changed` on every real change, `died` once per death.
class_name HealthComponent
extends Node

signal changed(health: float, max_health: float)
signal died(source: StringName)

@export var max_health: float = 100.0

var health: float = 0.0
var _dead: bool = false


func _ready() -> void:
	health = max_health


func is_dead() -> bool:
	return _dead


func damage(amount: float, source: StringName) -> void:
	if not _is_host("damage") or amount <= 0.0 or _dead:
		return
	health = maxf(health - amount, 0.0)
	changed.emit(health, max_health)
	if health <= 0.0:
		_dead = true
		died.emit(source)


func heal(amount: float) -> void:
	if not _is_host("heal") or amount <= 0.0 or _dead:
		return
	var healed := minf(health + amount, max_health)
	if healed == health:
		return
	health = healed
	changed.emit(health, max_health)


## Brings a dead (or living) entity back at `to_health` (clamped to 1..max_health). Used for respawn.
func revive(to_health: float) -> void:
	if not _is_host("revive"):
		return
	health = clampf(to_health, 1.0, max_health)
	_dead = false
	changed.emit(health, max_health)


func _is_host(action: String) -> bool:
	if Net.is_host():
		return true
	push_warning("[health] %s ignored: not host" % action)
	return false
