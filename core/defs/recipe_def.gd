## Crafting recipe: output, output_count, inputs, station, craft_time.
class_name RecipeDef
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var output: StringName = &""
@export var output_count: int = 1
@export var inputs: Dictionary[StringName, int] = {}
@export var station: StringName = &""
@export var craft_time: float = 0.0
