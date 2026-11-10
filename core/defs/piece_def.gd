## Buildable piece: scene, cost, category, snap points, support need, function.
class_name PieceDef
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var icon: Texture2D
@export var scene: PackedScene
@export var cost: Dictionary[StringName, int] = {}
@export var category: StringName = &""
@export var snap_points: Array[SnapPoint] = []
@export var needs_support: bool = true
@export var function: StringName = &""
