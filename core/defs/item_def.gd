## Item definition: id, display_name, icon, world_scene, stacking, category, value, food values, optional tool stats.
class_name ItemDef
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var icon: Texture2D
@export var world_scene: PackedScene
@export var max_stack: int = 1
@export var bulky: bool = false
@export var category: StringName = &""
@export var base_value: int = 0
@export var food_hunger: float = 0.0
@export var food_health: float = 0.0
@export var tool: ToolStats
