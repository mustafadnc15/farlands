## Animal: scene, health, speed, flee flag, attack damage, drops.
class_name AnimalDef
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var scene: PackedScene
@export var health: float = 0.0
@export var speed: float = 0.0
@export var flees: bool = false
@export var attack_damage: float = 0.0
@export var drops: Dictionary[StringName, int] = {}
