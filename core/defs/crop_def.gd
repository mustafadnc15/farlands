## Crop: seed item, harvest item and count range, growth days, stage scenes, regrow flag.
class_name CropDef
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var seed_item: StringName = &""
@export var harvest_item: StringName = &""
@export var harvest_count_min: int = 1
@export var harvest_count_max: int = 1
@export var grow_days: float = 0.0
@export var stage_scenes: Array[PackedScene] = []
@export var regrows: bool = false
