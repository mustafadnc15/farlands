## NPC job: required tool and behaviour script.
class_name JobDef
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var required_tool: StringName = &""
@export var behaviour_script: Script
