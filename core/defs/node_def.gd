## Harvestable world node: scene, required tool, hit points, drops, respawn days.
class_name NodeDef
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var scene: PackedScene
@export var required_tool: StringName = &""
@export var hit_points: float = 0.0
@export var drops: Dictionary[StringName, int] = {}
@export var respawn_days: float = 0.0
